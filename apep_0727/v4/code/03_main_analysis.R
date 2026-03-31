## 03_main_analysis.R — Main Bunching Estimation (V4)
## apep_0727 v4: Unified estimator, missing mass, mass balance
##
## Uses 00_bunching_estimator.R for ALL estimates (integer bins, degree 7)

source("00_packages.R")
source("00_bunching_estimator.R")

cat("Loading analysis data...\n")
dt_10 <- fread("../data/solar_clean_10.csv")
dt_30 <- fread("../data/solar_clean_30.csv")

# Precompute integer bins
dt_10[, bin_int := as.integer(floor(capacity_kwp * 10))]
dt_30[, bin_int := as.integer(floor(capacity_kwp * 10))]

all_bins_10 <- data.table(bin_int = 30L:199L)
all_bins_30 <- data.table(bin_int = 200L:399L)

# ============================================================
# MAIN ESTIMATES: 10 kWp by Period (with missing mass)
# ============================================================

cat("\n", paste(rep("=", 60), collapse = ""), "\n")
cat("BUNCHING AT 10 kWp BY PERIOD (Rooftop Only)\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

periods <- c("1_pre_fit_tier", "2_fit_kink", "3_surcharge",
             "4a_threshold_raised", "4b_surcharge_abolished")
period_labels <- c("Pre-FIT (2008-2011)", "FIT Kink (2012-2013)",
                    "Surcharge (2014-2020)", "Threshold Raised (2021-2022)",
                    "Surcharge Abolished (2023-2024)")

# Handle the case where v3 used "4_post_reform" instead of split periods
if (!"4a_threshold_raised" %in% dt_10$period) {
  # Create split post-reform periods
  dt_10[period == "4_post_reform" & year %in% 2021:2022,
        period := "4a_threshold_raised"]
  dt_10[period == "4_post_reform" & year %in% 2023:2024,
        period := "4b_surcharge_abolished"]
}

set.seed(20260331)
period_results <- list()

for (i in seq_along(periods)) {
  p <- periods[i]
  cat(sprintf("\n--- %s ---\n", period_labels[i]))

  p_data <- dt_10[period == p]
  p_bins <- make_bins_int(p_data, all_bins_10)

  # Point estimate with missing mass
  est <- bunching_estimate_int(p_bins)

  # Bootstrap
  boot <- bootstrap_bunching_int(dt_10, n_boot = 500L,
                                  subset_expr = quote(period == p))

  n_inst <- nrow(p_data)
  cat(sprintf("  N installations:  %s\n", format(n_inst, big.mark = ",")))
  cat(sprintf("  Excess mass:      %s\n", format(round(est$excess_mass), big.mark = ",")))
  cat(sprintf("  Missing mass:     %s\n", format(round(est$missing_mass), big.mark = ",")))
  cat(sprintf("  Mass balance:     %.2f\n", est$mass_balance))
  cat(sprintf("  Bunching ratio:   %.1f (SE = %.1f)\n",
      est$bunching_ratio,
      ifelse(is.na(boot$se_bunching), NA, boot$se_bunching)))
  if (!is.na(boot$ci_lower)) {
    cat(sprintf("  95%% CI:           [%.1f, %.1f]\n", boot$ci_lower, boot$ci_upper))
  }

  period_results[[p]] <- data.table(
    period = p,
    period_label = period_labels[i],
    n_installations = n_inst,
    excess_mass = round(est$excess_mass),
    missing_mass = round(est$missing_mass),
    mass_balance = round(est$mass_balance, 3),
    missing_10_12 = round(est$missing_10_12),
    missing_10_13 = round(est$missing_10_13),
    bunching_ratio = round(est$bunching_ratio, 2),
    se = round(ifelse(is.na(boot$se_bunching), NA, boot$se_bunching), 2),
    ci_lower = round(ifelse(is.na(boot$ci_lower), NA, boot$ci_lower), 2),
    ci_upper = round(ifelse(is.na(boot$ci_upper), NA, boot$ci_upper), 2)
  )
}

period_dt <- rbindlist(period_results)
fwrite(period_dt, "../data/bunching_10_by_period.csv")

# Difference-in-bunching: surcharge vs pre-FIT
dib_surcharge <- period_dt[period == "3_surcharge", bunching_ratio] -
                 period_dt[period == "1_pre_fit_tier", bunching_ratio]
se_pre <- period_dt[period == "1_pre_fit_tier", se]
se_sur <- period_dt[period == "3_surcharge", se]
se_dib <- sqrt(se_sur^2 + se_pre^2)
cat(sprintf("\nDifference-in-Bunching (surcharge - pre): %.1f (SE = %.1f, t = %.1f)\n",
    dib_surcharge, se_dib, dib_surcharge / se_dib))

# ============================================================
# MISSING MASS ANALYSIS (Phase 3 of revision plan)
# ============================================================

cat("\n", paste(rep("=", 60), collapse = ""), "\n")
cat("MISSING MASS ANALYSIS\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Surcharge period: full missing-mass decomposition
sur_data <- dt_10[period == "3_surcharge"]
sur_bins <- make_bins_int(sur_data, all_bins_10)
sur_est <- bunching_estimate_int(sur_bins)

cat(sprintf("\nSurcharge period (2014-2020):\n"))
cat(sprintf("  Excess mass below 10 kWp:  %s installations\n",
    format(round(sur_est$excess_mass), big.mark = ",")))
cat(sprintf("  Missing mass [10, 11) kWp: %s installations\n",
    format(round(sur_est$missing_mass), big.mark = ",")))
cat(sprintf("  Missing mass [10, 12) kWp: %s installations\n",
    format(round(sur_est$missing_10_12), big.mark = ",")))
cat(sprintf("  Missing mass [10, 13) kWp: %s installations\n",
    format(round(sur_est$missing_10_13), big.mark = ",")))
cat(sprintf("  Mass balance (excess/missing [10,11)): %.2f\n",
    sur_est$mass_balance))

# Compare distributions above 10 kWp across periods
cat("\n--- Distribution comparison above 10 kWp ---\n")
for (p_name in c("1_pre_fit_tier", "3_surcharge", "4b_surcharge_abolished")) {
  p_data <- dt_10[period == p_name & capacity_kwp >= 10 & capacity_kwp < 13]
  n_above <- nrow(p_data)
  n_total <- dt_10[period == p_name, .N]
  share <- n_above / n_total * 100
  median_above <- if (n_above > 0) median(p_data$capacity_kwp) else NA
  cat(sprintf("  %s: %s systems in [10, 13) kWp (%.1f%% of total), median = %.1f kWp\n",
      p_name, format(n_above, big.mark = ","), share,
      ifelse(is.na(median_above), NA, median_above)))
}

# Save missing mass results
missing_mass_dt <- data.table(
  period = period_dt$period,
  period_label = period_dt$period_label,
  excess_mass = period_dt$excess_mass,
  missing_mass_10_11 = period_dt$missing_mass,
  missing_mass_10_12 = period_dt$missing_10_12,
  missing_mass_10_13 = period_dt$missing_10_13,
  mass_balance = period_dt$mass_balance
)
fwrite(missing_mass_dt, "../data/missing_mass.csv")

# Data-driven welfare: use empirical missing mass
# Average foregone capacity per bunched system
# = total missing mass (in kWp terms) / excess installations
# From [10, 12) missing mass: each unit is 0.1 kWp
sur_missing_kwp <- sur_est$missing_10_12 * 0.1  # missing mass in kWp-bin-units → kWp
avg_foregone <- sur_missing_kwp / sur_est$excess_mass
cat(sprintf("\nData-driven welfare (surcharge period):\n"))
cat(sprintf("  Missing mass [10, 12) in bin-units: %s\n",
    format(round(sur_est$missing_10_12), big.mark = ",")))
cat(sprintf("  Excess mass: %s installations\n",
    format(round(sur_est$excess_mass), big.mark = ",")))

# Actually: the missing_10_12 is the TOTAL missing installations in [10, 12)
# Each missing installation would have had capacity somewhere in [10, 12)
# The empirical counterfactual tells us WHERE they would have been
# We need the weighted average counterfactual capacity of missing systems
sur_bd <- sur_est$bin_data
above_10 <- sur_bd[bin_int >= 100L & bin_int < 120L]
above_10[, missing := counterfactual - count]
above_10[, kWp := bin_int / 10]
# Weighted average capacity of missing systems
total_missing_cap <- sum(above_10[missing > 0, missing * kWp])
total_missing_n <- sum(above_10[missing > 0, missing])
avg_counterfactual_cap <- if (total_missing_n > 0) total_missing_cap / total_missing_n else NA
cat(sprintf("  Average counterfactual capacity of missing systems: %.2f kWp\n",
    avg_counterfactual_cap))
cat(sprintf("  Average foregone capacity per bunched system: %.2f kWp\n",
    avg_counterfactual_cap - 9.9))

# Total foregone capacity
total_foregone_mw <- sur_est$excess_mass * (avg_counterfactual_cap - 9.9) / 1000
cat(sprintf("  Total foregone capacity: %.0f MW\n", total_foregone_mw))
cat(sprintf("  Foregone generation (1000 kWh/kWp): %.0f GWh/year\n",
    total_foregone_mw))
cat(sprintf("  Household equivalents (3500 kWh/yr): %s\n",
    format(round(total_foregone_mw * 1e6 / 3500), big.mark = ",")))

welfare_dt <- data.table(
  avg_counterfactual_cap = round(avg_counterfactual_cap, 2),
  avg_foregone_kwp = round(avg_counterfactual_cap - 9.9, 2),
  total_excess = round(sur_est$excess_mass),
  total_foregone_mw = round(total_foregone_mw),
  foregone_gwh_year = round(total_foregone_mw),
  household_equiv = round(total_foregone_mw * 1e6 / 3500)
)
fwrite(welfare_dt, "../data/welfare_estimates.csv")

# ============================================================
# ANNUAL EVENT STUDY at 10 kWp (point estimates only — SEs in 03b)
# ============================================================

cat("\n", paste(rep("=", 60), collapse = ""), "\n")
cat("ANNUAL BUNCHING AT 10 kWp (2008-2024)\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

annual_results <- list()
for (yr in 2008:2024) {
  yr_data <- dt_10[year == yr]
  yr_bins <- make_bins_int(yr_data, all_bins_10)

  est <- tryCatch(
    bunching_estimate_int(yr_bins),
    error = function(e) list(bunching_ratio = NA, excess_mass = NA,
                              missing_mass = NA, mass_balance = NA)
  )

  n99 <- yr_bins[bin_int == 99L, count]
  n101 <- yr_bins[bin_int == 101L, count]

  annual_results[[as.character(yr)]] <- data.table(
    year = yr,
    bunching_ratio = round(est$bunching_ratio, 2),
    excess_mass = round(est$excess_mass),
    missing_mass = round(est$missing_mass),
    mass_balance = round(est$mass_balance, 3),
    n_99 = n99,
    n_101 = n101,
    raw_ratio = round(n99 / max(n101, 1), 1)
  )
  cat(sprintf("  %d: b = %7.1f, mass_bal = %5.2f, 9.9/10.1 = %7.1f:1\n",
      yr, est$bunching_ratio,
      ifelse(is.na(est$mass_balance), NA, est$mass_balance),
      n99 / max(n101, 1)))
}

annual_dt <- rbindlist(annual_results)
fwrite(annual_dt, "../data/bunching_10_annual.csv")

# ============================================================
# SUPPLEMENTARY: 30 kWp by Period (appendix in v4)
# ============================================================

cat("\n", paste(rep("=", 60), collapse = ""), "\n")
cat("BUNCHING AT 30 kWp BY PERIOD (Appendix)\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

period_results_30 <- list()
for (i in seq_along(periods)) {
  p <- periods[i]
  p_data <- dt_30[period == p]
  # Handle split post-reform for 30 kWp too
  if (nrow(p_data) == 0 && p %in% c("4a_threshold_raised", "4b_surcharge_abolished")) {
    if (p == "4a_threshold_raised") {
      p_data <- dt_30[period == "4_post_reform" & year %in% 2021:2022]
    } else {
      p_data <- dt_30[period == "4_post_reform" & year %in% 2023:2024]
    }
  }

  p_bins <- make_bins_int(p_data, all_bins_30)

  est <- tryCatch(
    bunching_estimate_int(p_bins, kink_int = 300L,
                          excl_lower = 290L, excl_upper = 310L,
                          window_lower = 200L, window_upper = 399L),
    error = function(e) list(bunching_ratio = NA, excess_mass = NA)
  )

  n_period <- nrow(p_data)
  cat(sprintf("  %s: N = %s, b = %.1f\n",
      period_labels[i], format(n_period, big.mark = ","),
      ifelse(is.na(est$bunching_ratio), NA, est$bunching_ratio)))

  period_results_30[[p]] <- data.table(
    period = p,
    period_label = period_labels[i],
    n_installations = n_period,
    bunching_ratio = round(ifelse(is.na(est$bunching_ratio), NA,
                                   est$bunching_ratio), 2),
    excess_mass = round(ifelse(is.na(est$excess_mass), NA, est$excess_mass))
  )
}

period_30_dt <- rbindlist(period_results_30)
fwrite(period_30_dt, "../data/bunching_30_by_period.csv")

# ============================================================
# Save All Results
# ============================================================

results <- list(
  bunching_10_period = as.list(period_dt),
  bunching_10_annual = as.list(annual_dt),
  bunching_30_period = as.list(period_30_dt),
  missing_mass = as.list(missing_mass_dt),
  welfare = as.list(welfare_dt),
  dib_surcharge_vs_pre = list(
    estimate = dib_surcharge,
    se = se_dib,
    t_stat = dib_surcharge / se_dib
  )
)
write_json(results, "../data/main_results.json", auto_unbox = TRUE, digits = 4)

# Diagnostics
diag <- list(
  n_treated = dt_10[period == "3_surcharge", .N],
  n_pre = length(unique(dt_10[period %in% c("1_pre_fit_tier", "2_fit_kink")]$year)),
  n_obs = nrow(dt_10)
)
write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\nMain analysis complete. Results saved.\n")
