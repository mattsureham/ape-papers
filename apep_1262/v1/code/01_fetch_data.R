## ============================================================================
## 01_fetch_data.R — SRU Carence Declarations and Electoral Backlash
## Fetch: SRU carence data, election results (Parquet), commune demographics
## ============================================================================

source("00_packages.R")

if (!requireNamespace("arrow", quietly = TRUE)) {
  install.packages("arrow", repos = "https://cloud.r-project.org")
}
library(arrow)

DATA_DIR <- "../data"
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)

## ============================================================================
## 1. SRU CARENCE DATA (data.gouv.fr)
## ============================================================================

cat("\n=== Downloading SRU data ===\n")

sru_dir <- file.path(DATA_DIR, "sru")
dir.create(sru_dir, showWarnings = FALSE)

## 1a. Full SRU inventory (2,196 communes, includes carence status)
sru_transparency_url <- "https://static.data.gouv.fr/resources/loi-sru-communes-carencees-a-la-suite-du-bilan-triennal-2017-2019/20210719-164757/transparence-sru-sans-doublon.csv"
sru_transparency_file <- file.path(sru_dir, "transparence_sru.csv")

if (!file.exists(sru_transparency_file)) {
  cat("Downloading SRU transparency data...\n")
  download.file(sru_transparency_url, sru_transparency_file, mode = "wb", quiet = FALSE)
} else {
  cat("SRU transparency data already exists.\n")
}

## 1b. Carencee commune list (2017-2019 period)
sru_carencees_url <- "https://static.data.gouv.fr/resources/loi-sru-communes-carencees-a-la-suite-du-bilan-triennal-2017-2019/20210125-182812/liste-carencees.csv"
sru_carencees_file <- file.path(sru_dir, "liste_carencees_2017_2019.csv")

if (!file.exists(sru_carencees_file)) {
  cat("Downloading carencee list 2017-2019...\n")
  download.file(sru_carencees_url, sru_carencees_file, mode = "wb", quiet = FALSE)
} else {
  cat("Carencee list 2017-2019 already exists.\n")
}

## 1c. Basic carencee list
sru_carences_url <- "https://static.data.gouv.fr/resources/loi-sru-communes-carencees-a-la-suite-du-bilan-triennal-2017-2019/20210125-182724/carences.csv"
sru_carences_file <- file.path(sru_dir, "carences.csv")

if (!file.exists(sru_carences_file)) {
  cat("Downloading carences basic list...\n")
  download.file(sru_carences_url, sru_carences_file, mode = "wb", quiet = FALSE)
} else {
  cat("Carences basic list already exists.\n")
}

## 1d. SRU penalties
sru_penalties_url <- "https://static.data.gouv.fr/resources/loi-sru-communes-carencees-a-la-suite-du-bilan-triennal-2017-2019/20210125-183113/penalites-sru.csv"
sru_penalties_file <- file.path(sru_dir, "penalites_sru.csv")

if (!file.exists(sru_penalties_file)) {
  cat("Downloading SRU penalties...\n")
  download.file(sru_penalties_url, sru_penalties_file, mode = "wb", quiet = FALSE)
} else {
  cat("SRU penalties already exists.\n")
}

## 1e. Search for additional SRU inventory data covering all periods
## The government published an updated SRU inventory with historical carence status
sru_inventory_url <- "https://static.data.gouv.fr/resources/loi-sru-bilan-triennal/20230116-160507/inventaire-sru-elargi.csv"
sru_inventory_file <- file.path(sru_dir, "inventaire_sru_elargi.csv")

if (!file.exists(sru_inventory_file)) {
  cat("Downloading SRU extended inventory (all periods)...\n")
  tryCatch({
    download.file(sru_inventory_url, sru_inventory_file, mode = "wb", quiet = FALSE)
    cat("  Extended SRU inventory downloaded.\n")
  }, error = function(e) {
    cat("  Extended inventory URL failed, trying alternative...\n")
    ## Alternative: data.gouv.fr SRU bilan triennal dataset
    alt_url <- "https://static.data.gouv.fr/resources/loi-sru-bilan-triennal/20221216-102505/inventaire-sru-2020-2022.csv"
    tryCatch({
      download.file(alt_url, file.path(sru_dir, "inventaire_sru_2020_2022.csv"),
                    mode = "wb", quiet = FALSE)
      cat("  2020-2022 inventory downloaded.\n")
    }, error = function(e2) {
      cat("  WARNING: Could not download extended SRU inventory.\n")
    })
  })
}

## ============================================================================
## 2. FRENCH ELECTION DATA (Aggregated Parquet — all elections, commune level)
## ============================================================================

cat("\n=== Downloading election data ===\n")

elections_dir <- file.path(DATA_DIR, "elections")
dir.create(elections_dir, showWarnings = FALSE)

## 2a. Candidate results (commune-level, all elections)
cand_url <- "https://object.files.data.gouv.fr/data-pipeline-open/elections/candidats_results.parquet"
cand_file <- file.path(elections_dir, "candidats_results.parquet")

if (!file.exists(cand_file)) {
  cat("Downloading candidate results parquet (158 MB)...\n")
  download.file(cand_url, cand_file, mode = "wb", quiet = FALSE)
} else {
  cat("Candidate results already exist.\n")
}

## 2b. General results (turnout, registered voters)
gen_url <- "https://object.files.data.gouv.fr/data-pipeline-open/elections/general_results.parquet"
gen_file <- file.path(elections_dir, "general_results.parquet")

if (!file.exists(gen_file)) {
  cat("Downloading general results parquet (68 MB)...\n")
  download.file(gen_url, gen_file, mode = "wb", quiet = FALSE)
} else {
  cat("General results already exist.\n")
}

## 2c. Political nuance mapping
nuance_url <- "https://static.data.gouv.fr/resources/donnees-des-elections-agregees/20260216-092608/nuances-politiques.csv"
nuance_file <- file.path(elections_dir, "nuances_politiques.csv")

if (!file.exists(nuance_file)) {
  cat("Downloading political nuance mapping...\n")
  tryCatch({
    download.file(nuance_url, nuance_file, mode = "wb", quiet = FALSE)
  }, error = function(e) {
    cat("  Nuance file download failed, will construct mapping manually.\n")
  })
}

## ============================================================================
## 3. COMMUNE DEMOGRAPHICS (INSEE)
## ============================================================================

cat("\n=== Downloading commune demographics ===\n")

demo_dir <- file.path(DATA_DIR, "demographics")
dir.create(demo_dir, showWarnings = FALSE)

## 3a. Commune population data from INSEE
## Using the COG (Code Officiel Geographique) for commune identifiers
pop_url <- "https://www.insee.fr/fr/statistiques/fichier/6683035/ensemble.zip"
pop_file <- file.path(demo_dir, "ensemble_population.zip")

if (!file.exists(pop_file)) {
  cat("Downloading commune population data...\n")
  tryCatch({
    download.file(pop_url, pop_file, mode = "wb", quiet = FALSE)
    unzip(pop_file, exdir = demo_dir)
    cat("  Population data downloaded and extracted.\n")
  }, error = function(e) {
    cat("  Population download failed, trying BDM API...\n")
  })
} else {
  cat("Population data already exists.\n")
}

## 3b. Commune median income data (Filosofi)
## Try to get median income at commune level from INSEE
income_url <- "https://www.insee.fr/fr/statistiques/fichier/6036907/indic-struct-distrib-revenu-2020-COMMUNES.zip"
income_file <- file.path(demo_dir, "revenu_communes.zip")

if (!file.exists(income_file)) {
  cat("Downloading commune income data (Filosofi)...\n")
  tryCatch({
    download.file(income_url, income_file, mode = "wb", quiet = FALSE)
    unzip(income_file, exdir = demo_dir)
    cat("  Income data downloaded.\n")
  }, error = function(e) {
    cat("  Income download failed: ", conditionMessage(e), "\n")
  })
} else {
  cat("Income data already exists.\n")
}

## ============================================================================
## 4. VALIDATION
## ============================================================================

cat("\n=== Validating downloaded data ===\n")

## Check SRU files
sru_files <- list.files(sru_dir, pattern = "\\.csv$", full.names = TRUE)
cat("SRU files found:", length(sru_files), "\n")
for (f in sru_files) {
  n <- nrow(fread(f, nrows = Inf))
  cat("  ", basename(f), ":", n, "rows\n")
}

## Check election Parquet files
if (file.exists(cand_file)) {
  cand_df <- read_parquet(cand_file) |> head(5)
  cat("\nElection candidate results columns:", paste(names(cand_df), collapse = ", "), "\n")
  cat("Sample election types:", paste(unique(head(read_parquet(cand_file) |>
    pull(any_of(c("type_election", "election_type", "type"))), 1000)), collapse = ", "), "\n")
} else {
  stop("FATAL: Election candidate results not downloaded.")
}

if (file.exists(gen_file)) {
  gen_df <- read_parquet(gen_file) |> head(5)
  cat("General results columns:", paste(names(gen_df), collapse = ", "), "\n")
} else {
  stop("FATAL: Election general results not downloaded.")
}

cat("\n=== Data fetch complete ===\n")
