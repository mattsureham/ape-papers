## 01_fetch_data.R — Download DVF, college sector boundaries, and REP list
## APEP-0746

source("00_packages.R")

data_dir <- "../data"

## ===================================================================
## 1. DVF Geolocalized (property transactions with lat/lon)
## Source: data.gouv.fr — full France, all years
## ===================================================================

dvf_file <- file.path(data_dir, "dvf_geo.csv.gz")

if (!file.exists(dvf_file)) {
  cat("Downloading DVF geolocalized data...\n")
  # DVF geolocalized is available as yearly CSVs from data.gouv.fr
  # We use the aggregated version from Etalab
  dvf_url <- "https://files.data.gouv.fr/geo-dvf/latest/csv/2024/full.csv.gz"

  # Download multiple years and combine (geo-dvf starts at 2020)
  years <- 2020:2024
  dvf_all <- list()

  for (yr in years) {
    url <- paste0("https://files.data.gouv.fr/geo-dvf/latest/csv/", yr, "/full.csv.gz")
    tmp <- tempfile(fileext = ".csv.gz")
    cat(sprintf("  Downloading DVF %d...\n", yr))
    dl_result <- tryCatch(
      download.file(url, tmp, mode = "wb", quiet = TRUE),
      error = function(e) {
        cat(sprintf("  ERROR downloading DVF %d: %s\n", yr, e$message))
        stop(sprintf("Failed to download DVF data for year %d. Cannot proceed without real data.", yr))
      }
    )
    if (dl_result != 0) stop(sprintf("Download failed for DVF %d (non-zero exit).", yr))

    cat(sprintf("  Reading DVF %d...\n", yr))
    dt <- fread(tmp, select = c(
      "id_mutation", "date_mutation", "nature_mutation",
      "valeur_fonciere", "code_commune", "nom_commune",
      "code_departement", "type_local", "surface_reelle_bati",
      "nombre_pieces_principales", "latitude", "longitude"
    ), encoding = "UTF-8")

    dt[, year := yr]
    dvf_all[[as.character(yr)]] <- dt
    unlink(tmp)
  }

  dvf <- rbindlist(dvf_all, fill = TRUE)
  cat(sprintf("DVF raw: %d rows across %d years\n", nrow(dvf), length(years)))

  # Basic cleaning: keep only sales (Vente), non-missing price/coords
  dvf <- dvf[nature_mutation == "Vente" &
             !is.na(valeur_fonciere) & valeur_fonciere > 0 &
             !is.na(latitude) & !is.na(longitude)]

  # Keep residential: Maison or Appartement
  dvf <- dvf[type_local %in% c("Maison", "Appartement")]

  # Remove extreme prices (< 10K or > 5M EUR)
  dvf <- dvf[valeur_fonciere >= 10000 & valeur_fonciere <= 5000000]

  cat(sprintf("DVF after cleaning: %d residential sales\n", nrow(dvf)))

  fwrite(dvf, dvf_file)
  cat("DVF saved to", dvf_file, "\n")
} else {
  cat("DVF already downloaded, reading...\n")
  dvf <- fread(dvf_file)
  cat(sprintf("DVF: %d rows\n", nrow(dvf)))
}

## ===================================================================
## 2. College Sector GeoJSON (catchment areas)
## Source: data.gouv.fr
## ===================================================================

sectors_file <- file.path(data_dir, "college_sectors.geojson")

if (!file.exists(sectors_file)) {
  cat("Downloading college sector boundaries...\n")
  # The carte scolaire data is available on data.education.gouv.fr
  # Try the data.gouv.fr dataset first
  # GeoJSON polygons from data.gouv.fr "Carte scolaire géolocalisée des collèges publics"
  sector_url <- "https://static.data.gouv.fr/resources/carte-scolaire-geolocalisee-des-colleges-publics/20230222-145200/secteurs.geojson"

  dl_result <- tryCatch(
    download.file(sector_url, sectors_file, mode = "wb", quiet = TRUE),
    error = function(e) {
      cat("ERROR downloading college sectors:", e$message, "\n")
      stop("Failed to download college sector boundaries. Cannot proceed.")
    }
  )
  if (dl_result != 0) stop("Download of college sectors failed.")
  cat("College sectors downloaded.\n")
} else {
  cat("College sectors already downloaded.\n")
}

# Read the GeoJSON
cat("Reading college sector GeoJSON (this may take a moment)...\n")
sectors <- tryCatch(
  st_read(sectors_file, quiet = TRUE),
  error = function(e) {
    cat("ERROR reading GeoJSON:", e$message, "\n")
    stop("Failed to read college sector GeoJSON. Cannot proceed.")
  }
)
cat(sprintf("College sectors: %d polygons\n", nrow(sectors)))

# Print column names for inspection
cat("Sector columns:", paste(names(sectors), collapse = ", "), "\n")

## ===================================================================
## 3. REP/REP+ College List
## Source: data.education.gouv.fr
## ===================================================================

rep_file <- file.path(data_dir, "rep_colleges.csv")

if (!file.exists(rep_file)) {
  cat("Downloading REP/REP+ list...\n")
  # REP list from data.education.gouv.fr
  # Use the correct dataset: fr-en-colleges-ep (collèges in priority education)
  rep_url <- "https://data.education.gouv.fr/api/explore/v2.1/catalog/datasets/fr-en-colleges-ep/exports/csv?lang=fr&timezone=Europe%2FBerlin&use_labels=true&delimiter=%3B"

  dl_result <- tryCatch(
    download.file(rep_url, rep_file, mode = "wb", quiet = TRUE),
    error = function(e) {
      cat("ERROR downloading REP list:", e$message, "\n")
      stop("Failed to download REP college list. Cannot proceed.")
    }
  )
  if (dl_result != 0) stop("Download of REP list failed.")
  cat("REP list downloaded.\n")
} else {
  cat("REP list already downloaded.\n")
}

rep_list <- fread(rep_file, sep = ";", encoding = "UTF-8")
cat(sprintf("REP list: %d establishments\n", nrow(rep_list)))
cat("REP columns:", paste(names(rep_list), collapse = ", "), "\n")

# Show REP/REP+ breakdown
if ("denomination_ep" %in% names(rep_list)) {
  cat("REP breakdown:\n")
  print(table(rep_list$denomination_ep))
} else if ("type_ep" %in% names(rep_list)) {
  cat("REP breakdown:\n")
  print(table(rep_list$type_ep))
} else {
  cat("Column names for REP type identification:\n")
  print(head(rep_list, 3))
}

cat("\n=== Data fetch complete ===\n")
cat(sprintf("DVF transactions: %d\n", nrow(dvf)))
cat(sprintf("College sectors: %d\n", nrow(sectors)))
cat(sprintf("REP establishments: %d\n", nrow(rep_list)))
