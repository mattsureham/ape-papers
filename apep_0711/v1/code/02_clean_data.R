## 02_clean_data.R — Clean CDC data and construct treatment indicators
## apep_0711: Online sports betting and suicide mortality

source("00_packages.R")

cat("=== Cleaning CDC Suicide Data ===\n")

## --- 1. Load raw data ---
cdc <- read_csv("../data/cdc_suicide_raw.csv", show_col_types = FALSE)
cat("Raw rows:", nrow(cdc), "\n")
cat("Column names:", paste(names(cdc), collapse = ", "), "\n")

## Inspect structure
cat("\nFirst few rows:\n")
print(head(cdc, 3))
cat("\nUnique outcomes:", paste(unique(cdc$outcome), collapse = ", "), "\n")

## --- 2. Clean and standardize ---
## The CDC dataset has columns like: state, year, week, outcome,
## median_estimate (or similar), lower_bound, upper_bound

## Standardize column names (CDC Socrata API returns snake_case)
cdc <- cdc %>%
  rename_with(tolower) %>%
  rename_with(~ gsub("\\.", "_", .x))

## Print actual columns for debugging
cat("Cleaned columns:", paste(names(cdc), collapse = ", "), "\n")

## Identify the median estimate column
median_col <- names(cdc)[grepl("median|mean|estimate", names(cdc), ignore.case = TRUE)]
cat("Median/estimate columns found:", paste(median_col, collapse = ", "), "\n")

## Identify state column
state_col <- names(cdc)[grepl("^state$|^jurisdiction|^geography", names(cdc), ignore.case = TRUE)]
cat("State columns found:", paste(state_col, collapse = ", "), "\n")

## Identify week/time columns
time_cols <- names(cdc)[grepl("week|year|date|time|period", names(cdc), ignore.case = TRUE)]
cat("Time columns found:", paste(time_cols, collapse = ", "), "\n")

## Construct clean panel
## We need: state, year, week, suicide_median
## Use mmwryear and mmwrweek directly (CDC MMWR epidemiological calendar)
cdc_clean <- cdc %>%
  mutate(
    state_name = .data[[state_col[1]]],
    state_abbr_raw = stateabb,
    year = as.integer(mmwryear),
    week = as.integer(mmwrweek)
  )

## Get the median estimate
if (length(median_col) > 0) {
  cdc_clean <- cdc_clean %>%
    mutate(suicide_median = as.numeric(.data[[median_col[1]]]))
} else {
  stop("FATAL: Cannot identify median estimate column in CDC data")
}

## Get bounds if available
lb_col <- names(cdc)[grepl("lower|lb|low", names(cdc), ignore.case = TRUE)]
ub_col <- names(cdc)[grepl("upper|ub|high", names(cdc), ignore.case = TRUE)]
if (length(lb_col) > 0) {
  cdc_clean$suicide_lb <- as.numeric(cdc_clean[[lb_col[1]]])
}
if (length(ub_col) > 0) {
  cdc_clean$suicide_ub <- as.numeric(cdc_clean[[ub_col[1]]])
}

## --- 3. State abbreviation ---
## CDC data already provides stateabb — use directly
cdc_clean <- cdc_clean %>%
  mutate(state_abbr = state_abbr_raw)

## Remove non-state rows (US total, NYC)
non_states <- c("US", "NYC", "YC", "")
cdc_clean <- cdc_clean %>%
  filter(!is.na(state_abbr), !(state_abbr %in% non_states),
         state_abbr %in% c(state.abb, "DC"))

cat("States after filtering:", n_distinct(cdc_clean$state_abbr), "\n")
cat("State list:", paste(sort(unique(cdc_clean$state_abbr)), collapse = ", "), "\n")

## --- 4. Online sports betting legalization dates ---
## Source: American Gaming Association, verified against state gaming commission records
## Date = first day mobile/online wagering was operational
betting_dates <- tribble(
  ~state_abbr, ~legal_date,         ~legal_year_week,
  "NJ",        "2018-06-14",        NA,
  "WV",        "2019-08-27",        NA,
  "PA",        "2019-07-15",        NA,
  "IN",        "2019-10-03",        NA,
  "NH",        "2020-01-01",        NA,
  "CO",        "2020-05-01",        NA,
  "IL",        "2020-06-18",        NA,
  "IA",        "2020-08-15",        NA,
  "TN",        "2020-11-01",        NA,
  "MI",        "2021-01-22",        NA,
  "VA",        "2021-01-21",        NA,
  "AZ",        "2021-09-09",        NA,
  "WY",        "2021-09-01",        NA,
  "LA",        "2022-01-28",        NA
) %>%
  mutate(
    legal_date = as.Date(legal_date),
    legal_year = year(legal_date),
    legal_week = isoweek(legal_date)
  )

cat("Betting legalization dates:\n")
print(betting_dates %>% select(state_abbr, legal_date, legal_year, legal_week))

## --- 5. Merge treatment status ---
cdc_panel <- cdc_clean %>%
  filter(!is.na(suicide_median), !is.na(year), !is.na(week)) %>%
  left_join(betting_dates %>% select(state_abbr, legal_date, legal_year, legal_week),
            by = "state_abbr") %>%
  mutate(
    ## Create a numeric time index (year * 100 + week) for easy comparison
    time_idx = year * 100 + week,
    legal_time_idx = legal_year * 100 + legal_week,
    ## Treatment indicator
    treated_post = ifelse(!is.na(legal_date) & time_idx >= legal_time_idx, 1, 0),
    ## Ever-treated indicator
    ever_treated = ifelse(!is.na(legal_date), 1, 0),
    ## Group variable for CS-DiD (0 = never treated)
    g = ifelse(is.na(legal_time_idx), 0, legal_time_idx),
    ## State numeric ID
    state_id = as.integer(factor(state_abbr))
  )

cat("\nPanel summary:\n")
cat("States:", n_distinct(cdc_panel$state_abbr), "\n")
cat("Treated states:", n_distinct(cdc_panel$state_abbr[cdc_panel$ever_treated == 1]), "\n")
cat("Control states:", n_distinct(cdc_panel$state_abbr[cdc_panel$ever_treated == 0]), "\n")
cat("Year range:", range(cdc_panel$year, na.rm = TRUE), "\n")
cat("Total observations:", nrow(cdc_panel), "\n")
cat("Non-missing suicide median:", sum(!is.na(cdc_panel$suicide_median)), "\n")

## --- 6. Create NFL season indicator ---
## NFL regular season runs roughly Week 36 (early Sep) through Week 7 (mid Feb)
cdc_panel <- cdc_panel %>%
  mutate(
    nfl_season = ifelse(week >= 36 | week <= 7, 1, 0)
  )

## --- 7. Save clean panel ---
write_csv(cdc_panel, "../data/suicide_panel.csv")
saveRDS(cdc_panel, "../data/suicide_panel.rds")
cat("\nSaved suicide_panel:", nrow(cdc_panel), "rows\n")

## Summary statistics
cat("\n=== Summary Statistics ===\n")
cdc_panel %>%
  group_by(ever_treated) %>%
  summarise(
    n_states = n_distinct(state_abbr),
    n_obs = n(),
    mean_suicide = mean(suicide_median, na.rm = TRUE),
    sd_suicide = sd(suicide_median, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()
