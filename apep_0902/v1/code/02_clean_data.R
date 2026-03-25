# ============================================================================
# 02_clean_data.R — Clean and construct analysis dataset
# ============================================================================

source("00_packages.R")

qwi_sa <- readRDS("../data/qwi_sa_raw.rds")
qwi_rh <- readRDS("../data/qwi_rh_raw.rds")

# --- Treatment dates (year-quarter of RTF strengthening) ---
# ND: Measure 3, passed Nov 2012 general election → effective 2012Q4
# NC: HB 614 signed Jul 2013 → effective 2013Q3
# MO: Amendment 1, passed Aug 2014 primary → effective 2014Q3
# IA: HF 2340 signed Mar 2018 → effective 2018Q2 (conservative: Q2)
# GA: HB 545 signed May 2019 → effective 2019Q2
# TX: SB 474 signed Jun 2021 → effective 2021Q2

treatment_dates <- data.frame(
  state_fips = c("38", "37", "29", "19", "13", "48"),
  state_abbr = c("ND", "NC", "MO", "IA", "GA", "TX"),
  treat_year = c(2012, 2013, 2014, 2018, 2019, 2021),
  treat_quarter = c(4, 3, 3, 2, 2, 2),
  stringsAsFactors = FALSE
)
treatment_dates$treat_yq <- treatment_dates$treat_year + (treatment_dates$treat_quarter - 1) / 4

# --- State names ---
state_names <- c(
  "13" = "GA", "19" = "IA", "20" = "KS", "21" = "KY",
  "29" = "MO", "30" = "MT", "31" = "NE", "37" = "NC",
  "38" = "ND", "46" = "SD", "47" = "TN", "48" = "TX",
  "51" = "VA", "55" = "WI"
)

# --- Clean QWI SA data ---
cat("Cleaning QWI SA data...\n")

# Inspect columns
cat("QWI SA columns:", paste(names(qwi_sa), collapse = ", "), "\n")

# Extract state FIPS from geography (first 2 digits)
qwi_sa <- qwi_sa %>%
  mutate(
    state_fips = substr(geography, 1, 2),
    county_fips = geography,
    state_abbr = state_names[state_fips],
    year = as.integer(year),
    quarter = as.integer(quarter),
    yq = year + (quarter - 1) / 4
  ) %>%
  filter(year >= 2005, year <= 2024)  # Restrict to 2005-2024

# Merge treatment info
qwi_sa <- qwi_sa %>%
  left_join(treatment_dates %>% select(state_fips, treat_yq), by = "state_fips") %>%
  mutate(
    treated_state = !is.na(treat_yq),
    post = ifelse(treated_state, yq >= treat_yq, FALSE),
    treat_indicator = as.integer(treated_state & post)
  )

# --- Construct main analysis panel (NAICS 112 — Animal Production) ---
panel_112 <- qwi_sa %>%
  filter(industry == "112") %>%
  mutate(
    Emp = as.numeric(Emp),
    HirN = as.numeric(HirN),
    Sep = as.numeric(Sep),
    FrmJbGn = as.numeric(FrmJbGn),
    FrmJbLs = as.numeric(FrmJbLs),
    EarnS = as.numeric(EarnS)
  ) %>%
  filter(!is.na(Emp) & Emp > 0)  # Drop county-quarters with suppressed/zero employment

# Create log employment
panel_112 <- panel_112 %>%
  mutate(
    log_emp = log(Emp),
    log_earn = ifelse(EarnS > 0, log(EarnS), NA_real_)
  )

# --- Balance the panel for CS estimator ---
# Keep counties present in at least 75% of quarters
n_quarters <- n_distinct(panel_112$yq)
county_coverage <- panel_112 %>%
  group_by(county_fips) %>%
  summarize(n_obs = n(), .groups = "drop") %>%
  filter(n_obs >= 0.75 * n_quarters)

cat(sprintf("Panel balancing: %d counties have >=75%% coverage (out of %d)\n",
  nrow(county_coverage), n_distinct(panel_112$county_fips)))

panel_112 <- panel_112 %>%
  semi_join(county_coverage, by = "county_fips")

# --- Construct placebo panel (NAICS 111 — Crop Production) ---
panel_111 <- qwi_sa %>%
  filter(industry == "111") %>%
  mutate(
    Emp = as.numeric(Emp),
    HirN = as.numeric(HirN),
    Sep = as.numeric(Sep),
    FrmJbGn = as.numeric(FrmJbGn),
    FrmJbLs = as.numeric(FrmJbLs),
    EarnS = as.numeric(EarnS)
  ) %>%
  filter(!is.na(Emp) & Emp > 0) %>%
  mutate(
    log_emp = log(Emp),
    log_earn = ifelse(EarnS > 0, log(EarnS), NA_real_)
  )

# Balance placebo panel same way
county_cov_111 <- panel_111 %>%
  group_by(county_fips) %>%
  summarize(n_obs = n(), .groups = "drop") %>%
  filter(n_obs >= 0.75 * n_distinct(panel_111$yq))

panel_111 <- panel_111 %>%
  semi_join(county_cov_111, by = "county_fips")

# --- Create cohort variable for CS estimator ---
# Cohort = first treated quarter. Never-treated = 0
panel_112 <- panel_112 %>%
  mutate(
    cohort_yq = ifelse(treated_state, treat_yq, 0)
  )

panel_111 <- panel_111 %>%
  mutate(
    cohort_yq = ifelse(treated_state, treat_yq, 0)
  )

# --- Time period: numeric index for CS estimator ---
# CS needs integer time periods
all_yqs <- sort(unique(panel_112$yq))
yq_to_int <- setNames(seq_along(all_yqs), as.character(all_yqs))
panel_112$time_id <- yq_to_int[as.character(panel_112$yq)]
panel_111$time_id <- yq_to_int[as.character(panel_111$yq)]

# Map cohort_yq to time_id
panel_112$cohort_id <- ifelse(
  panel_112$cohort_yq == 0, 0,
  yq_to_int[as.character(panel_112$cohort_yq)]
)
panel_111$cohort_id <- ifelse(
  panel_111$cohort_yq == 0, 0,
  yq_to_int[as.character(panel_111$cohort_yq)]
)

# Create numeric county ID
county_ids <- data.frame(
  county_fips = sort(unique(c(panel_112$county_fips, panel_111$county_fips))),
  stringsAsFactors = FALSE
)
county_ids$county_id <- seq_len(nrow(county_ids))

panel_112 <- panel_112 %>% left_join(county_ids, by = "county_fips")
panel_111 <- panel_111 %>% left_join(county_ids, by = "county_fips")

# --- Clean RH data for heterogeneity ---
cat("Cleaning QWI RH data...\n")
cat("QWI RH columns:", paste(names(qwi_rh), collapse = ", "), "\n")

qwi_rh <- qwi_rh %>%
  mutate(
    state_fips = substr(geography, 1, 2),
    county_fips = geography,
    state_abbr = state_names[state_fips],
    year = as.integer(year),
    quarter = as.integer(quarter),
    yq = year + (quarter - 1) / 4,
    Emp = as.numeric(Emp)
  ) %>%
  filter(year >= 2005, year <= 2024) %>%
  left_join(treatment_dates %>% select(state_fips, treat_yq), by = "state_fips") %>%
  mutate(
    treated_state = !is.na(treat_yq),
    post = ifelse(treated_state, yq >= treat_yq, FALSE),
    treat_indicator = as.integer(treated_state & post),
    cohort_yq = ifelse(treated_state, treat_yq, 0)
  )

# Time period mapping
qwi_rh$time_id <- yq_to_int[as.character(qwi_rh$yq)]
qwi_rh$cohort_id <- ifelse(
  qwi_rh$cohort_yq == 0, 0,
  yq_to_int[as.character(qwi_rh$cohort_yq)]
)
qwi_rh <- qwi_rh %>% left_join(county_ids, by = "county_fips")

# --- Summary statistics ---
cat("\n=== NAICS 112 Panel Summary ===\n")
cat(sprintf("Counties: %d\n", n_distinct(panel_112$county_fips)))
cat(sprintf("States: %d (%d treated, %d control)\n",
  n_distinct(panel_112$state_fips),
  n_distinct(panel_112$state_fips[panel_112$treated_state]),
  n_distinct(panel_112$state_fips[!panel_112$treated_state])
))
cat(sprintf("Time periods: %d quarters (%s to %s)\n",
  n_distinct(panel_112$yq),
  min(panel_112$yq), max(panel_112$yq)
))
cat(sprintf("Observations: %d\n", nrow(panel_112)))
cat(sprintf("Mean employment: %.1f\n", mean(panel_112$Emp, na.rm = TRUE)))
cat(sprintf("SD employment: %.1f\n", sd(panel_112$Emp, na.rm = TRUE)))
cat(sprintf("Mean log employment: %.3f\n", mean(panel_112$log_emp, na.rm = TRUE)))
cat(sprintf("SD log employment: %.3f\n", sd(panel_112$log_emp, na.rm = TRUE)))

# Save time period mapping for reference
saveRDS(data.frame(yq = all_yqs, time_id = seq_along(all_yqs)), "../data/time_mapping.rds")

# --- Save cleaned panels ---
saveRDS(panel_112, "../data/panel_112.rds")
saveRDS(panel_111, "../data/panel_111.rds")
saveRDS(qwi_rh, "../data/qwi_rh_clean.rds")
saveRDS(treatment_dates, "../data/treatment_dates.rds")
saveRDS(county_ids, "../data/county_ids.rds")

cat("\nCleaned data saved to data/\n")
