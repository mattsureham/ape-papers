# 03_main_analysis.R — Bunching estimation at 1,000 kg/month threshold
# apep_1341: RCRA Hazardous Waste Generator Thresholds

source("00_packages.R")
library(fixest)  # for potential supplementary regressions

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

# ============================================================
# 1. Load data
# ============================================================
panel <- readRDS(file.path(data_dir, "handler_cycle_panel.rds"))
cat("Handler-cycle observations:", nrow(panel), "\n")

# Focus on the most recent cycle for main analysis
# (pool all cycles for robustness)
recent <- panel %>% filter(cycle == max(cycle))
cat("Most recent cycle:", max(panel$cycle), "with", nrow(recent), "handlers\n")

# ============================================================
# 2. Bunching estimation at 1,000 kg/month
# ============================================================
# Following Kleven & Waseem (2013) methodology
# Estimate excess mass below the threshold

threshold <- 1000  # kg/month

# Define bins and bunching window
bin_width <- 25  # kg/month bins
bunching_window <- c(threshold - 300, threshold + 200)  # [700, 1200]
excluded_region <- c(threshold - 150, threshold + 50)   # [850, 1050]

# Create binned data
estimate_bunching <- function(df, threshold, bin_width = 25,
                              exclude_low = 850, exclude_high = 1050,
                              window_low = 200, window_high = 2500,
                              poly_order = 7) {

  # Filter to analysis window
  df_window <- df %>%
    filter(gen_kg_month >= window_low & gen_kg_month <= window_high)

  # Create bins
  df_binned <- df_window %>%
    mutate(bin_center = floor(gen_kg_month / bin_width) * bin_width + bin_width / 2) %>%
    count(bin_center) %>%
    mutate(
      excluded = bin_center >= exclude_low & bin_center <= exclude_high,
      below_threshold = bin_center < threshold,
      normalized_bin = (bin_center - threshold) / bin_width
    )

  # Fit polynomial counterfactual EXCLUDING the bunching region
  df_fit <- df_binned %>% filter(!excluded)

  # Polynomial regression
  fit <- lm(n ~ poly(normalized_bin, poly_order, raw = TRUE), data = df_fit)

  # Predict counterfactual for all bins
  df_binned <- df_binned %>%
    mutate(
      counterfactual = predict(fit, newdata = .),
      counterfactual = pmax(counterfactual, 0)  # Non-negative counts
    )

  # Calculate excess mass
  bunching_region <- df_binned %>% filter(excluded & below_threshold)
  missing_region <- df_binned %>% filter(excluded & !below_threshold)

  excess_mass <- sum(bunching_region$n) - sum(bunching_region$counterfactual)
  missing_mass <- sum(missing_region$counterfactual) - sum(missing_region$n)

  # Normalized excess mass (b)
  cf_at_threshold <- predict(fit,
    newdata = data.frame(normalized_bin = 0))
  b <- excess_mass / max(cf_at_threshold, 1)

  list(
    binned_data = df_binned,
    excess_mass = excess_mass,
    missing_mass = missing_mass,
    b_normalized = b,
    counterfactual_at_kink = cf_at_threshold,
    poly_order = poly_order,
    fit = fit,
    n_total = nrow(df_window),
    n_bunching_region = sum(bunching_region$n),
    n_bunching_cf = sum(bunching_region$counterfactual)
  )
}

# Main estimate
cat("\n=== Main Bunching Estimate ===\n")
main_result <- estimate_bunching(recent, threshold)

cat(sprintf("Excess mass: %.0f handlers\n", main_result$excess_mass))
cat(sprintf("Missing mass: %.0f handlers\n", main_result$missing_mass))
cat(sprintf("Normalized b: %.3f\n", main_result$b_normalized))
cat(sprintf("Observed in bunching region: %d\n", main_result$n_bunching_region))
cat(sprintf("Counterfactual in bunching region: %.0f\n", main_result$n_bunching_cf))

# ============================================================
# 3. Bootstrap standard errors
# ============================================================
cat("\nBootstrapping standard errors (200 iterations)...\n")
set.seed(42)
n_boot <- 200
boot_b <- numeric(n_boot)

for (i in 1:n_boot) {
  boot_sample <- recent[sample(nrow(recent), replace = TRUE), ]
  boot_result <- tryCatch(
    estimate_bunching(boot_sample, threshold),
    error = function(e) list(b_normalized = NA)
  )
  boot_b[i] <- boot_result$b_normalized
}

boot_se <- sd(boot_b, na.rm = TRUE)
cat(sprintf("Bootstrap SE(b): %.3f\n", boot_se))
cat(sprintf("95%% CI: [%.3f, %.3f]\n",
            main_result$b_normalized - 1.96 * boot_se,
            main_result$b_normalized + 1.96 * boot_se))

# ============================================================
# 4. Sensitivity to polynomial order
# ============================================================
cat("\n=== Polynomial Sensitivity ===\n")
for (p in 5:9) {
  result_p <- estimate_bunching(recent, threshold, poly_order = p)
  cat(sprintf("  Poly %d: b = %.3f, excess = %.0f\n",
              p, result_p$b_normalized, result_p$excess_mass))
}

# ============================================================
# 5. Pooled estimate (all cycles)
# ============================================================
cat("\n=== Pooled Estimate (all cycles) ===\n")
pooled_result <- estimate_bunching(panel, threshold)
cat(sprintf("Pooled b: %.3f (excess: %.0f)\n",
            pooled_result$b_normalized, pooled_result$excess_mass))

# ============================================================
# 6. Save results
# ============================================================
results <- list(
  main = list(
    b = main_result$b_normalized,
    se = boot_se,
    excess_mass = main_result$excess_mass,
    missing_mass = main_result$missing_mass,
    n_total = main_result$n_total,
    cycle = max(panel$cycle)
  ),
  pooled = list(
    b = pooled_result$b_normalized,
    excess_mass = pooled_result$excess_mass,
    n_total = pooled_result$n_total
  ),
  binned_data = main_result$binned_data
)

saveRDS(results, file.path(data_dir, "bunching_results.rds"))
cat("\nResults saved.\n")

cat("\n03_main_analysis.R complete.\n")
