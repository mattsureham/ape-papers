## ============================================================================
## 02_clean_data.R — Construct analysis panel
## Merge SRU carence status with presidential election results
## ============================================================================

source("00_packages.R")

if (!requireNamespace("arrow", quietly = TRUE)) {
  install.packages("arrow", repos = "https://cloud.r-project.org")
}
library(arrow)

DATA_DIR <- "../data"

## ============================================================================
## 1. LOAD SRU DATA
## ============================================================================

cat("\n=== Loading SRU data ===\n")

sru <- fread(file.path(DATA_DIR, "sru/transparence_sru.csv"))
cat("SRU communes:", nrow(sru), "\n")

## Clean commune code (ensure 5-digit, zero-padded)
sru[, code_commune := sprintf("%05s", as.character(code))]

## Define treatment groups:
## carencee = TRUE -> declared carencee in 2017-2019 triennial
## carencee = FALSE -> in deficit but NOT declared carencee
## carencee = NA -> compliant or not applicable
sru[, treatment := fcase(
  carence == TRUE, "carencee",
  carence == FALSE, "deficit_not_carencee",
  default = "compliant"
)]

cat("Treatment distribution:\n")
print(table(sru$treatment, useNA = "always"))

## Keep analysis sample: carencee + deficit_not_carencee
analysis_communes <- sru[treatment %in% c("carencee", "deficit_not_carencee")]
cat("Analysis communes:", nrow(analysis_communes), "\n")

## ============================================================================
## 2. LOAD ELECTION DATA
## ============================================================================

cat("\n=== Loading election data ===\n")

## Load candidate results (all elections, commune level)
cand <- read_parquet(file.path(DATA_DIR, "elections/candidats_results.parquet"))
cand <- as.data.table(cand)

## Filter to presidential first-round elections + 2014 European election
## Adding 2014 European election to increase pre-treatment periods (≥5 required)
pres_t1 <- cand[grepl("_pres_t1$", id_election) | id_election == "2014_euro_t1"]
cat("Election T1 rows:", nrow(pres_t1), "\n")
cat("Elections:", paste(sort(unique(pres_t1$id_election)), collapse = ", "), "\n")

## Extract year from id_election
pres_t1[, year := as.integer(substr(id_election, 1, 4))]

## ============================================================================
## 3. IDENTIFY FN/RN CANDIDATES
## ============================================================================

cat("\n=== Identifying FN/RN candidates ===\n")

## The Front National / Rassemblement National candidates:
## 2002: Jean-Marie LE PEN (FN) - nuance "FN" or "EXD"
## 2007: Jean-Marie LE PEN (FN)
## 2012: Marine LE PEN (FN)
## 2017: Marine LE PEN (FN)
## 2022: Marine LE PEN (RN)

## Check nuance labels
cat("Nuance values by year (selected):\n")
nuances_by_year <- pres_t1[, .(nuances = paste(sort(unique(nuance)), collapse = ", ")),
                           by = year]
print(nuances_by_year)

## Identify FN/RN by candidate name and nuance
## Presidential: LE PEN or FN/RN nuance
## European 2014: LFN nuance (Front National list)
pres_t1[, is_fn_rn := (
  grepl("^LE PEN$", nom, ignore.case = TRUE) |
  nuance %in% c("FN", "RN", "EXD", "LFN")
)]

## Verify FN/RN identification
fn_rn_check <- pres_t1[is_fn_rn == TRUE, .(
  candidates = paste(unique(paste(prenom, nom)), collapse = ", "),
  nuances = paste(unique(nuance), collapse = ", "),
  total_voix = sum(voix, na.rm = TRUE)
), by = year]
cat("\nFN/RN candidates identified:\n")
print(fn_rn_check)

## ============================================================================
## 4. CONSTRUCT COMMUNE-LEVEL ELECTION PANEL
## ============================================================================

cat("\n=== Constructing commune-level panel ===\n")

## code_commune in election data is already the full 5-digit INSEE code (e.g., "01001", "83137")
## Just ensure it's character and trimmed
pres_t1[, code_commune := trimws(as.character(code_commune))]

## Aggregate to commune level: total votes and FN/RN votes
## First, total expressed votes per commune-year
commune_total <- pres_t1[, .(
  total_voix = sum(voix, na.rm = TRUE)
), by = .(year, code_commune)]

## FN/RN votes per commune-year
fn_rn_votes <- pres_t1[is_fn_rn == TRUE, .(
  fn_rn_voix = sum(voix, na.rm = TRUE)
), by = .(year, code_commune)]

## Merge
commune_elections <- merge(commune_total, fn_rn_votes,
                           by = c("year", "code_commune"), all.x = TRUE)
commune_elections[is.na(fn_rn_voix), fn_rn_voix := 0]

## Calculate FN/RN vote share (% of expressed votes)
commune_elections[, fn_rn_pct := fn_rn_voix / total_voix * 100]

cat("Commune-year observations:", nrow(commune_elections), "\n")
cat("Communes per year:\n")
print(commune_elections[, .N, by = year][order(year)])

## ============================================================================
## 5. MERGE ELECTIONS WITH SRU TREATMENT
## ============================================================================

cat("\n=== Merging elections with SRU treatment ===\n")

## Merge on commune code
panel <- merge(commune_elections,
               analysis_communes[, .(code_commune, treatment, tx_2002, tx_2008,
                                     tx_2014, tx_2019, tx_legal, habitants,
                                     taux_majoration, ville)],
               by = "code_commune")

cat("Merged panel rows:", nrow(panel), "\n")
cat("Unique communes in panel:", uniqueN(panel$code_commune), "\n")
cat("Treatment distribution in panel:\n")
print(table(panel$treatment))

## ============================================================================
## 6. ADD CONTROL VARIABLES
## ============================================================================

## Create numeric treatment indicator
panel[, treated := as.integer(treatment == "carencee")]

## Treatment timing: carencee communes treated in 2018 (midpoint of 2017-2019 period)
## The declaration happens DURING the 2017-2019 period, AFTER the 2017 election
panel[, first_treat := fifelse(treated == 1L, 2018L, 0L)]

## Post indicator (2022 is the first election after treatment)
panel[, post := as.integer(year >= 2022)]

## Create commune numeric ID for panel estimation
panel[, commune_id := as.integer(factor(code_commune))]

## Department code (first 2 digits for mainland, handle Corsica)
panel[, dept := substr(code_commune, 1, 2)]
panel[grepl("^2[AB]", code_commune), dept := substr(code_commune, 1, 2)]

## Log population
panel[, log_pop := log(habitants)]

## Housing deficit: gap to legal target
panel[, housing_gap := tx_legal - tx_2019]
panel[housing_gap < 0, housing_gap := 0]

## ============================================================================
## 7. BALANCE CHECKS AND SUMMARY STATISTICS
## ============================================================================

cat("\n=== Balance across treatment groups ===\n")

balance <- panel[year == 2017, .(
  mean_fn_rn = mean(fn_rn_pct, na.rm = TRUE),
  sd_fn_rn = sd(fn_rn_pct, na.rm = TRUE),
  mean_pop = mean(habitants, na.rm = TRUE),
  mean_tx_2014 = mean(tx_2014, na.rm = TRUE),
  mean_housing_gap = mean(housing_gap, na.rm = TRUE),
  n = .N
), by = treatment]

cat("Pre-treatment (2017) balance:\n")
print(balance)

## ============================================================================
## 8. SAVE
## ============================================================================

cat("\n=== Saving analysis panel ===\n")

## Panel for main analysis
fwrite(panel, file.path(DATA_DIR, "analysis_panel.csv"))
cat("Saved analysis_panel.csv:", nrow(panel), "rows,",
    uniqueN(panel$code_commune), "communes,",
    uniqueN(panel$year), "election years\n")

## Summary statistics
cat("\nFN/RN vote share by treatment × year:\n")
summary_stats <- panel[, .(
  mean_fn_rn = round(mean(fn_rn_pct, na.rm = TRUE), 2),
  sd_fn_rn = round(sd(fn_rn_pct, na.rm = TRUE), 2),
  n = .N
), by = .(treatment, year)][order(treatment, year)]
print(summary_stats)

cat("\n=== Data cleaning complete ===\n")
