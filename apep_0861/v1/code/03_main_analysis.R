## 03_main_analysis.R — Main regressions
## APEP-0861: Austerity Triage and Domestic Abuse Justice

source("00_packages.R")
setwd("..")

panel <- readRDS("data/analysis_panel.rds")
workforce <- readRDS("data/workforce_panel.rds")

cat("=== MAIN ANALYSIS ===\n")
cat("Panel dimensions:", nrow(panel), "obs,", n_distinct(panel$force_std), "forces,",
    n_distinct(panel$year), "years\n")

# ===============================================================
# A. DEFINE TREATMENT: Austerity exposure
# ===============================================================
# Treatment intensity = percentage change in officers from 2010 peak
# Split into austerity period (2016-2019) vs uplift period (2020-2023)

panel <- panel %>%
  mutate(
    # Continuous treatment: officer change from 2010 baseline
    austerity_intensity = -officer_change_pct,  # Positive = bigger cuts
    # Binary uplift indicator (Boris Johnson's 20K officer pledge, 2019+)
    post_uplift = as.integer(year >= 2020),
    # Log officer FTE for elasticity interpretation
    log_officers = log(officer_fte),
    # Scale outcomes to percentages
    charge_rate = charge_rate_pct * 100,
    no_suspect = no_suspect_pct * 100,
    victim_nosupport = victim_nosupport_pct * 100,
    success_rate = success_rate_pct * 100
  )

# ===============================================================
# B. DESCRIPTIVE: Austerity and charge rate trends
# ===============================================================
cat("\n=== AUSTERITY EXPOSURE VARIATION ===\n")
cat("Officer change 2010-2018 (% from 2010 baseline):\n")

# Classification: high vs low austerity (above/below median cut)
median_cut <- panel %>%
  filter(year == 2018) %>%
  pull(officer_change_pct) %>%
  median(na.rm = TRUE)

panel <- panel %>%
  mutate(
    high_austerity = as.integer(officer_change_pct < median_cut |
                                  (year < 2018 & force_std %in%
                                     (panel %>% filter(year == 2018, officer_change_pct < median_cut) %>% pull(force_std))))
  )

# Actually, use 2018 classification for all years (pre-determined)
austerity_class <- panel %>%
  filter(year == 2018) %>%
  select(force_std, high_austerity_2018 = officer_change_pct) %>%
  mutate(high_austerity = as.integer(high_austerity_2018 < median_cut))

panel <- panel %>%
  select(-high_austerity) %>%
  left_join(austerity_class %>% select(force_std, high_austerity), by = "force_std")

cat("Median officer change by 2018:", round(median_cut, 1), "%\n")
cat("High austerity forces:", sum(austerity_class$high_austerity), "\n")
cat("Low austerity forces:", sum(!austerity_class$high_austerity), "\n")

# ===============================================================
# C. MAIN REGRESSIONS
# ===============================================================
cat("\n=== MAIN REGRESSIONS ===\n")

# Model 1: OLS — officer FTE on charge rate (force + year FE)
m1 <- feols(charge_rate ~ log_officers | force_std + year,
            data = panel, cluster = ~force_std)

# Model 2: Add interaction with post-uplift (differential recovery)
m2 <- feols(charge_rate ~ log_officers + log_officers:post_uplift | force_std + year,
            data = panel, cluster = ~force_std)

# Model 3: High vs low austerity × year (event study style)
m3 <- feols(charge_rate ~ i(year, high_austerity, ref = 2016) | force_std + year,
            data = panel, cluster = ~force_std)

# Model 4: Continuous treatment intensity
m4 <- feols(charge_rate ~ i(year, austerity_intensity, ref = 2016) | force_std + year,
            data = panel, cluster = ~force_std)

cat("Model 1 (OLS, FE): log_officers coef =", coef(m1)["log_officers"],
    ", SE =", se(m1)["log_officers"], "\n")
cat("Model 3 (event study, binary):\n")
print(summary(m3))

# ===============================================================
# D. ALTERNATIVE OUTCOMES
# ===============================================================
cat("\n=== ALTERNATIVE OUTCOMES ===\n")

# Victim does not support police action (mechanism: investigation quality)
m5 <- feols(victim_nosupport ~ log_officers | force_std + year,
            data = panel, cluster = ~force_std)

# No suspect identified (mechanism: investigative capacity)
m6 <- feols(no_suspect ~ log_officers | force_std + year,
            data = panel, cluster = ~force_std)

# Successful outcome rate
m7 <- feols(success_rate ~ log_officers | force_std + year,
            data = panel, cluster = ~force_std)

cat("Victim no-support: coef =", coef(m5)[1], ", SE =", se(m5)[1], "\n")
cat("No suspect: coef =", coef(m6)[1], ", SE =", se(m6)[1], "\n")
cat("Success rate: coef =", coef(m7)[1], ", SE =", se(m7)[1], "\n")

# ===============================================================
# E. SAVE MODELS AND DIAGNOSTICS
# ===============================================================
models <- list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5, m6 = m6, m7 = m7)
saveRDS(models, "data/main_models.rds")

# Write diagnostics for validator
diagnostics <- list(
  n_treated = n_distinct(panel$force_std[panel$high_austerity == 1]),
  n_pre = length(unique(panel$year[panel$year < 2020])),
  n_obs = nrow(panel)
)
jsonlite::write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE)

cat("\nDiagnostics:", jsonlite::toJSON(diagnostics, auto_unbox = TRUE), "\n")
cat("Models saved to data/main_models.rds\n")
