## 03_main_analysis.R — IV/2SLS: rainfall → protest size → contributions
## apep_1432: Protests and Campaign Contributions (Weather IV)

source("00_packages.R")

panel <- fread("../data/panel.csv") %>% as_tibble()
cat(sprintf("Panel loaded: %d obs, %d cities, %d weeks\n",
            nrow(panel), n_distinct(panel$city_state), n_distinct(panel$year_week)))

## ==========================================================
## A) OLS BASELINE — naive relationship
## ==========================================================

cat("\n=== OLS BASELINE ===\n")

## OLS: protests → contributions (biased by unobserved political engagement)
ols1 <- feols(ln_contributions ~ has_protest | city_id + week_id, data = panel,
              cluster = ~city_id)
ols2 <- feols(ln_contributions ~ ln_protests | city_id + week_id, data = panel,
              cluster = ~city_id)
ols3 <- feols(ln_amount ~ has_protest | city_id + week_id, data = panel,
              cluster = ~city_id)
ols4 <- feols(ln_amount ~ ln_protests | city_id + week_id, data = panel,
              cluster = ~city_id)

cat("OLS results (biased — omitted political engagement shocks):\n")
etable(ols1, ols2, ols3, ols4)

## ==========================================================
## B) FIRST STAGE — rainfall reduces protest attendance
## ==========================================================

cat("\n=== FIRST STAGE ===\n")

## Restrict to city-weeks with protests for first-stage analysis
protest_weeks <- panel %>% filter(has_protest == 1, !is.na(precip_protest_days))

cat(sprintf("City-weeks with protests and weather: %d\n", nrow(protest_weeks)))

## First stage: precipitation on protest days → crowd size
fs1 <- feols(ln_mentions ~ precip_protest_days | city_id + week_id,
             data = protest_weeks, cluster = ~city_id)
fs2 <- feols(ln_protests ~ precip_mean_mm | city_id + week_id,
             data = panel, cluster = ~city_id)

cat("First stage results:\n")
etable(fs1, fs2)
cat(sprintf("First-stage F-stat (mentions): %.1f\n", fitstat(fs1, "wald")$wald$stat))

## ==========================================================
## C) IV/2SLS — Main Specification
## ==========================================================

cat("\n=== IV/2SLS MAIN RESULTS ===\n")

## Strategy: use weekly average precipitation as instrument for protest intensity
## Panel includes both protest and non-protest weeks
## Instrument: precip_mean_mm (weekly average)
## Treatment: ln_protests or has_protest

## Main spec: IV with city + week FE
iv1 <- feols(ln_contributions ~ 1 | city_id + week_id | has_protest ~ precip_mean_mm,
             data = panel, cluster = ~city_id)
iv2 <- feols(ln_contributions ~ 1 | city_id + week_id | ln_protests ~ precip_mean_mm,
             data = panel, cluster = ~city_id)
iv3 <- feols(ln_amount ~ 1 | city_id + week_id | has_protest ~ precip_mean_mm,
             data = panel, cluster = ~city_id)
iv4 <- feols(ln_amount ~ 1 | city_id + week_id | ln_protests ~ precip_mean_mm,
             data = panel, cluster = ~city_id)

cat("IV/2SLS results:\n")
etable(iv1, iv2, iv3, iv4)

## With state x month FE
iv5 <- feols(ln_contributions ~ 1 | city_id + week_id + state_month_id | has_protest ~ precip_mean_mm,
             data = panel, cluster = ~city_id)
iv6 <- feols(ln_amount ~ 1 | city_id + week_id + state_month_id | has_protest ~ precip_mean_mm,
             data = panel, cluster = ~city_id)

cat("IV with state x month FE:\n")
etable(iv5, iv6)

## ==========================================================
## D) REDUCED FORM — direct effect of rain on contributions
## ==========================================================

cat("\n=== REDUCED FORM ===\n")

rf1 <- feols(ln_contributions ~ precip_mean_mm | city_id + week_id,
             data = panel, cluster = ~city_id)
rf2 <- feols(ln_amount ~ precip_mean_mm | city_id + week_id,
             data = panel, cluster = ~city_id)

cat("Reduced form (rain → contributions directly):\n")
etable(rf1, rf2)

## ==========================================================
## E) DONOR EXTENSITY — new donors
## ==========================================================

cat("\n=== DONOR EXTENSITY ===\n")

iv_donors <- feols(ln_donors ~ 1 | city_id + week_id | has_protest ~ precip_mean_mm,
                   data = panel, cluster = ~city_id)

cat("IV: effect on unique donor count:\n")
etable(iv_donors)

## ==========================================================
## F) Save diagnostics
## ==========================================================

## Diagnostics for validation
diag <- list(
  n_treated = n_distinct(panel$city_state[panel$has_protest == 1]),
  n_pre = length(unique(panel$year_week[panel$year < 2020])),
  n_obs = nrow(panel),
  n_cities = n_distinct(panel$city_state),
  n_weeks = n_distinct(panel$year_week),
  pct_protest_weeks = round(100 * mean(panel$has_protest), 2),
  first_stage_F = round(fitstat(fs2, "wald")$wald$stat, 1)
)

jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat("\nDiagnostics saved.\n")

## Save key regression objects for tables
save(ols1, ols2, ols3, ols4,
     fs1, fs2,
     iv1, iv2, iv3, iv4, iv5, iv6,
     rf1, rf2, iv_donors,
     file = "../data/main_results.RData")
cat("Main results saved.\n")
