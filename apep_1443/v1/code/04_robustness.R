## 04_robustness.R — Robustness checks for bunching estimates
source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"

pairs <- fread(file.path(data_dir, "repeat_sale_pairs.csv"))
pairs[, sale_date := as.Date(sale_date)]
pairs[, acq_date := as.Date(acq_date)]

results <- readRDS(file.path(data_dir, "bunching_results.rds"))

# Source the bunching function from 03
source("03_main_analysis.R")  # Loads bunching_estimate function

# ---- Robustness 1: Vary polynomial order ----
cat("\n=== Robustness: Polynomial Order Sensitivity ===\n")
tax2 <- pairs[tax_regime == "tax2"]
poly_robust <- list()

for (p in c(5, 6, 7, 8, 9)) {
  res <- bunching_estimate(tax2$holding_days, notch_day = 730,
                            bin_width = 7, window = 365, poly_order = p,
                            exclude_width = 60, n_boot = 100)
  cat(sprintf("  Poly %d: b = %.3f (SE = %.3f)\n", p, res$b, res$se))
  poly_robust[[as.character(p)]] <- list(b = res$b, se = res$se)
}
results[["robust_poly"]] <- poly_robust

# ---- Robustness 2: Vary bin width ----
cat("\n=== Robustness: Bin Width Sensitivity ===\n")
bin_robust <- list()
for (bw in c(5, 7, 10, 14)) {
  res <- bunching_estimate(tax2$holding_days, notch_day = 730,
                            bin_width = bw, window = 365, poly_order = 7,
                            exclude_width = 60, n_boot = 100)
  cat(sprintf("  Bin %d days: b = %.3f (SE = %.3f)\n", bw, res$b, res$se))
  bin_robust[[as.character(bw)]] <- list(b = res$b, se = res$se)
}
results[["robust_bin"]] <- bin_robust

# ---- Robustness 3: Vary exclusion window ----
cat("\n=== Robustness: Exclusion Window Sensitivity ===\n")
excl_robust <- list()
for (ew in c(30, 45, 60, 75, 90)) {
  res <- bunching_estimate(tax2$holding_days, notch_day = 730,
                            bin_width = 7, window = 365, poly_order = 7,
                            exclude_width = ew, n_boot = 100)
  cat(sprintf("  Exclude %d days: b = %.3f (SE = %.3f)\n", ew, res$b, res$se))
  excl_robust[[as.character(ew)]] <- list(b = res$b, se = res$se)
}
results[["robust_excl"]] <- excl_robust

# ---- Robustness 4: Donut RD around notch ----
cat("\n=== Donut RD: Excluding transactions within 14 days of notch ===\n")
if (nrow(tax2) > 200) {
  donut <- tax2[abs(holding_days - 730) > 14]
  res_donut <- bunching_estimate(donut$holding_days, notch_day = 730,
                                  bin_width = 7, window = 365, exclude_width = 60,
                                  n_boot = 100)
  cat(sprintf("  Donut b = %.3f (SE = %.3f)\n", res_donut$b, res_donut$se))
  results[["robust_donut"]] <- res_donut
}

# ---- Robustness 5: McCrary density test at notch ----
cat("\n=== McCrary-style Density Test ===\n")
if (nrow(tax2) > 200) {
  # Simple density discontinuity test
  near_notch <- tax2[holding_days >= 660 & holding_days <= 800]
  near_notch[, above := as.integer(holding_days >= 730)]
  near_notch[, centered := holding_days - 730]

  # Count transactions in bins
  near_notch[, bin := floor(centered / 7) * 7]
  bin_counts <- near_notch[, .N, by = .(bin, above)]

  # Test for discontinuity in density
  density_test <- feols(N ~ above + bin + above:bin, data = bin_counts)
  cat("Density discontinuity test:\n")
  print(summary(density_test))
  results[["density_test"]] <- density_test
}

# ---- Save updated results ----
saveRDS(results, file.path(data_dir, "bunching_results.rds"))
cat("\nRobustness results appended.\n")
