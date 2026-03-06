## 02_clean_data.R — Construct analysis panel
## APEP Paper apep_0539: Less Cash, Less Crime?

source("00_packages.R")
data_dir <- "../data"

# ===========================================================================
# 1. Load and clean UCR crime data
# ===========================================================================
cat("=== Loading UCR crime data ===\n")

ucr <- fread(file.path(data_dir, "ucr_state_crime.csv"))
cat("Raw UCR:", nrow(ucr), "obs,", n_distinct(ucr$state_abbr), "states\n")

# Compute crime rates per 100,000 from counts + population
ucr <- ucr %>%
  filter(year >= 1985, year <= 2015) %>%
  mutate(
    # Rates per 100K (compute from raw counts if rate columns missing)
    property_crime_rate = ifelse(is.na(property_crime_rate),
                                 property_crime / population * 100000,
                                 property_crime_rate),
    burglary_rate = ifelse(is.na(burglary_rate),
                           burglary / population * 100000,
                           burglary_rate),
    larceny_rate = ifelse(is.na(larceny_rate),
                          larceny / population * 100000,
                          larceny_rate),
    robbery_rate = ifelse(is.na(robbery_rate),
                          robbery / population * 100000,
                          robbery_rate),
    motor_vehicle_theft_rate = ifelse(is.na(motor_vehicle_theft_rate),
                                      motor_vehicle_theft / population * 100000,
                                      motor_vehicle_theft_rate),
    violent_crime_rate = ifelse(is.na(violent_crime_rate),
                                violent_crime / population * 100000,
                                violent_crime_rate),
    murder_rate = ifelse(is.na(murder_rate),
                         murder / population * 100000,
                         murder_rate),
    # Log crime rates (add 1 to avoid log(0))
    log_property_crime = log(property_crime_rate + 1),
    log_burglary = log(burglary_rate + 1),
    log_larceny = log(larceny_rate + 1),
    log_robbery = log(robbery_rate + 1),
    log_mvt = log(motor_vehicle_theft_rate + 1),
    log_violent = log(violent_crime_rate + 1),
    # Population in thousands
    pop_1000 = population / 1000,
    log_pop = log(population)
  ) %>%
  filter(!is.na(property_crime_rate), property_crime_rate > 0)

cat("Cleaned UCR:", nrow(ucr), "obs,", n_distinct(ucr$state_abbr), "states,",
    min(ucr$year), "-", max(ucr$year), "\n")

# ===========================================================================
# 2. Parse SNAP Policy Database for EBT adoption dates
# ===========================================================================
cat("\n=== Parsing SNAP Policy Database for EBT dates ===\n")

snap <- read_excel(file.path(data_dir, "snap_policy_database.xlsx"),
                   sheet = "SNAP Policy Database")

cat("SNAP columns with 'ebt':", paste(names(snap)[grepl("ebt", names(snap), ignore.case = TRUE)], collapse = ", "), "\n")

# Extract EBT adoption dates
# The 'ebtissuance' column should indicate when each state adopted EBT
# It's a state x yearmonth panel
ebt_data <- snap %>%
  select(state_fips, state_pc, statename, yearmonth, ebtissuance) %>%
  mutate(
    year = as.integer(substr(yearmonth, 1, 4)),
    month = as.integer(substr(yearmonth, 5, 6)),
    ebt = as.integer(ebtissuance)
  )

cat("EBT data:", nrow(ebt_data), "state-month obs\n")
cat("EBT values:", paste(sort(unique(ebt_data$ebt)), collapse = ", "), "\n")

# Find first month of EBT adoption for each state
ebt_adoption <- ebt_data %>%
  filter(ebt == 1) %>%
  group_by(state_pc, statename, state_fips) %>%
  summarise(
    ebt_first_yearmonth = min(yearmonth),
    ebt_first_year = min(year),
    ebt_first_month = month[which.min(yearmonth)],
    .groups = "drop"
  ) %>%
  mutate(state_abbr = state_pc)

cat("\nEBT adoption dates by state:\n")
ebt_adoption %>%
  arrange(ebt_first_yearmonth) %>%
  select(state_abbr, statename, ebt_first_year, ebt_first_month) %>%
  print(n = 60)

# Treatment cohort year (year of EBT adoption)
ebt_timing <- ebt_adoption %>%
  select(state_abbr, ebt_year = ebt_first_year, ebt_month = ebt_first_month)

cat("\nEBT adoption year distribution:\n")
print(table(ebt_timing$ebt_year))

# ===========================================================================
# 3. Load unemployment data
# ===========================================================================
cat("\n=== Loading unemployment data ===\n")

unemp_file <- file.path(data_dir, "bls_unemployment.csv")
if (file.exists(unemp_file) && file.size(unemp_file) > 0) {
  unemp <- fread(unemp_file)
  cat("Unemployment data:", nrow(unemp), "obs\n")
} else {
  cat("No unemployment data available. Will proceed without.\n")
  unemp <- NULL
}

# ===========================================================================
# 4. Merge into analysis panel
# ===========================================================================
cat("\n=== Building analysis panel ===\n")

# Merge UCR with EBT timing
panel <- ucr %>%
  left_join(ebt_timing, by = "state_abbr")

# Check merge
matched <- sum(!is.na(panel$ebt_year))
unmatched <- sum(is.na(panel$ebt_year))
cat("Matched to EBT timing:", matched, "obs\n")
cat("Unmatched:", unmatched, "obs\n")

if (unmatched > 0) {
  unmatched_states <- unique(panel$state_abbr[is.na(panel$ebt_year)])
  cat("Unmatched states:", paste(unmatched_states, collapse = ", "), "\n")
  cat("These may use different abbreviation codes. Attempting manual match...\n")

  # The SNAP database uses postal codes but some might differ
  # Check available state abbreviations in EBT data
  available_ebt <- unique(ebt_timing$state_abbr)
  missing_ebt <- setdiff(unique(ucr$state_abbr), available_ebt)
  cat("States in UCR but not EBT:", paste(missing_ebt, collapse = ", "), "\n")
  cat("States in EBT:", paste(sort(available_ebt), collapse = ", "), "\n")
}

# Add unemployment if available
if (!is.null(unemp)) {
  panel <- panel %>%
    left_join(unemp, by = c("state_abbr", "year"))
}

# Create treatment variables for CS-DiD
panel <- panel %>%
  mutate(
    # First treatment year (for CS-DiD: 0 = never treated, otherwise year)
    first_treat = ifelse(is.na(ebt_year), 0, ebt_year),
    # Post-treatment indicator
    post_ebt = ifelse(!is.na(ebt_year) & year >= ebt_year, 1, 0),
    # Years since treatment
    event_time = ifelse(!is.na(ebt_year), year - ebt_year, NA),
    # State numeric ID for panel
    state_id = as.integer(factor(state_abbr))
  )

# Filter to analysis sample
panel <- panel %>%
  filter(!is.na(property_crime_rate), !is.na(first_treat))

cat("\n=== Analysis Panel Summary ===\n")
cat("Observations:", nrow(panel), "\n")
cat("States:", n_distinct(panel$state_abbr), "\n")
cat("Years:", min(panel$year), "-", max(panel$year), "\n")
cat("Treated states:", sum(panel$first_treat > 0) / nrow(panel) * 100, "% of obs\n")
cat("EBT adoption cohorts:", n_distinct(panel$first_treat[panel$first_treat > 0]), "\n")

# Summary stats
cat("\n=== Crime Rate Summary (per 100K) ===\n")
panel %>%
  summarise(
    across(c(property_crime_rate, burglary_rate, larceny_rate,
             robbery_rate, motor_vehicle_theft_rate),
           list(mean = ~mean(., na.rm = TRUE),
                sd = ~sd(., na.rm = TRUE),
                min = ~min(., na.rm = TRUE),
                max = ~max(., na.rm = TRUE)))
  ) %>%
  pivot_longer(everything()) %>%
  print(n = 25)

# Save analysis panel
fwrite(panel, file.path(data_dir, "analysis_panel.csv"))
cat("\nPanel saved to data/analysis_panel.csv\n")

# Save EBT timing separately (for reference)
fwrite(ebt_timing, file.path(data_dir, "ebt_timing.csv"))
cat("EBT timing saved to data/ebt_timing.csv\n")

# ===========================================================================
# 5. Plot treatment rollout (DiD checklist step 1)
# ===========================================================================
cat("\n=== Creating treatment rollout plots ===\n")

# Rollout histogram
rollout_plot <- ebt_timing %>%
  ggplot(aes(x = ebt_year)) +
  geom_histogram(binwidth = 1, fill = "#2166AC", color = "white", alpha = 0.8) +
  labs(title = "EBT Adoption Rollout Across US States",
       x = "Year of EBT Adoption", y = "Number of States") +
  scale_x_continuous(breaks = seq(1990, 2010, 2))

ggsave(file.path("../figures", "ebt_rollout.pdf"), rollout_plot,
       width = 8, height = 5)
cat("Rollout plot saved.\n")

# Average property crime by adoption cohort (DiD checklist step 3)
cohort_trends <- panel %>%
  filter(first_treat > 0) %>%
  mutate(cohort = case_when(
    ebt_year <= 1997 ~ "Early (1994-1997)",
    ebt_year <= 2000 ~ "Mid (1998-2000)",
    TRUE ~ "Late (2001-2005)"
  )) %>%
  group_by(cohort, year) %>%
  summarise(mean_property = mean(property_crime_rate, na.rm = TRUE),
            mean_burglary = mean(burglary_rate, na.rm = TRUE),
            .groups = "drop")

cohort_plot <- cohort_trends %>%
  ggplot(aes(x = year, y = mean_property, color = cohort)) +
  geom_line(linewidth = 1) +
  labs(title = "Property Crime Rates by EBT Adoption Cohort",
       x = "Year", y = "Property Crime Rate (per 100K)",
       color = "Adoption Cohort") +
  scale_color_brewer(palette = "Set1")

ggsave(file.path("../figures", "cohort_trends.pdf"), cohort_plot,
       width = 9, height = 5)
cat("Cohort trends plot saved.\n")

cat("\n=== Data cleaning complete ===\n")
