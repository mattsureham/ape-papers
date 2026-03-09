## 01_fetch_data.R — Download ZRR classification and election data
## apep_0561: ZRR reclassification and RN voting

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1) ZRR Historical Classification
# ============================================================
cat("=== Downloading ZRR historical classification ===\n")

zrr_hist_url <- "https://static.data.gouv.fr/resources/zones-de-revitalisation-rurale-zrr/20201124-143142/diffusion-zonages-historique-zrr-2019.xls"
zrr_hist_file <- file.path(data_dir, "zrr_historique.xls")

if (!file.exists(zrr_hist_file)) {
  tryCatch({
    download.file(zrr_hist_url, zrr_hist_file, mode = "wb", quiet = FALSE)
    cat("ZRR historical file downloaded:", file.size(zrr_hist_file), "bytes\n")
  }, error = function(e) stop("ZRR historical data unavailable: ", e$message,
                               "\nPivot research question or fix the source."))
} else {
  cat("ZRR historical file already exists.\n")
}

zrr_curr_url <- "https://static.data.gouv.fr/resources/zones-de-revitalisation-rurale-zrr/20210907-124104/diffusion-zonages-zrr-cog2021.xls"
zrr_curr_file <- file.path(data_dir, "zrr_cog2021.xls")

if (!file.exists(zrr_curr_file)) {
  tryCatch({
    download.file(zrr_curr_url, zrr_curr_file, mode = "wb", quiet = FALSE)
    cat("ZRR current file downloaded:", file.size(zrr_curr_file), "bytes\n")
  }, error = function(e) stop("ZRR current data unavailable: ", e$message,
                               "\nPivot research question or fix the source."))
} else {
  cat("ZRR current file already exists.\n")
}

# ============================================================
# 2) Aggregated Election Data (Parquet — all elections 1999-2024)
# ============================================================
cat("\n=== Downloading aggregated election data (Parquet) ===\n")

# Candidate-level results (158 MB Parquet — all elections, all candidates, by bureau de vote)
cand_parquet_url <- "https://object.files.data.gouv.fr/data-pipeline-open/elections/candidats_results.parquet"
cand_parquet_file <- file.path(data_dir, "candidats_results.parquet")

if (!file.exists(cand_parquet_file)) {
  tryCatch({
    download.file(cand_parquet_url, cand_parquet_file, mode = "wb", quiet = FALSE)
    cat("Candidate results Parquet downloaded:", file.size(cand_parquet_file), "bytes\n")
  }, error = function(e) stop("Election candidate data unavailable: ", e$message,
                               "\nPivot research question or fix the source."))
} else {
  cat("Candidate results Parquet already exists.\n")
}

# General results (68 MB Parquet — turnout, blanks, nulls by bureau de vote)
gen_parquet_url <- "https://object.files.data.gouv.fr/data-pipeline-open/elections/general_results.parquet"
gen_parquet_file <- file.path(data_dir, "general_results.parquet")

if (!file.exists(gen_parquet_file)) {
  tryCatch({
    download.file(gen_parquet_url, gen_parquet_file, mode = "wb", quiet = FALSE)
    cat("General results Parquet downloaded:", file.size(gen_parquet_file), "bytes\n")
  }, error = function(e) stop("Election general data unavailable: ", e$message,
                               "\nPivot research question or fix the source."))
} else {
  cat("General results Parquet already exists.\n")
}

# ============================================================
# 3) 2022 Presidential Results by Commune (CSV — cleaner format for cross-check)
# ============================================================
cat("\n=== Downloading 2022 presidential first round by commune ===\n")

pres2022_url <- "https://static.data.gouv.fr/resources/resultats-du-premier-tour-de-lelection-presidentielle-2022-par-commune-et-par-departement/20220413-153144/04-resultats-par-commune.csv"
pres2022_file <- file.path(data_dir, "pres2022_t1_commune.csv")

if (!file.exists(pres2022_file)) {
  tryCatch({
    download.file(pres2022_url, pres2022_file, mode = "wb", quiet = FALSE)
    cat("2022 presidential results downloaded:", file.size(pres2022_file), "bytes\n")
  }, error = function(e) {
    warning("2022 commune CSV not available, will use Parquet aggregation instead: ", e$message)
  })
} else {
  cat("2022 presidential results already exist.\n")
}

# ============================================================
# 4) Commune-EPCI Crosswalk (for RD running variable)
# ============================================================
cat("\n=== Downloading commune-EPCI crosswalk ===\n")

# BANATIC (base nationale intercommunalité) — commune to EPCI mapping
# Using table des EPCI from collectivites-locales.gouv.fr
epci_url <- "https://www.collectivites-locales.gouv.fr/files/Accueil/DESL/2017/epcicom2017.csv"
epci_file <- file.path(data_dir, "epcicom2017.csv")

if (!file.exists(epci_file)) {
  tryCatch({
    download.file(epci_url, epci_file, mode = "wb", quiet = FALSE)
    cat("EPCI crosswalk downloaded:", file.size(epci_file), "bytes\n")
  }, error = function(e) {
    warning("EPCI crosswalk from collectivites-locales.gouv.fr failed: ", e$message)
    # Fallback: try BANATIC direct
    epci_url2 <- "https://www.banatic.interieur.gouv.fr/V5/fichiers-en-telechargement/telecharger.php?zone=N&date=01/01/2017&format=C"
    tryCatch({
      download.file(epci_url2, epci_file, mode = "wb", quiet = FALSE)
      cat("EPCI crosswalk downloaded from BANATIC.\n")
    }, error = function(e2) {
      warning("BANATIC fallback also failed: ", e2$message,
              "\nWill construct EPCI mapping from ZRR data if possible.")
    })
  })
} else {
  cat("EPCI crosswalk already exists.\n")
}

# ============================================================
# 5) Commune population and density data (INSEE)
# ============================================================
cat("\n=== Downloading commune population data ===\n")

# INSEE populations légales 2017 (for EPCI density calculation)
pop_url <- "https://www.insee.fr/fr/statistiques/fichier/4265439/ensemble.zip"
pop_file <- file.path(data_dir, "pop_legales_2017.zip")

if (!file.exists(pop_file)) {
  tryCatch({
    download.file(pop_url, pop_file, mode = "wb", quiet = FALSE)
    cat("Population data downloaded:", file.size(pop_file), "bytes\n")
  }, error = function(e) {
    warning("INSEE population download failed: ", e$message)
  })
} else {
  cat("Population data already exists.\n")
}

# ============================================================
# 6) Commune surface area (for density calculation)
# ============================================================
cat("\n=== Downloading commune surface area data ===\n")

# INSEE commune surface data from COG
surface_url <- "https://www.insee.fr/fr/statistiques/fichier/7766585/v_commune_2017.csv"
surface_file <- file.path(data_dir, "communes_cog2017.csv")

if (!file.exists(surface_file)) {
  tryCatch({
    download.file(surface_url, surface_file, mode = "wb", quiet = FALSE)
    cat("Commune surface data downloaded.\n")
  }, error = function(e) {
    warning("Commune surface download failed: ", e$message)
  })
} else {
  cat("Commune surface data already exists.\n")
}

# ============================================================
# VALIDATION
# ============================================================
cat("\n=== DATA VALIDATION ===\n")

# Check ZRR files exist and are non-empty
stopifnot("ZRR historical file must exist" = file.exists(zrr_hist_file))
stopifnot("ZRR historical file must be non-empty" = file.size(zrr_hist_file) > 1000)
stopifnot("ZRR current file must exist" = file.exists(zrr_curr_file))
cat("ZRR data: OK (historical:", round(file.size(zrr_hist_file)/1e6, 1), "MB,",
    "current:", round(file.size(zrr_curr_file)/1e6, 1), "MB)\n")

# Check election Parquet files
stopifnot("Candidate results Parquet must exist" = file.exists(cand_parquet_file))
stopifnot("Candidate results must be non-empty" = file.size(cand_parquet_file) > 1e6)
stopifnot("General results Parquet must exist" = file.exists(gen_parquet_file))
cat("Election data: OK (candidates:", round(file.size(cand_parquet_file)/1e6, 1), "MB,",
    "general:", round(file.size(gen_parquet_file)/1e6, 1), "MB)\n")

# Quick check of Parquet schema
cand_schema <- arrow::open_dataset(cand_parquet_file)$schema
cat("Candidate results columns:", paste(cand_schema$names, collapse = ", "), "\n")

gen_schema <- arrow::open_dataset(gen_parquet_file)$schema
cat("General results columns:", paste(gen_schema$names, collapse = ", "), "\n")

# Check which elections are in the data
elections <- arrow::open_dataset(cand_parquet_file) |>
  dplyr::select(id_election) |>
  dplyr::distinct() |>
  dplyr::collect()
cat("Elections available:", paste(sort(elections$id_election), collapse = ", "), "\n")

# Verify our target elections exist
target_elections <- c("2002_pres_t1", "2007_pres_t1", "2012_pres_t1",
                      "2017_pres_t1", "2022_pres_t1", "2019_euro")
found <- target_elections[target_elections %in% elections$id_election]
missing <- target_elections[!target_elections %in% elections$id_election]

cat("Target elections found:", paste(found, collapse = ", "), "\n")
if (length(missing) > 0) {
  cat("WARNING: Missing elections:", paste(missing, collapse = ", "), "\n")
  cat("Available elections with 'pres' or 'euro':\n")
  pres_euro <- elections$id_election[grepl("pres|euro", elections$id_election)]
  cat(paste(sort(pres_euro), collapse = "\n"), "\n")
}

cat("\nData fetch complete. All required files downloaded.\n")
