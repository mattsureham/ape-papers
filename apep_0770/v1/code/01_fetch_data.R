# 01_fetch_data.R — Data acquisition for apep_0770
# French maternity ward closures and populist voting
# Sources: DREES (maternities), data.gouv.fr (elections, commune coords)

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

cat("=== 1. DREES Maternity Facility Data ===\n")

# DREES SAE maternity data (2000-2024)
drees_url <- paste0(
  "https://data.drees.solidarites-sante.gouv.fr/api/explore/v2.1/",
  "catalog/datasets/fichier_maternites_112021/exports/csv",
  "?delimiter=%3B&list_separator=%2C&select=*"
)

drees_file <- file.path(data_dir, "drees_maternites_raw.csv")
cat("Fetching DREES maternity data...\n")
resp <- httr::GET(drees_url, httr::write_disk(drees_file, overwrite = TRUE),
                  httr::timeout(120))
if (httr::status_code(resp) != 200) {
  stop("DREES API returned status ", httr::status_code(resp),
       ". Cannot proceed without real maternity data.")
}

mat_raw <- fread(drees_file, encoding = "UTF-8")
cat("DREES records downloaded:", nrow(mat_raw), "\n")
cat("Columns:", paste(names(mat_raw), collapse = ", "), "\n")

if (nrow(mat_raw) == 0) {
  stop("DREES returned zero rows. Cannot proceed without real maternity data.")
}


cat("\n=== 2. Election Results (Parquet) ===\n")

# Candidate-level results (bureau de vote, all elections 1999-2024)
elec_url <- "https://object.files.data.gouv.fr/data-pipeline-open/elections/candidats_results.parquet"
elec_file <- file.path(data_dir, "candidats_results.parquet")

cat("Fetching election results (~158 MB Parquet)...\n")
resp2 <- httr::GET(elec_url, httr::write_disk(elec_file, overwrite = TRUE),
                   httr::timeout(300))
if (httr::status_code(resp2) != 200) {
  stop("Election data download failed with status ", httr::status_code(resp2))
}

# General results (turnout, blanks)
gen_url <- "https://object.files.data.gouv.fr/data-pipeline-open/elections/general_results.parquet"
gen_file <- file.path(data_dir, "general_results.parquet")

cat("Fetching general election results (~68 MB Parquet)...\n")
resp3 <- httr::GET(gen_url, httr::write_disk(gen_file, overwrite = TRUE),
                   httr::timeout(300))
if (httr::status_code(resp3) != 200) {
  stop("General election data download failed with status ", httr::status_code(resp3))
}

# Quick validation
elec <- arrow::read_parquet(elec_file)
setDT(elec)
cat("Election records:", nrow(elec), "\n")
cat("Election columns:", paste(names(elec), collapse = ", "), "\n")
cat("Election types:", paste(unique(elec$type_election %||% elec$election), collapse = ", "), "\n")

if (nrow(elec) == 0) {
  stop("Election parquet is empty. Cannot proceed.")
}


cat("\n=== 3. Commune Coordinates ===\n")

communes_url <- paste0(
  "https://static.data.gouv.fr/resources/",
  "communes-et-villes-de-france-en-csv-excel-json-parquet-et-feather/",
  "20250221-162232/communes-france-2025.csv"
)
communes_file <- file.path(data_dir, "communes_france.csv")

cat("Fetching commune coordinates...\n")
resp4 <- httr::GET(communes_url, httr::write_disk(communes_file, overwrite = TRUE),
                   httr::timeout(120))
if (httr::status_code(resp4) != 200) {
  stop("Commune coordinate download failed with status ", httr::status_code(resp4))
}

communes <- fread(communes_file, encoding = "UTF-8")
cat("Communes loaded:", nrow(communes), "\n")
cat("Commune columns:", paste(names(communes), collapse = ", "), "\n")

if (nrow(communes) == 0) {
  stop("Commune data is empty. Cannot proceed.")
}


cat("\n=== 4. Nuances politiques (party code lookup) ===\n")

nuances_url <- paste0(
  "https://static.data.gouv.fr/resources/donnees-des-elections-agregees/",
  "20260216-092608/nuances-politiques.csv"
)
nuances_file <- file.path(data_dir, "nuances_politiques.csv")

resp5 <- httr::GET(nuances_url, httr::write_disk(nuances_file, overwrite = TRUE),
                   httr::timeout(60))
if (httr::status_code(resp5) != 200) {
  cat("Warning: Nuances file not found (", httr::status_code(resp5),
      "). Will identify FN/RN candidates by name.\n")
} else {
  nuances <- fread(nuances_file, encoding = "UTF-8")
  cat("Nuances loaded:", nrow(nuances), "\n")
}


cat("\n=== All data fetched successfully ===\n")
cat("Files in data/:\n")
for (f in list.files(data_dir)) {
  sz <- file.info(file.path(data_dir, f))$size
  cat(sprintf("  %s: %.1f MB\n", f, sz / 1e6))
}
