## 03_main_analysis.R — Main Bunching Analysis (Revised)
## apep_1198: UK FIT Solar Bunching — Hidden Notches at Capacity Thresholds
##
## Analysis structure:
## 1. Raw bunching ratios at 4 kW (annual, FIT vs post-merger)
## 2. Missing-tail share above 4 kW (the "missing middle" analog)
## 3. Within-threshold placebos: 3.68, 3.92, 3.99 kW mass points
## 4. Kleven-Waseem estimator at 10 kW (where distribution is smoother)
## 5. Annual bunching at 10 kW (control threshold)
## 6. Supplementary: 50 kW (appendix)

source("code/00_packages.R")
source("code/00_bunching_estimator.R")

# ============================================================
# LOAD CLEANED DATA
# ============================================================

dt <- fread("data/ofgem_fit_solar_clean.csv")
dt[, commission_date := as.Date(commission_date)]
cat(sprintf("Loaded %s installations\n", format(nrow(dt), big.mark = ",")))

# ============================================================
# 1. RAW BUNCHING AT 4 kW — ANNUAL
# ============================================================

cat("\n========================================\n")
cat("1. RAW BUNCHING RATIOS AT 4 kW (ANNUAL)\n")
cat("========================================\n")

# Define: ratio = count in [4.0, 4.0] / mean count in [4.1, 4.5] per 0.1 bin
annual_4kw_raw <- data.table()
for (yr in 2010:2019) {
  d <- dt[commission_year == yr]

  # Count at exactly 4.0 kW (bin_int == 40)
  n_at <- nrow(d[bin_int == 40L])

  # Average count in bins 41-45 (4.1-4.5 kW range)
  above_counts <- d[bin_int >= 41L & bin_int <= 45L, .N, by = bin_int]
  if (nrow(above_counts) > 0) {
    avg_above <- sum(above_counts$N) / 5  # 5 bins
  } else {
    avg_above <- 0
  }

  raw_ratio <- ifelse(avg_above > 0, n_at / avg_above, Inf)

  # Also: share of installations in [4.0, 4.5] that are at exactly 4.0
  n_range <- nrow(d[bin_int >= 40L & bin_int <= 45L])
  share_at <- ifelse(n_range > 0, n_at / n_range, NA)

  annual_4kw_raw <- rbind(annual_4kw_raw, data.table(
    year = yr,
    n_at_4 = n_at,
    avg_above = round(avg_above, 1),
    raw_ratio = round(raw_ratio, 1),
    share_at_4 = round(share_at, 4),
    n_total = nrow(d[capacity_kw >= 3.0 & capacity_kw <= 5.0])
  ))

  cat(sprintf("  %d: at 4.0 = %6d, avg above = %5.1f, ratio = %7.1f:1, share = %.1f%%\n",
              yr, n_at, avg_above, raw_ratio, 100 * share_at))
}

fwrite(annual_4kw_raw, "data/annual_4kw_raw.csv")

# ============================================================
# 2. MISSING TAIL: SHARE OF INSTALLATIONS ABOVE 4 kW
# ============================================================

cat("\n========================================\n")
cat("2. MISSING TAIL ABOVE 4 kW\n")
cat("========================================\n")

# In the [3.5, 5.0] kW window, what share falls above 4.0?
for (period in c("FIT_bands", "post_merger")) {
  d <- dt[regime == period & capacity_kw >= 3.5 & capacity_kw <= 5.0]
  n_total <- nrow(d)
  n_above <- nrow(d[capacity_kw > 4.0])
  share_above <- n_above / n_total

  cat(sprintf("\n%s: N = %s, above 4.0 kW = %s (%.1f%%)\n",
              period, format(n_total, big.mark = ","),
              format(n_above, big.mark = ","),
              100 * share_above))
}

# Annual missing-tail share
cat("\nAnnual share above 4.0 kW (in [3.5, 5.0] window):\n")
annual_tail <- data.table()
for (yr in 2010:2019) {
  d <- dt[commission_year == yr & capacity_kw >= 3.5 & capacity_kw <= 5.0]
  n_above <- nrow(d[capacity_kw > 4.0])
  share <- n_above / nrow(d)
  annual_tail <- rbind(annual_tail, data.table(
    year = yr, n_total = nrow(d), n_above = n_above,
    share_above = round(share, 4)
  ))
  cat(sprintf("  %d: %.2f%% above 4.0 kW\n", yr, 100 * share))
}
fwrite(annual_tail, "data/annual_missing_tail.csv")

# ============================================================
# 3. WITHIN-THRESHOLD PLACEBOS (3.68, 3.92, 3.99)
# ============================================================

cat("\n========================================\n")
cat("3. WITHIN-THRESHOLD PLACEBOS\n")
cat("========================================\n")

# If bunching at 4.0 is purely policy-driven, nearby mass points should NOT
# respond to the 2016 reform. 3.68 (single-phase norm), 3.92, 3.96, 3.99
# are all module-configuration mass points.

placebo_caps <- c(3.68, 3.84, 3.92, 3.96, 3.99, 4.00)
cat("\nMass at specific capacities by regime:\n")
placebo_table <- data.table()
for (cap in placebo_caps) {
  for (period in c("FIT_bands", "post_merger")) {
    d <- dt[regime == period]
    # Match to 0.01 kW precision
    n <- nrow(d[abs(capacity_kw - cap) < 0.005])
    n_total <- nrow(d[capacity_kw >= 3.5 & capacity_kw <= 4.5])
    share <- n / n_total
    placebo_table <- rbind(placebo_table, data.table(
      capacity = cap, regime = period, count = n,
      total = n_total, share = round(share, 5)
    ))
  }
}

# Pivot and compute ratio
placebo_wide <- dcast(placebo_table, capacity ~ regime, value.var = "share")
placebo_wide[, ratio := FIT_bands / post_merger]
print(placebo_wide)
fwrite(placebo_table, "data/placebo_mass_points.csv")

# ============================================================
# 4. KLEVEN-WASEEM ESTIMATOR AT 10 kW
# ============================================================

cat("\n========================================\n")
cat("4. BUNCHING AT 10 kW (KLEVEN-WASEEM)\n")
cat("========================================\n")

results_10kw <- list()
for (period in c("FIT_bands", "post_merger")) {
  dt_sub <- dt[regime == period & capacity_kw >= 5.0 & capacity_kw < 15.0]
  bins <- make_bins_int(dt_sub, window_lower = 50L, window_upper = 149L)

  est <- bunching_estimate_int(bins,
                                kink_int = 100L,
                                excl_lower = 95L,
                                excl_upper = 105L,
                                window_lower = 50L,
                                window_upper = 149L,
                                poly_degree = 7L)

  boot <- bootstrap_bunching_int(dt_sub,
                                  kink_int = 100L,
                                  excl_lower = 95L,
                                  excl_upper = 105L,
                                  window_lower = 50L,
                                  window_upper = 149L,
                                  poly_degree = 7L,
                                  n_boot = 500L)

  results_10kw[[period]] <- list(est = est, boot = boot)

  cat(sprintf("\n%s:\n", period))
  cat(sprintf("  N installations: %s\n", format(nrow(dt_sub), big.mark = ",")))
  cat(sprintf("  Bunching ratio: %.1f (SE: %.1f)\n",
              est$bunching_ratio, boot$se_bunching))
  cat(sprintf("  95%% CI: [%.1f, %.1f]\n", boot$ci_lower, boot$ci_upper))
  cat(sprintf("  Excess mass: %.0f\n", est$excess_mass))
}

# ============================================================
# 5. ANNUAL BUNCHING AT 10 kW
# ============================================================

cat("\n========================================\n")
cat("5. ANNUAL BUNCHING AT 10 kW\n")
cat("========================================\n")

annual_10kw <- data.table()
for (yr in 2010:2019) {
  dt_yr <- dt[commission_year == yr & capacity_kw >= 5.0 & capacity_kw < 15.0]
  if (nrow(dt_yr) < 100) next

  bins <- make_bins_int(dt_yr, window_lower = 50L, window_upper = 149L)

  est <- bunching_estimate_int(bins,
                                kink_int = 100L,
                                excl_lower = 95L,
                                excl_upper = 105L,
                                window_lower = 50L,
                                window_upper = 149L,
                                poly_degree = 7L)

  boot <- bootstrap_bunching_int(dt_yr,
                                  kink_int = 100L,
                                  excl_lower = 95L,
                                  excl_upper = 105L,
                                  window_lower = 50L,
                                  window_upper = 149L,
                                  poly_degree = 7L,
                                  n_boot = 500L)

  annual_10kw <- rbind(annual_10kw, data.table(
    year = yr,
    bunching_ratio = round(est$bunching_ratio, 1),
    se = round(boot$se_bunching, 1),
    ci_lower = round(boot$ci_lower, 1),
    ci_upper = round(boot$ci_upper, 1),
    excess_mass = round(est$excess_mass, 0),
    n_obs = nrow(dt_yr)
  ))

  cat(sprintf("  %d: b = %6.1f (SE = %5.1f), N = %s\n",
              yr, est$bunching_ratio, boot$se_bunching,
              format(nrow(dt_yr), big.mark = ",")))
}

fwrite(annual_10kw, "data/annual_bunching_10kw.csv")

# ============================================================
# 6. SUPPLEMENTARY: 50 kW
# ============================================================

cat("\n========================================\n")
cat("6. BUNCHING AT 50 kW (SUPPLEMENTARY)\n")
cat("========================================\n")

for (period in c("FIT_bands", "post_merger")) {
  dt_sub <- dt[regime == period & capacity_kw >= 30.0 & capacity_kw < 70.0]
  if (nrow(dt_sub) < 100) {
    cat(sprintf("\n%s: N = %d (too few)\n", period, nrow(dt_sub)))
    next
  }

  bins <- make_bins_int(dt_sub, window_lower = 300L, window_upper = 699L)

  est <- bunching_estimate_int(bins,
                                kink_int = 500L,
                                excl_lower = 480L,
                                excl_upper = 520L,
                                window_lower = 300L,
                                window_upper = 699L,
                                poly_degree = 7L)

  boot <- bootstrap_bunching_int(dt_sub,
                                  kink_int = 500L,
                                  excl_lower = 480L,
                                  excl_upper = 520L,
                                  window_lower = 300L,
                                  window_upper = 699L,
                                  poly_degree = 7L,
                                  n_boot = 500L)

  cat(sprintf("\n%s:\n", period))
  cat(sprintf("  N installations: %s\n", format(nrow(dt_sub), big.mark = ",")))
  cat(sprintf("  Bunching ratio: %.1f (SE: %.1f)\n",
              est$bunching_ratio, boot$se_bunching))
  cat(sprintf("  95%% CI: [%.1f, %.1f]\n", boot$ci_lower, boot$ci_upper))
}

# ============================================================
# 7. SAVE ALL RESULTS
# ============================================================

save_results <- list(
  pooled_10kw_fit = list(
    bunching_ratio = results_10kw$FIT_bands$est$bunching_ratio,
    se = results_10kw$FIT_bands$boot$se_bunching,
    excess_mass = results_10kw$FIT_bands$est$excess_mass
  ),
  pooled_10kw_post = list(
    bunching_ratio = results_10kw$post_merger$est$bunching_ratio,
    se = results_10kw$post_merger$boot$se_bunching,
    excess_mass = results_10kw$post_merger$est$excess_mass
  )
)

write(toJSON(save_results, auto_unbox = TRUE, pretty = TRUE),
      "data/main_results.json")

# Update diagnostics
diag <- fromJSON("data/diagnostics.json")
diag$n_treated <- nrow(dt[regime == "FIT_bands"])
diag$n_pre <- length(unique(dt[regime == "FIT_bands"]$commission_year))
write(toJSON(diag, auto_unbox = TRUE, pretty = TRUE), "data/diagnostics.json")

cat("\nSaved all results.\n")
cat("03_main_analysis.R complete.\n")
