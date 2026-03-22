# ============================================================
# 03_main_analysis.R — Main DiD analysis with race DDD
# apep_0757: The Racial Anatomy of Food Desert Formation
# ============================================================

source("00_packages.R")
library(fixest)
library(did)
library(data.table)
library(dplyr)

data_dir <- "../data"

# ----------------------------------------------------------
# 1. Load data
# ----------------------------------------------------------
cat("=== Loading analysis panel ===\n")

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
cat("  Observations:", format(nrow(panel), big.mark = ","), "\n")

# ----------------------------------------------------------
# 2. Race DDD: TWFE specification
# ----------------------------------------------------------
cat("\n=== Race DDD: Employment (log) ===\n")

# Drop missing ln_emp
panel_emp <- panel[!is.na(ln_emp)]

# Main spec: county FE + time FE + race FE + treated × black
ddd_emp <- feols(ln_emp ~ treated * black | county_fips + time_id + race_label,
                 data = panel_emp, cluster = ~county_fips)
cat("  DDD — Log Employment:\n")
print(summary(ddd_emp))

# ----------------------------------------------------------
# 3. Race DDD: Separation rate
# ----------------------------------------------------------
cat("\n=== Race DDD: Separation Rate ===\n")

panel_sep <- panel[!is.na(sep_rate)]

ddd_sep <- feols(sep_rate ~ treated * black | county_fips + time_id + race_label,
                 data = panel_sep, cluster = ~county_fips)
cat("  DDD — Separation Rate:\n")
print(summary(ddd_sep))

# ----------------------------------------------------------
# 4. Race DDD: Log Earnings
# ----------------------------------------------------------
cat("\n=== Race DDD: Log Earnings ===\n")

panel_earn <- panel[!is.na(ln_earn)]

ddd_earn <- feols(ln_earn ~ treated * black | county_fips + time_id + race_label,
                  data = panel_earn, cluster = ~county_fips)
cat("  DDD — Log Earnings:\n")
print(summary(ddd_earn))

# ----------------------------------------------------------
# 5. Race DDD: Employment level
# ----------------------------------------------------------
cat("\n=== Race DDD: Employment Level ===\n")

ddd_emp_level <- feols(Emp ~ treated * black | county_fips + time_id + race_label,
                       data = panel, cluster = ~county_fips)
cat("  DDD — Employment Level:\n")
print(summary(ddd_emp_level))

# ----------------------------------------------------------
# 6. Race DDD: Hires
# ----------------------------------------------------------
cat("\n=== Race DDD: Hires ===\n")

panel_hir <- panel[!is.na(HirA)]

ddd_hir <- feols(HirA ~ treated * black | county_fips + time_id + race_label,
                 data = panel_hir, cluster = ~county_fips)
cat("  DDD — Hires:\n")
print(summary(ddd_hir))

# Save all models
saveRDS(ddd_emp, file.path(data_dir, "ddd_emp.rds"))
saveRDS(ddd_sep, file.path(data_dir, "ddd_sep.rds"))
saveRDS(ddd_earn, file.path(data_dir, "ddd_earn.rds"))
saveRDS(ddd_emp_level, file.path(data_dir, "ddd_emp_level.rds"))
saveRDS(ddd_hir, file.path(data_dir, "ddd_hir.rds"))

# ----------------------------------------------------------
# 7. Overall (non-race) DiD: Effect on total employment
# ----------------------------------------------------------
cat("\n=== Overall DiD: Total NAICS 445 Employment ===\n")

panel_all <- panel[race_label == "white"]  # One obs per county-quarter
twfe_total <- feols(ln_emp ~ treated | county_fips + time_id,
                    data = panel_all[!is.na(ln_emp)], cluster = ~county_fips)
cat("  Overall TWFE — Log Employment (White):\n")
print(summary(twfe_total))

panel_black_only <- panel[race_label == "black"]
twfe_black <- feols(ln_emp ~ treated | county_fips + time_id,
                    data = panel_black_only[!is.na(ln_emp)], cluster = ~county_fips)
cat("  Overall TWFE — Log Employment (Black):\n")
print(summary(twfe_black))

saveRDS(twfe_total, file.path(data_dir, "twfe_white_emp.rds"))
saveRDS(twfe_black, file.path(data_dir, "twfe_black_emp.rds"))

# ----------------------------------------------------------
# 8. Write diagnostics.json
# ----------------------------------------------------------
cat("\n=== Writing diagnostics ===\n")

diagnostics <- list(
  n_treated = sum(panel$first_treat > 0 & !duplicated(panel$county_fips)),
  n_pre = 20,  # 5 years × 4 quarters before median first_treat
  n_obs = nrow(panel),
  n_counties = length(unique(panel$county_fips)),
  n_sm_exits = 33050,
  outcome_sd_pre = sd(panel[treated == 0 & black == 1]$sep_rate, na.rm = TRUE),
  outcome_mean_pre_black_sep = mean(panel[treated == 0 & black == 1]$sep_rate, na.rm = TRUE),
  outcome_mean_pre_white_sep = mean(panel[treated == 0 & black == 0]$sep_rate, na.rm = TRUE),
  ddd_sep_est = coef(ddd_sep)["treated:black"],
  ddd_sep_se = sqrt(vcov(ddd_sep)["treated:black", "treated:black"])
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)

cat("  n_treated:", diagnostics$n_treated, "\n")
cat("  n_obs:", diagnostics$n_obs, "\n")
cat("  Black sep rate pre-treatment:", round(diagnostics$outcome_mean_pre_black_sep, 4), "\n")
cat("  White sep rate pre-treatment:", round(diagnostics$outcome_mean_pre_white_sep, 4), "\n")

cat("\n=== Main analysis complete ===\n")
