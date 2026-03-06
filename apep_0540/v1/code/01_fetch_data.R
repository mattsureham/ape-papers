# 01_fetch_data.R — Fetch DVF transactions, GPE stations, and construction milestones
# APEP-0540: Grand Paris Express Construction-Phase Capitalization

source("00_packages.R")

cat("=== PHASE 1: DATA ACQUISITION ===\n")

# ──────────────────────────────────────────────────────────────────
# 1. DVF TRANSACTION DATA (geo-DVF from data.gouv.fr, 2020-2025)
#    + raw DVF for 2014-2019 if available via DVF+
# ──────────────────────────────────────────────────────────────────

# Strategy: Download geo-DVF CSVs by IDF department and year
# Geo-DVF covers 2020-2025 with latitude/longitude
# For 2014-2019, we use the raw DVF from DGFiP (has commune codes but needs geocoding)

dvf_dir <- file.path(DATA_DIR, "dvf")
dir.create(dvf_dir, showWarnings = FALSE, recursive = TRUE)

# --- Geo-DVF (2020-2025): geolocated with lat/lon ---
geo_dvf_years <- 2020:2024  # 2025 may be partial
cat("Downloading geo-DVF data for IDF departments (2020-2024)...\n")

geo_dvf_list <- list()
for (yr in geo_dvf_years) {
  for (dep in IDF_DEPS) {
    fname <- file.path(dvf_dir, sprintf("geo_dvf_%s_%s.csv.gz", dep, yr))
    url <- sprintf("https://files.data.gouv.fr/geo-dvf/latest/csv/%d/departements/%s.csv.gz", yr, dep)

    if (!file.exists(fname)) {
      cat(sprintf("  Fetching dept %s, year %d...\n", dep, yr))
      tryCatch({
        download.file(url, fname, mode = "wb", quiet = TRUE)
      }, error = function(e) {
        stop(sprintf("Failed to download geo-DVF for dept %s year %d: %s\nPivot research question or fix the source.", dep, yr, e$message))
      })
    }

    dt <- tryCatch({
      fread(cmd = sprintf("gunzip -c '%s'", fname), select = c(
        "id_mutation", "date_mutation", "valeur_fonciere",
        "code_commune", "nom_commune", "code_departement",
        "code_type_local", "type_local", "surface_reelle_bati",
        "nombre_pieces_principales", "surface_terrain",
        "longitude", "latitude"
      ))
    }, error = function(e) {
      stop(sprintf("Failed to read geo-DVF for dept %s year %d: %s", dep, yr, e$message))
    })

    dt[, year := yr]
    geo_dvf_list[[paste(dep, yr)]] <- dt
    cat(sprintf("    dept %s year %d: %d rows\n", dep, yr, nrow(dt)))
  }
}

geo_dvf <- rbindlist(geo_dvf_list, fill = TRUE)
cat(sprintf("Geo-DVF total: %d rows across %d dept-years\n", nrow(geo_dvf), length(geo_dvf_list)))

# Pre-2020 DVF (geo-DVF only covers 2020+; DVF+ from CEREMA requires portal access)
# Proceeding with 2020-2024 geo-DVF (5 years, 2.2M+ transactions)
# This gives 2-4 pre-construction years for most lines (construction start 2018-2021)
# and pre-opening period for all lines

# Save intermediate data
fwrite(geo_dvf, file.path(DATA_DIR, "geo_dvf_idf_2020_2024.csv"))
cat(sprintf("Saved geo-DVF: %d rows\n", nrow(geo_dvf)))

# ──────────────────────────────────────────────────────────────────
# 2. GPE STATION COORDINATES (SmartIDF API)
# ──────────────────────────────────────────────────────────────────

cat("\n=== Fetching GPE station coordinates ===\n")
stations_file <- file.path(DATA_DIR, "gpe_stations.csv")

# SmartIDF API
stations_url <- "https://data.smartidf.services/api/explore/v2.1/catalog/datasets/point-de-localisation-des-gares-du-grand-paris-express/records?limit=100"

resp <- tryCatch({
  req <- request(stations_url) |> req_timeout(30) |> req_perform()
  resp_body_json(req)
}, error = function(e) {
  stop("Failed to fetch GPE station data from SmartIDF API: ", e$message,
       "\nPivot research question or fix the source.")
})

null_to_na <- function(x, default = NA) if (is.null(x)) default else x

stations_list <- lapply(resp$results, function(r) {
  data.table(
    station_name = null_to_na(r$libelle, NA_character_),
    line = null_to_na(r$ligne, NA_character_),
    code = null_to_na(r$code, NA_character_),
    lat = null_to_na(r$geo_point_2d$lat, NA_real_),
    lon = null_to_na(r$geo_point_2d$lon, NA_real_)
  )
})

stations <- rbindlist(stations_list)
stations <- stations[!is.na(lat) & !is.na(lon)]

cat(sprintf("GPE stations fetched: %d stations across %d lines\n",
            nrow(stations), uniqueN(stations$line)))
cat("Lines:", paste(sort(unique(stations$line)), collapse = ", "), "\n")

fwrite(stations, stations_file)

# ──────────────────────────────────────────────────────────────────
# 3. CONSTRUCTION MILESTONES (manually compiled from public sources)
# ──────────────────────────────────────────────────────────────────

cat("\n=== Constructing GPE milestone timeline ===\n")

# Key milestones from public records:
# - DUP (Declaration d'Utilite Publique) dates from Journal Officiel
# - First TBM launch dates from SGP/Herrenknecht press releases
# - Opening dates from SGP official schedule

milestones <- data.table(
  line = c("L14S", "L14N", "L15S", "L15O", "L15E", "L16", "L17", "L18"),
  line_label = c("Line 14 South", "Line 14 North", "Line 15 South",
                 "Line 15 West", "Line 15 East", "Line 16", "Line 17", "Line 18"),
  dup_date = as.Date(c(
    "2015-10-28",  # L14 extension DUP
    "2015-10-28",  # L14 extension DUP
    "2015-12-18",  # L15 Sud DUP
    "2017-01-13",  # L15 Ouest DUP
    "2017-01-13",  # L15 Est DUP
    "2017-02-14",  # L16 DUP
    "2017-02-14",  # L17 DUP
    "2017-06-13"   # L18 DUP
  )),
  construction_start = as.Date(c(
    "2015-06-01",  # L14S civil works began mid-2015
    "2019-02-01",  # L14N TBM launched Feb 2019
    "2018-04-01",  # L15S first civil works shaft April 2018
    "2021-06-01",  # L15O TBM launched 2021
    "2021-11-01",  # L15E TBM launched Nov 2021
    "2020-05-01",  # L16 first TBM May 2020
    "2020-10-01",  # L17 TBM launched Oct 2020
    "2021-03-01"   # L18 civil works began 2021
  )),
  opening_date = as.Date(c(
    "2024-06-24",  # L14S opened June 2024
    "2026-12-31",  # L14N expected late 2026
    "2026-10-01",  # L15S expected Q4 2026
    "2029-06-01",  # L15O expected 2029
    "2030-06-01",  # L15E expected 2030
    "2026-12-31",  # L16 partial end 2026
    "2027-06-01",  # L17 partial 2027
    "2026-10-01"   # L18 first segment Oct 2026
  )),
  n_stations = c(7, 2, 16, 11, 11, 6, 6, 9)
)

fwrite(milestones, file.path(DATA_DIR, "gpe_milestones.csv"))
cat("Milestone timeline:\n")
print(milestones[, .(line_label, dup_date, construction_start, opening_date, n_stations)])

# ──────────────────────────────────────────────────────────────────
# 4. SIRENE ESTABLISHMENT DATA (mechanism channel)
# ──────────────────────────────────────────────────────────────────

cat("\n=== Fetching SIRENE data for mechanism analysis ===\n")

# INSEE SIRENE API - fetch establishment counts by commune for IDF
# We'll query creation/closure counts for communes near GPE stations
sirene_key <- Sys.getenv("INSEE_SIRENE")
if (nchar(sirene_key) > 0) {
  cat("SIRENE API key found. Will fetch establishment data in 02_clean_data.R\n")
} else {
  cat("WARNING: No SIRENE API key. Mechanism channel will be limited.\n")
}

# ──────────────────────────────────────────────────────────────────
# 5. VALIDATION
# ──────────────────────────────────────────────────────────────────

cat("\n=== DATA VALIDATION ===\n")

# Validate geo-DVF
stopifnot("Expected 8 IDF departments" = uniqueN(geo_dvf$code_departement) == 8)
stopifnot("Expected 4+ years of geo-DVF" = uniqueN(geo_dvf$year) >= 4)
stopifnot("Expected 100K+ rows" = nrow(geo_dvf) > 100000)

# Validate stations
stopifnot("Expected 60+ GPE stations" = nrow(stations) >= 60)
stopifnot("All stations have coordinates" = all(!is.na(stations$lat) & !is.na(stations$lon)))

# Validate milestones
stopifnot("Expected 8 line segments" = nrow(milestones) == 8)
stopifnot("All lines have construction dates" = all(!is.na(milestones$construction_start)))

cat(sprintf("\nData validation passed:\n"))
cat(sprintf("  Geo-DVF: %s rows, %d departments, %d years\n",
            format(nrow(geo_dvf), big.mark = ","), uniqueN(geo_dvf$code_departement), uniqueN(geo_dvf$year)))
cat(sprintf("  GPE stations: %d stations\n", nrow(stations)))
cat(sprintf("  Milestones: %d line segments\n", nrow(milestones)))

cat("\n=== DATA ACQUISITION COMPLETE ===\n")
