# 01_fetch_data.R — Fetch earthquake data from USGS API and oil prices from FRED
# apep_1127: Injection well volume regulations and induced seismicity

source("00_packages.R")

cat("=== Fetching earthquake data from USGS ComCat API ===\n")

# --- Helper: query USGS FDSNWS API ---
fetch_usgs_earthquakes <- function(minlat, maxlat, minlon, maxlon,
                                    starttime, endtime, minmagnitude = 2.5,
                                    label = "region") {
  base_url <- "https://earthquake.usgs.gov/fdsnws/event/1/query"
  params <- list(
    format = "csv",
    starttime = starttime,
    endtime = endtime,
    minlatitude = minlat,
    maxlatitude = maxlat,
    minlongitude = minlon,
    maxlongitude = maxlon,
    minmagnitude = minmagnitude,
    orderby = "time"
  )

  url <- modify_url(base_url, query = params)
  cat(sprintf("Fetching %s earthquakes (M%.1f+)...\n", label, minmagnitude))

  resp <- GET(url, timeout(120))
  if (status_code(resp) != 200) {
    stop(sprintf("USGS API returned status %d for %s", status_code(resp), label))
  }

  raw_text <- content(resp, as = "text", encoding = "UTF-8")
  if (nchar(raw_text) < 50) {
    stop(sprintf("USGS API returned empty data for %s", label))
  }

  df <- read_csv(raw_text, show_col_types = FALSE)
  cat(sprintf("  -> %d events fetched for %s\n", nrow(df), label))

  if (nrow(df) == 0) {
    stop(sprintf("Zero earthquakes returned for %s — check parameters", label))
  }

  df$region_label <- label
  return(df)
}

# --- Oklahoma earthquakes (broad bounding box covering the state) ---
ok_quakes <- fetch_usgs_earthquakes(
  minlat = 33.5, maxlat = 37.2, minlon = -103.1, maxlon = -94.3,
  starttime = "2009-01-01", endtime = "2024-12-31",
  minmagnitude = 2.5, label = "Oklahoma"
)

# --- Kansas earthquakes (south-central Kansas where induced seismicity occurs) ---
ks_quakes <- fetch_usgs_earthquakes(
  minlat = 36.8, maxlat = 38.5, minlon = -99.0, maxlon = -96.5,
  starttime = "2009-01-01", endtime = "2024-12-31",
  minmagnitude = 2.5, label = "Kansas"
)

# --- California tectonic placebo (Southern California, not induced) ---
ca_quakes <- fetch_usgs_earthquakes(
  minlat = 32.0, maxlat = 37.0, minlon = -121.0, maxlon = -114.0,
  starttime = "2009-01-01", endtime = "2024-12-31",
  minmagnitude = 2.5, label = "California_placebo"
)

# --- Combine all earthquakes ---
all_quakes <- bind_rows(ok_quakes, ks_quakes, ca_quakes)
cat(sprintf("\nTotal earthquakes fetched: %d\n", nrow(all_quakes)))
cat(sprintf("  Oklahoma: %d\n", sum(all_quakes$region_label == "Oklahoma")))
cat(sprintf("  Kansas: %d\n", sum(all_quakes$region_label == "Kansas")))
cat(sprintf("  California placebo: %d\n", sum(all_quakes$region_label == "California_placebo")))

# --- Validate: Oklahoma should have thousands of events ---
ok_count <- sum(all_quakes$region_label == "Oklahoma")
if (ok_count < 1000) {
  stop(sprintf("Only %d Oklahoma earthquakes — expected ~9,000+. Check API parameters.", ok_count))
}

# --- Save raw earthquake data ---
write_csv(all_quakes, "../data/earthquakes_raw.csv")
cat("Saved earthquakes_raw.csv\n")

# --- Oklahoma county shapefiles ---
cat("\n=== Fetching Oklahoma and Kansas county shapefiles ===\n")
ok_counties <- counties(state = "OK", year = 2020, cb = TRUE) |>
  st_transform(4326) |>
  select(GEOID, NAME, geometry)

ks_counties <- counties(state = "KS", year = 2020, cb = TRUE) |>
  st_transform(4326) |>
  select(GEOID, NAME, geometry)

cat(sprintf("Oklahoma counties: %d\n", nrow(ok_counties)))
cat(sprintf("Kansas counties: %d\n", nrow(ks_counties)))

# Save county data
saveRDS(ok_counties, "../data/ok_counties.rds")
saveRDS(ks_counties, "../data/ks_counties.rds")

# --- Assign earthquakes to counties via spatial join ---
cat("\n=== Spatial join: assigning earthquakes to counties ===\n")

ok_quakes_sf <- ok_quakes |>
  filter(!is.na(longitude), !is.na(latitude)) |>
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

ok_quakes_county <- st_join(ok_quakes_sf, ok_counties, join = st_within)
ok_quakes_county <- ok_quakes_county |>
  st_drop_geometry() |>
  filter(!is.na(GEOID)) |>
  mutate(
    county_fips = GEOID,
    county_name = NAME,
    date = as.Date(time),
    year = year(date),
    month = month(date),
    year_month = floor_date(date, "month")
  )

cat(sprintf("Oklahoma earthquakes matched to counties: %d / %d\n",
            nrow(ok_quakes_county), nrow(ok_quakes)))

ks_quakes_sf <- ks_quakes |>
  filter(!is.na(longitude), !is.na(latitude)) |>
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

ks_quakes_county <- st_join(ks_quakes_sf, ks_counties, join = st_within)
ks_quakes_county <- ks_quakes_county |>
  st_drop_geometry() |>
  filter(!is.na(GEOID)) |>
  mutate(
    county_fips = GEOID,
    county_name = NAME,
    date = as.Date(time),
    year = year(date),
    month = month(date),
    year_month = floor_date(date, "month")
  )

cat(sprintf("Kansas earthquakes matched to counties: %d / %d\n",
            nrow(ks_quakes_county), nrow(ks_quakes)))

# --- Save geocoded earthquake data ---
write_csv(ok_quakes_county, "../data/ok_quakes_county.csv")
write_csv(ks_quakes_county, "../data/ks_quakes_county.csv")

# --- Fetch WTI crude oil prices from FRED ---
cat("\n=== Fetching WTI crude oil prices from FRED ===\n")

tryCatch({
  wti <- fredr(
    series_id = "MCOILWTICO",
    observation_start = as.Date("2009-01-01"),
    observation_end = as.Date("2024-12-31"),
    frequency = "m"
  )
  if (nrow(wti) == 0) stop("Empty FRED response")
  wti <- wti |>
    select(date, wti_price = value) |>
    mutate(year_month = floor_date(date, "month"))
  cat(sprintf("WTI prices: %d monthly observations\n", nrow(wti)))
  write_csv(wti, "../data/wti_prices.csv")
}, error = function(e) {
  stop(paste("Failed to fetch WTI prices:", e$message))
})

# --- Summary statistics ---
cat("\n=== Data Summary ===\n")
ok_annual <- ok_quakes_county |>
  group_by(year) |>
  summarise(n_quakes = n(), .groups = "drop")
cat("Oklahoma annual earthquake counts:\n")
print(ok_annual, n = 20)

ks_annual <- ks_quakes_county |>
  group_by(year) |>
  summarise(n_quakes = n(), .groups = "drop")
cat("\nKansas annual earthquake counts:\n")
print(ks_annual, n = 20)

cat("\n=== Data fetch complete ===\n")
