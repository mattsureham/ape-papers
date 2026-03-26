## 02_clean_data.R — Merge datasets, construct treatment indicators
## APEP Paper apep_1035

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 1. State FIPS crosswalk
# ============================================================
# Use R's built-in state.fips data or construct carefully
# state.name is alphabetical: Alabama, Alaska, Arizona, ...
# FIPS codes skip 3 (AS), 7 (CZ), 11 (DC), 14 (GU), 43 (PR), 52 (VI)
state_xwalk <- tibble(
  state_name = c(state.name, "District of Columbia"),
  state_abb = c(state.abb, "DC"),
  state_fips = c(
    1L, 2L, 4L, 5L, 6L, 8L, 9L, 10L, 12L, 13L,       # AL AK AZ AR CA CO CT DE FL GA
    15L, 16L, 17L, 18L, 19L, 20L, 21L, 22L, 23L, 24L,  # HI ID IL IN IA KS KY LA ME MD
    25L, 26L, 27L, 28L, 29L, 30L, 31L, 32L, 33L, 34L,  # MA MI MN MS MO MT NE NV NH NJ
    35L, 36L, 37L, 38L, 39L, 40L, 41L, 42L, 44L, 45L,  # NM NY NC ND OH OK OR PA RI SC
    46L, 47L, 48L, 49L, 50L, 51L, 53L, 54L, 55L, 56L,  # SD TN TX UT VT VA WA WV WI WY
    11L                                                    # DC
  )
)

# ============================================================
# 2. Treatment coding
# ============================================================
treatment_states <- tibble(
  state_abb = c("FL", "OK", "MD", "MN", "TN", "GA", "SC", "TX", "WV", "UT"),
  treat_year = c(1998L, 1999L, 2001L, 2001L, 2002L, 2004L, 2006L, 2007L, 2012L, 2018L)
)

state_xwalk <- state_xwalk %>%
  left_join(treatment_states, by = "state_abb") %>%
  mutate(
    treated = if_else(!is.na(treat_year), 1L, 0L),
    # For Callaway-Sant'Anna: first_treat = 0 for never-treated
    first_treat = if_else(!is.na(treat_year), treat_year, 0L)
  )

cat("Treatment states:\n")
state_xwalk %>% filter(treated == 1) %>% select(state_name, state_abb, treat_year) %>% print()
cat("\nNever-treated:", sum(state_xwalk$treated == 0), "states\n")

# ============================================================
# 3. Merge CDC divorce rates
# ============================================================
cdc_divorce <- readRDS(file.path(data_dir, "cdc_divorce_rates.rds"))
cdc_marriage <- readRDS(file.path(data_dir, "cdc_marriage_rates.rds"))

# Merge with state crosswalk
cdc_panel <- cdc_divorce %>%
  left_join(state_xwalk, by = "state_name") %>%
  left_join(
    cdc_marriage %>% select(state_name, year, marriage_rate),
    by = c("state_name", "year")
  ) %>%
  filter(!is.na(state_fips))

# Check Georgia coverage
ga_coverage <- cdc_panel %>%
  filter(state_abb == "GA") %>%
  summarise(
    min_year = min(year),
    max_year = max(year),
    n_years = n(),
    missing_years = paste(setdiff(1990:2022, year), collapse = ", ")
  )
cat("\nGeorgia CDC coverage:\n")
print(ga_coverage)

# Flag: Georgia is missing divorce data 2004-2016
# Create two panels: full (excluding GA) and with GA (for marriage rates only)
cdc_panel_noga <- cdc_panel %>% filter(state_abb != "GA")

cat("\nCDC panel (excl. GA):", nrow(cdc_panel_noga), "state-years\n")
cat("  States:", n_distinct(cdc_panel_noga$state_name), "\n")
cat("  Years:", paste(range(cdc_panel_noga$year), collapse = "-"), "\n")

# ============================================================
# 4. Merge ACS marital status
# ============================================================
acs <- readRDS(file.path(data_dir, "acs_marital_status.rds"))

acs_panel <- acs %>%
  left_join(state_xwalk, by = "state_fips") %>%
  filter(!is.na(state_name)) %>%
  select(state_name, state_abb, state_fips, year,
         pop_15plus, pct_married, pct_divorced, pct_separated,
         treated, first_treat, treat_year)

cat("\nACS panel:", nrow(acs_panel), "state-years\n")

# ============================================================
# 5. Merge BLS unemployment
# ============================================================
if (file.exists(file.path(data_dir, "bls_unemployment.rds"))) {
  bls <- readRDS(file.path(data_dir, "bls_unemployment.rds"))
  cdc_panel_noga <- cdc_panel_noga %>%
    left_join(bls, by = c("state_fips", "year"))
  acs_panel <- acs_panel %>%
    left_join(bls, by = c("state_fips", "year"))
  cat("\nMerged BLS unemployment rates\n")
}

# ============================================================
# 6. Summary statistics
# ============================================================
cat("\n=== Summary Statistics ===\n")

cat("\nCDC Divorce Rate (per 1,000 pop):\n")
cdc_panel_noga %>%
  group_by(treated) %>%
  summarise(
    n_states = n_distinct(state_name),
    mean_divorce = mean(divorce_rate, na.rm = TRUE),
    sd_divorce = sd(divorce_rate, na.rm = TRUE),
    mean_marriage = mean(marriage_rate, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

cat("\nTreatment cohort sizes:\n")
cdc_panel_noga %>%
  filter(treated == 1) %>%
  distinct(state_name, first_treat) %>%
  count(first_treat) %>%
  print()

# ============================================================
# 7. Save analysis-ready panels
# ============================================================
saveRDS(cdc_panel_noga, file.path(data_dir, "analysis_panel_cdc.rds"))
saveRDS(acs_panel, file.path(data_dir, "analysis_panel_acs.rds"))
saveRDS(state_xwalk, file.path(data_dir, "state_xwalk.rds"))

cat("\n=== Clean data complete ===\n")
cat("Saved: analysis_panel_cdc.rds, analysis_panel_acs.rds, state_xwalk.rds\n")
