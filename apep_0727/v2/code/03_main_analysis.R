## 03_main_analysis.R — Kleven-Waseem Bunching Estimation (V2)
## apep_0727 v2: German Solar PV Bunching at 10 kWp Threshold
##
## Four-period analysis at 10 kWp + supplementary 30 kWp
## Annual event study 2008-2024

source("00_packages.R")

cat("Loading analysis data...\n")
dt_10 <- fread("../data/solar_clean_10.csv")
dt_30 <- fread("../data/solar_clean_30.csv")

# ============================================================
# Kleven-Waseem Bunching Estimator
# ============================================================

bunching_estimate <- function(bin_data, kink_point = 10.0,
                               bin_width = 0.1,
                               excl_lower = 9.0, excl_upper = 11.0,
                               window_lower = 3.0, window_upper = 20.0,
                               poly_degree = 7) {
  bd <- copy(bin_data[bin_01 >= window_lower & bin_01 < window_upper])
  bd[, excluded := bin_01 >= excl_lower & bin_01 < excl_upper]
  bd[, z := bin_01 - kink_point]

  for (p in 1:poly_degree) {
    bd[, paste0("z", p) := z^p]
  }

  formula_str <- paste0("count ~ ", paste(paste0("z", 1:poly_degree), collapse = " + "))
  fit <- lm(as.formula(formula_str), data = bd[excluded == FALSE])

  bd[, counterfactual := pmax(predict(fit, newdata = bd), 0)]

  excess_zone <- bd[excluded == TRUE]
  excess_mass <- sum(excess_zone$count - excess_zone$counterfactual)

  f0 <- bd[abs(bin_01 - kink_point) < 0.05, counterfactual][1]
  if (is.na(f0) || f0 <= 0) f0 <- mean(bd[excluded == FALSE]$counterfactual)
  bunching_ratio <- excess_mass / f0

  missing_mass <- sum(bd[bin_01 >= kink_point & bin_01 < excl_upper,
                          counterfactual - count])

  list(
    excess_mass = excess_mass,
    missing_mass = missing_mass,
    bunching_ratio = bunching_ratio,
    f0 = f0,
    poly_degree = poly_degree,
    excl_lower = excl_lower,
    excl_upper = excl_upper,
    bin_data = bd
  )
}

# ============================================================
# Bootstrap Standard Errors
# ============================================================

bootstrap_bunching <- function(dt_raw, kink_point = 10.0,
                                excl_lower = 9.0, excl_upper = 11.0,
                                window_lower = 3.0, window_upper = 20.0,
                                poly_degree = 7, n_boot = 200,
                                period_filter = NULL) {
  dt_sub <- dt_raw[capacity_kwp >= window_lower & capacity_kwp < window_upper]
  if (!is.null(period_filter)) {
    dt_sub <- dt_sub[period == period_filter]
  }

  N <- nrow(dt_sub)
  if (N < 1000) return(list(se_bunching = NA, ci_lower = NA, ci_upper = NA))

  results <- numeric(n_boot)
  all_bins <- data.table(bin_01 = seq(window_lower, window_upper - 0.1, by = 0.1))

  for (b in 1:n_boot) {
    idx <- sample.int(N, N, replace = TRUE)
    boot_dt <- dt_sub[idx]
    boot_bins <- boot_dt[, .(count = .N), by = .(bin_01 = floor(capacity_kwp * 10) / 10)]
    boot_bins <- merge(all_bins, boot_bins, by = "bin_01", all.x = TRUE)
    boot_bins[is.na(count), count := 0]

    est <- tryCatch(
      bunching_estimate(boot_bins, kink_point = kink_point,
                        excl_lower = excl_lower, excl_upper = excl_upper,
                        window_lower = window_lower, window_upper = window_upper,
                        poly_degree = poly_degree),
      error = function(e) NULL
    )
    results[b] <- if (!is.null(est)) est$bunching_ratio else NA
  }

  list(
    se_bunching = sd(results, na.rm = TRUE),
    ci_lower = quantile(results, 0.025, na.rm = TRUE),
    ci_upper = quantile(results, 0.975, na.rm = TRUE)
  )
}

# ============================================================
# MAIN ESTIMATES: 10 kWp by Period
# ============================================================

cat("\n", paste(rep("=", 60), collapse = ""), "\n")
cat("BUNCHING AT 10 kWp BY PERIOD (Rooftop Only)\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

periods <- c("1_pre_fit_tier", "2_fit_kink", "3_surcharge", "4_post_reform")
period_labels <- c("Pre-FIT (2008-2011)", "FIT Kink (2012-2013)",
                    "Surcharge (2014-2020)", "Post-Reform (2021-2024)")
all_bins_10 <- data.table(bin_01 = seq(3.0, 19.9, by = 0.1))

period_results <- list()
set.seed(20260328)

for (i in seq_along(periods)) {
  p <- periods[i]
  cat(sprintf("\n--- %s ---\n", period_labels[i]))

  p_bins <- dt_10[period == p, .(count = .N),
                   by = .(bin_01 = floor(capacity_kwp * 10) / 10)]
  p_bins <- merge(all_bins_10, p_bins, by = "bin_01", all.x = TRUE)
  p_bins[is.na(count), count := 0]

  est <- bunching_estimate(p_bins, kink_point = 10.0,
                            excl_lower = 9.0, excl_upper = 11.0)

  boot <- bootstrap_bunching(dt_10, period_filter = p, n_boot = 200)

  cat(sprintf("  N installations:  %s\n", format(dt_10[period == p, .N], big.mark = ",")))
  cat(sprintf("  Excess mass:      %s\n", format(round(est$excess_mass), big.mark = ",")))
  cat(sprintf("  Bunching ratio:   %.1f (SE = %.1f)\n", est$bunching_ratio,
      ifelse(is.na(boot$se_bunching), NA, boot$se_bunching)))
  if (!is.na(boot$ci_lower)) {
    cat(sprintf("  95%% CI:           [%.1f, %.1f]\n", boot$ci_lower, boot$ci_upper))
  }

  period_results[[p]] <- data.table(
    period = p,
    period_label = period_labels[i],
    n_installations = dt_10[period == p, .N],
    excess_mass = round(est$excess_mass),
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
# ANNUAL EVENT STUDY at 10 kWp
# ============================================================

cat("\n", paste(rep("=", 60), collapse = ""), "\n")
cat("ANNUAL BUNCHING AT 10 kWp (2008-2024)\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

annual_results <- list()
for (yr in 2008:2024) {
  yr_bins <- dt_10[year == yr, .(count = .N),
                    by = .(bin_01 = floor(capacity_kwp * 10) / 10)]
  yr_bins <- merge(all_bins_10, yr_bins, by = "bin_01", all.x = TRUE)
  yr_bins[is.na(count), count := 0]

  est <- tryCatch(
    bunching_estimate(yr_bins, kink_point = 10.0,
                      excl_lower = 9.0, excl_upper = 11.0),
    error = function(e) list(bunching_ratio = NA, excess_mass = NA)
  )

  n99 <- yr_bins[bin_01 == 9.9, count]
  n101 <- yr_bins[bin_01 == 10.1, count]

  annual_results[[as.character(yr)]] <- data.table(
    year = yr,
    bunching_ratio = round(est$bunching_ratio, 2),
    excess_mass = round(est$excess_mass),
    n_99 = n99,
    n_101 = n101,
    raw_ratio = round(n99 / max(n101, 1), 1)
  )
  cat(sprintf("  %d: b = %7.1f, 9.9/10.1 = %7.1f:1 (%s vs %s)\n",
      yr, est$bunching_ratio, n99 / max(n101, 1),
      format(n99, big.mark = ","), format(n101, big.mark = ",")))
}

annual_dt <- rbindlist(annual_results)
fwrite(annual_dt, "../data/bunching_10_annual.csv")

# ============================================================
# SUPPLEMENTARY: 30 kWp by Period
# ============================================================

cat("\n", paste(rep("=", 60), collapse = ""), "\n")
cat("BUNCHING AT 30 kWp BY PERIOD (Supplementary)\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

all_bins_30 <- data.table(bin_01 = seq(20.0, 39.9, by = 0.1))

period_results_30 <- list()
for (i in seq_along(periods)) {
  p <- periods[i]
  p_bins <- dt_30[period == p, .(count = .N),
                   by = .(bin_01 = floor(capacity_kwp * 10) / 10)]
  p_bins <- merge(all_bins_30, p_bins, by = "bin_01", all.x = TRUE)
  p_bins[is.na(count), count := 0]

  est <- tryCatch(
    bunching_estimate(p_bins, kink_point = 30.0,
                      excl_lower = 29.0, excl_upper = 31.0,
                      window_lower = 20.0, window_upper = 40.0),
    error = function(e) list(bunching_ratio = NA, excess_mass = NA)
  )

  n_period <- dt_30[period == p, .N]
  cat(sprintf("  %s: N = %s, b = %.1f\n",
      period_labels[i], format(n_period, big.mark = ","),
      ifelse(is.na(est$bunching_ratio), NA, est$bunching_ratio)))

  period_results_30[[p]] <- data.table(
    period = p,
    period_label = period_labels[i],
    n_installations = n_period,
    bunching_ratio = round(ifelse(is.na(est$bunching_ratio), NA, est$bunching_ratio), 2),
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
  dib_surcharge_vs_pre = list(
    estimate = dib_surcharge,
    se = se_dib,
    t_stat = dib_surcharge / se_dib
  )
)
write_json(results, "../data/main_results.json", auto_unbox = TRUE, digits = 4)

# Diagnostics for validator
diag <- list(
  n_treated = dt_10[period == "3_surcharge", .N],
  n_pre = length(unique(dt_10[period %in% c("1_pre_fit_tier", "2_fit_kink")]$year)),
  n_obs = nrow(dt_10)
)
write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\nMain analysis complete. Results saved.\n")
