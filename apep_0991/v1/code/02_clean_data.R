## 02_clean_data.R — Construct analysis panel
## APEP-0991: EU Landing Obligation

source("00_packages.R")

# ---- Load raw data ----
catches_raw <- readRDS("../data/catches_raw.rds")
landings_raw <- readRDS("../data/landings_raw.rds")
fleet_raw <- readRDS("../data/fleet_raw.rds")

cat("=== Building analysis panel ===\n")

# ---- Species classification into Landing Obligation treatment cohorts ----
# Based on Regulation 1380/2013, Article 15 and subsequent delegated acts

# Pelagic species (treated Jan 2015)
pelagic_codes <- c(
  "HER",   # Herring
  "MAC",   # Mackerel
  "SPR",   # Sprat
  "HOM",   # Horse mackerel
  "JAX",   # Jack mackerels nei
  "PIL",   # European pilchard (sardine)
  "ANE",   # European anchovy
  "WHB",   # Blue whiting
  "BOR",   # Boarfish
  "ARG",   # Argentine
  "SAN"    # Sandeels
)

# Demersal species (treated Jan 2016)
demersal_codes <- c(
  "COD",   # Atlantic cod
  "HAD",   # Haddock
  "SOL",   # Common sole
  "HKE",   # European hake
  "PLE",   # European plaice
  "NEP",   # Norway lobster
  "WHG",   # Whiting
  "POK",   # Saithe
  "POL",   # Pollack
  "LEM",   # Lemon sole
  "WIT",   # Witch flounder
  "MEG",   # Megrim
  "MON",   # Monkfish/Anglerfish
  "ANF",   # Anglerfish
  "USK",   # Tusk
  "LIN",   # Ling
  "BLI",   # Blue ling
  "RNG",   # Roundnose grenadier
  "GHL"    # Greenland halibut
)

# Remaining species (treated Jan 2017 in Baltic/Med, Jan 2019 elsewhere)
# For simplicity, we treat species not in pelagic or demersal as the 2019 cohort
# since the 2017 phase was geographically limited

# ---- EU member states with significant fisheries in Area 27 ----
eu_countries <- c(
  "BE", "DE", "DK", "EE", "ES", "FI", "FR", "IE", "LT", "LV",
  "NL", "PL", "PT", "SE", "UK"  # UK was EU member during most of the period
)

# Non-EU controls (same fishing grounds, no Landing Obligation)
control_countries <- c("NO", "IS")  # Norway, Iceland

all_countries <- c(eu_countries, control_countries)

# ---- Process catches data ----
cat("Processing catches data...\n")

# Inspect column names
cat("  Catches columns:", paste(names(catches_raw), collapse = ", "), "\n")

catches <- catches_raw %>%
  rename(country = geo, year = TIME_PERIOD) %>%
  mutate(
    country = as.character(country),
    species = as.character(species),
    fishreg = as.character(fishreg),
    year = as.numeric(year)
  ) %>%
  filter(
    year >= 2000,
    year <= 2024,
    country %in% all_countries
  ) %>%
  mutate(values = as.numeric(values)) %>%
  filter(!is.na(values), values > 0)

cat(sprintf("  Catches after filtering: %d rows, %d countries, %d species\n",
            nrow(catches), n_distinct(catches$country), n_distinct(catches$species)))

# ---- Assign treatment groups ----
catches <- catches %>%
  mutate(
    treatment_group = case_when(
      species %in% pelagic_codes ~ "pelagic",
      species %in% demersal_codes ~ "demersal",
      TRUE ~ "other"
    ),
    treat_year = case_when(
      treatment_group == "pelagic" ~ 2015L,
      treatment_group == "demersal" ~ 2016L,
      treatment_group == "other" ~ 2019L
    ),
    is_eu = country %in% eu_countries
  )

# ---- Aggregate to country x treatment_group x year ----
cat("Aggregating to country x treatment_group x year...\n")

panel <- catches %>%
  group_by(country, treatment_group, year, treat_year, is_eu) %>%
  summarise(
    total_catch = sum(values, na.rm = TRUE),
    n_species = n_distinct(species),
    .groups = "drop"
  ) %>%
  filter(total_catch > 0) %>%
  mutate(
    log_catch = log(total_catch),
    # Create unit ID for CS-DiD
    unit_id = paste(country, treatment_group, sep = "_")
  )

cat(sprintf("  Panel: %d obs, %d units, years %d-%d\n",
            nrow(panel), n_distinct(panel$unit_id),
            min(panel$year), max(panel$year)))

# ---- Balance check ----
cat("\nBalance check:\n")
panel %>%
  group_by(treatment_group, is_eu) %>%
  summarise(
    n_countries = n_distinct(country),
    n_years = n_distinct(year),
    mean_catch = mean(total_catch),
    .groups = "drop"
  ) %>%
  print()

# ---- Treatment group summary ----
cat("\nTreatment group x cohort summary:\n")
panel %>%
  filter(is_eu) %>%
  group_by(treatment_group, treat_year) %>%
  summarise(
    n_country_years = n(),
    n_countries = n_distinct(country),
    mean_log_catch = mean(log_catch),
    .groups = "drop"
  ) %>%
  print()

# ---- Process landings data for landing-to-catch ratio ----
cat("\nProcessing landings data...\n")

landings <- landings_raw %>%
  rename(country = geo, year = TIME_PERIOD) %>%
  mutate(
    country = as.character(country),
    species = as.character(species),
    year = as.numeric(year)
  ) %>%
  filter(
    year >= 2000,
    year <= 2024,
    country %in% all_countries
  ) %>%
  mutate(landings = as.numeric(values)) %>%
  filter(!is.na(landings), landings > 0) %>%
  mutate(
    treatment_group = case_when(
      species %in% pelagic_codes ~ "pelagic",
      species %in% demersal_codes ~ "demersal",
      TRUE ~ "other"
    )
  ) %>%
  group_by(country, treatment_group, year) %>%
  summarise(
    total_landings = sum(landings, na.rm = TRUE),
    .groups = "drop"
  )

# ---- Merge catches and landings for ratio ----
panel <- panel %>%
  left_join(landings, by = c("country", "treatment_group", "year")) %>%
  mutate(
    landing_ratio = total_landings / total_catch,
    # Cap at 1 (landings can't exceed catches in theory, but data noise)
    landing_ratio = pmin(landing_ratio, 1, na.rm = TRUE)
  )

# ---- Process fleet data ----
if (nrow(fleet_raw) > 0) {
  cat("Processing fleet data...\n")
  cat("  Fleet columns:", paste(names(fleet_raw), collapse = ", "), "\n")

  fleet <- fleet_raw %>%
    rename(country = geo, year = TIME_PERIOD) %>%
    mutate(
      country = as.character(country),
      year = as.numeric(year)
    ) %>%
    filter(
      year >= 2000,
      year <= 2024,
      country %in% all_countries
    ) %>%
    mutate(values = as.numeric(values))

  # Aggregate fleet capacity by country x year
  fleet_panel <- fleet %>%
    group_by(country, year) %>%
    summarise(
      fleet_value = sum(values, na.rm = TRUE),
      .groups = "drop"
    )

  saveRDS(fleet_panel, "../data/fleet_panel.rds")
  cat(sprintf("  Fleet panel: %d obs\n", nrow(fleet_panel)))
}

# ---- Create numeric unit ID for did package ----
unit_map <- panel %>%
  distinct(unit_id) %>%
  mutate(unit_num = row_number())

panel <- panel %>%
  left_join(unit_map, by = "unit_id")

# ---- For non-EU countries, set treat_year = 0 (never-treated) ----
panel <- panel %>%
  mutate(
    first_treat = if_else(is_eu, treat_year, 0L)
  )

# ---- Save clean panel ----
saveRDS(panel, "../data/panel.rds")
cat(sprintf("\n=== Clean panel saved: %d obs, %d units ===\n",
            nrow(panel), n_distinct(panel$unit_id)))

# ---- Summary statistics for paper ----
sumstats <- list(
  n_obs = nrow(panel),
  n_units = n_distinct(panel$unit_id),
  n_eu_countries = n_distinct(panel$country[panel$is_eu]),
  n_control_countries = n_distinct(panel$country[!panel$is_eu]),
  n_years = n_distinct(panel$year),
  year_range = range(panel$year),
  n_treated_units = n_distinct(panel$unit_id[panel$is_eu]),
  treatment_groups = panel %>% filter(is_eu) %>%
    distinct(treatment_group, treat_year) %>% arrange(treat_year)
)
saveRDS(sumstats, "../data/sumstats.rds")

cat("\nSummary statistics:\n")
cat(sprintf("  EU countries: %d\n", sumstats$n_eu_countries))
cat(sprintf("  Control countries: %d\n", sumstats$n_control_countries))
cat(sprintf("  Total units: %d (treated: %d)\n",
            sumstats$n_units, sumstats$n_treated_units))
cat(sprintf("  Years: %d-%d (%d periods)\n",
            sumstats$year_range[1], sumstats$year_range[2], sumstats$n_years))
