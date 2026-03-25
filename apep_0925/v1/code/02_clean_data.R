# 02_clean_data.R — Clean and construct analysis panel
# Triple-diff: England × food services × post-2022

source("00_packages.R")

DATA_DIR <- "../data"

# ---- 1. Load raw data ----
data_ent <- readRDS(file.path(DATA_DIR, "enterprise_counts_by_sizeband.rds"))
data_total <- readRDS(file.path(DATA_DIR, "enterprise_counts_total.rds"))

cat("=== Raw data loaded ===\n")
cat(sprintf("Enterprise by sizeband: %d rows\n", nrow(data_ent)))
cat(sprintf("Enterprise totals: %d rows\n", nrow(data_total)))

# ---- 2. Clean variable names and construct analysis variables ----
panel <- data_ent |>
  mutate(
    country = GEOGRAPHY_NAME,
    sic2 = as.integer(gsub(" :.*", "", INDUSTRY_NAME)),
    sizeband = EMPLOYMENT_SIZEBAND_NAME,
    year = as.integer(DATE_NAME),
    enterprises = as.numeric(OBS_VALUE),
    # Treatment indicators
    england = as.integer(country == "England"),
    food = as.integer(sic2 == 56),
    # Post-regulation: April 2022, but data is March reference
    # So 2023+ is post-treatment (March 2023 = ~1 year after regulation)
    post = as.integer(year >= 2023),
    # Interaction
    treated = england * food * post,
    # Size band categories
    near_threshold = as.integer(sizeband %in% c("100 to 249", "250 to 499")),
    above_threshold = as.integer(sizeband %in% c("250 to 499", "500 to 999", "1000+")),
    large = as.integer(sizeband %in% c("250 to 499", "500 to 999", "1000+"))
  ) |>
  select(country, sic2, sizeband, year, enterprises, england, food, post,
         treated, near_threshold, above_threshold, large)

cat(sprintf("\n=== Panel constructed: %d rows ===\n", nrow(panel)))

# ---- 3. Create aggregate outcomes by country-industry-year ----
# Outcome 1: Total enterprises
agg_total <- panel |>
  group_by(country, sic2, year, england, food, post) |>
  summarise(
    total_enterprises = sum(enterprises, na.rm = TRUE),
    .groups = "drop"
  )

# Outcome 2: Large (250+) enterprises
agg_large <- panel |>
  filter(large == 1) |>
  group_by(country, sic2, year, england, food, post) |>
  summarise(
    large_enterprises = sum(enterprises, na.rm = TRUE),
    .groups = "drop"
  )

# Outcome 3: Near-threshold enterprises (100-249 and 250-499)
agg_near <- panel |>
  filter(near_threshold == 1) |>
  group_by(country, sic2, year, england, food, post) |>
  summarise(
    near_100_249 = sum(enterprises[sizeband == "100 to 249"], na.rm = TRUE),
    near_250_499 = sum(enterprises[sizeband == "250 to 499"], na.rm = TRUE),
    .groups = "drop"
  )

# Merge all aggregate outcomes
agg_panel <- agg_total |>
  left_join(agg_large, by = c("country", "sic2", "year", "england", "food", "post")) |>
  left_join(agg_near, by = c("country", "sic2", "year", "england", "food", "post")) |>
  mutate(
    large_enterprises = replace_na(large_enterprises, 0),
    near_100_249 = replace_na(near_100_249, 0),
    near_250_499 = replace_na(near_250_499, 0),
    # Key outcome: share of large enterprises
    large_share = large_enterprises / total_enterprises,
    # Threshold ratio: enterprises 250-499 / enterprises 100-249
    threshold_ratio = ifelse(near_100_249 > 0,
                             near_250_499 / near_100_249,
                             NA_real_),
    # Log outcomes
    ln_total = log(total_enterprises + 1),
    ln_large = log(large_enterprises + 1),
    # Triple-diff components
    eng_food = england * food,
    eng_post = england * post,
    food_post = food * post,
    treated = england * food * post,
    # Panel IDs
    unit_id = paste(country, sic2, sep = "_"),
    country_year = paste(country, year, sep = "_"),
    industry_year = paste(sic2, year, sep = "_")
  )

cat(sprintf("\n=== Aggregated panel: %d observations ===\n", nrow(agg_panel)))
cat(sprintf("Countries: %s\n", paste(unique(agg_panel$country), collapse = ", ")))
cat(sprintf("Industries: %s\n", paste(sort(unique(agg_panel$sic2)), collapse = ", ")))
cat(sprintf("Years: %s\n", paste(sort(unique(agg_panel$year)), collapse = ", ")))

# ---- 4. Descriptive statistics ----
cat("\n=== Key descriptive statistics ===\n")

# England food services around the threshold
eng_food <- agg_panel |>
  filter(england == 1, food == 1) |>
  select(year, total_enterprises, large_enterprises, large_share,
         near_100_249, near_250_499, threshold_ratio) |>
  arrange(year)

cat("\nEngland food services (SIC 56):\n")
print(as.data.frame(eng_food))

# Scotland food services around the threshold
scot_food <- agg_panel |>
  filter(country == "Scotland", food == 1) |>
  select(year, total_enterprises, large_enterprises, large_share,
         near_100_249, near_250_499, threshold_ratio) |>
  arrange(year)

cat("\nScotland food services (SIC 56):\n")
print(as.data.frame(scot_food))

# ---- 5. Also create event-study variable ----
agg_panel <- agg_panel |>
  mutate(
    # Event time relative to treatment (2022.5 is midpoint: regulation April 2022,
    # data is March reference, so 2023 = first post year = event_time 1)
    event_time = year - 2022,
    # For event study: england × food × year dummies
    ef_2010 = england * food * (year == 2010),
    ef_2011 = england * food * (year == 2011),
    ef_2012 = england * food * (year == 2012),
    ef_2013 = england * food * (year == 2013),
    ef_2014 = england * food * (year == 2014),
    ef_2015 = england * food * (year == 2015),
    ef_2016 = england * food * (year == 2016),
    ef_2017 = england * food * (year == 2017),
    ef_2018 = england * food * (year == 2018),
    ef_2019 = england * food * (year == 2019),
    ef_2020 = england * food * (year == 2020),
    ef_2021 = england * food * (year == 2021),
    # 2022 is the omitted reference year (last pre-treatment)
    ef_2023 = england * food * (year == 2023),
    ef_2024 = england * food * (year == 2024)
  )

# ---- 6. Save ----
saveRDS(panel, file.path(DATA_DIR, "panel_sizeband.rds"))
saveRDS(agg_panel, file.path(DATA_DIR, "analysis_panel.rds"))
write_csv(agg_panel, file.path(DATA_DIR, "analysis_panel.csv"))

cat(sprintf("\n✓ Analysis panel saved: %d observations\n", nrow(agg_panel)))
cat(sprintf("  Unit IDs: %d | Years: %d | Post-treatment years: 2023-2024\n",
  length(unique(agg_panel$unit_id)), length(unique(agg_panel$year))))
