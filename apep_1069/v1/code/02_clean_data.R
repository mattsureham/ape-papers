## 02_clean_data.R — Construct earthquake exposure + merge datasets
## apep_1069: The Compensation Cliff

source("00_packages.R")

data_dir <- "../data"

# ============================================================================
# 1. Load Raw Data
# ============================================================================
cat("=== Loading raw data ===\n")
eq_gron <- readRDS(file.path(data_dir, "earthquakes_groningen.rds"))
buurt_panel <- readRDS(file.path(data_dir, "buurt_panel_raw.rds"))
municipalities <- readRDS(file.path(data_dir, "study_municipalities.rds"))

cat("Earthquakes:", nrow(eq_gron), "\n")
cat("Buurt-year obs:", nrow(buurt_panel), "\n")

# ============================================================================
# 2. Get Buurt Geographic Data from PDOK (paginated WFS)
# ============================================================================
cat("\n=== Fetching complete buurt boundaries ===\n")

# Paginate WFS to get all buurten
fetch_buurt_page <- function(start_index, count = 1000, year = "2023") {
  url <- paste0(
    "https://service.pdok.nl/cbs/wijkenbuurten/", year, "/wfs/v1_0",
    "?service=WFS&version=2.0.0&request=GetFeature",
    "&typeName=buurten&outputFormat=json",
    "&count=", count,
    "&startIndex=", start_index
  )
  tryCatch(
    st_read(url, quiet = TRUE),
    error = function(e) NULL
  )
}

# Try to get all buurten via pagination
all_buurten <- list()
page <- 0
repeat {
  cat("  Fetching buurten page", page + 1, "(start:", page * 1000, ")...\n")
  result <- fetch_buurt_page(page * 1000, count = 1000, year = "2023")
  if (is.null(result) || nrow(result) == 0) {
    # Try 2022 if 2023 fails
    result <- fetch_buurt_page(page * 1000, count = 1000, year = "2022")
  }
  if (is.null(result) || nrow(result) == 0) break
  all_buurten[[page + 1]] <- result
  cat("    Got", nrow(result), "features\n")
  if (nrow(result) < 1000) break  # Last page
  page <- page + 1
  Sys.sleep(0.5)
  if (page > 20) break  # Safety limit (20k buurten max)
}

if (length(all_buurten) > 0) {
  buurt_geo <- do.call(rbind, all_buurten)
  cat("Total buurten with geometry:", nrow(buurt_geo), "\n")
} else {
  # Fallback: use the 1000 we already have
  buurt_geo <- readRDS(file.path(data_dir, "buurt_geo.rds"))
  cat("Using cached buurten:", nrow(buurt_geo), "\n")
}

# Standardize column names
names(buurt_geo) <- tolower(names(buurt_geo))
# Find the buurt code column
code_col <- intersect(c("buurtcode", "buurtnaam", "statcode", "code"), names(buurt_geo))
name_col_geo <- intersect(c("buurtnaam", "naam"), names(buurt_geo))
gem_col <- intersect(c("gemeentenaam", "gm_naam"), names(buurt_geo))

cat("Geo columns:", paste(names(buurt_geo), collapse = ", "), "\n")

# ============================================================================
# 3. Filter to Study Area
# ============================================================================
cat("\n=== Filtering to study area ===\n")

# First, find which column has municipality name
if (length(gem_col) > 0) {
  buurt_study <- buurt_geo %>%
    filter(.data[[gem_col[1]]] %in% municipalities$all)
  cat("Buurten in study municipalities:", nrow(buurt_study), "\n")
} else {
  # If no municipality column, use all buurten and filter later
  buurt_study <- buurt_geo
  cat("No municipality column found, using all", nrow(buurt_study), "buurten\n")
}

# Calculate buurt centroids
buurt_centroids <- buurt_study %>%
  st_centroid() %>%
  mutate(
    centroid_lon = st_coordinates(.)[, 1],
    centroid_lat = st_coordinates(.)[, 2]
  )

# Check coordinate system - PDOK typically uses EPSG:28992 (RD New)
cat("CRS:", st_crs(buurt_centroids)$input, "\n")

# Transform to WGS84 for distance calculations with earthquake locations
if (st_crs(buurt_centroids)$epsg != 4326) {
  buurt_centroids_wgs84 <- st_transform(buurt_centroids, 4326)
  buurt_centroids$lon_wgs84 <- st_coordinates(buurt_centroids_wgs84)[, 1]
  buurt_centroids$lat_wgs84 <- st_coordinates(buurt_centroids_wgs84)[, 2]
} else {
  buurt_centroids$lon_wgs84 <- buurt_centroids$centroid_lon
  buurt_centroids$lat_wgs84 <- buurt_centroids$centroid_lat
}

# ============================================================================
# 4. Construct Earthquake Exposure Measure
# ============================================================================
cat("\n=== Constructing earthquake exposure ===\n")

# For each buurt centroid, calculate cumulative PGA from all earthquakes
# Using simplified GMPE: log10(PGA) = a + b*M - c*log10(R) - d*R
# Groningen-specific GMPE (simplified from Bommer et al. 2017):
#   log10(PGA) ≈ -1.0 + 0.5*M - 1.5*log10(R+1)
# where M = magnitude, R = hypocentral distance (km)

# Haversine distance function
haversine_km <- function(lat1, lon1, lat2, lon2) {
  R <- 6371  # Earth radius in km
  dlat <- (lat2 - lat1) * pi / 180
  dlon <- (lon2 - lon1) * pi / 180
  a <- sin(dlat/2)^2 + cos(lat1*pi/180) * cos(lat2*pi/180) * sin(dlon/2)^2
  2 * R * asin(sqrt(a))
}

# Get buurt centroid coordinates (WGS84)
buurt_pts <- buurt_centroids %>%
  st_drop_geometry() %>%
  select(any_of(c(code_col, name_col_geo, gem_col, "lon_wgs84", "lat_wgs84")))

# Find the actual buurt code in buurt_pts
buurt_code_col <- intersect(c("buurtcode", "statcode", "code"), names(buurt_pts))[1]
if (is.na(buurt_code_col)) {
  cat("Available buurt columns:", paste(names(buurt_pts), collapse = ", "), "\n")
  # Try to find any column that looks like a buurt code (starts with BU)
  for (col in names(buurt_pts)) {
    if (is.character(buurt_pts[[col]]) && any(grepl("^BU", buurt_pts[[col]]))) {
      buurt_code_col <- col
      cat("Found buurt code column:", col, "\n")
      break
    }
  }
}

cat("Buurt code column:", buurt_code_col, "\n")
cat("Sample buurt codes:", head(buurt_pts[[buurt_code_col]], 5), "\n")

# Calculate earthquake exposure for each buurt
# Pre-2020 cumulative PGA (seismic history before compensation announcement)
eq_pre2020 <- eq_gron %>% filter(date < as.Date("2020-09-01"))
cat("Pre-2020 earthquakes (Groningen):", nrow(eq_pre2020), "\n")

# Calculate PGA contribution from each earthquake to each buurt
cat("Calculating earthquake exposure for", nrow(buurt_pts), "buurten...\n")

exposure_list <- lapply(seq_len(nrow(buurt_pts)), function(i) {
  b_lat <- buurt_pts$lat_wgs84[i]
  b_lon <- buurt_pts$lon_wgs84[i]

  # Distance to each earthquake
  dists <- haversine_km(b_lat, b_lon, eq_pre2020$lat, eq_pre2020$lon)
  hypo_dist <- sqrt(dists^2 + eq_pre2020$depth^2)  # Hypocentral distance

  # PGA from each earthquake (cm/s^2)
  log10_pga <- -1.0 + 0.5 * eq_pre2020$mag - 1.5 * log10(pmax(hypo_dist, 0.5))
  pga <- 10^log10_pga

  data.frame(
    buurt_code = buurt_pts[[buurt_code_col]][i],
    cum_pga = sum(pga, na.rm = TRUE),
    max_pga = max(pga, na.rm = TRUE),
    n_earthquakes_10km = sum(dists <= 10),
    n_earthquakes_20km = sum(dists <= 20),
    mean_dist_eq = mean(dists[dists <= 50], na.rm = TRUE),
    n_mag2plus = sum(eq_pre2020$mag >= 2.0 & dists <= 30)
  )
})

exposure_df <- bind_rows(exposure_list)
cat("Exposure calculated for", nrow(exposure_df), "buurten\n")
cat("Cumulative PGA range:", round(min(exposure_df$cum_pga), 2), "-",
    round(max(exposure_df$cum_pga), 2), "\n")
cat("Max single-event PGA range:", round(min(exposure_df$max_pga), 2), "-",
    round(max(exposure_df$max_pga), 2), "\n")

# ============================================================================
# 5. Define Treatment Groups
# ============================================================================
cat("\n=== Defining treatment groups ===\n")

# The IMG compensation zone roughly corresponds to PC4 areas with high
# earthquake exposure. We define treatment based on cumulative PGA.
# The actual IMG threshold was 20% of buildings with damage claims,
# which correlates strongly with earthquake intensity.

# Use median split as primary, also create terciles
exposure_df <- exposure_df %>%
  mutate(
    # Primary: above-median cumulative PGA
    treated_median = as.integer(cum_pga > median(cum_pga)),
    # Terciles for heterogeneity
    exposure_tercile = ntile(cum_pga, 3),
    # Log exposure for continuous treatment
    log_cum_pga = log(cum_pga + 1),
    # Quartiles
    exposure_quartile = ntile(cum_pga, 4)
  )

cat("Treatment (median split):\n")
print(table(exposure_df$treated_median))
cat("\nExposure terciles:\n")
print(table(exposure_df$exposure_tercile))

# ============================================================================
# 6. Merge Exposure with Buurt Panel
# ============================================================================
cat("\n=== Merging exposure with CBS panel ===\n")

# Clean buurt codes for merging
buurt_panel <- buurt_panel %>%
  mutate(buurt_code = trimws(region_code))

exposure_df <- exposure_df %>%
  mutate(buurt_code = trimws(buurt_code))

# Check format match
cat("Panel buurt code sample:", head(unique(buurt_panel$buurt_code), 3), "\n")
cat("Exposure buurt code sample:", head(unique(exposure_df$buurt_code), 3), "\n")

# Merge
panel <- buurt_panel %>%
  inner_join(exposure_df, by = "buurt_code")

cat("Merged panel:", nrow(panel), "observations\n")
cat("Unique buurten:", n_distinct(panel$buurt_code), "\n")
cat("Years:", sort(unique(panel$year)), "\n")

if (nrow(panel) < 100) {
  cat("\nWARNING: Very few matches. Checking code format mismatch...\n")
  cat("Panel codes (first 10):", head(unique(buurt_panel$buurt_code), 10), "\n")
  cat("Exposure codes (first 10):", head(unique(exposure_df$buurt_code), 10), "\n")

  # Try matching without the 'BU' prefix
  panel_alt <- buurt_panel %>%
    mutate(buurt_code_short = gsub("^BU", "", buurt_code)) %>%
    inner_join(
      exposure_df %>% mutate(buurt_code_short = gsub("^BU", "", buurt_code)),
      by = "buurt_code_short"
    )
  cat("Alternative match:", nrow(panel_alt), "\n")

  if (nrow(panel_alt) > nrow(panel)) {
    panel <- panel_alt %>%
      mutate(buurt_code = buurt_code.x) %>%
      select(-buurt_code.x, -buurt_code.y, -buurt_code_short)
  }
}

# ============================================================================
# 7. Clean and Prepare Analysis Dataset
# ============================================================================
cat("\n=== Preparing analysis dataset ===\n")

# Create post-treatment indicator (September 2020 announcement)
# WOZ values reflect January 1 of each year, so WOZ 2021+ reflects post-announcement
panel <- panel %>%
  mutate(
    post = as.integer(year >= 2021),
    # WOZ in thousands
    woz = as.numeric(woz_avg),
    log_woz = log(pmax(woz, 1)),
    # Housing characteristics
    n_dwellings = as.numeric(housing_stock),
    pct_owner = as.numeric(owner_occupied_pct)
  ) %>%
  filter(!is.na(woz), woz > 0)

# Add municipality info from geo data if available
if (length(gem_col) > 0) {
  gem_lookup <- buurt_centroids %>%
    st_drop_geometry() %>%
    select(buurt_code = all_of(buurt_code_col), gemeente = all_of(gem_col[1]))
  panel <- panel %>% left_join(gem_lookup, by = "buurt_code")
}

cat("\nFinal panel:\n")
cat("  Observations:", nrow(panel), "\n")
cat("  Buurten:", n_distinct(panel$buurt_code), "\n")
cat("  Years:", paste(sort(unique(panel$year)), collapse = ", "), "\n")
cat("  Treated (median):", sum(panel$treated_median == 1 & panel$year == min(panel$year)), "\n")
cat("  Control (median):", sum(panel$treated_median == 0 & panel$year == min(panel$year)), "\n")
cat("  Mean WOZ (000s):", round(mean(panel$woz, na.rm = TRUE), 1), "\n")
cat("  SD WOZ (000s):", round(sd(panel$woz, na.rm = TRUE), 1), "\n")

# Save analysis dataset
saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
saveRDS(exposure_df, file.path(data_dir, "exposure.rds"))
saveRDS(buurt_centroids, file.path(data_dir, "buurt_centroids.rds"))

cat("\n=== Clean data complete ===\n")
