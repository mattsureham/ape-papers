## ============================================================
## 01_fetch_data.R — Fetch police workforce and crime data
## apep_0531: PCSO Cuts and Crime in England
## ============================================================

source("00_packages.R")

## ---- 1. Home Office Police Workforce Data ---------------------
## ODS file with PCSO + officer FTE by force, 2007-2025

workforce_url <- "https://assets.publishing.service.gov.uk/media/697255b5a1311bdcfa0ed8f3/open-data-table-police-workforce-280126.ods"
workforce_file <- file.path(dat_dir, "police_workforce.ods")

if (!file.exists(workforce_file)) {
  cat("Downloading Home Office police workforce data...\n")
  tryCatch({
    download.file(workforce_url, workforce_file, mode = "wb", quiet = TRUE)
  }, error = function(e) stop("Workforce data unavailable: ", e$message,
                               "\nPivot research question or fix the source."))
}

# Read the Data sheet — readODS may garble headers, so read with col_names = FALSE
# and assign manually
workforce_raw <- tryCatch({
  read_ods(workforce_file, sheet = "Data", col_names = TRUE)
}, error = function(e) {
  cat("readODS failed on sheet 'Data', trying sheet 4...\n")
  read_ods(workforce_file, sheet = 4, col_names = TRUE)
})
workforce_raw <- as.data.table(workforce_raw)

# The ODS has known column names (from metadata):
# Year (As at 31 March), Geocode, Force name, Region, Sex, Rank, Worker type,
# Total (Headcount), Total (FTE)
expected_cols <- c("year", "geocode", "force_name", "region", "sex",
                   "rank", "worker_type", "headcount", "fte")
if (ncol(workforce_raw) == 9) {
  setnames(workforce_raw, expected_cols)
} else {
  # If different structure, inspect and adapt
  cat("WARNING: Unexpected columns:", ncol(workforce_raw), "\n")
  cat("Column names:", paste(names(workforce_raw), collapse = " | "), "\n")
  # Try to use whatever we got
  names(workforce_raw) <- tolower(gsub("[^a-z0-9]+", "_", names(workforce_raw)))
  names(workforce_raw) <- gsub("^_|_$", "", names(workforce_raw))
}

cat("Workforce data loaded:", nrow(workforce_raw), "rows\n")
cat("Years:", paste(sort(unique(workforce_raw$year)), collapse = ", "), "\n")
cat("Sample forces:", paste(head(unique(workforce_raw$force_name), 5), collapse = ", "), "\n")

fwrite(workforce_raw, file.path(dat_dir, "workforce_raw.csv"))


## ---- 2. Home Office Police Recorded Crime (PFA level) ---------
## Three historical files cover 2003-2024

crime_files <- list(
  early = list(
    url = "https://assets.publishing.service.gov.uk/media/5a74e87f40f0b65c0e84575a/prc-pfa-0203-to-0607-tabs.ods",
    file = "crime_pfa_0203_0607.ods",
    desc = "2002/03 to 2006/07"
  ),
  mid = list(
    url = "https://assets.publishing.service.gov.uk/media/5a80d98c40f0b62305b8d7ee/prc-pfa-mar2008-mar2012-tabs.ods",
    file = "crime_pfa_0708_1112.ods",
    desc = "2007/08 to 2011/12"
  ),
  recent = list(
    url = "https://assets.publishing.service.gov.uk/media/679a2aa1a39e422368d10e21/prc-pfa-mar2013-onwards-tables-300125.ods",
    file = "crime_pfa_1213_onwards.ods",
    desc = "2012/13 onwards"
  )
)

for (nm in names(crime_files)) {
  cf <- crime_files[[nm]]
  fpath <- file.path(dat_dir, cf$file)
  if (!file.exists(fpath)) {
    cat("Downloading crime data (", cf$desc, ")...\n")
    tryCatch({
      download.file(cf$url, fpath, mode = "wb", quiet = TRUE)
    }, error = function(e) stop("Crime data (", cf$desc, ") unavailable: ", e$message,
                                 "\nPivot research question or fix the source."))
    cat("  Downloaded:", round(file.size(fpath) / (1024 * 1024), 1), "MB\n")
  } else {
    cat("Crime data (", cf$desc, ") already cached:", round(file.size(fpath) / (1024 * 1024), 1), "MB\n")
  }
}


## ---- 3. ONS PFA Tables (latest — for supplementary data) ------

ons_pfa_url <- "https://www.ons.gov.uk/file?uri=/peoplepopulationandcommunity/crimeandjustice/datasets/policeforceareadatatables/yearendingseptember2025/policeforceareatablesyesep25.xlsx"
ons_file <- file.path(dat_dir, "ons_pfa_tables.xlsx")

if (!file.exists(ons_file)) {
  cat("Downloading ONS PFA crime tables (latest)...\n")
  tryCatch({
    download.file(ons_pfa_url, ons_file, mode = "wb", quiet = TRUE)
    cat("ONS PFA tables downloaded:", round(file.size(ons_file) / 1024), "KB\n")
  }, error = function(e) {
    cat("ONS PFA download failed:", e$message, "\n")
    cat("Non-fatal — we have Home Office data as primary source.\n")
  })
}

if (file.exists(ons_file)) {
  sheets <- readxl::excel_sheets(ons_file)
  cat("ONS sheets:", paste(sheets, collapse = ", "), "\n")
}


## ---- 4. Population Data from NOMIS ----------------------------
## Mid-year population estimates by Local Authority, then map to PFA

cat("\n--- Fetching NOMIS population data by LA ---\n")

nomis_base <- "https://www.nomisweb.co.uk/api/v01/"
nomis_key <- Sys.getenv("NOMIS_API_KEY")

years_str <- paste(2003:2023, collapse = ",")

pop_url <- paste0(nomis_base, "dataset/NM_2002_1.data.csv?",
                  "geography=TYPE464&",
                  "date=", years_str, "&",
                  "gender=0&",
                  "c_age=200&",
                  "measures=20100&",
                  "select=date_name,geography_name,geography_code,obs_value")
if (nchar(nomis_key) > 0) pop_url <- paste0(pop_url, "&uid=", nomis_key)

pop_data <- tryCatch({
  fread(pop_url, showProgress = FALSE)
}, error = function(e) {
  cat("NOMIS population download failed:", e$message, "\n")
  NULL
})

if (!is.null(pop_data) && nrow(pop_data) > 0) {
  cat("Population data:", nrow(pop_data), "LA-years\n")
  fwrite(pop_data, file.path(dat_dir, "population_la_raw.csv"))
} else {
  cat("NOMIS population query returned no data. Trying individual years...\n")
  # Try single year to test
  test_url <- paste0(nomis_base, "dataset/NM_2002_1.data.csv?",
                     "geography=TYPE464&",
                     "date=2020&",
                     "gender=0&",
                     "c_age=200&",
                     "measures=20100&",
                     "select=date_name,geography_name,geography_code,obs_value")
  if (nchar(nomis_key) > 0) test_url <- paste0(test_url, "&uid=", nomis_key)

  test_pop <- tryCatch(fread(test_url, showProgress = FALSE), error = function(e) NULL)
  if (!is.null(test_pop) && nrow(test_pop) > 0) {
    cat("Single year test successful:", nrow(test_pop), "rows\n")
    cat("Sample:", head(test_pop$GEOGRAPHY_NAME, 3), "\n")

    # Download year by year
    all_pop <- list()
    for (yr in 2003:2023) {
      yr_url <- paste0(nomis_base, "dataset/NM_2002_1.data.csv?",
                       "geography=TYPE464&",
                       "date=", yr, "&",
                       "gender=0&",
                       "c_age=200&",
                       "measures=20100&",
                       "select=date_name,geography_name,geography_code,obs_value")
      if (nchar(nomis_key) > 0) yr_url <- paste0(yr_url, "&uid=", nomis_key)
      yr_data <- tryCatch(fread(yr_url, showProgress = FALSE), error = function(e) NULL)
      if (!is.null(yr_data) && nrow(yr_data) > 0) {
        all_pop[[as.character(yr)]] <- yr_data
        cat("  ", yr, ":", nrow(yr_data), "rows\n")
      }
      Sys.sleep(0.5)
    }
    pop_data <- rbindlist(all_pop, fill = TRUE)
    cat("Total population data:", nrow(pop_data), "LA-years\n")
    fwrite(pop_data, file.path(dat_dir, "population_la_raw.csv"))
  } else {
    cat("NOMIS TYPE464 not available. Will extract population from ONS PFA tables.\n")
  }
}


## ---- 5. LA-to-PFA Mapping ------------------------------------
## Use ONS ArcGIS lookup for Community Safety Partnership → PFA

cat("\n--- Fetching LA-to-PFA lookup ---\n")

lookup_url <- "https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/CSPFA_APR_2024_LU_EN/FeatureServer/0/query?where=1%3D1&outFields=CSP24CD,CSP24NM,PFA24CD,PFA24NM&outSR=4326&f=json&resultRecordCount=500"

la_pfa_lookup <- tryCatch({
  resp <- request(lookup_url) |> req_perform()
  json <- resp_body_json(resp)
  features <- json$features
  dt <- rbindlist(lapply(features, function(f) as.data.table(f$attributes)))
  dt
}, error = function(e) {
  cat("ArcGIS lookup failed:", e$message, "\n")
  cat("Will create manual PFA mapping from workforce data.\n")
  NULL
})

if (!is.null(la_pfa_lookup) && nrow(la_pfa_lookup) > 0) {
  cat("LA-to-PFA lookup:", nrow(la_pfa_lookup), "rows\n")
  fwrite(la_pfa_lookup, file.path(dat_dir, "la_pfa_lookup.csv"))
} else {
  cat("Will construct PFA mapping in cleaning step.\n")
}


## ---- DATA VALIDATION =========================================

cat("\n=== DATA VALIDATION ===\n")

# Check workforce data
stopifnot("Workforce data must exist" = file.exists(file.path(dat_dir, "workforce_raw.csv")))
wf_check <- fread(file.path(dat_dir, "workforce_raw.csv"))
cat("Workforce:", nrow(wf_check), "rows,",
    length(unique(wf_check$force_name)), "forces,",
    length(unique(wf_check$year)), "years\n")

# Check crime data files exist
for (nm in names(crime_files)) {
  cf <- crime_files[[nm]]
  fpath <- file.path(dat_dir, cf$file)
  stopifnot(file.exists(fpath))
  cat("Crime data (", cf$desc, "):", round(file.size(fpath) / (1024 * 1024), 1), "MB\n")
}

cat("\n=== ALL DATA FETCHED SUCCESSFULLY ===\n")
