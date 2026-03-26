# 02_clean_data.R — Build analysis panels from raw data
# Czech EET and Business Dynamics (apep_0989)

source("00_packages.R")

# ===================================================================
# PANEL 1: Country × NACE sector × year (Eurostat SBS)
# Main analysis: Enterprise counts, births, deaths
# ===================================================================
cat("=== Building Eurostat enterprise panel ===\n")

# Combine all SBS tables (industry, services, construction, trade)
sbs_ind <- readRDS("../data/eurostat_sbs_na_ind_r2.rds")
sbs_svc <- readRDS("../data/eurostat_sbs_na_1a_se_r2.rds")
sbs_con <- readRDS("../data/eurostat_sbs_na_con_r2.rds")
sbs_trd <- readRDS("../data/eurostat_sbs_na_dt_r2.rds")

# Stack all SBS data
sbs_all <- bind_rows(
  mutate(sbs_ind, source = "industry"),
  mutate(sbs_svc, source = "services"),
  mutate(sbs_con, source = "construction"),
  mutate(sbs_trd, source = "trade")
)
cat("Total SBS rows:", nrow(sbs_all), "\n")
cat("Columns:", paste(names(sbs_all), collapse = ", "), "\n")
cat("Unique countries:", paste(unique(sbs_all$geo), collapse = ", "), "\n")
cat("Indicators:", paste(unique(sbs_all$indic_sb), collapse = ", "), "\n")

# Check available NACE sections
cat("NACE codes:\n")
print(sort(unique(sbs_all$nace_r2)))
cat("Year range:", range(sbs_all$time, na.rm = TRUE), "\n")

# Extract enterprise count indicator (V11110 = number of enterprises)
enterprises <- sbs_all %>%
  filter(indic_sb == "V11110") %>%
  select(geo, nace_r2, year = time, n_enterprises = values) %>%
  filter(!is.na(n_enterprises))

cat("\nEnterprise count data:\n")
cat("  Rows:", nrow(enterprises), "\n")
cat("  Countries:", paste(unique(enterprises$geo), collapse = ", "), "\n")
cat("  NACE sections:", paste(sort(unique(enterprises$nace_r2)), collapse = ", "), "\n")
cat("  Year range:", range(enterprises$year), "\n")

# Map NACE sections to EET phases (Czech Republic only)
# Phase 1 (Dec 2016 -> annual = 2017): I (Accommodation & food)
# Phase 2 (Mar 2017 -> annual = 2017): G (Wholesale & retail)
# Phase 3 (Mar 2018 -> annual = 2018): H (Transport), M (Professional), A (Agriculture)
# Phase 4 (Jun 2018 -> annual = 2018): C (Manufacturing)
# Non-EET sectors: B, D, E, F, J, K, L, N, O, P, Q, R, S, T, U

eet_phases <- data.frame(
  nace_r2 = c("I", "G", "H", "M", "A", "C"),
  eet_phase = c(1, 2, 3, 3, 3, 4),
  treatment_year = c(2017, 2017, 2018, 2018, 2018, 2018),
  stringsAsFactors = FALSE
)

# Focus on NACE sections present in EET and a few control sectors
# Keep only single-letter NACE codes (sections, not divisions)
eet_sectors <- c("I", "G", "H", "M", "A", "C")
control_sectors <- c("F", "J", "K", "L", "N")  # Never covered by EET
all_sectors <- c(eet_sectors, control_sectors)

panel <- enterprises %>%
  filter(nace_r2 %in% all_sectors,
         year >= 2008, year <= 2020) %>%
  left_join(eet_phases, by = "nace_r2") %>%
  mutate(
    # Treatment = 1 if CZ sector AND post-phase year
    treated = ifelse(geo == "CZ" & !is.na(treatment_year) & year >= treatment_year, 1, 0),
    # Treatment cohort for CS-DiD
    cohort_year = ifelse(geo == "CZ" & !is.na(treatment_year), treatment_year, Inf),
    # Unit ID = country × sector
    unit_id = paste(geo, nace_r2, sep = "_"),
    # Log outcome
    ln_enterprises = log(n_enterprises)
  )

cat("\n--- Main analysis panel ---\n")
cat("Observations:", nrow(panel), "\n")
cat("Units:", n_distinct(panel$unit_id), "\n")
cat("Years:", range(panel$year), "\n")
cat("Treated CZ-sector-years:", sum(panel$treated), "\n")
cat("Control observations:", sum(panel$treated == 0), "\n")

# Treatment cohort summary
cat("\nTreatment cohorts:\n")
panel %>%
  filter(geo == "CZ", !is.na(treatment_year)) %>%
  group_by(nace_r2, eet_phase, treatment_year) %>%
  summarize(n_obs = n(), .groups = "drop") %>%
  print()

# ===================================================================
# PANEL 2: Business demography (births/deaths) by sector
# ===================================================================
cat("\n=== Building business demography panel ===\n")

bd_raw <- readRDS("../data/eurostat_demography_raw.rds")
cat("BD raw rows:", nrow(bd_raw), "\n")
cat("Columns:", paste(names(bd_raw), collapse = ", "), "\n")
cat("Indicators:", paste(unique(bd_raw$indic_sb), collapse = ", "), "\n")
cat("Legal forms:", paste(unique(bd_raw$legal), collapse = ", "), "\n")

# V11910 = enterprise births, V11920 = enterprise deaths
cat("BD columns available:", paste(names(bd_raw), collapse = ", "), "\n")
# Column is leg_form, not legal
bd_panel <- bd_raw %>%
  filter(indic_sb %in% c("V11910", "V11920"),
         nace_r2 %in% all_sectors) %>%
  select(geo, nace_r2, year = time, indic_sb, leg_form, values) %>%
  filter(!is.na(values)) %>%
  pivot_wider(names_from = indic_sb, values_from = values,
              values_fn = sum) %>%
  rename(births = V11910, deaths = V11920) %>%
  left_join(eet_phases, by = "nace_r2") %>%
  mutate(
    treated = ifelse(geo == "CZ" & !is.na(treatment_year) & year >= treatment_year, 1, 0),
    unit_id = paste(geo, nace_r2, sep = "_"),
    net_entry = births - deaths
  )

cat("BD panel:", nrow(bd_panel), "rows,", n_distinct(bd_panel$unit_id), "units\n")

# ===================================================================
# PANEL 3: Business demography by size class (for small firm mechanism)
# ===================================================================
cat("\n=== Building size-class demography panel ===\n")
bd_size <- readRDS("../data/eurostat_bd_size.rds")
cat("BD size rows:", nrow(bd_size), "\n")
cat("Size classes:", paste(unique(bd_size$sizeclas), collapse = ", "), "\n")

bd_size_panel <- bd_size %>%
  filter(nace_r2 %in% all_sectors,
         !is.na(values)) %>%
  select(geo, nace_r2, year = time, indic_sb, sizeclas, values) %>%
  pivot_wider(names_from = indic_sb, values_from = values,
              values_fn = sum) %>%
  left_join(eet_phases, by = "nace_r2") %>%
  mutate(
    treated = ifelse(geo == "CZ" & !is.na(treatment_year) & year >= treatment_year, 1, 0),
    unit_id = paste(geo, nace_r2, sizeclas, sep = "_")
  )

cat("Size-class BD panel:", nrow(bd_size_panel), "rows\n")

# ===================================================================
# PANEL 4: VAT revenue by country
# ===================================================================
cat("\n=== Building tax revenue panel ===\n")
tax <- readRDS("../data/eurostat_tax_revenue.rds")
cat("Tax revenue rows:", nrow(tax), "\n")

tax_panel <- tax %>%
  filter(na_item == "D211") %>%  # VAT
  select(geo, year = time, vat_mio_eur = values) %>%
  filter(!is.na(vat_mio_eur)) %>%
  mutate(
    cz_post = ifelse(geo == "CZ" & year >= 2017, 1, 0),
    ln_vat = log(vat_mio_eur)
  )

cat("VAT panel:", nrow(tax_panel), "rows\n")
cat("Countries:", paste(unique(tax_panel$geo), collapse = ", "), "\n")
cat("Years:", range(tax_panel$year), "\n")

# ===================================================================
# PANEL 5: CZSO sector × ORP (2022-2025) for abolition test
# ===================================================================
cat("\n=== Building CZSO abolition panel ===\n")
czso_sector <- readRDS("../data/czso_sector_panel.rds")
cat("CZSO sector panel:", nrow(czso_sector), "rows\n")
cat("Columns:", paste(names(czso_sector), collapse = ", "), "\n")

# Explore the sector codes in CZSO data
cat("\nSector codes (odvetvi_txt):\n")
print(head(unique(czso_sector$odvetvi_txt), 20))
cat("\nTerritory count:", n_distinct(czso_sector$vuzemi_txt), "\n")
cat("\nTime periods:\n")
print(table(czso_sector$casref))

# Clean CZSO data: map Czech sector names to NACE codes
nace_map <- c(
  "Ubytování, stravování a pohostinství" = "I",
  "Velkoobchod a maloobchod; opravy a údržba motorových vozidel" = "G",
  "Doprava a skladování" = "H",
  "Profesní, vědecké a technické činnosti" = "M",
  "Zemědělství, lesnictví, rybářství" = "A",
  "Stavebnictví" = "F",
  "Informační a komunikační činnosti" = "J",
  "Peněžnictví a pojišťovnictví" = "K",
  "Činnosti v oblasti nemovitostí" = "L",
  "Administrativní a podpůrné činnosti" = "N",
  "Zdravotní a sociální péče" = "Q",
  "Vzdělávání" = "P",
  "Kulturní, zábavní a rekreační činnosti" = "R",
  "Ostatní činnosti" = "S",
  "Veřejná správa a obrana; povinné sociální zabezpečení" = "O"
)

# For manufacturing, we need to check if it's in the data
# Czech: "Zpracovatelský průmysl" = C
cat("\nChecking for manufacturing sector:\n")
mfg_check <- unique(czso_sector$odvetvi_txt)[grepl("průmysl|Výrob|Těžba", unique(czso_sector$odvetvi_txt), ignore.case = TRUE)]
cat("Manufacturing-related:", paste(mfg_check, collapse = "; "), "\n")

# Parse quarter from casref
czso_clean <- czso_sector %>%
  filter(!is.na(odvetvi_txt), odvetvi_txt != "Nedefinováno") %>%
  mutate(
    nace_letter = nace_map[odvetvi_txt],
    date = as.Date(casref),
    year = as.integer(format(date, "%Y")),
    quarter = as.integer(format(date, "%m")) / 3
  ) %>%
  filter(!is.na(nace_letter)) %>%
  group_by(nace_letter, vuzemi_kod, vuzemi_txt, year, quarter) %>%
  summarize(n_entities = sum(hodnota, na.rm = TRUE), .groups = "drop") %>%
  left_join(eet_phases, by = c("nace_letter" = "nace_r2"))

# The abolition was January 1, 2023
# Post-abolition indicator
czso_clean <- czso_clean %>%
  mutate(
    post_abolition = ifelse(year >= 2023, 1, 0),
    was_eet_sector = ifelse(!is.na(eet_phase), 1, 0)
  )

cat("CZSO clean panel:", nrow(czso_clean), "rows\n")
cat("Sectors:", paste(sort(unique(czso_clean$nace_letter)), collapse = ", "), "\n")
cat("Year range:", range(czso_clean$year), "\n")

# ===================================================================
# PANEL 6: Quarterly employment (Eurostat)
# ===================================================================
cat("\n=== Building quarterly employment panel ===\n")
emp_raw <- readRDS("../data/eurostat_employment_raw.rds")
cat("Employment raw:", nrow(emp_raw), "\n")
cat("Columns:", paste(names(emp_raw), collapse = ", "), "\n")

emp_panel <- emp_raw %>%
  mutate(
    date = as.Date(time),
    year = as.integer(format(date, "%Y")),
    quarter = as.integer(format(date, "%m")) / 3,
    yq = year + (quarter - 1) / 4
  ) %>%
  filter(year >= 2008, year <= 2024) %>%
  left_join(eet_phases, by = "nace_r2") %>%
  mutate(
    treated = ifelse(geo == "CZ" & !is.na(treatment_year) & yq >= treatment_year, 1, 0),
    unit_id = paste(geo, nace_r2, sep = "_")
  )

cat("Employment panel:", nrow(emp_panel), "rows\n")
cat("Countries:", paste(unique(emp_panel$geo), collapse = ", "), "\n")
cat("Sectors:", paste(unique(emp_panel$nace_r2), collapse = ", "), "\n")

# ===================================================================
# Save all clean panels
# ===================================================================
saveRDS(panel, "../data/panel_enterprises.rds")
saveRDS(bd_panel, "../data/panel_demography.rds")
saveRDS(bd_size_panel, "../data/panel_demography_size.rds")
saveRDS(tax_panel, "../data/panel_vat.rds")
saveRDS(czso_clean, "../data/panel_czso_abolition.rds")
saveRDS(emp_panel, "../data/panel_employment.rds")

# ===================================================================
# Summary statistics for the paper
# ===================================================================
cat("\n====== SUMMARY STATISTICS ======\n")

# Main enterprise panel
cat("\n--- Enterprise Panel (Main Analysis) ---\n")
panel_summ <- panel %>%
  group_by(geo) %>%
  summarize(
    n_obs = n(),
    n_sectors = n_distinct(nace_r2),
    years = paste(range(year), collapse = "-"),
    mean_enterprises = round(mean(n_enterprises, na.rm = TRUE)),
    sd_enterprises = round(sd(n_enterprises, na.rm = TRUE)),
    .groups = "drop"
  )
print(panel_summ)

# Pre/post treatment means for CZ treated sectors
cat("\n--- CZ treated sectors: pre vs post ---\n")
panel %>%
  filter(geo == "CZ", nace_r2 %in% eet_sectors) %>%
  group_by(nace_r2, treated) %>%
  summarize(
    mean_ent = round(mean(n_enterprises)),
    sd_ent = round(sd(n_enterprises)),
    n_years = n(),
    .groups = "drop"
  ) %>%
  print()

cat("\nAll panels saved to data/\n")
