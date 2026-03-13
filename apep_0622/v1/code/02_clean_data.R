# 02_clean_data.R — Merge datasets and create analysis panel
# APEP-0622: Taxing the Transition — EV Registration Fees and Adoption

source("code/00_packages.R")

cat("=== 02_clean_data.R ===\n")

# ============================================================
# 1. LOAD RAW DATA
# ============================================================
ev_reg    <- readRDS("data/ev_registrations.rds")
ev_fees   <- readRDS("data/ev_fees.rds")
gas       <- readRDS("data/gas_consumption.rds")
pop       <- readRDS("data/population.rds")
state_info <- readRDS("data/state_info.rds")

cat("Loaded:\n")
cat("  ev_registrations:", nrow(ev_reg), "obs\n")
cat("  ev_fees:", nrow(ev_fees), "states with fees\n")
cat("  gas_consumption:", nrow(gas), "obs\n")
cat("  population:", nrow(pop), "obs\n")
cat("  state_info:", nrow(state_info), "states\n")

# ============================================================
# 2. CREATE STATE ID CROSSWALK
# ============================================================
# state_info has: state (abbreviation), fips, state_name
# Create numeric state_id from FIPS for the `did` package
state_xwalk <- state_info %>%
  mutate(state_id = as.integer(fips)) %>%
  select(state, state_id, state_name, fips)

cat("\nState crosswalk: ", nrow(state_xwalk), " states\n")

# ============================================================
# 3. MERGE EV REGISTRATIONS WITH FEE POLICY
# ============================================================
# Left join fees: states without fees get NA
panel <- ev_reg %>%
  left_join(ev_fees, by = "state")

# Handle treatment timing:
# - MD enacted in 2024 — treat as never-treated in 2016-2023 panel
# - States with no fee: enacted_year = NA
# - For `did` package: first_treat = 0 means never-treated
panel <- panel %>%
  mutate(
    # Set first_treat: enacted_year for treated, 0 for never-treated
    # MD enacted 2024 -> outside panel -> never-treated
    first_treat = case_when(
      is.na(enacted_year)    ~ 0L,
      enacted_year > 2023    ~ 0L,
      TRUE                   ~ as.integer(enacted_year)
    ),
    # Binary treated indicator: 1 if fee enacted on or before current year
    treated = as.integer(first_treat > 0 & year >= first_treat),
    # Fee amount in dollars (for dose-response)
    fee_amount = case_when(
      treated == 1 ~ fee_bev,
      TRUE         ~ 0
    )
  )

cat("\nTreatment groups:\n")
panel %>%
  distinct(state, first_treat) %>%
  count(first_treat) %>%
  arrange(first_treat) %>%
  print()

# ============================================================
# 4. MERGE POPULATION (via state name crosswalk)
# ============================================================
# Population uses state_name; ev data uses state abbreviation
# Link via state_xwalk
pop_merged <- pop %>%
  left_join(state_xwalk %>% select(state, state_name), by = "state_name") %>%
  filter(!is.na(state)) %>%
  select(state, year, population)

cat("\nPopulation after crosswalk: ", nrow(pop_merged), " obs\n")

# Merge into panel
panel <- panel %>%
  left_join(pop_merged, by = c("state", "year"))

# ============================================================
# 5. MERGE GAS CONSUMPTION
# ============================================================
# Gas data uses state abbreviation, years 2016-2022
panel <- panel %>%
  left_join(gas, by = c("state", "year"))

cat("Gas consumption merged. Missing gas years (2023 expected):\n")
panel %>%
  filter(is.na(gas_consumption_kbbl)) %>%
  count(year) %>%
  print()

# ============================================================
# 6. ADD NUMERIC STATE ID
# ============================================================
panel <- panel %>%
  left_join(state_xwalk %>% select(state, state_id), by = "state")

stopifnot(all(!is.na(panel$state_id)))
cat("\nNumeric state IDs assigned. Range:", min(panel$state_id), "-", max(panel$state_id), "\n")

# ============================================================
# 7. CREATE ANALYSIS VARIABLES
# ============================================================
panel <- panel %>%
  mutate(
    # Log outcomes (add 1 to handle any zeros)
    log_bev      = log(bev + 1),
    log_phev     = log(phev + 1),
    log_ev_total = log(ev_total + 1),
    # Per capita
    bev_per_capita = ifelse(!is.na(population) & population > 0,
                            bev / population * 100000, NA_real_),
    # EV share: BEV as fraction of total EVs
    ev_share = ifelse(ev_total > 0, bev / ev_total, NA_real_),
    # Log gas consumption
    log_gas = ifelse(!is.na(gas_consumption_kbbl) & gas_consumption_kbbl > 0,
                     log(gas_consumption_kbbl), NA_real_)
  )

# ============================================================
# 8. PANEL DIAGNOSTICS
# ============================================================
cat("\n=== Panel Diagnostics ===\n")
cat("Observations:", nrow(panel), "\n")
cat("States:", n_distinct(panel$state), "\n")
cat("Years:", paste(sort(unique(panel$year)), collapse = ", "), "\n")
cat("Balanced:", nrow(panel) == n_distinct(panel$state) * n_distinct(panel$year), "\n")

n_treated_states <- panel %>%
  filter(first_treat > 0) %>%
  distinct(state) %>%
  nrow()
n_never_treated <- panel %>%
  filter(first_treat == 0) %>%
  distinct(state) %>%
  nrow()

cat("\nTreatment summary:\n")
cat("  Treated states:", n_treated_states, "\n")
cat("  Never-treated states:", n_never_treated, "\n")
cat("  Treated state-years:", sum(panel$treated), "\n")

cat("\nOutcome variable summary:\n")
cat("  log_bev: min =", round(min(panel$log_bev), 2),
    ", max =", round(max(panel$log_bev), 2),
    ", mean =", round(mean(panel$log_bev), 2), "\n")
cat("  bev_per_capita: min =", round(min(panel$bev_per_capita, na.rm = TRUE), 2),
    ", max =", round(max(panel$bev_per_capita, na.rm = TRUE), 2), "\n")
cat("  ev_share: min =", round(min(panel$ev_share, na.rm = TRUE), 3),
    ", max =", round(max(panel$ev_share, na.rm = TRUE), 3), "\n")

cat("\nFee amounts for treated state-years:\n")
panel %>%
  filter(treated == 1) %>%
  summarise(
    mean_fee = mean(fee_amount),
    median_fee = median(fee_amount),
    min_fee = min(fee_amount),
    max_fee = max(fee_amount)
  ) %>%
  print()

cat("\nMissing values:\n")
panel %>%
  summarise(across(everything(), ~ sum(is.na(.)))) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "n_missing") %>%
  filter(n_missing > 0) %>%
  print()

# ============================================================
# 9. SAVE
# ============================================================
saveRDS(panel, "data/analysis_panel.rds")
cat("\nSaved: data/analysis_panel.rds (", nrow(panel), " obs)\n")
cat("=== 02_clean_data.R complete ===\n")
