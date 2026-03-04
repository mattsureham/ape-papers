## 02_clean_data.R — Construct analysis panel
## apep_0495: Private School VAT and State School Housing Premium

source("00_packages.R")

data_dir <- "../data"
cat("=== DATA CLEANING & PANEL CONSTRUCTION ===\n")

## =========================================================================
## 1. Load data
## =========================================================================

lr <- fread(file.path(data_dir, "land_registry_all.csv"))
pc_lookup <- fread(file.path(data_dir, "postcode_lookup.csv"))
schools <- fread(file.path(data_dir, "state_secondary_schools.csv"))
independent <- fread(file.path(data_dir, "independent_schools.csv"))
la_treatment <- fread(file.path(data_dir, "la_treatment_intensity.csv"))

cat("Loaded Land Registry:", format(nrow(lr), big.mark = ","), "rows\n")
cat("Loaded postcode lookup:", format(nrow(pc_lookup), big.mark = ","), "rows\n")
cat("Loaded state secondary schools:", nrow(schools), "\n")
cat("Loaded independent schools:", nrow(independent), "\n")
cat("Loaded LA treatment data:", nrow(la_treatment), "\n")

## =========================================================================
## 2. Merge postcode geography onto Land Registry
## =========================================================================
cat("\n--- Merging geography ---\n")

lr[, date_transfer := as.Date(date_transfer)]

## Reconstruct postcode sector for merge
lr[, postcode_sector := sub("^(.+?)\\s*(\\d)\\w+$", "\\1 \\2", postcode)]

## Merge sector-level geography
lr <- merge(lr, pc_lookup, by = "postcode_sector", all.x = TRUE)
cat("  After merge:", format(nrow(lr), big.mark = ","), "rows\n")
cat("  With LA code:", format(lr[!is.na(la_code), .N], big.mark = ","), "\n")
cat("  Missing LA code:", format(lr[is.na(la_code), .N], big.mark = ","), "\n")

## Drop transactions without geographic info (cannot assign treatment)
lr <- lr[!is.na(la_code)]

## =========================================================================
## 3. Convert school coordinates from BNG (Easting/Northing) to lat/lon
## =========================================================================
cat("\n--- Converting school coordinates ---\n")

## British National Grid to WGS84 conversion
## Using the standard Helmert transformation
bng_to_latlon <- function(easting, northing) {
  ## OSGB36 ellipsoid parameters
  a <- 6377563.396; b <- 6356256.909
  F0 <- 0.9996012717
  lat0 <- 49 * pi / 180; lon0 <- -2 * pi / 180
  N0 <- -100000; E0 <- 400000
  e2 <- 1 - (b^2) / (a^2)
  n_param <- (a - b) / (a + b)

  ## Iterate for latitude
  lat <- lat0
  M <- 0
  while (abs(northing - N0 - M) >= 0.00001) {
    lat <- (northing - N0 - M) / (a * F0) + lat
    Ma <- (1 + n_param + (5/4) * n_param^2 + (5/4) * n_param^3) * (lat - lat0)
    Mb <- (3 * n_param + 3 * n_param^2 + (21/8) * n_param^3) * sin(lat - lat0) * cos(lat + lat0)
    Mc <- ((15/8) * n_param^2 + (15/8) * n_param^3) * sin(2 * (lat - lat0)) * cos(2 * (lat + lat0))
    Md <- (35/24) * n_param^3 * sin(3 * (lat - lat0)) * cos(3 * (lat + lat0))
    M <- b * F0 * (Ma - Mb + Mc - Md)
  }

  sin_lat <- sin(lat); cos_lat <- cos(lat); tan_lat <- tan(lat)
  nu <- a * F0 / sqrt(1 - e2 * sin_lat^2)
  rho <- a * F0 * (1 - e2) / (1 - e2 * sin_lat^2)^1.5
  eta2 <- nu / rho - 1

  VII <- tan_lat / (2 * rho * nu)
  VIII <- tan_lat / (24 * rho * nu^3) * (5 + 3 * tan_lat^2 + eta2 - 9 * tan_lat^2 * eta2)
  IX <- tan_lat / (720 * rho * nu^5) * (61 + 90 * tan_lat^2 + 45 * tan_lat^4)
  X <- 1 / (cos_lat * nu)
  XI <- 1 / (cos_lat * 6 * nu^3) * (nu / rho + 2 * tan_lat^2)
  XII <- 1 / (cos_lat * 120 * nu^5) * (5 + 28 * tan_lat^2 + 24 * tan_lat^4)

  dE <- easting - E0
  lat_out <- lat - VII * dE^2 + VIII * dE^4 - IX * dE^6
  lon_out <- lon0 + X * dE - XI * dE^3 + XII * dE^5

  list(lat = lat_out * 180 / pi, lon = lon_out * 180 / pi)
}

## Vectorized BNG conversion
convert_bng_batch <- function(eastings, northings) {
  n <- length(eastings)
  lats <- numeric(n)
  lons <- numeric(n)
  for (i in seq_len(n)) {
    if (!is.na(eastings[i]) && !is.na(northings[i])) {
      ll <- bng_to_latlon(eastings[i], northings[i])
      lats[i] <- ll$lat
      lons[i] <- ll$lon
    } else {
      lats[i] <- NA_real_
      lons[i] <- NA_real_
    }
  }
  list(lat = lats, lon = lons)
}

cat("  Converting state secondary school coordinates...\n")
school_ll <- convert_bng_batch(schools$easting, schools$northing)
schools[, `:=`(school_lat = school_ll$lat, school_lon = school_ll$lon)]

cat("  Converting independent school coordinates...\n")
indep_ll <- convert_bng_batch(independent$easting, independent$northing)
independent[, `:=`(school_lat = indep_ll$lat, school_lon = indep_ll$lon)]

## =========================================================================
## 4. Compute distance from each property to nearest state secondary school
## =========================================================================
cat("\n--- Computing property-to-school distances ---\n")

## For each property (with lat/lon), find nearest Outstanding/Good and
## nearest Requires Improvement/Inadequate state secondary school

## Schools by quality category
good_schools <- schools[ofsted_good == TRUE & !is.na(school_lat)]
bad_schools <- schools[ofsted_good == FALSE & ofsted_category != "Not rated" & !is.na(school_lat)]

cat("  Good/Outstanding state secondary schools:", nrow(good_schools), "\n")
cat("  RI/Inadequate state secondary schools:", nrow(bad_schools), "\n")

## Function to find nearest school from a set
find_nearest_school <- function(prop_lat, prop_lon, school_lats, school_lons, school_ids) {
  if (is.na(prop_lat) || is.na(prop_lon)) return(list(urn = NA, dist_km = NA))

  ## Haversine distance (vectorized via geosphere)
  dists <- geosphere::distHaversine(
    cbind(prop_lon, prop_lat),
    cbind(school_lons, school_lats)
  ) / 1000  # Convert to km

  idx <- which.min(dists)
  list(urn = school_ids[idx], dist_km = dists[idx])
}

## For efficiency, process at the postcode-sector level (not transaction level)
## Each sector gets one distance to nearest good school and one to nearest bad school
unique_props <- unique(lr[!is.na(latitude), .(postcode_sector, latitude, longitude)])
cat("  Unique property postcode sectors with coordinates:", format(nrow(unique_props), big.mark = ","), "\n")

cat("  Computing distances to nearest good school...\n")
nearest_good <- data.table(
  postcode_sector = unique_props$postcode_sector,
  nearest_good_urn = NA_integer_,
  dist_good_km = NA_real_
)

## Process in chunks for memory efficiency
chunk_size <- 5000
n_chunks <- ceiling(nrow(unique_props) / chunk_size)

for (ch in seq_len(n_chunks)) {
  idx_start <- (ch - 1) * chunk_size + 1
  idx_end <- min(ch * chunk_size, nrow(unique_props))

  for (i in idx_start:idx_end) {
    res <- find_nearest_school(
      unique_props$latitude[i], unique_props$longitude[i],
      good_schools$school_lat, good_schools$school_lon, good_schools$urn
    )
    set(nearest_good, i, "nearest_good_urn", res$urn)
    set(nearest_good, i, "dist_good_km", res$dist_km)
  }

  if (ch %% 10 == 0 || ch == n_chunks) {
    cat("    Chunk", ch, "of", n_chunks, "\n")
  }
}

cat("  Computing distances to nearest RI/Inadequate school...\n")
nearest_bad <- data.table(
  postcode_sector = unique_props$postcode_sector,
  nearest_bad_urn = NA_integer_,
  dist_bad_km = NA_real_
)

for (ch in seq_len(n_chunks)) {
  idx_start <- (ch - 1) * chunk_size + 1
  idx_end <- min(ch * chunk_size, nrow(unique_props))

  for (i in idx_start:idx_end) {
    res <- find_nearest_school(
      unique_props$latitude[i], unique_props$longitude[i],
      bad_schools$school_lat, bad_schools$school_lon, bad_schools$urn
    )
    set(nearest_bad, i, "nearest_bad_urn", res$urn)
    set(nearest_bad, i, "dist_bad_km", res$dist_km)
  }

  if (ch %% 10 == 0 || ch == n_chunks) {
    cat("    Chunk", ch, "of", n_chunks, "\n")
  }
}

## Merge distances back
nearest <- merge(nearest_good, nearest_bad, by = "postcode_sector")

## =========================================================================
## 5. Construct analysis variables
## =========================================================================
cat("\n--- Constructing analysis variables ---\n")

## Merge distances onto LR data
lr <- merge(lr, nearest, by = "postcode_sector", all.x = TRUE)

## Merge LA treatment intensity
## NOTE: lr$la_code is ONS code (from postcodes.io, e.g. "E09000001")
## while la_treatment$la_code is DfE code (from GIAS, e.g. 201).
## Merge on la_name instead.
lr <- merge(lr, la_treatment[, .(la_name, private_share, private_pupils, total_pupils)],
            by = "la_name", all.x = TRUE)

## Define treatment variables
lr[, `:=`(
  ## Time variables
  year_month_date = as.Date(paste0(year_month, "-01")),

  ## Post-treatment indicators
  post_announce = as.integer(date_transfer >= as.Date("2024-07-04")),   # Election
  post_budget = as.integer(date_transfer >= as.Date("2024-10-30")),     # Budget
  post_vat = as.integer(date_transfer >= as.Date("2025-01-01")),        # Implementation

  ## Treatment intensity (continuous)
  high_private = as.integer(private_share > median(la_treatment$private_share, na.rm = TRUE)),

  ## Near good school (within 3km of Outstanding/Good school AND >3km from RI/Inadequate)
  near_good_school = as.integer(dist_good_km <= 3),
  near_bad_school = as.integer(dist_bad_km <= 3),

  ## Log price
  log_price = log(price),

  ## Property type factor
  prop_type = factor(property_type, levels = c("D", "S", "T", "F", "O"),
                     labels = c("Detached", "Semi", "Terraced", "Flat", "Other"))
)]

## DDD treatment: high private share × near good school × post
lr[, ddd_treat := high_private * near_good_school * post_vat]

## Relative time (months from January 2025)
lr[, rel_month := (year - 2025) * 12 + (month - 1)]

## Postcode sector for fixed effects (e.g., "SW1A 1")
lr[, pc_sector := postcode_sector]

cat("  Treatment intensity (high_private) distribution:\n")
print(table(lr$high_private, useNA = "ifany"))

cat("\n  Near good school distribution:\n")
print(table(lr$near_good_school, useNA = "ifany"))

cat("\n  Post-VAT distribution:\n")
print(table(lr$post_vat, useNA = "ifany"))

## =========================================================================
## 6. Create analysis sample
## =========================================================================
cat("\n--- Creating analysis sample ---\n")

## Keep only records with all required variables
panel <- lr[!is.na(log_price) & !is.na(high_private) &
              !is.na(near_good_school) & !is.na(la_code) &
              price > 10000 & price < 10000000]  # Remove extremes

cat("  Analysis sample:", format(nrow(panel), big.mark = ","), "transactions\n")
cat("  Date range:", min(panel$date_transfer), "to", max(panel$date_transfer), "\n")
cat("  LAs:", uniqueN(panel$la_code), "\n")
cat("  Postcode sectors:", uniqueN(panel$pc_sector), "\n")

## Summary statistics
cat("\n  Summary of log prices:\n")
print(summary(panel$log_price))

cat("\n  Summary of distances to nearest good school (km):\n")
print(summary(panel$dist_good_km))

## Save analysis panel
fwrite(panel, file.path(data_dir, "analysis_panel.csv"))
cat("\n  Saved analysis panel:", format(nrow(panel), big.mark = ","), "rows\n")

## =========================================================================
## DATA VALIDATION
## =========================================================================
cat("\n=== PANEL VALIDATION ===\n")
stopifnot("Expected 500K+ analysis observations" = nrow(panel) >= 500000)
stopifnot("Expected 50+ LAs" = uniqueN(panel$la_code) >= 50)
stopifnot("Expected both treatment groups" = all(c(0, 1) %in% panel$high_private))
stopifnot("Expected pre and post periods" = all(c(0, 1) %in% panel$post_vat))
stopifnot("Expected near-good variation" = all(c(0, 1) %in% panel$near_good_school))

cat("Panel validation passed.\n")
cat("=== DATA CLEANING COMPLETE ===\n")
