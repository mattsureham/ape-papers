## 01_fetch_data.R — Download OSHA ITA Form 300A data (2016-2024)
## apep_1046: Cross-hazard injury substitution

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ITA 300A Summary Data download URLs (from osha.gov)
base_url <- "https://www.osha.gov/sites/default/files/"
ita_files <- list(
  "2016" = "ITA%20Data%20CY%202016.zip",
  "2017" = "ITA%20Data%20CY%202017.zip",
  "2018" = "ITA%20Data%20CY%202018.zip",
  "2019" = "ITA%20Data%20CY%202019.zip",
  "2020" = "ITA-Data-CY-2020.zip",
  "2021" = "ITA-data-cy2021.zip",
  "2022" = "ITA-data-cy2022.zip",
  "2023" = "ITA_300A_Summary_Data_2023_through_12-31-2024.zip",
  "2024" = "ITA_300A_Summary_Data_2024_through_08-31-2025.zip"
)

## Download each year
for (yr in names(ita_files)) {
  zip_path <- file.path(data_dir, paste0("ita_", yr, ".zip"))
  if (file.exists(zip_path)) {
    cat("Already have", yr, "\n")
    next
  }
  url <- paste0(base_url, ita_files[[yr]])
  cat("Downloading", yr, "from", url, "...\n")
  result <- tryCatch(
    curl::curl_download(url, zip_path, quiet = FALSE),
    error = function(e) {
      stop("FATAL: Failed to download ITA data for ", yr, ": ", e$message,
           "\nCannot proceed without real data.")
    }
  )
  cat("  Saved:", zip_path, "(", file.size(zip_path), "bytes)\n")
}

## Unzip and read each year
all_data <- list()

for (yr in names(ita_files)) {
  zip_path <- file.path(data_dir, paste0("ita_", yr, ".zip"))

  ## List files in zip
  zip_contents <- unzip(zip_path, list = TRUE)
  cat("\n", yr, "zip contents:\n")
  print(zip_contents$Name)

  ## Find CSV file(s)
  csv_files <- zip_contents$Name[grepl("\\.csv$", zip_contents$Name, ignore.case = TRUE)]
  if (length(csv_files) == 0) {
    stop("FATAL: No CSV found in ", yr, " zip file. Contents: ",
         paste(zip_contents$Name, collapse = ", "))
  }

  ## Extract to temp dir and read
  tmp_dir <- tempdir()
  unzip(zip_path, files = csv_files, exdir = tmp_dir)

  for (cf in csv_files) {
    csv_path <- file.path(tmp_dir, cf)
    cat("  Reading", cf, "...\n")
    dt <- fread(csv_path, fill = TRUE, showProgress = FALSE)
    dt[, source_year := as.integer(yr)]
    dt[, source_file := cf]
    all_data[[paste0(yr, "_", cf)]] <- dt
    cat("    Rows:", nrow(dt), " Cols:", ncol(dt), "\n")
  }
}

## Combine all years
cat("\nCombining all years...\n")

## Check column names across years
all_cols <- lapply(all_data, names)
common_cols_table <- table(unlist(all_cols))
cat("Column frequency across files:\n")
print(sort(common_cols_table, decreasing = TRUE))

## Save raw combined data
raw_combined <- rbindlist(all_data, fill = TRUE)
cat("\nTotal combined rows:", nrow(raw_combined), "\n")
cat("Total unique years:", uniqueN(raw_combined$source_year), "\n")

fwrite(raw_combined, file.path(data_dir, "ita_raw_combined.csv"))
cat("Saved: ita_raw_combined.csv\n")

## Validation: fail loudly if data is too small
stopifnot("Raw data has fewer than 100,000 rows — something is wrong" =
            nrow(raw_combined) >= 100000)

cat("\n=== Data fetch complete ===\n")
cat("Years:", paste(sort(unique(raw_combined$source_year)), collapse = ", "), "\n")
cat("Total rows:", nrow(raw_combined), "\n")
