# =============================================================================
# 02_clean_data.R — Clean CDC VSRR and build analysis panel
# =============================================================================
source("00_packages.R")

cdc_raw <- read_csv("../data/cdc_vsrr_raw.csv", show_col_types = FALSE)
fts_laws <- read_csv("../data/fts_legalization.csv", show_col_types = FALSE)

cat("Raw CDC rows:", nrow(cdc_raw), "\n")
cat("Unique indicators:\n")
print(sort(unique(cdc_raw$indicator)))

# =============================================================================
# Filter to drug-specific indicators we need
# =============================================================================
# The VSRR dataset uses indicator names, not ICD-10 codes directly.
# Map indicator names to our drug types.

drug_indicators <- tribble(
  ~indicator_pattern, ~drug_type, ~high_contam,
  "Heroin (T40.1)",                "Heroin",              1L,
  "Cocaine (T40.5)",               "Cocaine",             1L,
  "Methadone (T40.3)",             "Methadone",           0L,
  "Natural & semi-synthetic opioids (T40.2)", "Natural_opioids", 0L,
  "Synthetic opioids, excl. methadone (T40.4)", "Synthetic_opioids", 1L,
  "Psychostimulants with abuse potential (T43.6)", "Psychostimulants", NA_integer_
)

# Filter CDC data to state-level, monthly, matching our indicators
cdc_filtered <- cdc_raw %>%
  filter(
    !is.na(state_name),
    state_name != "United States",
    # Match our drug indicators
    indicator %in% drug_indicators$indicator_pattern
  ) %>%
  mutate(
    year = as.integer(year),
    month = as.integer(month),
    data_value = as.numeric(data_value)
  ) %>%
  filter(year >= 2015, year <= 2023) %>%
  left_join(drug_indicators, by = c("indicator" = "indicator_pattern"))

cat("Filtered rows:", nrow(cdc_filtered), "\n")
cat("Drug types:\n")
print(table(cdc_filtered$drug_type))
cat("States:", length(unique(cdc_filtered$state_name)), "\n")

# =============================================================================
# Aggregate to state x year x drug_type (annual)
# =============================================================================
# Monthly data has many suppressed cells. Aggregate to annual for power.

panel_annual <- cdc_filtered %>%
  group_by(state_name, year, drug_type, high_contam) %>%
  summarise(
    deaths = sum(data_value, na.rm = TRUE),
    n_months = sum(!is.na(data_value)),
    .groups = "drop"
  ) %>%
  # Only keep state-year-drug combos with at least 6 months of data
  filter(n_months >= 6)

cat("\nAnnual panel rows:", nrow(panel_annual), "\n")

# =============================================================================
# Merge FTS legalization
# =============================================================================
panel <- panel_annual %>%
  left_join(fts_laws, by = c("state_name" = "state")) %>%
  mutate(
    # States without FTS law = never-treated (set fts_year very high)
    fts_year = ifelse(is.na(fts_year), 9999L, fts_year),
    # Post-treatment indicator
    post_fts = as.integer(year >= fts_year),
    # DDD interaction
    post_x_high = post_fts * high_contam,
    # Treatment cohort for staggered design
    cohort = ifelse(fts_year == 9999L, 0L, fts_year),
    # Relative time (event time)
    rel_year = year - fts_year
  )

cat("\nPanel with FTS treatment:\n")
cat("  Total rows:", nrow(panel), "\n")
cat("  Treated states:", sum(panel$fts_year < 9999 & !duplicated(panel$state_name)), "\n")
cat("  Never-treated states:", sum(panel$fts_year == 9999 & !duplicated(panel$state_name)), "\n")
cat("  Drug types:", length(unique(panel$drug_type)), "\n")

# =============================================================================
# Create state population for rates (use 2020 as reference)
# =============================================================================
# Simple population from Census estimates (state-level)
state_pops <- tribble(
  ~state_name, ~pop_2020,
  "Alabama", 5024279, "Alaska", 733391, "Arizona", 7151502,
  "Arkansas", 3011524, "California", 39538223, "Colorado", 5773714,
  "Connecticut", 3605944, "Delaware", 989948, "District of Columbia", 689545,
  "Florida", 21538187, "Georgia", 10711908, "Hawaii", 1455271,
  "Idaho", 1839106, "Illinois", 12812508, "Indiana", 6785528,
  "Iowa", 3190369, "Kansas", 2937880, "Kentucky", 4505836,
  "Louisiana", 4657757, "Maine", 1362359, "Maryland", 6177224,
  "Massachusetts", 7029917, "Michigan", 10077331, "Minnesota", 5706494,
  "Mississippi", 2961279, "Missouri", 6154913, "Montana", 1084225,
  "Nebraska", 1961504, "Nevada", 3104614, "New Hampshire", 1377529,
  "New Jersey", 9288994, "New Mexico", 2117522, "New York", 20201249,
  "North Carolina", 10439388, "North Dakota", 779094, "Ohio", 11799448,
  "Oklahoma", 3959353, "Oregon", 4237256, "Pennsylvania", 13002700,
  "Rhode Island", 1097379, "South Carolina", 5118425, "South Dakota", 886667,
  "Tennessee", 6910840, "Texas", 29145505, "Utah", 3271616,
  "Vermont", 643077, "Virginia", 8631393, "Washington", 7614893,
  "West Virginia", 1793716, "Wisconsin", 5893718, "Wyoming", 576851
)

panel <- panel %>%
  left_join(state_pops, by = "state_name") %>%
  mutate(
    death_rate = deaths / pop_2020 * 100000
  )

# Drop observations where we don't have population
panel <- panel %>% filter(!is.na(pop_2020))

cat("\nFinal panel (with population):", nrow(panel), "\n")
cat("State-year-drug observations by high_contam:\n")
print(table(panel$high_contam, useNA = "ifany"))

# =============================================================================
# Focus panel: only high_contam == 0 or 1 (drop psychostimulants for main spec)
# =============================================================================
panel_main <- panel %>%
  filter(!is.na(high_contam))

cat("\nMain panel (excl. psychostimulants):", nrow(panel_main), "\n")

# Create numeric state ID
panel_main <- panel_main %>%
  mutate(state_id = as.integer(as.factor(state_name)),
         drug_id = as.integer(as.factor(drug_type)))

# Save
write_csv(panel_main, "../data/panel_main.csv")
write_csv(panel, "../data/panel_full.csv")
message("Saved analysis panel: ", nrow(panel_main), " rows")
