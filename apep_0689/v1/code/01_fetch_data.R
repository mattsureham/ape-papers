## 01_fetch_data.R — Data acquisition for apep_0689
## Downloads: HMDA (CFPB), Census ACS with geometry (flood risk proxy via coastal distance)

source("00_packages.R")

if (!requireNamespace("sf", quietly = TRUE)) install.packages("sf", repos = "https://cloud.r-project.org")
library(sf)

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. HMDA 2022 — Florida mortgage applications
# ============================================================
cat("=== Fetching HMDA 2022 Florida data ===\n")

hmda_file <- file.path(data_dir, "hmda_fl_2022.csv")

if (!file.exists(hmda_file)) {
  # CFPB Data Browser API — note: data-browser-api (not data-browser), needs -L for redirect
  hmda_url <- "https://ffiec.cfpb.gov/v2/data-browser-api/view/csv?years=2022&states=FL&actions_taken=1,3"

  cat("Downloading HMDA data from CFPB Data Browser API...\n")
  cmd <- sprintf('curl -sL --compressed -o "%s" "%s"', hmda_file, hmda_url)
  system(cmd)

  if (!file.exists(hmda_file) || file.size(hmda_file) < 10000) {
    stop("HMDA download failed or file is too small. Cannot proceed without real data.")
  }
  cat(sprintf("HMDA file size: %s MB\n", round(file.size(hmda_file) / 1e6, 1)))
}

# Column names from CFPB API use hyphens (read as-is, rename after)
# Force census_tract to character to prevent integer64 issues
hmda <- fread(hmda_file, colClasses = c(census_tract = "character"), select = c(
  "activity_year", "lei", "state_code", "county_code", "census_tract",
  "action_taken", "loan_type", "loan_purpose", "loan_amount",
  "interest_rate", "property_value", "income",
  "applicant_race-1", "applicant_ethnicity-1",
  "denial_reason-1", "denial_reason-2",
  "debt_to_income_ratio", "loan_to_value_ratio",
  "occupancy_type", "total_units", "purchaser_type",
  "tract_population", "tract_minority_population_percent",
  "ffiec_msa_md_median_family_income", "tract_to_msa_income_percentage",
  "tract_owner_occupied_units", "tract_one_to_four_family_homes",
  "tract_median_age_of_housing_units"
))

# Rename hyphenated columns
setnames(hmda, c("applicant_race-1", "applicant_ethnicity-1",
                  "denial_reason-1", "denial_reason-2"),
         c("applicant_race_1", "applicant_ethnicity_1",
           "denial_reason_1", "denial_reason_2"))

cat(sprintf("HMDA raw records: %s\n", format(nrow(hmda), big.mark = ",")))
stopifnot(nrow(hmda) > 10000)  # Must have real data

# ============================================================
# 2. Census ACS 5-Year Estimates — Florida tracts WITH GEOMETRY
# ============================================================
cat("\n=== Fetching ACS 5-Year Estimates with Geometry ===\n")

acs_file <- file.path(data_dir, "acs_fl_tracts_geo.rds")

if (!file.exists(acs_file)) {
  census_key <- Sys.getenv("CENSUS_API_KEY")
  if (nchar(census_key) > 0) {
    census_api_key(census_key, install = FALSE)
  }

  acs_vars <- c(
    median_income   = "B19013_001",  # Median household income
    total_pop       = "B01003_001",  # Total population
    total_housing   = "B25001_001",  # Total housing units
    owner_occupied  = "B25003_002",  # Owner-occupied units
    renter_occupied = "B25003_003",  # Renter-occupied units
    median_value    = "B25077_001",  # Median home value
    white_pop       = "B02001_002",  # White alone
    black_pop       = "B02001_003",  # Black alone
    hispanic_pop    = "B03003_003",  # Hispanic
    poverty_pop     = "B17001_002",  # Below poverty
    total_pov_denom = "B17001_001",  # Poverty universe
    bachelor_plus   = "B15003_022",  # Bachelor's degree
    total_25plus    = "B15003_001",  # Population 25+
    vacancy_rate_n  = "B25002_003",  # Vacant units
    total_units_occ = "B25002_001"   # Total units occupancy status
  )

  acs_fl <- get_acs(
    geography = "tract",
    variables = acs_vars,
    state = "FL",
    year = 2022,
    survey = "acs5",
    output = "wide",
    geometry = TRUE  # Include tract geometry for centroid computation
  )

  saveRDS(acs_fl, acs_file)
  cat(sprintf("ACS Florida tracts: %s\n", nrow(acs_fl)))
} else {
  acs_fl <- readRDS(acs_file)
  cat(sprintf("ACS Florida tracts (cached): %s\n", nrow(acs_fl)))
}

stopifnot(nrow(acs_fl) > 3000)

# ============================================================
# 3. Compute tract centroids and coastal distance
# ============================================================
cat("\n=== Computing coastal proximity ===\n")

# Get centroids
centroids <- st_centroid(acs_fl)
coords <- st_coordinates(centroids)

acs_fl$lon <- coords[, 1]
acs_fl$lat <- coords[, 2]

# Florida coastline approximation: compute minimum distance to coast
# Florida is bounded by water on three sides:
#   East coast: ~longitude -80 (Atlantic)
#   West coast: ~longitude -82 to -87 (Gulf)
#   South: ~latitude 25 (Keys)
# Use a simple Euclidean approximation — minimum distance to any coastal reference point

# Create a coastline reference: points along Florida's coast
# These are approximate reference points from which we compute min distance
fl_coast_points <- data.frame(
  lon = c(
    # Atlantic coast (east) - north to south
    -81.44, -81.40, -81.20, -80.95, -80.60, -80.35, -80.15, -80.10,
    -80.08, -80.07, -80.10, -80.15, -80.20, -80.25, -80.30,
    # South Florida / Keys
    -80.35, -80.50, -80.70, -81.00, -81.40, -81.80,
    # Gulf coast (west) - south to north
    -81.80, -82.00, -82.20, -82.45, -82.50, -82.60, -82.70, -82.65,
    -82.65, -82.75, -82.80, -83.00, -83.30, -83.60, -84.00, -84.30,
    -84.60, -84.90, -85.20, -85.40, -85.70, -86.00, -86.40, -86.60,
    -86.80, -87.00, -87.20, -87.40, -87.50
  ),
  lat = c(
    # Atlantic coast
    30.70, 30.40, 30.10, 29.80, 29.50, 29.10, 28.60, 28.10,
    27.50, 27.00, 26.70, 26.40, 26.10, 25.90, 25.80,
    # South Florida / Keys
    25.60, 25.40, 25.10, 24.80, 24.60, 24.55,
    # Gulf coast
    25.00, 25.80, 26.40, 26.90, 27.30, 27.60, 27.80, 28.10,
    28.40, 28.80, 29.00, 29.10, 29.20, 29.30, 29.60, 29.90,
    30.00, 30.10, 30.20, 30.30, 30.35, 30.38, 30.40, 30.40,
    30.38, 30.35, 30.32, 30.30, 30.30
  )
)

# Compute minimum distance from each tract centroid to nearest coast point
# Using simple Euclidean on lat/lon (approximately correct for Florida's latitude range)
# 1 degree lat ≈ 111 km, 1 degree lon ≈ 96 km at lat 28°
compute_coastal_distance <- function(tract_lon, tract_lat, coast_df) {
  # Convert to approximate km
  d_lon <- (tract_lon - coast_df$lon) * 96  # km
  d_lat <- (tract_lat - coast_df$lat) * 111  # km
  distances <- sqrt(d_lon^2 + d_lat^2)
  return(min(distances))
}

# Handle tracts with empty geometries (set to NA)
acs_fl$coast_dist_km <- NA_real_
valid <- !is.na(acs_fl$lon) & !is.na(acs_fl$lat)
cat(sprintf("Valid centroids: %d / %d\n", sum(valid), length(valid)))

acs_fl$coast_dist_km[valid] <- mapply(
  compute_coastal_distance,
  acs_fl$lon[valid], acs_fl$lat[valid],
  MoreArgs = list(coast_df = fl_coast_points)
)

cat(sprintf("Coastal distance: min=%.1f km, median=%.1f km, max=%.1f km\n",
            min(acs_fl$coast_dist_km), median(acs_fl$coast_dist_km), max(acs_fl$coast_dist_km)))

# ============================================================
# Save intermediate files
# ============================================================
saveRDS(hmda, file.path(data_dir, "hmda_fl_raw.rds"))
# Save ACS without geometry for merging
acs_df <- st_drop_geometry(acs_fl)
saveRDS(acs_df, file.path(data_dir, "acs_fl_with_coast.rds"))

cat("\n=== Data fetch complete ===\n")
cat(sprintf("  HMDA records:   %s\n", format(nrow(hmda), big.mark = ",")))
cat(sprintf("  ACS FL tracts:  %s (with coastal distance)\n", nrow(acs_fl)))
