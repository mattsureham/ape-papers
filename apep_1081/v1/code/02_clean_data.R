# 02_clean_data.R — Clean and construct analysis dataset
# APEP-1081: Coal Tar Sealant Bans and Waterway PAH Contamination

source("00_packages.R")

fluor_raw <- readRDS("../data/fluor_raw.rds")
ban_dates <- readRDS("../data/ban_dates.rds")

cat(sprintf("Raw fluoranthene records: %d\n", nrow(fluor_raw)))

# ── Extract key variables (new USGS API column names) ──
fluor <- fluor_raw %>%
  transmute(
    station_id    = Location_Identifier,
    activity_date = as.Date(Activity_StartDate),
    year          = year(activity_date),
    month         = month(activity_date),
    result_value  = as.numeric(Result_Measure),
    result_unit   = Result_MeasureUnit,
    detect_cond   = Result_ResultDetectionCondition,
    detect_limit  = as.numeric(DetectionLimit_MeasureA),
    sample_media  = Activity_Media,
    state         = state_abbr,
    lat           = as.numeric(Location_Latitude),
    lon           = as.numeric(Location_Longitude),
    huc8          = Location_HUCEightDigitCode,
    loc_type      = Location_Type
  ) %>%
  filter(
    year >= 2000 & year <= 2025,
    !is.na(activity_date)
  )

# ── Handle non-detects ──
fluor <- fluor %>%
  mutate(
    is_nondetect = grepl("Not Detected|Below|Non-detect", detect_cond, ignore.case = TRUE) |
                   (is.na(result_value) & !is.na(detect_limit)),
    value_clean = case_when(
      !is.na(result_value) & result_value >= 0 ~ result_value,
      is_nondetect & !is.na(detect_limit)       ~ detect_limit / 2,
      TRUE                                       ~ NA_real_
    )
  ) %>%
  filter(!is.na(value_clean))

cat(sprintf("After cleaning: %d records\n", nrow(fluor)))
cat(sprintf("Non-detects: %d (%.1f%%)\n",
            sum(fluor$is_nondetect), 100 * mean(fluor$is_nondetect)))

# ── Standardize units to ug/L ──
cat("\nUnit distribution:\n")
print(table(fluor$result_unit, useNA = "ifany"))

fluor <- fluor %>%
  mutate(
    value_ugl = case_when(
      result_unit %in% c("ug/l", "ug/L", "UG/L") ~ value_clean,
      result_unit %in% c("mg/l", "mg/L", "MG/L") ~ value_clean * 1000,
      result_unit %in% c("ng/l", "ng/L", "NG/L") ~ value_clean / 1000,
      TRUE ~ value_clean
    )
  )

# ── Drop extreme outliers ──
q99 <- quantile(fluor$value_ugl, 0.99, na.rm = TRUE)
n_before <- nrow(fluor)
fluor <- fluor %>% filter(value_ugl <= q99 * 10)
cat(sprintf("Dropped %d outliers (>10x 99th percentile)\n", n_before - nrow(fluor)))

# ── Merge treatment assignment ──
fluor <- fluor %>%
  left_join(ban_dates %>% select(state_abbr, ban_year),
            by = c("state" = "state_abbr")) %>%
  mutate(
    ban_year = replace_na(ban_year, 0L),
    treated  = as.integer(ban_year > 0),
    post     = as.integer(year >= ban_year & ban_year > 0)
  )

# ── Collapse to station-year level ──
station_year <- fluor %>%
  group_by(station_id, state, year, ban_year, lat, lon) %>%
  summarise(
    mean_fluor    = mean(value_ugl, na.rm = TRUE),
    median_fluor  = median(value_ugl, na.rm = TRUE),
    n_samples     = n(),
    pct_nondetect = mean(is_nondetect),
    .groups = "drop"
  ) %>%
  mutate(
    log_fluor = log(mean_fluor + 0.001),
    treated   = as.integer(ban_year > 0),
    post      = as.integer(year >= ban_year & ban_year > 0)
  )

cat(sprintf("\nStation-year panel: %d obs, %d stations, %d years\n",
            nrow(station_year),
            n_distinct(station_year$station_id),
            n_distinct(station_year$year)))

# ── Keep stations with ≥3 observations ──
station_counts <- station_year %>%
  group_by(station_id) %>%
  summarise(n_years = n(), .groups = "drop")

stations_keep <- station_counts %>% filter(n_years >= 3) %>% pull(station_id)

panel <- station_year %>%
  filter(station_id %in% stations_keep) %>%
  mutate(station_num = as.integer(factor(station_id)))

cat(sprintf("After filtering (≥3 years): %d obs, %d stations\n",
            nrow(panel), n_distinct(panel$station_id)))

# ── Summary by treatment status ──
cat("\n=== Treatment Summary ===\n")
panel %>%
  group_by(treated, ban_year) %>%
  summarise(
    n_stations = n_distinct(station_id),
    n_obs = n(),
    mean_fluor = mean(mean_fluor, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

cat("\n=== Year coverage ===\n")
panel %>%
  group_by(year) %>%
  summarise(n_stations = n_distinct(station_id), .groups = "drop") %>%
  print(n = 30)

# ── Save ──
saveRDS(panel, "../data/panel.rds")
saveRDS(fluor, "../data/fluor_clean.rds")
cat("\nAnalysis dataset saved.\n")
