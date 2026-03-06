## 02_clean_data.R — Construct analysis variables, spatial join, boundary assignment
## APEP-0538: ZFE Housing Price Capitalization

source("00_packages.R")

data_dir <- "../data"

## =========================================================================
## A. Load raw data
## =========================================================================

cat("=== A. Loading raw data ===\n")

dvf <- fread(file.path(data_dir, "dvf_geocoded_2020_2024.csv"))

## Use the proper BNZFE national file (downloaded separately)
bnzfe_file <- file.path(data_dir, "bnzfe_aires.geojson")
if (file.exists(bnzfe_file)) {
  zfe_sf <- st_read(bnzfe_file, quiet = TRUE)
  cat("  BNZFE loaded:", nrow(zfe_sf), "features\n")
} else {
  zfe_sf <- st_read(file.path(data_dir, "zfe_boundaries.geojson"), quiet = TRUE)
  cat("  Fallback ZFE loaded:", nrow(zfe_sf), "features\n")
}

## Filter BNZFE to ZFEs that started by 2024 (exclude future ones)
## and take the earliest phase per ZFE area (first restriction)
if ("date_debut" %in% names(zfe_sf)) {
  zfe_sf$date_debut <- as.Date(zfe_sf$date_debut)
  zfe_sf <- zfe_sf[zfe_sf$date_debut <= as.Date("2024-12-31"), ]
  cat("  ZFE features after date filter:", nrow(zfe_sf), "\n")
}

city_coords <- fread(file.path(data_dir, "city_coordinates.csv"))
air_quality <- fread(file.path(data_dir, "air_quality_monthly.csv"))
commune_prices <- tryCatch(
  fread(file.path(data_dir, "commune_price_trends.csv")),
  error = function(e) { cat("  WARN: No commune price trends yet\n"); NULL }
)

cat("  DVF rows:", format(nrow(dvf), big.mark = ","), "\n")

## =========================================================================
## B. Clean DVF transactions
## =========================================================================

cat("\n=== B. Cleaning DVF transactions ===\n")

## Keep only sales (Vente)
dvf <- dvf[nature_mutation == "Vente"]

## Remove missing/invalid prices
dvf <- dvf[!is.na(valeur_fonciere) & valeur_fonciere > 0]

## Remove missing coordinates
dvf <- dvf[!is.na(latitude) & !is.na(longitude)]

## Remove extreme outliers
dvf <- dvf[valeur_fonciere >= 10000 & valeur_fonciere <= 10000000]

## Compute price per m2
dvf[, surface := fifelse(!is.na(surface_reelle_bati) & surface_reelle_bati > 0,
                          surface_reelle_bati, NA_real_)]
dvf <- dvf[!is.na(surface) & surface >= 9 & surface <= 1000]
dvf[, price_m2 := valeur_fonciere / surface]
dvf[, log_price_m2 := log(price_m2)]

## Remove extreme price/m2 (below 500 or above 30000 EUR/m2)
dvf <- dvf[price_m2 >= 500 & price_m2 <= 30000]

## Create time variables
dvf[, date := as.Date(date_mutation)]
dvf[, year := year(date)]
dvf[, quarter := quarter(date)]
dvf[, year_quarter := paste0(year, "Q", quarter)]
dvf[, month := format(date, "%Y-%m")]

## Property type
dvf[, property_type := fcase(
  code_type_local == 1, "house",
  code_type_local == 2, "apartment",
  code_type_local == 3, "commercial",
  code_type_local == 4, "industrial",
  default = "other"
)]

## Size quintiles within property type
dvf[property_type %in% c("house", "apartment"),
    size_quintile := cut(surface,
                          breaks = quantile(surface, probs = seq(0, 1, 0.2), na.rm = TRUE),
                          labels = paste0("Q", 1:5),
                          include.lowest = TRUE),
    by = property_type]

cat("  After cleaning:", format(nrow(dvf), big.mark = ","), "transactions\n")
cat("  Property types:\n")
print(dvf[, .N, by = property_type][order(-N)])

## =========================================================================
## C. Spatial join: Assign ZFE status and distance to boundary
## =========================================================================

cat("\n=== C. Spatial join with ZFE boundaries ===\n")

## Convert DVF to sf object
cat("  Converting DVF to sf...\n")
dvf_sf <- st_as_sf(dvf, coords = c("longitude", "latitude"), crs = 4326)

## Ensure ZFE boundaries are in same CRS
zfe_sf <- st_transform(zfe_sf, 4326)

## Project to French Lambert-93 (EPSG:2154) for distance calculations in meters
cat("  Projecting to Lambert-93...\n")
dvf_proj <- st_transform(dvf_sf, 2154)
zfe_proj <- st_transform(zfe_sf, 2154)

## Union all ZFE polygons into a single multi-polygon
cat("  Creating ZFE union polygon...\n")
zfe_union <- st_union(zfe_proj)
zfe_union <- st_make_valid(zfe_union)

## Process in chunks to avoid memory issues (8GB RAM)
cat("  Computing point-in-polygon (inside ZFE) in chunks...\n")
chunk_size <- 100000
n_chunks <- ceiling(nrow(dvf) / chunk_size)
inside_vec <- logical(nrow(dvf))

for (ch in seq_len(n_chunks)) {
  idx_start <- (ch - 1) * chunk_size + 1
  idx_end <- min(ch * chunk_size, nrow(dvf))
  chunk_proj <- dvf_proj[idx_start:idx_end, ]
  inside_vec[idx_start:idx_end] <- st_within(chunk_proj, zfe_union, sparse = FALSE)[, 1]
  if (ch %% 5 == 0) cat("    Chunk", ch, "/", n_chunks, "\n")
}

dvf$inside_zfe <- as.integer(inside_vec)
cat("    Inside ZFE:", format(sum(dvf$inside_zfe), big.mark = ","), "\n")
cat("    Outside ZFE:", format(sum(!dvf$inside_zfe), big.mark = ","), "\n")

## Compute distance to nearest ZFE boundary (in meters) — also in chunks
cat("  Computing distance to ZFE boundary...\n")
zfe_boundary_line <- st_boundary(zfe_union)
dist_vec <- numeric(nrow(dvf))

for (ch in seq_len(n_chunks)) {
  idx_start <- (ch - 1) * chunk_size + 1
  idx_end <- min(ch * chunk_size, nrow(dvf))
  chunk_proj <- dvf_proj[idx_start:idx_end, ]
  dist_vec[idx_start:idx_end] <- as.numeric(st_distance(chunk_proj, zfe_boundary_line))
  if (ch %% 5 == 0) cat("    Chunk", ch, "/", n_chunks, "\n")
}

dvf$dist_to_zfe_m <- dist_vec

## Signed distance: negative = inside, positive = outside
dvf[, signed_dist_km := fifelse(inside_zfe == 1, -dist_to_zfe_m / 1000, dist_to_zfe_m / 1000)]

cat("  Distance stats (km):\n")
cat("    Median:", round(median(dvf$signed_dist_km, na.rm = TRUE), 2), "\n")
cat("    Range:", round(min(dvf$signed_dist_km, na.rm = TRUE), 2), "to",
    round(max(dvf$signed_dist_km, na.rm = TRUE), 2), "\n")

## =========================================================================
## D. Assign city and treatment timing
## =========================================================================

cat("\n=== D. Assigning city and treatment timing ===\n")

## Map departments to metro areas
dept_to_city <- data.table(
  code_departement = c("75", "92", "93", "94",
                        "69", "38", "76", "31",
                        "06", "13", "34", "42", "63", "51"),
  city = c(rep("paris", 4),
           "lyon", "grenoble", "rouen", "toulouse",
           "nice", "marseille", "montpellier", "saint_etienne",
           "clermont_ferrand", "reims")
)
## Note: Code_departement in DVF is character (e.g. "75", "06")
dvf[, code_departement := as.character(code_departement)]

dvf <- merge(dvf, dept_to_city, by = "code_departement", all.x = TRUE)

## ZFE adoption dates
zfe_dates <- data.table(
  city = c("paris", "lyon", "grenoble", "rouen", "toulouse",
           "nice", "marseille", "montpellier", "saint_etienne",
           "clermont_ferrand", "reims"),
  zfe_start_date = as.Date(c("2017-01-01", "2020-01-01", "2019-05-01",
                               "2021-09-01", "2022-03-01",
                               "2022-01-01", "2022-09-01", "2022-07-01",
                               "2022-01-01", "2023-01-01", "2023-01-01")),
  zfe_start_yq = c("2017Q1", "2020Q1", "2019Q2", "2021Q3", "2022Q1",
                     "2022Q1", "2022Q3", "2022Q3", "2022Q1", "2023Q1", "2023Q1")
)

dvf <- merge(dvf, zfe_dates, by = "city", all.x = TRUE)

## Treatment indicator: inside ZFE AND after adoption
dvf[, post_zfe := as.integer(date >= zfe_start_date)]
dvf[, treated := inside_zfe * post_zfe]

## For CS-DiD: cohort = year-quarter of ZFE adoption
dvf[, cohort_yq := zfe_start_yq]

## Time period as numeric for DiD
dvf[, time_numeric := year + (quarter - 1) / 4]

cat("  Treatment summary:\n")
print(dvf[, .(N = .N, pct_treated = round(mean(treated) * 100, 1)), by = city])

## =========================================================================
## E. Create analysis samples
## =========================================================================

cat("\n=== E. Creating analysis samples ===\n")

## Sample 1: Boundary sample (within 2km of ZFE boundary)
dvf_boundary <- dvf[abs(signed_dist_km) <= 2]
cat("  Boundary sample (2km):", format(nrow(dvf_boundary), big.mark = ","), "\n")

## Sample 2: Narrow boundary (1km)
dvf_narrow <- dvf[abs(signed_dist_km) <= 1]
cat("  Narrow boundary (1km):", format(nrow(dvf_narrow), big.mark = ","), "\n")

## Sample 3: Residential only
dvf_residential <- dvf_boundary[property_type %in% c("house", "apartment")]
cat("  Residential boundary:", format(nrow(dvf_residential), big.mark = ","), "\n")

## Sample 4: Commercial (placebo)
dvf_commercial <- dvf_boundary[property_type %in% c("commercial", "industrial")]
cat("  Commercial boundary:", format(nrow(dvf_commercial), big.mark = ","), "\n")

## Distance rings for gradient analysis
dvf[, dist_ring := fcase(
  signed_dist_km <= -2, "deep_inside",
  signed_dist_km > -2 & signed_dist_km <= -1, "inside_1_2km",
  signed_dist_km > -1 & signed_dist_km <= -0.5, "inside_05_1km",
  signed_dist_km > -0.5 & signed_dist_km <= 0, "inside_0_05km",
  signed_dist_km > 0 & signed_dist_km <= 0.5, "outside_0_05km",
  signed_dist_km > 0.5 & signed_dist_km <= 1, "outside_05_1km",
  signed_dist_km > 1 & signed_dist_km <= 2, "outside_1_2km",
  signed_dist_km > 2, "far_outside"
)]

## =========================================================================
## F. Merge air quality data (if available)
## =========================================================================

cat("\n=== F. Merging air quality data ===\n")

dvf <- merge(dvf, air_quality, by.x = c("city", "month"),
             by.y = c("city", "month"), all.x = TRUE)

cat("  Transactions with AQ data:", sum(!is.na(dvf$mean_no2)), "\n")

## =========================================================================
## G. Save analysis datasets
## =========================================================================

cat("\n=== G. Saving analysis datasets ===\n")

fwrite(dvf, file.path(data_dir, "dvf_analysis_full.csv"))
fwrite(dvf_boundary, file.path(data_dir, "dvf_boundary_2km.csv"))
fwrite(dvf_narrow, file.path(data_dir, "dvf_boundary_1km.csv"))
fwrite(dvf_residential, file.path(data_dir, "dvf_residential_boundary.csv"))
fwrite(dvf_commercial, file.path(data_dir, "dvf_commercial_boundary.csv"))

cat("\nAnalysis datasets saved.\n")

## Summary statistics
cat("\n=== Summary Statistics ===\n")
cat("Full sample:\n")
cat("  N transactions:", format(nrow(dvf), big.mark = ","), "\n")
cat("  N cities:", dvf[, uniqueN(city)], "\n")
cat("  Year range:", min(dvf$year), "-", max(dvf$year), "\n")
cat("  Mean price/m2:", round(mean(dvf$price_m2, na.rm = TRUE)), "EUR\n")
cat("  Median price/m2:", round(median(dvf$price_m2, na.rm = TRUE)), "EUR\n")
cat("  Share inside ZFE:", round(mean(dvf$inside_zfe) * 100, 1), "%\n")
cat("  Share treated (inside x post):", round(mean(dvf$treated) * 100, 1), "%\n")
