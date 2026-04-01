## 04_robustness.R — Robustness checks and placebo tests
## apep_1281: Pricing to the Cap

source("00_packages.R")
source("bunching_utils.R")

dt <- fread("../data/analysis_sample.csv")
dt[, contract_date := as.Date(contract_date)]

## ====================================================================
## PLACEBO 1: Commercial / Farm properties (no FHB thresholds)
## ====================================================================
cat("\n=== PLACEBO: Commercial + Farm Transactions ===\n")
cat("  (Should show only round-number heaping, NOT policy bunching)\n\n")

dt_placebo <- dt[prop_type %in% c("commercial", "farm")]
cat("Placebo sample size:", nrow(dt_placebo), "\n")

placebo_results <- list()
for (th in c(600000, 800000, 1000000)) {
  cat(sprintf("  Placebo at $%s: ", formatC(th, format = "d", big.mark = ",")))
  if (nrow(dt_placebo[purchase_price >= (th - 200000) & purchase_price <= (th + 200000)]) < 100) {
    cat("insufficient data\n")
    placebo_results[[as.character(th)]] <- list(b = NA, se = NA, excess = NA)
    next
  }
  pr <- estimate_bunching(dt_placebo, threshold = th, n_boot = 200)
  placebo_results[[as.character(th)]] <- pr
  cat(sprintf("b = %.3f (SE = %.3f)\n", pr$b, pr$se))
}

## ====================================================================
## ROBUSTNESS 2: Polynomial degree sensitivity
## ====================================================================
cat("\n=== SENSITIVITY: Polynomial Degree ===\n\n")

dt_res <- dt[prop_type == "residential"]

poly_sensitivity <- list()
for (deg in c(5, 6, 7, 8, 9)) {
  cat(sprintf("  Degree %d: ", deg))
  res <- estimate_bunching(dt_res, threshold = 800000, poly_degree = deg, n_boot = 200)
  poly_sensitivity[[as.character(deg)]] <- res
  cat(sprintf("b = %.3f (SE = %.3f)\n", res$b, res$se))
}

## ====================================================================
## ROBUSTNESS 3: Bin width sensitivity
## ====================================================================
cat("\n=== SENSITIVITY: Bin Width ===\n\n")

bin_sensitivity <- list()
for (bw in c(2000, 5000, 10000)) {
  cat(sprintf("  Bin width $%s: ", formatC(bw, format = "d", big.mark = ",")))
  res <- estimate_bunching(dt_res, threshold = 800000, bin_width = bw, n_boot = 200)
  bin_sensitivity[[as.character(bw)]] <- res
  cat(sprintf("b = %.3f (SE = %.3f)\n", res$b, res$se))
}

## ====================================================================
## ROBUSTNESS 4: Window width sensitivity
## ====================================================================
cat("\n=== SENSITIVITY: Bunching Window Width ===\n\n")

window_sensitivity <- list()
for (w in c(15000, 30000, 50000)) {
  cat(sprintf("  Window $%s below: ", formatC(w, format = "d", big.mark = ",")))
  res <- estimate_bunching(dt_res, threshold = 800000, window_below = w, n_boot = 200)
  window_sensitivity[[as.character(w)]] <- res
  cat(sprintf("b = %.3f (SE = %.3f)\n", res$b, res$se))
}

## ====================================================================
## ROBUSTNESS 5: Temporal stability (year-by-year)
## ====================================================================
cat("\n=== TEMPORAL STABILITY: $800K by Year ===\n\n")

yearly_results <- list()
for (yr in 2018:2025) {
  dt_yr <- dt_res[year == yr]
  cat(sprintf("  %d (N=%s): ", yr, formatC(nrow(dt_yr), format = "d", big.mark = ",")))
  if (nrow(dt_yr[purchase_price >= 600000 & purchase_price <= 1000000]) < 500) {
    cat("insufficient data\n")
    yearly_results[[as.character(yr)]] <- list(b = NA, se = NA)
    next
  }
  res <- estimate_bunching(dt_yr, threshold = 800000, n_boot = 200)
  yearly_results[[as.character(yr)]] <- res
  cat(sprintf("b = %.3f (SE = %.3f)\n", res$b, res$se))
}

## ---- Save robustness results ----
save(placebo_results, poly_sensitivity, bin_sensitivity,
     window_sensitivity, yearly_results,
     file = "../data/robustness_results.RData")

cat("\nDONE: 04_robustness.R\n")
