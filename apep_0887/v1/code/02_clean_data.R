# 02_clean_data.R — Clean and merge all data for apep_0887
source("00_packages.R")

cat("=== Cleaning data for apep_0887 ===\n")

# ============================================================
# 1. Load raw data
# ============================================================

# CBP — NAICS 562910 (Remediation Services) - primary outcome
cbp910 <- fread("../data/cbp_naics562910_raw.csv")
cat(sprintf("CBP 562910 raw: %d records\n", nrow(cbp910)))

# CBP — NAICS 562 (Waste Management & Remediation) - broader outcome
cbp562 <- fread("../data/cbp_naics562_raw.csv")
cat(sprintf("CBP 562 raw: %d records\n", nrow(cbp562)))

# EPA radon zones
epa_zones <- fread("../data/epa_radon_zones.csv")
epa_zones[, state_fips := sprintf("%02d", as.integer(state_fips))]

# RRNC adoption dates
rrnc <- fread("../data/rrnc_adoption_dates.csv")
rrnc[, state_fips := sprintf("%02d", as.integer(state_fips))]

# ============================================================
# 2. Clean CBP 562910 (Remediation Services)
# ============================================================
cat("\n--- Cleaning CBP 562910 ---\n")

# Standardize column names across NAICS vintages
naics_cols <- names(cbp910)[grepl("NAICS", names(cbp910))]
for (nc in naics_cols) {
  if (nc != "naics") setnames(cbp910, nc, "naics", skip_absent = TRUE)
}

cbp910[, `:=`(
  estab = as.numeric(ESTAB),
  emp = as.numeric(EMP),
  payroll = as.numeric(PAYANN),
  year = as.integer(year),
  state_fips = sprintf("%02d", as.integer(state)),
  county_fips = sprintf("%03d", as.integer(county))
)]
cbp910[, fips := paste0(state_fips, county_fips)]

# Drop rows with missing employment (suppressed)
cbp910_clean <- cbp910[!is.na(estab), .(
  fips, state_fips, county_fips, year,
  estab_rem = estab,
  emp_rem = emp,
  payroll_rem = payroll
)]

cat(sprintf("CBP 562910 clean: %d county-years, %d unique counties\n",
            nrow(cbp910_clean), uniqueN(cbp910_clean$fips)))

# ============================================================
# 3. Clean CBP 562 (Broader Waste/Remediation)
# ============================================================
cat("\n--- Cleaning CBP 562 ---\n")

naics_cols2 <- names(cbp562)[grepl("NAICS", names(cbp562))]
for (nc in naics_cols2) {
  if (nc != "naics") setnames(cbp562, nc, "naics", skip_absent = TRUE)
}

cbp562[, `:=`(
  estab = as.numeric(ESTAB),
  emp = as.numeric(EMP),
  payroll = as.numeric(PAYANN),
  year = as.integer(year),
  state_fips = sprintf("%02d", as.integer(state)),
  county_fips = sprintf("%03d", as.integer(county))
)]
cbp562[, fips := paste0(state_fips, county_fips)]

cbp562_clean <- cbp562[!is.na(estab), .(
  fips, state_fips, county_fips, year,
  estab_562 = estab,
  emp_562 = emp,
  payroll_562 = payroll
)]

cat(sprintf("CBP 562 clean: %d county-years, %d unique counties\n",
            nrow(cbp562_clean), uniqueN(cbp562_clean$fips)))

# ============================================================
# 4. Build Analysis Panel
# ============================================================
cat("\n--- Building panel ---\n")

# Use the broader NAICS 562 as the primary panel frame (more coverage)
# Merge in NAICS 562910 detail where available
panel <- merge(cbp562_clean, cbp910_clean,
               by = c("fips", "state_fips", "county_fips", "year"),
               all.x = TRUE)

# Fill missing 562910 with zeros (county has no remediation-specific firms)
panel[is.na(estab_rem), estab_rem := 0]
panel[is.na(emp_rem), emp_rem := 0]
panel[is.na(payroll_rem), payroll_rem := 0]

# Merge EPA zones
panel <- merge(panel, epa_zones, by = "state_fips", all.x = TRUE)

# Merge RRNC treatment dates
panel <- merge(panel, rrnc[, .(state_fips, adoption_year)],
               by = "state_fips", all.x = TRUE)

# ============================================================
# 5. Create Treatment Variables
# ============================================================
cat("\n--- Creating treatment variables ---\n")

panel[, `:=`(
  # Binary indicators
  treated = as.integer(!is.na(adoption_year)),
  post = as.integer(!is.na(adoption_year) & year >= adoption_year),

  # Cohort for CS-DiD (0 = never treated)
  cohort = ifelse(is.na(adoption_year), 0L, as.integer(adoption_year)),

  # Relative time
  rel_time = ifelse(!is.na(adoption_year),
                    as.integer(year - adoption_year), NA_integer_),

  # Zone indicators
  zone1 = as.integer(epa_zone == 1),
  zone2 = as.integer(epa_zone == 2),
  zone3 = as.integer(epa_zone == 3)
)]

# Log outcomes
panel[, `:=`(
  log_emp_562 = log(emp_562 + 1),
  log_estab_562 = log(estab_562 + 1),
  log_emp_rem = log(emp_rem + 1),
  log_estab_rem = log(estab_rem + 1),
  log_payroll_rem = log(payroll_rem + 1),
  # Remediation share of total waste management
  rem_share = ifelse(emp_562 > 0, emp_rem / emp_562, 0)
)]

# Restrict to pre-2017 for balanced panel (CBP methodology change)
# But keep full sample for robustness
panel_balanced <- panel[year <= 2016]

cat(sprintf("\nFull panel: %d county-years, %d counties, %d-%d\n",
            nrow(panel), uniqueN(panel$fips),
            min(panel$year), max(panel$year)))
cat(sprintf("Balanced panel (≤2016): %d county-years, %d counties\n",
            nrow(panel_balanced), uniqueN(panel_balanced$fips)))

# Treatment/control breakdown
cat(sprintf("\nTreated states: %d (%d counties)\n",
            uniqueN(panel$state_fips[panel$treated == 1]),
            uniqueN(panel$fips[panel$treated == 1])))
cat(sprintf("Never-treated states: %d (%d counties)\n",
            uniqueN(panel$state_fips[panel$treated == 0]),
            uniqueN(panel$fips[panel$treated == 0])))
cat(sprintf("Zone 1 counties: %d\n", uniqueN(panel$fips[panel$zone1 == 1])))
cat(sprintf("Zone 2 counties: %d\n", uniqueN(panel$fips[panel$zone2 == 1])))
cat(sprintf("Zone 3 counties: %d\n", uniqueN(panel$fips[panel$zone3 == 1])))

# Pre-period length (before earliest adoption in 2007)
n_pre <- length(unique(panel$year[panel$year < 2007]))
cat(sprintf("Pre-periods before earliest adoption (2007): %d years\n", n_pre))

# ============================================================
# 6. Save
# ============================================================
fwrite(panel, "../data/analysis_panel.csv")
fwrite(panel_balanced, "../data/analysis_panel_balanced.csv")

cat("\nSaved analysis panels to ../data/\n")
cat("=== Cleaning complete ===\n")
