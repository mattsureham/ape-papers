## 01_fetch_data.R — Fetch Land Registry, CAZ boundaries, geocode postcodes
## apep_0649: Clean Air Zone property values

source("00_packages.R")
setDTthreads(4)

DATA_DIR <- "../data"
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)

# ═══════════════════════════════════════════════════════════════
# 1) CAZ BOUNDARY DEFINITIONS
# ═══════════════════════════════════════════════════════════════
# Each CAZ has a known center + approximate radius. We query OSM Overpass
# for the exact boundary polygon. Fallback: use a circle approximation.

caz_info <- data.table(
  city       = c("Bath", "Birmingham", "Portsmouth", "Bradford", "Bristol", "Tyneside", "Sheffield"),
  launch     = as.Date(c("2021-03-15", "2021-06-01", "2021-11-29", "2022-09-26",
                          "2022-11-28", "2023-01-30", "2023-02-27")),
  class      = c("C", "D", "B", "C", "D", "C", "D"),
  center_lat = c(51.385, 52.479, 50.798, 53.795, 51.455, 54.975, 53.381),
  center_lon = c(-2.360, -1.900, -1.091, -1.752, -2.593, -1.613, -1.470),
  approx_radius_m = c(1500, 3000, 2000, 2000, 2500, 3000, 2500)
)

cat("CAZ definitions:\n")
print(caz_info)

# ─── Query Overpass for CAZ boundaries ───
get_caz_boundary <- function(city_name, lat, lon, radius_m) {
  cat(sprintf("  Querying OSM for %s CAZ boundary...\n", city_name))

  # Search for CAZ-related relations/ways near the city center
  query <- sprintf('[out:json][timeout:30];
    (
      relation["name"~"Clean Air Zone|CAZ",i](around:%d,%f,%f);
      way["name"~"Clean Air Zone|CAZ",i](around:%d,%f,%f);
      relation["boundary"="low_emission_zone"](around:%d,%f,%f);
    );
    out geom;', radius_m * 3, lat, lon, radius_m * 3, lat, lon, radius_m * 3, lat, lon)

  resp <- tryCatch({
    request("https://overpass-api.de/api/interpreter") |>
      req_body_form(data = query) |>
      req_timeout(60) |>
      req_perform()
  }, error = function(e) {
    cat(sprintf("    OSM query failed for %s: %s\n", city_name, e$message))
    return(NULL)
  })

  if (is.null(resp)) return(NULL)

  json <- resp_body_json(resp)
  if (length(json$elements) == 0) {
    cat(sprintf("    No OSM boundary found for %s\n", city_name))
    return(NULL)
  }

  cat(sprintf("    Found %d elements for %s\n", length(json$elements), city_name))
  return(json)
}

# Try to get boundaries from OSM; fall back to circular approximation
caz_polygons <- list()

for (i in 1:nrow(caz_info)) {
  row <- caz_info[i]
  Sys.sleep(2)  # Rate limit for Overpass
  osm_result <- get_caz_boundary(row$city, row$center_lat, row$center_lon, row$approx_radius_m)

  if (!is.null(osm_result) && length(osm_result$elements) > 0) {
    # Extract coordinates from the first relation/way with geometry
    elem <- osm_result$elements[[1]]
    coords <- NULL

    if (!is.null(elem$geometry)) {
      coords <- do.call(rbind, lapply(elem$geometry, function(g) c(g$lon, g$lat)))
    } else if (!is.null(elem$members)) {
      # Relation: extract from members with geometry
      all_coords <- list()
      for (m in elem$members) {
        if (!is.null(m$geometry)) {
          mc <- do.call(rbind, lapply(m$geometry, function(g) c(g$lon, g$lat)))
          all_coords[[length(all_coords) + 1]] <- mc
        }
      }
      if (length(all_coords) > 0) coords <- do.call(rbind, all_coords)
    }

    if (!is.null(coords) && nrow(coords) >= 3) {
      # Close the polygon
      if (!all(coords[1, ] == coords[nrow(coords), ])) {
        coords <- rbind(coords, coords[1, ])
      }
      poly <- st_sfc(st_polygon(list(coords)), crs = 4326)
      caz_polygons[[row$city]] <- st_sf(city = row$city, geometry = poly)
      cat(sprintf("    ✓ %s: polygon with %d vertices\n", row$city, nrow(coords)))
    } else {
      cat(sprintf("    Could not extract polygon for %s, using circular approximation\n", row$city))
      center <- st_sfc(st_point(c(row$center_lon, row$center_lat)), crs = 4326)
      circle <- st_buffer(st_transform(center, 27700), row$approx_radius_m)
      circle <- st_transform(circle, 4326)
      caz_polygons[[row$city]] <- st_sf(city = row$city, geometry = circle)
    }
  } else {
    # Circular approximation
    cat(sprintf("    Using circular approximation for %s (r=%dm)\n", row$city, row$approx_radius_m))
    center <- st_sfc(st_point(c(row$center_lon, row$center_lat)), crs = 4326)
    circle <- st_buffer(st_transform(center, 27700), row$approx_radius_m)
    circle <- st_transform(circle, 4326)
    caz_polygons[[row$city]] <- st_sf(city = row$city, geometry = circle)
  }
}

caz_boundaries <- do.call(rbind, caz_polygons)
st_write(caz_boundaries, file.path(DATA_DIR, "caz_boundaries.gpkg"), delete_dsn = TRUE)
cat(sprintf("Saved %d CAZ boundaries\n", nrow(caz_boundaries)))

# ═══════════════════════════════════════════════════════════════
# 2) LAND REGISTRY PRICE PAID DATA
# ═══════════════════════════════════════════════════════════════
# Download per-year CSVs, filter to 7-city postcode areas

# Postcode area prefixes for each city (broad — will filter precisely later)
city_pc_prefixes <- list(
  Bath = c("BA1", "BA2"),
  Birmingham = c("B1", "B2", "B3", "B4", "B5", "B6", "B7", "B8", "B9",
                  "B10", "B11", "B12", "B13", "B14", "B15", "B16", "B17", "B18", "B19",
                  "B20", "B21", "B23", "B24", "B25", "B26", "B27", "B28", "B29",
                  "B30", "B31", "B32", "B33", "B34", "B35", "B36", "B37", "B38"),
  Portsmouth = c("PO1", "PO2", "PO3", "PO4", "PO5", "PO6"),
  Bradford = c("BD1", "BD2", "BD3", "BD4", "BD5", "BD6", "BD7", "BD8", "BD9",
               "BD10", "BD11", "BD12", "BD13", "BD14", "BD15", "BD17", "BD18"),
  Bristol = c("BS1", "BS2", "BS3", "BS4", "BS5", "BS6", "BS7", "BS8", "BS9",
              "BS10", "BS11", "BS13", "BS14", "BS15", "BS16"),
  Tyneside = c("NE1", "NE2", "NE3", "NE4", "NE5", "NE6", "NE7", "NE8",
               "NE9", "NE10", "NE11", "NE12", "NE13", "NE15", "NE16",
               "NE25", "NE26", "NE27", "NE28", "NE29", "NE30", "NE31",
               "NE32", "NE33", "NE34"),
  Sheffield = c("S1", "S2", "S3", "S4", "S5", "S6", "S7", "S8", "S9",
                "S10", "S11", "S12", "S13", "S14", "S17", "S20", "S21", "S35", "S36")
)
all_prefixes <- unlist(city_pc_prefixes)

lr_col_names <- c("txn_id", "price", "date", "postcode", "prop_type", "old_new",
                   "duration", "paon", "saon", "street", "locality", "town",
                   "district", "county", "ppd_cat", "record_status")

years <- 2018:2024
all_lr <- list()

for (yr in years) {
  fname <- file.path(DATA_DIR, sprintf("pp-%d.csv", yr))

  if (!file.exists(fname)) {
    url <- sprintf("http://prod.publicdata.landregistry.gov.uk.s3-website-eu-west-1.amazonaws.com/pp-%d.csv", yr)
    cat(sprintf("Downloading Land Registry %d...\n", yr))
    tryCatch({
      download.file(url, fname, mode = "wb", quiet = TRUE)
      cat(sprintf("  ✓ Downloaded %s (%.0f MB)\n", basename(fname), file.size(fname) / 1e6))
    }, error = function(e) {
      stop(sprintf("FATAL: Failed to download Land Registry %d: %s", yr, e$message))
    })
  } else {
    cat(sprintf("  Using cached %s\n", basename(fname)))
  }

  # Read and filter to relevant postcodes
  dt <- fread(fname, header = FALSE, col.names = lr_col_names, na.strings = "")
  dt[, date := as.Date(substr(date, 1, 10))]

  # Extract postcode district (e.g., "BA1" from "BA1 2QF")
  dt[, pc_district := sub("^([A-Z]{1,2}[0-9]{1,2}[A-Z]?)\\s.*", "\\1", postcode)]

  dt_filtered <- dt[pc_district %chin% all_prefixes]
  cat(sprintf("  %d: %d total transactions, %d in 7-city areas\n", yr, nrow(dt), nrow(dt_filtered)))

  all_lr[[as.character(yr)]] <- dt_filtered[, .(txn_id, price, date, postcode, prop_type, old_new, duration, town, district)]

  # Free memory
  rm(dt)
  gc()
}

lr_data <- rbindlist(all_lr)
cat(sprintf("\nTotal Land Registry transactions in 7-city areas: %d\n", nrow(lr_data)))

# Assign city based on postcode
lr_data[, city := NA_character_]
for (city_name in names(city_pc_prefixes)) {
  pcs <- city_pc_prefixes[[city_name]]
  lr_data[sub("^([A-Z]{1,2}[0-9]{1,2}[A-Z]?)\\s.*", "\\1", postcode) %chin% pcs, city := city_name]
}
lr_data <- lr_data[!is.na(city)]
cat(sprintf("After city assignment: %d transactions\n", nrow(lr_data)))

fwrite(lr_data, file.path(DATA_DIR, "lr_7cities.csv"))
cat("Saved Land Registry data\n")

# ═══════════════════════════════════════════════════════════════
# 3) GEOCODE POSTCODES
# ═══════════════════════════════════════════════════════════════
# Use postcodes.io bulk API (100 postcodes per request)

unique_pcs <- unique(lr_data$postcode)
unique_pcs <- unique_pcs[!is.na(unique_pcs)]
cat(sprintf("Unique postcodes to geocode: %d\n", length(unique_pcs)))

# Check for cached geocodes
gc_file <- file.path(DATA_DIR, "postcode_geocodes.csv")
if (file.exists(gc_file)) {
  existing_gc <- fread(gc_file)
  remaining_pcs <- setdiff(unique_pcs, existing_gc$postcode)
  cat(sprintf("  Cached: %d, remaining: %d\n", nrow(existing_gc), length(remaining_pcs)))
} else {
  existing_gc <- data.table()
  remaining_pcs <- unique_pcs
}

if (length(remaining_pcs) > 0) {
  # Batch geocode in groups of 100
  batches <- split(remaining_pcs, ceiling(seq_along(remaining_pcs) / 100))
  cat(sprintf("  Geocoding %d postcodes in %d batches...\n", length(remaining_pcs), length(batches)))

  new_gc <- list()
  n_success <- 0
  n_fail <- 0

  for (b in seq_along(batches)) {
    if (b %% 50 == 0) cat(sprintf("    Batch %d/%d (%.0f%%)\n", b, length(batches), 100 * b / length(batches)))

    resp <- tryCatch({
      request("https://api.postcodes.io/postcodes") |>
        req_body_json(list(postcodes = batches[[b]])) |>
        req_timeout(30) |>
        req_perform()
    }, error = function(e) {
      Sys.sleep(2)
      NULL
    })

    if (!is.null(resp)) {
      result <- resp_body_json(resp)
      for (r in result$result) {
        if (!is.null(r$result)) {
          lsoa_val <- if (!is.null(r$result$lsoa)) r$result$lsoa else NA_character_
          admin_val <- if (!is.null(r$result$admin_district)) r$result$admin_district else NA_character_
          new_gc[[length(new_gc) + 1]] <- data.table(
            postcode = r$query,
            latitude = r$result$latitude,
            longitude = r$result$longitude,
            lsoa = lsoa_val,
            admin_district = admin_val
          )
          n_success <- n_success + 1
        } else {
          n_fail <- n_fail + 1
        }
      }
    }

    Sys.sleep(0.15)  # Rate limit
  }

  if (length(new_gc) > 0) {
    new_gc_dt <- rbindlist(new_gc)
    existing_gc <- rbind(existing_gc, new_gc_dt, fill = TRUE)
  }
  cat(sprintf("  Geocoded: %d success, %d failed\n", n_success, n_fail))
}

fwrite(existing_gc, gc_file)
cat(sprintf("Saved %d geocodes\n", nrow(existing_gc)))

# ═══════════════════════════════════════════════════════════════
# 4) CLEAN UP RAW YEAR FILES TO SAVE DISK SPACE
# ═══════════════════════════════════════════════════════════════
for (yr in years) {
  fname <- file.path(DATA_DIR, sprintf("pp-%d.csv", yr))
  if (file.exists(fname) && file.size(fname) > 1e8) {
    file.remove(fname)
    cat(sprintf("  Removed raw file %s\n", basename(fname)))
  }
}

cat("\n=== Data fetch complete ===\n")
cat(sprintf("  Land Registry transactions: %d\n", nrow(lr_data)))
cat(sprintf("  Geocoded postcodes: %d\n", nrow(existing_gc)))
cat(sprintf("  CAZ boundaries: %d\n", nrow(caz_boundaries)))
