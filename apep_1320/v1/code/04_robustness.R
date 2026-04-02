## 04_robustness.R — Robustness, placebos, heterogeneity, balance tests
source("00_packages.R")

data_dir <- "../data"
county <- fread(file.path(data_dir, "analysis_county.csv"))
load(file.path(data_dir, "main_results.RData"))

controls <- "log_pop + log_land_area + county_lat + county_lon + lat_sq + lon_sq"

cat("=== Balance Tests ===\n")
## Pre-determined covariates should not differ by instrument
bal_pop <- feols(log_pop ~ has_wwii_airfield | division,
                 data = county, cluster = ~state_fips)
bal_area <- feols(log_land_area ~ has_wwii_airfield | division,
                  data = county, cluster = ~state_fips)
bal_lat <- feols(county_lat ~ has_wwii_airfield | division,
                 data = county, cluster = ~state_fips)
bal_lon <- feols(county_lon ~ has_wwii_airfield | division,
                 data = county, cluster = ~state_fips)
bal_density <- feols(log_pop_density ~ has_wwii_airfield | division,
                     data = county, cluster = ~state_fips)

cat("Balance on log(pop):", round(coef(bal_pop)["has_wwii_airfield"], 3),
    " (se:", round(se(bal_pop)["has_wwii_airfield"], 3), ")\n")
cat("Balance on log(area):", round(coef(bal_area)["has_wwii_airfield"], 3),
    " (se:", round(se(bal_area)["has_wwii_airfield"], 3), ")\n")
cat("Balance on latitude:", round(coef(bal_lat)["has_wwii_airfield"], 3),
    " (se:", round(se(bal_lat)["has_wwii_airfield"], 3), ")\n")
cat("Balance on longitude:", round(coef(bal_lon)["has_wwii_airfield"], 3),
    " (se:", round(se(bal_lon)["has_wwii_airfield"], 3), ")\n")
cat("Balance on density:", round(coef(bal_density)["has_wwii_airfield"], 3),
    " (se:", round(se(bal_density)["has_wwii_airfield"], 3), ")\n")

cat("\n=== Placebo Outcomes ===\n")
## If airports → service economy, services should be POSITIVE
## Retail should be roughly zero (non-tradeable)

## Services (NAICS 54)
iv_svc <- feols(as.formula(paste("svc_share ~", controls,
                                  "| division | has_med_large ~ has_wwii_airfield")),
                data = county, cluster = ~state_fips)
cat("IV → services share:", round(coef(iv_svc)["fit_has_med_large"], 4),
    " (se:", round(se(iv_svc)["fit_has_med_large"], 4), ")\n")

## Retail (NAICS 44-45) — non-tradeable placebo
iv_ret <- feols(as.formula(paste("ret_share ~", controls,
                                  "| division | has_med_large ~ has_wwii_airfield")),
                data = county, cluster = ~state_fips)
cat("IV → retail share:", round(coef(iv_ret)["fit_has_med_large"], 4),
    " (se:", round(se(iv_ret)["fit_has_med_large"], 4), ")\n")

## Log services employment
iv_svc_log <- feols(as.formula(paste("log_emp_svc ~", controls,
                                      "| division | has_med_large ~ has_wwii_airfield")),
                    data = county, cluster = ~state_fips)
cat("IV → log svc emp:", round(coef(iv_svc_log)["fit_has_med_large"], 4),
    " (se:", round(se(iv_svc_log)["fit_has_med_large"], 4), ")\n")

cat("\n=== Alternative Treatment Definitions ===\n")

## Using count of airports instead of binary
iv_count <- feols(as.formula(paste("mfg_share ~", controls,
                                    "| division | n_airports ~ n_wwii_airfields")),
                  data = county, cluster = ~state_fips)
cat("IV (count airports):", round(coef(iv_count)["fit_n_airports"], 4), "\n")

## Using any airport (not just med/large)
iv_any <- feols(as.formula(paste("mfg_share ~", controls,
                                  "| division | has_airport ~ has_wwii_airfield")),
                data = county, cluster = ~state_fips)
cat("IV (any airport):", round(coef(iv_any)["fit_has_airport"], 4), "\n")

cat("\n=== Heterogeneity: Urban vs Rural ===\n")

## Split by population density (median split)
med_density <- median(county$pop_density)
county[, urban := as.integer(pop_density >= med_density)]

iv_urban <- feols(as.formula(paste("mfg_share ~", controls,
                                    "| division | has_med_large ~ has_wwii_airfield")),
                  data = county[urban == 1], cluster = ~state_fips)
iv_rural <- feols(as.formula(paste("mfg_share ~", controls,
                                    "| division | has_med_large ~ has_wwii_airfield")),
                  data = county[urban == 0], cluster = ~state_fips)

cat("IV urban:", round(coef(iv_urban)["fit_has_med_large"], 4),
    " (se:", round(se(iv_urban)["fit_has_med_large"], 4), ")\n")
cat("IV rural:", round(coef(iv_rural)["fit_has_med_large"], 4),
    " (se:", round(se(iv_rural)["fit_has_med_large"], 4), ")\n")

cat("\n=== Anderson-Rubin Confidence Intervals ===\n")
## Weak-IV robust inference
## AR test: test H0: β = β0 using reduced form
## Grid search for 95% CI
beta_grid <- seq(-0.3, 0.1, by = 0.005)
ar_pvals <- sapply(beta_grid, function(b0) {
  county[, y_adj := mfg_share - b0 * has_med_large]
  rf_test <- feols(as.formula(paste("y_adj ~ has_wwii_airfield +", controls, "| division")),
                   data = county, cluster = ~state_fips)
  ## Wald test on has_wwii_airfield
  t_stat <- coef(rf_test)["has_wwii_airfield"] / se(rf_test)["has_wwii_airfield"]
  2 * pnorm(-abs(t_stat))
})

ar_ci <- beta_grid[ar_pvals >= 0.05]
if (length(ar_ci) > 0) {
  cat("AR 95% CI: [", round(min(ar_ci), 4), ",", round(max(ar_ci), 4), "]\n")
} else {
  cat("AR CI: empty (instrument very strong, standard CI adequate)\n")
}

cat("\n=== Additional First Stage Diagnostics ===\n")

## First stage with additional controls
fs_full <- feols(as.formula(paste("has_med_large ~ has_wwii_airfield + n_wwii_airfields +",
                                   controls, "| division")),
                 data = county, cluster = ~state_fips)
cat("First stage with count:", round(coef(fs_full)["has_wwii_airfield"], 4),
    "binary +", round(coef(fs_full)["n_wwii_airfields"], 4), "count\n")

## Intensive margin: number of airfields → number of airports
fs_intensive <- feols(as.formula(paste("n_airports ~ n_wwii_airfields +",
                                        controls, "| division")),
                      data = county, cluster = ~state_fips)
cat("Intensive first stage:", round(coef(fs_intensive)["n_wwii_airfields"], 4),
    " (se:", round(se(fs_intensive)["n_wwii_airfields"], 4), ")\n")

## ================================================================
## Save robustness results
## ================================================================
save(bal_pop, bal_area, bal_lat, bal_lon, bal_density,
     iv_svc, iv_ret, iv_svc_log, iv_count, iv_any,
     iv_urban, iv_rural,
     file = file.path(data_dir, "robustness_results.RData"))
cat("\nRobustness results saved.\n")
