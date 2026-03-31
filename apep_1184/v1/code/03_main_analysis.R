# 03_main_analysis.R — Main estimation for apep_1184
# EU Airport Slot Waivers and Competition

source("00_packages.R")

cat("=== Main Analysis ===\n")

# ─────────────────────────────────────────────────────────────────────
# 1. Load panels
# ─────────────────────────────────────────────────────────────────────
panel <- readRDS("../data/panel_annual.rds")
panel_q <- readRDS("../data/panel_quarterly.rds")

# ─────────────────────────────────────────────────────────────────────
# 2. Main specification: Continuous DiD (annual)
#    log(pax) = airport FE + year FE + β(Level3 × waiver_intensity) + ε
#    waiver_intensity = (80 - threshold) / 80
#    β > 0 means waiver INCREASES passengers (unexpected)
#    β < 0 means waiver DECREASES passengers (incumbency shield)
# ─────────────────────────────────────────────────────────────────────

# Spec 1: Total passengers
m1 <- feols(log_pax ~ treat_continuous | airport + year,
  data = panel, cluster = ~airport)

# Spec 2: Scheduled passengers only (directly subject to slot rules)
m2 <- feols(log_pax_sched ~ treat_continuous | airport + year,
  data = panel, cluster = ~airport)

# Spec 3: Non-scheduled passengers (placebo — not subject to slots)
m3 <- feols(log_pax_nonsched ~ treat_continuous | airport + year,
  data = panel, cluster = ~airport)

cat("=== Main Results ===\n")
etable(m1, m2, m3,
  headers = c("Total", "Scheduled", "Non-Scheduled"),
  title = "Effect of Slot Waiver on Airport Passengers")

# ─────────────────────────────────────────────────────────────────────
# 3. Binary DiD: Post-COVID × Level3
#    Simpler specification for robustness
# ─────────────────────────────────────────────────────────────────────
panel[, post := as.integer(year >= 2020)]
panel[, treat_binary := level3 * post]

m4 <- feols(log_pax ~ treat_binary | airport + year,
  data = panel, cluster = ~airport)
m5 <- feols(log_pax_sched ~ treat_binary | airport + year,
  data = panel, cluster = ~airport)

cat("\n=== Binary DiD (Post-COVID × Level3) ===\n")
etable(m4, m5, headers = c("Total", "Scheduled"))

# ─────────────────────────────────────────────────────────────────────
# 4. Event Study (annual)
#    Omit 2019 as reference year
# ─────────────────────────────────────────────────────────────────────
panel[, year_f := factor(year)]
panel[, year_f := relevel(year_f, ref = "2019")]

m_es <- feols(log_pax ~ i(year_f, level3, ref = "2019") | airport + year,
  data = panel, cluster = ~airport)

cat("\n=== Event Study Coefficients ===\n")
print(coeftable(m_es))

# ─────────────────────────────────────────────────────────────────────
# 5. Quarterly Analysis (more precise timing)
# ─────────────────────────────────────────────────────────────────────
panel_q[, yq_f := factor(yq)]

# Continuous treatment quarterly
m_q1 <- feols(log_pax ~ treat_continuous | airport + yq_f,
  data = panel_q, cluster = ~airport)
cat("\n=== Quarterly Continuous DiD ===\n")
etable(m_q1)

# Quarterly event study (relative to 2019Q4)
panel_q[, yq_f := relevel(yq_f, ref = "2019.75")]
m_q_es <- feols(log_pax ~ i(yq_f, level3, ref = "2019.75") | airport + yq_f,
  data = panel_q, cluster = ~airport)
cat("\n=== Quarterly Event Study Coefficients ===\n")
es_coefs <- coeftable(m_q_es)
print(es_coefs)

# ─────────────────────────────────────────────────────────────────────
# 6. Country-pair analysis (within-country Level 3 vs Level 1/2)
#    Add country × year fixed effects to absorb country-specific shocks
# ─────────────────────────────────────────────────────────────────────
m6 <- feols(log_pax ~ treat_continuous | airport + country^year,
  data = panel, cluster = ~airport)

cat("\n=== Within-Country Specification ===\n")
etable(m6, headers = "Country×Year FE")

# ─────────────────────────────────────────────────────────────────────
# 7. Passengers per flight (intensive margin)
# ─────────────────────────────────────────────────────────────────────
# Load flight data if available
if (file.exists("../data/avia_flights_annual.rds")) {
  dt_flights <- as.data.table(readRDS("../data/avia_flights_annual.rds"))
  dt_flights[, year := as.integer(time)]
  flights <- dt_flights[!is.na(values) & year >= 2016 & year <= 2024,
    .(airport = rep_airp, year, flights = values)]

  panel_f <- merge(panel, flights, by = c("airport", "year"), all.x = TRUE)
  panel_f[, log_flights := log(flights + 1)]
  panel_f[, pax_per_flight := pax_total / (flights + 1)]
  panel_f[, log_ppf := log(pax_per_flight + 1)]

  m7 <- feols(log_flights ~ treat_continuous | airport + year,
    data = panel_f[!is.na(flights)], cluster = ~airport)
  m8 <- feols(log_ppf ~ treat_continuous | airport + year,
    data = panel_f[!is.na(flights)], cluster = ~airport)

  cat("\n=== Intensive Margin: Flights and Passengers per Flight ===\n")
  etable(m7, m8, headers = c("Log Flights", "Log Pax/Flight"))
}

# ─────────────────────────────────────────────────────────────────────
# 8. Save results and diagnostics
# ─────────────────────────────────────────────────────────────────────

# Diagnostics for validate_v1.py
n_treated <- length(unique(panel[level3 == 1]$airport))
# Use quarterly pre-periods for diagnostics (16 quarters, 2016Q1-2019Q4)
n_pre <- length(unique(panel_q[year < 2020]$yq))
n_obs <- nrow(panel)

jsonlite::write_json(list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs
), "../data/diagnostics.json", auto_unbox = TRUE)

cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
    n_treated, n_pre, n_obs))

# Save model objects
saveRDS(list(
  m_main_total = m1,
  m_main_sched = m2,
  m_main_nonsched = m3,
  m_binary_total = m4,
  m_binary_sched = m5,
  m_event_study = m_es,
  m_quarterly = m_q1,
  m_quarterly_es = m_q_es,
  m_within_country = m6,
  m_flights = if (exists("m7")) m7 else NULL,
  m_pax_per_flight = if (exists("m8")) m8 else NULL
), "../data/models.rds")

cat("\n=== Main analysis complete ===\n")
