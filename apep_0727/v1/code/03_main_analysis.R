## 03_main_analysis.R — Kleven-Waseem Bunching Estimation
## apep_0727: German Solar PV Bunching at 10 kWp Threshold

source("00_packages.R")

cat("Loading cleaned data...\n")
dt <- fread("../data/solar_clean.csv")
bin_counts_period <- fread("../data/bin_counts_period.csv")
bin_counts_year <- fread("../data/bin_counts_year.csv")

# ============================================================
# Kleven-Waseem Bunching Estimator
# ============================================================

bunching_estimate <- function(bin_data, kink_point = 10.0,
                               bin_width = 0.1,
                               excl_lower = 9.0, excl_upper = 11.0,
                               window_lower = 3.0, window_upper = 20.0,
                               poly_degree = 7,
                               period_col = NULL) {
  # bin_data: data.table with columns bin_01, count
  # Returns: list with excess bunching mass, counterfactual, elasticity

  # Filter to estimation window
  bd <- bin_data[bin_01 >= window_lower & bin_01 < window_upper]

  # Mark exclusion zone (bunching region)
  bd[, excluded := bin_01 >= excl_lower & bin_01 < excl_upper]

  # Number of bins
  n_excl <- sum(bd$excluded)

  # Fit polynomial counterfactual on non-excluded bins
  bd[, z := bin_01 - kink_point]  # Center at kink

  # Create polynomial terms
  for (p in 1:poly_degree) {
    bd[, paste0("z", p) := z^p]
  }

  # Regression: count ~ polynomial(z) + dummy for above-kink shift, excluding bunching zone
  formula_str <- paste0("count ~ ", paste(paste0("z", 1:poly_degree), collapse = " + "))
  fit <- lm(as.formula(formula_str), data = bd[excluded == FALSE])

  # Predict counterfactual for all bins (including excluded)
  bd[, counterfactual := predict(fit, newdata = bd)]
  bd[counterfactual < 0, counterfactual := 0]  # Floor at zero

  # Excess bunching mass = sum of (observed - counterfactual) in exclusion zone
  excess_zone <- bd[excluded == TRUE]
  excess_mass <- sum(excess_zone$count - excess_zone$counterfactual)

  # Bunching ratio b = B / f0 where f0 = counterfactual density at kink
  f0 <- bd[bin_01 == floor(kink_point * 10) / 10, counterfactual]
  if (length(f0) == 0 || f0 <= 0) f0 <- mean(bd[excluded == FALSE]$counterfactual)
  bunching_ratio <- excess_mass / f0

  # Missing mass above kink
  above_kink <- bd[bin_01 >= kink_point & bin_01 < excl_upper]
  missing_mass <- sum(above_kink$counterfactual - above_kink$count)

  # Normalized bunching b = B / (N_excl * f0)
  b_normalized <- excess_mass / (n_excl * f0)

  # Behavioral elasticity (for a notch/kink):
  # For kink: e = b / (dlog_tax), where dlog_tax = log change in net-of-tax rate
  # EEG surcharge ~6.7 c/kWh on ~30% self-consumption of ~1000 kWh/kWp
  # For 10 kWp: surcharge cost ~ 0.067 * 0.3 * 10000 = 201 EUR/year
  # Over 20-year FIT: NPV ~ 201 * 14 (discount factor) = 2,814 EUR
  # System cost ~10kWp * 1,200 EUR/kWp = 12,000 EUR
  # Effective tax rate at notch: 2,814 / 12,000 = 23.5%
  # delta_log = -log(1 - 0.235) = 0.268
  delta_log_tax <- 0.268  # Approximate log change at kink
  elasticity <- bunching_ratio / (delta_log_tax / bin_width)

  list(
    excess_mass = excess_mass,
    missing_mass = missing_mass,
    bunching_ratio = bunching_ratio,
    b_normalized = b_normalized,
    f0 = f0,
    elasticity = elasticity,
    n_bins_excluded = n_excl,
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
  # Resample installations with replacement, re-bin, re-estimate
  dt_sub <- dt_raw[capacity_kwp >= window_lower & capacity_kwp < window_upper]
  if (!is.null(period_filter)) {
    dt_sub <- dt_sub[period == period_filter]
  }

  N <- nrow(dt_sub)
  results <- numeric(n_boot)
  elasticities <- numeric(n_boot)

  for (b in 1:n_boot) {
    # Resample
    idx <- sample.int(N, N, replace = TRUE)
    boot_dt <- dt_sub[idx]

    # Re-bin
    boot_bins <- boot_dt[, .(count = .N), by = .(bin_01 = floor(capacity_kwp * 10) / 10)]

    # Ensure all bins present
    all_bins <- data.table(bin_01 = seq(window_lower, window_upper - 0.1, by = 0.1))
    boot_bins <- merge(all_bins, boot_bins, by = "bin_01", all.x = TRUE)
    boot_bins[is.na(count), count := 0]

    # Estimate
    est <- tryCatch(
      bunching_estimate(boot_bins, kink_point = kink_point,
                        excl_lower = excl_lower, excl_upper = excl_upper,
                        window_lower = window_lower, window_upper = window_upper,
                        poly_degree = poly_degree),
      error = function(e) NULL
    )

    if (!is.null(est)) {
      results[b] <- est$bunching_ratio
      elasticities[b] <- est$elasticity
    } else {
      results[b] <- NA
      elasticities[b] <- NA
    }
  }

  list(
    se_bunching = sd(results, na.rm = TRUE),
    se_elasticity = sd(elasticities, na.rm = TRUE),
    ci_lower_b = quantile(results, 0.025, na.rm = TRUE),
    ci_upper_b = quantile(results, 0.975, na.rm = TRUE),
    ci_lower_e = quantile(elasticities, 0.025, na.rm = TRUE),
    ci_upper_e = quantile(elasticities, 0.975, na.rm = TRUE)
  )
}

# ============================================================
# Main Estimates
# ============================================================

cat("\n========================================\n")
cat("BUNCHING ESTIMATION: POLICY PERIOD (2014-2018)\n")
cat("========================================\n")

# Construct bins for policy period
policy_bins <- dt[period == "policy", .(count = .N),
                  by = .(bin_01 = floor(capacity_kwp * 10) / 10)]
all_bins <- data.table(bin_01 = seq(3.0, 19.9, by = 0.1))
policy_bins <- merge(all_bins, policy_bins, by = "bin_01", all.x = TRUE)
policy_bins[is.na(count), count := 0]

est_policy <- bunching_estimate(policy_bins, kink_point = 10.0,
                                 excl_lower = 9.0, excl_upper = 11.0)

cat(sprintf("Excess mass:      %s installations\n", format(round(est_policy$excess_mass), big.mark = ",")))
cat(sprintf("Missing mass:     %s installations\n", format(round(est_policy$missing_mass), big.mark = ",")))
cat(sprintf("Bunching ratio:   %.2f\n", est_policy$bunching_ratio))
cat(sprintf("Normalized b:     %.3f\n", est_policy$b_normalized))
cat(sprintf("Counterfactual f0: %.1f\n", est_policy$f0))
cat(sprintf("Elasticity:       %.3f\n", est_policy$elasticity))

cat("\n========================================\n")
cat("BUNCHING ESTIMATION: PRE-POLICY PERIOD (2008-2013)\n")
cat("========================================\n")

pre_bins <- dt[period == "pre_policy", .(count = .N),
               by = .(bin_01 = floor(capacity_kwp * 10) / 10)]
pre_bins <- merge(all_bins, pre_bins, by = "bin_01", all.x = TRUE)
pre_bins[is.na(count), count := 0]

est_pre <- bunching_estimate(pre_bins, kink_point = 10.0,
                              excl_lower = 9.0, excl_upper = 11.0)

cat(sprintf("Excess mass:      %s installations\n", format(round(est_pre$excess_mass), big.mark = ",")))
cat(sprintf("Bunching ratio:   %.2f\n", est_pre$bunching_ratio))
cat(sprintf("Normalized b:     %.3f\n", est_pre$b_normalized))
cat(sprintf("Elasticity:       %.3f\n", est_pre$elasticity))

# ============================================================
# Difference-in-Bunching (DiB)
# ============================================================

cat("\n========================================\n")
cat("DIFFERENCE-IN-BUNCHING\n")
cat("========================================\n")

dib <- est_policy$bunching_ratio - est_pre$bunching_ratio
cat(sprintf("DiB (policy - pre): %.2f\n", dib))
cat(sprintf("Policy b:           %.2f\n", est_policy$bunching_ratio))
cat(sprintf("Pre-policy b:       %.2f\n", est_pre$bunching_ratio))

# ============================================================
# Bootstrap Standard Errors
# ============================================================

cat("\nComputing bootstrap SEs (200 replications)...\n")

set.seed(20260320)  # Reproducible

boot_policy <- bootstrap_bunching(dt, period_filter = "policy", n_boot = 200)
cat(sprintf("Policy: b = %.2f (SE = %.2f), e = %.3f (SE = %.3f)\n",
            est_policy$bunching_ratio, boot_policy$se_bunching,
            est_policy$elasticity, boot_policy$se_elasticity))
cat(sprintf("  95%% CI b: [%.2f, %.2f]\n", boot_policy$ci_lower_b, boot_policy$ci_upper_b))

boot_pre <- bootstrap_bunching(dt, period_filter = "pre_policy", n_boot = 200)
cat(sprintf("Pre-policy: b = %.2f (SE = %.2f), e = %.3f (SE = %.3f)\n",
            est_pre$bunching_ratio, boot_pre$se_bunching,
            est_pre$elasticity, boot_pre$se_elasticity))

# DiB SE (assuming independence across periods)
se_dib <- sqrt(boot_policy$se_bunching^2 + boot_pre$se_bunching^2)
cat(sprintf("DiB: %.2f (SE = %.2f), t = %.2f\n", dib, se_dib, dib / se_dib))

# ============================================================
# Annual Bunching Estimates (Event Study)
# ============================================================

cat("\n========================================\n")
cat("ANNUAL BUNCHING ESTIMATES\n")
cat("========================================\n")

annual_results <- list()
for (yr in 2008:2018) {
  yr_bins <- dt[year == yr, .(count = .N),
                by = .(bin_01 = floor(capacity_kwp * 10) / 10)]
  yr_bins <- merge(all_bins, yr_bins, by = "bin_01", all.x = TRUE)
  yr_bins[is.na(count), count := 0]

  est_yr <- tryCatch(
    bunching_estimate(yr_bins, kink_point = 10.0,
                      excl_lower = 9.0, excl_upper = 11.0),
    error = function(e) list(bunching_ratio = NA, elasticity = NA, excess_mass = NA)
  )

  annual_results[[as.character(yr)]] <- data.table(
    year = yr,
    bunching_ratio = est_yr$bunching_ratio,
    elasticity = est_yr$elasticity,
    excess_mass = est_yr$excess_mass,
    period = ifelse(yr < 2014, "pre_policy", "policy")
  )
  cat(sprintf("  %d: b = %.2f, e = %.3f, excess = %s\n",
              yr, est_yr$bunching_ratio, est_yr$elasticity,
              format(round(est_yr$excess_mass), big.mark = ",")))
}

annual_dt <- rbindlist(annual_results)
fwrite(annual_dt, "../data/annual_bunching.csv")

# ============================================================
# Save Results
# ============================================================

results <- list(
  policy = list(
    excess_mass = est_policy$excess_mass,
    missing_mass = est_policy$missing_mass,
    bunching_ratio = est_policy$bunching_ratio,
    b_normalized = est_policy$b_normalized,
    elasticity = est_policy$elasticity,
    se_bunching = boot_policy$se_bunching,
    se_elasticity = boot_policy$se_elasticity,
    ci_bunching = c(boot_policy$ci_lower_b, boot_policy$ci_upper_b),
    ci_elasticity = c(boot_policy$ci_lower_e, boot_policy$ci_upper_e)
  ),
  pre_policy = list(
    excess_mass = est_pre$excess_mass,
    bunching_ratio = est_pre$bunching_ratio,
    elasticity = est_pre$elasticity,
    se_bunching = boot_pre$se_bunching,
    se_elasticity = boot_pre$se_elasticity
  ),
  dib = list(
    estimate = dib,
    se = se_dib,
    t_stat = dib / se_dib
  )
)

write_json(results, "../data/main_results.json", auto_unbox = TRUE, digits = 6)
cat("\nMain results saved to data/main_results.json\n")

# ============================================================
# Diagnostics for validator
# ============================================================

diag <- list(
  n_treated = sum(dt$period == "policy"),
  n_pre = length(unique(dt[period == "pre_policy"]$year)),
  n_obs = nrow(dt)
)
write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat("Diagnostics saved.\n")
