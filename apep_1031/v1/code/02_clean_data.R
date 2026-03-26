# =============================================================================
# 02_clean_data.R — Clean data and construct analysis variables
# apep_1031: Kitchen Table Capitalism
# =============================================================================

source("00_packages.R")

df_food <- readRDS("../data/qwi_food_raw.rds")
df_mfg  <- readRDS("../data/qwi_mfg_raw.rds")
df_sex  <- readRDS("../data/qwi_sex_raw.rds")

# --- Treatment coding: Food Freedom / Major Cottage Food Expansions ---
# Two tiers of treatment:
# Tier 1: Food freedom acts (full deregulation - no permits, inspections, caps)
# Tier 2: Major cottage food expansions (first law, cap removal, or major expansion)
# Treatment year = year of most significant reform
treatment <- tribble(
  ~state_fips, ~state_abbr, ~law_name,                              ~treat_year, ~treat_qtr, ~tier,
  # Tier 1: Food Freedom Acts
  56,          "WY",        "Food Freedom Act",                      2015,        3,          1,
  38,          "ND",        "Food Freedom Law",                      2017,        3,          1,
  23,          "ME",        "Local Control Food Systems Act",         2017,        4,          1,
  49,          "UT",        "Home Consumption & Homemade Food Act",   2018,        2,          1,
  40,          "OK",        "Homemade Food Freedom Act (HB 1032)",    2021,        4,          1,
  47,          "TN",        "Food Freedom Act (HB 813)",              2022,        3,          1,
  19,          "IA",        "Cottage Food Overhaul",                  2022,        3,          1,
  # Tier 2: Major Cottage Food Expansions
  26,          "MI",        "First cottage food law (HB 5280)",       2010,        4,          2,
  5,           "AR",        "Cottage Food Act (Act 72)",              2011,        3,          2,
  17,          "IL",        "Cottage Food & Regulation Act",          2011,        3,          2,
  48,          "TX",        "Cottage food major expansion (HB 970)",  2013,        3,          2,
  6,           "CA",        "Cottage food law (AB 1616)",             2013,        1,          2,
  22,          "LA",        "Cottage food law (Act 542)",             2013,        3,          2,
  28,          "MS",        "Cottage food law (SB 2553)",             2013,        3,          2,
  1,           "AL",        "First cottage food law (SB 159)",        2014,        3,          2,
  27,          "MN",        "Cottage food exemption created",         2015,        3,          2,
  8,           "CO",        "Cottage Food Act expansion",             2012,        3,          2,
  12,          "FL",        "Major cottage food expansion",           2017,        3,          2,
  24,          "MD",        "Cottage food expansion",                 2012,        3,          2,
  34,          "NJ",        "First cottage food law",                 2021,        4,          2,
  10,          "DE",        "Cottage food establishment rules",       2016,        3,          2,
  33,          "NH",        "Cottage food cap removal",               2022,        1,          2,
  29,          "MO",        "Cottage food expansion (online sales)",  2022,        1,          2
)

# Use annual treatment timing to reduce cohort fragmentation
# (many cohorts with 1 unit each cause CS estimation issues)
treatment <- treatment %>%
  mutate(first_treat = treat_year)

# --- State FIPS to name mapping ---
state_map <- tibble(
  state_fips = c(1,2,4,5,6,8,9,10,11,12,13,15,16,17,18,19,20,21,22,23,24,25,
                 26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,44,45,46,
                 47,48,49,50,51,53,54,55,56),
  state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI",
                 "ID","IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN",
                 "MS","MO","MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH",
                 "OK","OR","PA","RI","SC","SD","TN","TX","UT","VT","VA","WA",
                 "WV","WI","WY")
)

# --- Collapse to annual level for CS DiD ---
# Annual aggregation avoids cohort fragmentation with quarterly data
df_food_annual <- df_food %>%
  group_by(state_fips, year, industry, sex, agegrp) %>%
  summarise(
    Emp = mean(Emp, na.rm = TRUE),
    FrmJbGn = mean(FrmJbGn, na.rm = TRUE),
    FrmJbLs = mean(FrmJbLs, na.rm = TRUE),
    EarnS_total = mean(EarnS_total, na.rm = TRUE),
    HirA = mean(HirA, na.rm = TRUE),
    .groups = "drop"
  )

# --- Process food industries data ---
df <- df_food_annual %>%
  mutate(
    time_q = year,
    avg_earnings = ifelse(Emp > 0, EarnS_total / Emp, NA_real_),
    entry_rate = ifelse(Emp > 0, FrmJbGn / Emp, NA_real_),
    exit_rate = ifelse(Emp > 0, FrmJbLs / Emp, NA_real_),
    hire_rate = ifelse(Emp > 0, HirA / Emp, NA_real_),
    log_emp = ifelse(Emp > 0, log(Emp), NA_real_)
  ) %>%
  left_join(treatment %>% select(state_fips, first_treat), by = "state_fips") %>%
  mutate(first_treat = ifelse(is.na(first_treat), 0, first_treat)) %>%
  left_join(state_map, by = "state_fips")

# --- Process manufacturing placebo data (annual) ---
df_mfg_annual <- df_mfg %>%
  group_by(state_fips, year, industry, sex, agegrp) %>%
  summarise(Emp = mean(Emp, na.rm = TRUE), FrmJbGn = mean(FrmJbGn, na.rm = TRUE),
            .groups = "drop")

df_placebo <- df_mfg_annual %>%
  mutate(
    time_q = year,
    log_emp = ifelse(Emp > 0, log(Emp), NA_real_),
    entry_rate = ifelse(Emp > 0, FrmJbGn / Emp, NA_real_)
  ) %>%
  left_join(treatment %>% select(state_fips, first_treat), by = "state_fips") %>%
  mutate(first_treat = ifelse(is.na(first_treat), 0, first_treat))

# --- Process sex-specific data (annual) ---
df_sex_annual <- df_sex %>%
  group_by(state_fips, year, industry, sex, agegrp) %>%
  summarise(Emp = mean(Emp, na.rm = TRUE), FrmJbGn = mean(FrmJbGn, na.rm = TRUE),
            .groups = "drop")

df_by_sex <- df_sex_annual %>%
  mutate(
    time_q = year,
    log_emp = ifelse(Emp > 0, log(Emp), NA_real_),
    sex_label = case_when(sex == "1" ~ "Male", sex == "2" ~ "Female")
  ) %>%
  left_join(treatment %>% select(state_fips, first_treat), by = "state_fips") %>%
  mutate(first_treat = ifelse(is.na(first_treat), 0, first_treat))

# --- Validation checks ---
cat("=== Data Validation ===\n")

n_states <- n_distinct(df$state_fips)
n_treated <- n_distinct(df$state_fips[df$first_treat > 0])
n_quarters <- n_distinct(df$time_q)
cat(sprintf("States: %d (treated: %d, control: %d)\n", n_states, n_treated, n_states - n_treated))
cat(sprintf("Quarters: %d (%s to %s)\n", n_quarters, min(df$time_q), max(df$time_q)))
cat(sprintf("Industries: %s\n", paste(unique(df$industry), collapse = ", ")))

# Pre-periods check (relative to first treatment in 2015 Q3)
n_pre <- sum(unique(df$time_q) < 2010)
cat(sprintf("Pre-treatment years (before 2010): %d\n", n_pre))

# Check treated states have data
for (i in 1:nrow(treatment)) {
  st <- treatment$state_fips[i]
  nm <- treatment$state_abbr[i]
  n_obs <- sum(df$state_fips == st & df$industry == "722")
  cat(sprintf("  %s (FIPS %d): %d obs for NAICS 722\n", nm, st, n_obs))
  stopifnot(n_obs > 0)
}

# --- Save cleaned data ---
saveRDS(df, "../data/analysis_panel.rds")
saveRDS(df_placebo, "../data/placebo_panel.rds")
saveRDS(df_by_sex, "../data/sex_panel.rds")
saveRDS(treatment, "../data/treatment_coding.rds")

cat("\nCleaned data saved.\n")
cat(sprintf("Main panel: %d observations\n", nrow(df)))
cat(sprintf("Placebo panel: %d observations\n", nrow(df_placebo)))
