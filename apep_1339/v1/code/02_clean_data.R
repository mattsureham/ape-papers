## ==========================================================
## 02_clean_data.R — Clean and merge datasets
## Paper: Obsolete by Design (apep_1339)
## ==========================================================

source("00_packages.R")

data_dir <- "../data"

## -----------------------------------------------------------
## 1. Clean NID
## -----------------------------------------------------------
cat("=== Cleaning NID ===\n")

nid <- fread(file.path(data_dir, "nid_full.csv"), showProgress = FALSE)

# Standardize column names
setnames(nid, make.names(names(nid)))

# Key variables
nid[, `:=`(
  nid_id     = NID.ID,
  dam_name   = Dam.Name,
  lat        = as.numeric(Latitude),
  lon        = as.numeric(Longitude),
  state      = State,
  county     = County,
  year_built = as.numeric(Year.Completed),
  hazard     = Hazard.Potential.Classification,
  max_discharge_cfs = as.numeric(Max.Discharge..Cubic.Ft.Second.),
  drainage_area_sqmi = as.numeric(Drainage.Area..Sq.Miles.),
  storage_acft = as.numeric(NID.Storage..Acre.Ft.),
  dam_height_ft = as.numeric(NID.Height..Ft.),
  spillway_type = Spillway.Type,
  primary_purpose = Primary.Purpose,
  condition = Condition.Assessment
)]

# Filter to CONUS dams with valid data
dams <- nid[!is.na(lat) & !is.na(lon) &
              lat > 24 & lat < 50 &
              lon > -125 & lon < -66 &
              !is.na(year_built) & year_built > 1800 & year_built <= 2025,
            .(nid_id, dam_name, lat, lon, state, county, year_built,
              hazard, max_discharge_cfs, drainage_area_sqmi,
              storage_acft, dam_height_ft, spillway_type,
              primary_purpose, condition)]

cat("CONUS dams with valid data:", nrow(dams), "\n")

# Create vintage categories
dams[, vintage := fcase(
  year_built < 1950, "Pre-1950",
  year_built < 1970, "1950-1969",
  year_built < 1990, "1970-1989",
  year_built >= 1990, "1990+"
)]

# Create pre-1970 indicator (dams designed with TP-40 era or earlier standards)
dams[, pre1970 := as.integer(year_built < 1970)]

# Hazard classification
dams[, high_hazard := as.integer(hazard == "High")]
dams[, sig_hazard := as.integer(hazard %in% c("High", "Significant"))]

cat("Pre-1970 dams:", sum(dams$pre1970), "\n")
cat("High hazard:", sum(dams$high_hazard, na.rm = TRUE), "\n")
cat("Significant+:", sum(dams$sig_hazard, na.rm = TRUE), "\n")

## -----------------------------------------------------------
## 2. Construct FIPS codes for county-level aggregation
## -----------------------------------------------------------
cat("\n=== Constructing county identifiers ===\n")

# Use built-in R state data for mapping (full name → abbreviation → FIPS)
state_lookup <- data.table(
  state = c(state.name, "District of Columbia", "Puerto Rico", "Virgin Islands", "Guam"),
  state_abbr = c(state.abb, "DC", "PR", "VI", "GU"),
  fips_st = c(sprintf("%02d", c(1,2,4,5,6,8,9,10,12,13,15,16,17,18,19,20,21,22,23,24,
    25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,44,45,46,47,48,49,50,51,53,54,55,56)),
    "11", "72", "78", "66")
)

dams <- merge(dams, state_lookup[, .(state, fips_st, state_abbr)],
              by = "state", all.x = TRUE)
cat("FIPS mapping success:", sum(!is.na(dams$fips_st)), "/", nrow(dams), "\n")

## -----------------------------------------------------------
## 3. Aggregate NID to county level
## -----------------------------------------------------------
cat("\n=== Aggregating dams to county level ===\n")

# We need county FIPS. NID has state + county name.
# For a clean county-level panel, we'll create state-county keys
dams[, state_county := paste0(state, "_", toupper(county))]

# County-level dam statistics
county_dams <- dams[, .(
  n_dams          = .N,
  n_pre1970       = sum(pre1970),
  n_high_hazard   = sum(high_hazard, na.rm = TRUE),
  n_pre1970_high  = sum(pre1970 * high_hazard, na.rm = TRUE),
  total_storage   = sum(storage_acft, na.rm = TRUE),
  pre1970_storage = sum(storage_acft * pre1970, na.rm = TRUE),
  mean_year_built = mean(year_built),
  mean_dam_height = mean(dam_height_ft, na.rm = TRUE),
  mean_drainage   = mean(drainage_area_sqmi, na.rm = TRUE),
  mean_discharge  = mean(max_discharge_cfs, na.rm = TRUE),
  mean_lat        = mean(lat),
  mean_lon        = mean(lon)
), by = .(state, fips_st, county)]

# Share of pre-1970 dams
county_dams[, share_pre1970 := n_pre1970 / n_dams]

cat("Counties with dams:", nrow(county_dams), "\n")
cat("Counties with pre-1970 dams:", sum(county_dams$n_pre1970 > 0), "\n")
cat("Counties with pre-1970 high-hazard dams:", sum(county_dams$n_pre1970_high > 0), "\n")

## -----------------------------------------------------------
## 4. Clean FEMA declarations
## -----------------------------------------------------------
cat("\n=== Cleaning FEMA declarations ===\n")

decl <- fread(file.path(data_dir, "fema_flood_declarations.csv"))

# Extract year from declaration date
decl[, decl_year := as.integer(substr(declarationDate, 1, 4))]

# Create county FIPS
decl[, fips_county := paste0(
  sprintf("%02d", as.integer(fipsStateCode)),
  sprintf("%03d", as.integer(fipsCountyCode))
)]

# Filter to valid years
decl <- decl[decl_year >= 1970 & decl_year <= 2025]

# County-year flood declaration counts
county_year_decl <- decl[, .(
  n_flood_decl = .N,
  n_disasters  = uniqueN(disasterNumber)
), by = .(fips_st = sprintf("%02d", as.integer(fipsStateCode)),
          fips_county, decl_year)]

cat("FEMA county-year flood observations:", nrow(county_year_decl), "\n")
cat("Year range:", range(county_year_decl$decl_year), "\n")

## -----------------------------------------------------------
## 5. Clean NFIP Claims
## -----------------------------------------------------------
cat("\n=== Cleaning NFIP claims ===\n")

claims <- fread(file.path(data_dir, "nfip_claims.csv"))

# Create year and total paid
claims[, `:=`(
  claim_year = as.integer(yearOfLoss),
  total_paid = as.numeric(amountPaidOnBuildingClaim) +
               as.numeric(amountPaidOnContentsClaim)
)]

# County-year claim aggregation
claims[, fips_st := sprintf("%02d", as.integer(substr(countyCode, 1, 2)))]

county_year_claims <- claims[claim_year >= 1970 & claim_year <= 2025, .(
  n_claims   = .N,
  total_paid = sum(total_paid, na.rm = TRUE),
  mean_paid  = mean(total_paid, na.rm = TRUE)
), by = .(state, claim_year)]

cat("NFIP county-year claims:", nrow(county_year_claims), "\n")

## -----------------------------------------------------------
## 6. Build design gap proxy
## -----------------------------------------------------------
cat("\n=== Constructing design gap proxy ===\n")

# The design gap for each dam is approximated as:
# gap = (dam_age / 50) × regional_precip_change
#
# Rationale: Older dams were designed with older precipitation estimates.
# A dam built in 1960 used TP-40 (1961) data; a dam built in 1940 used
# even older estimates. The design gap grows with:
#   (a) dam age (older standards)
#   (b) regional precipitation increase (bigger mismatch)
#
# We construct a county-level design gap score as the
# storage-weighted mean dam age, interacted with
# the county's precipitation trend

# For now, use dam age as the primary treatment variable
# Will add precipitation trends from nClimDiv in analysis

## -----------------------------------------------------------
## 7. Save cleaned datasets
## -----------------------------------------------------------
cat("\n=== Saving cleaned data ===\n")

fwrite(dams, file.path(data_dir, "dams_clean.csv"))
fwrite(county_dams, file.path(data_dir, "county_dams.csv"))
fwrite(county_year_decl, file.path(data_dir, "county_year_declarations.csv"))
fwrite(county_year_claims, file.path(data_dir, "county_year_claims.csv"))

cat("Saved: dams_clean.csv, county_dams.csv, county_year_declarations.csv, county_year_claims.csv\n")

# Diagnostics for V1 validation
cat("\n=== Quick descriptives ===\n")
cat("Total dams:", nrow(dams), "\n")
cat("Pre-1970:", sum(dams$pre1970), "\n")
cat("Post-1970:", sum(!dams$pre1970), "\n")
cat("Counties:", nrow(county_dams), "\n")
cat("State distribution:\n")
print(head(sort(table(dams$state), decreasing = TRUE), 10))
