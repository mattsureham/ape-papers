# 02_clean_data.R — Clean and merge datasets for apep_0934
source("00_packages.R")

data_dir <- "../data"

# ============================================================================
# 0. MUNICIPALITY CROSSWALK (name → code)
# ============================================================================
cat("=== Loading municipality crosswalk ===\n")
crosswalk_raw <- jsonlite::fromJSON(file.path(data_dir, "muni_crosswalk.json"))
muni_xwalk <- data.frame(
  muni_name = names(crosswalk_raw),
  muni_code = as.character(as.integer(unlist(crosswalk_raw))),
  stringsAsFactors = FALSE
)
# Remove aggregate entries (regions, national)
muni_xwalk <- muni_xwalk %>%
  filter(!grepl("^(Hele|Region |Landsdel )", muni_name),
         nchar(muni_code) >= 2)
cat(sprintf("  Crosswalk: %d municipalities\n", nrow(muni_xwalk)))

# ============================================================================
# 1. WIND CAPACITY — construct treatment variables
# ============================================================================
cat("\n=== Processing wind capacity data ===\n")

wind <- readRDS(file.path(data_dir, "wind_capacity.rds"))

# Aggregate to annual (use January of each year as snapshot)
wind_annual <- wind %>%
  filter(month(month) == 1) %>%
  select(municipality_no, year, onshore_wind_mw, n_onshore_turbines,
         solar_mw, offshore_wind_mw)

cat(sprintf("  Annual wind obs: %d (%d munis × %d years)\n",
            nrow(wind_annual), n_distinct(wind_annual$municipality_no),
            n_distinct(wind_annual$year)))

# Construct treatment variables
wind_annual <- wind_annual %>%
  group_by(municipality_no) %>%
  arrange(year) %>%
  mutate(
    has_onshore_wind = onshore_wind_mw > 0,
    delta_wind_mw = onshore_wind_mw - lag(onshore_wind_mw),
    delta_turbines = n_onshore_turbines - lag(n_onshore_turbines),
    new_install = !is.na(delta_wind_mw) & delta_wind_mw > 0 & !is.na(delta_turbines) & delta_turbines > 0
  ) %>%
  ungroup()

# Municipality-level treatment classification
muni_treatment <- wind_annual %>%
  group_by(municipality_no) %>%
  summarize(
    wind_2016 = first(onshore_wind_mw[year == 2016]),
    wind_2020 = first(onshore_wind_mw[year == 2020]),
    wind_latest = last(onshore_wind_mw),
    total_new_mw_2016_2020 = sum(pmax(delta_wind_mw[year >= 2017 & year <= 2020], 0), na.rm = TRUE),
    total_new_mw_post_2020 = sum(pmax(delta_wind_mw[year > 2020], 0), na.rm = TRUE),
    n_new_turbines_2016_2020 = sum(pmax(delta_turbines[year >= 2017 & year <= 2020], 0), na.rm = TRUE),
    first_new_install = {
      yrs <- year[!is.na(new_install) & new_install & year <= 2020]
      if (length(yrs) > 0) min(yrs) else NA_integer_
    },
    .groups = "drop"
  ) %>%
  mutate(
    treatment_group = case_when(
      total_new_mw_2016_2020 > 0 ~ "newly_treated",
      wind_2016 > 0 ~ "always_treated",
      total_new_mw_post_2020 > 0 ~ "post_policy",
      TRUE ~ "never_treated"
    )
  )

cat("\nTreatment groups:\n")
print(table(muni_treatment$treatment_group))
cat(sprintf("\nNew installs during køberetsordning (2017-2020): %d munis, %.1f MW\n",
            sum(muni_treatment$treatment_group == "newly_treated"),
            sum(muni_treatment$total_new_mw_2016_2020)))

saveRDS(wind_annual, file.path(data_dir, "wind_annual_clean.rds"))
saveRDS(muni_treatment, file.path(data_dir, "muni_treatment.rds"))

# ============================================================================
# 2. PROPERTY VALUES — municipality × year panel
# ============================================================================
cat("\n=== Processing property value data ===\n")

ejd <- readRDS(file.path(data_dir, "ejdfoe1_raw.rds"))

# Join with crosswalk using municipality name
ejd_clean <- ejd %>%
  filter(BOPKOM != "Hele landet", !grepl("^Region ", BOPKOM)) %>%
  left_join(muni_xwalk, by = c("BOPKOM" = "muni_name")) %>%
  mutate(
    municipality_no = muni_code,
    year = as.integer(TID),
    avg_property_value = as.numeric(gsub("[^0-9.-]", "", INDHOLD))
  ) %>%
  filter(!is.na(avg_property_value), !is.na(municipality_no)) %>%
  select(municipality_no, municipality_name = BOPKOM, year, avg_property_value)

cat(sprintf("  Property value obs: %d (%d munis × up to %d years)\n",
            nrow(ejd_clean), n_distinct(ejd_clean$municipality_no),
            n_distinct(ejd_clean$year)))
cat(sprintf("  Year range: %d - %d\n", min(ejd_clean$year), max(ejd_clean$year)))

saveRDS(ejd_clean, file.path(data_dir, "property_clean.rds"))

# ============================================================================
# 3. ELECTION DATA — green party vote share
# ============================================================================
cat("\n=== Processing election data ===\n")

elec_full <- readRDS(file.path(data_dir, "elections_full.rds"))

elec <- elec_full %>%
  filter(OMRÅDE != "Hele landet", !grepl("^Region ", OMRÅDE)) %>%
  left_join(muni_xwalk, by = c("OMRÅDE" = "muni_name")) %>%
  mutate(
    municipality_no = muni_code,
    year = as.integer(TID),
    value = as.numeric(gsub("[^0-9.-]", "", INDHOLD))
  ) %>%
  filter(!is.na(value), !is.na(municipality_no))

# Green parties: SF (F), Alternativet (Å), Enhedslisten (Ø)
green_parties <- c("Socialistisk Folkeparti",
                   "Alternativet",
                   "Enhedslisten - De Rød-Grønne")

total_votes <- elec %>%
  filter(STEMMER == "Gyldige stemmer") %>%
  group_by(municipality_no, year) %>%
  summarize(total_votes = sum(value, na.rm = TRUE), .groups = "drop")

green_votes <- elec %>%
  filter(STEMMER == "Gyldige stemmer", PARTI %in% green_parties) %>%
  group_by(municipality_no, year) %>%
  summarize(green_votes = sum(value, na.rm = TRUE), .groups = "drop")

election_panel <- total_votes %>%
  left_join(green_votes, by = c("municipality_no", "year")) %>%
  mutate(
    green_votes = ifelse(is.na(green_votes), 0, green_votes),
    green_share = green_votes / total_votes * 100
  )

cat(sprintf("  Election obs: %d (%d munis × %d elections)\n",
            nrow(election_panel), n_distinct(election_panel$municipality_no),
            n_distinct(election_panel$year)))
cat(sprintf("  Elections: %s\n", paste(sort(unique(election_panel$year)), collapse = ", ")))

saveRDS(election_panel, file.path(data_dir, "election_clean.rds"))

# ============================================================================
# 4. POPULATION — clean
# ============================================================================
cat("\n=== Processing population data ===\n")

pop <- readRDS(file.path(data_dir, "population_raw.rds"))

pop_clean <- pop %>%
  filter(OMRÅDE != "Hele landet", !grepl("^(Region |All )", OMRÅDE)) %>%
  left_join(muni_xwalk, by = c("OMRÅDE" = "muni_name")) %>%
  mutate(
    municipality_no = muni_code,
    year = as.integer(str_extract(TID, "^\\d{4}")),
    quarter = as.integer(str_extract(TID, "\\d$")),
    population = as.numeric(gsub("[^0-9.-]", "", INDHOLD))
  ) %>%
  filter(!is.na(population), !is.na(municipality_no), quarter == 1) %>%
  select(municipality_no, year, population)

# Remove duplicates (if any)
pop_clean <- pop_clean %>%
  group_by(municipality_no, year) %>%
  summarize(population = first(population), .groups = "drop")

cat(sprintf("  Population obs: %d\n", nrow(pop_clean)))
saveRDS(pop_clean, file.path(data_dir, "population_clean.rds"))

# ============================================================================
# 5. INCOME — clean
# ============================================================================
cat("\n=== Processing income data ===\n")

inc <- readRDS(file.path(data_dir, "income_raw.rds"))

inc_clean <- inc %>%
  filter(OMRÅDE != "Hele landet", !grepl("^(Region |Landsdel )", OMRÅDE)) %>%
  left_join(muni_xwalk, by = c("OMRÅDE" = "muni_name")) %>%
  mutate(
    municipality_no = muni_code,
    year = as.integer(TID),
    avg_income = as.numeric(gsub("[^0-9.-]", "", INDHOLD))
  ) %>%
  filter(!is.na(avg_income), !is.na(municipality_no)) %>%
  select(municipality_no, year, avg_income)

cat(sprintf("  Income obs: %d\n", nrow(inc_clean)))
saveRDS(inc_clean, file.path(data_dir, "income_clean.rds"))

# ============================================================================
# 6. MERGE INTO ANALYSIS PANEL
# ============================================================================
cat("\n=== Building analysis panel ===\n")

panel <- ejd_clean %>%
  left_join(pop_clean, by = c("municipality_no", "year")) %>%
  left_join(inc_clean, by = c("municipality_no", "year")) %>%
  left_join(muni_treatment %>%
              select(municipality_no, treatment_group, first_new_install,
                     total_new_mw_2016_2020, wind_2016),
            by = "municipality_no") %>%
  left_join(wind_annual %>%
              select(municipality_no, year, onshore_wind_mw, n_onshore_turbines),
            by = c("municipality_no", "year"))

# DiD treatment indicator
panel <- panel %>%
  mutate(
    log_property = log(avg_property_value),
    log_income = ifelse(avg_income > 0, log(avg_income), NA_real_),
    log_pop = ifelse(population > 0, log(population), NA_real_),
    post_treatment = ifelse(!is.na(first_new_install) & year >= first_new_install, 1L, 0L),
    treatment_intensity = ifelse(post_treatment == 1, total_new_mw_2016_2020, 0),
    # For CS-DiD: cohort = first treatment year
    cohort = ifelse(treatment_group == "newly_treated", first_new_install, 0L),
    # Restrict sample: drop "post_policy" (only 1 muni) and "always_treated"
    # for clean DiD (newly_treated vs never_treated)
    in_did_sample = treatment_group %in% c("newly_treated", "never_treated")
  )

cat(sprintf("  Panel: %d obs, %d munis, %d years\n",
            nrow(panel), n_distinct(panel$municipality_no), n_distinct(panel$year)))
cat(sprintf("  DiD sample (newly vs never treated): %d obs, %d munis\n",
            sum(panel$in_did_sample), n_distinct(panel$municipality_no[panel$in_did_sample])))

# Treatment summary in DiD sample
did_sample <- panel %>% filter(in_did_sample, year == 2020)
cat(sprintf("  Treated: %d, Control: %d\n",
            sum(did_sample$treatment_group == "newly_treated"),
            sum(did_sample$treatment_group == "never_treated")))

saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))

# Election panel with treatment
election_merged <- election_panel %>%
  left_join(muni_treatment %>%
              select(municipality_no, treatment_group, first_new_install,
                     total_new_mw_2016_2020, wind_2016),
            by = "municipality_no") %>%
  mutate(
    post_treatment = ifelse(!is.na(first_new_install) & year >= first_new_install, 1L, 0L),
    in_did_sample = treatment_group %in% c("newly_treated", "never_treated")
  )

saveRDS(election_merged, file.path(data_dir, "election_panel.rds"))

cat("\n=== Data cleaning complete ===\n")
