## 01_fetch_data.R — Fetch wilderness boundaries and Hansen GFC data
## apep_0913: Wilderness spatial RDD
##
## Data sources:
## 1. WDPA (World Database on Protected Areas) — wilderness boundaries
## 2. Hansen Global Forest Change v1.11 — tree cover loss (30m)
## 3. elevatr — elevation data
## All sources are public, no API keys required.

source("00_packages.R")
data_dir <- file.path(dirname(getwd()), "data")
setwd(data_dir)
cat("Working directory:", getwd(), "\n")

# ============================================================
# 1. Read WDPA wilderness boundaries
# ============================================================
cat("Reading WDPA USA shapefile...\n")

# The WDPA zip contains multiple shapefiles (polygons split into parts)
if (!dir.exists("wdpa_raw")) {
  unzip("wdpa_usa.zip", exdir = "wdpa_raw")
}

# WDPA contains nested zip files — unzip those too
inner_zips <- list.files("wdpa_raw", pattern = "\\.zip$", full.names = TRUE)
for (iz in inner_zips) {
  out_dir <- file.path("wdpa_raw", tools::file_path_sans_ext(basename(iz)))
  if (!dir.exists(out_dir)) {
    cat("  Unzipping inner:", basename(iz), "\n")
    unzip(iz, exdir = out_dir)
  }
}

shp_files <- list.files("wdpa_raw", pattern = "polygons.*\\.shp$",
                        recursive = TRUE, full.names = TRUE)
cat("Found polygon shapefiles:", length(shp_files), "\n")

stopifnot("No shapefiles found in WDPA download" = length(shp_files) > 0)

# Read all polygon files and combine
wdpa_list <- lapply(shp_files, function(f) {
  cat("  Reading", basename(f), "...\n")
  tryCatch(st_read(f, quiet = TRUE), error = function(e) {
    cat("  Failed:", conditionMessage(e), "\n")
    NULL
  })
})
wdpa_list <- Filter(Negate(is.null), wdpa_list)
wdpa <- do.call(rbind, wdpa_list)
cat("Total WDPA features:", nrow(wdpa), "\n")
cat("Columns:", paste(names(wdpa), collapse = ", "), "\n")

# Filter for wilderness areas
# WDPA uses DESIG field for designation type
# Look for "Wilderness" in designation
desig_col <- NULL
for (candidate in c("DESIG", "DESIG_ENG", "desig", "Desig")) {
  if (candidate %in% names(wdpa)) {
    desig_col <- candidate
    break
  }
}

if (!is.null(desig_col)) {
  cat("\nDesignation types containing 'ilderness':\n")
  wild_desigs <- unique(wdpa[[desig_col]][grepl("ilderness", wdpa[[desig_col]], ignore.case = TRUE)])
  cat(paste(" -", wild_desigs), sep = "\n")

  wilderness <- wdpa[grepl("ilderness", wdpa[[desig_col]], ignore.case = TRUE), ]
  cat("\nWilderness areas:", nrow(wilderness), "\n")
} else {
  # Try IUCN category Ib (Wilderness Area)
  iucn_col <- NULL
  for (candidate in c("IUCN_CAT", "iucn_cat", "IUCNCAT")) {
    if (candidate %in% names(wdpa)) {
      iucn_col <- candidate
      break
    }
  }

  if (!is.null(iucn_col)) {
    cat("Using IUCN category Ib for wilderness...\n")
    wilderness <- wdpa[wdpa[[iucn_col]] == "Ib", ]
    cat("Wilderness areas (IUCN Ib):", nrow(wilderness), "\n")
  } else {
    stop("FATAL: Cannot identify wilderness areas in WDPA data. ",
         "Columns: ", paste(names(wdpa), collapse = ", "))
  }
}

if (nrow(wilderness) == 0) {
  stop("FATAL: No wilderness areas found in WDPA data.")
}

# Print name column to verify
name_col <- NULL
for (candidate in c("NAME", "name", "ORIG_NAME", "Name")) {
  if (candidate %in% names(wdpa)) {
    name_col <- candidate
    break
  }
}
if (!is.null(name_col)) {
  cat("\nSample wilderness area names:\n")
  cat(paste(" -", head(wilderness[[name_col]], 10)), sep = "\n")
}

# Save all wilderness
st_write(wilderness, "wilderness_all.gpkg", delete_dsn = TRUE, quiet = TRUE)
cat("\nSaved all US wilderness areas:", nrow(wilderness), "\n")

# Free memory
rm(wdpa, wdpa_list); gc()

# ============================================================
# 2. Focus on Western US wilderness areas
# ============================================================
cat("\nFiltering to Western US (prime timber country)...\n")

# Ensure WGS84
if (!is.na(st_crs(wilderness)$epsg) && st_crs(wilderness)$epsg != 4326) {
  wilderness <- st_transform(wilderness, 4326)
}

# Western US bounding box (WA, OR, CA, ID, MT, WY, CO, NV, UT, AZ, NM)
west_bbox <- st_bbox(c(xmin = -125, ymin = 31, xmax = -103, ymax = 49),
                     crs = st_crs(4326))
west_box <- st_as_sfc(west_bbox)

# Spatial filter
west_wild <- wilderness[st_intersects(wilderness, west_box, sparse = FALSE)[,1], ]
cat("Western wilderness areas:", nrow(west_wild), "\n")

# Further focus on PNW + Northern Rockies for maximum timber relevance
pnw_bbox <- st_bbox(c(xmin = -125, ymin = 40, xmax = -110, ymax = 49),
                    crs = st_crs(4326))
pnw_box <- st_as_sfc(pnw_bbox)
pnw_wild <- wilderness[st_intersects(wilderness, pnw_box, sparse = FALSE)[,1], ]
cat("PNW wilderness areas:", nrow(pnw_wild), "\n")

# Use western set if PNW has too few
if (nrow(pnw_wild) >= 50) {
  study_wild <- pnw_wild
  study_region <- "PNW"
} else if (nrow(west_wild) >= 50) {
  study_wild <- west_wild
  study_region <- "Western US"
} else {
  study_wild <- wilderness
  study_region <- "All US"
}
cat("Study region:", study_region, "with", nrow(study_wild), "wilderness areas\n")

st_write(study_wild, "study_wilderness.gpkg", delete_dsn = TRUE, quiet = TRUE)

# ============================================================
# 3. Generate sample points near boundaries
# ============================================================
cat("\nGenerating sample points near wilderness boundaries...\n")

# Transform to NAD83 Albers Equal Area for distance calculations
study_wild_proj <- st_transform(study_wild, 5070)

# Dissolve all wilderness into single multipolygon for inside/outside test
wild_union <- st_union(study_wild_proj)

# Get boundary lines
cat("Extracting boundary lines...\n")
boundaries <- st_cast(st_boundary(wild_union), "MULTILINESTRING")

# Create 5km buffer around boundaries
cat("Creating 5km buffer...\n")
buffer_5km <- st_buffer(boundaries, dist = 5000)

# Generate random points
set.seed(20260325)
n_target <- 500000
cat("Generating", n_target, "random points within 5km of boundaries...\n")

sample_pts <- st_sample(buffer_5km, size = n_target)
cat("Generated", length(sample_pts), "points\n")

sample_pts_sf <- st_as_sf(data.frame(id = seq_along(sample_pts)),
                          geometry = sample_pts)
st_crs(sample_pts_sf) <- 5070

# Compute signed distance
cat("Computing distance to nearest boundary...\n")
# For large point sets, compute in batches
batch_size <- 50000
n_pts <- nrow(sample_pts_sf)
dist_vals <- numeric(n_pts)

for (b in seq(1, n_pts, by = batch_size)) {
  end_b <- min(b + batch_size - 1, n_pts)
  dist_vals[b:end_b] <- as.numeric(st_distance(
    sample_pts_sf[b:end_b, ], boundaries
  ))
  cat("  Distance batch", b, "-", end_b, "done\n")
}

# Inside/outside wilderness
cat("Determining inside/outside wilderness...\n")
inside_vals <- logical(n_pts)
for (b in seq(1, n_pts, by = batch_size)) {
  end_b <- min(b + batch_size - 1, n_pts)
  inside_vals[b:end_b] <- st_intersects(
    sample_pts_sf[b:end_b, ], wild_union, sparse = FALSE
  )[, 1]
  cat("  Inside/outside batch", b, "-", end_b, "done\n")
}

# Signed distance: negative inside, positive outside
signed_dist <- ifelse(inside_vals, -dist_vals, dist_vals)
sample_pts_sf$dist_m <- signed_dist
sample_pts_sf$inside_wilderness <- inside_vals

cat("Points inside:", sum(inside_vals), "\n")
cat("Points outside:", sum(!inside_vals), "\n")

# Get WGS84 coordinates for raster extraction
sample_pts_wgs <- st_transform(sample_pts_sf, 4326)
coords <- st_coordinates(sample_pts_wgs)
sample_pts_sf$lon <- coords[, 1]
sample_pts_sf$lat <- coords[, 2]

# ============================================================
# 4. Extract Hansen GFC tree cover loss
# ============================================================
cat("\nExtracting Hansen GFC data...\n")

hansen_base <- "https://storage.googleapis.com/earthenginepartners-hansen/GFC-2023-v1.11/"

# Determine needed tiles (10x10 degree grid)
lon_range <- range(sample_pts_sf$lon, na.rm = TRUE)
lat_range <- range(sample_pts_sf$lat, na.rm = TRUE)
cat("Lon range:", round(lon_range, 2), "\n")
cat("Lat range:", round(lat_range, 2), "\n")

# Generate tile list
lat_tiles <- seq(ceiling(lat_range[2] / 10) * 10,
                 ceiling(lat_range[1] / 10) * 10, by = -10)
lon_tiles <- seq(floor(lon_range[1] / 10) * 10,
                 floor(lon_range[2] / 10) * 10, by = 10)
# Keep only valid tiles
lat_tiles <- lat_tiles[lat_tiles > 0]

cat("Tile grid: lats =", lat_tiles, ", lons =", lon_tiles, "\n")

# Initialize result vectors
lossyear_values <- rep(NA_integer_, n_pts)
treecover_values <- rep(NA_integer_, n_pts)

for (lat_t in lat_tiles) {
  for (lon_t in lon_tiles) {
    lat_str <- sprintf("%02dN", lat_t)
    lon_str <- sprintf("%03dW", abs(lon_t))

    # Identify points in this tile
    tile_mask <- sample_pts_sf$lon >= lon_t &
      sample_pts_sf$lon < (lon_t + 10) &
      sample_pts_sf$lat <= lat_t &
      sample_pts_sf$lat > (lat_t - 10)

    n_in_tile <- sum(tile_mask)
    if (n_in_tile == 0) {
      cat("Tile", lat_str, lon_str, ": 0 points, skipping\n")
      next
    }
    cat("Tile", lat_str, lon_str, ":", n_in_tile, "points\n")

    # Download and extract lossyear
    loss_file <- paste0("Hansen_GFC-2023-v1.11_lossyear_", lat_str, "_", lon_str, ".tif")
    loss_url <- paste0(hansen_base, loss_file)

    if (!file.exists(loss_file)) {
      cat("  Downloading lossyear...\n")
      dl_ok <- tryCatch({
        download.file(loss_url, loss_file, mode = "wb", quiet = TRUE)
        TRUE
      }, error = function(e) {
        cat("  FAILED:", conditionMessage(e), "\n")
        FALSE
      })
      if (!dl_ok) next
    }

    cat("  Extracting lossyear values...\n")
    tryCatch({
      r <- rast(loss_file)
      pts_vect <- vect(sample_pts_wgs[tile_mask, ])
      vals <- terra::extract(r, pts_vect)
      lossyear_values[tile_mask] <- vals[[2]]
      rm(r); gc(verbose = FALSE)
    }, error = function(e) {
      cat("  Extract failed:", conditionMessage(e), "\n")
    })

    # Download and extract treecover2000
    tc_file <- paste0("Hansen_GFC-2023-v1.11_treecover2000_", lat_str, "_", lon_str, ".tif")
    tc_url <- paste0(hansen_base, tc_file)

    if (!file.exists(tc_file)) {
      cat("  Downloading treecover2000...\n")
      dl_ok <- tryCatch({
        download.file(tc_url, tc_file, mode = "wb", quiet = TRUE)
        TRUE
      }, error = function(e) {
        cat("  FAILED:", conditionMessage(e), "\n")
        FALSE
      })
      if (!dl_ok) next
    }

    cat("  Extracting treecover values...\n")
    tryCatch({
      r <- rast(tc_file)
      pts_vect <- vect(sample_pts_wgs[tile_mask, ])
      vals <- terra::extract(r, pts_vect)
      treecover_values[tile_mask] <- vals[[2]]
      rm(r); gc(verbose = FALSE)
    }, error = function(e) {
      cat("  Extract failed:", conditionMessage(e), "\n")
    })
  }
}

cat("\nHansen extraction complete.\n")
cat("Points with lossyear data:", sum(!is.na(lossyear_values)), "\n")
cat("Points with treecover data:", sum(!is.na(treecover_values)), "\n")

# ============================================================
# 5. Extract elevation data
# ============================================================
cat("\nExtracting elevation...\n")

if (!requireNamespace("elevatr", quietly = TRUE)) {
  install.packages("elevatr", repos = "https://cloud.r-project.org", quiet = TRUE)
}
library(elevatr)

elev_values <- rep(NA_real_, n_pts)
elev_batch <- 50000

for (b in seq(1, n_pts, by = elev_batch)) {
  end_b <- min(b + elev_batch - 1, n_pts)
  cat("  Elevation batch", b, "-", end_b, "...\n")
  tryCatch({
    batch_pts <- sample_pts_wgs[b:end_b, ]
    elev_result <- get_elev_point(batch_pts, src = "aws", z = 9)
    elev_values[b:end_b] <- elev_result$elevation
  }, error = function(e) {
    cat("  WARNING:", conditionMessage(e), "\n")
  })
}

cat("Points with elevation:", sum(!is.na(elev_values)), "\n")

# ============================================================
# 6. Assemble and save
# ============================================================
cat("\nAssembling final dataset...\n")

analysis_df <- data.frame(
  id = 1:n_pts,
  lon = sample_pts_sf$lon,
  lat = sample_pts_sf$lat,
  dist_m = sample_pts_sf$dist_m,
  dist_km = sample_pts_sf$dist_m / 1000,
  inside_wilderness = sample_pts_sf$inside_wilderness,
  lossyear = lossyear_values,
  treecover2000 = treecover_values,
  elevation = elev_values,
  stringsAsFactors = FALSE
)

# Derived variables
analysis_df$any_loss <- as.integer(!is.na(analysis_df$lossyear) & analysis_df$lossyear > 0)
analysis_df$forested <- as.integer(!is.na(analysis_df$treecover2000) &
                                     analysis_df$treecover2000 >= 25)

# Compute slope from elevation differences (approximate using nearby points)
# Not critical for V1; elevation alone captures most terrain variation

# Drop pixels with no raster data
n_before <- nrow(analysis_df)
analysis_df <- analysis_df[!is.na(analysis_df$treecover2000), ]
cat("Dropped", n_before - nrow(analysis_df), "pixels with no raster coverage\n")

# Forested subset
analysis_forested <- analysis_df[analysis_df$forested == 1, ]

cat("\n=== FINAL DATASET ===\n")
cat("Total pixels:", nrow(analysis_df), "\n")
cat("Forested pixels:", nrow(analysis_forested), "\n")
cat("Inside wilderness:", sum(analysis_df$inside_wilderness), "\n")
cat("Outside wilderness:", sum(!analysis_df$inside_wilderness), "\n")
cat("\nTree cover loss rate:\n")
cat("  Inside wilderness:",
    round(mean(analysis_df$any_loss[analysis_df$inside_wilderness], na.rm = TRUE), 4), "\n")
cat("  Outside wilderness:",
    round(mean(analysis_df$any_loss[!analysis_df$inside_wilderness], na.rm = TRUE), 4), "\n")
cat("  Forested inside:",
    round(mean(analysis_forested$any_loss[analysis_forested$inside_wilderness], na.rm = TRUE), 4), "\n")
cat("  Forested outside:",
    round(mean(analysis_forested$any_loss[!analysis_forested$inside_wilderness], na.rm = TRUE), 4), "\n")

# Save
saveRDS(analysis_df, "analysis_full.rds")
saveRDS(analysis_forested, "analysis_forested.rds")
write.csv(head(analysis_df, 10000), "analysis_sample.csv", row.names = FALSE)

# Wilderness area count for paper
n_wilderness <- nrow(study_wild)
saveRDS(list(
  n_wilderness = n_wilderness,
  study_region = study_region,
  n_pixels_total = nrow(analysis_df),
  n_pixels_forested = nrow(analysis_forested)
), "metadata.rds")

cat("\nData saved successfully.\n")
