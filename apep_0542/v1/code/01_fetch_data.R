# ==============================================================================
# 01_fetch_data.R — Download Land Registry PPD and NSPL postcode lookup
# Paper: When the Train Doesn't Come (apep_0542)
# ==============================================================================

source("code/00_packages.R")

# ------------------------------------------------------------------------------
# 1) Download Land Registry Price Paid Data (2019-2024)
# ------------------------------------------------------------------------------

lr_base <- "http://prod.publicdata.landregistry.gov.uk.s3-website-eu-west-1.amazonaws.com"
years <- 2019:2024

for (yr in years) {
  outfile <- file.path(DATA_DIR, paste0("pp-", yr, ".csv"))
  if (file.exists(outfile)) {
    cat("Already have:", outfile, "\n")
    next
  }
  url <- paste0(lr_base, "/pp-", yr, ".csv")
  cat("Downloading Land Registry", yr, "...\n")
  tryCatch({
    download.file(url, outfile, mode = "wb", quiet = TRUE)
    cat("  Saved:", outfile, "(", round(file.size(outfile) / 1e6, 1), "MB)\n")
  }, error = function(e) {
    stop("Land Registry download failed for ", yr, ": ", e$message,
         "\nPivot research question or fix the source.")
  })
}

# Read and combine (select key columns only)
cat("Reading Land Registry files...\n")
lr_list <- lapply(years, function(yr) {
  f <- file.path(DATA_DIR, paste0("pp-", yr, ".csv"))
  dt <- fread(f, header = FALSE,
              select = c(1:7, 14, 15),
              quote = "\"")
  setnames(dt, c("txn_id", "price", "date", "postcode", "property_type",
                  "old_new", "tenure", "county", "ppd_cat"))
  dt[, year := yr]
  dt
})
lr <- rbindlist(lr_list)

# Parse date
lr[, date := as.Date(date)]
lr[, year_quarter := paste0(year(date), "-Q", quarter(date))]

# Clean postcode
lr[, postcode_clean := toupper(gsub("\\s+", "", postcode))]

cat("Land Registry loaded:", nrow(lr), "transactions,",
    uniqueN(lr$postcode_clean), "postcodes\n")

# ------------------------------------------------------------------------------
# 2) Download ONS NSPL (postcode to coordinates + LSOA + LA)
# ------------------------------------------------------------------------------

nspl_file <- file.path(DATA_DIR, "nspl_lookup.csv")

if (!file.exists(nspl_file)) {
  cat("Downloading NSPL postcode lookup from ONS...\n")

  # NSPL is available as a large zip from ONS Geoportal
  # Use a direct download URL for the data CSV
  nspl_url <- "https://www.arcgis.com/sharing/rest/content/items/6e5301d116f942b1b7e132e4b80b8c52/data"
  nspl_zip <- file.path(DATA_DIR, "nspl.zip")

  tryCatch({
    download.file(nspl_url, nspl_zip, mode = "wb", quiet = TRUE)
    cat("  Downloaded NSPL zip:", round(file.size(nspl_zip) / 1e6, 1), "MB\n")

    # List contents and find the main data file
    zip_contents <- unzip(nspl_zip, list = TRUE)
    data_file <- zip_contents$Name[grepl("NSPL.*\\.csv$", zip_contents$Name) &
                                     !grepl("Column", zip_contents$Name)]
    if (length(data_file) == 0) {
      data_file <- zip_contents$Name[grepl("\\.csv$", zip_contents$Name) &
                                       grepl("Data", zip_contents$Name)]
    }
    cat("  Extracting:", data_file[1], "\n")
    unzip(nspl_zip, files = data_file[1], exdir = DATA_DIR, junkpaths = TRUE)

    # Find the extracted CSV
    csv_files <- list.files(DATA_DIR, pattern = "NSPL.*\\.csv$|nspl.*\\.csv$",
                            full.names = TRUE)
    if (length(csv_files) > 0) {
      file.rename(csv_files[1], nspl_file)
    }
    unlink(nspl_zip)
  }, error = function(e) {
    cat("NSPL download failed:", e$message, "\n")
    cat("Falling back to postcodes.io for targeted geocoding...\n")
  })
}

# If NSPL download worked, use it
if (file.exists(nspl_file)) {
  cat("Reading NSPL lookup...\n")
  nspl <- fread(nspl_file, select = c("pcds", "lat", "long", "lsoa11", "lsoa21",
                                        "oslaua", "osward", "rgn"),
                na.strings = "")
  setnames(nspl, c("pcds", "lat", "long", "lsoa11", "lsoa21", "oslaua", "osward", "rgn"),
           c("postcode_raw", "lat", "lng", "lsoa_2011", "lsoa_2021",
             "la_code", "ward_code", "region_code"))
  nspl[, postcode_clean := toupper(gsub("\\s+", "", postcode_raw))]
  nspl <- nspl[!is.na(lat) & !is.na(lng)]
  cat("NSPL loaded:", nrow(nspl), "postcodes with coordinates\n")

  # Merge
  lr <- merge(lr, nspl[, .(postcode_clean, lat, lng, lsoa_2011, la_code, region_code)],
              by = "postcode_clean", all.x = TRUE)
} else {
  # Fallback: geocode only postcodes near HS2 stations
  # Filter by county first to reduce volume
  hs2_counties <- c("GREATER MANCHESTER", "WEST YORKSHIRE", "SOUTH YORKSHIRE",
                     "DERBYSHIRE", "NOTTINGHAMSHIRE", "STAFFORDSHIRE",
                     "CHESHIRE", "CHESHIRE EAST", "CHESHIRE WEST AND CHESTER",
                     "WEST MIDLANDS", "WARWICKSHIRE", "BUCKINGHAMSHIRE",
                     "HERTFORDSHIRE", "GREATER LONDON", "SURREY")
  lr_near <- lr[toupper(county) %in% hs2_counties]
  unique_pcs <- unique(lr_near$postcode_clean)
  cat("Geocoding", length(unique_pcs), "postcodes near HS2 corridor...\n")

  format_pc <- function(pc) {
    n <- nchar(pc)
    if (n >= 5) paste0(substr(pc, 1, n - 3), " ", substr(pc, n - 2, n))
    else pc
  }

  batches <- split(unique_pcs, ceiling(seq_along(unique_pcs) / 100))
  results <- list()

  for (i in seq_along(batches)) {
    if (i %% 100 == 0) cat("  Batch", i, "/", length(batches), "\n")
    batch_formatted <- sapply(batches[[i]], format_pc)
    resp <- tryCatch({
      req <- request("https://api.postcodes.io/postcodes") |>
        req_body_json(list(postcodes = as.list(batch_formatted))) |>
        req_timeout(30)
      resp <- req_perform(req)
      resp_body_json(resp)
    }, error = function(e) { Sys.sleep(1); NULL })

    if (!is.null(resp) && !is.null(resp$result)) {
      for (r in resp$result) {
        if (!is.null(r$result)) {
          results[[length(results) + 1]] <- data.table(
            postcode_clean = gsub("\\s+", "", r$query),
            lat = r$result$latitude,
            lng = r$result$longitude,
            lsoa_2011 = r$result$codes$lsoa %||% NA_character_,
            la_code = r$result$codes$admin_district %||% NA_character_,
            region_code = r$result$region %||% NA_character_
          )
        }
      }
    }
    if (i %% 10 == 0) Sys.sleep(0.3)
  }

  if (length(results) > 0) {
    pc_geo <- rbindlist(results)
    fwrite(pc_geo, file.path(DATA_DIR, "postcode_geocodes.csv"))
    lr <- merge(lr, pc_geo, by = "postcode_clean", all.x = TRUE)
  }
}

geocoded_pct <- round(100 * mean(!is.na(lr$lat)), 1)
cat("Geocoding coverage:", geocoded_pct, "%\n")

# ------------------------------------------------------------------------------
# 3) Define HS2 station coordinates
# ------------------------------------------------------------------------------

phase2_stations <- data.table(
  station = c("Manchester Piccadilly HS2", "Manchester Airport HS2",
              "Crewe HS2 Hub", "East Midlands Hub (Toton)",
              "Meadowhall (Sheffield)", "Leeds HS2"),
  lat = c(53.4774, 53.3588, 53.0880, 52.9227, 53.4190, 53.7957),
  lng = c(-2.2309, -2.2750, -2.4340, -1.2573, -1.4107, -1.5484),
  phase = "Phase2_cancelled"
)

phase1_stations <- data.table(
  station = c("London Euston HS2", "Old Oak Common", "Birmingham Interchange",
              "Birmingham Curzon Street"),
  lat = c(51.5282, 51.5250, 52.4503, 52.4784),
  lng = c(-0.1337, -0.2437, -1.7302, -1.8879),
  phase = "Phase1_continuing"
)

all_stations <- rbind(phase2_stations, phase1_stations)
fwrite(all_stations, file.path(DATA_DIR, "hs2_stations.csv"))
cat("Saved", nrow(all_stations), "HS2 station coordinates\n")

# Save raw merged data
fwrite(lr, file.path(DATA_DIR, "lr_raw_geocoded.csv"))
cat("Saved lr_raw_geocoded.csv:", nrow(lr), "rows\n")

# === DATA VALIDATION (required) ===
stopifnot("Expected 6 years of data" = uniqueN(lr$year) == 6)
stopifnot("Expected 100K+ transactions" = nrow(lr) > 100000)
stopifnot("Expected geocoding > 50%" = geocoded_pct > 50)
cat("Data validation passed:", nrow(lr), "transactions,",
    uniqueN(lr$postcode_clean), "postcodes,",
    uniqueN(lr$year), "years,",
    geocoded_pct, "% geocoded\n")
