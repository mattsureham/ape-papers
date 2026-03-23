## ==========================================================================
## 01_fetch_data.R — Fetch internet shutdown data and nighttime lights
## Paper: Darkness by Decree (apep_0799)
## ==========================================================================

library(data.table)
library(jsonlite)
library(sf)

## setwd handled by caller — run from the paper workspace directory

cat("=== STEP 1: Fetch Internet Shutdown Data ===\n")

## --- 1a. Download DW Data GitHub shutdown dataset (382 labeled events) ------
## Source: https://github.com/internetfreedom/internet-shutdowns-india
## Alternative: DW Data compiled dataset with trigger-type labels

# Try the Software Freedom Law Centre (SFLC.in) / Internet Freedom Foundation
# compiled dataset from DW Data
# Note: this script is not used — data fetched via 01b_fetch_nightlights.py and downloaded RDS
dw_url <- "https://raw.githubusercontent.com/nicam/indias-internet-shutdowns/master/data/shutdowns.csv"
cat("Downloading shutdown data from GitHub...\n")

shutdown_raw <- tryCatch(
  fread(dw_url, showProgress = FALSE),
  error = function(e) {
    cat("Primary source failed:", e$message, "\n")
    NULL
  }
)

if (is.null(shutdown_raw)) {
  # Try alternative: internetshutdowns.in API/data
  # The Internet Shutdown Tracker by the Internet Freedom Foundation
  alt_url <- "https://raw.githubusercontent.com/nicam/indias-internet-shutdowns/master/data/shutdowns.json"
  cat("Trying JSON format...\n")
  shutdown_json <- tryCatch(
    fromJSON(alt_url),
    error = function(e) {
      cat("JSON source also failed:", e$message, "\n")
      NULL
    }
  )
  if (!is.null(shutdown_json)) {
    shutdown_raw <- as.data.table(shutdown_json)
  }
}

# If GitHub sources fail, try the Software Freedom Law Centre tracker
if (is.null(shutdown_raw)) {
  stop("FATAL: Could not download shutdown data from any source. Cannot proceed with simulated data.")
}

cat("Downloaded", nrow(shutdown_raw), "shutdown events\n")
cat("Columns:", paste(names(shutdown_raw), collapse = ", "), "\n")
cat("Sample:\n")
print(head(shutdown_raw, 3))

fwrite(shutdown_raw, "data/shutdowns_raw.csv")
cat("Saved raw shutdown data to data/shutdowns_raw.csv\n")

cat("\n=== STEP 2: Fetch India District Boundaries ===\n")

## --- 2. Download India GADM Level 2 (district) boundaries ------------------
library(geodata)

gadm_path <- "data/india_gadm"
dir.create(gadm_path, showWarnings = FALSE, recursive = TRUE)

cat("Downloading India GADM Level 2 (districts)...\n")
india_districts <- gadm(country = "IND", level = 2, path = gadm_path)
india_sf <- st_as_sf(india_districts)

cat("Downloaded", nrow(india_sf), "district polygons\n")
cat("CRS:", st_crs(india_sf)$input, "\n")
cat("Sample district names:", paste(head(india_sf$NAME_2, 5), collapse = ", "), "\n")
cat("State names:", paste(head(unique(india_sf$NAME_1), 5), collapse = ", "), "\n")

st_write(india_sf, "data/india_districts.gpkg", delete_dsn = TRUE, quiet = TRUE)
cat("Saved district boundaries to data/india_districts.gpkg\n")

cat("\n=== STEP 3: Fetch VIIRS Nighttime Lights ===\n")

## --- 3. Download VIIRS Black Marble monthly composites ----------------------
library(blackmarbler)

# NASA Earthdata bearer token
bearer <- Sys.getenv("NASA_EARTHDATA_API_KEY")
if (nchar(bearer) < 10) {
  stop("FATAL: NASA_EARTHDATA_API_KEY not set. Cannot fetch nightlights data.")
}

# Use VNP46A4 (yearly composites) for tractability
# Monthly (VNP46A3) would be ideal but too many downloads
# Yearly gives us district-year panel: ~700 districts x 12 years

cat("Extracting annual VIIRS Black Marble (VNP46A4) for India districts...\n")
cat("Years: 2012-2023\n")

# Extract nightlights for each year
# blackmarbler::bm_extract handles the spatial aggregation
ntl_annual <- bm_extract(
  roi_sf = india_sf,
  product_id = "VNP46A4",
  date = 2012:2023,
  bearer = bearer,
  aggregation_fun = "mean",
  quiet = FALSE
)

cat("Extracted nightlights for", nrow(ntl_annual), "district-year observations\n")
cat("Columns:", paste(names(ntl_annual), collapse = ", "), "\n")

# Convert to data.table and save
ntl_dt <- as.data.table(ntl_annual)
fwrite(ntl_dt, "data/ntl_annual.csv")
cat("Saved annual nightlights to data/ntl_annual.csv\n")

cat("\n=== STEP 4: Also try monthly data for event-study districts ===\n")

# For event studies, we need monthly resolution
# Download monthly data for 2017-2022 only (peak shutdown period)
# This is more tractable than full 2012-2024

cat("Extracting monthly VIIRS (VNP46A3) for 2017-2022...\n")

# Generate month sequences
months_seq <- seq(as.Date("2017-01-01"), as.Date("2022-12-01"), by = "month")

ntl_monthly <- tryCatch({
  bm_extract(
    roi_sf = india_sf,
    product_id = "VNP46A3",
    date = months_seq,
    bearer = bearer,
    aggregation_fun = "mean",
    quiet = FALSE
  )
}, error = function(e) {
  cat("Monthly download failed (expected if too many requests):", e$message, "\n")
  cat("Proceeding with annual data only.\n")
  NULL
})

if (!is.null(ntl_monthly)) {
  ntl_monthly_dt <- as.data.table(ntl_monthly)
  fwrite(ntl_monthly_dt, "data/ntl_monthly.csv")
  cat("Saved monthly nightlights to data/ntl_monthly.csv\n")
} else {
  cat("Monthly data not available. Will use annual data for analysis.\n")
}

cat("\n=== DATA FETCH COMPLETE ===\n")
cat("Files in data/:\n")
print(list.files("data/", recursive = TRUE))
