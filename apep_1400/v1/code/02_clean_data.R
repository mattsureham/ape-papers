# =============================================================================
# 02_clean_data.R — Clean QWI data, construct analysis variables
# =============================================================================

source("00_packages.R")

qwi_raw <- readRDS("../data/qwi_raw.rds")
pfl_states <- readRDS("../data/pfl_states.rds")

cat("Raw QWI rows:", nrow(qwi_raw), "\n")

# --- Basic cleaning ---
qwi <- qwi_raw %>%
  filter(!is.na(HirA), HirA > 0) %>%
  mutate(
    year_q = year + (quarter - 1) / 4,
    time_q = (year - 2000) * 4 + quarter
  )

cat("QWI after dropping missing/zero HirA:", nrow(qwi), "rows\n")

# --- Pivot to wide: one row per state × quarter ---
qwi_wide <- qwi %>%
  select(state_fips, year, quarter, year_q, time_q, race_code, HirA, Emp, EarnS) %>%
  pivot_wider(
    id_cols = c(state_fips, year, quarter, year_q, time_q),
    names_from = race_code,
    values_from = c(HirA, Emp, EarnS),
    values_fn = sum
  ) %>%
  filter(!is.na(HirA_A1), !is.na(HirA_A2), HirA_A1 > 0, HirA_A2 > 0)

cat("Wide panel rows:", nrow(qwi_wide), "\n")

# --- Construct outcome variables ---
state_quarter <- qwi_wide %>%
  mutate(
    log_hira_ratio = log(HirA_A2 / HirA_A1),
    hira_gap = (HirA_A1 - HirA_A2) / (HirA_A1 + HirA_A2),
    log_hira_black = log(HirA_A2),
    log_hira_white = log(HirA_A1),
    log_emp_ratio = log(Emp_A2 / Emp_A1),
    log_earn_ratio = log(EarnS_A2 / EarnS_A1),
    hire_share_black = HirA_A2 / (HirA_A1 + HirA_A2),
    HirA_black = HirA_A2,
    HirA_white = HirA_A1,
    Emp_black = Emp_A2,
    Emp_white = Emp_A1,
    EarnS_black = EarnS_A2,
    EarnS_white = EarnS_A1
  )

# --- Merge PFL treatment ---
state_quarter <- state_quarter %>%
  left_join(pfl_states %>% select(state_fips, pfl_year, pfl_quarter, benefit_rate,
                                   max_weeks, job_protection),
            by = "state_fips") %>%
  mutate(
    first_treat_q = ifelse(!is.na(pfl_year),
                           (pfl_year - 2000) * 4 + pfl_quarter,
                           0),
    treated = as.integer(!is.na(pfl_year)),
    post = as.integer(!is.na(pfl_year) & (year > pfl_year | (year == pfl_year & quarter >= pfl_quarter)))
  )

# Create numeric state ID
state_ids <- state_quarter %>%
  distinct(state_fips) %>%
  arrange(state_fips) %>%
  mutate(state_id = row_number())

state_quarter <- state_quarter %>%
  left_join(state_ids, by = "state_fips")

cat("Panel rows:", nrow(state_quarter), "\n")
cat("States:", n_distinct(state_quarter$state_fips), "\n")
cat("Treated states:", n_distinct(state_quarter$state_fips[state_quarter$treated == 1]), "\n")
cat("Control states:", n_distinct(state_quarter$state_fips[state_quarter$treated == 0]), "\n")
cat("Year range:", min(state_quarter$year), "-", max(state_quarter$year), "\n")

# --- Create annual panel (for CS-DiD efficiency) ---
state_annual <- state_quarter %>%
  group_by(state_fips, year, state_id, first_treat_q, treated, pfl_year,
           benefit_rate, max_weeks, job_protection) %>%
  summarise(
    HirA_black = sum(HirA_black, na.rm = TRUE),
    HirA_white = sum(HirA_white, na.rm = TRUE),
    Emp_black = mean(Emp_black, na.rm = TRUE),
    Emp_white = mean(Emp_white, na.rm = TRUE),
    EarnS_black = mean(EarnS_black, na.rm = TRUE),
    EarnS_white = mean(EarnS_white, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    log_hira_ratio = log(HirA_black / HirA_white),
    log_hira_black = log(HirA_black),
    log_hira_white = log(HirA_white),
    log_emp_ratio = log(Emp_black / Emp_white),
    log_earn_ratio = log(EarnS_black / EarnS_white),
    hire_share_black = HirA_black / (HirA_black + HirA_white),
    hira_gap = (HirA_white - HirA_black) / (HirA_white + HirA_black),
    first_treat_yr = ifelse(!is.na(pfl_year), pfl_year, 0),
    post = as.integer(!is.na(pfl_year) & year >= pfl_year)
  )

cat("Annual panel rows:", nrow(state_annual), "\n")

# --- Save ---
saveRDS(state_quarter, "../data/state_quarter.rds")
saveRDS(state_annual, "../data/state_annual.rds")
cat("Clean data saved.\n")
