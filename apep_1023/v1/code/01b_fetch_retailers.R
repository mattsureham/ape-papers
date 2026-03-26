## 01b_fetch_retailers.R — Fetch SNAP retailer data only (ACS already fetched)
source("00_packages.R")

snap_zip <- "../data/snap_retailers.zip"
snap_file <- "../data/snap_retailers_raw.csv"

# USDA FNS official historical retailer data
snap_url <- "https://fns-prod.azureedge.us/sites/default/files/resource-files/snap-retailer-locator-data2005-2025.zip"
cat(sprintf("Downloading from: %s\n", snap_url))

downloaded <- FALSE
tryCatch({
  download.file(snap_url, snap_zip, mode = "wb", quiet = FALSE, timeout = 600)
  finfo <- file.info(snap_zip)
  cat(sprintf("ZIP size: %.1f MB\n", finfo$size / 1e6))

  # Unzip
  unzip(snap_zip, exdir = "../data/", overwrite = TRUE)

  # Find the CSV
  csv_files <- list.files("../data/", pattern = "\\.csv$", full.names = TRUE, ignore.case = TRUE)
  cat(sprintf("Found CSVs: %s\n", paste(basename(csv_files), collapse = ", ")))

  # Pick the historical one (largest file or matching name)
  if (length(csv_files) > 0) {
    # Use the largest CSV
    sizes <- file.info(csv_files)$size
    biggest <- csv_files[which.max(sizes)]
    if (biggest != snap_file) {
      file.copy(biggest, snap_file, overwrite = TRUE)
    }
    downloaded <- TRUE
    cat(sprintf("Using: %s (%.1f MB)\n", basename(biggest), max(sizes) / 1e6))
  }
}, error = function(e) {
  cat(sprintf("Download failed: %s\n", e$message))
})

if (!downloaded) {
  # Try direct URL
  snap_url2 <- "https://www.fns.usda.gov/sites/default/files/resource-files/snap-retailer-locator-data2005-2025.zip"
  cat(sprintf("Trying: %s\n", snap_url2))
  tryCatch({
    download.file(snap_url2, snap_zip, mode = "wb", quiet = FALSE, timeout = 600)
    unzip(snap_zip, exdir = "../data/", overwrite = TRUE)
    csv_files <- list.files("../data/", pattern = "\\.csv$", full.names = TRUE)
    sizes <- file.info(csv_files)$size
    biggest <- csv_files[which.max(sizes)]
    file.copy(biggest, snap_file, overwrite = TRUE)
    downloaded <- TRUE
  }, error = function(e) {
    cat(sprintf("Fallback also failed: %s\n", e$message))
  })
}

if (!downloaded) {
  stop("FATAL: Cannot download SNAP retailer data")
}

snap_raw <- fread(snap_file)
cat(sprintf("SNAP retailers: %d rows, %d columns\n", nrow(snap_raw), ncol(snap_raw)))
cat(sprintf("Columns: %s\n", paste(names(snap_raw), collapse = ", ")))
cat(sprintf("Sample:\n"))
print(head(snap_raw, 3))

saveRDS(snap_raw, "../data/snap_retailers_raw.rds")
cat("Saved: data/snap_retailers_raw.rds\n")
