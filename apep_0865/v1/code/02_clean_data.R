## 02_clean_data.R — Construct treatment variables and analysis panel
## apep_0865: Last Call for Competition

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 1. Load data
# ============================================================
qcew <- fread(file.path(data_dir, "qcew_fl_drinking_restaurants.csv"))
pop_panel <- fread(file.path(data_dir, "census_pop_fl_counties.csv"))
pop_2000 <- fread(file.path(data_dir, "census_pop_fl_2000_baseline.csv"))

cat(sprintf("QCEW: %d rows\n", nrow(qcew)))
cat(sprintf("Population panel: %d rows\n", nrow(pop_panel)))

# ============================================================
# 2. Construct treatment variable: quota license thresholds
# ============================================================
# FL Statute 561.20: 1 quota license per 7,500 residents
# Benchmark: 1999 population (we use 2000 Census as closest available)
# New licenses awarded when county crosses next 7,500 increment

THRESHOLD <- 7500

pop_panel <- merge(pop_panel, pop_2000[, .(fips, pop_2000)], by = "fips", all.x = TRUE)
# pop_2000 column may already exist from fetch; handle duplicates
if ("pop_2000.y" %in% names(pop_panel)) {
  pop_panel[, pop_2000 := fifelse(!is.na(pop_2000.y), pop_2000.y, pop_2000.x)]
  pop_panel[, c("pop_2000.x", "pop_2000.y") := NULL]
}

# Population growth since 2000
pop_panel[, pop_growth := POP - pop_2000]

# Number of quota licenses entitled (based on current population)
pop_panel[, licenses_entitled := floor(POP / THRESHOLD)]

# Baseline licenses (based on 2000 population)
pop_panel[, licenses_baseline := floor(pop_2000 / THRESHOLD)]

# New licenses available = current entitlement - baseline
pop_panel[, new_licenses_cumul := pmax(0, licenses_entitled - licenses_baseline)]

# Running variable for RDD: distance to next threshold crossing
# Distance in residents to the next 7,500 increment
pop_panel[, next_threshold := (licenses_entitled + 1) * THRESHOLD]
pop_panel[, dist_to_threshold := POP - next_threshold]
# Negative = below next threshold; positive = just crossed

# Year-over-year change in license entitlement (new licenses this year)
setorder(pop_panel, fips, year)
pop_panel[, licenses_prev := shift(licenses_entitled, 1), by = fips]
pop_panel[, new_licenses_yr := pmax(0, licenses_entitled - licenses_prev)]
pop_panel[is.na(new_licenses_yr), new_licenses_yr := 0]

# Binary treatment: did the county gain new licenses this year?
pop_panel[, gained_license := as.integer(new_licenses_yr > 0)]

cat("\n=== Treatment variable summary ===\n")
cat(sprintf("Counties: %d\n", length(unique(pop_panel$fips))))
cat(sprintf("County-years with new license(s): %d\n", sum(pop_panel$gained_license, na.rm = TRUE)))
cat(sprintf("Total new licenses across all years: %d\n", sum(pop_panel$new_licenses_yr, na.rm = TRUE)))
cat(sprintf("Mean new licenses per county-year (when >0): %.1f\n",
            mean(pop_panel$new_licenses_yr[pop_panel$new_licenses_yr > 0])))

# ============================================================
# 3. Collapse QCEW to county-year-industry panel
# ============================================================
# Identify employment columns
emp_cols <- intersect(names(qcew), c("annual_avg_emplvl", "month1_emplvl", "month2_emplvl", "month3_emplvl"))
estab_cols <- intersect(names(qcew), c("annual_avg_estabs_count", "qtrly_estabs_count"))

# Determine NAICS from industry_code
qcew[, naics := as.character(industry_code)]

# Create standardized county FIPS
qcew[, fips := as.character(area_fips)]

# Annual aggregation: average across quarters
# Use month1_emplvl as the employment measure (start of quarter)
if ("month1_emplvl" %in% names(qcew)) {
  qcew[, emp := as.numeric(month1_emplvl)]
} else if ("annual_avg_emplvl" %in% names(qcew)) {
  qcew[, emp := as.numeric(annual_avg_emplvl)]
}

if ("qtrly_estabs" %in% names(qcew)) {
  qcew[, estabs := as.numeric(qtrly_estabs)]
} else if ("qtrly_estabs_count" %in% names(qcew)) {
  qcew[, estabs := as.numeric(qtrly_estabs_count)]
} else if ("annual_avg_estabs_count" %in% names(qcew)) {
  qcew[, estabs := as.numeric(annual_avg_estabs_count)]
}

# Average wage
if ("avg_wkly_wage" %in% names(qcew)) {
  qcew[, avg_wage := as.numeric(avg_wkly_wage)]
}

# Annual means by county-industry
qcew_annual <- qcew[, .(
  emp = mean(emp, na.rm = TRUE),
  estabs = mean(estabs, na.rm = TRUE),
  avg_wage = if ("avg_wage" %in% names(.SD)) mean(avg_wage, na.rm = TRUE) else NA_real_
), by = .(fips, naics, year)]

# Ensure fips types match
qcew_annual[, fips := as.character(fips)]
pop_panel[, fips := as.character(fips)]

# Separate drinking places (7224) and restaurants (7225)
drinking <- qcew_annual[naics == "7224", .(fips, year, emp_drink = emp, estabs_drink = estabs, wage_drink = avg_wage)]
restaurant <- qcew_annual[naics == "7225", .(fips, year, emp_rest = emp, estabs_rest = estabs, wage_rest = avg_wage)]

# ============================================================
# 4. Merge into analysis panel
# ============================================================
panel <- merge(pop_panel, drinking, by = c("fips", "year"), all.x = TRUE)
panel <- merge(panel, restaurant, by = c("fips", "year"), all.x = TRUE)

# Employment per capita (per 10,000 residents)
panel[, emp_drink_pc := emp_drink / POP * 10000]
panel[, estabs_drink_pc := estabs_drink / POP * 10000]
panel[, emp_rest_pc := emp_rest / POP * 10000]

# Log outcomes (add 1 for zeros)
panel[, log_emp_drink := log(emp_drink + 1)]
panel[, log_estabs_drink := log(estabs_drink + 1)]
panel[, log_emp_rest := log(emp_rest + 1)]

# County name from NAME column
panel[, county_name := gsub(" County, Florida", "", NAME)]

cat("\n=== Analysis panel summary ===\n")
cat(sprintf("Panel: %d county-years\n", nrow(panel)))
cat(sprintf("Counties with drinking place data: %d\n",
            length(unique(panel$fips[!is.na(panel$emp_drink)]))))
cat(sprintf("Years: %d-%d\n", min(panel$year), max(panel$year)))
cat(sprintf("Mean drinking-place employment: %.1f\n", mean(panel$emp_drink, na.rm = TRUE)))
cat(sprintf("Mean drinking-place establishments: %.1f\n", mean(panel$estabs_drink, na.rm = TRUE)))

# ============================================================
# 5. Save
# ============================================================
fwrite(panel, file.path(data_dir, "analysis_panel.csv"))
cat("\nSaved analysis panel.\n")
