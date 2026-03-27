## 02_clean_data.R — Variable construction and sample restrictions
## apep_1055: USPS Mail Slowdown and Preventable Hospitalizations

source("00_packages.R")

data_dir <- "../data/"
df <- readRDS(file.path(data_dir, "analysis_data.rds"))

cat("=== Data cleaning and variable construction ===\n")
cat(sprintf("Raw dataset: %d obs, %d counties\n", nrow(df), n_distinct(df$fips)))

# ============================================================================
# 1. SAMPLE RESTRICTIONS
# ============================================================================

# Drop non-contiguous states (Alaska, Hawaii) — different mail regime entirely
df <- df %>% filter(!non_contiguous)
cat(sprintf("After dropping AK/HI: %d obs, %d counties\n", nrow(df), n_distinct(df$fips)))

# Drop counties with extreme population (< 1000 or missing)
df <- df %>% filter(!is.na(population), population >= 1000)
cat(sprintf("After population filter: %d obs, %d counties\n", nrow(df), n_distinct(df$fips)))

# Drop counties missing key controls
df <- df %>% filter(
  !is.na(median_hh_income),
  !is.na(pct_65plus),
  !is.na(pharm_desert)
)
cat(sprintf("After dropping missing controls: %d obs, %d counties\n", nrow(df), n_distinct(df$fips)))

# ============================================================================
# 2. VARIABLE CONSTRUCTION
# ============================================================================

# Standardize outcome for interpretability
df <- df %>%
  group_by(fips) %>%
  mutate(
    # Pre-treatment mean and SD for each county
    pre_mean_hosp = mean(prev_hosp_rate[year < 2022], na.rm = TRUE),
    pre_sd_hosp = sd(prev_hosp_rate[year < 2022], na.rm = TRUE)
  ) %>%
  ungroup()

# Population-weighted outcome
df <- df %>%
  mutate(
    # Log outcome (for % interpretation)
    log_prev_hosp = log(prev_hosp_rate + 1),
    # Income quintiles
    income_quintile = ntile(median_hh_income, 5),
    # Elderly share quintiles
    elderly_quintile = ntile(pct_65plus, 5),
    # Distance quartiles for heterogeneity
    dist_quartile = ntile(dist_to_pdc, 4),
    # Year as factor for event study
    year_factor = factor(year),
    # Relative year (2021 = 0, the last pre-treatment year)
    rel_year = year - 2021
  )

# Create balanced panel indicator
county_year_counts <- df %>%
  group_by(fips) %>%
  summarise(n_years = n(), .groups = "drop")

balanced_counties <- county_year_counts %>%
  filter(n_years == max(n_years)) %>%
  pull(fips)

df <- df %>%
  mutate(balanced = fips %in% balanced_counties)

cat(sprintf("\nBalanced panel counties: %d (of %d total)\n",
            length(balanced_counties), n_distinct(df$fips)))

# ============================================================================
# 3. SUMMARY STATISTICS
# ============================================================================

cat("\n=== Summary Statistics ===\n")

# By treatment status
summ_by_treat <- df %>%
  filter(year == 2019) %>%  # Pre-treatment baseline
  group_by(treated) %>%
  summarise(
    n_counties = n(),
    mean_hosp_rate = mean(prev_hosp_rate, na.rm = TRUE),
    sd_hosp_rate = sd(prev_hosp_rate, na.rm = TRUE),
    mean_pop = mean(population, na.rm = TRUE),
    mean_income = mean(median_hh_income, na.rm = TRUE),
    mean_pct_65 = mean(pct_65plus, na.rm = TRUE),
    mean_pct_uninsured = mean(pct_uninsured, na.rm = TRUE),
    pct_pharm_desert = mean(pharm_desert, na.rm = TRUE) * 100,
    mean_dist_pdc = mean(dist_to_pdc, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nBaseline characteristics (2019) by treatment status:\n")
print(as.data.frame(summ_by_treat), digits = 3)

# By pharmacy desert status
summ_by_desert <- df %>%
  filter(year == 2019) %>%
  group_by(pharm_desert) %>%
  summarise(
    n_counties = n(),
    mean_hosp_rate = mean(prev_hosp_rate, na.rm = TRUE),
    mean_pop = mean(population, na.rm = TRUE),
    mean_dist_pdc = mean(dist_to_pdc, na.rm = TRUE),
    pct_treated = mean(treated, na.rm = TRUE) * 100,
    .groups = "drop"
  )

cat("\nBaseline characteristics (2019) by pharmacy desert status:\n")
print(as.data.frame(summ_by_desert), digits = 3)

# Overall outcome trends
outcome_trends <- df %>%
  group_by(year) %>%
  summarise(
    mean_hosp = mean(prev_hosp_rate, na.rm = TRUE),
    sd_hosp = sd(prev_hosp_rate, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  )

cat("\nPreventable hospitalization rate by year:\n")
print(as.data.frame(outcome_trends), digits = 2)

# ============================================================================
# 4. SAVE CLEANED DATA
# ============================================================================

saveRDS(df, file.path(data_dir, "analysis_clean.rds"))
cat(sprintf("\n✓ Cleaned dataset saved: %d obs, %d counties, years %d-%d\n",
            nrow(df), n_distinct(df$fips),
            min(df$year), max(df$year)))

# Save summary stats for later use in paper
summ_stats <- list(
  n_obs = nrow(df),
  n_counties = n_distinct(df$fips),
  n_treated = n_distinct(df$fips[df$treated == 1]),
  n_control = n_distinct(df$fips[df$treated == 0]),
  n_desert = n_distinct(df$fips[df$pharm_desert == 1]),
  n_nondesert = n_distinct(df$fips[df$pharm_desert == 0]),
  years = sort(unique(df$year)),
  n_pre = sum(unique(df$year) < 2022),
  n_post = sum(unique(df$year) >= 2022),
  mean_hosp_pre = mean(df$prev_hosp_rate[df$year < 2022], na.rm = TRUE),
  sd_hosp_pre = sd(df$prev_hosp_rate[df$year < 2022], na.rm = TRUE),
  mean_slowdown_treated = mean(df$mail_slowdown[df$treated == 1 & df$year == 2019], na.rm = TRUE)
)

saveRDS(summ_stats, file.path(data_dir, "summary_stats.rds"))
cat("✓ Summary statistics saved\n")
