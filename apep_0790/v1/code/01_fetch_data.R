# 01_fetch_data.R — Fetch EPA AQS daily PM2.5 data
# Downloads pre-generated annual CSV files from EPA AQS
# Parameter 88101 = PM2.5 FRM/FEM Mass (24-hour)

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# Years to download: 2003-2023 (need pre-periods for all treated states)
years <- 2003:2023

# EPA AQS pre-generated daily data files
# URL pattern from EPA download page
base_url <- "https://aqs.epa.gov/aqdat/action/download_data.html"

# The actual download URL for pre-generated files
download_epa <- function(year) {
  zip_file <- file.path(data_dir, sprintf("daily_88101_%d.zip", year))
  csv_file <- file.path(data_dir, sprintf("daily_88101_%d.csv", year))

  if (file.exists(csv_file)) {
    cat(sprintf("  %d: already exists (%s)\n", year, csv_file))
    return(csv_file)
  }

  # EPA AirData pre-generated files
  url <- sprintf(
    "https://aqs.epa.gov/aqsweb/airdata/daily_88101_%d.zip",
    year
  )

  cat(sprintf("  %d: downloading from EPA AQS...\n", year))
  options(timeout = 300)  # 5 minute timeout per file
  for (attempt in 1:3) {
    dl_result <- tryCatch(
      download.file(url, zip_file, mode = "wb", quiet = TRUE),
      error = function(e) {
        if (attempt < 3) {
          cat(sprintf("  %d: attempt %d failed, retrying...\n", year, attempt))
          Sys.sleep(2)
        }
        return(1L)
      }
    )
    if (dl_result == 0 && file.exists(zip_file) && file.size(zip_file) > 1000) break
    if (file.exists(zip_file)) file.remove(zip_file)
  }
  if (dl_result != 0 || !file.exists(zip_file) || file.size(zip_file) < 1000) {
    stop(sprintf("FATAL: Cannot download EPA data for %d after 3 attempts.", year))
  }

  # Unzip
  unzip(zip_file, exdir = data_dir)

  # Find the extracted CSV (may be in subdirectory)
  extracted <- list.files(data_dir, pattern = sprintf("daily_88101_%d\\.csv$", year),
                          full.names = TRUE, recursive = TRUE)

  if (length(extracted) == 0) {
    stop(sprintf("FATAL: No CSV found after unzipping %d data", year))
  }

  # Move to data_dir if in subdirectory
  if (dirname(extracted[1]) != normalizePath(data_dir)) {
    file.rename(extracted[1], csv_file)
    unlink(dirname(extracted[1]), recursive = TRUE)
    extracted[1] <- csv_file
  }

  cat(sprintf("  %d: OK (%s)\n", year, basename(extracted[1])))
  return(extracted[1])
}

cat("Downloading EPA AQS daily PM2.5 data (parameter 88101)...\n")
cat("Years: 2003-2023\n\n")

csv_files <- character(0)
for (y in years) {
  f <- download_epa(y)
  csv_files <- c(csv_files, f)
}

cat(sprintf("\nDownloaded %d years of data.\n", length(csv_files)))

# Read and combine all years, keeping only June-July + late December
# (for July 4 analysis + New Year's Eve placebo)
cat("\nReading and filtering to June 15 - July 15 + Dec 28 - Jan 5 windows...\n")

read_year <- function(csv_path) {
  dt <- fread(csv_path, select = c(
    "State Code", "County Code", "Site Num",
    "Date Local", "Arithmetic Mean",
    "State Name", "Latitude", "Longitude",
    "POC"
  ))

  setnames(dt, c("state_code", "county_code", "site_num",
                  "date", "pm25",
                  "state_name", "lat", "lon", "poc"))

  # Handle both date formats: "2019-01-03" and "1/1/2020"
  dt[, date := fifelse(
    grepl("^\\d{4}-", date),
    as.Date(date, format = "%Y-%m-%d"),
    as.Date(date, format = "%m/%d/%Y")
  )]
  dt[, month := month(date)]
  dt[, day := mday(date)]

  # Keep June 15 - July 15 (main analysis window)
  # Plus Dec 28 - Jan 5 (New Year's Eve placebo)
  # Plus May 20 - Jun 5 (Memorial Day placebo)
  # Plus Aug 25 - Sep 10 (Labor Day placebo)
  keep <- dt[
    (month == 6 & day >= 15) |
    (month == 7 & day <= 25) |
    (month == 12 & day >= 28) |
    (month == 1 & day <= 5) |
    (month == 5 & day >= 20) |
    (month == 6 & day <= 5) |
    (month == 8 & day >= 25) |
    (month == 9 & day <= 10)
  ]

  return(keep)
}

all_data <- rbindlist(lapply(csv_files, read_year))
cat(sprintf("Combined data: %s rows, %d monitors\n",
            format(nrow(all_data), big.mark = ","),
            uniqueN(all_data[, .(state_code, county_code, site_num)])))

# Create unique monitor ID
all_data[, monitor_id := paste(state_code, county_code, site_num, sep = "-")]
all_data[, year := year(date)]

# Average across POC (parameter occurrence codes) for same monitor-day
daily <- all_data[, .(
  pm25 = mean(pm25, na.rm = TRUE),
  lat = first(lat),
  lon = first(lon),
  state_name = first(state_name),
  state_code = first(state_code)
), by = .(monitor_id, date, year)]

cat(sprintf("After POC averaging: %s monitor-days\n",
            format(nrow(daily), big.mark = ",")))

# Validate: no missing PM2.5
stopifnot("PM2.5 values must not be NA" = !any(is.na(daily$pm25)))
cat(sprintf("Years covered: %s\n", paste(sort(unique(daily$year)), collapse = ", ")))
stopifnot("Must have data from at least 2003-2022" =
            all(2003:2022 %in% unique(daily$year)))

# Save
fwrite(daily, file.path(data_dir, "epa_daily_pm25_filtered.csv"))
cat(sprintf("\nSaved filtered data to %s\n", file.path(data_dir, "epa_daily_pm25_filtered.csv")))

cat("\n=== Data fetch complete ===\n")
