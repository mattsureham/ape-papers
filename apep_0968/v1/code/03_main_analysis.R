# ==============================================================================
# 03_main_analysis.R — Primary regressions
# Paper: The Recertification Ripple (apep_0968)
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

cat("=== MAIN ANALYSIS ===\n\n")

# =============================================================================
# Specification 1: Baseline — Recertification intensity × IES on enrollment volatility
# Y = abs_pct_change (month-over-month absolute percent change in Medicaid enrollment)
# =============================================================================

cat("--- Specification 1: Baseline DiD (abs percent change) ---\n")

# Restrict to period with SNAP policy data (2018-2020)
# and non-missing enrollment changes
df_main <- panel %>%
  filter(!is.na(recert_intensity) & !is.na(abs_pct_change)) %>%
  filter(year >= 2018 & year <= 2020)

cat(sprintf("Main sample: %d obs, %d states, %d months\n",
            nrow(df_main), n_distinct(df_main$state_abbr),
            n_distinct(df_main$ym)))

# Model 1a: Base — state + month FE
m1a <- feols(abs_pct_change ~ recert_intensity * ies_status |
               state_abbr + ym_factor,
             data = df_main,
             cluster = ~state_abbr)

# Model 1b: With unemployment control
m1b <- feols(abs_pct_change ~ recert_intensity * ies_status + unemp_rate |
               state_abbr + ym_factor,
             data = df_main,
             cluster = ~state_abbr)

# Model 1c: Using average cert period instead (continuous dose)
m1c <- feols(abs_pct_change ~ certearnavg * ies_status |
               state_abbr + ym_factor,
             data = df_main %>% filter(!is.na(certearnavg)),
             cluster = ~state_abbr)

cat("\nModel 1a (baseline):\n")
print(summary(m1a))
cat("\nModel 1b (+ unemployment):\n")
print(summary(m1b))
cat("\nModel 1c (avg cert period × IES):\n")
print(summary(m1c))

# =============================================================================
# Specification 2: Rolling CV as outcome (sustained volatility)
# =============================================================================

cat("\n--- Specification 2: Rolling CV (sustained volatility) ---\n")

df_cv <- panel %>%
  filter(!is.na(recert_intensity) & !is.na(roll_cv_12)) %>%
  filter(year >= 2019 & year <= 2020)  # Need 12-month window

m2a <- feols(roll_cv_12 ~ recert_intensity * ies_status |
               state_abbr + ym_factor,
             data = df_cv,
             cluster = ~state_abbr)

cat("\nModel 2a (rolling CV):\n")
print(summary(m2a))

# =============================================================================
# Specification 3: COVID Natural Experiment
# COVID blanket waivers (March 2020) extended SNAP recertification by 6 months
# Administrative pressure suddenly evaporated → differential volatility should narrow
# =============================================================================

cat("\n--- Specification 3: COVID natural experiment ---\n")

# Use full panel including COVID period
df_covid <- panel %>%
  filter(!is.na(abs_pct_change) & !is.na(recert_intensity)) %>%
  filter(year >= 2018 & year <= 2020) %>%
  mutate(
    post_waiver = ifelse(year == 2020 & month >= 3, 1, 0),
    # Triple interaction: recert × IES × post_waiver
    recert_x_ies_x_post = recert_intensity * ies_status * post_waiver
  )

m3a <- feols(abs_pct_change ~ recert_intensity * ies_status * post_waiver |
               state_abbr + ym_factor,
             data = df_covid,
             cluster = ~state_abbr)

cat("\nModel 3a (triple-diff: recert × IES × COVID waiver):\n")
print(summary(m3a))

# =============================================================================
# Specification 4: Application processing as mechanism
# If recert intensity overwhelms caseworkers, processing times should increase
# =============================================================================

cat("\n--- Specification 4: New applications as outcome ---\n")

# Use log applications as outcome (processing throughput)
df_apps <- panel %>%
  filter(!is.na(recert_intensity) & !is.na(new_applications)) %>%
  filter(new_applications > 0) %>%
  filter(year >= 2018 & year <= 2020) %>%
  mutate(log_apps = log(new_applications))

m4a <- feols(log_apps ~ recert_intensity * ies_status |
               state_abbr + ym_factor,
             data = df_apps,
             cluster = ~state_abbr)

cat("\nModel 4a (log applications):\n")
print(summary(m4a))

# =============================================================================
# Specification 5: Heterogeneity by Medicaid expansion status
# =============================================================================

cat("\n--- Specification 5: Heterogeneity by expansion status ---\n")

# Expansion states have larger Medicaid populations → more competition for resources
df_main <- df_main %>%
  mutate(expanded = ifelse(expanded_medicaid == "Y", 1, 0))

m5_expanded <- feols(abs_pct_change ~ recert_intensity * ies_status |
                       state_abbr + ym_factor,
                     data = df_main %>% filter(expanded == 1),
                     cluster = ~state_abbr)

cat("\nModel 5a (expansion states only):\n")
print(summary(m5_expanded))

# Non-expansion: check if enough IES states exist
n_nonexp_ies <- n_distinct(df_main$state_abbr[df_main$expanded == 0 & df_main$ies_status == 1])
cat(sprintf("\nNon-expansion IES states: %d\n", n_nonexp_ies))

if (n_nonexp_ies >= 5) {
  m5_nonexpanded <- feols(abs_pct_change ~ recert_intensity * ies_status |
                            state_abbr + ym_factor,
                          data = df_main %>% filter(expanded == 0),
                          cluster = ~state_abbr)
  cat("Model 5b (non-expansion states only):\n")
  print(summary(m5_nonexpanded))
} else {
  cat("Too few non-expansion IES states for reliable split.\n")
  m5_nonexpanded <- NULL
}

# =============================================================================
# Save diagnostics.json for validate_v1.py
# =============================================================================

diagnostics <- list(
  n_treated = n_distinct(df_main$state_abbr[df_main$ies_status == 1]),
  n_pre = length(unique(df_main$ym[df_main$year < 2020])),
  n_obs = nrow(df_main)
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))

# =============================================================================
# Save model objects for tables
# =============================================================================

save(m1a, m1b, m1c, m2a, m3a, m4a, m5_expanded, m5_nonexpanded,
     df_main, df_cv, df_covid, df_apps,
     file = file.path(data_dir, "main_models.RData"))

cat("\nAll main analysis complete. Models saved.\n")
