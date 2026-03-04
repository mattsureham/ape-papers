## 01_fetch_data.R — Fetch Land Registry, GIAS, Ofsted, and postcode data
## apep_0495: Private School VAT and State School Housing Premium

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

cat("=== DATA ACQUISITION START ===\n")
cat("Timestamp:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")

## =========================================================================
## 1. GIAS (Get Information about Schools) — All schools in England
## =========================================================================
cat("--- Fetching GIAS school data ---\n")

gias_url <- "https://ea-edubase-api-prod.azurewebsites.net/edubase/downloads/public/edubasealldata20260303.csv"
gias_file <- file.path(data_dir, "gias_schools.csv")

tryCatch({
  download.file(gias_url, gias_file, mode = "wb", quiet = TRUE)
  cat("  GIAS downloaded:", file.info(gias_file)$size / 1e6, "MB\n")
}, error = function(e) {
  stop("GIAS download failed: ", e$message,
       "\nCannot proceed without school data. Fix the URL or source.")
})

gias <- fread(gias_file, encoding = "Latin-1")
cat("  GIAS rows:", nrow(gias), "| Columns:", ncol(gias), "\n")

## =========================================================================
## 2. Land Registry Price Paid Data (England & Wales)
## =========================================================================
cat("\n--- Fetching Land Registry Price Paid Data ---\n")

## Download yearly files from 2015 to 2025 (2026 partial may exist)
lr_base_url <- "http://prod2.publicdata.landregistry.gov.uk.s3-website-eu-west-1.amazonaws.com"
years_to_fetch <- 2015:2025

lr_files <- c()
for (yr in years_to_fetch) {
  yr_file <- file.path(data_dir, paste0("pp-", yr, ".csv"))
  if (!file.exists(yr_file)) {
    url <- paste0(lr_base_url, "/pp-", yr, ".csv")
    cat("  Downloading pp-", yr, ".csv ... ")
    tryCatch({
      download.file(url, yr_file, mode = "wb", quiet = TRUE)
      cat(round(file.info(yr_file)$size / 1e6, 1), "MB\n")
    }, error = function(e) {
      cat("FAILED:", e$message, "\n")
      if (yr <= 2024) {
        stop("Cannot download Land Registry data for ", yr,
             ". This is a required year. Fix the URL or check connectivity.")
      }
    })
  } else {
    cat("  pp-", yr, ".csv already exists (",
        round(file.info(yr_file)$size / 1e6, 1), "MB)\n")
  }
  if (file.exists(yr_file)) lr_files <- c(lr_files, yr_file)
}

## Also try 2026 partial
yr_2026_file <- file.path(data_dir, "pp-2026.csv")
if (!file.exists(yr_2026_file)) {
  tryCatch({
    download.file(paste0(lr_base_url, "/pp-2026.csv"), yr_2026_file,
                  mode = "wb", quiet = TRUE)
    cat("  pp-2026.csv downloaded:", round(file.info(yr_2026_file)$size / 1e6, 1), "MB\n")
    lr_files <- c(lr_files, yr_2026_file)
  }, error = function(e) {
    cat("  pp-2026.csv not yet available (expected).\n")
  })
}

cat("  Total Land Registry files:", length(lr_files), "\n")

## Define column names for Land Registry PPD (no header in CSV)
lr_cols <- c(
  "transaction_id", "price", "date_transfer", "postcode",
  "property_type", "old_new", "duration", "paon", "saon",
  "street", "locality", "town", "district", "county",
  "ppd_category", "record_status"
)

## Read and combine using data.table for memory efficiency
cat("  Reading and combining Land Registry files...\n")
lr_select_cols <- c("transaction_id", "price", "date_transfer", "postcode",
                     "property_type", "old_new", "duration", "county", "ppd_category")
lr_all <- rbindlist(lapply(lr_files, function(f) {
  dt <- fread(f, header = FALSE, col.names = lr_cols, encoding = "Latin-1")
  dt[, .(transaction_id, price, date_transfer, postcode,
         property_type, old_new, duration, county, ppd_category)]
}), use.names = TRUE)

cat("  Total Land Registry transactions:", format(nrow(lr_all), big.mark = ","), "\n")

## Parse dates and filter to England only (postcode present)
lr_all[, date_transfer := as.Date(date_transfer)]
lr_all[, year_month := format(date_transfer, "%Y-%m")]
lr_all[, year := year(date_transfer)]
lr_all[, month := month(date_transfer)]

## Remove records without postcodes
lr_all <- lr_all[postcode != "" & !is.na(postcode)]
cat("  After removing missing postcodes:", format(nrow(lr_all), big.mark = ","), "\n")

## Filter to standard residential transactions (Category A)
lr_all <- lr_all[ppd_category == "A"]
cat("  After filtering to Category A (standard):", format(nrow(lr_all), big.mark = ","), "\n")

## =========================================================================
## 3. Geography: LA assignment + postcode coordinates
## =========================================================================
cat("\n--- Assigning geography ---\n")

## Land Registry 'county' column is the local authority district name
## Use GIAS LA name/code crosswalk instead of API lookups
lr_all[, postcode_sector := sub("^(.+?)\\s*(\\d)\\w+$", "\\1 \\2", postcode)]
lr_all[, postcode_district := sub("^(.+?)\\s*\\d\\w+$", "\\1", postcode)]

## Helper: null-coalescing operator for older R versions
`%||%` <- function(x, y) if (is.null(x)) y else x

## Strategy: Use postcodes.io for a representative sample of unique postcode
## SECTORS (not individual postcodes — there are ~9000 sectors vs 1.1M postcodes)
unique_sectors <- unique(lr_all$postcode_sector)
cat("  Unique postcode sectors:", length(unique_sectors), "\n")

## For each sector, pick one representative postcode to geocode
sector_reps <- lr_all[, .(rep_postcode = postcode[1]), by = postcode_sector]
cat("  Representative postcodes to look up:", nrow(sector_reps), "\n")

## Batch lookup function via postcodes.io
batch_postcode_lookup <- function(postcodes, batch_size = 100) {
  results <- list()
  n_batches <- ceiling(length(postcodes) / batch_size)

  for (i in seq_len(n_batches)) {
    start_idx <- (i - 1) * batch_size + 1
    end_idx <- min(i * batch_size, length(postcodes))
    batch <- postcodes[start_idx:end_idx]

    resp <- tryCatch({
      req <- httr2::request("https://api.postcodes.io/postcodes") |>
        httr2::req_body_json(list(postcodes = batch)) |>
        httr2::req_timeout(30) |>
        httr2::req_perform()
      httr2::resp_body_json(req)
    }, error = function(e) {
      cat("  Batch", i, "of", n_batches, "failed:", e$message, "\n")
      NULL
    })

    if (!is.null(resp) && !is.null(resp$result)) {
      for (r in resp$result) {
        if (!is.null(r$result)) {
          results[[length(results) + 1]] <- data.table(
            postcode = r$query,
            la_code = r$result$codes$admin_district %||% NA_character_,
            la_name = r$result$admin_district %||% NA_character_,
            region = r$result$region %||% NA_character_,
            latitude = r$result$latitude %||% NA_real_,
            longitude = r$result$longitude %||% NA_real_
          )
        }
      }
    }

    if (i %% 100 == 0 || i == n_batches) {
      cat("  Batch", i, "of", n_batches,
          "(", format(length(results), big.mark = ","), "postcodes resolved)\n")
    }
    Sys.sleep(0.05)
  }

  rbindlist(results, use.names = TRUE)
}

## Lookup representative postcodes for each sector
cat("  Looking up sector-representative postcodes...\n")
pc_lookup_raw <- batch_postcode_lookup(sector_reps$rep_postcode)

## Add postcode_sector back
pc_lookup_raw <- merge(pc_lookup_raw,
                        sector_reps[, .(rep_postcode, postcode_sector)],
                        by.x = "postcode", by.y = "rep_postcode", all.x = TRUE)

## Create sector-level lookup (one LA/region/lat/lon per sector)
pc_sector_lookup <- pc_lookup_raw[!is.na(la_code),
  .(la_code = la_code[1], la_name = la_name[1], region = region[1],
    latitude = latitude[1], longitude = longitude[1]),
  by = postcode_sector]

cat("  Sector lookups completed:", nrow(pc_sector_lookup), "sectors\n")

## Save postcode lookup
fwrite(pc_sector_lookup, file.path(data_dir, "postcode_lookup.csv"))

## =========================================================================
## 4. Ofsted Management Information (school-level ratings)
## =========================================================================
cat("\n--- Fetching Ofsted management information ---\n")

## NOTE: Ofsted ratings were removed from GIAS in Jan 2025 after single grades
## were abolished. We use the separate Ofsted MI CSV which has historical ratings.
## Try multiple known URLs (Ofsted updates the filename periodically)
ofsted_urls <- c(
  "https://assets.publishing.service.gov.uk/media/686d10a910d550c668de3c52/Management_information_-_state-funded_schools_-_latest_inspections_as_at_30_June_2025.csv",
  "https://assets.publishing.service.gov.uk/media/681cd390275cb67b18d870fc/Management_information_-_state-funded_schools_-_latest_inspections_as_at_30_Apr_2025.csv",
  "https://assets.publishing.service.gov.uk/media/67c8c52b49b9c0e6d65b58c4/Management_information_-_state-funded_schools_-_latest_inspections_as_at_31_Jan_2025.csv"
)
ofsted_file <- file.path(data_dir, "ofsted_mi.csv")
ofsted_ok <- FALSE
for (ourl in ofsted_urls) {
  tryCatch({
    download.file(ourl, ofsted_file, mode = "wb", quiet = TRUE)
    if (file.info(ofsted_file)$size > 1000) {
      cat("  Ofsted MI downloaded:", round(file.info(ofsted_file)$size / 1e6, 1), "MB\n")
      ofsted_ok <- TRUE
      break
    }
  }, error = function(e) cat("  URL failed:", substr(ourl, 80, nchar(ourl)), "\n"))
}
if (!ofsted_ok) {
  stop("Cannot download Ofsted management information.\n",
       "Check https://www.gov.uk/government/statistical-data-sets/monthly-management-information-ofsteds-school-inspections-outcomes\n",
       "for the latest CSV URL and update ofsted_urls in 01_fetch_data.R.")
}

ofsted_mi <- fread(ofsted_file, encoding = "Latin-1")
cat("  Ofsted MI rows:", nrow(ofsted_mi), "| Columns:", ncol(ofsted_mi), "\n")

## The key columns are URN and "Overall effectiveness" (1-4 numeric)
## Map to text labels
ofsted_ratings <- ofsted_mi[, .(
  urn = URN,
  ofsted_numeric = `Overall effectiveness`
)]
ofsted_ratings[, ofsted_rating := fcase(
  ofsted_numeric == 1, "Outstanding",
  ofsted_numeric == 2, "Good",
  ofsted_numeric == 3, "Requires improvement",
  ofsted_numeric == 4, "Inadequate",
  default = NA_character_
)]
cat("  Ofsted ratings parsed:", ofsted_ratings[!is.na(ofsted_rating), .N], "schools with ratings\n")

## =========================================================================
## 5. Process GIAS school data + merge Ofsted
## =========================================================================
cat("\n--- Processing school data from GIAS ---\n")

gias_cols <- names(gias)
cat("  Key GIAS columns available:\n")
cat("  ", paste(grep("Type|Post|East|North|Phase|Pupil|Status|Open|Close",
                     gias_cols, value = TRUE, ignore.case = TRUE), collapse = ", "), "\n")

## Extract school data from GIAS (without Ofsted — that comes from MI)
schools <- gias[, .(
  urn = URN,
  name = EstablishmentName,
  type_code = `TypeOfEstablishment (code)`,
  type_name = `TypeOfEstablishment (name)`,
  phase = `PhaseOfEducation (name)`,
  status = `EstablishmentStatus (name)`,
  open_date = `OpenDate`,
  close_date = `CloseDate`,
  postcode = Postcode,
  easting = Easting,
  northing = Northing,
  la_code = `LA (code)`,
  la_name = `LA (name)`,
  num_pupils = `NumberOfPupils`,
  statutory_low_age = StatutoryLowAge,
  statutory_high_age = StatutoryHighAge
)]

## Merge Ofsted ratings onto schools
schools <- merge(schools, ofsted_ratings[, .(urn, ofsted_rating)],
                 by = "urn", all.x = TRUE)
cat("  Schools with Ofsted rating:", schools[!is.na(ofsted_rating), .N], "\n")
cat("  Schools without rating:", schools[is.na(ofsted_rating), .N], "\n")

## Classify schools
schools[, is_independent := type_code %in% c(7, 10, 11)]
schools[, is_state_secondary := phase %in% c("Secondary", "All through", "Middle deemed secondary") &
          !is_independent & status == "Open"]
schools[, is_state_primary := phase %in% c("Primary", "Middle deemed primary") &
          !is_independent & status == "Open"]

## Classify Ofsted quality
schools[, ofsted_good := ofsted_rating %in% c("Outstanding", "Good")]
schools[, ofsted_category := fcase(
  ofsted_rating == "Outstanding", "Outstanding",
  ofsted_rating == "Good", "Good",
  ofsted_rating == "Requires improvement", "Requires Improvement",
  ofsted_rating == "Inadequate", "Inadequate",
  default = "Not rated"
)]

cat("\n  School counts by type:\n")
print(schools[status == "Open", .N, by = .(is_independent, phase)][order(-N)])

cat("\n  State secondary schools by Ofsted rating:\n")
print(schools[is_state_secondary == TRUE, .N, by = ofsted_category][order(-N)])

cat("\n  Independent schools:", schools[is_independent == TRUE & status == "Open", .N], "\n")

## =========================================================================
## 6. Compute LA-level private school share (treatment intensity)
## =========================================================================
cat("\n--- Computing LA-level treatment intensity ---\n")

## Private school pupils by LA
private_pupils <- schools[is_independent == TRUE & status == "Open" & !is.na(num_pupils),
                          .(private_pupils = sum(num_pupils, na.rm = TRUE)), by = la_code]

## Total pupils by LA (all schools)
all_pupils <- schools[status == "Open" & !is.na(num_pupils),
                      .(total_pupils = sum(num_pupils, na.rm = TRUE)), by = la_code]

la_treatment <- merge(all_pupils, private_pupils, by = "la_code", all.x = TRUE)
la_treatment[is.na(private_pupils), private_pupils := 0]
la_treatment[, private_share := private_pupils / total_pupils]

## Add LA name
la_names <- unique(schools[, .(la_code, la_name)])
la_treatment <- merge(la_treatment, la_names, by = "la_code", all.x = TRUE)

cat("  LA-level private school share summary:\n")
print(summary(la_treatment$private_share))
cat("  LAs with >10% private share:", la_treatment[private_share > 0.10, .N], "\n")
cat("  LAs with zero private schools:", la_treatment[private_share == 0, .N], "\n")

fwrite(la_treatment, file.path(data_dir, "la_treatment_intensity.csv"))

## =========================================================================
## 7. Save processed school locations for distance calculations
## =========================================================================
cat("\n--- Saving school locations ---\n")

## State secondary schools with coordinates
state_secondary <- schools[is_state_secondary == TRUE & !is.na(easting) & !is.na(northing)]
cat("  State secondary schools with coordinates:", nrow(state_secondary), "\n")

## Independent schools with coordinates
independent <- schools[is_independent == TRUE & status == "Open" & !is.na(easting) & !is.na(northing)]
cat("  Independent schools with coordinates:", nrow(independent), "\n")

fwrite(state_secondary, file.path(data_dir, "state_secondary_schools.csv"))
fwrite(independent, file.path(data_dir, "independent_schools.csv"))

## Save combined Land Registry data
cat("\n--- Saving combined Land Registry data ---\n")
fwrite(lr_all, file.path(data_dir, "land_registry_all.csv"))
cat("  Saved:", format(nrow(lr_all), big.mark = ","), "transactions\n")

## =========================================================================
## DATA VALIDATION (required)
## =========================================================================
cat("\n=== DATA VALIDATION ===\n")

stopifnot("Expected 10+ years of Land Registry data" =
            lr_all[, uniqueN(year)] >= 10)
stopifnot("Expected 1M+ transactions" = nrow(lr_all) >= 1000000)
stopifnot("Expected state secondary schools" = nrow(state_secondary) >= 2000)
stopifnot("Expected independent schools" = nrow(independent) >= 500)
stopifnot("Expected 100+ LAs with treatment data" = nrow(la_treatment) >= 100)

cat("Data validation passed.\n")
cat("  Land Registry: ", format(nrow(lr_all), big.mark = ","), " transactions, ",
    lr_all[, uniqueN(year)], " years\n")
cat("  State secondary schools: ", nrow(state_secondary), "\n")
cat("  Independent schools: ", nrow(independent), "\n")
cat("  LAs with treatment data: ", nrow(la_treatment), "\n")
cat("\n=== DATA ACQUISITION COMPLETE ===\n")
