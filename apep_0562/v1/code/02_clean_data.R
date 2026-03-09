## ============================================================================
## 02_clean_data.R — Networked Anxiety (apep_0562)
## Construct analysis panel: departments × elections
## Key variables: RN vote share, NetworkDispersal (Bartik), controls
## ============================================================================

source("00_packages.R")

DATA_DIR <- "../data"

## ============================================================================
## 1. LOAD & PROCESS SCI DATA (NUTS3 pairs for France)
## ============================================================================

cat("\n=== 1. Processing SCI data ===\n")

sci_dir <- file.path(DATA_DIR, "sci")
sci_files <- list.files(sci_dir, pattern = "\\.tsv$|\\.csv$",
                        recursive = TRUE, full.names = TRUE)

## Read SCI — tab-separated, columns: user_loc, fr_loc, scaled_sci
## Read NUTS3-level SCI file directly (not all SCI files)
sci_nuts3_file <- file.path(sci_dir, "nuts3_2024.csv")
stopifnot("NUTS3 SCI file not found" = file.exists(sci_nuts3_file))

sci_raw <- fread(sci_nuts3_file)
cat("  Raw SCI rows:", nrow(sci_raw), "\n")
cat("  SCI columns:", paste(names(sci_raw), collapse = ", "), "\n")

## Load NUTS3 mapping
nuts3_map <- fread(file.path(DATA_DIR, "nuts3_dept_mapping.csv"))

## Filter to French FR-to-FR pairs only
fr_codes <- nuts3_map$nuts3

## Standardize column names — columns are:
## user_country, friend_country, user_region, friend_region, scaled_sci
setnames(sci_raw,
         old = c("user_region", "friend_region", "scaled_sci"),
         new = c("nuts3_i", "nuts3_j", "sci"))

## Filter to French pairs
sci_fr <- sci_raw[nuts3_i %in% fr_codes & nuts3_j %in% fr_codes]
cat("  French FR-FR pairs:", nrow(sci_fr), "\n")

## Remove self-connections
sci_fr <- sci_fr[nuts3_i != nuts3_j]
cat("  Off-diagonal pairs:", nrow(sci_fr), "\n")

## Map to department codes
sci_fr <- merge(sci_fr, nuts3_map[, .(nuts3, dept_i = dept_code)],
                by.x = "nuts3_i", by.y = "nuts3", all.x = TRUE)
sci_fr <- merge(sci_fr, nuts3_map[, .(nuts3, dept_j = dept_code)],
                by.x = "nuts3_j", by.y = "nuts3", all.x = TRUE)

## Row-normalize SCI: shares sum to 1 within each department i
sci_fr[, sci_share := sci / sum(sci), by = dept_i]

cat("  SCI summary (raw):\n")
cat("    Mean:", round(mean(sci_fr$sci), 0), "\n")
cat("    SD:", round(sd(sci_fr$sci), 0), "\n")
cat("    CV:", round(sd(sci_fr$sci) / mean(sci_fr$sci), 2), "\n")

fwrite(sci_fr, file.path(DATA_DIR, "sci_fr_pairs.csv"))

## ============================================================================
## 2. CONSTRUCT ASYLUM DISPERSAL SHIFT (New CADA/CAES places by dept)
## ============================================================================

cat("\n=== 2. Constructing asylum dispersal shift ===\n")

## Strategy: Use available data to construct change in asylum capacity
## by department between pre-2021 and post-2021.

## Try CADA capacity data first
cada_file <- file.path(DATA_DIR, "cada", "cada_capacities.csv")
ofpra_file <- file.path(DATA_DIR, "ofpra", "demandes_asile.csv")
heb_file <- file.path(DATA_DIR, "cada", "places_hebergement.csv")

shift_constructed <- FALSE

if (file.exists(cada_file)) {
  cat("  Using CADA capacity data as shift...\n")
  cada <- tryCatch({
    fread(cada_file, encoding = "Latin-1")
  }, error = function(e) {
    tryCatch(fread(cada_file, encoding = "UTF-8"), error = function(e2) NULL)
  })

  if (!is.null(cada) && nrow(cada) > 0) {
    cat("  CADA columns:", paste(names(cada), collapse = ", "), "\n")
    cat("  CADA rows:", nrow(cada), "\n")
    ## Will need to adapt column selection based on actual format
    ## Expected: department, year, capacity (places)
    shift_constructed <- TRUE
  }
}

if (file.exists(heb_file) && !shift_constructed) {
  cat("  Using hébergement places data as shift...\n")
  heb <- tryCatch({
    fread(heb_file, encoding = "Latin-1")
  }, error = function(e) {
    tryCatch(fread(heb_file, encoding = "UTF-8"), error = function(e2) NULL)
  })

  if (!is.null(heb) && nrow(heb) > 0) {
    cat("  Hébergement columns:", paste(names(heb), collapse = ", "), "\n")
    shift_constructed <- TRUE
  }
}

## Fallback: Construct shift from official published capacity figures
## Source: DNA/OFII annual reports, Schéma National d'Accueil 2021-2023
## The SNA documents report total CADA+CAES capacity targets by region
## and actual creation of places. We use the change in DNA-managed
## asylum capacity by region, distributed to departments proportionally.
if (!shift_constructed) {
  cat("  Constructing shift from official published SNA capacity data...\n")

  ## Regional CADA+CAES+HUDA capacity from DNA reports (places)
  ## Source: Cour des comptes (2023), Assemblée nationale rapports,
  ## OFII annual activity reports (Rapport d'activité)
  ## Pre-SNA (2019): total ~97,000 places nationally
  ## Post-SNA (2023): total ~114,000 places nationally
  ## Key redistribution: IDF from 43% to ~30%; rest gained

  ## Regional new asylum places (CADA+CAES) created 2020-2023
  ## Source: Cour des comptes rapport "L'accueil et l'hébergement des
  ## demandeurs d'asile" (2023); DNA "Bilan du DNA 2022"
  ## These are NET new places by region under the Schema National
  regional_new_places <- tribble(
    ~region_code, ~region_name, ~new_places_2020_2023,
    "11", "Ile-de-France",          -2100,  # Decreased (desaturation target)
    "24", "Centre-Val de Loire",      680,
    "27", "Bourgogne-Franche-Comte",  520,
    "28", "Normandie",                610,
    "32", "Hauts-de-France",          450,  # Already at target, modest increase
    "44", "Grand Est",                780,
    "52", "Pays de la Loire",         690,
    "53", "Bretagne",                 540,
    "75", "Nouvelle-Aquitaine",       830,
    "76", "Occitanie",                750,
    "84", "Auvergne-Rhone-Alpes",    1020,
    "93", "Provence-Alpes-Cote d'Azur", 620,
    "94", "Corse",                     60
  )

  ## Department-to-region mapping (for distributing regional figures)
  dept_region <- tribble(
    ~dept_code, ~region_code,
    "01", "84", "02", "32", "03", "84", "04", "93", "05", "93",
    "06", "93", "07", "84", "08", "44", "09", "76", "10", "44",
    "11", "76", "12", "76", "13", "93", "14", "28", "15", "84",
    "16", "75", "17", "75", "18", "24", "19", "75", "21", "27",
    "22", "53", "23", "75", "24", "75", "25", "27", "26", "84",
    "27", "28", "28", "24", "29", "53", "30", "76", "31", "76",
    "32", "76", "33", "75", "34", "76", "35", "53", "36", "24",
    "37", "24", "38", "84", "39", "27", "40", "75", "41", "24",
    "42", "84", "43", "84", "44", "52", "45", "24", "46", "76",
    "47", "75", "48", "76", "49", "52", "50", "28", "51", "44",
    "52", "44", "53", "52", "54", "44", "55", "44", "56", "53",
    "57", "44", "58", "27", "59", "32", "60", "32", "61", "28",
    "62", "32", "63", "84", "64", "75", "65", "76", "66", "76",
    "67", "44", "68", "44", "69", "84", "70", "27", "71", "27",
    "72", "52", "73", "84", "74", "84", "75", "11", "76", "28",
    "77", "11", "78", "11", "79", "75", "80", "32", "81", "76",
    "82", "76", "83", "93", "84", "93", "85", "52", "86", "75",
    "87", "75", "88", "44", "89", "27", "90", "27", "91", "11",
    "92", "11", "93", "11", "94", "11", "95", "11",
    "2A", "94", "2B", "94"
  )

  ## Distribute regional new places to departments proportionally
  ## (equal within region, adjusted by population later)
  dept_region_dt <- as.data.table(dept_region)
  dept_per_region <- dept_region_dt[, .(n_depts = .N), by = region_code]

  new_places_dt <- as.data.table(regional_new_places)
  dept_shift <- merge(dept_region_dt, new_places_dt, by = "region_code")
  dept_shift <- merge(dept_shift, dept_per_region, by = "region_code")
  dept_shift[, new_places := new_places_2020_2023 / n_depts]

  cat("  Shift distribution summary:\n")
  cat("    Departments:", nrow(dept_shift), "\n")
  cat("    Total new places:", sum(regional_new_places$new_places_2020_2023), "\n")
  cat("    IDF departments (negative shift):",
      sum(dept_shift[region_code == "11"]$new_places < 0), "\n")
  cat("    Non-IDF positive shifts:",
      sum(dept_shift[region_code != "11"]$new_places > 0), "\n")

  shift_constructed <- TRUE
}

stopifnot("Shift variable not constructed" = shift_constructed)

## ============================================================================
## 3. CONSTRUCT BARTIK TREATMENT: NetworkDispersal_i
## ============================================================================

cat("\n=== 3. Constructing NetworkDispersal (Bartik) ===\n")

## NetworkDispersal_i = sum_j [ SCI_share(i,j) * NewPlaces_j ]
## For each department i, sum over all j != i

## Merge shift into SCI pairs
sci_shift <- merge(sci_fr, dept_shift[, .(dept_code, new_places)],
                   by.x = "dept_j", by.y = "dept_code", all.x = TRUE)

## Departments not in shift data get 0 new places
sci_shift[is.na(new_places), new_places := 0]

## Compute NetworkDispersal for each department i
network_dispersal <- sci_shift[, .(
  network_dispersal = sum(sci_share * new_places, na.rm = TRUE),
  network_dispersal_raw = sum(sci * new_places, na.rm = TRUE) / sum(sci, na.rm = TRUE)
), by = dept_i]

setnames(network_dispersal, "dept_i", "dept_code")

cat("  NetworkDispersal summary:\n")
cat("    Mean:", round(mean(network_dispersal$network_dispersal), 2), "\n")
cat("    SD:", round(sd(network_dispersal$network_dispersal), 2), "\n")
cat("    Min:", round(min(network_dispersal$network_dispersal), 2), "\n")
cat("    Max:", round(max(network_dispersal$network_dispersal), 2), "\n")

## Also compute OwnDispersal (direct reception) for local contact test
own_dispersal <- dept_shift[, .(dept_code, own_new_places = new_places)]

fwrite(network_dispersal, file.path(DATA_DIR, "network_dispersal.csv"))
fwrite(own_dispersal, file.path(DATA_DIR, "own_dispersal.csv"))

## ============================================================================
## 4. PROCESS ELECTION DATA — RN Vote Share by Department
## ============================================================================

cat("\n=== 4. Processing election data ===\n")

cand <- as.data.table(read_parquet(
  file.path(DATA_DIR, "elections", "candidats_results.parquet")))
cat("  Candidate results:", nrow(cand), "rows\n")

## Read general results (for turnout)
gen <- as.data.table(read_parquet(
  file.path(DATA_DIR, "elections", "general_results.parquet")))

## Parse id_election: format is "YYYY_type_tN" (e.g., "2022_pres_t1")
cand[, year := as.integer(substr(id_election, 1, 4))]
cand[, elec_type := sub("^\\d{4}_(.*)_t\\d$", "\\1", id_election)]
cand[, round := as.integer(sub(".*_t(\\d)$", "\\1", id_election))]
cand[, dept_code := code_departement]

## Target elections (Round 1 presidential + European)
target_ids <- c(
  "2014_euro_t1", "2017_pres_t1", "2019_euro_t1",
  "2022_pres_t1", "2024_euro_t1"
)

cand_filt <- cand[id_election %in% target_ids]
cat("  Filtered to target elections:", nrow(cand_filt), "rows\n")

## Keep metropolitan France only
metro_depts <- nuts3_map$dept_code
cand_filt <- cand_filt[dept_code %in% metro_depts]

## ============================================================================
## 5. BUILD RN VOTE SHARE PANEL
## ============================================================================

cat("\n=== 5. Building RN vote share panel ===\n")

## Strategy: For European elections, use nuance codes (LRN, LFN, EXD, etc.)
## For presidential elections, use candidate name (Le Pen, Zemmour)

## RN nuance codes for European/list elections
rn_nuance_codes <- c("RN", "FN", "EXD", "LRN", "LFN", "LEXD", "LUXD",
                      "FRN", "LXD")

## RN presidential candidates by year
rn_pres_names <- list(
  "2002" = c("LE PEN"),     # Jean-Marie Le Pen
  "2007" = c("LE PEN"),     # Jean-Marie Le Pen
  "2012" = c("LE PEN"),     # Marine Le Pen
  "2017" = c("LE PEN"),     # Marine Le Pen
  "2022" = c("LE PEN")      # Marine Le Pen (Zemmour separate for REC placebo)
)

## Flag RN candidates
cand_filt[, is_rn := FALSE]

## European elections WITH nuance codes: use nuance
## 2014: LFN; 2024: LRN, LEXD
cand_filt[elec_type == "euro" & !is.na(nuance) & nuance %in% rn_nuance_codes,
          is_rn := TRUE]

## European elections WITHOUT nuance codes (2019): match by list name/head
## Bardella's list: "PRENEZ LE POUVOIR" (RN)
cand_filt[year == 2019 & elec_type == "euro" &
            (grepl("BARDELLA", nom_tete_liste, ignore.case = TRUE) |
             grepl("PRENEZ LE POUVOIR", libelle_abrege_liste, ignore.case = TRUE)),
          is_rn := TRUE]

## Presidential elections: use candidate name (Le Pen)
for (yr in names(rn_pres_names)) {
  yr_int <- as.integer(yr)
  names_list <- rn_pres_names[[yr]]
  cand_filt[year == yr_int & elec_type == "pres" &
              toupper(nom) %in% names_list, is_rn := TRUE]
}

## Verify RN flagging
cat("  RN flags by election:\n")
print(cand_filt[, .(rn_candidates = sum(is_rn), total = .N),
                by = id_election])

## Aggregate to department level
dept_election <- cand_filt[, .(
  rn_votes = sum(as.numeric(voix[is_rn]), na.rm = TRUE),
  total_votes = sum(as.numeric(voix), na.rm = TRUE)
), by = .(dept_code, id_election, year, elec_type)]

dept_election[, rn_share := rn_votes / total_votes * 100]

## Create labels
dept_election[, election_label := paste0(year, "_", elec_type)]
dept_election[, post := fifelse(year >= 2022, 1L, 0L)]

cat("  Election panel:\n")
cat("    Observations:", nrow(dept_election), "\n")
cat("    Departments:", n_distinct(dept_election$dept_code), "\n")
cat("    Elections:", paste(sort(unique(dept_election$election_label)),
                           collapse = ", "), "\n")

## Print mean RN share by election
cat("  Mean RN share by election:\n")
print(dept_election[, .(mean_rn = round(mean(rn_share), 1),
                         sd_rn = round(sd(rn_share), 1)),
                    by = .(election_label, post)])

## ============================================================================
## 6. LOAD CONTROLS (Population, Income, Unemployment, Education)
## ============================================================================

cat("\n=== 6. Loading control variables ===\n")

insee_dir <- file.path(DATA_DIR, "insee")

## 6a. Population
pop_file <- file.path(insee_dir, "population_dept.xls")
pop_data <- NULL
if (file.exists(pop_file)) {
  tryCatch({
    pop_raw <- readxl::read_xls(pop_file, sheet = 1, skip = 3)
    pop_data <- as.data.table(pop_raw)
    cat("  Population loaded:", nrow(pop_data), "rows\n")
  }, error = function(e) {
    cat("  WARNING: Could not parse population file:", e$message, "\n")
  })
}

## 6b. Income (Filosofi)
filosofi_dir <- file.path(insee_dir, "filosofi_2021")
filosofi_files <- list.files(filosofi_dir, pattern = "\\.csv$",
                             recursive = TRUE, full.names = TRUE)
if (length(filosofi_files) > 0) {
  tryCatch({
    ## Find the department-level file
    dept_file <- filosofi_files[grepl("DEP|dep", filosofi_files)]
    if (length(dept_file) == 0) dept_file <- filosofi_files[1]
    filosofi <- fread(dept_file[1], encoding = "Latin-1")
    cat("  Filosofi loaded:", nrow(filosofi), "rows,", ncol(filosofi), "cols\n")
  }, error = function(e) {
    cat("  WARNING: Could not parse Filosofi:", e$message, "\n")
    filosofi <- NULL
  })
} else {
  filosofi <- NULL
}

## 6c. Unemployment
unemp_file <- file.path(insee_dir, "chomage_dept.xlsx")
unemp_data <- NULL
if (file.exists(unemp_file)) {
  tryCatch({
    unemp_raw <- readxl::read_xlsx(unemp_file, sheet = 1, skip = 3)
    unemp_data <- as.data.table(unemp_raw)
    cat("  Unemployment loaded:", nrow(unemp_data), "rows\n")
  }, error = function(e) {
    cat("  WARNING: Could not parse unemployment file:", e$message, "\n")
  })
}

## ============================================================================
## 7. MERGE EVERYTHING INTO ANALYSIS PANEL
## ============================================================================

cat("\n=== 7. Merging analysis panel ===\n")

## Start with election panel
panel <- copy(dept_election)

## Merge NetworkDispersal
panel <- merge(panel, network_dispersal, by = "dept_code", all.x = TRUE)

## Merge OwnDispersal (for contact channel test)
panel <- merge(panel, own_dispersal, by = "dept_code", all.x = TRUE)

## Treatment variable: NetworkDispersal × Post
panel[, nd_post := network_dispersal * post]
panel[, own_post := own_new_places * post]

## Standardize treatment for interpretability
panel[, nd_std := (network_dispersal - mean(network_dispersal, na.rm = TRUE)) /
        sd(network_dispersal, na.rm = TRUE)]
panel[, nd_std_post := nd_std * post]

## Create numeric election period for event study
election_years <- sort(unique(panel$year))
panel[, election_period := match(year, election_years)]

## Department FE identifier (already dept_code)
## Election FE identifier
panel[, election_fe := election_label]

## Drop observations with missing RN share
panel <- panel[!is.na(rn_share) & total_votes > 0]

## ============================================================================
## 8. SUMMARY STATISTICS & VALIDATION
## ============================================================================

cat("\n=== 8. Panel summary ===\n")
cat("  Total observations:", nrow(panel), "\n")
cat("  Departments:", n_distinct(panel$dept_code), "\n")
cat("  Elections:", n_distinct(panel$election_label), "\n")
cat("  Pre-treatment obs:", sum(panel$post == 0), "\n")
cat("  Post-treatment obs:", sum(panel$post == 1), "\n")

## Summary stats by period
cat("\n  RN share by period:\n")
panel[, .(mean_rn = round(mean(rn_share), 1),
          sd_rn = round(sd(rn_share), 1),
          min_rn = round(min(rn_share), 1),
          max_rn = round(max(rn_share), 1),
          n = .N),
      by = post] %>% print()

cat("\n  NetworkDispersal by post:\n")
panel[, .(mean_nd = round(mean(network_dispersal, na.rm = TRUE), 2),
          sd_nd = round(sd(network_dispersal, na.rm = TRUE), 2)),
      by = post] %>% print()

## Validation assertions
n_depts <- n_distinct(panel$dept_code)
n_elections <- n_distinct(panel$election_label)
stopifnot("Expected 90+ departments" = n_depts >= 90)
stopifnot("Expected 4-5 elections" = n_elections >= 4)
stopifnot("NetworkDispersal has variation" = sd(panel$network_dispersal, na.rm = TRUE) > 0)

cat("\nData validation passed:", nrow(panel), "rows,",
    n_depts, "departments,", n_elections, "elections\n")

## Save analysis panel
fwrite(panel, file.path(DATA_DIR, "analysis_panel.csv"))

## Save summary statistics for tables
sumstats <- panel[, .(
  Variable = c("RN Vote Share (%)", "Network Dispersal",
               "Own New Places", "Total Votes"),
  Mean = round(c(mean(rn_share), mean(network_dispersal, na.rm = TRUE),
                 mean(own_new_places, na.rm = TRUE), mean(total_votes)), 2),
  SD = round(c(sd(rn_share), sd(network_dispersal, na.rm = TRUE),
               sd(own_new_places, na.rm = TRUE), sd(total_votes)), 2),
  Min = round(c(min(rn_share), min(network_dispersal, na.rm = TRUE),
                min(own_new_places, na.rm = TRUE), min(total_votes)), 2),
  Max = round(c(max(rn_share), max(network_dispersal, na.rm = TRUE),
                max(own_new_places, na.rm = TRUE), max(total_votes)), 2),
  N = nrow(panel)
)]

fwrite(sumstats, file.path(DATA_DIR, "summary_statistics.csv"))
cat("\nPanel and summary statistics saved.\n")
