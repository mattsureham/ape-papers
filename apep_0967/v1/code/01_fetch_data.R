# 01_fetch_data.R — Download Sirene establishment data and election results
# apep_0967: CSE Reform and Far-Right Voting in France

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# 1. SIRENE STOCK FILE (Parquet, ~2.1GB)
# ============================================================================
sirene_parquet <- file.path(data_dir, "StockEtablissement_utf8.parquet")
sirene_url <- "https://object.files.data.gouv.fr/data-pipeline-open/siren/stock/StockEtablissement_utf8.parquet"

if (!file.exists(sirene_parquet)) {
  cat("Downloading Sirene stock file (2.1 GB)...\n")
  download.file(sirene_url, sirene_parquet, mode = "wb", quiet = FALSE)
  cat("Sirene download complete.\n")
} else {
  cat("Sirene file already exists, skipping download.\n")
}

# Validate: open and check schema
ds <- open_dataset(sirene_parquet)
schema_names <- names(ds)
stopifnot("codeCommuneEtablissement" %in% schema_names)
stopifnot("trancheEffectifsEtablissement" %in% schema_names)
stopifnot("etatAdministratifEtablissement" %in% schema_names)
cat("Sirene schema validated. Columns:", length(schema_names), "\n")

# Aggregate commune-level establishment counts by size bracket
# Process with arrow (never load full file into memory)
cat("Aggregating Sirene by commune and size bracket...\n")

commune_estab <- ds |>
  filter(etatAdministratifEtablissement == "A") |>  # Active establishments only
  select(codeCommuneEtablissement, trancheEffectifsEtablissement) |>
  collect() |>
  rename(
    code_commune = codeCommuneEtablissement,
    size_bracket = trancheEffectifsEtablissement
  ) |>
  filter(!is.na(code_commune), code_commune != "", nchar(code_commune) == 5)

cat("Active establishments with valid commune codes:", nrow(commune_estab), "\n")

# Size bracket codes (INSEE):
# NN = not known, 00 = 0 employees, 01 = 1-2, 02 = 3-5, 03 = 6-9
# 11 = 10-19, 12 = 20-49, 21 = 50-99, 22 = 100-199, 31 = 200-249
# 32 = 250-499, 41 = 500-999, 42 = 1000-1999, 51 = 2000-4999, 52 = 5000-9999, 53 = 10000+

# Define treatment: establishments with 50+ employees
# These are codes 21, 22, 31, 32, 41, 42, 51, 52, 53
treated_codes <- c("21", "22", "31", "32", "41", "42", "51", "52", "53")
# Medium firms (50-99): code 21 — most affected by CSE (had all 3 bodies, now 1)
medium_codes <- c("21")
# All firms with employees (excluding 00 and NN)
has_employees_codes <- c("01", "02", "03", "11", "12", "21", "22", "31", "32",
                          "41", "42", "51", "52", "53")

commune_treatment <- commune_estab |>
  group_by(code_commune) |>
  summarise(
    n_total = n(),
    n_has_employees = sum(size_bracket %in% has_employees_codes),
    n_50plus = sum(size_bracket %in% treated_codes),
    n_50_99 = sum(size_bracket %in% medium_codes),
    .groups = "drop"
  ) |>
  mutate(
    share_50plus = ifelse(n_has_employees > 0, n_50plus / n_has_employees, 0),
    share_50_99 = ifelse(n_has_employees > 0, n_50_99 / n_has_employees, 0)
  )

cat("Commune-level treatment data:", nrow(commune_treatment), "communes\n")
cat("Mean share 50+:", round(mean(commune_treatment$share_50plus), 4), "\n")
cat("SD share 50+:", round(sd(commune_treatment$share_50plus), 4), "\n")
cat("Communes with any 50+ firm:", sum(commune_treatment$n_50plus > 0), "\n")

write_csv(commune_treatment, file.path(data_dir, "commune_treatment.csv"))
rm(commune_estab, ds)
gc()

# ============================================================================
# 2. ELECTION RESULTS — 2012 Presidential 1st Round
# ============================================================================
elec_2012_file <- file.path(data_dir, "presidentielle_2012_T1_communes.csv")
elec_2012_url <- "https://static.data.gouv.fr/resources/election-presidentielle-2012-1er-tour-par-communes/20170425-174716/presidentielle_2012_T1_communes.csv"

if (!file.exists(elec_2012_file)) {
  cat("Downloading 2012 presidential election results...\n")
  download.file(elec_2012_url, elec_2012_file, mode = "wb", quiet = FALSE)
}
stopifnot(file.exists(elec_2012_file))
cat("2012 election data downloaded.\n")

# ============================================================================
# 3. ELECTION RESULTS — 2017 Presidential 1st Round
# ============================================================================
elec_2017_file <- file.path(data_dir, "presidentielle_2017_T1_communes.xls")
elec_2017_url <- "https://static.data.gouv.fr/resources/election-presidentielle-des-23-avril-et-7-mai-2017-resultats-definitifs-du-1er-tour-par-communes/20170427-100544/Presidentielle_2017_Resultats_Communes_Tour_1_c.xls"

if (!file.exists(elec_2017_file)) {
  cat("Downloading 2017 presidential election results...\n")
  download.file(elec_2017_url, elec_2017_file, mode = "wb", quiet = FALSE)
}
stopifnot(file.exists(elec_2017_file))
cat("2017 election data downloaded.\n")

# ============================================================================
# 4. ELECTION RESULTS — 2022 Presidential 1st Round
# ============================================================================
elec_2022_file <- file.path(data_dir, "presidentielle_2022_T1_communes.csv")
elec_2022_url <- "https://static.data.gouv.fr/resources/resultats-du-premier-tour-de-lelection-presidentielle-2022-par-commune-et-par-departement/20220413-153144/04-resultats-par-commune.csv"

if (!file.exists(elec_2022_file)) {
  cat("Downloading 2022 presidential election results...\n")
  download.file(elec_2022_url, elec_2022_file, mode = "wb", quiet = FALSE)
}
stopifnot(file.exists(elec_2022_file))
cat("2022 election data downloaded.\n")

cat("\n=== All data downloaded successfully ===\n")
