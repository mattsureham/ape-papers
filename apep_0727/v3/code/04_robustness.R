## 04_robustness.R — Robustness, Mechanism, and Placebo Tests (V2)
## apep_0727 v2: German Solar PV Bunching at 10 kWp Threshold

source("00_packages.R")

cat("Loading analysis data...\n")
dt_10 <- fread("../data/solar_clean_10.csv")
dt_gm <- fread("../data/solar_gm_10.csv")

# Integer bins to avoid floating-point issues
dt_10[, bin_int := as.integer(floor(capacity_kwp * 10))]
dt_gm[, bin_int := as.integer(floor(capacity_kwp * 10))]
all_bins_int <- data.table(bin_int = 30L:199L)

# Bunching estimator (integer version)
bunching_est_int <- function(bin_data, kink_int = 100L,
                              excl_lower = 90L, excl_upper = 110L,
                              window_lower = 30L, window_upper = 199L,
                              poly_degree = 7) {
  bd <- copy(bin_data[bin_int >= window_lower & bin_int <= window_upper])
  bd[, excluded := bin_int >= excl_lower & bin_int < excl_upper]
  bd[, z := bin_int - kink_int]
  for (p in 1:poly_degree) bd[, paste0("z", p) := z^p]
  fit <- lm(as.formula(paste0("count ~ ", paste(paste0("z", 1:poly_degree), collapse = " + "))),
             data = bd[excluded == FALSE])
  bd[, counterfactual := pmax(predict(fit, newdata = bd), 0)]
  excess <- sum(bd[excluded == TRUE, count - counterfactual])
  f0 <- bd[bin_int == kink_int, counterfactual]
  if (length(f0) == 0 || is.na(f0) || f0 <= 0) f0 <- mean(bd[excluded == FALSE]$counterfactual)
  list(bunching_ratio = excess / f0, excess_mass = excess)
}

# Helper: create bin counts for a subset
make_bins <- function(dt_sub) {
  bins <- dt_sub[, .(count = .N), by = bin_int]
  bins <- merge(all_bins_int, bins, by = "bin_int", all.x = TRUE)
  bins[is.na(count), count := 0L]
  bins
}

# ============================================================
# 1. POLYNOMIAL DEGREE ROBUSTNESS
# ============================================================

cat("\n=== Polynomial Degree Robustness (Surcharge Period) ===\n")
sur_bins <- make_bins(dt_10[period == "3_surcharge"])

poly_results <- list()
for (deg in c(5, 6, 7, 8, 9)) {
  est <- bunching_est_int(sur_bins, poly_degree = deg)
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
  est <- bunching_est_int(sur_bins, excl_lower = w[1], excl_upper = w[2])
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
    bunching_est_int(sur_bins, kink_int = pp,
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
    bunching_est_int(gm_bins),
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
  est <- tryCatch(bunching_est_int(yr_bins),
                   error = function(e) list(bunching_ratio = NA))
  cat(sprintf("  %d: b = %.1f\n", yr, est$bunching_ratio))
}

cat("\nKink contribution (2013 - 2011): ")
b_2013 <- tryCatch(bunching_est_int(make_bins(dt_10[year == 2013]))$bunching_ratio, error = function(e) NA)
b_2011 <- tryCatch(bunching_est_int(make_bins(dt_10[year == 2011]))$bunching_ratio, error = function(e) NA)
b_2014 <- tryCatch(bunching_est_int(make_bins(dt_10[year == 2014]))$bunching_ratio, error = function(e) NA)
cat(sprintf("%.1f\n", b_2013 - b_2011))
cat(sprintf("Notch contribution (2014 - 2013): %.1f\n", b_2014 - b_2013))
cat(sprintf("Notch/kink ratio: %.1f\n", (b_2014 - b_2013) / max(b_2013 - b_2011, 0.01)))

kink_notch <- data.frame(
  year = c(2011, 2012, 2013, 2014, 2015),
  bunching_ratio = c(b_2011,
    tryCatch(bunching_est_int(make_bins(dt_10[year == 2012]))$bunching_ratio, error = function(e) NA),
    b_2013, b_2014,
    tryCatch(bunching_est_int(make_bins(dt_10[year == 2015]))$bunching_ratio, error = function(e) NA)),
  stringsAsFactors = FALSE)
fwrite(as.data.table(kink_notch), "../data/mechanism_kink_notch.csv")

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
