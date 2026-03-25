## 03_main_analysis.R — Bunching estimation at stamp duty thresholds
## apep_0952: Australian Stamp Duty Threshold Bunching

source("00_packages.R")

sales <- fread("../data/nsw_sales_clean.csv")
sales[, contract_date := as.Date(contract_date)]

reform_date <- as.Date("2023-07-01")
sales[, post_reform := contract_date >= reform_date]

## ============================================================
## Bunching Estimation Function (Kleven 2016 / Chetty et al. 2011)
## ============================================================
estimate_bunching <- function(dt, threshold, bin_width = 5000,
                               lower_excl = 30000, upper_excl = 5000,
                               poly_degree = 7,
                               price_min = NULL, price_max = NULL,
                               n_boot = 200) {
  # Default analysis range: threshold ± $200K
  if (is.null(price_min)) price_min <- threshold - 200000
  if (is.null(price_max)) price_max <- threshold + 200000

  # Create bin counts
  sub <- dt[purchase_price >= price_min & purchase_price <= price_max]
  sub[, bin := floor(purchase_price / bin_width) * bin_width]
  bins <- sub[, .(count = .N), by = bin][order(bin)]

  # Ensure all bins exist (fill zeros)
  all_bins <- data.table(bin = seq(price_min, price_max - bin_width, by = bin_width))
  bins <- merge(all_bins, bins, by = "bin", all.x = TRUE)
  bins[is.na(count), count := 0]

  # Define exclusion window: [threshold - lower_excl, threshold + upper_excl]
  bins[, excluded := bin >= (threshold - lower_excl) & bin <= (threshold + upper_excl)]
  bins[, bin_centered := (bin - threshold) / bin_width]

  # Fit polynomial to non-excluded bins
  fit_data <- bins[excluded == FALSE]
  if (nrow(fit_data) < poly_degree + 1) {
    warning("Not enough non-excluded bins for polynomial fit")
    return(NULL)
  }

  fit <- lm(count ~ poly(bin_centered, poly_degree, raw = TRUE), data = fit_data)
  bins[, counterfactual := predict(fit, newdata = bins)]
  bins[counterfactual < 0, counterfactual := 0]

  # Excess mass in bunching region
  bunch_bins <- bins[excluded == TRUE]
  excess <- sum(bunch_bins$count) - sum(bunch_bins$counterfactual)
  cf_height <- mean(bunch_bins$counterfactual)

  # Normalized excess mass (b-hat)
  b_hat <- if (cf_height > 0) excess / cf_height else NA_real_

  # Bootstrap standard errors
  boot_b <- replicate(n_boot, {
    # Resample with replacement within bins
    boot_sub <- sub[sample(.N, .N, replace = TRUE)]
    boot_sub[, bin := floor(purchase_price / bin_width) * bin_width]
    boot_bins <- boot_sub[, .(count = .N), by = bin][order(bin)]
    boot_bins <- merge(all_bins, boot_bins, by = "bin", all.x = TRUE)
    boot_bins[is.na(count), count := 0]
    boot_bins[, excluded := bin >= (threshold - lower_excl) & bin <= (threshold + upper_excl)]
    boot_bins[, bin_centered := (bin - threshold) / bin_width]

    boot_fit_data <- boot_bins[excluded == FALSE]
    tryCatch({
      boot_fit <- lm(count ~ poly(bin_centered, poly_degree, raw = TRUE),
                      data = boot_fit_data)
      boot_bins[, counterfactual := predict(boot_fit, newdata = boot_bins)]
      boot_bins[counterfactual < 0, counterfactual := 0]
      boot_bunch <- boot_bins[excluded == TRUE]
      boot_excess <- sum(boot_bunch$count) - sum(boot_bunch$counterfactual)
      boot_cf <- mean(boot_bunch$counterfactual)
      if (boot_cf > 0) boot_excess / boot_cf else NA_real_
    }, error = function(e) NA_real_)
  })

  b_se <- sd(boot_b, na.rm = TRUE)

  list(
    b_hat = b_hat,
    b_se = b_se,
    excess = excess,
    cf_height = cf_height,
    n_bunching = sum(bunch_bins$count),
    n_total = nrow(sub),
    bins = bins
  )
}

## ============================================================
## 1. Bunching at $800K — Post-reform (main result)
## ============================================================
cat("=== Bunching at $800K — POST-REFORM ===\n")
post_data <- sales[post_reform == TRUE]
bunch_800_post <- estimate_bunching(post_data, threshold = 800000,
                                     lower_excl = 25000, upper_excl = 5000)
cat(sprintf("  b-hat = %.2f (SE = %.2f)\n", bunch_800_post$b_hat, bunch_800_post$b_se))
cat(sprintf("  Excess mass: %.0f transactions\n", bunch_800_post$excess))
cat(sprintf("  N in bunching window: %d\n", bunch_800_post$n_bunching))

## ============================================================
## 2. Bunching at $800K — Pre-reform (placebo / round-number baseline)
## ============================================================
cat("\n=== Bunching at $800K — PRE-REFORM (placebo) ===\n")
pre_data <- sales[post_reform == FALSE]
bunch_800_pre <- estimate_bunching(pre_data, threshold = 800000,
                                    lower_excl = 25000, upper_excl = 5000)
cat(sprintf("  b-hat = %.2f (SE = %.2f)\n", bunch_800_pre$b_hat, bunch_800_pre$b_se))
cat(sprintf("  Excess mass: %.0f transactions\n", bunch_800_pre$excess))

## ============================================================
## 3. Difference-in-bunching (DiB)
## ============================================================
dib <- bunch_800_post$b_hat - bunch_800_pre$b_hat
dib_se <- sqrt(bunch_800_post$b_se^2 + bunch_800_pre$b_se^2)
cat(sprintf("\n=== DIFFERENCE-IN-BUNCHING ===\n"))
cat(sprintf("  DiB = %.2f (SE = %.2f), t = %.2f\n",
            dib, dib_se, dib / dib_se))

## ============================================================
## 4. Bunching at OLD threshold $650K — Pre-reform
## ============================================================
cat("\n=== Bunching at $650K — PRE-REFORM ===\n")
bunch_650_pre <- estimate_bunching(pre_data, threshold = 650000,
                                    lower_excl = 25000, upper_excl = 5000)
cat(sprintf("  b-hat = %.2f (SE = %.2f)\n", bunch_650_pre$b_hat, bunch_650_pre$b_se))

## ============================================================
## 5. Bunching at $650K — Post-reform (should disappear)
## ============================================================
cat("\n=== Bunching at $650K — POST-REFORM (should disappear) ===\n")
bunch_650_post <- estimate_bunching(post_data, threshold = 650000,
                                     lower_excl = 25000, upper_excl = 5000)
cat(sprintf("  b-hat = %.2f (SE = %.2f)\n", bunch_650_post$b_hat, bunch_650_post$b_se))

# DiB at $650K (should be NEGATIVE — bunching should decrease)
dib_650 <- bunch_650_post$b_hat - bunch_650_pre$b_hat
dib_650_se <- sqrt(bunch_650_post$b_se^2 + bunch_650_pre$b_se^2)
cat(sprintf("  DiB at $650K = %.2f (SE = %.2f)\n", dib_650, dib_650_se))

## ============================================================
## 6. Placebo: Bunching at $900K (no policy relevance)
## ============================================================
cat("\n=== Placebo: $900K (no policy threshold) ===\n")
bunch_900_post <- estimate_bunching(post_data, threshold = 900000,
                                     lower_excl = 25000, upper_excl = 5000)
bunch_900_pre <- estimate_bunching(pre_data, threshold = 900000,
                                    lower_excl = 25000, upper_excl = 5000)
dib_900 <- bunch_900_post$b_hat - bunch_900_pre$b_hat
dib_900_se <- sqrt(bunch_900_post$b_se^2 + bunch_900_pre$b_se^2)
cat(sprintf("  DiB at $900K = %.2f (SE = %.2f)\n", dib_900, dib_900_se))

## ============================================================
## 7. Store results for tables
## ============================================================
results <- list(
  # $800K threshold
  b_800_post = bunch_800_post$b_hat,
  se_800_post = bunch_800_post$b_se,
  n_800_post = bunch_800_post$n_total,
  excess_800_post = bunch_800_post$excess,

  b_800_pre = bunch_800_pre$b_hat,
  se_800_pre = bunch_800_pre$b_se,
  n_800_pre = bunch_800_pre$n_total,

  dib_800 = dib,
  dib_800_se = dib_se,

  # $650K threshold
  b_650_pre = bunch_650_pre$b_hat,
  se_650_pre = bunch_650_pre$b_se,
  b_650_post = bunch_650_post$b_hat,
  se_650_post = bunch_650_post$b_se,
  dib_650 = dib_650,
  dib_650_se = dib_650_se,

  # $900K placebo
  dib_900 = dib_900,
  dib_900_se = dib_900_se,

  # Bin data for distribution table
  bins_800_post = bunch_800_post$bins,
  bins_800_pre = bunch_800_pre$bins
)

saveRDS(results, "../data/bunching_results.rds")

## ============================================================
## 8. Diagnostics
## ============================================================
diagnostics <- list(
  n_treated = nrow(sales[post_reform == TRUE & near_800k == TRUE]),
  n_pre = length(unique(sales[post_reform == FALSE]$yr_qtr)),
  n_obs = nrow(sales[purchase_price >= 500000 & purchase_price <= 1100000])
)
write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics written. n_treated =", diagnostics$n_treated,
    ", n_pre =", diagnostics$n_pre, ", n_obs =", diagnostics$n_obs, "\n")
