# 03_main_analysis.R — Main regressions for EPA enforcement shift-share
# apep_1336: EPA Enforcement Federalism Production Function

source("00_packages.R")

data_dir <- "../data/"

# ==============================================================================
# 1. LOAD DATA
# ==============================================================================

cat("=== Loading analysis data ===\n")
pm25 <- readRDS(file.path(data_dir, "panel_pm25.rds"))
so2 <- readRDS(file.path(data_dir, "panel_so2.rds"))
no2 <- readRDS(file.path(data_dir, "panel_no2.rds"))
ozone <- readRDS(file.path(data_dir, "panel_ozone.rds"))
state_panel <- readRDS(file.path(data_dir, "panel_state.rds"))

# Use balanced sample for main analysis
pm25_bal <- pm25[balanced == TRUE]
cat(sprintf("PM2.5 balanced panel: %d county-years, %d counties\n",
            nrow(pm25_bal), n_distinct(pm25_bal$county_id)))

# ==============================================================================
# 2. MAIN SPECIFICATION: COUNTY-LEVEL SHIFT-SHARE DiD
# ==============================================================================

cat("\n=== Main Specifications ===\n")

# Spec 1: Post × FedShare with county + year FE, clustered at state level
# Y_{c,t} = α_c + λ_t + β × FedShare_s × Post_t + ε_{c,t}
m1 <- feols(log_conc ~ post_x_fedshare | county_id + year,
            data = pm25_bal, cluster = ~state_abbr)
cat("Model 1 (PM2.5, Post × FedShare):\n")
print(summary(m1))

# Spec 2: Continuous treatment using staffing index
# Y_{c,t} = α_c + λ_t + β × FedShare_s × (1 - OECA_index_t) + ε_{c,t}
m2 <- feols(log_conc ~ treatment | county_id + year,
            data = pm25_bal, cluster = ~state_abbr)
cat("\nModel 2 (PM2.5, Continuous treatment):\n")
print(summary(m2))

# Spec 3: Event study
# Y_{c,t} = α_c + λ_t + Σ_k β_k × FedShare_s × 1(t = k) + ε_{c,t}
# Reference year: 2016 (last pre-treatment year)
pm25_bal[, year_factor := factor(year)]
pm25_bal[, year_factor := relevel(year_factor, ref = "2016")]

m3 <- feols(log_conc ~ i(year_factor, fed_share, ref = "2016") | county_id + year,
            data = pm25_bal, cluster = ~state_abbr)
cat("\nModel 3 (PM2.5, Event Study):\n")
print(summary(m3))

# ==============================================================================
# 3. ALTERNATIVE POLLUTANTS
# ==============================================================================

cat("\n=== Alternative Pollutants ===\n")

# SO2 (more directly linked to industrial sources)
so2_bal <- so2[balanced == TRUE]
if (nrow(so2_bal) > 100) {
  m4 <- feols(log_conc ~ post_x_fedshare | county_id + year,
              data = so2_bal, cluster = ~state_abbr)
  cat(sprintf("SO2: β=%.4f, SE=%.4f, p=%.4f (n=%d, counties=%d)\n",
              coef(m4), se(m4), pvalue(m4), nobs(m4), n_distinct(so2_bal$county_id)))
} else {
  cat("SO2: Insufficient balanced observations\n")
  m4 <- NULL
}

# NO2
no2_bal <- no2[balanced == TRUE]
if (nrow(no2_bal) > 100) {
  m5 <- feols(log_conc ~ post_x_fedshare | county_id + year,
              data = no2_bal, cluster = ~state_abbr)
  cat(sprintf("NO2: β=%.4f, SE=%.4f, p=%.4f (n=%d, counties=%d)\n",
              coef(m5), se(m5), pvalue(m5), nobs(m5), n_distinct(no2_bal$county_id)))
} else {
  cat("NO2: Insufficient balanced observations\n")
  m5 <- NULL
}

# Ozone
ozone_bal <- ozone[balanced == TRUE]
if (nrow(ozone_bal) > 100) {
  m6 <- feols(log_conc ~ post_x_fedshare | county_id + year,
              data = ozone_bal, cluster = ~state_abbr)
  cat(sprintf("Ozone: β=%.4f, SE=%.4f, p=%.4f (n=%d, counties=%d)\n",
              coef(m6), se(m6), pvalue(m6), nobs(m6), n_distinct(ozone_bal$county_id)))
} else {
  cat("Ozone: Insufficient balanced observations\n")
  m6 <- NULL
}

# ==============================================================================
# 4. STATE-LEVEL ANALYSIS (Coarser but simpler)
# ==============================================================================

cat("\n=== State-Level Analysis ===\n")

m7 <- feols(log_pm25 ~ post_x_fedshare | state_abbr + year,
            data = state_panel, cluster = ~state_abbr)
cat("State-level PM2.5:\n")
print(summary(m7))

# ==============================================================================
# 5. SAVE RESULTS AND DIAGNOSTICS
# ==============================================================================

cat("\n=== Saving results ===\n")

# Save all models
model_list <- list(
  pm25_binary = m1,
  pm25_continuous = m2,
  pm25_eventstudy = m3,
  so2 = m4,
  no2 = m5,
  ozone = m6,
  state_level = m7
)
saveRDS(model_list, file.path(data_dir, "main_models.rds"))

# Write diagnostics.json for validation
n_treated_states <- nrow(pm25_bal[fed_share > median(pm25_bal$fed_share, na.rm = TRUE) &
                                   post_decline == 1,
                                  .(n = .N), by = state_abbr])
n_pre <- n_distinct(pm25_bal[year < 2017, year])
n_obs <- nrow(pm25_bal)

diagnostics <- list(
  n_treated = n_treated_states,
  n_pre = n_pre,
  n_obs = n_obs,
  n_counties = n_distinct(pm25_bal$county_id),
  n_states = n_distinct(pm25_bal$state_abbr),
  years = range(pm25_bal$year),
  main_coef = as.numeric(coef(m1)),
  main_se = as.numeric(se(m1)),
  main_pvalue = as.numeric(pvalue(m1))
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)

cat("Results saved.\n")
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated_states, n_pre, n_obs))
