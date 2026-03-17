## 01_fetch_data.R — Fetch Census ACS broadband + BDS firm births
## Paper: Municipal Broadband Preemption and Digital Entrepreneurship

source("code/00_packages.R")

## ============================================================
## 1. CENSUS ACS BROADBAND SUBSCRIPTION DATA (B28002)
##    State-level, 2015-2023 (ACS 1-year estimates)
## ============================================================

fetch_acs_broadband <- function(year) {
  url <- paste0(
    "https://api.census.gov/data/", year, "/acs/acs1",
    "?get=NAME,B28002_001E,B28002_002E,B28002_004E,B28002_013E",
    "&for=state:*",
    ifelse(Sys.getenv("CENSUS_API_KEY") != "",
           paste0("&key=", Sys.getenv("CENSUS_API_KEY")), "")
  )
  resp <- fromJSON(url)
  df <- as.data.frame(resp[-1, ], stringsAsFactors = FALSE)
  names(df) <- resp[1, ]
  df$year <- year
  df <- df %>%
    mutate(
      households_total = as.numeric(B28002_001E),
      has_internet = as.numeric(B28002_002E),
      has_broadband = as.numeric(B28002_004E),
      no_internet = as.numeric(B28002_013E)
    ) %>%
    filter(households_total > 0) %>%
    mutate(
      broadband_rate = has_broadband / households_total,
      internet_rate = has_internet / households_total
    ) %>%
    select(state, NAME, year, households_total, has_broadband, broadband_rate, internet_rate, no_internet)
  return(df)
}

## Note: 2020 ACS 1-year was not released (COVID); skip it
acs_years <- c(2015, 2016, 2017, 2018, 2019, 2021, 2022, 2023)

cat("Fetching ACS broadband data for years:", paste(acs_years, collapse=", "), "\n")
acs_list <- lapply(acs_years, function(y) {
  cat("  Year:", y, "...")
  df <- tryCatch(
    fetch_acs_broadband(y),
    error = function(e) {
      stop(paste("ACS fetch failed for year", y, ":", conditionMessage(e)))
    }
  )
  cat("OK (", nrow(df), "states)\n")
  df
})

acs_broadband <- bind_rows(acs_list)

## Validate
stopifnot("ACS broadband must have 8 years × ~52 states" = nrow(acs_broadband) >= 8 * 50)
stopifnot("Broadband rate must be between 0 and 1" =
  all(acs_broadband$broadband_rate > 0 & acs_broadband$broadband_rate <= 1, na.rm=TRUE))

cat("\nACS broadband data: ", nrow(acs_broadband), "rows\n")
cat("Year range:", min(acs_broadband$year), "-", max(acs_broadband$year), "\n")
cat("National mean broadband rate (2021):",
    round(mean(acs_broadband$broadband_rate[acs_broadband$year==2021], na.rm=TRUE), 3), "\n")

## ============================================================
## 2. CENSUS BDS FIRM BIRTHS (STATE × YEAR)
## ============================================================

fetch_bds <- function(year) {
  url <- paste0(
    "https://api.census.gov/data/timeseries/bds",
    "?get=FIRM,ESTAB,EMP,JOB_CREATION_BIRTHS",
    "&for=state:*",
    "&YEAR=", year,
    ifelse(Sys.getenv("CENSUS_API_KEY") != "",
           paste0("&key=", Sys.getenv("CENSUS_API_KEY")), "")
  )
  resp <- fromJSON(url)
  df <- as.data.frame(resp[-1, ], stringsAsFactors = FALSE)
  names(df) <- resp[1, ]
  df$year_obs <- year
  df <- df %>%
    mutate(
      firms = as.numeric(FIRM),
      establishments = as.numeric(ESTAB),
      employment = as.numeric(EMP),
      job_creation_births = as.numeric(JOB_CREATION_BIRTHS)
    ) %>%
    mutate(firm_birth_rate = job_creation_births / firms) %>%
    select(state, year_obs, firms, establishments, employment, job_creation_births, firm_birth_rate)
  return(df)
}

## BDS available 2004-2023 at state level (pre-2004 state-level data may be limited)
bds_years <- 2004:2023

cat("\nFetching BDS firm births for years:", paste(range(bds_years), collapse="-"), "\n")
bds_list <- lapply(bds_years, function(y) {
  cat("  Year:", y, "...")
  df <- tryCatch(
    fetch_bds(y),
    error = function(e) {
      stop(paste("BDS fetch failed for year", y, ":", conditionMessage(e)))
    }
  )
  cat("OK (", nrow(df), "states)\n")
  df
})

bds_firms <- bind_rows(bds_list)

## Validate
stopifnot("BDS must have 20 years × ~51 states" = nrow(bds_firms) >= 20 * 48)
stopifnot("Firm birth rate must be positive" =
  all(bds_firms$firm_birth_rate > 0, na.rm=TRUE))

cat("\nBDS data:", nrow(bds_firms), "rows\n")
cat("Year range:", min(bds_firms$year_obs), "-", max(bds_firms$year_obs), "\n")

## ============================================================
## 3. PREEMPTION LAW DATES
## ============================================================
## Source: NCSL municipal broadband legislation tracker, BroadbandNow (2024),
##         specific state legislation citations per idea_0087 manifest

preemption_laws <- tribble(
  ~state_name,             ~state_fip, ~year_enacted, ~year_repealed, ~law_type,
  # Strong preemption (outright prohibition or near-total restriction)
  "Texas",                 "48",        1997,          NA,             "prohibition",
  "Missouri",              "29",        1997,          NA,             "prohibition",
  "Tennessee",             "47",        1999,          NA,             "prohibition",
  "Wisconsin",             "55",        1999,          2022,           "partial",
  "Virginia",              "51",        2003,          NA,             "restriction",
  "Florida",               "12",        2005,          NA,             "restriction",
  "Colorado",              "08",        2005,          2023,           "restriction",
  "Minnesota",             "27",        2001,          2023,           "restriction",
  "Pennsylvania",          "42",        2004,          NA,             "restriction",
  "Louisiana",             "22",        2004,          NA,             "restriction",
  "North Carolina",        "37",        2011,          NA,             "prohibition",
  "Utah",                  "49",        2001,          NA,             "restriction",
  "Nebraska",              "31",        2012,          NA,             "restriction",
  "Montana",               "30",        2015,          NA,             "restriction",
  "Alabama",               "01",        2012,          NA,             "restriction",
  "South Carolina",        "45",        2002,          NA,             "prohibition",
  "Arkansas",              "05",        2011,          2021,           "restriction",
  "Iowa",                  "19",        2004,          NA,             "restriction",
  "Michigan",              "26",        2005,          NA,             "restriction",
  "Mississippi",           "28",        2002,          NA,             "prohibition",
  "Arizona",               "04",        2017,          NA,             "restriction",
  "Washington",            "53",        2000,          2022,           "partial"
)

## The full set of FIPS codes for states
## We'll merge with state name/fips from Census data
cat("\nPreemption law coding:\n")
cat("Total preempted states:", nrow(preemption_laws), "\n")
cat("States with repeals:", sum(!is.na(preemption_laws$year_repealed)), "\n")
print(preemption_laws)

## ============================================================
## 4. SAVE DATA
## ============================================================
saveRDS(acs_broadband, "data/acs_broadband.rds")
saveRDS(bds_firms, "data/bds_firms.rds")
saveRDS(preemption_laws, "data/preemption_laws.rds")

cat("\n=== DATA FETCH COMPLETE ===\n")
cat("acs_broadband:", nrow(acs_broadband), "rows\n")
cat("bds_firms:", nrow(bds_firms), "rows\n")
cat("preemption_laws:", nrow(preemption_laws), "rows\n")
cat("Coverage: broadband 2015-2023, BDS 2004-2023, 22 preempted states\n")
