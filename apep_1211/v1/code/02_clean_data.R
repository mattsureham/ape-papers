# ==============================================================================
# 02_clean_data.R — Variable construction and panel assembly
# apep_1211: Medicaid Reimbursement and Black-White Nursing Home Earnings Gap
# ==============================================================================

source("00_packages.R")

qwi <- readRDS("../data/qwi_raw.rds")
rate_events <- readRDS("../data/rate_events.rds")
state_xwalk <- readRDS("../data/state_xwalk.rds")

# --- 1. Create time index ---------------------------------------------------
qwi <- qwi |>
  mutate(
    state_fips = as.integer(state_fips),
    year = as.integer(year),
    quarter = as.integer(quarter),
    # Calendar quarter index (2001Q1 = 1)
    time_q = (year - 2001L) * 4L + quarter,
    # Year-quarter as numeric for regressions
    yq = year + (quarter - 1) / 4,
    # Race labels
    race_label = case_when(
      race == "A1" ~ "White",
      race == "A2" ~ "Black",
      TRUE ~ race
    ),
    black = as.integer(race == "A2"),
    # Industry labels
    industry = as.character(industry),
    ind_label = case_when(
      industry == "623" ~ "Nursing/Residential Care",
      industry == "621" ~ "Ambulatory Care",
      industry == "721" ~ "Accommodation",
      TRUE ~ as.character(industry)
    ),
    nursing_home = as.integer(industry == "623")
  )

# --- 2. Merge treatment events (staggered DiD) ------------------------------
# first_treat = the year-quarter of the rate increase event
# For annual treatment events, assign to Q1 of the treatment year
treat_timing <- rate_events |>
  select(state_fips, treat_year) |>
  mutate(
    first_treat_q = (treat_year - 2001L) * 4L + 1L,  # Q1 of treatment year
    first_treat_yq = treat_year
  )

qwi <- qwi |>
  left_join(treat_timing, by = "state_fips") |>
  mutate(
    # Never-treated states: treat_year = 0 (convention for `did` package)
    treat_year = replace_na(treat_year, 0L),
    first_treat_q = replace_na(first_treat_q, 0L),
    first_treat_yq = replace_na(first_treat_yq, 0L),
    # Post-treatment indicator
    post = as.integer(treat_year > 0L & year >= treat_year),
    # Event time (years relative to treatment)
    event_time = ifelse(treat_year > 0L, year - treat_year, NA_integer_)
  )

# --- 3. Restrict sample to analysis window ----------------------------------
# Use 2010-2024 for the main analysis (5+ pre-period years for earliest treatment)
df <- qwi |>
  filter(year >= 2010, year <= 2024) |>
  filter(!is.na(EarnS), EarnS > 0, Emp > 0)

cat(sprintf("Analysis sample: %d obs\n", nrow(df)))
cat(sprintf("  States: %d (treated: %d, never-treated: %d)\n",
            n_distinct(df$state_fips),
            n_distinct(df$state_fips[df$treat_year > 0]),
            n_distinct(df$state_fips[df$treat_year == 0])))
cat(sprintf("  Years: %d-%d\n", min(df$year), max(df$year)))
cat(sprintf("  Industries: %s\n", paste(unique(df$ind_label), collapse = ", ")))

# --- 4. Create key analysis variables ----------------------------------------
# Log earnings
df <- df |>
  mutate(
    log_earn = log(EarnS),
    log_emp = log(Emp)
  )

# State-industry-race panel identifier
df <- df |>
  mutate(
    panel_id = paste(state_fips, industry, race, sep = "_"),
    state_ind = paste(state_fips, industry, sep = "_"),
    state_race = paste(state_fips, race, sep = "_")
  )

# --- 5. Summary statistics ---------------------------------------------------
cat("\n--- Summary: Mean Quarterly Earnings by Race × Industry ---\n")
df |>
  group_by(race_label, ind_label) |>
  summarise(
    mean_earn = weighted.mean(EarnS, Emp, na.rm = TRUE),
    mean_emp = mean(Emp, na.rm = TRUE),
    n_obs = n(),
    .groups = "drop"
  ) |>
  arrange(ind_label, race_label) |>
  print(n = 10)

# Black/White ratio by industry
cat("\n--- Black/White Earnings Ratio by Industry ---\n")
df |>
  group_by(ind_label, race_label) |>
  summarise(mean_earn = weighted.mean(EarnS, Emp, na.rm = TRUE), .groups = "drop") |>
  pivot_wider(names_from = race_label, values_from = mean_earn) |>
  mutate(BW_ratio = Black / White) |>
  print()

# Treated vs control summary
cat("\n--- Treatment Status Summary ---\n")
df |>
  filter(industry == "623") |>
  mutate(treated = treat_year > 0L) |>
  group_by(treated) |>
  summarise(
    n_states = n_distinct(state_fips),
    mean_black_earn = weighted.mean(EarnS[race == "A2"], Emp[race == "A2"], na.rm = TRUE),
    mean_white_earn = weighted.mean(EarnS[race == "A1"], Emp[race == "A1"], na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(bw_ratio = mean_black_earn / mean_white_earn) |>
  print()

# --- 6. Save analysis dataset -----------------------------------------------
saveRDS(df, "../data/analysis_panel.rds")

cat(sprintf("\nAnalysis panel saved: %d obs, %d state-quarter-race-industry cells\n",
            nrow(df), n_distinct(df$panel_id)))
