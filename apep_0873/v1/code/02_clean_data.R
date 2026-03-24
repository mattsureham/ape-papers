# 02_clean_data.R — apep_0873: The Pill Pipeline
# Build state-year panel: disability rate + overdose deaths by drug type
source("00_packages.R")

data_dir <- "../data"

# ═══════════════════════════════════════════════════════════════════
# 1. Process CDC VSRR: annual state-level deaths by drug type
# ═══════════════════════════════════════════════════════════════════
cat("=== Processing CDC VSRR data ===\n")
cdc <- fread(file.path(data_dir, "cdc_vsrr_raw.csv"))

# Use December "12 month-ending" for each year as the annual total
# This gives the cumulative 12-month count ending in that month
cdc[, year := as.integer(year)]
cdc[, data_value := as.numeric(data_value)]

# Take December observation for each state-year-indicator (12-month rolling sum)
cdc_annual <- cdc[month == "December" & period == "12 month-ending"]

# Pivot indicators to wide format
indicators_keep <- c(
  "Number of Drug Overdose Deaths",
  "Opioids (T40.0-T40.4,T40.6)",
  "Natural & semi-synthetic opioids (T40.2)",
  "Synthetic opioids, excl. methadone (T40.4)",
  "Cocaine (T40.5)",
  "Heroin (T40.1)",
  "Psychostimulants with abuse potential (T43.6)",
  "Methadone (T40.3)"
)

cdc_wide <- dcast(cdc_annual[indicator %in% indicators_keep],
                   state + state_name + year ~ indicator,
                   value.var = "data_value",
                   fun.aggregate = function(x) x[1])

# Rename columns for clarity
setnames(cdc_wide, old = c(
  "Number of Drug Overdose Deaths",
  "Opioids (T40.0-T40.4,T40.6)",
  "Natural & semi-synthetic opioids (T40.2)",
  "Synthetic opioids, excl. methadone (T40.4)",
  "Cocaine (T40.5)",
  "Heroin (T40.1)",
  "Psychostimulants with abuse potential (T43.6)",
  "Methadone (T40.3)"
), new = c(
  "total_od_deaths", "opioid_deaths", "rx_opioid_deaths",
  "synthetic_deaths", "cocaine_deaths", "heroin_deaths",
  "stimulant_deaths", "methadone_deaths"
), skip_absent = TRUE)

cat("  CDC annual panel: ", nrow(cdc_wide), "state-years\n")
cat("  States:", length(unique(cdc_wide$state)), "\n")
cat("  Years:", paste(sort(unique(cdc_wide$year)), collapse = ", "), "\n")

# ═══════════════════════════════════════════════════════════════════
# 2. Load ACS disability data
# ═══════════════════════════════════════════════════════════════════
cat("\n=== Loading ACS disability data ===\n")
acs <- fread(file.path(data_dir, "acs_state_disability.csv"))
acs[, state_fips := sprintf("%02d", as.integer(state_fips))]
cat("  ACS rows:", nrow(acs), "\n")

# ═══════════════════════════════════════════════════════════════════
# 3. Load Census demographics
# ═══════════════════════════════════════════════════════════════════
cat("\n=== Loading Census demographics ===\n")
census <- fread(file.path(data_dir, "census_state.csv"))
census[, state_fips := sprintf("%02d", as.integer(state_fips))]
cat("  Census rows:", nrow(census), "\n")

# ═══════════════════════════════════════════════════════════════════
# 4. Load state FIPS crosswalk
# ═══════════════════════════════════════════════════════════════════
xwalk <- fread(file.path(data_dir, "state_fips_xwalk.csv"))

# ═══════════════════════════════════════════════════════════════════
# 5. Merge: CDC + ACS + Census
# ═══════════════════════════════════════════════════════════════════
cat("\n=== Merging datasets ===\n")

# Add state_fips to CDC data via crosswalk
cdc_wide <- merge(cdc_wide, xwalk, by.x = "state", by.y = "state_abbr", all.x = TRUE)

# Drop US total and territories without FIPS
cdc_wide <- cdc_wide[!is.na(state_fips)]

# Ensure consistent types for merge keys
cdc_wide[, state_fips := as.character(state_fips)]
acs[, state_fips := as.character(state_fips)]
census[, state_fips := as.character(state_fips)]
acs[, year := as.integer(year)]
census[, year := as.integer(year)]

# Merge ACS disability
panel <- merge(cdc_wide, acs[, .(state_fips, year, disability_rate, disabled_pop, total_pop)],
               by = c("state_fips", "year"), all.x = TRUE)

# Merge Census demographics
panel <- merge(panel, census[, .(state_fips, year, population, unemp_rate, median_income,
                                  median_age, pct_white, pct_black)],
               by = c("state_fips", "year"), all.x = TRUE)

cat("  Merged panel:", nrow(panel), "state-years\n")

# ═══════════════════════════════════════════════════════════════════
# 6. Construct per-capita rates (per 100,000)
# ═══════════════════════════════════════════════════════════════════
cat("\n=== Computing per-capita rates ===\n")

death_vars <- c("total_od_deaths", "opioid_deaths", "rx_opioid_deaths",
                "synthetic_deaths", "cocaine_deaths", "heroin_deaths",
                "stimulant_deaths", "methadone_deaths")

for (v in death_vars) {
  if (v %in% names(panel)) {
    rate_name <- gsub("_deaths$", "_rate", v)
    panel[, (rate_name) := get(v) / population * 100000]
  }
}

# Log transform key variables
panel[, log_opioid_rate := log(opioid_rate + 0.1)]
panel[, log_rx_opioid_rate := log(rx_opioid_rate + 0.1)]
panel[, log_synthetic_rate := log(synthetic_rate + 0.1)]
panel[, log_cocaine_rate := log(cocaine_rate + 0.1)]
panel[, log_disability := log(disability_rate)]

# ═══════════════════════════════════════════════════════════════════
# 7. Restrict to analysis sample
# ═══════════════════════════════════════════════════════════════════
cat("\n=== Restricting to analysis sample ===\n")

# Keep 50 states + DC with complete disability + mortality data
panel_clean <- panel[!is.na(disability_rate) & !is.na(opioid_rate) &
                     !is.na(population) & population > 0]

# Drop 2025 (incomplete)
panel_clean <- panel_clean[year <= 2024]

# Exclude territories (state_fips > 56, except DC=11)
panel_clean <- panel_clean[as.integer(state_fips) <= 56]

cat("  Final panel:", nrow(panel_clean), "state-year obs\n")
cat("  States:", length(unique(panel_clean$state_fips)), "\n")
cat("  Years:", paste(sort(unique(panel_clean$year)), collapse = ", "), "\n")

cat("\n  Summary statistics:\n")
cat("  Opioid death rate (per 100K):", round(mean(panel_clean$opioid_rate, na.rm = TRUE), 1), "\n")
cat("  Rx opioid rate:", round(mean(panel_clean$rx_opioid_rate, na.rm = TRUE), 1), "\n")
cat("  Synthetic rate:", round(mean(panel_clean$synthetic_rate, na.rm = TRUE), 1), "\n")
cat("  Cocaine rate:", round(mean(panel_clean$cocaine_rate, na.rm = TRUE), 1), "\n")
cat("  Disability rate:", round(mean(panel_clean$disability_rate, na.rm = TRUE), 4), "\n")
cat("  SD disability:", round(sd(panel_clean$disability_rate, na.rm = TRUE), 4), "\n")
cat("  Unemployment rate:", round(mean(panel_clean$unemp_rate, na.rm = TRUE), 4), "\n")

# ═══════════════════════════════════════════════════════════════════
# 8. Save
# ═══════════════════════════════════════════════════════════════════
fwrite(panel_clean, file.path(data_dir, "panel_clean.csv"))
cat("\n  Saved panel_clean.csv\n")
cat("=== Data cleaning complete ===\n")
