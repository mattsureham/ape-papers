## 01_fetch_data.R — Fetch OSHA ITA establishment-level injury data
## apep_0787: PSL mandates and workplace injuries

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ── OSHA ITA data download (ZIP files) ──────────────────────────────────────
osha_urls <- list(
  "2016" = "https://www.osha.gov/sites/default/files/ITA%20Data%20CY%202016.zip",
  "2017" = "https://www.osha.gov/sites/default/files/ITA%20Data%20CY%202017.zip",
  "2018" = "https://www.osha.gov/sites/default/files/ITA%20Data%20CY%202018.zip",
  "2019" = "https://www.osha.gov/sites/default/files/ITA%20Data%20CY%202019.zip",
  "2020" = "https://www.osha.gov/sites/default/files/ITA-Data-CY-2020.zip",
  "2021" = "https://www.osha.gov/sites/default/files/ITA-data-cy2021.zip",
  "2022" = "https://www.osha.gov/sites/default/files/ITA-data-cy2022.zip",
  "2023" = "https://www.osha.gov/sites/default/files/ITA_300A_Summary_Data_2023_through_12-31-2024.zip"
)

all_years <- list()

for (yr in names(osha_urls)) {
  zipfile <- file.path(data_dir, paste0("osha_ita_", yr, ".zip"))
  csvfile <- file.path(data_dir, paste0("osha_ita_", yr, ".csv"))

  # Download ZIP if needed

  if (!file.exists(zipfile) && !file.exists(csvfile)) {
    cat("Downloading OSHA ITA", yr, "...\n")
    resp <- httr::GET(
      osha_urls[[yr]],
      httr::write_disk(zipfile, overwrite = TRUE),
      httr::timeout(300),
      httr::user_agent("Mozilla/5.0 (APEP Research)")
    )
    if (httr::status_code(resp) != 200) {
      stop(paste("FAILED to download OSHA ITA", yr, "- HTTP", httr::status_code(resp)))
    }
    cat("  Downloaded:", zipfile, "(", file.size(zipfile), "bytes)\n")
  }

  # Extract CSV from ZIP if needed
  if (!file.exists(csvfile) && file.exists(zipfile)) {
    cat("Extracting", yr, "...\n")
    csv_names <- unzip(zipfile, list = TRUE)$Name
    # Find the main CSV (largest file, or one containing "300A" or "summary" or "data")
    csv_target <- csv_names[grepl("\\.csv$", csv_names, ignore.case = TRUE)]
    if (length(csv_target) == 0) stop(paste("No CSV found in", zipfile))
    # Pick the largest CSV
    csv_target <- csv_target[1]
    cat("  Extracting:", csv_target, "\n")
    unzip(zipfile, files = csv_target, exdir = data_dir)
    # Rename to standard name
    extracted_path <- file.path(data_dir, csv_target)
    if (file.exists(extracted_path) && extracted_path != csvfile) {
      file.rename(extracted_path, csvfile)
    }
  }

  # Read CSV (integer64="double" prevents bit64 corruption during rbindlist)
  cat("Reading OSHA ITA", yr, "...\n")
  df_yr <- data.table::fread(csvfile, showProgress = FALSE, integer64 = "double")
  cat("  Year", yr, ":", nrow(df_yr), "rows,", ncol(df_yr), "cols\n")

  df_yr$data_year <- as.integer(yr)
  all_years[[yr]] <- df_yr
}

# ── Column name inventory ───────────────────────────────────────────────────
cat("\n=== Column name inventory ===\n")
for (yr in names(all_years)) {
  cat(yr, ":", paste(head(names(all_years[[yr]]), 20), collapse = " | "), "\n")
}

# Save raw data
saveRDS(all_years, file.path(data_dir, "osha_ita_raw_list.rds"))
cat("\nSaved raw data list to osha_ita_raw_list.rds\n")
cat("Total years downloaded:", length(all_years), "\n")
cat("Total rows across all years:", sum(sapply(all_years, nrow)), "\n")
