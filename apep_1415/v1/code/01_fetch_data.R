# 01_fetch_data.R — Fetch province boundaries, VIIRS nightlights, ACLED
# APEP 1415: Morocco Cannabis Legalization

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# =============================================================================
# 1. Morocco province boundaries (HDX / OCHA — admin2)
# =============================================================================

cat("=== Loading province boundaries ===\n")

boundaries_file <- file.path(data_dir, "mar_admin2.geojson")

if (!file.exists(boundaries_file)) {
  hdx_api <- "https://data.humdata.org/api/3/action/package_show?id=cod-ab-mar"
  resp <- httr::GET(hdx_api)
  stopifnot(httr::status_code(resp) == 200)

  pkg_info <- httr::content(resp, as = "parsed")
  resources <- pkg_info$result$resources

  zip_url <- NULL
  for (r in resources) {
    url <- r$url %||% r$download_url %||% ""
    if (grepl("geojson", tolower(r$name %||% "")) || grepl("geojson", tolower(r$format %||% ""))) {
      zip_url <- url
      break
    }
  }
  stopifnot(!is.null(zip_url))

  zip_file <- file.path(data_dir, "morocco_boundaries.zip")
  httr::GET(zip_url, httr::write_disk(zip_file, overwrite = TRUE))
  unzip(zip_file, exdir = data_dir)
}

provinces <- st_read(boundaries_file, quiet = TRUE)
cat("Provinces loaded:", nrow(provinces), "features\n")

# =============================================================================
# 2. Define treatment and control provinces
# =============================================================================

cat("\n=== Defining treatment groups ===\n")

treated_patterns <- c("Al Hoceima", "Chefchaouen", "Taounate")
adjacent_patterns <- c("Taza", "Larache", "Tetouan", "Fnideq", "Fahs Anjra", "Nador")

provinces$treated <- 0L
provinces$adjacent <- 0L
provinces$study_area <- 0L

for (p in treated_patterns) {
  idx <- grepl(p, provinces$adm2_name, ignore.case = TRUE)
  provinces$treated[idx] <- 1L
  provinces$study_area[idx] <- 1L
}

for (p in adjacent_patterns) {
  idx <- grepl(p, provinces$adm2_name, ignore.case = TRUE)
  provinces$adjacent[idx] <- 1L
  provinces$study_area[idx] <- 1L
}

study_provinces <- provinces[provinces$study_area == 1, ]
cat("Study area: ", nrow(study_provinces), " provinces (",
    sum(study_provinces$treated), " treated, ",
    sum(study_provinces$adjacent), " control)\n", sep = "")

# =============================================================================
# 3. Create 5km grid over study area
# =============================================================================

cat("\n=== Creating 5km analysis grid ===\n")

grid <- st_make_grid(study_provinces, cellsize = c(0.05, 0.05), what = "polygons")
grid_sf <- st_sf(cell_id = seq_along(grid), geometry = grid)
grid_prov <- st_join(grid_sf, study_provinces[, c("adm2_name", "treated", "adjacent")])
grid_prov <- grid_prov[!is.na(grid_prov$adm2_name), ]
grid_prov <- grid_prov[!duplicated(grid_prov$cell_id), ]

# Centroids and distances
grid_prov$centroid <- st_centroid(grid_prov$geometry)
coords <- st_coordinates(grid_prov$centroid)
grid_prov$lon <- coords[, 1]
grid_prov$lat <- coords[, 2]

treated_boundary <- st_union(study_provinces[study_provinces$treated == 1, ])
treated_boundary_line <- st_cast(st_boundary(treated_boundary), "MULTILINESTRING")

grid_prov$dist_to_boundary_km <- as.numeric(
  st_distance(grid_prov$centroid, treated_boundary_line)
) / 1000

grid_prov$dist_signed_km <- ifelse(
  grid_prov$treated == 1,
  grid_prov$dist_to_boundary_km,
  -grid_prov$dist_to_boundary_km
)

cat("Grid cells:", nrow(grid_prov), "(treated:", sum(grid_prov$treated == 1),
    ", control:", sum(grid_prov$adjacent == 1), ")\n")

# =============================================================================
# 4. VIIRS Nightlights via NASA BlackMarble (VNP46A4)
# =============================================================================

cat("\n=== Fetching VIIRS nightlights via NASA LAADS DAAC ===\n")

nasa_token <- Sys.getenv("NASA_EARTHDATA_API_KEY")
viirs_dir <- file.path(data_dir, "viirs")
dir.create(viirs_dir, showWarnings = FALSE)

years <- 2014:2023

# Use CMR to find BlackMarble annual composite (VNP46A4) granules
# covering the Rif Mountains region (tile h18v04)
nl_panel <- data.frame()

for (yr in years) {
  tif_file <- file.path(viirs_dir, paste0("vnp46a4_", yr, ".tif"))

  if (file.exists(tif_file) && file.size(tif_file) > 1000) {
    cat("Year", yr, "- loading cached file\n")
    r <- rast(tif_file)
  } else {
    # Search CMR for VNP46A4 granules
    cmr_url <- paste0(
      "https://cmr.earthdata.nasa.gov/search/granules.json?",
      "short_name=VNP46A4",
      "&temporal=", yr, "-01-01T00:00:00Z,", yr, "-12-31T23:59:59Z",
      "&bounding_box=-6.5,34,-3,36",  # Rif bbox
      "&page_size=10&sort_key=-start_date"
    )

    resp <- httr::GET(cmr_url, httr::add_headers(
      Authorization = paste("Bearer", nasa_token)
    ))

    if (httr::status_code(resp) != 200) {
      cat("Year", yr, "- CMR search failed (HTTP", httr::status_code(resp), ")\n")
      next
    }

    results <- httr::content(resp, as = "parsed")
    entries <- results$feed$entry

    if (length(entries) == 0) {
      cat("Year", yr, "- no granules found\n")
      next
    }

    # Get download URL
    download_url <- NULL
    for (entry in entries) {
      for (link in entry$links) {
        href <- link$href %||% ""
        if (grepl("h5$|hdf5$", href) && grepl("h18v04|h17v05", href)) {
          download_url <- href
          break
        }
      }
      if (!is.null(download_url)) break
    }

    if (is.null(download_url)) {
      # Try getting any HDF5 link
      for (entry in entries) {
        for (link in entry$links) {
          href <- link$href %||% ""
          if (grepl("\\.(h5|hdf5)$", href)) {
            download_url <- href
            break
          }
        }
        if (!is.null(download_url)) break
      }
    }

    if (is.null(download_url)) {
      cat("Year", yr, "- no download link found\n")
      next
    }

    cat("Year", yr, "- downloading:", basename(download_url), "\n")

    h5_file <- file.path(viirs_dir, basename(download_url))
    dl <- httr::GET(
      download_url,
      httr::add_headers(Authorization = paste("Bearer", nasa_token)),
      httr::write_disk(h5_file, overwrite = TRUE),
      httr::timeout(120)
    )

    if (httr::status_code(dl) != 200 || file.size(h5_file) < 10000) {
      cat("  Download failed (HTTP", httr::status_code(dl), ")\n")
      next
    }

    # Convert HDF5 to GeoTIFF and crop
    tryCatch({
      r_raw <- rast(h5_file)
      study_ext <- ext(-6.5, -3, 34, 36)
      r <- crop(r_raw, study_ext)
      writeRaster(r, tif_file, overwrite = TRUE)
      cat("  Processed and cropped.\n")
    }, error = function(e) {
      cat("  Processing failed:", e$message, "\n")
      r <<- NULL
    })
  }

  if (exists("r") && !is.null(r)) {
    tryCatch({
      vals <- exact_extract(r, st_geometry(grid_prov), fun = "mean")
      yr_data <- data.frame(
        cell_id = grid_prov$cell_id,
        year = yr,
        nl_mean = vals
      )
      nl_panel <- rbind(nl_panel, yr_data)
      cat("  Mean NL:", round(mean(vals, na.rm = TRUE), 3), "\n")
    }, error = function(e) {
      cat("  Extraction failed:", e$message, "\n")
    })
  }
}

# =============================================================================
# 5. Fallback: Download VIIRS annual tiles directly from EOG
# =============================================================================

if (nrow(nl_panel) == 0) {
  cat("\n=== BlackMarble failed — trying EOG annual composites with range request ===\n")

  # The EOG files are COGs (Cloud Optimized GeoTIFFs), so we should be able
  # to read just a subwindow. Let's try with explicit GDAL config.

  for (yr in years) {
    cat("Year", yr, "... ")

    # Try multiple URL patterns
    urls_to_try <- c(
      paste0("https://eogdata.mines.edu/nighttime_light/annual/v22/",
             yr, "/VNL_v22_npp-j01_", yr,
             "_global_vcmslcfg_c202303012100.average.dat.tif"),
      paste0("https://eogdata.mines.edu/nighttime_light/annual/v22/",
             yr, "/VNL_v22_npp_", yr,
             "_global_vcmslcfg_c202303012100.average.dat.tif"),
      paste0("https://eogdata.mines.edu/nighttime_light/annual/v21/",
             yr, "/VNL_v21_npp_", yr,
             "_global_vcmslcfg_c202205302300.average_masked.dat.tif")
    )

    loaded <- FALSE
    for (url in urls_to_try) {
      tryCatch({
        # Use GDAL's vsicurl with windowed reading
        vsicurl_path <- paste0("/vsicurl/", url)
        r <- rast(vsicurl_path, win = ext(-6.5, -3, 34, 36))
        vals <- exact_extract(r, st_geometry(grid_prov), fun = "mean")

        yr_data <- data.frame(
          cell_id = grid_prov$cell_id,
          year = yr,
          nl_mean = vals
        )
        nl_panel <- rbind(nl_panel, yr_data)
        cat("OK. Mean:", round(mean(vals, na.rm = TRUE), 3), "\n")
        loaded <- TRUE
        break
      }, error = function(e) {
        # silent
      })
    }

    if (!loaded) cat("failed\n")
  }
}

# =============================================================================
# 6. ACLED conflict/protest data (uses email/password auth)
# =============================================================================

cat("\n=== Fetching ACLED data ===\n")

acled_email <- Sys.getenv("ACLED_EMAIL")
acled_password <- Sys.getenv("ACLED_PASSWORD")
acled_file <- file.path(data_dir, "acled_morocco.csv")

if (!file.exists(acled_file) && nchar(acled_email) > 0) {
  # ACLED API v3 uses email + key (password)
  acled_url <- paste0(
    "https://api.acleddata.com/acled/read?",
    "key=", acled_password,
    "&email=", acled_email,
    "&country=Morocco",
    "&event_date=2014-01-01|2024-12-31",
    "&event_date_where=BETWEEN",
    "&limit=0"
  )

  cat("Requesting ACLED data...\n")
  resp <- httr::GET(acled_url, httr::timeout(60))

  if (httr::status_code(resp) == 200) {
    content <- httr::content(resp, as = "parsed")
    if (!is.null(content$data) && length(content$data) > 0) {
      acled_df <- bind_rows(lapply(content$data, function(x) {
        as.data.frame(lapply(x, function(v) if (is.null(v)) NA else v),
                      stringsAsFactors = FALSE)
      }))
      write.csv(acled_df, acled_file, row.names = FALSE)
      cat("ACLED data saved:", nrow(acled_df), "events\n")
    } else {
      cat("ACLED returned empty data. Status:", content$status %||% "unknown", "\n")
    }
  } else {
    cat("ACLED failed: HTTP", httr::status_code(resp), "\n")
    # Try alternative ACLED endpoint
    acled_url2 <- paste0(
      "https://api.acleddata.com/acled/read.csv?",
      "key=", acled_password,
      "&email=", acled_email,
      "&country=Morocco",
      "&event_date=2014-01-01|2024-12-31",
      "&event_date_where=BETWEEN",
      "&limit=0"
    )
    resp2 <- httr::GET(acled_url2, httr::write_disk(acled_file, overwrite = TRUE),
                       httr::timeout(60))
    if (httr::status_code(resp2) == 200 && file.size(acled_file) > 100) {
      acled_df <- read.csv(acled_file)
      cat("ACLED CSV saved:", nrow(acled_df), "events\n")
    }
  }
} else if (file.exists(acled_file)) {
  cat("ACLED data already exists\n")
  acled_df <- read.csv(acled_file)
  cat("ACLED loaded:", nrow(acled_df), "events\n")
} else {
  cat("No ACLED credentials, skipping\n")
}

# =============================================================================
# 7. Save everything
# =============================================================================

saveRDS(provinces, file.path(data_dir, "provinces.rds"))
saveRDS(study_provinces, file.path(data_dir, "study_provinces.rds"))
saveRDS(grid_prov, file.path(data_dir, "grid_cells.rds"))

if (nrow(nl_panel) > 0) {
  saveRDS(nl_panel, file.path(data_dir, "nl_panel.rds"))
  cat("\nNightlight panel saved:", nrow(nl_panel), "rows\n")
}

cat("\n=== Data fetch summary ===\n")
cat("Study provinces:", nrow(study_provinces), "\n")
cat("Grid cells:", nrow(grid_prov), "\n")
cat("NL panel rows:", nrow(nl_panel), "\n")
if (exists("acled_df")) cat("ACLED events:", nrow(acled_df), "\n")
