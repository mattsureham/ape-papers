## 01_fetch_data.R — Fetch and prepare raw data
## apep_1272: Breaking the Gauge Barrier
##
## Data sources:
##   1. SHRUG nightlights (DMSP) — on disk at data/india_shrug/
##   2. SHRUG district crosswalk — on disk
##   3. SHRUG Census 2001/2011 — on disk
##   4. SHRUG Economic Census 2005/2013 — on disk
##   5. datameet/railways stations.json — GitHub (CC0)

source("00_packages.R")

data_dir <- "../data"
shrug_dir <- "../../../../data/india_shrug"

dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ── 1. Load SHRUG nightlights (district-level, DMSP 1992–2013) ──────────

cat("Loading SHRUG nightlights...\n")
nl <- fread(file.path(shrug_dir, "dmsp_pc11dist.tab"))
stopifnot(nrow(nl) > 0, "dmsp_total_light_cal" %in% names(nl))
cat(sprintf("  Nightlights: %d district-year observations, years %d-%d\n",
            nrow(nl), min(nl$year), max(nl$year)))

# ── 2. Load SHRUG district crosswalk ────────────────────────────────────

cat("Loading SHRUG district crosswalk...\n")
td <- fread(file.path(shrug_dir, "pc11_td_clean_pc11dist.tab"))
cat(sprintf("  Crosswalk: %d districts\n", nrow(td)))

# ── 3. Load Census PCA for baseline controls ────────────────────────────

cat("Loading Census 2011 PCA...\n")
pca <- fread(file.path(shrug_dir, "pc11_pca_clean_pc11dist.tab"))
cat(sprintf("  Census PCA: %d districts\n", nrow(pca)))

# ── 4. Load Economic Census for firm outcomes ───────────────────────────

cat("Loading Economic Census 2005 and 2013...\n")
ec05 <- fread(file.path(shrug_dir, "ec05_pc11dist.tab"))
ec13 <- fread(file.path(shrug_dir, "ec13_pc11dist.tab"))
cat(sprintf("  EC05: %d districts, EC13: %d districts\n", nrow(ec05), nrow(ec13)))

# ── 5. Fetch datameet railway stations ──────────────────────────────────

stations_file <- file.path(data_dir, "stations.json")
if (!file.exists(stations_file)) {
  cat("Downloading datameet railway stations...\n")
  url <- "https://raw.githubusercontent.com/datameet/railways/master/stations.json"
  download.file(url, stations_file, quiet = TRUE)
}

cat("Parsing railway stations GeoJSON...\n")
stations_raw <- jsonlite::fromJSON(stations_file, flatten = TRUE)

# Extract coordinates safely (some may be NULL)
coords <- stations_raw$features$geometry.coordinates
lon_vec <- sapply(coords, function(x) if (is.null(x) || length(x) < 1) NA_real_ else x[1])
lat_vec <- sapply(coords, function(x) if (is.null(x) || length(x) < 2) NA_real_ else x[2])

stations_df <- data.table(
  name   = stations_raw$features$properties.name,
  code   = stations_raw$features$properties.code,
  state  = stations_raw$features$properties.state,
  zone   = stations_raw$features$properties.zone,
  lon    = as.numeric(lon_vec),
  lat    = as.numeric(lat_vec)
)
# Drop stations with missing coordinates or zone
stations_df <- stations_df[!is.na(lon) & !is.na(lat) & !is.na(zone) & zone != "?"]
cat(sprintf("  Stations: %d with %d unique zones\n",
            nrow(stations_df), uniqueN(stations_df$zone)))
cat("  Zone distribution:\n")
print(stations_df[, .N, by = zone][order(-N)])

# ── 6. Validate data presence ───────────────────────────────────────────

stopifnot(
  nrow(nl) > 5000,
  nrow(td) > 500,
  nrow(stations_df) > 3000
)

# ── 7. Save intermediate files ──────────────────────────────────────────

fwrite(nl, file.path(data_dir, "nightlights_district.csv"))
fwrite(td, file.path(data_dir, "district_crosswalk.csv"))
fwrite(pca, file.path(data_dir, "census_pca.csv"))
fwrite(ec05, file.path(data_dir, "ec05_district.csv"))
fwrite(ec13, file.path(data_dir, "ec13_district.csv"))
fwrite(stations_df, file.path(data_dir, "railway_stations.csv"))

cat("\nAll data fetched and saved.\n")
