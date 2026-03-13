## 02_clean_data.R — Clean and prepare analysis datasets
## apep_0662: Clean Slate Laws and Statistical Discrimination

source("00_packages.R")
load("data/clean_slate_data.RData")

cat("=== Cleaning data ===\n")

# --- BLS Panel: Annual aggregation for DiD ---
bls_annual <- bls_panel %>%
  filter(!is.na(urate)) %>%
  group_by(state_fips, state_abbr, year, first_treat, treated) %>%
  summarise(
    urate = mean(urate, na.rm = TRUE),
    nonfarm_emp = mean(nonfarm_emp, na.rm = TRUE),
    log_emp = mean(log_emp, na.rm = TRUE),
    n_months = n(),
    .groups = "drop"
  ) %>%
  filter(n_months >= 6)  # Require at least 6 months of data per year

# Create numeric state ID for CS-DiD
state_ids <- bls_annual %>%
  distinct(state_fips) %>%
  arrange(state_fips) %>%
  mutate(state_id = row_number())

bls_annual <- bls_annual %>%
  left_join(state_ids, by = "state_fips")

cat("BLS annual panel:\n")
cat("  Observations: ", nrow(bls_annual), "\n")
cat("  States: ", n_distinct(bls_annual$state_id), "\n")
cat("  Years: ", min(bls_annual$year), "-", max(bls_annual$year), "\n")
cat("  Treated states: ", n_distinct(bls_annual$state_abbr[bls_annual$treated == 1]), "\n")
cat("  Never-treated: ", n_distinct(bls_annual$state_abbr[bls_annual$treated == 0]), "\n")

# --- ACS Panel: Clean ---
acs_clean <- acs_panel %>%
  filter(!is.na(black_epop), !is.na(white_epop)) %>%
  filter(black_working_pop >= 1000) %>%  # Drop states with tiny Black populations
  left_join(state_ids, by = "state_fips")

cat("\nACS race panel:\n")
cat("  Observations: ", nrow(acs_clean), "\n")
cat("  States: ", n_distinct(acs_clean$state_fips), "\n")
cat("  Mean Black E-pop: ", round(mean(acs_clean$black_epop, na.rm = TRUE), 1), "\n")
cat("  Mean White E-pop: ", round(mean(acs_clean$white_epop, na.rm = TRUE), 1), "\n")
cat("  Mean B-W gap: ", round(mean(acs_clean$bw_gap, na.rm = TRUE), 1), " pp\n")

# --- Summary statistics table ---
sumstats <- tribble(
  ~Variable, ~Mean, ~SD, ~Min, ~Max, ~N,
  "Unemployment rate (\\%)", mean(bls_annual$urate), sd(bls_annual$urate),
    min(bls_annual$urate), max(bls_annual$urate), nrow(bls_annual),
  "Nonfarm employment (thous.)", mean(bls_annual$nonfarm_emp, na.rm = TRUE) / 1000,
    sd(bls_annual$nonfarm_emp, na.rm = TRUE) / 1000,
    min(bls_annual$nonfarm_emp, na.rm = TRUE) / 1000,
    max(bls_annual$nonfarm_emp, na.rm = TRUE) / 1000, sum(!is.na(bls_annual$nonfarm_emp)),
  "Black E-pop ratio (\\%)", mean(acs_clean$black_epop, na.rm = TRUE),
    sd(acs_clean$black_epop, na.rm = TRUE),
    min(acs_clean$black_epop, na.rm = TRUE),
    max(acs_clean$black_epop, na.rm = TRUE), nrow(acs_clean),
  "White E-pop ratio (\\%)", mean(acs_clean$white_epop, na.rm = TRUE),
    sd(acs_clean$white_epop, na.rm = TRUE),
    min(acs_clean$white_epop, na.rm = TRUE),
    max(acs_clean$white_epop, na.rm = TRUE), nrow(acs_clean),
  "White-Black E-pop gap (pp)", mean(acs_clean$bw_gap, na.rm = TRUE),
    sd(acs_clean$bw_gap, na.rm = TRUE),
    min(acs_clean$bw_gap, na.rm = TRUE),
    max(acs_clean$bw_gap, na.rm = TRUE), nrow(acs_clean)
)

cat("\n=== Summary Statistics ===\n")
print(sumstats)

# --- Cohort sizes ---
cat("\n=== Treatment Cohort Sizes ===\n")
bls_annual %>%
  filter(treated == 1) %>%
  distinct(state_abbr, first_treat) %>%
  count(first_treat) %>%
  print()

# --- Save cleaned data ---
save(bls_annual, acs_clean, state_ids, sumstats,
     state_fips, clean_slate_states,
     file = "data/clean_data.RData")

cat("\nCleaned data saved.\n")
