## 01_fetch_data.R — Fetch CDC divorce/marriage rates + ACS marital status data
## APEP Paper apep_1035

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 1. CDC NVSS State Divorce Rates (1990–2022)
# ============================================================
# CDC publishes state-level divorce rates as an Excel file
# URL: https://www.cdc.gov/nchs/data/dvs/state-divorce-rates-90-95-99-22.xlsx

cdc_url <- "https://www.cdc.gov/nchs/data/dvs/marriage-divorce/state-divorce-rates-90-95-00-23.xlsx"
cdc_file <- file.path(data_dir, "cdc_divorce_rates.xlsx")

cat("Downloading CDC divorce rate data...\n")
resp <- httr::GET(cdc_url, httr::write_disk(cdc_file, overwrite = TRUE))
stopifnot("CDC download failed" = httr::status_code(resp) == 200)
cat("  Downloaded:", cdc_file, "\n")

# Parse the Excel file
cdc_raw <- readxl::read_excel(cdc_file, skip = 5)
cat("  Raw CDC rows:", nrow(cdc_raw), "\n")

# The file has states in rows and years in columns
# Column names are years; first column is state name
# Clean column names — they have the pattern "1990", "1995", "1999", "2000", ..., "2022"
names(cdc_raw)[1] <- "state_name"

# Remove footnote rows (non-state entries)
us_states <- c(state.name, "District of Columbia")
cdc_clean <- cdc_raw %>%
  filter(state_name %in% us_states)

# Convert all year columns to character first (some may be numeric, some character)
year_cols_div <- setdiff(names(cdc_clean), "state_name")
cdc_clean <- cdc_clean %>%
  mutate(across(all_of(year_cols_div), as.character))

# Pivot to long format
cdc_long <- cdc_clean %>%
  pivot_longer(
    cols = -state_name,
    names_to = "year",
    values_to = "divorce_rate"
  ) %>%
  mutate(
    year = as.integer(year),
    divorce_rate = as.numeric(divorce_rate)  # "---" becomes NA
  ) %>%
  filter(!is.na(year), !is.na(divorce_rate))

cat("  CDC long format:", nrow(cdc_long), "state-years\n")
cat("  Year range:", range(cdc_long$year), "\n")
cat("  States:", n_distinct(cdc_long$state_name), "\n")

saveRDS(cdc_long, file.path(data_dir, "cdc_divorce_rates.rds"))

# ============================================================
# 2. CDC NVSS State Marriage Rates
# ============================================================
cdc_marry_url <- "https://www.cdc.gov/nchs/data/dvs/marriage-divorce/state-marriage-rates-90-95-00-23.xlsx"
cdc_marry_file <- file.path(data_dir, "cdc_marriage_rates.xlsx")

cat("\nDownloading CDC marriage rate data...\n")
resp2 <- httr::GET(cdc_marry_url, httr::write_disk(cdc_marry_file, overwrite = TRUE))
stopifnot("CDC marriage download failed" = httr::status_code(resp2) == 200)
cat("  Downloaded:", cdc_marry_file, "\n")

marry_raw <- readxl::read_excel(cdc_marry_file, skip = 5)
names(marry_raw)[1] <- "state_name"

marry_clean <- marry_raw %>%
  filter(state_name %in% us_states)

# Convert all year columns to character first (some are numeric, some character due to "---")
year_cols <- setdiff(names(marry_clean), "state_name")
marry_clean <- marry_clean %>%
  mutate(across(all_of(year_cols), as.character))

marry_long <- marry_clean %>%
  pivot_longer(
    cols = -state_name,
    names_to = "year",
    values_to = "marriage_rate"
  ) %>%
  mutate(
    year = as.integer(year),
    marriage_rate = as.numeric(marriage_rate)  # "---" becomes NA
  ) %>%
  filter(!is.na(year), !is.na(marriage_rate))

cat("  Marriage rate data:", nrow(marry_long), "state-years\n")
saveRDS(marry_long, file.path(data_dir, "cdc_marriage_rates.rds"))

# ============================================================
# 3. ACS 1-Year Marital Status (B12001) — 2008–2022
# ============================================================
census_key <- Sys.getenv("CENSUS_API_KEY")
stopifnot("CENSUS_API_KEY not set" = nchar(census_key) > 0)

# B12001: Sex by Marital Status for Population 15 Years and Over
# B12001_001: Total
# B12001_003: Now married (male)
# B12001_012: Now married (female)
# B12001_005: Divorced (male)
# B12001_014: Divorced (female)
# B12001_004: Widowed (male)  — skip
# B12001_010: Separated (male)
# B12001_019: Separated (female)
# B12001_002: Never married (male)
# B12001_011: Never married (female)

acs_vars <- c(
  "B12001_001E",  # Total 15+
  "B12001_003E",  # Now married male
  "B12001_012E",  # Now married female
  "B12001_005E",  # Divorced male
  "B12001_014E",  # Divorced female
  "B12001_010E",  # Separated male
  "B12001_019E"   # Separated female
)

acs_years <- 2008:2022
acs_results <- list()

cat("\nFetching ACS 1-Year data...\n")
for (yr in acs_years) {
  url <- paste0(
    "https://api.census.gov/data/", yr, "/acs/acs1",
    "?get=NAME,", paste(acs_vars, collapse = ","),
    "&for=state:*",
    "&key=", census_key
  )

  resp <- httr::GET(url)
  if (httr::status_code(resp) != 200) {
    cat("  WARNING: ACS", yr, "failed with status", httr::status_code(resp), "\n")
    next
  }

  raw <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
  df <- as.data.frame(raw[-1, ], stringsAsFactors = FALSE)
  names(df) <- raw[1, ]
  df$year <- yr
  acs_results[[as.character(yr)]] <- df
  cat("  ACS", yr, ":", nrow(df), "states\n")
  Sys.sleep(0.5)  # rate limiting
}

acs_all <- bind_rows(acs_results)

# Convert to numeric
for (v in acs_vars) {
  acs_all[[v]] <- as.numeric(acs_all[[v]])
}
acs_all$state_fips <- as.integer(acs_all$state)

# Compute shares
acs_all <- acs_all %>%
  mutate(
    pop_15plus = B12001_001E,
    married = B12001_003E + B12001_012E,
    divorced = B12001_005E + B12001_014E,
    separated = B12001_010E + B12001_019E,
    pct_married = married / pop_15plus * 100,
    pct_divorced = divorced / pop_15plus * 100,
    pct_separated = separated / pop_15plus * 100
  )

cat("  ACS total:", nrow(acs_all), "state-years\n")
saveRDS(acs_all, file.path(data_dir, "acs_marital_status.rds"))

# ============================================================
# 4. BLS LAUS State Unemployment Rates
# ============================================================
cat("\nFetching BLS unemployment data...\n")

# State FIPS codes for LAUS series IDs
state_fips <- sprintf("%02d", c(1:2, 4:6, 8:13, 15:42, 44:51, 53:56))

laus_results <- list()

# BLS API v2 — process in smaller chunks, 10-year spans (API limit)
for (chunk_start in seq(1, length(state_fips), by = 25)) {
  chunk_end <- min(chunk_start + 24, length(state_fips))
  fips_chunk <- state_fips[chunk_start:chunk_end]
  series_ids <- paste0("LASST", fips_chunk, "0000000000003")

  for (decade in list(c("1990", "2009"), c("2010", "2023"))) {
    payload <- list(
      seriesid = series_ids,
      startyear = decade[1],
      endyear = decade[2],
      annualaverage = TRUE
    )

    resp <- httr::POST(
      "https://api.bls.gov/publicAPI/v2/timeseries/data/",
      httr::content_type_json(),
      body = jsonlite::toJSON(payload, auto_unbox = TRUE)
    )

    if (httr::status_code(resp) != 200) {
      cat("  WARNING: BLS chunk failed\n")
      next
    }

    result <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"),
                                  simplifyVector = FALSE)

    if (result$status == "REQUEST_SUCCEEDED") {
      for (s in result$Results$series) {
        fips_code <- substr(s$seriesID, 6, 7)
        for (d in s$data) {
          if (d$period == "M13") {
            laus_results[[length(laus_results) + 1]] <- tibble(
              state_fips = as.integer(fips_code),
              year = as.integer(d$year),
              unemployment_rate = as.numeric(d$value)
            )
          }
        }
      }
    }
    Sys.sleep(1)
  }
}

if (length(laus_results) > 0) {
  laus_all <- bind_rows(laus_results)
  cat("  BLS LAUS:", nrow(laus_all), "state-years\n")
  saveRDS(laus_all, file.path(data_dir, "bls_unemployment.rds"))
} else {
  cat("  WARNING: No BLS data retrieved\n")
}

cat("\n=== Data fetch complete ===\n")
cat("Files saved in:", data_dir, "\n")
list.files(data_dir, pattern = "\\.rds$")
