## 02_clean_data.R — Merge spatial data with ACS and construct analysis dataset
## apep_0718: Tornado Paths and Manufactured Housing

source("00_packages.R")

cat("=== Loading saved data ===\n")
near_tracts <- readRDS("../data/tracts_with_distances.rds")
acs_combined <- readRDS("../data/acs_combined.rds")

cat(sprintf("Tracts with distances: %d\n", nrow(near_tracts)))
cat(sprintf("ACS observations: %d\n", nrow(acs_combined)))

# Drop geometry for merging (keep it separate)
tracts_df <- near_tracts %>%
  st_drop_geometry() %>%
  select(GEOID, STATEFP, COUNTYFP, in_path, near_path, dist_to_path_m,
         dist_to_path_mi, tornado_year)

# Reshape ACS to wide format (pre vs post)
acs_pre <- acs_combined %>%
  filter(period == "pre") %>%
  select(GEOID, ends_with("E")) %>%
  rename_with(~ paste0(.x, "_pre"), -GEOID)

acs_post <- acs_combined %>%
  filter(period == "post") %>%
  select(GEOID, ends_with("E")) %>%
  rename_with(~ paste0(.x, "_post"), -GEOID)

# Merge pre and post
acs_wide <- inner_join(acs_pre, acs_post, by = "GEOID")
cat(sprintf("Tracts with both pre and post ACS: %d\n", nrow(acs_wide)))

# Merge with spatial/distance data
analysis_df <- inner_join(tracts_df, acs_wide, by = "GEOID")
cat(sprintf("Analysis dataset: %d tracts\n", nrow(analysis_df)))

# Construct outcome variables (changes)
analysis_df <- analysis_df %>%
  mutate(
    # Mobile home share changes
    mobile_pct_pre  = mobile_homesE_pre / total_unitsE_pre * 100,
    mobile_pct_post = mobile_homesE_post / total_unitsE_post * 100,
    delta_mobile_pct = mobile_pct_post - mobile_pct_pre,

    # Mobile home count changes
    delta_mobile_units = mobile_homesE_post - mobile_homesE_pre,

    # Poverty rate changes
    poverty_rate_pre  = poverty_numE_pre / poverty_denomE_pre * 100,
    poverty_rate_post = poverty_numE_post / poverty_denomE_post * 100,
    delta_poverty = poverty_rate_post - poverty_rate_pre,

    # Median housing value changes (log)
    log_value_pre  = log(pmax(median_valueE_pre, 1)),
    log_value_post = log(pmax(median_valueE_post, 1)),
    delta_log_value = log_value_post - log_value_pre,

    # Population changes
    delta_pop = total_popE_post - total_popE_pre,
    delta_log_pop = log(pmax(total_popE_post, 1)) - log(pmax(total_popE_pre, 1)),

    # Median income changes (log)
    delta_log_income = log(pmax(median_incomeE_post, 1)) - log(pmax(median_incomeE_pre, 1)),

    # Vacancy rate changes
    vacancy_pre  = vacant_unitsE_pre / total_unitsE_pre * 100,
    vacancy_post = vacant_unitsE_post / total_unitsE_post * 100,
    delta_vacancy = vacancy_post - vacancy_pre,

    # Treatment indicator
    treated = as.integer(in_path),

    # Signed distance in miles (negative = inside path)
    dist_mi = dist_to_path_mi,

    # State FE
    state = STATEFP,

    # Pre-tornado mobile home share (for heterogeneity)
    pre_mobile_share = mobile_pct_pre
  )

# Filter to analysis sample:
# 1. Non-missing key outcomes
# 2. Within reasonable bandwidth (within 5 miles of path edge)
# 3. Pre-tornado had some housing units
analysis_df <- analysis_df %>%
  filter(
    !is.na(delta_mobile_pct),
    !is.na(delta_poverty),
    !is.na(delta_log_value),
    abs(dist_mi) <= 5,
    total_unitsE_pre >= 50  # Minimum tract size
  )

cat(sprintf("\n=== Analysis sample ===\n"))
cat(sprintf("Total tracts: %d\n", nrow(analysis_df)))
cat(sprintf("  Treated (in path): %d\n", sum(analysis_df$treated == 1)))
cat(sprintf("  Control (near path): %d\n", sum(analysis_df$treated == 0)))
cat(sprintf("  States: %d\n", n_distinct(analysis_df$state)))
cat(sprintf("\nOutcome summary:\n"))
cat(sprintf("  Delta mobile home %%: mean=%.2f, sd=%.2f\n",
            mean(analysis_df$delta_mobile_pct, na.rm = TRUE),
            sd(analysis_df$delta_mobile_pct, na.rm = TRUE)))
cat(sprintf("  Delta poverty rate: mean=%.2f, sd=%.2f\n",
            mean(analysis_df$delta_poverty, na.rm = TRUE),
            sd(analysis_df$delta_poverty, na.rm = TRUE)))
cat(sprintf("  Delta log housing value: mean=%.3f, sd=%.3f\n",
            mean(analysis_df$delta_log_value, na.rm = TRUE),
            sd(analysis_df$delta_log_value, na.rm = TRUE)))

stopifnot("Insufficient treated tracts" = sum(analysis_df$treated == 1) >= 20)
stopifnot("Insufficient control tracts" = sum(analysis_df$treated == 0) >= 50)

saveRDS(analysis_df, "../data/analysis_dataset.rds")
cat("\nAnalysis dataset saved.\n")
