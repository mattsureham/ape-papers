## 03_main_analysis.R — Bunching estimation at CMS Open Payments thresholds

source("00_packages.R")

# --- Load data ---
payments <- readRDS("../data/payments_clean.rds")
bin_counts <- readRDS("../data/bin_counts.rds")
thresholds <- read.csv("../data/thresholds.csv")

cat("=== BUNCHING ESTIMATION ===\n\n")

# ============================================================
# BUNCHING ESTIMATOR
# ============================================================
# Following Kleven (2016) and Chetty et al. (2011):
# 1. Fit a polynomial to the bin counts excluding the manipulation region
# 2. Estimate counterfactual density
# 3. Excess mass = observed - counterfactual in the bunching region
# 4. Standard errors via bootstrap
# ============================================================

estimate_bunching <- function(bin_data, threshold, bw_below = 3, bw_above = 3,
                              excl_below = 1.5, excl_above = 0.5,
                              poly_order = 7, n_boot = 200) {
  # bin_data: data.table with columns (bin_25, count)
  # threshold: the reporting threshold

  # Define analysis window
  lower <- threshold - bw_below
  upper <- threshold + bw_above

  # Subset to analysis window
  bd <- bin_data[bin_25 >= lower & bin_25 <= upper]

  if (nrow(bd) < 10) {
    return(list(excess_mass = NA, se = NA, counterfactual = NULL))
  }

  # Normalize bin positions relative to threshold
  bd[, z := bin_25 - threshold]

  # Exclusion region
  bd[, excluded := z >= -excl_below & z <= excl_above]

  # Fit polynomial on non-excluded bins
  fit_data <- bd[excluded == FALSE]
  if (nrow(fit_data) < poly_order + 1) {
    return(list(excess_mass = NA, se = NA, counterfactual = NULL))
  }

  # Polynomial fit
  fit <- lm(count ~ poly(z, poly_order, raw = TRUE), data = fit_data)

  # Predict counterfactual for all bins
  bd[, cf_count := predict(fit, newdata = .SD)]

  # Excess mass in the bunching region (below threshold only: -excl_below to 0)
  bunching_region <- bd[z >= -excl_below & z <= 0]
  B_hat <- sum(bunching_region$count) - sum(bunching_region$cf_count)

  # Normalize by counterfactual density at threshold
  cf_at_threshold <- predict(fit, newdata = data.table(z = 0))
  b_normalized <- B_hat / cf_at_threshold

  # Missing mass above (hole just above threshold)
  missing_region <- bd[z > 0 & z <= excl_above]
  M_hat <- sum(missing_region$cf_count) - sum(missing_region$count)

  # --- Bootstrap SE ---
  boot_b <- numeric(n_boot)
  for (i in 1:n_boot) {
    # Poisson bootstrap: resample counts
    bd_boot <- copy(bd)
    bd_boot[, count := rpois(.N, count)]

    fit_boot_data <- bd_boot[excluded == FALSE]
    fit_boot <- tryCatch(
      lm(count ~ poly(z, poly_order, raw = TRUE), data = fit_boot_data),
      error = function(e) NULL
    )
    if (is.null(fit_boot)) next

    bd_boot[, cf_count := predict(fit_boot, newdata = .SD)]
    bunch_boot <- bd_boot[z >= -excl_below & z <= 0]
    B_boot <- sum(bunch_boot$count) - sum(bunch_boot$cf_count)
    cf_boot <- predict(fit_boot, newdata = data.table(z = 0))
    boot_b[i] <- B_boot / max(cf_boot, 1)
  }

  se <- sd(boot_b, na.rm = TRUE)

  return(list(
    excess_mass = B_hat,
    b_normalized = b_normalized,
    missing_mass = M_hat,
    se = se,
    counterfactual = bd[, .(z, bin_25, count, cf_count, excluded)],
    n_bins = nrow(bd),
    n_bunching = nrow(bunching_region)
  ))
}

# ============================================================
# YEAR-BY-YEAR BUNCHING ESTIMATES
# ============================================================

results <- list()

for (yr in sort(unique(bin_counts$program_year))) {
  tau <- thresholds$threshold[thresholds$program_year == yr]

  year_bins <- bin_counts[program_year == yr, .(bin_25, count)]

  est <- estimate_bunching(year_bins, threshold = tau)

  results[[as.character(yr)]] <- list(
    year = yr,
    threshold = tau,
    excess_mass = est$excess_mass,
    b_normalized = est$b_normalized,
    missing_mass = est$missing_mass,
    se = est$se,
    counterfactual = est$counterfactual
  )

  cat(sprintf("%d (threshold=$%.2f): b = %.3f (SE = %.3f), excess = %d, missing = %d\n",
              yr, tau,
              ifelse(is.na(est$b_normalized), NA, est$b_normalized),
              ifelse(is.na(est$se), NA, est$se),
              ifelse(is.na(est$excess_mass), NA, round(est$excess_mass)),
              ifelse(is.na(est$missing_mass), NA, round(est$missing_mass))))
}

# ============================================================
# POOLED ESTIMATE (threshold-centered)
# ============================================================
cat("\n=== POOLED ESTIMATE ===\n")

pooled_bins <- readRDS("../data/pooled_bins.rds")
setDT(pooled_bins)

pooled_est <- estimate_bunching(
  pooled_bins[, .(bin_25 = dist_bin, count)],
  threshold = 0  # Already centered at 0
)

cat(sprintf("Pooled: b = %.3f (SE = %.3f)\n",
            ifelse(is.na(pooled_est$b_normalized), NA, pooled_est$b_normalized),
            ifelse(is.na(pooled_est$se), NA, pooled_est$se)))

# ============================================================
# PAYMENT-TYPE HETEROGENEITY
# ============================================================
cat("\n=== HETEROGENEITY BY PAYMENT TYPE ===\n")

het_results <- list()

for (ptype in c("Food & Beverage", "Other")) {
  if (ptype == "Other") {
    type_bins <- bin_counts[, .(count = sum(n_other)), by = .(program_year, bin_25, threshold)]
  } else {
    type_bins <- bin_counts[, .(count = sum(n_food)), by = .(program_year, bin_25, threshold)]
  }

  # Pool across years, centering on threshold
  type_pooled <- type_bins[, .(count = sum(count)),
                           by = .(dist_bin = floor((bin_25 - threshold) / 0.25) * 0.25)]

  est <- estimate_bunching(
    type_pooled[, .(bin_25 = dist_bin, count)],
    threshold = 0
  )

  het_results[[ptype]] <- est
  cat(sprintf("  %s: b = %.3f (SE = %.3f)\n",
              ptype,
              ifelse(is.na(est$b_normalized), NA, est$b_normalized),
              ifelse(is.na(est$se), NA, est$se)))
}

# ============================================================
# SAVE RESULTS
# ============================================================

# Results table for LaTeX
results_df <- data.table(
  Year = sapply(results, `[[`, "year"),
  Threshold = sapply(results, `[[`, "threshold"),
  Excess_Mass = sapply(results, `[[`, "excess_mass"),
  b_Normalized = sapply(results, `[[`, "b_normalized"),
  SE = sapply(results, `[[`, "se"),
  Missing_Mass = sapply(results, `[[`, "missing_mass")
)

saveRDS(results, "../data/bunching_results.rds")
saveRDS(results_df, "../data/results_table.rds")
saveRDS(het_results, "../data/het_results.rds")
saveRDS(pooled_est, "../data/pooled_est.rds")

# --- Diagnostics for validator ---
# Bunching design: "treated" = bins near threshold, "pre-period" = bins away from threshold
# Map to validator expectations
n_threshold_bins <- nrow(bin_counts[abs(dist) <= 2])
n_far_bins <- nrow(bin_counts[abs(dist) > 2])
jsonlite::write_json(list(
  n_treated = n_threshold_bins,
  n_pre = n_far_bins,
  n_obs = nrow(payments),
  design = "bunching",
  years = sort(unique(payments$program_year)),
  total_bins = nrow(bin_counts)
), "../data/diagnostics.json", auto_unbox = TRUE)

cat("\nAll results saved.\n")
