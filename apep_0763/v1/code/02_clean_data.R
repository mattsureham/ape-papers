# 02_clean_data.R
# SNAP Emergency Allotment Expiration and Labor Supply
# Merge QWI, EA timing, FRED unemployment; construct analysis dataset

source("00_packages.R")

data_dir <- "../data"

# ------------------------------------------------------------------
# 1. Load raw data
# ------------------------------------------------------------------
qwi_data  <- readRDS(file.path(data_dir, "qwi_data.rds"))
ea_timing <- readRDS(file.path(data_dir, "ea_timing.rds"))
fred_ur   <- readRDS(file.path(data_dir, "fred_ur.rds"))

cat("Loaded:\n")
cat("  QWI rows:", nrow(qwi_data), "\n")
cat("  EA timing rows:", nrow(ea_timing), "\n")
cat("  FRED UR rows:", nrow(fred_ur), "\n")

# ------------------------------------------------------------------
# 2. Standardize QWI geography to state_fips and state_abbr
# ------------------------------------------------------------------
# QWI data already has state_abbr from the fetch script
# Create consistent state_fips for merging
qwi_clean <- qwi_data %>%
  mutate(state_fips = str_pad(as.character(geography), width = 2, side = "left", pad = "0"))

# ------------------------------------------------------------------
# 3. Merge EA timing
# ------------------------------------------------------------------
ea_merge <- ea_timing %>%
  select(ea_state_abbr = state_abbr, state_fips, first_treat, treated)

qwi_ea <- qwi_clean %>%
  left_join(ea_merge, by = "state_fips")

# Verify join
missing_fips <- qwi_ea %>% filter(is.na(first_treat)) %>% distinct(state_fips)
if (nrow(missing_fips) > 0) {
  cat("WARNING: FIPS codes without EA timing match:\n")
  print(missing_fips)
  # Drop unmatched states (likely Alaska with no QWI data)
  qwi_ea <- qwi_ea %>% filter(!is.na(first_treat))
}

# ------------------------------------------------------------------
# 4. Merge FRED unemployment
# ------------------------------------------------------------------
# FRED merge: match on state_abbr from QWI and year/quarter
fred_merge <- fred_ur %>%
  rename(fred_state_abbr = state_abbr)
qwi_full <- qwi_ea %>%
  left_join(fred_merge, by = c("state_abbr" = "fred_state_abbr", "year", "quarter"))

missing_ur <- sum(is.na(qwi_full$unemp_rate))
cat("Missing unemployment rate observations:", missing_ur, "\n")

# ------------------------------------------------------------------
# 4b. Aggregate to state-race-quarter level (QWI has sub-industry rows)
# ------------------------------------------------------------------
cat("\nAggregating to state-race-quarter level...\n")
cat("Rows before aggregation:", nrow(qwi_full), "\n")
qwi_full <- qwi_full %>%
  group_by(state_abbr, state_fips, year, quarter, race, first_treat, treated, unemp_rate) %>%
  summarise(
    Emp   = sum(Emp, na.rm = TRUE),
    HirN  = sum(HirN, na.rm = TRUE),
    EarnS = mean(EarnS, na.rm = TRUE),
    .groups = "drop"
  )
cat("Rows after aggregation:", nrow(qwi_full), "\n")

# ------------------------------------------------------------------
# 5. Construct time index and derived variables
# ------------------------------------------------------------------
# Time index: 2019Q1 = 1, 2019Q2 = 2, ..., 2023Q4 = 20
qwi_full <- qwi_full %>%
  mutate(
    time_index = (year - 2019) * 4 + quarter,
    # Numeric state id for CS-DiD (must be integer, no factors)
    state_id = as.integer(state_fips),
    # Log new hires (IHS-style: log(1+x) to handle zeros)
    log_hirn = log(1 + HirN),
    # Log employment stock
    log_emp = log(1 + Emp),
    # New hires rate (new hires per worker)
    hirn_rate = if_else(Emp > 0, HirN / Emp, NA_real_),
    # Log earnings per worker (EarnS is total earnings of stable employment)
    log_earns = log(1 + EarnS),
    # EA treatment indicator: 1 once EA has ended in that state
    ea_ended = as.integer(treated == 1 & time_index >= first_treat & first_treat > 0),
    # Relative event time (quarters since EA termination; NA for never-treated)
    rel_time = if_else(
      treated == 1 & first_treat > 0,
      time_index - first_treat,
      NA_integer_
    )
  )

# Verify time index range
stopifnot(
  "time_index min should be 1 (2019Q1)" = min(qwi_full$time_index) == 1,
  "time_index max should be 20 (2023Q4)" = max(qwi_full$time_index) == 20
)

cat("\nTime index range:", min(qwi_full$time_index), "to", max(qwi_full$time_index),
    "(", min(qwi_full$year), "Q", min(qwi_full$quarter[qwi_full$time_index == 1]),
    "to", max(qwi_full$year), "Q", max(qwi_full$quarter[qwi_full$time_index == 20]), ")\n")
cat("EA ended observations:", sum(qwi_full$ea_ended, na.rm = TRUE), "\n")

# ------------------------------------------------------------------
# 6. Split by race
# ------------------------------------------------------------------
# Race codes: A0 = all races, A2 = Black
all_workers   <- qwi_full %>% filter(race == "A0")
black_workers <- qwi_full %>% filter(race == "A2")

cat("\nAll workers dataset:\n")
cat("  Rows:", nrow(all_workers), "\n")
cat("  Treated states:", n_distinct(all_workers$state_fips[all_workers$treated == 1]), "\n")
cat("  Never-treated states:", n_distinct(all_workers$state_fips[all_workers$treated == 0]), "\n")
cat("  Time periods:", n_distinct(all_workers$time_index), "\n")

cat("\nBlack workers dataset:\n")
cat("  Rows:", nrow(black_workers), "\n")
cat("  Non-missing HirN:", sum(!is.na(black_workers$HirN)), "\n")

# Summary of missing data
cat("\nMissing data summary (all workers):\n")
cat("  HirN missing:", sum(is.na(all_workers$HirN)), "\n")
cat("  Emp missing:", sum(is.na(all_workers$Emp)), "\n")
cat("  EarnS missing:", sum(is.na(all_workers$EarnS)), "\n")
cat("  unemp_rate missing:", sum(is.na(all_workers$unemp_rate)), "\n")

# ------------------------------------------------------------------
# 7. Verify identification assumptions
# ------------------------------------------------------------------
n_treated <- n_distinct(all_workers$state_fips[all_workers$treated == 1])
n_pre_periods <- n_distinct(all_workers$time_index[all_workers$time_index < min(ea_timing$first_treat[ea_timing$first_treat > 0])])

cat("\nIdentification check:\n")
cat("  Treated units:", n_treated, "(need >= 18)\n")
cat("  Pre-periods before first treatment:", n_pre_periods, "(need >= 5)\n")

stopifnot(
  "Need at least 15 treated states" = n_treated >= 15,
  "Need at least 5 pre-treatment periods" = n_pre_periods >= 5
)

# ------------------------------------------------------------------
# 8. Combine into single analysis dataset and save
# ------------------------------------------------------------------
analysis <- qwi_full %>%
  select(
    state_abbr, state_fips, state_id, year, quarter, time_index,
    race, Emp, HirN, EarnS,
    log_emp, log_hirn, log_earns, hirn_rate,
    first_treat, treated, ea_ended, rel_time,
    unemp_rate
  )

saveRDS(analysis, file.path(data_dir, "analysis.rds"))
cat("\nSaved analysis.rds\n")

# Save race-split datasets too for convenience
saveRDS(all_workers, file.path(data_dir, "all_workers.rds"))
saveRDS(black_workers, file.path(data_dir, "black_workers.rds"))
cat("Saved all_workers.rds and black_workers.rds\n")

# Summary statistics for verification
cat("\nSummary (all workers, treated states, post-treatment):\n")
all_workers %>%
  filter(ea_ended == 1) %>%
  summarise(
    across(c(Emp, HirN, log_hirn, hirn_rate), ~ mean(.x, na.rm = TRUE), .names = "mean_{.col}")
  ) %>%
  print()

cat("\n02_clean_data.R complete.\n")
