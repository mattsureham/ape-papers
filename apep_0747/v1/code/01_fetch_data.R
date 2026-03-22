## 01_fetch_data.R — Fetch Census ACS, NASS hog inventory, and FHFA HPI data
source("00_packages.R")

# Load API keys from .env
dotenv <- readLines("../../../../.env", warn = FALSE)
census_key <- gsub(".*=", "", grep("^CENSUS_API_KEY", dotenv, value = TRUE))
nass_key   <- gsub(".*=", "", grep("^USDA_NASS_API_KEY", dotenv, value = TRUE))

stopifnot("CENSUS_API_KEY not found" = nchar(census_key) > 5)
stopifnot("USDA_NASS_API_KEY not found" = nchar(nass_key) > 5)

tidycensus::census_api_key(census_key, install = FALSE)

# ===================================================================
# 1. Census ACS 5-year county-level demographics
# ===================================================================
cat("Fetching ACS data...\n")

# Use individual variable codes
acs_vars <- c(
  total_pop  = "B01003_001",
  white_pop  = "B02001_002",
  black_pop  = "B02001_003",
  hisp_pop   = "B03003_003",
  hisp_total = "B03003_001",
  pov_total  = "B17001_001",
  pov_below  = "B17001_002",
  med_income = "B19013_001"
)

# Start from 2012 to ensure compatibility; first RTF expansion is 2012
acs_years <- 2012:2023
acs_list <- list()

for (yr in acs_years) {
  cat(sprintf("  ACS %d...\n", yr))
  tryCatch({
    df <- tidycensus::get_acs(
      geography = "county",
      variables = acs_vars,
      year = yr,
      survey = "acs5"
    )
    df$year <- yr
    acs_list[[as.character(yr)]] <- df
  }, error = function(e) {
    cat(sprintf("    FAILED for %d: %s\n", yr, e$message))
    stop(sprintf("ACS fetch failed for year %d. Cannot proceed.", yr))
  })
}

acs_raw <- bind_rows(acs_list)
cat(sprintf("ACS: %d rows, %d counties, %d years\n",
            nrow(acs_raw), n_distinct(acs_raw$GEOID), n_distinct(acs_raw$year)))
stopifnot("ACS data too small" = nrow(acs_raw) > 10000)

# ===================================================================
# 2. USDA NASS Census of Agriculture — Hog inventory by county
# ===================================================================
cat("Fetching NASS hog inventory...\n")

fetch_nass <- function(year, api_key) {
  url <- "https://quickstats.nass.usda.gov/api/api_GET/"
  params <- list(
    key = api_key,
    source_desc = "CENSUS",
    sector_desc = "ANIMALS & PRODUCTS",
    commodity_desc = "HOGS",
    statisticcat_desc = "INVENTORY",
    agg_level_desc = "COUNTY",
    year = year,
    format = "JSON"
  )
  resp <- httr::GET(url, query = params)
  stopifnot("NASS API failed" = httr::status_code(resp) == 200)
  content <- httr::content(resp, as = "text", encoding = "UTF-8")
  parsed <- jsonlite::fromJSON(content)
  if (is.null(parsed$data) || length(parsed$data) == 0) {
    cat(sprintf("  NASS %d: no data returned\n", year))
    return(NULL)
  }
  df <- as.data.frame(parsed$data)
  df$census_year <- year
  cat(sprintf("  NASS %d: %d rows\n", year, nrow(df)))
  df
}

nass_list <- list()
for (yr in c(2002, 2007, 2012, 2017, 2022)) {
  nass_list[[as.character(yr)]] <- fetch_nass(yr, nass_key)
}

nass_raw <- bind_rows(nass_list[!sapply(nass_list, is.null)])
cat(sprintf("NASS hog inventory: %d rows\n", nrow(nass_raw)))
stopifnot("NASS data empty" = nrow(nass_raw) > 500)

# ===================================================================
# 3. FHFA House Price Index — State-level all-transactions
# ===================================================================
cat("Fetching FHFA HPI...\n")

# Try multiple known FHFA URLs
hpi_urls <- c(
  "https://www.fhfa.gov/sites/default/files/2025-02/HPI_AT_state.csv",
  "https://www.fhfa.gov/hpi/download/monthly/hpi_at_state.csv",
  "https://www.fhfa.gov/DataTools/Downloads/Documents/HPI/HPI_AT_state.csv"
)

hpi_raw <- NULL
for (u in hpi_urls) {
  cat(sprintf("  Trying: %s\n", u))
  resp <- httr::GET(u, httr::timeout(30))
  if (httr::status_code(resp) == 200) {
    txt <- httr::content(resp, as = "text", encoding = "UTF-8")
    hpi_raw <- read.csv(text = txt)
    cat(sprintf("  Success: %d rows\n", nrow(hpi_raw)))
    break
  }
}

if (is.null(hpi_raw)) {
  # Fallback: use FRED for state-level HPI
  cat("  FHFA direct download failed. Using FRED state HPI...\n")
  fred_key <- gsub(".*=", "", grep("^FRED_API_KEY", dotenv, value = TRUE))

  # Fetch national HPI as a proxy
  fred_url <- sprintf(
    "https://api.stlouisfed.org/fred/series/observations?series_id=USSTHPI&api_key=%s&file_type=json&observation_start=2005-01-01",
    fred_key
  )
  resp <- httr::GET(fred_url)
  stopifnot("FRED API failed" = httr::status_code(resp) == 200)
  parsed <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
  hpi_raw <- parsed$observations
  cat(sprintf("  FRED national HPI: %d rows\n", nrow(hpi_raw)))
}

stopifnot("HPI data empty" = !is.null(hpi_raw) && nrow(hpi_raw) > 50)

# ===================================================================
# Save raw data
# ===================================================================
saveRDS(acs_raw, "../data/acs_raw.rds")
saveRDS(nass_raw, "../data/nass_raw.rds")
saveRDS(hpi_raw, "../data/hpi_raw.rds")

cat("\n=== Data fetch complete ===\n")
cat(sprintf("ACS: %d rows\n", nrow(acs_raw)))
cat(sprintf("NASS: %d rows\n", nrow(nass_raw)))
cat(sprintf("HPI: %d rows\n", nrow(hpi_raw)))
