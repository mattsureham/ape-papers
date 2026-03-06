# ==============================================================================
# 01b_geocode.R — Geocode postcodes and merge with Land Registry data
# Paper: When the Train Doesn't Come (apep_0542)
# ==============================================================================

source("code/00_packages.R")

# Load raw LR data (already downloaded)
cat("Reading Land Registry files...\n")
years <- 2019:2024
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
lr[, date := as.Date(date)]
lr[, postcode_clean := toupper(gsub("\\s+", "", postcode))]
cat("Loaded:", nrow(lr), "transactions\n")

# Filter to HS2-corridor counties FIRST (much smaller set)
hs2_counties <- c("GREATER MANCHESTER", "WEST YORKSHIRE", "SOUTH YORKSHIRE",
                   "DERBYSHIRE", "NOTTINGHAMSHIRE", "STAFFORDSHIRE",
                   "CHESHIRE", "CHESHIRE EAST", "CHESHIRE WEST AND CHESTER",
                   "WEST MIDLANDS", "WARWICKSHIRE", "BUCKINGHAMSHIRE",
                   "HERTFORDSHIRE", "GREATER LONDON", "SURREY",
                   "LANCASHIRE", "MERSEYSIDE", "OXFORDSHIRE",
                   "NORTHAMPTONSHIRE", "LEICESTERSHIRE", "EAST RIDING OF YORKSHIRE",
                   "CITY OF BRISTOL", "BEDFORDSHIRE")
lr_corridor <- lr[toupper(county) %in% hs2_counties]
cat("Corridor counties:", nrow(lr_corridor), "transactions\n")

# Get unique postcodes to geocode
unique_pcs <- unique(lr_corridor$postcode_clean)
cat("Unique postcodes to geocode:", length(unique_pcs), "\n")

# Check if we have cached geocodes
geocode_file <- file.path(DATA_DIR, "postcode_geocodes.csv")
if (file.exists(geocode_file)) {
  pc_geo <- fread(geocode_file)
  if (nrow(pc_geo) > 0 && "lat" %in% names(pc_geo)) {
    cat("Loaded cached geocodes:", nrow(pc_geo), "\n")
    missing_pcs <- setdiff(unique_pcs, pc_geo$postcode_clean)
    cat("Missing:", length(missing_pcs), "\n")
  } else {
    pc_geo <- data.table()
    missing_pcs <- unique_pcs
  }
} else {
  pc_geo <- data.table()
  missing_pcs <- unique_pcs
}

# Geocode missing postcodes via postcodes.io
if (length(missing_pcs) > 0) {
  cat("Geocoding", length(missing_pcs), "postcodes...\n")

  format_pc <- function(pc) {
    n <- nchar(pc)
    if (n >= 5) paste0(substr(pc, 1, n - 3), " ", substr(pc, n - 2, n))
    else pc
  }

  batches <- split(missing_pcs, ceiling(seq_along(missing_pcs) / 100))
  results <- list()

  for (i in seq_along(batches)) {
    if (i %% 100 == 0) cat("  Batch", i, "/", length(batches), "\n")

    batch_formatted <- sapply(batches[[i]], format_pc, USE.NAMES = FALSE)

    resp <- tryCatch({
      req <- request("https://api.postcodes.io/postcodes") |>
        req_body_json(list(postcodes = as.list(batch_formatted))) |>
        req_timeout(30)
      resp <- req_perform(req)
      resp_body_json(resp)
    }, error = function(e) { Sys.sleep(1); NULL })

    if (!is.null(resp) && !is.null(resp$result)) {
      for (r in resp$result) {
        if (!is.null(r$result) && !is.null(r$result$latitude)) {
          la_code <- NA_character_
          if (!is.null(r$result$codes) && !is.null(r$result$codes$admin_district)) {
            la_code <- r$result$codes$admin_district
          }
          region <- NA_character_
          if (!is.null(r$result$region)) {
            region <- r$result$region
          }
          results[[length(results) + 1]] <- list(
            postcode_clean = gsub("\\s+", "", toupper(r$query)),
            lat = r$result$latitude,
            lng = r$result$longitude,
            la_code = la_code,
            region = region
          )
        }
      }
    }

    if (i %% 15 == 0) Sys.sleep(0.2)
  }

  if (length(results) > 0) {
    new_geo <- rbindlist(results)
    cat("Geocoded:", nrow(new_geo), "postcodes\n")
    pc_geo <- rbind(pc_geo, new_geo, fill = TRUE)
    fwrite(pc_geo, geocode_file)
    cat("Saved to:", geocode_file, "\n")
  }
}

cat("Total geocoded postcodes:", nrow(pc_geo), "\n")

# Merge geocodes with corridor transactions
lr_corridor <- merge(lr_corridor, pc_geo[, .(postcode_clean, lat, lng, la_code, region)],
                      by = "postcode_clean", all.x = TRUE)
geocoded_pct <- round(100 * mean(!is.na(lr_corridor$lat)), 1)
cat("Geocoding coverage in corridor:", geocoded_pct, "%\n")

# Drop non-geocoded
lr_corridor <- lr_corridor[!is.na(lat) & !is.na(lng)]
cat("After dropping non-geocoded:", nrow(lr_corridor), "\n")

# Add year-quarter
lr_corridor[, year_quarter := paste0(year(date), "-Q", quarter(date))]

# Define HS2 stations
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

# Save geocoded corridor data
fwrite(lr_corridor, file.path(DATA_DIR, "lr_raw_geocoded.csv"))
cat("Saved lr_raw_geocoded.csv:", nrow(lr_corridor), "rows\n")

# === DATA VALIDATION ===
stopifnot("Expected 6 years" = uniqueN(lr_corridor$year) == 6)
stopifnot("Expected 500K+ transactions" = nrow(lr_corridor) > 500000)
cat("Data validation passed:", nrow(lr_corridor), "transactions,",
    uniqueN(lr_corridor$postcode_clean), "postcodes,",
    uniqueN(lr_corridor$year), "years\n")
