## 04_robustness.R — Robustness, Mechanism, and Placebo Tests (V4)
## apep_0727 v4: Uses unified estimator, adds installer-proxy heterogeneity

source("00_packages.R")
source("00_bunching_estimator.R")

cat("Loading analysis data...\n")
dt_10 <- fread("../data/solar_clean_10.csv")
dt_gm <- fread("../data/solar_gm_10.csv")

# Integer bins
dt_10[, bin_int := as.integer(floor(capacity_kwp * 10))]
dt_gm[, bin_int := as.integer(floor(capacity_kwp * 10))]
all_bins_int <- data.table(bin_int = 30L:199L)

# Alias for backward compatibility in this file
make_bins <- function(dt_sub) make_bins_int(dt_sub, all_bins_int)

# ============================================================
# 1. POLYNOMIAL DEGREE ROBUSTNESS
# ============================================================

cat("\n=== Polynomial Degree Robustness (Surcharge Period) ===\n")
sur_bins <- make_bins(dt_10[period == "3_surcharge"])

poly_results <- list()
for (deg in c(5, 6, 7, 8, 9)) {
  est <- bunching_estimate_int(sur_bins, poly_degree = deg)
  poly_results[[as.character(deg)]] <- data.frame(
    poly_degree = deg, bunching_ratio = round(est$bunching_ratio, 2),
    excess_mass = round(est$excess_mass))
  cat(sprintf("  Degree %d: b = %.1f, excess = %s\n",
      deg, est$bunching_ratio, format(round(est$excess_mass), big.mark = ",")))
}
poly_dt <- as.data.table(do.call(rbind, poly_results))
fwrite(poly_dt, "../data/robustness_polynomial.csv")

# ============================================================
# 2. EXCLUSION WINDOW ROBUSTNESS
# ============================================================

cat("\n=== Exclusion Window Robustness ===\n")
windows <- list(
  c(90L, 110L),   # Baseline [9.0, 11.0)
  c(85L, 115L),   # Wider
  c(95L, 105L),   # Narrower
  c(80L, 120L),   # Very wide
  c(90L, 105L),   # Asymmetric tight above
  c(85L, 110L)    # Asymmetric wider below
)

window_results <- list()
for (w in windows) {
  est <- bunching_estimate_int(sur_bins, excl_lower = w[1], excl_upper = w[2])
  label <- sprintf("[%.1f, %.1f)", w[1]/10, w[2]/10)
  window_results[[label]] <- data.frame(
    excl_window = label, bunching_ratio = round(est$bunching_ratio, 2),
    excess_mass = round(est$excess_mass))
  cat(sprintf("  Window %s: b = %.1f\n", label, est$bunching_ratio))
}
window_dt <- as.data.table(do.call(rbind, window_results))
fwrite(window_dt, "../data/robustness_windows.csv")

# ============================================================
# 3. PLACEBO TESTS AT NON-THRESHOLD POINTS
# ============================================================

cat("\n=== Placebo Tests at Non-Threshold Points ===\n")
placebo_points <- c(60L, 70L, 80L, 120L, 140L, 160L)

placebo_results <- list()
for (pp in placebo_points) {
  est <- tryCatch(
    bunching_estimate_int(sur_bins, kink_int = pp,
                      excl_lower = pp - 10L, excl_upper = pp + 10L,
                      window_lower = max(30L, pp - 50L),
                      window_upper = min(199L, pp + 50L)),
    error = function(e) list(bunching_ratio = NA, excess_mass = NA))
  placebo_results[[as.character(pp)]] <- data.frame(
    placebo_kwp = pp / 10, bunching_ratio = round(est$bunching_ratio, 2),
    excess_mass = round(est$excess_mass))
  cat(sprintf("  Placebo at %.0f kWp: b = %.1f\n", pp / 10, est$bunching_ratio))
}
placebo_dt <- as.data.table(do.call(rbind, placebo_results))
fwrite(placebo_dt, "../data/robustness_placebo.csv")

# ============================================================
# 4. GROUND-MOUNT PLACEBO
# ============================================================

cat("\n=== Ground-Mount Placebo (Surcharge Period) ===\n")
gm_bins <- make_bins(dt_gm[period == "3_surcharge"])
n_gm <- dt_gm[period == "3_surcharge", .N]
cat(sprintf("  Ground-mount sample: %s installations\n", format(n_gm, big.mark = ",")))

if (n_gm > 100) {
  est_gm <- tryCatch(
    bunching_estimate_int(gm_bins),
    error = function(e) list(bunching_ratio = NA, excess_mass = NA))
  cat(sprintf("  Ground-mount b: %.1f\n", est_gm$bunching_ratio))
} else {
  cat("  Insufficient ground-mount data for bunching estimate.\n")
  est_gm <- list(bunching_ratio = NA, excess_mass = NA)
}

# ============================================================
# 5. MODULE COUNT ANALYSIS (Mechanism)
# ============================================================

cat("\n=== Module Count Analysis (Mechanism) ===\n")

# Near-threshold systems during surcharge period
dt_near <- dt_10[period == "3_surcharge" & !is.na(n_modules) &
                  capacity_kwp >= 9.0 & capacity_kwp <= 11.0]

# Module counts by bin
module_by_bin <- dt_near[, .(
  mean_modules = mean(n_modules),
  median_modules = as.double(median(n_modules)),
  sd_modules = sd(n_modules),
  n = .N
), by = .(bin_int = as.integer(floor(capacity_kwp * 10)))]
module_by_bin <- module_by_bin[order(bin_int)]

cat("Module counts by 0.1 kWp bin (surcharge period, 9.0-11.0 kWp):\n")
print(module_by_bin[, .(kwp = bin_int / 10, mean_modules = round(mean_modules, 1),
                         median_modules, n)])
fwrite(module_by_bin, "../data/mechanism_module_count.csv")

# Module count for bunched vs non-bunched systems
dt_mechanism <- dt_10[period == "3_surcharge" & !is.na(n_modules) &
                       capacity_kwp >= 8 & capacity_kwp <= 12]
dt_mechanism[, bunched := capacity_kwp >= 9.5 & capacity_kwp < 10.0]
mechanism_summary <- dt_mechanism[, .(
  mean_modules = mean(n_modules),
  median_modules = as.double(median(n_modules)),
  mean_kwp = mean(capacity_kwp),
  n = .N
), by = bunched]
cat("\nBunched (9.5-10.0) vs non-bunched (8.0-9.5 + 10.0-12.0):\n")
print(mechanism_summary)
fwrite(mechanism_summary, "../data/mechanism_bunched_vs_not.csv")

# ============================================================
# 6. KINK vs NOTCH DECOMPOSITION
# ============================================================

cat("\n=== Kink vs Notch Decomposition ===\n")

# The key comparison: 2013 (kink only) vs 2014 (kink + notch)
for (yr in c(2011, 2012, 2013, 2014, 2015)) {
  yr_bins <- make_bins(dt_10[year == yr])
  est <- tryCatch(bunching_estimate_int(yr_bins),
                   error = function(e) list(bunching_ratio = NA))
  cat(sprintf("  %d: b = %.1f\n", yr, est$bunching_ratio))
}

cat("\nKink contribution (2013 - 2011): ")
b_2013 <- tryCatch(bunching_estimate_int(make_bins(dt_10[year == 2013]))$bunching_ratio, error = function(e) NA)
b_2011 <- tryCatch(bunching_estimate_int(make_bins(dt_10[year == 2011]))$bunching_ratio, error = function(e) NA)
b_2014 <- tryCatch(bunching_estimate_int(make_bins(dt_10[year == 2014]))$bunching_ratio, error = function(e) NA)
cat(sprintf("%.1f\n", b_2013 - b_2011))
cat(sprintf("Notch contribution (2014 - 2013): %.1f\n", b_2014 - b_2013))
cat(sprintf("Notch/kink ratio: %.1f\n", (b_2014 - b_2013) / max(b_2013 - b_2011, 0.01)))

kink_notch <- data.frame(
  year = c(2011, 2012, 2013, 2014, 2015),
  bunching_ratio = c(b_2011,
    tryCatch(bunching_estimate_int(make_bins(dt_10[year == 2012]))$bunching_ratio, error = function(e) NA),
    b_2013, b_2014,
    tryCatch(bunching_estimate_int(make_bins(dt_10[year == 2015]))$bunching_ratio, error = function(e) NA)),
  stringsAsFactors = FALSE)
fwrite(as.data.table(kink_notch), "../data/mechanism_kink_notch.csv")

# ============================================================
# Save robustness summary
# ============================================================

# ============================================================
# 7. TEMPORAL DIFFERENCE-IN-BUNCHING AT PLACEBO THRESHOLDS
# ============================================================

cat("\n=== Temporal Difference-in-Bunching at Placebo Thresholds ===\n")
cat("Test: only the POLICY threshold should show breaks aligned with policy timing\n")

temporal_dib_results <- list()
for (pp in c(60L, 80L, 100L, 120L, 140L)) {
  for (period_name in c("1_pre_fit_tier", "3_surcharge")) {
    p_data <- dt_10[period == period_name]
    if (nrow(p_data) < 1000) next
    p_bins <- make_bins(p_data)

    est <- tryCatch(
      bunching_estimate_int(p_bins, kink_int = pp,
                            excl_lower = pp - 10L, excl_upper = pp + 10L,
                            window_lower = max(30L, pp - 50L),
                            window_upper = min(199L, pp + 50L)),
      error = function(e) list(bunching_ratio = NA, excess_mass = NA)
    )

    temporal_dib_results[[length(temporal_dib_results) + 1]] <- data.frame(
      threshold_kwp = pp / 10,
      period = period_name,
      bunching_ratio = round(est$bunching_ratio, 2),
      stringsAsFactors = FALSE)
  }
}

temporal_dib_dt <- as.data.table(do.call(rbind, temporal_dib_results))
fwrite(temporal_dib_dt, "../data/robustness_temporal_dib.csv")

# Compute DiB for each threshold
cat("  Difference-in-bunching (surcharge - pre-FIT) by threshold:\n")
for (pp in c(6, 8, 10, 12, 14)) {
  pre <- temporal_dib_dt[threshold_kwp == pp & period == "1_pre_fit_tier", bunching_ratio]
  sur <- temporal_dib_dt[threshold_kwp == pp & period == "3_surcharge", bunching_ratio]
  if (length(pre) > 0 && length(sur) > 0) {
    dib <- sur - pre
    cat(sprintf("  %d kWp: pre = %.1f, surcharge = %.1f, DiB = %.1f %s\n",
        pp, pre, sur, dib,
        ifelse(pp == 10, "<-- POLICY THRESHOLD", "")))
  }
}

# ============================================================
# 8. INSTALLER-PROXY HETEROGENEITY (Phase 4 of revision plan)
# ============================================================

cat("\n=== Installer-Proxy Heterogeneity ===\n")
cat("Testing whether areas with more concentrated installer markets show sharper bunching\n")

# Use municipality (Gemeinde) as geographic unit
# Proxy: number of distinct operators in the municipality during surcharge period
if ("municipality" %in% names(dt_10) || "gemeinde" %in% names(dt_10)) {
  geo_col <- if ("municipality" %in% names(dt_10)) "municipality" else "gemeinde"
  sur_data <- dt_10[period == "3_surcharge"]

  # Count distinct operators per municipality
  muni_stats <- sur_data[, .(
    n_installations = .N,
    n_operators = uniqueN(get(grep("operator|betreiber", names(dt_10),
                                    value = TRUE, ignore.case = TRUE)[1]))
  ), by = c(geo_col)]

  # Only municipalities with enough installations
  muni_stats <- muni_stats[n_installations >= 50]
  muni_stats[, concentration := n_installations / n_operators]

  # Split into high/low concentration (above/below median)
  med_conc <- median(muni_stats$concentration)
  muni_stats[, high_concentration := concentration >= med_conc]

  cat(sprintf("  Municipalities with >=50 installations: %d\n", nrow(muni_stats)))
  cat(sprintf("  Median concentration (installs/operator): %.1f\n", med_conc))

  # Estimate bunching separately for high/low concentration areas
  for (is_high in c(TRUE, FALSE)) {
    munis <- muni_stats[high_concentration == is_high, get(geo_col)]
    sub_data <- sur_data[get(geo_col) %in% munis]
    sub_bins <- make_bins(sub_data)
    est <- tryCatch(bunching_estimate_int(sub_bins),
                     error = function(e) list(bunching_ratio = NA, excess_mass = NA))
    cat(sprintf("  %s concentration: b = %.1f (N = %s)\n",
        ifelse(is_high, "High", "Low"),
        est$bunching_ratio,
        format(nrow(sub_data), big.mark = ",")))
  }
} else if ("state" %in% names(dt_10) || "bundesland" %in% names(dt_10)) {
  # Fallback: use state-level heterogeneity (less informative)
  cat("  Municipality data not available. Using state-level heterogeneity.\n")
  state_col <- if ("state" %in% names(dt_10)) "state" else "bundesland"
  sur_data <- dt_10[period == "3_surcharge"]

  state_results <- list()
  for (st in unique(sur_data[[state_col]])) {
    st_data <- sur_data[get(state_col) == st]
    if (nrow(st_data) < 500) next
    st_bins <- make_bins(st_data)
    est <- tryCatch(bunching_estimate_int(st_bins),
                     error = function(e) list(bunching_ratio = NA))
    state_results[[st]] <- data.frame(
      state = st, bunching_ratio = round(est$bunching_ratio, 2),
      n = nrow(st_data), stringsAsFactors = FALSE)
    cat(sprintf("  %s: b = %.1f (N = %s)\n",
        st, est$bunching_ratio, format(nrow(st_data), big.mark = ",")))
  }
  state_dt <- as.data.table(do.call(rbind, state_results))
  fwrite(state_dt, "../data/robustness_state_heterogeneity.csv")

  cat(sprintf("  State-level bunching range: [%.1f, %.1f]\n",
      min(state_dt$bunching_ratio, na.rm = TRUE),
      max(state_dt$bunching_ratio, na.rm = TRUE)))
  cat(sprintf("  CV = %.2f\n",
      sd(state_dt$bunching_ratio, na.rm = TRUE) /
      mean(state_dt$bunching_ratio, na.rm = TRUE)))
} else {
  cat("  No geographic identifiers available for heterogeneity test.\n")
  cat("  Mechanism claim will be labeled as interpretation (Path B).\n")
}

# ============================================================
# 9. FINE-GRID DISTRIBUTION (0.01 kWp near threshold)
# ============================================================

cat("\n=== Fine-Grid Distribution Near 10 kWp ===\n")
sur_near <- dt_10[period == "3_surcharge" & capacity_kwp >= 9.5 & capacity_kwp <= 10.5]
fine_bins <- sur_near[, .(count = .N),
                       by = .(bin_001 = round(capacity_kwp, 2))]
fine_bins <- fine_bins[order(bin_001)]
fwrite(fine_bins, "../data/fine_grid_near_threshold.csv")
cat("  Fine-grid bins (0.01 kWp) saved. Top bins:\n")
print(head(fine_bins[order(-count)], 15))

# ============================================================
# Save robustness summary
# ============================================================

robustness_summary <- list(
  polynomial = list(min_b = min(poly_dt$bunching_ratio),
                    max_b = max(poly_dt$bunching_ratio)),
  exclusion_window = list(min_b = min(window_dt$bunching_ratio),
                          max_b = max(window_dt$bunching_ratio)),
  placebo_max_b = max(abs(placebo_dt$bunching_ratio), na.rm = TRUE),
  ground_mount_b = est_gm$bunching_ratio,
  ground_mount_n = n_gm,
  kink_contribution = b_2013 - b_2011,
  notch_contribution = b_2014 - b_2013
)
write_json(robustness_summary, "../data/robustness_summary.json", auto_unbox = TRUE, digits = 4)

cat("\nAll robustness checks complete.\n")
