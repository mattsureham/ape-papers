# ===========================================================================
# 03_main_analysis.R — Main IV/DiD analysis for apep_0919
# Whistleblower Shield and Corruption Exposure
# ===========================================================================

source("00_packages.R")

data_dir <- "../data/"
tables_dir <- "../tables/"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(paste0(data_dir, "analysis_panel.csv"))

# Ensure factor variables
panel[, iso2 := as.factor(iso2)]
panel[, year_f := as.factor(year)]

cat("=== MAIN ANALYSIS ===\n")
cat("Panel: ", nrow(panel), " obs, ", panel[, uniqueN(iso2)], " countries, ",
    paste(range(panel$year), collapse = "-"), "\n\n")

# ===========================================================================
# 1. TWFE — Baseline (for comparison)
# ===========================================================================

cat("--- 1. TWFE Baseline ---\n")

# Primary outcome: corruption per capita (log)
twfe_corruption <- feols(
  ln_corruption_pc ~ treated + ln_gdp_pc | iso2 + year_f,
  data = panel[!is.na(ln_corruption_pc)],
  cluster = ~iso2
)
cat("TWFE Corruption:\n")
print(summary(twfe_corruption))

# Secondary: fraud per capita (log)
twfe_fraud <- feols(
  ln_fraud_pc ~ treated + ln_gdp_pc | iso2 + year_f,
  data = panel[!is.na(ln_fraud_pc)],
  cluster = ~iso2
)
cat("\nTWFE Fraud:\n")
print(summary(twfe_fraud))

# CPI score
twfe_cpi <- feols(
  cpi_score ~ treated + ln_gdp_pc | iso2 + year_f,
  data = panel[!is.na(cpi_score)],
  cluster = ~iso2
)
cat("\nTWFE CPI:\n")
print(summary(twfe_cpi))

# Court expenditure per capita
twfe_court <- feols(
  court_exp_pc ~ treated + ln_gdp_pc | iso2 + year_f,
  data = panel[!is.na(court_exp_pc)],
  cluster = ~iso2
)
cat("\nTWFE Court Expenditure:\n")
print(summary(twfe_court))

# ===========================================================================
# 2. TWFE Event Study
# ===========================================================================

cat("\n--- 2. Event Study ---\n")

# Create event-time dummies
panel[, rel_time_capped := fifelse(is.na(rel_time), -999L,
  fifelse(rel_time < -4, -4L, fifelse(rel_time > 3, 3L, rel_time)))]

# Drop never-treated from event study sample
es_sample <- panel[g > 0 & !is.na(ln_corruption_pc)]

es_corruption <- feols(
  ln_corruption_pc ~ i(rel_time_capped, ref = -1) + ln_gdp_pc | iso2 + year_f,
  data = es_sample,
  cluster = ~iso2
)
cat("Event Study (Corruption):\n")
print(summary(es_corruption))

es_fraud <- feols(
  ln_fraud_pc ~ i(rel_time_capped, ref = -1) + ln_gdp_pc | iso2 + year_f,
  data = panel[g > 0 & !is.na(ln_fraud_pc)],
  cluster = ~iso2
)
cat("\nEvent Study (Fraud):\n")
print(summary(es_fraud))

es_cpi <- feols(
  cpi_score ~ i(rel_time_capped, ref = -1) + ln_gdp_pc | iso2 + year_f,
  data = panel[g > 0 & !is.na(cpi_score)],
  cluster = ~iso2
)
cat("\nEvent Study (CPI):\n")
print(summary(es_cpi))

# ===========================================================================
# 3. Callaway-Sant'Anna (Robust to heterogeneous treatment effects)
# ===========================================================================

cat("\n--- 3. Callaway-Sant'Anna ---\n")

# Prepare data for did package
cs_data <- panel[!is.na(ln_corruption_pc)]
cs_data[, id := as.integer(as.factor(iso2))]

# CS-DiD: corruption
cs_corruption <- att_gt(
  yname = "ln_corruption_pc",
  tname = "year",
  idname = "id",
  gname = "g",
  xformla = ~ ln_gdp_pc,
  data = as.data.frame(cs_data),
  control_group = "notyettreated",
  est_method = "reg",
  clustervars = "id",
  base_period = "universal"
)
cat("CS-DiD Corruption (group-time ATTs):\n")
print(summary(cs_corruption))

# Aggregate to overall ATT
agg_corruption <- aggte(cs_corruption, type = "simple")
cat("\nCS-DiD Aggregate ATT (Corruption):\n")
print(summary(agg_corruption))

# Dynamic aggregation (event study)
es_agg_corruption <- aggte(cs_corruption, type = "dynamic", min_e = -4, max_e = 3)
cat("\nCS-DiD Dynamic (Corruption):\n")
print(summary(es_agg_corruption))

# CS-DiD: fraud
cs_data_fraud <- panel[!is.na(ln_fraud_pc)]
cs_data_fraud[, id := as.integer(as.factor(iso2))]

cs_fraud <- att_gt(
  yname = "ln_fraud_pc",
  tname = "year",
  idname = "id",
  gname = "g",
  xformla = ~ ln_gdp_pc,
  data = as.data.frame(cs_data_fraud),
  control_group = "notyettreated",
  est_method = "reg",
  clustervars = "id",
  base_period = "universal"
)
agg_fraud <- aggte(cs_fraud, type = "simple")
cat("\nCS-DiD Aggregate ATT (Fraud):\n")
print(summary(agg_fraud))

es_agg_fraud <- aggte(cs_fraud, type = "dynamic", min_e = -4, max_e = 3)

# CS-DiD: CPI
cs_data_cpi <- panel[!is.na(cpi_score)]
cs_data_cpi[, id := as.integer(as.factor(iso2))]

cs_cpi <- att_gt(
  yname = "cpi_score",
  tname = "year",
  idname = "id",
  gname = "g",
  xformla = ~ ln_gdp_pc,
  data = as.data.frame(cs_data_cpi),
  control_group = "notyettreated",
  est_method = "reg",
  clustervars = "id",
  base_period = "universal"
)
agg_cpi <- aggte(cs_cpi, type = "simple")
cat("\nCS-DiD Aggregate ATT (CPI):\n")
print(summary(agg_cpi))

es_agg_cpi <- aggte(cs_cpi, type = "dynamic", min_e = -4, max_e = 3)

# ===========================================================================
# 4. Save regression results for tables
# ===========================================================================

results <- list(
  twfe_corruption = twfe_corruption,
  twfe_fraud = twfe_fraud,
  twfe_cpi = twfe_cpi,
  twfe_court = twfe_court,
  es_corruption = es_corruption,
  es_fraud = es_fraud,
  es_cpi = es_cpi,
  cs_corruption = cs_corruption,
  cs_fraud = cs_fraud,
  cs_cpi = cs_cpi,
  agg_corruption = agg_corruption,
  agg_fraud = agg_fraud,
  agg_cpi = agg_cpi,
  es_agg_corruption = es_agg_corruption,
  es_agg_fraud = es_agg_fraud,
  es_agg_cpi = es_agg_cpi
)

saveRDS(results, paste0(data_dir, "main_results.rds"))

# ===========================================================================
# 5. Write diagnostics.json
# ===========================================================================

n_treated_countries <- panel[treated == 1, uniqueN(iso2)]
n_pre <- panel[!is.na(ln_corruption_pc) & year < 2021, uniqueN(year)]
n_obs_corruption <- nrow(panel[!is.na(ln_corruption_pc)])
n_obs_cpi <- nrow(panel[!is.na(cpi_score)])

diagnostics <- list(
  n_treated = n_treated_countries,
  n_pre = n_pre,
  n_obs = n_obs_corruption,
  n_countries = panel[, uniqueN(iso2)],
  n_cohorts = panel[g > 0, uniqueN(g)],
  outcome_sd_corruption = sd(panel$ln_corruption_pc, na.rm = TRUE),
  outcome_sd_fraud = sd(panel$ln_fraud_pc, na.rm = TRUE),
  outcome_sd_cpi = sd(panel$cpi_score, na.rm = TRUE),
  att_corruption = agg_corruption$overall.att,
  att_corruption_se = agg_corruption$overall.se,
  att_fraud = agg_fraud$overall.att,
  att_fraud_se = agg_fraud$overall.se,
  att_cpi = agg_cpi$overall.att,
  att_cpi_se = agg_cpi$overall.se
)

jsonlite::write_json(diagnostics, paste0(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("\n=== Main analysis complete ===\n")
cat("Key results:\n")
cat(sprintf("  CS-DiD ATT (corruption): %.4f (SE: %.4f)\n",
            agg_corruption$overall.att, agg_corruption$overall.se))
cat(sprintf("  CS-DiD ATT (fraud):      %.4f (SE: %.4f)\n",
            agg_fraud$overall.att, agg_fraud$overall.se))
cat(sprintf("  CS-DiD ATT (CPI):        %.4f (SE: %.4f)\n",
            agg_cpi$overall.att, agg_cpi$overall.se))
