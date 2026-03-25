## 03_main_analysis.R — Main regressions for apep_0898
## Grocery exit cascades: anchor store hypothesis

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

cat(sprintf("Panel: %d county-years, %d counties\n", nrow(panel), n_distinct(panel$fips)))

## ============================================================
## 1. TWFE Baseline (for comparison — known to be biased)
## ============================================================
cat("\n===== TWFE BASELINE =====\n")

## First stage: Bartik IV → grocery establishments
twfe_fs <- feols(
  log_grocery ~ bartik_iv | fips + year,
  data = panel,
  cluster = ~state
)
cat("First stage (Bartik → log grocery):\n")
summary(twfe_fs)

## OLS reduced form: post exposure → non-grocery retail
twfe_rf_food <- feols(
  log_foodservice ~ post_exposure | fips + year,
  data = panel,
  cluster = ~state
)

twfe_rf_health <- feols(
  log_health ~ post_exposure | fips + year,
  data = panel,
  cluster = ~state
)

twfe_rf_personal <- feols(
  log_personal ~ post_exposure | fips + year,
  data = panel,
  cluster = ~state
)

twfe_rf_nongrocery <- feols(
  log_nongrocery ~ post_exposure | fips + year,
  data = panel,
  cluster = ~state
)

cat("\nTWFE reduced form results:\n")
cat(sprintf("  Food service: %.4f (SE: %.4f)\n",
            coef(twfe_rf_food)["post_exposureTRUE"],
            se(twfe_rf_food)["post_exposureTRUE"]))
cat(sprintf("  Health:       %.4f (SE: %.4f)\n",
            coef(twfe_rf_health)["post_exposureTRUE"],
            se(twfe_rf_health)["post_exposureTRUE"]))
cat(sprintf("  Personal:     %.4f (SE: %.4f)\n",
            coef(twfe_rf_personal)["post_exposureTRUE"],
            se(twfe_rf_personal)["post_exposureTRUE"]))

## ============================================================
## 2. IV / 2SLS: Bartik → grocery decline → cascade
## ============================================================
cat("\n===== 2SLS: BARTIK IV =====\n")

## IV: instrument grocery change with Bartik IV
## Endogenous: log_grocery
## Instrument: bartik_iv
## Outcome: log non-grocery retail sectors

iv_foodservice <- feols(
  log_foodservice ~ 1 | fips + year | log_grocery ~ bartik_iv,
  data = panel,
  cluster = ~state
)

iv_health <- feols(
  log_health ~ 1 | fips + year | log_grocery ~ bartik_iv,
  data = panel,
  cluster = ~state
)

iv_personal <- feols(
  log_personal ~ 1 | fips + year | log_grocery ~ bartik_iv,
  data = panel,
  cluster = ~state
)

iv_nongrocery <- feols(
  log_nongrocery ~ 1 | fips + year | log_grocery ~ bartik_iv,
  data = panel,
  cluster = ~state
)

cat("IV results (effect of log grocery on outcomes):\n")
cat(sprintf("  Food service:  %.4f (SE: %.4f)\n",
            coef(iv_foodservice)["fit_log_grocery"],
            se(iv_foodservice)["fit_log_grocery"]))
cat(sprintf("  Health:        %.4f (SE: %.4f)\n",
            coef(iv_health)["fit_log_grocery"],
            se(iv_health)["fit_log_grocery"]))
cat(sprintf("  Personal:      %.4f (SE: %.4f)\n",
            coef(iv_personal)["fit_log_grocery"],
            se(iv_personal)["fit_log_grocery"]))
cat(sprintf("  Non-grocery:   %.4f (SE: %.4f)\n",
            coef(iv_nongrocery)["fit_log_grocery"],
            se(iv_nongrocery)["fit_log_grocery"]))

## First-stage F-statistic
fs_stat <- fitstat(iv_foodservice, "ivf")
cat(sprintf("\nFirst-stage F-statistic: %.1f\n", fs_stat$ivf1$stat))

## ============================================================
## 3. Callaway-Sant'Anna DiD (robust to staggered treatment)
## ============================================================
cat("\n===== CALLAWAY-SANT'ANNA DiD =====\n")

## Prepare data for CS: need integer IDs and first_treat
cs_data <- panel %>%
  mutate(
    county_id = as.integer(factor(fips)),
    g = ifelse(first_treat == 0, 0, first_treat)
  ) %>%
  filter(!is.na(log_foodservice), !is.na(log_grocery))

## CS-DiD for food service (main outcome)
cs_food <- att_gt(
  yname = "log_foodservice",
  tname = "year",
  idname = "county_id",
  gname = "g",
  data = cs_data,
  control_group = "nevertreated",
  base_period = "universal"
)

## Aggregate to event time
es_food <- aggte(cs_food, type = "dynamic", min_e = -5, max_e = 10)
cat("\nCS-DiD Event Study (food service):\n")
summary(es_food)

## Overall ATT
att_food <- aggte(cs_food, type = "simple")
cat(sprintf("\nOverall ATT (food service): %.4f (SE: %.4f)\n",
            att_food$overall.att, att_food$overall.se))

## CS-DiD for health stores
cs_health <- att_gt(
  yname = "log_health",
  tname = "year",
  idname = "county_id",
  gname = "g",
  data = cs_data,
  control_group = "nevertreated",
  base_period = "universal"
)
att_health <- aggte(cs_health, type = "simple")
cat(sprintf("Overall ATT (health): %.4f (SE: %.4f)\n",
            att_health$overall.att, att_health$overall.se))

## CS-DiD for personal services
cs_personal <- att_gt(
  yname = "log_personal",
  tname = "year",
  idname = "county_id",
  gname = "g",
  data = cs_data,
  control_group = "nevertreated",
  base_period = "universal"
)
att_personal <- aggte(cs_personal, type = "simple")
cat(sprintf("Overall ATT (personal): %.4f (SE: %.4f)\n",
            att_personal$overall.att, att_personal$overall.se))

## CS-DiD for grocery itself (first stage check)
cs_grocery <- att_gt(
  yname = "log_grocery",
  tname = "year",
  idname = "county_id",
  gname = "g",
  data = cs_data,
  control_group = "nevertreated",
  base_period = "universal"
)
att_grocery <- aggte(cs_grocery, type = "simple")
cat(sprintf("Overall ATT (grocery — first stage): %.4f (SE: %.4f)\n",
            att_grocery$overall.att, att_grocery$overall.se))

es_grocery <- aggte(cs_grocery, type = "dynamic", min_e = -5, max_e = 10)

## ============================================================
## 4. Save results for tables
## ============================================================
results <- list(
  twfe_fs = twfe_fs,
  twfe_rf_food = twfe_rf_food,
  twfe_rf_health = twfe_rf_health,
  twfe_rf_personal = twfe_rf_personal,
  twfe_rf_nongrocery = twfe_rf_nongrocery,
  iv_foodservice = iv_foodservice,
  iv_health = iv_health,
  iv_personal = iv_personal,
  iv_nongrocery = iv_nongrocery,
  cs_food = cs_food,
  cs_health = cs_health,
  cs_personal = cs_personal,
  cs_grocery = cs_grocery,
  att_food = att_food,
  att_health = att_health,
  att_personal = att_personal,
  att_grocery = att_grocery,
  es_food = es_food,
  es_grocery = es_grocery
)

saveRDS(results, file.path(data_dir, "results.rds"))

## Update diagnostics
diag <- jsonlite::fromJSON(file.path(data_dir, "diagnostics.json"))
diag$n_treated <- n_distinct(panel$fips[panel$ever_exposed])
diag$n_pre <- min(panel$first_treat[panel$first_treat > 0]) - min(panel$year)
diag$n_obs <- nrow(panel)
diag$fs_fstat <- fs_stat$ivf1$stat
jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("\nMain analysis complete. Results saved.\n")
