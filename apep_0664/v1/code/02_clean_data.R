## 02_clean_data.R — Clean and construct analysis panel
## apep_0664: Finland Competitiveness Pact

source("code/00_packages.R")

cat("=== Cleaning data ===\n")

## ---- Load raw data ----
hours_raw <- readRDS("data/hours_raw.rds")
gva_raw   <- readRDS("data/gva_raw.rds")

## ---- Clean hours/employment data ----
# Identify columns
cat("Hours columns:", paste(names(hours_raw), collapse = ", "), "\n")

hours <- hours_raw %>%
  select(
    country = geo,
    year = TIME_PERIOD,
    sector = nace_r2,
    indicator = unit,
    value = OBS_VALUE
  ) %>%
  filter(!is.na(value)) %>%
  pivot_wider(names_from = indicator, values_from = value) %>%
  rename(
    hours_thsd = THS_HW,
    employment_thsd = THS_PER
  ) %>%
  mutate(
    year = as.integer(year),
    hours_per_worker = hours_thsd / employment_thsd
  )

## ---- Clean GVA data ----
cat("GVA columns:", paste(names(gva_raw), collapse = ", "), "\n")

## GVA: multiple na_item values may cause duplicates. Keep only B1GQ (value added)
## and CLV10_MEUR (chain-linked volume)
gva <- gva_raw %>%
  filter(unit == "CLV10_MEUR") %>%
  select(
    country = geo,
    year = TIME_PERIOD,
    sector = nace_r2,
    na_item,
    value = OBS_VALUE
  ) %>%
  filter(!is.na(value), na_item == "B1G") %>%  # B1G = gross value added
  select(country, year, sector, gva_real = value) %>%
  distinct() %>%
  mutate(year = as.integer(year))

cat("GVA cleaned rows:", nrow(gva), "\n")

gva_clean <- gva %>%
  filter(!is.na(gva_real))

## ---- Merge into analysis panel ----
panel <- hours %>%
  left_join(gva_clean, by = c("country", "year", "sector")) %>%
  filter(year >= 2008, year <= 2022)

## ---- Construct variables ----
panel <- panel %>%
  mutate(
    # Treatment indicators
    finland = as.integer(country == "FI"),
    post = as.integer(year >= 2017),
    treat_did = finland * post,

    # Sector classification
    public_sector = as.integer(sector %in% c("O-Q")),
    triple_did = finland * post * public_sector,

    # Log outcomes
    ln_hours = log(hours_thsd),
    ln_employment = log(employment_thsd),
    ln_hours_pw = log(hours_per_worker),

    # Productivity (GVA per hour worked, in EUR)
    productivity = ifelse(!is.na(gva_real) & hours_thsd > 0,
                          gva_real * 1000 / hours_thsd, NA),  # M EUR to thsd EUR / thsd hours
    ln_productivity = ifelse(!is.na(productivity) & productivity > 0,
                             log(productivity), NA),

    # Country-sector and country-year identifiers
    country_sector = paste(country, sector, sep = "_"),
    country_year = paste(country, year, sep = "_"),

    # Relative time for event study
    rel_time = year - 2017
  )

## ---- Drop TOTAL row (avoid double counting) ----
panel <- panel %>% filter(sector != "TOTAL")

## ---- Summary ----
cat("\n=== Panel summary ===\n")
cat("Rows:", nrow(panel), "\n")
cat("Countries:", paste(unique(panel$country), collapse = ", "), "\n")
cat("Years:", paste(range(panel$year), collapse = "-"), "\n")
cat("Sectors:", paste(sort(unique(panel$sector)), collapse = ", "), "\n")
cat("Observations per country-year:\n")
print(table(panel$country, panel$year))

## ---- Save ----
saveRDS(panel, "data/panel.rds")

cat("\nPanel saved to data/panel.rds\n")
