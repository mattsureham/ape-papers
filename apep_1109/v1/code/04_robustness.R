## 04_robustness.R — Robustness checks and placebo tests
## apep_1109: Crop Insurance and Deaths of Despair

source("00_packages.R")
data_dir <- file.path(dirname(getwd()), "data")

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
load(file.path(data_dir, "models.RData"))

# ============================================================
# PLACEBO 1: Non-agricultural counties (no first stage expected)
# ============================================================

cat("=== Placebo 1: Non-Agricultural Counties ===\n")

nonag <- panel[ag_county == 0 & !is.na(pdsi_growing)]
nonag[, indem_pc_w := 0]  # No indemnity

# Reduced form on non-ag counties
rf_nonag <- feols(od_rate ~ pdsi_growing | fips5 + year,
                  data = nonag, cluster = ~state_fips)
cat("Reduced form (non-ag counties):\n")
cat(sprintf("  Coef: %.4f (SE: %.4f, t: %.2f)\n",
            coef(rf_nonag)["pdsi_growing"],
            se(rf_nonag)["pdsi_growing"],
            coef(rf_nonag)["pdsi_growing"] / se(rf_nonag)["pdsi_growing"]))

# ============================================================
# PLACEBO 2: Alternative severity thresholds
# ============================================================

cat("\n=== Sensitivity: PDSI Severity Thresholds ===\n")

ag2 <- panel[ag_county == 1 & !is.na(pdsi_growing)]
ag2[, indem_pc := indemnity / pop]
ag2[, indem_pc_w := pmin(pmax(indem_pc, quantile(indem_pc, 0.01, na.rm = TRUE)),
                          quantile(indem_pc, 0.99, na.rm = TRUE))]

# Use continuous PDSI (already used in main spec)
# Also try quadratic PDSI
iv_quad <- feols(od_rate ~ 1 | fips5 + year |
                   indem_pc_w ~ pdsi_growing + I(pdsi_growing^2),
                 data = ag2, cluster = ~state_fips)
cat(sprintf("IV with quadratic PDSI: coef = %.4f (SE: %.4f)\n",
            coef(iv_quad)["fit_indem_pc_w"], se(iv_quad)["fit_indem_pc_w"]))

# ============================================================
# PLACEBO 3: Lag structure (leads should be zero)
# ============================================================

cat("\n=== Placebo 3: Lead/Lag Structure ===\n")

ag2[, pdsi_lag1 := shift(pdsi_growing, 1), by = fips5]
ag2[, pdsi_lag2 := shift(pdsi_growing, 2), by = fips5]
ag2[, pdsi_lead1 := shift(pdsi_growing, -1), by = fips5]
ag2[, pdsi_lead2 := shift(pdsi_growing, -2), by = fips5]

rf_leads <- feols(od_rate ~ pdsi_lead2 + pdsi_lead1 + pdsi_growing +
                    pdsi_lag1 + pdsi_lag2 | fips5 + year,
                  data = ag2, cluster = ~state_fips)
cat("Reduced form with leads and lags:\n")
print(summary(rf_leads))

# ============================================================
# ROBUSTNESS 1: Different time periods
# ============================================================

cat("\n=== Robustness 1: Sub-period Analysis ===\n")

# Pre-opioid crisis (2003-2010)
iv_early <- feols(od_rate ~ 1 | fips5 + year | indem_pc_w ~ pdsi_growing,
                  data = ag2[year <= 2010], cluster = ~state_fips)
cat(sprintf("IV 2003-2010: coef = %.4f (SE: %.4f, N = %d)\n",
            coef(iv_early)["fit_indem_pc_w"], se(iv_early)["fit_indem_pc_w"],
            nobs(iv_early)))

# Opioid crisis (2011-2021)
iv_late <- feols(od_rate ~ 1 | fips5 + year | indem_pc_w ~ pdsi_growing,
                 data = ag2[year >= 2011], cluster = ~state_fips)
cat(sprintf("IV 2011-2021: coef = %.4f (SE: %.4f, N = %d)\n",
            coef(iv_late)["fit_indem_pc_w"], se(iv_late)["fit_indem_pc_w"],
            nobs(iv_late)))

# ============================================================
# ROBUSTNESS 2: Exclude 2020-2021 (COVID disruption)
# ============================================================

cat("\n=== Robustness 2: Exclude COVID years ===\n")

iv_nocovid <- feols(od_rate ~ 1 | fips5 + year | indem_pc_w ~ pdsi_growing,
                    data = ag2[year <= 2019], cluster = ~state_fips)
cat(sprintf("IV 2003-2019: coef = %.4f (SE: %.4f, N = %d)\n",
            coef(iv_nocovid)["fit_indem_pc_w"], se(iv_nocovid)["fit_indem_pc_w"],
            nobs(iv_nocovid)))

# ============================================================
# ROBUSTNESS 3: Rural-only sample
# ============================================================

cat("\n=== Robustness 3: Rural Counties Only ===\n")

ag_rural <- ag2[rural == 1]
iv_rural_only <- feols(od_rate ~ 1 | fips5 + year | indem_pc_w ~ pdsi_growing,
                       data = ag_rural, cluster = ~state_fips)
fs_rural <- feols(indem_pc_w ~ pdsi_growing | fips5 + year,
                  data = ag_rural, cluster = ~state_fips)
cat(sprintf("IV (rural only): coef = %.4f (SE: %.4f, N = %d)\n",
            coef(iv_rural_only)["fit_indem_pc_w"],
            se(iv_rural_only)["fit_indem_pc_w"],
            nobs(iv_rural_only)))
cat(sprintf("First stage F (rural): %.1f\n",
            summary(fs_rural)$coeftable["pdsi_growing", "t value"]^2))

# ============================================================
# ROBUSTNESS 4: Drought indicator instead of continuous PDSI
# ============================================================

cat("\n=== Robustness 4: Binary Drought Indicator ===\n")

ag2[, severe_drought := as.integer(pdsi_growing < -3)]

rf_binary <- feols(od_rate ~ severe_drought | fips5 + year,
                   data = ag2, cluster = ~state_fips)
cat(sprintf("Reduced form (severe drought binary): coef = %.3f (SE: %.3f)\n",
            coef(rf_binary)["severe_drought"], se(rf_binary)["severe_drought"]))

# ============================================================
# POWER ANALYSIS: What effect could we detect?
# ============================================================

cat("\n=== Power Analysis ===\n")

# With N=51024, clustered SE on IV coef = 0.0016
# Minimum detectable effect at 5% significance (two-sided) = 1.96 * SE
mde_iv <- 1.96 * as.numeric(se(iv1)["fit_indem_pc_w"])
cat(sprintf("MDE for IV coefficient: %.4f per $1 indemnity/capita\n", mde_iv))

# In terms of reduced form (PDSI -> OD rate)
mde_rf <- 1.96 * as.numeric(se(rf1)["pdsi_growing"])
cat(sprintf("MDE for reduced form: %.3f per unit PDSI\n", mde_rf))

# Scale: what does a 1-unit PDSI change mean?
# Mean SD of PDSI = 2.11, so moving from normal (0) to moderate drought (-2) is ~1 SD
# MDE: 0.084 per 100K per unit PDSI
# Mean OD rate: 13.3 per 100K
# So MDE is 0.084/13.3 = 0.6% of mean — we can rule out effects >0.6% of baseline
cat(sprintf("MDE as %% of mean OD rate: %.1f%%\n", 100 * mde_rf / mean(ag2$od_rate, na.rm = TRUE)))

# Save robustness results
save(rf_nonag, iv_quad, rf_leads, iv_early, iv_late, iv_nocovid,
     iv_rural_only, rf_binary,
     file = file.path(data_dir, "robustness_models.RData"))

cat("\n=== Robustness checks complete ===\n")
