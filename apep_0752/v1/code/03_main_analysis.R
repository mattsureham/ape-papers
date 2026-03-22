## 03_main_analysis.R — Main regressions for apep_0752
##
## Design: State-level panel with gaming state treatment
## Primary specification: Two-way FE (state + year)
## Secondary: CS DiD, dose-response, county cross-section

source("00_packages.R")
data_dir <- "../data"

state_panel <- readRDS(file.path(data_dir, "state_panel_analysis.rds"))
county_panel <- readRDS(file.path(data_dir, "county_panel_analysis.rds"))

cat("State panel:", nrow(state_panel), "obs,", n_distinct(state_panel$state), "states,",
    min(state_panel$year), "-", max(state_panel$year), "\n")
cat("County panel:", nrow(county_panel), "obs\n")

# ============================================================
# 1. MAIN SPECIFICATION: TWFE with gaming state indicator
# ============================================================
# Most gaming compacts were approved 1991-1994, well before our panel (1999-2024).
# This means "post_gaming" is essentially cross-sectional variation (always treated).
# We use a DDD: gaming_state × high_aian_share × year trends

cat("\n=== Main Specifications ===\n")

# Create high AI/AN share indicator (above-median among gaming states)
median_aian <- median(state_panel$state_aian_share[state_panel$gaming_state], na.rm = TRUE)
state_panel <- state_panel |>
  mutate(
    high_aian = state_aian_share > median_aian,
    gaming_x_highaian = gaming_state & high_aian,
    # Opioid wave periods
    period = case_when(
      year <= 2006 ~ "pre_opioid",
      year <= 2013 ~ "rx_wave",
      year <= 2019 ~ "synth_wave",
      TRUE ~ "post_covid"
    ),
    period_f = factor(period, levels = c("pre_opioid", "rx_wave", "synth_wave", "post_covid"))
  )

# Specification 1: Basic TWFE — Gaming state effect on overdose rate
m1 <- feols(od_rate ~ gaming_state | year,
            data = state_panel,
            cluster = ~state)

# Specification 2: DDD — Gaming × High AI/AN interaction
m2 <- feols(od_rate ~ gaming_state * high_aian | year,
            data = state_panel,
            cluster = ~state)

# Specification 3: Gaming × opioid wave interaction (year FE only)
# Since gaming_state is time-invariant, we cannot use state FE.
# Instead we use cross-sectional variation across states with year FE,
# interacting gaming with opioid waves to test differential trajectories.
m3 <- feols(od_rate ~ gaming_state * period_f + state_aian_share * period_f | year,
            data = state_panel |> filter(period != "post_covid"),
            cluster = ~state)

# Specification 4: DDD — Gaming × High AI/AN × Opioid Wave
# Does the protective (or enabling) effect concentrate in states with large AI/AN populations?
m4 <- feols(od_rate ~ gaming_state * high_aian * period_f | year,
            data = state_panel |> filter(period != "post_covid"),
            cluster = ~state)

cat("\n--- Spec 1: Gaming state (no state FE) ---\n")
print(summary(m1))

cat("\n--- Spec 2: Gaming × High AI/AN ---\n")
print(summary(m2))

cat("\n--- Spec 3: Gaming × AI/AN share (state + year FE) ---\n")
print(summary(m3))

cat("\n--- Spec 4: Period-specific effects ---\n")
print(summary(m4))

# ============================================================
# 2. COUNTY-LEVEL CROSS-SECTION (2020-2023)
# ============================================================

cat("\n=== County-Level Analysis ===\n")

# Specification 5: Casino county effect on overdose rate
m5 <- feols(od_rate_per_100k ~ has_casino + has_tribal_land | year,
            data = county_panel,
            cluster = ~fips)

# Specification 6: Casino × AI/AN share interaction
m6 <- feols(od_rate_per_100k ~ has_casino * aian_share_2010 + has_tribal_land | year,
            data = county_panel,
            cluster = ~fips)

cat("\n--- Spec 5: Casino county effect ---\n")
print(summary(m5))

cat("\n--- Spec 6: Casino × AI/AN share ---\n")
print(summary(m6))

# ============================================================
# 3. DESCRIPTIVE: Gaming vs Non-Gaming Overdose Trajectories
# ============================================================

cat("\n=== Descriptive Trajectories ===\n")

# Average OD rate by gaming status and year
trajectories <- state_panel |>
  group_by(year, gaming_state) |>
  summarize(
    mean_od_rate = mean(od_rate, na.rm = TRUE),
    se_od_rate = sd(od_rate, na.rm = TRUE) / sqrt(n()),
    n = n(),
    .groups = "drop"
  )

cat("Overdose rate trajectories (selected years):\n")
trajectories |>
  filter(year %in% c(1999, 2005, 2010, 2015, 2020, 2024)) |>
  mutate(gaming_label = ifelse(gaming_state, "Gaming", "Non-Gaming")) |>
  select(year, gaming_label, mean_od_rate, n) |>
  pivot_wider(names_from = gaming_label, values_from = c(mean_od_rate, n)) |>
  print()

# Trajectories for high-AI/AN gaming states specifically
high_aian_gaming <- state_panel |>
  filter(gaming_x_highaian) |>
  group_by(year) |>
  summarize(
    mean_od_rate = mean(od_rate, na.rm = TRUE),
    states = paste(unique(state), collapse = ", "),
    n = n(),
    .groups = "drop"
  )

cat("\nHigh-AI/AN gaming states trajectory:\n")
cat("States:", unique(state_panel$state[state_panel$gaming_x_highaian]), "\n")
high_aian_gaming |>
  filter(year %in% c(1999, 2005, 2010, 2015)) |>
  print()

# ============================================================
# 4. DIAGNOSTICS
# ============================================================

cat("\n=== Diagnostics ===\n")

# Treatment unit counts
n_gaming <- n_distinct(state_panel$state[state_panel$gaming_state])
n_nongaming <- n_distinct(state_panel$state[!state_panel$gaming_state])
n_pre <- length(unique(state_panel$year[state_panel$year < 2000]))
n_total_years <- length(unique(state_panel$year))

cat("Gaming states:", n_gaming, "\n")
cat("Non-gaming states:", n_nongaming, "\n")
cat("Total state-years:", nrow(state_panel), "\n")

# County-level counts
n_casino_counties <- n_distinct(county_panel$fips[county_panel$has_casino])
n_tribal_counties <- n_distinct(county_panel$fips[county_panel$has_tribal_land & !county_panel$has_casino])

cat("Casino counties:", n_casino_counties, "\n")
cat("Tribal (no casino) counties:", n_tribal_counties, "\n")

# Save diagnostics
diag <- list(
  n_treated = n_gaming,
  n_pre = n_total_years,  # All years are effectively post for state-level
  n_obs = nrow(state_panel),
  n_casino_counties = n_casino_counties,
  n_tribal_counties = n_tribal_counties,
  n_county_obs = nrow(county_panel)
)
jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

# Save models for table generation
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5, m6 = m6),
        file.path(data_dir, "main_models.rds"))

cat("\nMain analysis complete. Models saved.\n")
