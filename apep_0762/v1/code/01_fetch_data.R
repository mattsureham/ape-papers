## =============================================================================
## 01_fetch_data.R — Fetch Zillow ZHVI + build treatment assignment
## apep_0762
## =============================================================================

source("00_packages.R")

cat("=== Step 1: Build Dark Sky Community treatment data ===\n")

## ---- Treatment data: DarkSky International Dark Sky Communities (US) ----
## Source: DarkSky International public records
## https://darksky.org/what-we-do/international-dark-sky-places/communities/
##
## Each community must adopt a legally enforceable lighting ordinance, conduct
## public education, and demonstrate verified compliance to receive certification.

dark_sky_communities <- tribble(
  ~community,              ~state, ~year_designated, ~zip_codes,
  "Flagstaff",             "AZ",   2001,             "86001,86002,86003,86004,86005,86011",
  "Tucson",                "AZ",   2012,             "85701,85702,85704,85705,85706,85710,85711,85712,85713,85714,85715,85716,85718,85719,85730",
  "Sedona",                "AZ",   2014,             "86336,86340,86351",
  "Fountain Hills",        "AZ",   2018,             "85268,85269",
  "Camp Verde",            "AZ",   2019,             "86322",
  "Cottonwood",            "AZ",   2019,             "86326",
  "Clarkdale",             "AZ",   2021,             "86324",
  "Borrego Springs",       "CA",   2009,             "92004",
  "Julian",                "CA",   2021,             "92036",
  "Westcliffe",            "CO",   2015,             "81252",
  "Ketchum",               "ID",   2020,             "83340",
  "Homer Glen",            "IL",   2017,             "60491",
  "Beverly Shores",        "IN",   2019,             "46301",
  "Bon Secour",            "AL",   2022,             "36511",
  "Big Park/Village of Oak Creek", "AZ", 2014,       "86351",
  "Horsehead Bay",         "TX",   2019,             "78657",
  "Dripping Springs",      "TX",   2014,             "78620",
  "Wimberley",             "TX",   2020,             "78676",
  "Fredericksburg",        "TX",   2019,             "78624",
  "Bee Cave",              "TX",   2022,             "78738",
  "Lakeway",               "TX",   2022,             "78734",
  "Torrey",                "UT",   2018,             "84775",
  "Helper",                "UT",   2021,             "84526",
  "Kanab",                 "UT",   2023,             "84741",
  "Manti",                 "UT",   2023,             "84642",
  "Northumberland",        "PA",   2022,             "17857",
  "Woodstock",             "NY",   2023,             "12498",
  "Big Bear Lake",         "CA",   2023,             "92315",
  "Elko New Market",       "MN",   2021,             "55054"
)

## Expand zip codes to one row per zip
treatment_zips <- dark_sky_communities %>%
  separate_rows(zip_codes, sep = ",") %>%
  mutate(zip_code = str_trim(zip_codes)) %>%
  select(community, state, year_designated, zip_code) %>%
  distinct(zip_code, .keep_all = TRUE)

cat(sprintf("  Treated communities: %d\n", n_distinct(dark_sky_communities$community)))
cat(sprintf("  Treated zip codes: %d\n", nrow(treatment_zips)))

## ---- Fetch Zillow ZHVI data ----
cat("\n=== Step 2: Fetch Zillow ZHVI (zip-level, monthly) ===\n")

## Zillow ZHVI: Zillow Home Value Index, zip-level, monthly, all homes
## This is the smoothed, seasonally adjusted measure of home values
zhvi_url <- "https://files.zillowstatic.com/research/public_csvs/zhvi/Zip_zhvi_uc_sfrcondo_tier_0.33_0.67_sm_sa_month.csv"

zhvi_file <- "../data/zhvi_zip_monthly.csv"
if (!file.exists(zhvi_file)) {
  cat("  Downloading ZHVI from Zillow Research...\n")
  download.file(zhvi_url, zhvi_file, mode = "wb", quiet = FALSE)
  if (!file.exists(zhvi_file) || file.size(zhvi_file) < 1000) {
    stop("FATAL: Failed to download Zillow ZHVI data. Cannot proceed without real data.")
  }
}

zhvi_raw <- fread(zhvi_file, showProgress = FALSE)
cat(sprintf("  ZHVI raw: %d zip codes, %d columns\n", nrow(zhvi_raw), ncol(zhvi_raw)))

## Validate data is real (check known zip codes)
test_zip <- zhvi_raw %>% filter(RegionName == 86001)  # Flagstaff
if (nrow(test_zip) == 0) {
  stop("FATAL: Zillow data validation failed — Flagstaff zip 86001 not found")
}
cat("  Data validation passed: Flagstaff (86001) present in dataset.\n")

## ---- Reshape ZHVI to long panel ----
cat("\n=== Step 3: Reshape ZHVI to panel format ===\n")

# Identify date columns (format: YYYY-MM-DD)
date_cols <- names(zhvi_raw)[grepl("^\\d{4}-\\d{2}-\\d{2}$", names(zhvi_raw))]
cat(sprintf("  Date columns: %d (from %s to %s)\n",
            length(date_cols), min(date_cols), max(date_cols)))

# Reshape
zhvi_long <- zhvi_raw %>%
  select(RegionName, StateName, City, Metro, SizeRank, all_of(date_cols)) %>%
  pivot_longer(
    cols = all_of(date_cols),
    names_to = "date",
    values_to = "zhvi"
  ) %>%
  mutate(
    zip_code = sprintf("%05d", RegionName),
    date = as.Date(date),
    year = year(date),
    month = month(date),
    year_month = year + (month - 1) / 12
  ) %>%
  filter(!is.na(zhvi), zhvi > 0)

cat(sprintf("  Panel: %s observations, %d zip codes\n",
            format(nrow(zhvi_long), big.mark = ","),
            n_distinct(zhvi_long$zip_code)))

## ---- Merge treatment status ----
cat("\n=== Step 4: Merge treatment assignment ===\n")

zhvi_panel <- zhvi_long %>%
  left_join(treatment_zips %>% select(zip_code, community, year_designated),
            by = "zip_code") %>%
  mutate(
    treated = ifelse(!is.na(community), 1, 0),
    post = ifelse(!is.na(year_designated) & year >= year_designated, 1, 0),
    first_treat = ifelse(treated == 1, year_designated, 0)
  )

n_treated_zips <- zhvi_panel %>% filter(treated == 1) %>% pull(zip_code) %>% n_distinct()
cat(sprintf("  Matched treated zip codes in ZHVI: %d\n", n_treated_zips))

if (n_treated_zips < 20) {
  warning(sprintf("Only %d treated zips found in ZHVI data. Checking for missing zips...", n_treated_zips))
  missing <- treatment_zips %>%
    filter(!zip_code %in% zhvi_panel$zip_code)
  if (nrow(missing) > 0) {
    cat("  Missing from ZHVI:", paste(missing$zip_code, collapse = ", "), "\n")
  }
}

## ---- Save intermediate data ----
cat("\n=== Step 5: Save treatment and panel data ===\n")

saveRDS(treatment_zips, "../data/treatment_zips.rds")
saveRDS(zhvi_panel, "../data/zhvi_panel_full.rds")

cat(sprintf("  Saved: treatment_zips.rds (%d rows)\n", nrow(treatment_zips)))
cat(sprintf("  Saved: zhvi_panel_full.rds (%s rows)\n",
            format(nrow(zhvi_panel), big.mark = ",")))
cat("  DONE.\n")
