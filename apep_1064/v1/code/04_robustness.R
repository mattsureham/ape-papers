## 04_robustness.R — Robustness checks and diagnostics
## Address pre-trend concern, alternative specifications, placebos

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
results <- readRDS(file.path(data_dir, "main_results.rds"))

# ============================================================================
# 1. Pre-trend investigation
# ============================================================================
cat("=== PRE-TREND INVESTIGATION ===\n")

# The event study showed a large 2018 coefficient. Check if this is a level
# shift between 2018-2019 rather than a continuous pre-trend.

# Test: restrict to 2019-2021 only (drop 2018)
panel_3yr <- panel[year >= 2019]
panel_3yr[, post := as.integer(year >= 2021)]
panel_3yr[, treat_x_post := urban_share * post]

main_3yr <- feols(
  enterprises_pc ~ treat_x_post | muni_code + year,
  data = panel_3yr, cluster = ~state_code
)
cat("Dropping 2018 (2019-2021 only):\n")
summary(main_3yr)

# Event study: 2019-2021 with base year 2020
panel_3yr[, year_f := factor(year, levels = c(2020, 2019, 2021))]
es_3yr <- feols(
  enterprises_pc ~ i(year_f, urban_share, ref = 2020) | muni_code + year,
  data = panel_3yr, cluster = ~state_code
)
cat("\nEvent study (2019-2021, base=2020):\n")
summary(es_3yr)

# ============================================================================
# 2. State-specific linear trends (faster alternative to muni trends)
# ============================================================================
cat("\n=== STATE LINEAR TRENDS ===\n")

panel[, time_trend := year - 2018]
trend_spec <- feols(
  enterprises_pc ~ treat_x_post + i(state_code, time_trend) | muni_code + year,
  data = panel, cluster = ~state_code
)
cat("With state-specific linear trends:\n")
cat(sprintf("  treat_x_post: %.3f (%.3f), p=%.4f\n",
            coef(trend_spec)["treat_x_post"],
            se(trend_spec)["treat_x_post"],
            pvalue(trend_spec)["treat_x_post"]))

# ============================================================================
# 3. Placebo outcomes
# ============================================================================
cat("\n=== PLACEBO OUTCOMES ===\n")

# Wages per capita should respond less to digital payment adoption
# (wages reflect employer decisions, not self-employment entry)
placebo_wages <- feols(
  wages_pc ~ treat_x_post | muni_code + year,
  data = panel, cluster = ~state_code
)
cat("Placebo — Wages per capita:\n")
summary(placebo_wages)

# Employment per capita (salaried employment should not respond to formalization)
panel[, emp_salaried_pc := (emp_salaried / population) * 10000]
placebo_salaried <- feols(
  emp_salaried_pc ~ treat_x_post | muni_code + year,
  data = panel[!is.na(emp_salaried_pc)], cluster = ~state_code
)
cat("\nPlacebo — Salaried employment per capita:\n")
summary(placebo_salaried)

# ============================================================================
# 4. Placebo treatment timing (November 2018 pseudo-treatment)
# ============================================================================
cat("\n=== PLACEBO TIMING ===\n")

# Use only pre-treatment data (2018-2020) with pseudo-treatment in 2020
panel_placebo <- panel[year <= 2020]
panel_placebo[, pseudo_post := as.integer(year >= 2020)]
panel_placebo[, pseudo_treat := urban_share * pseudo_post]

placebo_timing <- feols(
  enterprises_pc ~ pseudo_treat | muni_code + year,
  data = panel_placebo, cluster = ~state_code
)
cat("Pseudo-treatment at 2020 (pre-period only):\n")
summary(placebo_timing)

# ============================================================================
# 5. Leave-one-state-out
# ============================================================================
cat("\n=== LEAVE-ONE-STATE-OUT ===\n")

states <- sort(unique(panel$state_code))
loso_results <- data.table(
  state_dropped = integer(),
  coef = numeric(),
  se = numeric(),
  pval = numeric()
)

for (s in states) {
  mod <- feols(
    enterprises_pc ~ treat_x_post | muni_code + year,
    data = panel[state_code != s], cluster = ~state_code
  )
  loso_results <- rbindlist(list(loso_results, data.table(
    state_dropped = s,
    coef = coef(mod)["treat_x_post"],
    se = se(mod)["treat_x_post"],
    pval = pvalue(mod)["treat_x_post"]
  )))
}

cat("Leave-one-state-out range:\n")
cat(sprintf("  Coefficient: [%.2f, %.2f]\n",
            min(loso_results$coef), max(loso_results$coef)))
cat(sprintf("  All significant at 5%%: %s\n",
            ifelse(all(loso_results$pval < 0.05), "Yes", "No")))
cat(sprintf("  Min p-value: %.4f, Max p-value: %.4f\n",
            min(loso_results$pval), max(loso_results$pval)))

# ============================================================================
# 6. Alternative treatment measures
# ============================================================================
cat("\n=== ALTERNATIVE TREATMENT ===\n")

# Binary treatment: above/below median urbanization
panel[, high_urban := as.integer(urban_share > median(urban_share))]
panel[, high_urban_x_post := high_urban * post]

binary_spec <- feols(
  enterprises_pc ~ high_urban_x_post | muni_code + year,
  data = panel, cluster = ~state_code
)
cat("Binary treatment (above median urbanization):\n")
summary(binary_spec)

# Quadratic urbanization interaction
panel[, urban_sq := urban_share^2]
panel[, treat_x_post_sq := urban_sq * post]

quad_spec <- feols(
  enterprises_pc ~ treat_x_post + treat_x_post_sq | muni_code + year,
  data = panel, cluster = ~state_code
)
cat("\nQuadratic treatment intensity:\n")
summary(quad_spec)

# ============================================================================
# 7. Outcome: log specification with 3-year panel
# ============================================================================
cat("\n=== LOG SPEC (3-year panel) ===\n")

log_3yr <- feols(
  log_enterprises ~ treat_x_post | muni_code + year,
  data = panel_3yr, cluster = ~state_code
)
cat("Log enterprises (2019-2021):\n")
summary(log_3yr)

# ============================================================================
# 8. Summary table of all robustness checks
# ============================================================================
cat("\n=== ROBUSTNESS SUMMARY ===\n")

rob_summary <- data.table(
  Specification = c(
    "Main (2018-2021)",
    "Drop 2018 (2019-2021)",
    "State × Year FE",
    "Muni linear trends",
    "Binary treatment",
    "Quadratic treatment",
    "Log enterprises (2019-2021)"
  ),
  Coefficient = c(
    coef(results$main)["treat_x_post"],
    coef(main_3yr)["treat_x_post"],
    coef(results$state_yr)["treat_x_post"],
    coef(trend_spec)["treat_x_post"],
    coef(binary_spec)["high_urban_x_post"],
    coef(quad_spec)["treat_x_post"],
    coef(log_3yr)["treat_x_post"]
  ),
  SE = c(
    se(results$main)["treat_x_post"],
    se(main_3yr)["treat_x_post"],
    se(results$state_yr)["treat_x_post"],
    se(trend_spec)["treat_x_post"],
    se(binary_spec)["high_urban_x_post"],
    se(quad_spec)["treat_x_post"],
    se(log_3yr)["treat_x_post"]
  ),
  P_value = c(
    pvalue(results$main)["treat_x_post"],
    pvalue(main_3yr)["treat_x_post"],
    pvalue(results$state_yr)["treat_x_post"],
    pvalue(trend_spec)["treat_x_post"],
    pvalue(binary_spec)["high_urban_x_post"],
    pvalue(quad_spec)["treat_x_post"],
    pvalue(log_3yr)["treat_x_post"]
  )
)

rob_summary[, Stars := fifelse(P_value < 0.001, "***",
                       fifelse(P_value < 0.01, "**",
                       fifelse(P_value < 0.05, "*",
                       fifelse(P_value < 0.1, "+", ""))))]

print(rob_summary)

# Save robustness results
rob_results <- list(
  main_3yr = main_3yr,
  es_3yr = es_3yr,
  trend_spec = trend_spec,
  placebo_wages = placebo_wages,
  placebo_salaried = placebo_salaried,
  placebo_timing = placebo_timing,
  loso = loso_results,
  binary = binary_spec,
  quad = quad_spec,
  log_3yr = log_3yr
)
saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))

cat("\nRobustness checks complete.\n")
