## ============================================================================
## 01_fetch_data.R — Networked Anxiety (apep_0562)
## Fetch all required data from public APIs and open data sources
## ============================================================================

source("00_packages.R")

DATA_DIR <- "../data"
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)

## ============================================================================
## 1. FACEBOOK SOCIAL CONNECTEDNESS INDEX (SCI) — NUTS3
## Source: Meta/Facebook via Humanitarian Data Exchange
## ============================================================================

cat("\n=== 1. Downloading SCI data ===\n")

sci_url <- "https://data.humdata.org/dataset/e9988552-74e4-4ff4-943f-c782ac8bca87/resource/b691d1d1-b286-456d-9a23-16e2f2d463cc/download/nuts_2024.zip"
sci_zip <- file.path(DATA_DIR, "nuts_2024.zip")
sci_dir <- file.path(DATA_DIR, "sci")

if (!file.exists(sci_zip)) {
  download.file(sci_url, sci_zip, mode = "wb", quiet = FALSE)
  dir.create(sci_dir, showWarnings = FALSE)
  unzip(sci_zip, exdir = sci_dir)
  cat("SCI data downloaded and extracted.\n")
} else {
  cat("SCI data already exists, skipping download.\n")
}

sci_files <- list.files(sci_dir, pattern = "\\.tsv$|\\.csv$",
                        recursive = TRUE, full.names = TRUE)
cat("SCI files found:", length(sci_files), "\n")

## ============================================================================
## 2. FRENCH ELECTION DATA (Aggregated Parquet from data.gouv.fr)
## ============================================================================

cat("\n=== 2. Downloading election data ===\n")

elections_dir <- file.path(DATA_DIR, "elections")
dir.create(elections_dir, showWarnings = FALSE)

cand_url <- "https://object.files.data.gouv.fr/data-pipeline-open/elections/candidats_results.parquet"
cand_file <- file.path(elections_dir, "candidats_results.parquet")

if (!file.exists(cand_file)) {
  cat("Downloading candidate results (~158 MB)...\n")
  download.file(cand_url, cand_file, mode = "wb", quiet = FALSE)
} else {
  cat("Candidate results already exist.\n")
}

gen_url <- "https://object.files.data.gouv.fr/data-pipeline-open/elections/general_results.parquet"
gen_file <- file.path(elections_dir, "general_results.parquet")

if (!file.exists(gen_file)) {
  cat("Downloading general results (~68 MB)...\n")
  download.file(gen_url, gen_file, mode = "wb", quiet = FALSE)
} else {
  cat("General results already exist.\n")
}

nuance_url <- "https://static.data.gouv.fr/resources/donnees-des-elections-agregees/20260216-092608/nuances-politiques.csv"
nuance_file <- file.path(elections_dir, "nuances-politiques.csv")

if (!file.exists(nuance_file)) {
  download.file(nuance_url, nuance_file, mode = "wb", quiet = FALSE)
}

## ============================================================================
## 3. CADA CAPACITY BY DEPARTMENT (1994-2024) — data.gouv.fr
## Source: Ministère de l'Intérieur / DNA
## This is the key SHIFT variable for the Bartik design
## ============================================================================

cat("\n=== 3. Downloading CADA capacity data ===\n")

cada_dir <- file.path(DATA_DIR, "cada")
dir.create(cada_dir, showWarnings = FALSE)

## Primary: CADA capacities dataset from data.gouv.fr
## URL: https://www.data.gouv.fr/datasets/capacites-des-centres-daccueil-pour-demandeurs-dasile-de-1994-a-2024/
cada_url <- "https://www.data.gouv.fr/fr/datasets/r/6da3757f-8b3f-4441-b8f5-4c122ef3f5c4"
cada_file <- file.path(cada_dir, "cada_capacities.csv")

cada_success <- FALSE

if (!file.exists(cada_file)) {
  cat("Downloading CADA capacity data...\n")
  tryCatch({
    download.file(cada_url, cada_file, mode = "wb", quiet = FALSE, timeout = 120)
    ## Check if download was successful (non-empty file)
    if (file.size(cada_file) > 100) {
      cat("  CADA capacity data downloaded.\n")
      cada_success <- TRUE
    } else {
      cat("  WARNING: Downloaded file appears empty.\n")
      file.remove(cada_file)
    }
  }, error = function(e) {
    cat("  WARNING: Primary CADA URL failed:", e$message, "\n")
  })
} else {
  cat("CADA capacity data already exists.\n")
  cada_success <- TRUE
}

## Fallback: Try alternative URL patterns from data.gouv.fr
if (!cada_success) {
  alt_urls <- c(
    "https://static.data.gouv.fr/resources/capacites-des-centres-daccueil-pour-demandeurs-dasile-de-1994-a-2024/20241201-000000/cada_capacites.csv",
    "https://www.data.gouv.fr/fr/datasets/r/capacites-cada-1994-2024.csv"
  )

  for (url in alt_urls) {
    tryCatch({
      download.file(url, cada_file, mode = "wb", quiet = FALSE, timeout = 120)
      if (file.size(cada_file) > 100) {
        cat("  CADA data downloaded from alternative URL.\n")
        cada_success <- TRUE
        break
      } else {
        file.remove(cada_file)
      }
    }, error = function(e) {
      cat("  Alternative URL failed:", e$message, "\n")
    })
  }
}

## ============================================================================
## 3b. OFPRA ASYLUM DEMANDS BY DEPARTMENT (backup shift measure)
## Source: data.gouv.fr — OFPRA published data
## ============================================================================

cat("\n=== 3b. Downloading OFPRA asylum demands data ===\n")

ofpra_dir <- file.path(DATA_DIR, "ofpra")
dir.create(ofpra_dir, showWarnings = FALSE)

## OFPRA asylum demands dataset
## URL: https://www.data.gouv.fr/datasets/les-demandes-dasile/
ofpra_url <- "https://www.data.gouv.fr/fr/datasets/r/45d26b23-4bbe-4a5d-97b2-07a13e02c664"
ofpra_file <- file.path(ofpra_dir, "demandes_asile.csv")

ofpra_success <- FALSE

if (!file.exists(ofpra_file)) {
  cat("Downloading OFPRA asylum demands...\n")
  tryCatch({
    download.file(ofpra_url, ofpra_file, mode = "wb", quiet = FALSE, timeout = 120)
    if (file.size(ofpra_file) > 100) {
      cat("  OFPRA data downloaded.\n")
      ofpra_success <- TRUE
    } else {
      file.remove(ofpra_file)
    }
  }, error = function(e) {
    cat("  WARNING: OFPRA download failed:", e$message, "\n")
  })
} else {
  cat("OFPRA data already exists.\n")
  ofpra_success <- TRUE
}

## ============================================================================
## 3c. HÉBERGEMENT PLACES (social housing/asylum accommodation)
## Source: data.gouv.fr — Places d'hébergement
## ============================================================================

cat("\n=== 3c. Downloading hébergement places data ===\n")

heb_url <- "https://www.data.gouv.fr/fr/datasets/r/58f1ed89-0585-4a88-9b54-e67a3cf3c448"
heb_file <- file.path(cada_dir, "places_hebergement.csv")

heb_success <- FALSE

if (!file.exists(heb_file)) {
  tryCatch({
    download.file(heb_url, heb_file, mode = "wb", quiet = FALSE, timeout = 120)
    if (file.size(heb_file) > 100) {
      cat("  Hébergement places data downloaded.\n")
      heb_success <- TRUE
    } else {
      file.remove(heb_file)
    }
  }, error = function(e) {
    cat("  WARNING: Hébergement download failed:", e$message, "\n")
  })
} else {
  cat("Hébergement data already exists.\n")
  heb_success <- TRUE
}

## ============================================================================
## 4. INSEE CONTROLS — Population, Income, Unemployment, Education
## ============================================================================

cat("\n=== 4. Downloading INSEE control variables ===\n")

insee_dir <- file.path(DATA_DIR, "insee")
dir.create(insee_dir, showWarnings = FALSE)

## 4a. Filosofi (income/poverty by département)
filosofi_url <- "https://www.insee.fr/fr/statistiques/fichier/7756729/base-cc-filosofi-2021-geo2025_csv.zip"
filosofi_zip <- file.path(insee_dir, "filosofi_2021.zip")

if (!file.exists(filosofi_zip)) {
  cat("Downloading Filosofi 2021...\n")
  tryCatch({
    download.file(filosofi_url, filosofi_zip, mode = "wb", quiet = FALSE)
    unzip(filosofi_zip, exdir = file.path(insee_dir, "filosofi_2021"))
  }, error = function(e) {
    cat("  WARNING: Filosofi download failed:", e$message, "\n")
  })
} else {
  cat("Filosofi 2021 already exists.\n")
}

## 4b. Population by département
pop_url <- "https://www.insee.fr/fr/statistiques/fichier/1893198/estim-pop-dep-sexe-gca-1975-2024.xls"
pop_file <- file.path(insee_dir, "population_dept.xls")

if (!file.exists(pop_file)) {
  tryCatch({
    download.file(pop_url, pop_file, mode = "wb", quiet = FALSE)
  }, error = function(e) {
    cat("  WARNING: Population download failed:", e$message, "\n")
  })
} else {
  cat("Population data already exists.\n")
}

## 4c. Unemployment by département
unemp_url <- "https://www.insee.fr/fr/statistiques/fichier/1893230/sl_etc_2003-2024.xlsx"
unemp_file <- file.path(insee_dir, "chomage_dept.xlsx")

if (!file.exists(unemp_file)) {
  tryCatch({
    download.file(unemp_url, unemp_file, mode = "wb", quiet = FALSE, timeout = 120)
    cat("  Downloaded unemployment rates.\n")
  }, error = function(e) {
    cat("  WARNING: Unemployment download failed:", e$message, "\n")
  })
} else {
  cat("Unemployment data already exists.\n")
}

## 4d. Education (diplômes) — RP 2020
dip_url <- "https://www.insee.fr/fr/statistiques/fichier/2862201/base-cc-diplomes-form-2013_csv.zip"
dip_zip <- file.path(insee_dir, "rp2013_diplomes.zip")

if (!file.exists(dip_zip)) {
  tryCatch({
    download.file(dip_url, dip_zip, mode = "wb", quiet = FALSE, timeout = 300)
    unzip(dip_zip, exdir = file.path(insee_dir, "diplomes"))
    cat("  Downloaded education data.\n")
  }, error = function(e) {
    cat("  WARNING: Education download failed:", e$message, "\n")
  })
} else {
  cat("Education data already exists.\n")
}

## 4e. Employment/immigration — RP 2013
act_url <- "https://www.insee.fr/fr/statistiques/fichier/2862149/base-cc-emploi-pop-active-2013_csv.zip"
act_zip <- file.path(insee_dir, "rp2013_emploi.zip")

if (!file.exists(act_zip)) {
  tryCatch({
    download.file(act_url, act_zip, mode = "wb", quiet = FALSE, timeout = 300)
    unzip(act_zip, exdir = file.path(insee_dir, "emploi"))
    cat("  Downloaded employment data.\n")
  }, error = function(e) {
    cat("  WARNING: Employment download failed:", e$message, "\n")
  })
} else {
  cat("Employment data already exists.\n")
}

## 4f. INSEE migration flows (RP 2013) — for SCI validation
migration_dir <- file.path(insee_dir, "migration")
dir.create(migration_dir, showWarnings = FALSE)

mig_url <- "https://www.insee.fr/fr/statistiques/fichier/2866283/base-td-mob-dep-2013.zip"
mig_zip <- file.path(migration_dir, "rp2013_mob_dep.zip")

if (!file.exists(mig_zip)) {
  cat("  Downloading RP2013 migration matrix...\n")
  tryCatch({
    download.file(mig_url, mig_zip, mode = "wb", quiet = FALSE, timeout = 300)
    unzip(mig_zip, exdir = migration_dir)
    cat("  Downloaded migration data.\n")
  }, error = function(e) {
    cat("  WARNING: Migration download failed:", e$message, "\n")
  })
} else {
  cat("  Migration data already exists.\n")
}

## ============================================================================
## 5. DÉPARTEMENT BOUNDARIES (GeoJSON)
## ============================================================================

cat("\n=== 5. Downloading département boundaries ===\n")

geo_dir <- file.path(DATA_DIR, "geo")
dir.create(geo_dir, showWarnings = FALSE)

dept_geojson_url <- "https://raw.githubusercontent.com/gregoiredavid/france-geojson/master/departements-version-simplifiee.geojson"
dept_geojson <- file.path(geo_dir, "departements.geojson")

if (!file.exists(dept_geojson)) {
  tryCatch({
    download.file(dept_geojson_url, dept_geojson, mode = "wb", quiet = FALSE)
  }, error = function(e) {
    cat("  WARNING: GeoJSON download failed.\n")
  })
} else {
  cat("Département boundaries already exist.\n")
}

## ============================================================================
## 6. NUTS3 → DÉPARTEMENT MAPPING TABLE
## (Reused from apep_0464 — complete mapping for metropolitan France)
## ============================================================================

cat("\n=== 6. Creating NUTS3 <-> département mapping ===\n")

nuts3_dept <- tribble(
  ~nuts3, ~dept_code, ~dept_name,
  "FR101", "75", "Paris",
  "FR102", "77", "Seine-et-Marne",
  "FR103", "78", "Yvelines",
  "FR104", "91", "Essonne",
  "FR105", "92", "Hauts-de-Seine",
  "FR106", "93", "Seine-Saint-Denis",
  "FR107", "94", "Val-de-Marne",
  "FR108", "95", "Val-d'Oise",
  "FRB01", "18", "Cher",
  "FRB02", "28", "Eure-et-Loir",
  "FRB03", "36", "Indre",
  "FRB04", "37", "Indre-et-Loire",
  "FRB05", "41", "Loir-et-Cher",
  "FRB06", "45", "Loiret",
  "FRC11", "21", "Cote-d'Or",
  "FRC12", "58", "Nievre",
  "FRC13", "71", "Saone-et-Loire",
  "FRC14", "89", "Yonne",
  "FRC21", "25", "Doubs",
  "FRC22", "39", "Jura",
  "FRC23", "70", "Haute-Saone",
  "FRC24", "90", "Territoire de Belfort",
  "FRD11", "14", "Calvados",
  "FRD12", "50", "Manche",
  "FRD13", "61", "Orne",
  "FRD21", "27", "Eure",
  "FRD22", "76", "Seine-Maritime",
  "FRE11", "59", "Nord",
  "FRE12", "62", "Pas-de-Calais",
  "FRE21", "02", "Aisne",
  "FRE22", "60", "Oise",
  "FRE23", "80", "Somme",
  "FRF11", "67", "Bas-Rhin",
  "FRF12", "68", "Haut-Rhin",
  "FRF21", "08", "Ardennes",
  "FRF22", "10", "Aube",
  "FRF23", "51", "Marne",
  "FRF24", "52", "Haute-Marne",
  "FRF31", "54", "Meurthe-et-Moselle",
  "FRF32", "55", "Meuse",
  "FRF33", "57", "Moselle",
  "FRF34", "88", "Vosges",
  "FRG01", "44", "Loire-Atlantique",
  "FRG02", "49", "Maine-et-Loire",
  "FRG03", "53", "Mayenne",
  "FRG04", "72", "Sarthe",
  "FRG05", "85", "Vendee",
  "FRH01", "22", "Cotes-d'Armor",
  "FRH02", "29", "Finistere",
  "FRH03", "35", "Ille-et-Vilaine",
  "FRH04", "56", "Morbihan",
  "FRI11", "24", "Dordogne",
  "FRI12", "33", "Gironde",
  "FRI13", "40", "Landes",
  "FRI14", "47", "Lot-et-Garonne",
  "FRI15", "64", "Pyrenees-Atlantiques",
  "FRI21", "19", "Correze",
  "FRI22", "23", "Creuse",
  "FRI23", "87", "Haute-Vienne",
  "FRI31", "16", "Charente",
  "FRI32", "17", "Charente-Maritime",
  "FRI33", "79", "Deux-Sevres",
  "FRI34", "86", "Vienne",
  "FRJ11", "11", "Aude",
  "FRJ12", "30", "Gard",
  "FRJ13", "34", "Herault",
  "FRJ14", "48", "Lozere",
  "FRJ15", "66", "Pyrenees-Orientales",
  "FRJ21", "09", "Ariege",
  "FRJ22", "12", "Aveyron",
  "FRJ23", "31", "Haute-Garonne",
  "FRJ24", "32", "Gers",
  "FRJ25", "46", "Lot",
  "FRJ26", "65", "Hautes-Pyrenees",
  "FRJ27", "81", "Tarn",
  "FRJ28", "82", "Tarn-et-Garonne",
  "FRK11", "03", "Allier",
  "FRK12", "15", "Cantal",
  "FRK13", "43", "Haute-Loire",
  "FRK14", "63", "Puy-de-Dome",
  "FRK21", "01", "Ain",
  "FRK22", "07", "Ardeche",
  "FRK23", "26", "Drome",
  "FRK24", "38", "Isere",
  "FRK25", "42", "Loire",
  "FRK26", "69", "Rhone",
  "FRK27", "73", "Savoie",
  "FRK28", "74", "Haute-Savoie",
  "FRL01", "04", "Alpes-de-Haute-Provence",
  "FRL02", "05", "Hautes-Alpes",
  "FRL03", "06", "Alpes-Maritimes",
  "FRL04", "13", "Bouches-du-Rhone",
  "FRL05", "83", "Var",
  "FRL06", "84", "Vaucluse",
  "FRM01", "2A", "Corse-du-Sud",
  "FRM02", "2B", "Haute-Corse"
)

fwrite(nuts3_dept, file.path(DATA_DIR, "nuts3_dept_mapping.csv"))
cat("  Created mapping with", nrow(nuts3_dept), "departments.\n")

## ============================================================================
## VALIDATION
## ============================================================================

cat("\n", strrep("=", 60), "\n")
cat("DATA FETCH SUMMARY\n")
cat(strrep("=", 60), "\n")

files_check <- tibble(
  dataset = c("SCI (NUTS3)", "Elections candidates", "Elections general",
              "CADA capacity", "OFPRA demands", "Hebergement",
              "Filosofi", "Population", "Unemployment",
              "Education", "Employment", "Migration", "GeoJSON"),
  path = c(sci_zip, cand_file, gen_file,
           cada_file, ofpra_file, heb_file,
           filosofi_zip, pop_file, unemp_file,
           dip_zip, act_zip, mig_zip, dept_geojson),
  exists = file.exists(c(sci_zip, cand_file, gen_file,
                          cada_file, ofpra_file, heb_file,
                          filosofi_zip, pop_file, unemp_file,
                          dip_zip, act_zip, mig_zip, dept_geojson))
)

print(files_check %>% select(dataset, exists))

## Critical datasets
critical <- c("SCI (NUTS3)", "Elections candidates", "Elections general")
critical_ok <- all(files_check %>% filter(dataset %in% critical) %>% pull(exists))

if (!critical_ok) {
  stop("CRITICAL: SCI or election data download failed. Cannot proceed.")
}

## CADA/OFPRA — at least one shift measure needed
shift_ok <- file.exists(cada_file) || file.exists(ofpra_file) || file.exists(heb_file)
if (!shift_ok) {
  cat("\nWARNING: No asylum capacity data downloaded.\n")
  cat("Will construct shift variable from official published figures.\n")
}

cat("\nData fetch complete.\n")
