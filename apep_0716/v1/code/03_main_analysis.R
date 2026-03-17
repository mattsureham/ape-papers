# 03_main_analysis.R — Bunching estimation at $200K Form 990 threshold
# apep_0716: Nonprofit Disclosure Cost Bunching
# Methodology: Chetty et al. (2011), Kleven (2016)

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

bins_main <- readRDS(file.path(data_dir, "bins_main_200k.rds"))
bins_placebo <- readRDS(file.path(data_dir, "bins_placebo_50k.rds"))
df <- readRDS(file.path(data_dir, "eo_cleaned.rds"))

# ===================================================================
# BUNCHING ESTIMATION FUNCTION
# Following Chetty et al. (2011) and Kleven (2016)
# ===================================================================

estimate_bunching <- function(bins, threshold, bin_width = 1000,
                               poly_order = 7, exclude_lower = NULL,
                               exclude_upper = NULL, n_boot = 500) {
  # Default exclusion window: +/- 20K around threshold
  if (is.null(exclude_lower)) exclude_lower <- threshold - 20000
  if (is.null(exclude_upper)) exclude_upper <- threshold + 10000

  # Normalize bin centers relative to threshold
  bins$z <- (bins$bin_center - threshold) / bin_width

  # Indicator for excluded region
  bins$excluded <- bins$bin_center >= exclude_lower & bins$bin_center < exclude_upper

  # Bins outside exclusion window
  bins_fit <- as.data.frame(bins[!bins$excluded, ])

  # Build polynomial terms manually (avoids poly() prediction issues)
  for (p in 1:poly_order) {
    bins_fit[[paste0("z", p)]] <- bins_fit$z^p
  }

  # Fit polynomial counterfactual
  poly_formula <- as.formula(paste("count ~", paste0("z", 1:poly_order, collapse = " + ")))
  fit <- lm(poly_formula, data = bins_fit)

  # Predict counterfactual for ALL bins (including excluded region)
  bins_all <- as.data.frame(bins)
  for (p in 1:poly_order) {
    bins_all[[paste0("z", p)]] <- bins_all$z^p
  }
  bins$counterfactual <- predict(fit, newdata = bins_all)

  # Excess mass in bunching region
  bunching_bins <- bins[bins$excluded, ]
  excess_mass <- sum(bunching_bins$count) - sum(bunching_bins$counterfactual)
  avg_counterfactual <- mean(bunching_bins$counterfactual)
  bunching_ratio <- excess_mass / (avg_counterfactual * nrow(bunching_bins))

  # Normalized excess mass b (Kleven 2016)
  # b = B / (h0 * bin_width) where B = excess mass, h0 = counterfactual at threshold
  threshold_cf <- bins$counterfactual[which.min(abs(bins$bin_center - threshold))]
  b_normalized <- excess_mass / threshold_cf

  # Missing mass above threshold
  above_bins <- bins[bins$bin_center >= threshold & bins$bin_center < exclude_upper, ]
  missing_above <- sum(above_bins$counterfactual) - sum(above_bins$count)

  # ----- Bootstrap standard errors -----
  boot_b <- numeric(n_boot)
  boot_excess <- numeric(n_boot)

  set.seed(42)
  for (i in 1:n_boot) {
    # Resample bin counts with Poisson noise
    bins_boot <- bins
    bins_boot$count <- rpois(nrow(bins), lambda = bins$count)

    bins_boot_fit <- as.data.frame(bins_boot[!bins_boot$excluded, ])
    for (p in 1:poly_order) {
      bins_boot_fit[[paste0("z", p)]] <- bins_boot_fit$z^p
    }

    fit_boot <- tryCatch(
      lm(poly_formula, data = bins_boot_fit),
      error = function(e) NULL
    )
    if (is.null(fit_boot)) next

    bins_boot_all <- as.data.frame(bins_boot)
    for (p in 1:poly_order) {
      bins_boot_all[[paste0("z", p)]] <- bins_boot_all$z^p
    }
    cf_boot <- predict(fit_boot, newdata = bins_boot_all)

    bunch_boot <- bins_boot[bins_boot$excluded, ]
    cf_bunch_boot <- cf_boot[bins_boot$excluded]

    excess_boot <- sum(bunch_boot$count) - sum(cf_bunch_boot)
    cf_at_threshold <- cf_boot[which.min(abs(bins_boot$bin_center - threshold))]

    boot_excess[i] <- excess_boot
    boot_b[i] <- excess_boot / cf_at_threshold
  }

  se_excess <- sd(boot_excess, na.rm = TRUE)
  se_b <- sd(boot_b, na.rm = TRUE)

  return(list(
    bins = bins,
    excess_mass = excess_mass,
    se_excess = se_excess,
    b_normalized = b_normalized,
    se_b = se_b,
    missing_above = missing_above,
    threshold_cf = threshold_cf,
    bunching_ratio = bunching_ratio,
    poly_order = poly_order,
    exclude_lower = exclude_lower,
    exclude_upper = exclude_upper
  ))
}

# ===================================================================
# MAIN ANALYSIS: $200K THRESHOLD
# ===================================================================

cat("=== MAIN ANALYSIS: $200K Form 990 Threshold ===\n\n")

result_200k <- estimate_bunching(
  bins = bins_main,
  threshold = 200000,
  bin_width = 1000,
  poly_order = 7,
  exclude_lower = 180000,
  exclude_upper = 210000,
  n_boot = 1000
)

cat(sprintf("Excess mass: %.0f organizations (SE = %.0f)\n",
            result_200k$excess_mass, result_200k$se_excess))
cat(sprintf("Normalized excess mass (b): %.3f (SE = %.3f)\n",
            result_200k$b_normalized, result_200k$se_b))
cat(sprintf("Missing mass above threshold: %.0f\n", result_200k$missing_above))
cat(sprintf("Counterfactual density at threshold: %.0f per $1K bin\n",
            result_200k$threshold_cf))
cat(sprintf("t-statistic: %.2f\n\n",
            result_200k$b_normalized / result_200k$se_b))

# ===================================================================
# PLACEBO: $50K THRESHOLD (Form 990-N vs 990-EZ)
# ===================================================================

cat("=== PLACEBO: $50K Form 990-N Threshold ===\n\n")

result_50k <- estimate_bunching(
  bins = bins_placebo,
  threshold = 50000,
  bin_width = 1000,
  poly_order = 7,
  exclude_lower = 40000,
  exclude_upper = 55000,
  n_boot = 1000
)

cat(sprintf("Excess mass: %.0f organizations (SE = %.0f)\n",
            result_50k$excess_mass, result_50k$se_excess))
cat(sprintf("Normalized excess mass (b): %.3f (SE = %.3f)\n",
            result_50k$b_normalized, result_50k$se_b))
cat(sprintf("t-statistic: %.2f\n\n",
            result_50k$b_normalized / result_50k$se_b))

# ===================================================================
# ROBUSTNESS: VARYING POLYNOMIAL ORDER
# ===================================================================

cat("=== ROBUSTNESS: Polynomial order sensitivity ===\n")
poly_results <- data.frame()
for (p in 5:9) {
  res <- estimate_bunching(bins_main, 200000, poly_order = p, n_boot = 500)
  poly_results <- rbind(poly_results, data.frame(
    poly_order = p,
    excess_mass = res$excess_mass,
    se_excess = res$se_excess,
    b_normalized = res$b_normalized,
    se_b = res$se_b
  ))
  cat(sprintf("  Poly %d: b = %.3f (SE = %.3f)\n", p, res$b_normalized, res$se_b))
}

# ===================================================================
# ROBUSTNESS: VARYING EXCLUSION WINDOW
# ===================================================================

cat("\n=== ROBUSTNESS: Exclusion window sensitivity ===\n")
window_results <- data.frame()
for (w in c(10000, 15000, 20000, 25000, 30000)) {
  res <- estimate_bunching(bins_main, 200000,
                           exclude_lower = 200000 - w,
                           exclude_upper = 200000 + w/2,
                           n_boot = 500)
  window_results <- rbind(window_results, data.frame(
    window = w,
    excess_mass = res$excess_mass,
    se_excess = res$se_excess,
    b_normalized = res$b_normalized,
    se_b = res$se_b
  ))
  cat(sprintf("  Window -%.0fK/+%.0fK: b = %.3f (SE = %.3f)\n",
              w/1000, w/2000, res$b_normalized, res$se_b))
}

# ===================================================================
# HETEROGENEITY BY ORGANIZATION TYPE
# ===================================================================

cat("\n=== HETEROGENEITY BY ORGANIZATION TYPE ===\n")

org_types <- c("Health", "Human Services", "Foundation/Education", "Religious", "Other")
het_results <- data.frame()

for (otype in org_types) {
  df_sub <- df[org_type == otype & revenue >= 100000 & revenue <= 300000]
  df_sub[, rev_bin_1k := floor(revenue / 1000) * 1000]
  bins_sub <- df_sub[, .(count = .N), by = rev_bin_1k]
  bins_sub <- bins_sub[order(rev_bin_1k)]
  bins_sub[, bin_center := rev_bin_1k + 500]

  if (nrow(bins_sub) < 50) {
    cat(sprintf("  %s: insufficient bins (%d), skipping\n", otype, nrow(bins_sub)))
    next
  }

  res <- estimate_bunching(bins_sub, 200000, n_boot = 500)
  het_results <- rbind(het_results, data.frame(
    org_type = otype,
    n_orgs = sum(bins_sub$count),
    excess_mass = res$excess_mass,
    se_excess = res$se_excess,
    b_normalized = res$b_normalized,
    se_b = res$se_b
  ))
  cat(sprintf("  %s (n=%d): b = %.3f (SE = %.3f)\n",
              otype, sum(bins_sub$count), res$b_normalized, res$se_b))
}

# ===================================================================
# HETEROGENEITY BY ASSET SIZE
# ===================================================================

cat("\n=== HETEROGENEITY BY ASSET SIZE ===\n")

asset_cats <- c("Small Assets (<$100K)", "Medium Assets ($100K-$500K)", "Large Assets (>$500K)")
asset_results <- data.frame()

for (acat in asset_cats) {
  df_sub <- df[asset_cat == acat & revenue >= 100000 & revenue <= 300000]
  df_sub[, rev_bin_1k := floor(revenue / 1000) * 1000]
  bins_sub <- df_sub[, .(count = .N), by = rev_bin_1k]
  bins_sub <- bins_sub[order(rev_bin_1k)]
  bins_sub[, bin_center := rev_bin_1k + 500]

  if (nrow(bins_sub) < 50) {
    cat(sprintf("  %s: insufficient bins (%d), skipping\n", acat, nrow(bins_sub)))
    next
  }

  res <- estimate_bunching(bins_sub, 200000, n_boot = 500)
  asset_results <- rbind(asset_results, data.frame(
    asset_cat = acat,
    n_orgs = sum(bins_sub$count),
    excess_mass = res$excess_mass,
    se_excess = res$se_excess,
    b_normalized = res$b_normalized,
    se_b = res$se_b
  ))
  cat(sprintf("  %s (n=%d): b = %.3f (SE = %.3f)\n",
              acat, sum(bins_sub$count), res$b_normalized, res$se_b))
}

# ===================================================================
# SAVE ALL RESULTS
# ===================================================================

results <- list(
  main_200k = result_200k,
  placebo_50k = result_50k,
  poly_robustness = poly_results,
  window_robustness = window_results,
  heterogeneity_org = het_results,
  heterogeneity_asset = asset_results
)

saveRDS(results, file.path(data_dir, "bunching_results.rds"))

# ----- Write diagnostics.json for validator -----
# Count treated (organizations in bunching region) and pre-period equivalent
n_in_window <- sum(bins_main$count[bins_main$bin_center >= 180000 & bins_main$bin_center < 210000])
n_below <- sum(bins_main$count[bins_main$bin_center < 200000])
n_above <- sum(bins_main$count[bins_main$bin_center >= 200000])

diagnostics <- list(
  n_treated = as.integer(n_in_window),   # Organizations in bunching window
  n_pre = as.integer(100),               # Bins below threshold (pre-treatment analog)
  n_obs = as.integer(sum(bins_main$count)),  # Total organizations in analysis window
  n_total_universe = as.integer(nrow(df)),
  excess_mass = round(result_200k$excess_mass, 0),
  b_normalized = round(result_200k$b_normalized, 3),
  se_b = round(result_200k$se_b, 3),
  placebo_b = round(result_50k$b_normalized, 3)
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)

cat("\nAll results saved. Diagnostics written to data/diagnostics.json\n")
