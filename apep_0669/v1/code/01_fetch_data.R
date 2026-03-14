## 01_fetch_data.R — Download Zillow ZHVI + Census spatial data
## APEP Paper apep_0669: Capitalization of Reproductive Rights

source("00_packages.R")

cat("=== Fetching Data ===\n")

# ----------------------------------------------------------------
# 1. Download Zillow ZHVI (ZIP-level, monthly, all homes)
# ----------------------------------------------------------------
zhvi_url <- "https://files.zillowstatic.com/research/public_csvs/zhvi/Zip_zhvi_uc_sfrcondo_tier_0.33_0.67_sm_sa_month.csv"

zhvi_file <- "../data/zhvi_zip.csv"

if (!file.exists(zhvi_file)) {
  cat("Downloading Zillow ZHVI...\n")
  resp <- GET(zhvi_url, write_disk(zhvi_file, overwrite = TRUE),
              timeout(300))
  if (resp$status_code != 200) {
    stop("FATAL: Failed to download Zillow ZHVI. Status: ", resp$status_code)
  }
  cat("  Downloaded:", round(file.size(zhvi_file) / 1e6, 1), "MB\n")
} else {
  cat("  ZHVI already downloaded.\n")
}

zhvi_raw <- fread(zhvi_file)
cat("  ZHVI rows:", nrow(zhvi_raw), "| columns:", ncol(zhvi_raw), "\n")

# Validate: check that we have monthly columns
date_cols <- grep("^\\d{4}-\\d{2}-\\d{2}$", names(zhvi_raw), value = TRUE)
if (length(date_cols) < 12) {
  stop("FATAL: ZHVI data has fewer than 12 date columns. Data format may have changed.")
}
cat("  Date columns:", length(date_cols), "| Range:", min(date_cols), "to", max(date_cols), "\n")

# ----------------------------------------------------------------
# 2. Download Census ZCTA centroids via tigris
# ----------------------------------------------------------------
cat("Downloading ZCTA shapefiles...\n")
zctas_sf <- tryCatch({
  zctas(cb = TRUE, year = 2020)
}, error = function(e) {
  stop("FATAL: Cannot download ZCTA shapefiles from Census. Error: ", e$message)
})

if (is.null(zctas_sf) || nrow(zctas_sf) == 0) {
  stop("FATAL: ZCTA shapefile download returned empty data.")
}
cat("  ZCTAs downloaded:", nrow(zctas_sf), "\n")

# Extract centroids
zcta_centroids <- zctas_sf %>%
  st_centroid() %>%
  mutate(
    lon = st_coordinates(.)[, 1],
    lat = st_coordinates(.)[, 2]
  ) %>%
  st_drop_geometry() %>%
  select(ZCTA5CE20, lon, lat) %>%
  rename(zip = ZCTA5CE20)

cat("  ZCTA centroids extracted:", nrow(zcta_centroids), "\n")

# ----------------------------------------------------------------
# 3. Download state boundaries for border distance computation
# ----------------------------------------------------------------
cat("Downloading state boundaries...\n")
states_sf <- tryCatch({
  states(cb = TRUE, year = 2020)
}, error = function(e) {
  stop("FATAL: Cannot download state boundaries. Error: ", e$message)
})

if (is.null(states_sf) || nrow(states_sf) == 0) {
  stop("FATAL: State boundary download returned empty data.")
}

# Extract MO, IL, KS boundaries
mo_sf <- states_sf %>% filter(STUSPS == "MO")
il_sf <- states_sf %>% filter(STUSPS == "IL")
ks_sf <- states_sf %>% filter(STUSPS == "KS")

cat("  State boundaries loaded: MO, IL, KS\n")

# ----------------------------------------------------------------
# 4. Compute shared borders
# ----------------------------------------------------------------
cat("Computing shared state borders...\n")

# MO-IL border (St. Louis)
mo_border <- st_boundary(mo_sf)
il_border <- st_boundary(il_sf)

# The shared border is the intersection of the two boundary lines
mo_il_border <- st_intersection(mo_border, il_border)
if (nrow(mo_il_border) == 0 || st_is_empty(mo_il_border)) {
  # Fallback: use buffered intersection
  cat("  Direct border intersection empty, using buffer method...\n")
  mo_il_border <- st_intersection(
    st_buffer(mo_border, 100),  # 100m buffer
    il_border
  )
}
cat("  MO-IL border computed\n")

# MO-KS border (Kansas City)
ks_border <- st_boundary(ks_sf)
mo_ks_border <- st_intersection(mo_border, ks_border)
if (nrow(mo_ks_border) == 0 || st_is_empty(mo_ks_border)) {
  cat("  Direct border intersection empty, using buffer method...\n")
  mo_ks_border <- st_intersection(
    st_buffer(mo_border, 100),
    ks_border
  )
}
cat("  MO-KS border computed\n")

# ----------------------------------------------------------------
# 5. Define MSA ZIPs
# ----------------------------------------------------------------
# St. Louis MSA: CBSA 41180
# Kansas City MSA: CBSA 28140
# Use HUD ZIP-CBSA crosswalk or define by county FIPS

# St. Louis MSA counties (FIPS)
stl_counties_mo <- c("29510",  # St. Louis City
                      "29189",  # St. Louis County
                      "29183",  # St. Charles
                      "29099",  # Jefferson
                      "29071",  # Franklin
                      "29113",  # Lincoln
                      "29219")  # Warren

stl_counties_il <- c("17119",  # Madison
                      "17163",  # St. Clair
                      "17005",  # Bond
                      "17013",  # Calhoun
                      "17027",  # Clinton
                      "17083",  # Jersey
                      "17117",  # Macoupin
                      "17133")  # Monroe

# Kansas City MSA counties
kc_counties_mo <- c("29095",  # Jackson
                     "29037",  # Cass
                     "29047",  # Clay
                     "29165",  # Platte
                     "29107",  # Lafayette
                     "29177",  # Ray
                     "29025",  # Caldwell
                     "29013",  # Bates
                     "29037")  # Clinton MO

kc_counties_ks <- c("20091",  # Johnson
                     "20209",  # Wyandotte
                     "20103",  # Leavenworth
                     "20121",  # Miami
                     "20087")  # Jefferson KS

# Download county-ZCTA relationship
cat("Downloading county-to-ZCTA relationship...\n")

# Use the HUD USPS ZIP Crosswalk or the Census ZCTA-County relationship file
# We'll use the Census relationship file
rel_url <- "https://www2.census.gov/geo/docs/maps-data/data/rel2020/zcta520/tab20_zcta520_county20_natl.txt"
rel_file <- "../data/zcta_county_rel.txt"

if (!file.exists(rel_file)) {
  resp <- GET(rel_url, write_disk(rel_file, overwrite = TRUE), timeout(120))
  if (resp$status_code != 200) {
    stop("FATAL: Failed to download ZCTA-County relationship file. Status: ", resp$status_code)
  }
}

zcta_county <- fread(rel_file)
cat("  ZCTA-County relationships:", nrow(zcta_county), "\n")

# Standardize column names
names(zcta_county) <- tolower(names(zcta_county))
cat("  Columns:", paste(names(zcta_county), collapse = ", "), "\n")

# The file has GEOID_ZCTA5_20 and GEOID_COUNTY_20
# Map ZCTAs to counties
if ("geoid_zcta5_20" %in% names(zcta_county)) {
  zcta_county <- zcta_county %>%
    mutate(
      zip = sprintf("%05d", as.integer(geoid_zcta5_20)),
      county_fips = sprintf("%05d", as.integer(geoid_county_20))
    )
} else {
  # Try alternative column names
  zip_col <- grep("zcta", names(zcta_county), value = TRUE)[1]
  county_col <- grep("county", names(zcta_county), value = TRUE)[1]
  zcta_county <- zcta_county %>%
    mutate(
      zip = sprintf("%05d", as.integer(.data[[zip_col]])),
      county_fips = sprintf("%05d", as.integer(.data[[county_col]]))
    )
}

# Remove any NAs from formatting
zcta_county <- zcta_county %>% filter(!is.na(zip) & zip != "   NA")

# Identify ZIPs in each MSA
stl_zips <- zcta_county %>%
  filter(county_fips %in% c(stl_counties_mo, stl_counties_il)) %>%
  distinct(zip) %>%
  pull(zip)

kc_zips <- zcta_county %>%
  filter(county_fips %in% c(kc_counties_mo, kc_counties_ks)) %>%
  distinct(zip) %>%
  pull(zip)

# State assignment for each ZIP — take the first row per ZIP
zip_state <- zcta_county %>%
  mutate(state_fips = substr(county_fips, 1, 2)) %>%
  distinct(zip, .keep_all = TRUE) %>%
  select(zip, county_fips, state_fips)

cat("  St. Louis MSA ZIPs:", length(stl_zips), "\n")
cat("  Kansas City MSA ZIPs:", length(kc_zips), "\n")

# ----------------------------------------------------------------
# 6. Save intermediate data
# ----------------------------------------------------------------
saveRDS(zhvi_raw, "../data/zhvi_raw.rds")
saveRDS(zcta_centroids, "../data/zcta_centroids.rds")
saveRDS(mo_il_border, "../data/mo_il_border.rds")
saveRDS(mo_ks_border, "../data/mo_ks_border.rds")
saveRDS(list(stl = stl_zips, kc = kc_zips), "../data/msa_zips.rds")
saveRDS(zip_state, "../data/zip_state.rds")

cat("=== Data fetch complete ===\n")
