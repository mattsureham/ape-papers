## 04_robustness.R — Robustness checks for bunching estimates
## apep_0952: Australian Stamp Duty Threshold Bunching

source("00_packages.R")

sales <- fread("../data/nsw_sales_clean.csv")
sales[, contract_date := as.Date(contract_date)]
reform_date <- as.Date("2023-07-01")
sales[, post_reform := contract_date >= reform_date]

## Re-use bunching function from 03_main_analysis.R
source("03_main_analysis.R")

## ============================================================
## Robustness 1: Different bin widths ($2.5K, $5K, $10K)
## ============================================================
cat("\n\n=== ROBUSTNESS 1: Bin width sensitivity ===\n")
for (bw in c(2500, 5000, 10000)) {
  post_data <- sales[post_reform == TRUE]
  pre_data <- sales[post_reform == FALSE]
  b_post <- estimate_bunching(post_data, 800000, bin_width = bw, n_boot = 100)
  b_pre <- estimate_bunching(pre_data, 800000, bin_width = bw, n_boot = 100)
  dib <- b_post$b_hat - b_pre$b_hat
  dib_se <- sqrt(b_post$b_se^2 + b_pre$b_se^2)
  cat(sprintf("  Bin $%.1fK: DiB(800K) = %.2f (SE = %.2f)\n", bw/1000, dib, dib_se))
}

## ============================================================
## Robustness 2: Different polynomial degrees (5, 7, 9)
## ============================================================
cat("\n=== ROBUSTNESS 2: Polynomial degree ===\n")
for (deg in c(5, 7, 9)) {
  post_data <- sales[post_reform == TRUE]
  pre_data <- sales[post_reform == FALSE]
  b_post <- estimate_bunching(post_data, 800000, poly_degree = deg, n_boot = 100)
  b_pre <- estimate_bunching(pre_data, 800000, poly_degree = deg, n_boot = 100)
  dib <- b_post$b_hat - b_pre$b_hat
  dib_se <- sqrt(b_post$b_se^2 + b_pre$b_se^2)
  cat(sprintf("  Poly %d: DiB(800K) = %.2f (SE = %.2f)\n", deg, dib, dib_se))
}

## ============================================================
## Robustness 3: Different exclusion windows
## ============================================================
cat("\n=== ROBUSTNESS 3: Exclusion window width ===\n")
for (excl in c(15000, 25000, 35000, 50000)) {
  post_data <- sales[post_reform == TRUE]
  pre_data <- sales[post_reform == FALSE]
  b_post <- estimate_bunching(post_data, 800000, lower_excl = excl, n_boot = 100)
  b_pre <- estimate_bunching(pre_data, 800000, lower_excl = excl, n_boot = 100)
  dib <- b_post$b_hat - b_pre$b_hat
  dib_se <- sqrt(b_post$b_se^2 + b_pre$b_se^2)
  cat(sprintf("  Excl $%.0fK: DiB(800K) = %.2f (SE = %.2f)\n", excl/1000, dib, dib_se))
}

## ============================================================
## Robustness 4: Different time windows
## ============================================================
cat("\n=== ROBUSTNESS 4: Time window sensitivity ===\n")
# Narrow: 6 months pre/post
narrow_pre <- sales[contract_date >= as.Date("2023-01-01") &
                      contract_date < reform_date]
narrow_post <- sales[contract_date >= reform_date &
                       contract_date <= as.Date("2023-12-31")]
b_n_pre <- estimate_bunching(narrow_pre, 800000, n_boot = 100)
b_n_post <- estimate_bunching(narrow_post, 800000, n_boot = 100)
dib_narrow <- b_n_post$b_hat - b_n_pre$b_hat
dib_narrow_se <- sqrt(b_n_post$b_se^2 + b_n_pre$b_se^2)
cat(sprintf("  6-month window: DiB = %.2f (SE = %.2f), n_pre=%d, n_post=%d\n",
            dib_narrow, dib_narrow_se, b_n_pre$n_total, b_n_post$n_total))

# Wide: full sample
wide_pre <- sales[post_reform == FALSE & contract_date >= as.Date("2020-01-01")]
wide_post <- sales[post_reform == TRUE]
b_w_pre <- estimate_bunching(wide_pre, 800000, n_boot = 100)
b_w_post <- estimate_bunching(wide_post, 800000, n_boot = 100)
dib_wide <- b_w_post$b_hat - b_w_pre$b_hat
dib_wide_se <- sqrt(b_w_post$b_se^2 + b_w_pre$b_se^2)
cat(sprintf("  Full window (2020+): DiB = %.2f (SE = %.2f), n_pre=%d, n_post=%d\n",
            dib_wide, dib_wide_se, b_w_pre$n_total, b_w_post$n_total))

## ============================================================
## Robustness 5: Zoning heterogeneity
## ============================================================
cat("\n=== ROBUSTNESS 5: By zoning ===\n")
for (z in c("R2", "R1", "R3")) {
  z_pre <- sales[post_reform == FALSE & zoning == z]
  z_post <- sales[post_reform == TRUE & zoning == z]
  if (nrow(z_pre[purchase_price >= 600000 & purchase_price <= 1000000]) > 200 &
      nrow(z_post[purchase_price >= 600000 & purchase_price <= 1000000]) > 200) {
    b_z_pre <- estimate_bunching(z_pre, 800000, n_boot = 100)
    b_z_post <- estimate_bunching(z_post, 800000, n_boot = 100)
    dib_z <- b_z_post$b_hat - b_z_pre$b_hat
    dib_z_se <- sqrt(b_z_post$b_se^2 + b_z_pre$b_se^2)
    cat(sprintf("  Zone %s: DiB = %.2f (SE = %.2f)\n", z, dib_z, dib_z_se))
  } else {
    cat(sprintf("  Zone %s: insufficient data\n", z))
  }
}

## ============================================================
## Robustness 6: Area composition near threshold
## ============================================================
cat("\n=== ROBUSTNESS 6: Area composition test ===\n")
near_800 <- sales[purchase_price >= 750000 & purchase_price <= 850000 &
                    !is.na(area_sqm) & area_sqm > 0 & area_sqm < 50000]

# Regression: area ~ post_reform × below_threshold
near_800[, below := purchase_price <= 800000]
composition_reg <- feols(log(area_sqm) ~ post_reform * below | postcode,
                          data = near_800,
                          cluster = "postcode")
cat("Area composition regression (log area ~ post × below $800K, postcode FE):\n")
print(summary(composition_reg))

## ============================================================
## Save robustness results
## ============================================================
rob_results <- list(
  dib_narrow = dib_narrow,
  dib_narrow_se = dib_narrow_se,
  dib_wide = dib_wide,
  dib_wide_se = dib_wide_se,
  composition_coef = coef(composition_reg)["post_reformTRUE:belowTRUE"],
  composition_se = sqrt(vcov(composition_reg)["post_reformTRUE:belowTRUE",
                                               "post_reformTRUE:belowTRUE"])
)
saveRDS(rob_results, "../data/robustness_results.rds")
cat("\nRobustness results saved.\n")
