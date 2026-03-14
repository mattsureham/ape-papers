# 03_main_analysis.R — Main DiD regressions
# apep_0685: Canada carbon pricing backstop

source("00_packages.R")

cat("=== Main Analysis ===\n")

analysis <- readRDS("../data/panel_analysis.rds")

# =========================================================================
# 1. TWFE DiD — baseline
# =========================================================================
cat("\n--- Model 1: TWFE DiD (baseline) ---\n")

m1 <- feols(log_total_co2e ~ treat_post | facility_id + year,
            data = analysis,
            cluster = ~province)
cat("Model 1 (TWFE, no controls):\n")
summary(m1)

# With WTI control
cat("\n--- Model 2: TWFE DiD + WTI control ---\n")
m2 <- feols(log_total_co2e ~ treat_post + wti_energy | facility_id + year,
            data = analysis,
            cluster = ~province)
summary(m2)

# =========================================================================
# 2. Event study — pre-trends test
# =========================================================================
cat("\n--- Event Study ---\n")

# Create relative time to treatment (2019)
analysis[, rel_year := year - 2019L]

# Bin endpoints at -7 and +4
analysis[, rel_year_binned := pmax(pmin(rel_year, 4L), -7L)]

# Drop year -1 as reference
es <- feols(log_total_co2e ~ i(rel_year_binned, treated, ref = -1) |
              facility_id + year,
            data = analysis,
            cluster = ~province)
cat("Event study coefficients:\n")
summary(es)

# Save event study for table
es_coefs <- as.data.frame(coeftable(es))
es_coefs$term <- rownames(es_coefs)
saveRDS(es_coefs, "../data/event_study_coefs.rds")

# =========================================================================
# 3. Callaway-Sant'Anna heterogeneity-robust DiD
# =========================================================================
cat("\n--- Callaway-Sant'Anna ---\n")

# Need a numeric facility ID for did::att_gt
analysis[, fac_num := as.integer(factor(facility_id))]

cs_out <- att_gt(
  yname = "log_total_co2e",
  tname = "year",
  idname = "fac_num",
  gname = "first_treat",
  data = as.data.frame(analysis),
  control_group = "nevertreated",
  base_period = "universal"
)
cat("CS ATT(g,t) summary:\n")
summary(cs_out)

# Aggregate to simple ATT
cs_simple <- aggte(cs_out, type = "simple")
cat("\nCS Simple ATT:\n")
summary(cs_simple)

# Dynamic aggregation (event study)
cs_dynamic <- aggte(cs_out, type = "dynamic")
cat("\nCS Dynamic ATT:\n")
summary(cs_dynamic)

# Save CS results
saveRDS(cs_out, "../data/cs_att_gt.rds")
saveRDS(cs_simple, "../data/cs_simple.rds")
saveRDS(cs_dynamic, "../data/cs_dynamic.rds")

# =========================================================================
# 4. Gas decomposition — mechanism test
# =========================================================================
cat("\n--- Gas Decomposition ---\n")

m_co2 <- feols(log_co2 ~ treat_post | facility_id + year,
               data = analysis, cluster = ~province)
m_ch4 <- feols(log_ch4_co2e ~ treat_post | facility_id + year,
               data = analysis, cluster = ~province)
m_n2o <- feols(log_n2o_co2e ~ treat_post | facility_id + year,
               data = analysis, cluster = ~province)

cat("CO2:\n"); print(coeftable(m_co2))
cat("\nCH4 (CO2e):\n"); print(coeftable(m_ch4))
cat("\nN2O (CO2e):\n"); print(coeftable(m_n2o))

# =========================================================================
# 5. Sector heterogeneity
# =========================================================================
cat("\n--- Sector Heterogeneity ---\n")

# Energy-intensive vs non-energy-intensive
m_energy <- feols(log_total_co2e ~ treat_post | facility_id + year,
                  data = analysis[energy_intensive == 1],
                  cluster = ~province)
m_nonenergy <- feols(log_total_co2e ~ treat_post | facility_id + year,
                     data = analysis[energy_intensive == 0],
                     cluster = ~province)

cat("Energy-intensive sectors:\n"); print(coeftable(m_energy))
cat("\nNon-energy-intensive sectors:\n"); print(coeftable(m_nonenergy))

# =========================================================================
# 6. Save all models
# =========================================================================
models <- list(
  twfe_base = m1,
  twfe_wti = m2,
  event_study = es,
  gas_co2 = m_co2,
  gas_ch4 = m_ch4,
  gas_n2o = m_n2o,
  sector_energy = m_energy,
  sector_nonenergy = m_nonenergy
)
saveRDS(models, "../data/main_models.rds")

# =========================================================================
# 7. Write diagnostics.json
# =========================================================================
diag <- list(
  n_treated = uniqueN(analysis[treated == 1]$facility_id),
  n_pre = length(unique(analysis[year < 2019]$year)),
  n_obs = nrow(analysis),
  n_facilities = uniqueN(analysis$facility_id),
  n_control = uniqueN(analysis[treated == 0]$facility_id),
  year_range = paste(range(analysis$year), collapse = "-"),
  twfe_coef = coef(m1)[["treat_post"]],
  twfe_se = coeftable(m1)["treat_post", "Std. Error"],
  cs_att = cs_simple$overall.att,
  cs_se = cs_simple$overall.se
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

cat("\n=== Main analysis complete ===\n")
cat(sprintf("TWFE ATT: %.4f (SE: %.4f)\n", diag$twfe_coef, diag$twfe_se))
cat(sprintf("CS ATT:   %.4f (SE: %.4f)\n", diag$cs_att, diag$cs_se))
