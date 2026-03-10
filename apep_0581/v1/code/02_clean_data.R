# 02_clean_data.R — Build sector × country × year panel from Eurostat air emissions
# APEP-0581: Technology Standards and Facility-Level Pollution

source("00_packages.R")

data_dir <- "../data/"

# ============================================================================
# PART 1: Load raw data
# ============================================================================

bat_info <- fread(file.path(data_dir, "bat_conclusions.csv"))
air_raw <- fread(file.path(data_dir, "eurostat_air_emissions.csv"))

cat("Eurostat air emissions:", nrow(air_raw), "records\n")
cat("Columns:", paste(names(air_raw), collapse = ", "), "\n\n")

# Examine structure
cat("airpol (pollutants):", uniqueN(air_raw$airpol), "\n")
cat("nace_r2:", uniqueN(air_raw$nace_r2), "\n")
cat("geo:", uniqueN(air_raw$geo), "\n")
cat("unit:", paste(unique(air_raw$unit), collapse=", "), "\n")
cat("time range:", range(as.integer(air_raw$TIME_PERIOD), na.rm = TRUE), "\n")

cat("\nTop NACE sectors:\n")
print(air_raw[, .N, by = nace_r2][order(-N)][1:30])

cat("\nPollutants:\n")
print(air_raw[, .N, by = airpol][order(-N)])

# ============================================================================
# PART 2: Map NACE Rev.2 to BAT sectors
# ============================================================================

# IED-regulated NACE sectors — use codes that exist in Eurostat air emissions
# Available codes: single-letter (C, D, E) and Cxx or Cxxx level
nace_bat_map <- data.table(
  nace_r2 = c(
    "C24",    # Manufacture of basic metals (Iron/Steel — largest share)
    "C23",    # Other non-metallic mineral products (Cement + Glass)
    "C17",    # Manufacture of paper products
    "C19",    # Coke and refined petroleum
    "C20",    # Chemicals and chemical products (Chlor-alkali subset)
    "D",      # Electricity, gas, steam (LCP)
    "E",      # Water supply, sewerage, waste
    "C10",    # Food products
    "C11",    # Beverages
    "C15"     # Leather products (tanning)
  ),
  bat_sector = c(
    "Iron and Steel Production",
    "Production of Cement, Lime and Magnesium Oxide",
    "Production of Pulp, Paper and Board",
    "Refining of Mineral Oil and Gas",
    "Production of Chlor-alkali",
    "Large Combustion Plants",
    "Waste Treatment",
    "Food, Drink and Milk Industries",
    "Food, Drink and Milk Industries",
    "Tanning of Hides and Skins"
  )
)

# Match — use the most granular NACE code available
air_matched <- merge(air_raw, nace_bat_map, by = "nace_r2", all.x = FALSE)
cat("\nMatched to BAT sectors:", nrow(air_matched), "of", nrow(air_raw), "records\n")
cat("BAT sectors represented:", uniqueN(air_matched$bat_sector), "\n")

# ============================================================================
# PART 3: Key pollutants for analysis
# ============================================================================

# Focus on regulated air pollutants
key_pollutants <- c("NOX", "SOX_SO2E", "CO2", "PM10", "PM2_5", "CO", "NMVOC", "NH3",
                     "CH4", "N2O")

# Filter to key pollutants (check which exist)
avail_polls <- intersect(key_pollutants, unique(air_matched$airpol))
cat("\nAvailable key pollutants:", paste(avail_polls, collapse = ", "), "\n")

if (length(avail_polls) == 0) {
  # Show what pollutants are available
  cat("Available pollutants in matched data:\n")
  print(air_matched[, .N, by = airpol][order(-N)])
  avail_polls <- head(air_matched[, .N, by = airpol][order(-N)]$airpol, 10)
}

air_filtered <- air_matched[airpol %in% avail_polls]
cat("After pollutant filter:", nrow(air_filtered), "records\n")

# ============================================================================
# PART 4: Filter to EU member states
# ============================================================================

eu27 <- c("AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR",
          "DE", "EL", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL",
          "PL", "PT", "RO", "SK", "SI", "ES", "SE")

# Also include EEA countries for more variation
eea <- c(eu27, "NO", "IS", "LI")
# Greece: EL in Eurostat, GR in ISO
# UK left in 2020 — include for pre-2020 data
extended <- c(eea, "UK", "CH")

# Filter to 2-letter country codes (exclude aggregate codes like EU27)
air_filtered[, geo_len := nchar(geo)]
air_eu <- air_filtered[geo %in% extended]
cat("EU/EEA countries:", uniqueN(air_eu$geo), "\n")
cat("Countries:", paste(sort(unique(air_eu$geo)), collapse = ", "), "\n")

# ============================================================================
# PART 5: Create sector × country × year panel
# ============================================================================

air_eu[, year := as.integer(TIME_PERIOD)]
air_eu[, values := as.numeric(values)]

# Drop missing values
air_eu <- air_eu[!is.na(values) & !is.na(year)]

# Create panel: aggregate to bat_sector × country × year × pollutant
sector_panel <- air_eu[, .(
  emissions = sum(values, na.rm = TRUE),
  n_nace_codes = uniqueN(nace_r2)
), by = .(bat_sector, country = geo, year, pollutant = airpol, unit)]

cat("\nSector panel:", nrow(sector_panel), "observations\n")
cat("Year range:", range(sector_panel$year, na.rm = TRUE), "\n")
cat("Countries:", uniqueN(sector_panel$country), "\n")
cat("BAT sectors:", uniqueN(sector_panel$bat_sector), "\n")

# ============================================================================
# PART 6: Create wide panel (one row per sector × country × year)
# ============================================================================

# Primary pollutant: use NOX as the main outcome
# Also create columns for SOX, CO2, PM10/PM2.5

nox_pattern <- "NOX"
sox_pattern <- "SOX_SO2E"
co2_pattern <- "CO2"
pm_pattern <- "PM10|PM2_5"

# Identify actual pollutant names in data
nox_name <- grep(nox_pattern, unique(sector_panel$pollutant), value = TRUE)[1]
sox_name <- grep(sox_pattern, unique(sector_panel$pollutant), value = TRUE)[1]
co2_name <- grep(co2_pattern, unique(sector_panel$pollutant), value = TRUE)[1]
pm_name <- grep(pm_pattern, unique(sector_panel$pollutant), value = TRUE)[1]

cat("\nPollutant mapping:\n")
cat("  NOx:", nox_name, "\n")
cat("  SOx:", sox_name, "\n")
cat("  CO2:", co2_name, "\n")
cat("  PM:", pm_name, "\n")

# Create wide panel
wide_panel <- sector_panel[pollutant == nox_name,
  .(nox_tonnes = sum(emissions, na.rm = TRUE)),
  by = .(bat_sector, country, year)]

for (poll_name in c(sox_name, co2_name, pm_name)) {
  if (!is.na(poll_name)) {
    col <- switch(poll_name,
      "SOX_SO2E" = "sox_tonnes", "SOX" = "sox_tonnes",
      "CO2" = "co2_tonnes",
      "PM10" = "pm_tonnes", "PM2_5" = "pm_tonnes",
      paste0(tolower(poll_name), "_tonnes"))

    poll_data <- sector_panel[pollutant == poll_name,
      .(temp = sum(emissions, na.rm = TRUE)),
      by = .(bat_sector, country, year)]
    setnames(poll_data, "temp", col)
    wide_panel <- merge(wide_panel, poll_data,
                         by = c("bat_sector", "country", "year"), all.x = TRUE)
  }
}

# ============================================================================
# PART 7: Merge with BAT timing and create treatment variables
# ============================================================================

panel <- merge(wide_panel,
               bat_info[, .(bat_sector, bat_adopted, compliance_deadline, bat_year, compliance_year)],
               by = "bat_sector", all.x = TRUE)

# Treatment indicators
panel[, post_bat := as.integer(!is.na(compliance_year) & year >= compliance_year)]
panel[, post_bat_adoption := as.integer(!is.na(bat_year) & year >= bat_year)]
panel[, first_treat := fifelse(is.na(compliance_year), 0L, compliance_year)]

# Create sector-country ID for fixed effects
panel[, sector_country := paste(bat_sector, country, sep = "_")]

# Log-transform emissions
emission_cols <- grep("_tonnes$", names(panel), value = TRUE)
for (col in emission_cols) {
  panel[is.na(get(col)), (col) := 0]
  panel[, paste0("log_", col) := log(get(col) + 1)]
}

# ============================================================================
# PART 8: Summary and validation
# ============================================================================

cat("\n=== PANEL SUMMARY ===\n")
cat("Observations:", nrow(panel), "\n")
cat("Sector × Country units:", uniqueN(panel$sector_country), "\n")
cat("Countries:", uniqueN(panel$country), "\n")
cat("BAT sectors:", uniqueN(panel$bat_sector), "\n")
cat("Year range:", range(panel$year, na.rm = TRUE), "\n")
cat("Treatment distribution:\n")
print(panel[, .N, by = post_bat])

cat("\nEmission columns:\n")
for (col in grep("^log_", names(panel), value = TRUE)) {
  cat(sprintf("  %s: N=%d, mean=%.2f, sd=%.2f\n",
              col, sum(!is.na(panel[[col]])),
              mean(panel[[col]], na.rm = TRUE),
              sd(panel[[col]], na.rm = TRUE)))
}

# Treatment timing by sector
timing <- panel[, .(
  n_countries = uniqueN(country),
  n_obs = .N,
  year_range = paste(range(year, na.rm = TRUE), collapse = "-"),
  mean_nox = mean(nox_tonnes, na.rm = TRUE)
), by = .(bat_sector, bat_year, compliance_year)][order(bat_year)]

cat("\n=== TREATMENT TIMING ===\n")
print(timing)

# ============================================================================
# PART 9: Also prepare E-PRTR facility-level data (supplementary)
# ============================================================================

eprtr_raw <- fread(file.path(data_dir, "eprtr_raw.csv"))
# Save a clean version for supplementary facility-level analysis
eprtr_clean <- eprtr_raw[countryCode %in% extended & !is.na(reportingYear), .(
  facility_id = fifelse(nchar(localId) > 0, localId,
                         fifelse(nchar(identifier) > 0, identifier,
                                 as.character(facilityReportId))),
  country = countryCode,
  year = as.integer(reportingYear),
  activity = EPRTRAnnexIMainActivity,
  pollutant = pollutant,
  quantity_kg = as.numeric(totalPollutantQuantityKg),
  medium = mediumCode,
  facility_name = facilityName,
  nuts2 = NUTS2,
  nuts3 = NUTS3
)]

if (nrow(eprtr_clean) > 0) {
  fwrite(eprtr_clean, file.path(data_dir, "eprtr_facility_clean.csv"))
  cat("\nE-PRTR facility data (supplementary):", nrow(eprtr_clean), "records\n")
}

# ============================================================================
# PART 10: Save
# ============================================================================

fwrite(panel, file.path(data_dir, "facility_panel.csv"))
fwrite(timing, file.path(data_dir, "treatment_timing.csv"))

cat("\n=== DATA CLEANING COMPLETE ===\n")
cat("Main panel (sector × country × year):", nrow(panel), "observations\n")
