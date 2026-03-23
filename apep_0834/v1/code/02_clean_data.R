## 02_clean_data.R — Build analysis dataset: stations x land prices
source("00_packages.R")

data_dir <- "../data"
s12_list <- readRDS(file.path(data_dir, "s12_raw_list.rds"))
l01_list <- readRDS(file.path(data_dir, "l01_raw_list.rds"))

## ===========================================================================
## 1. STATION DATA — Extract passenger counts from 2019 file (best coverage)
## ===========================================================================
# The 2019 file has Japanese names and contains passenger counts for FY2011-FY2018
s19 <- s12_list[["2019"]]
cat(sprintf("S12 2019: %d stations\n", nrow(s19)))

# Extract station name, coordinates, and yearly passenger counts
# Convert to centroids to handle MULTIPOINT geometries
s19_centroids <- s19 %>%
  st_transform(4326) %>%
  st_centroid()

coords <- st_coordinates(s19_centroids)

station_df <- s19 %>%
  st_drop_geometry() %>%
  mutate(
    station_name = `駅名`,
    operator     = `運営会社`,
    rail_line    = `路線名`,
    rail_type    = as.numeric(`鉄道区分`),
    pass_2011 = as.numeric(`乗降客数11`),
    pass_2012 = as.numeric(`乗降客数12`),
    pass_2013 = as.numeric(`乗降客数13`),
    pass_2014 = as.numeric(`乗降客数14`),
    pass_2015 = as.numeric(`乗降客数15`),
    pass_2016 = as.numeric(`乗降客数16`),
    pass_2017 = as.numeric(`乗降客数17`),
    pass_2018 = as.numeric(`乗降客数18`),
    lon = coords[, 1],
    lat = coords[, 2]
  ) %>%
  select(station_name, operator, rail_line, rail_type, lon, lat,
         starts_with("pass_"))

# Compute average daily users (pre-COVID: 2011-2018)
station_df <- station_df %>%
  rowwise() %>%
  mutate(
    avg_daily_users = mean(c_across(pass_2011:pass_2018), na.rm = TRUE)
  ) %>%
  ungroup()

# Remove stations with no passenger data
station_df <- station_df %>%
  filter(!is.na(avg_daily_users) & avg_daily_users > 0)

cat(sprintf("Stations with valid passenger data: %d\n", nrow(station_df)))

# Treatment indicator: above 3,000 threshold
station_df <- station_df %>%
  mutate(
    above_threshold = as.integer(avg_daily_users >= 3000),
    centered_users  = avg_daily_users - 3000
  )

cat(sprintf("Above threshold (>=3000): %d\n", sum(station_df$above_threshold)))
cat(sprintf("Below threshold (<3000): %d\n", sum(!station_df$above_threshold)))

# Summary stats
cat("\n--- Passenger count distribution ---\n")
print(summary(station_df$avg_daily_users))
cat(sprintf("Stations in [1000, 5000] window: %d\n",
            sum(station_df$avg_daily_users >= 1000 & station_df$avg_daily_users <= 5000)))

## ===========================================================================
## 2. LAND PRICE DATA — Extract and standardize across years
## ===========================================================================
process_l01 <- function(df, year) {
  nms <- names(df)

  # Identify columns by position/content
  # L01 2020: L01_006=price, L01_021=municipality, L01_025=land_use,
  #           L01_045=station_name, L01_046=distance_m, L01_047=zoning
  # L01 2015/2010: same core structure but fewer trailing columns

  # Find price column (L01_006 — always numeric-like, large values)
  price_col <- "L01_006"

  # Coordinates from geometry
  coords <- st_coordinates(df)

  result <- data.frame(
    survey_year     = year,
    price_yen_sqm   = as.numeric(df[[price_col]]),
    municipality_cd = as.character(df[["L01_021"]]),
    land_use        = as.character(df[["L01_025"]]),
    lon             = coords[, 1],
    lat             = coords[, 2],
    stringsAsFactors = FALSE
  )

  # Station name and distance (position varies by year)
  # In 2020: L01_045=station, L01_046=distance
  # In 2015: need to check - may be different position
  # Try to find station name column (contains Japanese station names)
  stn_col <- NULL
  dist_col <- NULL

  # For 2020: L01_045 and L01_046
  if ("L01_045" %in% nms) {
    stn_val <- as.character(df[["L01_045"]][1])
    # Check if it looks like a station name (not a number/boolean)
    if (!is.na(stn_val) && !stn_val %in% c("true", "false") && nchar(stn_val) > 1) {
      stn_col <- "L01_045"
      dist_col <- "L01_046"
    }
  }

  # For 2015/2010: L01 may have different column mapping
  if (is.null(stn_col)) {
    # Search for a column containing known station names
    for (cn in nms) {
      if (grepl("^L01_0[2-9][0-9]$|^L01_1[0-9][0-9]$", cn)) {
        vals <- as.character(df[[cn]])
        # Station names are typically short Japanese text
        if (any(grepl("駅|公園|丁目|町", vals, ignore.case = TRUE), na.rm = TRUE)) {
          stn_col <- cn
          # Next column should be distance
          idx <- which(nms == cn)
          if (idx < length(nms)) dist_col <- nms[idx + 1]
          break
        }
      }
    }
  }

  if (!is.null(stn_col)) {
    result$l01_station_name <- as.character(df[[stn_col]])
    if (!is.null(dist_col)) {
      result$l01_station_dist_m <- as.numeric(df[[dist_col]])
    }
    cat(sprintf("  L01 %d: Found station col=%s, dist col=%s\n", year, stn_col, dist_col))
  } else {
    cat(sprintf("  L01 %d: No station name column found\n", year))
  }

  # Zoning
  if ("L01_047" %in% nms) {
    result$zoning <- as.character(df[["L01_047"]])
  }

  result <- result %>%
    filter(!is.na(price_yen_sqm) & price_yen_sqm > 0)

  cat(sprintf("  L01 %d: %d valid observations\n", year, nrow(result)))
  return(result)
}

land_dfs <- list()
for (yr in names(l01_list)) {
  cat(sprintf("\nProcessing L01 %s...\n", yr))
  land_dfs[[yr]] <- process_l01(l01_list[[yr]], as.integer(yr))
}

land_all <- bind_rows(land_dfs)
cat(sprintf("\nTotal land price observations: %d\n", nrow(land_all)))

## ===========================================================================
## 3. SPATIAL MATCHING — Assign each land price point to nearest station
## ===========================================================================
cat("\n--- Spatial matching: land prices to nearest station ---\n")

# Convert station data to sf
station_sf <- st_as_sf(station_df, coords = c("lon", "lat"), crs = 4326)

# Process each year of land data
match_land_to_station <- function(land_df, station_sf, max_dist_m = 2000) {
  land_sf <- st_as_sf(land_df, coords = c("lon", "lat"), crs = 4326, remove = FALSE)

  # Find nearest station for each land point
  nearest_idx <- st_nearest_feature(land_sf, station_sf)
  nearest_dist <- st_distance(land_sf, station_sf[nearest_idx, ], by_element = TRUE)

  land_df$nearest_station_name  <- station_df$station_name[nearest_idx]
  land_df$nearest_station_users <- station_df$avg_daily_users[nearest_idx]
  land_df$nearest_station_above <- station_df$above_threshold[nearest_idx]
  land_df$station_dist_m        <- as.numeric(nearest_dist)
  land_df$centered_users        <- station_df$centered_users[nearest_idx]

  # Filter to within max distance
  land_df <- land_df %>%
    filter(station_dist_m <= max_dist_m)

  return(land_df)
}

analysis_dfs <- list()
for (yr in names(land_dfs)) {
  cat(sprintf("Matching L01 %s...\n", yr))
  analysis_dfs[[yr]] <- match_land_to_station(land_dfs[[yr]], station_sf, max_dist_m = 2000)
  cat(sprintf("  Within 2km: %d observations\n", nrow(analysis_dfs[[yr]])))
}

analysis_all <- bind_rows(analysis_dfs)
cat(sprintf("\nTotal matched observations (within 2km): %d\n", nrow(analysis_all)))

# Create log price
analysis_all <- analysis_all %>%
  mutate(log_price = log(price_yen_sqm))

# Summary
cat("\n--- Analysis dataset summary ---\n")
analysis_all %>%
  group_by(survey_year, nearest_station_above) %>%
  summarise(
    n = n(),
    mean_price = mean(price_yen_sqm),
    median_price = median(price_yen_sqm),
    mean_users = mean(nearest_station_users),
    .groups = "drop"
  ) %>%
  print()

## ===========================================================================
## 4. SAVE
## ===========================================================================
saveRDS(station_df, file.path(data_dir, "stations_clean.rds"))
saveRDS(analysis_all, file.path(data_dir, "analysis_data.rds"))

cat("\n=== Cleaning complete ===\n")
cat(sprintf("Stations: %d (%d above, %d below threshold)\n",
            nrow(station_df), sum(station_df$above_threshold),
            sum(!station_df$above_threshold)))
cat(sprintf("Land price obs: %d (across %d years)\n",
            nrow(analysis_all), length(unique(analysis_all$survey_year))))
