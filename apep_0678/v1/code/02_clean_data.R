# 02_clean_data.R — Clean and rebuild all panels
# APEP-0678: Price Floors and Poison — MUP and Alcohol-Specific Mortality
#
# This script:
#   1. Re-parses the deprivation panel from the raw Fingertips CSV (all 10 deciles)
#   2. Validates and cleans the country, region, and LA panels
#   3. Adds additional derived variables (event-time, trend variables)
#   4. Saves cleaned versions for downstream analysis

source("00_packages.R")

cat("\n=== CLEANING DATA FOR APEP-0678 ===\n\n")

DATA_DIR  <- "../data"
TABLE_DIR <- "../tables"
if (!dir.exists(TABLE_DIR)) dir.create(TABLE_DIR, recursive = TRUE)

# ============================================================================
# STEP 1: Re-parse deprivation panel — all 10 deciles
# ============================================================================
cat("--- Step 1: Re-parsing deprivation data (all 10 deciles) ---\n")

ft_raw <- read_csv(file.path(DATA_DIR, "fingertips_91380.csv"),
                   show_col_types = FALSE)

# Map ordinal category names to numeric decile ranks (1 = most deprived, 10 = least)
decile_map <- c(
  "Most deprived decile (IMD2019)"       = 1L,
  "Second most deprived decile (IMD2019)"= 2L,
  "Third more deprived decile (IMD2019)" = 3L,
  "Fourth more deprived decile (IMD2019)"= 4L,
  "Fifth more deprived decile (IMD2019)" = 5L,
  "Fifth less deprived decile (IMD2019)" = 6L,
  "Fourth less deprived decile (IMD2019)"= 7L,
  "Third less deprived decile (IMD2019)" = 8L,
  "Second least deprived decile (IMD2019)"= 9L,
  "Least deprived decile (IMD2019)"      = 10L
)

deprivation_panel <- ft_raw %>%
  filter(
    Sex              == "Persons",
    `Time period range` == "1y",
    `Area Code`      == "E92000001",
    grepl("4/21 geography", `Category Type`, fixed = TRUE),   # use stable geography
    Category         %in% names(decile_map)
  ) %>%
  mutate(year = as.integer(substr(`Time period`, 1, 4))) %>%
  filter(year >= 2013, year <= 2023) %>%
  transmute(
    year,
    category  = Category,
    decile    = decile_map[Category],
    rate      = Value,
    deaths    = Count,
    population = Denominator,
    lower_ci  = `Lower CI 95.0 limit`,
    upper_ci  = `Upper CI 95.0 limit`
  ) %>%
  arrange(decile, year)

cat("  Deprivation deciles found:", n_distinct(deprivation_panel$decile), "\n")
cat("  Decile labels:", paste(sort(unique(deprivation_panel$decile)), collapse = ", "), "\n")
cat("  Year range:", min(deprivation_panel$year), "-", max(deprivation_panel$year), "\n")
cat("  Total obs:", nrow(deprivation_panel), "\n")

if (n_distinct(deprivation_panel$decile) != 10) {
  stop("FATAL: Expected 10 deprivation deciles, found ",
       n_distinct(deprivation_panel$decile))
}

# ============================================================================
# STEP 2: Load and validate country panel
# ============================================================================
cat("\n--- Step 2: Cleaning country panel ---\n")

country_panel <- readRDS(file.path(DATA_DIR, "country_panel.rds"))

# Add event-time relative to each country's treatment
country_panel <- country_panel %>%
  mutate(
    treat_year = case_when(
      country == "Scotland" ~ 2018L,
      country == "Wales"    ~ 2020L,
      TRUE                  ~ NA_integer_
    ),
    # Event-time: t=0 is first post-treatment year; t=-1 is omitted baseline
    event_time = if_else(!is.na(treat_year), year - treat_year, NA_integer_),
    # Flag for pre-trend period (2013-2017 common pre-period)
    pre_period = as.integer(year <= 2017),
    # 2017 as base year for event studies
    rel_year   = year - 2017L,
    # Log rate for multiplicative models (optional)
    log_rate   = log(rate)
  )

cat("  Observations:", nrow(country_panel), "\n")
cat("  Countries:", paste(sort(unique(country_panel$country)), collapse = ", "), "\n")
cat("  Year range:", min(country_panel$year), "-", max(country_panel$year), "\n")
cat("  Pre-periods (Scotland): 5 (2013-2017)\n")

# Verify no missing rates in core data
missing_rates <- sum(is.na(country_panel$rate))
if (missing_rates > 0) {
  cat("  WARNING:", missing_rates, "missing rate values\n")
} else {
  cat("  No missing rates.\n")
}

# ============================================================================
# STEP 3: Clean regional panel — add event-time + short label
# ============================================================================
cat("\n--- Step 3: Cleaning regional panel ---\n")

region_panel <- readRDS(file.path(DATA_DIR, "region_panel.rds")) %>%
  mutate(
    treat_year = case_when(
      country == "Scotland" ~ 2018L,
      country == "Wales"    ~ 2020L,
      TRUE                  ~ NA_integer_
    ),
    event_time = if_else(!is.na(treat_year), year - treat_year, NA_integer_),
    rel_year   = year - 2017L,
    # Shorten region labels for plots
    unit_label = case_when(
      grepl("North East",      area_name, ignore.case = TRUE) ~ "North East",
      grepl("North West",      area_name, ignore.case = TRUE) ~ "North West",
      grepl("Yorkshire",       area_name, ignore.case = TRUE) ~ "Yorkshire",
      grepl("East Midlands",   area_name, ignore.case = TRUE) ~ "East Midlands",
      grepl("West Midlands",   area_name, ignore.case = TRUE) ~ "West Midlands",
      grepl("East of England", area_name, ignore.case = TRUE) ~ "East",
      grepl("London",          area_name, ignore.case = TRUE) ~ "London",
      grepl("South East",      area_name, ignore.case = TRUE) ~ "South East",
      grepl("South West",      area_name, ignore.case = TRUE) ~ "South West",
      country == "Scotland"                                   ~ "Scotland",
      country == "Wales"                                      ~ "Wales",
      TRUE ~ area_name
    ),
    # Binary treated indicator for any post-treatment year
    post_treat = as.integer(year >= treat_year & !is.na(treat_year)),
    log_rate   = log(rate)
  )

n_units   <- n_distinct(region_panel$area_code)
n_treated <- n_distinct(region_panel$area_code[region_panel$first_treat > 0])

cat("  Units:", n_units, "(need >= 11)\n")
cat("  Treated units:", n_treated, "\n")
cat("  Observations:", nrow(region_panel), "\n")

if (n_units < 11) {
  stop("FATAL: Expected at least 11 regional units, found ", n_units)
}

# ============================================================================
# STEP 4: Clean LA panel — add IMD quintile from deprivation decile
# ============================================================================
cat("\n--- Step 4: Cleaning LA panel ---\n")

la_panel <- readRDS(file.path(DATA_DIR, "la_panel.rds")) %>%
  mutate(
    rel_year = year - 2017L,
    log_rate = log(rate + 0.01)   # add small constant for LAs with 0 or missing
  )

n_las <- n_distinct(la_panel$area_code)
cat("  LAs:", n_las, "\n")
cat("  Observations:", nrow(la_panel), "\n")
cat("  NAs in rate:", sum(is.na(la_panel$rate)), "of", nrow(la_panel), "\n")

# Drop LAs with too many missing rate years (< 6 of 11 years present)
la_coverage <- la_panel %>%
  group_by(area_code) %>%
  summarise(n_obs = sum(!is.na(rate)), .groups = "drop")

la_keep <- la_coverage %>% filter(n_obs >= 6) %>% pull(area_code)
la_panel_clean <- la_panel %>% filter(area_code %in% la_keep)

cat("  LAs after coverage filter (>=6 non-NA years):", n_distinct(la_panel_clean$area_code), "\n")

# ============================================================================
# STEP 5: Deprivation gradient summary statistics
# ============================================================================
cat("\n--- Step 5: Deprivation gradient checks ---\n")

# Most vs least deprived trend
dep_ends <- deprivation_panel %>%
  filter(decile %in% c(1, 10)) %>%
  group_by(decile) %>%
  summarise(
    rate_2013 = rate[year == 2013],
    rate_2023 = rate[year == max(year[!is.na(rate)])],
    change    = rate_2023 - rate_2013,
    .groups   = "drop"
  )

cat("  Deprivation gradient 2013 vs 2023:\n")
print(dep_ends)

# Concentration index (ratio most/least deprived)
dep_ratio <- deprivation_panel %>%
  filter(decile %in% c(1, 10)) %>%
  select(year, decile, rate) %>%
  pivot_wider(names_from = decile, values_from = rate,
              names_prefix = "d") %>%
  mutate(ratio = d1 / d10)

cat("  Rate ratio (most/least) 2013:", round(dep_ratio$ratio[dep_ratio$year == 2013], 2), "\n")
cat("  Rate ratio (most/least) 2023:", round(dep_ratio$ratio[dep_ratio$year == max(dep_ratio$year)], 2), "\n")

# ============================================================================
# STEP 6: Save cleaned data
# ============================================================================
cat("\n--- Step 6: Saving cleaned datasets ---\n")

saveRDS(deprivation_panel, file.path(DATA_DIR, "deprivation_panel.rds"))
saveRDS(country_panel,     file.path(DATA_DIR, "country_panel.rds"))
saveRDS(region_panel,      file.path(DATA_DIR, "region_panel.rds"))
saveRDS(la_panel_clean,    file.path(DATA_DIR, "la_panel_clean.rds"))

# Update diagnostics
diag <- jsonlite::read_json(file.path(DATA_DIR, "diagnostics.json"))
diag$n_deprivation_deciles <- n_distinct(deprivation_panel$decile)
diag$n_regions              <- n_units
diag$n_las_clean            <- n_distinct(la_panel_clean$area_code)
jsonlite::write_json(diag, file.path(DATA_DIR, "diagnostics.json"), auto_unbox = TRUE)

cat("  deprivation_panel.rds:", nrow(deprivation_panel),
    "obs,", n_distinct(deprivation_panel$decile), "deciles\n")
cat("  country_panel.rds:    ", nrow(country_panel), "obs\n")
cat("  region_panel.rds:     ", nrow(region_panel), "obs\n")
cat("  la_panel_clean.rds:   ", nrow(la_panel_clean), "obs\n")

cat("\n=== DATA CLEANING COMPLETE ===\n")
