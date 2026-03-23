## 04_robustness.R — Robustness checks
## apep_0780: Last Orders for Crime?

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

## ========================================================================
## 1. LEVELS (not logs)
## ========================================================================
cat("\n=== Levels specification ===\n")
level_violent <- feols(violent_crime ~ did | force + fy_start, data = panel, cluster = ~force)
level_damage <- feols(criminal_damage ~ did | force + fy_start, data = panel, cluster = ~force)
cat("Violent (levels):", coef(level_violent)["did"], "\n")
cat("ASB (levels):", coef(level_damage)["did"], "\n")

## ========================================================================
## 2. EXCLUDING COVID YEARS (2020-2021)
## ========================================================================
cat("\n=== Excluding COVID years ===\n")
no_covid <- panel[!(fy_start %in% c(2020, 2021))]
covid_violent <- feols(log_violent_crime ~ did | force + fy_start, data = no_covid, cluster = ~force)
covid_damage <- feols(log_criminal_damage ~ did | force + fy_start, data = no_covid, cluster = ~force)
cat("Violent (no COVID):", coef(covid_violent)["did"], "\n")
cat("ASB (no COVID):", coef(covid_damage)["did"], "\n")

## ========================================================================
## 3. PLACEBO TREATMENT DATE (2016)
## ========================================================================
cat("\n=== Placebo treatment at 2016 ===\n")
pre_only <- panel[fy_start <= 2017]
pre_only[, placebo_post := as.integer(fy_start >= 2016)]
pre_only[, placebo_did := treated * placebo_post]
placebo_violent <- feols(log_violent_crime ~ placebo_did | force + fy_start,
                         data = pre_only, cluster = ~force)
cat("Placebo 2016 (violent):", coef(placebo_violent)["placebo_did"], "\n")

## ========================================================================
## SAVE
## ========================================================================
save(level_violent, level_damage,
     covid_violent, covid_damage,
     placebo_violent,
     file = file.path(data_dir, "robustness_models.rda"))

cat("\nRobustness checks complete.\n")
