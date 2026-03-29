## 01_fetch_data.R — Download BTS DB1B Market data
## APEP-1112: The Alliance Ratchet
##
## Downloads quarterly DB1B Market data from BTS Transtats (10% ticket sample).
## Period: Q1 2018 – Q4 2024 (28 quarters)
## Filters to routes involving NEA airports (JFK, LGA, BOS, EWR) to keep size manageable.

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ---- Configuration ----
years <- 2018:2024
quarters <- 1:4
nea_airports <- c("JFK", "LGA", "BOS", "EWR")

## ---- Download function ----
## BTS provides DB1B Market data as zipped CSVs via PREZIP
## Uses system curl for reliability with large files
download_db1b_quarter <- function(year, quarter, destdir) {
  fname <- sprintf("Origin_and_Destination_Survey_DB1BMarket_%d_%d.zip", year, quarter)
  url <- sprintf("https://transtats.bts.gov/PREZIP/%s", fname)
  outfile <- file.path(destdir, fname)

  ## Check if already downloaded AND valid
  if (file.exists(outfile)) {
    valid <- tryCatch({
      length(unzip(outfile, list = TRUE)$Name) > 0
    }, error = function(e) FALSE)
    if (valid) {
      cat(sprintf("  Already downloaded: %s\n", fname))
      return(outfile)
    } else {
      cat(sprintf("  Removing corrupt file: %s\n", fname))
      file.remove(outfile)
    }
  }

  cat(sprintf("  Downloading: %s ... ", fname))
  ret <- system2("curl", args = c(
    "-sS", "-o", outfile,
    "--connect-timeout", "60",
    "--max-time", "600",
    url
  ))

  if (ret != 0 || !file.exists(outfile)) {
    if (file.exists(outfile)) file.remove(outfile)
    stop(sprintf("Failed to download %s from %s", fname, url))
  }

  ## Validate zip
  valid <- tryCatch({
    length(unzip(outfile, list = TRUE)$Name) > 0
  }, error = function(e) FALSE)
  if (!valid) {
    file.remove(outfile)
    stop(sprintf("Downloaded file %s is corrupt", fname))
  }

  cat("OK\n")
  return(outfile)
}

## ---- Read and filter function ----
## Read a quarterly zip, filter to routes involving NEA airports, return data.table
read_db1b_quarter <- function(zipfile, year, quarter) {
  cat(sprintf("  Reading %d Q%d ... ", year, quarter))

  ## List files in zip to find the CSV
  csv_names <- unzip(zipfile, list = TRUE)$Name
  csv_name <- csv_names[grepl("\\.csv$", csv_names, ignore.case = TRUE)]
  if (length(csv_name) == 0) stop("No CSV found in ", zipfile)
  csv_name <- csv_name[1]

  ## Extract to temp dir and read
  tmpdir <- tempdir()
  unzip(zipfile, files = csv_name, exdir = tmpdir, overwrite = TRUE)
  csvpath <- file.path(tmpdir, csv_name)

  dt <- fread(csvpath, select = c(
    "Year", "Quarter", "Origin", "Dest",
    "OpCarrier", "TkCarrier", "RPCarrier",
    "MktFare", "Passengers", "MktMilesFlown",
    "MktCoupons", "BulkFare"
  ))

  ## Remove temp file
  file.remove(csvpath)

  ## Filter: at least one endpoint is an NEA airport
  dt <- dt[Origin %in% nea_airports | Dest %in% nea_airports]

  ## Remove bulk fares and zero/negative fares
  dt <- dt[BulkFare == 0 & MktFare > 0 & Passengers > 0]

  ## Drop extreme fares (< $20 or > $5000 — likely errors)
  dt <- dt[MktFare >= 20 & MktFare <= 5000]

  cat(sprintf("%s rows\n", format(nrow(dt), big.mark = ",")))
  return(dt)
}

## ---- Main download and processing loop ----
cat("=== Downloading BTS DB1B Market Data ===\n")
cat(sprintf("Period: Q1 %d – Q4 %d\n", min(years), max(years)))
cat(sprintf("Filtering to routes with: %s\n\n", paste(nea_airports, collapse = ", ")))

all_data <- list()
idx <- 0

for (yr in years) {
  max_q <- ifelse(yr == max(years), 4, 4)
  for (q in 1:max_q) {
    idx <- idx + 1

    ## Try download
    zipfile <- tryCatch(
      download_db1b_quarter(yr, q, data_dir),
      error = function(e) {
        cat(sprintf("  SKIPPING %d Q%d: %s\n", yr, q, e$message))
        return(NULL)
      }
    )

    if (is.null(zipfile)) next

    ## Read and filter
    dt <- tryCatch(
      read_db1b_quarter(zipfile, yr, q),
      error = function(e) {
        cat(sprintf("  ERROR reading %d Q%d: %s\n", yr, q, e$message))
        return(NULL)
      }
    )

    if (!is.null(dt) && nrow(dt) > 0) {
      all_data[[idx]] <- dt
    }
  }
}

## ---- Combine ----
if (length(all_data) == 0) {
  stop("FATAL: No data downloaded. Cannot proceed without real data.")
}

db1b <- rbindlist(all_data, use.names = TRUE, fill = TRUE)
cat(sprintf("\n=== Combined dataset: %s rows ===\n", format(nrow(db1b), big.mark = ",")))

## ---- Validate ----
stopifnot("No data loaded" = nrow(db1b) > 0)
stopifnot("Missing Year" = all(!is.na(db1b$Year)))
stopifnot("Missing Quarter" = all(!is.na(db1b$Quarter)))
stopifnot("Missing fares" = all(!is.na(db1b$MktFare)))

## Check quarter coverage
coverage <- db1b[, .N, by = .(Year, Quarter)][order(Year, Quarter)]
cat("\nQuarter coverage:\n")
print(coverage)

n_quarters <- nrow(coverage)
cat(sprintf("\nTotal quarters with data: %d\n", n_quarters))

if (n_quarters < 20) {
  warning("Fewer than 20 quarters available. Check download errors above.")
}

## ---- Save ----
outfile <- file.path(data_dir, "db1b_nea_airports.rds")
saveRDS(db1b, outfile)
cat(sprintf("\nSaved filtered data to: %s (%s MB)\n",
            outfile, round(file.size(outfile) / 1e6, 1)))

cat("\n=== Data fetch complete ===\n")
