## 01_fetch_data.R — Fetch BBS data from USGS ScienceBase
## apep_1025: Residential Neonicotinoid Bans and Bird Populations
## Data: North American Breeding Bird Survey 1966-2021 (2022 release)

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ---- BBS Data Download (2022 release, ScienceBase item 625f151e) ----
cat("Checking BBS data files...\n")

bbs_base <- "https://www.sciencebase.gov/catalog/file/get/625f151ed34e85fa62b7f926"

files_info <- list(
  routes = list(
    url = paste0(bbs_base, "?f=__disk__95%2F4e%2F1a%2F954e1a5ec1112c34bba91ad1fce6bd2d3c9df90e"),
    dest = "routes.zip"
  ),
  counts = list(
    url = paste0(bbs_base, "?f=__disk__b5%2Fde%2F6b%2Fb5de6b3d221373125e90a85b5fcba4b7059c7f94"),
    dest = "fifty_stop.zip"
  ),
  weather = list(
    url = paste0(bbs_base, "?f=__disk__69%2Fb6%2F5e%2F69b65e0b81199fa02bd856c892158d77c1ba7faf"),
    dest = "weather.zip"
  ),
  species = list(
    url = paste0(bbs_base, "?f=__disk__fb%2F82%2F53%2Ffb8253f145fcef9b44ef33eff603162bb39200cb"),
    dest = "SpeciesList.txt"
  )
)

for (nm in names(files_info)) {
  fi <- files_info[[nm]]
  dest_path <- file.path(data_dir, fi$dest)
  if (!file.exists(dest_path)) {
    cat("  Downloading", fi$dest, "...\n")
    result <- tryCatch(
      download.file(fi$url, dest_path, mode = "wb", quiet = TRUE),
      error = function(e) stop("FATAL: Failed to download BBS file: ", fi$dest, " — ", e$message)
    )
    if (result != 0) stop("FATAL: Download returned non-zero status for ", fi$dest)
  } else {
    cat("  ", fi$dest, "already exists, skipping.\n")
  }
}

## ---- Unzip ----
cat("Unzipping BBS files...\n")

for (zipfile in c("routes.zip", "fifty_stop.zip", "weather.zip")) {
  zip_path <- file.path(data_dir, zipfile)
  if (file.exists(zip_path)) {
    contents <- unzip(zip_path, list = TRUE)$Name
    existing <- file.exists(file.path(data_dir, contents))
    if (!all(existing)) {
      unzip(zip_path, exdir = data_dir, overwrite = TRUE)
      cat("  Unzipped:", zipfile, "\n")
    } else {
      cat("  Already unzipped:", zipfile, "\n")
    }
  }
}

## ---- Read data ----
cat("Reading route metadata...\n")
route_csv <- list.files(data_dir, pattern = "(?i)routes\\.csv$", full.names = TRUE)
stopifnot("FATAL: No routes CSV found" = length(route_csv) > 0)
routes <- fread(route_csv[1])
cat("  Routes:", nrow(routes), "rows. Columns:", paste(names(routes), collapse = ", "), "\n")

cat("Reading 50-stop count data...\n")
## Unzip nested 50-stop zips if needed
nested_dir <- file.path(data_dir, "50-StopData", "1997ToPresent_SurveyWide")
if (dir.exists(nested_dir)) {
  inner_zips <- list.files(nested_dir, pattern = "Fifty.*\\.zip$", full.names = TRUE, ignore.case = TRUE)
  for (zf in inner_zips) {
    unzip(zf, exdir = data_dir, overwrite = FALSE)
  }
}
count_csvs <- list.files(data_dir, pattern = "^fifty[0-9]+\\.csv$", full.names = TRUE, ignore.case = TRUE)
stopifnot("FATAL: No count CSV files found" = length(count_csvs) > 0)
cat("  Found", length(count_csvs), "count CSV files\n")
counts <- rbindlist(lapply(count_csvs, fread), fill = TRUE)
cat("  Counts:", nrow(counts), "rows. Year range:", paste(range(counts$Year, na.rm = TRUE), collapse = "–"), "\n")

cat("Reading weather data...\n")
weather_csv <- list.files(data_dir, pattern = "(?i)weather\\.csv$", full.names = TRUE)
stopifnot("FATAL: No weather CSV found" = length(weather_csv) > 0)
weather <- fread(weather_csv[1])
cat("  Weather:", nrow(weather), "rows\n")

cat("Reading species list...\n")
species_file <- file.path(data_dir, "SpeciesList.txt")
stopifnot("FATAL: SpeciesList.txt not found" = file.exists(species_file))
species <- fread(species_file)
cat("  Species:", nrow(species), "rows. Columns:", paste(names(species), collapse = ", "), "\n")

## ---- Save as RDS ----
saveRDS(routes, file.path(data_dir, "routes_raw.rds"))
saveRDS(counts, file.path(data_dir, "counts_raw.rds"))
saveRDS(weather, file.path(data_dir, "weather_raw.rds"))
saveRDS(species, file.path(data_dir, "species_raw.rds"))

cat("\n=== Data Fetch Summary ===\n")
cat("Routes:", nrow(routes), "\n")
cat("Count observations:", nrow(counts), "\n")
cat("Weather observations:", nrow(weather), "\n")
cat("Species in list:", nrow(species), "\n")
cat("Data saved to", normalizePath(data_dir), "\n")
