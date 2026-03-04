# ==============================================================================
# 02_clean_data.R — Clean and merge datasets for RDD analysis
# Clean Air, Dirty Power? NAAQS Nonattainment and the Clean Energy Transition
# ==============================================================================

source("00_packages.R")

# ==============================================================================
# 1. Load raw data
# ==============================================================================

design_values <- readRDS(file.path(data_dir, "design_values.rds"))
generators    <- readRDS(file.path(data_dir, "generators_raw.rds"))
acs_demo      <- readRDS(file.path(data_dir, "acs_demographics.rds"))

cat("=== Loaded raw data ===\n")
cat(sprintf("  Design values: %d rows\n", nrow(design_values)))
cat(sprintf("  eGRID generators: %d rows\n", nrow(generators)))
cat(sprintf("  ACS: %d rows\n", nrow(acs_demo)))

# ==============================================================================
# 2. Clean eGRID generator data
# ==============================================================================

gen <- copy(generators)

# eGRID uses specific column naming (e.g., PSTATABB, CNTYNAME, FIPSST, FIPSCNTY)
# Standardize to common names
cat("\neGRID columns: ", paste(head(names(gen), 30), collapse = ", "), "\n")

# Find key columns (eGRID naming varies slightly across years)
find_col <- function(dt, patterns) {
  nms <- names(dt)
  for (p in patterns) {
    match <- nms[grepl(p, nms, ignore.case = TRUE)]
    if (length(match) > 0) return(match[1])
  }
  return(NA_character_)
}

col_plant_id  <- find_col(gen, c("^ORISPL$", "ORISPL", "Plant.ID", "SEQPLT"))
col_plant_name <- find_col(gen, c("^PNAME$", "Plant.Name"))
col_state     <- find_col(gen, c("^PSTATABB$", "^STATEABB", "State"))
col_state_fips <- find_col(gen, c("^FIPSST$", "FIPS.State"))
col_county_fips <- find_col(gen, c("^FIPSCNTY$", "FIPS.County"))
col_county_name <- find_col(gen, c("^CNTYNAME$", "County"))
col_lat       <- find_col(gen, c("^LAT$", "Latitude"))
col_lon       <- find_col(gen, c("^LON$", "Longitude"))
col_capacity  <- find_col(gen, c("^NAMEPCAP$", "Nameplate.Cap", "PLNGENAN"))
col_fuel      <- find_col(gen, c("^PLPRMFL$", "Primary.Fuel", "PLFUELCT"))
col_gen_mwh   <- find_col(gen, c("^PLNGENAN$", "Net.Generation", "NAMEPCAP"))
col_co2       <- find_col(gen, c("^PLCO2AN$", "CO2.Annual"))
col_year_op   <- find_col(gen, c("^PLINYR$", "Initial.Year"))

cat(sprintf("\nColumn mapping:\n"))
cat(sprintf("  Plant ID: %s\n", col_plant_id))
cat(sprintf("  State: %s\n", col_state))
cat(sprintf("  State FIPS: %s\n", col_state_fips))
cat(sprintf("  County FIPS: %s\n", col_county_fips))
cat(sprintf("  Latitude: %s\n", col_lat))
cat(sprintf("  Capacity: %s\n", col_capacity))
cat(sprintf("  Fuel: %s\n", col_fuel))
cat(sprintf("  CO2: %s\n", col_co2))
cat(sprintf("  Year Started: %s\n", col_year_op))

# Create standardized columns
if (!is.na(col_plant_id)) gen[, plant_id := get(col_plant_id)]
if (!is.na(col_state)) gen[, state := get(col_state)]
if (!is.na(col_lat)) gen[, latitude := as.numeric(get(col_lat))]
if (!is.na(col_lon)) gen[, longitude := as.numeric(get(col_lon))]
if (!is.na(col_fuel)) gen[, fuel_code := get(col_fuel)]

# Create county FIPS from state+county FIPS codes
if (!is.na(col_state_fips) && !is.na(col_county_fips)) {
  gen[, county_fips := sprintf("%02d%03d",
                               as.integer(get(col_state_fips)),
                               as.integer(get(col_county_fips)))]
  cat(sprintf("  Counties from FIPS: %d unique\n", uniqueN(gen$county_fips[!is.na(gen$county_fips)])))
}

# Capacity (nameplate MW)
cap_col <- find_col(gen, c("^NAMEPCAP$", "Nameplate"))
if (!is.na(cap_col)) {
  gen[, capacity_mw := as.numeric(get(cap_col))]
}

# Net annual generation (MWh)
gen_col <- find_col(gen, c("^PLNGENAN$", "Net.Gen"))
if (!is.na(gen_col)) {
  gen[, generation_mwh := as.numeric(get(gen_col))]
}

# CO2 emissions (tons)
if (!is.na(col_co2)) {
  gen[, co2_tons := as.numeric(get(col_co2))]
}

# Year started operating
if (!is.na(col_year_op)) {
  gen[, year_started := as.integer(get(col_year_op))]
} else {
  gen[, year_started := NA_integer_]
}

# Classify fuel types based on eGRID fuel category
fuel_cat_col <- find_col(gen, c("^PLFUELCT$", "Fuel.Category", "^PLPRMFL$"))
if (!is.na(fuel_cat_col)) {
  gen[, fuel_category := get(fuel_cat_col)]
  cat(sprintf("\nFuel categories: %s\n", paste(unique(gen$fuel_category), collapse = ", ")))
}

# Create binary classifications
gen[, is_fossil := as.integer(fuel_category %in% c("COAL", "GAS", "OIL", "OTHF") |
                               grepl("^(BIT|SUB|LIG|NG|DFO|RFO|PC|RC|WC|OG|KER|JF)", fuel_code, ignore.case = TRUE))]
gen[, is_renewable := as.integer(fuel_category %in% c("SUN", "WIND", "GEOTHERMAL") |
                                  grepl("^(SUN|WND|GEO)", fuel_code, ignore.case = TRUE))]
gen[, is_coal := as.integer(fuel_category == "COAL" |
                             grepl("^(BIT|SUB|LIG|RC|WC|SC|ANT)", fuel_code, ignore.case = TRUE))]
gen[, is_gas := as.integer(fuel_category == "GAS" |
                            grepl("^(NG|OG|BFG|PG)", fuel_code, ignore.case = TRUE))]
gen[, is_solar := as.integer(fuel_category == "SUN" |
                              grepl("^SUN", fuel_code, ignore.case = TRUE))]
gen[, is_wind := as.integer(fuel_category == "WIND" |
                             grepl("^WND", fuel_code, ignore.case = TRUE))]

cat(sprintf("\nGenerator classification:\n"))
cat(sprintf("  Fossil: %d (%.1f%%)\n", sum(gen$is_fossil, na.rm = TRUE),
            100 * mean(gen$is_fossil, na.rm = TRUE)))
cat(sprintf("  Renewable (solar+wind+geo): %d (%.1f%%)\n", sum(gen$is_renewable, na.rm = TRUE),
            100 * mean(gen$is_renewable, na.rm = TRUE)))
cat(sprintf("  Coal: %d\n", sum(gen$is_coal, na.rm = TRUE)))
cat(sprintf("  Gas: %d\n", sum(gen$is_gas, na.rm = TRUE)))
cat(sprintf("  Solar: %d\n", sum(gen$is_solar, na.rm = TRUE)))
cat(sprintf("  Wind: %d\n", sum(gen$is_wind, na.rm = TRUE)))

# ==============================================================================
# 3. Aggregate to county-year level
# ==============================================================================

cat("\n=== Aggregating generators to county-year level ===\n")

# Use egrid_year as the year variable
if (!"egrid_year" %in% names(gen)) gen[, egrid_year := 2022]

county_energy <- gen[!is.na(county_fips) & !is.na(capacity_mw), .(
  total_capacity = sum(capacity_mw, na.rm = TRUE),
  fossil_capacity = sum(capacity_mw * is_fossil, na.rm = TRUE),
  renewable_capacity = sum(capacity_mw * is_renewable, na.rm = TRUE),
  coal_capacity = sum(capacity_mw * is_coal, na.rm = TRUE),
  gas_capacity = sum(capacity_mw * is_gas, na.rm = TRUE),
  solar_capacity = sum(capacity_mw * is_solar, na.rm = TRUE),
  wind_capacity = sum(capacity_mw * is_wind, na.rm = TRUE),
  total_generation = sum(generation_mwh, na.rm = TRUE),
  fossil_generation = sum(generation_mwh * is_fossil, na.rm = TRUE),
  renewable_generation = sum(generation_mwh * is_renewable, na.rm = TRUE),
  co2_total = sum(co2_tons, na.rm = TRUE),
  n_plants = uniqueN(plant_id),
  n_fossil = uniqueN(plant_id[is_fossil == 1]),
  n_renewable = uniqueN(plant_id[is_renewable == 1]),
  n_coal = uniqueN(plant_id[is_coal == 1]),
  # Track new plants (started within last 5 years)
  new_capacity_5yr = sum(capacity_mw[year_started >= (egrid_year[1] - 5)], na.rm = TRUE),
  new_fossil_5yr = sum(capacity_mw[year_started >= (egrid_year[1] - 5) & is_fossil == 1], na.rm = TRUE),
  new_renewable_5yr = sum(capacity_mw[year_started >= (egrid_year[1] - 5) & is_renewable == 1], na.rm = TRUE)
), by = .(county_fips, egrid_year)]

county_energy[total_capacity > 0, renewable_share := renewable_capacity / total_capacity]
county_energy[total_capacity > 0, fossil_share := fossil_capacity / total_capacity]
county_energy[total_generation > 0, renewable_gen_share := renewable_generation / total_generation]

cat(sprintf("County-year energy outcomes: %d rows, %d counties\n",
            nrow(county_energy), uniqueN(county_energy$county_fips)))
cat(sprintf("Counties with fossil plants: %d\n", uniqueN(county_energy[fossil_capacity > 0]$county_fips)))
cat(sprintf("Counties with renewable plants: %d\n", uniqueN(county_energy[renewable_capacity > 0]$county_fips)))

# ==============================================================================
# 4. Create analysis panel: design values + energy outcomes + demographics
# ==============================================================================

cat("\n=== Building analysis panel ===\n")

panel <- copy(design_values[!is.na(design_value)])

# Merge energy outcomes
# Use eGRID 2022 as cross-sectional capacity stock for all panel years
# Energy infrastructure changes slowly — county-level capacity stock is
# a reasonable cross-sectional measure reflecting cumulative investment decisions
latest_energy <- county_energy[egrid_year == max(egrid_year)]
latest_energy[, egrid_year := NULL]
panel_with_energy <- merge(panel, latest_energy, by = "county_fips", all.x = TRUE)

# Fill zeros for counties with no generators
energy_vars <- c("total_capacity", "fossil_capacity", "renewable_capacity",
                 "coal_capacity", "gas_capacity", "solar_capacity", "wind_capacity",
                 "total_generation", "fossil_generation", "renewable_generation",
                 "co2_total", "n_plants", "n_fossil", "n_renewable", "n_coal",
                 "new_capacity_5yr", "new_fossil_5yr", "new_renewable_5yr")
for (v in energy_vars) {
  if (v %in% names(panel_with_energy)) {
    panel_with_energy[is.na(get(v)), (v) := 0]
  }
}
panel_with_energy[total_capacity > 0 & is.na(renewable_share),
                  renewable_share := renewable_capacity / total_capacity]
panel_with_energy[total_capacity > 0 & is.na(fossil_share),
                  fossil_share := fossil_capacity / total_capacity]

# Create RDD running variables for each cutoff
panel_with_energy[, running_15 := design_value - 15]
panel_with_energy[, running_12 := design_value - 12]
panel_with_energy[, treat_15 := as.integer(design_value > 15)]
panel_with_energy[, treat_12 := as.integer(design_value > 12)]

# Merge demographics
acs_slim <- acs_demo[, .(county_fips, year, total_pop, median_income, total_workers)]
panel_with_energy <- merge(panel_with_energy, acs_slim,
                           by.x = c("county_fips", "Year"), by.y = c("county_fips", "year"),
                           all.x = TRUE)

# Create forward-looking PM2.5
setorder(panel_with_energy, county_fips, Year)
panel_with_energy[, pm25_fwd := shift(pm25_mean, n = -1, type = "lead"), by = county_fips]

# ==============================================================================
# 6. Create cross-sectional RDD dataset
# ==============================================================================
# Since energy outcomes are from eGRID 2022 (cross-sectional),
# the primary RDD should be cross-sectional: one observation per county
# using the most recent design value (2020-2022 average)

cat("\n=== Building cross-sectional RDD dataset ===\n")

# Use average design value over the 2012-2022 period per county
# This captures each county's typical regulatory status under the 12 μg/m³ standard
recent_dv <- panel_with_energy[Year >= 2012 & Year <= 2022 & !is.na(design_value),
                                .(dv_recent = mean(design_value, na.rm = TRUE),
                                  pm25_recent = mean(pm25_mean, na.rm = TRUE),
                                  n_years_recent = .N,
                                  ever_nonattain = max(as.integer(design_value > 12), na.rm = TRUE),
                                  frac_nonattain = mean(as.integer(design_value > 12), na.rm = TRUE)),
                                by = county_fips]

# Use most recent demographics
recent_demo <- panel_with_energy[Year >= 2020 & !is.na(total_pop),
                                  .(total_pop = mean(total_pop, na.rm = TRUE),
                                    median_income = mean(median_income, na.rm = TRUE),
                                    total_workers = mean(total_workers, na.rm = TRUE)),
                                  by = county_fips]

# Cross-sectional dataset: one row per county
cross_section <- merge(recent_dv, latest_energy, by = "county_fips", all.x = TRUE)
cross_section <- merge(cross_section, recent_demo, by = "county_fips", all.x = TRUE)

# Fill zeros for counties without generators
for (v in energy_vars) {
  if (v %in% names(cross_section)) {
    cross_section[is.na(get(v)), (v) := 0]
  }
}
cross_section[total_capacity > 0 & is.na(renewable_share),
              renewable_share := renewable_capacity / total_capacity]
cross_section[total_capacity > 0 & is.na(fossil_share),
              fossil_share := fossil_capacity / total_capacity]

# Running variables
cross_section[, running_12 := dv_recent - 12]
cross_section[, running_15 := dv_recent - 15]
cross_section[, treat_12 := as.integer(dv_recent > 12)]
cross_section[, treat_15 := as.integer(dv_recent > 15)]

# Monitor count from panel
n_monitors_cs <- panel_with_energy[Year >= 2020, .(n_monitors = mean(n_monitors, na.rm = TRUE)),
                                    by = county_fips]
cross_section <- merge(cross_section, n_monitors_cs, by = "county_fips", all.x = TRUE)

cat(sprintf("Cross-sectional RDD dataset: %d counties\n", nrow(cross_section)))
cat(sprintf("Counties near 12 cutoff (±2): %d\n",
            nrow(cross_section[abs(running_12) <= 2])))
cat(sprintf("Nonattainment (DV > 12): %d (%.1f%%)\n",
            sum(cross_section$treat_12 == 1, na.rm = TRUE),
            100 * mean(cross_section$treat_12 == 1, na.rm = TRUE)))

saveRDS(cross_section, file.path(data_dir, "cross_section_rdd.rds"))

cat(sprintf("\n=== Analysis panel ===\n"))
cat(sprintf("  Rows: %d\n", nrow(panel_with_energy)))
cat(sprintf("  Counties: %d\n", uniqueN(panel_with_energy$county_fips)))
cat(sprintf("  Years: %d-%d\n", min(panel_with_energy$Year), max(panel_with_energy$Year)))
cat(sprintf("  Counties with energy data: %d\n",
            uniqueN(panel_with_energy[total_capacity > 0]$county_fips)))
cat(sprintf("  Nonattainment (DV > standard): %d (%.1f%%)\n",
            sum(panel_with_energy$nonattainment == 1, na.rm = TRUE),
            100 * mean(panel_with_energy$nonattainment == 1, na.rm = TRUE)))

# ==============================================================================
# 5. Save analysis datasets
# ==============================================================================

saveRDS(panel_with_energy, file.path(data_dir, "analysis_panel.rds"))
saveRDS(panel_with_energy, file.path(data_dir, "analysis_with_energy.rds"))
saveRDS(county_energy, file.path(data_dir, "county_energy.rds"))
saveRDS(gen, file.path(data_dir, "generators_clean.rds"))

cat("\n=== Data cleaning complete ===\n")

# Validation
stopifnot("Panel has 100+ counties" = uniqueN(panel_with_energy$county_fips) >= 100)
stopifnot("Panel spans 10+ years" = uniqueN(panel_with_energy$Year) >= 10)
stopifnot("Running variable computed" = sum(!is.na(panel_with_energy$running_12)) > 0)
stopifnot("Some energy data merged" = sum(panel_with_energy$total_capacity > 0, na.rm = TRUE) > 0)
cat("Data validation passed.\n")
