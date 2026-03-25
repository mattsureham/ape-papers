## 02_clean_data.R — Construct analysis dataset
## apep_0897: The Carboniferous Lottery

source("00_packages.R")

DATA_DIR <- "../data"

# ======================================================================
# STATE FIPS MAPPING
# ======================================================================
state_fips_map <- c(
  "AL" = "01", "KY" = "21", "OH" = "39", "PA" = "42",
  "TN" = "47", "VA" = "51", "WV" = "54"
)

# ======================================================================
# 1. LOAD RAW DATA
# ======================================================================
cat("=== Loading raw data ===\n")
coal_mines <- readRDS(file.path(DATA_DIR, "msha_mines.rds"))
coal_prod  <- readRDS(file.path(DATA_DIR, "msha_production.rds"))
wqp_data   <- readRDS(file.path(DATA_DIR, "wqp_conductance.rds"))
acs_data   <- readRDS(file.path(DATA_DIR, "census_acs.rds"))

# ======================================================================
# 2. CONSTRUCT COUNTY FIPS FOR MINES
# ======================================================================
cat("=== Constructing county FIPS ===\n")

coal_mines <- coal_mines %>%
  mutate(
    state_fips = state_fips_map[state],
    fips = paste0(state_fips, str_pad(fips_cnty_cd, 3, pad = "0"))
  ) %>%
  filter(!is.na(state_fips))

cat("  Mines with valid FIPS:", sum(!is.na(coal_mines$fips)), "\n")

# Production data has state.x (from prod) and state.y (from mines join)
# Use whichever state column exists
if ("state" %in% names(coal_prod)) {
  coal_prod$state_abbr <- coal_prod$state
} else if ("state.x" %in% names(coal_prod)) {
  coal_prod$state_abbr <- coal_prod$state.x
} else if ("state.y" %in% names(coal_prod)) {
  coal_prod$state_abbr <- coal_prod$state.y
}

coal_prod <- coal_prod %>%
  mutate(
    state_fips = state_fips_map[state_abbr],
    fips = paste0(state_fips, str_pad(fips_cnty_cd, 3, pad = "0"))
  ) %>%
  filter(!is.na(state_fips))

# ======================================================================
# 3. COUNTY-LEVEL MINING VARIABLES (2010-2020)
# ======================================================================
cat("=== Constructing mining variables ===\n")

# Use exact column names from MSHA production data
coal_prod$production <- as.numeric(coal_prod$coal_production)
coal_prod$yr <- as.integer(coal_prod$cal_yr)
coal_prod$employment <- as.numeric(coal_prod$avg_employee_cnt)

# Aggregate annual production by county and mine type
annual_prod <- coal_prod %>%
  filter(!is.na(production), !is.na(current_mine_type),
         current_mine_type %in% c("Surface", "Underground"),
         !is.na(yr)) %>%
  group_by(fips, state_fips, current_mine_type, yr) %>%
  summarize(
    coal_tons = sum(production, na.rm = TRUE),
    n_mines = n_distinct(mine_id),
    total_emp = sum(employment, na.rm = TRUE),
    .groups = "drop"
  )

cat("  Annual production records:", nrow(annual_prod), "\n")
cat("  Year range:", min(annual_prod$yr, na.rm = TRUE), "-",
    max(annual_prod$yr, na.rm = TRUE), "\n")

# Cross-sectional county averages (2010-2020)
county_mining <- annual_prod %>%
  filter(yr >= 2010 & yr <= 2020) %>%
  group_by(fips, state_fips, current_mine_type) %>%
  summarize(
    total_tons = sum(coal_tons, na.rm = TRUE),
    avg_annual_emp = mean(total_emp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from = current_mine_type,
    values_from = c(total_tons, avg_annual_emp),
    values_fill = 0
  )

county_mining <- county_mining %>%
  mutate(
    total_production = total_tons_Surface + total_tons_Underground,
    surface_share = ifelse(total_production > 0,
                           total_tons_Surface / total_production, NA_real_),
    total_emp = avg_annual_emp_Surface + avg_annual_emp_Underground
  ) %>%
  filter(total_production > 0)

cat("  Counties with coal production (2010-2020):", nrow(county_mining), "\n")

# ======================================================================
# 4. GEOLOGICAL INSTRUMENT
# ======================================================================
cat("=== Constructing geological instrument ===\n")

# The instrument: fraction of ALL mines ever opened in a county
# that are surface mines. This reflects geological accessibility.
# Coal seams near the surface → more surface mines historically.
instrument <- coal_mines %>%
  filter(current_mine_type %in% c("Surface", "Underground")) %>%
  group_by(fips) %>%
  summarize(
    n_mines_total = n(),
    n_surface_all = sum(current_mine_type == "Surface"),
    n_underground_all = sum(current_mine_type == "Underground"),
    geo_surface_share = n_surface_all / n_mines_total,
    mean_lat = mean(latitude, na.rm = TRUE),
    mean_lon = mean(longitude, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(n_mines_total >= 3)  # At least 3 mines for stability

cat("  Counties with instrument:", nrow(instrument), "\n")
cat("  Geo surface share: mean =", round(mean(instrument$geo_surface_share), 3),
    ", sd =", round(sd(instrument$geo_surface_share), 3), "\n")

# ======================================================================
# 5. PROCESS WATER QUALITY DATA
# ======================================================================
cat("=== Processing water quality data ===\n")

# Load station metadata for county mapping
stations <- readRDS(file.path(DATA_DIR, "wqp_stations.rds"))

# Build station-to-county mapping
stn_cols <- names(stations)
stn_loc_col <- stn_cols[grepl("monitoring_location_identifier",
                               stn_cols, ignore.case = TRUE)][1]
stn_state_col <- stn_cols[grepl("state_code|statecode",
                                  stn_cols, ignore.case = TRUE)][1]
stn_county_col <- stn_cols[grepl("county_code|countycode",
                                   stn_cols, ignore.case = TRUE)][1]

cat("  Station cols — loc:", stn_loc_col, " state:", stn_state_col,
    " county:", stn_county_col, "\n")

station_map <- stations %>%
  select(all_of(c(stn_loc_col, stn_state_col, stn_county_col))) %>%
  rename(monitoring_location_identifier = !!stn_loc_col,
         stn_state_code = !!stn_state_col,
         stn_county_code = !!stn_county_col) %>%
  distinct(monitoring_location_identifier, .keep_all = TRUE) %>%
  mutate(
    st_fips = str_extract(stn_state_code, "\\d+$"),
    cty_fips = str_extract(stn_county_code, "\\d+$"),
    fips = paste0(str_pad(st_fips, 2, pad = "0"),
                  str_pad(cty_fips, 3, pad = "0"))
  ) %>%
  filter(!is.na(fips), nchar(fips) == 5)

cat("  Stations with county FIPS:", nrow(station_map), "\n")

# Process WQP results
wqp_cols <- names(wqp_data)
val_col <- wqp_cols[grepl("result.*measure.*value", wqp_cols, ignore.case = TRUE)][1]
date_col <- wqp_cols[grepl("activity.*start.*date", wqp_cols, ignore.case = TRUE)][1]
loc_col <- wqp_cols[grepl("monitoring_location_identifier",
                           wqp_cols, ignore.case = TRUE)][1]

cat("  Value col:", val_col, "\n")
cat("  Date col:", date_col, "\n")
cat("  Location col:", loc_col, "\n")

stopifnot("Cannot find WQP value column" = !is.na(val_col))

wqp_clean <- wqp_data %>%
  mutate(result_value = suppressWarnings(as.numeric(.data[[val_col]]))) %>%
  filter(!is.na(result_value), result_value > 0, result_value < 50000)

if (!is.na(date_col)) {
  wqp_clean <- wqp_clean %>%
    mutate(sample_date = as.Date(.data[[date_col]]),
           year = year(sample_date))
}

# Join with station metadata to get county FIPS
if (!is.na(loc_col)) {
  wqp_clean <- wqp_clean %>%
    rename(monitoring_location_identifier = !!loc_col) %>%
    inner_join(station_map %>% select(monitoring_location_identifier, fips),
               by = "monitoring_location_identifier")

  cat("  WQP records with county FIPS:", nrow(wqp_clean), "\n")
}

# County-level average specific conductance (2010-2020)
county_wq <- wqp_clean %>%
  filter(year >= 2010 & year <= 2020) %>%
  group_by(fips) %>%
  summarize(
    avg_conductance = mean(result_value, na.rm = TRUE),
    median_conductance = median(result_value, na.rm = TRUE),
    sd_conductance = sd(result_value, na.rm = TRUE),
    n_wq_samples = n(),
    .groups = "drop"
  ) %>%
  filter(n_wq_samples >= 5)

cat("  Counties with WQ data:", nrow(county_wq), "\n")
cat("  Conductance: mean =", round(mean(county_wq$avg_conductance), 1),
    ", sd =", round(sd(county_wq$avg_conductance), 1), "\n")

# ======================================================================
# 6. MERGE ALL DATA
# ======================================================================
cat("=== Merging datasets ===\n")

analysis_df <- county_mining %>%
  inner_join(instrument, by = "fips") %>%
  left_join(county_wq, by = "fips") %>%
  left_join(acs_data %>% select(fips, total_pop, median_income,
                                pct_poverty, pct_black, median_age,
                                NAME),
            by = "fips")

# Filter to complete cases
analysis_full <- analysis_df %>%
  filter(!is.na(avg_conductance),
         !is.na(surface_share),
         !is.na(geo_surface_share),
         !is.na(total_pop),
         !is.na(median_income)) %>%
  mutate(
    log_production = log(total_production + 1),
    log_pop = log(total_pop),
    log_income = log(median_income),
    log_conductance = log(avg_conductance)
  )

cat("\n========================================\n")
cat("ANALYSIS SAMPLE\n")
cat("========================================\n")
cat("Counties:", nrow(analysis_full), "\n")
cat("States:", length(unique(analysis_full$state_fips)),
    "(", paste(sort(unique(analysis_full$state_fips)), collapse = ", "), ")\n")
cat("Surface share: mean =", round(mean(analysis_full$surface_share), 3),
    ", sd =", round(sd(analysis_full$surface_share), 3), "\n")
cat("Geo surface share: mean =", round(mean(analysis_full$geo_surface_share), 3),
    ", sd =", round(sd(analysis_full$geo_surface_share), 3), "\n")
cat("Avg conductance: mean =", round(mean(analysis_full$avg_conductance), 1),
    ", sd =", round(sd(analysis_full$avg_conductance), 1), "\n")
cat("Correlation (surface_share, geo_surface_share):",
    round(cor(analysis_full$surface_share, analysis_full$geo_surface_share), 3), "\n")
cat("========================================\n")

# ======================================================================
# 7. PLACEBO SAMPLE (non-coal counties)
# ======================================================================
cat("=== Constructing placebo sample ===\n")

coal_fips <- county_mining$fips
non_coal <- acs_data %>%
  filter(state_fips %in% c("01", "21", "39", "42", "47", "51", "54")) %>%
  filter(!fips %in% coal_fips) %>%
  left_join(county_wq, by = "fips") %>%
  filter(!is.na(avg_conductance)) %>%
  mutate(
    log_pop = log(total_pop),
    log_income = log(median_income)
  )

cat("  Non-coal counties with WQ data:", nrow(non_coal), "\n")

# ======================================================================
# SAVE
# ======================================================================
saveRDS(analysis_full, file.path(DATA_DIR, "analysis_full.rds"))
saveRDS(annual_prod, file.path(DATA_DIR, "annual_prod.rds"))
saveRDS(non_coal, file.path(DATA_DIR, "placebo_counties.rds"))

cat("\n=== Data cleaning complete ===\n")
