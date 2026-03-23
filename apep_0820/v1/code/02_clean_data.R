## 02_clean_data.R — Clean data and construct Gaussian plume instrument
## apep_0820: Gaussian Plume IV for Pollution and Test Scores

source("00_packages.R")

DATA_DIR <- normalizePath("../data", mustWork = FALSE)

# ============================================================
# Load data
# ============================================================
cat("=== Loading data ===\n")
facilities <- readRDS(file.path(DATA_DIR, "echo_facilities.rds"))
aqs_data <- readRDS(file.path(DATA_DIR, "aqs_monitors.rds"))
wind_data <- readRDS(file.path(DATA_DIR, "asos_wind_raw.rds"))
edfacts <- readRDS(file.path(DATA_DIR, "edfacts_raw.rds"))
geocodes <- readRDS(file.path(DATA_DIR, "nces_geocodes.rds"))
fac_station <- readRDS(file.path(DATA_DIR, "facility_station_match.rds"))
stations <- readRDS(file.path(DATA_DIR, "asos_stations.rds"))

cat("  Facilities:", nrow(facilities), "\n")
cat("  AQS records:", nrow(aqs_data), "\n")
cat("  Wind data rows:", nrow(wind_data), "\n")
cat("  EdFacts records:", nrow(edfacts), "\n")
cat("  Geocodes:", nrow(geocodes), "\n")

# ============================================================
# 1. Clean AQS — county-year SO2/PM2.5
# ============================================================
cat("\n=== Cleaning AQS monitor data ===\n")

aqs_clean <- aqs_data %>%
  filter(`Parameter Code` %in% c(42401, 88101, 42602)) %>%
  mutate(
    fips_county = paste0(sprintf("%02d", as.integer(`State Code`)),
                         sprintf("%03d", as.integer(`County Code`))),
    parameter = case_when(
      `Parameter Code` == 42401 ~ "so2",
      `Parameter Code` == 88101 ~ "pm25",
      `Parameter Code` == 42602 ~ "no2"
    ),
    year = Year,
    conc_mean = `Arithmetic Mean`
  ) %>%
  filter(!is.na(conc_mean))

county_pollution <- aqs_clean %>%
  group_by(fips_county, year, parameter) %>%
  summarise(conc = mean(conc_mean, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = parameter, values_from = conc, names_prefix = "conc_")

cat("  County-year pollution records:", nrow(county_pollution), "\n")

# ============================================================
# 2. Wind roses (station × year × direction)
# ============================================================
cat("\n=== Computing wind roses ===\n")

wind_clean <- wind_data %>%
  rename_with(tolower) %>%
  mutate(drct = as.numeric(drct), sknt = as.numeric(sknt)) %>%
  filter(!is.na(drct), !is.na(sknt), drct >= 0, drct <= 360, sknt > 0) %>%
  mutate(
    dir_bin = round(drct / 22.5) %% 16,
    dir_center = dir_bin * 22.5,
    year = as.integer(wind_year)
  )

wind_roses <- wind_clean %>%
  group_by(station_id, year) %>%
  mutate(total_obs = n()) %>%
  group_by(station_id, year, dir_bin, dir_center) %>%
  summarise(
    freq = n() / first(total_obs),
    mean_speed_ms = mean(sknt * 0.5144),
    .groups = "drop"
  )

cat("  Wind roses:", n_distinct(wind_roses$station_id), "stations,",
    n_distinct(wind_roses$year), "years\n")
saveRDS(wind_roses, file.path(DATA_DIR, "wind_roses.rds"))

# ============================================================
# 3. Clean EdFacts + geocodes
# ============================================================
cat("\n=== Cleaning EdFacts data ===\n")

ef_cols <- names(edfacts)
cat("  Columns:", paste(head(ef_cols, 25), collapse = ", "), "\n")

# EdFacts has: NCESSCH, SCHNAM, ALL_MTH00PCTPROF_YYZZ columns
# Extract the proficiency percentage as our outcome
# Column format: ALL_MTH00PCTPROF_XXYY where XXYY is the school year

edfacts_clean <- edfacts %>%
  mutate(ncessch = as.character(NCESSCH)) %>%
  select(ncessch, SCHNAM, STNAM, school_year, matches("ALL_MTH00PCTPROF|ALL_MTH00NUMVALID"))

# Identify the proficiency column for each year
# They vary by year suffix: _1213, _1314, _1415, etc.
pct_cols <- names(edfacts_clean)[grepl("ALL_MTH00PCTPROF", names(edfacts_clean))]
num_cols <- names(edfacts_clean)[grepl("ALL_MTH00NUMVALID", names(edfacts_clean))]

cat("  Proficiency columns:", paste(pct_cols, collapse = ", "), "\n")

# For each row, extract the proficiency value from the year-specific column
edfacts_long <- edfacts_clean %>%
  rowwise() %>%
  mutate(
    pct_prof = {
      vals <- c_across(all_of(pct_cols))
      # Get the non-NA proficiency value
      v <- vals[!is.na(vals)]
      if (length(v) > 0) as.character(v[1]) else NA_character_
    },
    n_valid = {
      vals <- c_across(all_of(num_cols))
      v <- vals[!is.na(vals)]
      if (length(v) > 0) as.character(v[1]) else NA_character_
    }
  ) %>%
  ungroup() %>%
  select(ncessch, school_year, pct_prof, n_valid)

# Convert school_year to numeric year (use end year)
edfacts_long <- edfacts_long %>%
  mutate(
    year = as.integer(paste0("20", sub(".*-", "", school_year))),
    # Handle proficiency ranges (e.g., "GE50" "LT50" "50-59" etc.)
    pct_prof_num = case_when(
      grepl("^\\d+$", pct_prof) ~ as.numeric(pct_prof),
      grepl("^GE(\\d+)", pct_prof) ~ as.numeric(sub("^GE", "", pct_prof)),
      grepl("^LE(\\d+)", pct_prof) ~ as.numeric(sub("^LE", "", pct_prof)),
      grepl("^LT(\\d+)", pct_prof) ~ as.numeric(sub("^LT", "", pct_prof)) - 1,
      grepl("^GT(\\d+)", pct_prof) ~ as.numeric(sub("^GT", "", pct_prof)) + 1,
      grepl("^(\\d+)-(\\d+)$", pct_prof) ~ {
        lo <- as.numeric(sub("^(\\d+)-.*", "\\1", pct_prof))
        hi <- as.numeric(sub(".*-(\\d+)$", "\\1", pct_prof))
        (lo + hi) / 2
      },
      pct_prof %in% c("PS", "S", "-", "‡", "†") ~ NA_real_,
      TRUE ~ NA_real_
    ),
    n_valid_num = suppressWarnings(as.numeric(n_valid))
  ) %>%
  filter(!is.na(pct_prof_num), !is.na(year))

cat("  EdFacts with valid proficiency:", nrow(edfacts_long), "\n")
cat("  Year range:", paste(range(edfacts_long$year), collapse = "-"), "\n")

# Clean geocodes
cat("\n  Cleaning geocodes...\n")
geo_cols <- names(geocodes)
cat("  Geocode columns:", paste(head(geo_cols, 15), collapse = ", "), "\n")

# Find lat/lon/NCESSCH columns
lat_col <- geo_cols[grepl("^LAT$|^lat$|LATCOD", geo_cols, ignore.case = TRUE)][1]
lon_col <- geo_cols[grepl("^LON$|^lon$|LONCOD|^LONG", geo_cols, ignore.case = TRUE)][1]
nces_col <- geo_cols[grepl("NCESSCH|ncessch", geo_cols, ignore.case = TRUE)][1]

cat("  lat col:", lat_col, ", lon col:", lon_col, ", nces col:", nces_col, "\n")

geocodes_clean <- geocodes
if (!is.null(nces_col)) {
  geocodes_clean <- geocodes_clean %>%
    rename(ncessch = !!sym(nces_col)) %>%
    mutate(ncessch = as.character(ncessch))
}
if (!is.null(lat_col)) {
  geocodes_clean <- geocodes_clean %>%
    rename(lat = !!sym(lat_col))
}
if (!is.null(lon_col)) {
  geocodes_clean <- geocodes_clean %>%
    rename(lon = !!sym(lon_col))
}

geocodes_clean <- geocodes_clean %>%
  mutate(lat = as.numeric(lat), lon = as.numeric(lon)) %>%
  filter(!is.na(lat), !is.na(lon), lat > 24, lat < 50, lon > -125, lon < -65) %>%
  distinct(ncessch, .keep_all = TRUE)

cat("  Geocoded schools:", nrow(geocodes_clean), "\n")

# Merge EdFacts with geocodes
school_data <- edfacts_long %>%
  inner_join(geocodes_clean %>% select(ncessch, lat, lon), by = "ncessch")

cat("  Schools with scores + coords:", n_distinct(school_data$ncessch), "\n")
cat("  School-year records:", nrow(school_data), "\n")

# ============================================================
# 4. Gaussian Plume Instrument
# ============================================================
cat("\n=== Computing Gaussian plume instrument ===\n")

gaussian_plume_ground <- function(distance_m, wind_speed_ms, stack_height = 75) {
  sigma_y <- 0.08 * distance_m * (1 + 0.0001 * distance_m)^(-0.5)
  sigma_z <- 0.06 * distance_m * (1 + 0.0015 * distance_m)^(-0.5)
  conc <- 1 / (pi * pmax(wind_speed_ms, 0.5) * sigma_y * sigma_z) *
    exp(-stack_height^2 / (2 * sigma_z^2))
  conc[!is.finite(conc) | conc < 0] <- 0
  return(conc)
}

# Build school-facility pairs within 50km
cat("  Building pairs within 50km...\n")
fac_locs <- facilities %>% select(facilityId, latitude, longitude) %>% distinct()
sch_locs <- geocodes_clean %>% select(ncessch, lat, lon)

n_schools <- nrow(sch_locs)
pair_list <- list()

for (j in 1:n_schools) {
  dists <- geosphere::distHaversine(
    c(sch_locs$lon[j], sch_locs$lat[j]),
    cbind(fac_locs$longitude, fac_locs$latitude)
  )
  close_idx <- which(dists <= 50000)

  if (length(close_idx) > 0) {
    bearings <- geosphere::bearing(
      cbind(fac_locs$longitude[close_idx], fac_locs$latitude[close_idx]),
      c(sch_locs$lon[j], sch_locs$lat[j])
    )
    pair_list[[length(pair_list) + 1]] <- data.table(
      ncessch = sch_locs$ncessch[j],
      facilityId = fac_locs$facilityId[close_idx],
      dist_m = dists[close_idx],
      bearing = (bearings + 360) %% 360
    )
  }

  if (j %% 10000 == 0) cat("    Processed", j, "of", n_schools, "schools\n")
}

all_pairs <- rbindlist(pair_list)
cat("  Pairs:", nrow(all_pairs), "\n")
cat("  Schools near ≥1 facility:", n_distinct(all_pairs$ncessch), "\n")

# Match pairs to wind data
all_pairs <- merge(all_pairs,
                   as.data.table(fac_station)[, .(facilityId, nearest_station)],
                   by = "facilityId", all.x = TRUE)

all_pairs[, wind_from_needed := (bearing + 180) %% 360]
all_pairs[, wind_bin := round(wind_from_needed / 22.5) %% 16]

# Cross with wind roses (by year)
wind_roses_dt <- as.data.table(wind_roses)

pair_year <- merge(all_pairs,
                   wind_roses_dt[, .(station_id, year, dir_bin, freq, mean_speed_ms)],
                   by.x = c("nearest_station", "wind_bin"),
                   by.y = c("station_id", "dir_bin"),
                   allow.cartesian = TRUE)

pair_year[is.na(freq), freq := 1/16]
pair_year[is.na(mean_speed_ms) | mean_speed_ms < 0.5, mean_speed_ms := 3.0]
pair_year[, pred_conc := gaussian_plume_ground(dist_m, mean_speed_ms) * freq]

# Aggregate to school-year
school_iv <- pair_year[, .(
  pred_exposure = sum(pred_conc, na.rm = TRUE),
  n_facilities = uniqueN(facilityId),
  mean_dist_km = mean(dist_m) / 1000
), by = .(ncessch, year)]

cat("  School-year IV observations:", nrow(school_iv), "\n")

# ============================================================
# 5. Merge final analysis dataset
# ============================================================
cat("\n=== Merging ===\n")

school_data <- school_data %>%
  mutate(fips_county = substr(ncessch, 1, 5),
         fips_state = substr(ncessch, 1, 2))

analysis_df <- school_data %>%
  inner_join(as.data.frame(school_iv), by = c("ncessch", "year")) %>%
  left_join(county_pollution, by = c("fips_county", "year"))

cat("  Final N:", nrow(analysis_df), "\n")
cat("  Schools:", n_distinct(analysis_df$ncessch), "\n")
cat("  Years:", paste(sort(unique(analysis_df$year)), collapse = ", "), "\n")

# Standardize outcome
analysis_df <- analysis_df %>%
  mutate(
    test_score = pct_prof_num,
    test_score_std = (test_score - mean(test_score, na.rm = TRUE)) / sd(test_score, na.rm = TRUE),
    pred_exposure_std = (pred_exposure - mean(pred_exposure, na.rm = TRUE)) /
      sd(pred_exposure, na.rm = TRUE)
  )

cat("\n=== Summary ===\n")
cat("  Math proficiency (%):", round(mean(analysis_df$test_score, na.rm = TRUE), 1),
    "(SD:", round(sd(analysis_df$test_score, na.rm = TRUE), 1), ")\n")
cat("  Predicted exposure:", round(mean(analysis_df$pred_exposure, na.rm = TRUE), 6),
    "(SD:", round(sd(analysis_df$pred_exposure, na.rm = TRUE), 6), ")\n")
if ("conc_so2" %in% names(analysis_df))
  cat("  County SO2 (ppb):", round(mean(analysis_df$conc_so2, na.rm = TRUE), 3), "\n")

saveRDS(analysis_df, file.path(DATA_DIR, "analysis_panel.rds"))
cat("\n02_clean_data.R COMPLETE\n")
