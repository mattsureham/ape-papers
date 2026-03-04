## =============================================================================
## 01_fetch_data.R — Validate pre-downloaded election + affidavit data
## Paper: Does Candidate Wealth Buy Development?
## =============================================================================
## Data sources (pre-downloaded via Python):
## 1. assembly_elections.csv — State assembly election results (datameet)
##    Coverage: 1951-2013, all Indian states, candidate-level votes
## 2. mynetas_all.csv — MyNeta/ADR affidavit data (in-rolls/Indian-politician-bios)
##    Coverage: 2004-2015, Lok Sabha + state assembly, candidate-level assets
## 3. loksabha_affidavits_2004_2019.csv — Lok Sabha affidavits (bkamapantula)
##    Coverage: 2004-2019, Lok Sabha only, assets + criminal cases
## =============================================================================

source("00_packages.R")

data_dir <- "../data"

## =============================================================================
## Load and validate Assembly Election Results
## =============================================================================

cat("=== Loading Assembly Election Results ===\n")
ae_file <- file.path(data_dir, "assembly_elections.csv")
stopifnot("assembly_elections.csv not found" = file.exists(ae_file))

assembly <- fread(ae_file, encoding = "UTF-8")
cat("Loaded:", nrow(assembly), "rows,", ncol(assembly), "columns\n")
cat("Columns:", paste(names(assembly), collapse = ", "), "\n")

## Filter to post-2004 elections (affidavit era)
assembly_post2004 <- assembly[as.integer(YEAR) >= 2004]
cat("\nPost-2004 elections:", nrow(assembly_post2004), "candidate-observations\n")
cat("States:", length(unique(assembly_post2004$ST_NAME)), "\n")
cat("Years:", paste(sort(unique(assembly_post2004$YEAR)), collapse = ", "), "\n")
cat("Constituencies:", length(unique(paste(assembly_post2004$ST_NAME, assembly_post2004$AC_NAME))), "\n")

## =============================================================================
## Load and validate MyNeta Affidavit Data
## =============================================================================

cat("\n=== Loading MyNeta Affidavit Data ===\n")
myneta_file <- file.path(data_dir, "mynetas_all.csv")
stopifnot("mynetas_all.csv not found" = file.exists(myneta_file))

mynetas <- fread(myneta_file, encoding = "UTF-8", fill = TRUE)
cat("Loaded:", nrow(mynetas), "rows,", ncol(mynetas), "columns\n")

## Filter to state assembly elections only
mynetas_state <- mynetas[type == "state"]
cat("\nState assembly candidates:", nrow(mynetas_state), "\n")
cat("Election years:", paste(sort(unique(mynetas_state$election_year)), collapse = ", "), "\n")
cat("States:", length(unique(mynetas_state$state)), "\n")

## Check asset columns
asset_cols <- grep("total|asset|liabilit", names(mynetas), ignore.case = TRUE, value = TRUE)
cat("Asset columns:", paste(asset_cols, collapse = ", "), "\n")

## =============================================================================
## Load and validate Lok Sabha Affidavit Data
## =============================================================================

cat("\n=== Loading Lok Sabha Affidavit Data ===\n")
ls_file <- file.path(data_dir, "loksabha_affidavits_2004_2019.csv")
stopifnot("loksabha_affidavits_2004_2019.csv not found" = file.exists(ls_file))

loksabha <- fread(ls_file, encoding = "UTF-8")
cat("Loaded:", nrow(loksabha), "rows,", ncol(loksabha), "columns\n")
cat("Years:", paste(sort(unique(loksabha$Year)), collapse = ", "), "\n")
cat("Columns:", paste(names(loksabha), collapse = ", "), "\n")

## =============================================================================
## DATA VALIDATION (required)
## =============================================================================

cat("\n=== DATA VALIDATION ===\n")

## Assembly elections
n_ae_states <- length(unique(assembly_post2004$ST_NAME))
n_ae_years <- length(unique(assembly_post2004$YEAR))
stopifnot("Expected 20+ states in assembly elections" = n_ae_states >= 20)
stopifnot("Expected 5+ election years post-2004" = n_ae_years >= 5)
cat("Assembly elections: PASSED (", nrow(assembly_post2004), "rows,",
    n_ae_states, "states,", n_ae_years, "years)\n")

## MyNeta state assembly data
n_myneta_state <- nrow(mynetas_state)
stopifnot("Expected 10000+ state assembly candidates in MyNeta" = n_myneta_state >= 10000)
cat("MyNeta state assembly: PASSED (", n_myneta_state, "candidates)\n")

## Lok Sabha affidavits
stopifnot("Expected 20000+ Lok Sabha candidates" = nrow(loksabha) >= 20000)
cat("Lok Sabha affidavits: PASSED (", nrow(loksabha), "candidates)\n")

cat("\n=== Data fetch/validation complete ===\n")
cat("Ready for 02_clean_data.R\n")
