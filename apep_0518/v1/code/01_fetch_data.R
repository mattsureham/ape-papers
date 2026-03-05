## =============================================================================
## 01_fetch_data.R — Download shapefiles, SIRENE, and supplementary data
## =============================================================================

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ---- 1. QPV Shapefiles (2015 vintage) ----
cat("=== 1. QPV Shapefiles (2015 vintage) ===\n")
qpv_zip <- file.path(data_dir, "qpv_2015_shp.zip")
qpv_dir <- file.path(data_dir, "qpv_2015_shp")

if (!file.exists(qpv_zip)) {
  download.file(
    "https://static.data.gouv.fr/resources/quartiers-prioritaires-de-la-politique-de-la-ville-qpv/20180110-144945/qp-politiquedelaville-shp.zip",
    qpv_zip, mode = "wb", quiet = FALSE
  )
  stopifnot("QPV zip too small" = file.size(qpv_zip) > 100000)
}

if (!dir.exists(qpv_dir)) {
  dir.create(qpv_dir, recursive = TRUE)
  unzip(qpv_zip, exdir = qpv_dir)
}

# CRITICAL: Load the correct metro shapefile (Lambert-93, 1296 polygons)
qpv_shp <- file.path(qpv_dir, "QP_METROPOLE_LB93.shp")
stopifnot("QP_METROPOLE_LB93.shp not found" = file.exists(qpv_shp))
qpv_sf <- st_read(qpv_shp, quiet = TRUE)
# Already in Lambert-93 (EPSG:2154) but ensure
qpv_sf <- st_transform(qpv_sf, 2154)
cat("QPV 2015 loaded:", nrow(qpv_sf), "metro polygons\n")
stopifnot("Expected 1000+ QPV polygons" = nrow(qpv_sf) >= 1000)

## ---- 2. ZFU Shapefiles ----
cat("\n=== 2. ZFU Shapefiles ===\n")
zfu_zip <- file.path(data_dir, "zfu_shp.zip")
zfu_dir <- file.path(data_dir, "zfu_shp")

if (!file.exists(zfu_zip)) {
  download.file(
    "https://static.data.gouv.fr/resources/zones-franches-urbaines-zfu/20180117-110644/zfu.zip",
    zfu_zip, mode = "wb", quiet = FALSE
  )
  stopifnot("ZFU zip too small" = file.size(zfu_zip) > 10000)
}

if (!dir.exists(zfu_dir)) {
  dir.create(zfu_dir, recursive = TRUE)
  unzip(zfu_zip, exdir = zfu_dir)
}

# CRITICAL: Load the correct metro shapefile (Lambert-93, 93 polygons)
zfu_shp <- file.path(zfu_dir, "ZFU_FRM_Scan25_L93.shp")
stopifnot("ZFU_FRM_Scan25_L93.shp not found" = file.exists(zfu_shp))
zfu_sf <- st_read(zfu_shp, quiet = TRUE)
zfu_sf <- st_transform(zfu_sf, 2154)
cat("ZFU loaded:", nrow(zfu_sf), "metro polygons\n")
stopifnot("Expected 80+ ZFU polygons" = nrow(zfu_sf) >= 80)

## ---- 3. ZUS List (commune-level, from SIG ville XLS) ----
cat("\n=== 3. ZUS List ===\n")
zus_xls <- file.path(data_dir, "zus_list.xls")

if (!file.exists(zus_xls)) {
  download.file(
    "https://sig.ville.gouv.fr/uploads/doc/ZUS_FR_SGCIV_20100701.xls",
    zus_xls, mode = "wb", quiet = FALSE
  )
  stopifnot("ZUS XLS too small" = file.size(zus_xls) > 10000)
}

# Parse ZUS list (skip 9 header rows)
if (!requireNamespace("readxl", quietly = TRUE)) {
  install.packages("readxl", repos = "https://cloud.r-project.org")
}
zus_raw <- readxl::read_excel(zus_xls, sheet = 1, skip = 9,
  col_names = c("region", "dept", "communes", "code_zus", "quartier", "type", "type2"))

# Remove header row that got included
zus_raw <- zus_raw[zus_raw$type == "ZUS", ]
cat("ZUS list loaded:", nrow(zus_raw), "neighborhoods\n")
stopifnot("Expected 700+ ZUS" = nrow(zus_raw) >= 700)

## ---- 4. INSEE COG (commune reference) ----
cat("\n=== 4. INSEE COG (commune reference) ===\n")
cog_file <- file.path(data_dir, "cog_2024.csv")

if (!file.exists(cog_file)) {
  download.file(
    "https://www.insee.fr/fr/statistiques/fichier/7766585/v_commune_2024.csv",
    cog_file, mode = "wb", quiet = FALSE
  )
}

cog <- fread(cog_file, encoding = "UTF-8")
cog <- cog[TYPECOM == "COM"]
cat("COG communes:", nrow(cog), "\n")

## ---- 5. SIRENE Establishment Data ----
cat("\n=== 5. SIRENE Establishment Data ===\n")
sirene_file <- file.path(data_dir, "sirene_etablissements.parquet")

if (!file.exists(sirene_file) || file.size(sirene_file) < 1e9) {
  cat("SIRENE parquet missing or incomplete. Downloading (~2GB)...\n")
  cat("Using system curl for reliable large-file download.\n")
  if (file.exists(sirene_file)) file.remove(sirene_file)

  sirene_url <- "https://object.files.data.gouv.fr/data-pipeline-open/siren/stock/StockEtablissement_utf8.parquet"
  exit_code <- system2("curl", args = c(
    "-L", "--connect-timeout", "30", "--max-time", "900",
    "-o", sirene_file,
    sirene_url
  ))

  if (exit_code != 0 || !file.exists(sirene_file)) {
    stop("SIRENE download failed. Exit code: ", exit_code)
  }
  cat("SIRENE downloaded:", round(file.size(sirene_file) / 1e9, 2), "GB\n")
}

# Validate SIRENE
cat("Validating SIRENE parquet...\n")
sirene_schema <- arrow::read_parquet(sirene_file, as_data_frame = FALSE)
sirene_nrow <- nrow(sirene_schema)
cat("SIRENE rows:", format(sirene_nrow, big.mark = ","), "\n")
stopifnot("SIRENE must have >1M rows" = sirene_nrow > 1000000)

## ---- 6. Save spatial objects ----
cat("\n=== 6. Saving spatial objects ===\n")
st_write(qpv_sf, file.path(data_dir, "qpv.gpkg"), quiet = TRUE, delete_dsn = TRUE)
st_write(zfu_sf, file.path(data_dir, "zfu.gpkg"), quiet = TRUE, delete_dsn = TRUE)

## ---- 7. Final Validation ----
cat("\n=== DATA VALIDATION ===\n")
stopifnot("QPV polygons" = nrow(qpv_sf) >= 1000)
stopifnot("ZFU polygons" = nrow(zfu_sf) >= 80)
stopifnot("ZUS list" = nrow(zus_raw) >= 700)
stopifnot("SIRENE exists" = file.exists(sirene_file) && file.size(sirene_file) > 1e9)
stopifnot("COG exists" = nrow(cog) > 30000)

cat("Data validation passed.\n")
cat("  QPV polygons:", nrow(qpv_sf), "\n")
cat("  ZFU polygons:", nrow(zfu_sf), "\n")
cat("  ZUS neighborhoods:", nrow(zus_raw), "\n")
cat("  SIRENE:", format(sirene_nrow, big.mark = ","), "rows\n")
cat("  COG communes:", nrow(cog), "\n")
