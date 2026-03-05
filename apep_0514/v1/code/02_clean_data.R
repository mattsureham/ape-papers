##########################################################################
# 02_clean_data.R — Clean and merge data for the cumul des mandats paper
# Paper: The Price of Pork — France's Dual-Mandate Ban
# apep_0514
#
# Produces: ../data/analysis_panel.rds
# Panel of constituency-year observations with fiscal outcomes and treatment
##########################################################################

source("00_packages.R")
library(readxl)

data_dir <- "../data/"

# ============================================================================
# STEP 1: LOAD PRE-BUILT CUMULARD TREATMENT VARIABLE
# ============================================================================
cat("\n=== Step 1: Loading cumulard treatment variable ===\n")

treat <- fread(paste0(data_dir, "constituency_treatment.csv"), encoding = "UTF-8")
treat[, circo_id := paste0(sprintf("%02s", num_deptmt), "-",
                           sprintf("%02d", as.integer(num_circo)))]

cat("  Constituencies:", nrow(treat), "\n")
cat("  Cumulard (deputy-mayors):", sum(treat$is_cumulard_maire), "\n")
cat("  Non-cumulard:", sum(!treat$is_cumulard_maire), "\n")

# ============================================================================
# STEP 2: BUILD COMMUNE-CONSTITUENCY CROSSWALK
# ============================================================================
cat("\n=== Step 2: Building commune-constituency crosswalk ===\n")

cw_raw <- read_excel(paste0(data_dir, "crosswalk_circo_2017.xlsx"))

# Columns: CODE DPT, NOM DPT, CODE COMMUNE, NOM COMMUNE, CODE CIRC LEGISLATIVE
cw_clean <- cw_raw %>%
  rename_with(~ gsub("[^a-zA-Z0-9]", "_", tolower(.x))) %>%
  mutate(
    code_dep = sprintf("%02s", as.character(code_dpt)),
    code_commune_raw = as.character(code_commune),
    num_circo = as.integer(code_circ_legislative),
    code_insee = ifelse(nchar(code_commune_raw) >= 5,
                        code_commune_raw,
                        paste0(code_dep, sprintf("%03d", as.integer(code_commune_raw)))),
    circo_id = paste0(code_dep, "-", sprintf("%02d", num_circo))
  ) %>%
  select(code_insee, code_dep, num_circo, circo_id) %>%
  filter(!is.na(circo_id) & !is.na(num_circo))

cat("  Unique communes:", n_distinct(cw_clean$code_insee), "\n")
cat("  Unique constituencies:", n_distinct(cw_clean$circo_id), "\n")

# Merge crosswalk with treatment
cw_treat <- cw_clean %>%
  left_join(treat %>% select(circo_id, is_cumulard_maire), by = "circo_id")

cat("  Communes with treatment:", sum(!is.na(cw_treat$is_cumulard_maire)), "\n")

# ============================================================================
# STEP 3: LOAD DGFiP COMMUNE BUDGETS 2008-2017
# ============================================================================
cat("\n=== Step 3: Loading DGFiP commune budgets ===\n")

dgfip <- fread(paste0(data_dir, "comptes_communes_2000_2017.csv"),
               encoding = "Latin-1", showProgress = FALSE)

# DGFiP values are in THOUSANDS OF EUROS (milliers d'euros)
dgfip_panel <- dgfip %>%
  filter(annee >= 2008 & annee <= 2017) %>%
  mutate(
    year = as.integer(annee),
    code_insee = depcom
  )

# Convert all integer64 columns to numeric BEFORE selecting
int64_cols <- names(dgfip_panel)[sapply(dgfip_panel, bit64::is.integer64)]
if (length(int64_cols) > 0) {
  cat("  Converting integer64 columns:", paste(int64_cols, collapse = ", "), "\n")
  dgfip_panel <- dgfip_panel %>%
    mutate(across(all_of(int64_cols), as.numeric))
}

dgfip_panel <- dgfip_panel %>%
  select(
    code_insee, year, population,
    produits_total, prod_impots_locaux, prod_autres_impots_taxes, prod_dotation,
    charges_total, charges_personnel,
    invest_emplois_total, invest_empl_equipements, invest_empl_immobilisations,
    invest_ressources_total, invest_ress_subventions, invest_ress_fctva,
    dette_encours_total, dette_annuite,
    produits_fonctionnement_caf, charges_fonctionnement_caf
  ) %>%
  mutate(across(-code_insee, as.numeric))

cat("  DGFiP rows (2008-2017):", nrow(dgfip_panel), "\n")
cat("  Unique communes:", n_distinct(dgfip_panel$code_insee), "\n")
cat("  Years:", paste(sort(unique(dgfip_panel$year)), collapse = ", "), "\n")

# Verify DGFiP units: small commune 01001, pop ~785, produits_total ~478 (thousands)
check_row <- dgfip_panel[dgfip_panel$code_insee == "01001" & dgfip_panel$year == 2017, ]
if (nrow(check_row) > 0) {
  cat("  DGFiP unit check (01001, 2017): pop=", check_row$population,
      " produits=", check_row$produits_total, " → ",
      round(check_row$produits_total / check_row$population, 3),
      " (thousands per capita, i.e. ~",
      round(check_row$produits_total / check_row$population * 1000),
      " euros per capita)\n")
}

# Free memory
rm(dgfip)
gc()

# ============================================================================
# STEP 4: LOAD OFGL COMMUNE BUDGETS — 2020 + 2023 ONLY
# ============================================================================
cat("\n=== Step 4: Loading OFGL commune budgets ===\n")

# OFGL data quality varies dramatically by year:
# - 2017: Full (but DGFiP already covers it)
# - 2018: Only 2,263 communes, 6 agrégats — UNUSABLE
# - 2019: ~35K communes but key agrégats missing — UNUSABLE
# - 2020: ~35K communes, key agrégats present — USABLE
# - 2021: ~35K communes but no "Dépenses d'équipement" — UNUSABLE for investment
# - 2022: ~35K communes but no "Dépenses d'équipement" — UNUSABLE for investment
# - 2023: ~35K communes, key agrégats present — USABLE
#
# We use ONLY 2020 and 2023 from OFGL.
# OFGL values are in ACTUAL EUROS — divide by 1000 to match DGFiP.

ofgl_file <- paste0(data_dir, "ofgl_communes_2017_2024.csv")
stopifnot("OFGL file must exist" = file.exists(ofgl_file))

ofgl_raw <- fread(ofgl_file, sep = ";", encoding = "UTF-8", showProgress = FALSE)
names(ofgl_raw) <- gsub("[^a-zA-Z0-9]", "_", names(ofgl_raw))

cat("  OFGL total rows:", nrow(ofgl_raw), "\n")

# Filter to communes, usable years only (2020, 2023)
usable_years <- c(2020L, 2023L)
ofgl_communes <- ofgl_raw %>%
  filter(Cat_gorie == "Commune" & Exercice %in% usable_years) %>%
  select(
    year = Exercice,
    code_insee = Code_Insee_Collectivit_,
    agregat = Agr_gat,
    montant = Montant,
    population = Population_totale
  )

cat("  OFGL filtered rows (2020+2023):", nrow(ofgl_communes), "\n")
cat("  Communes per year:\n")
for (y in usable_years) {
  cat("    ", y, ":", n_distinct(ofgl_communes$code_insee[ofgl_communes$year == y]), "\n")
}

# Map OFGL agrégats to DGFiP variable names
# Agrégats available in 2020 and 2023:
# "Dépenses d'équipement" → invest_empl_equipements
# "Dépenses d'investissement hors remb" → invest_emplois_total
# "Dépenses de fonctionnement" → charges_total
# "Concours de l'Etat" → prod_dotation
# "Frais de personnel" → charges_personnel
# "Impôts locaux" → prod_impots_locaux
# "Recettes de fonctionnement" → produits_total (only in 2020, partial)
# "Encours de dette" → dette_encours_total (2023 only, partial)

ofgl_wide <- ofgl_communes %>%
  mutate(
    var_name = case_when(
      agregat == "Dépenses de fonctionnement" ~ "charges_total",
      agregat == "Recettes de fonctionnement" ~ "produits_total",
      agregat == "Dépenses d'investissement hors remb" ~ "invest_emplois_total",
      agregat == "Dépenses d'équipement" ~ "invest_empl_equipements",
      agregat == "Encours de dette" ~ "dette_encours_total",
      agregat == "Concours de l'Etat" ~ "prod_dotation",
      agregat == "Frais de personnel" ~ "charges_personnel",
      agregat == "Impôts locaux" ~ "prod_impots_locaux",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(var_name)) %>%
  select(code_insee, year, population, var_name, montant) %>%
  distinct(code_insee, year, var_name, .keep_all = TRUE) %>%
  pivot_wider(names_from = var_name, values_from = montant, values_fn = first) %>%
  # CRITICAL: Convert OFGL from actual euros to thousands of euros
  mutate(across(c(where(is.numeric), -year, -population), ~ . / 1000))

cat("  OFGL wide rows:", nrow(ofgl_wide), "\n")

# Verify OFGL unit conversion
ofgl_check <- ofgl_wide[ofgl_wide$year == 2020 & !is.na(ofgl_wide$charges_total), ]
if (nrow(ofgl_check) > 0) {
  med_charges_pc <- median(ofgl_check$charges_total / pmax(ofgl_check$population, 1), na.rm = TRUE)
  cat("  OFGL unit check (2020): median charges/pop =", round(med_charges_pc, 3),
      " (thousands per capita, i.e. ~", round(med_charges_pc * 1000),
      " euros per capita)\n")
}

rm(ofgl_raw, ofgl_communes)
gc()

# ============================================================================
# STEP 5: COMBINE DGFiP + OFGL INTO UNIFIED PANEL
# ============================================================================
cat("\n=== Step 5: Building unified panel ===\n")

fiscal_cols <- c("code_insee", "year", "population",
                 "produits_total", "prod_impots_locaux", "prod_dotation",
                 "charges_total", "charges_personnel",
                 "invest_emplois_total", "invest_empl_equipements",
                 "invest_ressources_total",
                 "dette_encours_total")

dgfip_sub <- dgfip_panel %>%
  select(any_of(fiscal_cols)) %>%
  mutate(across(-code_insee, as.numeric))

ofgl_sub <- ofgl_wide %>%
  select(any_of(fiscal_cols)) %>%
  mutate(across(-code_insee, as.numeric))

# Stack
budget_panel <- bind_rows(dgfip_sub, ofgl_sub)
cat("  Combined budget panel rows:", nrow(budget_panel), "\n")
cat("  Years:", paste(sort(unique(budget_panel$year)), collapse = ", "), "\n")

# ============================================================================
# STEP 6: MERGE WITH TREATMENT AND AGGREGATE TO CONSTITUENCY-YEAR
# ============================================================================
cat("\n=== Step 6: Merging with treatment and aggregating ===\n")

panel <- budget_panel %>%
  inner_join(cw_treat, by = "code_insee")

cat("  Merged panel rows:", nrow(panel), "\n")
cat("  Unique communes:", n_distinct(panel$code_insee), "\n")
cat("  Treatment distribution:\n")
cat("    Cumulard communes:", sum(panel$is_cumulard_maire == 1, na.rm = TRUE), "\n")
cat("    Non-cumulard communes:", sum(panel$is_cumulard_maire == 0, na.rm = TRUE), "\n")

# Aggregate to constituency-year level
circo_panel <- panel %>%
  filter(!is.na(is_cumulard_maire)) %>%
  group_by(circo_id, year, is_cumulard_maire) %>%
  summarize(
    n_communes = n(),
    total_pop = sum(population, na.rm = TRUE),
    produits_total = sum(produits_total, na.rm = TRUE),
    prod_impots_locaux = sum(prod_impots_locaux, na.rm = TRUE),
    prod_dotation = sum(prod_dotation, na.rm = TRUE),
    charges_total = sum(charges_total, na.rm = TRUE),
    charges_personnel = sum(charges_personnel, na.rm = TRUE),
    invest_emplois_total = sum(invest_emplois_total, na.rm = TRUE),
    invest_empl_equipements = sum(invest_empl_equipements, na.rm = TRUE),
    invest_ressources_total = sum(invest_ressources_total, na.rm = TRUE),
    dette_encours_total = sum(dette_encours_total, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    # Per capita outcomes (thousands of euros per inhabitant)
    invest_pc = invest_emplois_total / pmax(total_pop, 1),
    equip_pc = invest_empl_equipements / pmax(total_pop, 1),
    dotation_pc = prod_dotation / pmax(total_pop, 1),
    charges_pc = charges_total / pmax(total_pop, 1),
    produits_pc = produits_total / pmax(total_pop, 1),
    dette_pc = dette_encours_total / pmax(total_pop, 1),
    invest_rev_pc = invest_ressources_total / pmax(total_pop, 1),
    # Log outcomes
    log_invest_pc = log(pmax(invest_pc, 0.001)),
    log_equip_pc = log(pmax(equip_pc, 0.001)),
    log_dotation_pc = log(pmax(dotation_pc, 0.001)),
    # Treatment timing
    post = as.integer(year >= 2017),
    treated = is_cumulard_maire * post
  )

cat("\n  Constituency-year panel:\n")
cat("    Rows:", nrow(circo_panel), "\n")
cat("    Unique constituencies:", n_distinct(circo_panel$circo_id), "\n")
cat("    Years:", paste(sort(unique(circo_panel$year)), collapse = ", "), "\n")

# Per-year summary to verify units consistency
cat("\n  Per-year medians (invest_pc, charges_pc — thousands per capita):\n")
yr_check <- circo_panel %>%
  group_by(year) %>%
  summarize(
    n = n(),
    med_invest_pc = round(median(invest_pc, na.rm = TRUE), 3),
    med_charges_pc = round(median(charges_pc, na.rm = TRUE), 3),
    med_equip_pc = round(median(equip_pc, na.rm = TRUE), 3),
    .groups = "drop"
  )
print(yr_check, n = 20)

# Verify consistency: DGFiP years should have invest_pc ~0.3-0.6, charges_pc ~0.8-1.2
# OFGL years should be in the same range after /1000 conversion
cat("\n  Treated (cumulard × post):", sum(circo_panel$treated, na.rm = TRUE), "\n")

# Pre-period summary
cat("\n  Summary statistics by treatment group (pre-period average):\n")
pre_summary <- circo_panel %>%
  filter(year < 2017) %>%
  group_by(is_cumulard_maire) %>%
  summarize(
    n_circos = n_distinct(circo_id),
    mean_pop = mean(total_pop, na.rm = TRUE),
    mean_invest_pc = mean(invest_pc, na.rm = TRUE),
    mean_equip_pc = mean(equip_pc, na.rm = TRUE),
    mean_dotation_pc = mean(dotation_pc, na.rm = TRUE),
    mean_charges_pc = mean(charges_pc, na.rm = TRUE),
    mean_dette_pc = mean(dette_pc, na.rm = TRUE),
    .groups = "drop"
  )
print(pre_summary)

# ============================================================================
# STEP 7: ALSO BUILD COMMUNE-LEVEL PANEL (for robustness)
# ============================================================================
cat("\n=== Step 7: Building commune-level panel ===\n")

commune_panel <- panel %>%
  filter(!is.na(is_cumulard_maire) & population > 0) %>%
  mutate(
    invest_pc = invest_emplois_total / population,
    equip_pc = invest_empl_equipements / population,
    dotation_pc = prod_dotation / population,
    charges_pc = charges_total / population,
    produits_pc = produits_total / population,
    dette_pc = dette_encours_total / population,
    log_invest_pc = log(pmax(invest_pc, 0.001)),
    log_equip_pc = log(pmax(equip_pc, 0.001)),
    log_dotation_pc = log(pmax(dotation_pc, 0.001)),
    post = as.integer(year >= 2017),
    treated = is_cumulard_maire * post,
    log_pop = log(population)
  )

cat("  Commune-level panel rows:", nrow(commune_panel), "\n")
cat("  Unique communes:", n_distinct(commune_panel$code_insee), "\n")

# ============================================================================
# SAVE
# ============================================================================
cat("\n=== Saving analysis panels ===\n")

saveRDS(circo_panel, paste0(data_dir, "analysis_panel.rds"))
saveRDS(commune_panel, paste0(data_dir, "commune_panel.rds"))
saveRDS(cw_treat, paste0(data_dir, "crosswalk_treatment.rds"))

cat("  analysis_panel.rds — constituency-year panel\n")
cat("  commune_panel.rds — commune-year panel\n")
cat("  crosswalk_treatment.rds — crosswalk with treatment\n")
cat("\n=== 02_clean_data.R complete ===\n")
