## 01_fetch_data.R — Fetch EPA ECHO inspection + emissions data
## APEP-1174: The Enforcement Lottery
##
## Data sources:
## 1. ICIS-AIR downloads — CAA inspections with agency type (state vs federal)
## 2. NPDES downloads — CWA inspections with agency type
## 3. ECHO Exporter — facility metadata (state, NAICS, TRI releases)
## 4. POLL_RPT_COMBINED_EMISSIONS — facility-year emissions

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

download_and_check <- function(url, dest, label) {
  if (file.exists(dest)) {
    cat(label, "already cached:", round(file.size(dest) / 1e6, 1), "MB\n")
    return(TRUE)
  }
  cat("Downloading", label, "...\n")
  resp <- GET(url, write_disk(dest, overwrite = TRUE), progress(), timeout(600))
  if (status_code(resp) != 200 || file.size(dest) < 1000) {
    cat("FAILED:", label, "HTTP", status_code(resp), "\n")
    file.remove(dest)
    return(FALSE)
  }
  cat("Downloaded", label, ":", round(file.size(dest) / 1e6, 1), "MB\n")
  return(TRUE)
}

## ============================================================
## 1. ICIS-AIR: Clean Air Act inspections with agency type
## ============================================================
cat("\n=== 1. ICIS-AIR (Clean Air Act compliance monitoring) ===\n")
icis_air_zip <- file.path(data_dir, "ICIS-AIR_downloads.zip")
ok <- download_and_check(
  "https://echo.epa.gov/files/echodownloads/ICIS-AIR_downloads.zip",
  icis_air_zip, "ICIS-AIR"
)
if (!ok) stop("FATAL: Could not download ICIS-AIR data")

icis_air_dir <- file.path(data_dir, "icis_air")
dir.create(icis_air_dir, showWarnings = FALSE)
unzip(icis_air_zip, exdir = icis_air_dir, overwrite = TRUE)

air_files <- list.files(icis_air_dir, pattern = "\\.csv$", full.names = TRUE, recursive = TRUE)
cat("ICIS-AIR CSV files:\n")
for (f in air_files) {
  cat("  ", basename(f), ":", round(file.size(f) / 1e6, 1), "MB\n")
}

## Read files to find the one with inspection/compliance monitoring data
for (f in air_files) {
  cols <- names(fread(f, nrows = 0))
  cat("\n", basename(f), "columns:", paste(head(cols, 10), collapse = ", "), "...\n")
}

## The FCES (Full Compliance Evaluations) file has inspection-level data
## Look for it among the files
fce_file <- air_files[grepl("FCE|FCES|COMPLIANCE.*EVAL|STACK", air_files, ignore.case = TRUE)]
if (length(fce_file) == 0) {
  # Read all files and look for agency/evaluation columns
  for (f in air_files) {
    cols <- names(fread(f, nrows = 0))
    if (any(grepl("AGENCY|STATE_EPA|LEAD_AGENCY|COMP.*TYPE", cols, ignore.case = TRUE))) {
      fce_file <- f
      cat("Found inspection data with agency type in:", basename(f), "\n")
      break
    }
  }
}

if (length(fce_file) > 0) {
  cat("\nReading CAA inspection data from:", basename(fce_file[1]), "\n")
  air_inspections <- fread(fce_file[1], fill = TRUE, showProgress = TRUE)
  cat("CAA inspections loaded:", nrow(air_inspections), "rows\n")
  cat("Columns:", paste(names(air_inspections), collapse = ", "), "\n")

  # Check for agency columns
  agency_cols <- names(air_inspections)[grepl("AGENCY|STATE_EPA|LEAD|MONITOR",
                                              names(air_inspections), ignore.case = TRUE)]
  cat("Agency columns:", paste(agency_cols, collapse = ", "), "\n")
  for (col in agency_cols) {
    cat("\nDistribution of", col, ":\n")
    print(head(sort(table(air_inspections[[col]], useNA = "ifany"), decreasing = TRUE), 10))
  }
} else {
  cat("Reading all ICIS-AIR files to find inspection data...\n")
  for (f in air_files) {
    dt <- fread(f, nrows = 5, fill = TRUE)
    cat("\n", basename(f), "sample:\n")
    print(dt)
  }
}

## ============================================================
## 2. NPDES: Clean Water Act inspections with agency type
## ============================================================
cat("\n=== 2. NPDES downloads (Clean Water Act compliance) ===\n")
npdes_zip <- file.path(data_dir, "npdes_downloads.zip")
ok <- download_and_check(
  "https://echo.epa.gov/files/echodownloads/npdes_downloads.zip",
  npdes_zip, "NPDES"
)

if (ok) {
  npdes_dir <- file.path(data_dir, "npdes")
  dir.create(npdes_dir, showWarnings = FALSE)
  unzip(npdes_zip, exdir = npdes_dir, overwrite = TRUE)

  npdes_files <- list.files(npdes_dir, pattern = "\\.csv$", full.names = TRUE, recursive = TRUE)
  cat("NPDES CSV files:\n")
  for (f in npdes_files) {
    cat("  ", basename(f), ":", round(file.size(f) / 1e6, 1), "MB\n")
  }

  ## Find inspection/compliance monitoring file
  for (f in npdes_files) {
    cols <- names(fread(f, nrows = 0))
    if (any(grepl("AGENCY|INSPECT|COMP_MON", cols, ignore.case = TRUE))) {
      cat("\nFound CWA inspection data in:", basename(f), "\n")
      npdes_insp <- fread(f, fill = TRUE, showProgress = TRUE)
      cat("CWA inspections loaded:", nrow(npdes_insp), "rows\n")

      agency_cols <- names(npdes_insp)[grepl("AGENCY|STATE_EPA|LEAD",
                                              names(npdes_insp), ignore.case = TRUE)]
      for (col in agency_cols) {
        cat("\nDistribution of", col, ":\n")
        print(head(sort(table(npdes_insp[[col]], useNA = "ifany"), decreasing = TRUE), 10))
      }
      break
    }
  }
}

## ============================================================
## 3. Case downloads (enforcement actions with agency info)
## ============================================================
cat("\n=== 3. Case downloads (enforcement actions) ===\n")
case_zip <- file.path(data_dir, "case_downloads.zip")
ok <- download_and_check(
  "https://echo.epa.gov/files/echodownloads/case_downloads.zip",
  case_zip, "Case downloads"
)

if (ok) {
  case_dir <- file.path(data_dir, "cases")
  dir.create(case_dir, showWarnings = FALSE)
  unzip(case_zip, exdir = case_dir, overwrite = TRUE)

  case_files <- list.files(case_dir, pattern = "\\.csv$", full.names = TRUE, recursive = TRUE)
  cat("Case CSV files:\n")
  for (f in case_files) {
    cat("  ", basename(f), ":", round(file.size(f) / 1e6, 1), "MB\n")
  }

  ## Read enforcement actions file
  for (f in case_files) {
    cols <- names(fread(f, nrows = 0))
    if (any(grepl("PENALTY|ENFORCEMENT|CASE_NUMBER", cols, ignore.case = TRUE))) {
      cat("\nFound enforcement data in:", basename(f), "\n")
      cases <- fread(f, fill = TRUE, showProgress = TRUE)
      cat("Enforcement cases loaded:", nrow(cases), "rows\n")
      cat("Columns:", paste(head(names(cases), 15), collapse = ", "), "\n")
      break
    }
  }
}

## ============================================================
## 4. ECHO Exporter — facility metadata
## ============================================================
cat("\n=== 4. ECHO Exporter (facility metadata + TRI) ===\n")
echo_zip <- file.path(data_dir, "echo_exporter.zip")
ok <- download_and_check(
  "https://echo.epa.gov/files/echodownloads/echo_exporter.zip",
  echo_zip, "ECHO Exporter"
)

if (ok) {
  echo_dir <- file.path(data_dir, "echo_exporter")
  dir.create(echo_dir, showWarnings = FALSE)
  unzip(echo_zip, exdir = echo_dir, overwrite = TRUE)

  echo_files <- list.files(echo_dir, pattern = "\\.csv$", full.names = TRUE, recursive = TRUE)
  cat("ECHO Exporter CSV files:\n")
  for (f in echo_files) {
    sz <- file.size(f) / 1e6
    cat("  ", basename(f), ":", round(sz, 1), "MB\n")
  }

  ## Read the main exporter file (it should have facility-level TRI and compliance data)
  main_echo <- echo_files[which.max(file.size(echo_files))]
  cat("\nReading main ECHO file:", basename(main_echo), "\n")

  ## Read just the header to see columns
  echo_cols <- names(fread(main_echo, nrows = 0))
  cat("Total columns:", length(echo_cols), "\n")

  ## Select key columns for our analysis
  want_cols <- c(
    "REGISTRY_ID", "FAC_NAME", "FAC_STATE", "FAC_COUNTY", "FAC_FIPS_CODE",
    "FAC_NAICS_CODES", "FAC_SIC_CODES", "FAC_LAT", "FAC_LONG",
    "FAC_QTRS_WITH_NC", "FAC_COMPLIANCE_STATUS",
    "FAC_INSPECTION_COUNT", "FAC_FORMAL_ACTION_COUNT",
    "FAC_PENALTY_COUNT", "FAC_TOTAL_PENALTIES",
    "TRI_IDS", "TRI_RELEASES_TRANSFERS",
    "FAC_INDIAN_CNTRY_FLG", "FAC_FEDERAL_FLG",
    "FAC_EPA_REGION",
    "AIR_FLAG", "NPDES_FLAG", "RCRA_FLAG", "TRI_FLAG",
    "CAA_EVALUATION_COUNT", "CAA_INSPECTION_COUNT",
    "CWA_INSPECTION_COUNT", "RCRA_EVALUATION_COUNT"
  )

  avail_cols <- intersect(want_cols, echo_cols)
  cat("Available wanted columns:", length(avail_cols), "/", length(want_cols), "\n")

  echo <- fread(main_echo, select = avail_cols, fill = TRUE, showProgress = TRUE)
  cat("ECHO Exporter loaded:", nrow(echo), "facilities\n")

  ## Show TRI coverage
  cat("Facilities with TRI flag:", sum(echo$TRI_FLAG == "Y", na.rm = TRUE), "\n")
  cat("Facilities with AIR flag:", sum(echo$AIR_FLAG == "Y", na.rm = TRUE), "\n")
}

## ============================================================
## 5. Combined Emissions (facility-year)
## ============================================================
cat("\n=== 5. Combined Emissions ===\n")
emissions_zip <- file.path(data_dir, "combined_emissions.zip")
ok <- download_and_check(
  "https://echo.epa.gov/files/echodownloads/POLL_RPT_COMBINED_EMISSIONS.zip",
  emissions_zip, "Combined Emissions"
)

if (ok) {
  emissions_dir <- file.path(data_dir, "emissions")
  dir.create(emissions_dir, showWarnings = FALSE)
  unzip(emissions_zip, exdir = emissions_dir, overwrite = TRUE)

  emissions_files <- list.files(emissions_dir, pattern = "\\.csv$", full.names = TRUE)
  cat("Emissions files:\n")
  for (f in emissions_files) {
    cat("  ", basename(f), ":", round(file.size(f) / 1e6, 1), "MB\n")
  }

  if (length(emissions_files) > 0) {
    em_cols <- names(fread(emissions_files[1], nrows = 0))
    cat("Emissions columns:", paste(head(em_cols, 20), collapse = ", "), "\n")

    emissions <- fread(emissions_files[1], fill = TRUE, showProgress = TRUE)
    cat("Emissions loaded:", nrow(emissions), "rows\n")
  }
}

## ============================================================
## 6. Save everything
## ============================================================
cat("\n=== Saving processed data ===\n")

if (exists("echo")) saveRDS(echo, file.path(data_dir, "echo_facilities.rds"))
if (exists("air_inspections")) saveRDS(air_inspections, file.path(data_dir, "air_inspections.rds"))
if (exists("npdes_insp")) saveRDS(npdes_insp, file.path(data_dir, "npdes_inspections.rds"))
if (exists("cases")) saveRDS(cases, file.path(data_dir, "enforcement_cases.rds"))
if (exists("emissions")) saveRDS(emissions, file.path(data_dir, "emissions.rds"))

cat("\n=== Data fetch complete ===\n")
if (exists("echo")) cat("ECHO facilities:", nrow(echo), "\n")
if (exists("air_inspections")) cat("CAA inspections:", nrow(air_inspections), "\n")
if (exists("npdes_insp")) cat("CWA inspections:", nrow(npdes_insp), "\n")
if (exists("cases")) cat("Enforcement cases:", nrow(cases), "\n")
if (exists("emissions")) cat("Emissions records:", nrow(emissions), "\n")
