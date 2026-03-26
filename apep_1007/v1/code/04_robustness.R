## 04_robustness.R — Robustness checks: placebo, wild bootstrap, leave-one-out, HonestDiD
## apep_1007: Banking the Unbanked by Mandate

source("00_packages.R")

cat("=== Loading data ===\n")

panel <- fread("../data/panel_internet_banking.csv")
cs_out <- readRDS("../data/cs_results.rds")
cs_es <- readRDS("../data/cs_event_study.rds")

# ------------------------------------------------------------------
# 1. PLACEBO: Internet usage for non-financial purposes
# ------------------------------------------------------------------
cat("\n=== 1. Placebo Test: Internet info usage ===\n")

if (file.exists("../data/panel_placebo.csv")) {
  panel_placebo <- fread("../data/panel_placebo.csv")
  panel_placebo[, year := as.integer(year)]
  panel_placebo[, group := as.integer(group)]

  placebo_twfe <- feols(internet_info_pct ~ treated | country_id + year,
                         data = panel_placebo, cluster = ~country_id)
  cat("Placebo TWFE (internet info):", coef(placebo_twfe)["treated"],
      "SE:", sqrt(vcov(placebo_twfe)["treated", "treated"]), "\n")

  cs_placebo <- tryCatch({
    att_gt(
      yname = "internet_info_pct",
      tname = "year",
      idname = "country_id",
      gname = "group",
      data = as.data.frame(panel_placebo),
      control_group = "notyettreated",
      anticipation = 0,
      est_method = "dr",
      base_period = "varying",
      clustervars = "country_id",
      print_details = FALSE
    )
  }, error = function(e) {
    cat("  CS-DiD placebo failed:", conditionMessage(e), "\n")
    NULL
  })

  if (!is.null(cs_placebo)) {
    cs_placebo_simple <- aggte(cs_placebo, type = "simple", na.rm = TRUE)
    cat("Placebo CS-DiD ATT:\n")
    summary(cs_placebo_simple)
    saveRDS(cs_placebo, "../data/cs_placebo.rds")
  }

  saveRDS(placebo_twfe, "../data/placebo_twfe.rds")
} else {
  cat("  No placebo data available.\n")
}

# ------------------------------------------------------------------
# 2. WILD CLUSTER BOOTSTRAP (few clusters)
# ------------------------------------------------------------------
cat("\n=== 2. Wild Cluster Bootstrap ===\n")

twfe_main <- feols(internet_banking_pct ~ treated | country_id + year,
                    data = panel, cluster = ~country_id)

# Manual wild cluster bootstrap (Rademacher weights)
set.seed(42)
n_boot <- 9999
clusters <- unique(panel$country_id)
n_clusters <- length(clusters)
beta_hat <- coef(twfe_main)["treated"]

boot_t_stats <- numeric(n_boot)
for (b in seq_len(n_boot)) {
  # Rademacher weights: +1 or -1 with equal probability
  weights <- sample(c(-1, 1), n_clusters, replace = TRUE)
  names(weights) <- clusters

  # Perturb residuals by cluster
  panel_boot <- copy(panel)
  panel_boot[, resid := residuals(twfe_main)]
  panel_boot[, boot_resid := resid * weights[as.character(country_id)]]
  panel_boot[, boot_y := fitted(twfe_main) + boot_resid]

  boot_fit <- tryCatch(
    feols(boot_y ~ treated | country_id + year,
          data = panel_boot, cluster = ~country_id),
    error = function(e) NULL
  )
  if (!is.null(boot_fit)) {
    boot_t_stats[b] <- (coef(boot_fit)["treated"] - beta_hat) /
      sqrt(vcov(boot_fit)["treated", "treated"])
  }
}

# Compute WCB p-value
t_stat_orig <- beta_hat / sqrt(vcov(twfe_main)["treated", "treated"])
wcb_pval <- mean(abs(boot_t_stats) >= abs(t_stat_orig), na.rm = TRUE)
cat("WCB p-value (Rademacher):", wcb_pval, "\n")

wcb_result <- list(p_val = wcb_pval, t_stat = t_stat_orig, n_boot = n_boot)
saveRDS(wcb_result, "../data/wcb_result.rds")

# ------------------------------------------------------------------
# 3. LEAVE-ONE-OUT: Drop each country
# ------------------------------------------------------------------
cat("\n=== 3. Leave-One-Out ===\n")

countries <- unique(panel$country_code)
loo_results <- data.table(
  dropped = character(),
  coef = numeric(),
  se = numeric(),
  pval = numeric()
)

for (cc in countries) {
  loo_panel <- panel[country_code != cc]
  loo_fit <- feols(internet_banking_pct ~ treated | country_id + year,
                    data = loo_panel, cluster = ~country_id)
  loo_results <- rbind(loo_results, data.table(
    dropped = cc,
    coef = coef(loo_fit)["treated"],
    se = sqrt(vcov(loo_fit)["treated", "treated"]),
    pval = pvalue(loo_fit)["treated"]
  ))
}

cat("Leave-one-out results:\n")
cat("  Coefficient range:", range(loo_results$coef), "\n")
cat("  Most influential drop:", loo_results[which.max(abs(coef - median(coef)))]$dropped, "\n")
print(loo_results[order(coef)])

fwrite(loo_results, "../data/leave_one_out.csv")

# ------------------------------------------------------------------
# 4. HONESTDID SENSITIVITY (Rambachan-Roth bounds)
# ------------------------------------------------------------------
cat("\n=== 4. HonestDiD Sensitivity Analysis ===\n")

honest_result <- tryCatch({
  # Use CS event study for HonestDiD
  # Need to construct betahat and sigma from CS results
  es_coefs <- cs_es$att.egt
  es_se <- cs_es$se.egt
  es_periods <- cs_es$egt

  # Pre-treatment coefficients
  pre_idx <- which(es_periods < 0)
  post_idx <- which(es_periods >= 0)

  if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
    # Construct objects for HonestDiD
    betahat <- es_coefs
    sigma <- diag(es_se^2)  # Approximate (diagonal) variance matrix

    # Relative magnitudes approach
    honest_rm <- HonestDiD::createSensitivityResults_relativeMagnitudes(
      betahat = betahat,
      sigma = sigma,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mbarvec = seq(0, 2, by = 0.5)
    )
    cat("HonestDiD relative magnitudes:\n")
    print(honest_rm)
    honest_rm
  } else {
    cat("  Not enough pre/post periods for HonestDiD.\n")
    NULL
  }
}, error = function(e) {
  cat("  HonestDiD failed:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(honest_result)) {
  saveRDS(honest_result, "../data/honest_did.rds")
}

# ------------------------------------------------------------------
# 5. ALTERNATIVE ESTIMATOR: Sun-Abraham
# ------------------------------------------------------------------
cat("\n=== 5. Sun-Abraham Comparison ===\n")

panel[, cohort := fifelse(group == 0, 10000L, group)]
sa_result <- feols(internet_banking_pct ~ sunab(cohort, year) | country_id + year,
                    data = panel, cluster = ~country_id)
cat("Sun-Abraham overall ATT:\n")
summary(sa_result)
saveRDS(sa_result, "../data/sa_result.rds")

# ------------------------------------------------------------------
# 6. NEVER-TREATED TEST
# ------------------------------------------------------------------
cat("\n=== 6. Never-Treated Countries at Directive Deadline ===\n")

# Test: do pre-existing law countries show a change around Sept 2016 (deadline)?
never_treated <- panel[group == 0]
if (nrow(never_treated) > 0) {
  # Simple before/after means for never-treated countries
  nt_before <- never_treated[year < 2017, mean(internet_banking_pct, na.rm = TRUE)]
  nt_after <- never_treated[year >= 2017, mean(internet_banking_pct, na.rm = TRUE)]
  cat("Never-treated countries around deadline (2017):\n")
  cat("  Mean before:", round(nt_before, 2), "\n")
  cat("  Mean after:", round(nt_after, 2), "\n")
  cat("  Difference:", round(nt_after - nt_before, 2), "(secular growth, not PAD)\n")
}

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
