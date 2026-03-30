# ==============================================================================
# 03_main_analysis.R — Main DiD analysis: National Sword → waste employment
# ==============================================================================
source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")
exposure <- readRDS("../data/exposure.rds")

# ==============================================================================
# A. WASTE MANAGEMENT SECTOR (NAICS 562)
# ==============================================================================
cat("=== NAICS 562 (Waste Management) Analysis ===\n\n")

waste <- panel %>%
  filter(industry == "562") %>%
  mutate(
    county_id = as.integer(factor(fips)),
    # Event time relative to 2018Q1 (quarter 21)
    event_time = time_q - 21L
  )

cat(sprintf("Waste panel: %s county-quarters, %d counties\n",
            format(nrow(waste), big.mark = ","), n_distinct(waste$fips)))

# --- A1: Basic DiD (continuous exposure) ---
cat("\n--- A1: Continuous exposure DiD ---\n")
m1_emp <- feols(log_emp ~ waste_share:post | fips + time_q,
                data = waste, cluster = ~state_fips)
m1_earn <- feols(log_earn ~ waste_share:post | fips + time_q,
                 data = waste, cluster = ~state_fips)

cat("Employment (log):\n")
print(summary(m1_emp))
cat("\nEarnings per worker (log):\n")
print(summary(m1_earn))

# --- A2: Binary exposure DiD ---
cat("\n--- A2: Binary exposure (above-median) DiD ---\n")
m2_emp <- feols(log_emp ~ high_exposure:post | fips + time_q,
                data = waste, cluster = ~state_fips)
m2_earn <- feols(log_earn ~ high_exposure:post | fips + time_q,
                 data = waste, cluster = ~state_fips)

cat("Employment:\n")
print(summary(m2_emp))

# --- A3: Event study (key pre-trends check) ---
cat("\n--- A3: Event study ---\n")

# Create event-time bins (collapse distant quarters)
waste <- waste %>%
  mutate(
    et_bin = case_when(
      event_time <= -8 ~ -8L,
      event_time >= 12 ~ 12L,
      TRUE ~ event_time
    ),
    et_bin = as.integer(et_bin)
  )

# Reference period: et_bin = -1
m3_es <- feols(log_emp ~ i(et_bin, high_exposure, ref = -1) | fips + time_q,
               data = waste, cluster = ~state_fips)

cat("Event study coefficients:\n")
es_coefs <- as.data.frame(coeftable(m3_es))
print(es_coefs)

# --- A4: DiD with state × quarter FE (most stringent) ---
cat("\n--- A4: State × quarter FE ---\n")
m4_emp <- feols(log_emp ~ high_exposure:post | fips + state_fips^time_q,
                data = waste, cluster = ~state_fips)
m4_earn <- feols(log_earn ~ high_exposure:post | fips + state_fips^time_q,
                 data = waste, cluster = ~state_fips)

cat("Employment with state×quarter FE:\n")
print(summary(m4_emp))

# ==============================================================================
# B. TRIPLE-DIFFERENCE: Waste (562) vs Professional Services (541)
# ==============================================================================
cat("\n=== Triple-Difference: NAICS 562 vs 541 ===\n\n")

ddd_data <- panel %>%
  filter(industry %in% c("562", "541")) %>%
  mutate(
    waste_ind = as.integer(industry == "562"),
    county_id = as.integer(factor(fips))
  )

m5_ddd <- feols(log_emp ~ high_exposure:post:waste_ind +
                  high_exposure:post + high_exposure:waste_ind + post:waste_ind |
                  fips^industry + time_q^industry,
                data = ddd_data, cluster = ~state_fips)

cat("Triple-diff (562 vs 541):\n")
print(summary(m5_ddd))

# ==============================================================================
# C. FIRM DYNAMICS
# ==============================================================================
cat("\n=== Firm Dynamics ===\n\n")

m6_creation <- feols(log(FrmJbGn + 1) ~ high_exposure:post | fips + time_q,
                     data = waste, cluster = ~state_fips)
m6_destruction <- feols(log(FrmJbLs + 1) ~ high_exposure:post | fips + time_q,
                        data = waste, cluster = ~state_fips)

cat("Firm job gains:\n")
print(summary(m6_creation))
cat("\nFirm job losses:\n")
print(summary(m6_destruction))

# ==============================================================================
# D. SAVE RESULTS
# ==============================================================================
results <- list(
  m1_emp = m1_emp, m1_earn = m1_earn,
  m2_emp = m2_emp, m2_earn = m2_earn,
  m3_es = m3_es,
  m4_emp = m4_emp, m4_earn = m4_earn,
  m5_ddd = m5_ddd,
  m6_creation = m6_creation, m6_destruction = m6_destruction
)
saveRDS(results, "../data/main_results.rds")

# ==============================================================================
# E. DIAGNOSTICS for validator
# ==============================================================================
diagnostics <- list(
  n_treated = sum(exposure$high_exposure),
  n_pre = length(unique(waste$time_q[waste$post == 0])),
  n_obs = nrow(waste)
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))

cat("\nMain analysis complete.\n")
