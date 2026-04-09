# 02_clean_data.R — Process UCMR5 + county karst data
# PFAS/Karst Spatial RDD — apep_1440

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 1. Load and process UCMR5
# ============================================================
cat("Reading UCMR5...\n")
ucmr5 <- data.table::fread(file.path(data_dir, "ucmr5/UCMR5_All.txt"), sep = "\t")
cat("UCMR5 rows:", nrow(ucmr5), " columns:", ncol(ucmr5), "\n")
cat("Columns:", paste(names(ucmr5), collapse = ", "), "\n")

# Examine contaminants
cat("\nUnique contaminants:", length(unique(ucmr5$Contaminant)), "\n")
cat("Contaminants:", paste(unique(ucmr5$Contaminant), collapse = ", "), "\n")

# Filter to PFAS compounds
pfas_compounds <- ucmr5[grepl("PF|GenX|HFPO|ADONA|FTS|FBSA|NEtFOSAA|NMeFOSAA",
                               Contaminant, ignore.case = TRUE)]
cat("PFAS rows:", nrow(pfas_compounds), "\n")
cat("PFAS contaminants:", paste(unique(pfas_compounds$Contaminant), collapse = ", "), "\n")

# Parse result values
# AnalyticalResultsSign: "<" means below detection limit (non-detect)
# AnalyticalResultValue is blank for non-detects, numeric for detects
# Units are µg/L (= ppb). MCL is 4 ppt = 0.004 µg/L
pfas_compounds[, result_ugL := suppressWarnings(as.numeric(AnalyticalResultValue))]
pfas_compounds[is.na(result_ugL), result_ugL := 0]  # Non-detects = 0
pfas_compounds[, detected := as.integer(AnalyticalResultsSign != "<" & result_ugL > 0)]
# Convert to ppt (parts per trillion) = µg/L × 1,000,000 / 1000 = µg/L × 1000
pfas_compounds[, result_ppt := result_ugL * 1000]
cat("Detected samples:", sum(pfas_compounds$detected), "of", nrow(pfas_compounds), "\n")
cat("Max detected (ppt):", max(pfas_compounds$result_ppt, na.rm = TRUE), "\n")
cat("Mean detected (ppt):", mean(pfas_compounds$result_ppt[pfas_compounds$detected == 1], na.rm = TRUE), "\n")

# Water type distribution
cat("\nWater types:\n")
print(table(pfas_compounds$FacilityWaterType))

# PWS-level aggregation
pws_pfas <- pfas_compounds[, .(
  max_pfas_ppt = max(result_ppt, na.rm = TRUE),
  mean_pfas_ppt = mean(result_ppt[detected == 1], na.rm = TRUE),
  any_detect = as.integer(any(detected == 1)),
  above_mcl = as.integer(any(result_ppt > 4)),  # 4 ppt MCL
  n_samples = .N,
  n_detected = sum(detected),
  n_pfas_compounds = uniqueN(Contaminant),
  has_gw = as.integer(any(FacilityWaterType == "GW")),
  has_sw = as.integer(any(FacilityWaterType == "SW")),
  pws_name = first(PWSName),
  pws_size = first(Size)
), by = PWSID]

# Clean infinite/NaN values
pws_pfas[is.infinite(max_pfas_ppt) | is.nan(max_pfas_ppt), max_pfas_ppt := 0]
pws_pfas[is.infinite(mean_pfas_ppt) | is.nan(mean_pfas_ppt), mean_pfas_ppt := 0]

cat("\nPWS-level summary:\n")
cat("Total PWSs:", nrow(pws_pfas), "\n")
cat("Any detection:", sum(pws_pfas$any_detect), "\n")
cat("Above MCL:", sum(pws_pfas$above_mcl), "\n")
cat("Has groundwater:", sum(pws_pfas$has_gw), "\n")

# ============================================================
# 2. Map PWSIDs to counties via ZIP codes
# ============================================================
cat("\nMapping PWSs to counties...\n")

# Load UCMR5 ZIP code file
pws_zips <- data.table::fread(file.path(data_dir, "ucmr5/UCMR5_ZIPCodes.txt"), sep = "\t")
cat("PWS-ZIP mappings:", nrow(pws_zips), "\n")

# Pad ZIP codes to 5 digits
pws_zips[, ZIPCODE := sprintf("%05d", as.integer(ZIPCODE))]

# Download HUD ZIP-to-county crosswalk (or use Census relationship file)
# Use Census ZCTA-to-county relationship file
zcta_url <- "https://www2.census.gov/geo/docs/maps-data/data/rel2020/zcta520/tab20_zcta520_county20_natl.txt"
zcta_file <- file.path(data_dir, "zcta_county.txt")

if (!file.exists(zcta_file)) {
  cat("Downloading ZCTA-county crosswalk...\n")
  resp <- httr::GET(zcta_url, httr::write_disk(zcta_file, overwrite = TRUE),
                    httr::timeout(60))
  stopifnot("ZCTA crosswalk download failed" = httr::status_code(resp) == 200)
}

zcta_county <- data.table::fread(zcta_file, sep = "|")
cat("ZCTA-county rows:", nrow(zcta_county), "\n")
cat("ZCTA-county columns:", paste(names(zcta_county), collapse = ", "), "\n")

# Get primary county for each ZCTA (highest area overlap)
# GEOID_COUNTY_20 is already the 5-digit FIPS
zcta_county[, county_fips := sprintf("%05d", as.integer(GEOID_COUNTY_20))]

# Keep the primary county for each ZCTA (largest AREALAND overlap)
zcta_primary <- zcta_county[order(-AREALAND_PART), .SD[1], by = GEOID_ZCTA5_20]
zcta_primary[, ZIPCODE := sprintf("%05d", as.integer(GEOID_ZCTA5_20))]

cat("Unique ZCTAs:", nrow(zcta_primary), "\n")

# Merge: PWS → ZIP → county
pws_county <- merge(pws_zips, zcta_primary[, .(ZIPCODE, county_fips)],
                    by = "ZIPCODE", all.x = FALSE)
# Keep first county per PWSID (some PWSs span multiple ZIPs)
pws_county <- pws_county[, .SD[1], by = PWSID]
cat("PWSs matched to county:", nrow(pws_county), "\n")

# Merge with PFAS data
pws_merged <- merge(pws_pfas, pws_county[, .(PWSID, county_fips)],
                    by = "PWSID", all.x = FALSE)
cat("PWSs with PFAS + county:", nrow(pws_merged), "\n")

# ============================================================
# 3. Load county-level karst data
# ============================================================
cat("\nLoading county karst data...\n")

karst <- data.table::fread(
  file.path(data_dir, "county_ssi/Table_CountyExposure_SSI_current/County_Area_by_SSI_bin_Current.csv")
)
cat("County karst rows:", nrow(karst), "\n")

# Build county FIPS
karst[, county_fips := sprintf("%02d%03d", as.integer(STATEFP), as.integer(COUNTYFP))]

# Compute karst exposure measures
# SSI bins: Bin1 = lowest susceptibility, Bin5 = highest (most karst)
# Karst fraction = (Bin3 + Bin4 + Bin5) / total area
karst[, karst_area_km2 := SS1_Bin3_Area_sqkm + SS1_Bin4_Area_sqkm + SS1_Bin5_Area_sqkm]
karst[, karst_frac := karst_area_km2 / County_Area_sqkm]
karst[, high_karst_area := SS1_Bin4_Area_sqkm + SS1_Bin5_Area_sqkm]
karst[, high_karst_frac := high_karst_area / County_Area_sqkm]
karst[, any_karst := as.integer(karst_area_km2 > 0)]
karst[, high_karst := as.integer(high_karst_frac > 0.1)]

cat("Counties with any karst:", sum(karst$any_karst), "\n")
cat("Counties with high karst (>10%):", sum(karst$high_karst), "\n")

# ============================================================
# 4. Merge PWS-level PFAS with county karst
# ============================================================
cat("\nMerging PFAS with karst...\n")

df <- merge(pws_merged, karst[, .(county_fips, karst_frac, high_karst_frac,
                                   any_karst, high_karst, karst_area_km2,
                                   County_Area_sqkm, STATENAME, NAMELSAD)],
            by = "county_fips", all.x = FALSE)

cat("Final merged dataset:", nrow(df), "PWSs\n")
cat("On karst county:", sum(df$any_karst), "\n")
cat("On high karst county:", sum(df$high_karst), "\n")

# ============================================================
# 5. Also create county-level aggregation for birth outcomes merge
# ============================================================
county_pfas <- df[, .(
  n_pws = .N,
  pct_detect = mean(any_detect, na.rm = TRUE),
  mean_max_pfas = mean(max_pfas_ppt, na.rm = TRUE),
  max_pfas = max(max_pfas_ppt, na.rm = TRUE),
  pct_above_mcl = mean(above_mcl, na.rm = TRUE),
  n_gw_pws = sum(has_gw)
), by = .(county_fips, karst_frac, high_karst_frac, any_karst, high_karst,
          STATENAME, NAMELSAD)]

county_pfas[is.infinite(max_pfas), max_pfas := 0]
cat("\nCounty-level summary:", nrow(county_pfas), "counties\n")

# ============================================================
# 6. Save
# ============================================================
saveRDS(df, file.path(data_dir, "pws_pfas_karst.rds"))
saveRDS(county_pfas, file.path(data_dir, "county_pfas_karst.rds"))

cat("\n=== Data Summary ===\n")
cat("PWSs total:", nrow(df), "\n")
cat("PWSs in karst counties:", sum(df$any_karst), "\n")
cat("PWSs in non-karst counties:", sum(!df$any_karst), "\n")
cat("Detection rate (karst):", mean(df$any_detect[df$any_karst == 1], na.rm = TRUE), "\n")
cat("Detection rate (non-karst):", mean(df$any_detect[df$any_karst == 0], na.rm = TRUE), "\n")
cat("Mean max PFAS (karst):", mean(df$max_pfas_ppt[df$any_karst == 1], na.rm = TRUE), "ppt\n")
cat("Mean max PFAS (non-karst):", mean(df$max_pfas_ppt[df$any_karst == 0], na.rm = TRUE), "ppt\n")
