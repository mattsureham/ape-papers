## 02_clean_data.R — apep_1238
## Clean and merge CMS, hospital, BEA, and Census data

source("00_packages.R")

data_dir <- "../data"

## ============================================================
## 1. Clean CMS Geographic Variation data
## ============================================================
cat("=== Cleaning CMS Geographic Variation ===\n")

gv <- fread(file.path(data_dir, "cms_gv_county.csv"))

## Filter to county-level, all ages
gv_county <- gv[BENE_GEO_LVL == "County" & BENE_AGE_LVL == "All"]
cat("County-level, all ages: ", nrow(gv_county), " rows\n")

## Parse FIPS code from BENE_GEO_CD (should be 5-digit county FIPS)
gv_county[, fips := sprintf("%05d", as.integer(BENE_GEO_CD))]
gv_county[, state_fips := substr(fips, 1, 2)]
gv_county[, year := as.integer(YEAR)]

## Convert spending columns to numeric (handle '*' suppression)
spend_cols <- c("TOT_MDCR_STDZD_PYMT_PC", "TOT_MDCR_PYMT_PC",
                "IP_MDCR_STDZD_PYMT_PC", "OP_MDCR_STDZD_PYMT_PC",
                "SNF_MDCR_STDZD_PYMT_PC", "HH_MDCR_STDZD_PYMT_PC",
                "HOSPC_MDCR_STDZD_PYMT_PC", "EM_MDCR_STDZD_PYMT_PC",
                "PRCDRS_MDCR_STDZD_PYMT_PC", "TESTS_MDCR_STDZD_PYMT_PC",
                "IMGNG_MDCR_STDZD_PYMT_PC", "DME_MDCR_STDZD_PYMT_PC")

for (col in spend_cols) {
  if (col %in% names(gv_county)) {
    gv_county[, (col) := as.numeric(gsub("[^0-9.\\-]", "", get(col)))]
  }
}

## Key beneficiary counts
bene_cols <- c("BENES_FFS_CNT", "BENE_AVG_RISK_SCRE", "BENE_AVG_AGE",
               "BENE_FEML_PCT", "BENE_RACE_WHT_PCT", "BENE_RACE_BLACK_PCT",
               "BENE_DUAL_PCT", "IP_CVRD_STAYS_PER_1000_BENES")
for (col in bene_cols) {
  if (col %in% names(gv_county)) {
    gv_county[, (col) := as.numeric(gsub("[^0-9.\\-]", "", get(col)))]
  }
}

## Keep relevant columns
keep_cols <- c("fips", "state_fips", "year", "BENE_GEO_DESC",
               spend_cols[spend_cols %in% names(gv_county)],
               bene_cols[bene_cols %in% names(gv_county)])
gv_clean <- gv_county[, .SD, .SDcols = keep_cols]

cat("GV clean: ", nrow(gv_clean), " county-years\n")
cat("Years: ", paste(sort(unique(gv_clean$year)), collapse = ", "), "\n")
cat("Counties with 2022 data: ", uniqueN(gv_clean[year == 2022]$fips), "\n")

## ============================================================
## 2. Clean hospital data and construct county-level HHI
## ============================================================
cat("\n=== Constructing Hospital HHI ===\n")

hosp <- fread(file.path(data_dir, "cms_hospitals.csv"))
cat("Hospitals: ", nrow(hosp), "\n")
cat("Types: ", paste(unique(hosp$hospital_type), collapse = "; "), "\n")

## Include Acute Care + Critical Access + VA hospitals
hospital_types <- c("Acute Care Hospitals", "Critical Access Hospitals",
                     "Acute Care - Veterans Administration")
acute <- hosp[hospital_type %in% hospital_types]
cat("Hospitals (Acute + CAH + VA): ", nrow(acute), "\n")

## Create state-county FIPS from state abbreviation + county name
## We need to map hospital county to FIPS. Use Census county data for this.
census <- fread(file.path(data_dir, "census_county_demographics.csv"))

## Census has 'state' (FIPS) and 'county' (FIPS) columns
census[, fips := paste0(sprintf("%02d", as.integer(state)),
                         sprintf("%03d", as.integer(county)))]

## Map hospital state abbreviations to FIPS
state_map <- data.table(
  state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL",
                  "GA","HI","ID","IL","IN","IA","KS","KY","LA","ME",
                  "MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
                  "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI",
                  "SC","SD","TN","TX","UT","VT","VA","WA","WV","WI",
                  "WY","PR","GU","VI","AS","MP"),
  state_fips = c("01","02","04","05","06","08","09","10","11","12",
                  "13","15","16","17","18","19","20","21","22","23",
                  "24","25","26","27","28","29","30","31","32","33",
                  "34","35","36","37","38","39","40","41","42","44",
                  "45","46","47","48","49","50","51","53","54","55",
                  "56","72","66","78","60","69")
)

acute <- merge(acute, state_map, by.x = "state", by.y = "state_abbr", all.x = TRUE)

## Match hospitals to county FIPS using GV county descriptions
## GV format: "AL-Houston" -> state_abbr="AL", county_name="Houston"
## Hospital format: state="AL", countyparish="HOUSTON"
acute[, county_clean := toupper(trimws(countyparish))]

## Create a mapping from GV data: parse "STATE_ABBR-County Name" → FIPS
gv_fips_map <- unique(gv_clean[year == 2022, .(fips, county_name = BENE_GEO_DESC)])
gv_fips_map[, state_abbr := sub("-.*", "", county_name)]
gv_fips_map[, county_part := toupper(sub("^[A-Z]{2}-", "", county_name))]

## Merge hospitals with FIPS using state abbreviation + county name
acute_fips <- merge(acute, gv_fips_map,
                     by.x = c("state", "county_clean"),
                     by.y = c("state_abbr", "county_part"),
                     all.x = TRUE)
cat("Hospitals matched to FIPS (exact): ", sum(!is.na(acute_fips$fips)), " of ", nrow(acute_fips), "\n")

## For unmatched: try removing common suffixes and re-matching
unmatched <- acute_fips[is.na(fips)]
if (nrow(unmatched) > 0) {
  cat("Unmatched hospitals: ", nrow(unmatched), "\n")
  ## Try matching with cleaned county names (remove COUNTY, PARISH, etc.)
  gv_fips_map2 <- copy(gv_fips_map)
  gv_fips_map2[, county_part2 := toupper(gsub(" COUNTY| PARISH| BOROUGH| CENSUS AREA| MUNICIPALITY",
                                                "", county_part))]
  unmatched[, county_clean2 := gsub(" COUNTY| PARISH| BOROUGH", "", county_clean)]

  retry <- merge(unmatched[, .(state, county_clean2, facility_id)],
                  gv_fips_map2[, .(state_abbr, county_part2, fips)],
                  by.x = c("state", "county_clean2"),
                  by.y = c("state_abbr", "county_part2"),
                  all.x = TRUE)
  cat("Retry matched: ", sum(!is.na(retry$fips)), " additional\n")

  ## Update main dataset with retry matches
  if (sum(!is.na(retry$fips)) > 0) {
    retry_matches <- retry[!is.na(fips), .(facility_id, fips_retry = fips)]
    acute_fips <- merge(acute_fips, retry_matches, by = "facility_id", all.x = TRUE)
    acute_fips[is.na(fips) & !is.na(fips_retry), fips := fips_retry]
    acute_fips[, fips_retry := NULL]
  }
}

cat("Hospitals matched to FIPS (total): ", sum(!is.na(acute_fips$fips)), " of ", nrow(acute_fips), "\n")

## Compute hospital count and HHI by county FIPS
hosp_county <- acute_fips[!is.na(fips),
                           .(n_hospitals = .N),
                           by = fips]
hosp_county[, hhi_count := 10000 / n_hospitals]
hosp_county[, log_n_hosp := log(n_hospitals)]
cat("Counties with FIPS-matched hospitals: ", nrow(hosp_county), "\n")

## ============================================================
## 3. Clean BEA Historical State Income (for instrument)
## ============================================================
cat("\n=== Processing BEA State Income ===\n")

bea_hist <- fread(file.path(data_dir, "bea_state_income_hist.csv"))
bea_hist[, pci := as.numeric(gsub("[^0-9]", "", DataValue))]
bea_hist[, year := as.integer(TimePeriod)]

## State FIPS from GeoFips (first 2 digits)
bea_hist[, state_fips := substr(sprintf("%05d", as.integer(GeoFips)), 1, 2)]

## Create instrument: inverse of 1950 per capita income
pci_1950 <- bea_hist[year == 1950 & nchar(GeoFips) <= 5 & state_fips != "00",
                      .(state_fips, pci_1950 = pci)]
pci_1950[, inv_pci_1950 := 1 / pci_1950]
cat("States with 1950 PCI: ", nrow(pci_1950), "\n")

## Also get 1960 for robustness
pci_1960 <- bea_hist[year == 1960 & nchar(GeoFips) <= 5 & state_fips != "00",
                      .(state_fips, pci_1960 = pci)]
pci_1960[, inv_pci_1960 := 1 / pci_1960]

## ============================================================
## 4. Clean Census Demographics
## ============================================================
cat("\n=== Processing Census Demographics ===\n")

census[, fips := paste0(sprintf("%02d", as.integer(state)),
                         sprintf("%03d", as.integer(county)))]
census[, pop := as.numeric(B01001_001E)]
census[, median_age := as.numeric(B01002_001E)]
census[, below_poverty := as.numeric(B17001_002E)]
census[, poverty_universe := as.numeric(B17001_001E)]
census[, poverty_rate := below_poverty / poverty_universe]

## Compute 65+ population (males: 020-025, females: 044-049)
male_65plus_cols <- paste0("B01001_0", 20:25, "E")
female_65plus_cols <- paste0("B01001_0", 44:49, "E")
for (col in c(male_65plus_cols, female_65plus_cols)) {
  census[, (col) := as.numeric(get(col))]
}
census[, pop_65plus := rowSums(.SD, na.rm = TRUE),
       .SDcols = c(male_65plus_cols, female_65plus_cols)]
census[, pct_65plus := pop_65plus / pop]

census_clean <- census[, .(fips, pop, median_age, poverty_rate, pct_65plus)]
cat("Census counties: ", nrow(census_clean), "\n")

## ============================================================
## 5. Merge everything into analysis dataset
## ============================================================
cat("\n=== Merging Analysis Dataset ===\n")

## Use 2019 GV data as primary cross-section (pre-COVID)
## Also create panel 2014-2022 for robustness
gv_2019 <- gv_clean[year == 2019]
cat("GV 2019 counties: ", nrow(gv_2019), "\n")

## Merge with hospital HHI
analysis <- merge(gv_2019, hosp_county, by = "fips", all.x = TRUE)
cat("After hospital merge: ", nrow(analysis), " (", sum(!is.na(analysis$n_hospitals)), " with hospitals)\n")

## Merge with Census
analysis <- merge(analysis, census_clean, by = "fips", all.x = TRUE)
cat("After Census merge: ", nrow(analysis), "\n")

## Merge with state income instrument
analysis[, state_fips2 := substr(fips, 1, 2)]
analysis <- merge(analysis, pci_1950, by.x = "state_fips2", by.y = "state_fips", all.x = TRUE)
analysis <- merge(analysis, pci_1960, by.x = "state_fips2", by.y = "state_fips", all.x = TRUE)
cat("After BEA merge: ", nrow(analysis), " (", sum(!is.na(analysis$pci_1950)), " with instrument)\n")

## Counties with no hospitals → assign monopoly HHI (10000)
## These are counties so small they have no acute care hospital
analysis[is.na(n_hospitals), n_hospitals := 0]
analysis[n_hospitals == 0, hhi_count := 10000]
analysis[n_hospitals == 0, log_n_hosp := 0]

## Create key variables
analysis[, log_spend := log(TOT_MDCR_STDZD_PYMT_PC)]
analysis[, log_ip_spend := log(IP_MDCR_STDZD_PYMT_PC)]
analysis[, log_hhi := log(hhi_count)]

## Drop counties with missing spending or tiny beneficiary counts
analysis <- analysis[!is.na(TOT_MDCR_STDZD_PYMT_PC) & BENES_FFS_CNT >= 100]
cat("Final analysis dataset: ", nrow(analysis), " counties\n")

## Summary statistics
cat("\n--- Key Variable Summary ---\n")
cat("Medicare standardized spending/capita:\n")
cat("  Mean: $", round(mean(analysis$TOT_MDCR_STDZD_PYMT_PC, na.rm = TRUE)), "\n")
cat("  SD:   $", round(sd(analysis$TOT_MDCR_STDZD_PYMT_PC, na.rm = TRUE)), "\n")
cat("  Min:  $", round(min(analysis$TOT_MDCR_STDZD_PYMT_PC, na.rm = TRUE)), "\n")
cat("  Max:  $", round(max(analysis$TOT_MDCR_STDZD_PYMT_PC, na.rm = TRUE)), "\n")

cat("Hospital count per county:\n")
cat("  Mean: ", round(mean(analysis$n_hospitals), 2), "\n")
cat("  Median: ", median(analysis$n_hospitals), "\n")
cat("  % with 0-1 hospitals: ", round(100 * mean(analysis$n_hospitals <= 1), 1), "%\n")
cat("  % monopoly (HHI=10000): ", round(100 * mean(analysis$hhi_count == 10000), 1), "%\n")

cat("Equal-share HHI:\n")
cat("  Mean: ", round(mean(analysis$hhi_count)), "\n")
cat("  Median: ", round(median(analysis$hhi_count)), "\n")

## Save
fwrite(analysis, file.path(data_dir, "analysis_dataset.csv"))
cat("\nSaved analysis dataset: ", nrow(analysis), " counties\n")

## Also create panel dataset (2014-2022) for robustness
gv_panel <- gv_clean[year %in% 2014:2022]
panel <- merge(gv_panel, hosp_county, by = "fips", all.x = TRUE)
panel <- merge(panel, census_clean, by = "fips", all.x = TRUE)
panel[, state_fips2 := substr(fips, 1, 2)]
panel <- merge(panel, pci_1950, by.x = "state_fips2", by.y = "state_fips", all.x = TRUE)
panel[is.na(n_hospitals), n_hospitals := 0]
panel[n_hospitals == 0, hhi_count := 10000]
panel[n_hospitals == 0, log_n_hosp := 0]
panel[, log_spend := log(TOT_MDCR_STDZD_PYMT_PC)]
panel <- panel[!is.na(TOT_MDCR_STDZD_PYMT_PC) & BENES_FFS_CNT >= 100]
fwrite(panel, file.path(data_dir, "panel_dataset.csv"))
cat("Saved panel dataset: ", nrow(panel), " county-years\n")
