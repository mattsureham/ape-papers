## 01_fetch_data.R — Fetch EPA NEI Facility Summaries (HAP emissions)
## apep_0915: HAP Emission Bunching at CAA Thresholds
##
## Data source: EPA National Emissions Inventory (NEI) Facility Summaries
## URL: https://gaftp.epa.gov/air/nei/nei_facility_summaries/
## Years: 2012-2021 (10 annual files, ~25-31MB each as zip)

source("00_packages.R")

options(timeout = 600)

data_dir <- "../data"
raw_dir <- file.path(data_dir, "raw_nei")
dir.create(raw_dir, showWarnings = FALSE, recursive = TRUE)

## --- Check for existing zip files (may have been downloaded externally) ---
years <- 2012:2021
min_filesize <- 10e6  # 10MB minimum to consider complete

cat("=== Checking NEI Facility Summary files ===\n")
available_years <- c()

for (yr in years) {
  zipfile <- file.path(raw_dir, paste0(yr, "_NEI_Facility_summary.zip"))

  if (file.exists(zipfile) && file.size(zipfile) > min_filesize) {
    cat("  ", yr, ":", round(file.size(zipfile) / 1e6, 1), "MB [OK]\n")
    available_years <- c(available_years, yr)
  } else {
    # Try to download
    url <- paste0("https://gaftp.epa.gov/air/nei/nei_facility_summaries/",
                   yr, "_NEI_Facility_summary.zip")
    cat("  ", yr, ": downloading from EPA...\n")
    dl_ok <- tryCatch({
      download.file(url, zipfile, mode = "wb", quiet = TRUE, timeout = 600)
      file.size(zipfile) > min_filesize
    }, error = function(e) FALSE)

    if (dl_ok) {
      cat("    OK:", round(file.size(zipfile) / 1e6, 1), "MB\n")
      available_years <- c(available_years, yr)
    } else {
      cat("    SKIPPED (will retry later if needed)\n")
    }
  }
}

# Must have at least 2 pre-2018 and 2 post-2018 years
n_pre <- sum(available_years < 2018)
n_post <- sum(available_years >= 2018)
cat("\n  Available years:", paste(available_years, collapse = ", "), "\n")
cat("  Pre-2018:", n_pre, "years | Post-2018:", n_post, "years\n")

if (n_pre < 2 || n_post < 2) {
  stop("FATAL: Need at least 2 pre-2018 and 2 post-2018 years for the analysis.")
}

## --- Extract CSV files from zips ---
cat("\n=== Extracting CSV files ===\n")

all_data <- list()

for (yr in available_years) {
  zipfile <- file.path(raw_dir, paste0(yr, "_NEI_Facility_summary.zip"))

  # List files in zip
  zip_contents <- unzip(zipfile, list = TRUE)
  csv_files <- zip_contents$Name[grepl("\\.csv$", zip_contents$Name, ignore.case = TRUE)]

  if (length(csv_files) == 0) {
    cat("  WARNING: No CSV in", yr, "zip — skipping\n")
    next
  }

  cat("  Extracting", yr, ":", csv_files[1], "\n")
  unzip(zipfile, files = csv_files[1], exdir = raw_dir, overwrite = TRUE)

  csv_path <- file.path(raw_dir, csv_files[1])
  dt <- fread(csv_path, showProgress = FALSE)
  dt[, nei_year := yr]

  cat("    Rows:", nrow(dt), "| Columns:", ncol(dt), "\n")

  all_data[[as.character(yr)]] <- dt
}

## --- Combine and save ---
cat("\n=== Combining all years ===\n")

all_names <- lapply(all_data, names)
common_cols <- Reduce(intersect, all_names)
cat("  Common columns across all years:", length(common_cols), "\n")

combined <- rbindlist(
  lapply(all_data, function(dt) dt[, ..common_cols]),
  fill = TRUE
)

cat("  Combined dataset:", nrow(combined), "rows x", ncol(combined), "columns\n")
cat("  Years:", paste(sort(unique(combined$nei_year)), collapse = ", "), "\n")

saveRDS(combined, file.path(data_dir, "nei_facility_summaries_2012_2021.rds"))
cat("\nSaved to data/nei_facility_summaries_2012_2021.rds\n")

cat("\nAll column names:\n")
print(names(combined))

cat("\nRows per year:\n")
print(combined[, .N, by = nei_year][order(nei_year)])
