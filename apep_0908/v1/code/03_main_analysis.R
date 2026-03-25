# 03_main_analysis.R — Multi-threshold bunching estimation
# Implements Kleven (2016) bunching estimator at 5 EEG thresholds

source("00_packages.R")

cat("=== Multi-Threshold Bunching Estimation ===\n")

binned <- fread("../data/binned_by_threshold_period.csv")
thresholds <- fread("../data/thresholds.csv")
solar <- fread("../data/solar_clean.csv")

# ---------------------------------------------------------------
# Bunching Estimation Function (Kleven 2016)
# ---------------------------------------------------------------

estimate_bunching <- function(bins, threshold, bin_width,
                               poly_order = 7,
                               bunching_window = NULL,
                               exclude_window = NULL,
                               n_boot = 500) {
  # Default bunching window: threshold ± 2*threshold*0.1
  if (is.null(bunching_window)) {
    bw <- threshold * 0.15
    bunching_window <- c(threshold - bw, threshold)
  }

  # Exclude window around notch (where we estimate excess mass)
  if (is.null(exclude_window)) {
    ew <- threshold * 0.12
    exclude_window <- c(threshold - ew, threshold + ew * 0.5)
  }

  # Normalize bins relative to threshold
  bins[, z := bin - threshold]
  bins[, z_norm := z / bin_width]

  # Identify excluded region
  bins[, excluded := bin >= exclude_window[1] & bin <= exclude_window[2]]

  # Fit polynomial to non-excluded bins
  fit_data <- bins[excluded == FALSE & count > 0]

  if (nrow(fit_data) < poly_order + 1) {
    warning("Insufficient non-excluded bins for polynomial fit")
    return(NULL)
  }

  # Polynomial fit
  fit <- lm(count ~ poly(z_norm, poly_order, raw = TRUE), data = fit_data)

  # Predict counterfactual for all bins
  bins[, counterfactual := predict(fit, newdata = bins)]
  bins[counterfactual < 0, counterfactual := 0]

  # Excess mass in bunching region
  excess_region <- bins[excluded == TRUE]
  B_hat <- sum(excess_region$count) - sum(excess_region$counterfactual)

  # Normalize by average counterfactual height in excluded region
  avg_counterfactual <- mean(excess_region$counterfactual)
  if (avg_counterfactual <= 0) avg_counterfactual <- 1

  b_hat <- B_hat / avg_counterfactual  # Normalized excess mass

  # Number of excluded bins
  n_excluded <- nrow(excess_region)

  # Bootstrap for standard errors
  boot_b <- numeric(n_boot)
  for (i in seq_len(n_boot)) {
    # Resample counts with Poisson perturbation
    bins_boot <- copy(bins)
    bins_boot[, count := rpois(.N, count + 0.5)]

    fit_boot_data <- bins_boot[excluded == FALSE & count > 0]
    if (nrow(fit_boot_data) < poly_order + 1) next

    fit_boot <- tryCatch(
      lm(count ~ poly(z_norm, poly_order, raw = TRUE), data = fit_boot_data),
      error = function(e) NULL
    )
    if (is.null(fit_boot)) next

    bins_boot[, cf_boot := predict(fit_boot, newdata = bins_boot)]
    bins_boot[cf_boot < 0, cf_boot := 0]

    exc_boot <- bins_boot[excluded == TRUE]
    B_boot <- sum(exc_boot$count) - sum(exc_boot$cf_boot)
    avg_cf_boot <- mean(exc_boot$cf_boot)
    if (avg_cf_boot <= 0) avg_cf_boot <- 1
    boot_b[i] <- B_boot / avg_cf_boot
  }

  se_b <- sd(boot_b, na.rm = TRUE)

  list(
    threshold = threshold,
    b_hat = b_hat,
    se_b = se_b,
    B_hat = B_hat,
    avg_counterfactual = avg_counterfactual,
    n_excluded = n_excluded,
    n_bins = nrow(bins),
    total_count = sum(bins$count),
    bins = bins  # Return for plotting/diagnostics
  )
}

# ---------------------------------------------------------------
# Estimate bunching at each threshold — POOLED
# ---------------------------------------------------------------

cat("\n--- Pooled Bunching Estimates ---\n")
pooled_results <- list()

for (i in seq_len(nrow(thresholds))) {
  thr <- thresholds$threshold_kw[i]
  bw <- ifelse(thr <= 100, 0.1, 1.0)

  cat(sprintf("\nThreshold: %d kWp (%s)\n", thr, thresholds$short_label[i]))

  bins <- binned[threshold == thr & period == "pooled"]

  res <- estimate_bunching(bins, thr, bw)

  if (!is.null(res)) {
    cat(sprintf("  Excess mass (b̂): %.3f (SE: %.3f)\n", res$b_hat, res$se_b))
    cat(sprintf("  Absolute excess (B̂): %s installations\n",
                format(round(res$B_hat), big.mark = ",")))
    cat(sprintf("  t-statistic: %.2f\n", res$b_hat / res$se_b))
    pooled_results[[thresholds$short_label[i]]] <- res
  }
}

# ---------------------------------------------------------------
# Estimate bunching by period (pre vs post 2021) — DIFF-IN-BUNCHING
# ---------------------------------------------------------------

cat("\n\n--- Difference-in-Bunching: Pre vs Post 2021 ---\n")

period_results <- list()

for (i in seq_len(nrow(thresholds))) {
  thr <- thresholds$threshold_kw[i]
  bw <- ifelse(thr <= 100, 0.1, 1.0)

  for (per in c("pre", "post")) {
    bins <- binned[threshold == thr & period == per]
    res <- estimate_bunching(bins, thr, bw, n_boot = 300)

    if (!is.null(res)) {
      res$period <- per
      period_results[[paste(thresholds$short_label[i], per)]] <- res
    }
  }
}

# Compute diff-in-bunching for each threshold
cat("\nDifference-in-bunching (post - pre):\n")
dib_results <- list()

for (label in thresholds$short_label) {
  pre_key <- paste(label, "pre")
  post_key <- paste(label, "post")

  if (pre_key %in% names(period_results) & post_key %in% names(period_results)) {
    pre_b <- period_results[[pre_key]]$b_hat
    post_b <- period_results[[post_key]]$b_hat
    pre_se <- period_results[[pre_key]]$se_b
    post_se <- period_results[[post_key]]$se_b

    diff <- post_b - pre_b
    se_diff <- sqrt(pre_se^2 + post_se^2)

    cat(sprintf("  %s: pre=%.3f, post=%.3f, diff=%.3f (SE=%.3f, t=%.2f)\n",
                label, pre_b, post_b, diff, se_diff, diff / se_diff))

    dib_results[[label]] <- list(
      threshold = label,
      pre_b = pre_b, post_b = post_b,
      diff = diff, se_diff = se_diff,
      pre_se = pre_se, post_se = post_se
    )
  }
}

# ---------------------------------------------------------------
# Key test: 10 kWp bunching should DECREASE post-2021
#           30 kWp bunching should INCREASE post-2021
#           40, 100, 750 should be UNCHANGED (placebos)
# ---------------------------------------------------------------

cat("\n\n=== KEY HYPOTHESIS TESTS ===\n")
cat("H1: 10 kWp bunching decreases post-2021 (threshold shifted up)\n")
if ("10kWp" %in% names(dib_results)) {
  d <- dib_results[["10kWp"]]
  cat(sprintf("  Δb = %.3f (SE = %.3f, t = %.2f) — %s\n",
              d$diff, d$se_diff, d$diff / d$se_diff,
              ifelse(d$diff < 0, "CONFIRMED", "NOT CONFIRMED")))
}

cat("\nH2: 30 kWp bunching increases post-2021 (new threshold)\n")
if ("30kWp" %in% names(dib_results)) {
  d <- dib_results[["30kWp"]]
  cat(sprintf("  Δb = %.3f (SE = %.3f, t = %.2f) — %s\n",
              d$diff, d$se_diff, d$diff / d$se_diff,
              ifelse(d$diff > 0, "CONFIRMED", "NOT CONFIRMED")))
}

cat("\nPlacebo thresholds (should be near zero):\n")
for (label in c("40kWp", "100kWp", "750kWp")) {
  if (label %in% names(dib_results)) {
    d <- dib_results[[label]]
    cat(sprintf("  %s: Δb = %.3f (SE = %.3f, t = %.2f)\n",
                label, d$diff, d$se_diff, d$diff / d$se_diff))
  }
}

# ---------------------------------------------------------------
# Welfare calculation: aggregate kWp "left on the roof"
# ---------------------------------------------------------------

cat("\n\n=== Welfare: Aggregate Capacity Lost to Strategic Undersizing ===\n")

total_kwp_lost <- 0
for (label in names(pooled_results)) {
  res <- pooled_results[[label]]
  thr <- res$threshold

  # Each bunching installation is on average missing_kw below counterfactual
  # Approximate: installations at threshold would average threshold * 1.05 absent regulation
  missing_per_unit <- thr * 0.05  # Conservative: 5% undersizing on average
  kwp_lost <- res$B_hat * missing_per_unit

  cat(sprintf("  %s: %s excess installations × %.1f kWp avg undersizing = %.0f MWp lost\n",
              label, format(round(res$B_hat), big.mark = ","),
              missing_per_unit, kwp_lost / 1000))
  total_kwp_lost <- total_kwp_lost + kwp_lost
}

cat(sprintf("\n  TOTAL capacity lost: %.0f MWp (%.2f GWp)\n",
            total_kwp_lost / 1000, total_kwp_lost / 1e6))

# ---------------------------------------------------------------
# Save results for tables
# ---------------------------------------------------------------

# Pooled results table
pooled_tab <- rbindlist(lapply(names(pooled_results), function(label) {
  r <- pooled_results[[label]]
  data.table(
    threshold = label,
    threshold_kw = r$threshold,
    b_hat = r$b_hat,
    se_b = r$se_b,
    B_hat = r$B_hat,
    total = r$total_count
  )
}))

# DiB results table
dib_tab <- rbindlist(lapply(names(dib_results), function(label) {
  d <- dib_results[[label]]
  data.table(
    threshold = label,
    pre_b = d$pre_b, pre_se = d$pre_se,
    post_b = d$post_b, post_se = d$post_se,
    diff = d$diff, se_diff = d$se_diff
  )
}))

fwrite(pooled_tab, "../data/pooled_bunching_results.csv")
fwrite(dib_tab, "../data/dib_results.csv")

# Save period-level results
period_tab <- rbindlist(lapply(names(period_results), function(key) {
  r <- period_results[[key]]
  data.table(
    threshold = r$threshold,
    period = r$period,
    b_hat = r$b_hat,
    se_b = r$se_b,
    B_hat = r$B_hat
  )
}))
fwrite(period_tab, "../data/period_bunching_results.csv")

# Write diagnostics.json
diag <- list(
  n_treated = sum(pooled_tab$B_hat > 0),
  n_pre = 5L,  # 5 thresholds as "pre" cross-sections
  n_obs = as.integer(sum(pooled_tab$total))
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\nAll results saved.\n")
