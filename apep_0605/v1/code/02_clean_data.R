# =============================================================================
# 02_clean_data.R — Construct analysis panel
# apep_0605: Asymmetric Resource Curse in US Shale Counties
# =============================================================================

source("00_packages.R")

# Load raw data
qwi <- fread("../data/qwi_county_year.csv")
crosswalk <- fread("../data/shale_crosswalk.csv")
oil <- fread("../data/oil_prices.csv")

# Ensure fips is character with leading zeros (5-digit)
qwi[, fips := sprintf("%05s", as.character(fips))]
crosswalk[, fips := sprintf("%05s", as.character(fips))]

# =============================================================================
# 1. CONSTRUCT TOTAL AND MINING EMPLOYMENT BY COUNTY-YEAR
# =============================================================================

# Check if there's a "total" industry code
cat("Industries available:", paste(sort(unique(qwi$industry)), collapse=", "), "\n")

# Total employment: sum across all NAICS sectors
total_emp <- qwi[, .(
  total_emp = sum(avg_emp, na.rm = TRUE),
  total_earnings = weighted.mean(avg_earnings, avg_emp, na.rm = TRUE),
  total_job_creation = sum(avg_job_creation, na.rm = TRUE),
  total_job_destruction = sum(avg_job_destruction, na.rm = TRUE),
  total_hires = sum(avg_hires, na.rm = TRUE),
  total_separations = sum(avg_separations, na.rm = TRUE),
  n_sectors = .N
), by = .(fips, year)]

# Mining employment (NAICS 21)
mining_emp <- qwi[industry == "21", .(
  mining_emp = avg_emp,
  mining_earnings = avg_earnings,
  mining_job_creation = avg_job_creation,
  mining_job_destruction = avg_job_destruction
), by = .(fips, year)]

# Non-mining employment
nonmining <- qwi[industry != "21", .(
  nonmining_emp = sum(avg_emp, na.rm = TRUE),
  nonmining_earnings = weighted.mean(avg_earnings, avg_emp, na.rm = TRUE)
), by = .(fips, year)]

# Merge
panel <- merge(total_emp, mining_emp, by = c("fips", "year"), all.x = TRUE)
panel <- merge(panel, nonmining, by = c("fips", "year"), all.x = TRUE)

# Fill missing mining employment with 0 (counties with no mining)
panel[is.na(mining_emp), mining_emp := 0]
panel[is.na(mining_job_creation), mining_job_creation := 0]
panel[is.na(mining_job_destruction), mining_job_destruction := 0]

cat("Panel before merge:", nrow(panel), "county-years\n")

# =============================================================================
# 2. MERGE WITH SHALE CROSSWALK
# =============================================================================

panel <- merge(panel, crosswalk[, .(fips, play, first_treat)],
               by = "fips", all.x = TRUE)

# Non-shale counties: first_treat = 0 (never-treated for CS-DiD)
panel[is.na(first_treat), first_treat := 0L]
panel[is.na(play), play := "Non-shale"]

# Mining share
panel[, mining_share := mining_emp / total_emp]
panel[is.na(mining_share) | is.infinite(mining_share), mining_share := 0]

# Log outcomes (add 1 to handle zeros)
panel[, log_total_emp := log(total_emp + 1)]
panel[, log_mining_emp := log(mining_emp + 1)]
panel[, log_nonmining_emp := log(nonmining_emp + 1)]
panel[, log_earnings := log(total_earnings + 1)]

# =============================================================================
# 3. MERGE OIL PRICES
# =============================================================================

panel <- merge(panel, oil, by = "year", all.x = TRUE)

# Interaction: shale indicator × oil price (continuous treatment intensity)
panel[, shale := as.integer(first_treat > 0)]
panel[, shale_x_price := shale * wti_price]

# =============================================================================
# 4. EVENT TIME
# =============================================================================

# Event time relative to first treatment year (for treated counties)
panel[first_treat > 0, event_time := year - first_treat]
panel[first_treat == 0, event_time := NA_integer_]

# =============================================================================
# 5. CREATE NUMERIC COUNTY ID
# =============================================================================

panel[, county_id := as.integer(factor(fips))]

# =============================================================================
# 6. SAMPLE RESTRICTIONS
# =============================================================================

# Drop counties with very small employment (< 50 avg across years)
avg_emp <- panel[, .(mean_emp = mean(total_emp, na.rm = TRUE)), by = fips]
small_counties <- avg_emp[mean_emp < 50]$fips
cat("Dropping", length(small_counties), "counties with avg employment < 50\n")
panel <- panel[!fips %in% small_counties]

# Drop observations with zero total employment (data quality)
panel <- panel[total_emp > 0]

# =============================================================================
# 7. SUMMARY AND SAVE
# =============================================================================

cat("\n=== Final Panel ===\n")
cat("Observations:", nrow(panel), "\n")
cat("Counties:", length(unique(panel$fips)), "\n")
cat("Years:", min(panel$year), "-", max(panel$year), "\n")
cat("Shale counties:", sum(panel$shale == 1 & panel$year == min(panel$year)), "\n")
cat("Non-shale counties:", sum(panel$shale == 0 & panel$year == min(panel$year)), "\n")
cat("\nTreatment cohorts:\n")
print(panel[shale == 1, .(n_counties = uniqueN(fips)), by = first_treat])
cat("\nMining share (shale vs non-shale, 2001):\n")
print(panel[year == min(year), .(
  mean_mining_share = mean(mining_share, na.rm = TRUE),
  median_mining_share = median(mining_share, na.rm = TRUE)
), by = shale])

fwrite(panel, "../data/analysis_panel.csv")
cat("\nAnalysis panel saved: data/analysis_panel.csv\n")
