# ============================================================================
# 01_fetch_data.R — Fetch Eurostat tourism, GDP, and geographic data
# APEP-0593: Roaming Abolition and Cross-Border Tourism
# ============================================================================

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# Helper: eurostat v4+ uses TIME_PERIOD instead of time
fix_time <- function(dt) {
  if ("TIME_PERIOD" %in% names(dt) && !"time" %in% names(dt)) {
    setnames(dt, "TIME_PERIOD", "time")
  }
  dt
}

# -----------------------------------------------------------------------
# 1. Foreign tourist nights at NUTS2 (primary outcome)
#    Dataset: tour_occ_nin2 — Nights spent at tourist accommodation
#    by NUTS 2 regions
# -----------------------------------------------------------------------
cat("Fetching Eurostat tour_occ_nin2 (tourist nights, NUTS2)...\n")

tourism_raw <- tryCatch(
  get_eurostat("tour_occ_nin2", time_format = "num"),
  error = function(e) stop("Failed to fetch tour_occ_nin2: ", e$message,
                           "\nPivot research question or fix the source.")
)
cat("  Raw rows:", nrow(tourism_raw), "\n")

# Filter: nace_r2 = I551-I553 (hotels, holiday, campgrounds) or total
# c_resid: TOTAL, FOR (foreign), DOM (domestic)
# unit: NR (number of nights)
tourism <- fix_time(as.data.table(tourism_raw))
tourism <- tourism[unit == "NR"]
cat("  After unit=NR filter:", nrow(tourism), "\n")

# Keep useful c_resid categories
tourism <- tourism[c_resid %in% c("TOTAL", "FOR", "DOM")]

# Filter to nace_r2 = I551-I553 (total accommodation) or TOTAL
tourism <- tourism[nace_r2 %in% c("I551-I553", "TOTAL")]

# Keep years 2012-2022
tourism <- tourism[time >= 2012 & time <= 2022]

# Keep only NUTS2 codes (4-character geo codes for NUTS2)
tourism[, geo_len := nchar(as.character(geo))]
tourism <- tourism[geo_len == 4]  # NUTS2 = country (2) + region (2)
tourism[, geo_len := NULL]

cat("  Tourism data (NUTS2, 2012-2022):", nrow(tourism), "rows,",
    uniqueN(tourism$geo), "regions,",
    uniqueN(tourism$time), "years\n")

fwrite(tourism, file.path(data_dir, "tourism_nuts2.csv"))

# -----------------------------------------------------------------------
# 2. Tourist nights by country of residence (for intra-EEA decomposition)
#    Dataset: tour_occ_ninraw — national-level, by origin country
# -----------------------------------------------------------------------
cat("\nFetching Eurostat tour_occ_ninraw (tourist nights by origin country)...\n")

tourism_origin <- tryCatch(
  get_eurostat("tour_occ_ninraw", time_format = "num"),
  error = function(e) {
    warning("tour_occ_ninraw not available: ", e$message)
    NULL
  }
)

if (!is.null(tourism_origin)) {
  tourism_origin <- fix_time(as.data.table(tourism_origin))
  tourism_origin <- tourism_origin[unit == "NR" & time >= 2012 & time <= 2022]
  # Keep only country-level destination (2-char geo)
  tourism_origin[, geo_len := nchar(as.character(geo))]
  tourism_origin <- tourism_origin[geo_len == 2]
  tourism_origin[, geo_len := NULL]
  cat("  Tourism origin data:", nrow(tourism_origin), "rows,",
      uniqueN(tourism_origin$geo), "destinations,",
      uniqueN(tourism_origin$partner), "origins\n")
  fwrite(tourism_origin, file.path(data_dir, "tourism_origin_national.csv"))
} else {
  cat("  Skipping tourism origin data (not available)\n")
}

# -----------------------------------------------------------------------
# 3. NUTS2 GDP (secondary outcome)
#    Dataset: nama_10r_2gdp
# -----------------------------------------------------------------------
cat("\nFetching Eurostat nama_10r_2gdp (GDP at NUTS2)...\n")

gdp_raw <- tryCatch(
  get_eurostat("nama_10r_2gdp", time_format = "num",
               filters = list(unit = "MIO_EUR")),
  error = function(e) stop("Failed to fetch NUTS2 GDP: ", e$message)
)

gdp <- fix_time(as.data.table(gdp_raw))
gdp <- gdp[time >= 2012 & time <= 2022]
gdp[, geo_len := nchar(as.character(geo))]
gdp <- gdp[geo_len == 4]
gdp[, geo_len := NULL]
cat("  GDP NUTS2:", nrow(gdp), "rows,", uniqueN(gdp$geo), "regions\n")

fwrite(gdp, file.path(data_dir, "gdp_nuts2.csv"))

# -----------------------------------------------------------------------
# 4. Population by NUTS2 (control variable)
#    Dataset: demo_r_pjanaggr3
# -----------------------------------------------------------------------
cat("\nFetching Eurostat demo_r_pjanaggr3 (population NUTS2/3)...\n")

pop_raw <- tryCatch(
  get_eurostat("demo_r_pjanaggr3", time_format = "num",
               filters = list(sex = "T", age = "TOTAL")),
  error = function(e) stop("Failed to fetch population: ", e$message)
)

pop <- fix_time(as.data.table(pop_raw))
pop <- pop[time >= 2012 & time <= 2022]
pop[, geo_len := nchar(as.character(geo))]
pop_nuts2 <- pop[geo_len == 4]
pop_nuts2[, geo_len := NULL]
cat("  Population NUTS2:", nrow(pop_nuts2), "rows,",
    uniqueN(pop_nuts2$geo), "regions\n")

fwrite(pop_nuts2, file.path(data_dir, "pop_nuts2.csv"))

# -----------------------------------------------------------------------
# 5. NUTS2 boundaries (for border classification)
# -----------------------------------------------------------------------
cat("\nFetching NUTS2 boundaries (GISCO shapefiles)...\n")

nuts2_sf <- tryCatch(
  get_eurostat_geospatial(resolution = "20", nuts_level = "2", year = 2016),
  error = function(e) stop("Failed to fetch NUTS2 shapefile: ", e$message)
)

cat("  NUTS2 shapefile:", nrow(nuts2_sf), "regions\n")

# Save as geopackage
sf::st_write(nuts2_sf, file.path(data_dir, "nuts2_2016.gpkg"),
             delete_dsn = TRUE, quiet = TRUE)

# -----------------------------------------------------------------------
# 6. Average length of stay (mechanism)
#    Dataset: tour_occ_arnts
# -----------------------------------------------------------------------
cat("\nFetching Eurostat tour_occ_arnts (avg nights per stay)...\n")

arnts_raw <- tryCatch(
  get_eurostat("tour_occ_arnts", time_format = "num"),
  error = function(e) {
    warning("tour_occ_arnts not available: ", e$message)
    NULL
  }
)

if (!is.null(arnts_raw)) {
  arnts <- fix_time(as.data.table(arnts_raw))
  arnts <- arnts[time >= 2012 & time <= 2022]
  arnts[, geo_len := nchar(as.character(geo))]
  arnts <- arnts[geo_len == 4]
  arnts[, geo_len := NULL]
  cat("  Average nights:", nrow(arnts), "rows\n")
  fwrite(arnts, file.path(data_dir, "avg_nights_nuts2.csv"))
} else {
  cat("  Skipping average nights data\n")
}

# =======================================================================
# DATA VALIDATION (required)
# =======================================================================
cat("\n=== DATA VALIDATION ===\n")
stopifnot("Expected 100+ NUTS2 regions in tourism" =
            uniqueN(tourism$geo) >= 100)
stopifnot("Expected 2012-2022 coverage" =
            all(2012:2019 %in% unique(tourism$time)))
stopifnot("Expected foreign/domestic split" =
            all(c("FOR", "DOM") %in% unique(tourism$c_resid)))

cat("Data validation passed:", nrow(tourism), "tourism rows,",
    uniqueN(tourism$geo), "NUTS2 regions,",
    length(unique(tourism$time)), "years\n")
cat("All data fetched and saved to", data_dir, "\n")
