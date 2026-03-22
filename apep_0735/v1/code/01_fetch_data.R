# 01_fetch_data.R — Fetch DVF and Monuments data
# apep_0735: ABF Monument Boundary Spatial RDD

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. Fetch Monuments Historiques data
# ============================================================
cat("Fetching Monuments Historiques data...\n")

# The Monuments Historiques API: POP/Merimee database
# We need monument coordinates. Use the open data export.
monuments_file <- file.path(data_dir, "monuments.csv")

if (!file.exists(monuments_file)) {
  # Use bulk CSV export (API pagination caps at offset 10000)
  export_url <- paste0(
    "https://data.culture.gouv.fr/api/explore/v2.1/catalog/datasets/",
    "liste-des-immeubles-proteges-au-titre-des-monuments-historiques/",
    "exports/csv?limit=-1&delimiter=%3B&select=",
    "titre_editorial_de_la_notice,coordonnees_au_format_wgs84,",
    "commune_forme_index,departement_en_lettres,departement_format_numerique,",
    "precision_de_la_protection"
  )

  export_file <- file.path(data_dir, "monuments_export.csv")
  cat("  Downloading full CSV export...\n")
  download.file(export_url, export_file, mode = "wb", quiet = FALSE, timeout = 300)

  monuments_df <- fread(export_file, sep = ";", encoding = "UTF-8")
  cat("  Raw export rows:", nrow(monuments_df), "\n")

  # Parse coordinates from the WGS84 column (format: "lat, lon" or structured)
  coord_col <- names(monuments_df)[grepl("coordonnees", names(monuments_df), ignore.case = TRUE)]
  cat("  Coordinate column:", coord_col, "\n")

  if (length(coord_col) > 0) {
    coords_raw <- monuments_df[[coord_col[1]]]
    # Format is typically "lat, lon"
    parsed <- strsplit(as.character(coords_raw), ",\\s*")
    monuments_df[, lat := as.numeric(sapply(parsed, function(x) if (length(x) >= 2) x[1] else NA))]
    monuments_df[, lon := as.numeric(sapply(parsed, function(x) if (length(x) >= 2) x[2] else NA))]
  }

  # Standardize column names
  setnames(monuments_df,
    old = c("titre_editorial_de_la_notice", "commune_forme_index",
            "departement_en_lettres", "precision_de_la_protection",
            "departement_format_numerique"),
    new = c("titre", "commune", "departement", "protection", "dept_code"),
    skip_absent = TRUE
  )

  fwrite(monuments_df, monuments_file)
  cat("Saved", nrow(monuments_df), "monuments to", monuments_file, "\n")
} else {
  monuments_df <- fread(monuments_file)
  cat("Loaded", nrow(monuments_df), "monuments from cache.\n")
}

# Validate: must have coordinates
monuments_geo <- monuments_df[!is.na(lat) & !is.na(lon) & lat != 0 & lon != 0]
cat("Monuments with valid coordinates:", nrow(monuments_geo), "\n")
stopifnot("Too few geocoded monuments" = nrow(monuments_geo) > 30000)

# Classify monument type
monuments_geo[, type := fifelse(
  grepl("class", protection, ignore.case = TRUE), "classe", "inscrit"
)]
fwrite(monuments_geo, file.path(data_dir, "monuments_geo.csv"))

# ============================================================
# 2. Fetch DVF data (property transactions)
# ============================================================
cat("\nFetching DVF data...\n")

dvf_file <- file.path(data_dir, "dvf_combined.csv")

if (!file.exists(dvf_file)) {
  # DVF data is available as annual CSV files on data.gouv.fr
  # We'll fetch 2020-2024 (5 years)
  years <- 2020:2024
  all_dvf <- list()

  for (yr in years) {
    cat("  Downloading DVF", yr, "...\n")
    url <- paste0("https://files.data.gouv.fr/geo-dvf/latest/csv/", yr, "/full.csv.gz")

    dest_gz <- file.path(data_dir, paste0("dvf_", yr, ".csv.gz"))
    dest_csv <- file.path(data_dir, paste0("dvf_", yr, ".csv"))

    if (!file.exists(dest_csv)) {
      tryCatch({
        download.file(url, dest_gz, mode = "wb", quiet = TRUE, timeout = 300)
        # Decompress
        system2("gunzip", args = c("-f", dest_gz))
        cat("  Downloaded and decompressed DVF", yr, "\n")
      }, error = function(e) {
        stop("Failed to download DVF ", yr, ": ", e$message)
      })
    }

    # Read with data.table for speed - select only needed columns
    dvf_yr <- fread(
      dest_csv,
      select = c("date_mutation", "nature_mutation", "valeur_fonciere",
                  "code_commune", "nom_commune", "code_departement",
                  "type_local", "surface_reelle_bati", "nombre_pieces_principales",
                  "latitude", "longitude"),
      showProgress = FALSE
    )

    dvf_yr[, year := yr]
    all_dvf[[as.character(yr)]] <- dvf_yr
    cat("  DVF", yr, ":", nrow(dvf_yr), "rows\n")
  }

  dvf <- rbindlist(all_dvf, fill = TRUE)
  fwrite(dvf, dvf_file)
  cat("Combined DVF:", nrow(dvf), "rows\n")
} else {
  dvf <- fread(dvf_file)
  cat("Loaded DVF from cache:", nrow(dvf), "rows\n")
}

# Validate DVF
stopifnot("DVF has zero rows" = nrow(dvf) > 0)
cat("DVF columns:", paste(names(dvf), collapse = ", "), "\n")
cat("DVF years:", paste(sort(unique(dvf$year)), collapse = ", "), "\n")
cat("Rows with valid lat/lon:", sum(!is.na(dvf$latitude) & !is.na(dvf$longitude)), "\n")

cat("\nData fetch complete.\n")
