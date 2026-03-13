## 01_fetch_data.R — Download STATS19 collision and casualty data
## APEP paper apep_0627: Wales 20mph Speed Limit

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ------------------------------------------------------------------
## 1. Download collision data (2018-2024)
## ------------------------------------------------------------------
base_url <- "https://data.dft.gov.uk/road-accidents-safety-data"
years <- 2018:2024

collision_list <- list()
casualty_list <- list()

for (yr in years) {
  # Collision file
  col_file <- file.path(data_dir, paste0("collision_", yr, ".csv"))
  col_url <- paste0(base_url, "/dft-road-casualty-statistics-collision-", yr, ".csv")

  if (!file.exists(col_file)) {
    cat("Downloading collision data for", yr, "...\n")
    resp <- tryCatch(
      download.file(col_url, col_file, mode = "wb", quiet = TRUE),
      error = function(e) {
        cat("  Failed to download collision", yr, ":", conditionMessage(e), "\n")
        return(1L)
      }
    )
    if (!identical(resp, 0L) || file.size(col_file) < 1000) {
      cat("  Collision data for", yr, "not available. Removing.\n")
      file.remove(col_file)
      next
    }
  }
  cat("Reading collision data for", yr, "...\n")
  collision_list[[as.character(yr)]] <- fread(col_file, showProgress = FALSE)

  # Casualty file
  cas_file <- file.path(data_dir, paste0("casualty_", yr, ".csv"))
  cas_url <- paste0(base_url, "/dft-road-casualty-statistics-casualty-", yr, ".csv")

  if (!file.exists(cas_file)) {
    cat("Downloading casualty data for", yr, "...\n")
    resp <- tryCatch(
      download.file(cas_url, cas_file, mode = "wb", quiet = TRUE),
      error = function(e) {
        cat("  Failed to download casualty", yr, ":", conditionMessage(e), "\n")
        return(1L)
      }
    )
    if (!identical(resp, 0L) || file.size(cas_file) < 1000) {
      cat("  Casualty data for", yr, "not available. Removing.\n")
      file.remove(cas_file)
      next
    }
  }
  cat("Reading casualty data for", yr, "...\n")
  casualty_list[[as.character(yr)]] <- fread(cas_file, showProgress = FALSE)
}

## ------------------------------------------------------------------
## 2. Validate: we must have real data
## ------------------------------------------------------------------
stopifnot(
  "No collision data downloaded — cannot proceed" = length(collision_list) >= 3
)

years_available <- as.integer(names(collision_list))
cat("Collision data available for years:", paste(years_available, collapse = ", "), "\n")
cat("Casualty data available for years:", paste(names(casualty_list), collapse = ", "), "\n")

## ------------------------------------------------------------------
## 3. Bind and save
## ------------------------------------------------------------------
# Standardize column names across years (they may vary slightly)
standardize_cols <- function(dt) {
  nms <- tolower(names(dt))
  # Common renames
  nms <- gsub("accident_index", "collision_index", nms)
  nms <- gsub("accident_year", "collision_year", nms)
  nms <- gsub("accident_severity", "collision_severity", nms)
  nms <- gsub("accident_reference", "collision_ref_no", nms)
  nms <- gsub("1st_road_class", "first_road_class", nms)
  nms <- gsub("1st_road_number", "first_road_number", nms)
  nms <- gsub("2nd_road_class", "second_road_class", nms)
  nms <- gsub("2nd_road_number", "second_road_number", nms)
  setnames(dt, names(dt), nms)
  return(dt)
}

collision_list <- lapply(collision_list, standardize_cols)
casualty_list <- lapply(casualty_list, standardize_cols)

# Find common columns and bind
common_col_cols <- Reduce(intersect, lapply(collision_list, names))
collisions <- rbindlist(lapply(collision_list, function(dt) dt[, ..common_col_cols]))

common_cas_cols <- Reduce(intersect, lapply(casualty_list, names))
casualties <- rbindlist(lapply(casualty_list, function(dt) dt[, ..common_cas_cols]))

cat("Total collisions:", nrow(collisions), "\n")
cat("Total casualties:", nrow(casualties), "\n")

## ------------------------------------------------------------------
## 4. Save raw data
## ------------------------------------------------------------------
fwrite(collisions, file.path(data_dir, "collisions_raw.csv"))
fwrite(casualties, file.path(data_dir, "casualties_raw.csv"))

cat("Raw data saved to", data_dir, "\n")
cat("Collision columns:", paste(names(collisions), collapse = ", "), "\n")
