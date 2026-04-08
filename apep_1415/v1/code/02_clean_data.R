# 02_clean_data.R — Extract nightlights from BlackMarble HDF5, build panel
# APEP 1415: Morocco Cannabis Legalization

source("00_packages.R")

data_dir <- "../data/"
viirs_dir <- file.path(data_dir, "viirs")

# =============================================================================
# 1. Load grid cells and study provinces
# =============================================================================

grid_prov <- readRDS(file.path(data_dir, "grid_cells.rds"))
study_provinces <- readRDS(file.path(data_dir, "study_provinces.rds"))

cat("Grid cells:", nrow(grid_prov), "\n")
cat("Study provinces:", nrow(study_provinces), "\n")

# =============================================================================
# 2. Extract nightlights from BlackMarble HDF5 files
# =============================================================================

cat("\n=== Extracting nightlights from BlackMarble HDF5 ===\n")

h5_files <- list.files(viirs_dir, pattern = "\\.h5$", full.names = TRUE)
cat("Found", length(h5_files), "HDF5 files\n")

# The subdataset we want: AllAngle_Composite_Snow_Free
# This gives the annual average nighttime radiance (nW/cm2/sr)
sds_name <- "AllAngle_Composite_Snow_Free"

nl_panel <- data.frame()

# We need to reproject grid_prov to match the HDF5 sinusoidal projection
# BlackMarble uses sinusoidal (MODIS standard grid)

for (h5f in h5_files) {
  # Extract year from filename: VNP46A4.AYYYY001...
  yr <- as.integer(sub(".*\\.A(\\d{4})\\d{3}\\..*", "\\1", basename(h5f)))
  cat("Processing year", yr, "... ")

  # Read the nightlight radiance subdataset
  sds_path <- paste0(
    'HDF5:"', h5f,
    '"://HDFEOS/GRIDS/VIIRS_Grid_DNB_2d/Data_Fields/', sds_name
  )

  tryCatch({
    r <- rast(sds_path)

    # BlackMarble HDF5 lacks embedded georeference — set manually
    # h17v05 tile extent in MODIS sinusoidal projection:
    sin_crs <- '+proj=sinu +lon_0=0 +x_0=0 +y_0=0 +R=6371007.181 +units=m +no_defs'
    tile_size <- 1111950.5197
    x_ul <- -20015109.354
    y_ul <- 10007554.677
    h <- 17; v <- 5
    xmin <- x_ul + h * tile_size
    xmax <- xmin + tile_size
    ymax <- y_ul - v * tile_size
    ymin <- ymax - tile_size

    ext(r) <- ext(xmin, xmax, ymin, ymax)
    crs(r) <- sin_crs

    # Reproject grid polygons to sinusoidal for extraction
    grid_sin <- st_transform(grid_prov, sin_crs)

    # Extract mean radiance per grid cell
    vals <- exact_extract(r, st_geometry(grid_sin), fun = "mean")

    # Replace fill values with NA (65535 = fill for unsigned int, 0 = valid dark)
    vals[vals > 6000] <- NA

    yr_data <- data.frame(
      cell_id = grid_prov$cell_id,
      year = yr,
      nl_mean = vals
    )
    nl_panel <- rbind(nl_panel, yr_data)

    cat("done. Non-NA:", sum(!is.na(vals)),
        "Mean:", round(mean(vals, na.rm = TRUE), 2),
        "Median:", round(median(vals, na.rm = TRUE), 2), "\n")

  }, error = function(e) {
    cat("FAILED:", e$message, "\n")
  })
}

cat("\nTotal NL panel rows:", nrow(nl_panel), "\n")
cat("Years:", paste(sort(unique(nl_panel$year)), collapse = ", "), "\n")

# =============================================================================
# 3. Merge nightlights with grid cell attributes
# =============================================================================

cat("\n=== Building analysis panel ===\n")

# Drop geometry from grid_prov for merging
grid_attrs <- st_drop_geometry(grid_prov) %>%
  select(cell_id, adm2_name, treated, adjacent, lon, lat,
         dist_to_boundary_km, dist_signed_km)

panel <- nl_panel %>%
  left_join(grid_attrs, by = "cell_id")

# Add time variables
panel <- panel %>%
  mutate(
    # Law enacted May 2021, Decree effective March 2022
    # Permits start October 2022
    post = as.integer(year >= 2022),
    post_decree = as.integer(year >= 2022),
    post_permits = as.integer(year >= 2023),

    # Treatment intensity
    treat_post = treated * post,

    # Log nightlights (add small constant to handle zeros)
    ln_nl = log(nl_mean + 0.01),

    # Asinh transform (handles zeros more gracefully)
    asinh_nl = asinh(nl_mean),

    # Province fixed effect
    province = as.factor(adm2_name),

    # Year fixed effect
    year_fe = as.factor(year),

    # For Callaway-Sant'Anna: first_treat = 2022 for treated, 0 for never-treated
    first_treat = ifelse(treated == 1, 2022, 0)
  )

cat("Panel dimensions:", nrow(panel), "rows x", ncol(panel), "cols\n")
cat("Years:", paste(sort(unique(panel$year)), collapse = ", "), "\n")
cat("Treated cells:", n_distinct(panel$cell_id[panel$treated == 1]), "\n")
cat("Control cells:", n_distinct(panel$cell_id[panel$adjacent == 1]), "\n")

# =============================================================================
# 4. Load ACLED data if available
# =============================================================================

acled_file <- file.path(data_dir, "acled_morocco.csv")
if (file.exists(acled_file)) {
  cat("\n=== Processing ACLED data ===\n")
  acled <- read.csv(acled_file, stringsAsFactors = FALSE)
  cat("ACLED events:", nrow(acled), "\n")

  # Geocode to grid cells
  if ("latitude" %in% names(acled) && "longitude" %in% names(acled)) {
    acled_sf <- st_as_sf(acled, coords = c("longitude", "latitude"), crs = 4326)
    acled_grid <- st_join(acled_sf, grid_prov[, "cell_id"])
    acled_grid <- acled_grid[!is.na(acled_grid$cell_id), ]

    # Extract year
    acled_grid$year <- as.integer(substr(acled_grid$event_date, 1, 4))

    # Aggregate: events per cell-year
    acled_agg <- acled_grid %>%
      st_drop_geometry() %>%
      group_by(cell_id, year) %>%
      summarize(
        n_events = n(),
        n_protests = sum(event_type == "Protests", na.rm = TRUE),
        n_violence = sum(event_type %in% c("Violence against civilians",
                                            "Battles", "Explosions/Remote violence"),
                         na.rm = TRUE),
        n_riots = sum(event_type == "Riots", na.rm = TRUE),
        .groups = "drop"
      )

    panel <- panel %>%
      left_join(acled_agg, by = c("cell_id", "year"))

    # Fill NAs with 0 (no events = 0 count)
    panel <- panel %>%
      mutate(across(c(n_events, n_protests, n_violence, n_riots),
                    ~replace_na(., 0)))

    cat("ACLED merged. Cells with events:", sum(panel$n_events > 0), "\n")
  }
} else {
  cat("\nNo ACLED data available — using nightlights only\n")
  panel$n_events <- 0L
  panel$n_protests <- 0L
  panel$n_violence <- 0L
  panel$n_riots <- 0L
}

# =============================================================================
# 5. Summary statistics
# =============================================================================

cat("\n=== Summary Statistics ===\n")

panel %>%
  group_by(treated) %>%
  summarize(
    n_cells = n_distinct(cell_id),
    mean_nl = mean(nl_mean, na.rm = TRUE),
    sd_nl = sd(nl_mean, na.rm = TRUE),
    mean_events = mean(n_events, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

# Pre/post comparison
panel %>%
  group_by(treated, post) %>%
  summarize(
    mean_nl = mean(nl_mean, na.rm = TRUE),
    mean_asinh = mean(asinh_nl, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

# =============================================================================
# 6. Save panel
# =============================================================================

saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
cat("\nPanel saved:", nrow(panel), "observations\n")

# Write diagnostics for validate_v1.py
diagnostics <- list(
  n_treated = n_distinct(panel$cell_id[panel$treated == 1]),
  n_pre = length(unique(panel$year[panel$year < 2022])),
  n_obs = nrow(panel)
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE)
cat("Diagnostics written:", paste(names(diagnostics), unlist(diagnostics),
                                   sep = "=", collapse = ", "), "\n")
