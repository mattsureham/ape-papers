# 03_main_analysis.R — Main econometric analysis
# apep_1131: The Hollow Safety Net

source("00_packages.R")

panel <- read_csv("../data/analysis_panel.csv", show_col_types = FALSE)
cat(sprintf("Panel: %d obs, %d states, years %d-%d\n",
            nrow(panel), n_distinct(panel$state_fips), min(panel$year), max(panel$year)))

# ============================================================================
# 1. Summary Statistics
# ============================================================================
cat("\n=== Summary Statistics ===\n")

sumstats <- panel %>%
  summarise(
    across(c(timeliness_14d, timeliness_21d, bartik_shock, staff_per_1000,
             annual_initial_claims, claims_per_staff, workload_n),
           list(mean = ~mean(., na.rm = TRUE),
                sd   = ~sd(., na.rm = TRUE),
                min  = ~min(., na.rm = TRUE),
                max  = ~max(., na.rm = TRUE)),
           .names = "{.col}_{.fn}")
  )

# Display
cat(sprintf("  Timeliness (14d):     mean=%.1f  sd=%.1f  [%.1f, %.1f]\n",
            sumstats$timeliness_14d_mean, sumstats$timeliness_14d_sd,
            sumstats$timeliness_14d_min, sumstats$timeliness_14d_max))
cat(sprintf("  Bartik shock:         mean=%.4f  sd=%.4f  [%.4f, %.4f]\n",
            sumstats$bartik_shock_mean, sumstats$bartik_shock_sd,
            sumstats$bartik_shock_min, sumstats$bartik_shock_max))
cat(sprintf("  Staff per 1000:       mean=%.1f  sd=%.1f  [%.1f, %.1f]\n",
            sumstats$staff_per_1000_mean, sumstats$staff_per_1000_sd,
            sumstats$staff_per_1000_min, sumstats$staff_per_1000_max))

# ============================================================================
# 2. Reduced Form: Bartik shock → Timeliness
# ============================================================================
cat("\n=== Reduced Form: Bartik → Timeliness ===\n")

# OLS with state and year FE, clustered at state level
rf1 <- feols(timeliness_14d ~ bartik_shock | state_fips + year,
             data = panel, cluster = ~state_fips)

# Add Bartik × thinness interaction
rf2 <- feols(timeliness_14d ~ bartik_shock + bartik_x_thinness | state_fips + year,
             data = panel, cluster = ~state_fips)

# With log income control
rf3 <- feols(timeliness_14d ~ bartik_shock + bartik_x_thinness + log_income | state_fips + year,
             data = panel, cluster = ~state_fips)

cat("--- Reduced form (no interaction) ---\n")
print(summary(rf1))
cat("--- Reduced form (with thinness interaction) ---\n")
print(summary(rf2))
cat("--- Reduced form (with controls) ---\n")
print(summary(rf3))

# ============================================================================
# 3. First Stage: Bartik → log(claims)
# ============================================================================
cat("\n=== First Stage: Bartik → Claims ===\n")

fs1 <- feols(log_claims ~ bartik_shock | state_fips + year,
             data = panel, cluster = ~state_fips)

cat("First stage coefficient:\n")
print(summary(fs1))
# F-stat = t^2 for single instrument
fs1_tstat <- coef(fs1)["bartik_shock"] / se(fs1)["bartik_shock"]
cat(sprintf("  First-stage F-stat (t^2): %.1f\n", fs1_tstat^2))

# ============================================================================
# 4. 2SLS: Claims (instrumented) → Timeliness
# ============================================================================
cat("\n=== 2SLS: Claims → Timeliness ===\n")

# IV regression: timeliness ~ log_claims | FE | bartik_shock
iv1 <- feols(timeliness_14d ~ 1 | state_fips + year | log_claims ~ bartik_shock,
             data = panel, cluster = ~state_fips)

# Also instrument claims_per_staff
iv2 <- feols(timeliness_14d ~ 1 | state_fips + year | claims_per_staff ~ bartik_shock,
             data = panel %>% filter(!is.na(claims_per_staff)),
             cluster = ~state_fips)

cat("--- IV: Bartik → log(claims) → timeliness ---\n")
print(summary(iv1))
cat(sprintf("  First-stage F: %.1f\n", fitstat(iv1, "ivf")$ivf1$stat))

cat("--- IV: Bartik → claims/staff → timeliness ---\n")
print(summary(iv2))
cat(sprintf("  First-stage F: %.1f\n", fitstat(iv2, "ivf")$ivf1$stat))

# ============================================================================
# 5. Event Study Around Recession
# ============================================================================
cat("\n=== Event Study ===\n")

# Create year indicators interacted with Bartik exposure
# Use 2007 as reference year (last pre-recession year)
panel <- panel %>%
  mutate(
    bartik_exposure = bartik_shock,  # time-varying Bartik
    # Pre-recession average Bartik "exposure" (structural exposure)
    year_f = factor(year)
  )

# Get 2006 Bartik shock as baseline exposure for each state
exposure_2008 <- panel %>%
  filter(year == 2008) %>%
  select(state_fips, exposure_08 = bartik_shock)

panel <- panel %>%
  left_join(exposure_2008, by = "state_fips")

# Event study: year dummies × 2008 Bartik exposure
es <- feols(timeliness_14d ~ i(year, exposure_08, ref = 2007) | state_fips + year,
            data = panel %>% filter(!is.na(exposure_08)),
            cluster = ~state_fips)

cat("Event study coefficients (ref=2007):\n")
print(summary(es))

# ============================================================================
# 6. Heterogeneity: Thin vs Thick staffed states
# ============================================================================
cat("\n=== Heterogeneity: Thin vs Thick States ===\n")

# Split sample
panel_thin  <- panel %>% filter(thin_state == TRUE)
panel_thick <- panel %>% filter(thin_state == FALSE)

iv_thin  <- feols(timeliness_14d ~ 1 | state_fips + year | log_claims ~ bartik_shock,
                  data = panel_thin, cluster = ~state_fips)
iv_thick <- feols(timeliness_14d ~ 1 | state_fips + year | log_claims ~ bartik_shock,
                  data = panel_thick, cluster = ~state_fips)

cat("--- IV: Thin states (below median staffing) ---\n")
print(summary(iv_thin))
cat("--- IV: Thick states (above median staffing) ---\n")
print(summary(iv_thick))

# ============================================================================
# 7. Save results and diagnostics
# ============================================================================

# Diagnostics for validate_v1.py
n_pre <- sum(panel$year <= 2007)
n_post <- sum(panel$year >= 2008)
diagnostics <- list(
  n_treated = n_distinct(panel$state_fips),  # All states treated (continuous)
  n_pre = length(unique(panel$year[panel$year <= 2007])),
  n_obs = nrow(panel),
  n_states = n_distinct(panel$state_fips),
  n_years = n_distinct(panel$year),
  first_stage_F = tryCatch(fitstat(iv1, "ivf")$ivf1$stat,
                           error = function(e) (coef(fs1)["bartik_shock"] / se(fs1)["bartik_shock"])^2),
  iv_coef = coef(iv1)["fit_log_claims"],
  iv_se = se(iv1)["fit_log_claims"],
  rf_coef = coef(rf1)["bartik_shock"],
  rf_se = se(rf1)["bartik_shock"]
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

# Save model objects for tables
save(rf1, rf2, rf3, fs1, iv1, iv2, iv_thin, iv_thick, es, panel,
     file = "../data/models.RData")

cat("\n=== Analysis complete. Models saved to data/models.RData ===\n")
