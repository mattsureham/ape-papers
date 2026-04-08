## 01_fetch_data.R — Fetch EOIR parquet, ACS housing, court crosswalk
## apep_1416: The Legal Status Premium in Local Housing Markets

source("00_packages.R")

if (!requireNamespace("arrow", quietly = TRUE)) {
  install.packages("arrow", repos = "https://cran.r-project.org")
}
library(arrow)

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

census_key <- Sys.getenv("CENSUS_API_KEY")
if (census_key == "") stop("CENSUS_API_KEY not set in .env")

## ============================================================
## 1. EOIR Case Data (processed parquet from deportationdata.org)
## ============================================================
cat("=== Step 1: EOIR Case Data ===\n")

parquet_file <- file.path(data_dir, "eoir_cases.parquet")

if (!file.exists(parquet_file) || file.size(parquet_file) < 1e6) {
  cat("  Downloading EOIR cases parquet (317 MB)...\n")
  download.file(
    "https://media.githubusercontent.com/media/deportationdata/eoir/main/data/cases.parquet",
    parquet_file, mode = "wb", quiet = FALSE
  )
}
stopifnot("EOIR parquet download failed" = file.exists(parquet_file) && file.size(parquet_file) > 1e6)
cat(sprintf("  EOIR parquet: %.1f MB\n", file.size(parquet_file) / 1e6))

## Verify schema
schema <- arrow::open_dataset(parquet_file)$schema
cat(sprintf("  Columns: %s\n", paste(schema$names, collapse = ", ")))

## ============================================================
## 2. Court-to-County crosswalk
## ============================================================
cat("\n=== Step 2: Court-County Crosswalk ===\n")

## Manual crosswalk: EOIR court names to county FIPS
## The parquet uses decoded court names (e.g., "New York") not codes
court_county <- data.table(
  court_name = c(
    "New York City", "Los Angeles", "San Francisco", "Miami", "Chicago",
    "Houston", "Arlington", "San Diego", "Boston",
    "Atlanta", "Newark", "Baltimore", "Philadelphia", "Denver",
    "Seattle", "Cleveland", "Detroit", "Dallas",
    "Orlando", "Hartford", "Phoenix", "Las Vegas", "Memphis",
    "Santa Ana", "Buffalo", "Portland",
    "Tacoma", "Harlingen", "El Paso", "San Juan", "Omaha",
    "Kansas City", "St. Louis", "Salt Lake City",
    "Honolulu", "Minneapolis", "Imperial", "Pittsburgh", "Bloomington"
  ),
  county_fips = c(
    "36061", "06037", "06075", "12086", "17031", "48201", "51013", "06073", "25025",
    "13121", "36047", "24510", "42101", "08031", "53033", "39035", "26163", "48113",
    "12095", "09003", "04013", "32003", "47157", "06059", "36029", "41051",
    "53053", "48215", "48141", "72127", "31055", "29095", "29510", "49035",
    "15003", "27053", "06025", "42003", "55025"
  ),
  ## Also include common code variants from EOIR
  base_city_code = c(
    "NYC", "LOS", "SFR", "MIA", "CHI", "HOU", "ARL", "SAN", "BOS",
    "ATL", "NEW", "BAL", "PHI", "DEN", "SEA", "CLE", "DET", "DAL",
    "ORL", "HAR", "PHO", "LAS", "MEM", "SNA", "BUF", "POR",
    "TAC", "HLG", "ELP", "SJN", "OMA", "KCA", "STL", "SLC",
    "HON", "MIN", "IMP", "PIB", "BLM"
  )
)

fwrite(court_county, file.path(data_dir, "court_county_crosswalk.csv"))
cat(sprintf("  Court-county crosswalk: %d courts mapped\n", nrow(court_county)))

## ============================================================
## 3. ACS Housing Outcomes (5-year estimates, county level)
## ============================================================
cat("\n=== Step 3: ACS Housing Data ===\n")

acs_vars <- c("B25064_001E", "B25077_001E", "B25003_001E", "B25003_002E",
              "B05001_001E", "B05001_006E", "B01003_001E", "B19013_001E")

acs_list <- list()
for (yr in 2010:2022) {
  cat(sprintf("  ACS %d...", yr))
  url <- sprintf(
    "https://api.census.gov/data/%d/acs/acs5?get=%s&for=county:*&key=%s",
    yr, paste(acs_vars, collapse = ","), census_key
  )
  resp <- tryCatch(httr::GET(url, httr::timeout(60)), error = function(e) NULL)
  if (is.null(resp) || httr::status_code(resp) != 200) {
    cat(" SKIP\n")
    next
  }
  raw <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
  if (is.null(raw) || nrow(raw) < 2) { cat(" empty\n"); next }
  dt <- as.data.table(raw[-1, , drop = FALSE])
  setnames(dt, c(acs_vars, "state", "county"))
  dt[, year := yr]
  for (v in acs_vars) dt[, (v) := as.numeric(get(v))]
  acs_list[[as.character(yr)]] <- dt
  cat(sprintf(" %d counties\n", nrow(dt)))
  Sys.sleep(0.5)
}
acs <- rbindlist(acs_list, fill = TRUE)
stopifnot("No ACS data retrieved" = nrow(acs) > 0)

acs[, fips := paste0(state, county)]

setnames(acs, c("B25064_001E", "B25077_001E", "B25003_001E", "B25003_002E",
                "B05001_001E", "B05001_006E", "B01003_001E", "B19013_001E"),
         c("median_rent", "median_home_value", "tenure_total", "owner_occupied",
           "citizen_total", "noncitizen", "total_pop", "median_hh_income"))

acs[, homeownership_rate := owner_occupied / tenure_total]
acs[, noncitizen_share := noncitizen / citizen_total]
acs[, log_rent := log(median_rent)]
acs[, log_home_value := log(median_home_value)]
acs[, log_income := log(median_hh_income)]

fwrite(acs, file.path(data_dir, "acs_housing.csv"))
cat(sprintf("\n  ACS: %d county-year obs, %d counties, years %d-%d\n",
            nrow(acs), uniqueN(acs$fips), min(acs$year), max(acs$year)))

cat("\n=== Data fetch complete ===\n")
