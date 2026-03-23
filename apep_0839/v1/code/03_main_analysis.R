# 03_main_analysis.R — Main regressions for TFP revision paper
# apep_0839: Thrifty Food Plan revision and food security

source("00_packages.R")

this_dir <- tryCatch(
  dirname(rstudioapi::getSourceEditorContext()$path),
  error = function(e) {
    args <- commandArgs(trailingOnly = FALSE)
    file_arg <- grep("--file=", args, value = TRUE)
    if (length(file_arg) > 0) dirname(sub("--file=", "", file_arg))
    else getwd()
  }
)
setwd(this_dir)

data_dir <- "../data/"
panel <- fread(paste0(data_dir, "analysis_panel.csv"))

cat("=== MAIN ANALYSIS: APEP_0839 ===\n\n")

# ═══════════════════════════════════════════════════════════════
# TABLE 1: Summary Statistics
# ═══════════════════════════════════════════════════════════════
cat("--- Table 1: Summary Statistics ---\n")

# Pre vs Post comparison
summ_pre <- panel[year <= 2019, .(
  snap_rate_mean = mean(snap_rate_pct, na.rm = TRUE),
  snap_rate_sd = sd(snap_rate_pct, na.rm = TRUE),
  poverty_rate_mean = mean(poverty_rate_pct, na.rm = TRUE),
  poverty_rate_sd = sd(poverty_rate_pct, na.rm = TRUE),
  median_income_mean = mean(median_hh_income, na.rm = TRUE),
  median_income_sd = sd(median_hh_income, na.rm = TRUE),
  unemp_mean = mean(unemp_rate, na.rm = TRUE),
  unemp_sd = sd(unemp_rate, na.rm = TRUE),
  N = .N
)]

summ_post <- panel[year >= 2022, .(
  snap_rate_mean = mean(snap_rate_pct, na.rm = TRUE),
  snap_rate_sd = sd(snap_rate_pct, na.rm = TRUE),
  poverty_rate_mean = mean(poverty_rate_pct, na.rm = TRUE),
  poverty_rate_sd = sd(poverty_rate_pct, na.rm = TRUE),
  median_income_mean = mean(median_hh_income, na.rm = TRUE),
  median_income_sd = sd(median_hh_income, na.rm = TRUE),
  unemp_mean = mean(unemp_rate, na.rm = TRUE),
  unemp_sd = sd(unemp_rate, na.rm = TRUE),
  N = .N
)]

cat(sprintf("  Pre-treatment (2017-2019): N=%d\n", summ_pre$N))
cat(sprintf("    SNAP rate: %.1f (%.1f)\n", summ_pre$snap_rate_mean, summ_pre$snap_rate_sd))
cat(sprintf("    Poverty rate: %.1f (%.1f)\n", summ_pre$poverty_rate_mean, summ_pre$poverty_rate_sd))
cat(sprintf("    Median HH income: $%.0f ($%.0f)\n", summ_pre$median_income_mean, summ_pre$median_income_sd))
cat(sprintf("    Unemployment: %.1f (%.1f)\n", summ_pre$unemp_mean, summ_pre$unemp_sd))

cat(sprintf("  Post-treatment (2022-2023): N=%d\n", summ_post$N))
cat(sprintf("    SNAP rate: %.1f (%.1f)\n", summ_post$snap_rate_mean, summ_post$snap_rate_sd))
cat(sprintf("    Poverty rate: %.1f (%.1f)\n", summ_post$poverty_rate_mean, summ_post$poverty_rate_sd))
cat(sprintf("    Median HH income: $%.0f ($%.0f)\n", summ_post$median_income_mean, summ_post$median_income_sd))
cat(sprintf("    Unemployment: %.1f (%.1f)\n", summ_post$unemp_mean, summ_post$unemp_sd))

# ═══════════════════════════════════════════════════════════════
# TABLE 2: Main DiD Results — Poverty Rate
# ═══════════════════════════════════════════════════════════════
cat("\n--- Table 2: Continuous DiD — Poverty Rate ---\n")

# Exclude 2021 (partial treatment year) for clean estimates
panel_clean <- panel[year != 2021]

# (1) Basic continuous DiD: Poverty ~ SNAPrate2019 × Post | state + year
m1 <- feols(poverty_rate_pct ~ treat_intensity | fips + year,
            data = panel_clean, cluster = ~fips)

# (2) Add unemployment control
m2 <- feols(poverty_rate_pct ~ treat_intensity + unemp_rate | fips + year,
            data = panel_clean, cluster = ~fips)

# (3) Population-weighted
m3 <- feols(poverty_rate_pct ~ treat_intensity | fips + year,
            data = panel_clean, cluster = ~fips,
            weights = ~population_2019)

# (4) Include 2021 (partial treatment) as separate regressor
m4 <- feols(poverty_rate_pct ~ treat_intensity + treat_intensity_partial | fips + year,
            data = panel, cluster = ~fips)

cat("\n  Model 1 (baseline): β =", round(coef(m1)["treat_intensity"], 3),
    ", SE =", round(se(m1)["treat_intensity"], 3), "\n")
cat("  Model 2 (+ unemp): β =", round(coef(m2)["treat_intensity"], 3),
    ", SE =", round(se(m2)["treat_intensity"], 3), "\n")
cat("  Model 3 (weighted): β =", round(coef(m3)["treat_intensity"], 3),
    ", SE =", round(se(m3)["treat_intensity"], 3), "\n")
cat("  Model 4 (inc. 2021): β =", round(coef(m4)["treat_intensity"], 3),
    ", SE =", round(se(m4)["treat_intensity"], 3), "\n")

# ═══════════════════════════════════════════════════════════════
# TABLE 3: Main DiD Results — SNAP Participation Rate
# ═══════════════════════════════════════════════════════════════
cat("\n--- Table 3: Continuous DiD — SNAP Participation ---\n")

# SNAP rate as outcome (take-up response)
m5 <- feols(snap_rate_pct ~ treat_intensity | fips + year,
            data = panel_clean, cluster = ~fips)

m6 <- feols(snap_rate_pct ~ treat_intensity + unemp_rate | fips + year,
            data = panel_clean, cluster = ~fips)

m7 <- feols(snap_rate_pct ~ treat_intensity | fips + year,
            data = panel_clean, cluster = ~fips,
            weights = ~population_2019)

cat("  Model 5 (baseline): β =", round(coef(m5)["treat_intensity"], 3),
    ", SE =", round(se(m5)["treat_intensity"], 3), "\n")
cat("  Model 6 (+ unemp): β =", round(coef(m6)["treat_intensity"], 3),
    ", SE =", round(se(m6)["treat_intensity"], 3), "\n")
cat("  Model 7 (weighted): β =", round(coef(m7)["treat_intensity"], 3),
    ", SE =", round(se(m7)["treat_intensity"], 3), "\n")

# ═══════════════════════════════════════════════════════════════
# TABLE 4: Triple-Difference (EA Timing)
# ═══════════════════════════════════════════════════════════════
cat("\n--- Table 4: Triple-Difference (EA Timing) ---\n")

# Triple-diff: Does the TFP effect differ by EA timing?
# States that ended EA early should show LARGER TFP effect on poverty
# because their residents actually experienced the new benefit level

m8 <- feols(poverty_rate_pct ~ treat_intensity + triple_diff | fips + year,
            data = panel_clean, cluster = ~fips)

m9 <- feols(poverty_rate_pct ~ treat_intensity + triple_diff + unemp_rate | fips + year,
            data = panel_clean, cluster = ~fips)

m10 <- feols(snap_rate_pct ~ treat_intensity + triple_diff | fips + year,
             data = panel_clean, cluster = ~fips)

cat("  Poverty triple-diff (β₂): ", round(coef(m8)["triple_diff"], 3),
    ", SE =", round(se(m8)["triple_diff"], 3), "\n")
cat("  Poverty triple-diff + controls (β₂): ", round(coef(m9)["triple_diff"], 3),
    ", SE =", round(se(m9)["triple_diff"], 3), "\n")
cat("  SNAP triple-diff (β₂): ", round(coef(m10)["triple_diff"], 3),
    ", SE =", round(se(m10)["triple_diff"], 3), "\n")

# ═══════════════════════════════════════════════════════════════
# EVENT STUDY (Pre-trend test)
# ═══════════════════════════════════════════════════════════════
cat("\n--- Event Study (Pre-trends) ---\n")

# Event study: interact dosage with year dummies (omit 2019)
es_pov <- feols(poverty_rate_pct ~ dose_yr_2014 + dose_yr_2015 + dose_yr_2016 +
                  dose_yr_2017 + dose_yr_2018 +
                  dose_yr_2021 + dose_yr_2022 + dose_yr_2023 | fips + year,
                data = panel, cluster = ~fips)

es_snap <- feols(snap_rate_pct ~ dose_yr_2014 + dose_yr_2015 + dose_yr_2016 +
                   dose_yr_2017 + dose_yr_2018 +
                   dose_yr_2021 + dose_yr_2022 + dose_yr_2023 | fips + year,
                 data = panel, cluster = ~fips)

cat("\n  Poverty event study coefficients:\n")
for (v in names(coef(es_pov))) {
  cat(sprintf("    %s: %.3f (%.3f)\n", v, coef(es_pov)[v], se(es_pov)[v]))
}

cat("\n  SNAP event study coefficients:\n")
for (v in names(coef(es_snap))) {
  cat(sprintf("    %s: %.3f (%.3f)\n", v, coef(es_snap)[v], se(es_snap)[v]))
}

# ═══════════════════════════════════════════════════════════════
# MEDIAN INCOME (Additional outcome)
# ═══════════════════════════════════════════════════════════════
cat("\n--- Additional: Log Median Household Income ---\n")

m_inc <- feols(ln_median_income ~ treat_intensity | fips + year,
               data = panel_clean, cluster = ~fips)

m_inc2 <- feols(ln_median_income ~ treat_intensity + unemp_rate | fips + year,
                data = panel_clean, cluster = ~fips)

cat("  Log income (baseline): β =", round(coef(m_inc)["treat_intensity"], 4),
    ", SE =", round(se(m_inc)["treat_intensity"], 4), "\n")
cat("  Log income (+ unemp): β =", round(coef(m_inc2)["treat_intensity"], 4),
    ", SE =", round(se(m_inc2)["treat_intensity"], 4), "\n")

# ═══════════════════════════════════════════════════════════════
# WILD CLUSTER BOOTSTRAP (small N robustness)
# ═══════════════════════════════════════════════════════════════
cat("\n--- Wild Cluster Bootstrap ---\n")

# With 51 clusters, standard cluster SEs are borderline
# Wild cluster bootstrap provides more reliable inference
boot_m1 <- boottest(m1, param = "treat_intensity", B = 9999,
                    clustid = "fips", type = "webb")
cat(sprintf("  Poverty baseline: WCB p-value = %.4f, CI = [%.3f, %.3f]\n",
            boot_m1$p_val, boot_m1$conf_int[1], boot_m1$conf_int[2]))

boot_m5 <- boottest(m5, param = "treat_intensity", B = 9999,
                    clustid = "fips", type = "webb")
cat(sprintf("  SNAP baseline: WCB p-value = %.4f, CI = [%.3f, %.3f]\n",
            boot_m5$p_val, boot_m5$conf_int[1], boot_m5$conf_int[2]))

# ═══════════════════════════════════════════════════════════════
# Save results for tables
# ═══════════════════════════════════════════════════════════════

# Save models for table generation
save(m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m_inc, m_inc2,
     es_pov, es_snap, boot_m1, boot_m5,
     summ_pre, summ_post,
     file = paste0(data_dir, "main_results.RData"))

# Write diagnostics.json for validate_v1
n_treated <- uniqueN(panel_clean[post_tfp == 1, fips])
n_pre <- length(unique(panel_clean[post_tfp == 0, year]))
n_obs <- nrow(panel_clean)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs
)

jsonlite::write_json(diagnostics, paste0(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated, n_pre, n_obs))

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
