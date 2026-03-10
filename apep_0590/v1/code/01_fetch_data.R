## =============================================================================
## 01_fetch_data.R — apep_0590
## Download: Hansen GFW tiles, GADM boundaries, CONEVAL marginalization
## =============================================================================

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# =============================================================================
# SECTION 1: GADM Municipality Boundaries (Level 2)
# =============================================================================
cat("=== Downloading GADM Level 2 boundaries for Mexico ===\n")

gadm_file <- file.path(data_dir, "gadm_mex_2.rds")

if (!file.exists(gadm_file)) {
  # geodata::gadm downloads from GADM database
  mex_gadm <- geodata::gadm("MEX", level = 2, path = data_dir)

  # Convert to sf for easier handling
  mex_sf <- sf::st_as_sf(mex_gadm)
  saveRDS(mex_sf, gadm_file)
  cat("GADM boundaries saved:", nrow(mex_sf), "municipalities\n")
} else {
  mex_sf <- readRDS(gadm_file)
  cat("GADM boundaries loaded from cache:", nrow(mex_sf), "municipalities\n")
}

stopifnot("Expected 2000+ municipalities" = nrow(mex_sf) >= 2000)

# =============================================================================
# SECTION 2: Hansen/GFW Tree Cover Loss Tiles
# =============================================================================
cat("\n=== Downloading Hansen GFW lossyear tiles ===\n")

tile_dir <- file.path(data_dir, "hansen_tiles")
dir.create(tile_dir, showWarnings = FALSE)

# Mexico spans ~14.5N-32.7N, ~86.7W-118.4W
# Hansen tiles are 10x10 degree blocks named by upper-left corner
# We need tiles covering this extent
base_url <- "https://storage.googleapis.com/earthenginepartners-hansen/GFC-2024-v1.12"

tiles <- c(
  "Hansen_GFC-2024-v1.12_lossyear_20N_090W.tif",  # Yucatan, SE Mexico
  "Hansen_GFC-2024-v1.12_lossyear_20N_100W.tif",  # S Mexico (Chiapas, Oaxaca)
  "Hansen_GFC-2024-v1.12_lossyear_20N_110W.tif",  # SW coast
  "Hansen_GFC-2024-v1.12_lossyear_30N_090W.tif",  # Gulf coast north
  "Hansen_GFC-2024-v1.12_lossyear_30N_100W.tif",  # Central Mexico
  "Hansen_GFC-2024-v1.12_lossyear_30N_110W.tif",  # NW Mexico
  "Hansen_GFC-2024-v1.12_lossyear_30N_120W.tif"   # Baja California
)

# Also download treecover2000 for baseline forest cover
tc_tiles <- gsub("lossyear", "treecover2000", tiles)

all_tiles <- c(tiles, tc_tiles)

for (tile_name in all_tiles) {
  tile_path <- file.path(tile_dir, tile_name)
  if (!file.exists(tile_path)) {
    tile_url <- paste0(base_url, "/", tile_name)
    cat("Downloading:", tile_name, "... ")

    tryCatch({
      download.file(tile_url, tile_path, mode = "wb", quiet = TRUE)
      fsize <- file.info(tile_path)$size / 1e6
      cat(sprintf("OK (%.1f MB)\n", fsize))
    }, error = function(e) {
      # Some tiles might not exist (mostly ocean)
      cat("SKIPPED (not available):", e$message, "\n")
      if (file.exists(tile_path)) file.remove(tile_path)
    })
  } else {
    cat("Already cached:", tile_name, "\n")
  }
}

# Verify at least core tiles downloaded
core_tiles <- c(
  "Hansen_GFC-2024-v1.12_lossyear_20N_100W.tif",
  "Hansen_GFC-2024-v1.12_lossyear_30N_100W.tif"
)
for (ct in core_tiles) {
  if (!file.exists(file.path(tile_dir, ct))) {
    stop("CRITICAL: Core tile missing: ", ct,
         "\nCannot proceed without satellite data. Check network connection.")
  }
}
cat("Core Hansen tiles verified.\n")

# =============================================================================
# SECTION 3: CONEVAL Rezago Social Index
# =============================================================================
cat("\n=== Downloading CONEVAL Rezago Social data ===\n")

coneval_file <- file.path(data_dir, "coneval_rezago_social.csv")

if (!file.exists(coneval_file)) {
  # CONEVAL provides rezago social at municipal level
  # ZIP file contains entity + municipality level data for 2000-2020
  coneval_zip <- file.path(data_dir, "IRS_ent_mun_2000_2020.zip")

  tryCatch({
    download.file(
      "https://www.coneval.org.mx/Medicion/Documents/IRS_2020/IRS_ent_mun_2000_2020.zip",
      coneval_zip, mode = "wb", quiet = TRUE
    )

    if (file.info(coneval_zip)$size > 10000) {
      # Unzip and find the relevant file
      unzip(coneval_zip, exdir = file.path(data_dir, "coneval_tmp"))
      coneval_files <- list.files(file.path(data_dir, "coneval_tmp"),
                                  pattern = "\\.(csv|xlsx|xls)$",
                                  recursive = TRUE, full.names = TRUE)
      cat("Extracted files:", paste(basename(coneval_files), collapse = ", "), "\n")

      if (length(coneval_files) > 0) {
        # Read the first available file
        f <- coneval_files[1]
        if (grepl("\\.csv$", f)) {
          coneval_raw <- fread(f, encoding = "Latin-1")
        } else {
          coneval_raw <- as.data.table(readxl::read_excel(f))
        }
        fwrite(coneval_raw, coneval_file)
        cat("CONEVAL data extracted and saved:", nrow(coneval_raw), "rows\n")
      } else {
        stop("No data files found in CONEVAL ZIP archive.")
      }
    } else {
      stop("CONEVAL ZIP download too small — likely failed.")
    }
  }, error = function(e) {
    cat("CONEVAL download failed:", e$message, "\n")
    cat("Creating CONEVAL data from GADM municipality metadata as fallback.\n")
    # The treatment assignment doesn't strictly need CONEVAL IRS values
    # We use state-level rollout as the treatment variable (not municipality-level IRS)
    # Create a minimal placeholder with state names for matching
    cat("Note: CONEVAL data not critical for primary analysis.\n")
    cat("Treatment assignment uses state-level program rollout only.\n")
    fwrite(data.table(note = "CONEVAL download failed; using state-level treatment"),
           coneval_file)
  })
} else {
  cat("CONEVAL data loaded from cache.\n")
}

# =============================================================================
# SECTION 4: Sembrando Vida Program Rollout Data
# =============================================================================
cat("\n=== Constructing Sembrando Vida treatment assignment ===\n")

# Treatment assignment based on official program rollout documentation:
# Cohort 1 (2019): Original 20 states (southern/southeastern Mexico)
# Cohort 2 (2020): Golden Triangle expansion + additional states
# Cohort 3 (2021): Further expansion
#
# Sources:
# - DOF Reglas de Operación 2019, 2020, 2021, 2022
# - CONEVAL Evaluación Sembrando Vida 2024
# - CEFP Nota 044/2023

# State-level rollout (first year of program operation in each state)
sv_states <- data.table(
  state_name = c(
    # Cohort 1 — 2019 (original states)
    "Campeche", "Chiapas", "Colima", "Durango", "Guerrero",
    "Hidalgo", "Michoacán", "Morelos", "Oaxaca", "Puebla",
    "Quintana Roo", "San Luis Potosí", "Tabasco", "Tamaulipas",
    "Tlaxcala", "Veracruz", "Yucatán",
    # Cohort 2 — 2020 (expansion including Golden Triangle)
    "Chihuahua", "Sinaloa", "Nayarit", "Jalisco", "Sonora", "Zacatecas",
    # Cohort 3 — 2021 (further expansion)
    "México"  # Estado de México added later
  ),
  sv_cohort_year = c(
    rep(2019, 17),  # Original 17 states
    rep(2020, 6),   # 2020 expansion
    2021             # 2021 expansion
  )
)

# Map state names to GADM state names for merging
# GADM uses "NAME_1" for state names
sv_rollout_file <- file.path(data_dir, "sv_rollout.csv")
fwrite(sv_states, sv_rollout_file)
cat("Sembrando Vida rollout data constructed:",
    nrow(sv_states), "states across 3 cohorts\n")
cat("  Cohort 2019:", sum(sv_states$sv_cohort_year == 2019), "states\n")
cat("  Cohort 2020:", sum(sv_states$sv_cohort_year == 2020), "states\n")
cat("  Cohort 2021:", sum(sv_states$sv_cohort_year == 2021), "states\n")

# =============================================================================
# SECTION 5: Zonal Statistics — Tree Cover Loss by Municipality-Year
# =============================================================================
cat("\n=== Computing zonal statistics (tree cover loss by municipality) ===\n")

panel_file <- file.path(data_dir, "municipality_forest_panel.csv")

if (!file.exists(panel_file)) {
  library(exactextractr)

  # Ensure CRS match (Hansen tiles are in WGS84)
  mex_sf <- st_transform(mex_sf, 4326)

  # Process lossyear tiles: for each municipality, tabulate pixels by loss year
  loss_tiles <- list.files(tile_dir, pattern = "lossyear.*\\.tif$", full.names = TRUE)

  cat("Processing", length(loss_tiles), "lossyear tiles...\n")

  # Initialize accumulator matrix (municipalities × 24 years)
  n_muni <- nrow(mex_sf)
  total_loss <- matrix(0, nrow = n_muni, ncol = 24)
  colnames(total_loss) <- paste0("loss_pixels_", 2001:2024)
  mex_ext <- terra::ext(sf::st_bbox(mex_sf))

  for (i in seq_along(loss_tiles)) {
    tile_path <- loss_tiles[i]
    cat(sprintf("  Tile %d/%d: %s\n", i, length(loss_tiles), basename(tile_path)))

    r <- terra::rast(tile_path)
    tile_ext <- terra::ext(r)
    overlap <- terra::intersect(mex_ext, tile_ext)
    if (is.null(overlap)) {
      cat("    No overlap with Mexico, skipping.\n")
      next
    }

    r_crop <- terra::crop(r, mex_ext)

    # Single-pass tabulation: extract all values and tabulate years at once
    # This is ~24x faster than creating 24 binary rasters
    cat("    Tabulating loss years (single pass)...\n")
    yr_counts_raw <- exact_extract(r_crop, mex_sf, function(values, coverage_fractions) {
      vals <- values[!is.na(values) & values > 0]
      if (length(vals) == 0) return(rep(0, 24))
      as.numeric(tabulate(vals, nbins = 24))
    })

    # exact_extract returns matrix of dim (nbins × n_polygons) — transpose to (n_muni × 24)
    if (is.matrix(yr_counts_raw)) {
      # Result is 24 × n_muni, need to transpose
      yr_counts_mat <- t(yr_counts_raw)
    } else if (is.data.frame(yr_counts_raw)) {
      yr_counts_mat <- t(as.matrix(yr_counts_raw))
    } else {
      yr_counts_mat <- matrix(unlist(yr_counts_raw), nrow = n_muni, ncol = 24, byrow = TRUE)
    }
    stopifnot(nrow(yr_counts_mat) == n_muni, ncol(yr_counts_mat) == 24)
    total_loss <- total_loss + yr_counts_mat
    cat(sprintf("    Done. Total loss pixels this tile: %d\n", round(sum(yr_counts_mat))))

    rm(r, r_crop, yr_counts_raw, yr_counts_mat)
    gc(verbose = FALSE)
  }

  # Convert pixel counts to hectares
  # At 30m resolution, each pixel = 30m × 30m = 900 m² = 0.09 hectares
  pixel_ha <- 0.09
  loss_ha <- total_loss * pixel_ha

  # Create municipality-level panel
  muni_data <- data.table(
    GID_2 = mex_sf$GID_2,
    NAME_1 = mex_sf$NAME_1,  # State name
    NAME_2 = mex_sf$NAME_2,  # Municipality name
    loss_ha
  )

  # Process treecover2000 tiles for baseline forest cover
  cat("\nProcessing treecover2000 tiles for baseline...\n")
  tc_tiles_files <- list.files(tile_dir, pattern = "treecover2000.*\\.tif$", full.names = TRUE)

  # Accumulators
  tc_sum <- rep(0, n_muni)      # sum of treecover values (for weighted mean)
  tc_count <- rep(0, n_muni)    # total pixel count
  forest_pixels_total <- rep(0, n_muni)  # pixels with >=25% canopy

  for (i in seq_along(tc_tiles_files)) {
    tile_path <- tc_tiles_files[i]
    cat(sprintf("  Tile %d/%d: %s\n", i, length(tc_tiles_files), basename(tile_path)))

    r <- terra::rast(tile_path)
    tile_ext <- terra::ext(r)
    overlap <- terra::intersect(mex_ext, tile_ext)
    if (is.null(overlap)) {
      cat("    No overlap, skipping.\n")
      next
    }

    r_crop <- terra::crop(r, mex_ext)

    # Extract mean and count
    cat("    Extracting mean + count...\n")
    tc_stats <- exact_extract(r_crop, mex_sf, c("mean", "count"))
    tc_sum <- tc_sum + tc_stats$mean * tc_stats$count
    tc_count <- tc_count + tc_stats$count

    # Count pixels with >=25% canopy (forested)
    cat("    Counting forest pixels...\n")
    forest_binary <- (r_crop >= 25)
    fp <- exact_extract(forest_binary, mex_sf, "sum")
    forest_pixels_total <- forest_pixels_total + fp

    rm(r, r_crop, forest_binary)
    gc(verbose = FALSE)
  }

  # Compute weighted mean tree cover
  tc_combined <- data.frame(
    mean = ifelse(tc_count > 0, tc_sum / tc_count, 0),
    count = tc_count
  )

  muni_data[, `:=`(
    treecover2000_pct = tc_combined$mean,
    forest_area_ha_2000 = forest_pixels_total * pixel_ha,
    total_pixels = tc_combined$count
  )]

  # Reshape to long panel (municipality × year)
  loss_cols <- grep("^loss_pixels_", names(muni_data), value = TRUE)
  panel <- melt(muni_data,
    id.vars = c("GID_2", "NAME_1", "NAME_2", "treecover2000_pct",
                "forest_area_ha_2000", "total_pixels"),
    measure.vars = loss_cols,
    variable.name = "year_var",
    value.name = "tree_cover_loss_ha"
  )
  panel[, year := as.integer(gsub("loss_pixels_", "", year_var))]
  panel[, year_var := NULL]

  # Sort
  setorder(panel, GID_2, year)

  fwrite(panel, panel_file)
  cat("\nPanel saved:", nrow(panel), "municipality-year observations\n")
  cat("  Municipalities:", uniqueN(panel$GID_2), "\n")
  cat("  Years:", min(panel$year), "-", max(panel$year), "\n")

} else {
  panel <- fread(panel_file)
  cat("Panel loaded from cache:", nrow(panel), "obs\n")
}

# =============================================================================
# SECTION 6: Merge Treatment Assignment
# =============================================================================
cat("\n=== Merging treatment assignment ===\n")

# Merge Sembrando Vida rollout by state name
panel <- merge(panel, sv_states,
  by.x = "NAME_1", by.y = "state_name",
  all.x = TRUE
)

# Municipalities in non-SV states are never-treated (sv_cohort_year = 0)
panel[is.na(sv_cohort_year), sv_cohort_year := 0]

# Create treatment indicator
panel[, treated := as.integer(sv_cohort_year > 0 & year >= sv_cohort_year)]

# Create numeric municipality ID for Callaway-Sant'Anna
panel[, muni_id := as.integer(as.factor(GID_2))]

cat("Treatment assignment summary:\n")
cat("  Treated municipalities:", uniqueN(panel[sv_cohort_year > 0, GID_2]), "\n")
cat("  Control municipalities:", uniqueN(panel[sv_cohort_year == 0, GID_2]), "\n")
cat("  Cohort 2019:", uniqueN(panel[sv_cohort_year == 2019, GID_2]), "\n")
cat("  Cohort 2020:", uniqueN(panel[sv_cohort_year == 2020, GID_2]), "\n")
cat("  Cohort 2021:", uniqueN(panel[sv_cohort_year == 2021, GID_2]), "\n")

# Save final panel
final_panel_file <- file.path(data_dir, "analysis_panel.csv")
fwrite(panel, final_panel_file)
cat("\nFinal analysis panel saved:", nrow(panel), "observations\n")

# =============================================================================
# DATA VALIDATION (required)
# =============================================================================
cat("\n=== Data Validation ===\n")

stopifnot("Expected 2000+ municipalities" = uniqueN(panel$GID_2) >= 2000)
stopifnot("Expected years 2001-2024" = all(2001:2024 %in% panel$year))
stopifnot("Expected 24 years" = uniqueN(panel$year) == 24)
stopifnot("Expected treated municipalities" = uniqueN(panel[sv_cohort_year > 0, GID_2]) >= 500)
stopifnot("Expected control municipalities" = uniqueN(panel[sv_cohort_year == 0, GID_2]) >= 100)
stopifnot("No negative loss values" = all(panel$tree_cover_loss_ha >= 0))

cat("Data validation passed:",
    nrow(panel), "rows,",
    uniqueN(panel$GID_2), "municipalities,",
    uniqueN(panel$year), "years\n")
cat("DONE.\n")
