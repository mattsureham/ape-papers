## =============================================================================
## 01_fetch_data.R — Fetch all data sources
## apep_0496: Education Priority Labels and Housing Markets in France
## =============================================================================

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ---------------------------------------------------------------------------
## 1. DVF — Raw yearly files from DGFiP (most reliable source)
##    Source: https://www.data.gouv.fr/datasets/demandes-de-valeurs-foncieres/
##    These are txt.zip files containing pipe-delimited transaction data
## ---------------------------------------------------------------------------

cat("=== Fetching DVF data ===\n")

# Official DGFiP URLs for yearly DVF files
dvf_urls <- list(
  "2020" = "https://www.data.gouv.fr/fr/datasets/r/8d771135-57c8-480f-a853-3d1d00ea0b69",
  "2021" = "https://www.data.gouv.fr/fr/datasets/r/e117fe7d-f7fb-4c52-8089-231e755d19d3",
  "2022" = "https://www.data.gouv.fr/fr/datasets/r/8c8abe23-2a82-4b95-8174-1c1e0734c921",
  "2023" = "https://www.data.gouv.fr/fr/datasets/r/cc8a50e4-c8d1-4ac2-8de2-c1e4b3c44c86",
  "2024" = "https://www.data.gouv.fr/fr/datasets/r/af812b0e-a898-4226-8cc8-5a570b257326"
)

for (yr in names(dvf_urls)) {
  dest_zip <- file.path(data_dir, paste0("dvf_", yr, ".txt.zip"))
  dest_txt <- file.path(data_dir, paste0("dvf_", yr, ".txt"))

  if (file.exists(dest_txt)) {
    cat("DVF", yr, "already extracted.\n")
    next
  }

  if (!file.exists(dest_zip)) {
    cat("Downloading DVF", yr, "...\n")
    tryCatch({
      download.file(dvf_urls[[yr]], dest_zip, mode = "wb", quiet = FALSE)
      cat("  Downloaded:", round(file.size(dest_zip) / 1e6, 1), "MB\n")
    }, error = function(e) {
      stop("DVF data for ", yr, " unavailable: ", e$message,
           "\nPivot research question or fix the source.")
    })
  }

  # Extract
  cat("Extracting DVF", yr, "...\n")
  unzip(dest_zip, exdir = data_dir)
  # Find the extracted txt file (name varies)
  extracted <- list.files(data_dir, pattern = paste0(".*", yr, ".*\\.txt$"),
                          full.names = TRUE)
  if (length(extracted) > 0 && extracted[1] != dest_txt) {
    file.rename(extracted[1], dest_txt)
  }
  cat("  Extracted:", round(file.size(dest_txt) / 1e6, 1), "MB\n")
}

## ---------------------------------------------------------------------------
## 1b. DVF géolocalisé (consolidated geocoded version)
##     Source: https://www.data.gouv.fr/datasets/demandes-de-valeurs-foncieres-geolocalisees
##     Single compressed CSV with all years and coordinates
## ---------------------------------------------------------------------------

cat("\n=== Fetching DVF géolocalisé (consolidated) ===\n")

dvf_geo_dest <- file.path(data_dir, "dvf_geolocalisee.csv.gz")

if (!file.exists(dvf_geo_dest)) {
  # Try the consolidated geocoded CSV (494 MB compressed)
  geo_url <- "https://www.data.gouv.fr/fr/datasets/r/d7933994-2c66-4131-a4da-cf7cd18040a4"
  cat("Downloading DVF géolocalisé (may take several minutes)...\n")
  tryCatch({
    download.file(geo_url, dvf_geo_dest, mode = "wb", quiet = FALSE)
    cat("  Downloaded:", round(file.size(dvf_geo_dest) / 1e6, 1), "MB\n")
  }, error = function(e) {
    cat("  Geocoded version unavailable, will geocode from raw DVF.\n")
    cat("  Error:", e$message, "\n")
  })
} else {
  cat("DVF géolocalisé already downloaded:",
      round(file.size(dvf_geo_dest) / 1e6, 1), "MB\n")
}

## ---------------------------------------------------------------------------
## 2. Carte scolaire — collège catchment boundaries
##    Source: data.education.gouv.fr
## ---------------------------------------------------------------------------

cat("\n=== Fetching carte scolaire data ===\n")

carte_dest <- file.path(data_dir, "carte_scolaire_colleges.geojson")
if (!file.exists(carte_dest)) {
  # Export from data.education.gouv.fr API
  carte_url <- "https://data.education.gouv.fr/api/explore/v2.1/catalog/datasets/fr-en-carte-scolaire-colleges-publics/exports/geojson"
  cat("Downloading carte scolaire from data.education.gouv.fr...\n")
  tryCatch({
    download.file(carte_url, carte_dest, mode = "wb", quiet = FALSE)
    cat("  Downloaded:", round(file.size(carte_dest) / 1e6, 1), "MB\n")
  }, error = function(e) {
    # Try data.gouv.fr as fallback
    alt_url <- "https://www.data.gouv.fr/fr/datasets/r/0de7e25d-7cb0-4750-8925-28c3db3a6759"
    cat("  Trying data.gouv.fr fallback...\n")
    tryCatch({
      download.file(alt_url, carte_dest, mode = "wb", quiet = FALSE)
      cat("  Downloaded:", round(file.size(carte_dest) / 1e6, 1), "MB\n")
    }, error = function(e2) {
      stop("Carte scolaire data unavailable from both sources: ", e2$message,
           "\nPivot research question or fix the source.")
    })
  })
} else {
  cat("Carte scolaire already downloaded.\n")
}

## ---------------------------------------------------------------------------
## 3. REP/REP+ school lists
##    Source: data.education.gouv.fr
## ---------------------------------------------------------------------------

cat("\n=== Fetching REP/REP+ school lists ===\n")

# All education priority establishments
rep_etab_dest <- file.path(data_dir, "rep_etablissements.csv")
if (!file.exists(rep_etab_dest)) {
  rep_url <- "https://data.education.gouv.fr/api/explore/v2.1/catalog/datasets/fr-en-etablissements-ep/exports/csv?delimiter=%3B&list_separator=%2C&quote_all=false&with_bom=true"
  cat("Downloading REP establishments...\n")
  tryCatch({
    download.file(rep_url, rep_etab_dest, mode = "wb", quiet = FALSE)
    cat("  Downloaded:", round(file.size(rep_etab_dest) / 1e6, 1), "MB\n")
  }, error = function(e) {
    stop("REP data unavailable: ", e$message,
         "\nPivot research question or fix the source.")
  })
} else {
  cat("REP establishments already downloaded.\n")
}

# Elementary schools in priority education
rep_ecoles_dest <- file.path(data_dir, "rep_ecoles.csv")
if (!file.exists(rep_ecoles_dest)) {
  rep_ecoles_url <- "https://data.education.gouv.fr/api/explore/v2.1/catalog/datasets/fr-en-ecoles-ep/exports/csv?delimiter=%3B&list_separator=%2C&quote_all=false&with_bom=true"
  cat("Downloading REP elementary schools...\n")
  tryCatch({
    download.file(rep_ecoles_url, rep_ecoles_dest, mode = "wb", quiet = FALSE)
    cat("  Downloaded:", round(file.size(rep_ecoles_dest) / 1e6, 1), "MB\n")
  }, error = function(e) {
    stop("REP ecoles data unavailable: ", e$message,
         "\nPivot research question or fix the source.")
  })
} else {
  cat("REP ecoles already downloaded.\n")
}

## ---------------------------------------------------------------------------
## 4. Brevet results by collège
##    Source: data.education.gouv.fr
## ---------------------------------------------------------------------------

cat("\n=== Fetching brevet results ===\n")

brevet_dest <- file.path(data_dir, "brevet_par_etablissement.csv")
if (!file.exists(brevet_dest)) {
  brevet_url <- "https://data.education.gouv.fr/api/explore/v2.1/catalog/datasets/fr-en-dnb-par-etablissement/exports/csv?delimiter=%3B&list_separator=%2C&quote_all=false&with_bom=true"
  cat("Downloading brevet results...\n")
  tryCatch({
    download.file(brevet_url, brevet_dest, mode = "wb", quiet = FALSE)
    cat("  Downloaded:", round(file.size(brevet_dest) / 1e6, 1), "MB\n")
  }, error = function(e) {
    warning("Brevet data unavailable (not fatal). Proceeding without it.")
  })
} else {
  cat("Brevet results already downloaded.\n")
}

## ---------------------------------------------------------------------------
## 5. School directory (annuaire) — includes private schools
##    Source: data.education.gouv.fr
## ---------------------------------------------------------------------------

cat("\n=== Fetching school directory ===\n")

annuaire_dest <- file.path(data_dir, "annuaire_education.csv")
if (!file.exists(annuaire_dest)) {
  annuaire_url <- "https://data.education.gouv.fr/api/explore/v2.1/catalog/datasets/fr-en-annuaire-education/exports/csv?delimiter=%3B&list_separator=%2C&quote_all=false&with_bom=true"
  cat("Downloading school directory...\n")
  tryCatch({
    download.file(annuaire_url, annuaire_dest, mode = "wb", quiet = FALSE)
    cat("  Downloaded:", round(file.size(annuaire_dest) / 1e6, 1), "MB\n")
  }, error = function(e) {
    stop("School directory unavailable: ", e$message,
         "\nPivot research question or fix the source.")
  })
} else {
  cat("School directory already downloaded.\n")
}

## ---------------------------------------------------------------------------
## DATA VALIDATION
## ---------------------------------------------------------------------------

cat("\n=== Data Validation ===\n")

# Check that we have EITHER geocoded DVF OR raw yearly DVF files
dvf_geo_ok <- file.exists(dvf_geo_dest) && file.size(dvf_geo_dest) > 1e6
dvf_raw_files <- list.files(data_dir, pattern = "^dvf_20[12][0-9]\\.txt$",
                            full.names = TRUE)
dvf_raw_ok <- length(dvf_raw_files) >= 3

stopifnot("Need DVF data (geocoded or raw yearly)" = dvf_geo_ok || dvf_raw_ok)
if (dvf_geo_ok) {
  cat("DVF géolocalisé:", round(file.size(dvf_geo_dest) / 1e6, 1), "MB\n")
}
if (dvf_raw_ok) {
  cat("DVF raw yearly files:", length(dvf_raw_files), "files\n")
}

# Check carte scolaire
stopifnot("Carte scolaire must exist" = file.exists(carte_dest) &&
            file.size(carte_dest) > 1000)
cat("Carte scolaire:", round(file.size(carte_dest) / 1e6, 1), "MB\n")

# Check REP lists
stopifnot("REP establishments must exist" = file.exists(rep_etab_dest))
cat("REP establishments:", round(file.size(rep_etab_dest) / 1e6, 1), "MB\n")

# Check annuaire
stopifnot("School directory must exist" = file.exists(annuaire_dest))
cat("School directory:", round(file.size(annuaire_dest) / 1e6, 1), "MB\n")

cat("\nData validation passed. All required files present.\n")
