## ============================================================
## 01_fetch_data.R — Data acquisition from three sources
## Paper: Does Foreign Aid Buffer Oil Revenue Shocks?
##        Geocoded Evidence from Nigeria
## ============================================================

source("00_packages.R")

DATA_DIR <- "../data"
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)

## ============================================================
## A) AidData Nigeria AIMS v1.3.2 — Geocoded aid projects
##    Source: Already downloaded to data/nigeria_aims/
## ============================================================

cat("\n========== A) AIDDATA GEOCODED PROJECTS ==========\n")

aims_dir <- file.path(DATA_DIR,
  "nigeria_aims/NigeriaAIMS_GeocodedResearchRelease_Level1_v1.3.2/data")

## Load the merged project-location file (level_1a has both)
level1a <- fread(file.path(aims_dir, "level_1a.csv"))
projects <- fread(file.path(aims_dir, "projects.csv"))
locations <- fread(file.path(aims_dir, "locations.csv"))
transactions <- fread(file.path(aims_dir, "transactions.csv"))

cat(sprintf("AidData loaded: %d projects, %d locations, %d transactions\n",
            nrow(projects), nrow(locations), nrow(transactions)))
cat(sprintf("Level 1a merged file: %d rows\n", nrow(level1a)))

## Validate
stopifnot("Expected 300+ projects" = nrow(projects) >= 300)
stopifnot("Expected 1000+ locations" = nrow(locations) >= 1000)

## Save as RDS for downstream scripts
saveRDS(projects, file.path(DATA_DIR, "aiddata_projects.rds"))
saveRDS(locations, file.path(DATA_DIR, "aiddata_locations.rds"))
saveRDS(transactions, file.path(DATA_DIR, "aiddata_transactions.rds"))
saveRDS(level1a, file.path(DATA_DIR, "aiddata_level1a.rds"))

## ============================================================
## B) UCDP GED v24.1 — Georeferenced conflict events
##    Source: Uppsala Conflict Data Program (free download)
##    Pre-filtered to Nigeria in data/ucdp_nigeria.csv
## ============================================================

cat("\n========== B) UCDP GED CONFLICT DATA ==========\n")

ucdp_cache <- file.path(DATA_DIR, "ucdp_nigeria.rds")

if (file.exists(ucdp_cache)) {
  cat("Loading cached UCDP data...\n")
  conflict <- readRDS(ucdp_cache)
} else {
  ucdp_file <- file.path(DATA_DIR, "ucdp_nigeria.csv")

  if (!file.exists(ucdp_file)) {
    ## Download UCDP GED v24.1 and filter to Nigeria
    cat("Downloading UCDP GED v24.1...\n")
    zip_file <- file.path(DATA_DIR, "ged241-csv.zip")
    download.file("https://ucdp.uu.se/downloads/ged/ged241-csv.zip",
                  zip_file, mode = "wb", quiet = FALSE)
    unzip(zip_file, exdir = DATA_DIR)
    full_ged <- fread(file.path(DATA_DIR, "GEDEvent_v24_1.csv"))
    nigeria_ged <- full_ged[country == "Nigeria"]
    fwrite(nigeria_ged, ucdp_file)
    file.remove(zip_file)
    file.remove(file.path(DATA_DIR, "GEDEvent_v24_1.csv"))
    cat(sprintf("Filtered %d Nigeria events from UCDP GED\n", nrow(nigeria_ged)))
  }

  raw <- fread(ucdp_file)

  ## Parse into clean format (clean CSV has only selected columns)
  conflict <- data.table(
    event_id   = raw$id,
    year       = as.integer(raw$year),
    event_date = as.Date(raw$date_start),
    end_date   = as.Date(raw$date_end),
    type_of_violence = as.integer(raw$type_of_violence),
    conflict_name = raw$conflict_name,
    side_a     = raw$side_a,
    side_b     = raw$side_b,
    admin1     = raw$adm_1,
    admin2     = raw$adm_2,
    latitude   = as.numeric(raw$latitude),
    longitude  = as.numeric(raw$longitude),
    deaths_a   = as.integer(raw$deaths_a),
    deaths_b   = as.integer(raw$deaths_b),
    deaths_civ = as.integer(raw$deaths_civilians),
    deaths_unk = as.integer(raw$deaths_unknown),
    best_est   = as.integer(raw$best),
    high_est   = as.integer(raw$high),
    low_est    = as.integer(raw$low),
    where_prec = as.integer(raw$where_prec)
  )

  ## Classify violence types
  ## UCDP type_of_violence: 1=state-based, 2=non-state, 3=one-sided
  conflict[, event_type := fcase(
    type_of_violence == 1, "State-based conflict",
    type_of_violence == 2, "Non-state conflict",
    type_of_violence == 3, "One-sided violence",
    default = "Unknown"
  )]

  saveRDS(conflict, ucdp_cache)
  cat(sprintf("Saved %d UCDP events for Nigeria\n", nrow(conflict)))
}

cat(sprintf("UCDP: %d events, %d-%d, %d admin1 regions\n",
            nrow(conflict),
            min(conflict$year, na.rm = TRUE),
            max(conflict$year, na.rm = TRUE),
            uniqueN(conflict$admin1)))

## ============================================================
## C) Brent crude oil prices from FRED
## ============================================================

cat("\n========== C) BRENT CRUDE OIL PRICES (FRED) ==========\n")

fred_cache <- file.path(DATA_DIR, "brent_crude.rds")

if (file.exists(fred_cache)) {
  cat("Loading cached oil prices...\n")
  oil <- readRDS(fred_cache)
} else {
  fred_key <- Sys.getenv("FRED_API_KEY")
  if (fred_key == "") stop("FRED_API_KEY must be set in .env")

  url <- sprintf(
    "https://api.stlouisfed.org/fred/series/observations?series_id=DCOILBRENTEU&api_key=%s&file_type=json&observation_start=1989-01-01",
    fred_key
  )
  resp <- GET(url, timeout(30))
  if (status_code(resp) != 200) stop("FRED API failed")

  json <- content(resp, as = "parsed")
  oil <- rbindlist(lapply(json$observations, function(x) {
    data.table(
      date  = as.Date(x$date),
      price = as.numeric(ifelse(x$value == ".", NA, x$value))
    )
  }))
  oil <- oil[!is.na(price)]
  saveRDS(oil, fred_cache)
}

## Monthly average for panel merge
oil[, ym := floor_date(date, "month")]
oil_monthly <- oil[, .(
  oil_price = mean(price, na.rm = TRUE)
), by = ym]

fwrite(oil_monthly, file.path(DATA_DIR, "oil_monthly.csv"))

## Annual average
oil_annual <- oil[, .(
  oil_price_avg = mean(price, na.rm = TRUE),
  oil_price_min = min(price, na.rm = TRUE),
  oil_price_max = max(price, na.rm = TRUE)
), by = .(year = year(date))]

fwrite(oil_annual, file.path(DATA_DIR, "oil_annual.csv"))

cat(sprintf("Oil prices: %d-%d, range $%.1f-$%.1f\n",
            min(oil_annual$year), max(oil_annual$year),
            min(oil_annual$oil_price_avg), max(oil_annual$oil_price_avg)))

## ============================================================
## FINAL VALIDATION
## ============================================================

cat("\n========== DATA VALIDATION ==========\n")

stopifnot("Expected 300+ AidData projects" = nrow(projects) >= 300)
cat(sprintf("  AidData: %d projects, %d locations\n",
            nrow(projects), nrow(locations)))

stopifnot("Expected 1000+ UCDP events" = nrow(conflict) >= 1000)
cat(sprintf("  UCDP: %s events, %d-%d\n",
            format(nrow(conflict), big.mark = ","),
            min(conflict$year), max(conflict$year)))

stopifnot("Expected oil prices" = nrow(oil_monthly) >= 100)
cat(sprintf("  Oil prices: %d months\n", nrow(oil_monthly)))

cat("\nData validation passed. All sources loaded.\n")
