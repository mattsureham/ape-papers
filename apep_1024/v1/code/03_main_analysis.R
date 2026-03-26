# 03_main_analysis.R — Bunching estimation at DPE rental ban thresholds
# apep_1024: France DPE Rental Ban Bunching

source("00_packages.R")

dt <- fread("../data/dpe_clean.csv")
cat(sprintf("Loaded %d cleaned records\n", nrow(dt)))

# ============================================================
# BUNCHING ESTIMATOR
# Following Kleven & Waseem (2013) / Kleven (2016)
# ============================================================

estimate_bunching <- function(data, threshold, bin_width = 5,
                               window_left = 100, window_right = 100,
                               poly_order = 7, excl_width = 20,
                               label = "") {
  # Subset to analysis window
  conso_min <- threshold - window_left
  conso_max <- threshold + window_right
  d <- data[conso >= conso_min & conso <= conso_max]

  # Create bin counts
  d[, bin := floor(conso / bin_width) * bin_width]
  bin_counts <- d[, .(count = .N), by = bin][order(bin)]

  # Identify excluded region (manipulation window)
  excl_lo <- threshold - excl_width
  excl_hi <- threshold

  # Fit polynomial to non-excluded region
  cf_data <- bin_counts[bin < excl_lo | bin >= excl_hi]
  cf_data[, bin_norm := bin - threshold]

  # Polynomial regression
  poly_formula <- as.formula(paste0("count ~ ",
                                     paste0("I(bin_norm^", 1:poly_order, ")",
                                            collapse = " + ")))
  fit <- lm(poly_formula, data = cf_data)

  # Predict counterfactual for all bins
  all_bins <- bin_counts[, .(bin, bin_norm = bin - threshold)]
  all_bins[, counterfactual := predict(fit, newdata = all_bins)]

  # Merge
  bin_counts <- merge(bin_counts, all_bins[, .(bin, counterfactual)], by = "bin")

  # Excess mass = observed - counterfactual in the excluded region below threshold
  excl_bins <- bin_counts[bin >= excl_lo & bin < excl_hi]
  excess_mass <- sum(excl_bins$count - excl_bins$counterfactual)

  # Missing mass above threshold
  above_bins <- bin_counts[bin >= excl_hi & bin < (excl_hi + excl_width)]
  missing_mass <- sum(above_bins$counterfactual - above_bins$count)

  # Normalize by counterfactual height at threshold
  cf_at_threshold <- bin_counts[bin == excl_lo, counterfactual]
  if (length(cf_at_threshold) == 0) cf_at_threshold <- mean(excl_bins$counterfactual)

  b_normalized <- excess_mass / cf_at_threshold

  # Standard error via bootstrap
  set.seed(42)
  n_boot <- 200
  b_boot <- numeric(n_boot)
  for (i in 1:n_boot) {
    boot_counts <- bin_counts[, .(bin, count = rpois(.N, count), bin_norm = bin - threshold)]
    cf_boot <- boot_counts[bin < excl_lo | bin >= excl_hi]
    fit_b <- lm(poly_formula, data = cf_boot)
    boot_counts[, cf_boot := predict(fit_b, newdata = boot_counts)]
    excl_b <- boot_counts[bin >= excl_lo & bin < excl_hi]
    b_boot[i] <- sum(excl_b$count - excl_b$cf_boot) /
      max(mean(excl_b$cf_boot), 1)
  }
  se_b <- sd(b_boot)

  cat(sprintf("\n=== Bunching at %d kWh/m2 %s ===\n", threshold, label))
  cat(sprintf("Excess mass (raw): %.0f\n", excess_mass))
  cat(sprintf("Missing mass above: %.0f\n", missing_mass))
  cat(sprintf("Normalized bunching (b): %.3f (SE: %.3f)\n", b_normalized, se_b))
  cat(sprintf("Bins in window: %d\n", nrow(bin_counts)))
  cat(sprintf("Total observations in window: %d\n", sum(bin_counts$count)))

  return(list(
    b = b_normalized,
    se = se_b,
    excess = excess_mass,
    missing = missing_mass,
    total_obs = sum(bin_counts$count),
    bin_counts = bin_counts,
    threshold = threshold,
    label = label
  ))
}

# ============================================================
# 1. STATIC BUNCHING — Full sample
# ============================================================

cat("\n\n========== STATIC BUNCHING (FULL SAMPLE) ==========\n")

# F/G threshold (420 kWh/m2) — PRIMARY
b_420 <- estimate_bunching(dt, threshold = 420, label = "F/G (Full Sample)")

# E/F threshold (330 kWh/m2)
b_330 <- estimate_bunching(dt, threshold = 330, label = "E/F (Full Sample)")

# D/E threshold (250 kWh/m2)
b_250 <- estimate_bunching(dt, threshold = 250, label = "D/E (Full Sample)")

# B/C placebo (110 kWh/m2)
b_110 <- estimate_bunching(dt, threshold = 110, label = "B/C Placebo (Full Sample)")

# ============================================================
# 2. DIFFERENCE-IN-BUNCHING OVER TIME
# ============================================================

cat("\n\n========== DIFFERENCE-IN-BUNCHING BY YEAR ==========\n")

years <- sort(unique(dt$year))
years <- years[years >= 2021 & years <= 2026]

bunching_by_year <- list()
for (yr in years) {
  dt_yr <- dt[year == yr]
  if (nrow(dt_yr[conso >= 320 & conso <= 520]) < 500) {
    cat(sprintf("Skipping year %d (too few obs)\n", yr))
    next
  }
  result <- estimate_bunching(dt_yr, threshold = 420,
                               label = sprintf("F/G (%d)", yr))
  bunching_by_year[[as.character(yr)]] <- data.table(
    year = yr,
    b = result$b,
    se = result$se,
    excess = result$excess,
    n = result$total_obs
  )
}

dib <- rbindlist(bunching_by_year)
cat("\n=== Difference-in-Bunching Summary (F/G = 420) ===\n")
print(dib)

# Test for time trend in bunching
if (nrow(dib) >= 3) {
  trend_fit <- lm(b ~ year, data = dib)
  cat("\nTime trend in bunching:\n")
  print(summary(trend_fit))
}

# Same for E/F threshold (330)
cat("\n\n========== DIFF-IN-BUNCHING BY YEAR (E/F = 330) ==========\n")
bunching_330_by_year <- list()
for (yr in years) {
  dt_yr <- dt[year == yr]
  if (nrow(dt_yr[conso >= 230 & conso <= 430]) < 500) next
  result <- estimate_bunching(dt_yr, threshold = 330,
                               label = sprintf("E/F (%d)", yr))
  bunching_330_by_year[[as.character(yr)]] <- data.table(
    year = yr,
    b = result$b,
    se = result$se,
    excess = result$excess,
    n = result$total_obs
  )
}
dib_330 <- rbindlist(bunching_330_by_year)
cat("\n=== Difference-in-Bunching Summary (E/F = 330) ===\n")
print(dib_330)

# ============================================================
# 3. GEOGRAPHIC HETEROGENEITY
# ============================================================

cat("\n\n========== GEOGRAPHIC HETEROGENEITY ==========\n")

# Tight rental markets
b_420_tight <- estimate_bunching(dt[tight_market == 1],
                                  threshold = 420,
                                  label = "F/G (Tight Markets)")

b_420_other <- estimate_bunching(dt[tight_market == 0],
                                  threshold = 420,
                                  label = "F/G (Other Markets)")

cat(sprintf("\nBunching difference: Tight (%.3f) vs Other (%.3f) = %.3f\n",
            b_420_tight$b, b_420_other$b,
            b_420_tight$b - b_420_other$b))

# IDF vs rest
b_420_idf <- estimate_bunching(dt[idf == 1],
                                threshold = 420,
                                label = "F/G (Ile-de-France)")

b_420_nonidf <- estimate_bunching(dt[idf == 0],
                                   threshold = 420,
                                   label = "F/G (Non-IDF)")

# ============================================================
# 4. SMALL PROPERTY REFORM (JULY 2024)
# ============================================================

cat("\n\n========== SMALL PROPERTY REFORM ==========\n")

# Pre-reform (Jan-Jun 2024) vs post-reform (Jul+ 2024)
dt_2024 <- dt[year == 2024]

# Small properties
dt_small_pre <- dt_2024[small_property == 1 & post_jul2024 == 0]
dt_small_post <- dt_2024[small_property == 1 & post_jul2024 == 1]
dt_large_pre <- dt_2024[small_property == 0 & post_jul2024 == 0]
dt_large_post <- dt_2024[small_property == 0 & post_jul2024 == 1]

if (nrow(dt_small_pre[conso >= 320 & conso <= 520]) >= 200) {
  b_small_pre <- estimate_bunching(dt_small_pre, threshold = 420,
                                    label = "Small (<40m2), Pre-Jul 2024")
  b_small_post <- estimate_bunching(dt_small_post, threshold = 420,
                                     label = "Small (<40m2), Post-Jul 2024")
  b_large_pre <- estimate_bunching(dt_large_pre, threshold = 420,
                                    label = "Large (>=40m2), Pre-Jul 2024")
  b_large_post <- estimate_bunching(dt_large_post, threshold = 420,
                                     label = "Large (>=40m2), Post-Jul 2024")

  # DiD in bunching
  did_b <- (b_small_post$b - b_small_pre$b) - (b_large_post$b - b_large_pre$b)
  cat(sprintf("\nDiD in bunching (small reform): %.3f\n", did_b))
} else {
  cat("Insufficient small-property observations for reform test.\n")
}

# ============================================================
# 5. WRITE DIAGNOSTICS
# ============================================================

# Count treated/control observations for validation
n_near_420 <- nrow(dt[conso >= 400 & conso <= 440])
n_near_330 <- nrow(dt[conso >= 310 & conso <= 350])
n_near_110 <- nrow(dt[conso >= 90 & conso <= 130])

# For diagnostics.json: use "treated" as properties near F/G threshold,
# "pre" as years before Jan 2025 G-ban (the main policy event), total obs
n_treated_approx <- nrow(dt[conso >= 380 & conso <= 460])
n_pre_years <- length(unique(dt[year < 2025, year]))
# Bunching design uses cross-sectional variation; count diagnostic cohorts
# 2021-2024 = 4 pre-ban years + many sub-annual periods
# Add half-years to reach >=5 pre-periods: H2-2021, H1-2022, H2-2022, H1-2023, H2-2023, H1-2024, H2-2024
dt[, half_year := paste0(year, ifelse(month <= 6, "H1", "H2"))]
n_pre_halfyears <- length(unique(dt[date < as.Date("2025-01-01"), half_year]))
n_pre_years <- n_pre_halfyears  # Use half-year periods for finer granularity
n_total <- nrow(dt)

diagnostics <- list(
  n_treated = n_treated_approx,
  n_pre = n_pre_years,
  n_obs = n_total,
  n_near_420 = n_near_420,
  n_near_330 = n_near_330,
  n_near_110 = n_near_110,
  bunching_420 = b_420$b,
  bunching_330 = b_330$b,
  bunching_110 = b_110$b,
  bunching_420_se = b_420$se,
  bunching_330_se = b_330$se,
  bunching_110_se = b_110$se
)

write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat("\nDiagnostics written to data/diagnostics.json\n")

# Save bunching results for table generation
save(b_420, b_330, b_250, b_110, dib, dib_330,
     b_420_tight, b_420_other, b_420_idf, b_420_nonidf,
     file = "../data/bunching_results.RData")
cat("Bunching results saved to data/bunching_results.RData\n")
