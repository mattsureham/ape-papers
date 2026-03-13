# 02_clean_data.R — Build analysis panel from CDC overdose data
# apep_0639: Opioid Day-Supply Limits and Illicit Overdose Substitution

source("00_packages.R")

# ==============================================================================
# 1. Load raw data
# ==============================================================================
cdc_raw <- readRDS("../data/cdc_raw.rds")
treatment_laws <- readRDS("../data/treatment_laws.rds")
never_treated <- readRDS("../data/never_treated.rds")
pop_df <- readRDS("../data/population.rds")

cat("CDC raw: ", nrow(cdc_raw), " records\n")
cat("Columns: ", paste(names(cdc_raw), collapse = ", "), "\n")

# ==============================================================================
# 2. Inspect and parse CDC data
# ==============================================================================
# Check available indicators
cat("\nAvailable indicators:\n")
print(sort(unique(cdc_raw$indicator)))

# Check available periods
cat("\nYear range: ", range(cdc_raw$year, na.rm = TRUE), "\n")

# Keep relevant indicators
target_indicators <- c(
  "Heroin (T40.1)",
  "Natural & semi-synthetic opioids (T40.2)",
  "Synthetic opioids, excl. methadone (T40.4)",
  "Cocaine (T40.5)",
  "Psychostimulants with abuse potential (T43.6)",
  "Number of Drug Overdose Deaths"
)

# Create short drug-type labels
drug_labels <- c(
  "Heroin (T40.1)" = "heroin",
  "Natural & semi-synthetic opioids (T40.2)" = "rx_opioid",
  "Synthetic opioids, excl. methadone (T40.4)" = "synthetic",
  "Cocaine (T40.5)" = "cocaine",
  "Psychostimulants with abuse potential (T43.6)" = "psychostimulant",
  "Number of Drug Overdose Deaths" = "total"
)

cdc <- cdc_raw %>%
  filter(indicator %in% target_indicators) %>%
  mutate(
    drug_type = drug_labels[indicator],
    year = as.integer(year),
    month = as.integer(month),
    data_value = as.numeric(data_value),
    state_name = state_name
  ) %>%
  filter(!is.na(data_value), !is.na(year))

cat("\nFiltered CDC data: ", nrow(cdc), " records across ",
    n_distinct(cdc$drug_type), " drug types\n")

# Check state coverage
cat("States in data: ", n_distinct(cdc$state_name), "\n")

# ==============================================================================
# 3. Map state names to FIPS codes
# ==============================================================================
state_crosswalk <- tibble(
  state_name = c(state.name, "District of Columbia"),
  state_abbr = c(state.abb, "DC"),
  state_fips = c(
    "01","02","04","05","06","08","09","10","12","13",
    "15","16","17","18","19","20","21","22","23","24",
    "25","26","27","28","29","30","31","32","33","34",
    "35","36","37","38","39","40","41","42","44","45",
    "46","47","48","49","50","51","53","54","55","56",
    "11"
  )
)

cdc <- cdc %>%
  left_join(state_crosswalk, by = "state_name") %>%
  filter(!is.na(state_fips))

cat("After state merge: ", nrow(cdc), " records, ",
    n_distinct(cdc$state_fips), " states\n")

# ==============================================================================
# 4. Aggregate to state-year level (annual)
# ==============================================================================
# CRITICAL: The CDC provisional data uses "12 month-ending" rolling totals.
# Each monthly row = trailing 12-month total ending in that month.
# We take the DECEMBER observation for each year = calendar-year total.
# For partial years (no December), take the latest available month.

cat("\nPeriod field values: ", paste(head(unique(cdc$period), 10), collapse = ", "), "\n")

if ("predicted_value" %in% names(cdc)) {
  cat("Has predicted_value column\n")
}

# For each state-year-drug_type: take the month closest to December (latest month)
# This gives us the 12-month rolling total ending closest to December = best proxy for calendar year
annual <- cdc %>%
  group_by(state_fips, state_abbr, state_name, year, drug_type) %>%
  arrange(desc(month)) %>%
  slice(1) %>%
  ungroup() %>%
  rename(deaths = data_value) %>%
  mutate(deaths_adj = deaths)

cat("\nAnnual panel: ", nrow(annual), " state-year-drug observations\n")
cat("Year range: ", min(annual$year), "-", max(annual$year), "\n")

# ==============================================================================
# 5. Merge population and compute per-capita rates
# ==============================================================================
annual <- annual %>%
  left_join(pop_df %>% select(state_fips, year, population),
            by = c("state_fips", "year"))

# For years without population data, interpolate
annual <- annual %>%
  group_by(state_fips) %>%
  arrange(year) %>%
  mutate(population = zoo::na.approx(population, na.rm = FALSE)) %>%
  ungroup()

# Deaths per 100,000 population
annual <- annual %>%
  filter(!is.na(population), population > 0) %>%
  mutate(
    death_rate = (deaths_adj / population) * 100000
  )

cat("After population merge: ", nrow(annual), " observations\n")

# ==============================================================================
# 6. Merge treatment status
# ==============================================================================
# Create treatment variable: first_treat = year of law adoption (0 for never-treated)
all_states <- annual %>%
  distinct(state_fips, state_abbr, state_name) %>%
  left_join(treatment_laws %>% select(state_fips, law_year, max_days),
            by = "state_fips") %>%
  mutate(
    first_treat = replace_na(law_year, 0),
    treated = as.integer(first_treat > 0),
    max_days = replace_na(max_days, NA_real_)
  )

annual <- annual %>%
  left_join(all_states %>% select(state_fips, first_treat, treated, max_days),
            by = "state_fips") %>%
  mutate(
    post = as.integer(year >= first_treat & first_treat > 0),
    treat_post = treated * post
  )

cat("\nTreatment status:\n")
cat("  Treated states: ", sum(all_states$treated == 1), "\n")
cat("  Never-treated: ", sum(all_states$treated == 0), "\n")
cat("  Cohort distribution:\n")
print(table(all_states$first_treat[all_states$first_treat > 0]))

# ==============================================================================
# 7. Create numeric state ID for CS estimator
# ==============================================================================
annual <- annual %>%
  mutate(state_id = as.integer(as.factor(state_fips)))

# ==============================================================================
# 8. Wide-format panel for separate drug-type analyses
# ==============================================================================
panel_wide <- annual %>%
  select(state_id, state_fips, state_abbr, state_name, year, drug_type,
         death_rate, deaths_adj, population, first_treat, treated, max_days) %>%
  pivot_wider(
    id_cols = c(state_id, state_fips, state_abbr, state_name, year,
                first_treat, treated, max_days, population),
    names_from = drug_type,
    values_from = c(death_rate, deaths_adj)
  )

cat("\nWide panel: ", nrow(panel_wide), " state-year observations\n")
cat("Columns: ", paste(names(panel_wide), collapse = ", "), "\n")

# ==============================================================================
# 9. Summary statistics
# ==============================================================================
cat("\n=== Summary Statistics (Pre-treatment, all states) ===\n")
pre_panel <- panel_wide %>% filter(year < 2016)

summary_vars <- c("death_rate_rx_opioid", "death_rate_heroin",
                   "death_rate_synthetic", "death_rate_cocaine",
                   "death_rate_psychostimulant", "death_rate_total")

for (v in summary_vars) {
  if (v %in% names(pre_panel)) {
    vals <- pre_panel[[v]]
    cat(sprintf("  %-35s Mean: %6.2f  SD: %6.2f  N: %d\n",
                v, mean(vals, na.rm=TRUE), sd(vals, na.rm=TRUE), sum(!is.na(vals))))
  }
}

# ==============================================================================
# 10. Merge long-history total drug poisoning data (2010-2014)
# ==============================================================================
# The CDC provisional drug-type data starts in 2015, giving limited pre-periods
# for the 2016 cohort. We extend the panel with total drug poisoning data from
# CDC NCHS jx6g-fdh6 (1999-2015) for years 2010-2014 to increase pre-treatment
# periods for the total overdose outcome.

if (file.exists("../data/drug_poisoning_long.rds")) {
  dp_long <- readRDS("../data/drug_poisoning_long.rds")

  if (nrow(dp_long) > 0) {
    cat("\n=== Extending panel with 2010-2014 total drug poisoning data ===\n")

    dp_ext <- dp_long %>%
      filter(year >= 2010, year <= 2014) %>%
      left_join(state_crosswalk, by = c("state" = "state_name")) %>%
      filter(!is.na(state_fips)) %>%
      mutate(
        drug_type = "total",
        deaths_adj = deaths,
        death_rate = crude_rate
      ) %>%
      select(state_fips, state_abbr, state_name = state, year, drug_type,
             deaths = deaths, deaths_adj, population, death_rate)

    # Create state IDs consistent with existing panel
    dp_ext <- dp_ext %>%
      left_join(all_states %>% select(state_fips, first_treat, treated, max_days),
                by = "state_fips") %>%
      mutate(
        post = 0L,
        treat_post = 0L,
        state_id = as.integer(as.factor(state_fips))
      )

    # Add to long panel
    annual <- bind_rows(annual, dp_ext) %>%
      arrange(state_fips, year, drug_type)

    # Rebuild wide panel with extended data
    panel_wide <- annual %>%
      select(state_id, state_fips, state_abbr, state_name, year, drug_type,
             death_rate, deaths_adj, population, first_treat, treated, max_days) %>%
      pivot_wider(
        id_cols = c(state_id, state_fips, state_abbr, state_name, year,
                    first_treat, treated, max_days, population),
        names_from = drug_type,
        values_from = c(death_rate, deaths_adj)
      )

    cat("Extended panel: ", nrow(panel_wide), " state-year observations\n")
    cat("Year range: ", min(panel_wide$year), " - ", max(panel_wide$year), "\n")
    cat("Pre-treatment years (before 2016): ", n_distinct(panel_wide$year[panel_wide$year < 2016]), "\n")
  }
}

# ==============================================================================
# 11. Save analysis-ready datasets
# ==============================================================================
saveRDS(annual, "../data/analysis_long.rds")
saveRDS(panel_wide, "../data/analysis_wide.rds")
saveRDS(all_states, "../data/state_treatment.rds")

# Save summary stats for tables
summ_stats <- annual %>%
  filter(year >= 2015) %>%
  group_by(drug_type) %>%
  summarise(
    mean = mean(death_rate, na.rm = TRUE),
    sd = sd(death_rate, na.rm = TRUE),
    min = min(death_rate, na.rm = TRUE),
    max = max(death_rate, na.rm = TRUE),
    n_obs = sum(!is.na(death_rate)),
    n_states = n_distinct(state_fips),
    .groups = "drop"
  )

saveRDS(summ_stats, "../data/summary_stats.rds")

cat("\n=== Clean data complete ===\n")
cat("analysis_long.rds: ", nrow(annual), " rows (state-year-drug_type)\n")
cat("analysis_wide.rds: ", nrow(panel_wide), " rows (state-year)\n")
