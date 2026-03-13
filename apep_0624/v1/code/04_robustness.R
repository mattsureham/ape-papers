# 04_robustness.R — Robustness checks and mechanism tests
# apep_0624: Canada Carbon Backstop and Facility-Level Emissions

source("00_packages.R")

cat("=== Loading data ===\n")
df <- fread("../data/analysis_panel.csv")
df_bal <- fread("../data/balanced_panel.csv")

# ============================================================
# ROBUSTNESS 1: Restrict to 2017-2023 (consistent reporting rules)
# The GHGRP reporting threshold dropped from 50kt to 10kt in 2017
# This ensures compositional consistency
# ============================================================
cat("\n=== Robustness: 2017-2023 sample (consistent reporting) ===\n")

df_short <- df_bal[year >= 2017]
cat("Short panel:", nrow(df_short), "obs,", uniqueN(df_short$facility_id), "facilities\n")

m_short <- feols(log_co2e ~ treat_post | facility_id + year,
                 data = df_short, cluster = ~province)
cat("Short panel result:\n")
print(summary(m_short))

# Event study on short panel
es_short <- feols(log_co2e ~ i(year, backstop, ref = 2018) | facility_id + year,
                  data = df_short, cluster = ~province)
cat("\nShort panel event study:\n")
print(summary(es_short))

# ============================================================
# ROBUSTNESS 2: Long-lived facilities only (2009-2023, consistent reporters)
# ============================================================
cat("\n=== Robustness: Long-lived facilities (2009-2023) ===\n")

longterm_ids <- df[year <= 2009, unique(facility_id)]
longterm_ids <- intersect(longterm_ids, df[year >= 2019, unique(facility_id)])
df_long <- df[facility_id %in% longterm_ids & year >= 2009]
cat("Long-lived panel:", nrow(df_long), "obs,", length(longterm_ids), "facilities\n")

if (length(longterm_ids) >= 50) {
  m_long <- feols(log_co2e ~ treat_post | facility_id + year,
                  data = df_long, cluster = ~province)
  cat("Long-lived result:\n")
  print(summary(m_long))
} else {
  cat("Too few long-lived facilities for reliable estimation\n")
}

# ============================================================
# ROBUSTNESS 3: Exclude Ontario (Ontario had brief cap-and-trade 2017-2018)
# ============================================================
cat("\n=== Robustness: Exclude Ontario ===\n")

df_no_on <- df_bal[province != "Ontario"]
cat("Excluding Ontario:", nrow(df_no_on), "obs\n")

m_no_on <- feols(log_co2e ~ treat_post | facility_id + year,
                 data = df_no_on, cluster = ~province)
cat("Without Ontario:\n")
print(summary(m_no_on))

# ============================================================
# ROBUSTNESS 4: Exclude Alberta (Alberta had own evolving system)
# ============================================================
cat("\n=== Robustness: Exclude Alberta ===\n")

df_no_ab <- df_bal[province != "Alberta"]
cat("Excluding Alberta:", nrow(df_no_ab), "obs\n")

m_no_ab <- feols(log_co2e ~ treat_post | facility_id + year,
                 data = df_no_ab, cluster = ~province)
cat("Without Alberta:\n")
print(summary(m_no_ab))

# ============================================================
# MECHANISM 1: Gas-type decomposition
# ============================================================
cat("\n=== Mechanism: Gas decomposition ===\n")

# CO2 (fuel combustion)
m_co2 <- feols(log_co2 ~ treat_post | facility_id + year,
               data = df_bal, cluster = ~province)

# CH4 (process/fugitive)
df_bal[, log_ch4 := log(pmax(ch4_co2e, 1))]
m_ch4 <- feols(log_ch4 ~ treat_post | facility_id + year,
               data = df_bal, cluster = ~province)

# N2O
df_bal[, log_n2o := log(pmax(n2o_co2e, 1))]
m_n2o <- feols(log_n2o ~ treat_post | facility_id + year,
               data = df_bal, cluster = ~province)

cat("CO2 effect:", round(coef(m_co2)["treat_post"], 4), "\n")
cat("CH4 effect:", round(coef(m_ch4)["treat_post"], 4), "\n")
cat("N2O effect:", round(coef(m_n2o)["treat_post"], 4), "\n")

# ============================================================
# MECHANISM 2: Sector heterogeneity
# ============================================================
cat("\n=== Mechanism: Sector heterogeneity ===\n")

sectors <- unique(df_bal$sector)
sector_results <- list()

for (s in sectors) {
  df_s <- df_bal[sector == s]
  if (nrow(df_s) > 100 && uniqueN(df_s$facility_id) > 20) {
    m_s <- feols(log_co2e ~ treat_post | facility_id + year,
                 data = df_s, cluster = ~province)
    sector_results[[s]] <- list(
      coef = coef(m_s)["treat_post"],
      se = se(m_s)["treat_post"],
      n = nrow(df_s),
      n_fac = uniqueN(df_s$facility_id)
    )
    cat(sprintf("  %s: %.4f (%.4f), N=%d, fac=%d\n",
                s, coef(m_s)["treat_post"], se(m_s)["treat_post"],
                nrow(df_s), uniqueN(df_s$facility_id)))
  } else {
    cat(sprintf("  %s: Insufficient observations\n", s))
  }
}

# ============================================================
# PLACEBO: Use 2014 as fake treatment date (on pre-2017 balanced panel)
# ============================================================
cat("\n=== Placebo test: fake treatment at 2014 ===\n")

df_placebo <- df_bal[year <= 2018]
df_placebo[, fake_post := as.integer(year >= 2014)]
df_placebo[, fake_treat := backstop * fake_post]

m_placebo <- feols(log_co2e ~ fake_treat | facility_id + year,
                   data = df_placebo, cluster = ~province)
cat("Placebo (2014 treatment):\n")
print(summary(m_placebo))

# ============================================================
# SAVE ALL ROBUSTNESS RESULTS
# ============================================================
saveRDS(list(
  m_short = m_short, es_short = es_short,
  m_no_on = m_no_on, m_no_ab = m_no_ab,
  m_co2 = m_co2, m_ch4 = m_ch4, m_n2o = m_n2o,
  m_placebo = m_placebo,
  sector_results = sector_results
), "../data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
