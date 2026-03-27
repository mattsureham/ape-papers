## 01_fetch_data.R — Fetch ACS earnings + employment data for CROWN Act analysis
## apep_1066 v1

source("00_packages.R")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) == 0) stop("CENSUS_API_KEY not set in .env")

## ---- CROWN Act treatment assignment ----
crown_states <- tribble(
  ~state_fips, ~state_abbr, ~crown_year,
  "06", "CA", 2019,
  "36", "NY", 2019,
  "34", "NJ", 2019,
  "24", "MD", 2020,
  "08", "CO", 2020,
  "53", "WA", 2020,
  "51", "VA", 2020,
  "09", "CT", 2021,
  "10", "DE", 2021,
  "35", "NM", 2021,
  "32", "NV", 2021,
  "31", "NE", 2021,
  "41", "OR", 2021,
  "17", "IL", 2021,
  "23", "ME", 2022,
  "47", "TN", 2022,
  "25", "MA", 2022,
  "22", "LA", 2022,
  "27", "MN", 2023,
  "48", "TX", 2023,
  "26", "MI", 2023,
  "05", "AR", 2023
)

## ---- Helper: fetch one ACS table for all states in one year ----
fetch_acs_table <- function(table_id, year, key) {
  base_url <- sprintf(
    "https://api.census.gov/data/%d/acs/acs1?get=NAME,%s&for=state:*&key=%s",
    year, table_id, key
  )
  resp <- httr::GET(base_url, httr::timeout(60))
  if (httr::status_code(resp) != 200) {
    stop(sprintf("ACS API error %d for table %s year %d",
                 httr::status_code(resp), table_id, year))
  }
  raw <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
  df <- as.data.frame(raw[-1, ], stringsAsFactors = FALSE)
  names(df) <- raw[1, ]
  df$year <- year
  df
}

## ---- Fetch earnings data ----
## B20017B: Black median earnings by sex
##   B20017B_001E = total, B20017B_002E = male, B20017B_005E = female
## B20017H: White non-Hispanic median earnings by sex
##   B20017H_001E = total, B20017H_002E = male, B20017H_005E = female

earnings_vars_black <- "B20017B_001E,B20017B_002E,B20017B_005E"
earnings_vars_white <- "B20017H_001E,B20017H_002E,B20017H_005E"

years <- c(2014, 2015, 2016, 2017, 2018, 2019, 2021, 2022, 2023)

cat("Fetching Black earnings data...\n")
black_earn_list <- lapply(years, function(y) {
  cat(sprintf("  Year %d...\n", y))
  fetch_acs_table(earnings_vars_black, y, census_key)
})
black_earn <- bind_rows(black_earn_list)

cat("Fetching White non-Hispanic earnings data...\n")
white_earn_list <- lapply(years, function(y) {
  cat(sprintf("  Year %d...\n", y))
  fetch_acs_table(earnings_vars_white, y, census_key)
})
white_earn <- bind_rows(white_earn_list)

## ---- Fetch employment data ----
## B23002B: Black employment by sex
##   B23002B_001E = total, B23002B_003E = male 16-64 total,
##   B23002B_006E = male in labor force employed,
##   B23002B_016E = female 16-64 total,
##   B23002B_019E = female in labor force employed
## B23002H: White non-Hispanic employment by sex
##   Same structure

emp_vars_black <- "B23002B_001E,B23002B_003E,B23002B_006E,B23002B_016E,B23002B_019E"
emp_vars_white <- "B23002H_001E,B23002H_003E,B23002H_006E,B23002H_016E,B23002H_019E"

cat("Fetching Black employment data...\n")
black_emp_list <- lapply(years, function(y) {
  cat(sprintf("  Year %d...\n", y))
  fetch_acs_table(emp_vars_black, y, census_key)
})
black_emp <- bind_rows(black_emp_list)

cat("Fetching White non-Hispanic employment data...\n")
white_emp_list <- lapply(years, function(y) {
  cat(sprintf("  Year %d...\n", y))
  fetch_acs_table(emp_vars_white, y, census_key)
})
white_emp <- bind_rows(white_emp_list)

## ---- Validate data ----
stopifnot("No Black earnings data" = nrow(black_earn) > 0)
stopifnot("No White earnings data" = nrow(white_earn) > 0)
stopifnot("No Black employment data" = nrow(black_emp) > 0)
stopifnot("No White employment data" = nrow(white_emp) > 0)

cat(sprintf("Black earnings: %d rows\n", nrow(black_earn)))
cat(sprintf("White earnings: %d rows\n", nrow(white_earn)))
cat(sprintf("Black employment: %d rows\n", nrow(black_emp)))
cat(sprintf("White employment: %d rows\n", nrow(white_emp)))

## ---- Save raw data ----
save(black_earn, white_earn, black_emp, white_emp, crown_states,
     file = "../data/raw_acs.RData")
cat("Raw data saved to data/raw_acs.RData\n")
