# 04b_refined_analysis.R — Refined analysis separating coal phase-out from backstop
# apep_0624: Canada Carbon Backstop and Facility-Level Emissions

source("00_packages.R")

cat("=== Loading data ===\n")
df_bal <- fread("../data/balanced_panel.csv")
df_bal[, log_co2 := log(pmax(co2_tonnes, 1))]
df_bal[, log_ch4 := log(pmax(ch4_co2e, 1))]
df_bal[, log_n2o := log(pmax(n2o_co2e, 1))]
df_bal[, co2e_k := total_co2e / 1000]

# ============================================================
# KEY FINDING: Exclude utilities (Ontario coal phase-out confounder)
# ============================================================
cat("\n=== MAIN RESULT: Excluding utilities sector ===\n")

df_no_util <- df_bal[sector != "Utilities"]
cat("Observations:", nrow(df_no_util), ", Facilities:", uniqueN(df_no_util$facility_id), "\n")

m_no_util <- feols(log_co2e ~ treat_post | facility_id + year,
                   data = df_no_util, cluster = ~province)
cat("Without utilities:\n")
print(summary(m_no_util))
cat("Implied % change:", round((exp(coef(m_no_util)["treat_post"]) - 1) * 100, 2), "%\n")

# Short panel without utilities
df_no_util_short <- df_no_util[year >= 2017]
m_no_util_short <- feols(log_co2e ~ treat_post | facility_id + year,
                         data = df_no_util_short, cluster = ~province)
cat("\nShort panel (2017-2023) without utilities:\n")
print(summary(m_no_util_short))

# Event study without utilities
es_no_util <- feols(log_co2e ~ i(year, backstop, ref = 2018) | facility_id + year,
                    data = df_no_util[year >= 2009], cluster = ~province)
cat("\nEvent study (2009-2023) without utilities:\n")
print(summary(es_no_util))

# ============================================================
# DDD: sector (utilities vs non-utilities) x backstop x post
# ============================================================
cat("\n=== Triple difference: Sector × Backstop × Post ===\n")

df_bal[, utility := as.integer(sector == "Utilities")]

m_ddd <- feols(log_co2e ~ treat_post + treat_post:utility |
                 facility_id + sector^year,
               data = df_bal, cluster = ~province)
cat("DDD result:\n")
print(summary(m_ddd))
cat("Non-utility backstop effect:", round(coef(m_ddd)["treat_post"], 4), "\n")
cat("Additional utility effect:", round(coef(m_ddd)["treat_post:utility"], 4), "\n")

# ============================================================
# FORMAL: Ontario-specific analysis (deregulation gap)
# ============================================================
cat("\n=== Ontario deregulation analysis ===\n")

df_on <- df_bal[province %in% c("Ontario", "British Columbia", "Quebec")]
df_on[, ontario := as.integer(province == "Ontario")]

# Ontario had cap-and-trade Jan 2017 - June 2018, then deregulated,
# then backstop April 2019. Focus on 2017-2023.
df_on_short <- df_on[year >= 2017]

# Year-by-year Ontario relative to BC+QC
es_on <- feols(log_co2e ~ i(year, ontario, ref = 2018) | facility_id + year,
               data = df_on_short, cluster = ~province)
cat("Ontario event study (vs BC+QC, 2017-2023):\n")
print(summary(es_on))

# ============================================================
# ENERGY-INTENSIVE TRADE-EXPOSED (EITE) sectors specifically
# These are the sectors where carbon pricing should bite hardest
# ============================================================
cat("\n=== EITE sectors (Mining/Oil/Gas + Manufacturing) ===\n")

df_eite <- df_bal[sector %in% c("Mining & Oil/Gas", "Manufacturing")]
cat("EITE observations:", nrow(df_eite), "\n")

m_eite <- feols(log_co2e ~ treat_post | facility_id + year,
                data = df_eite, cluster = ~province)
cat("EITE result:\n")
print(summary(m_eite))

m_eite_short <- feols(log_co2e ~ treat_post | facility_id + year,
                      data = df_eite[year >= 2017], cluster = ~province)
cat("\nEITE short panel (2017-2023):\n")
print(summary(m_eite_short))

# ============================================================
# UPDATE DIAGNOSTICS
# ============================================================
diag <- fromJSON("../data/diagnostics.json")
diag$main_coef_no_util <- coef(m_no_util)["treat_post"]
diag$main_se_no_util <- se(m_no_util)["treat_post"]
diag$main_coef_short <- coef(m_no_util_short)["treat_post"]
diag$main_se_short <- se(m_no_util_short)["treat_post"]
diag$utilities_effect <- coef(m_ddd)["treat_post:utility"]
write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

# Save refined results
saveRDS(list(
  m_no_util = m_no_util,
  m_no_util_short = m_no_util_short,
  es_no_util = es_no_util,
  m_ddd = m_ddd,
  es_on = es_on,
  m_eite = m_eite,
  m_eite_short = m_eite_short
), "../data/refined_results.rds")

cat("\n=== Refined analysis complete ===\n")
