## 04_robustness.R — Robustness checks for bunching analysis
## apep_0676: UK Charity Bunching at Audit Thresholds

source("00_packages.R")

data_dir <- "../data"
load(file.path(data_dir, "cleaned_data.RData"))
load(file.path(data_dir, "results.RData"))

create_bins <- function(dt, threshold, bw, window) {
  subset <- dt[income >= (threshold - window) & income <= (threshold + window)]
  subset[, bin := floor(income / bw) * bw + bw/2]
  counts <- subset[, .N, by = bin]
  setnames(counts, "N", "count")
  setorder(counts, bin)
  return(counts)
}

estimate_bunching <- function(bins, threshold, bw,
                               exclude_lower = 3, exclude_upper = 3,
                               poly_order = 7) {
  bins <- copy(bins)
  bins[, z := (bin - threshold) / bw]
  z_lower <- -exclude_lower
  z_upper <- exclude_upper
  fit_data <- bins[z < z_lower | z > z_upper]
  if (nrow(fit_data) < poly_order + 1) return(NULL)
  formula_str <- paste0("count ~ ", paste(paste0("I(z^", 1:poly_order, ")"), collapse = " + "))
  fit <- lm(as.formula(formula_str), data = fit_data)
  bins[, counterfactual := pmax(predict(fit, newdata = bins), 0)]
  bunching_region <- bins[z >= z_lower & z <= z_upper]
  excess_mass <- sum(bunching_region$count) - sum(bunching_region$counterfactual)
  avg_cf <- mean(bunching_region$counterfactual)
  b_hat <- excess_mass / avg_cf
  return(list(bins = bins, b_hat = b_hat, excess_mass = excess_mass,
              avg_counterfactual = avg_cf))
}

cat("=== ROBUSTNESS CHECKS ===\n\n")

## ============================================================
## 1. Sensitivity to polynomial order
## ============================================================

cat("--- Polynomial Order Sensitivity (£25K, pre-reform) ---\n")
pre <- arr[fiscal_year >= 2015 & fiscal_year <= 2022]
bins_25k <- create_bins(pre, 25000, 500, 15000)

poly_sensitivity <- data.table(
  poly_order = integer(),
  b_hat = numeric()
)

for (p in 3:9) {
  res <- estimate_bunching(bins_25k, 25000, 500,
                            exclude_lower = 3, exclude_upper = 3,
                            poly_order = p)
  if (!is.null(res)) {
    poly_sensitivity <- rbind(poly_sensitivity,
                               data.table(poly_order = p, b_hat = res$b_hat))
    cat("  Poly order", p, ": b =", round(res$b_hat, 3), "\n")
  }
}

## ============================================================
## 2. Sensitivity to exclusion window
## ============================================================

cat("\n--- Exclusion Window Sensitivity (£25K, pre-reform) ---\n")

window_sensitivity <- data.table(
  exclude = integer(),
  b_hat = numeric()
)

for (ex in 2:6) {
  res <- estimate_bunching(bins_25k, 25000, 500,
                            exclude_lower = ex, exclude_upper = ex,
                            poly_order = 7)
  if (!is.null(res)) {
    window_sensitivity <- rbind(window_sensitivity,
                                 data.table(exclude = ex, b_hat = res$b_hat))
    cat("  Exclude ±", ex, "bins: b =", round(res$b_hat, 3), "\n")
  }
}

## ============================================================
## 3. Placebo thresholds (no regulatory significance)
## ============================================================

cat("\n--- Placebo Thresholds ---\n")
placebo_thresholds <- c(15000, 20000, 30000, 35000, 50000)

placebo_results <- data.table(
  threshold = numeric(),
  b_hat = numeric()
)

for (pt in placebo_thresholds) {
  bins_p <- create_bins(pre, pt, 500, 15000)
  res <- estimate_bunching(bins_p, pt, 500,
                            exclude_lower = 3, exclude_upper = 3,
                            poly_order = 7)
  if (!is.null(res)) {
    placebo_results <- rbind(placebo_results,
                              data.table(threshold = pt, b_hat = res$b_hat))
    cat("  £", format(pt, big.mark = ","), ": b =", round(res$b_hat, 3), "\n")
  }
}

## ============================================================
## 4. Bin width sensitivity
## ============================================================

cat("\n--- Bin Width Sensitivity (£25K) ---\n")
bw_sensitivity <- data.table(
  bin_width = numeric(),
  b_hat = numeric()
)

for (bw in c(250, 500, 750, 1000)) {
  bins_bw <- create_bins(pre, 25000, bw, 15000)
  res <- estimate_bunching(bins_bw, 25000, bw,
                            exclude_lower = 3, exclude_upper = 3,
                            poly_order = 7)
  if (!is.null(res)) {
    bw_sensitivity <- rbind(bw_sensitivity,
                             data.table(bin_width = bw, b_hat = res$b_hat))
    cat("  Bin width £", bw, ": b =", round(res$b_hat, 3), "\n")
  }
}

## ============================================================
## 5. Year-by-year estimates at £25K
## ============================================================

cat("\n--- Year-by-Year Bunching at £25K ---\n")
yearly_results <- data.table(
  year = integer(),
  b_hat = numeric(),
  n_obs = integer()
)

for (y in 2015:2024) {
  yr_data <- arr[fiscal_year == y]
  bins_yr <- create_bins(yr_data, 25000, 500, 15000)
  res <- estimate_bunching(bins_yr, 25000, 500,
                            exclude_lower = 3, exclude_upper = 3,
                            poly_order = 5)
  if (!is.null(res)) {
    yearly_results <- rbind(yearly_results,
                             data.table(year = y, b_hat = res$b_hat,
                                        n_obs = nrow(yr_data[income >= 10000 & income <= 40000])))
    cat("  ", y, ": b =", round(res$b_hat, 3),
        ", N =", format(nrow(yr_data[income >= 10000 & income <= 40000]), big.mark = ","), "\n")
  }
}

## ============================================================
## 6. Restricting to consistently-reporting charities
## ============================================================

cat("\n--- Consistently-Reporting Charities (≥5 years of data) ---\n")

# Count years per charity
yr_counts <- arr[fiscal_year >= 2015, .(n_years = .N), by = organisation_number]
consistent <- yr_counts[n_years >= 5]$organisation_number

pre_consistent <- pre[organisation_number %in% consistent]
cat("  Charities with ≥5 years:", format(length(consistent), big.mark = ","), "\n")
cat("  Obs in pre-reform:", format(nrow(pre_consistent), big.mark = ","), "\n")

bins_consistent <- create_bins(pre_consistent, 25000, 500, 15000)
res_consistent <- estimate_bunching(bins_consistent, 25000, 500,
                                      exclude_lower = 3, exclude_upper = 3,
                                      poly_order = 7)
if (!is.null(res_consistent)) {
  cat("  b_hat (consistent reporters):", round(res_consistent$b_hat, 3), "\n")
}

## ============================================================
## 7. Round number effects: test at round numbers without regulation
## ============================================================

cat("\n--- Round Number Placebo (£10K, £50K, £100K) ---\n")
for (rn in c(10000, 50000, 100000)) {
  bins_rn <- create_bins(pre, rn, ifelse(rn <= 50000, 500, 5000),
                          ifelse(rn <= 50000, 15000, 50000))
  res_rn <- estimate_bunching(bins_rn, rn, ifelse(rn <= 50000, 500, 5000),
                                exclude_lower = 3, exclude_upper = 3,
                                poly_order = 7)
  if (!is.null(res_rn)) {
    cat("  £", format(rn, big.mark = ","), ": b =", round(res_rn$b_hat, 3), "\n")
  }
}

## ============================================================
## 8. Save robustness results
## ============================================================

robustness <- list(
  poly_sensitivity = poly_sensitivity,
  window_sensitivity = window_sensitivity,
  placebo_results = placebo_results,
  bw_sensitivity = bw_sensitivity,
  yearly_results = yearly_results,
  consistent_b_hat = ifelse(!is.null(res_consistent), res_consistent$b_hat, NA)
)

save(robustness, file = file.path(data_dir, "robustness.RData"))

cat("\n=== Robustness complete ===\n")
