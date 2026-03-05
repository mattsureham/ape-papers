# ============================================================================
# 01_fetch_data.R — Download IRS SOI ZIP code data + geographic shapefiles
# APEP-0525: Tax Borders and the Rich
# ============================================================================

source("00_packages.R")

# ============================================================================
# 1. Download IRS SOI ZIP-code income data (2012-2021)
# ============================================================================

irs_years <- 12:21
irs_files <- paste0(sprintf("%02d", irs_years), "zpallagi.csv")
irs_urls  <- paste0("https://www.irs.gov/pub/irs-soi/", irs_files)

irs_all <- list()

for (i in seq_along(irs_years)) {
  yr <- irs_years[i]
  file_year <- 2000 + yr
  dest <- file.path(DATA_DIR, irs_files[i])

  if (!file.exists(dest)) {
    cat("Downloading IRS SOI ZIP data for", file_year, "...\n")
    tryCatch(
      download.file(irs_urls[i], dest, mode = "wb", quiet = TRUE),
      error = function(e) stop("Failed to download IRS data for ", file_year,
                               ": ", e$message,
                               "\nPivot research question or fix the source.")
    )
  }

  dt <- fread(dest, colClasses = list(character = c("STATEFIPS", "zipcode")))
  # Normalize column names to lowercase BEFORE adding to list
  setnames(dt, tolower(names(dt)))
  dt[, year := file_year]
  irs_all[[i]] <- dt
  cat("  Loaded", file_year, ":", nrow(dt), "rows\n")
}

irs <- rbindlist(irs_all, fill = TRUE)
cat("\nTotal IRS SOI records:", nrow(irs), "\n")

# Keep relevant columns
keep_cols <- c("statefips", "zipcode", "agi_stub", "n1", "n2", "a00100", "year")
# a00100 = Adjusted Gross Income
missing_cols <- setdiff(keep_cols, names(irs))
if (length(missing_cols) > 0) {
  stop("Missing expected columns: ", paste(missing_cols, collapse = ", "))
}
irs <- irs[, ..keep_cols]

# Clean ZIP codes (remove state-level aggregates)
irs <- irs[zipcode != "00000" & zipcode != "99999" & nchar(zipcode) == 5]

fwrite(irs, file.path(DATA_DIR, "irs_zip_panel.csv"))
cat("IRS panel saved:", nrow(irs), "rows,",
    uniqueN(irs$zipcode), "ZIP codes,",
    uniqueN(irs$year), "years\n")

# ============================================================================
# 2. Download ZCTA shapefiles for ZIP code centroids
# ============================================================================

zcta_file <- file.path(DATA_DIR, "zcta_centroids.csv")

if (!file.exists(zcta_file)) {
  # Use Census Gazetteer files (small text file) instead of full shapefile
  cat("Downloading ZCTA Gazetteer file from Census...\n")
  gaz_url <- "https://www2.census.gov/geo/docs/maps-data/data/gazetteer/2020_Gazetteer/2020_Gaz_zcta_national.zip"
  gaz_zip <- file.path(DATA_DIR, "2020_Gaz_zcta_national.zip")

  tryCatch(
    download.file(gaz_url, gaz_zip, mode = "wb", quiet = TRUE),
    error = function(e) stop("Failed to download ZCTA Gazetteer: ", e$message)
  )

  unzip(gaz_zip, exdir = DATA_DIR)
  gaz_file_path <- list.files(DATA_DIR, pattern = "Gaz_zcta", full.names = TRUE)
  gaz_file_path <- gaz_file_path[!grepl("\\.zip$", gaz_file_path)][1]

  gaz <- fread(gaz_file_path, sep = "\t")
  setnames(gaz, trimws(names(gaz)))

  zcta_dt <- data.table(
    zipcode = sprintf("%05d", gaz$GEOID),
    lon = gaz$INTPTLONG,
    lat = gaz$INTPTLAT
  )

  fwrite(zcta_dt, zcta_file)
  cat("ZCTA centroids saved:", nrow(zcta_dt), "ZIP codes\n")

  unlink(gaz_zip)
  file.remove(gaz_file_path)
} else {
  zcta_dt <- fread(zcta_file)
  cat("ZCTA centroids loaded:", nrow(zcta_dt), "ZIP codes\n")
}

# ============================================================================
# 3. Download state boundary shapefile for distance computation
# ============================================================================

state_border_file <- file.path(DATA_DIR, "state_borders.rds")

if (!file.exists(state_border_file)) {
  cat("Downloading state boundary shapefile...\n")
  state_url <- "https://www2.census.gov/geo/tiger/TIGER2020/STATE/tl_2020_us_state.zip"
  state_zip <- file.path(DATA_DIR, "tl_2020_us_state.zip")

  tryCatch(
    download.file(state_url, state_zip, mode = "wb", quiet = TRUE),
    error = function(e) stop("Failed to download state shapefile: ", e$message)
  )

  unzip(state_zip, exdir = file.path(DATA_DIR, "state_shp"))

  states <- st_read(file.path(DATA_DIR, "state_shp", "tl_2020_us_state.shp"),
                    quiet = TRUE)
  # Keep only contiguous US + DC
  states <- states[!states$STATEFP %in% c("02", "15", "60", "66", "69", "72", "78"), ]
  states <- st_transform(states, crs = 5070)  # Conus Albers for distance

  saveRDS(states, state_border_file)
  cat("State boundaries saved:", nrow(states), "states\n")

  unlink(file.path(DATA_DIR, "state_shp"), recursive = TRUE)
  unlink(state_zip)
} else {
  states <- readRDS(state_border_file)
  cat("State boundaries loaded:", nrow(states), "states\n")
}

# ============================================================================
# 4. State income tax rate data
# ============================================================================

# Top marginal state income tax rates for border pair states (Tax Foundation)
# These are the top marginal rates as of the relevant year
tax_rates <- fread(text = "
state_fips,state_abbr,state_name,rate_2012,rate_2013,rate_2014,rate_2015,rate_2016,rate_2017,rate_2018,rate_2019,rate_2020,rate_2021
06,CA,California,13.30,13.30,13.30,13.30,13.30,13.30,13.30,13.30,13.30,13.30
32,NV,Nevada,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00
34,NJ,New Jersey,8.97,8.97,8.97,8.97,8.97,8.97,10.75,10.75,10.75,10.75
42,PA,Pennsylvania,3.07,3.07,3.07,3.07,3.07,3.07,3.07,3.07,3.07,3.07
36,NY,New York,8.82,8.82,8.82,8.82,8.82,8.82,8.82,8.82,8.82,10.90
09,CT,Connecticut,6.70,6.70,6.99,6.99,6.99,6.99,6.99,6.99,6.99,6.99
27,MN,Minnesota,7.85,9.85,9.85,9.85,9.85,9.85,9.85,9.85,9.85,9.85
46,SD,South Dakota,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00
41,OR,Oregon,9.90,9.90,9.90,9.90,9.90,9.90,9.90,9.90,9.90,9.90
53,WA,Washington,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00
55,WI,Wisconsin,7.75,7.65,7.65,7.65,7.65,7.65,7.65,7.65,7.65,7.65
04,AZ,Arizona,4.54,4.54,4.54,4.54,4.54,4.54,4.50,4.50,4.50,4.50
28,MS,Mississippi,5.00,5.00,5.00,5.00,5.00,5.00,5.00,5.00,5.00,5.00
47,TN,Tennessee,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00
")

fwrite(tax_rates, file.path(DATA_DIR, "state_tax_rates.csv"))
cat("State tax rates saved\n")

# ============================================================================
# 5. Define border pairs
# ============================================================================

border_pairs <- fread(text = "
pair_id,high_tax_fips,low_tax_fips,high_tax_abbr,low_tax_abbr,pair_label
1,34,42,NJ,PA,NJ-PA
2,36,09,NY,CT,NY-CT
3,06,32,CA,NV,CA-NV
4,27,46,MN,SD,MN-SD
5,41,53,OR,WA,OR-WA
6,27,55,MN,WI,MN-WI
7,06,04,CA,AZ,CA-AZ
8,36,42,NY,PA,NY-PA
")

fwrite(border_pairs, file.path(DATA_DIR, "border_pairs.csv"))
cat("Border pairs defined:", nrow(border_pairs), "pairs\n")

# ============================================================================
# 6. Validation
# ============================================================================

stopifnot("Expected 10 years of IRS data" = uniqueN(irs$year) == 10)
stopifnot("Expected 25000+ ZIP codes" = uniqueN(irs$zipcode) >= 25000)
stopifnot("Expected 25000+ ZCTA centroids" = nrow(zcta_dt) >= 25000)
stopifnot("Expected 48+ states in shapefile" = nrow(states) >= 48)

cat("\n=== DATA VALIDATION PASSED ===\n")
cat("IRS ZIP panel:", nrow(irs), "rows,", uniqueN(irs$zipcode), "ZIPs,",
    uniqueN(irs$year), "years\n")
cat("ZCTA centroids:", nrow(zcta_dt), "ZIPs with coordinates\n")
cat("State boundaries:", nrow(states), "states\n")
cat("Border pairs:", nrow(border_pairs), "defined\n")
