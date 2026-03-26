# =============================================================================
# 03_main_analysis.R — Main DiD analysis
# apep_0998: USAID contract terminations and local employment
# =============================================================================

source("00_packages.R")

DATA_DIR <- "../data"

panel_54 <- readRDS(file.path(DATA_DIR, "panel_54.rds"))
panel_72 <- readRDS(file.path(DATA_DIR, "panel_72.rds"))
panel_mfg <- readRDS(file.path(DATA_DIR, "panel_mfg.rds"))
panel_retail <- readRDS(file.path(DATA_DIR, "panel_retail.rds"))
treatment <- readRDS(file.path(DATA_DIR, "treatment.rds"))

# ---------------------------------------------------------------------------
# 1. Main specification: Continuous treatment DiD (shift-share)
# ---------------------------------------------------------------------------
cat("=== Main specification: Continuous treatment DiD ===\n")

# Focus on 2019Q1-2025Q2 for cleaner sample (avoids COVID onset mess)
# Keep 2019-2024 as pre-period, 2025 as post
panel_54_main <- panel_54[year >= 2019]

# Continuous treatment: USAID contract dollars per employee × Post
# This is the shift-share Bartik design
model_1 <- feols(log_emp ~ usaid_per_emp:post | county_fips + time_id,
                 data = panel_54_main, cluster = ~state_fips)

cat("\n--- Model 1: Continuous treatment (log emp) ---\n")
summary(model_1)

# Binary treatment: High-USAID × Post
model_2 <- feols(log_emp ~ high_usaid:post | county_fips + time_id,
                 data = panel_54_main, cluster = ~state_fips)

cat("\n--- Model 2: Binary treatment (log emp) ---\n")
summary(model_2)

# New hires channel
model_3 <- feols(log_hirn ~ usaid_per_emp:post | county_fips + time_id,
                 data = panel_54_main, cluster = ~state_fips)

cat("\n--- Model 3: New hires (continuous treatment) ---\n")
summary(model_3)

# Separations channel
model_4 <- feols(log_sep ~ usaid_per_emp:post | county_fips + time_id,
                 data = panel_54_main, cluster = ~state_fips)

cat("\n--- Model 4: Separations (continuous treatment) ---\n")
summary(model_4)

# ---------------------------------------------------------------------------
# 2. Event study specification
# ---------------------------------------------------------------------------
cat("\n=== Event study ===\n")

# Create relative time dummies (2025Q1 = treatment onset)
# Reference: 2024Q4 (last pre-treatment quarter)
panel_54_main[, rel_time := time_id - ((2025 - 2015) * 4 + 1)]  # 0 = 2025Q1

# Event study with continuous treatment
es_model <- feols(log_emp ~ i(rel_time, usaid_per_emp, ref = -1) | county_fips + time_id,
                  data = panel_54_main, cluster = ~state_fips)

cat("\n--- Event study coefficients ---\n")
print(coeftable(es_model)[1:min(10, nrow(coeftable(es_model))), ])

# Binary treatment event study
es_binary <- feols(log_emp ~ i(rel_time, high_usaid, ref = -1) | county_fips + time_id,
                   data = panel_54_main, cluster = ~state_fips)

# ---------------------------------------------------------------------------
# 3. Sector-specific results
# ---------------------------------------------------------------------------
cat("\n=== Sector-specific results ===\n")

# NAICS 72: Accommodation/Food (local multiplier)
panel_72_main <- panel_72[year >= 2019]
panel_72_main[, log_emp := log(emp + 1)]
panel_72_main[, rel_time := time_id - ((2025 - 2015) * 4 + 1)]
model_72 <- feols(log_emp ~ usaid_per_emp:post | county_fips + time_id,
                  data = panel_72_main, cluster = ~state_fips)
cat("\n--- NAICS 72 (Accommodation/Food) ---\n")
summary(model_72)

# NAICS 31-33: Manufacturing (placebo)
panel_mfg_main <- panel_mfg[year >= 2019]
panel_mfg_main[, log_emp := log(emp + 1)]
model_mfg <- feols(log_emp ~ usaid_per_emp:post | county_fips + time_id,
                   data = panel_mfg_main, cluster = ~state_fips)
cat("\n--- NAICS 31-33 (Manufacturing, placebo) ---\n")
summary(model_mfg)

# NAICS 44-45: Retail (local multiplier)
panel_retail_main <- panel_retail[year >= 2019]
panel_retail_main[, log_emp := log(emp + 1)]
model_retail <- feols(log_emp ~ usaid_per_emp:post | county_fips + time_id,
                      data = panel_retail_main, cluster = ~state_fips)
cat("\n--- NAICS 44-45 (Retail, multiplier) ---\n")
summary(model_retail)

# ---------------------------------------------------------------------------
# 4. Excluding DMV
# ---------------------------------------------------------------------------
cat("\n=== Excluding DC-MD-VA ===\n")

model_ex_dmv <- feols(log_emp ~ usaid_per_emp:post | county_fips + time_id,
                      data = panel_54_main[dmv == 0], cluster = ~state_fips)
cat("\n--- Model excluding DMV ---\n")
summary(model_ex_dmv)

# ---------------------------------------------------------------------------
# 5. Save results and diagnostics
# ---------------------------------------------------------------------------
cat("\n=== Saving results ===\n")

results <- list(
  model_1 = model_1,
  model_2 = model_2,
  model_3 = model_3,
  model_4 = model_4,
  es_model = es_model,
  es_binary = es_binary,
  model_72 = model_72,
  model_mfg = model_mfg,
  model_retail = model_retail,
  model_ex_dmv = model_ex_dmv
)

saveRDS(results, file.path(DATA_DIR, "main_results.rds"))

# Diagnostics for validator
n_treated <- uniqueN(panel_54_main[high_usaid == 1]$county_fips)
n_pre <- uniqueN(panel_54_main[post == 0]$time_id)
n_obs <- nrow(panel_54_main)

cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n", n_treated, n_pre, n_obs))

jsonlite::write_json(
  list(n_treated = n_treated, n_pre = n_pre, n_obs = n_obs),
  file.path(DATA_DIR, "diagnostics.json"),
  auto_unbox = TRUE
)

# Pre-treatment SD of log employment for SDE calculation
pre_sd_emp <- sd(panel_54_main[post == 0]$log_emp, na.rm = TRUE)
pre_sd_hirn <- sd(panel_54_main[post == 0]$log_hirn, na.rm = TRUE)
pre_sd_sep <- sd(panel_54_main[post == 0]$log_sep, na.rm = TRUE)

cat(sprintf("Pre-treatment SD(log emp): %.4f\n", pre_sd_emp))
cat(sprintf("Pre-treatment SD(log hirn): %.4f\n", pre_sd_hirn))
cat(sprintf("Pre-treatment SD(log sep): %.4f\n", pre_sd_sep))

sde_info <- list(
  pre_sd_log_emp = pre_sd_emp,
  pre_sd_log_hirn = pre_sd_hirn,
  pre_sd_log_sep = pre_sd_sep
)
saveRDS(sde_info, file.path(DATA_DIR, "sde_info.rds"))

cat("\n=== Main analysis complete ===\n")
