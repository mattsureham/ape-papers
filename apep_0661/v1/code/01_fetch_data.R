# 01_fetch_data.R — Fetch all data for apep_0661
# UK Asylum Dispersal and Local Crime
# Sources: Home Office, ONS Crime, NOMIS/Census 2011, ONS Population

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# =============================================================================
# 1. HOME OFFICE: Asylum support by local authority (Asy_D11)
# =============================================================================
cat("=== 1. Fetching Home Office asylum support data ===\n")

ho_url <- "https://assets.publishing.service.gov.uk/media/69959470047739fe61889d47/support-local-authority-datasets-dec-2025.xlsx"
ho_file <- file.path(data_dir, "asylum_support_la.xlsx")

if (!file.exists(ho_file)) {
  cat("Downloading Home Office asylum support data (1.23 MB)...\n")
  download.file(ho_url, ho_file, mode = "wb", quiet = FALSE)
}
stopifnot("Home Office asylum data download failed" = file.exists(ho_file) && file.size(ho_file) > 1000)

sheets <- readxl::excel_sheets(ho_file)
cat("Available sheets:", paste(sheets, collapse = " | "), "\n")

# Read Asy_D11 sheet (dispersal by LA)
asy_sheet <- grep("D11|dispersal|local.auth", sheets, value = TRUE, ignore.case = TRUE)
if (length(asy_sheet) == 0) {
  # Try each sheet to find the right one
  cat("Searching all sheets for LA-level dispersal data...\n")
  for (s in sheets) {
    tryCatch({
      tmp <- readxl::read_excel(ho_file, sheet = s, n_max = 10, .name_repair = "minimal")
      cols <- tolower(paste(names(tmp), collapse = " "))
      cat(sprintf("  Sheet '%s' (%d cols): %s\n", s, ncol(tmp),
                  paste(head(names(tmp), 6), collapse=", ")))
      if (grepl("local.auth|la_code|lad|region", cols)) {
        asy_sheet <- s
        cat("  >>> MATCH: contains LA identifiers\n")
        break
      }
    }, error = function(e) NULL)
  }
}

if (length(asy_sheet) == 0) {
  stop("FATAL: Cannot find LA-level asylum data sheet")
}

cat("Reading sheet:", asy_sheet[1], "\n")
asylum_raw <- as.data.table(readxl::read_excel(ho_file, sheet = asy_sheet[1],
                                                .name_repair = "minimal"))
cat("Asylum data:", nrow(asylum_raw), "rows x", ncol(asylum_raw), "cols\n")
cat("Columns:", paste(head(names(asylum_raw), 10), collapse = ", "), "\n")
cat("First rows:\n")
print(head(asylum_raw, 3))
fwrite(asylum_raw, file.path(data_dir, "asylum_raw.csv"))

# =============================================================================
# 2. ONS: Recorded crime by CSP (Community Safety Partnership = LA)
# =============================================================================
cat("\n=== 2. Fetching ONS recorded crime data ===\n")

crime_url <- "https://www.ons.gov.uk/file?uri=/peoplepopulationandcommunity/crimeandjustice/datasets/policeforceareadatatables/yearendingseptember2025/policeforceareatablesyesep25.xlsx"
crime_file <- file.path(data_dir, "ons_crime_pfa.xlsx")

if (!file.exists(crime_file)) {
  cat("Downloading ONS recorded crime data (643 KB)...\n")
  download.file(crime_url, crime_file, mode = "wb", quiet = FALSE)
}
stopifnot("ONS crime data download failed" = file.exists(crime_file) && file.size(crime_file) > 1000)

crime_sheets <- readxl::excel_sheets(crime_file)
cat("Crime data sheets:", paste(crime_sheets, collapse = " | "), "\n")

# Read all sheets to find CSP-level crime data
for (s in crime_sheets) {
  tryCatch({
    tmp <- readxl::read_excel(crime_file, sheet = s, n_max = 5, .name_repair = "minimal")
    cat(sprintf("  Sheet '%s' (%d cols): %s\n", s, ncol(tmp),
                paste(head(names(tmp), 6), collapse=", ")))
  }, error = function(e) NULL)
}

# =============================================================================
# 3. CENSUS 2011: Housing vacancy by LA (instrument share)
# =============================================================================
cat("\n=== 3. Fetching Census 2011 housing data (NOMIS) ===\n")

nomis_key <- Sys.getenv("NOMIS_API_KEY")
nomis_base <- "https://www.nomisweb.co.uk/api/v01"

# KS401EW: Dwellings, household spaces and accommodation type
# Cell 7 = "Household spaces with no usual residents"
# Geography TYPE464 = 2011 local authority districts (England & Wales)
nomis_url <- paste0(nomis_base, "/dataset/NM_618_1.data.csv?",
                    "geography=TYPE464&",
                    "rural_urban=0&",
                    "cell=0,7&",
                    "measures=20100&",
                    "select=GEOGRAPHY_CODE,GEOGRAPHY_NAME,CELL_NAME,OBS_VALUE")
if (nchar(nomis_key) > 0) {
  nomis_url <- paste0(nomis_url, "&uid=", nomis_key)
}

cat("Fetching NOMIS Census 2011 KS401EW...\n")
census_resp <- httr::GET(nomis_url)
cat("Response:", httr::status_code(census_resp), "\n")

if (httr::status_code(census_resp) == 200) {
  census_text <- httr::content(census_resp, "text", encoding = "UTF-8")
  census_housing <- fread(text = census_text)
  cat("Census housing data:", nrow(census_housing), "rows\n")
  print(head(census_housing))
  fwrite(census_housing, file.path(data_dir, "census_housing_raw.csv"))
} else {
  cat("NOMIS KS401EW failed. Trying alternative approach...\n")
  # Alternative: search for housing datasets
  search_url <- paste0(nomis_base, "/dataset/def.sdmx.json?search=dwelling*vacancy*2011")
  search_resp <- httr::GET(search_url)
  if (httr::status_code(search_resp) == 200) {
    search_data <- jsonlite::fromJSON(httr::content(search_resp, "text", encoding = "UTF-8"))
    cat("Available datasets with 'dwelling/vacancy/2011':\n")
    if (!is.null(search_data$structure$keyfamilies$keyfamily)) {
      kf <- search_data$structure$keyfamilies$keyfamily
      for (i in seq_len(min(nrow(kf), 10))) {
        cat(sprintf("  %s: %s\n", kf$id[i], kf$name$value[i]))
      }
    }
  }
}

# =============================================================================
# 4. ONS: Mid-year population estimates by LA (denominators)
# =============================================================================
cat("\n=== 4. Fetching ONS population estimates ===\n")

pop_url <- "https://www.ons.gov.uk/file?uri=/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/populationestimatesforukenglandandwalesscotlandandnorthernireland/mid2011tomid2024/myebtablesuk20112024.xlsx"
pop_file <- file.path(data_dir, "ons_population_ts.xlsx")

if (!file.exists(pop_file)) {
  cat("Downloading ONS population estimates (44.9 MB)...\n")
  download.file(pop_url, pop_file, mode = "wb", quiet = FALSE)
}
stopifnot("ONS population download failed" = file.exists(pop_file) && file.size(pop_file) > 1000)

pop_sheets <- readxl::excel_sheets(pop_file)
cat("Population data sheets:", paste(head(pop_sheets, 10), collapse = " | "), "\n")

# =============================================================================
# 5. NOMIS: LA-level unemployment (controls)
# =============================================================================
cat("\n=== 5. Fetching NOMIS labour market data ===\n")

# Model-based estimates of unemployment by LA
# NM_17_5: model-based estimates
unemp_url <- paste0(nomis_base, "/dataset/NM_17_5.data.csv?",
                    "geography=TYPE464&",
                    "variable=45&",
                    "measures=20599&",
                    "time=2014...2023&",
                    "select=GEOGRAPHY_CODE,GEOGRAPHY_NAME,DATE_NAME,OBS_VALUE")
if (nchar(nomis_key) > 0) {
  unemp_url <- paste0(unemp_url, "&uid=", nomis_key)
}

cat("Fetching NOMIS unemployment data...\n")
unemp_resp <- httr::GET(unemp_url)
cat("Response:", httr::status_code(unemp_resp), "\n")

if (httr::status_code(unemp_resp) == 200) {
  unemp_text <- httr::content(unemp_resp, "text", encoding = "UTF-8")
  unemp_data <- fread(text = unemp_text)
  cat("Unemployment data:", nrow(unemp_data), "rows\n")
  fwrite(unemp_data, file.path(data_dir, "unemp_raw.csv"))
} else {
  cat("Unemployment data fetch failed, will use alternatives\n")
}

# =============================================================================
# Summary
# =============================================================================
cat("\n=== Data fetching complete ===\n")
cat("Files in data directory:\n")
for (f in list.files(data_dir)) {
  sz <- file.size(file.path(data_dir, f))
  cat(sprintf("  %s (%.1f KB)\n", f, sz / 1024))
}
