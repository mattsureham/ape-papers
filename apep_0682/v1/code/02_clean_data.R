## 02_clean_data.R — Parse EDM data, geocode overflows, construct analysis panel
## apep_0682: Sewage EDM Information Revelation and House Prices

library(data.table)
library(readxl)
library(sf)
library(httr2)
library(jsonlite)
library(stringr)
library(RANN)

DATA_DIR <- "data"

## ── 1. Parse NGR (National Grid Reference) to Easting/Northing ────────────

parse_ngr <- function(ngr_vec) {
  # British National Grid: 2-letter prefix + even digits
  # Second letter → (col, row) within 500km square (no letter I)
  letter_grid <- list(
    A=c(0,4), B=c(1,4), C=c(2,4), D=c(3,4), E=c(4,4),
    F=c(0,3), G=c(1,3), H=c(2,3), J=c(3,3), K=c(4,3),
    L=c(0,2), M=c(1,2), N=c(2,2), O=c(3,2), P=c(4,2),
    Q=c(0,1), R=c(1,1), S=c(2,1), T=c(3,1), U=c(4,1),
    V=c(0,0), W=c(1,0), X=c(2,0), Y=c(3,0), Z=c(4,0)
  )
  # First letter → (col, row) of 500km square
  first_grid <- list(H=c(0,2), N=c(0,1), O=c(1,1), S=c(0,0), T=c(1,0))

  easting <- rep(NA_real_, length(ngr_vec))
  northing <- rep(NA_real_, length(ngr_vec))

  for (i in seq_along(ngr_vec)) {
    ngr <- toupper(trimws(as.character(ngr_vec[i])))
    if (is.na(ngr) || nchar(ngr) < 4) next

    l1 <- substr(ngr, 1, 1)
    l2 <- substr(ngr, 2, 2)
    digits <- gsub("[^0-9]", "", substr(ngr, 3, nchar(ngr)))

    if (is.null(first_grid[[l1]]) || is.null(letter_grid[[l2]])) next

    fg <- first_grid[[l1]]
    lg <- letter_grid[[l2]]

    base_e <- (fg[1] * 5 + lg[1]) * 100000
    base_n <- (fg[2] * 5 + lg[2]) * 100000

    nd <- nchar(digits)
    if (nd %% 2 != 0 || nd == 0) next
    half <- nd / 2
    e_digits <- substr(digits, 1, half)
    n_digits <- substr(digits, half + 1, nd)

    scale <- 10^(5 - half)
    easting[i] <- base_e + as.numeric(e_digits) * scale
    northing[i] <- base_n + as.numeric(n_digits) * scale
  }

  data.table(easting = easting, northing = northing)
}

## ── 2. Read EDM 2024 data (all WaSCs) ─────────────────────────────────────
cat("=== Reading EDM 2024 data ===\n")
f24 <- "data/edm_2024/EDM_2024_Storm_Overflow_Annual_Return/EDM 2024 Storm Overflow Annual Return - all water and sewerage companies.xlsx"
sheets <- excel_sheets(f24)

edm_list <- list()
for (s in sheets) {
  d <- read_excel(f24, sheet = s, skip = 1, col_types = "text")
  # Standardise column names
  names(d) <- paste0("V", seq_len(ncol(d)))
  edm_list[[s]] <- d
}
edm_raw <- rbindlist(edm_list, fill = TRUE)
cat("Total EDM rows:", nrow(edm_raw), "\n")

# Key columns from 2024 format:
# V1=Unique ID, V2=Water Company, V3=Site Name, V9=NGR,
# V17=Spill Count, V16=Total Duration, V19=Data start year, V20=EDM %
edm <- data.table(
  overflow_id = edm_raw$V1,
  water_company = edm_raw$V2,
  site_name = edm_raw$V3,
  ngr = edm_raw$V9,
  spill_count_raw = edm_raw$V17,
  duration_raw = edm_raw$V16,
  data_start_year_raw = edm_raw$V19,
  edm_pct_raw = edm_raw$V20
)

# Parse spill count
edm[, spill_count := suppressWarnings(as.numeric(spill_count_raw))]

# Parse duration: handle hh:mm:ss or numeric (Excel serial time or hours)
edm[, total_duration_hrs := {
  dur <- rep(NA_real_, .N)
  raw <- duration_raw
  # hh:mm:ss format
  hms <- grepl(":", raw, fixed = TRUE) & !is.na(raw)
  if (any(hms)) {
    parts <- strsplit(raw[hms], ":")
    dur[hms] <- sapply(parts, function(p) {
      p <- suppressWarnings(as.numeric(p))
      if (length(p) >= 3) p[1] + p[2]/60 + p[3]/3600
      else if (length(p) == 2) p[1] + p[2]/60
      else NA_real_
    })
  }
  # Numeric format (already hours or Excel serial day fraction)
  num <- !hms & !is.na(raw) & grepl("^[0-9eE.+-]+$", raw)
  if (any(num)) {
    vals <- suppressWarnings(as.numeric(raw[num]))
    # If values < 10, likely Excel serial days → convert to hours
    dur[num] <- ifelse(vals < 10, vals * 24, vals)
  }
  dur
}]

# Parse data start year
edm[, data_start_year := suppressWarnings(as.integer(as.numeric(data_start_year_raw)))]
edm[, edm_pct := suppressWarnings(as.numeric(edm_pct_raw))]

# Clean up raw columns
edm[, c("spill_count_raw", "duration_raw", "data_start_year_raw", "edm_pct_raw") := NULL]

cat("Non-NA spill counts:", sum(!is.na(edm$spill_count)), "/", nrow(edm), "\n")
cat("Non-NA data start years:", sum(!is.na(edm$data_start_year)), "/", nrow(edm), "\n")
cat("Data start year distribution:\n")
print(table(edm$data_start_year, useNA = "ifany"))

## ── 3. Parse NGR → Easting/Northing ───────────────────────────────────────
cat("\n=== Parsing NGR coordinates ===\n")
coords <- parse_ngr(edm$ngr)
edm[, `:=`(easting = coords$easting, northing = coords$northing)]
cat("Successfully geocoded:", sum(!is.na(edm$easting)), "/", nrow(edm), "overflows\n")

## ── 4. Convert BNG to WGS84 (lat/lon) ────────────────────────────────────
cat("\n=== Converting to WGS84 ===\n")
valid_idx <- !is.na(edm$easting) & !is.na(edm$northing)
edm[, `:=`(lat = NA_real_, lon = NA_real_)]

if (sum(valid_idx) > 0) {
  pts <- st_as_sf(edm[valid_idx, .(easting, northing)],
                  coords = c("easting", "northing"), crs = 27700)
  pts_wgs <- st_transform(pts, 4326)
  crds <- st_coordinates(pts_wgs)
  edm[valid_idx, `:=`(lon = crds[, 1], lat = crds[, 2])]
}
cat("WGS84 coordinates:", sum(!is.na(edm$lat)), "overflows\n")

## ── 5. Reverse geocode to postcodes via postcodes.io ──────────────────────
cat("\n=== Reverse geocoding via postcodes.io ===\n")
geo_idx <- which(!is.na(edm$lat) & !is.na(edm$lon))
edm[, `:=`(nearest_postcode = NA_character_, postcode_district = NA_character_)]

batch_size <- 100
n_batches <- ceiling(length(geo_idx) / batch_size)
cat("Processing", length(geo_idx), "overflows in", n_batches, "batches\n")

for (b in seq_len(n_batches)) {
  start <- (b - 1) * batch_size + 1
  end <- min(b * batch_size, length(geo_idx))
  batch_idx <- geo_idx[start:end]

  geolocations <- lapply(batch_idx, function(i) {
    list(longitude = edm$lon[i], latitude = edm$lat[i], limit = 1)
  })

  resp <- tryCatch({
    request("https://api.postcodes.io/postcodes") |>
      req_body_json(list(geolocations = geolocations)) |>
      req_timeout(30) |>
      req_perform()
  }, error = function(e) {
    cat("  Batch", b, "failed:", conditionMessage(e), "\n")
    NULL
  })

  if (!is.null(resp)) {
    body <- resp_body_json(resp)
    results <- body$result
    for (j in seq_along(results)) {
      res <- results[[j]]$result
      if (!is.null(res) && length(res) > 0) {
        pc <- res[[1]]$postcode
        if (!is.null(pc)) {
          edm$nearest_postcode[batch_idx[j]] <- pc
          # Outward code = everything before the space
          edm$postcode_district[batch_idx[j]] <- sub("\\s+\\S+$", "", pc)
        }
      }
    }
  }

  if (b %% 20 == 0) cat("  Completed batch", b, "/", n_batches, "\n")
  Sys.sleep(0.15)  # Rate limiting
}

cat("Geocoded to postcode:", sum(!is.na(edm$postcode_district)), "/", nrow(edm), "\n")
cat("Unique postcode districts:", uniqueN(edm$postcode_district), "\n")

## ── 6. Construct overflow treatment dataset ───────────────────────────────
cat("\n=== Constructing treatment dataset ===\n")

# Treatment year: the year monitoring data was first published
# Data collected in year Y is published in the Annual Return the following spring
# So data_start_year = Y means information available to market from ~spring Y+1
# For annual analysis: treatment_year = data_start_year + 1
edm[, treatment_year := data_start_year + 1L]

# Aggregate to postcode district level
edm_pd <- edm[!is.na(postcode_district) & !is.na(treatment_year),
  .(first_treatment_year = min(treatment_year),
    n_overflows = .N,
    mean_spill_count = mean(spill_count, na.rm = TRUE),
    total_spills = sum(spill_count, na.rm = TRUE),
    mean_duration_hrs = mean(total_duration_hrs, na.rm = TRUE),
    high_spill = as.integer(mean(spill_count, na.rm = TRUE) > 30)),
  by = postcode_district]

cat("Postcode districts with overflows:", nrow(edm_pd), "\n")
cat("Treatment year distribution:\n")
print(table(edm_pd$first_treatment_year, useNA = "ifany"))

## ── 7. Read and process Land Registry PPD ─────────────────────────────────
cat("\n=== Processing Land Registry PPD ===\n")

# PPD columns: TxID, Price, Date, Postcode, PropType, New/Old, Tenure,
#              PAON, SAON, Street, Locality, Town, District, County, PPD_Cat, RecStatus
lr_cols <- c("tx_id", "price", "date", "postcode", "prop_type", "new_old",
             "tenure", "paon", "saon", "street", "locality", "town",
             "district", "county", "ppd_cat", "rec_status")

lr_list <- list()
for (yr in 2016:2024) {
  fpath <- file.path("data/land_registry", paste0("pp-", yr, ".csv"))
  if (!file.exists(fpath)) {
    cat("  MISSING:", fpath, "\n")
    stop(paste("Land Registry file missing for year", yr))
  }
  dt <- fread(fpath, header = FALSE,
              select = c(2, 3, 4, 5, 6, 7),
              col.names = c("price", "date", "postcode", "prop_type", "new_old", "tenure"))
  dt[, year := as.integer(substr(date, 1, 4))]
  lr_list[[as.character(yr)]] <- dt
  cat("  Loaded", yr, ":", nrow(dt), "transactions\n")
}
lr <- rbindlist(lr_list)
cat("Total transactions:", nrow(lr), "\n")

# Extract postcode district (outward code)
lr[, postcode_district := sub("\\s+\\S+$", "", trimws(postcode))]
# Remove records with missing/invalid postcodes
lr <- lr[nchar(postcode_district) >= 2 & nchar(postcode_district) <= 4]
lr <- lr[price > 0]
lr[, price := as.double(price)]
lr[, log_price := log(price)]

cat("Valid transactions:", nrow(lr), "\n")
cat("Unique postcode districts in LR:", uniqueN(lr$postcode_district), "\n")

## ── 8. Aggregate Land Registry to postcode-district × year ────────────────
cat("\n=== Aggregating to postcode-district x year ===\n")

lr_panel <- lr[, .(
  mean_log_price = mean(log_price),
  median_price = median(price),
  mean_price = mean(price),
  n_transactions = .N,
  pct_detached = mean(prop_type == "D"),
  pct_flat = mean(prop_type == "F"),
  pct_new = mean(new_old == "Y")
), by = .(postcode_district, year)]

cat("Panel size:", nrow(lr_panel), "postcode-district x year cells\n")
cat("Postcode districts:", uniqueN(lr_panel$postcode_district), "\n")
cat("Years:", sort(unique(lr_panel$year)), "\n")

## ── 9. Merge treatment data and construct analysis panel ──────────────────
cat("\n=== Constructing analysis panel ===\n")

panel <- merge(lr_panel, edm_pd, by = "postcode_district", all.x = TRUE)

# Postcode districts without overflows: never treated
panel[is.na(first_treatment_year), `:=`(
  first_treatment_year = 0L,  # Never treated (for C&S)
  n_overflows = 0L,
  mean_spill_count = 0,
  total_spills = 0L,
  mean_duration_hrs = 0,
  high_spill = 0L
)]

# Binary treatment indicator
panel[, treated := as.integer(first_treatment_year > 0 & year >= first_treatment_year)]

# For Callaway & Sant'Anna: gname = first_treatment_year (0 = never treated)
panel[, gname := first_treatment_year]

cat("Panel dimensions:", nrow(panel), "rows x", ncol(panel), "cols\n")
cat("Treated postcode-districts:", uniqueN(panel[gname > 0, postcode_district]), "\n")
cat("Never-treated postcode-districts:", uniqueN(panel[gname == 0, postcode_district]), "\n")
cat("Treatment status:\n")
print(table(panel$treated))

# Filter to panel with sufficient observations
panel <- panel[n_transactions >= 5]  # At least 5 transactions per cell
cat("After filtering (n>=5):", nrow(panel), "rows\n")

## ── 10. Save datasets ────────────────────────────────────────────────────
fwrite(edm, file.path(DATA_DIR, "edm_overflow_panel.csv"))
fwrite(edm_pd, file.path(DATA_DIR, "edm_postcode_district.csv"))
fwrite(panel, file.path(DATA_DIR, "analysis_panel.csv"))

cat("\n=== Panel construction complete ===\n")
cat("Saved: edm_overflow_panel.csv, edm_postcode_district.csv, analysis_panel.csv\n")
