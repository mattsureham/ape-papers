# 02_clean_data.R — Construct analysis panel
# apep_1051: CRP Cap Reduction and Land-Use Transitions

source("00_packages.R")

data_dir <- "../data"

crp   <- readRDS(file.path(data_dir, "crp_enrollment.rds"))
crops <- readRDS(file.path(data_dir, "crop_acreage.rds"))
cland <- readRDS(file.path(data_dir, "total_cropland.rds"))

cat("Loaded: CRP", nrow(crp), "| Crops", nrow(crops), "| Cropland", nrow(cland), "\n")

# ============================================================
# 1. CONSTRUCT CRP TREATMENT VARIABLE
# ============================================================

# Treatment intensity: CRP acre loss from peak (2012-2013) to trough (2018-2019)
# The 2014 Farm Bill forced cap reduction from 32M to 24M acres

# Compute pre-reform CRP level (average 2012-2013) and post-reform (average 2018-2019)
crp_pre <- crp %>%
  filter(year %in% 2012:2013) %>%
  group_by(fips, state_name, county_name) %>%
  summarise(crp_pre = mean(crp_acres, na.rm = TRUE), .groups = "drop")

crp_post <- crp %>%
  filter(year %in% 2018:2019) %>%
  group_by(fips) %>%
  summarise(crp_post = mean(crp_acres, na.rm = TRUE), .groups = "drop")

crp_change <- crp_pre %>%
  left_join(crp_post, by = "fips") %>%
  mutate(
    crp_loss = crp_pre - crp_post,  # positive = lost CRP acres
    crp_loss = pmax(crp_loss, 0)     # only count net losses
  )

# Get total cropland from Census 2012 for denominator
cropland_2012 <- cland %>%
  filter(year == 2012) %>%
  select(fips, total_cropland)

crp_treat <- crp_change %>%
  left_join(cropland_2012, by = "fips") %>%
  filter(!is.na(total_cropland), total_cropland > 0) %>%
  mutate(
    treatment = crp_loss / total_cropland,  # share of cropland lost from CRP
    high_treat = treatment > median(treatment[treatment > 0]),
    treat_quartile = ntile(treatment, 4)
  )

cat("Treatment variable constructed:\n")
cat("  Counties with CRP data:", nrow(crp_treat), "\n")
cat("  Counties with CRP loss > 0:", sum(crp_treat$crp_loss > 0), "\n")
cat("  Mean treatment (share):", round(mean(crp_treat$treatment), 4), "\n")
cat("  Median treatment:", round(median(crp_treat$treatment), 4), "\n")
cat("  Mean CRP loss (acres):", round(mean(crp_treat$crp_loss), 1), "\n")
cat("  Total CRP loss:", round(sum(crp_treat$crp_loss) / 1e6, 2), "M acres\n")

# ============================================================
# 2. CONSTRUCT OUTCOME: TOTAL CROP ACREAGE PANEL
# ============================================================

# Wide format: one row per county-year with total planted acres across crops
crop_panel <- crops %>%
  filter(crop %in% c("CORN", "SOYBEANS", "WHEAT")) %>%
  group_by(fips, year) %>%
  summarise(
    total_planted = sum(acres, na.rm = TRUE),
    n_crops = n_distinct(crop),
    .groups = "drop"
  )

# Also individual crops for mechanism tests
crop_wide <- crops %>%
  filter(crop %in% c("CORN", "SOYBEANS", "WHEAT", "HAY")) %>%
  group_by(fips, year, crop) %>%
  summarise(acres = sum(acres, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(
    id_cols = c(fips, year),
    names_from = crop,
    values_from = acres,
    values_fill = 0
  ) %>%
  rename_with(tolower)

# Merge total with individual
outcome <- crop_panel %>%
  left_join(crop_wide, by = c("fips", "year"))

cat("Outcome panel:", nrow(outcome), "obs,", n_distinct(outcome$fips),
    "counties,", paste(range(outcome$year), collapse = "-"), "\n")

# ============================================================
# 3. MERGE INTO ANALYSIS PANEL
# ============================================================

# State FIPS for state-by-year FE
state_fips <- crp %>%
  select(fips, state_name) %>%
  distinct() %>%
  mutate(state_fips = substr(fips, 1, 2))

panel <- outcome %>%
  inner_join(crp_treat %>% select(fips, state_name, county_name, crp_pre, crp_loss,
                                   total_cropland, treatment, high_treat, treat_quartile),
             by = "fips") %>%
  left_join(state_fips %>% select(fips, state_fips), by = "fips") %>%
  mutate(
    post = as.integer(year >= 2014),
    treat_x_post = treatment * post,
    high_x_post = high_treat * post,
    # Normalize outcome: planted acres as share of total cropland
    planted_share = total_planted / total_cropland,
    # Log outcomes
    ln_planted = log(total_planted + 1),
    ln_corn = log(corn + 1),
    ln_soy = log(soybeans + 1),
    ln_wheat = log(wheat + 1),
    ln_hay = log(hay + 1)
  ) %>%
  filter(!is.na(state_fips))

cat("Analysis panel:", nrow(panel), "obs,", n_distinct(panel$fips),
    "counties,", paste(range(panel$year), collapse = "-"), "\n")
cat("Pre-treatment obs:", sum(panel$year < 2014),
    "| Post-treatment:", sum(panel$year >= 2014), "\n")

# ============================================================
# 4. CRP ENROLLMENT TIME SERIES (for descriptive panel)
# ============================================================

crp_ts <- crp %>%
  group_by(year) %>%
  summarise(
    total_crp = sum(crp_acres, na.rm = TRUE),
    n_counties = n_distinct(fips),
    mean_crp = mean(crp_acres, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nCRP National Time Series:\n")
print(crp_ts %>% filter(year %in% c(2006, 2010, 2012, 2013, 2014, 2016, 2018, 2020, 2022)))

# ============================================================
# 5. SAVE
# ============================================================

saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
saveRDS(crp_treat, file.path(data_dir, "crp_treatment.rds"))
saveRDS(crp_ts, file.path(data_dir, "crp_timeseries.rds"))

cat("\nPanel saved:", nrow(panel), "obs\n")
cat("Treatment counties:", n_distinct(panel$fips), "\n")
cat("Treated (high_treat):", n_distinct(panel$fips[panel$high_treat]), "\n")
cat("Control (low_treat):", n_distinct(panel$fips[!panel$high_treat]), "\n")
