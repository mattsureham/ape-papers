## 01_fetch_data.R — Fetch all data sources
## apep_0632: ZFE Low-Emission Zones and Populist Voting in France

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## Helper: download with retry (uses download.file for better redirect handling)
safe_download <- function(url, destfile, desc, timeout_sec = 120) {
  if (file.exists(destfile) && file.size(destfile) > 100) {
    cat(sprintf("  %s: already on disk\n", desc))
    return(TRUE)
  }
  cat(sprintf("  Downloading %s...\n", desc))
  options(timeout = timeout_sec)
  tryCatch({
    download.file(url, destfile, mode = "wb", quiet = TRUE)
    if (file.exists(destfile) && file.size(destfile) > 100) {
      cat(sprintf("  OK: %s (%.1f KB)\n", desc, file.size(destfile) / 1024))
      return(TRUE)
    } else {
      cat(sprintf("  FAILED: %s (file too small or missing)\n", desc))
      unlink(destfile)
      return(FALSE)
    }
  }, error = function(e) {
    cat(sprintf("  FAILED: %s (%s)\n", desc, e$message))
    unlink(destfile)
    return(FALSE)
  })
}

## ============================================================
## 1. ZFE Boundaries from transport.data.gouv.fr (BNZFE aires)
## ============================================================
cat("=== 1. ZFE Boundaries ===\n")
zfe_ok <- safe_download(
  "https://transport.data.gouv.fr/resources/79567/download",
  file.path(data_dir, "zfe_aires.geojson"),
  "ZFE boundary polygons (BNZFE)",
  timeout_sec = 120
)
stopifnot("ZFE boundaries download failed — cannot proceed" = zfe_ok)

zfe <- sf::st_read(file.path(data_dir, "zfe_aires.geojson"), quiet = TRUE)
cat(sprintf("  ZFE features: %d\n", nrow(zfe)))

## ============================================================
## 2. Commune centroids from geo.api.gouv.fr (by département)
## ============================================================
cat("\n=== 2. Commune Centroids ===\n")
communes_file <- file.path(data_dir, "communes_centroids.rds")

if (!file.exists(communes_file)) {
  ## Download all départements (01-95 + 2A, 2B, 971-976)
  dept_codes <- c(sprintf("%02d", 1:19), "2A", "2B", sprintf("%02d", 21:95),
                  sprintf("%03d", 971:976))
  all_communes <- list()

  for (d in dept_codes) {
    url <- sprintf("https://geo.api.gouv.fr/departements/%s/communes?fields=code,nom,centre,population&format=json", d)
    resp <- httr::GET(url, httr::timeout(30))
    if (httr::status_code(resp) == 200) {
      json <- httr::content(resp, as = "text", encoding = "UTF-8")
      parsed <- jsonlite::fromJSON(json, simplifyDataFrame = FALSE)
      for (c in parsed) {
        if (!is.null(c$centre)) {
          all_communes[[length(all_communes) + 1]] <- data.frame(
            code = c$code,
            nom = c$nom,
            lon = c$centre$coordinates[[1]],
            lat = c$centre$coordinates[[2]],
            population = ifelse(is.null(c$population), NA_integer_, c$population),
            departement = d,
            stringsAsFactors = FALSE
          )
        }
      }
    }
  }
  communes_df <- do.call(rbind, all_communes)
  communes <- sf::st_as_sf(communes_df, coords = c("lon", "lat"), crs = 4326)
  saveRDS(communes, communes_file)
  cat(sprintf("  Communes fetched and saved: %d\n", nrow(communes)))
} else {
  communes <- readRDS(communes_file)
  cat(sprintf("  Communes loaded from cache: %d\n", nrow(communes)))
}

## ============================================================
## 3. Election Results — Presidential 2012, 2017, 2022
## ============================================================
cat("\n=== 3. Election Results ===\n")

## Presidential 2022 Round 1 (tab-separated .txt, subcom level)
safe_download(
  "https://static.data.gouv.fr/resources/election-presidentielle-des-10-et-24-avril-2022-resultats-definitifs-du-1er-tour/20220414-152459/resultats-par-niveau-subcom-t1-france-entiere.txt",
  file.path(data_dir, "pres_2022_t1.txt"),
  "Presidential 2022 R1 (subcom)"
)

## Presidential 2017 Round 1 (xls, commune level)
safe_download(
  "https://static.data.gouv.fr/resources/election-presidentielle-des-23-avril-et-7-mai-2017-resultats-definitifs-du-1er-tour-par-communes/20170427-100544/Presidentielle_2017_Resultats_Communes_Tour_1_c.xls",
  file.path(data_dir, "pres_2017_t1.xls"),
  "Presidential 2017 R1 (communes)"
)

## Presidential 2012 Round 1 (csv, commune level)
safe_download(
  "https://static.data.gouv.fr/resources/election-presidentielle-2012-1er-tour-par-communes/20170425-174716/presidentielle_2012_T1_communes.csv",
  file.path(data_dir, "pres_2012_t1.csv"),
  "Presidential 2012 R1 (communes)"
)

## Legislative 2024 Round 1 (csv, commune level)
safe_download(
  "https://www.data.gouv.fr/fr/datasets/r/bd32fcd3-53df-47ac-bf1d-8d8003fe23a1",
  file.path(data_dir, "legis_2024_t1.csv"),
  "Legislative 2024 R1 (communes)"
)

## ============================================================
## 4. Verify downloads
## ============================================================
cat("\n=== Download Summary ===\n")
expected_files <- c("zfe_aires.geojson", "communes_centroids.geojson",
                    "pres_2022_t1.txt", "pres_2017_t1.xls",
                    "pres_2012_t1.csv", "legis_2024_t1.csv")
for (f in expected_files) {
  fp <- file.path(data_dir, f)
  if (file.exists(fp)) {
    cat(sprintf("  ✓ %s (%.1f KB)\n", f, file.size(fp) / 1024))
  } else {
    cat(sprintf("  ✗ %s MISSING\n", f))
  }
}

cat("\nData fetch complete.\n")
