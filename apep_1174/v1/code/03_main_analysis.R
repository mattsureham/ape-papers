## 03_main_analysis.R — Main regressions
## APEP-1174: The Enforcement Lottery
##
## Three estimands:
## 1. First stage: Does federal inspection share predict enforcement stringency?
## 2. Reduced form: Does state-year federal share predict TRI emissions?
## 3. IV: Federal share instruments for enforcement → emissions

source("00_packages.R")
data_dir <- "../data"

panel_tri <- readRDS(file.path(data_dir, "panel_tri.rds"))
panel_full <- readRDS(file.path(data_dir, "panel_full.rds"))
state_year <- readRDS(file.path(data_dir, "state_year_fed.rds"))
setDT(panel_tri); setDT(panel_full); setDT(state_year)

cat("TRI panel:", nrow(panel_tri), "obs,", uniqueN(panel_tri$PGM_SYS_ID), "facilities\n")
cat("Full panel:", nrow(panel_full), "obs\n")

## ============================================================
## 1. FIRST STAGE: Federal inspections → enforcement stringency
## ============================================================
cat("\n=== 1. First Stage: Federal share and enforcement ===\n")

## At the facility-year level, test if federal inspections correlate with
## more intensive enforcement actions (FCE rate, total inspections)

## 1a. FCE rate: federal inspectors → higher share of full compliance evaluations?
## Interesting: raw data shows LOWER FCE rate for federal inspectors (12.9% vs 34.5%)
## This might be because federal inspectors do targeted partial evaluations
## Focus instead on enforcement ACTIONS

## 1b. Use enforcement case data if available
cases_file <- file.path(data_dir, "enforcement_cases.rds")
if (file.exists(cases_file)) {
  cases <- readRDS(cases_file)
  setDT(cases)
  cat("Enforcement cases loaded:", nrow(cases), "\n")
  cat("Columns:", paste(names(cases), collapse = ", "), "\n")
}

## 1c. State-year level first stage:
## Higher state-year federal share → more enforcement actions?

## Create state-year enforcement intensity measures from the full panel
state_enforcement <- panel_full[, .(
  total_inspections = sum(n_inspections, na.rm = TRUE),
  total_federal     = sum(n_federal, na.rm = TRUE),
  total_fce         = sum(n_fce, na.rm = TRUE),
  n_facilities      = .N,
  mean_fce_rate     = mean(fce_rate, na.rm = TRUE)
), by = .(state, year)]

state_enforcement[, fed_share := total_federal / total_inspections]
state_enforcement[, insp_per_facility := total_inspections / n_facilities]

## Merge with state-year data
state_panel <- merge(state_enforcement, state_year[, .(state, year, high_federal,
                                                        fed_share_deviation)],
                      by = c("state", "year"), all.x = TRUE)

## State-year TRI emissions
state_tri <- panel_tri[, .(
  mean_log_releases = mean(log_releases, na.rm = TRUE),
  total_releases    = sum(total_releases_lbs, na.rm = TRUE),
  n_tri_facilities  = .N,
  sd_log_releases   = sd(log_releases, na.rm = TRUE)
), by = .(state, year)]
state_tri[, log_total_releases := log(total_releases + 1)]

state_panel <- merge(state_panel, state_tri, by = c("state", "year"), all.x = TRUE)

## State and year FE
state_panel[, state_id := as.integer(factor(state))]

cat("\nState panel:", nrow(state_panel), "state-years\n")
cat("With TRI data:", sum(!is.na(state_panel$mean_log_releases)), "\n")

## ============================================================
## 2. FACILITY-LEVEL REGRESSIONS (within-facility)
## ============================================================
cat("\n=== 2. Facility-Level Regressions ===\n")

## 2a. OLS: Federal inspection → log(TRI releases)
## With facility FE and year FE

m1_ols <- feols(log_releases ~ any_federal | PGM_SYS_ID + year,
                data = panel_tri, cluster = ~state)
cat("\nModel 1 - OLS: any_federal on log(releases), Facility + Year FE\n")
summary(m1_ols)

## 2b. Federal share (continuous)
m2_share <- feols(log_releases ~ fed_share | PGM_SYS_ID + year,
                  data = panel_tri, cluster = ~state)
cat("\nModel 2 - OLS: fed_share on log(releases)\n")
summary(m2_share)

## 2c. Number of federal inspections
m3_n <- feols(log_releases ~ n_federal | PGM_SYS_ID + year,
              data = panel_tri, cluster = ~state)
cat("\nModel 3 - OLS: n_federal on log(releases)\n")
summary(m3_n)

## 2d. Total inspections as control
m4_ctrl <- feols(log_releases ~ any_federal + n_inspections | PGM_SYS_ID + year,
                 data = panel_tri, cluster = ~state)
cat("\nModel 4 - OLS: any_federal + n_inspections\n")
summary(m4_ctrl)

## ============================================================
## 3. IV ESTIMATION: State-year federal share as instrument
## ============================================================
cat("\n=== 3. IV: State-year federal share → enforcement → emissions ===\n")

## The idea: state-year variation in federal inspection intensity
## (driven by SRF reviews or administrative priorities) is quasi-random
## with respect to individual facility emissions

## 3a. First stage at facility level:
## Does state-year federal share predict facility-level federal inspection?
fs1 <- feols(any_federal ~ state_fed_share | PGM_SYS_ID + year,
             data = panel_tri, cluster = ~state)
cat("\nFirst stage: state_fed_share → any_federal\n")
summary(fs1)

## 3b. IV regression
## Instrument facility-level federal inspection with state-year aggregate
m5_iv <- feols(log_releases ~ 1 | PGM_SYS_ID + year | any_federal ~ state_fed_share,
               data = panel_tri, cluster = ~state)
cat("\nModel 5 - IV: state_fed_share instruments any_federal\n")
summary(m5_iv)

## 3c. IV with high_federal as instrument (binary)
m6_iv_binary <- feols(log_releases ~ 1 | PGM_SYS_ID + year | any_federal ~ high_federal,
                      data = panel_tri, cluster = ~state)
cat("\nModel 6 - IV: high_federal instruments any_federal\n")
summary(m6_iv_binary)

## ============================================================
## 4. STATE-YEAR LEVEL REDUCED FORM
## ============================================================
cat("\n=== 4. State-Year Reduced Form ===\n")

## Does state-level federal share predict state-level emissions?
state_panel_tri <- state_panel[!is.na(mean_log_releases)]

m7_rf <- feols(mean_log_releases ~ fed_share | state_id + year,
               data = state_panel_tri, cluster = ~state_id)
cat("\nModel 7 - Reduced form: state fed_share → mean log(releases)\n")
summary(m7_rf)

m8_rf_total <- feols(log_total_releases ~ fed_share | state_id + year,
                     data = state_panel_tri, cluster = ~state_id)
cat("\nModel 8 - Reduced form: state fed_share → total log(releases)\n")
summary(m8_rf_total)

## High federal indicator
m9_rf_binary <- feols(mean_log_releases ~ high_federal | state_id + year,
                      data = state_panel_tri, cluster = ~state_id)
cat("\nModel 9 - Reduced form: high_federal → mean log(releases)\n")
summary(m9_rf_binary)

## ============================================================
## 5. INSPECTION INTENSITY (all facilities)
## ============================================================
cat("\n=== 5. Inspection intensity regressions ===\n")

## Does state-year federal share predict facility inspection frequency?
m10_insp <- feols(n_inspections ~ state_fed_share | PGM_SYS_ID + year,
                  data = panel_full, cluster = ~state)
cat("\nModel 10 - state_fed_share → n_inspections (all facilities)\n")
summary(m10_insp)

## FCE intensity
m11_fce <- feols(fce_rate ~ state_fed_share | PGM_SYS_ID + year,
                 data = panel_full, cluster = ~state)
cat("\nModel 11 - state_fed_share → FCE rate (all facilities)\n")
summary(m11_fce)

## ============================================================
## 6. Save results and diagnostics
## ============================================================
cat("\n=== Saving results ===\n")

## Diagnostics for validator
diag <- list(
  n_treated = uniqueN(panel_tri$PGM_SYS_ID[panel_tri$any_federal == 1]),
  n_pre = length(unique(panel_tri$year[panel_tri$year < 2012])),
  n_obs = nrow(panel_tri)
)
jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("Diagnostics: n_treated =", diag$n_treated,
    ", n_pre =", diag$n_pre, ", n_obs =", diag$n_obs, "\n")

## Save model objects
saveRDS(list(
  m1_ols = m1_ols,
  m2_share = m2_share,
  m3_n = m3_n,
  m4_ctrl = m4_ctrl,
  fs1 = fs1,
  m5_iv = m5_iv,
  m6_iv_binary = m6_iv_binary,
  m7_rf = m7_rf,
  m8_rf_total = m8_rf_total,
  m9_rf_binary = m9_rf_binary,
  m10_insp = m10_insp,
  m11_fce = m11_fce
), file.path(data_dir, "models_main.rds"))

## Save key data for tables
saveRDS(state_panel, file.path(data_dir, "state_panel.rds"))

cat("\n=== Main analysis complete ===\n")
