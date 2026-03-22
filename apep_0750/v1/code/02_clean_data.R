# 02_clean_data.R — Clean and merge bankruptcy + transposition data
# APEP-0750: Rescue or Ruin?

source("00_packages.R")

cat("=== Loading raw data ===\n")
bkrt <- read_csv("../data/bankruptcy_index.csv", show_col_types = FALSE)
transposition <- read_csv("../data/transposition_dates.csv", show_col_types = FALSE)

# --- Filter to EU member states only ---
eu27 <- c("AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR",
          "DE", "EL", "ES", "HU", "IE", "IT", "LV", "LT", "LU", "MT",
          "NL", "PL", "PT", "RO", "SK", "SI", "SE")

bkrt_eu <- bkrt %>%
  filter(country %in% eu27)

cat(sprintf("EU-27 bankruptcy data: %d rows, %d countries\n",
            nrow(bkrt_eu), n_distinct(bkrt_eu$country)))

# Check which countries have data
countries_with_data <- unique(bkrt_eu$country)
cat(sprintf("Countries with data: %s\n", paste(sort(countries_with_data), collapse = ", ")))
cat(sprintf("Countries missing: %s\n",
            paste(setdiff(eu27, countries_with_data), collapse = ", ")))

# --- Create numeric time variable ---
# Quarter as integer: 2015Q1 = 1, 2015Q2 = 2, etc.
bkrt_eu <- bkrt_eu %>%
  mutate(time_q = (year - 2015) * 4 + quarter)

# --- Merge with transposition dates ---
panel <- bkrt_eu %>%
  left_join(
    transposition %>% select(country, transpose_date, transpose_year, transpose_quarter, treat_yq),
    by = "country"
  ) %>%
  mutate(
    # Treatment indicator: 1 if quarter >= transposition quarter
    treat_time_q = ifelse(!is.na(transpose_year),
                          (transpose_year - 2015) * 4 + transpose_quarter,
                          NA_real_),
    # Post-treatment indicator
    post = ifelse(!is.na(treat_time_q) & time_q >= treat_time_q, 1L, 0L),
    # For CS-DiD: first_treat = treatment period, 0 if never treated
    first_treat = ifelse(!is.na(treat_time_q), treat_time_q, 0L),
    # Event time (relative to treatment)
    event_time = ifelse(!is.na(treat_time_q), time_q - treat_time_q, NA_integer_),
    # Treatment cohort (for grouping)
    cohort = ifelse(!is.na(treat_yq), treat_yq, "Never"),
    # Log outcome
    log_bkrt = log(bkrt_index + 1),
    # Asinh transformation (handles zeros)
    asinh_bkrt = asinh(bkrt_index)
  )

# --- Merge COVID stringency ---
covid <- tryCatch(
  read_csv("../data/covid_stringency.csv", show_col_types = FALSE),
  error = function(e) NULL
)

if (!is.null(covid)) {
  panel <- panel %>%
    left_join(covid, by = c("country", "year", "quarter")) %>%
    mutate(stringency_mean = replace_na(stringency_mean, 0))
  cat("  COVID stringency merged.\n")
}

# --- Summary statistics ---
cat("\n=== Panel Summary ===\n")
cat(sprintf("Total observations: %d\n", nrow(panel)))
cat(sprintf("Countries: %d\n", n_distinct(panel$country)))
cat(sprintf("Sectors: %s\n", paste(unique(panel$sector), collapse = ", ")))
cat(sprintf("Time periods: %d quarters (%s to %s)\n",
            n_distinct(panel$time_q), min(panel$yq), max(panel$yq)))

# Treatment summary
treat_summary <- panel %>%
  filter(!is.na(treat_time_q)) %>%
  distinct(country, treat_yq) %>%
  count(treat_yq, name = "n_countries") %>%
  arrange(treat_yq)
cat("\nTransposition cohorts:\n")
print(treat_summary, n = 20)

# Never-treated countries
never_treated <- setdiff(countries_with_data,
                         transposition$country)
cat(sprintf("\nNever-treated countries in data: %s\n",
            ifelse(length(never_treated) == 0, "None", paste(never_treated, collapse = ", "))))

# Countries with treatment but no bankruptcy data
treated_no_data <- setdiff(transposition$country, countries_with_data)
cat(sprintf("Treated countries missing bankruptcy data: %s\n",
            ifelse(length(treated_no_data) == 0, "None", paste(treated_no_data, collapse = ", "))))

# --- Check pre-trend plausibility ---
cat("\n=== Pre-trend check (total sector, pre-2021) ===\n")
pre_means <- panel %>%
  filter(sector == "B-S_X_O_S94", year < 2021) %>%
  group_by(country) %>%
  summarise(
    mean_bkrt = mean(bkrt_index, na.rm = TRUE),
    sd_bkrt = sd(bkrt_index, na.rm = TRUE),
    n_obs = n(),
    .groups = "drop"
  )
cat(sprintf("Pre-treatment summary: mean = %.1f, sd = %.1f across %d countries\n",
            mean(pre_means$mean_bkrt, na.rm = TRUE),
            mean(pre_means$sd_bkrt, na.rm = TRUE),
            nrow(pre_means)))

# --- Save cleaned panel ---
write_csv(panel, "../data/panel_clean.csv")
cat(sprintf("\nSaved: data/panel_clean.csv (%s rows)\n", format(nrow(panel), big.mark = ",")))

# --- Create country-level aggregate panel (for simpler analysis) ---
panel_country <- panel %>%
  filter(sector == "B-S_X_O_S94") %>%
  select(country, year, quarter, time_q, yq, bkrt_index, log_bkrt, asinh_bkrt,
         first_treat, post, event_time, cohort, stringency_mean)

write_csv(panel_country, "../data/panel_country.csv")
cat(sprintf("Saved: data/panel_country.csv (%s rows)\n", format(nrow(panel_country), big.mark = ",")))
