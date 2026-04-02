## 03_main_analysis.R — Main DiD analysis
## apep_1315: The Forever Chemical Discount

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

## ---- 0. Clean panel for analysis ----
# Remove observations with missing or infinite values
panel <- panel[is.finite(hpi) & hpi > 0]
panel[, log_hpi := log(hpi)]

# Recalculate growth cleanly
panel <- panel[order(zip5, year)]
panel[, hpi_growth := c(NA, diff(log_hpi)), by = zip5]

# Balanced panel: keep ZIPs with all 11 years (2014-2024)
zip_counts <- panel[, .N, by = zip5]
balanced_zips <- zip_counts[N == 11, zip5]
panel_bal <- panel[zip5 %in% balanced_zips]

cat("Balanced panel: ", nrow(panel_bal), " obs, ", uniqueN(panel_bal$zip5), " ZIPs\n")
cat("  Treated:", uniqueN(panel_bal$zip5[panel_bal$treat == 1]), "\n")
cat("  Control:", uniqueN(panel_bal$zip5[panel_bal$treat == 0]), "\n")

## ---- 1. Event study (main specification) ----
cat("\nRunning event study...\n")

# Create event-time indicators (relative to 2024)
panel_bal[, event_time := year - 2024]

# Event study with fixest::feols
es_model <- feols(
  log_hpi ~ i(event_time, treat, ref = -1) | zip5 + year,
  data = panel_bal,
  cluster = ~state
)

cat("Event study results:\n")
print(summary(es_model))

## ---- 2. Main DiD (TWFE — appropriate here since common treatment timing) ----
cat("\nMain DiD specification...\n")

# Simple DiD: above-MCL × post-2024
did_main <- feols(
  log_hpi ~ treat_post | zip5 + year,
  data = panel_bal,
  cluster = ~state
)

cat("Main DiD:\n")
print(summary(did_main))

## ---- 3. Triple-difference: prior state MCL ----
cat("\nTriple-difference with prior state MCL...\n")

# Need to construct interaction terms
panel_bal[, `:=`(
  post_noprior = post * no_prior_mcl,
  treat_noprior = treat * no_prior_mcl,
  treat_post = treat * post
)]

ddd_model <- feols(
  log_hpi ~ treat_post + treat_post_noprior + post_noprior | zip5 + year,
  data = panel_bal,
  cluster = ~state
)

cat("DDD results:\n")
print(summary(ddd_model))

## ---- 4. Dose-response: continuous PFAS concentration ----
cat("\nDose-response specification...\n")

# Use max PFOA/PFOS concentration as continuous treatment
panel_bal[, max_pfas_ppt := pmax(max_pfoa_ppt, max_pfos_ppt)]
panel_bal[, log_pfas := log(max_pfas_ppt + 1)]

# Continuous treatment DiD
dose_model <- feols(
  log_hpi ~ log_pfas:post | zip5 + year,
  data = panel_bal,
  cluster = ~state
)

cat("Dose-response results:\n")
print(summary(dose_model))

## ---- 5. Alternative clustering ----
cat("\nAlternative clustering...\n")

# ZIP-level clustering
did_zip_clust <- feols(
  log_hpi ~ treat_post | zip5 + year,
  data = panel_bal,
  cluster = ~zip5
)

cat("ZIP-clustered SE:", coef(did_zip_clust)["treat_post"],
    "SE:", se(did_zip_clust)["treat_post"], "\n")

## ---- 6. Store results for tables ----
results <- list(
  event_study = es_model,
  did_main = did_main,
  ddd = ddd_model,
  dose_response = dose_model,
  did_zip_clust = did_zip_clust
)

saveRDS(results, file.path(data_dir, "main_results.rds"))

## ---- 7. Diagnostics for validator ----
diag <- list(
  n_treated = uniqueN(panel_bal$zip5[panel_bal$treat == 1]),
  n_pre = length(2014:2023),
  n_obs = nrow(panel_bal),
  n_clusters_state = uniqueN(panel_bal$state),
  n_control = uniqueN(panel_bal$zip5[panel_bal$treat == 0]),
  main_coef = as.numeric(coef(did_main)["treat_post"]),
  main_se = as.numeric(se(did_main)["treat_post"]),
  main_pval = pvalue(did_main)["treat_post"],
  ddd_coef_noprior = as.numeric(coef(ddd_model)["treat_post_noprior"]),
  ddd_se_noprior = as.numeric(se(ddd_model)["treat_post_noprior"]),
  sd_y_pre = sd(panel_bal$log_hpi[panel_bal$year < 2024], na.rm = TRUE)
)

write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE, pretty = TRUE)

cat("\n=== MAIN RESULTS SUMMARY ===\n")
cat("DiD (treat × post):", round(diag$main_coef, 5),
    "(SE:", round(diag$main_se, 5), ")\n")
cat("DDD (no prior MCL):", round(diag$ddd_coef_noprior, 5),
    "(SE:", round(diag$ddd_se_noprior, 5), ")\n")
cat("Pre-treatment SD(log HPI):", round(diag$sd_y_pre, 4), "\n")
cat("SDE:", round(diag$main_coef / diag$sd_y_pre, 4), "\n")
cat("N treated:", diag$n_treated, "N control:", diag$n_control, "\n")
cat("N observations:", diag$n_obs, "\n")

cat("\nMain analysis complete.\n")
