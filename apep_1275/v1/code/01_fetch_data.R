# 01_fetch_data.R — Data acquisition for Pakistan 2022 Floods paper
# Sources: UNOSAT/HDX flood extent, GADM admin boundaries, MODIS NDVI

source("00_packages.R")

# Disable S2 to avoid edge-case geometry errors with satellite-derived polygons
sf::sf_use_s2(FALSE)

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# 1. Download GADM Pakistan admin boundaries (Level 3 = tehsil/sub-district)
# ============================================================================
cat("=== Downloading GADM Pakistan admin boundaries ===\n")

pak_adm3_path <- file.path(data_dir, "pak_adm3.rds")
if (!file.exists(pak_adm3_path)) {
  pak_adm3 <- geodata::gadm(country = "PAK", level = 3, path = data_dir)
  pak_adm3_sf <- sf::st_as_sf(pak_adm3)
  saveRDS(pak_adm3_sf, pak_adm3_path)
  cat("  Downloaded:", nrow(pak_adm3_sf), "Level-3 admin units\n")
} else {
  pak_adm3_sf <- readRDS(pak_adm3_path)
  cat("  Loaded from cache:", nrow(pak_adm3_sf), "Level-3 admin units\n")
}

cat("  Province breakdown:\n")
print(table(pak_adm3_sf$NAME_1))

# ============================================================================
# 2. Download UNOSAT flood extent data from HDX
# ============================================================================
cat("\n=== Downloading UNOSAT Pakistan 2022 flood extent ===\n")

flood_path <- file.path(data_dir, "flood_extent.rds")
if (!file.exists(flood_path)) {
  # HDX dataset: VIIRS-derived flood extent for Pakistan Jul-Aug 2022
  hdx_url <- "https://data.humdata.org/api/3/action/package_search"
  resp <- httr::GET(hdx_url, query = list(
    q = "pakistan flood 2022 unosat satellite water extent",
    rows = 15
  ))
  stopifnot(httr::status_code(resp) == 200)

  results <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))$result$results

  # Find shapefile/geojson resources
  flood_resource_url <- NULL
  for (i in seq_len(nrow(results))) {
    resources <- results$resources[[i]]
    if (is.null(resources) || nrow(resources) == 0) next
    for (j in seq_len(nrow(resources))) {
      fmt <- tolower(resources$format[j])
      url <- resources$url[j]
      if (grepl("shp|shapefile|geojson|gpkg", fmt) && grepl("flood|water", tolower(resources$name[j]))) {
        flood_resource_url <- url
        cat("  Found:", results$title[i], "\n")
        break
      }
    }
    if (!is.null(flood_resource_url)) break
  }

  if (!is.null(flood_resource_url)) {
    flood_file <- file.path(data_dir, "flood_raw.zip")
    download.file(flood_resource_url, flood_file, mode = "wb", quiet = TRUE)
    exdir <- file.path(data_dir, "flood_shp")
    dir.create(exdir, showWarnings = FALSE)
    unzip(flood_file, exdir = exdir)

    shp_files <- list.files(exdir, pattern = "\\.shp$", recursive = TRUE, full.names = TRUE)
    gjson_files <- list.files(exdir, pattern = "\\.geojson$", recursive = TRUE, full.names = TRUE)

    if (length(shp_files) > 0) {
      flood_sf <- sf::st_read(shp_files[1], quiet = TRUE)
    } else if (length(gjson_files) > 0) {
      flood_sf <- sf::st_read(gjson_files[1], quiet = TRUE)
    } else {
      stop("No spatial files found in UNOSAT download")
    }

    flood_sf <- sf::st_transform(flood_sf, sf::st_crs(pak_adm3_sf))
    flood_sf <- sf::st_make_valid(flood_sf)
    saveRDS(flood_sf, flood_path)
    cat("  Flood extent features:", nrow(flood_sf), "\n")
  } else {
    stop("Could not find UNOSAT flood shapefile on HDX")
  }
} else {
  flood_sf <- readRDS(flood_path)
  cat("  Loaded from cache:", nrow(flood_sf), "flood features\n")
}

# ============================================================================
# 3. Compute flood intensity per admin unit (spatial overlay)
# ============================================================================
cat("\n=== Computing flood intensity per admin unit ===\n")

flood_intensity_path <- file.path(data_dir, "flood_intensity.rds")
if (!file.exists(flood_intensity_path)) {
  # Ensure valid geometries
  pak_adm3_valid <- sf::st_make_valid(pak_adm3_sf)

  # Compute area of each admin unit
  pak_adm3_valid$total_area_km2 <- as.numeric(sf::st_area(pak_adm3_valid)) / 1e6

  # Compute intersection of flood extent with admin boundaries
  cat("  Computing spatial intersection...\n")
  flood_union <- sf::st_union(flood_sf)
  flood_union <- sf::st_make_valid(flood_union)

  intersections <- sf::st_intersection(pak_adm3_valid, flood_union)
  intersections$flood_area_km2 <- as.numeric(sf::st_area(intersections)) / 1e6

  # Create flood intensity table
  flood_dt <- data.table::data.table(
    NAME_1 = intersections$NAME_1,
    NAME_2 = intersections$NAME_2,
    NAME_3 = intersections$NAME_3,
    flood_area_km2 = intersections$flood_area_km2
  )

  # Merge with full admin table
  admin_dt <- data.table::data.table(
    tehsil_id = seq_len(nrow(pak_adm3_valid)),
    province = pak_adm3_valid$NAME_1,
    district = pak_adm3_valid$NAME_2,
    tehsil_name = pak_adm3_valid$NAME_3,
    total_area_km2 = pak_adm3_valid$total_area_km2
  )

  # Aggregate flood area per admin unit (some may have multiple intersection pieces)
  flood_agg <- flood_dt[, .(flood_area_km2 = sum(flood_area_km2)),
                         by = .(NAME_1, NAME_2, NAME_3)]

  flood_intensity <- merge(admin_dt, flood_agg,
                           by.x = c("province", "district", "tehsil_name"),
                           by.y = c("NAME_1", "NAME_2", "NAME_3"),
                           all.x = TRUE)

  # Replace NA flood area with 0 (no flooding detected)
  flood_intensity[is.na(flood_area_km2), flood_area_km2 := 0]

  # Compute percent flooded
  flood_intensity[, pct_flooded := 100 * flood_area_km2 / total_area_km2]
  flood_intensity[pct_flooded > 100, pct_flooded := 100]

  saveRDS(flood_intensity, flood_intensity_path)

  cat("  Flood intensity computed for", nrow(flood_intensity), "admin units\n")
  cat("  Flooded (>5%): ", sum(flood_intensity$pct_flooded > 5), " units\n")
  cat("  Unflooded (<5%):", sum(flood_intensity$pct_flooded <= 5), " units\n")
  cat("\n  Distribution of % flooded:\n")
  print(summary(flood_intensity$pct_flooded))
  cat("\n  By province:\n")
  print(flood_intensity[, .(n = .N, mean_pct = round(mean(pct_flooded), 1),
                            max_pct = round(max(pct_flooded), 1)),
                         by = province][order(-mean_pct)])
} else {
  flood_intensity <- readRDS(flood_intensity_path)
  cat("  Loaded from cache:", nrow(flood_intensity), "admin units\n")
}

# ============================================================================
# 4. Fetch MODIS NDVI via ORNL DAAC API (seasonal chunks)
# ============================================================================
cat("\n=== Fetching MODIS NDVI for admin unit centroids ===\n")

ndvi_path <- file.path(data_dir, "ndvi_tehsil.rds")
if (!file.exists(ndvi_path)) {
  # Compute centroids
  centroids <- sf::st_centroid(sf::st_make_valid(pak_adm3_sf),
                                of_largest_polygon = TRUE)
  coords <- sf::st_coordinates(centroids)

  n_units <- nrow(pak_adm3_sf)
  cat("  Centroids computed:", n_units, "locations\n")

  # MODIS ORNL API limits to 10 time steps per request
  # Each MODIS composite = 16 days, so 10 × 16 = 160 days max per request
  # Define seasonal chunks (~4 months each, ~8 composites)
  # We need: 2019-2023 (4 pre-flood seasons + 2 post-flood seasons minimum)

  seasons <- data.table::data.table(
    season_id = character(),
    season_type = character(),  # "kharif" or "rabi"
    year = integer(),
    start_doy = character(),
    end_doy = character()
  )

  for (yr in 2019:2023) {
    # Kharif (summer crop): June 15 - October 31
    seasons <- rbind(seasons, data.table::data.table(
      season_id = paste0("kharif_", yr),
      season_type = "kharif",
      year = yr,
      start_doy = sprintf("A%d166", yr),   # ~June 15
      end_doy = sprintf("A%d304", yr)      # ~October 31
    ))
    # Rabi (winter crop): November 15 - March 31
    rabi_start_yr <- yr
    rabi_end_yr <- yr + 1
    if (rabi_end_yr <= 2024) {
      seasons <- rbind(seasons, data.table::data.table(
        season_id = paste0("rabi_", yr, yr + 1),
        season_type = "rabi",
        year = yr,
        start_doy = sprintf("A%d319", rabi_start_yr),  # ~November 15
        end_doy = sprintf("A%d090", rabi_end_yr)        # ~March 31
      ))
    }
  }

  cat("  Seasons defined:\n")
  print(seasons[, .(season_id, season_type, year)])

  # MODIS API setup
  base_url <- "https://modis.ornl.gov/rst/api/v1"
  product <- "MOD13Q1"
  band <- "250m_16_days_NDVI"

  all_ndvi <- list()
  total_calls <- 0
  failed_calls <- 0

  cat("  Downloading NDVI for", n_units, "units ×", nrow(seasons), "seasons...\n")

  for (s in seq_len(nrow(seasons))) {
    season <- seasons[s]
    cat("  Season:", season$season_id, "")

    season_results <- list()

    for (i in seq_len(n_units)) {
      api_url <- sprintf(
        "%s/%s/subset?latitude=%f&longitude=%f&band=%s&startDate=%s&endDate=%s&kmAboveBelow=0&kmLeftRight=0",
        base_url, product, coords[i, "Y"], coords[i, "X"],
        band, season$start_doy, season$end_doy
      )

      resp <- tryCatch(
        httr::GET(api_url, httr::timeout(30)),
        error = function(e) NULL
      )

      if (!is.null(resp) && httr::status_code(resp) == 200) {
        result <- jsonlite::fromJSON(
          httr::content(resp, as = "text", encoding = "UTF-8"),
          simplifyVector = TRUE
        )

        if (!is.null(result$subset) && length(result$subset$calendar_date) > 0) {
          ndvi_vals <- as.numeric(unlist(result$subset$data))
          dates <- result$subset$calendar_date

          # NDVI scale factor: divide by 10000
          ndvi_dt <- data.table::data.table(
            tehsil_id = i,
            season_id = season$season_id,
            season_type = season$season_type,
            year = season$year,
            date = as.Date(dates),
            ndvi_raw = ndvi_vals,
            ndvi = ndvi_vals / 10000
          )

          # Filter fill values
          ndvi_dt <- ndvi_dt[ndvi >= -0.2 & ndvi <= 1.0]
          season_results[[length(season_results) + 1]] <- ndvi_dt
        }
      } else {
        failed_calls <- failed_calls + 1
      }

      total_calls <- total_calls + 1
      Sys.sleep(0.25)
    }

    n_success <- length(season_results)
    cat("(", n_success, "/", n_units, "success )\n")

    if (n_success > 0) {
      all_ndvi[[length(all_ndvi) + 1]] <- data.table::rbindlist(season_results)
    }
  }

  cat("\n  Total API calls:", total_calls, "| Failures:", failed_calls, "\n")

  if (length(all_ndvi) == 0) {
    stop("No NDVI data retrieved. Cannot proceed.")
  }

  ndvi_all <- data.table::rbindlist(all_ndvi)

  # Compute seasonal mean NDVI per tehsil
  ndvi_seasonal <- ndvi_all[, .(
    ndvi_mean = mean(ndvi, na.rm = TRUE),
    ndvi_max = max(ndvi, na.rm = TRUE),
    ndvi_sd = sd(ndvi, na.rm = TRUE),
    n_obs = .N
  ), by = .(tehsil_id, season_id, season_type, year)]

  # Merge with admin info
  admin_info <- data.table::data.table(
    tehsil_id = seq_len(n_units),
    tehsil_name = pak_adm3_sf$NAME_3,
    district = pak_adm3_sf$NAME_2,
    province = pak_adm3_sf$NAME_1
  )

  ndvi_seasonal <- merge(ndvi_seasonal, admin_info, by = "tehsil_id")

  saveRDS(ndvi_seasonal, ndvi_path)
  saveRDS(admin_info, file.path(data_dir, "tehsil_info.rds"))

  cat("  Saved seasonal NDVI:", nrow(ndvi_seasonal), "tehsil-season observations\n")
} else {
  ndvi_seasonal <- readRDS(ndvi_path)
  cat("  Loaded from cache:", nrow(ndvi_seasonal), "tehsil-season observations\n")
}

# ============================================================================
# 5. Summary
# ============================================================================
cat("\n=== Data Summary ===\n")
cat("Admin units:", nrow(flood_intensity), "\n")
cat("NDVI observations:", nrow(ndvi_seasonal), "\n")
cat("Seasons:", length(unique(ndvi_seasonal$season_id)), "\n")
cat("Flood intensity range:", round(min(flood_intensity$pct_flooded), 1), "to",
    round(max(flood_intensity$pct_flooded), 1), "%\n")
cat("NDVI range:", round(min(ndvi_seasonal$ndvi_mean, na.rm = TRUE), 3), "to",
    round(max(ndvi_seasonal$ndvi_mean, na.rm = TRUE), 3), "\n")

cat("\n=== Data acquisition complete ===\n")
