# 02_clean_data.R — Clean and construct analysis variables
# apep_0644: Pay Transparency Mandates and Employer Adjustment

source("00_packages.R")

cat("=== Cleaning and constructing analysis dataset ===\n")

# ---- 1. Load raw data ----
qwi_raw <- readRDS("../data/qwi_raw.rds")

cat("Raw rows: ", nrow(qwi_raw), "\n")

# ---- 2. Extract state FIPS from county FIPS ----
# QWI geography is 5-digit county FIPS (character)
qwi_raw <- qwi_raw %>%
  mutate(
    county_fips = as.character(geography),
    county_fips = str_pad(county_fips, 5, pad = "0"),
    state_fips = substr(county_fips, 1, 2)
  )

# ---- 3. Define treatment cohorts ----
# Pay transparency mandate effective dates
treat_map <- tribble(
  ~state_fips, ~state_name,        ~treat_date,
  "08",        "Colorado",         "2021-01-01",  # 2021Q1
  "06",        "California",       "2023-01-01",  # 2023Q1
  "53",        "Washington",       "2023-01-01",  # 2023Q1
  "36",        "New York",         "2023-10-01"   # 2023Q4 (law effective Sep 17; first full treated quarter is Q4)
) %>%
  mutate(treat_date = as.Date(treat_date))

# Map treatment quarter
treat_map <- treat_map %>%
  mutate(
    treat_year = year(treat_date),
    treat_quarter = quarter(treat_date),
    # G = first treated period as year-quarter integer (YYYYQ format)
    first_treat_yq = treat_year * 10 + treat_quarter
  )

# ---- 4. Create time variable (year-quarter as integer for CS estimator) ----
qwi_raw <- qwi_raw %>%
  mutate(
    yq = year * 10 + quarter,
    time_index = (year - 2015) * 4 + quarter  # sequential time index
  )

# ---- 5. Merge treatment assignment ----
df <- qwi_raw %>%
  left_join(treat_map %>% select(state_fips, state_name, first_treat_yq),
            by = "state_fips") %>%
  mutate(
    # Never-treated get first_treat = 0 (for Callaway-Sant'Anna)
    first_treat_yq = replace_na(first_treat_yq, 0),
    treated_state = first_treat_yq > 0
  )

cat("States with mandates: ", n_distinct(df$state_fips[df$treated_state]), "\n")
cat("Counties in treated states: ", n_distinct(df$county_fips[df$treated_state]), "\n")
cat("Counties in control states: ", n_distinct(df$county_fips[!df$treated_state]), "\n")

# ---- 6. Construct outcome variables ----
# Rates normalized by beginning-of-quarter employment
df <- df %>%
  mutate(
    # Hiring rates
    new_hire_rate = ifelse(Emp > 0, HirN / Emp, NA_real_),
    total_hire_rate = ifelse(Emp > 0, HirA / Emp, NA_real_),
    recall_rate = ifelse(Emp > 0 & !is.na(HirA) & !is.na(HirN),
                         (HirA - HirN) / Emp, NA_real_),
    # Separation rate
    sep_rate = ifelse(Emp > 0, Sep / Emp, NA_real_),
    # Job creation/destruction rates
    job_creation_rate = ifelse(Emp > 0, FrmJbGn / Emp, NA_real_),
    job_destruction_rate = ifelse(Emp > 0, FrmJbLs / Emp, NA_real_),
    net_job_creation_rate = ifelse(Emp > 0, FrmJbC / Emp, NA_real_),
    # Turnover rate
    turnover_rate = ifelse(Emp > 0, TurnOvrS / Emp, NA_real_),
    # Log earnings
    log_earn_stable = ifelse(EarnS > 0, log(EarnS), NA_real_),
    log_earn_new_hire = ifelse(EarnHirNS > 0, log(EarnHirNS), NA_real_)
  )

# ---- 7. Define industry wage-dispersion classification ----
# High-dispersion: Finance (52), Professional Services (54), Information (51), Management (55)
# Low-dispersion: Retail (44-45), Accommodation/Food (72), Admin/Support (56)
# These are based on BLS OES wage distribution data
df <- df %>%
  mutate(
    high_dispersion = industry %in% c("51", "52", "54", "55"),
    low_dispersion = industry %in% c("44-45", "72", "56"),
    dispersion_group = case_when(
      high_dispersion ~ "High wage dispersion",
      low_dispersion ~ "Low wage dispersion",
      TRUE ~ "Other"
    )
  )

# ---- 8. Define border counties for spatial analysis ----
# Colorado border counties (approximate via state adjacency)
# Colorado FIPS = 08, bordering: Utah (49), Kansas (20), Nebraska (31), Wyoming (56),
# New Mexico (35), Oklahoma (40), Arizona (04)
border_states <- c("49", "20", "31", "56", "35", "40", "04")

df <- df %>%
  mutate(
    co_border_sample = state_fips == "08" | state_fips %in% border_states
  )

# ---- 9. Drop missing observations and extreme outliers ----
df <- df %>%
  filter(
    !is.na(Emp),
    Emp > 0,
    !is.na(new_hire_rate),
    new_hire_rate < 5,        # Drop implausible hire rates > 500%
    job_creation_rate < 5     # Drop implausible rates
  )

cat("\n=== Final dataset ===\n")
cat("Observations: ", nrow(df), "\n")
cat("Counties: ", n_distinct(df$county_fips), "\n")
cat("States: ", n_distinct(df$state_fips), "\n")
cat("Industries: ", n_distinct(df$industry), "\n")
cat("Time periods: ", n_distinct(df$yq), "\n")
cat("Treated counties: ", n_distinct(df$county_fips[df$treated_state]), "\n")
cat("Control counties: ", n_distinct(df$county_fips[!df$treated_state]), "\n")
cat("\nTreatment cohort sizes:\n")
df %>%
  filter(treated_state) %>%
  distinct(county_fips, first_treat_yq, state_name) %>%
  count(first_treat_yq, state_name) %>%
  print()

# ---- 10. Save analysis dataset ----
saveRDS(df, "../data/analysis_data.rds")

# Also save sex-disaggregated data with same treatment assignment
qwi_sex <- readRDS("../data/qwi_sex.rds")
qwi_sex <- qwi_sex %>%
  mutate(
    county_fips = str_pad(as.character(geography), 5, pad = "0"),
    state_fips = substr(county_fips, 1, 2),
    yq = year * 10 + quarter,
    time_index = (year - 2015) * 4 + quarter
  ) %>%
  left_join(treat_map %>% select(state_fips, first_treat_yq), by = "state_fips") %>%
  mutate(
    first_treat_yq = replace_na(first_treat_yq, 0),
    treated_state = first_treat_yq > 0,
    new_hire_rate = ifelse(Emp > 0, HirN / Emp, NA_real_),
    log_earn_new_hire = ifelse(EarnHirNS > 0, log(EarnHirNS), NA_real_)
  ) %>%
  filter(!is.na(Emp), Emp > 0, !is.na(new_hire_rate), new_hire_rate < 5)

saveRDS(qwi_sex, "../data/qwi_sex_clean.rds")

cat("\nDatasets saved to data/\n")
