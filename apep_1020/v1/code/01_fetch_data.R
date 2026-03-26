# 01_fetch_data.R — Download Land Registry Price Paid Data
# apep_1020/v1

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# Download annual Land Registry PPD CSVs (2023, 2024, 2025)
base_url <- "http://prod.publicdata.landregistry.gov.uk.s3-website-eu-west-1.amazonaws.com"

years <- c(2023, 2024, 2025)

ppd_cols <- c(
  "txn_id", "price", "date_transfer", "postcode", "property_type",
  "old_new", "duration", "paon", "saon", "street", "locality",
  "town", "district", "county", "ppd_cat", "record_status"
)

all_data <- list()

for (yr in years) {
  fname <- paste0("pp-", yr, ".csv")
  fpath <- file.path(data_dir, fname)

  if (!file.exists(fpath)) {
    url <- paste0(base_url, "/", fname)
    cat("Downloading", url, "...\n")
    dl_result <- tryCatch(
      {
        curl::curl_download(url, fpath, quiet = FALSE)
        TRUE
      },
      error = function(e) {
        cat("ERROR downloading", yr, ":", conditionMessage(e), "\n")
        FALSE
      }
    )
    if (!dl_result) {
      stop("FATAL: Cannot download Land Registry data for ", yr,
           ". Cannot proceed without real data.")
    }
  } else {
    cat("File exists:", fpath, "\n")
  }

  cat("Reading", fname, "...\n")
  dt <- fread(fpath, header = FALSE,
              select = c(2, 3, 4, 5, 6, 7, 15))
  names(dt) <- c("price", "date_transfer", "postcode", "property_type",
                  "old_new", "duration", "ppd_cat")

  # Parse date
  dt[, date_transfer := as.Date(date_transfer)]
  dt[, year := year(date_transfer)]
  dt[, month := month(date_transfer)]
  dt[, ym := as.integer(year * 100 + month)]

  # Keep only standard price paid (Category A) and positive prices
  dt <- dt[ppd_cat == "A" & price > 0]

  # Extract country from postcode prefix for England/Scotland/Wales filtering
  # Scottish postcodes: AB, DD, DG, EH, FK, G, HS, IV, KA, KW, KY, ML, PA, PH, TD, ZE
  # Welsh postcodes: CF, LD, LL, NP, SA, SY (partial)
  # Note: Land Registry PPD covers England & Wales only (not Scotland)
  # So we only need to separate England from Wales
  dt[, pc_area := str_extract(postcode, "^[A-Z]{1,2}")]

  welsh_areas <- c("CF", "LD", "LL", "NP", "SA")
  dt[, country := fifelse(pc_area %in% welsh_areas, "Wales", "England")]
  # SY postcodes span England/Wales border — conservatively keep as England
  # (Shropshire is mostly English; Powys is Welsh but tiny share)

  all_data[[as.character(yr)]] <- dt
  cat("  Loaded", nrow(dt), "Category A transactions for", yr, "\n")
}

ppd <- rbindlist(all_data)
cat("\nTotal transactions:", nrow(ppd), "\n")
cat("Date range:", as.character(min(ppd$date_transfer)), "to",
    as.character(max(ppd$date_transfer)), "\n")
cat("By country:\n")
print(ppd[, .N, by = country])

# Save combined dataset
fwrite(ppd, file.path(data_dir, "ppd_combined.csv"))
cat("\nSaved combined dataset to ppd_combined.csv\n")

# Validate: must have data spanning both regimes
stopifnot("No pre-reversion data" = any(ppd$date_transfer < as.Date("2025-04-01")))
stopifnot("No post-reversion data" = any(ppd$date_transfer >= as.Date("2025-05-01")))
cat("Data validation passed: both pre- and post-reversion periods present.\n")
