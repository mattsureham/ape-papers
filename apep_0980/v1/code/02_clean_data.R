# =============================================================================
# 02_clean_data.R — Construct treatment and analysis panel
# apep_0980: IRA Energy Community Bonus Credit and County-Level Labor Markets
# =============================================================================

source("00_packages.R")

DATA_DIR <- "../data"

# =============================================================================
# Load raw data
# =============================================================================
cat("=== Loading data ===\n")
qwi <- arrow::read_parquet(file.path(DATA_DIR, "qwi_sectors.parquet"))
setDT(qwi)

qwi_total <- arrow::read_parquet(file.path(DATA_DIR, "qwi_total.parquet"))
setDT(qwi_total)

ff_share <- fread(file.path(DATA_DIR, "ff_employment_share.csv"))
unemp <- fread(file.path(DATA_DIR, "county_unemployment.csv"))
nat_unemp <- fread(file.path(DATA_DIR, "national_unemployment.csv"))

cat(sprintf("  QWI sectors: %s rows\n", format(nrow(qwi), big.mark = ",")))
cat(sprintf("  FF share: %d counties\n", nrow(ff_share)))
cat(sprintf("  Unemployment: %d county-years, %d counties\n",
            nrow(unemp), uniqueN(unemp$county_fips)))

# =============================================================================
# Construct treatment: Energy Community FFE designation
# =============================================================================
cat("\n=== Constructing treatment ===\n")

# Step 1: Fossil fuel employment criterion (predetermined, time-invariant)
# Counties with avg mining employment share >= 0.17% (2018-2022)
ff_share[, ff_eligible := ff_emp_share >= 0.0017]
cat(sprintf("  FF-eligible counties: %d / %d\n",
            sum(ff_share$ff_eligible), nrow(ff_share)))

# Step 2: Unemployment criterion (time-varying, annual)
# County unemployment >= national average in the qualifying year
unemp <- merge(unemp, nat_unemp, by = "year")
unemp[, unemp_eligible := unemp_rate >= national_unemp_rate]

# Merge with FF eligibility
unemp_ff <- merge(unemp, ff_share[, .(county_fips, ff_eligible, ff_emp_share)],
                  by = "county_fips")

# Energy community designation: both criteria met
unemp_ff[, energy_community := ff_eligible & unemp_eligible]

cat(sprintf("  Unemployment data available for %d FF-eligible counties\n",
            sum(unemp_ff[year == 2022]$ff_eligible, na.rm = TRUE)))

# Treatment timing:
# - IRS Notice 2023-29 published April 2023 → treatment starts Q2 2023
# - 2023 designation based on 2022 unemployment data
# - 2024 designation based on 2023 unemployment data
# Treatment year: use unemployment from PRIOR year for designation
unemp_ff[, designation_year := year + 1]  # 2022 unemp → 2023 designation

# Create treatment panel: county × designation year
treat_2023 <- unemp_ff[year == 2022 & ff_eligible == TRUE,
  .(county_fips, treated_2023 = energy_community, unemp_2022 = unemp_rate,
    ff_emp_share)]
treat_2024 <- unemp_ff[year == 2023 & ff_eligible == TRUE,
  .(county_fips, treated_2024 = energy_community, unemp_2023 = unemp_rate)]

treat <- merge(treat_2023, treat_2024[, .(county_fips, treated_2024, unemp_2023)],
               by = "county_fips", all.x = TRUE)

# Treatment cohorts:
# 1. Always treated (2023 and 2024)
# 2. Treated 2023 only (lost eligibility in 2024)
# 3. Treated 2024 only (gained eligibility in 2024)
# 4. Never treated among FF-eligible (unemployment always below threshold)
treat[, cohort := fcase(
  treated_2023 & !is.na(treated_2024) & treated_2024, "always_treated",
  treated_2023 & (is.na(treated_2024) | !treated_2024), "treated_2023_only",
  !treated_2023 & !is.na(treated_2024) & treated_2024, "treated_2024_only",
  default = "never_treated_ff"
)]

cat("\nTreatment cohorts among FF-eligible counties:\n")
print(treat[, .N, by = cohort][order(-N)])

# For Callaway-Sant'Anna: first treatment quarter
# Q2 2023 = 2023.25 for 2023 designees, Q2 2024 = 2024.25 for 2024-only
treat[, first_treat_qtr := fcase(
  cohort %in% c("always_treated", "treated_2023_only"), 20232,
  cohort == "treated_2024_only", 20242,
  default = 0  # never treated
)]

# =============================================================================
# Build analysis panel: county × quarter
# =============================================================================
cat("\n=== Building analysis panel ===\n")

# Create time variable: year * 10 + quarter (e.g., 20181, 20182, ...)
qwi[, time := year * 10 + quarter]
qwi_total[, time := year * 10 + quarter]

# For DiD analysis, work with key sectors
# Focus on: Construction (23), Utilities (22), Mining (21)
# Also include: Manufacturing (31-33), Retail (44-45), Accommodation (72) for placebo

# Merge treatment assignment
panel <- merge(qwi, ff_share[, .(county_fips, ff_eligible, ff_emp_share)],
               by = "county_fips", all.x = TRUE)
panel[is.na(ff_eligible), ff_eligible := FALSE]

# Add treatment cohort (for FF-eligible counties with unemployment data)
panel <- merge(panel, treat[, .(county_fips, cohort, first_treat_qtr,
                                 treated_2023, unemp_2022)],
               by = "county_fips", all.x = TRUE)

# Non-FF counties get "never_treated" designation
panel[is.na(cohort) & ff_eligible == FALSE, cohort := "never_treated"]
panel[is.na(cohort), cohort := "no_unemp_data"]  # FF but no unemployment data
panel[is.na(first_treat_qtr), first_treat_qtr := 0]

# Binary treatment indicator: treated in current period
panel[, treated := 0L]
panel[first_treat_qtr > 0 & time >= first_treat_qtr, treated := 1L]

# Log employment (handle zeros and NAs)
panel[, log_emp := log(Emp + 1)]
panel[, log_emp_end := log(EmpEnd + 1)]
panel[, log_earn := log(EarnS + 1)]
panel[, log_hires := log(HirA + 1)]

# State FIPS (first 2 digits)
panel[, state_fips := county_fips %/% 1000]

cat(sprintf("  Panel: %s rows, %d counties, %d quarters\n",
            format(nrow(panel), big.mark = ","),
            uniqueN(panel$county_fips),
            uniqueN(panel$time)))

cat("\nPanel by treatment status:\n")
print(panel[, .(n_counties = uniqueN(county_fips)), by = cohort][order(-n_counties)])

cat("\nPanel by sector:\n")
print(panel[, .(n_obs = .N, mean_emp = mean(Emp, na.rm = TRUE)), by = industry])

# =============================================================================
# Save analysis panel
# =============================================================================
arrow::write_parquet(panel, file.path(DATA_DIR, "analysis_panel.parquet"))
fwrite(treat, file.path(DATA_DIR, "treatment_assignment.csv"))

cat("\n=== Data cleaning complete ===\n")
cat(sprintf("  Analysis panel saved: %s rows\n", format(nrow(panel), big.mark = ",")))
cat(sprintf("  Treated counties (2023): %d\n",
            nrow(treat[treated_2023 == TRUE])))
cat(sprintf("  Never-treated (FF-eligible): %d\n",
            nrow(treat[cohort == "never_treated_ff"])))
cat(sprintf("  Never-treated (non-FF): %d\n",
            uniqueN(panel[cohort == "never_treated"]$county_fips)))
