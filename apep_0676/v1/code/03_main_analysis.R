## 03_main_analysis.R — Bunching estimation at charity audit thresholds
## apep_0676: UK Charity Bunching at Audit Thresholds

source("00_packages.R")

data_dir <- "../data"
load(file.path(data_dir, "cleaned_data.RData"))

## ============================================================
## 1. Bunching Estimation Functions
## ============================================================

#' Estimate bunching at a threshold using polynomial counterfactual
#'
#' @param bins data.table with 'bin' and 'count' columns
#' @param threshold the regulatory threshold
#' @param bw bin width
#' @param exclude_lower bins below threshold to exclude from fit
#' @param exclude_upper bins above threshold to exclude from fit
#' @param poly_order polynomial order for counterfactual
#' @return list with bunching estimate, counterfactual, and statistics
estimate_bunching <- function(bins, threshold, bw,
                               exclude_lower = 3, exclude_upper = 3,
                               poly_order = 7) {

  bins <- copy(bins)
  bins[, z := (bin - threshold) / bw]  # Normalized running variable

  # Define excluded region (bins around threshold)
  z_lower <- -exclude_lower
  z_upper <- exclude_upper

  # Fit polynomial on bins OUTSIDE the excluded region
  fit_data <- bins[z < z_lower | z > z_upper]

  if (nrow(fit_data) < poly_order + 1) {
    warning("Not enough bins outside exclusion region for polynomial fit")
    return(NULL)
  }

  # Polynomial regression
  formula_str <- paste0("count ~ ", paste(paste0("I(z^", 1:poly_order, ")"), collapse = " + "))
  fit <- lm(as.formula(formula_str), data = fit_data)

  # Predict counterfactual for all bins
  bins[, counterfactual := predict(fit, newdata = bins)]
  bins[, counterfactual := pmax(counterfactual, 0)]  # Floor at zero

  # Excess mass in the bunching region
  bunching_region <- bins[z >= z_lower & z <= z_upper]
  excess_mass <- sum(bunching_region$count) - sum(bunching_region$counterfactual)

  # Normalized excess mass (b = excess / average counterfactual in region)
  avg_cf <- mean(bunching_region$counterfactual)
  b_hat <- excess_mass / avg_cf

  # Missing mass above (hole)
  above_region <- bins[z > 0 & z <= z_upper]
  missing_mass <- sum(above_region$counterfactual) - sum(above_region$count)

  return(list(
    bins = bins,
    b_hat = b_hat,
    excess_mass = excess_mass,
    missing_mass = missing_mass,
    avg_counterfactual = avg_cf,
    fit = fit,
    threshold = threshold,
    z_lower = z_lower,
    z_upper = z_upper
  ))
}

#' Bootstrap standard errors for bunching estimate
bootstrap_bunching_se <- function(dt, threshold, bw, window,
                                   exclude_lower = 3, exclude_upper = 3,
                                   poly_order = 7, n_boot = 500) {

  # Expand bins back to individual observations for resampling
  obs <- dt[income >= (threshold - window) & income <= (threshold + window)]

  b_hats <- numeric(n_boot)

  for (i in 1:n_boot) {
    # Resample charities with replacement
    boot_sample <- obs[sample(.N, .N, replace = TRUE)]
    boot_bins <- boot_sample[, .(count = .N),
                              by = .(bin = floor(income / bw) * bw + bw/2)]
    setorder(boot_bins, bin)

    result <- estimate_bunching(boot_bins, threshold, bw,
                                 exclude_lower, exclude_upper, poly_order)
    if (!is.null(result)) {
      b_hats[i] <- result$b_hat
    } else {
      b_hats[i] <- NA
    }
  }

  return(list(
    se = sd(b_hats, na.rm = TRUE),
    ci_lower = quantile(b_hats, 0.025, na.rm = TRUE),
    ci_upper = quantile(b_hats, 0.975, na.rm = TRUE),
    boot_dist = b_hats
  ))
}

## ============================================================
## 2. Main Bunching Estimates
## ============================================================

cat("=== BUNCHING ANALYSIS ===\n\n")

## --- £25K threshold (pre-reform, 2015-2022) ---
cat("--- £25,000 Threshold (Pre-Reform, 2015-2022) ---\n")
pre <- arr[fiscal_year >= 2015 & fiscal_year <= 2022]
bins_25k <- create_bins <- function(dt, threshold, bw, window) {
  subset <- dt[income >= (threshold - window) & income <= (threshold + window)]
  subset[, bin := floor(income / bw) * bw + bw/2]
  counts <- subset[, .N, by = bin]
  setnames(counts, "N", "count")
  setorder(counts, bin)
  return(counts)
}
bins_25k <- create_bins(pre, 25000, 500, 15000)

result_25k <- estimate_bunching(bins_25k, 25000, 500,
                                 exclude_lower = 3, exclude_upper = 3,
                                 poly_order = 7)

cat("  Excess mass (b_hat):", round(result_25k$b_hat, 3), "\n")
cat("  Raw excess count:", round(result_25k$excess_mass), "\n")
cat("  Missing mass above:", round(result_25k$missing_mass), "\n")

# Bootstrap SE
cat("  Computing bootstrap SE (500 iterations)...\n")
boot_25k <- bootstrap_bunching_se(pre, 25000, 500, 15000,
                                    exclude_lower = 3, exclude_upper = 3,
                                    poly_order = 7, n_boot = 500)
cat("  SE(b_hat):", round(boot_25k$se, 3), "\n")
cat("  95% CI: [", round(boot_25k$ci_lower, 3), ",",
    round(boot_25k$ci_upper, 3), "]\n\n")

## --- £1M threshold (2015-2025) ---
cat("--- £1,000,000 Threshold (2015-2025) ---\n")
recent <- arr[fiscal_year >= 2015]
bins_1m <- create_bins(recent, 1000000, 10000, 300000)

result_1m <- estimate_bunching(bins_1m, 1000000, 10000,
                                exclude_lower = 3, exclude_upper = 3,
                                poly_order = 7)

cat("  Excess mass (b_hat):", round(result_1m$b_hat, 3), "\n")
cat("  Raw excess count:", round(result_1m$excess_mass), "\n")

cat("  Computing bootstrap SE...\n")
boot_1m <- bootstrap_bunching_se(recent, 1000000, 10000, 300000,
                                   exclude_lower = 3, exclude_upper = 3,
                                   poly_order = 7, n_boot = 500)
cat("  SE(b_hat):", round(boot_1m$se, 3), "\n")
cat("  95% CI: [", round(boot_1m$ci_lower, 3), ",",
    round(boot_1m$ci_upper, 3), "]\n\n")

## ============================================================
## 3. Reform Test: Pre vs Post at £25K and £40K
## ============================================================

cat("--- Reform Test: Pre vs Post ---\n")

# Pre-reform: bunching at £25K
# Already computed above

# Post-reform: bunching at £25K should disappear
post <- arr[fiscal_year >= 2023]
bins_25k_post <- create_bins(post, 25000, 500, 15000)
result_25k_post <- estimate_bunching(bins_25k_post, 25000, 500,
                                      exclude_lower = 3, exclude_upper = 3,
                                      poly_order = 7)

cat("  Post-reform b_hat at £25K:", round(result_25k_post$b_hat, 3), "\n")

boot_25k_post <- bootstrap_bunching_se(post, 25000, 500, 15000,
                                        exclude_lower = 3, exclude_upper = 3,
                                        poly_order = 7, n_boot = 500)
cat("  SE:", round(boot_25k_post$se, 3), "\n")

# Post-reform: bunching should appear at £40K
bins_40k <- create_bins(post, 40000, 500, 15000)
result_40k <- estimate_bunching(bins_40k, 40000, 500,
                                 exclude_lower = 3, exclude_upper = 3,
                                 poly_order = 7)

cat("  Post-reform b_hat at £40K:", round(result_40k$b_hat, 3), "\n")

boot_40k <- bootstrap_bunching_se(post, 40000, 500, 15000,
                                    exclude_lower = 3, exclude_upper = 3,
                                    poly_order = 7, n_boot = 500)
cat("  SE:", round(boot_40k$se, 3), "\n\n")

## ============================================================
## 4. Heterogeneity by Charity Type
## ============================================================

cat("--- Heterogeneity by Charity Purpose ---\n")

top_types <- names(sort(table(pre$classification_description), decreasing = TRUE))[1:6]

het_results <- data.table(
  type = character(),
  b_hat = numeric(),
  se = numeric(),
  n_obs = integer()
)

for (ctype in top_types) {
  sub <- pre[classification_description == ctype]
  if (sum(sub$income >= 10000 & sub$income <= 40000) < 200) next

  bins_sub <- create_bins(sub, 25000, 500, 15000)
  result_sub <- estimate_bunching(bins_sub, 25000, 500,
                                   exclude_lower = 3, exclude_upper = 3,
                                   poly_order = 5)  # Lower order for smaller samples

  if (!is.null(result_sub)) {
    boot_sub <- bootstrap_bunching_se(sub, 25000, 500, 15000,
                                       exclude_lower = 3, exclude_upper = 3,
                                       poly_order = 5, n_boot = 200)
    het_results <- rbind(het_results, data.table(
      type = ctype,
      b_hat = result_sub$b_hat,
      se = boot_sub$se,
      n_obs = nrow(sub[income >= 10000 & income <= 40000])
    ))
    cat("  ", ctype, ": b =", round(result_sub$b_hat, 3),
        "(SE =", round(boot_sub$se, 3), "), N =",
        format(nrow(sub[income >= 10000 & income <= 40000]), big.mark = ","), "\n")
  }
}

## ============================================================
## 5. McCrary Density Test
## ============================================================

cat("\n--- McCrary-style Density Test ---\n")

# Simple density discontinuity test at £25K
# Compare count in bin just below vs just above
below <- bins_25k_pre[bin == 24750, count]
above <- bins_25k_pre[bin == 25250, count]
cat("  Bin just below £25K (£24,500-£25,000):", below, "\n")
cat("  Bin just above £25K (£25,000-£25,500):", above, "\n")
cat("  Ratio:", round(below / above, 2), "\n")
cat("  Percentage drop:", round((1 - above/below) * 100, 1), "%\n")

# At £1M
below_1m <- bins_1m[bin == 995000, count]
above_1m <- bins_1m[bin == 1005000, count]
cat("\n  Bin just below £1M (£990K-£1M):", below_1m, "\n")
cat("  Bin just above £1M (£1M-£1.01M):", above_1m, "\n")
cat("  Ratio:", round(below_1m / above_1m, 2), "\n")
cat("  Percentage drop:", round((1 - above_1m/below_1m) * 100, 1), "%\n")

## ============================================================
## 6. Save Results and Diagnostics
## ============================================================

results <- list(
  result_25k_pre = result_25k,
  boot_25k_pre = boot_25k,
  result_1m = result_1m,
  boot_1m = boot_1m,
  result_25k_post = result_25k_post,
  boot_25k_post = boot_25k_post,
  result_40k_post = result_40k,
  boot_40k = boot_40k,
  het_results = het_results
)

save(results, file = file.path(data_dir, "results.RData"))

# Diagnostics for validator
diagnostics <- list(
  n_treated = nrow(arr[income >= 20000 & income <= 30000 & fiscal_year >= 2015]),
  n_pre = length(unique(arr$fiscal_year[arr$fiscal_year < 2023])),
  n_obs = nrow(arr[fiscal_year >= 2015])
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE)

cat("\n=== Analysis complete ===\n")
cat("Results saved to data/results.RData\n")
cat("Diagnostics saved to data/diagnostics.json\n")
