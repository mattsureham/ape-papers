# ==============================================================================
# APEP-0509: MGNREGA, Input Substitution, and Crop-Specific Productivity
# 01_fetch_data.R — Fetch all data from ICRISAT DLD API
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ==============================================================================
# Helper function to fetch ICRISAT DLD API endpoint
# ==============================================================================

fetch_icrisat <- function(endpoint, cache_file, variant = "apportioned") {
  cache_path <- file.path(data_dir, cache_file)

  if (file.exists(cache_path)) {
    cat(sprintf("  Loading cached: %s\n", cache_file))
    return(readRDS(cache_path))
  }

  url <- sprintf("http://data.icrisat.org/dldAPI/%s/%s", variant, endpoint)
  cat(sprintf("  Fetching: %s ...\n", url))

  raw <- tryCatch(
    fromJSON(url, flatten = TRUE),
    error = function(e) stop("ICRISAT API unavailable: ", e$message,
                             "\nPivot research question or fix the source.")
  )

  # Parse: raw$headers is a data.frame with 'header' column; raw$data is a matrix
  col_names <- raw$headers$header
  dt <- as.data.table(raw$data)
  setnames(dt, names(dt), col_names)

  # Convert numeric columns (skip geographic identifiers)
  geo_cols <- c("Dist Code", "Year", "Indian census State Code 2011",
                "Indian census District Code 2011", "SAT NONSAT Districts",
                "Region Code", "Region Name", "Agro Ecological Zones ICRISAT",
                "Agro Ecological Zones NATP", "AEZ Production Systems NATP",
                "State Code", "State Name", "ICRISAT Indian Id", "Dist Name",
                "LATITUDE", "LONGITUDE")
  num_cols <- setdiff(col_names, geo_cols)
  for (col in num_cols) {
    dt[, (col) := suppressWarnings(as.numeric(get(col)))]
  }

  # Convert key IDs to numeric
  for (col in c("Dist Code", "Year", "State Code",
                "Indian census State Code 2011",
                "Indian census District Code 2011")) {
    if (col %in% names(dt)) dt[, (col) := as.numeric(get(col))]
  }

  dt[, LATITUDE := as.numeric(LATITUDE)]
  dt[, LONGITUDE := as.numeric(LONGITUDE)]

  saveRDS(dt, cache_path)
  cat(sprintf("  Saved: %s (%d rows, %d cols)\n", cache_file, nrow(dt), ncol(dt)))
  return(dt)
}

# ==============================================================================
# 1. Fetch crop area, production, yield data
# ==============================================================================
cat("=== Fetching crop area/production/yield data ===\n")
apy <- fetch_icrisat("area-production-yield", "apy_raw.rds")

# ==============================================================================
# 2. Fetch fertilizer consumption data
# ==============================================================================
cat("\n=== Fetching fertilizer consumption data ===\n")
fert <- fetch_icrisat("fertilizer-consumption", "fert_raw.rds")

# ==============================================================================
# 3. Fetch agricultural wages data
# ==============================================================================
cat("\n=== Fetching agricultural wages data ===\n")
wages <- fetch_icrisat("wages", "wages_raw.rds")

# ==============================================================================
# 4. Fetch cropwise irrigated area data
# ==============================================================================
cat("\n=== Fetching cropwise irrigated area data ===\n")
irr <- fetch_icrisat("cropwise-irrigated-area", "irr_raw.rds")

# ==============================================================================
# 5. Fetch monthly rainfall data
# ==============================================================================
cat("\n=== Fetching rainfall data ===\n")
rain <- fetch_icrisat("monthly-rainfall", "rain_raw.rds")

# ==============================================================================
# 6. Fetch Census population data (for backwardness index)
# ==============================================================================
cat("\n=== Fetching Census population data ===\n")
pop <- fetch_icrisat("population", "pop_raw.rds")

# ==============================================================================
# 7. Fetch district metadata
# ==============================================================================
cat("\n=== Fetching district metadata ===\n")
dist_meta_path <- file.path(data_dir, "districts_raw.rds")
if (file.exists(dist_meta_path)) {
  cat("  Loading cached: districts_raw.rds\n")
  dist_meta <- readRDS(dist_meta_path)
} else {
  url <- "http://data.icrisat.org/dldAPI/apportioned/districts"
  cat(sprintf("  Fetching: %s ...\n", url))
  dist_meta <- as.data.table(fromJSON(url, flatten = TRUE))
  saveRDS(dist_meta, dist_meta_path)
  cat(sprintf("  Saved: districts_raw.rds (%d districts)\n", nrow(dist_meta)))
}

# ==============================================================================
# DATA VALIDATION
# ==============================================================================
cat("\n=== Data Validation ===\n")
stopifnot("Expected 300+ districts in crop data" = length(unique(apy$`Dist Code`)) >= 300)
stopifnot("Expected 2000-2017 in crop data" = all(2000:2017 %in% unique(apy$Year)))
stopifnot("Expected fertilizer data" = nrow(fert) > 10000)
stopifnot("Expected wage data" = nrow(wages) > 10000)
stopifnot("Expected irrigation data" = nrow(irr) > 10000)
stopifnot("Expected Census population data" = nrow(pop) > 1000)
stopifnot("Expected 300+ districts in metadata" = nrow(dist_meta) >= 300)

cat(sprintf("Crop data: %d rows, %d districts, years %d-%d\n",
            nrow(apy), length(unique(apy$`Dist Code`)),
            min(apy$Year), max(apy$Year)))
cat(sprintf("Fertilizer: %d rows\n", nrow(fert)))
cat(sprintf("Wages: %d rows, years %d-%d\n",
            nrow(wages), min(wages$Year), max(wages$Year)))
cat(sprintf("Irrigation: %d rows\n", nrow(irr)))
cat(sprintf("Rainfall: %d rows\n", nrow(rain)))
cat(sprintf("Population: %d rows\n", nrow(pop)))
cat(sprintf("Districts: %d\n", nrow(dist_meta)))
cat("\nAll data validation passed.\n")
