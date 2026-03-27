# 03_main_analysis.R — Main DiD analysis
# APEP Paper apep_1086: CAA Attainment Redesignation

source("00_packages.R")

data_dir <- "../data/"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

cat("Panel:", format(nrow(panel), big.mark = ","), "obs,",
    n_distinct(panel$fips), "counties\n")
cat("Treated:", sum(panel$ever_treated & !duplicated(panel$fips)), "\n")
cat("Years:", min(panel$year), "-", max(panel$year), "\n")

# ============================================================================
# A. TWFE (Baseline — interpret with caution under heterogeneity)
# ============================================================================
cat("\n=== TWFE Estimates ===\n")

# Main outcome: log manufacturing employment
twfe_emp <- feols(log_mfg_emp ~ post | fips + year, data = panel,
                  cluster = ~fips)
cat("TWFE Log Mfg Employment:\n")
print(summary(twfe_emp))

# Level outcome
twfe_emp_level <- feols(mfg_emp ~ post | fips + year, data = panel,
                        cluster = ~fips)

# Hiring rate
twfe_hires <- feols(mfg_hires ~ post | fips + year, data = panel,
                    cluster = ~fips)

# Separation rate
twfe_seps <- feols(mfg_seps ~ post | fips + year, data = panel,
                   cluster = ~fips)

# Earnings
twfe_earnings <- feols(log_mfg_earnings ~ post | fips + year, data = panel,
                       cluster = ~fips)

# ============================================================================
# B. Callaway & Sant'Anna (2021) — Heterogeneity-robust
# ============================================================================
cat("\n=== Callaway-Sant'Anna Estimates ===\n")

# Need balanced panel for CS. Drop counties with < 5 years
panel_cs <- panel %>%
  group_by(fips) %>%
  filter(n() >= 10) %>%
  ungroup()

cat("CS sample:", format(nrow(panel_cs), big.mark = ","), "obs,",
    n_distinct(panel_cs$fips), "counties\n")

# CS estimator: log manufacturing employment
cs_emp <- att_gt(
  yname = "log_mfg_emp",
  tname = "year",
  idname = "county_id",
  gname = "first_treat",
  data = panel_cs,
  control_group = "nevertreated",
  est_method = "dr",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)

cat("\nCS group-time ATTs:\n")
print(summary(cs_emp))

# Aggregate: simple ATT
cs_simple <- aggte(cs_emp, type = "simple")
cat("\nCS Simple ATT:\n")
print(summary(cs_simple))

# Aggregate: dynamic (event study)
cs_dynamic <- aggte(cs_emp, type = "dynamic", min_e = -5, max_e = 5)
cat("\nCS Dynamic ATT:\n")
print(summary(cs_dynamic))

# ============================================================================
# C. Sun-Abraham (via fixest::sunab) — Alternative robust estimator
# ============================================================================
cat("\n=== Sun-Abraham Estimates ===\n")

# sunab requires first_treat > 0 for treated, Inf for never-treated
panel_sa <- panel_cs %>%
  mutate(first_treat_sa = ifelse(first_treat == 0, 10000, first_treat))

sa_emp <- feols(log_mfg_emp ~ sunab(first_treat_sa, year) | fips + year,
                data = panel_sa, cluster = ~fips)
cat("Sun-Abraham Log Mfg Employment:\n")
print(summary(sa_emp))

# ============================================================================
# D. Air quality outcome (subsample with monitors)
# ============================================================================
cat("\n=== Air Quality Analysis (PM2.5 subsample) ===\n")

panel_aqs <- panel %>%
  filter(has_pm25 == TRUE)

cat("PM2.5 sample:", format(nrow(panel_aqs), big.mark = ","), "obs,",
    n_distinct(panel_aqs$fips), "counties\n")
cat("Treated counties with PM2.5:", sum(panel_aqs$ever_treated & !duplicated(panel_aqs$fips)), "\n")

if (sum(panel_aqs$ever_treated & !duplicated(panel_aqs$fips)) >= 20) {
  twfe_pm25 <- feols(mean_conc_PM25 ~ post | fips + year,
                     data = panel_aqs, cluster = ~fips)
  cat("TWFE PM2.5:\n")
  print(summary(twfe_pm25))
} else {
  cat("Too few treated counties with PM2.5 monitors for separate analysis\n")
  twfe_pm25 <- NULL
}

# Ozone
panel_o3 <- panel %>%
  filter(has_o3 == TRUE)

cat("\nOzone sample:", format(nrow(panel_o3), big.mark = ","), "obs,",
    n_distinct(panel_o3$fips), "counties\n")
cat("Treated counties with O3:", sum(panel_o3$ever_treated & !duplicated(panel_o3$fips)), "\n")

if (sum(panel_o3$ever_treated & !duplicated(panel_o3$fips)) >= 20) {
  twfe_o3 <- feols(mean_conc_O3 ~ post | fips + year,
                   data = panel_o3, cluster = ~fips)
  cat("TWFE Ozone:\n")
  print(summary(twfe_o3))
} else {
  cat("Too few treated counties with O3 monitors for separate analysis\n")
  twfe_o3 <- NULL
}

# ============================================================================
# E. Save results
# ============================================================================
cat("\n=== Saving Results ===\n")

results <- list(
  twfe_emp = twfe_emp,
  twfe_emp_level = twfe_emp_level,
  twfe_hires = twfe_hires,
  twfe_seps = twfe_seps,
  twfe_earnings = twfe_earnings,
  cs_emp = cs_emp,
  cs_simple = cs_simple,
  cs_dynamic = cs_dynamic,
  sa_emp = sa_emp,
  twfe_pm25 = twfe_pm25,
  twfe_o3 = twfe_o3
)

saveRDS(results, file.path(data_dir, "main_results.rds"))

# Write diagnostics.json for validator
diag <- list(
  n_treated = sum(panel$ever_treated & !duplicated(panel$fips)),
  n_pre = as.integer(max(panel$first_redesig_year[panel$ever_treated], na.rm = TRUE) -
                       min(panel$year)),
  n_obs = nrow(panel)
)
jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("Diagnostics:", toJSON(diag, auto_unbox = TRUE), "\n")

cat("\n=== Main Analysis Complete ===\n")
