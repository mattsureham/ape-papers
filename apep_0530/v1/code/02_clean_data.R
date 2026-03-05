## 02_clean_data.R — Construct analysis dataset
## Match DVF transactions to QPV 2015 boundaries, compute distances

source("00_packages.R")

data_dir <- "../data"
dvf_dir <- file.path(data_dir, "dvf")

# ── 1. Load classified QPV zones ─────────────────────────────────────────────
cat("=== Loading classified QPV zones ===\n")
qpv <- readRDS(file.path(data_dir, "qpv_classified.rds"))
cat("QPV zones:", nrow(qpv), "\n")
cat("  Gained:", sum(qpv$zone_type == "gained"), "\n")
cat("  Retained:", sum(qpv$zone_type == "retained"), "\n")

# Standardize and fix invalid geometries
qpv_std <- qpv[, c("zone_type", "boundary_id")]
qpv_std <- st_make_valid(qpv_std)

# Create boundary-only version (cast polygons to lines) for distance computation
# st_distance to polygon returns 0 for inside points; we need distance to boundary edge
qpv_boundaries <- st_cast(st_boundary(qpv_std), "MULTILINESTRING")

# ── 2. Create buffer for filtering ──────────────────────────────────────────
cat("\nCreating 2km buffer around all QPV zones...\n")
# Buffer each zone individually then union (avoids topology errors)
zones_buffered <- st_buffer(qpv_std, 2000)
zones_buffer <- st_union(zones_buffered)

# ── 3. Process DVF year by year ──────────────────────────────────────────────
cat("\n=== Processing DVF transactions ===\n")

max_bandwidth <- 2000  # Keep all within 2km

dvf_files <- sort(list.files(dvf_dir, pattern = "dvf_\\d{4}\\.csv$", full.names = TRUE))
all_matched <- list()

for (dvf_file in dvf_files) {
  yr <- as.integer(gsub(".*dvf_(\\d{4})\\.csv", "\\1", dvf_file))
  cat("\n  Processing year", yr, "...")

  dt <- fread(dvf_file, showProgress = FALSE)

  # Basic cleaning
  dt <- dt[!is.na(latitude) & !is.na(longitude) &
           !is.na(valeur_fonciere) & valeur_fonciere > 0 &
           !is.na(surface_reelle_bati) & surface_reelle_bati > 0]

  # Keep only sales
  if ("nature_mutation" %in% names(dt)) {
    dt <- dt[grepl("Vente", nature_mutation, ignore.case = TRUE)]
  }

  # Keep only houses and apartments
  if ("type_local" %in% names(dt)) {
    dt <- dt[type_local %in% c("Maison", "Appartement")]
  }

  # Price per sqm
  dt[, price_sqm := valeur_fonciere / surface_reelle_bati]
  dt <- dt[price_sqm > 100 & price_sqm < 30000]
  dt <- dt[surface_reelle_bati >= 9 & surface_reelle_bati <= 500]

  if (nrow(dt) == 0) { cat(" no valid transactions\n"); next }

  # Convert to sf
  dt_sf <- st_as_sf(dt, coords = c("longitude", "latitude"), crs = 4326)
  dt_sf <- st_transform(dt_sf, 2154)

  # Filter to 2km buffer
  in_buffer <- st_intersects(dt_sf, zones_buffer, sparse = TRUE)
  dt_sf <- dt_sf[lengths(in_buffer) > 0, ]

  if (nrow(dt_sf) == 0) { cat(" no transactions near zones\n"); next }
  cat(format(nrow(dt_sf), big.mark = ","), "near zones...")

  # Check inside which QPV zones
  inside_qpv <- st_intersects(dt_sf, qpv_std, sparse = TRUE)
  dt_sf$inside <- lengths(inside_qpv) > 0

  # For those inside, get the zone type
  dt_sf$inside_zone_type <- NA_character_
  for (i in which(dt_sf$inside)) {
    idx <- inside_qpv[[i]][1]
    dt_sf$inside_zone_type[i] <- qpv_std$zone_type[idx]
  }

  # Find nearest QPV boundary
  n_trans <- nrow(dt_sf)
  chunk_size <- 3000
  n_chunks <- ceiling(n_trans / chunk_size)

  nearest_bid <- character(n_trans)
  nearest_type <- character(n_trans)
  nearest_dist <- numeric(n_trans)

  for (ch in seq_len(n_chunks)) {
    i1 <- (ch - 1) * chunk_size + 1
    i2 <- min(ch * chunk_size, n_trans)
    chunk <- dt_sf[i1:i2, ]

    dists <- st_distance(chunk, qpv_boundaries)
    min_idx <- apply(dists, 1, which.min)
    min_dist <- sapply(seq_along(min_idx), function(j) as.numeric(dists[j, min_idx[j]]))

    nearest_bid[i1:i2] <- qpv_std$boundary_id[min_idx]
    nearest_type[i1:i2] <- qpv_std$zone_type[min_idx]
    nearest_dist[i1:i2] <- min_dist
  }

  # Build result
  result <- data.table(
    year = yr,
    id_mutation = dt_sf$id_mutation,
    date_mutation = if ("date_mutation" %in% names(dt_sf)) dt_sf$date_mutation else NA,
    valeur_fonciere = dt_sf$valeur_fonciere,
    price_sqm = dt_sf$price_sqm,
    surface = dt_sf$surface_reelle_bati,
    rooms = if ("nombre_pieces_principales" %in% names(dt_sf))
      dt_sf$nombre_pieces_principales else NA_integer_,
    type_local = dt_sf$type_local,
    code_commune = if ("code_commune" %in% names(dt_sf)) dt_sf$code_commune else NA,
    inside = dt_sf$inside,
    nearest_boundary_id = nearest_bid,
    nearest_group = nearest_type,
    dist_to_boundary = nearest_dist
  )

  result <- result[dist_to_boundary <= max_bandwidth]
  all_matched[[length(all_matched) + 1]] <- result
  cat(" kept", format(nrow(result), big.mark = ","), "\n")
}

# ── 4. Combine and construct variables ───────────────────────────────────────
cat("\n=== Constructing analysis dataset ===\n")

panel <- rbindlist(all_matched, fill = TRUE)

# Signed distance: negative = inside, positive = outside
panel[, signed_dist := ifelse(inside, -dist_to_boundary, dist_to_boundary)]

# Treatment indicators (no pre/post — all data is post-2015 reform)
panel[, is_gained := as.integer(nearest_group == "gained")]
panel[, is_retained := as.integer(nearest_group == "retained")]
panel[, inside_int := as.integer(inside)]
panel[, inside_x_gained := inside_int * is_gained]
panel[, inside_x_retained := inside_int * is_retained]

# Log price
panel[, log_price_sqm := log(price_sqm)]
panel[, is_apartment := as.integer(type_local == "Appartement")]
panel[, transaction_year := year]

cat("\nFinal panel:\n")
cat("  Total transactions:", format(nrow(panel), big.mark = ","), "\n")
cat("  Years:", paste(range(panel$year), collapse = "-"), "\n")
cat("  Unique boundaries:", uniqueN(panel$nearest_boundary_id), "\n")
cat("  By group:\n")
print(panel[, .N, by = nearest_group])
cat("  Inside vs outside:\n")
print(panel[, .N, by = inside])

# Save
fwrite(panel, file.path(data_dir, "analysis_panel.csv"))
cat("\nPanel saved:", format(nrow(panel), big.mark = ","), "rows\n")

# Summary stats
sumstats <- panel[, .(
  mean_price_sqm = mean(price_sqm, na.rm = TRUE),
  median_price_sqm = median(price_sqm, na.rm = TRUE),
  mean_surface = mean(surface, na.rm = TRUE),
  mean_rooms = mean(rooms, na.rm = TRUE),
  pct_apartment = mean(is_apartment, na.rm = TRUE),
  n_transactions = .N
), by = .(nearest_group, inside, year)]
fwrite(sumstats, file.path(data_dir, "summary_stats.csv"))

# Validation
stopifnot("Expected both groups" = uniqueN(panel$nearest_group) >= 2)
stopifnot("Expected inside and outside" = all(c(TRUE, FALSE) %in% panel$inside))
stopifnot("Expected substantial sample" = nrow(panel) > 10000)

cat("\n=== Data cleaning complete ===\n")
