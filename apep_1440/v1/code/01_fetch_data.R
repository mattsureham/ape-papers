# 01_fetch_data.R — Fetch UCMR5, karst geology, and DoD PFAS data
# PFAS/Karst Spatial RDD — apep_1440

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. UCMR5 — EPA PFAS monitoring data
# ============================================================
ucmr5_url <- "https://www.epa.gov/system/files/other-files/2023-08/ucmr5-occurrence-data.zip"
ucmr5_zip <- file.path(data_dir, "ucmr5.zip")
ucmr5_dir <- file.path(data_dir, "ucmr5")

if (!file.exists(file.path(ucmr5_dir, "UCMR5_All.txt"))) {
  cat("Downloading UCMR5 data...\n")
  resp <- httr::GET(ucmr5_url, httr::write_disk(ucmr5_zip, overwrite = TRUE),
                    httr::timeout(300))
  stopifnot("UCMR5 download failed" = httr::status_code(resp) == 200)
  dir.create(ucmr5_dir, showWarnings = FALSE)
  unzip(ucmr5_zip, exdir = ucmr5_dir)
  cat("UCMR5 extracted.\n")
} else {
  cat("UCMR5 already downloaded.\n")
}

# Find the main data file
ucmr5_files <- list.files(ucmr5_dir, pattern = "\\.txt$|\\.csv$", recursive = TRUE, full.names = TRUE)
cat("UCMR5 files found:", ucmr5_files, "\n")

# ============================================================
# 2. USGS Karst Geology Map
# ============================================================
# Karst areas of the US — published shapefile from USGS
karst_url <- "https://pubsdata.usgs.gov/pubs/of/2014/1156/downloads/USKarstMap.zip"
karst_zip <- file.path(data_dir, "karst_gis.zip")
karst_dir <- file.path(data_dir, "karst_gis")

if (!dir.exists(karst_dir) || length(list.files(karst_dir, pattern = "\\.shp$", recursive = TRUE)) == 0) {
  cat("Downloading USGS karst geology map...\n")
  resp <- httr::GET(karst_url, httr::write_disk(karst_zip, overwrite = TRUE),
                    httr::timeout(300))
  stopifnot("Karst map download failed" = httr::status_code(resp) == 200)
  dir.create(karst_dir, showWarnings = FALSE)
  unzip(karst_zip, exdir = karst_dir)
  cat("Karst GIS extracted.\n")
} else {
  cat("Karst GIS already downloaded.\n")
}

karst_shps <- list.files(karst_dir, pattern = "\\.shp$", recursive = TRUE, full.names = TRUE)
cat("Karst shapefiles found:", karst_shps, "\n")

# ============================================================
# 3. DoD PFAS Installation List
# ============================================================
# Use EWG's DoD PFAS contamination database (publicly scraped from DoD reports)
# Alternative: EPA PFAS Analytics Tool
pfas_sites_url <- "https://www.epa.gov/system/files/other-files/2024-08/pfas-analytic-tools-data.zip"
pfas_zip <- file.path(data_dir, "pfas_analytic.zip")
pfas_dir <- file.path(data_dir, "pfas_analytic")

if (!dir.exists(pfas_dir)) {
  cat("Downloading EPA PFAS Analytic Tools data...\n")
  resp <- httr::GET(pfas_sites_url, httr::write_disk(pfas_zip, overwrite = TRUE),
                    httr::timeout(300))
  if (httr::status_code(resp) == 200) {
    dir.create(pfas_dir, showWarnings = FALSE)
    unzip(pfas_zip, exdir = pfas_dir)
    cat("EPA PFAS data extracted.\n")
  } else {
    cat("EPA PFAS download returned status:", httr::status_code(resp), "\n")
    cat("Will proceed with UCMR5 data alone (contains PWS-level PFAS detections).\n")
  }
}

# ============================================================
# 4. SDWIS PWS Location Data (from EPA ECHO API)
# ============================================================
# We need PWS latitude/longitude to do spatial joins
# Use EPA ECHO Water System Search
cat("PWS locations will be fetched in 02_clean_data.R via ECHO API for matched systems.\n")

# ============================================================
# 5. CDC WONDER Natality — County-level birth outcome aggregates
# ============================================================
# CDC WONDER requires interactive agreement; use NBER natality mirrors instead
# For V1, use county-level aggregates from CDC Vital Stats
# Available: https://wonder.cdc.gov/natality-expanded-current.html

cat("\n=== Data Fetch Summary ===\n")
cat("UCMR5 files:", length(ucmr5_files), "\n")
cat("Karst shapefiles:", length(karst_shps), "\n")
cat("Data fetch complete.\n")
