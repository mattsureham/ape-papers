# Clean and prepare data for analysis
source("code/00_packages.R")

message("Loading raw data...")
df <- read_csv("data/florida_liquor_panel.csv", show_col_types = FALSE)

# ============================================================================
# CREATE ANALYSIS VARIABLES
# ============================================================================

message("Creating analysis variables...")

df <- df %>%
  mutate(
    # Log employment (main outcome)
    log_employees = log(employees + 1),

    # Treatment: threshold crossed (RDD running variable)
    # Centered running variable for RDD
    pop_distance_centered = distance_to_threshold,  # Distance to threshold

    # Threshold indicator (1 = crossed in that year)
    threshold_indicator = as.integer(threshold_crossed == 1),

    # Lottery intensity (licenses allocated / population)
    lottery_intensity = (licenses_allocated / population) * 100000,  # per 100k residents

    # Any lottery held
    lottery_held_binary = as.integer(lottery_held > 0),

    # Log population
    log_population = log(population + 1),

    # Lagged log employment
    log_employees_lag = lag(log_employees),

    # Year and county FE variables
    year_fe = year,
    county_fe = as.factor(county_fips),
    county_fe_num = as.numeric(county_fips)
  ) %>%
  arrange(county_fips, year)

# ============================================================================
# RDD BANDWIDTH SELECTION
# ============================================================================

message("Selecting RDD bandwidth...")

# Standard bandwidth for population threshold: +/- 7,500 (one threshold width)
# For sensitivity: also define +/- 5,000 and +/- 10,000

df <- df %>%
  mutate(
    # Bandwidth indicators
    in_bandwidth_5k = abs(pop_distance_centered) <= 5000,
    in_bandwidth_7.5k = abs(pop_distance_centered) <= 7500,
    in_bandwidth_10k = abs(pop_distance_centered) <= 10000,

    # Polynomial terms for RDD
    pop_distance_lin = pop_distance_centered,
    pop_distance_sq = pop_distance_centered ^ 2,
    pop_distance_cub = pop_distance_centered ^ 3,

    # Interaction: threshold × polynomial (allows slope change)
    threshold_x_lin = threshold_indicator * pop_distance_lin,
    threshold_x_sq = threshold_indicator * pop_distance_sq
  )

# ============================================================================
# SUMMARY STATISTICS & BALANCE
# ============================================================================

message("Computing summary statistics...")

# Overall summary
overall_summary <- df %>%
  summarize(
    n = n(),
    counties = n_distinct(county_fips),
    years = n_distinct(year),
    employees_mean = mean(employees, na.rm = TRUE),
    employees_sd = sd(employees, na.rm = TRUE),
    employees_min = min(employees, na.rm = TRUE),
    employees_max = max(employees, na.rm = TRUE),
    population_mean = mean(population, na.rm = TRUE),
    population_sd = sd(population, na.rm = TRUE),
    lottery_intensity_mean = mean(lottery_intensity, na.rm = TRUE),
    threshold_cross_n = sum(threshold_indicator, na.rm = TRUE)
  )

message(glue("  Overall: {overall_summary$n} obs, {overall_summary$counties} counties, {overall_summary$years} years"))
message(glue("  Avg employment: {round(overall_summary$employees_mean, 1)} ± {round(overall_summary$employees_sd, 1)}")

# Balance by threshold crossing
balance_check <- df %>%
  group_by(threshold_indicator) %>%
  summarize(
    n = n(),
    employees_mean = mean(employees, na.rm = TRUE),
    employees_sd = sd(employees, na.rm = TRUE),
    population_mean = mean(population, na.rm = TRUE),
    lottery_intensity = mean(lottery_intensity, na.rm = TRUE),
    .groups = "drop"
  )

message("  Balance by threshold crossing:")
print(balance_check)

# ============================================================================
# MISSING DATA & IMPUTATION
# ============================================================================

message("Checking for missing data...")

missing_summary <- df %>%
  summarize(across(everything(), ~ sum(is.na(.))))

message(glue("  Missing values: {sum(missing_summary)}"))
if (sum(missing_summary) > 0) {
  message("  Variables with missing data:")
  print(missing_summary[, missing_summary != 0])
}

# Forward-fill missing employment data within county
df <- df %>%
  group_by(county_fips) %>%
  fill(log_employees, .direction = "down") %>%
  ungroup()

# ============================================================================
# SAVE CLEANED DATA
# ============================================================================

write_csv(df, "data/florida_liquor_clean.csv")
message("✓ Cleaned data saved to data/florida_liquor_clean.csv")

# Save summary
summary_stats <- list(
  n_obs = nrow(df),
  n_counties = n_distinct(df$county_fips),
  n_years = n_distinct(df$year),
  n_threshold_crossings = sum(df$threshold_indicator, na.rm = TRUE),
  mean_employment = mean(df$employees, na.rm = TRUE),
  sd_employment = sd(df$employees, na.rm = TRUE),
  mean_population = mean(df$population, na.rm = TRUE),
  n_lotteries = sum(df$lottery_held_binary, na.rm = TRUE)
)

jsonlite::write_json(summary_stats, "data/summary_stats.json", auto_unbox = TRUE)
message("✓ Summary statistics saved")
