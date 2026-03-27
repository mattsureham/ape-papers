## 01_fetch_data.R — Download BPE and election data
## apep_1036: Tax Office Closures and Far-Right Voting in France

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ---------------------------------------------------------------
## 1. BPE (Base Permanente des Équipements) — tax office presence
## ---------------------------------------------------------------

## BPE Evolution 2019-2024 (commune-level counts, code A01G = DRFIP+DDFIP)
bpe_evo_url <- "https://www.insee.fr/fr/statistiques/fichier/8217532/ds_bpe_evolution_com_2019_2024_geo_2025.zip"
bpe_evo_zip <- file.path(data_dir, "bpe_evolution.zip")
if (!file.exists(bpe_evo_zip)) {
  cat("Downloading BPE Evolution 2019-2024...\n")
  download.file(bpe_evo_url, bpe_evo_zip, mode = "wb", quiet = TRUE)
}
unzip(bpe_evo_zip, exdir = file.path(data_dir, "bpe_evolution"))
bpe_evo_files <- list.files(file.path(data_dir, "bpe_evolution"), pattern = "\\.csv$",
                             full.names = TRUE, recursive = TRUE)
cat("BPE evolution files:", bpe_evo_files, "\n")

## BPE 2024 geolocated (individual establishments)
bpe24_url <- "https://www.insee.fr/fr/statistiques/fichier/8217525/BPE24.parquet"
bpe24_file <- file.path(data_dir, "BPE24.parquet")
if (!file.exists(bpe24_file)) {
  cat("Downloading BPE 2024 (parquet)...\n")
  download.file(bpe24_url, bpe24_file, mode = "wb", quiet = TRUE)
}

## BPE 2021 geolocated
bpe21_url <- "https://static.data.gouv.fr/resources/equipements-geolocalises-commerce-services-sante-en-2021/20230131-181325/bpe21-ensemble-xy-csv.zip"
bpe21_zip <- file.path(data_dir, "bpe21.zip")
if (!file.exists(bpe21_zip)) {
  cat("Downloading BPE 2021...\n")
  download.file(bpe21_url, bpe21_zip, mode = "wb", quiet = TRUE)
}
unzip(bpe21_zip, exdir = file.path(data_dir, "bpe21"))

## BPE 2018
bpe18_url <- "https://static.data.gouv.fr/resources/base-permanente-des-equipements/20200819-125550/bpe-ensemble.csv"
bpe18_file <- file.path(data_dir, "bpe18.csv")
if (!file.exists(bpe18_file)) {
  cat("Downloading BPE 2018...\n")
  download.file(bpe18_url, bpe18_file, mode = "wb", quiet = TRUE)
}

## ---------------------------------------------------------------
## 2. Election results — commune level
## ---------------------------------------------------------------

cand_url <- "https://object.files.data.gouv.fr/data-pipeline-open/elections/candidats_results.parquet"
gen_url  <- "https://object.files.data.gouv.fr/data-pipeline-open/elections/general_results.parquet"

cand_file <- file.path(data_dir, "candidats_results.parquet")
gen_file  <- file.path(data_dir, "general_results.parquet")

if (!file.exists(cand_file)) {
  cat("Downloading election candidate results (parquet)...\n")
  download.file(cand_url, cand_file, mode = "wb", quiet = TRUE)
}
if (!file.exists(gen_file)) {
  cat("Downloading election general results (parquet)...\n")
  download.file(gen_url, gen_file, mode = "wb", quiet = TRUE)
}

## ---------------------------------------------------------------
## 3. Verify downloads
## ---------------------------------------------------------------

stopifnot("BPE 2024 parquet missing" = file.exists(bpe24_file))
stopifnot("Election candidates missing" = file.exists(cand_file))
stopifnot("Election general missing" = file.exists(gen_file))

## Quick check: read BPE 2024 and count tax offices
bpe24 <- arrow::read_parquet(bpe24_file)
bpe24 <- as.data.table(bpe24)
tax_offices_24 <- bpe24[TYPEQU %in% c("A120", "A121")]
cat("BPE 2024: ", nrow(tax_offices_24), "tax office establishments across",
    length(unique(tax_offices_24$DEPCOM)), "communes\n")

## Quick check: election data
cand <- arrow::read_parquet(cand_file)
cand <- as.data.table(cand)
cat("Election data: ", nrow(cand), "rows,", length(unique(cand$id_election)), "election-rounds\n")
cat("Elections available:\n")
print(sort(unique(cand$id_election)))

cat("\n01_fetch_data.R complete.\n")
