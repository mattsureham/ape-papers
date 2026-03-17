## 02_clean_data.R — Variable construction and panel assembly
## apep_0714: Marijuana Expungement × Black Employment DDD

source("code/00_packages.R")

# ============================================================
# 1. LOAD RAW DATA
# ============================================================

qwi_raw <- readRDS("data/qwi_raw.rds")
marijuana_laws <- read_csv("data/marijuana_laws.csv", show_col_types = FALSE)
acs_controls  <- read_csv("data/acs_county_controls.csv", show_col_types = FALSE)

cat("QWI rows:", nrow(qwi_raw), "\n")
cat("Counties:", n_distinct(qwi_raw$county_fips), "\n")

# ============================================================
# 2. WIDE FORMAT — one row per county-quarter
# ============================================================

# Pivot to wide: separate columns for Black (A2) and White (A1)
qwi_wide <- qwi_raw %>%
  filter(race %in% c("A1", "A2")) %>%
  mutate(race_label = case_when(race == "A2" ~ "black", race == "A1" ~ "white")) %>%
  select(county_fips, state_fips, year, quarter, race_label, Emp, EarnS) %>%
  pivot_wider(names_from = race_label, values_from = c(Emp, EarnS)) %>%
  rename(
    emp_black = Emp_black,
    emp_white = Emp_white,
    earn_black = EarnS_black,
    earn_white = EarnS_white
  )

cat("Wide format rows:", nrow(qwi_wide), "\n")

# ============================================================
# 3. MERGE LAW DATES
# ============================================================

qwi_wide <- qwi_wide %>%
  left_join(
    marijuana_laws %>% select(state_fips, group, expunge_year, expunge_qtr, retail_year, retail_qtr),
    by = "state_fips"
  )

# Check coverage
cat("Rows with group assigned:", sum(!is.na(qwi_wide$group)), "\n")

# ============================================================
# 4. TREATMENT TIMING VARIABLES
# ============================================================

qwi_wide <- qwi_wide %>%
  mutate(
    # Time index (quarters since 2013Q1)
    t = (year - 2013) * 4 + quarter,

    # Post indicators
    # Post-expungement: 1 if county is in expunge state AND current quarter >= expunge
    post_expunge = case_when(
      group != "expunge" ~ 0L,
      is.na(expunge_year) ~ 0L,
      year > expunge_year ~ 1L,
      year == expunge_year & quarter >= expunge_qtr ~ 1L,
      TRUE ~ 0L
    ),

    # Post-retail-legalization
    post_legal = case_when(
      is.na(retail_year) ~ 0L,
      year > retail_year ~ 1L,
      year == retail_year & quarter >= retail_qtr ~ 1L,
      TRUE ~ 0L
    ),

    # Legal state indicator (expunge OR legalize_only)
    legal_state = as.integer(group %in% c("expunge", "legalize_only")),

    # Expunge state indicator
    expunge_state = as.integer(group == "expunge"),

    # For CS-DiD: treatment cohort = first year of expungement (0 if never-treated)
    # Use numeric year*4+quarter to allow staggered timing
    # For CS-DiD, we need the "cohort" = time of first treatment
    # cohort_expunge uses same t-scale as t = (year-2013)*4 + quarter
    cohort_expunge = case_when(
      group == "expunge" ~ (expunge_year - 2013) * 4 + expunge_qtr,
      TRUE ~ 0  # 0 = never-treated
    )
  )

# ============================================================
# 5. OUTCOME VARIABLES
# ============================================================

# Replace 0 or missing employment with NA (QWI uses 0 for suppressed cells)
qwi_wide <- qwi_wide %>%
  mutate(
    emp_black = if_else(emp_black == 0, NA_real_, emp_black),
    emp_white = if_else(emp_white == 0, NA_real_, emp_white),
    earn_black = if_else(earn_black == 0, NA_real_, earn_black),
    earn_white = if_else(earn_white == 0, NA_real_, earn_white)
  )

# Main outcomes: log employment and earnings (Black and White separately)
qwi_wide <- qwi_wide %>%
  mutate(
    log_emp_black  = log(emp_black),
    log_emp_white  = log(emp_white),
    log_earn_black = log(earn_black),
    log_earn_white = log(earn_white),
    # Black-White ratio (for DDD)
    bw_emp_ratio   = emp_black / emp_white,
    bw_earn_ratio  = earn_black / earn_white,
    log_bw_emp     = log(bw_emp_ratio),
    log_bw_earn    = log(bw_earn_ratio)
  )

# ============================================================
# 6. LONG FORMAT FOR CS-DID — Black and White stacked
# ============================================================

# Stack Black and White rows (for race-interacted specifications)
qwi_long <- qwi_raw %>%
  filter(race %in% c("A1", "A2")) %>%
  mutate(
    is_black = as.integer(race == "A2"),
    t = (year - 2013) * 4 + quarter,
    log_emp = log(if_else(Emp == 0, NA_real_, Emp)),
    log_earn = log(if_else(EarnS == 0, NA_real_, EarnS))
  ) %>%
  left_join(marijuana_laws %>% select(state_fips, group, expunge_year, expunge_qtr), by = "state_fips") %>%
  mutate(
    expunge_state = as.integer(group == "expunge"),
    # cohort_expunge on same t-scale as t = (year-2013)*4 + quarter
    cohort_expunge = case_when(
      group == "expunge" ~ (expunge_year - 2013) * 4 + expunge_qtr,
      TRUE ~ 0
    )
  )

# ============================================================
# 7. MERGE COUNTY CONTROLS
# ============================================================

qwi_wide <- qwi_wide %>%
  left_join(acs_controls, by = "county_fips")

# ============================================================
# 8. SAMPLE RESTRICTIONS
# ============================================================

# Keep only counties with both Black and White employment data
# in at least 50% of pre-treatment periods (to avoid composition changes)
pre_complete <- qwi_wide %>%
  filter(year <= 2018) %>%
  group_by(county_fips) %>%
  summarise(
    n_pre = n(),
    n_black_obs = sum(!is.na(log_emp_black)),
    n_white_obs = sum(!is.na(log_emp_white)),
    .groups = "drop"
  ) %>%
  filter(n_black_obs >= 0.5 * n_pre & n_white_obs >= 0.5 * n_pre)

qwi_analysis <- qwi_wide %>%
  filter(county_fips %in% pre_complete$county_fips)

cat(sprintf("\nAnalysis sample: %d county-quarters, %d counties\n",
            nrow(qwi_analysis), n_distinct(qwi_analysis$county_fips)))
cat("By group:\n")
print(qwi_analysis %>% distinct(county_fips, group) %>% count(group))

# ============================================================
# 9. BALANCED PANEL CHECK
# ============================================================

panel_check <- qwi_analysis %>%
  group_by(county_fips) %>%
  summarise(n_periods = n(), .groups = "drop")

cat(sprintf("\nPanel balance: min=%d, max=%d, median=%d periods per county\n",
            min(panel_check$n_periods), max(panel_check$n_periods), median(panel_check$n_periods)))

# ============================================================
# 10. SAVE
# ============================================================

saveRDS(qwi_analysis, "data/qwi_analysis.rds")
saveRDS(qwi_long, "data/qwi_long.rds")

cat("\nData cleaning complete.\n")
cat(sprintf("Final analysis dataset: %d rows, %d counties\n",
            nrow(qwi_analysis), n_distinct(qwi_analysis$county_fips)))
