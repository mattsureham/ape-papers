# 01_fetch_data.R — Fetch ACS 5-year county-level tenure data by race
source("00_packages.R")

# Variables: Black and White non-Hispanic tenure
vars <- c(
  black_total  = "B25003B_001",  # Black HH total
  black_owner  = "B25003B_002",  # Black HH owner-occupied
  white_total  = "B25003H_001",  # White NH HH total
  white_owner  = "B25003H_002",  # White NH HH owner-occupied
  total_pop    = "B01003_001",   # Total population
  med_hvalue   = "B25077_001"    # Median home value
)

# Fetch ACS 5-year estimates for 2009-2023 (all counties)
years <- 2009:2023

fetch_year <- function(yr) {
  cat(sprintf("Fetching ACS 5-year data for %d...\n", yr))
  df <- get_acs(
    geography = "county",
    variables = vars,
    year = yr,
    survey = "acs5",
    output = "wide"
  )
  if (is.null(df) || nrow(df) == 0) {
    stop(sprintf("ACS API returned no data for year %d", yr))
  }
  df$year <- yr
  cat(sprintf("  Year %d: %d counties returned.\n", yr, nrow(df)))
  df
}

all_data <- map(years, fetch_year) |> bind_rows()

cat(sprintf("\nTotal observations: %d rows across %d years.\n",
            nrow(all_data), n_distinct(all_data$year)))
cat(sprintf("Unique counties: %d\n", n_distinct(all_data$GEOID)))

# Validate: no empty results
stopifnot(nrow(all_data) > 0)
stopifnot(n_distinct(all_data$year) == length(years))

# Save raw data
write_csv(all_data, "../data/acs_raw.csv")
cat("Saved: data/acs_raw.csv\n")
