## 03_main_analysis.R — Bunching estimation at holding-period notches
source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# ---- Load repeat-sale pairs ----
pairs <- fread(file.path(data_dir, "repeat_sale_pairs.csv"))
cat(sprintf("Loaded %s repeat-sale pairs\n", format(nrow(pairs), big.mark = ",")))

# Convert dates
pairs[, sale_date := as.Date(sale_date)]
pairs[, acq_date := as.Date(acq_date)]

# ---- Bunching Estimation Functions ----

#' Estimate bunching at a notch using polynomial density estimation
#' @param holding_days Vector of holding periods in days
#' @param notch_day The notch threshold in days
#' @param bin_width Width of each bin in days
#' @param window Width of estimation window on each side (in days)
#' @param poly_order Polynomial order for counterfactual
#' @param exclude_width Width to exclude around notch (in days)
#' @param n_boot Number of bootstrap iterations
bunching_estimate <- function(holding_days, notch_day, bin_width = 7,
                               window = 365, poly_order = 7,
                               exclude_width = 60, n_boot = 200) {

  # Create bins
  min_day <- notch_day - window
  max_day <- notch_day + window
  subset_days <- holding_days[holding_days >= min_day & holding_days <= max_day]
  if (length(subset_days) < 20) {
    return(list(b = NA, se = NA, excess_mass = NA, bins = data.table()))
  }
  breaks <- seq(min_day, max_day + bin_width, by = bin_width)
  h <- hist(subset_days, breaks = breaks, plot = FALSE)
  bins <- data.table(
    bin_mid = h$mids,
    count = h$counts
  )
  bins[, relative_day := bin_mid - notch_day]
  bins[, excluded := abs(relative_day) <= exclude_width]

  # Fit polynomial to non-excluded region
  fit_data <- bins[excluded == FALSE]
  if (nrow(fit_data) < poly_order + 2) {
    return(list(b = NA, se = NA, excess_mass = NA, bins = bins))
  }

  fit <- lm(count ~ poly(relative_day, poly_order, raw = TRUE), data = fit_data)

  # Predict counterfactual for all bins
  bins[, counterfactual := predict(fit, newdata = .SD)]

  # Excess mass: observed - counterfactual in the bunching region (just above notch)
  above_notch <- bins[relative_day > 0 & relative_day <= exclude_width]
  below_notch <- bins[relative_day >= -exclude_width & relative_day < 0]

  excess_above <- sum(above_notch$count) - sum(above_notch$counterfactual)
  missing_below <- sum(below_notch$counterfactual) - sum(below_notch$count)

  # Normalized excess mass
  avg_counterfactual <- mean(bins$counterfactual[bins$counterfactual > 0])
  b_hat <- excess_above / avg_counterfactual

  # Bootstrap SE
  boot_b <- replicate(n_boot, {
    boot_idx <- sample(seq_along(holding_days), replace = TRUE)
    boot_days <- holding_days[boot_idx]
    boot_subset <- boot_days[boot_days >= min_day & boot_days <= max_day]
    boot_counts <- hist(boot_subset, breaks = breaks, plot = FALSE)$counts
    boot_bins <- copy(bins)
    boot_bins[, count := boot_counts]
    boot_fit_data <- boot_bins[excluded == FALSE]
    boot_fit <- tryCatch(
      lm(count ~ poly(relative_day, poly_order, raw = TRUE), data = boot_fit_data),
      error = function(e) NULL
    )
    if (is.null(boot_fit)) return(NA)
    boot_bins[, cf := predict(boot_fit, newdata = .SD)]
    boot_above <- boot_bins[relative_day > 0 & relative_day <= exclude_width]
    boot_excess <- sum(boot_above$count) - sum(boot_above$cf)
    boot_avg_cf <- mean(boot_bins$cf[boot_bins$cf > 0])
    boot_excess / boot_avg_cf
  })

  se_b <- sd(boot_b, na.rm = TRUE)

  list(
    b = b_hat,
    se = se_b,
    excess_mass = excess_above,
    missing_mass = missing_below,
    avg_counterfactual = avg_counterfactual,
    n_obs = sum(holding_days >= min_day & holding_days < max_day),
    bins = bins
  )
}

# ---- Main Bunching Estimates ----
cat("\n=== Bunching Estimation ===\n")

# Split by tax regime
tax2 <- pairs[tax_regime == "tax2"]
tax1 <- pairs[tax_regime == "tax1"]
exempt <- pairs[tax_regime == "exempt"]

cat(sprintf("Tax 2.0 (post-Jul 2021 acquisitions): %s pairs\n", format(nrow(tax2), big.mark = ",")))
cat(sprintf("Tax 1.0 (2016-Jun 2021 acquisitions): %s pairs\n", format(nrow(tax1), big.mark = ",")))
cat(sprintf("Exempt (pre-2016 acquisitions): %s pairs\n", format(nrow(exempt), big.mark = ",")))

results <- list()

# Tax 2.0: Bunching at 730 days (2-year notch)
cat("\n--- Tax 2.0: 2-year notch (730 days) ---\n")
if (nrow(tax2) > 100) {
  res_2yr <- bunching_estimate(tax2$holding_days, notch_day = 730,
                                bin_width = 7, window = 365, exclude_width = 60)
  cat(sprintf("  Excess mass b = %.3f (SE = %.3f)\n", res_2yr$b, res_2yr$se))
  cat(sprintf("  N in window: %d\n", res_2yr$n_obs))
  results[["tax2_2yr"]] <- res_2yr
} else {
  cat("  Insufficient observations for Tax 2.0 2-year analysis\n")
}

# Tax 2.0: Bunching at 1825 days (5-year notch)
cat("\n--- Tax 2.0: 5-year notch (1825 days) ---\n")
if (nrow(tax2) > 100) {
  res_5yr <- bunching_estimate(tax2$holding_days, notch_day = 1825,
                                bin_width = 14, window = 365, exclude_width = 90)
  cat(sprintf("  Excess mass b = %.3f (SE = %.3f)\n", res_5yr$b, res_5yr$se))
  results[["tax2_5yr"]] <- res_5yr
} else {
  cat("  Insufficient observations\n")
}

# Tax 1.0: Bunching at 365 days (1-year notch — the old threshold)
cat("\n--- Tax 1.0: 1-year notch (365 days) ---\n")
if (nrow(tax1) > 100) {
  res_1yr <- bunching_estimate(tax1$holding_days, notch_day = 365,
                                bin_width = 7, window = 180, exclude_width = 45)
  cat(sprintf("  Excess mass b = %.3f (SE = %.3f)\n", res_1yr$b, res_1yr$se))
  results[["tax1_1yr"]] <- res_1yr
}

# Tax 1.0: Bunching at 730 days (2-year notch under Tax 1.0)
cat("\n--- Tax 1.0: 2-year notch (730 days) ---\n")
if (nrow(tax1) > 100) {
  res_1_2yr <- bunching_estimate(tax1$holding_days, notch_day = 730,
                                  bin_width = 7, window = 365, exclude_width = 60)
  cat(sprintf("  Excess mass b = %.3f (SE = %.3f)\n", res_1_2yr$b, res_1_2yr$se))
  results[["tax1_2yr"]] <- res_1_2yr
}

# Placebo: Exempt properties (no notch expected)
cat("\n--- Placebo: Exempt properties at 730 days ---\n")
if (nrow(exempt) > 100) {
  res_placebo <- bunching_estimate(exempt$holding_days, notch_day = 730,
                                    bin_width = 7, window = 365, exclude_width = 60)
  cat(sprintf("  Excess mass b = %.3f (SE = %.3f)\n", res_placebo$b, res_placebo$se))
  results[["exempt_placebo"]] <- res_placebo
}

# ---- Heterogeneity: Price quartiles ----
cat("\n=== Heterogeneity by Price Quartile ===\n")

if (nrow(tax2) > 400) {
  tax2[, price_quartile := ntile(sale_price, 4)]

  hetero_results <- list()
  for (q in 1:4) {
    sub <- tax2[price_quartile == q]
    if (nrow(sub) > 50) {
      res <- bunching_estimate(sub$holding_days, notch_day = 730,
                                bin_width = 14, window = 365, exclude_width = 60,
                                n_boot = 100)
      cat(sprintf("  Q%d (N=%d): b = %.3f (SE = %.3f)\n", q, nrow(sub), res$b, res$se))
      hetero_results[[paste0("Q", q)]] <- res
    }
  }
  results[["hetero_price"]] <- hetero_results
}

# ---- Heterogeneity: Taipei vs other cities ----
cat("\n=== Heterogeneity: Taipei vs Rest ===\n")
if (nrow(tax2) > 200) {
  taipei <- tax2[grepl("(大安|信義|中正|松山|中山|內湖|南港|萬華|文山|士林|北投|大同)", district)]
  rest <- tax2[!grepl("(大安|信義|中正|松山|中山|內湖|南港|萬華|文山|士林|北投|大同)", district)]

  if (nrow(taipei) > 50) {
    res_taipei <- bunching_estimate(taipei$holding_days, notch_day = 730,
                                     bin_width = 14, window = 365, exclude_width = 60, n_boot = 100)
    cat(sprintf("  Taipei (N=%d): b = %.3f (SE = %.3f)\n", nrow(taipei), res_taipei$b, res_taipei$se))
    results[["taipei"]] <- res_taipei
  }
  if (nrow(rest) > 50) {
    res_rest <- bunching_estimate(rest$holding_days, notch_day = 730,
                                   bin_width = 14, window = 365, exclude_width = 60, n_boot = 100)
    cat(sprintf("  Rest (N=%d): b = %.3f (SE = %.3f)\n", nrow(rest), res_rest$b, res_rest$se))
    results[["rest"]] <- res_rest
  }
}

# ---- Price discontinuity at notch ----
cat("\n=== Price Discontinuity at 2-year Notch ===\n")
if (nrow(tax2) > 200) {
  # RD-style: price return as function of holding period near 730 days
  rd_data <- tax2[holding_days >= 600 & holding_days <= 860 & !is.na(price_return)]
  rd_data[, above_notch := as.integer(holding_days >= 730)]
  rd_data[, centered_days := holding_days - 730]

  if (nrow(rd_data) > 50) {
    rd_fit <- feols(price_return ~ above_notch + centered_days + above_notch:centered_days,
                    data = rd_data)
    cat("Price return discontinuity at 730 days:\n")
    print(summary(rd_fit))
    results[["price_rd"]] <- rd_fit
  }
}

# ---- Transaction volume time series ----
cat("\n=== Monthly Transaction Volume ===\n")
vol_monthly <- pairs[, .N, by = .(month = floor_date(sale_date, "month"))]
setorder(vol_monthly, month)
fwrite(vol_monthly, file.path(data_dir, "monthly_volume.csv"))

# ---- Save all results ----
saveRDS(results, file.path(data_dir, "bunching_results.rds"))
cat("\nResults saved to bunching_results.rds\n")

# ---- Write diagnostics.json ----
diag <- list(
  n_treated = nrow(tax2),
  n_pre = nrow(tax1) + nrow(exempt),
  n_obs = nrow(pairs)
)
jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("Diagnostics written.\n")
