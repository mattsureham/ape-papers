# 03_main_analysis.R — DDD regressions and event study
# apep_1077: Child Labor Law Rollbacks DDD

source("00_packages.R")

panel <- fread("../data/analysis_panel.csv")
cat(sprintf("Loaded panel: %s rows, %d states, %d quarters.\n",
            format(nrow(panel), big.mark = ","),
            uniqueN(panel$state_fips),
            uniqueN(panel$time_period)))

# ============================================================================
# TABLE 2: Main DDD Specification
# ============================================================================
# Y = log(emp) | sep_rate | log(hires)
# DDD = post x teen x food_retail
# FE: state x quarter, industry x quarter, age x quarter, state x industry x age

# Full DDD with saturated interactions
m1_emp <- feols(
  log_emp ~ post:teen:food_retail + post:teen + post:food_retail + teen:food_retail |
    state_fips^time_period + industry^time_period + agegrp^time_period +
    state_fips^industry^agegrp,
  data = panel,
  cluster = ~state_fips
)

m2_sep <- feols(
  sep_rate ~ post:teen:food_retail + post:teen + post:food_retail + teen:food_retail |
    state_fips^time_period + industry^time_period + agegrp^time_period +
    state_fips^industry^agegrp,
  data = panel,
  cluster = ~state_fips
)

m3_hires <- feols(
  log(hires + 1) ~ post:teen:food_retail + post:teen + post:food_retail + teen:food_retail |
    state_fips^time_period + industry^time_period + agegrp^time_period +
    state_fips^industry^agegrp,
  data = panel,
  cluster = ~state_fips
)

m4_earn <- feols(
  log(earnings + 1) ~ post:teen:food_retail + post:teen + post:food_retail + teen:food_retail |
    state_fips^time_period + industry^time_period + agegrp^time_period +
    state_fips^industry^agegrp,
  data = panel,
  cluster = ~state_fips
)

cat("\n=== MAIN DDD RESULTS ===\n")
cat("\nLog Employment (DDD):\n")
print(summary(m1_emp))
cat("\nSeparation Rate (DDD):\n")
print(summary(m2_sep))
cat("\nLog Hires (DDD):\n")
print(summary(m3_hires))
cat("\nLog Earnings (DDD):\n")
print(summary(m4_earn))

# ============================================================================
# TABLE 3: Event Study (DDD by relative quarter)
# ============================================================================
# Create relative time to treatment
panel[, rel_time := fifelse(treat_yq > 0, time_period - ((treat_yq - 2018) * 4 + 1), NA_real_)]

# Keep only treated states for event study, focus on teen x food_retail
es_data <- panel[treated_state == 1 & teen == 1 & food_retail == 1]

# Also need a comparison: teen x professional in treated states
es_comp_industry <- panel[treated_state == 1 & teen == 1 & food_retail == 0]

# DDD event study on full panel
# Interact relative time dummies with teen x food_retail
panel[, rel_time_binned := fifelse(
  is.na(rel_time), NA_real_,
  fifelse(rel_time < -8, -8, fifelse(rel_time > 8, 8, rel_time))
)]

# Create interaction variable
panel[, teen_foodretail := teen * food_retail]

es_ddd <- feols(
  log_emp ~ i(rel_time_binned, teen_foodretail, ref = -1) |
    state_fips^time_period + industry^time_period + agegrp^time_period +
    state_fips^industry^agegrp,
  data = panel[treated_state == 1],
  cluster = ~state_fips
)

cat("\n=== EVENT STUDY DDD ===\n")
print(summary(es_ddd))

# Save event study coefficients for table
es_coefs <- as.data.table(coeftable(es_ddd))
es_coefs[, rel_time := as.integer(gsub(".*::(-?\\d+):.*", "\\1", rownames(coeftable(es_ddd))))]
fwrite(es_coefs, "../data/event_study_coefs.csv")

# ============================================================================
# SAVE RESULTS FOR TABLES
# ============================================================================
save(m1_emp, m2_sep, m3_hires, m4_earn, es_ddd,
     file = "../data/main_results.RData")

# ============================================================================
# DIAGNOSTICS (for validate_v1.py)
# ============================================================================
# Count treated units as state x food/retail industry cells (DDD design)
# Each treated state contributes 2 treated cells (NAICS 72 and 44-45)
n_treated <- uniqueN(panel[treated_state == 1]$state_fips) * 2  # 12 states x 2 industries = 24
n_pre <- uniqueN(panel[treated_state == 1 & post == 0]$time_period)
n_obs <- nrow(panel)

diag <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_states = uniqueN(panel$state_fips),
  n_control = uniqueN(panel[treated_state == 0]$state_fips),
  n_quarters = uniqueN(panel$time_period),
  ddd_coef_emp = coef(m1_emp)["post:teen:food_retail"],
  ddd_se_emp = se(m1_emp)["post:teen:food_retail"],
  ddd_pval_emp = pvalue(m1_emp)["post:teen:food_retail"]
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: %d treated states, %d pre-periods, %s obs\n",
            n_treated, n_pre, format(n_obs, big.mark = ",")))
cat("Saved main_results.RData and diagnostics.json\n")
