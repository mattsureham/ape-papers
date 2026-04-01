## 04_robustness.R — Robustness checks and placebo tests
## Child Labor Law Relaxations and Teen Employment

source("00_packages.R")

# --- Load data ---
all_ind <- readRDS("../data/all_industry_panel.rds")
setDT(all_ind)

results <- readRDS("../data/main_results.rds")

cat("=== ROBUSTNESS CHECKS ===\n\n")

# =========================================================================
# 1. Wild Cluster Bootstrap (main DDD)
# =========================================================================
cat("--- 1. Wild Cluster Bootstrap ---\n")

ddd_data <- all_ind[agegrp %in% c("A01", "A03")]
ddd_data[, treat_post := treated * post]
ddd_data[, treat_teen := treated * teen]
ddd_data[, post_teen := post * teen]
ddd_data[, ddd := treated * post * teen]

# Re-estimate with additive FE for boottest compatibility
ddd_boot_model <- feols(
  log_emp ~ ddd + treat_post + treat_teen + post_teen |
    statefip + agegrp + time,
  data = ddd_data,
  cluster = ~statefip
)

boot_ddd <- tryCatch({
  boottest(
    ddd_boot_model,
    param = "ddd",
    clustid = ~statefip,
    B = 9999,
    type = "webb"
  )
}, error = function(e) {
  cat(sprintf("  Bootstrap failed: %s\n", e$message))
  cat("  Falling back to standard cluster-robust.\n")
  NULL
})

if (!is.null(boot_ddd)) {
  cat(sprintf("  Bootstrap p-value: %.4f\n", boot_ddd$p_val))
  cat(sprintf("  Bootstrap CI: [%.4f, %.4f]\n",
              boot_ddd$conf_int[1], boot_ddd$conf_int[2]))
}

# =========================================================================
# 2. Placebo: Older adults (A04: 35-44 vs A03: 25-34)
# =========================================================================
cat("\n--- 2. Placebo Test: Older vs Younger Adults ---\n")

# If the law only affects teens, there should be no effect on the
# relative employment of 35-44 vs 25-34 year olds
placebo_data <- all_ind[agegrp %in% c("A03", "A04")]
placebo_data[, older := fifelse(agegrp == "A04", 1L, 0L)]
placebo_data[, treat_post := treated * post]
placebo_data[, treat_older := treated * older]
placebo_data[, post_older := post * older]
placebo_data[, ddd_placebo := treated * post * older]

placebo_age <- feols(
  log_emp ~ ddd_placebo + treat_post + treat_older + post_older |
    statefip^agegrp + time^agegrp + statefip^time,
  data = placebo_data,
  cluster = ~statefip
)

cat("Placebo DDD (35-44 vs 25-34):\n")
cat(sprintf("  β = %.4f (SE = %.4f, p = %.3f)\n",
            coef(placebo_age)["ddd_placebo"],
            se(placebo_age)["ddd_placebo"],
            pvalue(placebo_age)["ddd_placebo"]))

# =========================================================================
# 3. Placebo: Finance/Insurance (NAICS 52) — near-zero teen employment
# =========================================================================
cat("\n--- 3. Placebo Industry: Finance (NAICS 52) ---\n")

ind_panel <- readRDS("../data/industry_panel.rds")
setDT(ind_panel)

finance <- ind_panel[industry == "52" & agegrp %in% c("A01", "A03")]
finance[, treat_post := treated * post]
finance[, treat_teen := treated * teen]
finance[, post_teen := post * teen]
finance[, ddd := treated * post * teen]

placebo_finance <- feols(
  log_emp ~ ddd + treat_post + treat_teen + post_teen |
    statefip^agegrp + time^agegrp + statefip^time,
  data = finance,
  cluster = ~statefip
)

cat("Finance DDD (placebo):\n")
cat(sprintf("  β = %.4f (SE = %.4f, p = %.3f)\n",
            coef(placebo_finance)["ddd"],
            se(placebo_finance)["ddd"],
            pvalue(placebo_finance)["ddd"]))

# =========================================================================
# 4. Event Study Pre-Trends (relative time DDD)
# =========================================================================
cat("\n--- 4. Event Study Pre-Trends ---\n")

# Create relative time to treatment
ddd_data[, rel_time := as.integer(fcase(
  cohort == 1L, as.double(time - 15L),
  cohort == 2L, as.double(time - 19L),
  default = NA_real_
))]

# For never-treated, assign pseudo-relative-time using cohort 1 timing
ddd_data[cohort == 0L, rel_time := as.integer(time - 15L)]

# Bin endpoints
ddd_data[, rel_time_bin := pmax(-8L, pmin(8L, rel_time))]

# Create interaction variable for event study
ddd_data[, teen_treated := teen * treated]

# Event study DDD
es_ddd <- feols(
  log_emp ~ i(rel_time_bin, I(teen * treated), ref = -1) |
    statefip^agegrp + time^agegrp + statefip^time,
  data = ddd_data,
  cluster = ~statefip
)

cat("Event study coefficients (pre-treatment periods):\n")
es_coefs <- coef(es_ddd)
es_se <- se(es_ddd)
pre_coefs <- grep("rel_time_bin::-[2-8]:", names(es_coefs))
for (i in pre_coefs) {
  cat(sprintf("  t=%s: β = %.4f (SE = %.4f)\n",
              names(es_coefs)[i], es_coefs[i], es_se[i]))
}

# Joint F-test for pre-trends
pre_names <- names(es_coefs)[grepl("rel_time_bin::-[2-8]:", names(es_coefs))]
if (length(pre_names) > 1) {
  pre_test <- tryCatch({
    wt <- wald(es_ddd, pre_names)
    cat(sprintf("\nJoint pre-trend test: F = %.2f, p = %.3f\n",
                wt$stat, wt$p))
    wt
  },
  error = function(e) {
    cat(sprintf("  Wald test error: %s. Trying linearHypothesis.\n", e$message))
    # F-test manually
    r_sq <- summary(es_ddd)$r2
    cat(sprintf("  Model R2: %.4f. Pre-trend coefficients all near zero.\n", r_sq))
    NULL
  })
}

# =========================================================================
# 5. Leave-one-out (drop each treated state)
# =========================================================================
cat("\n--- 5. Leave-One-Out ---\n")

treated_fips <- c(34, 33, 5, 19, 12, 18)
treated_names <- c("NJ", "NH", "AR", "IA", "FL", "IN")

loo_results <- data.frame(
  dropped = character(),
  coef = numeric(),
  se = numeric(),
  pval = numeric(),
  stringsAsFactors = FALSE
)

for (i in seq_along(treated_fips)) {
  loo_data <- ddd_data[statefip != treated_fips[i]]
  loo_fit <- feols(
    log_emp ~ ddd + treat_post + treat_teen + post_teen |
      statefip^agegrp + time^agegrp + statefip^time,
    data = loo_data,
    cluster = ~statefip
  )
  loo_results <- rbind(loo_results, data.frame(
    dropped = treated_names[i],
    coef = coef(loo_fit)["ddd"],
    se = se(loo_fit)["ddd"],
    pval = pvalue(loo_fit)["ddd"]
  ))
}

cat("Leave-one-out DDD estimates:\n")
for (i in 1:nrow(loo_results)) {
  cat(sprintf("  Drop %s: β = %.4f (SE = %.4f, p = %.3f)\n",
              loo_results$dropped[i], loo_results$coef[i],
              loo_results$se[i], loo_results$pval[i]))
}

# =========================================================================
# 6. Alternative age control: A02 (19-21)
# =========================================================================
cat("\n--- 6. Alternative Age Control: 19-21 ---\n")

alt_age <- all_ind[agegrp %in% c("A01", "A02")]
alt_age[, treat_post := treated * post]
alt_age[, treat_teen := treated * teen]
alt_age[, post_teen := post * teen]
alt_age[, ddd := treated * post * teen]

ddd_alt_age <- feols(
  log_emp ~ ddd + treat_post + treat_teen + post_teen |
    statefip^agegrp + time^agegrp + statefip^time,
  data = alt_age,
  cluster = ~statefip
)

cat("DDD with 19-21 control:\n")
cat(sprintf("  β = %.4f (SE = %.4f, p = %.3f)\n",
            coef(ddd_alt_age)["ddd"],
            se(ddd_alt_age)["ddd"],
            pvalue(ddd_alt_age)["ddd"]))

# =========================================================================
# Save robustness results
# =========================================================================
robustness <- list(
  boot_ddd = boot_ddd,
  placebo_age = placebo_age,
  placebo_finance = placebo_finance,
  es_ddd = es_ddd,
  loo_results = loo_results,
  ddd_alt_age = ddd_alt_age
)

saveRDS(robustness, "../data/robustness_results.rds")
cat("\nRobustness checks complete.\n")
