## 03_main_analysis.R — Main regressions
## apep_0877: Croatia 2013 Fiscalization

source("code/00_packages.R")

cat("=== Main Analysis ===\n")

panel_vat <- readRDS("data/panel_vat.rds")
panel_gva <- readRDS("data/panel_gva.rds")

# ===============================================================
# SPECIFICATION 1: Cross-Country DiD — VAT/GDP
# ===============================================================
cat("\n--- Specification 1: Cross-Country DiD (VAT/GDP) ---\n")

# 1a. Basic DiD
m1a <- feols(vat_gdp ~ treat | country + year,
             data = panel_vat,
             cluster = ~country)
cat("Basic DiD (country + year FE):\n")
summary(m1a)

# 1b. With macro controls
m1b <- feols(vat_gdp ~ treat + gdp_growth + unemp_rate | country + year,
             data = panel_vat,
             cluster = ~country)
cat("\nWith macro controls:\n")
summary(m1b)

# 1c. Event study
m1c <- feols(vat_gdp ~ i(event_time, croatia, ref = -1) | country + year,
             data = panel_vat,
             cluster = ~country)
cat("\nEvent study:\n")
summary(m1c)

# Store event study coefficients for table
es_coefs <- as.data.frame(coeftable(m1c))
es_coefs$event_time <- as.integer(gsub(".*::", "", rownames(es_coefs)))

saveRDS(list(basic = m1a, controls = m1b, event_study = m1c,
             es_coefs = es_coefs), "data/results_vat.rds")

# ===============================================================
# SPECIFICATION 2: Within-Croatia Sector DiD — Log GVA
# ===============================================================
cat("\n--- Specification 2: Sector DiD (Log GVA) ---\n")

# Only Croatia, treated vs never-treated sectors
hr_gva <- panel_gva %>% filter(country == "HR")

cat(sprintf("Croatia panel: %d sector-years, %d sectors (%d treated, %d never-treated)\n",
            nrow(hr_gva), n_distinct(hr_gva$nace),
            n_distinct(hr_gva$nace[hr_gva$treated == 1]),
            n_distinct(hr_gva$nace[hr_gva$treated == 0])))

# 2a. Basic sector DiD
m2a <- feols(log_gva ~ sector_treat | nace + year,
             data = hr_gva,
             cluster = ~nace)
cat("Within-Croatia sector DiD:\n")
summary(m2a)

# 2b. By treatment phase
hr_gva <- hr_gva %>%
  mutate(
    phase1_treat = as.integer(phase == 1 & post == 1),
    phase2_treat = as.integer(phase == 2 & post == 1),
    phase3_treat = as.integer(phase == 3 & post == 1)
  )

m2b <- feols(log_gva ~ phase1_treat + phase2_treat + phase3_treat | nace + year,
             data = hr_gva,
             cluster = ~nace)
cat("\nBy phase:\n")
summary(m2b)

saveRDS(list(basic = m2a, by_phase = m2b), "data/results_sector.rds")

# ===============================================================
# SPECIFICATION 3: Triple Difference — Country × Sector × Time
# ===============================================================
cat("\n--- Specification 3: Triple Difference ---\n")

# All countries, sector-level
# Treatment: being in a treated sector in Croatia after 2013
panel_gva <- panel_gva %>%
  mutate(
    country_sector = paste(country, nace, sep = "_"),
    country_year = paste(country, year, sep = "_"),
    sector_year = paste(nace, year, sep = "_"),
    # Triple-diff treatment
    ddd = as.integer(treated == 1 & croatia == 1 & post == 1),
    # Component interactions
    did_croatia_post = as.integer(croatia == 1 & post == 1),
    did_treated_post = as.integer(treated == 1 & post == 1),
    did_croatia_treated = as.integer(croatia == 1 & treated == 1)
  )

# 3a. Full triple difference with three-way FE
m3a <- feols(log_gva ~ ddd | country_sector + country_year + sector_year,
             data = panel_gva,
             cluster = ~country)
cat("Triple difference (country×sector + country×year + sector×year FE):\n")
summary(m3a)

# 3b. Less saturated (for comparison)
m3b <- feols(log_gva ~ ddd + did_croatia_post + did_treated_post |
               country_sector + year,
             data = panel_gva,
             cluster = ~country)
cat("\nTriple difference (less saturated):\n")
summary(m3b)

saveRDS(list(full_fe = m3a, less_saturated = m3b), "data/results_ddd.rds")

# ===============================================================
# Summary of main results
# ===============================================================
cat("\n=== MAIN RESULTS SUMMARY ===\n")
cat(sprintf("Cross-country DiD (VAT/GDP):    β = %.3f (SE = %.3f)\n",
            coef(m1a)["treat"], se(m1a)["treat"]))
cat(sprintf("Within-Croatia sector (log GVA): β = %.3f (SE = %.3f)\n",
            coef(m2a)["sector_treat"], se(m2a)["sector_treat"]))
cat(sprintf("Triple difference (log GVA):     β = %.3f (SE = %.3f)\n",
            coef(m3a)["ddd"], se(m3a)["ddd"]))

# Pre-treatment SD of outcome for SDE calculation
pre_vat_sd <- sd(panel_vat$vat_gdp[panel_vat$year < 2013], na.rm = TRUE)
pre_gva_sd <- sd(hr_gva$log_gva[hr_gva$year < 2013], na.rm = TRUE)

cat(sprintf("\nSD(VAT/GDP) pre-treatment: %.3f\n", pre_vat_sd))
cat(sprintf("SD(log GVA) pre-treatment: %.3f\n", pre_gva_sd))

# Store SDE inputs
sde_inputs <- list(
  vat_beta = coef(m1a)["treat"],
  vat_se = se(m1a)["treat"],
  vat_sd_y = pre_vat_sd,
  gva_beta = coef(m2a)["sector_treat"],
  gva_se = se(m2a)["sector_treat"],
  gva_sd_y = pre_gva_sd,
  ddd_beta = coef(m3a)["ddd"],
  ddd_se = se(m3a)["ddd"]
)
saveRDS(sde_inputs, "data/sde_inputs.rds")

# Diagnostics for validator
diagnostics <- list(
  n_treated = n_distinct(hr_gva$nace[hr_gva$treated == 1]),
  n_pre = length(unique(panel_vat$year[panel_vat$year < 2013])),
  n_obs = nrow(panel_vat) + nrow(panel_gva)
)
jsonlite::write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))

cat("\n=== Main analysis complete ===\n")
