## 02_clean_data.R — Construct analysis dataset
## apep_0612: Immigration Judge Leniency and Local Crime

source("code/00_packages.R")

# Load raw data
courts_raw       <- readRDS("data/courts_raw.rds")
judges_raw       <- readRDS("data/judges_raw.rds")
court_judges_raw <- readRDS("data/court_judges_raw.rds")
cdc_raw          <- readRDS("data/cdc_raw.rds")
acs_raw          <- readRDS("data/acs_raw.rds")

# ===================================================================
# 1. Court-level judge leniency measures
# ===================================================================
cat("=== Computing court-level judge leniency ===\n")

# For each court, compute weighted average judge leniency
court_leniency <- court_judges_raw %>%
  filter(!is.na(grantRate) & decisions > 0) %>%
  group_by(court_code, court_state) %>%
  summarise(
    n_judges           = n(),
    judge_leniency     = weighted.mean(grantRate, w = decisions),
    judge_leniency_sd  = sd(grantRate),
    judge_leniency_min = min(grantRate),
    judge_leniency_max = max(grantRate),
    judge_leniency_range = max(grantRate) - min(grantRate),
    total_decisions    = sum(decisions),
    .groups = "drop"
  )

cat(sprintf("Computed leniency for %d courts\n", nrow(court_leniency)))

# Merge with court-level grant rate from court index
courts_clean <- courts_raw %>%
  select(code, state, city, cases, grants, grantRate, slug) %>%
  rename(court_code = code, court_state = state) %>%
  left_join(court_leniency, by = c("court_code", "court_state"))

# ===================================================================
# 2. State-level aggregation of court data
# ===================================================================
cat("=== Aggregating to state level ===\n")

state_courts <- courts_clean %>%
  filter(!is.na(judge_leniency)) %>%
  group_by(court_state) %>%
  summarise(
    n_courts              = n(),
    state_grant_rate      = weighted.mean(grantRate, w = cases),
    state_judge_leniency  = weighted.mean(judge_leniency, w = total_decisions),
    state_leniency_sd     = weighted.mean(judge_leniency_sd, w = total_decisions, na.rm = TRUE),
    state_leniency_range  = max(judge_leniency_max) - min(judge_leniency_min),
    total_cases           = sum(cases),
    total_judges          = sum(n_judges),
    .groups = "drop"
  )

cat(sprintf("States with immigration courts: %d\n", nrow(state_courts)))

# ===================================================================
# 3. State-level crime data from CDC
# ===================================================================
cat("=== Processing CDC homicide data ===\n")

# State abbreviation to name crosswalk
state_xwalk <- tibble(
  state_name = state.name,
  state_abb  = state.abb
) %>%
  add_row(state_name = "District of Columbia", state_abb = "DC")

# Process CDC data: aggregate county-level to state-level
# Columns: geoid, name, st_geoid, st_name, intent, period, count_sup, rate, rate_m
cdc_clean <- cdc_raw %>%
  mutate(
    count = as.numeric(count_sup),
    rate_val = as.numeric(rate),
    year  = as.integer(period)
  ) %>%
  filter(!is.na(count))

# State-year level: sum counts across counties, take mean of county rates
# Since we don't have population, use the rate directly (CDC computes per 100K)
state_crime <- cdc_clean %>%
  group_by(st_name, intent, year) %>%
  summarise(
    total_count = sum(count, na.rm = TRUE),
    # Weighted mean rate not possible without pop; use sum of counts
    n_counties  = n(),
    .groups = "drop"
  )

# We'll compute state-level rates using ACS population data later
# For now, save aggregated counts
state_crime_avg <- state_crime %>%
  group_by(st_name, intent) %>%
  summarise(
    avg_annual_count = mean(total_count, na.rm = TRUE),
    total_count      = sum(total_count, na.rm = TRUE),
    n_years          = n(),
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from  = intent,
    values_from = c(avg_annual_count, total_count, n_years),
    names_glue  = "{intent}_{.value}"
  )

# Merge state abbreviations
state_crime_avg <- state_crime_avg %>%
  left_join(state_xwalk, by = c("st_name" = "state_name"))

cat(sprintf("States with crime data: %d\n", nrow(state_crime_avg)))

# ===================================================================
# 4. ACS demographics
# ===================================================================
cat("=== Processing ACS demographics ===\n")

# Handle both wide and long format output from tidycensus
if ("total_popE" %in% names(acs_raw)) {
  # Wide format
  acs_clean <- acs_raw %>%
    transmute(
      state_name   = NAME,
      GEOID        = GEOID,
      total_pop    = total_popE,
      foreign_born = foreign_bornE,
      poverty_rate = poverty_belowE / poverty_totalE * 100,
      unemp_rate   = unemployedE / labor_forceE * 100,
      median_inc   = median_incomeE,
      pct_foreign  = foreign_bornE / total_popE * 100
    )
} else {
  # Long format — pivot
  acs_clean <- acs_raw %>%
    select(NAME, GEOID, variable, estimate) %>%
    pivot_wider(names_from = variable, values_from = estimate) %>%
    transmute(
      state_name   = NAME,
      GEOID        = GEOID,
      total_pop    = B01003_001,
      foreign_born = B05012_003,
      poverty_rate = B17001_002 / B17001_001 * 100,
      unemp_rate   = B23025_005 / B23025_003 * 100,
      median_inc   = B19013_001,
      pct_foreign  = B05012_003 / B01003_001 * 100
    )
}

# Add state abbreviations
acs_clean <- acs_clean %>%
  left_join(state_xwalk, by = c("state_name" = "state_name")) %>%
  rename(state_abb = state_abb)

cat(sprintf("ACS data for %d states\n", nrow(acs_clean)))

# ===================================================================
# 5. Census region crosswalk
# ===================================================================
region_xwalk <- tibble(
  state_abb = state.abb,
  region    = as.character(state.region),
  division  = as.character(state.division)
) %>%
  add_row(state_abb = "DC", region = "South", division = "South Atlantic")

# ===================================================================
# 6. Merge into analysis dataset
# ===================================================================
cat("=== Merging analysis dataset ===\n")

analysis <- state_courts %>%
  rename(state_abb = court_state) %>%
  left_join(state_crime_avg, by = "state_abb") %>%
  left_join(acs_clean, by = "state_abb") %>%
  left_join(region_xwalk, by = "state_abb") %>%
  mutate(
    log_pop   = log(total_pop),
    log_cases = log(total_cases),
    # Compute homicide rate per 100K using ACS population
    All_Homicide_avg_rate = All_Homicide_avg_annual_count / total_pop * 100000,
    FA_Homicide_avg_rate  = FA_Homicide_avg_annual_count / total_pop * 100000,
    All_Suicide_avg_rate  = All_Suicide_avg_annual_count / total_pop * 100000
  )

# Filter to states with both crime and court data
analysis <- analysis %>%
  filter(!is.na(All_Homicide_avg_rate) & !is.na(state_judge_leniency))

cat(sprintf("\n=== Final analysis dataset: %d state observations ===\n", nrow(analysis)))
cat(sprintf("  States: %s\n", paste(sort(analysis$state_abb), collapse = ", ")))
cat(sprintf("  Mean grant rate: %.1f%%\n", mean(analysis$state_grant_rate)))
cat(sprintf("  Mean judge leniency: %.1f%%\n", mean(analysis$state_judge_leniency)))
cat(sprintf("  Mean homicide rate: %.1f per 100K\n", mean(analysis$All_Homicide_avg_rate, na.rm = TRUE)))

# ===================================================================
# 7. State-year PANEL dataset (for n_obs >= 100)
# ===================================================================
cat("=== Building state-year panel ===\n")

# Get state-year crime counts
state_crime_wide <- state_crime %>%
  pivot_wider(
    names_from  = intent,
    values_from = c(total_count, n_counties),
    names_glue  = "{intent}_{.value}"
  )

state_crime_wide <- state_crime_wide %>%
  left_join(state_xwalk, by = c("st_name" = "state_name"))

# Merge state-year crime with state-level courts + demographics
panel <- state_crime_wide %>%
  rename(state_abb = state_abb) %>%
  left_join(
    state_courts %>% rename(state_abb = court_state),
    by = "state_abb"
  ) %>%
  left_join(acs_clean, by = "state_abb") %>%
  left_join(region_xwalk, by = "state_abb") %>%
  mutate(
    log_pop = log(total_pop),
    log_cases = log(total_cases),
    # Compute annual homicide rate per 100K
    All_Homicide_rate = All_Homicide_total_count / total_pop * 100000,
    FA_Homicide_rate  = FA_Homicide_total_count / total_pop * 100000,
    All_Suicide_rate  = All_Suicide_total_count / total_pop * 100000
  ) %>%
  filter(!is.na(All_Homicide_rate) & !is.na(state_judge_leniency))

cat(sprintf("Panel: %d state-year observations (%d states x %d years)\n",
            nrow(panel), n_distinct(panel$state_abb), n_distinct(panel$year)))

# Save
saveRDS(analysis, "data/analysis.rds")        # cross-section
saveRDS(panel, "data/panel.rds")              # state-year panel
saveRDS(courts_clean, "data/courts_clean.rds")
saveRDS(state_crime, "data/state_crime_panel.rds")

cat("=== Data cleaning complete ===\n")
