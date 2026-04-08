## 02_clean_data.R — Build analysis dataset for MOT RDD
## apep_1414: UK MOT First-Inspection RDD

source("code/00_packages.R")
setwd(here::here("output", "apep_1414", "v1"))

## ──────────────────────────────────────────────────────────────
## 1. Load data
## ──────────────────────────────────────────────────────────────

cohort_2022 <- readRDS("data/cohort_2022_bandwidth.rds")
cat(sprintf("Loaded cohort: %d records\n", nrow(cohort_2022)))

outcomes_2023 <- tryCatch(
  readRDS("data/outcomes_2023.rds"),
  error = function(e) {
    cat("Note: 2023 outcomes not available. Using first-test outcomes.\n")
    data.frame()
  }
)
cat(sprintf("Loaded 2023 outcomes: %d records\n", nrow(outcomes_2023)))

## ──────────────────────────────────────────────────────────────
## 2. Build centered running variable
## ──────────────────────────────────────────────────────────────

cohort_2022 <- cohort_2022 %>%
  mutate(
    # Running variable centered at 36 months
    rv = age_months_at_test - 36,
    # Treatment: at or after 36 months (mandatory inspection)
    treated = as.integer(age_months_at_test >= 36),
    # Outcome: failure at first test
    failed_first_test = case_when(
      test_result %in% c("F", "FAIL", "fail", "Fail", "0") ~ 1L,
      test_result %in% c("P", "PASS", "pass", "Pass", "1") ~ 0L,
      TRUE ~ NA_integer_
    ),
    # Vehicle age at first registration (calendar year)
    reg_year = year(first_use_date),
    # Age category for vehicle classification
    vehicle_age_at_test_years = age_months_at_test / 12
  ) %>%
  filter(!is.na(failed_first_test))

cat(sprintf("After cleaning: %d records with valid outcomes\n", nrow(cohort_2022)))
cat("Running variable distribution (rv = age - 36):\n")
print(table(cohort_2022$rv))

## ──────────────────────────────────────────────────────────────
## 3. Merge second-test outcomes if available
## ──────────────────────────────────────────────────────────────

if (nrow(outcomes_2023) > 0) {
  # Take the first 2023 test for each vehicle (earliest date)
  outcomes_2023_clean <- outcomes_2023 %>%
    filter(!is.na(failed_second_test)) %>%
    group_by(vehicle_id) %>%
    arrange(test_date_2) %>%
    slice(1) %>%
    ungroup() %>%
    select(vehicle_id, test_date_2, failed_second_test, test_mileage_2)

  cat(sprintf("Clean 2023 outcomes: %d unique vehicles\n", nrow(outcomes_2023_clean)))

  df <- cohort_2022 %>%
    left_join(outcomes_2023_clean, by = "vehicle_id")

  df$has_second_test <- !is.na(df$failed_second_test)
  cat(sprintf("Vehicles with second test: %d (%.1f%%)\n",
              sum(df$has_second_test), 100 * mean(df$has_second_test)))
} else {
  df <- cohort_2022
  df$failed_second_test <- NA_integer_
  df$has_second_test <- FALSE
  cat("No second-test outcomes available. Main analysis will use first-test failure rate.\n")
}

## ──────────────────────────────────────────────────────────────
## 4. Fuel type and make cleaning
## ──────────────────────────────────────────────────────────────

if ("fuel_type" %in% names(df)) {
  df <- df %>%
    mutate(
      fuel_clean = case_when(
        fuel_type %in% c("PE", "P", "Petrol", "petrol", "PETROL") ~ "Petrol",
        fuel_type %in% c("DI", "D", "Diesel", "diesel", "DIESEL") ~ "Diesel",
        fuel_type %in% c("EL", "E", "Electric", "electric", "ELECTRIC") ~ "Electric",
        fuel_type %in% c("HY", "H", "Hybrid", "hybrid", "HYBRID") ~ "Hybrid",
        TRUE ~ "Other"
      )
    )
}

if ("postcode_region" %in% names(df)) {
  df <- df %>%
    mutate(
      region_clean = case_when(
        postcode_region %in% c("E", "EC", "N", "NW", "SE", "SW", "W", "WC") ~ "London",
        postcode_region %in% c("M", "L", "B") ~ "Major Cities",
        postcode_region %in% c("S", "LS", "YO", "HU", "BD") ~ "Yorkshire/N.England",
        postcode_region %in% c("BS", "GL", "OX", "SN", "SP", "BA") ~ "South West",
        TRUE ~ "Other England"
      )
    )
}

## ──────────────────────────────────────────────────────────────
## 5. Final dataset
## ──────────────────────────────────────────────────────────────

# Primary outcome: fail at SECOND test (if available), else first test failure rate
df <- df %>%
  mutate(
    # Primary analysis outcome
    primary_outcome = if (any(df$has_second_test)) failed_second_test else failed_first_test,
    # Keep both
    y_first = failed_first_test,
    y_second = failed_second_test
  )

cat("\n=== FINAL DATASET SUMMARY ===\n")
cat(sprintf("Total observations: %d\n", nrow(df)))
cat(sprintf("Running variable range: [%d, %d] months\n", min(df$rv), max(df$rv)))
cat(sprintf("Treated (rv >= 0): %d (%.1f%%)\n",
            sum(df$treated), 100 * mean(df$treated)))
cat(sprintf("Failure rate at first test: %.3f\n", mean(df$y_first, na.rm = TRUE)))
if (any(df$has_second_test)) {
  cat(sprintf("Failure rate at second test: %.3f\n", mean(df$y_second, na.rm = TRUE)))
}

## ──────────────────────────────────────────────────────────────
## 6. Summary by rv bins for visual inspection
## ──────────────────────────────────────────────────────────────

bin_summary <- df %>%
  group_by(rv) %>%
  summarise(
    n = n(),
    failure_rate_first = mean(y_first, na.rm = TRUE),
    failure_rate_second = if ("y_second" %in% names(.)) mean(y_second, na.rm = TRUE) else NA_real_,
    .groups = "drop"
  )

cat("\nBin summary (failure rates by age-at-test):\n")
print(bin_summary, n = 30)

saveRDS(df, "data/analysis_dataset.rds")
saveRDS(bin_summary, "data/bin_summary.rds")

cat("\n02_clean_data.R complete.\n")
