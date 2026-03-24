# 03_main_analysis.R — apep_0873: The Pill Pipeline
# Main regressions: disability prevalence → opioid mortality
# Key design: "difference-in-drugs" placebo (rx opioids vs synthetic/cocaine)
source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "panel_clean.csv"))
cat("Panel loaded:", nrow(panel), "obs,", length(unique(panel$state_fips)), "states,",
    length(unique(panel$year)), "years\n")

# ═══════════════════════════════════════════════════════════════════
# TABLE 1: Summary Statistics
# ═══════════════════════════════════════════════════════════════════
cat("\n=== Summary Statistics ===\n")

sum_vars <- c("opioid_rate", "rx_opioid_rate", "synthetic_rate", "cocaine_rate",
              "heroin_rate", "stimulant_rate", "disability_rate", "unemp_rate",
              "median_income", "population")

sum_labels <- c("All opioid deaths per 100K", "Rx opioid deaths per 100K",
                "Synthetic opioid deaths per 100K", "Cocaine deaths per 100K",
                "Heroin deaths per 100K", "Stimulant deaths per 100K",
                "Disability prevalence rate", "Unemployment rate",
                "Median household income (\\$)", "Population")

sum_stats <- data.frame(
  Variable = sum_labels,
  Mean = sapply(sum_vars, function(v) round(mean(panel[[v]], na.rm = TRUE), 2)),
  SD = sapply(sum_vars, function(v) round(sd(panel[[v]], na.rm = TRUE), 2)),
  Min = sapply(sum_vars, function(v) round(min(panel[[v]], na.rm = TRUE), 2)),
  Max = sapply(sum_vars, function(v) round(max(panel[[v]], na.rm = TRUE), 2)),
  stringsAsFactors = FALSE, row.names = NULL
)

cat("  Summary:\n")
print(sum_stats)

# ═══════════════════════════════════════════════════════════════════
# TABLE 2: Main Results — Disability → Opioid Deaths
# ═══════════════════════════════════════════════════════════════════
cat("\n=== Main Results ===\n")

# (1) Pooled OLS: opioid death rate on disability rate
m1 <- feols(opioid_rate ~ disability_rate,
            data = panel, vcov = ~state_fips)

# (2) + Controls
m2 <- feols(opioid_rate ~ disability_rate + unemp_rate + log(median_income) +
            log(population) + pct_white + median_age,
            data = panel, vcov = ~state_fips)

# (3) Year FE only
m3 <- feols(opioid_rate ~ disability_rate + unemp_rate + log(median_income) |
            year,
            data = panel, vcov = ~state_fips)

# (4) State FE + Year FE (within-state variation)
m4 <- feols(opioid_rate ~ disability_rate + unemp_rate |
            state_fips + year,
            data = panel, vcov = ~state_fips)

# (5) State FE + Year FE + time-varying controls
m5 <- feols(opioid_rate ~ disability_rate + unemp_rate + log(median_income) +
            pct_black |
            state_fips + year,
            data = panel, vcov = ~state_fips)

cat("  (1) Pooled: β =", round(coef(m1)["disability_rate"], 1), "\n")
cat("  (2) Controls: β =", round(coef(m2)["disability_rate"], 1), "\n")
cat("  (3) Year FE: β =", round(coef(m3)["disability_rate"], 1), "\n")
cat("  (4) State+Year FE: β =", round(coef(m4)["disability_rate"], 1), "\n")
cat("  (5) Full controls: β =", round(coef(m5)["disability_rate"], 1), "\n")

# ═══════════════════════════════════════════════════════════════════
# TABLE 3: Difference-in-Drugs Placebo
# ═══════════════════════════════════════════════════════════════════
cat("\n=== Difference-in-Drugs Placebo ===\n")

# Prescription opioids (T40.2) — should respond to disability (insurance channel)
m_rx <- feols(rx_opioid_rate ~ disability_rate + unemp_rate |
              state_fips + year,
              data = panel, vcov = ~state_fips)

# All opioids
m_all_op <- feols(opioid_rate ~ disability_rate + unemp_rate |
                  state_fips + year,
                  data = panel, vcov = ~state_fips)

# Synthetic opioids/fentanyl (T40.4) — illicit, NOT insurance-mediated
m_synth <- feols(synthetic_rate ~ disability_rate + unemp_rate |
                 state_fips + year,
                 data = panel, vcov = ~state_fips)

# Cocaine (T40.5) — illicit, NOT insurance-mediated
m_coke <- feols(cocaine_rate ~ disability_rate + unemp_rate |
                state_fips + year,
                data = panel, vcov = ~state_fips)

# Heroin (T40.1) — illicit, partial insurance mediation (gateway)
m_heroin <- feols(heroin_rate ~ disability_rate + unemp_rate |
                  state_fips + year,
                  data = panel, vcov = ~state_fips)

# Psychostimulants (T43.6) — illicit/non-opioid
m_stim <- feols(stimulant_rate ~ disability_rate + unemp_rate |
                state_fips + year,
                data = panel, vcov = ~state_fips)

cat("  Rx opioids (T40.2): β =", round(coef(m_rx)["disability_rate"], 2), "\n")
cat("  All opioids: β =", round(coef(m_all_op)["disability_rate"], 2), "\n")
cat("  Synthetic (T40.4): β =", round(coef(m_synth)["disability_rate"], 2), "\n")
cat("  Cocaine (T40.5): β =", round(coef(m_coke)["disability_rate"], 2), "\n")
cat("  Heroin (T40.1): β =", round(coef(m_heroin)["disability_rate"], 2), "\n")
cat("  Stimulants (T43.6): β =", round(coef(m_stim)["disability_rate"], 2), "\n")

# ═══════════════════════════════════════════════════════════════════
# TABLE 4: Robustness (see 04_robustness.R for full checks)
# ═══════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════
# Save all results
# ═══════════════════════════════════════════════════════════════════
save(m1, m2, m3, m4, m5,
     m_rx, m_all_op, m_synth, m_coke, m_heroin, m_stim,
     sum_stats, panel,
     file = file.path(data_dir, "main_results.RData"))
cat("\n  Saved main_results.RData\n")

# ═══════════════════════════════════════════════════════════════════
# Diagnostics
# ═══════════════════════════════════════════════════════════════════
cat("\n=== Writing diagnostics ===\n")

diagnostics <- list(
  n_obs = nrow(panel),
  n_treated = length(unique(panel$state_fips)),
  n_pre = length(unique(panel$year[panel$year <= 2018])),
  n_states = length(unique(panel$state_fips)),
  n_years = length(unique(panel$year)),
  mean_opioid_rate = round(mean(panel$opioid_rate, na.rm = TRUE), 1),
  sd_opioid_rate = round(sd(panel$opioid_rate, na.rm = TRUE), 1),
  mean_rx_rate = round(mean(panel$rx_opioid_rate, na.rm = TRUE), 1),
  mean_disability = round(mean(panel$disability_rate, na.rm = TRUE), 4),
  sd_disability = round(sd(panel$disability_rate, na.rm = TRUE), 4),
  beta_preferred = round(coef(m4)["disability_rate"], 2),
  beta_rx = round(coef(m_rx)["disability_rate"], 2),
  beta_placebo_synth = round(coef(m_synth)["disability_rate"], 2),
  beta_placebo_cocaine = round(coef(m_coke)["disability_rate"], 2)
)

write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE, pretty = TRUE)
cat("  Saved diagnostics.json\n")

cat("\n=== Main analysis complete ===\n")
