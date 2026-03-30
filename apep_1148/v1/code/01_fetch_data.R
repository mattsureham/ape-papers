## 01_fetch_data.R — Download CMS HCRIS cost report data (multiple fiscal years)
## Source: CMS Hospital Cost Report Information System (Form 2552-10)

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## -----------------------------------------------------------------------
## CMS HCRIS: download individual fiscal year ZIPs
## Each contains RPT, NMRC, and ALPHA tables for that FY
## URL pattern: https://downloads.cms.gov/files/hcris/HOSP10FY{YEAR}.zip
## -----------------------------------------------------------------------

target_years <- 2012:2024

for (yr in target_years) {
  zip_file <- file.path(data_dir, sprintf("hosp10_fy%d.zip", yr))
  nmrc_marker <- file.path(data_dir, sprintf("fy%d_nmrc.csv", yr))

  if (file.exists(nmrc_marker) && file.size(nmrc_marker) > 1000) {
    cat(sprintf("Already have FY%d data\n", yr))
    next
  }

  # Try known URL patterns
  urls <- c(
    sprintf("https://downloads.cms.gov/files/hcris/HOSP10FY%d.zip", yr),
    sprintf("https://downloads.cms.gov/files/hcris/hosp10fy%d.zip", yr)
  )

  downloaded <- FALSE
  for (url in urls) {
    cat(sprintf("Trying FY%d: %s\n", yr, url))
    result <- tryCatch({
      download.file(url, zip_file, mode = "wb", quiet = TRUE)
      if (file.exists(zip_file) && file.size(zip_file) > 10000) {
        downloaded <- TRUE
        TRUE
      } else FALSE
    }, error = function(e) FALSE)
    if (result) break
  }

  if (downloaded) {
    # Extract and rename files
    tmp_dir <- file.path(data_dir, sprintf("tmp_fy%d", yr))
    dir.create(tmp_dir, showWarnings = FALSE)
    unzip(zip_file, exdir = tmp_dir)

    # Find the extracted files
    extracted <- list.files(tmp_dir, full.names = TRUE, recursive = TRUE)
    for (f in extracted) {
      bn <- tolower(basename(f))
      if (grepl("nmrc", bn)) {
        file.copy(f, file.path(data_dir, sprintf("fy%d_nmrc.csv", yr)))
      } else if (grepl("rpt", bn) && !grepl("alpha", bn)) {
        file.copy(f, file.path(data_dir, sprintf("fy%d_rpt.csv", yr)))
      }
    }

    # Cleanup
    unlink(tmp_dir, recursive = TRUE)
    unlink(zip_file)
    cat(sprintf("  Extracted FY%d\n", yr))
  } else {
    cat(sprintf("  FAILED FY%d\n", yr))
  }
}

## -----------------------------------------------------------------------
## Verify what we have
## -----------------------------------------------------------------------

cat("\n=== Downloaded HCRIS files ===\n")
rpt_files <- list.files(data_dir, pattern = "fy\\d{4}_rpt\\.csv", full.names = TRUE)
nmrc_files <- list.files(data_dir, pattern = "fy\\d{4}_nmrc\\.csv", full.names = TRUE)

cat(sprintf("  RPT files: %d\n", length(rpt_files)))
cat(sprintf("  NMRC files: %d\n", length(nmrc_files)))

for (f in sort(rpt_files)) {
  sz <- file.size(f) / 1024 / 1024
  cat(sprintf("    %s (%.1f MB)\n", basename(f), sz))
}

if (length(nmrc_files) == 0) {
  stop("FATAL: No HCRIS NMRC data downloaded. Cannot proceed.")
}

cat("\n01_fetch_data.R complete.\n")
