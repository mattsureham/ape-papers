## 04_robustness.R — Robustness checks and placebo tests
## apep_0865: Last Call for Competition

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
load(file.path(data_dir, "main_results.RData"))

panel[, fips_f := as.factor(fips)]
panel[, year_f := as.factor(year)]

# Recompute RDD running variable (same as 03_main_analysis.R)
panel[, prev_threshold := licenses_entitled * 7500]
panel[, dist_from_crossed := POP - prev_threshold]
panel[, rv_rdd := fifelse(gained_license == 1, dist_from_crossed, -(next_threshold - POP))]

cat("=== Robustness Checks ===\n")

# ============================================================
# 1. Bandwidth sensitivity for RDD
# ============================================================
cat("\n--- RDD bandwidth sensitivity ---\n")

rdd_data <- panel[!is.na(emp_drink) & !is.na(rv_rdd) & is.finite(rv_rdd)]

bandwidths <- c(1000, 1500, 2000, 2500, 3000, 3500)
bw_results <- data.frame(
  bw = numeric(), coef = numeric(), se = numeric(),
  ci_lo = numeric(), ci_hi = numeric(), n = numeric()
)

for (bw in bandwidths) {
  sub <- rdd_data[abs(rv_rdd) <= bw]
  if (nrow(sub) >= 30) {
    rdd_fit <- tryCatch(
      rdrobust(y = sub$emp_drink, x = sub$rv_rdd, c = 0,
               kernel = "triangular", all = TRUE),
      error = function(e) NULL
    )
    if (!is.null(rdd_fit)) {
      bw_results <- rbind(bw_results, data.frame(
        bw = bw,
        coef = rdd_fit$coef[1],
        se = rdd_fit$se[3],
        ci_lo = rdd_fit$ci[3, 1],
        ci_hi = rdd_fit$ci[3, 2],
        n = rdd_fit$N[1] + rdd_fit$N[2]
      ))
    }
  }
}

if (nrow(bw_results) > 0) {
  cat("\nBandwidth sensitivity results:\n")
  print(bw_results)
}

# ============================================================
# 2. Placebo cutoffs (false thresholds)
# ============================================================
cat("\n--- Placebo cutoffs ---\n")

# Test at 3,750 and 5,000 (non-threshold values)
placebo_cutoffs <- c(2500, 3750, 5000)
placebo_results <- data.frame(
  cutoff = numeric(), coef = numeric(), se = numeric(), pval = numeric()
)

for (pc in placebo_cutoffs) {
  panel[, rv_placebo := (POP %% pc) - pc/2]
  sub_p <- panel[!is.na(emp_drink) & !is.na(rv_placebo) & is.finite(rv_placebo)]
  if (nrow(sub_p) > 50) {
    rdd_p <- tryCatch(
      rdrobust(y = sub_p$emp_drink, x = sub_p$rv_placebo, c = 0,
               kernel = "triangular", all = TRUE),
      error = function(e) NULL
    )
    if (!is.null(rdd_p)) {
      placebo_results <- rbind(placebo_results, data.frame(
        cutoff = pc,
        coef = rdd_p$coef[1],
        se = rdd_p$se[3],
        pval = rdd_p$pv[3]
      ))
    }
  }
}

if (nrow(placebo_results) > 0) {
  cat("\nPlacebo cutoff results:\n")
  print(placebo_results)
}

# ============================================================
# 3. Covariate balance at threshold
# ============================================================
cat("\n--- Covariate balance ---\n")

# Test whether restaurant employment (not subject to quota) is smooth at threshold
if (nrow(rdd_data[!is.na(emp_rest)]) > 50) {
  rdd_rest <- tryCatch(
    rdrobust(y = rdd_data$emp_rest[!is.na(rdd_data$emp_rest)],
             x = rdd_data$rv_rdd[!is.na(rdd_data$emp_rest)],
             c = 0, kernel = "triangular", all = TRUE),
    error = function(e) NULL
  )
  if (!is.null(rdd_rest)) {
    cat("\nBalance test: Restaurant employment at threshold\n")
    cat(sprintf("  Coefficient: %.3f, Robust SE: %.3f, p-value: %.3f\n",
                rdd_rest$coef[1], rdd_rest$se[3], rdd_rest$pv[3]))
  }
}

# Test population level (should be smooth by construction near modular boundary)
rdd_pop <- tryCatch(
  rdrobust(y = rdd_data$POP, x = rdd_data$rv_rdd, c = 0,
           kernel = "triangular", all = TRUE),
  error = function(e) NULL
)
if (!is.null(rdd_pop)) {
  cat(sprintf("\nBalance test: Population at threshold\n"))
  cat(sprintf("  Coefficient: %.1f, Robust SE: %.1f, p-value: %.3f\n",
              rdd_pop$coef[1], rdd_pop$se[3], rdd_pop$pv[3]))
}

# ============================================================
# 4. Panel robustness: alternative specifications
# ============================================================
cat("\n--- Panel specification robustness ---\n")

# 4a. Binary treatment (any new license)
m_binary <- feols(emp_drink ~ gained_license | fips_f + year_f,
                  data = panel[!is.na(emp_drink)],
                  cluster = ~fips_f)
cat("\nBinary treatment (any new license):\n")
summary(m_binary)

# 4b. With population control
m_pop <- feols(emp_drink ~ new_licenses_yr + POP | fips_f + year_f,
               data = panel[!is.na(emp_drink)],
               cluster = ~fips_f)
cat("\nWith population control:\n")
summary(m_pop)

# 4c. Excluding Miami-Dade (largest county, potential outlier)
m_no_dade <- feols(emp_drink ~ new_licenses_yr | fips_f + year_f,
                   data = panel[!is.na(emp_drink) & fips != "12086"],
                   cluster = ~fips_f)
cat("\nExcluding Miami-Dade:\n")
summary(m_no_dade)

# 4d. Per capita specification
m_pc <- feols(emp_drink_pc ~ new_licenses_yr | fips_f + year_f,
              data = panel[!is.na(emp_drink_pc)],
              cluster = ~fips_f)
cat("\nPer capita employment:\n")
summary(m_pc)

# 4e. Leave-one-out: drop each county, re-estimate
cat("\n--- Leave-one-out sensitivity ---\n")
counties <- unique(panel$fips[!is.na(panel$emp_drink)])
loo_coefs <- numeric(length(counties))
for (i in seq_along(counties)) {
  loo_fit <- feols(emp_drink ~ new_licenses_yr | fips_f + year_f,
                   data = panel[!is.na(emp_drink) & fips != counties[i]],
                   cluster = ~fips_f)
  loo_coefs[i] <- coef(loo_fit)["new_licenses_yr"]
}
cat(sprintf("Leave-one-out: mean coef = %.3f, sd = %.3f, range = [%.3f, %.3f]\n",
            mean(loo_coefs), sd(loo_coefs), min(loo_coefs), max(loo_coefs)))

# ============================================================
# 5. Save robustness results
# ============================================================
save(bw_results, placebo_results, m_binary, m_pop, m_no_dade, m_pc,
     loo_coefs,
     file = file.path(data_dir, "robustness_results.RData"))

cat("\n=== Robustness checks complete ===\n")
