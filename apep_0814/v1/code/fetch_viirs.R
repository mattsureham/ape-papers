## fetch_viirs.R — Download VIIRS annual nightlights using blackmarbler + gdal_translate
## Works around terra's HDF5 reading issue by converting via GDAL CLI

source("00_packages.R")

data_dir <- "../data"
viirs_raw <- file.path(data_dir, "viirs_raw")
dir.create(viirs_raw, showWarnings = FALSE, recursive = TRUE)

viirs_path <- file.path(data_dir, "viirs_annual.csv")
if (file.exists(viirs_path)) {
  message("VIIRS data already exists at ", viirs_path)
  quit(status = 0)
}

nasa_token <- Sys.getenv("NASA_EARTHDATA_API_KEY")
if (nasa_token == "") stop("NASA_EARTHDATA_API_KEY must be set in .env")

# Load municipality boundaries
slv_sf <- sf::st_read(file.path(data_dir, "gadm_slv_adm2.gpkg"), quiet = TRUE)
message("Loaded ", nrow(slv_sf), " municipalities")

years <- 2012:2023
all_results <- list()

for (yr in years) {
  message("\n=== Year ", yr, " ===")

  yr_tif <- file.path(viirs_raw, paste0("viirs_", yr, "_merged.tif"))

  if (!file.exists(yr_tif)) {
    # Step 1: Download HDF5 tiles using blackmarbler
    message("  Step 1: Downloading HDF5 tiles...")
    bm_dir <- file.path(viirs_raw, paste0("bm_", yr))
    dir.create(bm_dir, showWarnings = FALSE)

    tryCatch({
      r <- blackmarbler::bm_raster(
        roi_sf = slv_sf,
        product_id = "VNP46A4",
        date = yr,
        bearer = nasa_token,
        output_directory = bm_dir
      )
      message("  bm_raster succeeded for ", yr)
      # If bm_raster succeeds, save the result directly
      terra::writeRaster(r, yr_tif, overwrite = TRUE)
    }, error = function(e) {
      message("  bm_raster failed: ", e$message)
      message("  Step 2: Converting HDF5 → GeoTIFF via gdal_translate...")

      # Find downloaded H5 files
      h5_files <- list.files(bm_dir, pattern = "\\.h5$", full.names = TRUE,
                             recursive = TRUE)
      if (length(h5_files) == 0) {
        # Check blackmarbler temp dir
        tmp_dirs <- list.dirs(tempdir(), recursive = TRUE)
        h5_files <- list.files(tempdir(), pattern = "VNP46A4.*\\.h5$",
                               full.names = TRUE, recursive = TRUE)
      }

      if (length(h5_files) == 0) {
        message("  No H5 files found for ", yr, ". Skipping.")
        return()
      }

      message("  Found ", length(h5_files), " H5 files")

      # Convert each H5 to GeoTIFF using gdal_translate
      tile_tifs <- character()
      for (h5f in h5_files) {
        # Find the nightlight subdataset
        sds_info <- system2("gdalinfo", h5f, stdout = TRUE, stderr = TRUE)
        # Look for DNB_BRDF-Corrected_NTL subdataset
        ntl_sds <- grep("DNB_BRDF-Corrected_NTL", sds_info, value = TRUE)
        ntl_sds <- grep("SUBDATASET.*_NAME=", ntl_sds, value = TRUE)

        if (length(ntl_sds) == 0) {
          message("  Could not find NTL subdataset in ", basename(h5f))
          next
        }

        sds_name <- sub(".*_NAME=", "", ntl_sds[1])
        tile_tif <- sub("\\.h5$", ".tif", h5f)

        cmd <- sprintf('gdal_translate -of GTiff "%s" "%s"', sds_name, tile_tif)
        system(cmd, ignore.stdout = TRUE)

        if (file.exists(tile_tif) && file.size(tile_tif) > 1000) {
          tile_tifs <- c(tile_tifs, tile_tif)
          message("  Converted: ", basename(tile_tif))
        }
      }

      if (length(tile_tifs) == 0) {
        message("  No tiles converted for ", yr)
        return()
      }

      # Merge tiles and reproject to EPSG:4326
      rasters <- lapply(tile_tifs, terra::rast)
      if (length(rasters) > 1) {
        merged <- do.call(terra::merge, rasters)
      } else {
        merged <- rasters[[1]]
      }

      # Crop to El Salvador extent + buffer
      bbox <- sf::st_bbox(slv_sf)
      ext_buf <- terra::ext(bbox["xmin"] - 0.5, bbox["xmax"] + 0.5,
                            bbox["ymin"] - 0.5, bbox["ymax"] + 0.5)
      proj_ext <- terra::project(terra::as.points(terra::ext(ext_buf),
                                                   crs = "EPSG:4326"),
                                  terra::crs(merged))
      cropped <- terra::crop(merged, terra::ext(proj_ext))

      # Reproject to EPSG:4326
      reproj <- terra::project(cropped, "EPSG:4326")
      terra::writeRaster(reproj, yr_tif, overwrite = TRUE)
      message("  Saved: ", yr_tif)
    })
  } else {
    message("  Using cached GeoTIFF")
  }

  if (!file.exists(yr_tif)) {
    message("  Skipping year ", yr, " — no data")
    next
  }

  # Step 3: Extract zonal statistics per municipality
  r <- terra::rast(yr_tif)

  # Replace fill values
  r[r > 65000] <- NA

  vals <- exactextractr::exact_extract(r, slv_sf, fun = c("mean", "median", "count"))
  names(vals) <- c("ntl_mean", "ntl_median", "ntl_pixels")

  result <- data.frame(
    NAME_1 = slv_sf$NAME_1,
    NAME_2 = slv_sf$NAME_2,
    GID_2 = slv_sf$GID_2,
    year = yr,
    ntl_mean = vals$ntl_mean,
    ntl_median = vals$ntl_median,
    ntl_pixels = vals$ntl_pixels,
    stringsAsFactors = FALSE
  )

  all_results[[as.character(yr)]] <- result
  message("  Extracted: ", yr, " — mean NTL range: ",
          round(min(result$ntl_mean, na.rm = TRUE), 2), " to ",
          round(max(result$ntl_mean, na.rm = TRUE), 2))
}

# Combine and save
viirs_df <- data.table::rbindlist(all_results)
data.table::fwrite(viirs_df, viirs_path)

message("\n=== VIIRS extraction complete ===")
message("Rows: ", nrow(viirs_df))
message("Years: ", paste(unique(viirs_df$year), collapse = ", "))
message("Municipalities: ", length(unique(viirs_df$GID_2)))
