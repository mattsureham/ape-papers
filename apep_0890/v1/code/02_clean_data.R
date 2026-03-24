# 02_clean_data.R — Data cleaning and variable construction
# apep_0890: Craigslist Entry and Local Journalism Employment

source("00_packages.R")
setwd(file.path(getwd(), "..", "data"))

panel <- readRDS("panel_publishing.rds")

# =============================================================================
# 1. Filter to analysis sample
# =============================================================================
# Keep 2001-2015 to avoid:
# - Pre-2001: QWI coverage is spotty for many states
# - Post-2015: NAICS reclassification issues
panel <- panel %>%
  filter(year >= 2001, year <= 2015)

# Drop counties with all-zero employment (suppressed or non-existent publishing)
county_emp <- panel %>%
  group_by(fips) %>%
  summarise(
    total_emp = sum(emp, na.rm = TRUE),
    n_nonzero = sum(emp > 0, na.rm = TRUE),
    n_periods = n(),
    .groups = "drop"
  )

# Keep counties with at least 8 quarters of positive employment
# (need meaningful time series)
valid_counties <- county_emp %>%
  filter(n_nonzero >= 8, total_emp > 0) %>%
  pull(fips)

panel <- panel %>% filter(fips %in% valid_counties)
cat("Counties after filtering:", n_distinct(panel$fips), "\n")

# =============================================================================
# 2. Construct analysis variables
# =============================================================================
panel <- panel %>%
  mutate(
    # Log employment (add 1 to handle zeros)
    ln_emp = log(emp + 1),
    # State FIPS for clustering
    state_fips = as.integer(fips %/% 1000),
    # Year-quarter string for display
    yq = paste0(year, "Q", quarter),
    # For CS-DiD: first_treat must be 0 for never-treated
    g = ifelse(treated_ever, cl_entry_year, 0L)
  )

# =============================================================================
# 3. Summary statistics
# =============================================================================
cat("\n=== Sample Summary ===\n")
cat("Observations:", nrow(panel), "\n")
cat("Counties:", n_distinct(panel$fips), "\n")
cat("States:", n_distinct(panel$state_fips), "\n")
cat("Time periods:", n_distinct(panel$time_period), "\n")
cat("Years:", paste(range(panel$year), collapse = "-"), "\n")

cat("\nTreatment status:\n")
county_level <- panel %>%
  distinct(fips, treated_ever, g) %>%
  group_by(treated_ever) %>%
  summarise(n = n(), .groups = "drop")
print(county_level)

cat("\nTreated counties by entry cohort:\n")
cohort_dist <- panel %>%
  filter(treated_ever) %>%
  distinct(fips, g) %>%
  count(g, name = "n_counties")
print(cohort_dist)

cat("\nEmployment summary (publishing):\n")
print(summary(panel$emp))

cat("\nLog employment summary:\n")
print(summary(panel$ln_emp))

# Pre-treatment SD of outcome for SDE calculation
pre_stats <- panel %>%
  filter(post == 0 | !treated_ever) %>%
  summarise(
    sd_emp = sd(emp, na.rm = TRUE),
    sd_ln_emp = sd(ln_emp, na.rm = TRUE),
    mean_emp = mean(emp, na.rm = TRUE),
    mean_ln_emp = mean(ln_emp, na.rm = TRUE)
  )
cat("\nPre-treatment outcome statistics:\n")
print(pre_stats)

# =============================================================================
# 4. Balanced panel check
# =============================================================================
# CS-DiD works with unbalanced panels, but check coverage
panel_balance <- panel %>%
  group_by(fips) %>%
  summarise(n_periods = n(), .groups = "drop")

cat("\nPanel balance:\n")
cat("  Min periods:", min(panel_balance$n_periods), "\n")
cat("  Max periods:", max(panel_balance$n_periods), "\n")
cat("  Median periods:", median(panel_balance$n_periods), "\n")
cat("  Counties with full panel (60 quarters):", sum(panel_balance$n_periods == 60), "\n")

# =============================================================================
# 5. Save clean panel
# =============================================================================
saveRDS(panel, "panel_clean.rds")
saveRDS(pre_stats, "pre_stats.rds")

# Save key parameters for later scripts
params <- list(
  n_obs = nrow(panel),
  n_counties = n_distinct(panel$fips),
  n_treated = sum(county_level$n[county_level$treated_ever]),
  n_control = sum(county_level$n[!county_level$treated_ever]),
  n_states = n_distinct(panel$state_fips),
  year_range = range(panel$year),
  sd_ln_emp = pre_stats$sd_ln_emp,
  mean_emp = pre_stats$mean_emp
)
saveRDS(params, "params.rds")

cat("\nClean panel saved:", nrow(panel), "rows\n")
