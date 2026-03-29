## 02_clean_data.R
## The Housing Cost of Reshoring: CHIPS Act and Local Housing Markets
## Construct analysis panel: merge Zillow + CHIPS + ACS

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 1. Load data
# ============================================================
zhvi_long <- readRDS(file.path(data_dir, "zhvi_long.rds"))
zori_long <- readRDS(file.path(data_dir, "zori_long.rds"))
chips <- read_csv(file.path(data_dir, "chips_announcements.csv"),
                  col_types = cols(county_fips = col_character()))
acs <- read_csv(file.path(data_dir, "census_acs_2021.csv"),
                col_types = cols(county_fips = col_character()))

# ============================================================
# 2. Create numeric time index
# ============================================================
# Convert dates to monthly period index (months since Jan 2000)
ref_date <- as.Date("2000-01-01")

zhvi_long <- zhvi_long %>%
  mutate(
    year = year(date),
    month = month(date),
    time_index = 12 * (year - 2000) + month - 1  # 0 = Jan 2000
  )

# ============================================================
# 3. Merge CHIPS treatment status
# ============================================================
# Create treatment indicator and group variable for C-S
chips <- chips %>%
  mutate(
    announce_year = year(announce_date),
    announce_month = month(announce_date),
    treat_time = 12 * (announce_year - 2000) + announce_month - 1
  )

# Merge treatment info onto ZHVI panel
panel_zhvi <- zhvi_long %>%
  left_join(chips %>% select(county_fips, announce_date, treat_time,
                              total_award_billion, companies),
            by = "county_fips") %>%
  mutate(
    treated = !is.na(announce_date),
    # Group variable for C-S: treatment time for treated, 0 for never-treated
    first_treat = ifelse(treated, treat_time, 0),
    # Post indicator
    post = ifelse(treated & time_index >= treat_time, 1, 0),
    # Event time (months relative to announcement)
    event_time = ifelse(treated, time_index - treat_time, NA_real_),
    # Log outcome
    log_zhvi = log(zhvi)
  )

# ============================================================
# 4. Merge ACS county characteristics
# ============================================================
panel_zhvi <- panel_zhvi %>%
  left_join(acs, by = "county_fips")

# ============================================================
# 5. Restrict sample
# ============================================================
# Focus on 2020-01 through latest available (pre-COVID to post-CHIPS)
# This gives ~36+ months pre-treatment for earliest announcements
panel_zhvi <- panel_zhvi %>%
  filter(date >= as.Date("2020-01-01"))

cat("Panel dimensions after restriction:\n")
cat("  Rows:", nrow(panel_zhvi), "\n")
cat("  Counties:", n_distinct(panel_zhvi$county_fips), "\n")
cat("  Treated:", sum(panel_zhvi$treated & panel_zhvi$time_index == max(panel_zhvi$time_index)), "\n")
cat("  Control:", sum(!panel_zhvi$treated & panel_zhvi$time_index == max(panel_zhvi$time_index)), "\n")
cat("  Date range:", as.character(min(panel_zhvi$date)), "to",
    as.character(max(panel_zhvi$date)), "\n")

# ============================================================
# 6. Build ZORI panel (same structure)
# ============================================================
zori_long <- zori_long %>%
  mutate(
    year = year(date),
    month = month(date),
    time_index = 12 * (year - 2000) + month - 1
  )

panel_zori <- zori_long %>%
  left_join(chips %>% select(county_fips, announce_date, treat_time,
                              total_award_billion, companies),
            by = "county_fips") %>%
  mutate(
    treated = !is.na(announce_date),
    first_treat = ifelse(treated, treat_time, 0),
    post = ifelse(treated & time_index >= treat_time, 1, 0),
    event_time = ifelse(treated, time_index - treat_time, NA_real_),
    log_zori = log(zori)
  ) %>%
  left_join(acs, by = "county_fips") %>%
  filter(date >= as.Date("2020-01-01"))

cat("\nZORI panel:\n")
cat("  Rows:", nrow(panel_zori), "\n")
cat("  Counties:", n_distinct(panel_zori$county_fips), "\n")
cat("  Treated:", sum(panel_zori$treated & !duplicated(panel_zori$county_fips[panel_zori$treated])), "\n")

# ============================================================
# 7. Summary statistics for treated vs control
# ============================================================
baseline <- panel_zhvi %>%
  filter(date == as.Date("2022-01-01")) %>%  # Pre-CHIPS baseline
  group_by(treated) %>%
  summarise(
    n_counties = n(),
    mean_zhvi = mean(zhvi, na.rm = TRUE),
    sd_zhvi = sd(zhvi, na.rm = TRUE),
    mean_pop = mean(population, na.rm = TRUE),
    mean_income = mean(median_hh_income, na.rm = TRUE),
    mean_home_value = mean(median_home_value, na.rm = TRUE),
    .groups = "drop"
  )

cat("\n=== Baseline (Jan 2022) Summary ===\n")
print(baseline)

# ============================================================
# 8. Save analysis panels
# ============================================================
saveRDS(panel_zhvi, file.path(data_dir, "panel_zhvi.rds"))
saveRDS(panel_zori, file.path(data_dir, "panel_zori.rds"))

cat("\n=== CLEAN DATA COMPLETE ===\n")
