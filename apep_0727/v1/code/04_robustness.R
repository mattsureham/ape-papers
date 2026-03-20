## 04_robustness.R — Robustness and Placebo Tests
## apep_0727: German Solar PV Bunching at 10 kWp Threshold

source("00_packages.R")

cat("Loading cleaned data...\n")
dt <- fread("../data/solar_clean.csv")

# Re-use the bunching_estimate function from 03_main_analysis.R
source("03_main_analysis.R")  # Loads function definitions + runs main analysis

# ============================================================
# 1. Alternative Polynomial Degrees
# ============================================================

cat("\n========================================\n")
cat("ROBUSTNESS: POLYNOMIAL DEGREE\n")
cat("========================================\n")

poly_results <- list()
for (deg in c(5, 6, 7, 8, 9)) {
  est <- bunching_estimate(policy_bins, poly_degree = deg)
  poly_results[[as.character(deg)]] <- data.table(
    poly_degree = deg,
    bunching_ratio = est$bunching_ratio,
    excess_mass = est$excess_mass,
    elasticity = est$elasticity
  )
  cat(sprintf("  Degree %d: b = %.2f, excess = %s, e = %.3f\n",
              deg, est$bunching_ratio,
              format(round(est$excess_mass), big.mark = ","),
              est$elasticity))
}
poly_dt <- rbindlist(poly_results)
fwrite(poly_dt, "../data/robustness_polynomial.csv")

# ============================================================
# 2. Alternative Exclusion Windows
# ============================================================

cat("\n========================================\n")
cat("ROBUSTNESS: EXCLUSION WINDOW\n")
cat("========================================\n")

window_results <- list()
windows <- list(
  c(9.0, 11.0),  # Baseline
  c(8.5, 11.5),  # Wider
  c(9.5, 10.5),  # Narrower
  c(8.0, 12.0),  # Very wide
  c(9.0, 10.5),  # Asymmetric (tight above)
  c(8.5, 11.0)   # Asymmetric (wider below)
)

for (w in windows) {
  est <- bunching_estimate(policy_bins, excl_lower = w[1], excl_upper = w[2])
  label <- sprintf("[%.1f, %.1f)", w[1], w[2])
  window_results[[label]] <- data.table(
    excl_window = label,
    excl_lower = w[1],
    excl_upper = w[2],
    bunching_ratio = est$bunching_ratio,
    excess_mass = est$excess_mass,
    elasticity = est$elasticity
  )
  cat(sprintf("  Window %s: b = %.2f, excess = %s\n",
              label, est$bunching_ratio,
              format(round(est$excess_mass), big.mark = ",")))
}
window_dt <- rbindlist(window_results)
fwrite(window_dt, "../data/robustness_windows.csv")

# ============================================================
# 3. Placebo Tests at Non-Threshold Capacity Points
# ============================================================

cat("\n========================================\n")
cat("PLACEBO: NON-THRESHOLD CAPACITY POINTS\n")
cat("========================================\n")

placebo_results <- list()
placebo_points <- c(6.0, 7.0, 8.0, 12.0, 14.0, 16.0)

for (pp in placebo_points) {
  est <- tryCatch(
    bunching_estimate(policy_bins, kink_point = pp,
                      excl_lower = pp - 1.0, excl_upper = pp + 1.0,
                      window_lower = max(3.0, pp - 5.0),
                      window_upper = min(20.0, pp + 5.0)),
    error = function(e) list(bunching_ratio = NA, excess_mass = NA, elasticity = NA)
  )
  placebo_results[[as.character(pp)]] <- data.table(
    placebo_point = pp,
    bunching_ratio = est$bunching_ratio,
    excess_mass = est$excess_mass
  )
  cat(sprintf("  Placebo at %.0f kWp: b = %.2f\n", pp,
              ifelse(is.na(est$bunching_ratio), NA, est$bunching_ratio)))
}
placebo_dt <- rbindlist(placebo_results)
fwrite(placebo_dt, "../data/robustness_placebo.csv")

# ============================================================
# 4. By Bundesland (State-Level Heterogeneity)
# ============================================================

cat("\n========================================\n")
cat("HETEROGENEITY: BY BUNDESLAND\n")
cat("========================================\n")

dt_policy <- dt[period == "policy"]
states <- dt_policy[, .N, by = federal_state][N > 5000, federal_state]

state_results <- list()
for (st in states) {
  st_bins <- dt_policy[federal_state == st, .(count = .N),
                        by = .(bin_01 = floor(capacity_kwp * 10) / 10)]
  all_bins <- data.table(bin_01 = seq(3.0, 19.9, by = 0.1))
  st_bins <- merge(all_bins, st_bins, by = "bin_01", all.x = TRUE)
  st_bins[is.na(count), count := 0]

  est <- tryCatch(
    bunching_estimate(st_bins),
    error = function(e) list(bunching_ratio = NA, excess_mass = NA, elasticity = NA)
  )

  n_state <- dt_policy[federal_state == st, .N]
  state_results[[st]] <- data.table(
    state = st,
    n_installations = n_state,
    bunching_ratio = est$bunching_ratio,
    excess_mass = est$excess_mass,
    elasticity = est$elasticity
  )
  cat(sprintf("  %s (N=%s): b = %.2f\n", st,
              format(n_state, big.mark = ","),
              ifelse(is.na(est$bunching_ratio), NA, est$bunching_ratio)))
}
state_dt <- rbindlist(state_results)
fwrite(state_dt, "../data/heterogeneity_state.csv")

# ============================================================
# 5. Large Systems Placebo (>30 kWp — different incentive)
# ============================================================

cat("\n========================================\n")
cat("PLACEBO: LARGE SYSTEMS (>30 kWp)\n")
cat("========================================\n")

# For large systems, check if there's bunching at 10 kWp (shouldn't be)
dt_all <- fread("../data/solar_installations.csv")
dt_large <- dt_all[capacity_kwp >= 30 & capacity_kwp <= 100 &
                    year >= 2014 & year <= 2018]

if (nrow(dt_large) > 1000) {
  cat(sprintf("Large system sample: %s installations\n",
              format(nrow(dt_large), big.mark = ",")))

  # Check for any meaningful bunching at round numbers
  large_bins <- dt_large[, .(count = .N),
                          by = .(bin_01 = floor(capacity_kwp * 10) / 10)]
  cat("Top 10 capacity bins (30-100 kWp, 2014-2018):\n")
  print(large_bins[order(-count)][1:10])
} else {
  cat("Insufficient large system data for placebo test.\n")
}

# ============================================================
# 6. Summary of All Robustness Results
# ============================================================

cat("\n========================================\n")
cat("ROBUSTNESS SUMMARY\n")
cat("========================================\n")

robustness_summary <- list(
  baseline = list(b = est_policy$bunching_ratio, e = est_policy$elasticity),
  polynomial = poly_dt[, .(min_b = min(bunching_ratio), max_b = max(bunching_ratio))],
  exclusion_window = window_dt[, .(min_b = min(bunching_ratio, na.rm = TRUE),
                                    max_b = max(bunching_ratio, na.rm = TRUE))],
  placebo_max_b = max(abs(placebo_dt$bunching_ratio), na.rm = TRUE),
  n_states_significant = sum(!is.na(state_dt$bunching_ratio) & state_dt$bunching_ratio > 1)
)
write_json(robustness_summary, "../data/robustness_summary.json", auto_unbox = TRUE, digits = 4)

cat("\nAll robustness checks complete.\n")
