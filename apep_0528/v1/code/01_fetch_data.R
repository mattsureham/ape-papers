## 01_fetch_data.R — Fetch ElCom tariffs and municipal boundaries
## APEP-0528: Do Administrative Borders Tax Electricity?

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ===========================================================================
# 1. ElCom Electricity Tariff Data (SPARQL from LINDAS)
# ===========================================================================
cat("=== Fetching ElCom electricity tariff data ===\n")

sparql_endpoint <- "https://lindas.admin.ch/query"

# Query for household consumption category H4 (typical 4-room apartment, 4500 kWh/year)
# This is ElCom's standard comparison category
sparql_query <- '
PREFIX cube: <https://cube.link/>
PREFIX elcom: <https://energy.ld.admin.ch/elcom/electricityprice/dimension/>

SELECT ?period ?munId ?operator ?total ?energy ?gridusage ?aidfee ?charge
WHERE {
  <https://energy.ld.admin.ch/elcom/electricityprice> cube:observationSet/cube:observation ?obs .
  ?obs elcom:period ?period ;
       elcom:municipality ?mun ;
       elcom:operator ?op ;
       elcom:category <https://energy.ld.admin.ch/elcom/electricityprice/category/H4> ;
       elcom:total ?total ;
       elcom:energy ?energy ;
       elcom:gridusage ?gridusage ;
       elcom:aidfee ?aidfee ;
       elcom:charge ?charge .
  BIND(REPLACE(STR(?mun), "https://ld.admin.ch/municipality/", "") AS ?munId)
  BIND(REPLACE(STR(?op), "https://energy.ld.admin.ch/elcom/electricityprice/operator/", "") AS ?operator)
}
'

cat("  Querying LINDAS SPARQL endpoint...\n")
resp <- POST(
  sparql_endpoint,
  body = list(query = sparql_query),
  encode = "form",
  add_headers(Accept = "text/csv"),
  timeout(600)
)

if (status_code(resp) != 200) {
  stop("ElCom SPARQL query failed with status: ", status_code(resp),
       "\nResponse: ", content(resp, "text", encoding = "UTF-8"))
}

elcom_raw <- content(resp, "text", encoding = "UTF-8")
elcom <- fread(text = elcom_raw)

cat("  Raw observations:", nrow(elcom), "\n")
cat("  Columns:", paste(names(elcom), collapse = ", "), "\n")

# Parse and clean
elcom[, year := as.integer(substr(period, 1, 4))]
elcom[, mun_id := as.integer(munId)]
elcom[, operator_id := operator]

# Keep numeric tariff columns (convert from character if needed)
tariff_cols <- c("total", "energy", "gridusage", "aidfee", "charge")
for (col in tariff_cols) {
  elcom[, (col) := as.numeric(get(col))]
}

# Remove rows with missing municipality IDs
elcom <- elcom[!is.na(mun_id) & !is.na(year)]

cat("  Cleaned observations:", nrow(elcom), "\n")
cat("  Years:", paste(sort(unique(elcom$year)), collapse = ", "), "\n")
cat("  Municipalities:", uniqueN(elcom$mun_id), "\n")
cat("  Operators:", uniqueN(elcom$operator_id), "\n")

fwrite(elcom, file.path(data_dir, "elcom_tariffs.csv"))
cat("  Saved to data/elcom_tariffs.csv\n\n")

# ===========================================================================
# 2. Municipal Boundaries (swissBOUNDARIES3D)
# ===========================================================================
cat("=== Fetching municipal boundary data ===\n")

# Use BFS generalized boundaries (smaller file, sufficient for centroids and distances)
bfs_url <- "https://dam-api.bfs.admin.ch/hub/api/dam/assets/30487000/master"
bfs_zip <- file.path(data_dir, "bfs_boundaries.zip")
bfs_dir <- file.path(data_dir, "bfs_boundaries")

if (!file.exists(bfs_zip)) {
  cat("  Downloading BFS generalized boundaries...\n")
  tryCatch({
    download.file(bfs_url, bfs_zip, mode = "wb", quiet = TRUE)
    cat("  Downloaded:", file.size(bfs_zip), "bytes\n")
  }, error = function(e) {
    stop("BFS boundary download failed: ", e$message,
         "\nPivot or fix the source.")
  })
}

# Extract
dir.create(bfs_dir, showWarnings = FALSE, recursive = TRUE)
unzip(bfs_zip, exdir = bfs_dir, overwrite = TRUE)

# Find the shapefile or geopackage
boundary_files <- list.files(bfs_dir, pattern = "\\.(gpkg|shp)$", recursive = TRUE, full.names = TRUE)
cat("  Found boundary files:", paste(basename(boundary_files), collapse = ", "), "\n")

# Try to find municipal boundaries
mun_file <- boundary_files[grepl("(gemeinde|municipality|Gemeinde)", boundary_files, ignore.case = TRUE)]
if (length(mun_file) == 0) {
  # Try any file and list layers
  if (length(boundary_files) > 0) {
    cat("  Checking layers in:", basename(boundary_files[1]), "\n")
    layers <- st_layers(boundary_files[1])
    cat("  Available layers:", paste(layers$name, collapse = ", "), "\n")
    # Try to read a municipality-like layer
    mun_layer <- layers$name[grepl("(gemeinde|municipality|polg|POLG)", layers$name, ignore.case = TRUE)]
    if (length(mun_layer) > 0) {
      mun_file <- boundary_files[1]
      cat("  Using layer:", mun_layer[1], "\n")
    }
  }
}

if (length(mun_file) == 0) {
  cat("  BFS file structure not as expected. Trying swisstopo alternative...\n")
  # Fallback: download swisstopo boundaries (larger but guaranteed structure)
  swiss_url <- "https://data.geo.admin.ch/ch.swisstopo.swissboundaries3d/swissboundaries3d_2024-01/swissboundaries3d_2024-01_2056_5728.gpkg.zip"
  swiss_zip <- file.path(data_dir, "swissboundaries.zip")
  swiss_dir <- file.path(data_dir, "swissboundaries")

  tryCatch({
    download.file(swiss_url, swiss_zip, mode = "wb", quiet = TRUE)
    dir.create(swiss_dir, showWarnings = FALSE, recursive = TRUE)
    unzip(swiss_zip, exdir = swiss_dir, overwrite = TRUE)
    gpkg_files <- list.files(swiss_dir, pattern = "\\.gpkg$", recursive = TRUE, full.names = TRUE)
    mun_file <- gpkg_files[1]
    cat("  Downloaded swisstopo boundaries:", basename(mun_file), "\n")
    layers <- st_layers(mun_file)
    cat("  Layers:", paste(layers$name, collapse = ", "), "\n")
    mun_layer <- layers$name[grepl("(gemeinde|hoheitsgebiet|POLG)", layers$name, ignore.case = TRUE)]
  }, error = function(e) {
    stop("Boundary download failed: ", e$message)
  })
}

# Read municipal boundaries
if (exists("mun_layer") && length(mun_layer) > 0) {
  municipalities <- st_read(mun_file, layer = mun_layer[1], quiet = TRUE)
} else {
  municipalities <- st_read(mun_file, quiet = TRUE)
}

cat("  Municipal polygons loaded:", nrow(municipalities), "features\n")
cat("  Columns:", paste(names(municipalities), collapse = ", "), "\n")

# Save as geopackage for reuse
st_write(municipalities, file.path(data_dir, "municipalities.gpkg"),
         delete_layer = TRUE, quiet = TRUE)
cat("  Saved to data/municipalities.gpkg\n\n")

# ===========================================================================
# 3. Cantonal Energy Law Reform Dates
# ===========================================================================
cat("=== Encoding cantonal energy law reform dates ===\n")

# Based on pre-computed policy opportunities from rcds/swiss_legislation
# and verified against Fedlex SPARQL
reform_dates <- data.table(
  canton = c("GR", "BE", "AG", "BL", "BS", "LU", "FR", "AI"),
  reform_year = c(2010L, 2011L, 2012L, 2016L, 2016L, 2017L, 2019L, 2020L),
  law_name = c(
    "Energiegesetz GR (EG 820.200)",
    "Energiegesetz BE (EnG 741.1)",
    "Energiegesetz AG (EnergieG 773.200)",
    "Energiegesetz BL (EnergieG 490)",
    "Energiegesetz BS (EnergieG 772.100)",
    "Energiegesetz LU (EnG 773)",
    "Loi sur l'énergie FR (LEn 770.1)",
    "Energiegesetz AI (EnG 750.000)"
  )
)

cat("  Reform cantons:\n")
print(reform_dates[, .(canton, reform_year)])

fwrite(reform_dates, file.path(data_dir, "reform_dates.csv"))
cat("  Saved to data/reform_dates.csv\n\n")

# ===========================================================================
# 4. Canton-to-municipality mapping
# ===========================================================================
cat("=== Creating canton mapping ===\n")

# All 26 Swiss cantons with their abbreviations
all_cantons <- data.table(
  canton_abbr = c("ZH","BE","LU","UR","SZ","OW","NW","GL","ZG","FR",
                  "SO","BS","BL","SH","AR","AI","SG","GR","AG","TG",
                  "TI","VD","VS","NE","GE","JU"),
  canton_id = 1:26
)

fwrite(all_cantons, file.path(data_dir, "cantons.csv"))
cat("  Saved 26 cantons to data/cantons.csv\n\n")

# ===========================================================================
# 5. DATA VALIDATION
# ===========================================================================
cat("=== DATA VALIDATION ===\n")

stopifnot("Expected 2500+ municipalities" = uniqueN(elcom$mun_id) >= 2500)
stopifnot("Expected 10+ years of tariff data" = uniqueN(elcom$year) >= 10)
stopifnot("Expected >95% tariffs > 0" = mean(elcom$total > 0, na.rm = TRUE) > 0.95)
stopifnot("Expected 8 reform cantons" = nrow(reform_dates) == 8)
stopifnot("Expected municipal polygons" = nrow(municipalities) > 2000)

# Report any zero/negative tariffs
n_zero <- sum(elcom$total <= 0, na.rm = TRUE)
if (n_zero > 0) {
  cat("  WARNING:", n_zero, "observations with total tariff <= 0 (",
      round(n_zero / nrow(elcom) * 100, 2), "%). Dropping from analysis.\n")
  elcom <- elcom[total > 0]
  fwrite(elcom, file.path(data_dir, "elcom_tariffs.csv"))
}

cat("Data validation passed:\n")
cat("  ElCom tariffs:", nrow(elcom), "rows,",
    uniqueN(elcom$mun_id), "municipalities,",
    uniqueN(elcom$year), "years\n")
cat("  Municipal boundaries:", nrow(municipalities), "polygons\n")
cat("  Reform cantons:", nrow(reform_dates), "\n")
cat("\nAll data fetched successfully.\n")
