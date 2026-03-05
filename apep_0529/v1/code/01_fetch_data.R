## 01_fetch_data.R — Fetch all data for apep_0529
## Sources: elections, ZFE boundaries, roll-call votes, constituencies

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ============================================================
## 1. Election results (aggregated elections, Parquet format)
## ============================================================
cat("=== Fetching election results ===\n")

election_cand_url <- "https://object.files.data.gouv.fr/data-pipeline-open/elections/candidats_results.parquet"
election_cand_file <- file.path(data_dir, "elections_candidats.parquet")

if (!file.exists(election_cand_file)) {
  tryCatch({
    download.file(election_cand_url, election_cand_file, mode = "wb", quiet = FALSE)
  }, error = function(e) stop("Election candidate data unavailable: ", e$message,
                              "\nCheck: https://www.data.gouv.fr/datasets/donnees-des-elections-agregees"))
}

election_gen_url <- "https://object.files.data.gouv.fr/data-pipeline-open/elections/general_results.parquet"
election_gen_file <- file.path(data_dir, "elections_general.parquet")

if (!file.exists(election_gen_file)) {
  tryCatch({
    download.file(election_gen_url, election_gen_file, mode = "wb", quiet = FALSE)
  }, error = function(e) stop("Election general data unavailable: ", e$message))
}

## ============================================================
## 2. ZFE boundaries (BNZFE GeoJSON)
## ============================================================
cat("=== Fetching ZFE boundaries ===\n")

zfe_url <- "https://static.data.gouv.fr/resources/base-nationale-consolidee-des-zones-a-faibles-emissions/20260224-143029/aires.geojson"
zfe_file <- file.path(data_dir, "zfe_aires.geojson")

if (!file.exists(zfe_file)) {
  tryCatch({
    download.file(zfe_url, zfe_file, mode = "wb", quiet = FALSE)
  }, error = function(e) stop("ZFE boundary data unavailable: ", e$message))
}

## ============================================================
## 3. Constituency boundaries (GeoJSON)
## ============================================================
cat("=== Fetching constituency boundaries ===\n")

circ_url <- "https://static.data.gouv.fr/resources/contours-geographiques-des-circonscriptions-legislatives/20240613-191506/circonscriptions-legislatives-p20.geojson"
circ_file <- file.path(data_dir, "circonscriptions.geojson")

if (!file.exists(circ_file)) {
  tryCatch({
    download.file(circ_url, circ_file, mode = "wb", quiet = FALSE)
  }, error = function(e) stop("Constituency boundary data unavailable: ", e$message))
}

## ============================================================
## 4. Assemblee nationale roll-call votes (scrutins publics)
## ============================================================
cat("=== Fetching roll-call votes ===\n")

fetch_scrutins_legislature <- function(legislature) {
  url <- sprintf("https://www.nosdeputes.fr/%d/scrutins/json", legislature)
  cat("  Fetching legislature", legislature, "...\n")
  tryCatch({
    resp <- httr2::request(url) |>
      httr2::req_timeout(120) |>
      httr2::req_perform()
    raw <- httr2::resp_body_string(resp)
    parsed <- jsonlite::fromJSON(raw, simplifyVector = FALSE)
    return(parsed)
  }, error = function(e) {
    warning("Failed to fetch scrutins for legislature ", legislature, ": ", e$message)
    return(NULL)
  })
}

scrutins_file <- file.path(data_dir, "scrutins_all.rds")
if (!file.exists(scrutins_file)) {
  all_scrutins <- list()
  for (leg in c(14, 15, 16, 17)) {
    result <- fetch_scrutins_legislature(leg)
    if (!is.null(result)) {
      all_scrutins[[as.character(leg)]] <- result
    }
    Sys.sleep(2)
  }
  saveRDS(all_scrutins, scrutins_file)
}

## ============================================================
## 5. Deputy information (MP-constituency link)
## ============================================================
cat("=== Fetching deputy data ===\n")

## NosDéputes deputy endpoint only works for current legislature
## Use the current legislature data (sufficient for spillback analysis on recent votes)
deputes_file <- file.path(data_dir, "deputes_current.rds")
if (!file.exists(deputes_file)) {
  cat("  Fetching current legislature deputies...\n")
  tryCatch({
    resp <- httr2::request("https://www.nosdeputes.fr/deputes/json") |>
      httr2::req_timeout(60) |>
      httr2::req_perform()
    raw <- httr2::resp_body_string(resp)
    parsed <- jsonlite::fromJSON(raw, simplifyVector = FALSE)
    saveRDS(parsed, deputes_file)
    cat("  Saved", length(parsed$deputes), "deputies\n")
  }, error = function(e) stop("Failed to fetch deputy data: ", e$message))
}

## ============================================================
## 6. ZFE implementation timeline (from government sources)
## ============================================================
cat("=== Writing ZFE implementation timeline ===\n")

zfe_timeline <- data.table(
  agglomeration = c(
    "Paris", "Lyon", "Grenoble", "Strasbourg",
    "Toulouse", "Nice", "Montpellier",
    "Reims", "Saint-Etienne", "Aix-Marseille", "Rouen",
    "Clermont-Ferrand",
    "Bordeaux", "Lille", "Nantes", "Rennes",
    "Nancy", "Le Havre", "Caen", "Dijon",
    "Annecy", "Pau", "Angers", "Nimes"
  ),
  departement = c(
    "75", "69", "38", "67",
    "31", "06", "34",
    "51", "42", "13", "76",
    "63",
    "33", "59", "44", "35",
    "54", "76", "14", "21",
    "74", "64", "49", "30"
  ),
  zfe_start = as.Date(c(
    "2019-07-01", "2020-01-01", "2023-07-07", "2023-01-01",
    "2022-03-01", "2022-01-31", "2022-07-01",
    "2022-01-01", "2022-01-31", "2022-09-01", "2022-09-01",
    "2023-07-01",
    "2025-01-01", "2025-01-01", "2025-01-01", "2024-12-30",
    "2025-01-01", "2025-01-01", "2025-01-01", "2025-01-01",
    "2025-01-01", "2025-01-01", "2025-01-01", "2025-01-01"
  )),
  wave = c(1L, 1L, 1L, 1L, 1L, 1L, 1L, 1L, 1L, 1L, 1L,
           2L, 2L, 2L, 2L, 2L, 2L, 2L, 2L, 2L, 2L, 2L, 2L, 2L),
  mandate_type = c(
    rep("air_quality", 11),
    rep("population_150k", 13)
  ),
  tier_2024 = c(
    "effectif", "effectif",
    "vigilance", "vigilance",
    "vigilance", "vigilance", "vigilance",
    "vigilance", "vigilance", "vigilance", "vigilance",
    rep("vigilance", 13)
  )
)

## Assign treatment year for DiD (election year when ZFE was first active)
## Legislative elections: 2012, 2017, 2022, 2024
zfe_timeline[, treatment_election_year := fifelse(
  zfe_start < as.Date("2022-06-01"), 2022L,
  fifelse(zfe_start < as.Date("2024-06-01"), 2024L, NA_integer_)
)]

fwrite(zfe_timeline, file.path(data_dir, "zfe_timeline.csv"))

## ============================================================
## VALIDATION
## ============================================================
cat("\n=== DATA VALIDATION ===\n")

## Check election data
stopifnot("Election candidate file must exist" = file.exists(election_cand_file))
elec <- arrow::open_dataset(election_cand_file)
cat("Election candidates:", length(elec$schema$names), "columns\n")

sample_dt <- as.data.table(head(elec, 100))
cat("  Sample columns:", paste(names(sample_dt)[1:min(8, ncol(sample_dt))], collapse = ", "), "\n")

## Check general results
stopifnot("Election general file must exist" = file.exists(election_gen_file))
gen <- arrow::open_dataset(election_gen_file)
cat("Election general:", length(gen$schema$names), "columns\n")

## Check ZFE boundaries
stopifnot("ZFE GeoJSON must exist" = file.exists(zfe_file))
zfe_sf <- sf::st_read(zfe_file, quiet = TRUE)
cat("ZFE boundaries:", nrow(zfe_sf), "features\n")

## Check constituency boundaries
stopifnot("Constituency GeoJSON must exist" = file.exists(circ_file))
circ_sf <- sf::st_read(circ_file, quiet = TRUE)
cat("Constituencies:", nrow(circ_sf), "features\n")

## Check scrutins
stopifnot("Scrutins file must exist" = file.exists(scrutins_file))
scrutins <- readRDS(scrutins_file)
cat("Roll-call votes:", length(scrutins), "legislatures\n")

## Check deputies
stopifnot("Deputies file must exist" = file.exists(deputes_file))
deputes <- readRDS(deputes_file)
cat("Deputy data:", length(deputes$deputes), "deputies\n")

## ZFE timeline
cat("ZFE timeline:", nrow(zfe_timeline), "cities,",
    "Wave 1:", sum(zfe_timeline$wave == 1), ",",
    "Wave 2:", sum(zfe_timeline$wave == 2), "\n")

cat("\n=== FETCH COMPLETE ===\n")
