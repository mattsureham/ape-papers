# 02_clean_data.R — Clean dam data, match to USGS gauges, build analysis panel
# apep_1072: Dam Removal and Water Quality

source("00_packages.R")

data_dir <- "../data/"

# ============================================================================
# 1. CLEAN DAM REMOVAL DATA
# ============================================================================

cat("=== Cleaning Dam Removal Data ===\n")

dams_raw <- readRDS(file.path(data_dir, "dams_raw.rds"))

dams <- dams_raw %>%
  mutate(year_removed = as.integer(year_removed)) %>%
  filter(
    !is.na(latitude) & !is.na(longitude),
    !is.na(year_removed),
    year_removed >= 2000L & year_removed <= 2020L,
    latitude > 24 & latitude < 50,     # Continental US
    longitude < -65 & longitude > -125
  ) %>%
  mutate(
    dam_height_ft = as.numeric(dam_height_ft),
    year_removed = as.integer(year_removed),
    year_built = as.numeric(year_built),
    dam_id = ar_id
  ) %>%
  select(dam_id, dam_name, year_removed, latitude, longitude, state,
         river, dam_height_ft, year_built, reason_for_removal)

cat(sprintf("  Dams after cleaning: %d (from %d raw)\n", nrow(dams), nrow(dams_raw)))
cat(sprintf("  Year range: %d to %d\n", min(dams$year_removed), max(dams$year_removed)))
cat(sprintf("  States: %s\n", paste(sort(unique(dams$state)), collapse = ", ")))

# Summary by year
cat("\n  Removals by year:\n")
print(table(dams$year_removed))

# Dam height summary
cat(sprintf("\n  Dams with height data: %d / %d (%.0f%%)\n",
            sum(!is.na(dams$dam_height_ft)), nrow(dams),
            100 * mean(!is.na(dams$dam_height_ft))))

# ============================================================================
# 2. PREPARE USGS GAUGE DATA
# ============================================================================

cat("\n=== Preparing USGS Gauge Data ===\n")

temp_data <- readRDS(file.path(data_dir, "usgs_temperature_all.rds"))
do_data   <- readRDS(file.path(data_dir, "usgs_do_all.rds"))

# Clean temperature data
temp_clean <- temp_data %>%
  mutate(
    date  = as.Date(substr(date, 1, 10)),
    value = as.numeric(value)
  ) %>%
  filter(
    !is.na(value),
    value >= -5 & value <= 40,  # Plausible water temperature range (C)
    !grepl("e", qualifier, ignore.case = TRUE)  # Remove estimated values
  ) %>%
  mutate(
    year  = year(date),
    month = month(date),
    ym    = floor_date(date, "month")
  )

cat(sprintf("  Temperature: %d obs after cleaning (from %d)\n",
            nrow(temp_clean), nrow(temp_data)))

# Clean DO data
do_clean <- do_data %>%
  mutate(
    date  = as.Date(substr(date, 1, 10)),
    value = as.numeric(value)
  ) %>%
  filter(
    !is.na(value),
    value >= 0 & value <= 20,  # Plausible DO range (mg/L)
    !grepl("e", qualifier, ignore.case = TRUE)
  ) %>%
  mutate(
    year  = year(date),
    month = month(date),
    ym    = floor_date(date, "month")
  )

cat(sprintf("  DO: %d obs after cleaning (from %d)\n",
            nrow(do_clean), nrow(do_data)))

# Extract unique gauge locations
temp_gauges <- temp_clean %>%
  group_by(site_no) %>%
  summarise(
    lat   = first(lat),
    lon   = first(lon),
    state = first(state),
    n_obs = n(),
    first_date = min(date),
    last_date  = max(date),
    .groups = "drop"
  )

do_gauges <- do_clean %>%
  group_by(site_no) %>%
  summarise(
    lat   = first(lat),
    lon   = first(lon),
    state = first(state),
    n_obs = n(),
    first_date = min(date),
    last_date  = max(date),
    .groups = "drop"
  )

cat(sprintf("  Unique temperature gauges: %d\n", nrow(temp_gauges)))
cat(sprintf("  Unique DO gauges: %d\n", nrow(do_gauges)))

# ============================================================================
# 3. SPATIAL MATCHING: DAM → NEAREST DOWNSTREAM GAUGE
# ============================================================================

cat("\n=== Spatial Matching: Dams to Gauges ===\n")

# Calculate distances between all dams and all gauges
# Use a maximum distance threshold of 20 km
MAX_DIST_KM <- 20

match_dam_to_gauge <- function(dams_df, gauges_df, max_dist_km = MAX_DIST_KM) {
  dam_coords  <- as.matrix(dams_df[, c("longitude", "latitude")])
  gauge_coords <- as.matrix(gauges_df[, c("lon", "lat")])

  matches <- list()

  for (i in seq_len(nrow(dams_df))) {
    # Calculate distance from this dam to all gauges
    dists <- distHaversine(dam_coords[i, ], gauge_coords) / 1000  # km

    # Find gauges within threshold
    nearby <- which(dists <= max_dist_km)

    if (length(nearby) > 0) {
      # Take the nearest gauge
      nearest_idx <- nearby[which.min(dists[nearby])]
      matches[[length(matches) + 1]] <- data.frame(
        dam_id     = dams_df$dam_id[i],
        site_no    = gauges_df$site_no[nearest_idx],
        dist_km    = dists[nearest_idx],
        stringsAsFactors = FALSE
      )
    }
  }

  if (length(matches) == 0) return(data.frame())
  bind_rows(matches)
}

# Match dams to temperature gauges
cat("  Matching dams to temperature gauges...\n")
temp_matches <- match_dam_to_gauge(dams, temp_gauges)
cat(sprintf("  Temperature matches (raw): %d dam-gauge pairs (within %d km)\n",
            nrow(temp_matches), MAX_DIST_KM))

# Deduplicate: keep nearest dam per gauge (avoid double-counting gauge data)
temp_matches <- temp_matches %>%
  group_by(site_no) %>%
  slice_min(dist_km, n = 1, with_ties = FALSE) %>%
  ungroup()
cat(sprintf("  Temperature matches (deduped 1 dam per gauge): %d\n", nrow(temp_matches)))

# Match dams to DO gauges
cat("  Matching dams to DO gauges...\n")
do_matches <- match_dam_to_gauge(dams, do_gauges)
cat(sprintf("  DO matches (raw): %d dam-gauge pairs\n", nrow(do_matches)))

do_matches <- do_matches %>%
  group_by(site_no) %>%
  slice_min(dist_km, n = 1, with_ties = FALSE) %>%
  ungroup()
cat(sprintf("  DO matches (deduped 1 dam per gauge): %d\n", nrow(do_matches)))

# Distance summary
if (nrow(temp_matches) > 0) {
  cat(sprintf("  Distance summary (temp): median=%.1f km, mean=%.1f km\n",
              median(temp_matches$dist_km), mean(temp_matches$dist_km)))
}

# ============================================================================
# 4. BUILD MONTHLY PANEL FOR ANALYSIS
# ============================================================================

cat("\n=== Building Monthly Analysis Panel ===\n")

# --- TEMPERATURE PANEL ---
# Merge matched dams with gauge monthly data
temp_panel_matched <- temp_matches %>%
  inner_join(dams %>% select(dam_id, year_removed, dam_height_ft, state),
             by = "dam_id") %>%
  inner_join(
    temp_clean %>%
      group_by(site_no, ym) %>%
      summarise(
        temp_mean = mean(value, na.rm = TRUE),
        temp_max  = max(value, na.rm = TRUE),
        temp_min  = min(value, na.rm = TRUE),
        temp_sd   = sd(value, na.rm = TRUE),
        n_daily   = n(),
        .groups = "drop"
      ),
    by = "site_no"
  ) %>%
  filter(n_daily >= 15) %>%  # Require at least 15 daily obs per month
  mutate(
    year      = year(ym),
    month     = month(ym),
    rel_year  = year - year_removed,
    post      = as.integer(year >= year_removed),
    treated   = 1L
  )

# Add never-treated gauges (gauges not within 20km of any dam removal)
matched_gauge_ids <- unique(temp_matches$site_no)
never_treated_gauges <- temp_gauges %>%
  filter(!site_no %in% matched_gauge_ids)

cat(sprintf("  Never-treated temperature gauges: %d\n", nrow(never_treated_gauges)))

temp_panel_control <- temp_clean %>%
  filter(site_no %in% never_treated_gauges$site_no) %>%
  group_by(site_no, ym) %>%
  summarise(
    temp_mean = mean(value, na.rm = TRUE),
    temp_max  = max(value, na.rm = TRUE),
    temp_min  = min(value, na.rm = TRUE),
    temp_sd   = sd(value, na.rm = TRUE),
    n_daily   = n(),
    .groups = "drop"
  ) %>%
  filter(n_daily >= 15) %>%
  mutate(
    year      = year(ym),
    month     = month(ym),
    dam_id    = NA_character_,
    year_removed = 0L,  # Never treated (coded as 0 for CS)
    dam_height_ft = NA_real_,
    dist_km   = NA_real_,
    rel_year  = NA_integer_,
    post      = 0L,
    treated   = 0L,
    state     = NA_character_
  )

# For never-treated, get state from gauge data
temp_panel_control <- temp_panel_control %>%
  left_join(temp_gauges %>% select(site_no, state), by = "site_no") %>%
  mutate(state = coalesce(state.y, state.x)) %>%
  select(-state.x, -state.y)

# Combine treated and control
temp_panel <- bind_rows(
  temp_panel_matched %>% select(site_no, ym, year, month, temp_mean, temp_max,
                                 temp_min, temp_sd, n_daily, dam_id,
                                 year_removed, dam_height_ft, dist_km,
                                 rel_year, post, treated, state),
  temp_panel_control %>% select(site_no, ym, year, month, temp_mean, temp_max,
                                 temp_min, temp_sd, n_daily, dam_id,
                                 year_removed, dam_height_ft, dist_km,
                                 rel_year, post, treated, state)
)

cat(sprintf("  Temperature panel: %d gauge-months, %d gauges\n",
            nrow(temp_panel), n_distinct(temp_panel$site_no)))
cat(sprintf("    Treated gauges: %d\n", n_distinct(temp_panel$site_no[temp_panel$treated == 1])))
cat(sprintf("    Control gauges: %d\n", n_distinct(temp_panel$site_no[temp_panel$treated == 0])))

# --- DO PANEL ---
do_panel_matched <- do_matches %>%
  inner_join(dams %>% select(dam_id, year_removed, dam_height_ft, state),
             by = "dam_id") %>%
  inner_join(
    do_clean %>%
      group_by(site_no, ym) %>%
      summarise(
        do_mean = mean(value, na.rm = TRUE),
        do_max  = max(value, na.rm = TRUE),
        do_min  = min(value, na.rm = TRUE),
        n_daily = n(),
        .groups = "drop"
      ),
    by = "site_no"
  ) %>%
  filter(n_daily >= 15) %>%
  mutate(
    year      = year(ym),
    month     = month(ym),
    rel_year  = year - year_removed,
    post      = as.integer(year >= year_removed),
    treated   = 1L
  )

matched_do_ids <- unique(do_matches$site_no)
never_treated_do <- do_gauges %>%
  filter(!site_no %in% matched_do_ids)

do_panel_control <- do_clean %>%
  filter(site_no %in% never_treated_do$site_no) %>%
  group_by(site_no, ym) %>%
  summarise(
    do_mean = mean(value, na.rm = TRUE),
    do_max  = max(value, na.rm = TRUE),
    do_min  = min(value, na.rm = TRUE),
    n_daily = n(),
    .groups = "drop"
  ) %>%
  filter(n_daily >= 15) %>%
  mutate(
    year      = year(ym),
    month     = month(ym),
    dam_id    = NA_character_,
    year_removed = 0L,
    dam_height_ft = NA_real_,
    dist_km   = NA_real_,
    rel_year  = NA_integer_,
    post      = 0L,
    treated   = 0L,
    state     = NA_character_
  )

do_panel_control <- do_panel_control %>%
  left_join(do_gauges %>% select(site_no, state), by = "site_no") %>%
  mutate(state = coalesce(state.y, state.x)) %>%
  select(-state.x, -state.y)

do_panel <- bind_rows(
  do_panel_matched %>% select(site_no, ym, year, month, do_mean, do_max,
                               do_min, n_daily, dam_id, year_removed,
                               dam_height_ft, dist_km, rel_year, post,
                               treated, state),
  do_panel_control %>% select(site_no, ym, year, month, do_mean, do_max,
                               do_min, n_daily, dam_id, year_removed,
                               dam_height_ft, dist_km, rel_year, post,
                               treated, state)
)

cat(sprintf("  DO panel: %d gauge-months, %d gauges\n",
            nrow(do_panel), n_distinct(do_panel$site_no)))
cat(sprintf("    Treated gauges: %d\n", n_distinct(do_panel$site_no[do_panel$treated == 1])))
cat(sprintf("    Control gauges: %d\n", n_distinct(do_panel$site_no[do_panel$treated == 0])))

# ============================================================================
# 5. SAVE ANALYSIS PANELS
# ============================================================================

saveRDS(dams, file.path(data_dir, "dams_clean.rds"))
saveRDS(temp_panel, file.path(data_dir, "temp_panel.rds"))
saveRDS(do_panel, file.path(data_dir, "do_panel.rds"))
saveRDS(temp_matches, file.path(data_dir, "temp_matches.rds"))
saveRDS(do_matches, file.path(data_dir, "do_matches.rds"))

cat("\n=== Panel construction complete ===\n")
cat(sprintf("  Saved to: %s\n", data_dir))
