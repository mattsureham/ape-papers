## 01_fetch_data.R — Download DVF transactions and ZFE boundary
## apep_0680: ZFE Spatial RDD on Property Values

source("code/00_packages.R")

cat("=== Fetching data for apep_0680 ===\n\n")

# ---- 1. DVF bulk geocoded CSVs (Rhône department = 69) ----
dvf_years <- 2020:2024  # geo-dvf bulk CSVs available from 2020
dvf_base_url <- "https://files.data.gouv.fr/geo-dvf/latest/csv"

for (yr in dvf_years) {
  outfile <- sprintf("data/dvf_%d.csv.gz", yr)
  if (file.exists(outfile)) {
    cat(sprintf("DVF %d already downloaded.\n", yr))
    next
  }
  url <- sprintf("%s/%d/departements/69.csv.gz", dvf_base_url, yr)
  cat(sprintf("Downloading DVF %d from %s ...\n", yr, url))
  resp <- tryCatch(
    download.file(url, outfile, mode = "wb", quiet = TRUE),
    error = function(e) {
      stop(sprintf("FATAL: DVF %d download failed: %s", yr, e$message))
    }
  )
  stopifnot(file.exists(outfile) && file.size(outfile) > 1000)
  cat(sprintf("  OK: %s (%s bytes)\n", outfile, format(file.size(outfile), big.mark = ",")))
}

# ---- 2. ZFE boundary GeoJSON ----
zfe_file <- "data/zfe_lyon.geojson"
if (!file.exists(zfe_file)) {
  zfe_url <- "https://download.data.grandlyon.com/files/grandlyon/environnement/zfe/zfe_zone_metropole_de_lyon.geojson"
  cat(sprintf("Downloading ZFE boundary from %s ...\n", zfe_url))
  resp <- tryCatch(
    download.file(zfe_url, zfe_file, mode = "wb", quiet = TRUE),
    error = function(e) {
      # Try alternative URL pattern
      alt_url <- "https://data.grandlyon.com/geoserver/metropole-de-lyon/ows?service=WFS&version=1.1.0&request=GetFeature&typeName=metropole-de-lyon:zfe_zone&outputFormat=application/json"
      cat(sprintf("Primary URL failed, trying WFS: %s\n", alt_url))
      tryCatch(
        download.file(alt_url, zfe_file, mode = "wb", quiet = TRUE),
        error = function(e2) {
          stop(sprintf("FATAL: ZFE boundary download failed: %s / %s", e$message, e2$message))
        }
      )
    }
  )
  stopifnot(file.exists(zfe_file))
  cat(sprintf("  OK: %s (%s bytes)\n", zfe_file, format(file.size(zfe_file), big.mark = ",")))
} else {
  cat("ZFE boundary already downloaded.\n")
}

# ---- 3. Validate downloads ----
cat("\n=== Validation ===\n")

# Check DVF files
for (yr in dvf_years) {
  f <- sprintf("data/dvf_%d.csv.gz", yr)
  stopifnot(file.exists(f))
  # Read a few rows to verify structure
  test <- fread(cmd = sprintf("gzip -dc '%s' | head -5", f), header = TRUE)
  required_cols <- c("date_mutation", "valeur_fonciere", "type_local",
                     "surface_reelle_bati", "longitude", "latitude")
  missing <- setdiff(required_cols, names(test))
  if (length(missing) > 0) {
    stop(sprintf("FATAL: DVF %d missing columns: %s", yr, paste(missing, collapse = ", ")))
  }
  cat(sprintf("DVF %d: columns OK\n", yr))
}

# Check ZFE boundary
zfe <- st_read(zfe_file, quiet = TRUE)
stopifnot(nrow(zfe) > 0)
cat(sprintf("ZFE boundary: %d feature(s), CRS = %s\n", nrow(zfe), st_crs(zfe)$epsg))

cat("\n=== All data fetched and validated ===\n")
