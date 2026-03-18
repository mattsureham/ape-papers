## 01_fetch_data.R — Download NOAA tornado data and Census ACS data
## apep_0718: Tornado Paths and Manufactured Housing

source("00_packages.R")

cat("=== Step 1: Download NOAA Storm Prediction Center tornado data ===\n")

# Download tornado CSV
tornado_url <- "https://www.spc.noaa.gov/wcm/data/1950-2023_actual_tornadoes.csv"
tornado_file <- "../data/tornadoes_raw.csv"

if (!file.exists(tornado_file)) {
  download.file(tornado_url, tornado_file, method = "libcurl",
                headers = c("User-Agent" = "Mozilla/5.0 APEP-Research"))
  cat("Downloaded tornado data.\n")
} else {
  cat("Tornado data already exists, skipping download.\n")
}

# Read and validate
tornadoes <- read_csv(tornado_file, show_col_types = FALSE)
stopifnot("Failed to read tornado data" = nrow(tornadoes) > 50000)
cat(sprintf("Total tornado records: %d\n", nrow(tornadoes)))

# Check columns exist
required_cols <- c("yr", "mo", "dy", "st", "mag", "slat", "slon", "elat", "elon", "wid")
missing <- setdiff(required_cols, names(tornadoes))
if (length(missing) > 0) stop("Missing columns: ", paste(missing, collapse = ", "))

# Filter to EF2+ events with valid coordinates, 2000-2015
# (Need post-2015 ACS data to measure outcomes)
torn_ef2 <- tornadoes %>%
  filter(
    mag >= 2,           # EF2 or higher
    yr >= 2000,
    yr <= 2015,
    slat != 0, slon != 0,  # Valid start coordinates
    elat != 0, elon != 0,  # Valid end coordinates
    wid > 0                 # Valid width
  ) %>%
  mutate(
    # Width in yards -> convert to miles for spatial operations
    wid_miles = wid / 1760,
    # Unique tornado ID
    torn_id = paste0("T", yr, "_", sprintf("%03d", row_number()))
  )

cat(sprintf("EF2+ tornadoes 2000-2015 with valid coords: %d\n", nrow(torn_ef2)))
cat(sprintf("  EF2: %d, EF3: %d, EF4: %d, EF5: %d\n",
            sum(torn_ef2$mag == 2), sum(torn_ef2$mag == 3),
            sum(torn_ef2$mag == 4), sum(torn_ef2$mag == 5)))

stopifnot("Insufficient EF2+ tornadoes" = nrow(torn_ef2) >= 100)

# Save filtered tornado data
saveRDS(torn_ef2, "../data/tornadoes_ef2plus.rds")

cat("\n=== Step 2: Create tornado path polygons ===\n")

# Create line geometries from start/end coordinates, then buffer by half-width
torn_lines <- torn_ef2 %>%
  rowwise() %>%
  mutate(
    geometry = list(st_linestring(matrix(c(slon, slat, elon, elat), ncol = 2, byrow = TRUE)))
  ) %>%
  ungroup() %>%
  st_as_sf(crs = 4326)

# Project to Albers Equal Area for accurate buffering (in meters)
torn_lines_proj <- st_transform(torn_lines, 5070)

# Buffer each line by half the path width (width is full width in yards)
# Convert yards to meters: 1 yard = 0.9144 meters
torn_paths <- torn_lines_proj %>%
  mutate(
    buffer_m = (wid / 2) * 0.9144  # half-width in meters
  ) %>%
  rowwise() %>%
  mutate(
    geometry = st_buffer(geometry, dist = buffer_m)
  ) %>%
  ungroup() %>%
  st_as_sf()

cat(sprintf("Created %d tornado path polygons.\n", nrow(torn_paths)))

# Also create "near-path" buffer zones (within 2 miles of path edge but outside path)
torn_outer_buffer <- torn_lines_proj %>%
  mutate(
    outer_buffer_m = (wid / 2) * 0.9144 + 3218.69  # path edge + 2 miles in meters
  ) %>%
  rowwise() %>%
  mutate(
    geometry = st_buffer(geometry, dist = outer_buffer_m)
  ) %>%
  ungroup() %>%
  st_as_sf()

saveRDS(torn_paths, "../data/tornado_path_polygons.rds")
saveRDS(torn_outer_buffer, "../data/tornado_outer_buffer.rds")

cat("\n=== Step 3: Download census tract boundaries ===\n")

# States with significant EF2+ tornado activity
tornado_states <- torn_ef2 %>%
  count(st, sort = TRUE) %>%
  filter(n >= 3) %>%
  pull(st)

# Map state abbreviations to FIPS codes
state_fips <- tigris::fips_codes %>%
  select(state, state_code) %>%
  distinct() %>%
  filter(state %in% tornado_states)

cat(sprintf("Downloading tract boundaries for %d states: %s\n",
            nrow(state_fips), paste(state_fips$state, collapse = ", ")))

# Download tract boundaries for all tornado states
tracts_list <- list()
for (i in seq_len(nrow(state_fips))) {
  st_abbr <- state_fips$state[i]
  st_fips <- state_fips$state_code[i]
  cat(sprintf("  Downloading tracts for %s (%s)...\n", st_abbr, st_fips))
  tracts_list[[st_abbr]] <- tracts(state = st_fips, year = 2020, cb = TRUE) %>%
    st_transform(5070)  # Project to Albers
}

tracts_all <- bind_rows(tracts_list)
cat(sprintf("Total census tracts downloaded: %d\n", nrow(tracts_all)))

saveRDS(tracts_all, "../data/census_tracts.rds")

cat("\n=== Step 4: Spatial join — classify tracts ===\n")

# Compute tract centroids
tracts_centroids <- tracts_all %>%
  mutate(centroid = st_centroid(geometry))

# For each tract, find minimum distance to any tornado path edge
# Positive = outside path, Negative = inside path
cat("Computing signed distances to tornado path edges...\n")

# First: which tracts intersect any tornado path?
tract_in_path <- st_intersects(tracts_all, torn_paths, sparse = TRUE)
tracts_all$in_path <- lengths(tract_in_path) > 0

# Which tracts are within the outer buffer (near-path control zone)?
tract_near <- st_intersects(tracts_all, torn_outer_buffer, sparse = TRUE)
tracts_all$near_path <- lengths(tract_near) > 0

# Compute distance from tract centroid to nearest path polygon edge
# This is computationally intensive — do it for near-path tracts only
near_tracts <- tracts_all %>% filter(near_path)
cat(sprintf("Computing distances for %d near-path tracts...\n", nrow(near_tracts)))

# Get centroids
near_centroids <- st_centroid(near_tracts)

# Compute minimum distance to any path polygon boundary
# For tracts INSIDE a path, distance is negative
distances <- numeric(nrow(near_tracts))

for (i in seq_len(nrow(near_tracts))) {
  if (i %% 500 == 0) cat(sprintf("  Processing tract %d / %d\n", i, nrow(near_tracts)))

  centroid_i <- near_centroids[i, ]

  # Distance to nearest path polygon
  dist_to_paths <- st_distance(centroid_i, torn_paths)
  min_dist <- min(as.numeric(dist_to_paths))

  # Check if inside any path
  if (near_tracts$in_path[i]) {
    distances[i] <- -min_dist  # Negative = inside
  } else {
    distances[i] <- min_dist   # Positive = outside
  }
}

near_tracts$dist_to_path_m <- distances
near_tracts$dist_to_path_mi <- distances / 1609.34  # Convert to miles

# Find which tornado(es) are nearest to each tract (for matching pre/post timing)
cat("Matching tracts to nearest tornado event year...\n")
nearest_torn_year <- integer(nrow(near_tracts))

for (i in seq_len(nrow(near_tracts))) {
  centroid_i <- near_centroids[i, ]
  dist_to_paths <- as.numeric(st_distance(centroid_i, torn_paths))
  nearest_idx <- which.min(dist_to_paths)
  nearest_torn_year[i] <- torn_paths$yr[nearest_idx]
}

near_tracts$tornado_year <- nearest_torn_year

saveRDS(near_tracts, "../data/tracts_with_distances.rds")
cat(sprintf("Tracts in path: %d, Near path (control zone): %d\n",
            sum(near_tracts$in_path), sum(!near_tracts$in_path)))

cat("\n=== Step 5: Download ACS data for near-path tracts ===\n")

# Variables to fetch
acs_vars <- c(
  mobile_homes  = "B25024_010",  # Mobile homes
  total_units   = "B25024_001",  # Total housing units
  poverty_num   = "B17001_002",  # Below poverty
  poverty_denom = "B17001_001",  # Total for poverty
  median_value  = "B25077_001",  # Median housing value
  total_pop     = "B01003_001",  # Total population
  median_income = "B19013_001",  # Median household income
  vacant_units  = "B25002_003",  # Vacant housing units
  owner_occ     = "B25003_002",  # Owner-occupied
  renter_occ    = "B25003_003"   # Renter-occupied
)

# Get unique tract GEOIDs for filtering
target_geoids <- near_tracts$GEOID

# Fetch pre-tornado ACS (2006-2010)
cat("Fetching ACS 2006-2010 (pre-tornado)...\n")
acs_pre_list <- list()
for (i in seq_len(nrow(state_fips))) {
  st_fips <- state_fips$state_code[i]
  cat(sprintf("  ACS pre: state %s\n", state_fips$state[i]))
  acs_pre_list[[i]] <- get_acs(
    geography = "tract",
    variables = acs_vars,
    state = st_fips,
    year = 2010,
    survey = "acs5",
    output = "wide",
    geometry = FALSE
  )
}
acs_pre <- bind_rows(acs_pre_list) %>%
  filter(GEOID %in% target_geoids) %>%
  mutate(period = "pre")

# Fetch post-tornado ACS (2018-2022)
cat("Fetching ACS 2018-2022 (post-tornado)...\n")
acs_post_list <- list()
for (i in seq_len(nrow(state_fips))) {
  st_fips <- state_fips$state_code[i]
  cat(sprintf("  ACS post: state %s\n", state_fips$state[i]))
  acs_post_list[[i]] <- get_acs(
    geography = "tract",
    variables = acs_vars,
    state = st_fips,
    year = 2022,
    survey = "acs5",
    output = "wide",
    geometry = FALSE
  )
}
acs_post <- bind_rows(acs_post_list) %>%
  filter(GEOID %in% target_geoids) %>%
  mutate(period = "post")

# Combine and compute outcomes
acs_combined <- bind_rows(acs_pre, acs_post) %>%
  mutate(
    mobile_pct = mobile_homesE / total_unitsE * 100,
    poverty_rate = poverty_numE / poverty_denomE * 100,
    vacancy_rate = vacant_unitsE / total_unitsE * 100
  )

saveRDS(acs_combined, "../data/acs_combined.rds")

cat(sprintf("\nACS data fetched: %d tract-period observations\n", nrow(acs_combined)))
cat(sprintf("Pre-period: %d tracts, Post-period: %d tracts\n",
            sum(acs_combined$period == "pre"), sum(acs_combined$period == "post")))

# Validate: data is real and substantial
stopifnot("No ACS data fetched" = nrow(acs_combined) > 0)
stopifnot("Missing pre-period data" = sum(acs_combined$period == "pre") > 100)
stopifnot("Missing post-period data" = sum(acs_combined$period == "post") > 100)

cat("\n=== Data fetch complete. ===\n")
cat(sprintf("Tornado events: %d EF2+ (2000-2015)\n", nrow(torn_ef2)))
cat(sprintf("Census tracts in analysis: %d\n", nrow(near_tracts)))
cat(sprintf("ACS observations: %d\n", nrow(acs_combined)))
