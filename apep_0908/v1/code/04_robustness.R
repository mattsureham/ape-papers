# 04_robustness.R — Robustness checks for bunching estimation
# 1. Polynomial order sensitivity (5, 7, 9)
# 2. Installation type heterogeneity (rooftop vs ground-mount)
# 3. Exclude round-number bunching placebo
# 4. Year-by-year event study at 10 and 30 kWp

source("00_packages.R")

cat("=== Robustness Checks ===\n")

solar <- fread("../data/solar_clean.csv")
binned <- fread("../data/binned_by_threshold_period.csv")
type_binned <- fread("../data/binned_by_type_threshold.csv")
year_binned <- fread("../data/binned_by_year_threshold.csv")

# Reuse bunching function from main analysis
estimate_bunching <- function(bins, threshold, bin_width,
                               poly_order = 7, n_boot = 200) {
  bw_window <- threshold * 0.15
  ew <- threshold * 0.12
  exclude_window <- c(threshold - ew, threshold + ew * 0.5)

  bins[, z := bin - threshold]
  bins[, z_norm := z / bin_width]
  bins[, excluded := bin >= exclude_window[1] & bin <= exclude_window[2]]

  fit_data <- bins[excluded == FALSE & count > 0]
  if (nrow(fit_data) < poly_order + 1) return(NULL)

  fit <- lm(count ~ poly(z_norm, poly_order, raw = TRUE), data = fit_data)
  bins[, counterfactual := pmax(0, predict(fit, newdata = bins))]

  excess_region <- bins[excluded == TRUE]
  B_hat <- sum(excess_region$count) - sum(excess_region$counterfactual)
  avg_cf <- max(1, mean(excess_region$counterfactual))
  b_hat <- B_hat / avg_cf

  boot_b <- numeric(n_boot)
  for (i in seq_len(n_boot)) {
    bins_boot <- copy(bins)
    bins_boot[, count := rpois(.N, count + 0.5)]
    fd <- bins_boot[excluded == FALSE & count > 0]
    if (nrow(fd) < poly_order + 1) next
    fb <- tryCatch(lm(count ~ poly(z_norm, poly_order, raw = TRUE), data = fd),
                   error = function(e) NULL)
    if (is.null(fb)) next
    bins_boot[, cf := pmax(0, predict(fb, newdata = bins_boot))]
    eb <- bins_boot[excluded == TRUE]
    B_b <- sum(eb$count) - sum(eb$cf)
    boot_b[i] <- B_b / max(1, mean(eb$cf))
  }

  list(threshold = threshold, b_hat = b_hat, se_b = sd(boot_b, na.rm = TRUE),
       B_hat = B_hat)
}

# ---------------------------------------------------------------
# 1. Polynomial order sensitivity
# ---------------------------------------------------------------
cat("\n--- Polynomial Order Sensitivity ---\n")
poly_results <- list()
for (order in c(5, 7, 9)) {
  for (thr in c(10, 30, 100, 750)) {
    bw <- ifelse(thr <= 100, 0.1, 1.0)
    bins <- binned[threshold == thr & period == "pooled"]
    res <- estimate_bunching(bins, thr, bw, poly_order = order, n_boot = 100)
    if (!is.null(res)) {
      poly_results[[paste(order, thr)]] <- data.table(
        poly_order = order, threshold = thr,
        b_hat = res$b_hat, se = res$se_b
      )
      cat(sprintf("  Order %d, %d kWp: b̂ = %.3f (SE = %.3f)\n",
                  order, thr, res$b_hat, res$se_b))
    }
  }
}
poly_tab <- rbindlist(poly_results)
fwrite(poly_tab, "../data/robustness_polynomial.csv")

# ---------------------------------------------------------------
# 2. Installation type heterogeneity
# ---------------------------------------------------------------
cat("\n--- Installation Type Heterogeneity ---\n")
type_results <- list()
for (itype in c("rooftop", "ground_mount")) {
  for (thr in c(10, 30, 100, 750)) {
    bw <- ifelse(thr <= 100, 0.1, 1.0)
    bins <- type_binned[threshold == thr & install_type == itype]
    if (nrow(bins) < 20) next
    res <- estimate_bunching(bins, thr, bw, n_boot = 100)
    if (!is.null(res)) {
      type_results[[paste(itype, thr)]] <- data.table(
        type = itype, threshold = thr,
        b_hat = res$b_hat, se = res$se_b
      )
      cat(sprintf("  %s, %d kWp: b̂ = %.3f (SE = %.3f)\n",
                  itype, thr, res$b_hat, res$se_b))
    }
  }
}
type_tab <- rbindlist(type_results)
fwrite(type_tab, "../data/robustness_type.csv")

# ---------------------------------------------------------------
# 3. Round-number placebo: check bunching at 5, 15, 20, 25, 50 kWp
# These are round numbers but NOT regulatory thresholds
# ---------------------------------------------------------------
cat("\n--- Round-Number Placebo ---\n")
placebo_thresholds <- c(5, 15, 20, 25, 50)
placebo_results <- list()

for (thr in placebo_thresholds) {
  bw <- 0.1
  # Create bins from scratch for placebo thresholds
  lower <- max(0.5, thr * 0.3)
  upper <- thr * 2.0
  sub <- solar[capacity_kw >= lower & capacity_kw <= upper]
  sub[, bin := floor(capacity_kw / bw) * bw]
  bins <- sub[, .(count = .N), by = bin]
  setorder(bins, bin)
  bins[, threshold := thr]
  bins[, bin_width := bw]

  res <- estimate_bunching(bins, thr, bw, n_boot = 100)
  if (!is.null(res)) {
    placebo_results[[as.character(thr)]] <- data.table(
      threshold = thr, regulatory = FALSE,
      b_hat = res$b_hat, se = res$se_b
    )
    cat(sprintf("  Placebo %d kWp: b̂ = %.3f (SE = %.3f)\n",
                thr, res$b_hat, res$se_b))
  }
}
placebo_tab <- rbindlist(placebo_results)
fwrite(placebo_tab, "../data/robustness_placebo.csv")

# ---------------------------------------------------------------
# 4. Year-by-year event study at 10 and 30 kWp
# ---------------------------------------------------------------
cat("\n--- Year-by-Year Event Study (10 & 30 kWp) ---\n")
yearly_results <- list()

for (thr in c(10, 30)) {
  bw <- 0.1
  for (yr in 2010:2024) {
    bins <- year_binned[threshold == thr & year == yr]
    if (nrow(bins) < 20) next
    res <- estimate_bunching(bins, thr, bw, n_boot = 100)
    if (!is.null(res)) {
      yearly_results[[paste(thr, yr)]] <- data.table(
        threshold = thr, year = yr,
        b_hat = res$b_hat, se = res$se_b
      )
      cat(sprintf("  %d kWp, %d: b̂ = %.3f (SE = %.3f)\n",
                  thr, yr, res$b_hat, res$se_b))
    }
  }
}
yearly_tab <- rbindlist(yearly_results)
fwrite(yearly_tab, "../data/robustness_yearly.csv")

cat("\nAll robustness checks complete.\n")
