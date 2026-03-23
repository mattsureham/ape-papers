## 03_main_analysis.R — Main DiD regressions
## apep_0780: Last Orders for Crime?

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
cat(sprintf("Loaded %d observations\n", nrow(panel)))

## ========================================================================
## MAIN SPECIFICATION: Binary DiD (CIA forces vs non-CIA forces)
## ========================================================================

## ---- Outcome 1: Log violent crime ----
cat("\n=== Violent Crime ===\n")
m1_basic <- feols(log_violent_crime ~ did | force + fy_start, data = panel, cluster = ~force)
m1_full  <- feols(log_violent_crime ~ did | force + fy_start, data = panel, cluster = ~force)
print(summary(m1_full))

## ---- Outcome 2: Log ASB ----
cat("\n=== Anti-Social Behaviour ===\n")
m2 <- feols(log_criminal_damage ~ did | force + fy_start, data = panel, cluster = ~force)
print(summary(m2))

## ---- Outcome 3: Log public order ----
cat("\n=== Public Order ===\n")
m3 <- feols(log_public_order ~ did | force + fy_start, data = panel, cluster = ~force)
print(summary(m3))

## ---- Outcome 4: Log total crime ----
cat("\n=== Total Crime ===\n")
m4 <- feols(log_total_crime ~ did | force + fy_start, data = panel, cluster = ~force)
print(summary(m4))

## ---- Placebo: Bicycle theft ----
cat("\n=== Placebo: Bicycle Theft ===\n")
m_bike <- feols(log_bike_theft ~ did | force + fy_start, data = panel, cluster = ~force)
print(summary(m_bike))

## ---- Placebo: Vehicle crime ----
cat("\n=== Placebo: Vehicle Crime ===\n")
m_vehicle <- feols(log_vehicle_crime ~ did | force + fy_start, data = panel, cluster = ~force)
print(summary(m_vehicle))

## ========================================================================
## EVENT STUDY
## ========================================================================
cat("\n=== Event Study ===\n")

es_violent <- feols(log_violent_crime ~ i(rel_year, treated, ref = -1) | force + fy_start,
                    data = panel, cluster = ~force)
print(summary(es_violent))

es_asb <- feols(log_criminal_damage ~ i(rel_year, treated, ref = -1) | force + fy_start,
                data = panel, cluster = ~force)

es_bike <- feols(log_bike_theft ~ i(rel_year, treated, ref = -1) | force + fy_start,
                 data = panel, cluster = ~force)

## ========================================================================
## SAVE
## ========================================================================
save(m1_basic, m1_full, m2, m3, m4, m_bike, m_vehicle,
     es_violent, es_asb, es_bike,
     file = file.path(data_dir, "main_models.rda"))

## ========================================================================
## DIAGNOSTICS
## ========================================================================
n_treated <- sum(panel$treated == 1 & panel$post == 0) / length(unique(panel$year[panel$post == 0]))
n_pre <- length(unique(panel$year[panel$post == 0]))

diagnostics <- list(
  n_treated = as.integer(n_treated),
  n_pre = n_pre,
  n_obs = nrow(panel),
  outcomes = c("log_violent_crime", "log_criminal_damage", "log_public_order", "log_total_crime"),
  treatment = "CIA statutory strengthening (April 2018)",
  estimator = "TWFE DiD with force + fy_start FE, force-clustered"
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)

cat(sprintf("\nDiagnostics: N=%d, treated forces=%d, pre-periods=%d\n",
            nrow(panel), diagnostics$n_treated, n_pre))
cat("\nMain analysis complete.\n")
