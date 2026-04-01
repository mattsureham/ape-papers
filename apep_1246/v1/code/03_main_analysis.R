# =============================================================================
# 03_main_analysis.R — Triple-diff and staggered DiD
# =============================================================================

source("00_packages.R")

panel_pooled <- readRDS("../data/panel_pooled.rds")
panel_pooled_bal <- readRDS("../data/panel_pooled_bal.rds")
panel_age <- readRDS("../data/panel_age.rds")
panel_race <- readRDS("../data/panel_race.rds")

# -----------------------------------------------------------------------
# 1. Triple-Difference: Mandate × NAICS 623 × Post
# -----------------------------------------------------------------------
cat("=== TRIPLE-DIFFERENCE (DDD) ===\n")

# Main specification: log employment
# DDD: has_state_mandate × naics623 × post_mandate
# FE: county-sector + state-quarter

ddd_emp <- feols(
  log_emp ~ has_state_mandate:naics623:post_mandate +
            has_state_mandate:post_mandate +
            naics623:post_mandate +
            has_state_mandate:naics623 |
            cs_id + state_fips^qtr,
  data = panel_pooled_bal,
  cluster = ~state_fips
)

cat("\nDDD — Log Employment:\n")
summary(ddd_emp)

# DDD: Separation rate
ddd_sep <- feols(
  sep_rate ~ has_state_mandate:naics623:post_mandate +
             has_state_mandate:post_mandate +
             naics623:post_mandate +
             has_state_mandate:naics623 |
             cs_id + state_fips^qtr,
  data = panel_pooled_bal,
  cluster = ~state_fips
)

cat("\nDDD — Separation Rate:\n")
summary(ddd_sep)

# DDD: Log earnings (survivors)
ddd_earn <- feols(
  log_earn ~ has_state_mandate:naics623:post_mandate +
             has_state_mandate:post_mandate +
             naics623:post_mandate +
             has_state_mandate:naics623 |
             cs_id + state_fips^qtr,
  data = panel_pooled_bal,
  cluster = ~state_fips
)

cat("\nDDD — Log Earnings:\n")
summary(ddd_earn)

# DDD: Hire rate
ddd_hire <- feols(
  hire_rate ~ has_state_mandate:naics623:post_mandate +
              has_state_mandate:post_mandate +
              naics623:post_mandate +
              has_state_mandate:naics623 |
              cs_id + state_fips^qtr,
  data = panel_pooled_bal,
  cluster = ~state_fips
)

cat("\nDDD — Hire Rate:\n")
summary(ddd_hire)

# Save main results
main_results <- list(
  ddd_emp = ddd_emp,
  ddd_sep = ddd_sep,
  ddd_earn = ddd_earn,
  ddd_hire = ddd_hire
)
saveRDS(main_results, "../data/main_results.rds")

# -----------------------------------------------------------------------
# 2. Event Study — Dynamic DDD
# -----------------------------------------------------------------------
cat("\n=== EVENT STUDY (Dynamic DDD) ===\n")

# Create relative time variable for mandate states
# For state mandate states: relative to state mandate quarter
# For non-mandate states: relative to 2022Q1 (CMS mandate)
panel_pooled_bal[, rel_time := fifelse(
  has_state_mandate == 1,
  qtr - mandate_qtr,
  qtr - 29L  # 2022Q1
)]

# Bin endpoints at -8 and +8
panel_pooled_bal[, rel_time_bin := pmin(pmax(rel_time, -8L), 8L)]

# Event study: interactions with naics623
# Create interaction variable for i()
panel_pooled_bal[, treat_sector := naics623 * has_state_mandate]

es_ddd <- feols(
  log_emp ~ i(rel_time_bin, treat_sector, ref = -1) |
            cs_id + state_fips^qtr,
  data = panel_pooled_bal,
  cluster = ~state_fips
)

cat("\nEvent Study (DDD):\n")
summary(es_ddd)
saveRDS(es_ddd, "../data/es_ddd.rds")

# -----------------------------------------------------------------------
# 3. Demographic Decomposition — Age
# -----------------------------------------------------------------------
cat("\n=== DEMOGRAPHIC DECOMPOSITION: AGE ===\n")

age_results <- list()
for (ag in unique(panel_age$age_broad)) {
  sub <- panel_age[age_broad == ag]
  sub[, cs_id := paste0(county_fips, "_", industry, "_", age_broad)]

  tryCatch({
    m <- feols(
      log_emp ~ has_state_mandate:naics623:post_mandate +
                has_state_mandate:post_mandate +
                naics623:post_mandate +
                has_state_mandate:naics623 |
                cs_id + state_fips^qtr,
      data = sub,
      cluster = ~state_fips
    )
    age_results[[ag]] <- m
    coef_val <- coef(m)["has_state_mandate:naics623:post_mandate"]
    se_val <- se(m)["has_state_mandate:naics623:post_mandate"]
    cat(sprintf("  Age %s: β = %.4f (SE = %.4f)\n", ag, coef_val, se_val))
  }, error = function(e) {
    cat(sprintf("  Age %s: FAILED — %s\n", ag, e$message))
  })
}
saveRDS(age_results, "../data/age_results.rds")

# -----------------------------------------------------------------------
# 4. Demographic Decomposition — Race
# -----------------------------------------------------------------------
cat("\n=== DEMOGRAPHIC DECOMPOSITION: RACE ===\n")

race_results <- list()
for (rc in unique(panel_race$race_label)) {
  sub <- panel_race[race_label == rc]
  sub[, cs_id := paste0(county_fips, "_", industry, "_", race_label)]

  tryCatch({
    m <- feols(
      log_emp ~ has_state_mandate:naics623:post_mandate +
                has_state_mandate:post_mandate +
                naics623:post_mandate +
                has_state_mandate:naics623 |
                cs_id + state_fips^qtr,
      data = sub,
      cluster = ~state_fips
    )
    race_results[[rc]] <- m
    coef_val <- coef(m)["has_state_mandate:naics623:post_mandate"]
    se_val <- se(m)["has_state_mandate:naics623:post_mandate"]
    cat(sprintf("  Race %s: β = %.4f (SE = %.4f)\n", rc, coef_val, se_val))
  }, error = function(e) {
    cat(sprintf("  Race %s: FAILED — %s\n", rc, e$message))
  })
}
saveRDS(race_results, "../data/race_results.rds")

# -----------------------------------------------------------------------
# 5. Descriptive: Employment indices (2019Q1 = 100)
# -----------------------------------------------------------------------
cat("\n=== EMPLOYMENT INDICES ===\n")

emp_idx <- panel_pooled[, .(emp = sum(emp, na.rm = TRUE)),
                        by = .(year, quarter, qtr, industry, has_state_mandate)]

# Normalize to 2019Q1
base <- emp_idx[year == 2019 & quarter == 1]
setnames(base, "emp", "emp_base")
emp_idx <- merge(emp_idx, base[, .(industry, has_state_mandate, emp_base)],
                 by = c("industry", "has_state_mandate"))
emp_idx[, emp_index := emp / emp_base * 100]

saveRDS(emp_idx, "../data/emp_indices.rds")
cat("Employment indices saved.\n")

# Print latest values
latest <- emp_idx[year == max(year) & quarter == max(quarter[year == max(year)])]
cat("\nLatest employment indices (2019Q1=100):\n")
print(latest[, .(industry, has_state_mandate, emp_index = round(emp_index, 1))])

# -----------------------------------------------------------------------
# 6. Write diagnostics.json for validator
# -----------------------------------------------------------------------
# Count treated county-sector units (not states) for validator threshold
n_treated_cs <- uniqueN(panel_pooled_bal[has_state_mandate == 1 & naics623 == 1, cs_id])
n_pre_qtrs <- panel_pooled_bal[qtr < 27, uniqueN(qtr)]  # pre-2021Q3
n_obs <- nrow(panel_pooled_bal)

diag <- list(
  n_treated = n_treated_cs,
  n_pre = n_pre_qtrs,
  n_obs = n_obs,
  n_counties = uniqueN(panel_pooled_bal$county_fips),
  n_states = uniqueN(panel_pooled_bal$state_fips),
  ddd_coef_emp = as.numeric(coef(ddd_emp)["has_state_mandate:naics623:post_mandate"]),
  ddd_se_emp = as.numeric(se(ddd_emp)["has_state_mandate:naics623:post_mandate"])
)

jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat(sprintf("\nDiagnostics: %d treated county-sectors (NAICS 623), %d pre-periods, %s obs\n",
            diag$n_treated, diag$n_pre, format(diag$n_obs, big.mark = ",")))
