# 03_main_analysis.R — RDD analysis of Swiss Second Home Ban
# apep_0903

base_dir <- normalizePath(file.path(getwd(), ".."))
source(file.path(base_dir, "code", "00_packages.R"))
data_dir <- file.path(base_dir, "data")

cat("=== Main RDD Analysis ===\n")

# Load data
analysis <- readRDS(file.path(data_dir, "analysis_panel.rds"))
first_obs <- readRDS(file.path(data_dir, "first_obs.rds"))

# ---------------------------------------------------------------
# 1. Cross-sectional outcomes: first wave vs latest wave
# ---------------------------------------------------------------

# For each municipality, compute changes from first to latest observation
mun_outcomes <- analysis[, .(
  first_pct_secondary = pct_secondary[which.min(wave_date)],
  latest_pct_secondary = pct_secondary[which.max(wave_date)],
  first_n_total = n_total[which.min(wave_date)],
  latest_n_total = n_total[which.max(wave_date)],
  first_wave = wave[which.min(wave_date)],
  latest_wave = wave[which.max(wave_date)],
  n_waves = .N
), by = .(mun_id, mun_name, treated, running_var, first_pct_secondary)]

# Rename to avoid duplicate
mun_outcomes[, first_pct_sec := first_pct_secondary]

# Compute changes
mun_outcomes[, delta_pct_secondary := latest_pct_secondary - first_pct_sec]
mun_outcomes[, pct_growth_dwellings := (latest_n_total - first_n_total) / first_n_total * 100]

cat(sprintf("Municipalities with outcomes: %d\n", nrow(mun_outcomes)))
cat(sprintf("  Treated: %d, Control: %d\n",
            sum(mun_outcomes$treated), sum(!mun_outcomes$treated)))

# Summary of outcomes by treatment
cat("\n--- Change in secondary share (treated vs control) ---\n")
cat(sprintf("  Treated: mean=%.3f, sd=%.3f\n",
            mean(mun_outcomes[treated == TRUE]$delta_pct_secondary, na.rm=TRUE),
            sd(mun_outcomes[treated == TRUE]$delta_pct_secondary, na.rm=TRUE)))
cat(sprintf("  Control: mean=%.3f, sd=%.3f\n",
            mean(mun_outcomes[treated == FALSE]$delta_pct_secondary, na.rm=TRUE),
            sd(mun_outcomes[treated == FALSE]$delta_pct_secondary, na.rm=TRUE)))

cat("\n--- Dwelling growth rate (treated vs control) ---\n")
cat(sprintf("  Treated: mean=%.3f%%, sd=%.3f%%\n",
            mean(mun_outcomes[treated == TRUE]$pct_growth_dwellings, na.rm=TRUE),
            sd(mun_outcomes[treated == TRUE]$pct_growth_dwellings, na.rm=TRUE)))
cat(sprintf("  Control: mean=%.3f%%, sd=%.3f%%\n",
            mean(mun_outcomes[treated == FALSE]$pct_growth_dwellings, na.rm=TRUE),
            sd(mun_outcomes[treated == FALSE]$pct_growth_dwellings, na.rm=TRUE)))

# ---------------------------------------------------------------
# 2. McCrary Density Test (manipulation at threshold)
# ---------------------------------------------------------------

cat("\n=== McCrary Density Test ===\n")

# Test for bunching at the 20% threshold
density_test <- rddensity::rddensity(X = mun_outcomes$running_var, c = 0)
mccrary_t <- density_test$test$t_jk
mccrary_p <- density_test$test$p_jk
cat(sprintf("McCrary test: T-stat = %.3f, p-value = %.4f\n", mccrary_t, mccrary_p))

if (mccrary_p < 0.05) {
  cat("  WARNING: Evidence of manipulation at threshold (p < 0.05)\n")
} else {
  cat("  PASS: No evidence of manipulation at threshold\n")
}

# ---------------------------------------------------------------
# 3. Main RDD: Effect on change in secondary share
# ---------------------------------------------------------------

cat("\n=== Main RDD: Change in Secondary Home Share ===\n")

# Remove observations with missing outcomes
rdd_data <- mun_outcomes[!is.na(delta_pct_secondary) & !is.na(running_var)]
cat(sprintf("RDD sample: %d municipalities\n", nrow(rdd_data)))

# Main specification: local linear, MSE-optimal bandwidth
rdd_main <- rdrobust::rdrobust(
  y = rdd_data$delta_pct_secondary,
  x = rdd_data$running_var,
  c = 0,
  kernel = "triangular",
  p = 1,  # local linear
  bwselect = "mserd"
)

cat("\n--- Main RDD result ---\n")
summary(rdd_main)

# Store coefficients
main_coef <- rdd_main$coef[1]   # Conventional
main_se <- rdd_main$se[3]       # Robust SE
main_bw <- rdd_main$bws[1, 1]   # MSE-optimal bandwidth
main_n_left <- rdd_main$N_h[1]
main_n_right <- rdd_main$N_h[2]
main_ci_lo <- rdd_main$ci[3, 1]  # Robust CI
main_ci_hi <- rdd_main$ci[3, 2]

cat(sprintf("\nMain result: β = %.3f (robust SE = %.3f)\n", main_coef, main_se))
cat(sprintf("Robust 95%% CI: [%.3f, %.3f]\n", main_ci_lo, main_ci_hi))
cat(sprintf("Bandwidth: %.2f pp, N(left)=%d, N(right)=%d\n",
            main_bw, main_n_left, main_n_right))

# ---------------------------------------------------------------
# 4. RDD on dwelling growth (construction displacement)
# ---------------------------------------------------------------

cat("\n=== RDD: Dwelling Growth Rate ===\n")

rdd_growth <- rdrobust::rdrobust(
  y = rdd_data$pct_growth_dwellings,
  x = rdd_data$running_var,
  c = 0,
  kernel = "triangular",
  p = 1,
  bwselect = "mserd"
)

cat("\n--- Dwelling growth RDD result ---\n")
summary(rdd_growth)

growth_coef <- rdd_growth$coef[1]
growth_se <- rdd_growth$se[3]
growth_bw <- rdd_growth$bws[1, 1]

cat(sprintf("\nGrowth result: β = %.3f (robust SE = %.3f)\n", growth_coef, growth_se))

# ---------------------------------------------------------------
# 5. RDD on latest secondary share level
# ---------------------------------------------------------------

cat("\n=== RDD: Latest Secondary Share Level ===\n")

rdd_level <- rdrobust::rdrobust(
  y = rdd_data$latest_pct_secondary,
  x = rdd_data$running_var,
  c = 0,
  kernel = "triangular",
  p = 1,
  bwselect = "mserd"
)

summary(rdd_level)

level_coef <- rdd_level$coef[1]
level_se <- rdd_level$se[3]
level_bw <- rdd_level$bws[1, 1]

cat(sprintf("\nLevel result: β = %.3f (robust SE = %.3f)\n", level_coef, level_se))

# ---------------------------------------------------------------
# 6. Save results for tables
# ---------------------------------------------------------------

results <- list(
  main = list(
    outcome = "delta_pct_secondary",
    coef = main_coef,
    se_robust = main_se,
    ci_lo = main_ci_lo,
    ci_hi = main_ci_hi,
    bw = main_bw,
    n_left = main_n_left,
    n_right = main_n_right,
    n_total = main_n_left + main_n_right
  ),
  growth = list(
    outcome = "pct_growth_dwellings",
    coef = growth_coef,
    se_robust = growth_se,
    ci_lo = rdd_growth$ci[3, 1],
    ci_hi = rdd_growth$ci[3, 2],
    bw = growth_bw,
    n_left = rdd_growth$N_h[1],
    n_right = rdd_growth$N_h[2],
    n_total = rdd_growth$N_h[1] + rdd_growth$N_h[2]
  ),
  level = list(
    outcome = "latest_pct_secondary",
    coef = level_coef,
    se_robust = level_se,
    ci_lo = rdd_level$ci[3, 1],
    ci_hi = rdd_level$ci[3, 2],
    bw = level_bw,
    n_left = rdd_level$N_h[1],
    n_right = rdd_level$N_h[2],
    n_total = rdd_level$N_h[1] + rdd_level$N_h[2]
  ),
  mccrary = list(
    t_stat = mccrary_t,
    p_value = mccrary_p
  )
)

saveRDS(results, file.path(data_dir, "rdd_results.rds"))
saveRDS(rdd_data, file.path(data_dir, "rdd_data.rds"))

# ---------------------------------------------------------------
# 7. Diagnostics JSON for validator
# ---------------------------------------------------------------

diagnostics <- list(
  n_treated = sum(rdd_data$treated),
  n_pre = 16,  # 16 waves of panel data
  n_obs = nrow(rdd_data),
  n_bandwidth = main_n_left + main_n_right,
  mccrary_pvalue = mccrary_p,
  main_coef = main_coef,
  main_se = main_se,
  bw_optimal = main_bw
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)

cat(sprintf("\nDiagnostics saved to %s\n", file.path(data_dir, "diagnostics.json")))
cat("\n=== Main analysis complete ===\n")
