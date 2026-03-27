## 01_fetch_data.R — Fetch USGS earthquake data and construct SRA boundaries
## apep_1095: Induced seismicity and self-regulation in Texas Permian Basin
##
## Data sources:
## 1. USGS ComCat API — earthquake catalog (M2.0+, 2017-2024)
## 2. SRA boundaries — defined from RRC orders (hard-coded coordinates)
## 3. Texas RRC H-10 injection data — approximated from SRA-level aggregates

source("00_packages.R")

# ========================================================================
# 1. USGS ComCat earthquake data
# ========================================================================
# Permian Basin bounding box: lat 30-33.5°N, lon 100.5-105°W
# This covers all three SRAs plus buffer zones

cat("Fetching USGS ComCat earthquake data...\n")

# USGS API has a 20,000 event limit per query; split by year
fetch_usgs <- function(start, end, minlat = 30.0, maxlat = 33.5,
                       minlon = -105.0, maxlon = -100.5, minmag = 2.0) {
  url <- paste0(
    "https://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson",
    "&starttime=", start,
    "&endtime=", end,
    "&minlatitude=", minlat,
    "&maxlatitude=", maxlat,
    "&minlongitude=", minlon,
    "&maxlongitude=", maxlon,
    "&minmagnitude=", minmag,
    "&orderby=time"
  )

  resp <- httr::GET(url, httr::timeout(120))
  if (httr::status_code(resp) != 200) {
    stop(paste("USGS API returned status", httr::status_code(resp),
               "for period", start, "to", end))
  }

  raw <- httr::content(resp, as = "text", encoding = "UTF-8")
  parsed <- jsonlite::fromJSON(raw, flatten = TRUE)

  if (length(parsed$features) == 0) {
    cat(sprintf("  %s to %s: 0 events\n", start, end))
    return(NULL)
  }

  # Extract coordinates from nested list
  coords_list <- parsed$features$geometry.coordinates
  lon_vec <- sapply(coords_list, function(x) x[1])
  lat_vec <- sapply(coords_list, function(x) x[2])
  dep_vec <- sapply(coords_list, function(x) x[3])

  df <- parsed$features %>%
    transmute(
      eq_id = id,
      time_ms = properties.time,
      mag = properties.mag,
      depth_km = dep_vec,
      lon = lon_vec,
      lat = lat_vec,
      place = properties.place,
      mag_type = properties.magType,
      rms = properties.rms
    ) %>%
    mutate(
      datetime = as.POSIXct(time_ms / 1000, origin = "1970-01-01", tz = "UTC"),
      date = as.Date(datetime),
      year = year(date),
      month = month(date),
      ym = paste0(year, "-", sprintf("%02d", month))
    )

  cat(sprintf("  %s to %s: %d events\n", start, end, nrow(df)))
  return(df)
}

# Fetch year by year to stay under API limits
years <- 2017:2024
eq_list <- list()
for (yr in years) {
  eq_list[[as.character(yr)]] <- fetch_usgs(
    start = paste0(yr, "-01-01"),
    end = paste0(yr, "-12-31")
  )
  Sys.sleep(1)  # be polite to USGS servers
}

earthquakes <- bind_rows(eq_list)
stopifnot("No earthquake data returned" = nrow(earthquakes) > 0)

cat(sprintf("\nTotal earthquakes fetched: %d (M2.0+, 2017-2024)\n", nrow(earthquakes)))
cat("Annual counts:\n")
print(table(earthquakes$year))

# ========================================================================
# 2. SRA boundary definitions (from RRC orders)
# ========================================================================
# Three Seismic Response Areas designated by Texas RRC:
# 1. Gardendale SRA — designated Sep 2021, deep disposal suspended Dec 2021
# 2. Northern Culberson-Reeves (NCR) SRA — designated Mar 2022
# 3. Stanton SRA — designated Jan-May 2022

cat("\nDefining SRA boundaries...\n")

# SRA boundaries (approximate polygons from RRC published maps)
# Gardendale: centered around Gardendale, TX (Ector/Midland county border)
gardendale_bbox <- list(
  name = "Gardendale",
  designation_date = as.Date("2021-09-01"),
  enforcement_date = as.Date("2021-12-01"),
  center_lat = 32.02, center_lon = -102.38,
  radius_km = 40  # approximate radius
)

# Northern Culberson-Reeves: Culberson and Reeves counties
ncr_bbox <- list(
  name = "Northern Culberson-Reeves",
  designation_date = as.Date("2022-03-01"),
  enforcement_date = as.Date("2022-03-01"),
  center_lat = 31.60, center_lon = -103.80,
  radius_km = 50
)

# Stanton: Martin County area
stanton_bbox <- list(
  name = "Stanton",
  designation_date = as.Date("2022-01-01"),
  enforcement_date = as.Date("2022-05-01"),
  center_lat = 32.13, center_lon = -101.78,
  radius_km = 30
)

sra_list <- list(gardendale_bbox, ncr_bbox, stanton_bbox)

# Assign earthquakes to SRAs based on distance from center
assign_sra <- function(eq_df, sra_info) {
  # Haversine distance in km
  dlat <- (eq_df$lat - sra_info$center_lat) * pi / 180
  dlon <- (eq_df$lon - sra_info$center_lon) * pi / 180
  a <- sin(dlat/2)^2 + cos(eq_df$lat * pi / 180) * cos(sra_info$center_lat * pi / 180) * sin(dlon/2)^2
  dist_km <- 2 * 6371 * asin(sqrt(a))
  return(dist_km)
}

earthquakes$dist_gardendale <- assign_sra(earthquakes, gardendale_bbox)
earthquakes$dist_ncr <- assign_sra(earthquakes, ncr_bbox)
earthquakes$dist_stanton <- assign_sra(earthquakes, stanton_bbox)

# Assign to nearest SRA and ring zones
earthquakes <- earthquakes %>%
  mutate(
    in_gardendale = dist_gardendale <= gardendale_bbox$radius_km,
    in_ncr = dist_ncr <= ncr_bbox$radius_km,
    in_stanton = dist_stanton <= stanton_bbox$radius_km,
    in_any_sra = in_gardendale | in_ncr | in_stanton,
    nearest_sra = case_when(
      in_gardendale ~ "Gardendale",
      in_ncr ~ "NCR",
      in_stanton ~ "Stanton",
      TRUE ~ "Outside"
    ),
    # Ring zones for displacement analysis (distance to nearest SRA boundary)
    min_dist_to_sra = pmin(
      pmax(0, dist_gardendale - gardendale_bbox$radius_km),
      pmax(0, dist_ncr - ncr_bbox$radius_km),
      pmax(0, dist_stanton - stanton_bbox$radius_km)
    ),
    ring_zone = case_when(
      in_any_sra ~ "Within SRA",
      min_dist_to_sra <= 20 ~ "0-20km buffer",
      min_dist_to_sra <= 50 ~ "20-50km buffer",
      min_dist_to_sra <= 100 ~ "50-100km buffer",
      TRUE ~ ">100km"
    )
  )

cat("\nEarthquakes by SRA assignment:\n")
print(table(earthquakes$nearest_sra))

cat("\nEarthquakes by ring zone:\n")
print(table(earthquakes$ring_zone))

# ========================================================================
# 3. Construct grid cells for panel analysis
# ========================================================================
cat("\nConstructing 0.1° (~11km) grid cells...\n")

# Create grid covering Permian Basin
grid_lat <- seq(30.0, 33.5, by = 0.1)
grid_lon <- seq(-105.0, -100.5, by = 0.1)
grid <- expand.grid(grid_lat = grid_lat, grid_lon = grid_lon) %>%
  mutate(grid_id = row_number())

# Assign grid cells to SRA status
grid <- grid %>%
  rowwise() %>%
  mutate(
    d_gard = {
      dlat <- (grid_lat - gardendale_bbox$center_lat) * pi / 180
      dlon <- (grid_lon - gardendale_bbox$center_lon) * pi / 180
      a <- sin(dlat/2)^2 + cos(grid_lat * pi/180) * cos(gardendale_bbox$center_lat * pi/180) * sin(dlon/2)^2
      2 * 6371 * asin(sqrt(a))
    },
    d_ncr = {
      dlat <- (grid_lat - ncr_bbox$center_lat) * pi / 180
      dlon <- (grid_lon - ncr_bbox$center_lon) * pi / 180
      a <- sin(dlat/2)^2 + cos(grid_lat * pi/180) * cos(ncr_bbox$center_lat * pi/180) * sin(dlon/2)^2
      2 * 6371 * asin(sqrt(a))
    },
    d_stan = {
      dlat <- (grid_lat - stanton_bbox$center_lat) * pi / 180
      dlon <- (grid_lon - stanton_bbox$center_lon) * pi / 180
      a <- sin(dlat/2)^2 + cos(grid_lat * pi/180) * cos(stanton_bbox$center_lat * pi/180) * sin(dlon/2)^2
      2 * 6371 * asin(sqrt(a))
    }
  ) %>%
  ungroup() %>%
  mutate(
    in_gardendale = d_gard <= gardendale_bbox$radius_km,
    in_ncr = d_ncr <= ncr_bbox$radius_km,
    in_stanton = d_stan <= stanton_bbox$radius_km,
    in_any_sra = in_gardendale | in_ncr | in_stanton,
    sra_name = case_when(
      in_gardendale ~ "Gardendale",
      in_ncr ~ "NCR",
      in_stanton ~ "Stanton",
      TRUE ~ "Non-SRA"
    ),
    # Treatment timing (month of SRA enforcement)
    treat_date = case_when(
      in_gardendale ~ as.Date("2021-12-01"),
      in_ncr ~ as.Date("2022-03-01"),
      in_stanton ~ as.Date("2022-05-01"),
      TRUE ~ NA_Date_
    )
  )

cat(sprintf("Grid cells: %d total, %d in SRAs\n", nrow(grid), sum(grid$in_any_sra)))

# ========================================================================
# 4. Aggregate earthquakes to grid-cell × month panel
# ========================================================================
cat("\nBuilding grid-cell × month panel...\n")

# Assign earthquakes to grid cells
earthquakes <- earthquakes %>%
  mutate(
    grid_lat = round(lat / 0.1) * 0.1,
    grid_lon = round(lon / 0.1) * 0.1
  )

# Create month sequence
months <- seq(as.Date("2017-01-01"), as.Date("2024-12-01"), by = "month")
month_df <- data.frame(
  month_date = months,
  ym = paste0(year(months), "-", sprintf("%02d", month(months)))
)

# Count earthquakes per grid-cell per month
eq_counts <- earthquakes %>%
  group_by(grid_lat, grid_lon, ym) %>%
  summarize(
    eq_count = n(),
    eq_count_m25 = sum(mag >= 2.5, na.rm = TRUE),
    eq_count_m30 = sum(mag >= 3.0, na.rm = TRUE),
    max_mag = max(mag, na.rm = TRUE),
    mean_mag = mean(mag, na.rm = TRUE),
    .groups = "drop"
  )

# Merge with full panel (grid × month)
# Only keep grid cells that ever had an earthquake (avoids massive sparse panel)
active_grids <- earthquakes %>%
  distinct(grid_lat, grid_lon) %>%
  left_join(grid %>% dplyr::select(grid_lat, grid_lon, grid_id, in_any_sra, sra_name, treat_date,
                             in_gardendale, in_ncr, in_stanton),
            by = c("grid_lat", "grid_lon"))

panel <- expand.grid(
  grid_id_temp = seq_len(nrow(active_grids)),
  ym = month_df$ym,
  stringsAsFactors = FALSE
) %>%
  left_join(active_grids %>% mutate(grid_id_temp = row_number()), by = "grid_id_temp") %>%
  left_join(month_df, by = "ym") %>%
  left_join(eq_counts, by = c("grid_lat", "grid_lon", "ym")) %>%
  mutate(
    eq_count = replace_na(eq_count, 0L),
    eq_count_m25 = replace_na(eq_count_m25, 0L),
    eq_count_m30 = replace_na(eq_count_m30, 0L),
    # Treatment indicator
    post = !is.na(treat_date) & month_date >= treat_date,
    treated = in_any_sra,
    # Relative month (for event study)
    rel_month = if_else(!is.na(treat_date),
                        as.integer(difftime(month_date, treat_date, units = "days")) %/% 30L,
                        NA_integer_),
    year = year(month_date),
    month_num = month(month_date)
  ) %>%
  dplyr::select(-grid_id_temp)

cat(sprintf("Panel: %d grid-cells × %d months = %d observations\n",
            n_distinct(panel$grid_id), n_distinct(panel$ym), nrow(panel)))
cat(sprintf("Treated grid-cells: %d\n", sum(panel$treated & panel$ym == "2017-01")))
cat(sprintf("Total earthquakes in panel: %d\n", sum(panel$eq_count)))

# ========================================================================
# 5. Save data
# ========================================================================
saveRDS(earthquakes, "../data/earthquakes_raw.rds")
saveRDS(panel, "../data/panel.rds")
saveRDS(grid, "../data/grid.rds")
saveRDS(sra_list, "../data/sra_definitions.rds")

cat("\nData saved to data/ directory.\n")
cat("============================\n")
cat("Data fetch complete.\n")
