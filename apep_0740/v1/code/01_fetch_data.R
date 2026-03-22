## 01_fetch_data.R — Download DVF geolocalized + QPV boundaries
## APEP-0740: QPV Designation Paradox
## All data from public APIs

source("00_packages.R")
script_dir <- tryCatch(dirname(sys.frame(1)$ofile), error = function(e) ".")
setwd(file.path(script_dir, ".."))
data_dir <- "data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

cat("=== Fetching QPV boundaries from Geoplateforme WFS ===\n")

qpv_file <- file.path(data_dir, "qpv_boundaries.geojson")

if (!file.exists(qpv_file)) {
  ## Download from IGN Geoplateforme WFS in batches of 1000
  wfs_base <- paste0(
    "https://data.geopf.fr/wfs/ows?service=WFS&version=2.0.0",
    "&request=GetFeature",
    "&typeName=AREAMANAGEMENT.QP.VECTOR:qp_decretmodif_2015_epsg3857_wm",
    "&outputFormat=application/json"
  )

  cat("Downloading QPV batch 1 (features 0-999)...\n")
  batch1_file <- file.path(data_dir, "qpv_batch1.geojson")
  url1 <- paste0(wfs_base, "&startIndex=0&count=1000")
  curl::curl_download(url1, batch1_file, quiet = FALSE)

  cat("Downloading QPV batch 2 (features 1000+)...\n")
  batch2_file <- file.path(data_dir, "qpv_batch2.geojson")
  url2 <- paste0(wfs_base, "&startIndex=1000&count=1000")
  curl::curl_download(url2, batch2_file, quiet = FALSE)

  ## Read and combine
  qpv1 <- sf::st_read(batch1_file, quiet = TRUE)
  qpv2 <- sf::st_read(batch2_file, quiet = TRUE)
  qpv_all <- rbind(qpv1, qpv2)

  cat(sprintf("Combined QPV features: %d\n", nrow(qpv_all)))
  if (nrow(qpv_all) < 1000) {
    stop("FATAL: QPV download returned fewer than 1000 features. Expected ~1514.")
  }

  ## Filter to metropolitan France (exclude overseas: 97x codes)
  metro_mask <- !grepl("^QP97", qpv_all$code_qp)
  qpv_metro <- qpv_all[metro_mask, ]
  cat(sprintf("Metropolitan France QPVs: %d\n", nrow(qpv_metro)))

  sf::st_write(qpv_metro, qpv_file, delete_dsn = TRUE, quiet = TRUE)

  ## Cleanup batch files
  file.remove(batch1_file, batch2_file)
} else {
  qpv_metro <- sf::st_read(qpv_file, quiet = TRUE)
  cat(sprintf("QPV loaded from cache: %d features\n", nrow(qpv_metro)))
}

stopifnot(nrow(qpv_metro) >= 1000)
rm(qpv_metro)

cat("\n=== Fetching DVF geolocalized data ===\n")

## DVF Geolocalized from data.gouv.fr
## Fetch 2014 (pre-treatment placebo) + 2015-2024 (post-QPV)
## Each year ~50-100MB compressed

dvf_base_url <- "https://files.data.gouv.fr/geo-dvf/latest/csv"
years <- 2014:2024

for (yr in years) {
  dvf_file <- file.path(data_dir, sprintf("dvf_%d.csv.gz", yr))
  if (!file.exists(dvf_file)) {
    url <- sprintf("%s/%d/full.csv.gz", dvf_base_url, yr)
    cat(sprintf("Downloading DVF %d...\n", yr))
    result <- tryCatch(
      curl::curl_download(url, dvf_file, quiet = FALSE),
      error = function(e) {
        cat(sprintf("  DVF %d download failed: %s\n", yr, e$message))
        NULL
      }
    )
    if (is.null(result) || !file.exists(dvf_file) || file.size(dvf_file) < 10000) {
      warning(sprintf("DVF %d: download failed. Skipping.", yr))
      if (file.exists(dvf_file)) file.remove(dvf_file)
    }
  }
  if (file.exists(dvf_file)) {
    cat(sprintf("  DVF %d: %.1f MB\n", yr, file.size(dvf_file) / 1e6))
  }
}

## Verify we have at least 5 years of data
dvf_files <- list.files(data_dir, pattern = "^dvf_\\d{4}\\.csv\\.gz$", full.names = TRUE)
if (length(dvf_files) < 5) {
  stop(sprintf("FATAL: Only %d DVF year files downloaded. Need at least 5.", length(dvf_files)))
}

cat(sprintf("\n=== Data fetch complete ===\n"))
cat(sprintf("QPV boundaries: %s\n", qpv_file))
cat(sprintf("DVF files: %d years downloaded\n", length(dvf_files)))
