# ============================================================
# 02_clean_data.R — Build county-quarter panel
# apep_0874: Feeding the Supply Side
# ============================================================

source("00_packages.R")

data_dir <- "../data"

# ----------------------------------------------------------
# 1. Load raw data
# ----------------------------------------------------------
cat("=== Loading Raw Data ===\n")

retailers <- fread(file.path(data_dir, "snap_retailers_raw.csv"), showProgress = FALSE)
acs <- fread(file.path(data_dir, "acs_county_2019.csv"))
ea_dates <- readRDS(file.path(data_dir, "ea_dates.rds"))

cat("  Retailers:", nrow(retailers), "\n")
cat("  ACS counties:", nrow(acs), "\n")

# ----------------------------------------------------------
# 2. Parse retailer authorization dates
# ----------------------------------------------------------
cat("\n=== Processing Retailer Data ===\n")

# Parse authorization date
retailers[, auth_date := as.Date(`Authorization Date`, format = "%m/%d/%Y")]

# Handle alternative date formats if needed
if (sum(is.na(retailers$auth_date)) > nrow(retailers) * 0.5) {
  retailers[is.na(auth_date), auth_date := as.Date(`Authorization Date`, format = "%Y-%m-%d")]
}

cat("  Valid auth dates:", sum(!is.na(retailers$auth_date)), "of", nrow(retailers), "\n")

# Extract year-quarter
retailers[, auth_year := year(auth_date)]
retailers[, auth_quarter := quarter(auth_date)]
retailers[, auth_yq := paste0(auth_year, "Q", auth_quarter)]

# Filter to 2016-2024
retailers <- retailers[auth_year >= 2016 & auth_year <= 2024]
cat("  Retailers 2016-2024:", nrow(retailers), "\n")

# ----------------------------------------------------------
# 3. Build county FIPS from retailer data
# ----------------------------------------------------------

# County column exists in retailer data
cat("  County column values (sample):", head(retailers$County, 5), "\n")

# Build state FIPS mapping
state_to_fips <- data.table(
  state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI","ID","IL","IN",
                  "IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
                  "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT",
                  "VT","VA","WA","WV","WI","WY"),
  state_fips = sprintf("%02d", c(1,2,4,5,6,8,9,10,11,12,13,15,16,17,18,19,20,21,22,23,24,
                                  25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,44,
                                  45,46,47,48,49,50,51,53,54,55,56))
)

# The County column contains the county name. We need to geocode to FIPS.
# Use the 5-digit zip code to county FIPS crosswalk approach:
# Actually, the retailer data has State + County name. We'll match via state + county name to FIPS.
# But this is fragile. Better approach: use Zip Code to get county FIPS from ACS.

# Alternative: Use Latitude/Longitude if available
has_coords <- "Latitude" %in% names(retailers) && "Longitude" %in% names(retailers)

if (has_coords) {
  cat("  Using coordinates for county assignment.\n")
  # We'll use zip code -> county FIPS crosswalk instead (more reliable)
}

# Use HUD ZIP-County crosswalk or direct zip->county mapping
# Simplest reliable approach: first 3 digits of zip approximate county, but
# the best approach is to use the Census API ZIP-to-County crosswalk.
# For speed and reliability, we'll use the state abbreviation + county name
# to match against the ACS county names.

# Clean state abbreviation
retailers[, state_abbr := State]

# Merge state FIPS
retailers <- merge(retailers, state_to_fips, by = "state_abbr", all.x = TRUE)
cat("  Retailers with state FIPS:", sum(!is.na(retailers$state_fips)), "\n")

# Now match county name to FIPS within state
# ACS has NAME like "County Name, State" and state + county FIPS
acs[, county_name := gsub(",.*$", "", NAME)]
acs[, county_name_clean := tolower(gsub(" County$| Parish$| Borough$| Census Area$| Municipality$| city$",
                                          "", county_name))]
acs[, state_fips_acs := state]

# Retailer county names
retailers[, county_name_clean := tolower(trimws(County))]
# Remove "county", "parish" etc. from retailer county names too
retailers[, county_name_clean := gsub(" county$| parish$| borough$| census area$| municipality$| city$",
                                       "", county_name_clean)]

# Build lookup from ACS: state_fips + county_name_clean -> fips
county_lookup <- acs[, .(fips, state_fips_acs, county_name_clean)]
setnames(county_lookup, "state_fips_acs", "state_fips")
# Ensure both are character for merge
county_lookup[, state_fips := as.character(state_fips)]
retailers[, state_fips := as.character(state_fips)]
# Remove duplicate county names within state (keep first match)
county_lookup <- unique(county_lookup, by = c("state_fips", "county_name_clean"))

# Merge
retailers <- merge(retailers, county_lookup,
                    by = c("state_fips", "county_name_clean"),
                    all.x = TRUE)

matched <- sum(!is.na(retailers$fips))
cat("  Retailers matched to county FIPS:", matched, "of", nrow(retailers),
    "(", round(100 * matched / nrow(retailers), 1), "%)\n")

# Drop unmatched (typically military bases, territories, etc.)
retailers <- retailers[!is.na(fips)]

# ----------------------------------------------------------
# 4. Classify store types
# ----------------------------------------------------------
cat("\n=== Store Type Classification ===\n")

type_col <- "Store Type"
if (type_col %in% names(retailers)) {
  cat("  Store types:\n")
  print(table(retailers[[type_col]]))

  retailers[, store_category := fcase(
    grepl("Super", get(type_col), ignore.case = TRUE), "supermarket",
    grepl("Convenience|Small", get(type_col), ignore.case = TRUE), "convenience",
    grepl("Medium|Large|Combo|Warehouse", get(type_col), ignore.case = TRUE), "large_grocery",
    default = "other"
  )]
} else {
  cat("  No Store Type column found, classifying all as 'all'.\n")
  retailers[, store_category := "all"]
}

cat("  Category counts:\n")
print(table(retailers$store_category))

# ----------------------------------------------------------
# 5. Build county-quarter panel
# ----------------------------------------------------------
cat("\n=== Building County-Quarter Panel ===\n")

# Create balanced panel grid
counties <- unique(acs[!is.na(snap_rate), .(fips)])
quarters <- CJ(year = 2016:2024, quarter = 1:4)
quarters[, yq := paste0(year, "Q", quarter)]

# Remove future quarters
quarters <- quarters[!(year == 2024 & quarter > 4)]
quarters <- quarters[!(year == 2025)]

panel_grid <- CJ(fips = counties$fips, yq = quarters$yq)
panel_grid <- merge(panel_grid, quarters, by = "yq")

# Count new authorizations per county-quarter
auth_counts <- retailers[, .(
  new_auths = .N,
  new_supermarket = sum(store_category == "supermarket"),
  new_convenience = sum(store_category == "convenience"),
  new_large = sum(store_category == "large_grocery"),
  new_other = sum(store_category == "other")
), by = .(fips, yq = auth_yq)]

# Merge onto panel
panel <- merge(panel_grid, auth_counts, by = c("fips", "yq"), all.x = TRUE)

# Fill NAs with 0 (quarters with no new authorizations)
auth_cols <- c("new_auths", "new_supermarket", "new_convenience", "new_large", "new_other")
for (col in auth_cols) {
  panel[is.na(get(col)), (col) := 0]
}

# ----------------------------------------------------------
# 6. Compute existing store base per county
# ----------------------------------------------------------
# Count stores authorized before 2016 that are still active in 2016
# (End Date is NA or after 2016)
existing_stores <- retailers[auth_year < 2016 | (auth_year >= 2016 & auth_date < as.Date("2016-01-01"))]

# Actually, count all stores present at baseline (have authorization before period start)
all_retailers_full <- fread(file.path(data_dir, "snap_retailers_raw.csv"), showProgress = FALSE)
all_retailers_full[, auth_date := as.Date(`Authorization Date`, format = "%m/%d/%Y")]
all_retailers_full <- merge(all_retailers_full,
                             state_to_fips[, .(state_abbr, state_fips)],
                             by.x = "State", by.y = "state_abbr", all.x = TRUE)
all_retailers_full[, county_name_clean := tolower(trimws(County))]
all_retailers_full[, county_name_clean := gsub(" county$| parish$| borough$| census area$| municipality$| city$",
                                                 "", county_name_clean)]
all_retailers_full[, state_fips := as.character(state_fips)]
all_retailers_full <- merge(all_retailers_full, county_lookup,
                             by = c("state_fips", "county_name_clean"), all.x = TRUE)

# Baseline store count: authorized before 2019 (stable pre-period measure)
baseline_stores <- all_retailers_full[!is.na(fips) & auth_date < as.Date("2019-01-01"),
                                       .(baseline_stores = .N), by = fips]

panel <- merge(panel, baseline_stores, by = "fips", all.x = TRUE)
panel[is.na(baseline_stores), baseline_stores := 0]

# Rate: new authorizations per 1,000 existing stores
panel[, auth_rate := fifelse(baseline_stores > 0, (new_auths / baseline_stores) * 1000, NA_real_)]

# ----------------------------------------------------------
# 7. Merge treatment intensity and controls
# ----------------------------------------------------------
cat("\n=== Merging Treatment and Controls ===\n")

# Treatment intensity: SNAP rate × $36.24/person/month
# This is the per-household-per-month SNAP benefit increase
panel <- merge(panel, acs[, .(fips, snap_rate, poverty_rate, population,
                                pct_black, pct_hispanic, median_income)],
                by = "fips", all.x = TRUE)

# Treatment intensity: snap_rate × $36.24 (benefit increase per person per month)
panel[, treatment_intensity := snap_rate * 36.24]

# Post indicator (TFP effective October 1, 2021 = 2021Q4)
panel[, post_tfp := as.integer(year > 2021 | (year == 2021 & quarter >= 4))]

# Continuous DiD variable
panel[, did_continuous := treatment_intensity * post_tfp]

# ----------------------------------------------------------
# 8. Add EA controls
# ----------------------------------------------------------

# Merge EA end dates (state level)
panel[, state_fips := substr(fips, 1, 2)]
ea_dates_panel <- ea_dates[, .(state_fips, ea_end_date, early_optout)]
panel <- merge(panel, ea_dates_panel, by = "state_fips", all.x = TRUE)

# EA active indicator: EA was active for that state-quarter
panel[, quarter_start := as.Date(paste0(year, "-", (quarter - 1) * 3 + 1, "-01"))]
panel[, ea_active := as.integer(!is.na(ea_end_date) & quarter_start <= ea_end_date)]

# ----------------------------------------------------------
# 9. Create time variables for FE
# ----------------------------------------------------------
panel[, time_id := (year - 2016) * 4 + quarter]
panel[, county_id := as.integer(as.factor(fips))]

# Drop counties with missing treatment
panel <- panel[!is.na(snap_rate) & !is.na(treatment_intensity)]

# Drop tiny counties (fewer than 5 baseline stores — no meaningful rate)
panel <- panel[baseline_stores >= 5]

cat("  Panel dimensions:", nrow(panel), "rows,", uniqueN(panel$fips), "counties,",
    uniqueN(panel$yq), "quarters\n")
cat("  Treatment intensity range:", round(min(panel$treatment_intensity, na.rm = TRUE), 2), "-",
    round(max(panel$treatment_intensity, na.rm = TRUE), 2), "\n")
cat("  Post-TFP obs:", sum(panel$post_tfp), "\n")
cat("  Pre-TFP obs:", sum(!panel$post_tfp), "\n")

# ----------------------------------------------------------
# 10. Summary statistics
# ----------------------------------------------------------
cat("\n=== Summary Statistics ===\n")

sumstats <- panel[, .(
  mean_new_auths = mean(new_auths, na.rm = TRUE),
  sd_new_auths = sd(new_auths, na.rm = TRUE),
  mean_auth_rate = mean(auth_rate, na.rm = TRUE),
  sd_auth_rate = sd(auth_rate, na.rm = TRUE),
  mean_snap_rate = mean(snap_rate, na.rm = TRUE),
  sd_snap_rate = sd(snap_rate, na.rm = TRUE),
  mean_treatment = mean(treatment_intensity, na.rm = TRUE),
  sd_treatment = sd(treatment_intensity, na.rm = TRUE),
  mean_population = mean(population, na.rm = TRUE),
  sd_population = sd(population, na.rm = TRUE),
  mean_poverty = mean(poverty_rate, na.rm = TRUE),
  sd_poverty = sd(poverty_rate, na.rm = TRUE),
  mean_baseline_stores = mean(baseline_stores, na.rm = TRUE),
  sd_baseline_stores = sd(baseline_stores, na.rm = TRUE),
  n_counties = uniqueN(fips),
  n_quarters = uniqueN(yq),
  n_obs = .N
)]

cat("  Mean new authorizations/county-quarter:", round(sumstats$mean_new_auths, 2), "\n")
cat("  SD new authorizations:", round(sumstats$sd_new_auths, 2), "\n")
cat("  Mean SNAP rate:", round(sumstats$mean_snap_rate, 3), "\n")
cat("  Mean treatment intensity:", round(sumstats$mean_treatment, 2), "\n")
cat("  Counties:", sumstats$n_counties, "\n")
cat("  Total obs:", sumstats$n_obs, "\n")

# Save
saveRDS(panel, file.path(data_dir, "panel.rds"))
saveRDS(sumstats, file.path(data_dir, "sumstats.rds"))

# Also save summary stats for the paper table
sumstats_table <- panel[, .(
  Variable = c("New authorizations (count)", "Authorization rate (per 1,000 stores)",
               "SNAP participation rate", "Treatment intensity ($/person/month)",
               "Population", "Poverty rate", "Baseline stores",
               "Median household income"),
  Mean = c(mean(new_auths, na.rm=TRUE), mean(auth_rate, na.rm=TRUE),
           mean(snap_rate, na.rm=TRUE), mean(treatment_intensity, na.rm=TRUE),
           mean(population, na.rm=TRUE), mean(poverty_rate, na.rm=TRUE),
           mean(baseline_stores, na.rm=TRUE), mean(median_income, na.rm=TRUE)),
  SD = c(sd(new_auths, na.rm=TRUE), sd(auth_rate, na.rm=TRUE),
         sd(snap_rate, na.rm=TRUE), sd(treatment_intensity, na.rm=TRUE),
         sd(population, na.rm=TRUE), sd(poverty_rate, na.rm=TRUE),
         sd(baseline_stores, na.rm=TRUE), sd(median_income, na.rm=TRUE)),
  Min = c(min(new_auths, na.rm=TRUE), min(auth_rate, na.rm=TRUE),
          min(snap_rate, na.rm=TRUE), min(treatment_intensity, na.rm=TRUE),
          min(population, na.rm=TRUE), min(poverty_rate, na.rm=TRUE),
          min(baseline_stores, na.rm=TRUE), min(median_income, na.rm=TRUE)),
  Max = c(max(new_auths, na.rm=TRUE), max(auth_rate, na.rm=TRUE),
          max(snap_rate, na.rm=TRUE), max(treatment_intensity, na.rm=TRUE),
          max(population, na.rm=TRUE), max(poverty_rate, na.rm=TRUE),
          max(baseline_stores, na.rm=TRUE), max(median_income, na.rm=TRUE))
)]

saveRDS(sumstats_table, file.path(data_dir, "sumstats_table.rds"))

cat("\n=== Panel Construction Complete ===\n")
