# =============================================================================
# 02_clean_data.R — Construct treatment panel
# Marijuana legalization and labor market firm dynamics
# =============================================================================

source("00_packages.R")

qwi_sa <- readRDS("../data/qwi_state_industry.rds")

# ---------------------------------------------------------------------------
# Treatment dates: first legal retail sale, coded as year + quarter fraction
# Source: NCSL marijuana overview + DISA legalization timeline
# ---------------------------------------------------------------------------

treat_dates <- tribble(
  ~state_fips, ~state_name,         ~treat_year, ~treat_q,
  8,           "Colorado",          2014,        1,
  53,          "Washington",        2014,        3,
  2,           "Alaska",            2016,        4,
  41,          "Oregon",            2015,        4,
  11,          "DC",                2020,        1,
  6,           "California",        2018,        1,
  23,          "Maine",             2020,        4,
  25,          "Massachusetts",     2018,        4,
  32,          "Nevada",            2017,        3,
  26,          "Michigan",          2019,        4,
  17,          "Illinois",          2020,        1,
  4,           "Arizona",           2021,        1,
  30,          "Montana",           2022,        1,
  34,          "New Jersey",        2022,        2,
  36,          "New York",          2023,        1,
  51,          "Virginia",          2024,        3,
  35,          "New Mexico",        2022,        2,
  9,           "Connecticut",       2023,        1,
  44,          "Rhode Island",      2022,        4,
  24,          "Maryland",          2023,        3,
  29,          "Missouri",          2023,        1,
  10,          "Delaware",          2024,        2,
  27,          "Minnesota",         2025,        1,
  39,          "Ohio",              2024,        3
) %>%
  mutate(treat_quarter = treat_year + (treat_q - 1) / 4)

# ---------------------------------------------------------------------------
# Create numeric quarter variable
# ---------------------------------------------------------------------------
# Rename 'quarter' to 'q' to avoid lubridate conflict
qwi_sa <- qwi_sa %>%
  rename(q = quarter) %>%
  mutate(
    year = as.integer(year),
    q = as.integer(q),
    quarter_num = year + (q - 1) / 4
  )

# ---------------------------------------------------------------------------
# Merge treatment status
# ---------------------------------------------------------------------------
panel <- qwi_sa %>%
  left_join(treat_dates %>% select(state_fips, treat_quarter), by = "state_fips") %>%
  mutate(
    treat_quarter = replace_na(treat_quarter, 0),
    post = if_else(treat_quarter > 0 & quarter_num >= treat_quarter, 1L, 0L),
    treated = if_else(treat_quarter > 0, 1L, 0L)
  )

# Filter: MN (2025 Q1) and OH (2024 Q3) might have very few post-periods in data ending 2024
# Keep them — they contribute to pre-period comparison even if post is thin
# But drop states not in the QWI (VT, WY already in data from Azure)

# ---------------------------------------------------------------------------
# Create net firm job creation and log employment
# ---------------------------------------------------------------------------
panel <- panel %>%
  mutate(
    net_firm_jb = frm_jb_gn - frm_jb_ls,
    log_emp = log(pmax(emp, 1)),
    turnover = hir_a + sep
  )

# ---------------------------------------------------------------------------
# Numeric IDs for CS-DiD
# ---------------------------------------------------------------------------
state_ids <- panel %>%
  distinct(state_fips) %>%
  arrange(state_fips) %>%
  mutate(state_id = row_number())

panel <- panel %>%
  left_join(state_ids, by = "state_fips")

# Integer time index
time_index <- panel %>%
  distinct(quarter_num) %>%
  arrange(quarter_num) %>%
  mutate(time_id = row_number())

panel <- panel %>%
  left_join(time_index, by = "quarter_num")

# Treatment time as integer
treat_time_index <- treat_dates %>%
  select(state_fips, treat_quarter) %>%
  left_join(time_index, by = c("treat_quarter" = "quarter_num")) %>%
  rename(g_time = time_id)

# If treat_quarter falls outside data window, treat as never-treated
# Use numeric (not integer) so did package can assign Inf to never-treated
treat_time_index <- treat_time_index %>%
  mutate(g_time = if_else(is.na(g_time), 0, as.numeric(g_time)))

panel <- panel %>%
  left_join(treat_time_index %>% select(state_fips, g_time), by = "state_fips") %>%
  mutate(g_time = replace_na(g_time, 0))

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
cat("Panel dimensions:\n")
cat("  States:", n_distinct(panel$state_fips), "\n")
cat("  Quarters:", n_distinct(panel$quarter_num), "\n")
cat("  Industries:", n_distinct(panel$industry), "\n")
cat("  Treated states:", sum(treat_dates$state_fips %in% unique(panel$state_fips)), "\n")
cat("  Never-treated:", n_distinct(panel$state_fips[panel$treat_quarter == 0]), "\n")
cat("  Total rows:", nrow(panel), "\n")

# Treatment cohort summary
cohort_summ <- treat_dates %>%
  filter(state_fips %in% unique(panel$state_fips)) %>%
  group_by(treat_year) %>%
  summarise(n_states = n(), states = paste(state_name, collapse = ", ")) %>%
  arrange(treat_year)
cat("\nCohort summary:\n")
print(as.data.frame(cohort_summ))

# ---------------------------------------------------------------------------
# Save
# ---------------------------------------------------------------------------
saveRDS(panel, "../data/analysis_panel.rds")
saveRDS(treat_dates, "../data/treat_dates.rds")
saveRDS(time_index, "../data/time_index.rds")

cat("\nAnalysis panel saved.\n")
