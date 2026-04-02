## 01_fetch_data.R — Fetch Census Building Permits Survey data
## County-level annual permits by structure type, 2004-2024

source("00_packages.R")

cat("=== Fetching Census Building Permits Survey data ===\n")

years <- 2004:2024
base_url <- "https://www2.census.gov/econ/bps/County"

# Column names for BPS county files (two header rows, manually specified)
bps_cols <- c(
  "year", "state_fips", "county_fips", "region", "division", "county_name",
  "units1_bldgs", "units1_units", "units1_value",
  "units2_bldgs", "units2_units", "units2_value",
  "units34_bldgs", "units34_units", "units34_value",
  "units5p_bldgs", "units5p_units", "units5p_value",
  "units1r_bldgs", "units1r_units", "units1r_value",
  "units2r_bldgs", "units2r_units", "units2r_value",
  "units34r_bldgs", "units34r_units", "units34r_value",
  "units5pr_bldgs", "units5pr_units", "units5pr_value"
)

fetch_bps_year <- function(yr) {
  url <- sprintf("%s/co%da.txt", base_url, yr)
  resp <- httr::GET(url, httr::timeout(60))

  if (httr::status_code(resp) != 200) {
    stop(sprintf("FATAL: HTTP %d for year %d", httr::status_code(resp), yr))
  }

  content <- httr::content(resp, as = "text", encoding = "UTF-8")

  # Read with skip=2 (two header rows) and assign column names
  df <- read.csv(
    textConnection(content),
    header = FALSE,
    skip = 3,  # Skip 2 header rows + 1 blank line
    stringsAsFactors = FALSE,
    strip.white = TRUE
  )

  # Some years may have slightly different column counts
  if (ncol(df) >= length(bps_cols)) {
    df <- df[, 1:length(bps_cols)]
    names(df) <- bps_cols
  } else if (ncol(df) >= 18) {
    # At minimum need the first 18 columns (non-reported)
    names(df)[1:min(ncol(df), length(bps_cols))] <-
      bps_cols[1:min(ncol(df), length(bps_cols))]
  } else {
    stop(sprintf("Unexpected column count %d for year %d", ncol(df), yr))
  }

  # Ensure year column is set
  df$year <- yr

  cat(sprintf("  Year %d: %d counties\n", yr, nrow(df)))
  return(df)
}

# --- Fetch all years ---
all_data <- list()
for (yr in years) {
  all_data[[as.character(yr)]] <- fetch_bps_year(yr)
  Sys.sleep(0.3)
}

raw_df <- bind_rows(all_data)

# --- Clean numeric columns ---
numeric_cols <- setdiff(bps_cols, c("county_name"))
for (col in intersect(numeric_cols, names(raw_df))) {
  raw_df[[col]] <- as.numeric(gsub(",", "", as.character(raw_df[[col]])))
}

# --- Create FIPS code ---
raw_df <- raw_df %>%
  mutate(
    state_fips = sprintf("%02d", as.integer(state_fips)),
    county_fips = sprintf("%03d", as.integer(county_fips)),
    fips = paste0(state_fips, county_fips)
  ) %>%
  filter(!is.na(state_fips), state_fips != "NA")

cat(sprintf("\nTotal records: %d\n", nrow(raw_df)))
cat(sprintf("Years: %d-%d\n", min(raw_df$year, na.rm = TRUE), max(raw_df$year, na.rm = TRUE)))
cat(sprintf("Unique counties: %d\n", n_distinct(raw_df$fips)))
cat(sprintf("Unique states: %d\n", n_distinct(raw_df$state_fips)))

# --- Save ---
saveRDS(raw_df, "../data/bps_county_raw.rds")
cat("Raw data saved.\n")

# --- Quick summary for treated states ---
treated_states <- c("41", "06", "23", "30", "53")  # OR, CA, ME, MT, WA
state_labels <- c("41" = "Oregon", "06" = "California", "23" = "Maine",
                   "30" = "Montana", "53" = "Washington")

cat("\n=== Treated States Summary ===\n")
treated_summary <- raw_df %>%
  filter(state_fips %in% treated_states) %>%
  group_by(year, state_fips) %>%
  summarise(
    n_counties = n(),
    total_1unit = sum(units1_units, na.rm = TRUE),
    total_2unit = sum(units2_units, na.rm = TRUE),
    total_34unit = sum(units34_units, na.rm = TRUE),
    total_5plus = sum(units5p_units, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    total = total_1unit + total_2unit + total_34unit + total_5plus,
    mm_share = (total_2unit + total_34unit) / pmax(total, 1),
    state = state_labels[state_fips]
  ) %>%
  filter(year >= 2018) %>%
  select(year, state, n_counties, total, total_2unit, total_34unit, mm_share)

print(as.data.frame(treated_summary), row.names = FALSE)

cat("\nData fetch complete.\n")
