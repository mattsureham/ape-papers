## bunching_utils.R — Bunching estimation function (Chetty et al. 2011 / Kleven & Waseem 2013)
## Shared by 03_main_analysis.R and 04_robustness.R

estimate_bunching <- function(data, threshold, bin_width = 5000,
                              window_below = 30000, window_above = 5000,
                              poly_degree = 7, bandwidth = 200000,
                              n_boot = 500) {
  # Create bin counts in bandwidth around threshold
  lower <- threshold - bandwidth
  upper <- threshold + bandwidth
  sub <- data[purchase_price >= lower & purchase_price <= upper]

  bins <- sub[, .(count = .N), by = .(bin = floor(purchase_price / bin_width) * bin_width)]
  bins <- bins[order(bin)]

  # Fill missing bins with zero
  all_bins <- data.table(bin = seq(lower, upper - bin_width, by = bin_width))
  bins <- merge(all_bins, bins, by = "bin", all.x = TRUE)
  bins[is.na(count), count := 0]

  # Bunching window: [threshold - window_below, threshold + window_above]
  bins[, in_window := bin >= (threshold - window_below) & bin <= (threshold + window_above)]
  bins[, bin_centered := (bin - threshold) / bin_width]

  # Fit polynomial on bins OUTSIDE the window
  outside <- bins[in_window == FALSE]

  if (nrow(outside) < poly_degree + 1) {
    return(list(b = NA, se = NA, excess = NA, counterfactual = NA,
                bins = bins, converged = FALSE))
  }

  # Polynomial regression for counterfactual density
  fit <- lm(count ~ poly(bin_centered, poly_degree, raw = TRUE), data = outside)

  # Predict counterfactual for ALL bins (including window)
  bins[, counterfactual := predict(fit, newdata = bins)]
  bins[counterfactual < 0, counterfactual := 0]

  # Excess mass in the bunching window
  window_bins <- bins[in_window == TRUE]
  excess <- sum(window_bins$count) - sum(window_bins$counterfactual)
  b <- excess / mean(window_bins$counterfactual)

  # Bootstrap SE
  boot_b <- numeric(n_boot)
  for (i in seq_len(n_boot)) {
    boot_data <- data[sample(.N, .N, replace = TRUE)]
    boot_bins <- boot_data[purchase_price >= lower & purchase_price <= upper,
                           .(count = .N), by = .(bin = floor(purchase_price / bin_width) * bin_width)]
    boot_bins <- merge(all_bins, boot_bins, by = "bin", all.x = TRUE)
    boot_bins[is.na(count), count := 0]
    boot_bins[, in_window := bin >= (threshold - window_below) & bin <= (threshold + window_above)]
    boot_bins[, bin_centered := (bin - threshold) / bin_width]

    boot_outside <- boot_bins[in_window == FALSE]
    if (nrow(boot_outside) < poly_degree + 1) { boot_b[i] <- NA; next }

    boot_fit <- tryCatch(
      lm(count ~ poly(bin_centered, poly_degree, raw = TRUE), data = boot_outside),
      error = function(e) NULL
    )
    if (is.null(boot_fit)) { boot_b[i] <- NA; next }

    boot_bins[, cf := predict(boot_fit, newdata = boot_bins)]
    boot_bins[cf < 0, cf := 0]

    boot_window <- boot_bins[in_window == TRUE]
    boot_excess <- sum(boot_window$count) - sum(boot_window$cf)
    boot_b[i] <- boot_excess / mean(boot_window$cf)
  }

  se <- sd(boot_b, na.rm = TRUE)

  list(b = b, se = se, excess = round(excess),
       counterfactual = sum(window_bins$counterfactual),
       observed = sum(window_bins$count),
       bins = bins, converged = TRUE)
}
