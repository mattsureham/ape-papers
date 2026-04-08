## 01_fetch_data.R — Download and process DVSA MOT test data
## apep_1414: UK MOT First-Inspection RDD
##
## Strategy: Download 2021, 2022, 2023 DVSA test result ZIPs (1.19GB each compressed).
## Use DuckDB for out-of-core processing (8GB RAM constraint).
## Extract bandwidth cohort: vehicles with first test at age 30-45 months in 2022.
## Link to second test outcomes in 2023.

source("code/00_packages.R")

setwd(here::here("output", "apep_1414", "v1"))

## ──────────────────────────────────────────────────────────────
## 1. Setup
## ──────────────────────────────────────────────────────────────

dir.create("data", showWarnings = FALSE)

# DVSA S3 base URLs confirmed via smoke tests in idea_2452
base_url <- "https://edh-dvsa-data-gov-uk-files-prod.s3.eu-west-1.amazonaws.com"

years_to_download <- c(2022, 2023)  # 2021 returns 403; only 2022 and 2023 available

## ──────────────────────────────────────────────────────────────
## 2. Download DVSA test result ZIPs
## ──────────────────────────────────────────────────────────────

for (yr in years_to_download) {
  zip_path <- sprintf("data/dft_test_result_%d.zip", yr)
  if (!file.exists(zip_path)) {
    url <- sprintf("%s/dft_test_result_%d.zip", base_url, yr)
    cat(sprintf("Downloading %d data from %s...\n", yr, url))
    result <- tryCatch({
      # Use system curl for reliability with large S3 files
      exit_code <- system(sprintf('curl -L --retry 3 --retry-delay 5 -o "%s" "%s"', zip_path, url))
      if (exit_code != 0) stop(sprintf("curl exited with code %d", exit_code))
      TRUE
    }, error = function(e) {
      cat(sprintf("ERROR: Failed to download %d data: %s\n", yr, e$message))
      stop(sprintf("Data download failed for year %d. Cannot proceed without real data.", yr))
    })
    if (!file.exists(zip_path) || file.size(zip_path) < 1e6) {
      stop(sprintf("Download incomplete for year %d. File size too small.", yr))
    }
    cat(sprintf("Downloaded %d: %.1f MB\n", yr, file.size(zip_path) / 1e6))
  } else {
    cat(sprintf("Year %d already downloaded: %.1f MB\n", yr, file.size(zip_path) / 1e6))
  }
}

## ──────────────────────────────────────────────────────────────
## 3. Extract ZIP files (DuckDB can read CSVs, not ZIPs directly)
## ──────────────────────────────────────────────────────────────

for (yr in years_to_download) {
  zip_path <- sprintf("data/dft_test_result_%d.zip", yr)
  csv_path <- sprintf("data/dft_test_result_%d.csv", yr)

  if (!file.exists(csv_path)) {
    cat(sprintf("Extracting year %d...\n", yr))
    # Extract to data/ directory
    result <- system(sprintf('unzip -o "%s" -d data/', zip_path), intern = TRUE)
    # The extracted file may be named differently — find it
    extracted_files <- list.files("data", pattern = sprintf(".*%d.*\\.csv$", yr), full.names = TRUE)
    if (length(extracted_files) == 0) {
      # Try looking for any new CSV
      extracted_files <- list.files("data", pattern = "\\.csv$", full.names = TRUE)
      extracted_files <- extracted_files[!grepl("bandwidth|cohort|clean", extracted_files)]
    }
    if (length(extracted_files) == 0) {
      stop(sprintf("No CSV extracted from year %d ZIP. Cannot proceed.", yr))
    }
    # Rename to standard name if needed
    main_csv <- extracted_files[which.max(file.size(extracted_files))]
    if (main_csv != csv_path) {
      file.rename(main_csv, csv_path)
    }
    cat(sprintf("Extracted year %d: %.1f GB\n", yr, file.size(csv_path) / 1e9))
  } else {
    cat(sprintf("Year %d already extracted: %.1f GB\n", yr, file.size(csv_path) / 1e9))
  }
}

## ──────────────────────────────────────────────────────────────
## 4. Inspect column names from a sample
## ──────────────────────────────────────────────────────────────

cat("\nInspecting CSV structure via DuckDB...\n")
con <- dbConnect(duckdb())

# Detect actual column names
sample_query <- "SELECT * FROM read_csv_auto('data/dft_test_result_2022.csv', sample_size=1000) LIMIT 5"
sample_df <- tryCatch(
  dbGetQuery(con, sample_query),
  error = function(e) {
    # Try with header=true if auto-detect fails
    sample_query2 <- "SELECT * FROM read_csv('data/dft_test_result_2022.csv', header=true) LIMIT 5"
    dbGetQuery(con, sample_query2)
  }
)
cat("Column names:\n")
print(names(sample_df))
cat("\nSample rows:\n")
print(head(sample_df, 3))

# Save column names for reference
writeLines(names(sample_df), "data/column_names.txt")

dbDisconnect(con)

## ──────────────────────────────────────────────────────────────
## 5. Extract bandwidth cohort using DuckDB
## ──────────────────────────────────────────────────────────────

# Re-detect column names to map to expected fields
col_names <- readLines("data/column_names.txt")
cat("\nDetected columns:", paste(col_names, collapse = ", "), "\n")

# Map column names (DVSA uses specific field names)
# Expected: vehicle_id, test_date, first_use_date, test_result, make, model, fuel_type, test_mileage
# Find the actual names (may be lowercase/uppercase variations)

find_col <- function(cols, patterns) {
  for (pat in patterns) {
    match <- grep(pat, cols, ignore.case = TRUE, value = TRUE)
    if (length(match) > 0) return(match[1])
  }
  return(NULL)
}

col_vehicle_id <- find_col(col_names, c("vehicle_id", "vehicleid", "vin"))
col_test_date  <- find_col(col_names, c("test_date", "testdate", "date_of_test"))
col_first_use  <- find_col(col_names, c("first_use_date", "firstusedate", "first_registration", "registration_date"))
col_result     <- find_col(col_names, c("test_result", "testresult", "result"))
col_make       <- find_col(col_names, c("^make$", "vehicle_make", "make"))
col_model      <- find_col(col_names, c("^model$", "vehicle_model", "model"))
col_fuel       <- find_col(col_names, c("fuel_type", "fueltype", "fuel"))
col_mileage    <- find_col(col_names, c("test_mileage", "mileage", "odometer"))
col_postcode   <- find_col(col_names, c("postcode_area", "postcode_region", "postcode", "region"))

cat(sprintf("\nColumn mapping:\n  vehicle_id -> %s\n  test_date -> %s\n  first_use_date -> %s\n  test_result -> %s\n",
            col_vehicle_id, col_test_date, col_first_use, col_result))

if (is.null(col_vehicle_id) || is.null(col_test_date) || is.null(col_first_use) || is.null(col_result)) {
  cat("Available columns:\n")
  print(col_names)
  stop("Could not identify required columns. Cannot proceed without proper column mapping.")
}

## ──────────────────────────────────────────────────────────────
## 6. Build first-test cohort from 2022 data
## ──────────────────────────────────────────────────────────────

cat("\nBuilding first-test cohort from 2022 data...\n")
con <- dbConnect(duckdb())

# First: Build 2022 file with age computation, filter to bandwidth
# Age at test = (test_date - first_use_date) in months
# Bandwidth: age 28 to 46 months (±8 months around cutoff)
# Also filter to 10% random sample for memory efficiency

cohort_2022_query <- sprintf("
  CREATE OR REPLACE VIEW tests_2022 AS
  SELECT
    \"%s\" AS vehicle_id,
    CAST(\"%s\" AS DATE) AS test_date,
    CAST(\"%s\" AS DATE) AS first_use_date,
    \"%s\" AS test_result,
    %s,
    %s,
    %s,
    %s,
    %s
  FROM read_csv_auto('data/dft_test_result_2022.csv', header=true)
  WHERE
    \"%s\" IS NOT NULL
    AND \"%s\" IS NOT NULL
    AND \"%s\" IS NOT NULL
    AND YEAR(CAST(\"%s\" AS DATE)) = 2022;
",
  col_vehicle_id, col_test_date, col_first_use, col_result,
  if (!is.null(col_make)) sprintf('"%s" AS make', col_make) else "'unknown' AS make",
  if (!is.null(col_model)) sprintf('"%s" AS model', col_model) else "'unknown' AS model",
  if (!is.null(col_fuel)) sprintf('"%s" AS fuel_type', col_fuel) else "'unknown' AS fuel_type",
  if (!is.null(col_mileage)) sprintf('"%s" AS test_mileage', col_mileage) else "NULL AS test_mileage",
  if (!is.null(col_postcode)) sprintf('"%s" AS postcode_region', col_postcode) else "'unknown' AS postcode_region",
  col_vehicle_id, col_test_date, col_first_use,
  col_test_date
)

dbExecute(con, cohort_2022_query)

# Compute age at test and filter to bandwidth
bandwidth_query <- "
  SELECT
    vehicle_id,
    test_date,
    first_use_date,
    test_result,
    make,
    model,
    fuel_type,
    test_mileage,
    postcode_region,
    DATEDIFF('month', first_use_date, test_date) AS age_months_at_test,
    CASE WHEN test_result IN ('P', 'PASS', 'pass', 'Pass') THEN 0
         WHEN test_result IN ('F', 'FAIL', 'fail', 'Fail') THEN 1
         ELSE NULL END AS failed_first_test,
    random() AS rand_sample
  FROM tests_2022
  WHERE
    DATEDIFF('month', first_use_date, test_date) BETWEEN 28 AND 46
    AND test_result IS NOT NULL
"

cat("Extracting bandwidth cohort (10% sample)...\n")
cohort_2022 <- dbGetQuery(con, paste(bandwidth_query, "AND random() < 0.10"))

cat(sprintf("Cohort 2022: %d vehicle-tests in bandwidth\n", nrow(cohort_2022)))
cat("Age distribution:\n")
print(table(cohort_2022$age_months_at_test))
cat("Test result distribution:\n")
print(table(cohort_2022$test_result))

## ──────────────────────────────────────────────────────────────
## 7. Identify likely first-test vehicles (2021 data not available - 403)
## ──────────────────────────────────────────────────────────────

cat("\nIdentifying first-test vehicles from age at test...\n")

# Since 2021 data is not available, use age at test as proxy:
# Vehicles tested at age 28-46 months in 2022 were registered in 2019-2020.
# For vehicles tested at ~36 months (registration ~2019), this is very likely their first MOT.
# We cannot verify from 2021 data, so we note this as a limitation.

vehicle_ids_2022 <- unique(cohort_2022$vehicle_id)
cat(sprintf("Cohort vehicle IDs: %d\n", length(vehicle_ids_2022)))

# Write vehicle_ids to a CSV file for DuckDB to read
write.csv(data.frame(vehicle_id = vehicle_ids_2022), "data/cohort_vids.csv", row.names = FALSE)

# Build temp table from CSV (more reliable than UNNEST parameter binding)
dbExecute(con, "CREATE OR REPLACE TABLE cohort_vids AS SELECT CAST(vehicle_id AS BIGINT) AS vehicle_id FROM read_csv_auto('data/cohort_vids.csv', header=true)")

# Flag: vehicles at age 28-46 months in 2022
# Registered ~early 2019 = age ~36 months in early 2022 (mandatory first test)
# Registered ~mid 2019  = age ~36 months in mid 2022
# All consistent with mandatory first MOT window
cohort_2022$is_likely_first_test <- TRUE  # All in bandwidth are first-test cohort by construction
cat("All bandwidth vehicles treated as first-test cohort (age 28-46 months at first 2022 test).\n")

## ──────────────────────────────────────────────────────────────
## 8. Get 2023 test outcomes for the same vehicles
## ──────────────────────────────────────────────────────────────

cat("\nFetching 2023 test outcomes for cohort vehicles...\n")

# Build view for 2023 data
outcome_query <- sprintf("
  SELECT
    \"%s\" AS vehicle_id,
    CAST(\"%s\" AS DATE) AS test_date_2,
    \"%s\" AS test_result_2,
    CASE WHEN \"%s\" IN ('F', 'FAIL', 'fail', 'Fail') THEN 1
         WHEN \"%s\" IN ('P', 'PASS', 'pass', 'Pass') THEN 0
         ELSE NULL END AS failed_second_test,
    \"%s\" AS test_mileage_2
  FROM read_csv_auto('data/dft_test_result_2023.csv', header=true)
  WHERE
    \"%s\" IN (SELECT vehicle_id FROM cohort_vids)
    AND YEAR(CAST(\"%s\" AS DATE)) = 2023
", col_vehicle_id, col_test_date, col_result,
   col_result, col_result,
   if (!is.null(col_mileage)) col_mileage else "'NA'",
   col_vehicle_id, col_test_date)

outcomes_2023 <- tryCatch({
  dbGetQuery(con, outcome_query)
}, error = function(e) {
  cat("Warning: Error fetching 2023 outcomes:", e$message, "\n")
  cat("Will proceed with 2022-only analysis.\n")
  data.frame()
})

cat(sprintf("2023 outcomes found: %d records\n", nrow(outcomes_2023)))

dbDisconnect(con, shutdown = TRUE)

## ──────────────────────────────────────────────────────────────
## 9. Save intermediate datasets
## ──────────────────────────────────────────────────────────────

saveRDS(cohort_2022, "data/cohort_2022_bandwidth.rds")
if (nrow(outcomes_2023) > 0) {
  saveRDS(outcomes_2023, "data/outcomes_2023.rds")
}

cat("\n=== DATA FETCH COMPLETE ===\n")
cat(sprintf("Bandwidth cohort (2022): %d observations\n", nrow(cohort_2022)))
cat(sprintf("Second-test outcomes (2023): %d observations\n", nrow(outcomes_2023)))

# Validate: must have real data
if (nrow(cohort_2022) < 1000) {
  stop("Insufficient data in cohort. Something went wrong with data fetch or filtering.")
}
