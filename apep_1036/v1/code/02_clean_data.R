## 02_clean_data.R — Build treatment panel and merge with elections
## apep_1036: Tax Office Closures and Far-Right Voting in France

source("00_packages.R")

data_dir <- "../data/"

## =================================================================
## PART 1: Construct treatment variable from BPE vintages
## =================================================================

## --- BPE Evolution 2019 & 2024 (long format, A01G = DRFIP+DDFIP) ---
bpe_evo <- fread(file.path(data_dir, "bpe_evolution",
                            "ds_bpe_evolution_com_2019_2024_geo_2025.csv"),
                  sep = ";")

## GEO may be char or int; ensure 5-char zero-padded commune codes
## Corsica has 2A/2B prefixes (character), rest are numeric
tax_evo <- bpe_evo[FACILITY_TYPE == "A01G"]
tax_evo[, commune := fifelse(
  grepl("[A-Za-z]", GEO),
  as.character(GEO),  # Corsica: already formatted
  formatC(as.integer(as.character(GEO)), width = 5, format = "d", flag = "0")
)]

## Pivot to wide: one row per commune
tax19 <- tax_evo[TIME_PERIOD == 2019 & OBS_VALUE > 0,
                  .(n_offices_2019 = sum(OBS_VALUE)), by = commune]
tax24_evo <- tax_evo[TIME_PERIOD == 2024 & OBS_VALUE > 0,
                      .(n_offices_2024_evo = sum(OBS_VALUE)), by = commune]

cat("2019 (evolution):", nrow(tax19), "communes with tax offices\n")
cat("2024 (evolution):", nrow(tax24_evo), "communes with tax offices\n")

## --- BPE 2021 (geolocated establishments) ---
bpe21_files <- list.files(file.path(data_dir, "bpe21"), pattern = "\\.csv$",
                           full.names = TRUE, recursive = TRUE)
bpe21 <- fread(bpe21_files[1], sep = ";", encoding = "Latin-1")
tax21 <- bpe21[TYPEQU %in% c("A120", "A121"),
               .(n_offices_2021 = .N), by = .(commune = DEPCOM)]
cat("2021 (geolocated):", nrow(tax21), "communes with tax offices\n")

## --- BPE 2024 (geolocated establishments) ---
bpe24 <- as.data.table(arrow::read_parquet(file.path(data_dir, "BPE24.parquet")))
tax24 <- bpe24[TYPEQU %in% c("A120", "A121"),
               .(n_offices_2024 = .N), by = .(commune = DEPCOM)]
cat("2024 (geolocated):", nrow(tax24), "communes with tax offices\n")

## --- Merge to create treatment panel ---
all_communes <- unique(c(tax19$commune, tax21$commune, tax24$commune))
panel <- data.table(commune = all_communes)
panel <- merge(panel, tax19, by = "commune", all.x = TRUE)
panel <- merge(panel, tax21, by = "commune", all.x = TRUE)
panel <- merge(panel, tax24, by = "commune", all.x = TRUE)
panel[is.na(n_offices_2019), n_offices_2019 := 0]
panel[is.na(n_offices_2021), n_offices_2021 := 0]
panel[is.na(n_offices_2024), n_offices_2024 := 0]

## Treatment groups
panel[, treatment_group := fcase(
  n_offices_2019 > 0 & n_offices_2021 == 0, "early_closure",   # lost 2019-2021
  n_offices_2019 > 0 & n_offices_2021 > 0 & n_offices_2024 == 0, "late_closure",  # lost 2021-2024
  n_offices_2024 > 0, "retained",
  n_offices_2019 == 0 & n_offices_2021 > 0 & n_offices_2024 == 0, "late_closure",  # appeared then lost
  default = "other"
)]

cat("\nTreatment groups:\n")
print(panel[, .N, by = treatment_group][order(-N)])
cat("Total closures:", panel[treatment_group %in% c("early_closure", "late_closure"), .N], "\n")

## =================================================================
## PART 2: Process election data — RN vote share at commune level
## =================================================================

cand <- as.data.table(arrow::read_parquet(file.path(data_dir, "candidats_results.parquet")))
gen  <- as.data.table(arrow::read_parquet(file.path(data_dir, "general_results.parquet")))

## Target elections
elections <- c(
  "2002_pres_t1", "2007_pres_t1", "2012_pres_t1", "2017_pres_t1", "2022_pres_t1",
  "2014_euro_t1", "2019_euro_t1", "2024_euro_t1"
)

cand_sub <- cand[id_election %in% elections]
gen_sub  <- gen[id_election %in% elections]

## Commune code: code_commune already contains the full 5-digit INSEE code
cand_sub[, commune := code_commune]
gen_sub[, commune := code_commune]

## --- Identify RN/FN candidates ---
cand_sub[, is_rn := FALSE]
cand_sub[grepl("pres", id_election) & toupper(nom) == "LE PEN", is_rn := TRUE]
cand_sub[id_election == "2014_euro_t1" & toupper(nuance) == "LFN", is_rn := TRUE]
cand_sub[id_election == "2019_euro_t1" &
           (grepl("BARDELLA", toupper(nom_tete_liste), fixed = TRUE) |
            grepl("PRENEZ LE POUVOIR", toupper(libelle_abrege_liste), fixed = TRUE) |
            grepl("RASSEMBLEMENT NATIONAL", toupper(liste), fixed = TRUE)),
         is_rn := TRUE]
cand_sub[id_election == "2024_euro_t1" & toupper(nuance) == "LRN", is_rn := TRUE]

## Aggregate to commune
rn_votes <- cand_sub[is_rn == TRUE,
                      .(rn_voix = sum(voix, na.rm = TRUE)),
                      by = .(id_election, commune)]
total_votes <- gen_sub[, .(exprimes = sum(exprimes, na.rm = TRUE),
                           inscrits = sum(inscrits, na.rm = TRUE),
                           abstentions = sum(abstentions, na.rm = TRUE)),
                       by = .(id_election, commune)]

elec <- merge(total_votes, rn_votes, by = c("id_election", "commune"), all.x = TRUE)
elec[is.na(rn_voix), rn_voix := 0]
elec[, rn_share := rn_voix / exprimes * 100]
elec[, turnout := (inscrits - abstentions) / inscrits * 100]
elec[, year := as.integer(substr(id_election, 1, 4))]
elec[, election_type := fifelse(grepl("pres", id_election), "presidential", "european")]

## Verify national RN shares
cat("\nRN vote share by election (commune means):\n")
print(elec[, .(mean_rn = round(mean(rn_share, na.rm = TRUE), 1),
               n_communes = .N),
           by = id_election][order(id_election)])

## =================================================================
## PART 3: Build analysis panel
## =================================================================

## Department code: first 2 chars of commune code (or 3 for DOM-TOM)
elec[, dep := substr(commune, 1, 2)]
elec[substr(commune, 1, 2) == "97", dep := substr(commune, 1, 3)]

## Merge treatment
elec <- merge(elec, panel[, .(commune, treatment_group)],
              by = "commune", all.x = TRUE)
elec[is.na(treatment_group), treatment_group := "never"]

## Treatment dummy
elec[, treated := 0L]
elec[treatment_group == "early_closure" & year >= 2022, treated := 1L]
elec[treatment_group == "late_closure" & year >= 2024, treated := 1L]

## CS-DiD cohort
elec[, cohort := fcase(
  treatment_group == "early_closure", 2022L,
  treatment_group == "late_closure", 2024L,
  default = 0L
)]

## Primary sample: communes in the tax-office universe
analysis <- elec[treatment_group %in% c("early_closure", "late_closure", "retained")]

## Expanded: add "never" communes for robustness
analysis_exp <- elec[treatment_group %in%
                       c("early_closure", "late_closure", "retained", "never")]

cat("\n=== PRIMARY ANALYSIS PANEL ===\n")
cat("Communes:", uniqueN(analysis$commune), "\n")
cat("Elections:", length(unique(analysis$id_election)), "\n")
cat("Observations:", nrow(analysis), "\n")
cat("Treatment groups:\n")
print(analysis[, .(n_communes = uniqueN(commune)), by = treatment_group])
cat("\nMean RN share by group × period:\n")
print(analysis[, .(mean_rn = round(mean(rn_share, na.rm = TRUE), 1)),
               by = .(treatment_group, year)][order(treatment_group, year)])

## Save
fwrite(analysis, file.path(data_dir, "analysis_panel.csv"))
fwrite(analysis_exp, file.path(data_dir, "analysis_panel_expanded.csv"))
fwrite(panel, file.path(data_dir, "treatment_panel.csv"))
cat("\n02_clean_data.R complete.\n")
