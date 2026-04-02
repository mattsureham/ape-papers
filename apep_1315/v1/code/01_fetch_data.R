## 01_fetch_data.R — Fetch UCMR 5 and FHFA data
## apep_1315: The Forever Chemical Discount

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ---- 1. UCMR 5 Occurrence Data ----
cat("Fetching UCMR 5 occurrence data...\n")
ucmr5_url <- "https://www.epa.gov/system/files/other-files/2023-08/ucmr5-occurrence-data.zip"
ucmr5_zip <- file.path(data_dir, "ucmr5_occurrence.zip")

if (!file.exists(ucmr5_zip)) {
  download.file(ucmr5_url, ucmr5_zip, mode = "wb", quiet = FALSE)
}

ucmr5_dir <- file.path(data_dir, "ucmr5_raw")
dir.create(ucmr5_dir, showWarnings = FALSE)
unzip(ucmr5_zip, exdir = ucmr5_dir, overwrite = TRUE)

ucmr5_files <- list.files(ucmr5_dir, full.names = TRUE, recursive = TRUE)
cat("UCMR 5 extracted files:\n")
for (f in ucmr5_files) cat("  ", basename(f), " (", file.size(f), " bytes)\n")

# Read all txt files — the main results and the ZIP crosswalk
all_file <- ucmr5_files[grepl("(?i)all\\.txt$", ucmr5_files)]
zip_file_in_archive <- ucmr5_files[grepl("(?i)zip", ucmr5_files)]

cat("\nLooking for main analytical results file...\n")
if (length(all_file) > 0) {
  cat("Reading:", basename(all_file[1]), "\n")
  ucmr5 <- fread(all_file[1], showProgress = TRUE)
} else {
  # Fallback: read the largest txt file
  sizes <- file.size(ucmr5_files[grepl("\\.txt$", ucmr5_files)])
  biggest <- ucmr5_files[grepl("\\.txt$", ucmr5_files)][which.max(sizes)]
  cat("Reading largest file:", basename(biggest), "\n")
  ucmr5 <- fread(biggest, showProgress = TRUE)
}

cat("UCMR 5 rows:", nrow(ucmr5), "cols:", ncol(ucmr5), "\n")
cat("Column names:", paste(names(ucmr5), collapse = ", "), "\n")

saveRDS(ucmr5, file.path(data_dir, "ucmr5_results.rds"))

# Check for ZIP code file in the archive
if (length(zip_file_in_archive) > 0) {
  cat("\nFound ZIP code file in archive:", basename(zip_file_in_archive[1]), "\n")
  ucmr5_zips <- fread(zip_file_in_archive[1], showProgress = TRUE)
  cat("ZIP crosswalk rows:", nrow(ucmr5_zips), "\n")
  cat("Column names:", paste(names(ucmr5_zips), collapse = ", "), "\n")
  saveRDS(ucmr5_zips, file.path(data_dir, "ucmr5_zipcodes.rds"))
} else {
  cat("\nNo separate ZIP code file found. ZIP info may be in occurrence data.\n")
  # Check if occurrence data has ZIP codes embedded
  zip_cols <- grep("(?i)zip", names(ucmr5), value = TRUE)
  cat("ZIP-related columns in occurrence data:", paste(zip_cols, collapse = ", "), "\n")
}

## ---- 2. FHFA ZIP-Level House Price Index ----
cat("\nFetching FHFA ZIP-level HPI...\n")
fhfa_url <- "https://www.fhfa.gov/hpi/download/annual/hpi_at_zip5.xlsx"
fhfa_file <- file.path(data_dir, "fhfa_zip5_hpi.xlsx")

if (!file.exists(fhfa_file)) {
  download.file(fhfa_url, fhfa_file, mode = "wb", quiet = FALSE)
}

if (!requireNamespace("readxl", quietly = TRUE)) {
  install.packages("readxl", repos = "https://cloud.r-project.org")
}
library(readxl)

fhfa <- read_excel(fhfa_file)
cat("FHFA rows:", nrow(fhfa), "cols:", ncol(fhfa), "\n")
cat("Column names:", paste(names(fhfa), collapse = ", "), "\n")

# Identify year column
yr_col <- grep("(?i)year|yr", names(fhfa), value = TRUE)
if (length(yr_col) > 0) {
  cat("Year range:", paste(range(fhfa[[yr_col[1]]], na.rm = TRUE), collapse = " - "), "\n")
}

saveRDS(fhfa, file.path(data_dir, "fhfa_zip5_hpi.rds"))

## ---- 3. State PFAS MCL data (hand-coded) ----
cat("\nCreating state prior PFAS MCL lookup...\n")
# States with enforceable PFAS drinking water MCLs prior to federal rule (April 2024)
prior_mcl_states <- data.frame(
  state = c("NJ", "MA", "MI", "NH", "PA", "VT", "WI"),
  prior_mcl_year = c(2020, 2020, 2020, 2019, 2023, 2020, 2022),
  prior_mcl_pfoa_ppt = c(14, 20, 8, 12, 14, 20, 70),
  prior_mcl_pfos_ppt = c(13, 20, 16, 15, 18, 20, 70),
  stringsAsFactors = FALSE
)
saveRDS(prior_mcl_states, file.path(data_dir, "prior_mcl_states.rds"))
cat("Prior MCL states:", paste(prior_mcl_states$state, collapse = ", "), "\n")

## ---- 4. Verify data integrity ----
cat("\n=== DATA FETCH SUMMARY ===\n")
cat("UCMR 5 results:", nrow(ucmr5), "rows\n")
cat("FHFA ZIP5 HPI:", nrow(fhfa), "rows\n")

stopifnot("UCMR 5 data too small" = nrow(ucmr5) > 10000)
stopifnot("FHFA data too small" = nrow(fhfa) > 10000)

cat("All data fetched and validated successfully.\n")
