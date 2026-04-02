# ==============================================================================
# 01_fetch_data.R — Fetch Amazon FC locations + QWI race panel
# Paper: The Racial Dividend of the Warehouse Boom (apep_1300)
# ==============================================================================

source("00_packages.R")

# ---------- Part 1: Amazon FC Locations from MWPVL gist ---------------------

cat("Fetching Amazon FC location data...\n")

# Read MWPVL gist CSV
url <- "https://gist.githubusercontent.com/lifewinning/9e889d3e5b556ceff5f3/raw/North_America_Fulfillment_Centers.csv"
raw_fc <- read.csv(url, stringsAsFactors = FALSE)

cat("Raw FC entries:", nrow(raw_fc), "\n")

# Clean and parse
fc <- raw_fc %>%
  rename(
    fc_code = FulfillmentCenter,
    location = Location,
    country = Country,
    sqft = SquareFeet,
    year_opened = YearOpened,
    description = Description.of.Operation
  ) %>%
  # Filter to US only (drop Canada and Mexico)
  filter(is.na(country) | trimws(country) == "" | trimws(country) == "US") %>%
  # Remove entries with Canadian/Mexican indicators
  filter(!grepl("Canada|Ontario|British Columbia|México|Mexico", location, ignore.case = TRUE)) %>%
  mutate(
    # Parse opening year: extract a 4-digit year in the range 1990-2025
    # Must handle: "September2007", "October 142014", "Q42015", "2015-16", etc.
    # Extract ALL 4-digit numbers, then keep the one that looks like a year
    all_years = str_extract_all(year_opened, "(?:19|20)\\d{2}"),
    year_opened_clean = sapply(all_years, function(x) {
      if (length(x) == 0) return(NA_integer_)
      as.integer(x[1])  # Take first valid year
    }),
    # Parse square footage
    sqft_clean = as.numeric(gsub("[^0-9]", "", sqft))
  ) %>%
  select(-all_years) %>%
  # Must have an opening year
  filter(!is.na(year_opened_clean)) %>%
  # Filter: include substantial logistics facilities, exclude tiny hubs
  # Prime Now Hubs (U* codes, ~20-50K sqft) and Fresh Delivery Stations (D* codes)
  # are too small to move county-level employment
  filter(
    # Exclude Prime Now hubs by code pattern
    !grepl("^U[A-Z]{2}[0-9]", fc_code),
    # Exclude Fresh Delivery stations by code pattern
    !grepl("^D[A-Z]{2}[0-9]", fc_code)
  ) %>%
  # Also exclude by description
  filter(!grepl("^Prime Now Hub", description, ignore.case = TRUE)) %>%
  filter(!grepl("^Amazon\\.?Fresh\\s+(Delivery Station|Grocery)", description, ignore.case = TRUE)) %>%
  # Keep facilities >= 100K sqft, or FC/Sortation/Redistribution types
  filter(
    sqft_clean >= 100000 |
    is.na(sqft_clean) |
    grepl("Fulfillment|Sortable|Non.Sortable|Sortation|Redistribution|Returns",
          description, ignore.case = TRUE)
  )

cat("US FC entries after filtering:", nrow(fc), "\n")

# Extract state and city from location field
fc <- fc %>%
  mutate(
    location_clean = trimws(location),
    # Extract ZIP code (5-digit)
    zip5 = str_extract(location, "\\b\\d{5}\\b"),
    # Extract state name
    state_raw = str_extract(location,
      "Alabama|Alaska|Arizona|Arkansas|California|Colorado|Connecticut|Delaware|Florida|Georgia|Hawaii|Idaho|Illinois|Indiana|Iowa|Kansas|Kentucky|Louisiana|Maine|Maryland|Massachusetts|Michigan|Minnesota|Mississippi|Missouri|Montana|Nebraska|Nevada|New Hampshire|New Jersey|New Mexico|New York|North Carolina|North Dakota|Ohio|Oklahoma|Oregon|Pennsylvania|Rhode Island|South Carolina|South Dakota|Tennessee|Texas|Utah|Vermont|Virginia|Washington|West Virginia|Wisconsin|Wyoming"),
    state_abbr = state.abb[match(state_raw, state.name)]
  )

cat("FC entries with state identified:", sum(!is.na(fc$state_abbr)), "\n")

# Use ZIP-to-county crosswalk for FIPS assignment
cat("Fetching ZIP-to-county crosswalk...\n")
zip_county <- tryCatch({
  zip_xwalk <- read.csv(
    "https://www2.census.gov/geo/docs/maps-data/data/rel2020/zcta520/tab20_zcta520_county20_natl.txt",
    sep = "|", stringsAsFactors = FALSE
  )
  zip_xwalk %>%
    mutate(
      zip5 = sprintf("%05d", GEOID_ZCTA5_20),
      county_fips = sprintf("%05d", as.integer(GEOID_COUNTY_20))
    ) %>%
    group_by(zip5) %>%
    slice_max(AREALAND_PART, n = 1, with_ties = FALSE) %>%
    ungroup() %>%
    select(zip5, county_fips)
}, error = function(e) {
  cat("Primary crosswalk failed:", conditionMessage(e), "\n")
  stop("FATAL: Could not fetch ZIP-to-county crosswalk. Cannot proceed without real data.")
})

cat("ZIP-county crosswalk loaded:", nrow(zip_county), "entries\n")

# Join FC locations to county FIPS via ZIP code
fc <- fc %>%
  left_join(zip_county, by = "zip5")

cat("FCs matched to county via ZIP:", sum(!is.na(fc$county_fips)), "of", nrow(fc), "\n")

# For unmatched FCs, try geocoding
unmatched <- fc %>% filter(is.na(county_fips) & !is.na(location_clean) & nchar(location_clean) > 10)
if (nrow(unmatched) > 0) {
  cat("Attempting geocoding for", nrow(unmatched), "unmatched FCs...\n")
  unmatched_geo <- unmatched %>%
    mutate(address_for_geo = location_clean) %>%
    geocode(address = address_for_geo, method = "osm", quiet = TRUE) %>%
    filter(!is.na(lat) & !is.na(long))

  if (nrow(unmatched_geo) > 0) {
    county_shapes <- tigris::counties(cb = TRUE, year = 2020, progress_bar = FALSE) %>%
      sf::st_transform(4326)

    geo_sf <- sf::st_as_sf(unmatched_geo, coords = c("long", "lat"), crs = 4326)
    geo_joined <- sf::st_join(geo_sf, county_shapes)

    geo_fips <- geo_joined %>%
      sf::st_drop_geometry() %>%
      mutate(county_fips = paste0(STATEFP, COUNTYFP)) %>%
      select(fc_code, county_fips_geo = county_fips) %>%
      distinct(fc_code, .keep_all = TRUE)

    fc <- fc %>%
      left_join(geo_fips, by = "fc_code") %>%
      mutate(county_fips = coalesce(county_fips, county_fips_geo)) %>%
      select(-county_fips_geo)
  }
}

cat("Final FCs matched to county:", sum(!is.na(fc$county_fips)), "of", nrow(fc), "\n")

# Keep only matched FCs
fc_final <- fc %>%
  filter(!is.na(county_fips)) %>%
  select(fc_code, location_clean, state_abbr, county_fips, zip5,
         year_opened = year_opened_clean, sqft = sqft_clean, description) %>%
  arrange(year_opened, county_fips)

# Determine first FC opening per county (treatment timing)
treatment <- fc_final %>%
  group_by(county_fips) %>%
  summarise(
    first_fc_year = min(year_opened),
    n_fcs = n(),
    first_fc_code = first(fc_code),
    total_sqft = sum(sqft, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nTreatment summary:\n")
cat("  Treated counties:", nrow(treatment), "\n")
cat("  Treatment year range:", min(treatment$first_fc_year), "-", max(treatment$first_fc_year), "\n")
print(table(treatment$first_fc_year))

# Validate: no years outside 1995-2020
stopifnot(all(treatment$first_fc_year >= 1995 & treatment$first_fc_year <= 2020))

# Save treatment data
saveRDS(fc_final, "../data/amazon_fc_locations.rds")
saveRDS(treatment, "../data/treatment_timing.rds")
write.csv(fc_final, "../data/amazon_fc_locations.csv", row.names = FALSE)

# ---------- Part 2: QWI Race Panel (pre-fetched via Python/DuckDB) -----------

cat("\n\nLoading QWI race panel (pre-fetched from Azure)...\n")

# QWI was fetched via Python DuckDB (Azure extension works in Python but not R)
qwi_raw <- fread("../data/qwi_warehousing_race.csv")
qwi_placebo <- fread("../data/qwi_placebo_race.csv")

cat("QWI warehousing rows:", nrow(qwi_raw), "\n")
cat("Unique counties:", uniqueN(qwi_raw$county_fips), "\n")
cat("Year range:", min(qwi_raw$year), "-", max(qwi_raw$year), "\n")
cat("Races:", paste(unique(qwi_raw$race), collapse = ", "), "\n")
cat("Placebo rows:", nrow(qwi_placebo), "\n")

# Save as RDS for faster loading in subsequent scripts
saveRDS(as.data.frame(qwi_raw), "../data/qwi_warehousing_race.rds")
saveRDS(as.data.frame(qwi_placebo), "../data/qwi_placebo_race.rds")

cat("\nData fetch complete.\n")
