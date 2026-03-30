## 04_robustness.R — Placebo tests, sensitivity checks, McCrary density

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"

panel <- fread(file.path(data_dir, "analysis_panel.csv"))

## -----------------------------------------------------------------------
## Helper: simplified bunching estimator (same as 03 but returns b_hat + SE)
## -----------------------------------------------------------------------

quick_bunch <- function(df, threshold, exclude_lo, exclude_hi,
                         bin_lo = 20, bin_hi = 100, poly_order = 7,
                         n_boot = 300) {
  hist_data <- df[total_beds >= bin_lo & total_beds <= bin_hi,
                   .N, by = total_beds]
  setnames(hist_data, c("beds", "count"))
  all_bins <- data.table(beds = bin_lo:bin_hi)
  hist_data <- merge(all_bins, hist_data, by = "beds", all.x = TRUE)
  hist_data[is.na(count), count := 0]
  hist_data[, excluded := beds >= exclude_lo & beds <= exclude_hi]

  fit_data <- hist_data[excluded == FALSE]
  if (nrow(fit_data) < poly_order + 1) return(list(b_hat = NA, se = NA, excess = NA))

  fit <- lm(count ~ poly(beds, poly_order, raw = TRUE), data = fit_data)
  hist_data[, cf := predict(fit, newdata = hist_data)]
  hist_data[cf < 0, cf := 0]

  bunch_region <- hist_data[beds >= exclude_lo & beds <= threshold]
  excess <- sum(bunch_region$count) - sum(bunch_region$cf)
  cf_thresh <- hist_data[beds == threshold, cf]
  b_hat <- ifelse(cf_thresh > 0, excess / cf_thresh, NA)

  # Bootstrap
  boot_b <- numeric(n_boot)
  pids <- unique(df$prvdr_num)
  np <- length(pids)
  for (i in 1:n_boot) {
    bids <- sample(pids, np, replace = TRUE)
    bdf <- df[prvdr_num %in% bids]
    bh <- bdf[total_beds >= bin_lo & total_beds <= bin_hi, .N, by = total_beds]
    setnames(bh, c("beds", "count"))
    bh <- merge(all_bins, bh, by = "beds", all.x = TRUE)
    bh[is.na(count), count := 0]
    bh[, excluded := beds >= exclude_lo & beds <= exclude_hi]
    bf <- tryCatch(
      lm(count ~ poly(beds, poly_order, raw = TRUE), data = bh[excluded == FALSE]),
      error = function(e) NULL
    )
    if (is.null(bf)) next
    bh[, cf := predict(bf, newdata = bh)]
    bh[cf < 0, cf := 0]
    br <- bh[beds >= exclude_lo & beds <= threshold]
    bex <- sum(br$count) - sum(br$cf)
    bcf <- bh[beds == threshold, cf]
    boot_b[i] <- ifelse(bcf > 0, bex / bcf, NA)
  }

  list(b_hat = b_hat, se = sd(boot_b, na.rm = TRUE), excess = excess)
}

## -----------------------------------------------------------------------
## 1. Placebo thresholds
## -----------------------------------------------------------------------

cat("=== PLACEBO TESTS ===\n")

placebos <- data.table()

# Placebo at 40 (round number, no regulatory significance)
cat("\nPlacebo at 40 beds:\n")
p40 <- quick_bunch(panel, threshold = 40, exclude_lo = 36, exclude_hi = 45)
cat(sprintf("  b̂ = %.3f (SE = %.3f)\n", p40$b_hat, p40$se))
placebos <- rbind(placebos, data.table(threshold = 40, b_hat = p40$b_hat, se = p40$se, type = "Placebo"))

# Placebo at 60 (round number, no regulatory significance)
cat("\nPlacebo at 60 beds:\n")
p60 <- quick_bunch(panel, threshold = 60, exclude_lo = 56, exclude_hi = 65)
cat(sprintf("  b̂ = %.3f (SE = %.3f)\n", p60$b_hat, p60$se))
placebos <- rbind(placebos, data.table(threshold = 60, b_hat = p60$b_hat, se = p60$se, type = "Placebo"))

# Placebo at 30
cat("\nPlacebo at 30 beds:\n")
p30 <- quick_bunch(panel, threshold = 30, exclude_lo = 26, exclude_hi = 35)
cat(sprintf("  b̂ = %.3f (SE = %.3f)\n", p30$b_hat, p30$se))
placebos <- rbind(placebos, data.table(threshold = 30, b_hat = p30$b_hat, se = p30$se, type = "Placebo"))

# Placebo at 75
cat("\nPlacebo at 75 beds:\n")
p75 <- quick_bunch(panel, threshold = 75, exclude_lo = 71, exclude_hi = 80)
cat(sprintf("  b̂ = %.3f (SE = %.3f)\n", p75$b_hat, p75$se))
placebos <- rbind(placebos, data.table(threshold = 75, b_hat = p75$b_hat, se = p75$se, type = "Placebo"))

# Actual threshold at 50
cat("\nActual threshold at 50 beds:\n")
p50 <- quick_bunch(panel, threshold = 50, exclude_lo = 46, exclude_hi = 55)
cat(sprintf("  b̂ = %.3f (SE = %.3f)\n", p50$b_hat, p50$se))
placebos <- rbind(placebos, data.table(threshold = 50, b_hat = p50$b_hat, se = p50$se, type = "Policy"))

fwrite(placebos, file.path(data_dir, "placebo_results.csv"))

## -----------------------------------------------------------------------
## 2. Sensitivity to polynomial order
## -----------------------------------------------------------------------

cat("\n=== POLYNOMIAL ORDER SENSITIVITY ===\n")

poly_sens <- data.table()
for (p in 5:9) {
  res <- quick_bunch(panel, threshold = 50, exclude_lo = 46, exclude_hi = 55,
                      poly_order = p, n_boot = 200)
  cat(sprintf("  Order %d: b̂ = %.3f (SE = %.3f)\n", p, res$b_hat, res$se))
  poly_sens <- rbind(poly_sens, data.table(poly_order = p, b_hat = res$b_hat, se = res$se))
}
fwrite(poly_sens, file.path(data_dir, "poly_sensitivity.csv"))

## -----------------------------------------------------------------------
## 3. Sensitivity to exclusion window
## -----------------------------------------------------------------------

cat("\n=== EXCLUSION WINDOW SENSITIVITY ===\n")

excl_sens <- data.table()
windows <- list(
  c(47, 53),  # narrow
  c(46, 54),  # moderate-narrow
  c(46, 55),  # baseline
  c(45, 56),  # moderate-wide
  c(44, 57)   # wide
)

for (w in windows) {
  res <- quick_bunch(panel, threshold = 50, exclude_lo = w[1], exclude_hi = w[2],
                      n_boot = 200)
  cat(sprintf("  Window [%d, %d]: b̂ = %.3f (SE = %.3f)\n",
              w[1], w[2], res$b_hat, res$se))
  excl_sens <- rbind(excl_sens, data.table(
    window = sprintf("[%d,%d]", w[1], w[2]),
    b_hat = res$b_hat, se = res$se
  ))
}
fwrite(excl_sens, file.path(data_dir, "window_sensitivity.csv"))

## -----------------------------------------------------------------------
## 4. McCrary-style density test
## -----------------------------------------------------------------------

cat("\n=== DENSITY DISCONTINUITY TEST ===\n")

# Simple McCrary test: log density ratio at the threshold
# Compare density just below (46-50) to density just above (51-55)
for (per in c("pre_bba", "post_bba", "all")) {
  sub <- if (per == "all") panel else panel[period == per]
  n_below <- nrow(sub[total_beds >= 46 & total_beds <= 50])
  n_above <- nrow(sub[total_beds >= 51 & total_beds <= 55])

  # Bins are same width (5 each), so density ratio = count ratio
  log_ratio <- log(n_below / n_above)
  se_log <- sqrt(1/n_below + 1/n_above)

  cat(sprintf("  %s: below=%d, above=%d, log-ratio=%.3f (SE=%.3f), z=%.2f\n",
              toupper(per), n_below, n_above, log_ratio, se_log, log_ratio/se_log))
}

## -----------------------------------------------------------------------
## 5. Round-number heaping test
## -----------------------------------------------------------------------

cat("\n=== ROUND NUMBER HEAPING CHECK ===\n")

# Check if the bunching at 50 is just round-number heaping
# Compare heaping at other round numbers (10, 20, 30, 40, 50, 60, 70, 80)
round_nums <- seq(20, 80, by = 10)
round_heap <- data.table()

for (rn in round_nums) {
  n_at <- nrow(panel[total_beds == rn])
  n_neighbors <- nrow(panel[total_beds %in% c(rn - 1, rn + 1)]) / 2
  heap_ratio <- ifelse(n_neighbors > 0, n_at / n_neighbors, Inf)
  cat(sprintf("  Beds=%d: N=%d, avg neighbors=%.1f, heap ratio=%.2f\n",
              rn, n_at, n_neighbors, heap_ratio))
  round_heap <- rbind(round_heap, data.table(
    beds = rn, count = n_at, avg_neighbors = n_neighbors, heap_ratio = heap_ratio
  ))
}

fwrite(round_heap, file.path(data_dir, "round_heaping.csv"))

# Key comparison: heaping at 50 vs other round numbers
heap_50 <- round_heap[beds == 50, heap_ratio]
heap_others <- round_heap[beds != 50 & beds != 100, mean(heap_ratio)]
cat(sprintf("\n  Heap ratio at 50: %.2f\n", heap_50))
cat(sprintf("  Avg heap ratio at other round numbers: %.2f\n", heap_others))
cat(sprintf("  50-bed heaping is %.1fx the round-number average\n", heap_50 / heap_others))

## -----------------------------------------------------------------------
## 6. Donut hole: exclude hospitals exactly at 50
## -----------------------------------------------------------------------

cat("\n=== DONUT HOLE TEST (exclude beds=50) ===\n")

panel_donut <- panel[total_beds != 50]
res_donut <- quick_bunch(panel_donut, threshold = 49, exclude_lo = 46, exclude_hi = 55,
                          n_boot = 200)
cat(sprintf("  b̂ at 49 (donut): %.3f (SE = %.3f)\n", res_donut$b_hat, res_donut$se))

cat("\n04_robustness.R complete.\n")
