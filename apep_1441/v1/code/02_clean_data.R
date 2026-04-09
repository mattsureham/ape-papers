# 02_clean_data.R — Construct analysis panel
# APEP-1441: Swiss cantonal minimum wages

source("00_packages.R")

# ============================================================================
# 1. Load and reshape STATENT
# ============================================================================
statent <- read_csv("../data/statent_raw.csv", show_col_types = FALSE)
cat("STATENT loaded:", nrow(statent), "rows\n")

# Standardize canton names to abbreviations
canton_map <- tibble(
  name_pattern = c("Zürich", "Bern", "Luzern", "Uri", "Schwyz", "Obwalden",
                   "Nidwalden", "Glarus", "Zug", "Freiburg|Fribourg", "Solothurn",
                   "Basel-Stadt", "Basel-Landschaft", "Schaffhausen",
                   "Appenzell A", "Appenzell I", "St. Gallen|St.Gallen",
                   "Graubünden", "Aargau", "Thurgau", "Ticino|Tessin",
                   "Vaud|Waadt", "Wallis|Valais", "Neuchâtel|Neuenburg",
                   "Genève|Genf", "Jura"),
  canton = c("ZH", "BE", "LU", "UR", "SZ", "OW", "NW", "GL", "ZG", "FR",
             "SO", "BS", "BL", "SH", "AR", "AI", "SG", "GR", "AG", "TG",
             "TI", "VD", "VS", "NE", "GE", "JU"),
  canton_id = 1:26
)

# Map canton names
statent$canton <- NA_character_
for (i in seq_len(nrow(canton_map))) {
  matches <- grepl(canton_map$name_pattern[i], statent$Kanton, ignore.case = TRUE)
  statent$canton[matches] <- canton_map$canton[i]
}

# Check mapping
unmapped <- sum(is.na(statent$canton))
if (unmapped > 0) {
  cat("WARNING:", unmapped, "rows with unmapped cantons\n")
  cat("Unmapped:", unique(statent$Kanton[is.na(statent$canton)]), "\n")
}
stopifnot(unmapped == 0)

# Extract year
statent$year <- as.integer(statent$Jahr)

# Map NOGA sector codes
statent$noga <- case_when(
  grepl("Total", statent$Wirtschaftsabteilung) ~ "total",
  grepl("^47 ", statent$Wirtschaftsabteilung) ~ "47_retail",
  grepl("^55 ", statent$Wirtschaftsabteilung) ~ "55_accommodation",
  grepl("^56 ", statent$Wirtschaftsabteilung) ~ "56_food_beverage",
  grepl("^81 ", statent$Wirtschaftsabteilung) ~ "81_building_services",
  grepl("^21 ", statent$Wirtschaftsabteilung) ~ "21_pharma",
  grepl("^62 ", statent$Wirtschaftsabteilung) ~ "62_it",
  grepl("^64 ", statent$Wirtschaftsabteilung) ~ "64_finance",
  TRUE ~ "other"
)

# Pivot to wide by measure
panel <- statent %>%
  select(canton, year, noga, measure, value) %>%
  pivot_wider(names_from = measure, values_from = value) %>%
  arrange(canton, noga, year)

cat("Panel dimensions:", nrow(panel), "rows\n")
cat("Cantons:", n_distinct(panel$canton), "\n")
cat("Years:", paste(range(panel$year), collapse = "-"), "\n")
cat("Sectors:", paste(unique(panel$noga), collapse = ", "), "\n")

# ============================================================================
# 2. Treatment assignment
# ============================================================================
# Treatment years (year the minimum wage took effect)
treatment_years <- c(
  "NE" = 2017,  # Neuchâtel: CHF 20.08, August 2017
  "JU" = 2018,  # Jura: CHF 20.00, January 2018
  "GE" = 2020,  # Geneva: CHF 23.00, November 2020
  "TI" = 2021,  # Ticino: CHF 19.00, December 2021
  "BS" = 2022   # Basel-Stadt: CHF 21.00, July 2022
)

# Minimum wage levels (CHF/hr at adoption)
mw_levels <- c("NE" = 20.08, "JU" = 20.00, "GE" = 23.00, "TI" = 19.00, "BS" = 21.00)

panel <- panel %>%
  mutate(
    treated_canton = canton %in% names(treatment_years),
    first_treat = ifelse(treated_canton, treatment_years[canton], 0),
    post = ifelse(treated_canton, as.integer(year >= first_treat), 0L),
    treat_post = treated_canton * post,
    mw_level = ifelse(treated_canton, mw_levels[canton], 0)
  )

# Sector classification for triple-difference
panel <- panel %>%
  mutate(
    high_bite = noga %in% c("47_retail", "55_accommodation", "56_food_beverage", "81_building_services"),
    low_bite = noga %in% c("21_pharma", "62_it", "64_finance"),
    sector_type = case_when(
      noga == "total" ~ "total",
      high_bite ~ "high_bite",
      low_bite ~ "low_bite",
      TRUE ~ "other"
    )
  )

# ============================================================================
# 3. Create log outcomes
# ============================================================================
panel <- panel %>%
  mutate(
    log_emp = log(employment + 1),
    log_est = log(establishments + 1),
    log_fte = log(fte + 1)
  )

# ============================================================================
# 4. Load and process UDEMO (firm demographics)
# ============================================================================
udemo <- read_csv("../data/udemo_raw.csv", show_col_types = FALSE)
cat("\nUDEMO loaded:", nrow(udemo), "rows\n")

# Map canton names
udemo$canton <- NA_character_
for (i in seq_len(nrow(canton_map))) {
  matches <- grepl(canton_map$name_pattern[i], udemo$Kanton, ignore.case = TRUE)
  udemo$canton[matches] <- canton_map$canton[i]
}

udemo$year <- as.integer(udemo$Jahr)

# Map observation types
udemo$obs_type <- case_when(
  grepl("Bestand", udemo$Beobachtungseinheit) ~ "active",
  grepl("gründung|Neugründung", udemo$Beobachtungseinheit, ignore.case = TRUE) ~ "births",
  grepl("schliess", udemo$Beobachtungseinheit, ignore.case = TRUE) ~ "closures",
  TRUE ~ "other"
)

# Aggregate across legal forms to get canton-year totals
udemo_agg <- udemo %>%
  filter(obs_type %in% c("active", "births", "closures"), !is.na(canton)) %>%
  group_by(canton, year, obs_type) %>%
  summarise(value = sum(value, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = obs_type, values_from = value, values_fill = 0)

# Add treatment info
udemo_agg <- udemo_agg %>%
  mutate(
    treated_canton = canton %in% names(treatment_years),
    first_treat = ifelse(treated_canton, treatment_years[canton], 0),
    post = ifelse(treated_canton, as.integer(year >= first_treat), 0L),
    birth_rate = births / active,
    closure_rate = closures / active,
    net_entry = births - closures,
    log_births = log(births + 1),
    log_closures = log(closures + 1)
  )

# ============================================================================
# 5. Save analysis datasets
# ============================================================================
write_csv(panel, "../data/panel.csv")
write_csv(udemo_agg, "../data/udemo_panel.csv")

cat("\n=== Panel Summary ===\n")
cat("Main panel:", nrow(panel), "rows\n")
cat("  Treated cantons:", sum(panel$treated_canton & panel$year == 2015), "canton-sector obs\n")
cat("  Control cantons:", sum(!panel$treated_canton & panel$year == 2015), "canton-sector obs\n")
cat("UDEMO panel:", nrow(udemo_agg), "rows\n")

# Summary stats for treated vs control
panel %>%
  filter(noga == "total", year == 2016) %>%
  group_by(treated_canton) %>%
  summarise(
    n_cantons = n(),
    mean_emp = mean(employment, na.rm = TRUE),
    sd_emp = sd(employment, na.rm = TRUE),
    mean_est = mean(establishments, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

cat("\nData cleaning complete.\n")
