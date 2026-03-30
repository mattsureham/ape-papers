## 04_robustness.R — Robustness checks for bunching estimation

source("00_packages.R")

# --- Load data ---
payments <- readRDS("../data/payments_clean.rds")
bin_counts <- readRDS("../data/bin_counts.rds")
thresholds <- read.csv("../data/thresholds.csv")
results <- readRDS("../data/bunching_results.rds")

# Source the bunching estimator from main analysis
# (Redefined here for self-containedness)

estimate_bunching <- function(bin_data, threshold, bw_below = 3, bw_above = 3,
                              excl_below = 1.5, excl_above = 0.5,
                              poly_order = 7, n_boot = 200) {
  lower <- threshold - bw_below
  upper <- threshold + bw_above
  bd <- copy(bin_data[bin_25 >= lower & bin_25 <= upper])
  if (nrow(bd) < 10) return(list(b_normalized = NA, se = NA))
  bd[, z := bin_25 - threshold]
  bd[, excluded := z >= -excl_below & z <= excl_above]
  fit_data <- bd[excluded == FALSE]
  if (nrow(fit_data) < poly_order + 1) return(list(b_normalized = NA, se = NA))
  fit <- lm(count ~ poly(z, poly_order, raw = TRUE), data = fit_data)
  bd[, cf_count := predict(fit, newdata = .SD)]
  bunching_region <- bd[z >= -excl_below & z <= 0]
  B_hat <- sum(bunching_region$count) - sum(bunching_region$cf_count)
  cf_at_threshold <- predict(fit, newdata = data.table(z = 0))
  b_normalized <- B_hat / cf_at_threshold

  boot_b <- numeric(n_boot)
  for (i in 1:n_boot) {
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
  return(list(b_normalized = b_normalized, se = se))
}

# ============================================================
# 1. POLYNOMIAL ORDER SENSITIVITY
# ============================================================
cat("=== POLYNOMIAL ORDER SENSITIVITY ===\n")

pooled_bins <- readRDS("../data/pooled_bins.rds")
setDT(pooled_bins)

poly_sensitivity <- data.table()
for (p in c(5, 6, 7, 8, 9)) {
  est <- estimate_bunching(
    pooled_bins[, .(bin_25 = dist_bin, count)],
    threshold = 0,
    poly_order = p,
    n_boot = 100
  )
  poly_sensitivity <- rbind(poly_sensitivity, data.table(
    poly_order = p,
    b = est$b_normalized,
    se = est$se
  ))
  cat(sprintf("  Poly %d: b = %.3f (SE = %.3f)\n", p, est$b_normalized, est$se))
}

# ============================================================
# 2. BANDWIDTH SENSITIVITY
# ============================================================
cat("\n=== BANDWIDTH SENSITIVITY ===\n")

bw_sensitivity <- data.table()
for (bw in c(2, 3, 4, 5)) {
  est <- estimate_bunching(
    pooled_bins[, .(bin_25 = dist_bin, count)],
    threshold = 0,
    bw_below = bw,
    bw_above = bw,
    n_boot = 100
  )
  bw_sensitivity <- rbind(bw_sensitivity, data.table(
    bandwidth = bw,
    b = est$b_normalized,
    se = est$se
  ))
  cat(sprintf("  BW = $%.0f: b = %.3f (SE = %.3f)\n", bw, est$b_normalized, est$se))
}

# ============================================================
# 3. EXCLUSION REGION SENSITIVITY
# ============================================================
cat("\n=== EXCLUSION REGION SENSITIVITY ===\n")

excl_sensitivity <- data.table()
for (excl in c(0.5, 1.0, 1.5, 2.0)) {
  est <- estimate_bunching(
    pooled_bins[, .(bin_25 = dist_bin, count)],
    threshold = 0,
    excl_below = excl,
    excl_above = 0.5,
    n_boot = 100
  )
  excl_sensitivity <- rbind(excl_sensitivity, data.table(
    excl_below = excl,
    b = est$b_normalized,
    se = est$se
  ))
  cat(sprintf("  Excl [-$%.1f, $0.50]: b = %.3f (SE = %.3f)\n",
              excl, est$b_normalized, est$se))
}

# ============================================================
# 4. PLACEBO TEST: BUNCHING AT ROUND NUMBERS
# ============================================================
cat("\n=== PLACEBO: BUNCHING AT ROUND NUMBERS ===\n")

# Test for bunching at $5, $10, $15, $20 — none of these are thresholds
# We expect round-number heaping but NOT the asymmetric pattern of strategic bunching

placebo_results <- data.table()
for (placebo_thresh in c(5, 15, 20)) {
  est <- estimate_bunching(
    pooled_bins[, .(bin_25 = dist_bin + 0, count)],  # pooled is centered at 0
    threshold = placebo_thresh,  # this won't work well since data is centered at 0
    n_boot = 100
  )
  # Use raw bins instead
  raw_bins <- payments[, .(count = .N), by = .(bin_25)]
  est <- estimate_bunching(raw_bins, threshold = placebo_thresh, n_boot = 100)
  placebo_results <- rbind(placebo_results, data.table(
    placebo = placebo_thresh,
    b = est$b_normalized,
    se = est$se
  ))
  cat(sprintf("  Placebo at $%d: b = %.3f (SE = %.3f)\n",
              placebo_thresh,
              ifelse(is.na(est$b_normalized), NA, est$b_normalized),
              ifelse(is.na(est$se), NA, est$se)))
}

# ============================================================
# 5. PLACEBO: BUNCHING AT PRIOR-YEAR THRESHOLDS
# ============================================================
cat("\n=== PLACEBO: BUNCHING AT PRIOR-YEAR THRESHOLDS ===\n")

# In year t, test for bunching at year t-1 threshold (which is no longer relevant)
prior_year_placebo <- data.table()
years <- sort(unique(payments$program_year))

for (i in 2:length(years)) {
  yr <- years[i]
  prior_yr <- years[i - 1]

  current_threshold <- thresholds$threshold[thresholds$program_year == yr]
  prior_threshold <- thresholds$threshold[thresholds$program_year == prior_yr]

  # Only test if thresholds differ meaningfully
  if (abs(current_threshold - prior_threshold) < 0.20) next

  year_bins <- bin_counts[program_year == yr, .(bin_25, count)]
  est <- estimate_bunching(year_bins, threshold = prior_threshold, n_boot = 100)

  prior_year_placebo <- rbind(prior_year_placebo, data.table(
    year = yr,
    tested_at = prior_threshold,
    actual_threshold = current_threshold,
    b = est$b_normalized,
    se = est$se
  ))
  cat(sprintf("  %d tested at $%.2f (prior year; actual=$%.2f): b = %.3f\n",
              yr, prior_threshold, current_threshold,
              ifelse(is.na(est$b_normalized), NA, est$b_normalized)))
}

# ============================================================
# 6. BIN SIZE SENSITIVITY
# ============================================================
cat("\n=== BIN SIZE SENSITIVITY ===\n")

for (binw in c(0.10, 0.25, 0.50)) {
  custom_bins <- payments[, .(count = .N),
                          by = .(bin_25 = floor(dist_from_threshold / binw) * binw)]
  est <- estimate_bunching(custom_bins, threshold = 0, n_boot = 100)
  cat(sprintf("  Bin width $%.2f: b = %.3f (SE = %.3f)\n",
              binw, est$b_normalized, est$se))
}

# ============================================================
# SAVE ROBUSTNESS RESULTS
# ============================================================

robustness <- list(
  poly_sensitivity = poly_sensitivity,
  bw_sensitivity = bw_sensitivity,
  excl_sensitivity = excl_sensitivity,
  placebo_results = placebo_results,
  prior_year_placebo = prior_year_placebo
)

saveRDS(robustness, "../data/robustness_results.rds")
cat("\nRobustness results saved.\n")
