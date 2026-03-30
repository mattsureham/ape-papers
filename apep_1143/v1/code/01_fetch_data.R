## 01_fetch_data.R — Download USPVDB + BBS data
## apep_1143: Solar PV and Farmland Birds

source("./code/00_packages.R")

DATA_DIR <- "./data"
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. USPVDB — US Large-Scale Solar Photovoltaic Database
# ============================================================
cat("\n=== DOWNLOADING USPVDB ===\n")

# Download the GeoJSON (smaller than shapefile)
uspvdb_url <- "https://energy.usgs.gov/uspvdb/assets/data/uspvdb_v3_0_20250430.csv"
uspvdb_file <- file.path(DATA_DIR, "uspvdb.csv")

tryCatch({
  download.file(uspvdb_url, uspvdb_file, mode = "wb", quiet = TRUE)
  uspvdb <- fread(uspvdb_file, showProgress = FALSE)
  cat("USPVDB:", nrow(uspvdb), "facilities\n")
  cat("Columns:", paste(head(names(uspvdb), 15), collapse = ", "), "\n")
}, error = function(e) {
  cat("Direct CSV failed:", e$message, "\n")
  cat("Trying alternative URL...\n")
  # Try the ScienceBase download
  alt_url <- "https://www.sciencebase.gov/catalog/file/get/6671c479d34e84915adb7536?f=__disk__c8%2Fcd%2F1d%2Fc8cd1d0f7f5b6c39f3eb6e5c8e5e1a9b4e7d3a2b"
  tryCatch({
    download.file(alt_url, uspvdb_file, mode = "wb", quiet = TRUE)
    uspvdb <<- fread(uspvdb_file, showProgress = FALSE)
    cat("USPVDB (alt):", nrow(uspvdb), "facilities\n")
  }, error = function(e2) {
    cat("Alt also failed:", e2$message, "\n")
    cat("Will try USGS data API...\n")
  })
})

# If download failed, try the USGS data catalog API
if (!exists("uspvdb") || is.null(uspvdb)) {
  cat("Trying USGS API for USPVDB...\n")
  # The USPVDB viewer may have an API
  tryCatch({
    resp <- httr::GET("https://energy.usgs.gov/uspvdb/api/facilities?limit=10000")
    if (httr::status_code(resp) == 200) {
      content <- httr::content(resp, as = "text")
      uspvdb <- fread(content)
      cat("USPVDB via API:", nrow(uspvdb), "facilities\n")
    }
  }, error = function(e) {
    cat("API failed:", e$message, "\n")
  })
}

# Show USPVDB summary
if (exists("uspvdb") && !is.null(uspvdb) && nrow(uspvdb) > 0) {
  cat("\nUSPVDB Summary:\n")
  cat("  Facilities:", nrow(uspvdb), "\n")
  cat("  Column names:", paste(names(uspvdb), collapse = ", "), "\n")
  cat("  Sample:\n")
  print(head(uspvdb, 3))
}

# ============================================================
# 2. BBS — Breeding Bird Survey
# ============================================================
cat("\n=== DOWNLOADING BBS DATA ===\n")

# BBS route data (centroids, lat/lon)
bbs_routes_url <- "https://www.sciencebase.gov/catalog/file/get/625f151ed34e85fa62b7f926?f=__disk__6f%2F0e%2F97%2F6f0e9729e7c8efc30cc9aa0ef0c4ef8f2e2a1c3b"

# Try the direct USGS BBS download page
# Routes file
routes_url <- "https://www.pwrc.usgs.gov/BBS/RawData/Choose-Method.cfm"
cat("BBS raw data page available\n")

# Download route locations
cat("Downloading BBS route locations...\n")
routes_csv_url <- "https://www.sciencebase.gov/catalog/file/get/66e3c26fd34e0de260702415?f=__disk__8e%2Fe9%2F81%2F8ee981f5e29c2b3e0bb1e8b8e03e5b3f0c0d8a9b"
tryCatch({
  download.file("https://www.pwrc.usgs.gov/BBS/RawData/2024-release/routes.zip",
                file.path(DATA_DIR, "bbs_routes.zip"), mode = "wb", quiet = TRUE)
  unzip(file.path(DATA_DIR, "bbs_routes.zip"), exdir = DATA_DIR)
  routes_files <- list.files(DATA_DIR, pattern = "routes", full.names = TRUE, ignore.case = TRUE)
  cat("Route files:", paste(basename(routes_files), collapse = ", "), "\n")
}, error = function(e) {
  cat("BBS routes download failed:", e$message, "\n")
  cat("Trying alternative...\n")
  tryCatch({
    download.file("https://www.sciencebase.gov/catalog/file/get/66e3c26fd34e0de260702415",
                  file.path(DATA_DIR, "bbs_routes.zip"), mode = "wb", quiet = TRUE)
    unzip(file.path(DATA_DIR, "bbs_routes.zip"), exdir = DATA_DIR)
    cat("BBS routes downloaded via ScienceBase\n")
  }, error = function(e2) {
    cat("ScienceBase also failed:", e2$message, "\n")
  })
})

# Download species count data (state-level files)
# For 8GB RAM, download a few key states first as proof of concept
cat("\nDownloading BBS 50-stop count data...\n")
tryCatch({
  download.file("https://www.pwrc.usgs.gov/BBS/RawData/2024-release/50-StopData.zip",
                file.path(DATA_DIR, "bbs_counts.zip"), mode = "wb", quiet = TRUE,
                timeout = 300)
  cat("BBS count data downloaded, unzipping...\n")
  unzip(file.path(DATA_DIR, "bbs_counts.zip"), exdir = file.path(DATA_DIR, "bbs_counts"))
  count_files <- list.files(file.path(DATA_DIR, "bbs_counts"), pattern = "\\.csv$",
                            full.names = TRUE)
  cat("Count files:", length(count_files), "\n")
}, error = function(e) {
  cat("BBS counts download failed:", e$message, "\n")
  cat("Trying ScienceBase...\n")
  tryCatch({
    download.file("https://www.sciencebase.gov/catalog/file/get/66e3c26fd34e0de260702415?f=__disk__50-StopData.zip",
                  file.path(DATA_DIR, "bbs_counts.zip"), mode = "wb", quiet = TRUE,
                  timeout = 300)
    unzip(file.path(DATA_DIR, "bbs_counts.zip"), exdir = file.path(DATA_DIR, "bbs_counts"))
    cat("BBS counts via ScienceBase OK\n")
  }, error = function(e2) {
    cat("ScienceBase also failed:", e2$message, "\n")
  })
})

# Download species list (to identify farmland guild by AOU number)
cat("\nDownloading BBS species list...\n")
tryCatch({
  download.file("https://www.pwrc.usgs.gov/BBS/RawData/2024-release/SpeciesList.csv",
                file.path(DATA_DIR, "bbs_species.csv"), mode = "wb", quiet = TRUE)
  species <- fread(file.path(DATA_DIR, "bbs_species.csv"))
  cat("Species list:", nrow(species), "species\n")
}, error = function(e) {
  cat("Species list failed:", e$message, "\n")
})

# Download weather data (observation conditions)
cat("Downloading BBS weather data...\n")
tryCatch({
  download.file("https://www.pwrc.usgs.gov/BBS/RawData/2024-release/weather.zip",
                file.path(DATA_DIR, "bbs_weather.zip"), mode = "wb", quiet = TRUE)
  unzip(file.path(DATA_DIR, "bbs_weather.zip"), exdir = DATA_DIR)
  cat("Weather data downloaded\n")
}, error = function(e) {
  cat("Weather download failed:", e$message, "\n")
})

cat("\n=== DATA FETCH COMPLETE ===\n")
cat("Files in data directory:\n")
cat(paste(list.files(DATA_DIR, recursive = FALSE), collapse = "\n"), "\n")
