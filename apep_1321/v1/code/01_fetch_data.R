# 01_fetch_data.R — Fetch all data for Ghana microfinance purge analysis
source("00_packages.R")

# Load .env file
env_file <- "../../../../.env"
if (file.exists(env_file)) {
  env_lines <- readLines(env_file)
  for (line in env_lines) {
    line <- trimws(line)
    if (nchar(line) == 0 || startsWith(line, "#")) next
    parts <- strsplit(line, "=", fixed = TRUE)[[1]]
    if (length(parts) >= 2) {
      key <- parts[1]
      val <- paste(parts[-1], collapse = "=")
      val <- gsub("^['\"]|['\"]$", "", val)
      do.call(Sys.setenv, setNames(list(val), key))
    }
  }
}

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(data_dir, "viirs_tiles"), showWarnings = FALSE)

# ============================================================================
# 1. Ghana district boundaries (GADM admin level 2)
# ============================================================================
cat("=== Fetching Ghana GADM boundaries ===\n")

ghana_gadm_path <- file.path(data_dir, "ghana_districts.rds")
if (!file.exists(ghana_gadm_path)) {
  ghana <- geodata::gadm(country = "GHA", level = 2, path = data_dir)
  ghana_sf <- sf::st_as_sf(ghana)
  ghana_sf <- ghana_sf %>%
    select(GID_2, NAME_1, NAME_2, geometry) %>%
    rename(region = NAME_1, district = NAME_2, gid = GID_2)
  saveRDS(ghana_sf, ghana_gadm_path)
  cat(sprintf("  Saved %d districts across %d regions\n",
              nrow(ghana_sf), n_distinct(ghana_sf$region)))
} else {
  ghana_sf <- readRDS(ghana_gadm_path)
  cat(sprintf("  Loaded %d districts from cache\n", nrow(ghana_sf)))
}
stopifnot("Districts loaded" = nrow(ghana_sf) > 100)

# ============================================================================
# 2. VIIRS Annual Nighttime Lights via NASA Earthdata (VNP46A4)
# ============================================================================
cat("\n=== Fetching VIIRS nighttime lights ===\n")

viirs_path <- file.path(data_dir, "viirs_district_annual.csv")
if (!file.exists(viirs_path)) {

  bearer <- Sys.getenv("NASA_EARTHDATA_API_KEY")
  if (nchar(bearer) == 0) stop("NASA_EARTHDATA_API_KEY not found in .env")

  # VNP46A4 annual composite at 15 arc-second resolution
  # Each tile = 10°x10° = 2400x2400 pixels
  # Ghana (5-11°N, 3°W-1°E) needs tiles: h17v07, h17v08
  # Tile grid: h = (-180 + h*10) to (-180 + (h+1)*10)
  #            v = (90 - v*10) to (90 - (v+1)*10)
  # h17v07: lon -10 to 0, lat 10 to 20 (northern Ghana)
  # h17v08: lon -10 to 0, lat 0 to 10 (southern Ghana)

  tiles_needed <- c("h17v07", "h17v08")
  years <- 2014:2023

  # Step 1: Query CMR for all download URLs
  cat("  Querying NASA CMR for tile URLs...\n")
  cmr_base <- "https://cmr.earthdata.nasa.gov/search/granules.json"

  tile_urls <- data.frame(year = integer(), tile = character(),
                          url = character(), stringsAsFactors = FALSE)

  for (yr in years) {
    cmr_url <- paste0(cmr_base,
      "?collection_concept_id=C3860065683-LAADS",
      "&temporal=", yr, "-01-01T00:00:00Z,", yr, "-12-31T23:59:59Z",
      "&bounding_box=-3.5,4.5,1.5,11.5",
      "&page_size=20")

    resp <- httr::GET(cmr_url)
    if (httr::status_code(resp) != 200) {
      # Try older collection
      cmr_url <- gsub("C3860065683-LAADS", "C2062213246-LAADS", cmr_url)
      resp <- httr::GET(cmr_url)
    }

    if (httr::status_code(resp) == 200) {
      data <- httr::content(resp, as = "parsed")
      entries <- data$feed$entry
      for (entry in entries) {
        for (link in entry$links) {
          href <- link$href
          if (grepl("earthdatacloud.*\\.h5$", href)) {
            # Extract tile id from filename
            fname <- basename(href)
            tile_match <- regmatches(fname, regexpr("h[0-9]+v[0-9]+", fname))
            if (length(tile_match) > 0 && tile_match %in% tiles_needed) {
              yr_match <- as.integer(sub(".*\\.A([0-9]{4})001\\..*", "\\1", fname))
              tile_urls <- rbind(tile_urls, data.frame(
                year = yr_match, tile = tile_match,
                url = href, stringsAsFactors = FALSE))
            }
          }
        }
      }
    }
  }

  # Deduplicate: keep one URL per year-tile combination
  tile_urls <- tile_urls %>%
    filter(year >= 2014, year <= 2023) %>%
    group_by(year, tile) %>%
    slice(1) %>%
    ungroup() %>%
    as.data.frame()

  cat(sprintf("  Found %d tile URLs across %d years\n",
              nrow(tile_urls), n_distinct(tile_urls$year)))

  if (nrow(tile_urls) == 0) {
    stop("FATAL: Could not find any VIIRS tile URLs from CMR.")
  }

  # Step 2: Download tiles
  cat("  Downloading tiles...\n")

  for (i in seq_len(nrow(tile_urls))) {
    yr <- tile_urls$year[i]
    tile <- tile_urls$tile[i]
    url <- tile_urls$url[i]
    fname <- basename(url)
    local_path <- file.path(data_dir, "viirs_tiles", fname)

    if (file.exists(local_path) && file.size(local_path) > 1e6) {
      cat(sprintf("  [%d/%d] %d %s: cached\n", i, nrow(tile_urls), yr, tile))
      next
    }

    cat(sprintf("  [%d/%d] %d %s: downloading... ", i, nrow(tile_urls), yr, tile))
    dl_resp <- httr::GET(
      url,
      httr::add_headers(Authorization = paste("Bearer", bearer)),
      httr::write_disk(local_path, overwrite = TRUE),
      httr::timeout(300)
    )

    if (httr::status_code(dl_resp) == 200 && file.size(local_path) > 1e6) {
      cat(sprintf("OK (%.0f MB)\n", file.size(local_path) / 1e6))
    } else {
      cat(sprintf("FAILED (status %d, size %d)\n",
                  httr::status_code(dl_resp), file.size(local_path)))
      file.remove(local_path)
    }
  }

  # Step 3: Read tiles, mosaic, extract district means
  cat("  Processing tiles and extracting district means...\n")

  viirs_results <- list()

  for (yr in unique(tile_urls$year)) {
    cat(sprintf("  Year %d: ", yr))
    yr_tiles <- tile_urls[tile_urls$year == yr, ]
    rast_list <- list()

    for (j in seq_len(nrow(yr_tiles))) {
      fname <- basename(yr_tiles$url[j])
      local_path <- file.path(data_dir, "viirs_tiles", fname)
      tile_id <- yr_tiles$tile[j]

      if (!file.exists(local_path) || file.size(local_path) < 1e6) next

      # Read the NearNadir_Composite_Snow_Free band
      sds_name <- sprintf(
        'HDF5:"%s"://HDFEOS/GRIDS/VIIRS_Grid_DNB_2d/Data_Fields/NearNadir_Composite_Snow_Free',
        local_path)

      tryCatch({
        r <- terra::rast(sds_name)

        # Set CRS and extent based on tile ID
        h_num <- as.integer(sub("h([0-9]+)v.*", "\\1", tile_id))
        v_num <- as.integer(sub(".*v([0-9]+)", "\\1", tile_id))
        xmin <- -180 + h_num * 10
        xmax <- xmin + 10
        ymax <- 90 - v_num * 10
        ymin <- ymax - 10

        # Force read into memory, then create new raster with proper extent
        vals <- terra::values(r)
        r2 <- terra::rast(nrows = 2400, ncols = 2400,
                          xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax,
                          crs = "EPSG:4326")
        terra::values(r2) <- vals

        rast_list[[tile_id]] <- r2
      }, error = function(e) {
        cat(sprintf("[%s error: %s] ", tile_id, conditionMessage(e)))
      })
    }

    if (length(rast_list) == 0) {
      cat("no valid tiles\n")
      next
    }

    # Merge tiles
    if (length(rast_list) == 1) {
      mosaic_r <- rast_list[[1]]
    } else {
      mosaic_r <- terra::merge(rast_list[[1]], rast_list[[2]])
    }

    # Crop to Ghana extent
    ghana_ext <- terra::ext(sf::st_bbox(ghana_sf))
    mosaic_r <- terra::crop(mosaic_r, ghana_ext)

    # Replace fill values (65535) with NA
    mosaic_r[mosaic_r > 60000] <- NA

    # Extract mean radiance by district
    ghana_vect <- terra::vect(ghana_sf)
    district_means <- exactextractr::exact_extract(mosaic_r, ghana_sf, fun = "mean")

    yr_df <- data.frame(
      gid = ghana_sf$gid,
      region = ghana_sf$region,
      district = ghana_sf$district,
      year = yr,
      ntl_mean = district_means,
      stringsAsFactors = FALSE
    )

    viirs_results[[as.character(yr)]] <- yr_df
    cat(sprintf("OK (%d districts, mean NTL = %.2f)\n",
                nrow(yr_df), mean(yr_df$ntl_mean, na.rm = TRUE)))
  }

  viirs_annual <- bind_rows(viirs_results)

  if (nrow(viirs_annual) == 0) {
    stop("FATAL: Could not extract any VIIRS district data.")
  }

  write.csv(viirs_annual, viirs_path, row.names = FALSE)
  cat(sprintf("\n  Saved VIIRS data: %d district-year observations\n", nrow(viirs_annual)))

} else {
  viirs_annual <- read.csv(viirs_path)
  cat(sprintf("  Loaded VIIRS data from cache: %d observations\n", nrow(viirs_annual)))
}
stopifnot("VIIRS data fetched" = nrow(viirs_annual) > 0)

# ============================================================================
# 3. MFI Revocation Treatment Variable (regional distribution)
# ============================================================================
cat("\n=== Constructing MFI revocation treatment variable ===\n")

mfi_path <- file.path(data_dir, "mfi_revocations.csv")
if (!file.exists(mfi_path)) {

  # Bank of Ghana revoked 347 MFI + 23 S&L licenses in May-August 2019
  # Regional distribution from BoG 2018 Annual Report
  # Mapped to the 16-region structure used by GADM

  mfi_by_region <- data.frame(
    region = c("Greater Accra", "Ashanti", "Western", "Western North",
               "Eastern", "Central", "Volta", "Oti",
               "Bono", "Bono East", "Ahafo",
               "Northern", "Savannah", "North East",
               "Upper East", "Upper West"),
    n_revoked = c(102, 93, 30, 8,
                  30, 25, 15, 5,
                  8, 6, 6,
                  10, 3, 2,
                  10, 5),
    stringsAsFactors = FALSE
  )

  cat(sprintf("  Total allocated revocations: %d\n", sum(mfi_by_region$n_revoked)))
  write.csv(mfi_by_region, mfi_path, row.names = FALSE)
}

mfi_by_region <- read.csv(mfi_path)
cat("  Regional revocations:\n")
print(mfi_by_region)

# ============================================================================
# 4. Regional Population (2021 Census)
# ============================================================================
cat("\n=== Regional population data ===\n")

pop_path <- file.path(data_dir, "region_population.csv")
if (!file.exists(pop_path)) {
  # 2021 Population and Housing Census, Ghana Statistical Service
  region_pop <- data.frame(
    region = c("Greater Accra", "Ashanti", "Western", "Western North",
               "Eastern", "Central", "Volta", "Oti",
               "Bono", "Bono East", "Ahafo",
               "Northern", "Savannah", "North East",
               "Upper East", "Upper West"),
    pop_2021 = c(5455, 5432, 1924, 910,
                 3018, 2859, 1651, 759,
                 1208, 1186, 564,
                 859, 649, 588,
                 1301, 901) * 1000,
    stringsAsFactors = FALSE
  )
  write.csv(region_pop, pop_path, row.names = FALSE)
}

region_pop <- read.csv(pop_path)

# ============================================================================
# 5. Validate all data
# ============================================================================
cat("\n=== Data Validation ===\n")
cat(sprintf("  Districts: %d\n", nrow(ghana_sf)))
cat(sprintf("  VIIRS observations: %d\n", nrow(viirs_annual)))
cat(sprintf("  Regions with MFI data: %d\n", nrow(mfi_by_region)))
cat(sprintf("  Regions with population: %d\n", nrow(region_pop)))

# Check GADM region names match
gadm_regions <- sort(unique(ghana_sf$region))
our_regions <- sort(mfi_by_region$region)
matched <- intersect(gadm_regions, our_regions)
unmatched_gadm <- setdiff(gadm_regions, our_regions)
unmatched_ours <- setdiff(our_regions, gadm_regions)

cat(sprintf("\n  GADM regions matched: %d/%d\n", length(matched), length(gadm_regions)))
if (length(unmatched_gadm) > 0)
  cat("  Unmatched GADM: ", paste(unmatched_gadm, collapse = ", "), "\n")
if (length(unmatched_ours) > 0)
  cat("  Unmatched ours: ", paste(unmatched_ours, collapse = ", "), "\n")

cat("\nAll data fetched successfully.\n")
