# 04_robustness.R — Robustness checks for hospital bed bunching
# APEP-1150

source("00_packages.R")

dt <- fread("../data/hospital_bed_panel_clean.csv")
results <- readRDS("../data/bunching_results.rds")

# Load bunching function from main analysis
source("03_main_analysis.R")

# ============================================================
# 1. POLYNOMIAL DEGREE SENSITIVITY
# ============================================================
cat("\n=== Polynomial Degree Sensitivity ===\n")

freq_all <- dt[, .(count = .N), by = beds]
freq_nc <- dt[is_cah == FALSE, .(count = .N), by = beds]

poly_sens_25 <- data.table()
poly_sens_50 <- data.table()
poly_sens_100 <- data.table()

for (deg in 5:9) {
  r25 <- estimate_bunching(freq_all, threshold = 25, window_below = 2, window_above = 3,
                           poly_degree = deg, range_low = 5, range_high = 55, n_boot = 100)
  r50 <- estimate_bunching(freq_nc, threshold = 50, window_below = 2, window_above = 3,
                           poly_degree = deg, range_low = 20, range_high = 80, n_boot = 100)
  r100 <- estimate_bunching(freq_nc, threshold = 100, window_below = 3, window_above = 3,
                            poly_degree = deg, range_low = 60, range_high = 140, n_boot = 100)

  poly_sens_25 <- rbind(poly_sens_25, data.table(degree = deg, b = r25$normalized_b, se = r25$se_b))
  poly_sens_50 <- rbind(poly_sens_50, data.table(degree = deg, b = r50$normalized_b, se = r50$se_b))
  poly_sens_100 <- rbind(poly_sens_100, data.table(degree = deg, b = r100$normalized_b, se = r100$se_b))
}

cat("25-bed threshold (all hospitals):\n")
print(poly_sens_25)
cat("\n50-bed threshold (non-CAH):\n")
print(poly_sens_50)
cat("\n100-bed threshold (non-CAH):\n")
print(poly_sens_100)

# ============================================================
# 2. MANIPULATION WINDOW SENSITIVITY
# ============================================================
cat("\n=== Manipulation Window Sensitivity ===\n")

window_sens_25 <- data.table()
for (wb in 1:4) {
  for (wa in 1:5) {
    r <- estimate_bunching(freq_all, threshold = 25, window_below = wb, window_above = wa,
                           poly_degree = 7, range_low = 5, range_high = 55, n_boot = 50)
    window_sens_25 <- rbind(window_sens_25,
                            data.table(win_below = wb, win_above = wa,
                                       b = r$normalized_b, se = r$se_b))
  }
}
cat("25-bed window sensitivity:\n")
print(window_sens_25)

# ============================================================
# 3. DONUT-HOLE TEST — exclude hospitals at exact threshold
# ============================================================
cat("\n=== Donut-Hole Test ===\n")

# Remove hospitals at exactly 25 beds and re-estimate — should see missing mass
dt_donut <- dt[beds != 25]
freq_donut <- dt_donut[, .(count = .N), by = beds]
bunch_donut_25 <- estimate_bunching(freq_donut, threshold = 25,
                                     window_below = 2, window_above = 3,
                                     poly_degree = 7, range_low = 5, range_high = 55,
                                     n_boot = 100)
cat(sprintf("25-bed donut: b=%.2f (SE=%.2f) — should be near zero\n",
            bunch_donut_25$normalized_b, bunch_donut_25$se_b))

# ============================================================
# 4. STATE-LEVEL HETEROGENEITY
# ============================================================
cat("\n=== State-Level CAH Bunching ===\n")

# Top 10 states by CAH count
cah_states <- dt[is_cah == TRUE, .(n_cah = .N), by = state_code][order(-n_cah)][1:10]
cat("Top 10 CAH states:\n")
print(cah_states)

# State-level bunching estimates
state_bunch <- list()
for (st in cah_states$state_code) {
  freq_st <- dt[state_code == st, .(count = .N), by = beds]
  r <- estimate_bunching(freq_st, threshold = 25, window_below = 2, window_above = 3,
                         poly_degree = 5, range_low = 5, range_high = 55, n_boot = 100)
  if (!is.null(r)) {
    state_bunch[[st]] <- data.table(state = st, b = r$normalized_b, se = r$se_b,
                                    excess = r$excess_mass)
  }
}
state_results <- rbindlist(state_bunch)
cat("State-level bunching at 25 beds:\n")
print(state_results[order(-b)])

# ============================================================
# 5. EARLY vs LATE PERIOD COMPARISON
# ============================================================
cat("\n=== Early vs Late Period ===\n")

# Early: 2010-2016
freq_early <- dt[fiscal_year <= 2016, .(count = .N), by = beds]
r_early <- estimate_bunching(freq_early, threshold = 25, window_below = 2, window_above = 3,
                             poly_degree = 7, range_low = 5, range_high = 55, n_boot = 100)

# Late: 2017-2023
freq_late <- dt[fiscal_year >= 2017, .(count = .N), by = beds]
r_late <- estimate_bunching(freq_late, threshold = 25, window_below = 2, window_above = 3,
                            poly_degree = 7, range_low = 5, range_high = 55, n_boot = 100)

cat(sprintf("Early (2010-2016): b=%.2f (SE=%.2f)\n", r_early$normalized_b, r_early$se_b))
cat(sprintf("Late  (2017-2023): b=%.2f (SE=%.2f)\n", r_late$normalized_b, r_late$se_b))

# ============================================================
# 6. SAVE ROBUSTNESS RESULTS
# ============================================================
robustness <- list(
  poly_sens = list(t25 = poly_sens_25, t50 = poly_sens_50, t100 = poly_sens_100),
  window_sens = window_sens_25,
  donut = list(b = bunch_donut_25$normalized_b, se = bunch_donut_25$se_b),
  state_bunch = state_results,
  period = list(early_b = r_early$normalized_b, early_se = r_early$se_b,
                late_b = r_late$normalized_b, late_se = r_late$se_b),
  placebo_urban = list(b = results$placebo_urban_25$b, se = results$placebo_urban_25$se)
)
saveRDS(robustness, "../data/robustness_results.rds")
cat("\nRobustness results saved.\n")
