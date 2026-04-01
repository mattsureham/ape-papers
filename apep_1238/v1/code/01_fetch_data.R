## 01_fetch_data.R — apep_1238
## Fetch CMS Medicare Geographic Variation data, hospital data, and controls

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ============================================================
## 1. CMS Geographic Variation PUF (County-level) — ALREADY DOWNLOADED
##    Medicare per-beneficiary spending by county, 2014-2023
## ============================================================
cat("=== Checking CMS Geographic Variation PUF ===\n")

gv_file <- file.path(data_dir, "cms_gv_county.csv")
if (!file.exists(gv_file)) {
  stop("FATAL: CMS Geographic Variation file not found. Must be downloaded first.")
}

gv_raw <- fread(gv_file)
cat("CMS GV data: ", nrow(gv_raw), " rows, ", ncol(gv_raw), " cols\n")
cat("Geographic levels: ", paste(unique(gv_raw$BENE_GEO_LVL), collapse = ", "), "\n")
cat("Years: ", paste(sort(unique(gv_raw$YEAR)), collapse = ", "), "\n")

## Filter to county level only
gv_county <- gv_raw[BENE_GEO_LVL == "County"]
cat("County-level rows: ", nrow(gv_county), "\n")
stopifnot("Must have county data" = nrow(gv_county) > 1000)

## ============================================================
## 2. CMS Hospital General Information — All hospitals via API
## ============================================================
cat("\n=== Fetching CMS Hospital General Information ===\n")

hosp_file <- file.path(data_dir, "cms_hospitals.csv")

## Paginate through all hospitals
base_url <- "https://data.cms.gov/provider-data/api/1/datastore/query/xubh-q36u/0"
all_hospitals <- list()
offset <- 0
page_size <- 1000

repeat {
  url <- paste0(base_url, "?limit=", page_size, "&offset=", offset)
  cat("  Fetching hospitals offset=", offset, "...\n")
  resp <- tryCatch(GET(url, timeout(120)), error = function(e) {
    stop("FATAL: Hospital API request failed: ", e$message)
  })
  if (status_code(resp) != 200) {
    stop("FATAL: Hospital API returned status ", status_code(resp))
  }
  json_text <- content(resp, as = "text", encoding = "UTF-8")
  parsed <- fromJSON(json_text)
  results <- parsed$results
  if (length(results) == 0 || nrow(results) == 0) break
  all_hospitals[[length(all_hospitals) + 1]] <- as.data.table(results)
  if (nrow(results) < page_size) break
  offset <- offset + page_size
}

hospitals <- rbindlist(all_hospitals, fill = TRUE)
cat("Total hospitals fetched: ", nrow(hospitals), "\n")
stopifnot("Must have hospitals" = nrow(hospitals) > 3000)

## Keep relevant columns
hosp_cols <- c("facility_id", "facility_name", "state", "countyparish",
               "zip_code", "hospital_type", "hospital_ownership",
               "emergency_services", "hospital_overall_rating")
hospitals <- hospitals[, .SD, .SDcols = intersect(hosp_cols, names(hospitals))]
fwrite(hospitals, hosp_file)
cat("Saved ", nrow(hospitals), " hospitals.\n")

## ============================================================
## 3. BEA State Per Capita Personal Income (Historical + Current)
##    For Hill-Burton instrument: 1950 state PCI
##    For controls: current state/county income
## ============================================================
cat("\n=== Fetching BEA State Income Data ===\n")

bea_key <- Sys.getenv("BEA_API_KEY")
if (nchar(bea_key) == 0) {
  stop("FATAL: BEA_API_KEY not set. Cannot fetch income data.")
}

## Historical state per capita income (SAINC1, Line 3 = Per capita personal income)
## Fetch 1950 and 1960 for instrument, plus recent years for controls
hist_years <- "1950,1960,1970,1980"
recent_years <- "2018,2019,2020,2021,2022"

fetch_bea <- function(years, geo = "STATE") {
  url <- paste0(
    "https://apps.bea.gov/api/data/?UserID=", bea_key,
    "&method=GetData&datasetname=Regional",
    "&TableName=SAINC1&LineCode=3&GeoFips=", geo,
    "&Year=", years, "&ResultFormat=JSON"
  )
  resp <- tryCatch(GET(url, timeout(120)), error = function(e) {
    stop("FATAL: BEA API failed: ", e$message)
  })
  if (status_code(resp) != 200) {
    stop("FATAL: BEA API returned status ", status_code(resp))
  }
  json_text <- content(resp, as = "text", encoding = "UTF-8")
  parsed <- fromJSON(json_text)
  if (!"Results" %in% names(parsed$BEAAPI)) {
    cat("WARNING: BEA returned no results for years: ", years, "\n")
    return(NULL)
  }
  as.data.table(parsed$BEAAPI$Results$Data)
}

cat("Fetching historical state income...\n")
bea_hist <- fetch_bea(hist_years)
if (!is.null(bea_hist)) {
  cat("Historical state income: ", nrow(bea_hist), " rows\n")
  fwrite(bea_hist, file.path(data_dir, "bea_state_income_hist.csv"))
}

cat("Fetching recent state income...\n")
bea_recent <- fetch_bea(recent_years)
if (!is.null(bea_recent)) {
  cat("Recent state income: ", nrow(bea_recent), " rows\n")
  fwrite(bea_recent, file.path(data_dir, "bea_state_income_recent.csv"))
}

## Also fetch county-level income for controls
cat("Fetching county-level income...\n")
bea_county <- fetch_bea("2019,2020,2021,2022", geo = "COUNTY")
if (!is.null(bea_county)) {
  cat("County income: ", nrow(bea_county), " rows\n")
  fwrite(bea_county, file.path(data_dir, "bea_county_income.csv"))
}

## ============================================================
## 4. Census County Demographics (ACS 5-year via API)
## ============================================================
cat("\n=== Fetching Census County Demographics ===\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) > 0) {
  ## ACS 5-year 2022: Population, age, poverty
  ## B01001_001: Total population
  ## B01002_001: Median age
  ## B17001_002: Below poverty level
  ## B01001_020 + higher age groups for 65+ population
  census_url <- paste0(
    "https://api.census.gov/data/2022/acs/acs5?get=B01001_001E,B01002_001E,B17001_002E,B17001_001E,B01001_020E,B01001_021E,B01001_022E,B01001_023E,B01001_024E,B01001_025E,B01001_044E,B01001_045E,B01001_046E,B01001_047E,B01001_048E,B01001_049E,NAME",
    "&for=county:*&key=", census_key
  )
  cat("Fetching ACS 2022 county data...\n")
  census_resp <- tryCatch(GET(census_url, timeout(120)), error = function(e) {
    cat("WARNING: Census API failed: ", e$message, "\n")
    NULL
  })

  if (!is.null(census_resp) && status_code(census_resp) == 200) {
    census_json <- content(census_resp, as = "text", encoding = "UTF-8")
    census_matrix <- fromJSON(census_json)
    census_dt <- as.data.table(census_matrix[-1, ])
    setnames(census_dt, census_matrix[1, ])
    fwrite(census_dt, file.path(data_dir, "census_county_demographics.csv"))
    cat("Census county demographics: ", nrow(census_dt), " rows\n")
  }
} else {
  cat("WARNING: No Census API key. Skipping demographic controls.\n")
}

## ============================================================
## 5. Summary
## ============================================================
cat("\n=== Data Fetch Summary ===\n")
files <- list.files(data_dir, pattern = "\\.(csv|xlsx)$")
for (f in files) {
  sz <- file.size(file.path(data_dir, f))
  cat(sprintf("  %s: %.1f MB\n", f, sz / (1024 * 1024)))
}
cat("Data fetch complete.\n")
