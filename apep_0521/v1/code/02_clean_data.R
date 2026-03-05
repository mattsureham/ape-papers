## ==========================================================================
## 02_clean_data.R — Build analysis panels for Constitutional Carry paper
## ==========================================================================

source("00_packages.R")
data_dir <- "../data"

## ==========================================================================
## LOAD RAW DATA
## ==========================================================================

treatment <- fread(file.path(data_dir, "treatment_timing.csv"))
cdc_lead  <- fread(file.path(data_dir, "cdc_leading_causes.csv"))
cdc_viol  <- fread(file.path(data_dir, "cdc_state_violence.csv"))
nics_raw  <- fread(file.path(data_dir, "nics_checks.csv"))
acs_raw   <- fread(file.path(data_dir, "acs_covariates.csv"))

## ==========================================================================
## PANEL A: Long Panel (1999-2017) — Suicide + Unintentional Injury
## ==========================================================================

cat("=== Building Panel A (1999-2017) ===\n")

# Clean CDC leading causes data
panel_a <- cdc_lead %>%
  filter(state != "United States") %>%
  select(year, state, cause_name, deaths, aadr) %>%
  mutate(year = as.integer(year),
         deaths = as.integer(deaths),
         aadr = as.numeric(aadr)) %>%
  # Pivot to wide: one row per state-year
  pivot_wider(id_cols = c(year, state),
              names_from = cause_name,
              values_from = c(deaths, aadr),
              names_sep = "_") %>%
  clean_names()

# Rename key variables
panel_a <- panel_a %>%
  rename(suicide_deaths = deaths_suicide,
         suicide_rate = aadr_suicide,
         uninj_deaths = deaths_unintentional_injuries,
         uninj_rate = aadr_unintentional_injuries,
         heart_deaths = deaths_heart_disease,
         heart_rate = aadr_heart_disease,
         cancer_deaths = deaths_cancer,
         cancer_rate = aadr_cancer,
         total_deaths = deaths_all_causes,
         total_rate = aadr_all_causes)

cat("Panel A: ", nrow(panel_a), "state-years, ",
    n_distinct(panel_a$state), "states, ",
    n_distinct(panel_a$year), "years\n")

## ==========================================================================
## PANEL B: Recent Panel (2019-2024) — Firearm-Specific
## ==========================================================================

cat("\n=== Building Panel B (2019-2024) ===\n")

# Clean CDC violence data
panel_b <- cdc_viol %>%
  filter(name != "United States",
         period != "TTM") %>%  # Exclude trailing 12-month
  mutate(year = as.integer(period),
         count = ifelse(count_sup == "Suppressed", NA_real_,
                        as.numeric(count_sup)),
         rate_raw = as.numeric(rate),
         rate = ifelse(rate_raw == -999, NA_real_, rate_raw)) %>%
  select(-rate_raw) %>%
  select(year, state = name, intent, count, rate) %>%
  pivot_wider(id_cols = c(year, state),
              names_from = intent,
              values_from = c(count, rate),
              names_sep = "_") %>%
  clean_names()

cat("Panel B:", nrow(panel_b), "state-years, ",
    n_distinct(panel_b$state), "states, ",
    n_distinct(panel_b$year), "years\n")

## ==========================================================================
## NICS BACKGROUND CHECKS — Aggregate to State × Year
## ==========================================================================

cat("\n=== Processing NICS data ===\n")

nics <- nics_raw %>%
  mutate(year = as.integer(substr(month, 1, 4)),
         state_name = state) %>%
  filter(year >= 2000, year <= 2023) %>%
  group_by(state_name, year) %>%
  summarise(
    nics_total = sum(totals, na.rm = TRUE),
    nics_handgun = sum(handgun, na.rm = TRUE),
    nics_long_gun = sum(long_gun, na.rm = TRUE),
    .groups = "drop"
  )

cat("NICS annual:", nrow(nics), "state-years\n")

## ==========================================================================
## ACS COVARIATES
## ==========================================================================

cat("\n=== Processing ACS covariates ===\n")

acs <- acs_raw %>%
  mutate(
    population = b01003_001e,
    median_income = b19013_001e,
    poverty_count = b17001_002e,
    black_pop = b02001_003e,
    poverty_rate = poverty_count / population * 100,
    pct_black = black_pop / population * 100
  ) %>%
  select(state = name, year, fips = state, population, median_income,
         poverty_rate, pct_black) %>%
  mutate(year = as.integer(year))

# Backfill covariates for years before 2009 using 2009 values
# (ACS starts in 2009; earlier years use 2009 baseline)
early_years <- expand.grid(
  state = unique(acs$state),
  year = 2000:2008,
  stringsAsFactors = FALSE
) %>% as_tibble()

acs_2009 <- acs %>% filter(year == 2009) %>% select(-year)
acs_early <- early_years %>% left_join(acs_2009, by = "state")
acs_full <- bind_rows(acs_early, acs) %>% arrange(state, year)

cat("ACS covariates:", nrow(acs_full), "state-years (2000-2023)\n")

## ==========================================================================
## MERGE TREATMENT TIMING INTO ALL STATES
## ==========================================================================

cat("\n=== Merging treatment timing ===\n")

# Create full state panel
all_states <- unique(acs_full$state)
n_states <- length(all_states)
cat("States in ACS:", n_states, "\n")

# Merge treatment timing
# first_treat: year of adoption (0 for never-treated)
state_treatment <- tibble(state = all_states) %>%
  left_join(treatment %>% select(state, treat_year), by = "state") %>%
  mutate(
    # For CS-DiD: first_treat = 0 means never treated
    first_treat = case_when(
      is.na(treat_year) ~ 0L,          # Never-treated states
      treat_year < 2010 ~ 0L,           # Vermont (1791), Alaska (2003) — exclude (insufficient pre-period)
      TRUE ~ as.integer(treat_year)
    ),
    ever_treated = first_treat > 0,
    # For TWFE: post indicator
    treatment_status = case_when(
      is.na(treat_year) ~ "Never treated",
      treat_year < 2010 ~ "Always treated (exclude)",
      treat_year <= 2017 ~ "Early adopter (2010-2017)",
      treat_year <= 2019 ~ "Mid adopter (2019)",
      treat_year <= 2022 ~ "Late adopter (2021-2022)",
      TRUE ~ "Very late (2023+)"
    )
  )

cat("Treatment status:\n")
print(table(state_treatment$treatment_status))

## ==========================================================================
## BUILD FINAL ANALYSIS PANELS
## ==========================================================================

cat("\n=== Building final panels ===\n")

# Panel A: Long panel for suicide analysis
analysis_a <- panel_a %>%
  left_join(state_treatment, by = "state") %>%
  left_join(acs_full, by = c("state", "year")) %>%
  left_join(nics %>% rename(state = state_name), by = c("state", "year")) %>%
  mutate(
    treated = as.integer(first_treat > 0 & year >= first_treat),
    log_pop = log(population),
    nics_pc = nics_total / population * 100000
  ) %>%
  # Exclude Vermont (always treated) and Alaska (treated before panel)
  filter(treatment_status != "Always treated (exclude)")

cat("Panel A (final):", nrow(analysis_a), "obs, ",
    n_distinct(analysis_a$state), "states, ",
    range(analysis_a$year), "\n")
cat("  Treated states:", sum(analysis_a$ever_treated & !duplicated(analysis_a$state)), "\n")
cat("  Never-treated states:", sum(!analysis_a$ever_treated & !duplicated(analysis_a$state)), "\n")

# Panel B: Recent panel for firearm-specific analysis
analysis_b <- panel_b %>%
  left_join(state_treatment, by = "state") %>%
  left_join(acs_full, by = c("state", "year")) %>%
  left_join(nics %>% rename(state = state_name), by = c("state", "year")) %>%
  mutate(
    treated = as.integer(first_treat > 0 & year >= first_treat),
    log_pop = log(population),
    nics_pc = nics_total / population * 100000,
    # Construct non-firearm placebos
    nf_homicide_rate = rate_all_homicide - rate_fa_homicide,
    nf_suicide_rate = rate_all_suicide - rate_fa_suicide
  ) %>%
  filter(treatment_status != "Always treated (exclude)")

cat("Panel B (final):", nrow(analysis_b), "obs, ",
    n_distinct(analysis_b$state), "states, ",
    range(analysis_b$year), "\n")

# Panel C: NICS panel (full period)
analysis_nics <- acs_full %>%
  left_join(state_treatment, by = "state") %>%
  left_join(nics %>% rename(state = state_name), by = c("state", "year")) %>%
  filter(treatment_status != "Always treated (exclude)",
         year >= 2000, year <= 2023) %>%
  mutate(
    treated = as.integer(first_treat > 0 & year >= first_treat),
    log_pop = log(population),
    nics_pc = nics_total / population * 100000
  )

cat("Panel C (NICS):", nrow(analysis_nics), "obs, ",
    n_distinct(analysis_nics$state), "states, ",
    range(analysis_nics$year), "\n")

## ==========================================================================
## SAVE
## ==========================================================================

fwrite(analysis_a, file.path(data_dir, "panel_a_suicide.csv"))
fwrite(analysis_b, file.path(data_dir, "panel_b_firearm.csv"))
fwrite(analysis_nics, file.path(data_dir, "panel_c_nics.csv"))
fwrite(state_treatment, file.path(data_dir, "state_treatment.csv"))

## ==========================================================================
## DESCRIPTIVE STATISTICS
## ==========================================================================

cat("\n=== Descriptive Statistics ===\n\n")

cat("--- Panel A: Suicide (1999-2017) ---\n")
cat("Mean suicide rate:", round(mean(analysis_a$suicide_rate, na.rm = TRUE), 1), "\n")
cat("SD suicide rate:", round(sd(analysis_a$suicide_rate, na.rm = TRUE), 1), "\n")
cat("Mean uninj rate:", round(mean(analysis_a$uninj_rate, na.rm = TRUE), 1), "\n")

cat("\n--- Panel B: Firearm-Specific (2019-2024) ---\n")
cat("Mean FA death rate:", round(mean(analysis_b$rate_fa_deaths, na.rm = TRUE), 1), "\n")
cat("Mean FA homicide rate:", round(mean(analysis_b$rate_fa_homicide, na.rm = TRUE), 1), "\n")
cat("Mean FA suicide rate:", round(mean(analysis_b$rate_fa_suicide, na.rm = TRUE), 1), "\n")
cat("Mean All homicide rate:", round(mean(analysis_b$rate_all_homicide, na.rm = TRUE), 1), "\n")
cat("Mean All suicide rate:", round(mean(analysis_b$rate_all_suicide, na.rm = TRUE), 1), "\n")

cat("\n--- Panel C: NICS (2000-2023) ---\n")
cat("Mean NICS checks per 100K:", round(mean(analysis_nics$nics_pc, na.rm = TRUE), 0), "\n")

cat("\n=== Data cleaning complete ===\n")
