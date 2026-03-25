## 03_main_analysis.R — Main regressions
## APEP-0923: The End of Banking Secrecy

source("00_packages.R")

panel <- fread("../data/analysis_panel.csv")
panel[, date := as.Date(date)]

cat("Analysis panel:", nrow(panel), "obs,", uniqueN(panel$cp_country), "countries\n")
cat("Treatment: Wave 1 (2017):", uniqueN(panel[wave == 1]$cp_country),
    ", Wave 2 (2018):", uniqueN(panel[wave == 2]$cp_country),
    ", Wave 3 (2019):", uniqueN(panel[wave == 3]$cp_country),
    ", Wave 4 (2020):", uniqueN(panel[wave == 4]$cp_country),
    ", Never:", uniqueN(panel[wave == 0]$cp_country), "\n")

# ---------------------------------------------------------------
# 1. TWFE DiD — Baseline
# ---------------------------------------------------------------
cat("\n=== TWFE DiD Results ===\n")

# Main specification: log deposits, country + quarter FE, clustered by country
m1 <- feols(log_deposits ~ aeoi_active | country_id + time_id,
            data = panel, cluster = ~cp_country)
cat("Model 1 (TWFE, log deposits):\n")
print(summary(m1))

# Levels specification
m2 <- feols(deposits_usd_mn ~ aeoi_active | country_id + time_id,
            data = panel, cluster = ~cp_country)
cat("\nModel 2 (TWFE, levels):\n")
print(summary(m2))

# Deposit share specification
m3 <- feols(deposit_share ~ aeoi_active | country_id + time_id,
            data = panel, cluster = ~cp_country)
cat("\nModel 3 (TWFE, deposit share):\n")
print(summary(m3))

# ---------------------------------------------------------------
# 2. Event Study — Pre-trend validation
# ---------------------------------------------------------------
cat("\n=== Event Study ===\n")

# Create event study dummies (relative to AEOI activation)
# Bin at -8 and +8 quarters
panel[, rel_q_binned := pmin(pmax(rel_quarter, -8L), 8L)]

# For never-treated, assign to reference category
panel[is.na(rel_q_binned), rel_q_binned := -1L]  # Reference: t=-1

# Event study regression
# Reference period: rel_quarter = -1 (quarter before activation)
panel[, rel_q_factor := relevel(factor(rel_q_binned), ref = "-1")]

m_event <- feols(log_deposits ~ rel_q_factor | country_id + time_id,
                 data = panel[wave > 0],  # Only treated countries
                 cluster = ~cp_country)

cat("Event study coefficients:\n")
es_coefs <- coeftable(m_event)
print(es_coefs)

# Extract event study results for table
es_results <- data.table(
  rel_quarter = as.integer(gsub("rel_q_factor", "", rownames(es_coefs))),
  estimate = es_coefs[, 1],
  se = es_coefs[, 2],
  pval = es_coefs[, 4]
)
es_results <- es_results[order(rel_quarter)]
es_results[, ci_lo := estimate - 1.96 * se]
es_results[, ci_hi := estimate + 1.96 * se]

cat("\nPre-trend test (H0: all pre-treatment coefficients = 0):\n")
pre_coefs <- es_results[rel_quarter < -1]
cat("  Pre-period estimates:\n")
print(pre_coefs[, .(rel_quarter, estimate = round(estimate, 4),
                     se = round(se, 4), pval = round(pval, 3))])
cat("  Any pre-trend sig at 5%?", any(pre_coefs$pval < 0.05), "\n")

fwrite(es_results, "../data/event_study_results.csv")

# ---------------------------------------------------------------
# 3. Callaway-Sant'Anna (2021) — Heterogeneous treatment timing
# ---------------------------------------------------------------
cat("\n=== Callaway-Sant'Anna DiD ===\n")

# Prepare data for did::att_gt
# Need: yname (outcome), gname (group/cohort), tname (time), idname (unit)
cs_data <- copy(panel)
cs_data[, g := ifelse(wave > 0, cohort_year * 4 + 1, 0)]  # Cohort in quarter units
cs_data <- cs_data[!is.na(log_deposits)]

# Convert cohort to first treatment quarter (year of activation, Q1)
# Wave 1: 2017Q1, Wave 2: 2018Q1, Wave 3: 2019Q1, Wave 4: 2020Q1
cs_data[wave == 1, g_quarter := (2017 - 2010) * 4 + 1]  # = 29
cs_data[wave == 2, g_quarter := (2018 - 2010) * 4 + 1]  # = 33
cs_data[wave == 3, g_quarter := (2019 - 2010) * 4 + 1]  # = 37
cs_data[wave == 4, g_quarter := (2020 - 2010) * 4 + 1]  # = 41
cs_data[wave == 0, g_quarter := 0]  # Never treated

cs_result <- tryCatch({
  att_gt(
    yname = "log_deposits",
    gname = "g_quarter",
    tname = "time_id",
    idname = "country_id",
    data = as.data.frame(cs_data),
    control_group = "nevertreated",
    est_method = "reg",
    bstrap = TRUE,
    cband = TRUE,
    biters = 1000
  )
}, error = function(e) {
  cat("CS-DiD error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(cs_result)) {
  cs_agg <- aggte(cs_result, type = "simple")
  cat("\nCS-DiD ATT (simple aggregate):\n")
  cat("  ATT:", round(cs_agg$overall.att, 4), "\n")
  cat("  SE:", round(cs_agg$overall.se, 4), "\n")
  cat("  95% CI: [", round(cs_agg$overall.att - 1.96 * cs_agg$overall.se, 4),
      ",", round(cs_agg$overall.att + 1.96 * cs_agg$overall.se, 4), "]\n")

  # Dynamic aggregation (event study)
  cs_dynamic <- aggte(cs_result, type = "dynamic")
  cat("\nCS-DiD dynamic effects:\n")
  cs_dyn_dt <- data.table(
    rel_period = cs_dynamic$egt,
    att = cs_dynamic$att.egt,
    se = cs_dynamic$se.egt
  )
  print(cs_dyn_dt[order(rel_period)])

  # Save CS results
  saveRDS(cs_result, "../data/cs_did_result.rds")
  fwrite(cs_dyn_dt, "../data/cs_dynamic_results.csv")
} else {
  cat("CS-DiD failed — using TWFE results as primary.\n")
}

# ---------------------------------------------------------------
# 4. Heterogeneity
# ---------------------------------------------------------------
cat("\n=== Heterogeneity Analysis ===\n")

# a) Tax haven vs non-haven counterparties
m_haven <- feols(log_deposits ~ aeoi_active * tax_haven | country_id + time_id,
                 data = panel, cluster = ~cp_country)
cat("Tax haven interaction:\n")
print(coeftable(m_haven))

# b) EU vs non-EU
m_eu <- feols(log_deposits ~ aeoi_active * eu_member | country_id + time_id,
              data = panel, cluster = ~cp_country)
cat("\nEU membership interaction:\n")
print(coeftable(m_eu))

# c) Large vs small depositors (above/below median pre-deposits)
med_deposits <- median(panel[wave > 0, pre_deposits], na.rm = TRUE)
panel[, large_depositor := as.integer(pre_deposits > med_deposits)]

m_size <- feols(log_deposits ~ aeoi_active * large_depositor | country_id + time_id,
                data = panel[wave > 0], cluster = ~cp_country)
cat("\nLarge depositor interaction (treated countries only):\n")
print(coeftable(m_size))

# ---------------------------------------------------------------
# 5. Write diagnostics.json
# ---------------------------------------------------------------
n_treated <- uniqueN(panel[wave > 0]$cp_country)
n_pre <- uniqueN(panel[wave == 1 & aeoi_active == 0]$time_id)
n_obs <- nrow(panel)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_countries = uniqueN(panel$cp_country),
  n_never_treated = uniqueN(panel[wave == 0]$cp_country),
  twfe_coef = round(coef(m1)["aeoi_active"], 4),
  twfe_se = round(se(m1)["aeoi_active"], 4),
  cs_att = if (!is.null(cs_result)) round(cs_agg$overall.att, 4) else NA,
  cs_se = if (!is.null(cs_result)) round(cs_agg$overall.se, 4) else NA
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics written:\n")
print(diagnostics)

# Save key model objects for table generation
saveRDS(list(m1 = m1, m2 = m2, m3 = m3,
             m_haven = m_haven, m_eu = m_eu, m_size = m_size,
             m_event = m_event,
             cs_result = cs_result,
             panel = panel),
        "../data/model_objects.rds")
cat("\nModel objects saved.\n")
