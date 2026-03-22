## 02_clean_data.R — Construct analysis sample near state borders
## apep_0741: Hands-Free Driving Laws and Fatal Crashes at State Borders

source("00_packages.R")

data_dir <- "../data"

## ---- Load crash data ----
crashes <- fread(file.path(data_dir, "fars_accident_2015_2022.csv"))
cat("Total crashes loaded:", nrow(crashes), "\n")

## ---- Define treatment states and timing ----
# Handheld cellphone ban effective dates (month/year)
# Source: GHSA, IIHS, state statutes
treatment_info <- data.table(
  state_fips = c(41L, 13L, 47L, 27L, 18L, 25L, 51L),
  state_abbr = c("OR", "GA", "TN", "MN", "IN", "MA", "VA"),
  treat_year = c(2017L, 2018L, 2019L, 2019L, 2020L, 2020L, 2021L),
  treat_month = c(10L, 7L, 7L, 8L, 7L, 2L, 1L)
)

# FIPS codes for all states (we need these for neighbor identification)
state_fips_map <- data.table(
  fips = c(1:2, 4:6, 8:13, 15:42, 44:51, 53:56),
  abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL",
           "GA","HI","ID","IL","IN","IA","KS","KY","LA","ME",
           "MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
           "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI",
           "SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY")
)

## ---- Define border pairs ----
# Each pair: treated state + untreated neighbor at time of treatment
# We require the neighbor state did NOT have a handheld ban at the time
# States with pre-existing bans (before 2015): CA, CT, DE, HI, IL, MD, NV, NH, NJ, NY, OR, VT, WA, WV, DC
# (OR already had a ban that was strengthened in 2017; WA had one before 2015)
# For our staggered design, we use states that newly adopted 2017-2021

# Border pairs where the treated state borders an untreated state
# These are confirmed by checking which neighbor states lacked bans at treatment time
border_pairs <- data.table(
  pair_id = 1:10,
  treated_fips = c(13L, 13L, 13L, 47L, 47L, 27L, 27L, 18L, 51L, 51L),
  treated_abbr = c("GA","GA","GA","TN","TN","MN","MN","IN","VA","VA"),
  control_fips = c(1L, 12L, 45L, 28L, 21L, 35L, 46L, 36L, 21L, 37L),
  control_abbr = c("AL","FL","SC","MS","KY","ND","SD","OH","KY","NC")
)

# Add treatment timing to pairs
border_pairs <- merge(border_pairs,
                      treatment_info[, .(treated_fips = state_fips, treat_year, treat_month)],
                      by = "treated_fips")

cat("\nBorder pairs defined:\n")
print(border_pairs[, .(pair_id, treated_abbr, control_abbr, treat_year, treat_month)])

## ---- Download state boundaries for distance calculation ----
# Use US Census TIGER shapefiles
tiger_url <- "https://www2.census.gov/geo/tiger/GENZ2022/shp/cb_2022_us_state_500k.zip"
tiger_zip <- file.path(data_dir, "cb_2022_us_state_500k.zip")
tiger_dir <- file.path(data_dir, "tiger_states")

if (!file.exists(tiger_zip)) {
  cat("Downloading state boundaries...\n")
  result <- tryCatch(
    download.file(tiger_url, tiger_zip, mode = "wb", quiet = TRUE),
    error = function(e) stop("FATAL: Cannot download state boundaries: ", e$message)
  )
  if (result != 0) stop("FATAL: State boundary download failed")
}

dir.create(tiger_dir, showWarnings = FALSE)
unzip(tiger_zip, exdir = tiger_dir)

states_sf <- st_read(tiger_dir, quiet = TRUE)
states_sf <- states_sf[states_sf$STATEFP %in% sprintf("%02d", 1:56), ]

cat("State boundaries loaded:", nrow(states_sf), "states/territories\n")

## ---- Compute distance to relevant borders ----
# For each border pair, we need crashes in both states and their distance to the shared border

# Convert crashes to sf points
crashes_sf <- st_as_sf(crashes, coords = c("LONGITUD", "LATITUDE"), crs = 4326)
crashes_sf <- st_transform(crashes_sf, crs = 5070)  # Albers Equal Area for distance

# Also transform state boundaries
states_proj <- st_transform(states_sf, crs = 5070)

# Function to get shared border between two states
get_shared_border <- function(fips1, fips2) {
  s1 <- states_proj[states_proj$STATEFP == sprintf("%02d", fips1), ]
  s2 <- states_proj[states_proj$STATEFP == sprintf("%02d", fips2), ]
  border <- st_intersection(st_boundary(s1), st_boundary(s2))
  if (nrow(border) == 0 || st_is_empty(border)) return(NULL)
  return(border)
}

# Process each border pair
analysis_list <- list()
BW_KM <- 50  # Maximum bandwidth in km

for (i in 1:nrow(border_pairs)) {
  bp <- border_pairs[i]
  cat("\nProcessing pair", bp$pair_id, ":", bp$treated_abbr, "-", bp$control_abbr, "\n")

  # Get shared border
  border_line <- get_shared_border(bp$treated_fips, bp$control_fips)
  if (is.null(border_line)) {
    cat("  WARNING: No shared border found, skipping pair\n")
    next
  }

  # Get crashes in both states
  pair_crashes <- crashes_sf[crashes_sf$STATE %in% c(bp$treated_fips, bp$control_fips), ]
  cat("  Crashes in both states:", nrow(pair_crashes), "\n")

  # Compute distance to border (in meters)
  dist_to_border <- as.numeric(st_distance(pair_crashes, border_line))
  pair_crashes$dist_km <- dist_to_border / 1000

  # Keep only crashes within bandwidth
  pair_crashes <- pair_crashes[pair_crashes$dist_km <= BW_KM, ]
  cat("  Crashes within", BW_KM, "km of border:", nrow(pair_crashes), "\n")

  # Assign treatment status
  pair_crashes$treated_side <- as.integer(pair_crashes$STATE == bp$treated_fips)
  pair_crashes$pair_id <- bp$pair_id
  pair_crashes$treat_year <- bp$treat_year
  pair_crashes$treat_month <- bp$treat_month
  pair_crashes$treated_abbr <- bp$treated_abbr
  pair_crashes$control_abbr <- bp$control_abbr

  # Create signed distance: positive = treated side, negative = control side
  pair_crashes$signed_dist <- ifelse(pair_crashes$treated_side == 1,
                                     pair_crashes$dist_km,
                                     -pair_crashes$dist_km)

  # Post-treatment indicator
  pair_crashes$post <- as.integer(
    pair_crashes$YEAR > bp$treat_year |
    (pair_crashes$YEAR == bp$treat_year & pair_crashes$MONTH >= bp$treat_month)
  )

  # Convert back to data.table
  pair_dt <- as.data.table(st_drop_geometry(pair_crashes))
  analysis_list[[i]] <- pair_dt
}

## ---- Combine all border pairs ----
analysis <- rbindlist(analysis_list, use.names = TRUE, fill = TRUE)

cat("\n=== Analysis sample summary ===\n")
cat("Total crashes near borders:", nrow(analysis), "\n")
cat("Border pairs:", length(unique(analysis$pair_id)), "\n")
cat("Treated-side crashes:", sum(analysis$treated_side), "\n")
cat("Control-side crashes:", sum(1 - analysis$treated_side), "\n")
cat("Post-treatment crashes:", sum(analysis$post), "\n")
cat("Phone-distracted crashes:", sum(analysis$phone_distracted), "\n")
cat("Any-distraction crashes:", sum(analysis$any_distraction), "\n")

cat("\nCrashes by pair:\n")
print(analysis[, .(.N, phone = sum(phone_distracted), post = sum(post)),
               by = .(pair_id, treated_abbr, control_abbr)])

## ---- Aggregate to county-year-month cells ----
# For RDD, we can work at crash level (binary outcome = crash occurred)
# But for count outcomes, we need cells

# Create county-month panel
county_month <- analysis[, .(
  n_crashes = .N,
  n_phone = sum(phone_distracted),
  n_distracted = sum(any_distraction),
  n_nonphone = sum(nonphone_distracted),
  n_fatals = sum(FATALS),
  n_drunk = sum(DRUNK_DR > 0, na.rm = TRUE),
  mean_dist = mean(dist_km),
  median_dist = median(dist_km)
), by = .(pair_id, STATE, COUNTY, YEAR, MONTH, treated_side, post,
          treat_year, treat_month, treated_abbr, control_abbr)]

# Add signed distance (use mean distance for county)
county_month[, signed_dist := ifelse(treated_side == 1, mean_dist, -mean_dist)]

cat("\nCounty-month panel:", nrow(county_month), "observations\n")
cat("Unique counties:", uniqueN(county_month, by = c("STATE", "COUNTY")), "\n")

## ---- Save analysis datasets ----
fwrite(analysis, file.path(data_dir, "analysis_crash_level.csv"))
fwrite(county_month, file.path(data_dir, "analysis_county_month.csv"))

cat("\nSaved analysis datasets.\n")
cat("Done.\n")
