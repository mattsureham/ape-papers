## 02_clean_data.R — Compute signed distances from transactions to QPV boundaries
## APEP-0740: QPV Designation Paradox
## Optimized: computes distance to QPV union boundary (single geometry)

source("00_packages.R")
script_dir <- tryCatch(dirname(sys.frame(1)$ofile), error = function(e) ".")
setwd(file.path(script_dir, ".."))
data_dir <- "data"

cat("=== Loading QPV boundaries ===\n")
qpv <- sf::st_read(file.path(data_dir, "qpv_boundaries.geojson"), quiet = TRUE)
qpv <- sf::st_transform(qpv, 2154)  # Lambert-93 (meters)
qpv <- sf::st_make_valid(qpv)
cat(sprintf("QPV features: %d\n", nrow(qpv)))

## Assign each QPV a numeric ID for boundary-segment FE
qpv$qpv_id <- seq_len(nrow(qpv))

## Create union of all QPV polygons and extract its boundary
cat("Creating QPV union and boundary...\n")
qpv_union <- sf::st_union(qpv)
qpv_union_boundary <- sf::st_boundary(qpv_union)

## Create 2km buffer for spatial filtering
qpv_buffer <- sf::st_buffer(qpv_union, dist = 2000)

cat("\n=== Processing DVF year by year ===\n")

dvf_cols <- c("date_mutation", "nature_mutation", "valeur_fonciere",
              "type_local", "surface_reelle_bati", "nombre_pieces_principales",
              "longitude", "latitude", "code_commune", "code_departement")

results <- list()

for (yr in 2020:2024) {
  dvf_file <- file.path(data_dir, sprintf("dvf_%d.csv.gz", yr))
  if (!file.exists(dvf_file)) {
    cat(sprintf("  Skipping %d: file not found\n", yr))
    next
  }

  cat(sprintf("Processing DVF %d...\n", yr))

  dt <- tryCatch({
    data.table::fread(dvf_file, select = dvf_cols, na.strings = c("", "NA"))
  }, error = function(e) {
    cat(sprintf("  Error with select, reading all columns for %d\n", yr))
    raw <- data.table::fread(dvf_file, na.strings = c("", "NA"))
    cols_avail <- intersect(dvf_cols, names(raw))
    raw[, ..cols_avail]
  })

  cat(sprintf("  Raw rows: %s\n", format(nrow(dt), big.mark = ",")))

  ## Filter to sales of apartments and houses
  dt <- dt[nature_mutation == "Vente"]
  dt <- dt[type_local %in% c("Appartement", "Maison")]
  dt <- dt[!is.na(valeur_fonciere) & valeur_fonciere > 0]
  dt <- dt[!is.na(longitude) & !is.na(latitude)]
  dt <- dt[!is.na(surface_reelle_bati) & surface_reelle_bati > 0]

  dt[, price_m2 := valeur_fonciere / surface_reelle_bati]
  dt <- dt[price_m2 >= 100 & price_m2 <= 30000]
  dt <- unique(dt, by = c("date_mutation", "valeur_fonciere", "longitude", "latitude"))

  cat(sprintf("  After cleaning: %s transactions\n", format(nrow(dt), big.mark = ",")))
  if (nrow(dt) == 0) next

  ## Convert to sf points
  pts <- sf::st_as_sf(dt, coords = c("longitude", "latitude"), crs = 4326)
  pts <- sf::st_transform(pts, 2154)

  ## Filter to 2km buffer
  in_buffer <- sf::st_intersects(pts, qpv_buffer, sparse = FALSE)[, 1]
  pts <- pts[in_buffer, ]
  cat(sprintf("  Within 2km of QPV: %s transactions\n", format(nrow(pts), big.mark = ",")))
  if (nrow(pts) == 0) next

  ## Determine inside/outside QPV
  inside_qpv <- sf::st_intersects(pts, qpv_union, sparse = FALSE)[, 1]
  cat(sprintf("  Inside QPV: %s (%.1f%%)\n",
              format(sum(inside_qpv), big.mark = ","), 100 * mean(inside_qpv)))

  ## Compute distance to QPV union boundary (FAST: single geometry)
  cat("  Computing distances to QPV boundary...\n")
  dist_to_boundary <- as.numeric(sf::st_distance(sf::st_geometry(pts), qpv_union_boundary))

  ## Signed distance: positive = inside QPV, negative = outside
  signed_dist <- ifelse(inside_qpv, dist_to_boundary, -dist_to_boundary)

  ## Find nearest QPV for boundary-segment FE (use centroids for speed)
  cat("  Assigning nearest QPV IDs...\n")
  qpv_centroids <- sf::st_centroid(qpv)
  nearest_qpv <- sf::st_nearest_feature(pts, qpv_centroids)

  ## Build output
  out <- data.table::data.table(
    date = as.Date(pts$date_mutation),
    price = pts$valeur_fonciere,
    price_m2 = pts$price_m2,
    surface = pts$surface_reelle_bati,
    rooms = pts$nombre_pieces_principales,
    type = pts$type_local,
    commune = pts$code_commune,
    dept = pts$code_departement,
    inside_qpv = inside_qpv,
    dist_to_boundary = dist_to_boundary,
    signed_dist = signed_dist,
    nearest_qpv_id = nearest_qpv,
    year = yr
  )

  results[[as.character(yr)]] <- out
  cat(sprintf("  Kept: %s obs\n", format(nrow(out), big.mark = ",")))

  rm(dt, pts, in_buffer, inside_qpv, dist_to_boundary, signed_dist, nearest_qpv, out)
  gc()
}

## Stack all years
cat("\n=== Combining all years ===\n")
analysis_data <- data.table::rbindlist(results, fill = TRUE)

if (nrow(analysis_data) == 0) {
  stop("FATAL: No transactions found within 2km of QPV boundaries.")
}

cat(sprintf("Total observations: %s\n", format(nrow(analysis_data), big.mark = ",")))
cat(sprintf("Years: %s\n", paste(sort(unique(analysis_data$year)), collapse = ", ")))
cat(sprintf("Inside QPV: %s (%.1f%%)\n",
            format(sum(analysis_data$inside_qpv), big.mark = ","),
            100 * mean(analysis_data$inside_qpv)))

## Derived variables
analysis_data[, log_price_m2 := log(price_m2)]
analysis_data[, year_quarter := paste0(year, "Q", data.table::quarter(date))]
analysis_data[, is_apartment := as.integer(type == "Appartement")]

## Save
data.table::fwrite(analysis_data, file.path(data_dir, "analysis_data.csv"))
cat(sprintf("\nSaved: %s\n", file.path(data_dir, "analysis_data.csv")))

## Summary stats
cat("\n=== Summary Statistics ===\n")
cat(sprintf("Median price/m2: %.0f EUR\n", median(analysis_data$price_m2)))
cat(sprintf("Mean dist to boundary: %.0f m\n", mean(abs(analysis_data$signed_dist))))
cat(sprintf("Obs within 500m: %s\n",
            format(sum(abs(analysis_data$signed_dist) <= 500), big.mark = ",")))
cat(sprintf("Unique QPVs represented: %d\n", length(unique(analysis_data$nearest_qpv_id))))
cat(sprintf("Unique communes: %d\n", length(unique(analysis_data$commune))))
