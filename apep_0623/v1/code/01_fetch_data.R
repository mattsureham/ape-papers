## 01_fetch_data.R — Download all data sources
## APEP apep_0623: The Symmetric Tax Shock

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ============================================================
## 1. Zillow ZHVI — Zip-code monthly home values
## ============================================================
cat("=== Downloading Zillow ZHVI (zip-code, monthly, all homes) ===\n")
zhvi_url <- "https://files.zillowstatic.com/research/public_csvs/zhvi/Zip_zhvi_uc_sfrcondo_tier_0.33_0.67_sm_sa_month.csv"
zhvi_file <- file.path(data_dir, "zillow_zhvi_zip.csv")

if (!file.exists(zhvi_file)) {
  tryCatch({
    download.file(zhvi_url, zhvi_file, mode = "wb", quiet = FALSE)
    cat("ZHVI downloaded:", file.info(zhvi_file)$size / 1e6, "MB\n")
  }, error = function(e) {
    stop("FATAL: Zillow ZHVI download failed: ", e$message,
         "\nCannot proceed without primary outcome data.")
  })
} else {
  cat("ZHVI already exists:", file.info(zhvi_file)$size / 1e6, "MB\n")
}

# Validate
zhvi_check <- fread(zhvi_file, nrows = 5)
stopifnot("RegionName" %in% names(zhvi_check))
cat("ZHVI columns:", ncol(zhvi_check), "\n")
cat("Sample zip codes:", paste(zhvi_check$RegionName[1:3], collapse = ", "), "\n")

## ============================================================
## 2. IRS SOI — Zip-code income data (2017) for SALT exposure
## ============================================================
cat("\n=== Downloading IRS SOI zip-code income data (2017) ===\n")
# IRS SOI individual income tax statistics by zip code
soi_url <- "https://www.irs.gov/pub/irs-soi/17zpallagi.csv"
soi_file <- file.path(data_dir, "irs_soi_2017_zip.csv")

if (!file.exists(soi_file)) {
  tryCatch({
    download.file(soi_url, soi_file, mode = "wb", quiet = FALSE)
    cat("IRS SOI downloaded:", file.info(soi_file)$size / 1e6, "MB\n")
  }, error = function(e) {
    # Try alternative URL format
    soi_url2 <- "https://www.irs.gov/pub/irs-soi/17zpallagi.csv"
    tryCatch({
      download.file(soi_url2, soi_file, mode = "wb", quiet = FALSE)
    }, error = function(e2) {
      stop("FATAL: IRS SOI download failed: ", e2$message,
           "\nCannot proceed without SALT exposure data.")
    })
  })
} else {
  cat("IRS SOI already exists:", file.info(soi_file)$size / 1e6, "MB\n")
}

# Validate — check for SALT-related fields
soi_check <- fread(soi_file, nrows = 5)
cat("SOI columns:", ncol(soi_check), "\n")
cat("SOI column names (first 20):", paste(names(soi_check)[1:min(20, ncol(soi_check))], collapse = ", "), "\n")

# Check for SALT deduction fields (A18300 = total taxes paid deduction in newer files)
salt_cols <- grep("A18|N18|a18|n18", names(soi_check), value = TRUE)
cat("SALT-related columns found:", paste(salt_cols, collapse = ", "), "\n")
if (length(salt_cols) == 0) {
  cat("WARNING: No SALT columns found. Will check alternative column naming.\n")
  # Print all columns for debugging
  cat("All columns:\n")
  print(names(soi_check))
}

## ============================================================
## 3. FHFA HPI — Zip-code annual repeat-sales index (robustness)
## ============================================================
cat("\n=== Downloading FHFA HPI (zip-code annual) ===\n")
fhfa_url <- "https://www.fhfa.gov/sites/default/files/2025-01/HPI_AT_BDL_ZIP5.xlsx"
fhfa_file <- file.path(data_dir, "fhfa_hpi_zip.xlsx")

if (!file.exists(fhfa_file)) {
  tryCatch({
    download.file(fhfa_url, fhfa_file, mode = "wb", quiet = FALSE)
    cat("FHFA downloaded:", file.info(fhfa_file)$size / 1e6, "MB\n")
  }, error = function(e) {
    cat("WARNING: FHFA download failed (non-fatal, used for robustness only):", e$message, "\n")
  })
} else {
  cat("FHFA already exists:", file.info(fhfa_file)$size / 1e6, "MB\n")
}

## ============================================================
## 4. Zip-to-CBSA crosswalk (for within-metro FE)
## ============================================================
cat("\n=== Downloading HUD ZIP-CBSA crosswalk ===\n")
# Use Census delineation file for zip-to-CBSA mapping
crosswalk_url <- "https://www2.census.gov/programs-surveys/metro-micro/geographies/reference-files/2023/delineation-files/list2_2023.xls"
crosswalk_file <- file.path(data_dir, "cbsa_delineation.xls")

if (!file.exists(crosswalk_file)) {
  tryCatch({
    download.file(crosswalk_url, crosswalk_file, mode = "wb", quiet = FALSE)
    cat("CBSA crosswalk downloaded\n")
  }, error = function(e) {
    cat("WARNING: CBSA crosswalk download failed:", e$message, "\n")
    cat("Will use state FIPS as alternative geographic control.\n")
  })
} else {
  cat("CBSA crosswalk already exists\n")
}

## ============================================================
## 5. IRS SOI Migration data (mechanism test)
## ============================================================
cat("\n=== Downloading IRS SOI Migration data ===\n")
# State-to-state outflows for 2017-2018 (around TCJA) and 2019-2020
migration_urls <- c(
  "https://www.irs.gov/pub/irs-soi/stateoutflow1718.csv",
  "https://www.irs.gov/pub/irs-soi/stateoutflow1819.csv",
  "https://www.irs.gov/pub/irs-soi/stateoutflow1920.csv",
  "https://www.irs.gov/pub/irs-soi/stateoutflow2021.csv",
  "https://www.irs.gov/pub/irs-soi/stateoutflow2122.csv"
)

for (url in migration_urls) {
  fname <- basename(url)
  fpath <- file.path(data_dir, fname)
  if (!file.exists(fpath)) {
    tryCatch({
      download.file(url, fpath, mode = "wb", quiet = TRUE)
      cat("  Downloaded:", fname, "\n")
    }, error = function(e) {
      cat("  WARNING: Failed to download", fname, ":", e$message, "\n")
    })
  }
}

cat("\n=== All downloads complete ===\n")
cat("Files in data directory:\n")
print(list.files(data_dir, full.names = FALSE))
