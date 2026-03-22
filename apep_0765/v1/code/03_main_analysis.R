# ============================================================
# 03_main_analysis.R — Main DiD analysis
# apep_0765: SNAP Retailer Exits and Mortgage Access
# ============================================================

source("00_packages.R")
library(fixest)
library(data.table)

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

# ----------------------------------------------------------
# 1. TWFE: Log originations
# ----------------------------------------------------------
cat("=== TWFE: Log Originations ===\n")

twfe_orig <- feols(ln_orig ~ treated | county_fips + year,
                   data = panel, cluster = ~county_fips)
print(summary(twfe_orig))

# ----------------------------------------------------------
# 2. TWFE: Denial rate
# ----------------------------------------------------------
cat("\n=== TWFE: Denial Rate ===\n")

twfe_deny <- feols(denial_rate ~ treated | county_fips + year,
                   data = panel, cluster = ~county_fips)
print(summary(twfe_deny))

# ----------------------------------------------------------
# 3. TWFE: Log median loan amount
# ----------------------------------------------------------
cat("\n=== TWFE: Log Median Loan ===\n")

twfe_loan <- feols(ln_loan ~ treated | county_fips + year,
                   data = panel, cluster = ~county_fips)
print(summary(twfe_loan))

# ----------------------------------------------------------
# 4. TWFE: FHA share
# ----------------------------------------------------------
cat("\n=== TWFE: FHA Share ===\n")

twfe_fha <- feols(fha_share ~ treated | county_fips + year,
                  data = panel, cluster = ~county_fips)
print(summary(twfe_fha))

# ----------------------------------------------------------
# 5. State × year FE (more aggressive)
# ----------------------------------------------------------
cat("\n=== State × Year FE ===\n")

twfe_orig_sy <- feols(ln_orig ~ treated | county_fips + state_fips^year,
                      data = panel, cluster = ~county_fips)
cat("  Log orig (state×year FE):\n")
print(summary(twfe_orig_sy))

twfe_deny_sy <- feols(denial_rate ~ treated | county_fips + state_fips^year,
                      data = panel, cluster = ~county_fips)
cat("  Denial rate (state×year FE):\n")
print(summary(twfe_deny_sy))

# ----------------------------------------------------------
# 6. Save results
# ----------------------------------------------------------
saveRDS(twfe_orig, file.path(data_dir, "twfe_orig.rds"))
saveRDS(twfe_deny, file.path(data_dir, "twfe_deny.rds"))
saveRDS(twfe_loan, file.path(data_dir, "twfe_loan.rds"))
saveRDS(twfe_fha, file.path(data_dir, "twfe_fha.rds"))
saveRDS(twfe_orig_sy, file.path(data_dir, "twfe_orig_sy.rds"))
saveRDS(twfe_deny_sy, file.path(data_dir, "twfe_deny_sy.rds"))

# ----------------------------------------------------------
# 7. Diagnostics
# ----------------------------------------------------------
cat("\n=== Diagnostics ===\n")

diagnostics <- list(
  n_treated = sum(panel$first_treat > 0 & !duplicated(panel$county_fips)),
  n_pre = 5,  # 2018-2022 for 2023 cohort; SNAP exits from 2015 give 3+ years pre-period
  n_obs = nrow(panel),
  n_counties = length(unique(panel$county_fips)),
  outcome_sd_pre = sd(panel[treated == 0]$denial_rate, na.rm = TRUE),
  outcome_mean_pre = mean(panel[treated == 0]$denial_rate, na.rm = TRUE)
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)

cat("  n_treated:", diagnostics$n_treated, "\n")
cat("  n_obs:", diagnostics$n_obs, "\n")

cat("\n=== Main analysis complete ===\n")
