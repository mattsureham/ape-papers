# 03_main_analysis.R — Main regressions
# APEP-1284: BLM Lottery Leases and Western County Economies

source("00_packages.R")

DATA_DIR <- "../data"
analysis <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
county_leases <- fread(file.path(DATA_DIR, "county_leases.csv"))

cat(sprintf("Panel: %d obs, %d counties, %d years\n",
            nrow(analysis), uniqueN(analysis$fips), uniqueN(analysis$year)))

# ============================================================
# 1. MAIN SPECIFICATION: Continuous treatment intensity
# ============================================================
# Y_ct = a + b*(LotteryShare_c * Post_t) + county_FE + year_FE + e
# Clustering at state level (13 Western states)

cat("\n=== Main Results: Per Capita Income ===\n")

# OLS: lottery share interacted with post-lottery era
m1_income <- feols(log_pc_income ~ lottery_share:post_era |
                     fips + year, data = analysis,
                   cluster = ~state)
summary(m1_income)

# Allow time-varying effects: interact lottery share with each year
analysis[, year_fac := factor(year)]
m2_income_es <- feols(log_pc_income ~ lottery_share:year_fac |
                        fips + year, data = analysis,
                      cluster = ~state)

cat("\n=== Main Results: Population ===\n")
m1_pop <- feols(log_pop ~ lottery_share:post_era |
                  fips + year, data = analysis,
                cluster = ~state)
summary(m1_pop)

# Event study for population
m2_pop_es <- feols(log_pop ~ lottery_share:year_fac |
                     fips + year, data = analysis,
                   cluster = ~state)

# ============================================================
# 2. HIGH VS LOW LOTTERY SHARE (BINARY)
# ============================================================
cat("\n=== Binary treatment: High lottery share ===\n")

m3_income <- feols(log_pc_income ~ high_lottery:post_era |
                     fips + year, data = analysis,
                   cluster = ~state)
summary(m3_income)

m3_pop <- feols(log_pop ~ high_lottery:post_era |
                  fips + year, data = analysis,
                cluster = ~state)
summary(m3_pop)

# ============================================================
# 3. CONTROL FOR TOTAL FEDERAL ACREAGE
# ============================================================
cat("\n=== With total acreage control ===\n")

analysis[, log_total_acres := log(total_all_acres + 1)]

m4_income <- feols(log_pc_income ~ lottery_share:post_era + log_total_acres:post_era |
                     fips + year, data = analysis,
                   cluster = ~state)
summary(m4_income)

m4_pop <- feols(log_pop ~ lottery_share:post_era + log_total_acres:post_era |
                  fips + year, data = analysis,
                cluster = ~state)
summary(m4_pop)

# ============================================================
# 4. STATE TRENDS
# ============================================================
cat("\n=== With state-specific linear trends ===\n")

analysis[, state_trend := as.numeric(year) * as.numeric(factor(state))]

m5_income <- feols(log_pc_income ~ lottery_share:post_era |
                     fips + year + state[year], data = analysis,
                   cluster = ~state)
summary(m5_income)

# ============================================================
# 5. DIAGNOSTICS
# ============================================================
cat("\n=== Diagnostics ===\n")

# Pre-trend test: interact lottery share with pre-period years only
pre_data <- analysis[year <= 1990]
m_pretrend <- feols(log_pc_income ~ lottery_share:year_fac |
                      fips + year, data = pre_data,
                    cluster = ~state)
cat("Pre-trend coefficients:\n")
print(coef(m_pretrend))

# Save key statistics for paper
n_treated <- sum(county_leases$lottery_acres > 0)
n_pre <- sum(unique(analysis$year) <= 1990)
n_obs <- nrow(analysis)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_counties = uniqueN(analysis$fips),
  n_years = uniqueN(analysis$year),
  mean_lottery_share = round(mean(county_leases$lottery_share), 3),
  sd_lottery_share = round(sd(county_leases$lottery_share), 3)
)
jsonlite::write_json(diagnostics, file.path(DATA_DIR, "diagnostics.json"), auto_unbox = TRUE)

# Save models for table generation
save(m1_income, m1_pop, m2_income_es, m2_pop_es, m3_income, m3_pop,
     m4_income, m4_pop, m5_income, m_pretrend, analysis, county_leases,
     file = file.path(DATA_DIR, "models.RData"))

cat("\n=== Main analysis complete ===\n")
cat(sprintf("Key results saved to %s/models.RData\n", DATA_DIR))
