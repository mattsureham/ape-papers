# 01_fetch_data.R — Download HM Land Registry Price Paid Data
# apep_0712: UK Ground Rent Abolition
#
# Source: HM Land Registry Price Paid Data (bulk CSV)
# URL: http://prod.publicdata.landregistry.gov.uk.s3-website-eu-west-1.amazonaws.com/pp-complete.csv
# License: Open Government Licence v3.0

source("00_packages.R")

data_dir <- "../data"

# --- Download Land Registry PPD ---
# The complete file is ~4GB. We download yearly files for 2020-2024.
# Yearly files: pp-YYYY.csv

years <- 2020:2024
ppd_files <- character(0)

for (yr in years) {
  url <- sprintf(
    "http://prod.publicdata.landregistry.gov.uk.s3-website-eu-west-1.amazonaws.com/pp-%d.csv",
    yr
  )
  dest <- file.path(data_dir, sprintf("pp-%d.csv", yr))

  if (!file.exists(dest)) {
    cat(sprintf("Downloading PPD for %d...\n", yr))
    result <- tryCatch(
      download.file(url, dest, mode = "wb", quiet = FALSE),
      error = function(e) {
        # Try alternative URL format
        url2 <- sprintf(
          "http://prod.publicdata.landregistry.gov.uk.s3-website-eu-west-1.amazonaws.com/pp-%d.csv",
          yr
        )
        download.file(url2, dest, mode = "wb", quiet = FALSE)
      }
    )
  } else {
    cat(sprintf("PPD for %d already exists, skipping download.\n", yr))
  }
  ppd_files <- c(ppd_files, dest)
}

# --- Read and combine ---
# PPD columns (no header in bulk files):
# 1. Transaction unique identifier
# 2. Price
# 3. Date of Transfer
# 4. Postcode
# 5. Property Type (D=Detached, S=Semi, T=Terraced, F=Flat)
# 6. Old/New (Y=New build, N=Existing)
# 7. Duration (F=Freehold, L=Leasehold)
# 8. PAON (primary address)
# 9. SAON (secondary address)
# 10. Street
# 11. Locality
# 12. Town/City
# 13. District
# 14. County
# 15. PPD Category (A=Standard, B=Additional price paid)
# 16. Record Status (A=Addition, C=Change, D=Delete)

col_names <- c(
  "txn_id", "price", "date_transfer", "postcode",
  "property_type", "new_build", "duration",
  "paon", "saon", "street", "locality",
  "town", "district", "county",
  "ppd_category", "record_status"
)

col_types <- c(
  "character", "numeric", "character", "character",
  "character", "character", "character",
  "character", "character", "character", "character",
  "character", "character", "character",
  "character", "character"
)

cat("Reading PPD files...\n")
ppd_list <- lapply(ppd_files, function(f) {
  cat(sprintf("  Reading %s...\n", basename(f)))
  dt <- fread(f, header = FALSE, col.names = col_names,
              colClasses = col_types, quote = "\"")
  dt
})

ppd <- rbindlist(ppd_list)
cat(sprintf("Total records: %s\n", format(nrow(ppd), big.mark = ",")))

# --- Parse dates ---
ppd[, date_transfer := as.Date(date_transfer, format = "%Y-%m-%d %H:%M")]

# --- Basic validation ---
stopifnot("No records loaded" = nrow(ppd) > 0)
stopifnot("Missing dates" = sum(is.na(ppd$date_transfer)) / nrow(ppd) < 0.01)
stopifnot("Missing prices" = sum(is.na(ppd$price)) / nrow(ppd) < 0.01)

cat(sprintf("Date range: %s to %s\n", min(ppd$date_transfer, na.rm = TRUE),
            max(ppd$date_transfer, na.rm = TRUE)))
cat(sprintf("Property types: %s\n",
            paste(names(table(ppd$property_type)), collapse = ", ")))
cat(sprintf("New builds: %s\n",
            paste(names(table(ppd$new_build)), collapse = ", ")))
cat(sprintf("Duration: %s\n",
            paste(names(table(ppd$duration)), collapse = ", ")))

# --- Save raw combined data ---
saveRDS(ppd, file.path(data_dir, "ppd_2020_2024.rds"))
cat("Saved ppd_2020_2024.rds\n")
