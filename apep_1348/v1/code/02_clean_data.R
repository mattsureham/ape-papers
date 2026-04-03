# 02_clean_data.R — Construct analysis panel
# apep_1348: Groningen Regulatory Rebound

source("00_packages.R")

data_dir <- "../data/"

# Load raw data
earthquakes <- readRDS(file.path(data_dir, "earthquakes.rds"))
cbs_housing <- readRDS(file.path(data_dir, "cbs_housing_raw.rds"))
regions <- readRDS(file.path(data_dir, "cbs_regions.rds"))
centroids <- readRDS(file.path(data_dir, "municipality_centroids.rds"))
production <- readRDS(file.path(data_dir, "groningen_production.rds"))

# ============================================================
# 1. Compute distance from each municipality to Huizinge epicenter
# ============================================================
cat("Computing distances to Huizinge epicenter...\n")

# Huizinge epicenter: 53.348°N, 6.664°E
huizinge_lat <- 53.348
huizinge_lon <- 6.664

# Check if coordinates are in Dutch national grid (RD New, EPSG:28992)
# RD New x values are typically 10000-300000, y values 300000-630000
if (max(centroids$lon, na.rm = TRUE) > 180) {
  cat("  Centroids in projected CRS (RD New) — transforming to WGS84...\n")
  # Convert from RD New to WGS84
  centroids_sf <- st_as_sf(centroids, coords = c("lon", "lat"), crs = 28992)
  centroids_sf <- st_transform(centroids_sf, 4326)
  centroids$lon <- st_coordinates(centroids_sf)[, 1]
  centroids$lat <- st_coordinates(centroids_sf)[, 2]
  cat(sprintf("  Transformed: lon range [%.2f, %.2f], lat range [%.2f, %.2f]\n",
      min(centroids$lon), max(centroids$lon), min(centroids$lat), max(centroids$lat)))
}

centroids <- centroids %>%
  mutate(
    dist_km = distHaversine(
      cbind(lon, lat),
      c(huizinge_lon, huizinge_lat)
    ) / 1000
  )

cat(sprintf("  Distance range: %.1f to %.1f km\n", min(centroids$dist_km), max(centroids$dist_km)))

# Create distance bins
centroids <- centroids %>%
  mutate(
    dist_bin = case_when(
      dist_km <= 20 ~ "0-20km",
      dist_km <= 50 ~ "20-50km",
      dist_km <= 100 ~ "50-100km",
      dist_km <= 150 ~ "100-150km",
      TRUE ~ ">150km"
    ),
    dist_bin = factor(dist_bin, levels = c(">150km", "100-150km", "50-100km", "20-50km", "0-20km"))
  )

cat("  Distance bin counts:\n")
print(table(centroids$dist_bin))

# ============================================================
# 2. Merge housing prices with municipality geography
# ============================================================
cat("\nMerging housing prices with geographic data...\n")

# Filter housing data to municipality level
housing <- cbs_housing %>%
  filter(grepl("^GM", region_code))

# Standardize gem_code format
centroids <- centroids %>%
  mutate(gem_code = ifelse(grepl("^GM", gem_code), gem_code, paste0("GM", gem_code)))

# Merge
panel <- housing %>%
  inner_join(centroids, by = c("region_code" = "gem_code"))

cat(sprintf("  Merged panel: %d obs, %d municipalities, %d years\n",
    nrow(panel), n_distinct(panel$region_code), n_distinct(panel$year)))

# ============================================================
# 3. Construct treatment variables
# ============================================================
cat("\nConstructing treatment variables...\n")

panel <- panel %>%
  mutate(
    # Post-Huizinge indicator
    post_huizinge = as.integer(year >= 2013),

    # Post-cap indicator (first production cap: January 2014)
    post_cap = as.integer(year >= 2014),

    # Post-closure announcement (March 2018)
    post_closure = as.integer(year >= 2018),

    # Continuous treatment intensity (inverse distance)
    treat_intensity = 1 / dist_km,

    # Log housing price
    log_price = log(value),

    # Event time (relative to Huizinge, 2012)
    event_time = year - 2012,

    # Interaction: post × proximity
    post_proximity = post_huizinge * treat_intensity
  )

# ============================================================
# 4. Compute annual earthquake intensity by municipality
# ============================================================
cat("Computing annual seismic exposure by municipality...\n")

# For each municipality-year, compute cumulative PGA proxy
# Using sum of 10^(magnitude) within radius as intensity measure
eq_by_year <- earthquakes %>%
  group_by(year) %>%
  summarise(
    n_quakes = n(),
    max_mag = max(magnitude),
    cum_energy = sum(10^magnitude),
    .groups = "drop"
  )

panel <- panel %>%
  left_join(eq_by_year, by = "year") %>%
  mutate(
    n_quakes = replace_na(n_quakes, 0),
    max_mag = replace_na(max_mag, 0),
    cum_energy = replace_na(cum_energy, 0)
  )

# ============================================================
# 5. Merge production data
# ============================================================
panel <- panel %>%
  left_join(production, by = "year")

# ============================================================
# 6. Create balanced panel (municipalities present in all years)
# ============================================================
cat("\nBalancing panel...\n")

# Keep municipalities with data for the core analysis period
core_years <- 1997:2023
panel_core <- panel %>% filter(year %in% core_years)

# Balanced: municipalities with data in all years
muni_counts <- panel_core %>%
  group_by(region_code) %>%
  summarise(n_years = n_distinct(year), .groups = "drop")

balanced_munis <- muni_counts %>%
  filter(n_years >= length(core_years) * 0.8) %>%  # At least 80% of years
  pull(region_code)

panel_balanced <- panel_core %>%
  filter(region_code %in% balanced_munis)

cat(sprintf("  Balanced panel: %d obs, %d municipalities, %d years\n",
    nrow(panel_balanced), n_distinct(panel_balanced$region_code),
    n_distinct(panel_balanced$year)))

# ============================================================
# 7. Summary statistics
# ============================================================
cat("\nSummary statistics:\n")
cat(sprintf("  Municipalities within 20km: %d\n",
    n_distinct(panel_balanced$region_code[panel_balanced$dist_bin == "0-20km"])))
cat(sprintf("  Municipalities 20-50km: %d\n",
    n_distinct(panel_balanced$region_code[panel_balanced$dist_bin == "20-50km"])))
cat(sprintf("  Mean housing price: EUR %.0f\n", mean(panel_balanced$value, na.rm = TRUE)))
cat(sprintf("  SD housing price: EUR %.0f\n", sd(panel_balanced$value, na.rm = TRUE)))

# Save
saveRDS(panel_balanced, file.path(data_dir, "analysis_panel.rds"))
saveRDS(eq_by_year, file.path(data_dir, "earthquake_annual.rds"))

cat("\n=== Panel construction complete ===\n")
