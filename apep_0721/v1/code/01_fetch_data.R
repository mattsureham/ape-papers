## 01_fetch_data.R — Download NOMIS ASHE data
## apep_0721: UK NLW Wage Distribution Compression

source("00_packages.R")

cat("=== Fetching NOMIS ASHE data ===\n")

# ASHE Table 7: Hourly pay (excluding overtime) by local authority
# Dataset NM_99_1 (ASHE Table 7 - place of work)
# We need: hourly pay excl OT at percentiles 10, 25, 50, 60, 90
# For all local authority districts, years 2013-2023

# NOMIS dataset ID for ASHE Table 7 (hourly pay by workplace LA)
# The nomisr package queries the NOMIS API

# First, let's check available datasets
cat("Querying NOMIS for ASHE datasets...\n")

# ASHE Table 7 workplace analysis
# Pay variable 1 = hourly pay excluding overtime
# Item 2,3,5,7,9 = 10th, 25th, median, 60th, 90th percentiles

# Build the NOMIS API query manually for reliability
# Dataset: NM_99_1 (ASHE Table 7)
# Geography type: 464 (local authority districts 2023)
# Pay: 1 (hourly pay excl overtime)
# Sex: 7 (all)
# Working pattern: 0 (all)
# Measures: 20100 (value)

ashe_url <- paste0(
  "https://www.nomisweb.co.uk/api/v01/dataset/NM_99_1.data.csv?",
  "geography=TYPE464&",  # Local authority districts
  "date=2013-2023&",     # Years 2013-2023
  "sex=7&",              # All
  "item=6,8,2,11,15&",   # 10th(6), 25th(8), median(2), 60th(11), 90th(15)
  "pay=6&",              # Hourly pay excluding overtime
  "measures=20100&",     # Value
  "select=date_name,geography_name,geography_code,item_name,obs_value"
)

cat("Downloading ASHE data from NOMIS...\n")
ashe_raw <- read.csv(ashe_url, stringsAsFactors = FALSE)

stopifnot("NOMIS returned no data" = nrow(ashe_raw) > 0)
cat(sprintf("Downloaded %d rows from NOMIS ASHE\n", nrow(ashe_raw)))

# Clean and reshape
ashe <- ashe_raw %>%
  rename(
    year = DATE_NAME,
    la_name = GEOGRAPHY_NAME,
    la_code = GEOGRAPHY_CODE,
    percentile = ITEM_NAME,
    value = OBS_VALUE
  ) %>%
  mutate(
    year = as.integer(year),
    value = as.numeric(value)
  ) %>%
  filter(!is.na(value), value > 0)

# Map percentile names to codes
ashe <- ashe %>%
  mutate(
    pctile = case_when(
      grepl("^10 percentile", percentile) ~ "p10",
      grepl("^25 percentile", percentile) ~ "p25",
      grepl("^Median", percentile) ~ "p50",
      grepl("^60 percentile", percentile) ~ "p60",
      grepl("^90 percentile", percentile) ~ "p90",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(pctile))

cat(sprintf("Cleaned: %d observations\n", nrow(ashe)))
cat(sprintf("  LAs: %d\n", n_distinct(ashe$la_code)))
cat(sprintf("  Years: %s to %s\n", min(ashe$year), max(ashe$year)))
cat(sprintf("  Percentiles: %s\n", paste(unique(ashe$pctile), collapse = ", ")))

# Reshape to wide format (one row per LA-year)
ashe_wide <- ashe %>%
  select(year, la_code, la_name, pctile, value) %>%
  pivot_wider(names_from = pctile, values_from = value)

cat(sprintf("Wide format: %d LA-year observations\n", nrow(ashe_wide)))

# Validate completeness
la_year_counts <- ashe_wide %>%
  group_by(la_code) %>%
  summarise(n_years = n(), .groups = "drop")

cat(sprintf("LAs with complete data (all years): %d\n",
            sum(la_year_counts$n_years == max(la_year_counts$n_years))))

# Save
saveRDS(ashe, "../data/ashe_long.rds")
saveRDS(ashe_wide, "../data/ashe_wide.rds")

stopifnot("Insufficient LAs" = n_distinct(ashe$la_code) >= 200)
stopifnot("Insufficient years" = n_distinct(ashe$year) >= 8)

cat("\n=== NOMIS ASHE data fetch complete ===\n")
