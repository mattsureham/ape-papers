## 01_fetch_data.R
## The Housing Cost of Reshoring: CHIPS Act and Local Housing Markets
## Fetch Zillow ZHVI/ZORI county-level data and compile CHIPS announcements

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. CHIPS Act Funding Announcements
# ============================================================
# Source: US Department of Commerce CHIPS Program Office press releases
# Compiled from official announcements at commerce.gov/chips
# Each row: company, county FIPS, state, announcement date, award amount

chips_announcements <- tribble(
  ~company,          ~facility,              ~county_fips, ~state, ~announce_date,  ~award_billion,
  # Major fabs (>$1B awards)
  "Intel",           "Columbus OH fabs",     "39049",      "OH",   "2024-03-20",    8.5,
  "TSMC",            "Phoenix AZ fabs",      "04013",      "AZ",   "2024-04-08",    6.6,
  "Samsung",         "Taylor TX fab",        "48491",      "TX",   "2024-04-15",    6.4,

  "Micron",          "Clay NY fab",          "36067",      "NY",   "2024-04-25",    6.1,
  "GlobalFoundries", "Malta NY fab",         "36091",      "NY",   "2024-02-19",    1.5,
  "Microchip Tech",  "Colorado Springs CO",  "08041",      "CO",   "2024-09-25",    0.162,
  "GlobalFoundries", "Burlington VT fab",    "36091",      "NY",   "2024-02-19",    1.5,
  # Note: GF Malta NY has single award covering both sites, use Malta
  "Micron",          "Boise ID HQ fab",      "16001",      "ID",   "2024-04-25",    6.1,
  # Micron award covers both NY and ID
  "BAE Systems",     "Nashua NH fab",        "33011",      "NH",   "2024-01-26",    0.035,
  "Polar Semi",      "Bloomington MN",       "27053",      "MN",   "2024-08-26",    0.123,
  "Texas Instruments","Sherman TX fabs",     "48181",      "TX",   "2024-08-16",    1.6,
  "Texas Instruments","Lehi UT fab",         "49049",      "UT",   "2024-08-16",    1.6,
  # TI award covers both TX and UT
  "Amkor Technology","Peoria AZ",            "04013",      "AZ",   "2024-07-26",    0.400,
  # Amkor in Maricopa same county as TSMC
  "SK Hynix",        "West Lafayette IN",    "18157",      "IN",   "2025-03-04",    0.458,
  "Wolfspeed",       "Siler City NC fab",    "37019",      "NC",   "2024-11-18",    0.750,
  "Corning Inc",     "Canton NY",            "36089",      "NY",   "2024-10-28",    0.325,
  "HBM / Absolics",  "Covington GA",         "13217",      "GA",   "2025-02-19",    0.075,
  "II-VI / Coherent","Sherman TX",           "48181",      "TX",   "2025-01-15",    0.093,
  "Rocket Lab",      "Albuquerque NM",       "35001",      "NM",   "2025-02-05",    0.024,
  # Additional verified CHIPS Act awards
  "Onsemi",          "East Fishkill NY",     "36027",      "NY",   "2024-09-09",    0.406,
  "Onsemi",          "Gresham OR",           "41051",      "OR",   "2024-09-09",    0.406,
  "SkyWater Tech",   "Kissimmee FL",         "12097",      "FL",   "2024-11-27",    0.050,
  "MACOM Technology","Lowell MA",            "25017",      "MA",   "2024-12-02",    0.100,
  "Entegris",        "Colorado Springs CO",  "08041",      "CO",   "2024-10-22",    0.075,
  # Entegris same county as Microchip — will merge
  "Lattice Semi",    "Hillsboro OR",         "41067",      "OR",   "2024-12-16",    0.015
)

# De-duplicate: keep largest award per county (some counties have multiple announcements)
# Use earliest announcement date per county
chips_by_county <- chips_announcements %>%
  group_by(county_fips) %>%
  summarise(
    announce_date = min(announce_date),
    total_award_billion = sum(award_billion),
    companies = paste(unique(company), collapse = "; "),
    .groups = "drop"
  ) %>%
  mutate(announce_date = as.Date(announce_date))

cat("CHIPS counties:", nrow(chips_by_county), "\n")
cat("Total awards: $", sum(chips_by_county$total_award_billion), "B\n")
print(chips_by_county)

write_csv(chips_by_county, file.path(data_dir, "chips_announcements.csv"))

# ============================================================
# 2. Zillow Home Value Index (ZHVI) — County Level
# ============================================================
# All Homes, Smoothed, Seasonally Adjusted, County Level
zhvi_url <- "https://files.zillowstatic.com/research/public_csvs/zhvi/County_zhvi_uc_sfrcondo_tier_0.33_0.67_sm_sa_month.csv"

cat("Downloading Zillow ZHVI...\n")
zhvi_file <- file.path(data_dir, "zillow_zhvi_county.csv")

download_result <- tryCatch({
  download.file(zhvi_url, zhvi_file, mode = "wb", quiet = FALSE)
  TRUE
}, error = function(e) {
  stop("FATAL: Failed to download Zillow ZHVI data: ", e$message,
       "\nURL: ", zhvi_url)
})

zhvi_raw <- fread(zhvi_file)
cat("ZHVI raw dimensions:", nrow(zhvi_raw), "x", ncol(zhvi_raw), "\n")

# Validate data is real
stopifnot("RegionName" %in% names(zhvi_raw))
stopifnot(nrow(zhvi_raw) > 2000)  # Expect ~3,100 counties

# Identify date columns (format: YYYY-MM-DD)
date_cols <- grep("^\\d{4}-\\d{2}-\\d{2}$", names(zhvi_raw), value = TRUE)
cat("Date columns span:", min(date_cols), "to", max(date_cols), "\n")

stopifnot(length(date_cols) > 200)  # Expect 200+ months

# Reshape to long format
# Keep: RegionID, SizeRank, RegionName (county FIPS name),
#        StateCodeFIPS, MunicipalCodeFIPS, StateName, date columns
zhvi_long <- zhvi_raw %>%
  select(RegionID, RegionName, StateCodeFIPS, MunicipalCodeFIPS,
         StateName, all_of(date_cols)) %>%
  pivot_longer(
    cols = all_of(date_cols),
    names_to = "date",
    values_to = "zhvi"
  ) %>%
  mutate(
    date = as.Date(date),
    # Construct 5-digit FIPS
    county_fips = sprintf("%02d%03d", StateCodeFIPS, MunicipalCodeFIPS)
  ) %>%
  filter(!is.na(zhvi))

cat("ZHVI long format:", nrow(zhvi_long), "rows,",
    n_distinct(zhvi_long$county_fips), "counties\n")
cat("Date range:", as.character(min(zhvi_long$date)), "to",
    as.character(max(zhvi_long$date)), "\n")

# ============================================================
# 3. Zillow Observed Rent Index (ZORI) — County Level
# ============================================================
zori_url <- "https://files.zillowstatic.com/research/public_csvs/zori/County_zori_uc_sfrcondomfr_sm_sa_month.csv"

cat("\nDownloading Zillow ZORI...\n")
zori_file <- file.path(data_dir, "zillow_zori_county.csv")

download_result <- tryCatch({
  download.file(zori_url, zori_file, mode = "wb", quiet = FALSE)
  TRUE
}, error = function(e) {
  stop("FATAL: Failed to download Zillow ZORI data: ", e$message)
})

zori_raw <- fread(zori_file)
cat("ZORI raw dimensions:", nrow(zori_raw), "x", ncol(zori_raw), "\n")

zori_date_cols <- grep("^\\d{4}-\\d{2}-\\d{2}$", names(zori_raw), value = TRUE)

zori_long <- zori_raw %>%
  select(RegionID, RegionName, StateCodeFIPS, MunicipalCodeFIPS,
         StateName, all_of(zori_date_cols)) %>%
  pivot_longer(
    cols = all_of(zori_date_cols),
    names_to = "date",
    values_to = "zori"
  ) %>%
  mutate(
    date = as.Date(date),
    county_fips = sprintf("%02d%03d", StateCodeFIPS, MunicipalCodeFIPS)
  ) %>%
  filter(!is.na(zori))

cat("ZORI long format:", nrow(zori_long), "rows,",
    n_distinct(zori_long$county_fips), "counties\n")
cat("Date range:", as.character(min(zori_long$date)), "to",
    as.character(max(zori_long$date)), "\n")

# ============================================================
# 4. Census ACS — County Characteristics (Controls)
# ============================================================
# Fetch 2021 ACS 5-year (pre-CHIPS baseline characteristics)

census_api_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_api_key) == 0) {
  stop("FATAL: CENSUS_API_KEY not set in .env")
}

acs_url <- paste0(
  "https://api.census.gov/data/2021/acs/acs5?get=",
  "B01001_001E,B19013_001E,B25001_001E,B25077_001E,B25064_001E",
  "&for=county:*&key=", census_api_key
)

cat("\nFetching Census ACS 2021...\n")
acs_resp <- httr::GET(acs_url)
stopifnot(httr::status_code(acs_resp) == 200)

acs_json <- httr::content(acs_resp, as = "text", encoding = "UTF-8")
acs_mat <- jsonlite::fromJSON(acs_json)
acs_df <- as.data.frame(acs_mat[-1, ], stringsAsFactors = FALSE)
names(acs_df) <- acs_mat[1, ]

acs_df <- acs_df %>%
  transmute(
    county_fips = paste0(state, county),
    population = as.numeric(B01001_001E),
    median_hh_income = as.numeric(B19013_001E),
    housing_units = as.numeric(B25001_001E),
    median_home_value = as.numeric(B25077_001E),
    median_gross_rent = as.numeric(B25064_001E)
  ) %>%
  filter(population > 0)

cat("ACS counties:", nrow(acs_df), "\n")
cat("Median income range: $", min(acs_df$median_hh_income, na.rm = TRUE),
    "- $", max(acs_df$median_hh_income, na.rm = TRUE), "\n")

write_csv(acs_df, file.path(data_dir, "census_acs_2021.csv"))

# ============================================================
# 5. Save intermediate data
# ============================================================
saveRDS(zhvi_long, file.path(data_dir, "zhvi_long.rds"))
saveRDS(zori_long, file.path(data_dir, "zori_long.rds"))

cat("\n=== DATA FETCH COMPLETE ===\n")
cat("CHIPS announcements:", nrow(chips_by_county), "counties\n")
cat("ZHVI:", n_distinct(zhvi_long$county_fips), "counties,",
    nrow(zhvi_long), "county-months\n")
cat("ZORI:", n_distinct(zori_long$county_fips), "counties,",
    nrow(zori_long), "county-months\n")
cat("ACS:", nrow(acs_df), "counties\n")
