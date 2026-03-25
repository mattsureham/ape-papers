# =============================================================================
# 02_clean_data.R — Construct treatment and outcome variables
# =============================================================================

source("00_packages.R")

hd <- readRDS("../data/hd_raw.rds")
ef <- readRDS("../data/ef_raw.rds")

# ---------------------------------------------------------------------------
# 1. Identify for-profit closures (2015 present, 2018 absent) as treatment
# ---------------------------------------------------------------------------
# These capture ACICS collapse + related for-profit closures (ITT Tech, etc.)
fp_2015 <- hd %>%
  filter(year == 2015, control == 3) %>%
  select(unitid, sector, county_fips, state)

fp_2018_ids <- hd %>%
  filter(year == 2018, control == 3) %>%
  pull(unitid) %>%
  unique()

# Institutions that closed
closed_ids <- fp_2015 %>%
  filter(!unitid %in% fp_2018_ids) %>%
  pull(unitid) %>%
  unique()

cat("For-profit closures 2015-2018:", length(closed_ids), "\n")
stopifnot(length(closed_ids) > 100)

# ---------------------------------------------------------------------------
# 2. Get enrollment of closed institutions in 2015 (treatment intensity)
# ---------------------------------------------------------------------------
closed_enrollment <- ef %>%
  filter(unitid %in% closed_ids, year == 2015) %>%
  inner_join(
    hd %>% filter(year == 2015) %>% select(unitid, county_fips, state),
    by = "unitid"
  ) %>%
  filter(!is.na(county_fips)) %>%
  group_by(county_fips) %>%
  summarise(
    n_closed_inst    = n(),
    closed_total     = sum(eftotlt, na.rm = TRUE),
    closed_black     = sum(efbkaat, na.rm = TRUE),
    closed_hispanic  = sum(efhispt, na.rm = TRUE),
    closed_white     = sum(efwhitt, na.rm = TRUE),
    .groups = "drop"
  )

cat("Counties with closures:", nrow(closed_enrollment), "\n")
cat("Total displaced enrollment:", sum(closed_enrollment$closed_total), "\n")

# ---------------------------------------------------------------------------
# 3. All for-profit enrollment in 2015 by county (broader treatment measure)
# ---------------------------------------------------------------------------
fp_enrollment_2015 <- ef %>%
  filter(year == 2015) %>%
  inner_join(
    hd %>% filter(year == 2015, control == 3) %>% select(unitid, county_fips),
    by = "unitid"
  ) %>%
  filter(!is.na(county_fips)) %>%
  group_by(county_fips) %>%
  summarise(
    fp_total_2015 = sum(eftotlt, na.rm = TRUE),
    .groups = "drop"
  )

# ---------------------------------------------------------------------------
# 4. Construct county-year-race panel: community college enrollment
# ---------------------------------------------------------------------------
# Community colleges = sector 4 (public 2-year)
cc_panel <- ef %>%
  inner_join(
    hd %>% select(unitid, year, county_fips, sector, state) %>%
      filter(sector == 4),
    by = c("unitid", "year")
  ) %>%
  filter(!is.na(county_fips)) %>%
  group_by(county_fips, year, state) %>%
  summarise(
    cc_total    = sum(eftotlt, na.rm = TRUE),
    cc_black    = sum(efbkaat, na.rm = TRUE),
    cc_hispanic = sum(efhispt, na.rm = TRUE),
    cc_white    = sum(efwhitt, na.rm = TRUE),
    cc_asian    = sum(efasiat, na.rm = TRUE),
    n_cc        = n_distinct(unitid),
    .groups     = "drop"
  )

cat("CC panel: ", nrow(cc_panel), " county-year obs\n")
cat("Counties with CC: ", n_distinct(cc_panel$county_fips), "\n")
cat("Years: ", range(cc_panel$year), "\n")

# ---------------------------------------------------------------------------
# 5. 4-year public enrollment (placebo outcome)
# ---------------------------------------------------------------------------
pub4yr_panel <- ef %>%
  inner_join(
    hd %>% select(unitid, year, county_fips, sector) %>%
      filter(sector == 1),
    by = c("unitid", "year")
  ) %>%
  filter(!is.na(county_fips)) %>%
  group_by(county_fips, year) %>%
  summarise(
    pub4_total    = sum(eftotlt, na.rm = TRUE),
    pub4_black    = sum(efbkaat, na.rm = TRUE),
    pub4_hispanic = sum(efhispt, na.rm = TRUE),
    pub4_white    = sum(efwhitt, na.rm = TRUE),
    .groups       = "drop"
  )

# ---------------------------------------------------------------------------
# 6. Merge into analysis dataset
# ---------------------------------------------------------------------------
# Start with CC panel, merge treatment
analysis <- cc_panel %>%
  left_join(closed_enrollment, by = "county_fips") %>%
  left_join(fp_enrollment_2015, by = "county_fips") %>%
  mutate(
    # Treatment variables
    n_closed_inst   = replace_na(n_closed_inst, 0),
    closed_total    = replace_na(closed_total, 0),
    closed_black    = replace_na(closed_black, 0),
    closed_hispanic = replace_na(closed_hispanic, 0),
    closed_white    = replace_na(closed_white, 0),
    fp_total_2015   = replace_na(fp_total_2015, 0),
    # Treatment intensity = log(1 + displaced enrollment) / log(1 + CC enrollment in 2015)
    has_closure     = as.integer(closed_total > 0),
    # Post period: ACICS revocation Sept 2016 → academic year 2017+
    post            = as.integer(year >= 2017),
    # Log outcomes
    log_cc_total    = log(cc_total + 1),
    log_cc_black    = log(cc_black + 1),
    log_cc_hispanic = log(cc_hispanic + 1),
    log_cc_white    = log(cc_white + 1),
    # Treatment intensity (continuous)
    log_displaced   = log(closed_total + 1)
  )

# Merge placebo outcome
analysis <- analysis %>%
  left_join(pub4yr_panel, by = c("county_fips", "year"))

# State FIPS from county FIPS (first 2 digits)
analysis <- analysis %>%
  mutate(state_fips = county_fips %/% 1000)

cat("\n--- Analysis dataset ---\n")
cat("Rows:", nrow(analysis), "\n")
cat("Counties:", n_distinct(analysis$county_fips), "\n")
cat("Treated counties (has_closure=1):", sum(analysis$has_closure & analysis$year == 2015), "\n")
cat("Control counties:", sum(!analysis$has_closure & analysis$year == 2015), "\n")

# ---------------------------------------------------------------------------
# 7. Reshape to long format (by race) for DDD specification
# ---------------------------------------------------------------------------
analysis_long <- analysis %>%
  select(county_fips, year, state, state_fips, post,
         has_closure, closed_total, log_displaced,
         cc_total, cc_black, cc_hispanic, cc_white) %>%
  pivot_longer(
    cols = c(cc_black, cc_hispanic, cc_white),
    names_to = "race",
    values_to = "enrollment"
  ) %>%
  mutate(
    race = str_replace(race, "cc_", ""),
    minority = as.integer(race %in% c("black", "hispanic")),
    log_enroll = log(enrollment + 1)
  )

# ---------------------------------------------------------------------------
# 8. Save
# ---------------------------------------------------------------------------
saveRDS(analysis, "../data/analysis.rds")
saveRDS(analysis_long, "../data/analysis_long.rds")
cat("\nSaved analysis.rds and analysis_long.rds\n")
