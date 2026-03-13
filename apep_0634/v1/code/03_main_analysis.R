# =============================================================================
# 03_main_analysis.R — Main DiD analysis
# APEP-0634: Disaster Salience and the Costs of Safety Regulation
# =============================================================================

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")

# ─── Main specification: Continuous-treatment DiD ────────────────────────────
# Y_{c,t} = α_c + γ_t + β(MiningShare_c × Post2006_t) + ε_{c,t}
# Clustered at state level (24 clusters)

# Table 2: Main results — Total employment and earnings
cat("=== Main DiD Results ===\n")

# (1) Log total employment
m1_emp <- feols(log_emp ~ treat_post | county_id + time_q,
                data = panel, cluster = ~state_fips)

# (2) Log earnings
m1_earn <- feols(log_earn ~ treat_post | county_id + time_q,
                 data = panel, cluster = ~state_fips)

# (3) Log mining employment
m1_mining <- feols(log_emp_mining ~ treat_post | county_id + time_q,
                   data = panel |> filter(mining_share > 0),
                   cluster = ~state_fips)

# (4) Log non-mining employment
m1_nonmining <- feols(log_emp_nonmining ~ treat_post | county_id + time_q,
                      data = panel, cluster = ~state_fips)

# (5) Hires
m1_hire <- feols(log(pmax(hire_total, 1)) ~ treat_post | county_id + time_q,
                 data = panel, cluster = ~state_fips)

# (6) Separations
m1_sep <- feols(log(pmax(sep_total, 1)) ~ treat_post | county_id + time_q,
                data = panel, cluster = ~state_fips)

etable(m1_emp, m1_earn, m1_mining, m1_nonmining, m1_hire, m1_sep,
       headers = c("Log Emp", "Log Earn", "Log Mining Emp",
                    "Log Non-Mining Emp", "Log Hires", "Log Sep"))

# ─── Event study (annual) ───────────────────────────────────────────────────
cat("\n=== Event Study ===\n")

# Create annual event-time dummies interacted with mining share
# Reference year: 2005 (year before MINER Act)
panel <- panel |>
  mutate(event_year_f = factor(event_year))

# Event study for log employment
es_emp <- feols(log_emp ~ i(event_year, mining_share, ref = -1) |
                  county_id + time_q,
                data = panel |> filter(event_year >= -5 & event_year <= 9),
                cluster = ~state_fips)

cat("Event study coefficients (employment):\n")
print(summary(es_emp))

# Event study for log mining employment
es_mining <- feols(log_emp_mining ~ i(event_year, mining_share, ref = -1) |
                     county_id + time_q,
                   data = panel |> filter(event_year >= -5 & event_year <= 9,
                                          mining_share > 0),
                   cluster = ~state_fips)

# Event study for earnings
es_earn <- feols(log_earn ~ i(event_year, mining_share, ref = -1) |
                   county_id + time_q,
                 data = panel |> filter(event_year >= -5 & event_year <= 9),
                 cluster = ~state_fips)

# ─── Two-event specification ────────────────────────────────────────────────
cat("\n=== Two-Event Specification (MINER Act + UBB) ===\n")

# Post-MINER × mining_share + Post-UBB × mining_share
m2_emp <- feols(log_emp ~ treat_post + treat_post_ubb | county_id + time_q,
                data = panel, cluster = ~state_fips)

m2_earn <- feols(log_earn ~ treat_post + treat_post_ubb | county_id + time_q,
                 data = panel, cluster = ~state_fips)

m2_mining <- feols(log_emp_mining ~ treat_post + treat_post_ubb | county_id + time_q,
                   data = panel |> filter(mining_share > 0),
                   cluster = ~state_fips)

etable(m2_emp, m2_earn, m2_mining,
       headers = c("Log Emp", "Log Earn", "Log Mining Emp"))

# ─── Save model objects ─────────────────────────────────────────────────────
saveRDS(list(
  m1_emp = m1_emp, m1_earn = m1_earn, m1_mining = m1_mining,
  m1_nonmining = m1_nonmining, m1_hire = m1_hire, m1_sep = m1_sep,
  m2_emp = m2_emp, m2_earn = m2_earn, m2_mining = m2_mining,
  es_emp = es_emp, es_mining = es_mining, es_earn = es_earn
), "../data/main_models.rds")

# ─── Write diagnostics.json ─────────────────────────────────────────────────
n_treated <- n_distinct(panel$county_id[panel$mining_share > 0.05])
n_pre <- length(unique(panel$year[panel$year < 2006]))
n_obs <- nrow(panel)

write_json(list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs
), "../data/diagnostics.json", auto_unbox = TRUE)

cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated, n_pre, n_obs))
cat("Saved: data/main_models.rds, data/diagnostics.json\n")
