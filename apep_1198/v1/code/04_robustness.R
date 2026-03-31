## 04_robustness.R — Robustness Checks
## apep_1198: UK FIT Solar Bunching — Hidden Notches at Capacity Thresholds

source("code/00_packages.R")
source("code/00_bunching_estimator.R")

dt <- fread("data/ofgem_fit_solar_clean.csv")
dt[, commission_date := as.Date(commission_date)]

# ============================================================
# 1. SPECIFICATION FAMILY AT 10 kW
# ============================================================

cat("\n========================================\n")
cat("1. SPECIFICATION FAMILY AT 10 kW (FIT period)\n")
cat("========================================\n")

spec_family <- data.table()
dt_fit <- dt[regime == "FIT_bands" & capacity_kw >= 3.0 & capacity_kw < 20.0]

for (deg in c(6L, 7L, 8L)) {
  for (excl in list(c(95L, 105L), c(90L, 110L), c(85L, 115L))) {
    bins <- make_bins_int(dt_fit, window_lower = 50L, window_upper = 149L)
    est <- bunching_estimate_int(bins,
                                  kink_int = 100L,
                                  excl_lower = excl[1],
                                  excl_upper = excl[2],
                                  window_lower = 50L,
                                  window_upper = 149L,
                                  poly_degree = deg)

    spec_family <- rbind(spec_family, data.table(
      degree = deg,
      excl_window = sprintf("[%s, %s)", excl[1] / 10, excl[2] / 10),
      bunching_ratio = round(est$bunching_ratio, 1),
      excess_mass = round(est$excess_mass, 0)
    ))

    cat(sprintf("  deg %d, [%s, %s): b = %.1f, excess = %.0f\n",
                deg, excl[1] / 10, excl[2] / 10,
                est$bunching_ratio, est$excess_mass))
  }
}

fwrite(spec_family, "data/spec_family_10kw.csv")

# ============================================================
# 2. RAW RATIO ROBUSTNESS: ALTERNATIVE BINS AT 4 kW
# ============================================================

cat("\n========================================\n")
cat("2. RAW RATIO ALTERNATIVES AT 4 kW\n")
cat("========================================\n")

# Try different denominator definitions
for (period in c("FIT_bands", "post_merger")) {
  d <- dt[regime == period]

  # A: count at 4.0 / average of [4.1, 4.5] bins (main)
  n_at <- nrow(d[bin_int == 40L])
  avg_41_45 <- nrow(d[bin_int >= 41L & bin_int <= 45L]) / 5
  ratio_A <- n_at / avg_41_45

  # B: count at 4.0 / count at 4.0 using [3.6, 3.8] average as baseline
  avg_36_38 <- nrow(d[bin_int >= 36L & bin_int <= 38L]) / 3
  ratio_B <- n_at / avg_36_38

  # C: excess above = (count at 4.0) - (average of adjacent non-policy bins)
  # Use average of [3.5, 3.9] and [4.5, 5.0] as counterfactual
  avg_below <- nrow(d[bin_int >= 35L & bin_int <= 39L]) / 5
  avg_above <- nrow(d[bin_int >= 45L & bin_int <= 50L]) / 6
  avg_cf <- (avg_below + avg_above) / 2
  excess_ratio <- (n_at - avg_cf) / avg_cf

  cat(sprintf("\n%s:\n", period))
  cat(sprintf("  Ratio A (4.0 / avg 4.1-4.5): %.1f\n", ratio_A))
  cat(sprintf("  Ratio B (4.0 / avg 3.6-3.8): %.1f\n", ratio_B))
  cat(sprintf("  Excess ratio (4.0 - cf) / cf: %.1f\n", excess_ratio))
}

# ============================================================
# 3. INSTALLED CAPACITY VS DNC COMPARISON
# ============================================================

cat("\n========================================\n")
cat("3. INSTALLED CAPACITY VS DNC\n")
cat("========================================\n")

# Some systems have installed > DNC (inverter-limited, or DNC adjusted)
dt[, installed_kw := as.numeric(installed_capacity)]
dt[, cap_gap := installed_kw - capacity_kw]

cat("Systems where installed > DNC (FIT period):\n")
d <- dt[regime == "FIT_bands" & !is.na(installed_kw)]
cat(sprintf("  Total: %s\n", format(nrow(d), big.mark = ",")))
cat(sprintf("  installed > DNC: %s (%.1f%%)\n",
            format(nrow(d[cap_gap > 0.01]), big.mark = ","),
            100 * mean(d$cap_gap > 0.01)))
cat(sprintf("  installed == DNC: %s (%.1f%%)\n",
            format(nrow(d[abs(cap_gap) <= 0.01]), big.mark = ","),
            100 * mean(abs(d$cap_gap) <= 0.01)))

# Among systems at DNC == 4.0, what is their installed capacity?
d_at4 <- dt[regime == "FIT_bands" & abs(capacity_kw - 4.0) < 0.01]
cat(sprintf("\nSystems with DNC == 4.0 (FIT period): %d\n", nrow(d_at4)))
cat("Installed capacity distribution:\n")
print(quantile(d_at4$installed_kw, probs = c(0, 0.05, 0.25, 0.5, 0.75, 0.95, 1),
                na.rm = TRUE))

# ============================================================
# 4. PLACEBO: NON-POLICY THRESHOLDS
# ============================================================

cat("\n========================================\n")
cat("4. PLACEBO: NON-POLICY THRESHOLDS\n")
cat("========================================\n")

# Check bunching at round numbers that are NOT policy thresholds
# (3 kW, 5 kW, 6 kW, 8 kW)
for (cap in c(30L, 50L, 60L, 80L)) {
  for (period in c("FIT_bands", "post_merger")) {
    d <- dt[regime == period]
    n_at <- nrow(d[bin_int == cap])
    n_above <- nrow(d[bin_int >= (cap + 1L) & bin_int <= (cap + 5L)])
    avg_above <- n_above / 5
    ratio <- ifelse(avg_above > 0, n_at / avg_above, Inf)

    cat(sprintf("  %s kW, %s: at = %d, avg above = %.1f, ratio = %.1f\n",
                cap / 10, period, n_at, avg_above, ratio))
  }
}

cat("\n04_robustness.R complete.\n")
