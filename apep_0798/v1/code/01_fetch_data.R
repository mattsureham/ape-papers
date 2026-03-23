# ==============================================================================
# 01_fetch_data.R — Data acquisition for FASTag paper
# Paper: Frictionless Highways (apep_0798)
# ==============================================================================

source("code/00_packages.R")

data_dir <- "data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ── 1. Toll Plaza Data (already downloaded from GitHub) ──────────────────────
cat("Loading toll plaza data...\n")
plazas_raw <- fread(file.path(data_dir, "toll_plazas_raw.csv"))
stopifnot("Toll plaza data must exist and have rows" = nrow(plazas_raw) > 0)
cat(sprintf("  Loaded %d plaza-snapshot observations, %d unique plazas\n",
            nrow(plazas_raw), uniqueN(plazas_raw$id)))

# ── 2. India District Boundaries (GADM Level 2) ─────────────────────────────
cat("Downloading India district boundaries from GADM...\n")
gadm_file <- file.path(data_dir, "india_districts.rds")

if (!file.exists(gadm_file)) {
  india_gadm <- geodata::gadm(country = "IND", level = 2,
                               path = file.path(data_dir, "gadm_cache"))
  india_districts <- sf::st_as_sf(india_gadm)
  saveRDS(india_districts, gadm_file)
  cat(sprintf("  Downloaded %d districts from GADM\n", nrow(india_districts)))
} else {
  india_districts <- readRDS(gadm_file)
  cat(sprintf("  Loaded cached %d districts\n", nrow(india_districts)))
}

# ── 3. Assign Plazas to Districts via Spatial Join ──────────────────────────
cat("Assigning toll plazas to districts...\n")
plaza_locs <- unique(plazas_raw[!is.na(lat) & !is.na(lon), .(id, name, lat, lon)])

plaza_sf <- sf::st_as_sf(plaza_locs, coords = c("lon", "lat"), crs = 4326)
plaza_districts <- sf::st_join(plaza_sf, india_districts[, c("NAME_1", "NAME_2", "GID_2")])

plaza_district_map <- as.data.table(plaza_districts)
plaza_district_map[, geometry := NULL]
setnames(plaza_district_map, c("NAME_1", "NAME_2", "GID_2"),
         c("state_name", "district_name", "gid_2"))

cat(sprintf("  Mapped %d plazas to districts (%d states)\n",
            nrow(plaza_district_map), uniqueN(plaza_district_map$state_name)))

fwrite(plaza_district_map, file.path(data_dir, "plaza_district_map.csv"))

# ── 4. VIIRS Annual Nightlights via blackmarbler ────────────────────────────
cat("Attempting VIIRS nightlights extraction...\n")
viirs_file <- file.path(data_dir, "district_nightlights.csv")

nasa_token <- Sys.getenv("NASA_EARTHDATA_API_KEY")

if (!file.exists(viirs_file) && nchar(nasa_token) > 0) {
  # Try blackmarbler package
  if (requireNamespace("blackmarbler", quietly = TRUE)) {
    library(blackmarbler)

    years_to_get <- 2015:2023

    nl_list <- list()
    for (yr in years_to_get) {
      cat(sprintf("  Extracting VIIRS for %d...\n", yr))
      tryCatch({
        bm_yr <- bm_extract(
          roi_sf = india_districts,
          product_id = "VNP46A4",
          date = yr,
          bearer = nasa_token,
          output_location_type = "memory",
          aggregation_fun = "mean",
          quiet = TRUE
        )
        bm_dt <- as.data.table(bm_yr)
        bm_dt[, year := yr]
        nl_list[[as.character(yr)]] <- bm_dt
        cat(sprintf("    %d: OK (%d districts)\n", yr, nrow(bm_dt)))
      }, error = function(e) {
        cat(sprintf("    %d: FAILED — %s\n", yr, conditionMessage(e)))
      })
    }

    if (length(nl_list) > 0) {
      nl_panel <- rbindlist(nl_list, fill = TRUE)
      fwrite(nl_panel, viirs_file)
      cat(sprintf("  Saved nightlights: %d observations\n", nrow(nl_panel)))
    }
  } else {
    cat("  blackmarbler not available. Trying direct VIIRS download...\n")
  }
}

# ── 5. Alternative: Construct Nightlights from NOAA EOG ─────────────────────
# If blackmarbler failed, download VIIRS v2.2 annual average_masked composites
if (!file.exists(viirs_file)) {
  cat("Attempting direct VIIRS download from NOAA EOG...\n")
  viirs_cache <- file.path(data_dir, "viirs_cache")
  dir.create(viirs_cache, showWarnings = FALSE, recursive = TRUE)

  # VIIRS v2.2 annual average tiles covering India
  # India spans approx lon 68-97, lat 6-37
  # Tile naming: {lat_band}N{lon_band}E
  # 75N tiles = lat 0-75 (covers India); lon bands = 060E, 075E, 090E

  years <- 2015:2023
  india_ext <- terra::ext(68, 98, 5, 38)

  # Convert districts to terra::vect for extraction
  districts_vect <- terra::vect(india_districts)

  nl_results <- list()

  for (yr in years) {
    cat(sprintf("  Year %d: ", yr))

    # Try multiple URL patterns used by EOG
    tile_patterns <- c(
      # Pattern 1: v22 with tile naming
      sprintf("https://eogdata.mines.edu/nighttime_light/annual/v22/%d/VNP46A4/VNP46A4_t75N060E_%d.tif", yr, yr),
      # Pattern 2: vcm composites (global file)
      sprintf("https://eogdata.mines.edu/nighttime_light/annual/vnl/v22/VNP46A4/average/%d/VNP46A4_%d_global_average_masked.tif", yr, yr)
    )

    got_data <- FALSE
    for (url in tile_patterns) {
      tile_dest <- file.path(viirs_cache, sprintf("viirs_%d.tif", yr))
      if (!file.exists(tile_dest)) {
        resp <- tryCatch({
          download.file(url, tile_dest, mode = "wb", quiet = TRUE, timeout = 300)
          TRUE
        }, error = function(e) FALSE)
        if (!resp || file.size(tile_dest) < 1000) {
          unlink(tile_dest)
          next
        }
      }
      if (file.exists(tile_dest)) {
        got_data <- TRUE
        break
      }
    }

    if (got_data) {
      tryCatch({
        r <- terra::rast(tile_dest)
        r_india <- terra::crop(r, india_ext)
        vals <- terra::extract(r_india, districts_vect, fun = mean, na.rm = TRUE)

        nl_results[[as.character(yr)]] <- data.table(
          district_idx = seq_len(nrow(india_districts)),
          year = yr,
          mean_nl = vals[, 2]
        )
        cat("OK\n")
        rm(r, r_india, vals); gc()
      }, error = function(e) {
        cat(sprintf("extraction failed: %s\n", conditionMessage(e)))
      })
    } else {
      cat("no tiles found\n")
    }
  }

  if (length(nl_results) > 0) {
    nl_panel <- rbindlist(nl_results)
    # Attach district names
    dist_ids <- data.table(
      district_idx = seq_len(nrow(india_districts)),
      state_name = india_districts$NAME_1,
      district_name = india_districts$NAME_2,
      gid_2 = india_districts$GID_2
    )
    nl_panel <- merge(nl_panel, dist_ids, by = "district_idx")
    fwrite(nl_panel, viirs_file)
    cat(sprintf("  District nightlights saved: %d obs\n", nrow(nl_panel)))
  }
}

# ── 6. Final Fallback: Construct proxy from toll revenue trends ─────────────
# If nightlights unavailable, the analysis focuses on plaza-level traffic data
# which is already loaded. Economic spillovers will use cumulative_revenue trend.

if (!file.exists(viirs_file)) {
  cat("\nWARNING: Nightlights data unavailable. Paper will focus on plaza-level analysis.\n")
  cat("Creating plaza revenue panel as primary outcome.\n")

  # Ensure we have revenue data from the toll plazas
  revenue_panel <- plazas_raw[, .(id, name, lat, lon, snapshot_date,
                                   traffic_per_day, cumulative_revenue)]
  revenue_panel[, snapshot_date := as.Date(snapshot_date)]
  fwrite(revenue_panel, file.path(data_dir, "plaza_revenue_panel.csv"))
  cat(sprintf("  Plaza revenue panel: %d obs\n", nrow(revenue_panel)))
}

# ── 7. Data Validation ─────────────────────────────────────────────────────
cat("\n=== FINAL DATA VALIDATION ===\n")

# Must have toll plazas
cat(sprintf("Toll plazas: %d unique, %d snapshots spanning %s to %s\n",
            uniqueN(plazas_raw$id),
            uniqueN(plazas_raw$snapshot_date),
            min(plazas_raw$snapshot_date),
            max(plazas_raw$snapshot_date)))

# Must have pre and post mandate data
pre_dates <- plazas_raw[as.Date(snapshot_date) < as.Date("2021-02-16"),
                         uniqueN(snapshot_date)]
post_dates <- plazas_raw[as.Date(snapshot_date) >= as.Date("2021-02-16"),
                          uniqueN(snapshot_date)]
cat(sprintf("Pre-mandate snapshots: %d | Post-mandate snapshots: %d\n",
            pre_dates, post_dates))
stopifnot("Need pre-mandate data" = pre_dates >= 3)
stopifnot("Need post-mandate data" = post_dates >= 3)

# Districts
cat(sprintf("Districts: %d GADM polygons\n", nrow(india_districts)))

# Plaza-district mapping
pdm <- fread(file.path(data_dir, "plaza_district_map.csv"))
cat(sprintf("Plazas mapped to districts: %d plazas in %d districts\n",
            nrow(pdm), uniqueN(pdm$gid_2)))

# Nightlights
if (file.exists(viirs_file)) {
  nl <- fread(viirs_file)
  cat(sprintf("Nightlights: %d district-years, %d years (%d-%d)\n",
              nrow(nl), uniqueN(nl$year), min(nl$year), max(nl$year)))
} else {
  cat("Nightlights: NOT AVAILABLE — using plaza traffic data only\n")
}

cat("\nData acquisition complete.\n")
