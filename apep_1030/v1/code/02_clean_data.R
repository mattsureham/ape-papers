## 02_clean_data.R — Construct analysis panel
## apep_1030: EU Deposit Return Schemes and Packaging Waste Recycling

source("00_packages.R")

# ---------------------------------------------------------------
# Load raw data
# ---------------------------------------------------------------
cei_raw   <- readRDS("../data/cei_wm020_raw.rds")
drs_dates <- readRDS("../data/drs_dates.rds")

# ---------------------------------------------------------------
# 1. Clean recycling rate data (cei_wm020)
# ---------------------------------------------------------------
cat("=== Cleaning cei_wm020 ===\n")
cat("  Columns:", paste(names(cei_raw), collapse = ", "), "\n")
cat("  Waste codes:", paste(sort(unique(cei_raw$waste)), collapse = ", "), "\n")

# Waste code mapping (from Eurostat):
# W1501     = Packaging (total)
# W150101   = Paper and cardboard packaging
# W150102   = Plastic packaging
# W150103   = Wooden packaging
# W150104   = Metallic packaging
# W150107   = Glass packaging

# EU-27 + EEA country codes (2-letter)
eu_eea <- c("AT", "BE", "BG", "CY", "CZ", "DE", "DK", "EE", "EL", "ES",
            "FI", "FR", "HR", "HU", "IE", "IT", "LT", "LU", "LV", "MT",
            "NL", "PL", "PT", "RO", "SE", "SI", "SK",
            "NO", "IS", "LI")

# Filter to country-level, individual material types
recycling <- cei_raw %>%
  filter(geo %in% eu_eea) %>%
  rename(year = TIME_PERIOD, recycle_rate = values) %>%
  select(geo, waste, year, recycle_rate) %>%
  filter(!is.na(recycle_rate))

cat(sprintf("  Recycling rates: %d obs, %d countries, years %.0f-%.0f\n",
            nrow(recycling), n_distinct(recycling$geo),
            min(recycling$year), max(recycling$year)))

# ---------------------------------------------------------------
# 2. Map waste codes to material labels
# ---------------------------------------------------------------
recycling <- recycling %>%
  mutate(
    material = case_when(
      waste == "W150104" ~ "Metal",
      waste == "W150102" ~ "Plastic",
      waste == "W150107" ~ "Glass",
      waste == "W150101" ~ "Paper",
      waste == "W150103" ~ "Wood",
      waste == "W1501"   ~ "Total",
      TRUE               ~ NA_character_
    )
  ) %>%
  filter(!is.na(material))

cat("  Materials:", paste(sort(unique(recycling$material)), collapse = ", "), "\n")
cat("  Obs per material:\n")
recycling %>% count(material) %>% print()

# ---------------------------------------------------------------
# 3. Merge DRS treatment
# ---------------------------------------------------------------
cat("\n=== Constructing treatment variables ===\n")

yr_min <- min(recycling$year)
yr_max <- max(recycling$year)
cat(sprintf("  Data range: %.0f to %.0f\n", yr_min, yr_max))

recycling <- recycling %>%
  left_join(drs_dates %>% select(geo, drs_year, deposit_eur), by = "geo") %>%
  mutate(
    drs_adopted = ifelse(!is.na(drs_year) & year >= drs_year, 1L, 0L),
    first_treat = case_when(
      is.na(drs_year)        ~ 0L,
      drs_year > yr_max      ~ 0L,
      drs_year < yr_min      ~ NA_integer_,
      TRUE                   ~ as.integer(drs_year)
    ),
    drs_group = case_when(
      is.na(drs_year)        ~ "Never DRS",
      drs_year > yr_max      ~ "Not yet (post-data)",
      drs_year < yr_min      ~ "Always DRS",
      TRUE                   ~ paste0("DRS ", drs_year)
    )
  )

cat("  Treatment groups:\n")
recycling %>% distinct(geo, drs_group) %>% count(drs_group) %>% print()

# ---------------------------------------------------------------
# 4. Define targeted materials
# ---------------------------------------------------------------
recycling <- recycling %>%
  mutate(
    targeted = case_when(
      material %in% c("Plastic", "Metal") ~ 1L,
      material %in% c("Paper", "Wood")    ~ 0L,
      TRUE                                ~ NA_integer_
    )
  )

cat("\n  Material targeting:\n")
recycling %>% distinct(material, targeted) %>% arrange(material) %>% print()

# ---------------------------------------------------------------
# 5. Create numeric IDs
# ---------------------------------------------------------------
recycling <- recycling %>%
  mutate(
    geo_id = as.integer(factor(geo)),
    mat_id = as.integer(factor(material)),
    panel_id = as.integer(factor(paste(geo, material)))
  )

# ---------------------------------------------------------------
# 6. Summary statistics
# ---------------------------------------------------------------
cat("\n=== Summary Statistics ===\n")
recycling %>%
  filter(!is.na(recycle_rate)) %>%
  summarise(
    n_obs = n(),
    n_countries = n_distinct(geo),
    n_materials = n_distinct(material),
    n_years = n_distinct(year),
    mean_rate = round(mean(recycle_rate), 1),
    sd_rate = round(sd(recycle_rate), 1),
    min_rate = round(min(recycle_rate), 1),
    max_rate = round(max(recycle_rate), 1)
  ) %>% print()

cat("\n  By DRS status (targeted materials):\n")
recycling %>%
  filter(targeted == 1, !is.na(recycle_rate)) %>%
  group_by(drs_adopted) %>%
  summarise(n = n(), mean_rate = round(mean(recycle_rate), 1),
            sd_rate = round(sd(recycle_rate), 1), .groups = "drop") %>%
  print()

# ---------------------------------------------------------------
# 7. Save
# ---------------------------------------------------------------
saveRDS(recycling, "../data/analysis_panel.rds")
cat(sprintf("\nSaved analysis panel: %d observations\n", nrow(recycling)))

sumstats <- recycling %>%
  filter(material != "Total") %>%
  group_by(material) %>%
  summarise(N = n(), Mean = round(mean(recycle_rate, na.rm = TRUE), 1),
            SD = round(sd(recycle_rate, na.rm = TRUE), 1),
            Min = round(min(recycle_rate, na.rm = TRUE), 1),
            Max = round(max(recycle_rate, na.rm = TRUE), 1), .groups = "drop")
saveRDS(sumstats, "../data/summary_stats.rds")
print(sumstats)
