## ============================================================
## 01_fetch_data.R — Fetch Land Registry PPD + EA flood risk data
## apep_0522: Flood Re and English Property Values
## ============================================================

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## -------------------------------------------------------
## 1. Land Registry Price Paid Data (year-by-year download)
## -------------------------------------------------------

lr_cols <- c(
  "transaction_id", "price", "date_of_transfer", "postcode",
  "property_type", "old_new", "duration", "paon", "saon",
  "street", "locality", "town_city", "district", "county",
  "ppd_category", "record_status"
)

keep_cols <- c("transaction_id", "price", "date_of_transfer",
               "postcode", "property_type", "old_new", "duration",
               "town_city", "district", "county", "ppd_category")

years <- 2010:2025
lr_file <- file.path(data_dir, "land_registry_panel.csv")

if (!file.exists(lr_file)) {
  cat("Downloading Land Registry PPD by year...\n")

  # Download each year to a separate file (preserves progress)
  for (yr in years) {
    yr_file <- file.path(data_dir, sprintf("lr_%d.csv", yr))
    if (file.exists(yr_file)) {
      cat(sprintf("  %d: already downloaded\n", yr))
      next
    }
    url <- sprintf(
      "https://price-paid-data.publicdata.landregistry.gov.uk/pp-%d.csv", yr
    )
    tmp <- tempfile(fileext = ".csv")
    cat(sprintf("  Downloading %d...\n", yr))
    tryCatch({
      download.file(url, tmp, mode = "wb", quiet = TRUE)
      dt <- fread(tmp, header = FALSE, na.strings = "")
      if (ncol(dt) == 16) {
        setnames(dt, lr_cols)
      } else if (ncol(dt) == 15) {
        setnames(dt, lr_cols[1:15])
      }
      dt <- dt[, ..keep_cols]
      dt[, year := yr]
      fwrite(dt, yr_file)
      cat(sprintf("    %d: %s rows\n", yr, format(nrow(dt), big.mark = ",")))
    }, error = function(e) {
      if (yr <= 2024) {
        stop(sprintf("Failed to download Land Registry data for %d: %s\n",
                      yr, e$message),
             "\nPivot research question or fix the source.")
      } else {
        cat(sprintf("    %d: Not yet available (skipping)\n", yr))
      }
    })
    unlink(tmp)
  }

  # Combine all yearly files
  cat("Combining yearly files...\n")
  yr_files <- list.files(data_dir, pattern = "^lr_20[0-9]{2}\\.csv$",
                          full.names = TRUE)
  all_lr <- lapply(yr_files, fread)
  lr <- rbindlist(all_lr, fill = TRUE)
  cat(sprintf("Total Land Registry records: %s\n",
              format(nrow(lr), big.mark = ",")))

  # Clean postcodes
  lr[, postcode_clean := str_trim(postcode)]

  # Filter to England only using postcode prefix patterns
  welsh_prefixes <- c("^CF", "^LD", "^LL", "^NP", "^SA")
  scottish_prefixes <- c("^AB", "^DD", "^DG", "^EH", "^FK", "^G[0-9]",
                          "^HS", "^IV", "^KA", "^KW", "^KY", "^ML",
                          "^PA", "^PH", "^TD", "^ZE")
  ni_prefixes <- c("^BT")

  non_england <- paste(c(welsh_prefixes, scottish_prefixes, ni_prefixes),
                        collapse = "|")
  lr <- lr[!grepl(non_england, postcode_clean)]

  # Also remove SY postcodes where county is a Welsh county
  lr <- lr[!(grepl("^SY", postcode_clean) &
              county %in% c("POWYS", "CEREDIGION", "Powys", "Ceredigion"))]

  cat(sprintf("After England filter: %s rows\n",
              format(nrow(lr), big.mark = ",")))

  # Clean and filter
  lr[, date_of_transfer := as.Date(date_of_transfer)]

  # Filter: standard transactions only (PPD Category A),
  # exclude zero/extreme prices
  lr <- lr[ppd_category == "A" & price > 10000 & price < 50000000]

  # Extract postcode sector (e.g., "SW1A 1" from "SW1A 1AA")
  lr[, postcode_sector := str_extract(postcode_clean,
                                       "^[A-Z]{1,2}[0-9][0-9A-Z]?\\s?[0-9]")]

  fwrite(lr, lr_file)
  cat(sprintf("Saved: %s (%s rows)\n", lr_file,
              format(nrow(lr), big.mark = ",")))

  # Clean up yearly files
  for (f in yr_files) unlink(f)
  cat("Cleaned up yearly files.\n")
} else {
  cat("Land Registry data already exists, loading...\n")
  lr <- fread(lr_file)
  cat(sprintf("Loaded: %s rows\n", format(nrow(lr), big.mark = ",")))
}

## -------------------------------------------------------
## 2. EA Flood Risk by Postcode
## -------------------------------------------------------

flood_file <- file.path(data_dir, "flood_risk_postcodes.csv")

if (!file.exists(flood_file)) {
  cat("Downloading EA flood risk postcode data...\n")

  flood_url <- paste0(
    "https://environment.data.gov.uk/api/file/download?",
    "fileDataSetId=97781741-2982-4802-af2e-313fe3fd8f7e&",
    "fileName=RoFRS_Postcodes_in_Areas_at_Risk.zip"
  )

  zip_tmp <- tempfile(fileext = ".zip")
  tryCatch({
    download.file(flood_url, zip_tmp, mode = "wb", quiet = TRUE)
    unzip_dir <- tempdir()
    unzip(zip_tmp, exdir = unzip_dir)
    csv_files <- list.files(unzip_dir, pattern = "\\.csv$",
                            recursive = TRUE, full.names = TRUE)
    if (length(csv_files) == 0) {
      stop("No CSV found in flood risk ZIP file")
    }
    flood <- fread(csv_files[1])
    fwrite(flood, flood_file)
    cat(sprintf("Flood risk data: %s rows\n",
                format(nrow(flood), big.mark = ",")))
  }, error = function(e) {
    stop("Failed to download flood risk data: ", e$message,
         "\nPivot research question or fix the source.")
  })
  unlink(zip_tmp)
} else {
  cat("Flood risk data already exists, loading...\n")
  flood <- fread(flood_file)
  cat(sprintf("Loaded: %s rows\n", format(nrow(flood), big.mark = ",")))
}

cat("Flood risk columns:", paste(names(flood), collapse = ", "), "\n")

## -------------------------------------------------------
## 3. Data Validation
## -------------------------------------------------------

stopifnot("Expected 100K+ Land Registry records" = nrow(lr) > 100000)
n_years <- uniqueN(lr$year)
n_districts <- uniqueN(lr$district)
cat(sprintf("Land Registry: %s rows, %d years, %d districts\n",
            format(nrow(lr), big.mark = ","), n_years, n_districts))

stopifnot("Expected flood risk postcodes" = nrow(flood) > 1000)
cat(sprintf("Flood risk: %s rows\n",
            format(nrow(flood), big.mark = ",")))

cat("\n=== DATA FETCH COMPLETE ===\n")
