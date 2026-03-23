# 02_clean_data.R — Merge FRA quiet zone data with Zillow ZHVI
# apep_0785: Quiet zone designations and property values

source("00_packages.R")

cat("=== Loading data ===\n")
city_qz <- readRDS("../data/city_quiet_zones.rds")
city_crossings <- readRDS("../data/city_crossings.rds")
zhvi_long <- readRDS("../data/zhvi_long.rds")

cat("Quiet zone cities:", nrow(city_qz), "\n")
cat("All crossing cities:", nrow(city_crossings), "\n")
cat("ZHVI observations:", nrow(zhvi_long), "\n")

cat("\n=== Merging datasets ===\n")

# Join city crossings info with quiet zone info
city_panel <- city_crossings %>%
  left_join(city_qz, by = c("state_clean", "city_clean")) %>%
  mutate(
    ever_treated = !is.na(first_qz_date),
    first_qz_year_month = if_else(ever_treated, floor_date(first_qz_date, "month"), as.Date(NA))
  )

cat("Cities in crossing panel:", nrow(city_panel), "\n")
cat("  Treated (ever QZ):", sum(city_panel$ever_treated), "\n")
cat("  Control (never QZ):", sum(!city_panel$ever_treated), "\n")

# Zillow uses state abbreviations; FRA uses full names — build crosswalk
state_xwalk <- tibble(
  state_abbr = state.abb,
  state_full = str_to_title(state.name)
) %>%
  bind_rows(tibble(state_abbr = "DC", state_full = "District Of Columbia"))

# Add state abbreviation to city_panel
city_panel <- city_panel %>%
  left_join(state_xwalk, by = c("state_clean" = "state_full"))

# Zillow state_clean is the abbreviation
# Match on city name + state abbreviation
panel <- zhvi_long %>%
  inner_join(
    city_panel,
    by = c("city_clean", "state_clean" = "state_abbr")
  )

cat("\nMerged panel observations:", nrow(panel), "\n")
cat("Unique cities in merged panel:", n_distinct(panel$RegionID), "\n")

# Check merge rates
merged_qz_cities <- panel %>%
  filter(ever_treated) %>%
  distinct(state_clean, city_clean) %>%
  nrow()
cat("Quiet zone cities matched to ZHVI:", merged_qz_cities, "of", nrow(city_qz), "\n")

merged_control_cities <- panel %>%
  filter(!ever_treated) %>%
  distinct(state_clean, city_clean) %>%
  nrow()
cat("Control cities matched to ZHVI:", merged_control_cities, "\n")

# Create analysis variables
panel <- panel %>%
  mutate(
    # Year-month numeric for CS: months since Jan 2000
    ym = (year - 2000) * 12 + month,
    # Treatment cohort: year-month of first QZ (0 for never-treated)
    cohort_ym = if_else(
      ever_treated,
      (year(first_qz_year_month) - 2000) * 12 + month(first_qz_year_month),
      0L
    ),
    # Post-treatment indicator
    post = if_else(ever_treated & date >= first_qz_year_month, 1L, 0L),
    # Log ZHVI
    log_zhvi = log(zhvi),
    # Dose: number of quiet zone crossings
    dose = if_else(ever_treated, as.numeric(n_qz_crossings), 0),
    # Intensity: QZ crossings as share of all public crossings
    qz_intensity = if_else(ever_treated, n_qz_crossings / n_public_crossings, 0)
  )

cat("\n=== Panel summary ===\n")
cat("Total observations:", nrow(panel), "\n")
cat("Unique cities:", n_distinct(panel$RegionID), "\n")
cat("Date range:", as.character(min(panel$date)), "to", as.character(max(panel$date)), "\n")
cat("Treatment cohorts:", n_distinct(panel$cohort_ym[panel$cohort_ym > 0]), "\n")

# Restrict sample: require at least 12 pre-treatment months for treated cities
# and at least some balance
panel_balanced <- panel %>%
  group_by(RegionID) %>%
  filter(n() >= 60) %>%  # At least 5 years of data
  ungroup()

# For treated cities, verify we have pre-period data
treated_check <- panel_balanced %>%
  filter(ever_treated) %>%
  group_by(RegionID) %>%
  summarise(
    n_pre = sum(post == 0),
    n_post = sum(post == 1),
    .groups = "drop"
  )

cat("\nPre/post balance for treated cities:\n")
cat("  Mean pre-periods:", round(mean(treated_check$n_pre), 1), "\n")
cat("  Mean post-periods:", round(mean(treated_check$n_post), 1), "\n")
cat("  Cities with >=12 pre-periods:", sum(treated_check$n_pre >= 12), "\n")

# Keep only treated cities with sufficient pre-period
good_treated <- treated_check %>%
  filter(n_pre >= 12) %>%
  pull(RegionID)

panel_final <- panel_balanced %>%
  filter(!ever_treated | RegionID %in% good_treated)

cat("\n=== Final analysis panel ===\n")
n_treated <- n_distinct(panel_final$RegionID[panel_final$ever_treated])
n_control <- n_distinct(panel_final$RegionID[!panel_final$ever_treated])
cat("Treated cities:", n_treated, "\n")
cat("Control cities:", n_control, "\n")
cat("Total observations:", nrow(panel_final), "\n")
cat("Months:", n_distinct(panel_final$ym), "\n")

# Summary statistics
cat("\n=== Summary statistics ===\n")
summ <- panel_final %>%
  group_by(ever_treated) %>%
  summarise(
    n_cities = n_distinct(RegionID),
    mean_zhvi = mean(zhvi, na.rm = TRUE),
    sd_zhvi = sd(zhvi, na.rm = TRUE),
    mean_crossings = mean(n_public_crossings, na.rm = TRUE),
    mean_trains = mean(avg_trains, na.rm = TRUE),
    .groups = "drop"
  )
print(summ)

saveRDS(panel_final, "../data/analysis_panel.rds")
cat("\nSaved analysis panel to data/analysis_panel.rds\n")

# Save summary stats for tables
saveRDS(summ, "../data/summary_stats.rds")
