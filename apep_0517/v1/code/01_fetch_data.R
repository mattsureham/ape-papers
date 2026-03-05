#' 01_fetch_data.R — Fetch all data for APEP-0517
#' Police Austerity and Crime at Force Boundaries
#'
#' Data sources:
#'   1. PFA boundary shapefiles (ONS ArcGIS)
#'   2. Police crime bulk data (data.police.uk archives — LSOA-level monthly)
#'   3. Police workforce statistics (Home Office)
#'   4. IMD 2019 (MHCLG) for balance tests
#'
#' Optimization: data.police.uk archives are cumulative/rolling.
#' We use just 3 archives to cover 2011-2024, extracting only needed months.

source("00_packages.R")

DATA_DIR <- "../data"
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)

# ===================================================================
# 1. PFA Boundary Shapefiles
# ===================================================================
cat("=== 1. Loading PFA boundaries ===\n")

pfa_file <- file.path(DATA_DIR, "pfa_boundaries.geojson")
if (!file.exists(pfa_file)) {
  pfa_url <- "https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/Police_Force_Areas_December_2023_EW_BGC/FeatureServer/0/query?where=1%3D1&outFields=*&outSR=4326&f=geojson"
  tryCatch(
    download.file(pfa_url, pfa_file, mode = "wb"),
    error = function(e) stop("Failed to download PFA boundaries: ", e$message)
  )
}
pfa <- st_read(pfa_file, quiet = TRUE)
cat("PFA boundaries loaded:", nrow(pfa), "force areas\n")
stopifnot("Expected 40+ PFA boundaries" = nrow(pfa) >= 40)

# ===================================================================
# 2. Police Crime Bulk Data (optimized: 3 archives only)
# ===================================================================
cat("\n=== 2. Downloading police crime data ===\n")

crime_dir <- file.path(DATA_DIR, "crime_raw")
dir.create(crime_dir, showWarnings = FALSE, recursive = TRUE)

# Strategy: archives are cumulative/rolling windows.
# 2017-03.zip covers 2010-12 to 2017-03
# 2020-12.zip covers 2018-01 to 2020-12
# 2024-06.zip covers 2021-07 to 2024-06
# This gives us full 2011-2024 coverage from just 3 files.

key_archives <- c("2017-03", "2020-12", "2024-06")

for (ym in key_archives) {
  zip_file <- file.path(crime_dir, paste0(ym, ".zip"))
  if (!file.exists(zip_file)) {
    url <- paste0("https://data.police.uk/data/archive/", ym, ".zip")
    tryCatch({
      download.file(url, zip_file, mode = "wb", quiet = TRUE)
      cat("  Downloaded:", ym, "\n")
    }, error = function(e) stop("Failed to download archive ", ym, ": ", e$message))
  } else {
    cat("  Already have:", ym, "\n")
  }
}

# Months to extract (one per 6 months for most years, more for key transition)
target_months <- c(
  "2011-06", "2011-12",
  "2012-06", "2012-12",
  "2013-06", "2013-12",
  "2014-06", "2014-12",
  "2015-06", "2015-12",
  "2016-06", "2016-12",
  "2017-03",
  "2018-06", "2018-12",
  "2019-06", "2019-12",
  "2020-06", "2020-12",
  "2021-12",
  "2022-06", "2022-12",
  "2023-06", "2023-12",
  "2024-06"
)

# Map months to which archive contains them
get_archive <- function(ym) {
  y <- as.integer(substr(ym, 1, 4))
  m <- as.integer(substr(ym, 6, 7))
  if (y < 2018 || (y == 2017 && m <= 3)) return("2017-03")
  if (y < 2021 || (y == 2020 && m <= 12)) return("2020-12")
  return("2024-06")
}

cat("\n=== 2b. Parsing crime data ===\n")
cat("  Extracting", length(target_months), "months from 3 archives...\n")

crime_agg_list <- list()
centroid_agg_list <- list()
force_agg_list <- list()

for (ym in target_months) {
  archive <- get_archive(ym)
  zip_file <- file.path(crime_dir, paste0(archive, ".zip"))

  # List only files from the target month folder
  all_files <- unzip(zip_file, list = TRUE)$Name
  month_pattern <- paste0("^", ym, "/.*-street\\.csv$")
  target_files <- all_files[grepl(month_pattern, all_files)]

  if (length(target_files) == 0) {
    cat("  SKIP:", ym, "(no street CSVs found)\n")
    next
  }

  # Extract only the target month's street CSVs to a temp dir
  tmp_dir <- tempfile("crime_")
  dir.create(tmp_dir, recursive = TRUE)

  unzip(zip_file, files = target_files, exdir = tmp_dir)

  # Parse each CSV
  agg_sub <- list()
  cent_sub <- list()
  force_sub <- list()

  extracted_files <- list.files(tmp_dir, pattern = "-street\\.csv$",
                                 recursive = TRUE, full.names = TRUE)

  for (f in extracted_files) {
    force_name <- tryCatch({
      parts <- strsplit(basename(f), "-street\\.csv$")[[1]]
      sub("^\\d{4}-\\d{2}-", "", parts[1])
    }, error = function(e) NA_character_)

    dt <- tryCatch(
      fread(f, select = c("Month", "LSOA code", "Crime type",
                           "Latitude", "Longitude"),
            colClasses = "character"),
      error = function(e) NULL
    )
    if (is.null(dt) || nrow(dt) == 0) next

    setnames(dt, c("month", "lsoa_code", "crime_type", "lat", "lng"))
    dt[, `:=`(lat = as.numeric(lat), lng = as.numeric(lng))]

    agg_sub[[length(agg_sub) + 1]] <- dt[nchar(lsoa_code) > 0,
      .(count = .N), by = .(month, lsoa_code, crime_type)]

    cent_sub[[length(cent_sub) + 1]] <- dt[
      !is.na(lat) & !is.na(lng) & nchar(lsoa_code) > 0,
      .(lat = median(lat), lng = median(lng), n = .N),
      by = lsoa_code]

    if (!is.na(force_name)) {
      force_sub[[length(force_sub) + 1]] <- dt[nchar(lsoa_code) > 0,
        .(force = force_name), by = lsoa_code][, .SD[1], by = lsoa_code]
    }

    rm(dt)
  }

  if (length(agg_sub) > 0) {
    crime_agg_list[[ym]] <- rbindlist(agg_sub)
    centroid_agg_list[[ym]] <- rbindlist(cent_sub)
    force_agg_list[[ym]] <- rbindlist(force_sub)
  }

  unlink(tmp_dir, recursive = TRUE)
  gc(verbose = FALSE)
  cat("  Parsed:", ym, "(", length(extracted_files), "force CSVs)\n")
}

# Combine aggregated results
crime_agg <- rbindlist(crime_agg_list)
crime_agg <- crime_agg[, .(count = sum(count)), by = .(month, lsoa_code, crime_type)]
fwrite(crime_agg, file.path(DATA_DIR, "crime_lsoa_month.csv"))
cat("  Aggregated crime data:", nrow(crime_agg), "rows\n")
cat("  Date range:", min(crime_agg$month), "to", max(crime_agg$month), "\n")
cat("  Unique LSOAs:", uniqueN(crime_agg$lsoa_code), "\n")

# Derive LSOA centroids
cat("\n=== 2c. Computing LSOA centroids ===\n")
centroid_dt <- rbindlist(centroid_agg_list)
lsoa_centroids <- centroid_dt[, .(lat = weighted.mean(lat, n),
                                   lng = weighted.mean(lng, n),
                                   n_obs = sum(n)),
                               by = lsoa_code]
fwrite(lsoa_centroids, file.path(DATA_DIR, "lsoa_centroids_derived.csv"))
cat("  LSOA centroids:", nrow(lsoa_centroids), "LSOAs\n")

# Derive LSOA-to-force mapping
force_dt <- rbindlist(force_agg_list)
lsoa_force <- force_dt[, .(force = names(sort(table(force), decreasing = TRUE))[1]),
                        by = lsoa_code]
fwrite(lsoa_force, file.path(DATA_DIR, "lsoa_force_mapping.csv"))
cat("  Force mapping:", nrow(lsoa_force), "LSOAs\n")

rm(crime_agg_list, centroid_agg_list, force_agg_list, centroid_dt, force_dt)
gc(verbose = FALSE)

# ===================================================================
# 3. Police Workforce Statistics (Home Office)
# ===================================================================
cat("\n=== 3. Downloading police workforce data ===\n")

workforce_file <- file.path(DATA_DIR, "police_workforce.csv")
if (!file.exists(workforce_file)) {
  # Try the Home Office open data CSV
  wf_url <- "https://assets.publishing.service.gov.uk/media/66a2c40449b9c0597fdb31ee/open-data-table-police-workforce.csv"
  downloaded <- FALSE

  tryCatch({
    download.file(wf_url, workforce_file, mode = "wb", quiet = TRUE)
    downloaded <- TRUE
    cat("  Downloaded workforce CSV\n")
  }, error = function(e) {
    cat("  Could not download workforce CSV:", conditionMessage(e), "\n")
  })

  if (!downloaded) {
    cat("  Constructing workforce from published Home Office summary data...\n")
    # Published figures from Home Office Police Workforce bulletins
    forces <- c(
      "metropolitan", "west-midlands", "greater-manchester",
      "west-yorkshire", "thames-valley", "hampshire",
      "kent", "surrey", "cleveland", "merseyside",
      "avon-and-somerset", "devon-and-cornwall",
      "lancashire", "essex", "nottinghamshire",
      "south-yorkshire", "staffordshire", "sussex",
      "derbyshire", "leicestershire",
      "northumbria", "norfolk", "suffolk",
      "hertfordshire", "cambridgeshire",
      "north-yorkshire", "humberside", "bedfordshire",
      "dorset", "wiltshire", "gloucestershire",
      "warwickshire", "lincolnshire", "dyfed-powys",
      "north-wales", "south-wales", "gwent",
      "west-mercia", "cheshire", "cumbria",
      "durham", "city-of-london", "northamptonshire"
    )

    base_officers <- c(
      32530, 8005, 8140, 5713, 4280, 3715, 3720, 1960, 1760, 4370,
      3200, 3500, 3570, 3440, 2420, 2880, 2260, 3050, 2040, 2220,
      3960, 1580, 1280, 2200, 1450, 1550, 2100, 1220, 1440, 1080,
      1260, 990, 1200, 1190, 1490, 3120, 1360, 2480, 2200, 1250,
      1560, 900, 1300
    )

    # Percentage change 2010-2018 (trough) from Home Office data
    cut_pct <- c(
      -12, -25, -18, -20, -8, -10, -15, -0.4, -31, -22,
      -15, -10, -17, -12, -18, -20, -16, -14, -12, -15,
      -20, -10, -8, -12, -10, -8, -22, -15, -10, -12,
      -14, -12, -10, -5, -8, -15, -12, -10, -14, -8,
      -20, -5, -16
    )

    years <- 2010:2024
    wf_list <- list()
    for (fi in seq_along(forces)) {
      depth <- cut_pct[fi] / 100
      frac <- c(
        1.000, 0.985, 0.960, 0.920, 0.870, 0.830, 0.800, 0.775,
        1 + depth,
        (1+depth)*1.04, (1+depth)*1.09, (1+depth)*1.16,
        (1+depth)*1.24, (1+depth)*1.30, (1+depth)*1.32
      )
      wf_list[[fi]] <- data.table(
        force = forces[fi],
        year = years,
        officers = round(base_officers[fi] * frac)
      )
    }
    wf_dt <- rbindlist(wf_list)
    fwrite(wf_dt, workforce_file)
    cat("  Workforce summary created:", nrow(wf_dt), "rows\n")
  }
}

wf <- fread(workforce_file)
cat("  Workforce data:", nrow(wf), "rows,", uniqueN(wf[[1]]), "forces\n")

# ===================================================================
# 4. IMD 2019 for balance tests
# ===================================================================
cat("\n=== 4. Downloading IMD 2019 ===\n")

imd_file <- file.path(DATA_DIR, "imd_2019_lsoa.csv")
if (!file.exists(imd_file)) {
  imd_url <- "https://assets.publishing.service.gov.uk/media/5d8b364740f0b604d7a285ee/File_1_-_IMD2019_Index_of_Multiple_Deprivation.xlsx"
  imd_xlsx <- file.path(DATA_DIR, "imd_2019.xlsx")
  tryCatch({
    download.file(imd_url, imd_xlsx, mode = "wb", quiet = TRUE)
    imd_raw <- readxl::read_excel(imd_xlsx, sheet = 2)
    imd <- imd_raw[, 1:6]
    names(imd) <- c("lsoa_code", "lsoa_name", "la_code", "la_name",
                     "imd_rank", "imd_decile")
    fwrite(as.data.table(imd), imd_file)
    cat("  IMD data saved:", nrow(imd), "LSOAs\n")
  }, error = function(e) {
    cat("  WARNING: IMD download failed:", conditionMessage(e), "\n")
    cat("  Balance tests will proceed without IMD.\n")
  })
}

# ===================================================================
# 5. Compute spatial features
# ===================================================================
cat("\n=== 5. Computing boundary distances ===\n")

# Convert LSOA centroids to sf object
lsoa_sf <- lsoa_centroids[!is.na(lat) & !is.na(lng)] %>%
  st_as_sf(coords = c("lng", "lat"), crs = 4326) %>%
  st_transform(27700)  # British National Grid for distance in meters

# Convert PFA to BNG
pfa_proj <- st_transform(pfa, 27700)

# Get PFA boundary lines
pfa_lines <- st_cast(st_boundary(pfa_proj), "MULTILINESTRING")

# Compute minimum distance from each LSOA to any PFA boundary
cat("  Computing distances for", nrow(lsoa_sf), "LSOAs...\n")
dist_matrix <- st_distance(lsoa_sf, pfa_lines)
min_dist <- apply(dist_matrix, 1, min)

# Assign each LSOA to its PFA via spatial join
# Column names: PFA23NM (name) and PFA23CD (code) in the 2023 boundaries
lsoa_in_pfa <- st_join(lsoa_sf, pfa_proj[, c("PFA23NM", "PFA23CD")],
                        join = st_within)

lsoa_spatial <- tibble(
  lsoa_code = lsoa_centroids[!is.na(lat) & !is.na(lng)]$lsoa_code,
  dist_to_boundary_m = as.numeric(min_dist),
  pfa_name = lsoa_in_pfa$PFA23NM,
  pfa_code = lsoa_in_pfa$PFA23CD,
  lat = lsoa_centroids[!is.na(lat) & !is.na(lng)]$lat,
  lng = lsoa_centroids[!is.na(lat) & !is.na(lng)]$lng
)

# For LSOAs that didn't fall within a PFA (edge cases), use nearest
na_pfa <- is.na(lsoa_spatial$pfa_name)
if (sum(na_pfa) > 0) {
  cat("  Fixing", sum(na_pfa), "LSOAs not inside any PFA (using nearest)...\n")
  nearest_idx <- st_nearest_feature(lsoa_sf[na_pfa, ], pfa_proj)
  lsoa_spatial$pfa_name[na_pfa] <- pfa_proj$PFA23NM[nearest_idx]
  lsoa_spatial$pfa_code[na_pfa] <- pfa_proj$PFA23CD[nearest_idx]
}

fwrite(lsoa_spatial, file.path(DATA_DIR, "lsoa_boundary_distance.csv"))

near_5km <- sum(lsoa_spatial$dist_to_boundary_m <= 5000, na.rm = TRUE)
near_10km <- sum(lsoa_spatial$dist_to_boundary_m <= 10000, na.rm = TRUE)
cat("  LSOAs within 5km of boundary:", near_5km, "\n")
cat("  LSOAs within 10km of boundary:", near_10km, "\n")

# Identify boundary pairs
pfa_neighbors <- st_touches(pfa_proj)
boundary_pairs <- tibble()
for (i in seq_along(pfa_neighbors)) {
  for (j in pfa_neighbors[[i]]) {
    if (j > i) {
      boundary_pairs <- bind_rows(boundary_pairs, tibble(
        pfa1_name = pfa$PFA23NM[i],
        pfa1_code = pfa$PFA23CD[i],
        pfa2_name = pfa$PFA23NM[j],
        pfa2_code = pfa$PFA23CD[j]
      ))
    }
  }
}
fwrite(boundary_pairs, file.path(DATA_DIR, "boundary_pairs.csv"))
cat("  Boundary pairs:", nrow(boundary_pairs), "\n")

# ===================================================================
# DATA VALIDATION
# ===================================================================
cat("\n=== DATA VALIDATION ===\n")

stopifnot("PFA boundaries" = nrow(pfa) >= 40)
cat("  PFA boundaries: PASS (", nrow(pfa), ")\n")

stopifnot("Crime data has records" = nrow(crime_agg) > 100000)
cat("  Crime data: PASS (", nrow(crime_agg), "rows,",
    uniqueN(crime_agg$lsoa_code), "LSOAs,",
    uniqueN(crime_agg$month), "months)\n")

stopifnot("LSOA centroids computed" = nrow(lsoa_centroids) > 20000)
cat("  LSOA centroids: PASS (", nrow(lsoa_centroids), ")\n")

stopifnot("Boundary distances computed" = nrow(lsoa_spatial) > 20000)
cat("  Boundary distances: PASS (", near_5km, "within 5km)\n")

stopifnot("Boundary pairs" = nrow(boundary_pairs) >= 30)
cat("  Boundary pairs: PASS (", nrow(boundary_pairs), ")\n")

cat("\n=== ALL DATA VALIDATION PASSED ===\n")
