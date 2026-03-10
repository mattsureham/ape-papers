# ============================================================================
# 02_clean_data.R — Merge datasets, construct analysis variables
# APEP Paper apep_0566
# ============================================================================

source("00_packages.R")

data_dir <- "../data/"

# ============================================================================
# 1. Load data
# ============================================================================

cdc_panel    <- fread(paste0(data_dir, "cdc_panel.csv"))
reform_dates <- fread(paste0(data_dir, "reform_dates.csv"))
covariates   <- fread(paste0(data_dir, "acs_covariates.csv"))

cat("CDC panel:", nrow(cdc_panel), "rows\n")
cat("Covariates:", nrow(covariates), "rows\n")

# ============================================================================
# 2. Merge reform treatment
# ============================================================================

cat("Merging reform treatment...\n")

panel <- merge(cdc_panel, reform_dates, by = "state_abbr", all.x = TRUE)

# Create treatment variables
panel[, treated_ever := !is.na(reform_year)]
panel[, treated := as.integer(treated_ever & year >= reform_year)]
panel[, gvar := ifelse(treated_ever, reform_year, 0L)]

# Relative time
panel[treated_ever == TRUE, rel_time := year - reform_year]
panel[treated_ever == FALSE, rel_time := NA_integer_]

cat("Treatment summary:\n")
cat("  Ever-treated states:", uniqueN(panel[treated_ever == TRUE]$state_fips), "\n")
cat("  Never-treated states:", uniqueN(panel[treated_ever == FALSE]$state_fips), "\n")
cat("  Treated state-years:", sum(panel$treated, na.rm = TRUE), "\n")

# ============================================================================
# 3. Merge ACS covariates
# ============================================================================

cat("Merging ACS covariates...\n")

panel <- merge(panel, covariates, by = c("state_fips", "year"), all.x = TRUE)

# Interpolate missing covariate years (ACS starts 2005, CDC starts 1999)
for (st in unique(panel$state_fips)) {
  for (col in c("median_income", "poverty_rate", "pct_white")) {
    if (col %in% names(panel)) {
      vals <- panel[state_fips == st, get(col)]
      yrs <- panel[state_fips == st]$year
      if (any(!is.na(vals))) {
        panel[state_fips == st, (col) := approx(yrs, vals, yrs, rule = 2)$y]
      }
    }
  }
}

# ============================================================================
# 4. Construct outcome variables
# ============================================================================

cat("Constructing outcome variables...\n")

panel[, drug_od_rate := as.numeric(age_adjusted_rate)]
panel[, drug_od_deaths := as.numeric(deaths)]
panel[, pop := as.numeric(population)]
panel[, log_drug_od_rate := log(drug_od_rate + 0.1)]
panel[, crude_rate := as.numeric(crude_death_rate)]

# ============================================================================
# 5. Pre-treatment characteristics for heterogeneity
# ============================================================================

cat("Computing pre-treatment characteristics...\n")

pre_avg <- panel[year >= 2009 & year <= 2013,
                 .(pre_drug_rate = mean(drug_od_rate, na.rm = TRUE),
                   pre_drug_deaths = mean(drug_od_deaths, na.rm = TRUE)),
                 by = state_fips]
panel <- merge(panel, pre_avg, by = "state_fips", all.x = TRUE)

med_pre_rate <- median(pre_avg$pre_drug_rate, na.rm = TRUE)
panel[, high_pre_drug := as.integer(pre_drug_rate > med_pre_rate)]

# ============================================================================
# 6. Cohort summaries
# ============================================================================

cohort_counts <- panel[treated_ever == TRUE, .(n_states = uniqueN(state_fips)), by = reform_year]
setorder(cohort_counts, reform_year)
cat("\nCohort sizes:\n")
print(cohort_counts)

# ============================================================================
# 7. Flag states vs DC
# ============================================================================

panel[, is_state := state_abbr != "DC"]

# Sort
setorder(panel, state_fips, year)

# ============================================================================
# 8. Summary and save
# ============================================================================

cat("\n=== Final Panel Summary ===\n")
cat("Observations:", nrow(panel), "\n")
cat("States:", uniqueN(panel$state_fips), "\n")
cat("Years:", min(panel$year), "-", max(panel$year), "\n")
cat("Treated states:", uniqueN(panel[treated_ever == TRUE]$state_fips), "\n")
cat("Control states:", uniqueN(panel[treated_ever == FALSE]$state_fips), "\n")
cat("Drug OD rate — Mean:", round(mean(panel$drug_od_rate, na.rm = TRUE), 2),
    "SD:", round(sd(panel$drug_od_rate, na.rm = TRUE), 2), "\n")

fwrite(panel, paste0(data_dir, "analysis_panel.csv"))

# Summary stats by group
sumstats <- panel[year >= 2005, .(
  mean_drug_od_rate = mean(drug_od_rate, na.rm = TRUE),
  sd_drug_od_rate = sd(drug_od_rate, na.rm = TRUE),
  mean_deaths = mean(drug_od_deaths, na.rm = TRUE),
  mean_pop = mean(pop, na.rm = TRUE),
  n_obs = .N
), by = .(group = ifelse(treated_ever, "Treated", "Control"))]

cat("\nSummary by treatment group:\n")
print(sumstats)

fwrite(sumstats, paste0(data_dir, "summary_by_group.csv"))

cat("\nData cleaning complete.\n")
