## 01_fetch_data.R — Download EPA ICIS-Air, ICIS-NPDES (CWA), RCRA, and TRI data
## APEP-0642 v2: Regulatory Whack-a-Mole

source("00_packages.R")

# Increase download timeout for large EPA files
options(timeout = 600)

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. Download ICIS-Air bulk data (inspections)
# ============================================================
icis_zip <- file.path(data_dir, "ICIS-AIR_downloads.zip")
icis_dir <- file.path(data_dir, "icis_air")

if (!file.exists(icis_zip)) {
  cat("Downloading ICIS-Air bulk data (~64MB)...\n")
  download.file(
    url = "https://echo.epa.gov/files/echodownloads/ICIS-AIR_downloads.zip",
    destfile = icis_zip,
    mode = "wb",
    timeout = 600
  )
  stopifnot("ICIS-Air download failed" = file.exists(icis_zip) && file.size(icis_zip) > 1e6)
  cat("ICIS-Air downloaded:", round(file.size(icis_zip) / 1e6, 1), "MB\n")
}

if (!dir.exists(icis_dir)) {
  dir.create(icis_dir, showWarnings = FALSE)
  unzip(icis_zip, exdir = icis_dir)
  cat("ICIS-Air unzipped to:", icis_dir, "\n")
}

# List available files
icis_files <- list.files(icis_dir, pattern = "\\.csv$", full.names = TRUE)
cat("ICIS-Air files:\n")
for (f in icis_files) cat("  ", basename(f), "—", round(file.size(f) / 1e6, 1), "MB\n")

# ============================================================
# 2. Read ICIS-Air inspections (FCEs and PCEs)
# ============================================================
fce_file <- grep("FCES_PCES", icis_files, value = TRUE)
stopifnot("Cannot find ICIS-AIR_FCES_PCES.csv" = length(fce_file) == 1)

cat("Reading inspections from:", basename(fce_file), "\n")
inspections_raw <- fread(fce_file, showProgress = FALSE)
cat("  Raw inspections:", nrow(inspections_raw), "rows\n")
cat("  Columns:", paste(names(inspections_raw), collapse = ", "), "\n")

# ============================================================
# 3. Read ICIS-Air facilities (for REGISTRY_ID linkage to TRI)
# ============================================================
fac_file <- grep("FACILITIES", icis_files, value = TRUE)
stopifnot("Cannot find ICIS-AIR_FACILITIES.csv" = length(fac_file) == 1)

cat("Reading facilities from:", basename(fac_file), "\n")
facilities_raw <- fread(fac_file, showProgress = FALSE)
cat("  Raw facilities:", nrow(facilities_raw), "rows\n")
cat("  Columns:", paste(names(facilities_raw), collapse = ", "), "\n")

# ============================================================
# 4. Download TRI Basic Data Files (releases by medium)
# ============================================================
# Download for years 2005-2022 (manageable scope)
tri_dir <- file.path(data_dir, "tri")
dir.create(tri_dir, showWarnings = FALSE)

tri_years <- 2005:2022

for (yr in tri_years) {
  tri_file <- file.path(tri_dir, paste0("tri_", yr, "_us.csv"))
  if (!file.exists(tri_file)) {
    url <- paste0("https://data.epa.gov/efservice/downloads/tri/mv_tri_basic_download/", yr, "_US/csv")
    cat("Downloading TRI", yr, "...\n")
    tryCatch({
      download.file(url, destfile = tri_file, mode = "wb", timeout = 300, quiet = TRUE)
      if (file.size(tri_file) < 1000) {
        cat("  WARNING: TRI", yr, "file is suspiciously small (", file.size(tri_file), "bytes). Removing.\n")
        file.remove(tri_file)
        # Try alternate URL with period instead of underscore
        url2 <- paste0("https://data.epa.gov/efservice/downloads/tri/mv_tri_basic_download/", yr, "_U.S./csv")
        download.file(url2, destfile = tri_file, mode = "wb", timeout = 300, quiet = TRUE)
        if (file.size(tri_file) < 1000) {
          cat("  ERROR: TRI", yr, "could not be downloaded from either URL.\n")
          file.remove(tri_file)
        }
      }
      if (file.exists(tri_file)) cat("  TRI", yr, ":", round(file.size(tri_file) / 1e6, 1), "MB\n")
    }, error = function(e) {
      cat("  ERROR downloading TRI", yr, ":", conditionMessage(e), "\n")
      if (file.exists(tri_file)) file.remove(tri_file)
    })
  } else {
    cat("TRI", yr, "already exists:", round(file.size(tri_file) / 1e6, 1), "MB\n")
  }
}

# Check how many years we got
tri_files <- list.files(tri_dir, pattern = "tri_\\d{4}_us\\.csv$", full.names = TRUE)
cat("\nTRI files downloaded:", length(tri_files), "of", length(tri_years), "years\n")
stopifnot("Must have at least 8 years of TRI data" = length(tri_files) >= 8)

# ============================================================
# 5. Read one TRI file to verify columns
# ============================================================
cat("\nReading sample TRI file to check columns...\n")
tri_sample <- fread(tri_files[length(tri_files)], nrows = 100, showProgress = FALSE)
cat("TRI columns (", ncol(tri_sample), "):\n")
cat(paste(names(tri_sample), collapse = "\n"), "\n")

# ============================================================
# 6. Save raw data summaries
# ============================================================
summary_list <- list(
  icis_air_inspections = nrow(inspections_raw),
  icis_air_facilities = nrow(facilities_raw),
  tri_years_downloaded = length(tri_files),
  tri_year_range = paste(range(as.integer(gsub(".*_(\\d{4})_.*", "\\1", basename(tri_files)))), collapse = "-"),
  download_timestamp = Sys.time()
)
write_json(summary_list, file.path(data_dir, "download_summary.json"), auto_unbox = TRUE, pretty = TRUE)

# ============================================================
# 7. Download ICIS-NPDES (Clean Water Act) inspection data [V2 NEW]
# ============================================================
npdes_zip <- file.path(data_dir, "npdes_downloads.zip")
npdes_dir <- file.path(data_dir, "npdes")

if (!file.exists(npdes_zip)) {
  cat("Downloading ICIS-NPDES bulk data (CWA inspections, ~330MB)...\n")
  download.file(
    url = "https://echo.epa.gov/files/echodownloads/npdes_downloads.zip",
    destfile = npdes_zip,
    mode = "wb",
    timeout = 1200
  )
  stopifnot("NPDES download failed" = file.exists(npdes_zip) && file.size(npdes_zip) > 1e6)
  cat("NPDES downloaded:", round(file.size(npdes_zip) / 1e6, 1), "MB\n")
}

if (!dir.exists(npdes_dir)) {
  dir.create(npdes_dir, showWarnings = FALSE)
  cat("Unzipping NPDES...\n")
  unzip(npdes_zip, exdir = npdes_dir)
  cat("NPDES unzipped to:", npdes_dir, "\n")
}

npdes_files <- list.files(npdes_dir, pattern = "\\.csv$", full.names = TRUE, recursive = TRUE)
cat("NPDES files:\n")
for (f in npdes_files) cat("  ", basename(f), "—", round(file.size(f) / 1e6, 1), "MB\n")

# ============================================================
# 8. Download RCRA (waste program) inspection data [V2 NEW]
# ============================================================
rcra_zip <- file.path(data_dir, "rcrainfo_downloads.zip")
rcra_dir <- file.path(data_dir, "rcra")

if (!file.exists(rcra_zip)) {
  cat("Downloading RCRAInfo bulk data (RCRA inspections, ~200MB)...\n")
  download.file(
    url = "https://echo.epa.gov/files/echodownloads/rcrainfo_downloads.zip",
    destfile = rcra_zip,
    mode = "wb",
    timeout = 1200
  )
  stopifnot("RCRA download failed" = file.exists(rcra_zip) && file.size(rcra_zip) > 1e6)
  cat("RCRA downloaded:", round(file.size(rcra_zip) / 1e6, 1), "MB\n")
}

if (!dir.exists(rcra_dir)) {
  dir.create(rcra_dir, showWarnings = FALSE)
  cat("Unzipping RCRA...\n")
  unzip(rcra_zip, exdir = rcra_dir)
  cat("RCRA unzipped to:", rcra_dir, "\n")
}

rcra_files <- list.files(rcra_dir, pattern = "\\.csv$", full.names = TRUE, recursive = TRUE)
cat("RCRA files:\n")
for (f in rcra_files) cat("  ", basename(f), "—", round(file.size(f) / 1e6, 1), "MB\n")

# ============================================================
# 9. Save updated download summary
# ============================================================
summary_list <- list(
  icis_air_inspections = nrow(inspections_raw),
  icis_air_facilities = nrow(facilities_raw),
  tri_years_downloaded = length(tri_files),
  tri_year_range = paste(range(as.integer(gsub(".*_(\\d{4})_.*", "\\1", basename(tri_files)))), collapse = "-"),
  npdes_files = length(npdes_files),
  rcra_files = length(rcra_files),
  download_timestamp = Sys.time()
)
write_json(summary_list, file.path(data_dir, "download_summary.json"), auto_unbox = TRUE, pretty = TRUE)

cat("\n=== Data fetch complete ===\n")
cat("ICIS-Air inspections:", nrow(inspections_raw), "\n")
cat("ICIS-Air facilities:", nrow(facilities_raw), "\n")
cat("TRI years:", length(tri_files), "\n")
cat("NPDES files:", length(npdes_files), "\n")
cat("RCRA files:", length(rcra_files), "\n")
