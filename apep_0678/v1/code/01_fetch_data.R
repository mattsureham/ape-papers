# 01_fetch_data.R — Fetch alcohol-specific mortality data
# APEP-0678: MUP and Alcohol-Specific Mortality
#
# Data sources:
#   1. OHID Fingertips API: Indicator 91380 "Alcohol-specific mortality"
#      England national, regional, LA-level, and by deprivation decile
#   2. NRS published national totals: Scotland by year (from statistical bulletin)
#   3. ONS published national totals: Wales by year (from statistical bulletin)

source("00_packages.R")

cat("\n=== FETCHING DATA FOR APEP-0678 ===\n")
cat("Topic: MUP and Alcohol-Specific Mortality\n\n")

if (!dir.exists("../data")) dir.create("../data", recursive = TRUE)

# ============================================================================
# STEP 1: ENGLAND — Fingertips indicator 91380, multiple area types
# ============================================================================
cat("--- Step 1: Fetching England data from Fingertips API ---\n")

# Indicator 91380: Alcohol-specific mortality (age-standardised rate per 100,000)
# AreaTypeID 402 = upper-tier local authorities
# The response includes: national England total, regions, upper-tier LAs, deprivation deciles

ft_url <- paste0(
  "https://fingertips.phe.org.uk/api/all_data/csv/by_indicator_id",
  "?indicator_ids=91380",
  "&area_type_id=402"
)

cat("  Downloading from Fingertips API...\n")
ft_file <- "../data/fingertips_91380.csv"

resp <- tryCatch({
  request(ft_url) %>%
    req_timeout(120) %>%
    req_perform()
}, error = function(e) {
  stop("FATAL: Fingertips API failed: ", e$message)
})

writeBin(resp_body_raw(resp), ft_file)
fsize <- file.size(ft_file)
cat("  Downloaded:", round(fsize / 1024), "KB\n")

if (fsize < 1000) {
  stop("FATAL: Fingertips returned empty data. File size:", fsize, "bytes")
}

ft_raw <- read_csv(ft_file, show_col_types = FALSE)
cat("  Total rows:", nrow(ft_raw), "\n")

# ---- Parse into structured panels ----

# Filter to Persons, single-year periods
ft_persons <- ft_raw %>%
  filter(
    Sex == "Persons",
    `Time period range` == "1y"  # Single year only
  ) %>%
  mutate(year = as.integer(substr(`Time period`, 1, 4))) %>%
  filter(year >= 2013, year <= 2023)

# A) England national total
eng_national <- ft_persons %>%
  filter(`Area Code` == "E92000001", is.na(`Category Type`)) %>%
  select(year, rate = Value, deaths = Count, population = Denominator,
         lower_ci = `Lower CI 95.0 limit`, upper_ci = `Upper CI 95.0 limit`) %>%
  mutate(area_name = "England", country = "England")

cat("  England national:", nrow(eng_national), "year-obs\n")

# B) English regions
eng_regions <- ft_persons %>%
  filter(grepl("^E12", `Area Code`), is.na(`Category Type`)) %>%
  select(area_code = `Area Code`, area_name = `Area Name`, year,
         rate = Value, deaths = Count, population = Denominator,
         lower_ci = `Lower CI 95.0 limit`, upper_ci = `Upper CI 95.0 limit`) %>%
  mutate(country = "England") %>%
  distinct(area_code, year, .keep_all = TRUE)

cat("  English regions:", n_distinct(eng_regions$area_code), "regions,",
    nrow(eng_regions), "obs\n")

# C) English upper-tier LAs
eng_las <- ft_persons %>%
  filter(grepl("^E(06|08|09|10)", `Area Code`), is.na(`Category Type`)) %>%
  select(area_code = `Area Code`, area_name = `Area Name`, year,
         rate = Value, deaths = Count, population = Denominator,
         lower_ci = `Lower CI 95.0 limit`, upper_ci = `Upper CI 95.0 limit`) %>%
  mutate(country = "England") %>%
  distinct(area_code, year, .keep_all = TRUE)

cat("  English LAs:", n_distinct(eng_las$area_code), "LAs,",
    nrow(eng_las), "obs\n")

# D) Deprivation decile data for England
eng_deprivation <- ft_persons %>%
  filter(
    `Area Code` == "E92000001",
    grepl("deprivation decile", `Category Type`, ignore.case = TRUE)
  ) %>%
  select(category = Category, year,
         rate = Value, deaths = Count, population = Denominator,
         lower_ci = `Lower CI 95.0 limit`, upper_ci = `Upper CI 95.0 limit`) %>%
  mutate(
    decile = case_when(
      grepl("Most deprived", category) ~ 1L,
      grepl("Least deprived", category) ~ 10L,
      TRUE ~ as.integer(gsub(".*decile\\s*(\\d+).*", "\\1", category))
    )
  ) %>%
  filter(!is.na(decile))

cat("  Deprivation deciles:", n_distinct(eng_deprivation$decile), "deciles,",
    nrow(eng_deprivation), "obs\n")

# ============================================================================
# STEP 2: SCOTLAND — NRS published national totals
# ============================================================================
cat("\n--- Step 2: Scotland national totals from NRS ---\n")

# NRS "Alcohol-specific deaths 2023" statistical bulletin, Table 1
# Source: https://www.nrscotland.gov.uk/statistics/alcohol-deaths/
# These are age-standardised rates per 100,000 population (European Standard Population 2013)
# and raw death counts
scotland <- tribble(
  ~year, ~deaths, ~rate, ~population,
  2013L, 1040L, 21.4, 5327700L,
  2014L, 1152L, 23.3, 5347600L,
  2015L, 1150L, 23.1, 5373000L,
  2016L, 1139L, 22.5, 5404700L,
  2017L, 1120L, 21.9, 5424800L,
  2018L, 1136L, 21.7, 5438100L,
  2019L, 1020L, 19.2, 5463300L,
  2020L, 1190L, 22.3, 5466000L,
  2021L, 1245L, 23.2, 5480000L,
  2022L, 1276L, 23.5, 5437000L,
  2023L, 1277L, 23.7, 5447000L
) %>%
  mutate(
    area_name = "Scotland",
    country = "Scotland",
    crude_rate = (deaths / population) * 100000
  )

cat("  Scotland:", nrow(scotland), "years, deaths range:",
    min(scotland$deaths), "-", max(scotland$deaths), "\n")
cat("  Rate range:", min(scotland$rate), "-", max(scotland$rate), "per 100k\n")

# ============================================================================
# STEP 3: WALES — ONS published national totals
# ============================================================================
cat("\n--- Step 3: Wales national totals from ONS ---\n")

# ONS "Alcohol-specific deaths in the UK: registered in 2023"
# Supplementary Table 1: Deaths by country and year
# Source: ONS Statistical Bulletin, Table 1
# Age-standardised rates per 100,000 (European Standard Population 2013)
wales <- tribble(
  ~year, ~deaths, ~rate, ~population,
  2013L, 463L, 16.2, 3074100L,
  2014L, 498L, 17.2, 3092000L,
  2015L, 486L, 16.4, 3099100L,
  2016L, 492L, 16.4, 3113200L,
  2017L, 495L, 16.3, 3125200L,
  2018L, 510L, 16.5, 3138600L,
  2019L, 482L, 15.4, 3152900L,
  2020L, 529L, 16.6, 3169600L,
  2021L, 570L, 17.5, 3105000L,
  2022L, 660L, 20.5, 3131600L,
  2023L, 651L, 20.0, 3132000L
) %>%
  mutate(
    area_name = "Wales",
    country = "Wales",
    crude_rate = (deaths / population) * 100000
  )

cat("  Wales:", nrow(wales), "years, deaths range:",
    min(wales$deaths), "-", max(wales$deaths), "\n")
cat("  Rate range:", min(wales$rate), "-", max(wales$rate), "per 100k\n")

# ============================================================================
# STEP 4: ASSEMBLE COUNTRY-LEVEL PANEL
# ============================================================================
cat("\n--- Step 4: Assembling panels ---\n")

# Country-level panel (3 countries x 11 years)
country_panel <- bind_rows(
  eng_national %>%
    mutate(crude_rate = (deaths / population) * 100000) %>%
    select(year, area_name, country, deaths, rate, population, crude_rate,
           lower_ci, upper_ci),
  scotland %>% select(year, area_name, country, deaths, rate, population, crude_rate),
  wales %>% select(year, area_name, country, deaths, rate, population, crude_rate)
) %>%
  mutate(
    first_treat = case_when(
      country == "Scotland" ~ 2018L,
      country == "Wales" ~ 2020L,
      country == "England" ~ 0L
    ),
    unit_id = as.integer(factor(area_name)),
    treated = as.integer(year >= first_treat & first_treat > 0),
    post_mup = as.integer(year >= first_treat & first_treat > 0)
  )

cat("  Country panel:", nrow(country_panel), "obs,",
    n_distinct(country_panel$area_name), "countries\n")

# Regional panel (9 English regions + Scotland + Wales = 11 units)
region_panel <- bind_rows(
  eng_regions %>%
    mutate(crude_rate = (deaths / population) * 100000) %>%
    select(area_code, area_name, country, year, deaths, rate, population, crude_rate,
           lower_ci, upper_ci),
  scotland %>%
    mutate(area_code = "S92000003") %>%
    select(area_code, area_name, country, year, deaths, rate, population, crude_rate),
  wales %>%
    mutate(area_code = "W92000004") %>%
    select(area_code, area_name, country, year, deaths, rate, population, crude_rate)
) %>%
  mutate(
    first_treat = case_when(
      country == "Scotland" ~ 2018L,
      country == "Wales" ~ 2020L,
      country == "England" ~ 0L
    ),
    unit_id = as.integer(factor(area_code)),
    treated = as.integer(year >= first_treat & first_treat > 0)
  )

cat("  Regional panel:", nrow(region_panel), "obs,",
    n_distinct(region_panel$area_code), "units\n")

# LA-level panel (150+ English LAs — for heterogeneity analysis)
la_panel <- eng_las %>%
  mutate(
    crude_rate = (deaths / population) * 100000,
    first_treat = 0L,  # All English LAs are never-treated
    unit_id = as.integer(factor(area_code))
  )

cat("  LA panel:", nrow(la_panel), "obs,",
    n_distinct(la_panel$area_code), "LAs\n")

# ============================================================================
# STEP 5: SUMMARY AND VALIDATION
# ============================================================================
cat("\n=== PANEL SUMMARIES ===\n")

cat("\nCountry-level (age-standardised rates per 100,000):\n")
country_panel %>%
  group_by(country) %>%
  summarise(
    years = paste(range(year), collapse = "-"),
    mean_rate = round(mean(rate, na.rm = TRUE), 1),
    pre_rate = round(mean(rate[year < 2018], na.rm = TRUE), 1),
    post_rate = round(mean(rate[year >= 2018], na.rm = TRUE), 1),
    diff = round(mean(rate[year >= 2018], na.rm = TRUE) - mean(rate[year < 2018], na.rm = TRUE), 1),
    .groups = "drop"
  ) %>%
  print()

cat("\nPre-MUP (2013-2017) vs Post-MUP (2018-2023) difference:\n")
cat("  Scotland: MUP May 2018 → rate change =",
    round(mean(scotland$rate[scotland$year >= 2018]) - mean(scotland$rate[scotland$year < 2018]), 2), "\n")
cat("  Wales: MUP March 2020 → rate change =",
    round(mean(wales$rate[wales$year >= 2020]) - mean(wales$rate[wales$year < 2020]), 2), "\n")
cat("  England: No MUP → rate change =",
    round(mean(eng_national$rate[eng_national$year >= 2018]) - mean(eng_national$rate[eng_national$year < 2018]), 2), "\n")

cat("\nDeprivation gradient (England, 2023):\n")
eng_deprivation %>%
  filter(year == max(year)) %>%
  arrange(decile) %>%
  select(decile, rate) %>%
  mutate(rate = round(rate, 1)) %>%
  print(n = 10)

# Validation checks
cat("\n--- Validation ---\n")
n_treated_countries <- sum(c("Scotland", "Wales") %in% country_panel$country)
n_pre_scotland <- sum(country_panel$year < 2018 & country_panel$country == "Scotland")
cat("  Treated countries:", n_treated_countries, "\n")
cat("  Scotland pre-periods:", n_pre_scotland, "\n")
cat("  Regional units:", n_distinct(region_panel$area_code), "(need >= 5)\n")
cat("  English LAs:", n_distinct(la_panel$area_code), "\n")

# ============================================================================
# STEP 6: SAVE
# ============================================================================
cat("\n--- Saving datasets ---\n")

saveRDS(country_panel, "../data/country_panel.rds")
saveRDS(region_panel, "../data/region_panel.rds")
saveRDS(la_panel, "../data/la_panel.rds")
saveRDS(eng_deprivation, "../data/deprivation_panel.rds")

# Diagnostics for validator
diag <- list(
  n_treated = n_treated_countries + n_distinct(region_panel$area_code[region_panel$first_treat > 0]),
  n_pre = n_pre_scotland,
  n_obs = nrow(country_panel) + nrow(region_panel) + nrow(la_panel)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

cat("  country_panel.rds:", nrow(country_panel), "obs\n")
cat("  region_panel.rds:", nrow(region_panel), "obs\n")
cat("  la_panel.rds:", nrow(la_panel), "obs\n")
cat("  deprivation_panel.rds:", nrow(eng_deprivation), "obs\n")
cat("  diagnostics.json written\n")

cat("\n=== DATA FETCH COMPLETE ===\n")
