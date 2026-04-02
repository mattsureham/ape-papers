## 01_fetch_data.R — Data acquisition for apep_1291
## Fetches NASS Census of Agriculture + county border geometry

source("00_packages.R")

nass_key <- Sys.getenv("USDA_NASS_API_KEY")
if (nass_key == "") stop("USDA_NASS_API_KEY not set in environment")

cat("=== Fetching NASS Census of Agriculture data ===\n")

# States of interest: NE and its neighbors
states <- c("NE", "IA", "KS", "SD", "MO", "CO", "WY")
census_years <- c(1987, 1992, 1997, 2002, 2007, 2012, 2017, 2022)

# Function to query NASS QuickStats API
fetch_nass <- function(params) {
  base_url <- "https://quickstats.nass.usda.gov/api/api_GET/"
  params$key <- nass_key
  params$format <- "JSON"

  resp <- httr::GET(base_url, query = params)
  if (httr::status_code(resp) != 200) {
    stop("NASS API returned status ", httr::status_code(resp))
  }

  content <- httr::content(resp, as = "text", encoding = "UTF-8")
  parsed <- jsonlite::fromJSON(content)

  if (is.null(parsed$data) || length(parsed$data) == 0) {
    warning("No data returned for query: ", paste(names(params), params, sep = "=", collapse = "&"))
    return(NULL)
  }
  as_tibble(parsed$data)
}

# Fetch total farm operations by county
all_farms <- list()
for (st in states) {
  for (yr in census_years) {
    cat(sprintf("  Fetching farms for %s %d...\n", st, yr))
    tryCatch({
      df <- fetch_nass(list(
        source_desc = "CENSUS",
        sector_desc = "ECONOMICS",
        group_desc = "FARMS & LAND & ASSETS",
        commodity_desc = "FARM OPERATIONS",
        statisticcat_desc = "OPERATIONS",
        unit_desc = "OPERATIONS",
        agg_level_desc = "COUNTY",
        state_alpha = st,
        year = yr
      ))
      if (!is.null(df)) all_farms[[paste(st, yr)]] <- df
    }, error = function(e) {
      warning(sprintf("Failed for %s %d: %s", st, yr, e$message))
    })
    Sys.sleep(0.5)  # Rate limiting
  }
}

farms_raw <- bind_rows(all_farms)
stopifnot("No farm data returned" = nrow(farms_raw) > 0)
cat(sprintf("  Total farm records: %d\n", nrow(farms_raw)))

# Fetch land in farms (total acres)
all_land <- list()
for (st in states) {
  for (yr in census_years) {
    cat(sprintf("  Fetching land in farms for %s %d...\n", st, yr))
    tryCatch({
      df <- fetch_nass(list(
        source_desc = "CENSUS",
        sector_desc = "ECONOMICS",
        group_desc = "FARMS & LAND & ASSETS",
        commodity_desc = "FARM OPERATIONS",
        statisticcat_desc = "AREA OPERATED",
        unit_desc = "ACRES",
        agg_level_desc = "COUNTY",
        state_alpha = st,
        year = yr,
        domain_desc = "TOTAL"
      ))
      if (!is.null(df)) all_land[[paste(st, yr)]] <- df
    }, error = function(e) {
      warning(sprintf("Failed land for %s %d: %s", st, yr, e$message))
    })
    Sys.sleep(0.5)
  }
}

land_raw <- bind_rows(all_land)
cat(sprintf("  Total land records: %d\n", nrow(land_raw)))

# Fetch farms by size class (area operated)
all_size <- list()
for (st in states) {
  for (yr in census_years) {
    cat(sprintf("  Fetching farm size distribution for %s %d...\n", st, yr))
    tryCatch({
      df <- fetch_nass(list(
        source_desc = "CENSUS",
        sector_desc = "ECONOMICS",
        group_desc = "FARMS & LAND & ASSETS",
        commodity_desc = "FARM OPERATIONS",
        statisticcat_desc = "OPERATIONS",
        unit_desc = "OPERATIONS",
        agg_level_desc = "COUNTY",
        state_alpha = st,
        year = yr,
        domain_desc = "AREA OPERATED"
      ))
      if (!is.null(df)) all_size[[paste(st, yr)]] <- df
    }, error = function(e) {
      warning(sprintf("Failed size for %s %d: %s", st, yr, e$message))
    })
    Sys.sleep(0.5)
  }
}

size_raw <- bind_rows(all_size)
cat(sprintf("  Total size-class records: %d\n", nrow(size_raw)))

# Save raw data
saveRDS(farms_raw, "../data/farms_raw.rds")
saveRDS(land_raw, "../data/land_raw.rds")
saveRDS(size_raw, "../data/size_raw.rds")

cat("\n=== Fetching county geometry ===\n")

# Download county boundaries for all states
county_sf <- tigris::counties(
  state = c("NE", "IA", "KS", "SD", "MO", "CO", "WY"),
  year = 2020,
  cb = TRUE  # Cartographic boundary (smaller file)
) |>
  st_transform(4326)

# Compute county centroids
county_centroids <- county_sf |>
  mutate(
    centroid = st_centroid(geometry),
    lon = st_coordinates(centroid)[, 1],
    lat = st_coordinates(centroid)[, 2]
  )

# Download state boundaries for border distance calculation
state_sf <- tigris::states(year = 2020, cb = TRUE) |>
  st_transform(4326) |>
  filter(STUSPS %in% c("NE", "IA", "KS", "SD", "MO", "CO", "WY"))

# Extract Nebraska border as a line
ne_boundary <- state_sf |>
  filter(STUSPS == "NE") |>
  st_boundary()

# Compute distance from each county centroid to Nebraska border
county_centroids_proj <- county_centroids |> st_transform(5070)  # NAD83 Albers
ne_boundary_proj <- ne_boundary |> st_transform(5070)

# Distance in km
centroids_pts <- st_centroid(county_centroids_proj$geometry)
distances_m <- as.numeric(st_distance(centroids_pts, ne_boundary_proj))
county_centroids$dist_to_ne_border_km <- distances_m / 1000

# Sign convention: positive = inside NE, negative = outside NE
county_centroids <- county_centroids |>
  mutate(
    in_nebraska = STUSPS == "NE",
    dist_signed_km = ifelse(in_nebraska, dist_to_ne_border_km, -dist_to_ne_border_km)
  )

# Save geometry data
saveRDS(county_centroids |> st_drop_geometry() |>
          select(GEOID, STATEFP, STUSPS, COUNTYFP, NAME, lon, lat,
                 dist_to_ne_border_km, dist_signed_km, in_nebraska),
        "../data/county_geo.rds")
saveRDS(county_sf, "../data/county_sf.rds")

cat("\n=== Identifying border counties ===\n")

# Find counties that share a border with a county in a different state
# (counties whose boundary touches a county in another state)
ne_counties <- county_sf |> filter(STUSPS == "NE")
neighbor_counties <- county_sf |> filter(STUSPS != "NE")

# Find touching pairs
touches <- st_touches(ne_counties, neighbor_counties)
ne_border_ids <- ne_counties$GEOID[lengths(touches) > 0]
neighbor_border_ids <- unique(unlist(lapply(which(lengths(touches) > 0), function(i) {
  neighbor_counties$GEOID[touches[[i]]]
})))

border_counties <- c(ne_border_ids, neighbor_border_ids)
cat(sprintf("  NE border counties: %d\n", length(ne_border_ids)))
cat(sprintf("  Neighbor border counties: %d\n", length(neighbor_border_ids)))
cat(sprintf("  Total border counties: %d\n", length(border_counties)))

saveRDS(border_counties, "../data/border_counties.rds")

cat("\n=== Data fetch complete ===\n")
cat(sprintf("Farm records: %d | Land records: %d | Size records: %d\n",
            nrow(farms_raw), nrow(land_raw), nrow(size_raw)))
cat(sprintf("Counties with geometry: %d | Border counties: %d\n",
            nrow(county_sf), length(border_counties)))
