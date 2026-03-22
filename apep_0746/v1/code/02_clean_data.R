## 02_clean_data.R — Spatial RDD construction
## APEP-0746
## Strategy: extract boundaries, filter DVF to boundary sectors, compute distances

source("00_packages.R")

data_dir <- "../data"
MAX_BW <- 1000  # meters

## ===================================================================
## 1. Load data
## ===================================================================

cat("Loading DVF...\n")
dvf <- fread(file.path(data_dir, "dvf_geo.csv.gz"))
cat(sprintf("DVF: %d rows\n", nrow(dvf)))

cat("Loading college sectors...\n")
sectors <- st_read(file.path(data_dir, "college_sectors.geojson"), quiet = TRUE)
cat(sprintf("Sectors: %d polygons\n", nrow(sectors)))

cat("Loading REP list...\n")
rep_list <- fread(file.path(data_dir, "rep_colleges.csv"), sep = ";", encoding = "UTF-8")

## ===================================================================
## 2. Build REP status and join to sectors
## ===================================================================

rep_list[, uai := `Numéro établissement`]
rep_list[, ep_status := `Appartenance EP`]
rep_list[, rs := `Rentrée scolaire`]
rep_latest <- rep_list[, .SD[which.max(rs)], by = uai]
rep_lookup <- rep_latest[, .(uai, ep_status)]

# Map ECLAIR -> REP+, REPPLUS -> REP+, RRS -> REP
rep_lookup[, ep_clean := fifelse(ep_status %in% c("REPPLUS", "ECLAIR"), "REP+",
                          fifelse(ep_status == "RRS", "REP",
                          fifelse(ep_status == "REP", "REP", "HEP")))]

cat("EP status (cleaned):\n")
print(table(rep_lookup$ep_clean))

sectors$ep_status <- rep_lookup$ep_clean[match(sectors$codeRNE, rep_lookup$uai)]
sectors$is_rep <- sectors$ep_status %in% c("REP", "REP+")
sectors$is_rep[is.na(sectors$is_rep)] <- FALSE
sectors$ep_status[is.na(sectors$ep_status)] <- "HEP"

cat(sprintf("Sectors: %d REP/REP+, %d non-REP\n",
            sum(sectors$is_rep), sum(!sectors$is_rep)))

# Project to Lambert-93
sectors_proj <- st_transform(sectors, 2154)
sectors_proj$row_id <- seq_len(nrow(sectors_proj))

## ===================================================================
## 3. Identify boundary sectors
## ===================================================================

cat("Finding adjacent sectors...\n")
adj <- st_touches(sectors_proj)

boundary_sector_ids <- integer(0)
boundary_pairs <- list()

for (i in seq_len(nrow(sectors_proj))) {
  nbrs <- adj[[i]]
  if (length(nbrs) == 0) next
  nbr_rep <- sectors_proj$is_rep[nbrs]
  if (any(nbr_rep != sectors_proj$is_rep[i])) {
    boundary_sector_ids <- c(boundary_sector_ids, i)
    opp_nbrs <- nbrs[nbr_rep != sectors_proj$is_rep[i]]
    for (j in opp_nbrs) {
      if (j > i) {
        boundary_pairs[[length(boundary_pairs) + 1]] <- c(i, j)
      }
    }
  }
}

boundary_sector_ids <- unique(boundary_sector_ids)
cat(sprintf("Boundary sectors: %d | Pairs: %d\n",
            length(boundary_sector_ids), length(boundary_pairs)))

## ===================================================================
## 4. Extract shared boundary lines (cached)
## ===================================================================

seg_cache <- file.path(data_dir, "boundary_segments.rds")

if (!file.exists(seg_cache)) {
  cat("Extracting boundary lines...\n")
  sf_use_s2(FALSE)

  seg_lines <- list()
  seg_ids <- character(0)

  for (k in seq_along(boundary_pairs)) {
    if (k %% 500 == 0) cat(sprintf("  %d/%d\n", k, length(boundary_pairs)))
    i <- boundary_pairs[[k]][1]
    j <- boundary_pairs[[k]][2]

    shared <- tryCatch(
      st_intersection(st_geometry(sectors_proj)[i], st_geometry(sectors_proj)[j]),
      error = function(e) NULL
    )

    if (is.null(shared) || any(st_is_empty(shared))) next
    gtype <- as.character(st_geometry_type(shared))

    if (gtype == "GEOMETRYCOLLECTION") {
      parts <- tryCatch(st_collection_extract(shared, "LINESTRING"), error = function(e) NULL)
      if (is.null(parts) || length(parts) == 0 || all(st_is_empty(parts))) next
      shared <- st_union(parts)
    } else if (!(gtype %in% c("LINESTRING", "MULTILINESTRING"))) {
      next
    }

    if (any(st_is_empty(shared))) next
    seg_lines[[length(seg_lines) + 1]] <- shared
    seg_ids <- c(seg_ids, paste0("seg_", i, "_", j))
  }

  cat(sprintf("Valid segments: %d\n", length(seg_lines)))
  boundary_geom <- do.call(c, seg_lines)
  boundary_sf <- st_sf(seg_id = seg_ids, seg_idx = seq_along(seg_ids),
                         geometry = boundary_geom)
  saveRDS(boundary_sf, seg_cache)
  cat("Boundary segments cached.\n")
} else {
  cat("Loading cached boundary segments...\n")
  boundary_sf <- readRDS(seg_cache)
  cat(sprintf("Segments: %d\n", nrow(boundary_sf)))
}

## ===================================================================
## 5. Filter DVF to boundary sectors, assign REP status
## ===================================================================

cat("Converting DVF to spatial...\n")
dvf_sf <- st_as_sf(dvf, coords = c("longitude", "latitude"), crs = 4326)
dvf_sf <- st_transform(dvf_sf, 2154)

cat("Assigning DVF to boundary sectors...\n")
# Only join with boundary sectors (much faster than all 43K)
bnd_sectors <- sectors_proj[boundary_sector_ids, c("codeRNE", "is_rep", "ep_status", "row_id")]
dvf_joined <- st_join(dvf_sf, bnd_sectors, join = st_within, left = FALSE)

# Deduplicate
dvf_joined <- dvf_joined[!duplicated(dvf_joined$id_mutation), ]
cat(sprintf("DVF in boundary sectors: %d\n", nrow(dvf_joined)))

## ===================================================================
## 6. Compute distance to nearest boundary (in batches)
## ===================================================================

cat("Computing distances to boundary (batched)...\n")

BATCH <- 10000
n_pts <- nrow(dvf_joined)
dist_vals <- numeric(n_pts)
near_seg <- integer(n_pts)

for (b in seq(1, n_pts, by = BATCH)) {
  end <- min(b + BATCH - 1, n_pts)
  if (b %% 50000 == 1) cat(sprintf("  Batch %d-%d / %d\n", b, end, n_pts))

  batch_pts <- dvf_joined[b:end, ]
  idx <- st_nearest_feature(batch_pts, boundary_sf)
  d <- st_distance(batch_pts, boundary_sf[idx, ], by_element = TRUE)

  dist_vals[b:end] <- as.numeric(d)
  near_seg[b:end] <- boundary_sf$seg_idx[idx]
}

dvf_joined$dist_m <- dist_vals
dvf_joined$nearest_seg <- near_seg
dvf_joined$signed_dist_m <- ifelse(dvf_joined$is_rep, -dvf_joined$dist_m, dvf_joined$dist_m)

cat(sprintf("Distance: min=%.0f, median=%.0f, max=%.0f\n",
            min(dvf_joined$dist_m), median(dvf_joined$dist_m), max(dvf_joined$dist_m)))

## ===================================================================
## 7. Final dataset
## ===================================================================

dvf_final <- dvf_joined[dvf_joined$dist_m <= MAX_BW, ]
cat(sprintf("Within %dm: %d\n", MAX_BW, nrow(dvf_final)))

analysis_dt <- as.data.table(st_drop_geometry(dvf_final))
analysis_dt[, log_price := log(valeur_fonciere)]
analysis_dt[, date_mutation := as.Date(date_mutation)]
analysis_dt[, qtr := quarter(date_mutation)]
analysis_dt[, year_quarter := paste0(year, "Q", qtr)]
analysis_dt[, is_apt := as.integer(type_local == "Appartement")]

fwrite(analysis_dt, file.path(data_dir, "analysis_data.csv.gz"))
cat(sprintf("\nSaved: %d rows\n", nrow(analysis_dt)))

cat("\n=== Summary ===\n")
cat(sprintf("REP: %d | non-REP: %d\n", sum(analysis_dt$is_rep), sum(!analysis_dt$is_rep)))
cat(sprintf("REP+: %d | REP: %d\n",
            sum(analysis_dt$ep_status == "REP+"), sum(analysis_dt$ep_status == "REP")))
cat(sprintf("Segments: %d\n", uniqueN(analysis_dt$nearest_seg)))
cat(sprintf("Price REP: EUR %.0f | non-REP: EUR %.0f\n",
            mean(analysis_dt$valeur_fonciere[analysis_dt$is_rep]),
            mean(analysis_dt$valeur_fonciere[!analysis_dt$is_rep])))
cat(sprintf("SD(log price): %.4f\n", sd(analysis_dt$log_price)))
