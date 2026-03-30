## 01_fetch_data.R — Fetch LISA paper data
## Sources: UK HPI (LA-level prices), Land Registry PPD (transactions)
## All public, no API keys required.

source("00_packages.R")

DATA_DIR <- "../data"
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)

# ===========================================================================
# 1. UK House Price Index — LA-level monthly data from Land Registry
#    Contains average price, sales volume, and index by LA
# ===========================================================================
cat("--- Fetching UK HPI (LA-level house prices) ---\n")

hpi_file <- file.path(DATA_DIR, "uk_hpi_full.csv")

if (!file.exists(hpi_file)) {
  # Try multiple date suffixes — LR updates monthly
  base <- "http://publicdata.landregistry.gov.uk/market-trend-data/house-price-index-data"
  candidates <- c(
    sprintf("%s/UK-HPI-full-file-2025-01.csv", base),
    sprintf("%s/UK-HPI-full-file-2024-12.csv", base),
    sprintf("%s/UK-HPI-full-file-2024-11.csv", base),
    sprintf("%s/UK-HPI-full-file-2024-10.csv", base),
    sprintf("%s/UK-HPI-full-file-2024-09.csv", base),
    sprintf("%s/UK-HPI-full-file-2024-06.csv", base),
    sprintf("%s/UK-HPI-full-file-2024-03.csv", base)
  )
  downloaded <- FALSE
  for (u in candidates) {
    cat(sprintf("  Trying: %s\n", basename(u)))
    res <- tryCatch({
      download.file(u, hpi_file, mode = "wb", quiet = TRUE)
      TRUE
    }, error = function(e) FALSE, warning = function(w) FALSE)
    if (res && file.exists(hpi_file) && file.size(hpi_file) > 1000) {
      cat(sprintf("  SUCCESS: %s (%s bytes)\n", basename(u),
                  format(file.size(hpi_file), big.mark = ",")))
      downloaded <- TRUE
      break
    }
  }
  if (!downloaded) stop("FATAL: Could not download UK HPI data from any URL.")
} else {
  cat(sprintf("  UK HPI already exists (%s bytes)\n",
              format(file.size(hpi_file), big.mark = ",")))
}

hpi <- fread(hpi_file, header = TRUE)
cat(sprintf("UK HPI: %d rows x %d cols\n", nrow(hpi), ncol(hpi)))
cat("Columns (first 15):", paste(head(names(hpi), 15), collapse = ", "), "\n")
cat(sprintf("Date range: %s to %s\n",
            min(hpi$Date, na.rm = TRUE), max(hpi$Date, na.rm = TRUE)))

# Check for key columns
required_cols <- c("Date", "AreaCode", "RegionName", "AveragePrice", "SalesVolume")
present <- required_cols %in% names(hpi)
cat("Required columns present:", paste(required_cols, ifelse(present, "YES", "NO"),
                                       sep = "=", collapse = ", "), "\n")
stopifnot("Missing required columns in UK HPI" = all(present))

# ===========================================================================
# 2. Land Registry Price Paid Data (PPD) — 2010-2024
#    Transaction-level data for bunching and volume analysis
# ===========================================================================
cat("\n--- Fetching Land Registry PPD (2010-2024) ---\n")

ppd_dir <- file.path(DATA_DIR, "ppd")
dir.create(ppd_dir, showWarnings = FALSE)

years <- 2010:2024
for (yr in years) {
  ppd_file <- file.path(ppd_dir, sprintf("pp-%d.csv", yr))
  if (!file.exists(ppd_file)) {
    url <- sprintf(
      "http://prod.publicdata.landregistry.gov.uk.s3-website-eu-west-1.amazonaws.com/pp-%d.csv",
      yr
    )
    cat(sprintf("  Downloading PPD %d... ", yr))
    tryCatch({
      download.file(url, ppd_file, mode = "wb", quiet = TRUE)
      cat(sprintf("OK (%s bytes)\n", format(file.size(ppd_file), big.mark = ",")))
    }, error = function(e) {
      stop(sprintf("FATAL: Could not download PPD for %d: %s", yr, e$message))
    })
  } else {
    cat(sprintf("  PPD %d: cached (%s bytes)\n", yr,
                format(file.size(ppd_file), big.mark = ",")))
  }
}

# ===========================================================================
# 3. Validate downloaded data
# ===========================================================================
cat("\n=== DATA VALIDATION ===\n")

# Validate HPI
stopifnot("HPI has data" = nrow(hpi) > 10000)
n_las <- length(unique(hpi$AreaCode[grepl("^E0[6-9]|^W06", hpi$AreaCode)]))
cat(sprintf("HPI: %d unique LA codes (E06/E07/E08/E09/W06)\n", n_las))

# Validate PPD
ppd_files <- list.files(ppd_dir, pattern = "pp-20.*\\.csv$", full.names = TRUE)
stopifnot("PPD files exist" = length(ppd_files) >= 10)
cat(sprintf("PPD: %d yearly files\n", length(ppd_files)))

# Quick check one PPD file
test_ppd <- fread(ppd_files[1], nrows = 5, header = FALSE)
cat(sprintf("PPD columns: %d (expected 16)\n", ncol(test_ppd)))

# Save HPI path info for downstream scripts
cat("\n=== DATA FETCH COMPLETE ===\n")
cat(sprintf("HPI: %s\nPPD dir: %s\n", hpi_file, ppd_dir))
