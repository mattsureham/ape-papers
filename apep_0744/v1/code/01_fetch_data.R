# 01_fetch_data.R — Download STATS19 collision data for England and Wales (2020-2024)
# Wales 20mph Speed Limit and Road Safety (apep_0744)

source("00_packages.R")

# ============================================================================
# STATS19 data from DfT — direct CSV download
# https://www.data.gov.uk/dataset/cb7ae6f0-4be6-4935-9277-47e5ce24a11f/road-safety-data
# ============================================================================

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# Download collision data for each year (2020-2024)
# DfT publishes CSV files by year
base_url <- "https://data.dft.gov.uk/road-accidents-safety-data"

years <- 2020:2024
collision_files <- c()

for (yr in years) {
  # DfT CSV naming convention
  fname <- sprintf("dft-road-casualty-statistics-collision-%d.csv", yr)
  dest <- file.path(data_dir, fname)

  if (!file.exists(dest)) {
    url <- sprintf("%s/%s", base_url, fname)
    cat(sprintf("Downloading %d collision data...\n", yr))
    tryCatch({
      download.file(url, dest, mode = "wb", quiet = TRUE)
      if (file.size(dest) < 1000) {
        stop(sprintf("Downloaded file for %d is too small (%d bytes) — likely an error page",
                      yr, file.size(dest)))
      }
      cat(sprintf("  Downloaded: %s (%s MB)\n", fname, round(file.size(dest)/1e6, 1)))
    }, error = function(e) {
      stop(sprintf("FATAL: Cannot download %d collision data: %s\nURL: %s", yr, e$message, url))
    })
  } else {
    cat(sprintf("  Already have: %s (%s MB)\n", fname, round(file.size(dest)/1e6, 1)))
  }
  collision_files <- c(collision_files, dest)
}

# Also download casualty data for severity analysis
for (yr in years) {
  fname <- sprintf("dft-road-casualty-statistics-casualty-%d.csv", yr)
  dest <- file.path(data_dir, fname)

  if (!file.exists(dest)) {
    url <- sprintf("%s/%s", base_url, fname)
    cat(sprintf("Downloading %d casualty data...\n", yr))
    tryCatch({
      download.file(url, dest, mode = "wb", quiet = TRUE)
      if (file.size(dest) < 1000) {
        stop(sprintf("Downloaded file for %d is too small (%d bytes)", yr, file.size(dest)))
      }
      cat(sprintf("  Downloaded: %s (%s MB)\n", fname, round(file.size(dest)/1e6, 1)))
    }, error = function(e) {
      stop(sprintf("FATAL: Cannot download %d casualty data: %s", yr, e$message))
    })
  } else {
    cat(sprintf("  Already have: %s (%s MB)\n", fname, round(file.size(dest)/1e6, 1)))
  }
}

# ============================================================================
# Read and combine collision data
# ============================================================================

cat("\nReading collision files...\n")

collisions <- rbindlist(lapply(collision_files, function(f) {
  dt <- fread(f, select = c(
    "collision_index", "collision_year", "date", "day_of_week",
    "local_authority_district", "local_authority_ons_district",
    "collision_severity", "number_of_casualties",
    "speed_limit", "road_type",
    "latitude", "longitude",
    "urban_or_rural_area"
  ))
  # Rename to consistent names
  setnames(dt, c("collision_index", "collision_year", "collision_severity"),
           c("accident_index", "accident_year", "accident_severity"))
  cat(sprintf("  Read %s: %s rows\n", basename(f), format(nrow(dt), big.mark = ",")))
  dt
}))

cat(sprintf("\nTotal collisions: %s\n", format(nrow(collisions), big.mark = ",")))

# ============================================================================
# Validate data
# ============================================================================

stopifnot("accident_year" %in% names(collisions))
stopifnot(nrow(collisions) > 100000)  # Expect 500K+ collisions over 5 years

# Check year coverage
yr_counts <- collisions[, .N, by = accident_year][order(accident_year)]
cat("\nCollisions by year:\n")
print(yr_counts)

stopifnot(all(years %in% yr_counts$accident_year))

# Check speed limit values
speed_counts <- collisions[, .N, by = speed_limit][order(speed_limit)]
cat("\nCollisions by speed limit:\n")
print(speed_counts)

# Save raw combined data
fwrite(collisions, file.path(data_dir, "collisions_2020_2024.csv"))
cat(sprintf("\nSaved combined collision data: %s rows\n", format(nrow(collisions), big.mark = ",")))
