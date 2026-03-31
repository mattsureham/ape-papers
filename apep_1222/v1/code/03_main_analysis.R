## 03_main_analysis.R — DiD and event study
## apep_1222: When the Mine Money Stops

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

cat(sprintf("Panel: %s obs, %d mining munis, %d control munis\n",
            format(nrow(panel), big.mark = ","),
            uniqueN(panel[mining == 1]$cve_mun),
            uniqueN(panel[mining == 0]$cve_mun)))

## ---- 1. Main DiD Specification ----
cat("Running main DiD specification...\n")

# TWFE DiD: log(total_crime+1) ~ mining × post | municipality + year
# Clustering at state level (~32 clusters)
did_total <- feols(log_total ~ mining:post | cve_mun + year,
                   data = panel, cluster = ~state_code)

did_homicide <- feols(log_homicide ~ mining:post | cve_mun + year,
                      data = panel, cluster = ~state_code)

did_robbery <- feols(log_robbery ~ mining:post | cve_mun + year,
                     data = panel, cluster = ~state_code)

did_extortion <- feols(log_extortion ~ mining:post | cve_mun + year,
                       data = panel, cluster = ~state_code)

did_dv <- feols(log_dv ~ mining:post | cve_mun + year,
                data = panel, cluster = ~state_code)

cat("\n=== Main DiD Results ===\n")
etable(did_total, did_homicide, did_robbery, did_extortion, did_dv,
       headers = c("Total", "Homicide", "Robbery", "Extortion", "Dom. Violence"))

## ---- 2. Event Study ----
cat("\nRunning event study...\n")

# Create event-time indicators (relative to 2020)
panel[, event_time := year - 2020]

# Event study: interact mining with year dummies (omit 2019 = event_time -1)
es_total <- feols(log_total ~ i(event_time, mining, ref = -1) | cve_mun + year,
                  data = panel, cluster = ~state_code)

es_homicide <- feols(log_homicide ~ i(event_time, mining, ref = -1) | cve_mun + year,
                     data = panel, cluster = ~state_code)

es_robbery <- feols(log_robbery ~ i(event_time, mining, ref = -1) | cve_mun + year,
                    data = panel, cluster = ~state_code)

cat("\n=== Event Study: Total Crime ===\n")
summary(es_total)

## ---- 3. State × Year Fixed Effects ----
cat("\nRunning DiD with state × year FE...\n")
did_stateyear <- feols(log_total ~ mining:post | cve_mun + state_code^year,
                       data = panel, cluster = ~state_code)
cat("State × year FE:\n")
summary(did_stateyear)

## ---- 4. Store results ----
results <- list(
  did_total = did_total,
  did_homicide = did_homicide,
  did_robbery = did_robbery,
  did_extortion = did_extortion,
  did_dv = did_dv,
  es_total = es_total,
  es_homicide = es_homicide,
  es_robbery = es_robbery,
  did_stateyear = did_stateyear
)
saveRDS(results, file.path(data_dir, "regression_results.rds"))

## ---- 5. Diagnostics ----
cat("\nWriting diagnostics.json...\n")

n_treated <- uniqueN(panel[mining == 1]$cve_mun)
n_pre <- length(unique(panel[year < 2021]$year))
n_obs <- nrow(panel)

# Pre-trend test: joint significance of pre-treatment event-study coefficients
es_coefs <- coeftable(es_total)
pre_coefs <- es_coefs[grepl("event_time::-[2-9]|event_time::-[1-9][0-9]", rownames(es_coefs)), ]

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_clusters = length(unique(panel$state_code)),
  n_control = uniqueN(panel[mining == 0]$cve_mun),
  main_coef = coef(did_total)[[1]],
  main_se = se(did_total)[[1]],
  main_pval = pvalue(did_total)[[1]],
  pre_trend_max_abs = if (nrow(pre_coefs) > 0) max(abs(pre_coefs[, "Estimate"])) else NA,
  sd_y_pre = sd(panel[mining == 1 & year < 2021]$log_total, na.rm = TRUE),
  sd_y_all = sd(panel$log_total, na.rm = TRUE),
  mean_y_treated_pre = mean(panel[mining == 1 & year < 2021]$total_crime, na.rm = TRUE),
  mean_y_control_pre = mean(panel[mining == 0 & year < 2021]$total_crime, na.rm = TRUE)
)

write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
           auto_unbox = TRUE, pretty = TRUE)

cat(sprintf("\nDiagnostics: %d treated units, %d pre-periods, %s obs\n",
            diagnostics$n_treated, diagnostics$n_pre,
            format(diagnostics$n_obs, big.mark = ",")))
cat(sprintf("Main effect: %.4f (SE = %.4f, p = %.4f)\n",
            diagnostics$main_coef, diagnostics$main_se, diagnostics$main_pval))
cat("Results saved.\n")
