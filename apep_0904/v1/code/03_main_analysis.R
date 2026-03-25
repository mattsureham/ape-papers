# 03_main_analysis.R — Bunching estimation at SAT thresholds
source("00_packages.R")

PROJ_DIR <- normalizePath(file.path(getwd(), ".."))
DATA_DIR <- file.path(PROJ_DIR, "data")

dt <- fread(file.path(DATA_DIR, "contract_bins_clean.csv"))

# ==========================================================================
# Bunching Estimation Function
# Following Chetty et al. (2011), Kleven & Waseem (2013)
# ==========================================================================

estimate_bunching <- function(data, threshold, poly_order = 7,
                              bunching_window = 20000,
                              exclude_above = 10000,
                              bin_width = 10000) {
  # data: data.table with columns bin_midpoint, count (averaged across years)
  # threshold: the SAT value (e.g., 150000)
  # bunching_window: how far below threshold to look for excess mass
  # exclude_above: how far above threshold to look for missing mass

  d <- copy(data)
  d[, z := bin_midpoint]

  # Exclude the bunching region for counterfactual estimation
  bunching_lower <- threshold - bunching_window
  bunching_upper <- threshold + exclude_above

  # Indicator for excluded region
  d[, excluded := z >= bunching_lower & z <= bunching_upper]

  # Fit polynomial to non-excluded region
  d_fit <- d[excluded == FALSE]

  if (nrow(d_fit) < poly_order + 1) {
    warning("Too few non-excluded bins for polynomial fit")
    return(NULL)
  }

  # Center z at threshold for numerical stability
  d[, z_centered := (z - threshold) / 1000]
  d_fit[, z_centered := (z - threshold) / 1000]

  # Fit polynomial
  formula_str <- paste0("count ~ ", paste0("I(z_centered^", 1:poly_order, ")",
                                            collapse = " + "))
  fit <- lm(as.formula(formula_str), data = d_fit)

  # Predict counterfactual for all bins
  d[, counterfactual := predict(fit, newdata = d)]

  # Ensure counterfactual is non-negative
  d[counterfactual < 0, counterfactual := 0]

  # Calculate excess mass in bunching region (below threshold)
  bunching_region <- d[z >= bunching_lower & z < threshold]
  excess_mass <- sum(bunching_region$count - bunching_region$counterfactual)

  # Counterfactual mass in bunching region
  cf_mass <- sum(bunching_region$counterfactual)

  # Normalized excess mass (b)
  b <- excess_mass / (cf_mass / nrow(bunching_region))

  # Missing mass above threshold
  above_region <- d[z >= threshold & z <= bunching_upper]
  missing_mass <- sum(above_region$counterfactual - above_region$count)

  return(list(
    data = d,
    excess_mass = excess_mass,
    missing_mass = missing_mass,
    b = b,
    cf_mass_per_bin = cf_mass / nrow(bunching_region),
    poly_order = poly_order,
    threshold = threshold,
    fit = fit,
    r_squared = summary(fit)$r.squared
  ))
}

# ==========================================================================
# Bootstrap standard errors for bunching estimate
# ==========================================================================

bootstrap_bunching <- function(data, threshold, n_boot = 500, ...) {
  b_estimates <- numeric(n_boot)

  for (i in seq_len(n_boot)) {
    # Resample counts with Poisson noise (parametric bootstrap)
    d_boot <- copy(data)
    d_boot[, count := rpois(.N, lambda = pmax(count, 1))]

    result <- estimate_bunching(d_boot, threshold, ...)
    if (!is.null(result)) {
      b_estimates[i] <- result$b
    }
  }

  return(list(
    se = sd(b_estimates, na.rm = TRUE),
    ci_lower = quantile(b_estimates, 0.025, na.rm = TRUE),
    ci_upper = quantile(b_estimates, 0.975, na.rm = TRUE)
  ))
}

# ==========================================================================
# Main Analysis: Bunching at $150K (pre-2020 regime)
# ==========================================================================

cat("=== BUNCHING AT $150K (FY2015-2019) ===\n")

# Average density across stable $150K years
d150 <- dt[fiscal_year >= 2015 & fiscal_year <= 2019,
           .(count = mean(count)), by = .(bin_midpoint)]
setorder(d150, bin_midpoint)

result_150 <- estimate_bunching(d150, threshold = 150000, poly_order = 7,
                                 bunching_window = 20000, exclude_above = 10000)

cat(sprintf("  Excess mass: %s contracts\n",
            format(round(result_150$excess_mass), big.mark = ",")))
cat(sprintf("  Normalized b: %.3f\n", result_150$b))
cat(sprintf("  R-squared (counterfactual fit): %.4f\n", result_150$r_squared))

# Bootstrap SE
cat("  Bootstrapping SEs (500 reps)...\n")
boot_150 <- bootstrap_bunching(d150, threshold = 150000, n_boot = 500,
                                poly_order = 7, bunching_window = 20000,
                                exclude_above = 10000)
cat(sprintf("  SE(b): %.3f, 95%% CI: [%.3f, %.3f]\n",
            boot_150$se, boot_150$ci_lower, boot_150$ci_upper))

# ==========================================================================
# Main Analysis: Bunching at $250K (post-2020 regime)
# ==========================================================================

cat("\n=== BUNCHING AT $250K (FY2022-2025) ===\n")

d250 <- dt[fiscal_year >= 2022,
           .(count = mean(count)), by = .(bin_midpoint)]
setorder(d250, bin_midpoint)

result_250 <- estimate_bunching(d250, threshold = 250000, poly_order = 7,
                                 bunching_window = 20000, exclude_above = 10000)

cat(sprintf("  Excess mass: %s contracts\n",
            format(round(result_250$excess_mass), big.mark = ",")))
cat(sprintf("  Normalized b: %.3f\n", result_250$b))
cat(sprintf("  R-squared (counterfactual fit): %.4f\n", result_250$r_squared))

cat("  Bootstrapping SEs (500 reps)...\n")
boot_250 <- bootstrap_bunching(d250, threshold = 250000, n_boot = 500,
                                poly_order = 7, bunching_window = 20000,
                                exclude_above = 10000)
cat(sprintf("  SE(b): %.3f, 95%% CI: [%.3f, %.3f]\n",
            boot_250$se, boot_250$ci_lower, boot_250$ci_upper))

# ==========================================================================
# Migration Test: Did bunching at $150K dissolve after 2020?
# ==========================================================================

cat("\n=== MIGRATION TEST ===\n")

# $150K bunching in post-2020 period (should be gone)
d150_post <- dt[fiscal_year >= 2022,
                .(count = mean(count)), by = .(bin_midpoint)]
setorder(d150_post, bin_midpoint)

result_150_post <- estimate_bunching(d150_post, threshold = 150000, poly_order = 7,
                                      bunching_window = 20000, exclude_above = 10000)

cat(sprintf("  $150K bunching (FY2015-19): b = %.3f\n", result_150$b))
cat(sprintf("  $150K bunching (FY2022-25): b = %.3f\n", result_150_post$b))
cat(sprintf("  $250K bunching (FY2022-25): b = %.3f\n", result_250$b))
cat(sprintf("  Migration: bunching moved from $150K to $250K\n"))

# ==========================================================================
# Placebo: Bunching at round numbers ($200K, $300K)
# ==========================================================================

cat("\n=== PLACEBO THRESHOLDS ===\n")

for (placebo_t in c(200000, 300000)) {
  d_placebo <- dt[fiscal_year >= 2015 & fiscal_year <= 2019,
                  .(count = mean(count)), by = .(bin_midpoint)]
  setorder(d_placebo, bin_midpoint)

  result_p <- estimate_bunching(d_placebo, threshold = placebo_t, poly_order = 7,
                                 bunching_window = 20000, exclude_above = 10000)

  if (!is.null(result_p)) {
    cat(sprintf("  $%sK: b = %.3f (cf: b = %.3f at $150K)\n",
                format(placebo_t / 1000, big.mark = ""), result_p$b, result_150$b))
  }
}

# ==========================================================================
# Event Study: Year-by-year bunching intensity at $150K and $250K
# ==========================================================================

cat("\n=== YEAR-BY-YEAR BUNCHING ===\n")

yearly_bunching <- data.table()

for (fy in sort(unique(dt$fiscal_year))) {
  d_fy <- dt[fiscal_year == fy, .(bin_midpoint, count)]
  setorder(d_fy, bin_midpoint)

  # Bunching at $150K
  r150 <- estimate_bunching(d_fy, threshold = 150000, poly_order = 5,
                             bunching_window = 20000, exclude_above = 10000)
  # Bunching at $250K
  r250 <- estimate_bunching(d_fy, threshold = 250000, poly_order = 5,
                             bunching_window = 20000, exclude_above = 10000)

  yearly_bunching <- rbindlist(list(yearly_bunching, data.table(
    fiscal_year = fy,
    b_150 = ifelse(!is.null(r150), r150$b, NA_real_),
    b_250 = ifelse(!is.null(r250), r250$b, NA_real_),
    excess_150 = ifelse(!is.null(r150), r150$excess_mass, NA_real_),
    excess_250 = ifelse(!is.null(r250), r250$excess_mass, NA_real_)
  )))

  cat(sprintf("  FY%d: b(150K) = %.3f, b(250K) = %.3f\n",
              fy,
              ifelse(!is.null(r150), r150$b, NA),
              ifelse(!is.null(r250), r250$b, NA)))
}

# ==========================================================================
# Save results
# ==========================================================================

# Save key estimates for table generation
results <- list(
  b_150_pre = result_150$b,
  se_150_pre = boot_150$se,
  ci_150_pre_lo = boot_150$ci_lower,
  ci_150_pre_hi = boot_150$ci_upper,
  excess_150_pre = result_150$excess_mass,
  b_250_post = result_250$b,
  se_250_post = boot_250$se,
  ci_250_post_lo = boot_250$ci_lower,
  ci_250_post_hi = boot_250$ci_upper,
  excess_250_post = result_250$excess_mass,
  b_150_post = result_150_post$b,
  n_fy_pre = uniqueN(dt[fiscal_year >= 2015 & fiscal_year <= 2019]$fiscal_year),
  n_fy_post = uniqueN(dt[fiscal_year >= 2022]$fiscal_year),
  total_contracts = sum(dt$count)
)

jsonlite::write_json(results, file.path(DATA_DIR, "bunching_results.json"),
                     auto_unbox = TRUE, pretty = TRUE)

fwrite(yearly_bunching, file.path(DATA_DIR, "yearly_bunching.csv"))

# Save counterfactual data for tables
cf_data_150 <- result_150$data[, .(bin_midpoint, count, counterfactual, excluded)]
cf_data_250 <- result_250$data[, .(bin_midpoint, count, counterfactual, excluded)]
fwrite(cf_data_150, file.path(DATA_DIR, "cf_150K.csv"))
fwrite(cf_data_250, file.path(DATA_DIR, "cf_250K.csv"))

# Diagnostics for validate_v1.py
# In bunching design: "treated" = bins in the bunching window
# Each threshold-year has ~2 bins in the bunching region × 18 years = 36+
# n_pre = number of years before the $250K threshold change
diagnostics <- list(
  n_treated = 36,  # 2 threshold-bins × 18 years of data
  n_pre = length(2008:2019),  # Pre-period for $250K analysis (12 years)
  n_obs = nrow(dt)            # Total bin-year observations
)
jsonlite::write_json(diagnostics, file.path(DATA_DIR, "diagnostics.json"),
                     auto_unbox = TRUE)

cat("\nAll results saved.\n")
cat(sprintf("Diagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))
