## 03_main_analysis.R — Primary DiD estimation
## APEP apep_0623: The Symmetric Tax Shock

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

## ============================================================
## 1. Load analysis panel
## ============================================================
cat("=== Loading analysis panel ===\n")
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
cat("  Observations:", format(nrow(panel), big.mark = ","), "\n")
cat("  Zip codes:", length(unique(panel$zip5)), "\n")

## ============================================================
## 2. TCJA Analysis (2014-2024, pre-OBBB)
## ============================================================
cat("\n=== TCJA Cap Analysis ===\n")

# Restrict to pre-OBBB period for clean TCJA estimate
tcja_panel <- panel[date < as.Date("2025-01-01")]

# Main specification: continuous treatment, zip + month FE
# Y_z,t = alpha_z + gamma_t + beta * Post_TCJA * SALT_exposure_z + epsilon
fit_tcja_1 <- feols(log_zhvi ~ treat_tcja | zip_id + ym,
                     data = tcja_panel,
                     cluster = ~state_fips)

cat("Spec 1 (Zip + Month FE, continuous):\n")
cat("  Coefficient:", round(coef(fit_tcja_1)["treat_tcja"], 6), "\n")
cat("  SE:", round(se(fit_tcja_1)["treat_tcja"], 6), "\n")
cat("  p-value:", round(pvalue(fit_tcja_1)["treat_tcja"], 4), "\n")

# Binary treatment version
fit_tcja_2 <- feols(log_zhvi ~ treat_tcja_bin | zip_id + ym,
                     data = tcja_panel,
                     cluster = ~state_fips)

cat("\nSpec 2 (Zip + Month FE, binary):\n")
cat("  Coefficient:", round(coef(fit_tcja_2)["treat_tcja_bin"], 6), "\n")
cat("  SE:", round(se(fit_tcja_2)["treat_tcja_bin"], 6), "\n")

# Within-metro specification (CBSA x month FE)
if ("metro_id" %in% names(tcja_panel) && length(unique(tcja_panel$metro_id[!is.na(tcja_panel$metro_id)])) > 1) {
  tcja_metro <- tcja_panel[!is.na(metro_id)]

  fit_tcja_3 <- feols(log_zhvi ~ treat_tcja | zip_id + metro_id^ym,
                       data = tcja_metro,
                       cluster = ~state_fips)

  cat("\nSpec 3 (Zip + Metro×Month FE, continuous):\n")
  cat("  Coefficient:", round(coef(fit_tcja_3)["treat_tcja"], 6), "\n")
  cat("  SE:", round(se(fit_tcja_3)["treat_tcja"], 6), "\n")

  fit_tcja_4 <- feols(log_zhvi ~ treat_tcja_bin | zip_id + metro_id^ym,
                       data = tcja_metro,
                       cluster = ~state_fips)

  cat("\nSpec 4 (Zip + Metro×Month FE, binary):\n")
  cat("  Coefficient:", round(coef(fit_tcja_4)["treat_tcja_bin"], 6), "\n")
  cat("  SE:", round(se(fit_tcja_4)["treat_tcja_bin"], 6), "\n")
} else {
  cat("\nWARNING: Metro ID not available. Using state×month FE instead.\n")
  fit_tcja_3 <- feols(log_zhvi ~ treat_tcja | zip_id + state_fips^ym,
                       data = tcja_panel,
                       cluster = ~state_fips)
  fit_tcja_4 <- feols(log_zhvi ~ treat_tcja_bin | zip_id + state_fips^ym,
                       data = tcja_panel,
                       cluster = ~state_fips)
}

## ============================================================
## 3. OBBB Reversal Analysis (2022-2026)
## ============================================================
cat("\n=== OBBB Reversal Analysis ===\n")

# Use 2022-2026 for clean reversal window
obbb_panel <- panel[date >= as.Date("2022-01-01")]

# Main specification
fit_obbb_1 <- feols(log_zhvi ~ treat_obbb | zip_id + ym,
                     data = obbb_panel,
                     cluster = ~state_fips)

cat("Spec 1 (Zip + Month FE, continuous):\n")
cat("  Coefficient:", round(coef(fit_obbb_1)["treat_obbb"], 6), "\n")
cat("  SE:", round(se(fit_obbb_1)["treat_obbb"], 6), "\n")

# Binary treatment
fit_obbb_2 <- feols(log_zhvi ~ treat_obbb_bin | zip_id + ym,
                     data = obbb_panel,
                     cluster = ~state_fips)

cat("\nSpec 2 (Zip + Month FE, binary):\n")
cat("  Coefficient:", round(coef(fit_obbb_2)["treat_obbb_bin"], 6), "\n")

# Within-metro
if ("metro_id" %in% names(obbb_panel) && length(unique(obbb_panel$metro_id[!is.na(obbb_panel$metro_id)])) > 1) {
  obbb_metro <- obbb_panel[!is.na(metro_id)]

  fit_obbb_3 <- feols(log_zhvi ~ treat_obbb | zip_id + metro_id^ym,
                       data = obbb_metro,
                       cluster = ~state_fips)

  fit_obbb_4 <- feols(log_zhvi ~ treat_obbb_bin | zip_id + metro_id^ym,
                       data = obbb_metro,
                       cluster = ~state_fips)
} else {
  fit_obbb_3 <- feols(log_zhvi ~ treat_obbb | zip_id + state_fips^ym,
                       data = obbb_panel,
                       cluster = ~state_fips)
  fit_obbb_4 <- feols(log_zhvi ~ treat_obbb_bin | zip_id + state_fips^ym,
                       data = obbb_panel,
                       cluster = ~state_fips)
}

## ============================================================
## 4. Symmetry Test — Full Panel
## ============================================================
cat("\n=== Symmetry Test ===\n")

# Full panel with both shocks
# Create separate post indicators for each shock period
panel[, tcja_only := as.integer(date >= as.Date("2018-01-01") & date < as.Date("2025-01-01"))]
panel[, obbb_on := as.integer(date >= as.Date("2025-01-01"))]

# Interact with SALT exposure
panel[, treat_tcja_sym := tcja_only * salt_exposure]
panel[, treat_obbb_sym := obbb_on * salt_exposure]

fit_sym <- feols(log_zhvi ~ treat_tcja_sym + treat_obbb_sym | zip_id + ym,
                  data = panel,
                  cluster = ~state_fips)

cat("Symmetry regression:\n")
cat("  TCJA coefficient:", round(coef(fit_sym)["treat_tcja_sym"], 6), "\n")
cat("  OBBB coefficient:", round(coef(fit_sym)["treat_obbb_sym"], 6), "\n")

# Test H0: beta_tcja = beta_obbb (no change from cap to reversal — pure hysteresis)
# If reversal restored prices, beta_obbb should be closer to 0 than beta_tcja
# Test difference: beta_obbb - beta_tcja = 0
sym_test <- tryCatch({
  wald(fit_sym, keep = c("treat_tcja_sym", "treat_obbb_sym"),
       hypotheses = "treat_tcja_sym = treat_obbb_sym")
}, error = function(e) {
  # Manual Wald test
  b <- coef(fit_sym)
  V <- vcov(fit_sym)
  diff <- b["treat_obbb_sym"] - b["treat_tcja_sym"]
  se_diff <- sqrt(V["treat_obbb_sym", "treat_obbb_sym"] +
                   V["treat_tcja_sym", "treat_tcja_sym"] -
                   2 * V["treat_obbb_sym", "treat_tcja_sym"])
  list(diff = diff, se_diff = se_diff, t_stat = diff / se_diff,
       p_value = 2 * pnorm(-abs(diff / se_diff)))
})

if (is.list(sym_test) && "diff" %in% names(sym_test)) {
  cat("  Symmetry test (H0: beta_TCJA = beta_OBBB):\n")
  cat("    Difference:", round(sym_test$diff, 6), "\n")
  cat("    SE:", round(sym_test$se_diff, 6), "\n")
  cat("    t-stat:", round(sym_test$t_stat, 4), "\n")
  cat("    p-value:", round(sym_test$p_value, 4), "\n")
} else {
  cat("  Symmetry Wald test:\n")
  print(sym_test)
}

# Also test H0: beta_obbb = 0 (full reversal to baseline)
cat("\n  Test: beta_OBBB = 0 (full reversal):\n")
cat("    Coefficient:", round(coef(fit_sym)["treat_obbb_sym"], 6), "\n")
cat("    p-value:", round(pvalue(fit_sym)["treat_obbb_sym"], 4), "\n")

## ============================================================
## 5. Event Study (for pre-trends validation)
## ============================================================
cat("\n=== Event Study (TCJA) ===\n")

# Create yearly relative-time dummies for TCJA (2014-2024)
tcja_panel[, rel_year := year - 2018]

# Event study with yearly interactions
fit_es <- feols(log_zhvi ~ i(rel_year, salt_exposure, ref = -1) | zip_id + ym,
                 data = tcja_panel,
                 cluster = ~state_fips)

# Extract pre-trend coefficients
es_coefs <- coeftable(fit_es)
cat("Event study coefficients (selected):\n")
pre_coefs <- es_coefs[grep("rel_year::-4|rel_year::-3|rel_year::-2|rel_year::-1", rownames(es_coefs)), ]
print(pre_coefs)

# Pre-trend F-test: joint test that all pre-treatment coefficients = 0
pre_vars <- grep("rel_year::-[2-4]", rownames(es_coefs), value = TRUE)
if (length(pre_vars) >= 2) {
  cat("\nPre-trend joint F-test:\n")
  pre_test <- wald(fit_es, keep = pre_vars)
  print(pre_test)
}

## ============================================================
## 5b. Dose-Response by SALT Quintile
## ============================================================
cat("\n=== Dose-Response by Quintile ===\n")

for (q in paste0("Q", 2:5)) {
  tcja_panel[, paste0("post_", q) := as.integer(post_tcja == 1 & salt_quintile == q)]
}

fit_quintile <- feols(log_zhvi ~ post_Q2 + post_Q3 + post_Q4 + post_Q5 | zip_id + ym,
                       data = tcja_panel,
                       cluster = ~state_fips)

cat("Quintile effects (Q1 = lowest SALT = reference):\n")
print(coeftable(fit_quintile))

## ============================================================
## 6. Save results and diagnostics
## ============================================================
cat("\n=== Saving results ===\n")

# Save compact summaries (full model objects too large for disk)
results_list <- list(
  tcja_1 = list(coef = coef(fit_tcja_1), se = se(fit_tcja_1), pval = pvalue(fit_tcja_1), nobs = fit_tcja_1$nobs),
  tcja_2 = list(coef = coef(fit_tcja_2), se = se(fit_tcja_2), pval = pvalue(fit_tcja_2), nobs = fit_tcja_2$nobs),
  tcja_3 = list(coef = coef(fit_tcja_3), se = se(fit_tcja_3), pval = pvalue(fit_tcja_3), nobs = fit_tcja_3$nobs),
  tcja_4 = list(coef = coef(fit_tcja_4), se = se(fit_tcja_4), pval = pvalue(fit_tcja_4), nobs = fit_tcja_4$nobs),
  obbb_1 = list(coef = coef(fit_obbb_1), se = se(fit_obbb_1), pval = pvalue(fit_obbb_1), nobs = fit_obbb_1$nobs),
  obbb_2 = list(coef = coef(fit_obbb_2), se = se(fit_obbb_2), pval = pvalue(fit_obbb_2), nobs = fit_obbb_2$nobs),
  obbb_3 = list(coef = coef(fit_obbb_3), se = se(fit_obbb_3), pval = pvalue(fit_obbb_3), nobs = fit_obbb_3$nobs),
  obbb_4 = list(coef = coef(fit_obbb_4), se = se(fit_obbb_4), pval = pvalue(fit_obbb_4), nobs = fit_obbb_4$nobs),
  sym = list(coef = coef(fit_sym), se = se(fit_sym), pval = pvalue(fit_sym), nobs = fit_sym$nobs, vcov = vcov(fit_sym)),
  es = list(coeftable = coeftable(fit_es), nobs = fit_es$nobs),
  quintile = list(coef = coef(fit_quintile), se = se(fit_quintile), pval = pvalue(fit_quintile), nobs = fit_quintile$nobs)
)
saveRDS(results_list, file.path(data_dir, "main_results.rds"))

# Also save sd_y and sd_x for SDE table
sd_y <- sd(panel$log_zhvi, na.rm = TRUE)
sd_x <- sd(panel$salt_exposure, na.rm = TRUE)
saveRDS(list(sd_y = sd_y, sd_x = sd_x), file.path(data_dir, "panel_sds.rds"))

# Write diagnostics.json
n_treated <- length(unique(panel$zip5[panel$above_cap == 1]))
n_control <- length(unique(panel$zip5[panel$above_cap == 0]))
n_pre <- length(unique(panel$ym[panel$date < as.Date("2018-01-01")]))
n_obs <- nrow(panel)

diagnostics <- list(
  n_treated = n_treated,
  n_control = n_control,
  n_pre = n_pre,
  n_obs = n_obs,
  tcja_coef = round(coef(fit_tcja_1)["treat_tcja"], 6),
  tcja_se = round(se(fit_tcja_1)["treat_tcja"], 6),
  tcja_pval = round(pvalue(fit_tcja_1)["treat_tcja"], 6),
  obbb_coef = round(coef(fit_obbb_1)["treat_obbb"], 6),
  obbb_se = round(se(fit_obbb_1)["treat_obbb"], 6)
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                      auto_unbox = TRUE, pretty = TRUE)

cat("Diagnostics written to data/diagnostics.json\n")
cat("  Treated zip codes (above $10K cap):", n_treated, "\n")
cat("  Control zip codes (below $10K cap):", n_control, "\n")
cat("  Pre-TCJA periods:", n_pre, "\n")
cat("  Total observations:", format(n_obs, big.mark = ","), "\n")
