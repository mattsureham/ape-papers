## 02_clean_data.R — Construct analysis panel
## apep_0907: The Digital Door to Food Stamps

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 1. Load raw data
# ============================================================
policy_raw <- readRDS(file.path(data_dir, "policy_raw.rds"))
snap_fred  <- readRDS(file.path(data_dir, "snap_fred.rds"))
pop_fred   <- readRDS(file.path(data_dir, "pop_fred.rds"))
state_fips <- readRDS(file.path(data_dir, "state_fips.rds"))

# ============================================================
# 2. Process SNAP participation (monthly → annual)
# ============================================================
cat("Processing SNAP participation data...\n")

snap <- snap_fred %>%
  mutate(
    date = as.Date(date),
    year = year(date),
    month = month(date),
    snap_persons = value  # persons
  ) %>%
  filter(year >= 1996, year <= 2023)

# Aggregate to state-year (annual average of monthly caseload)
snap_annual <- snap %>%
  group_by(state_abbr, fips, year) %>%
  summarize(
    snap_persons = mean(snap_persons, na.rm = TRUE),
    n_months = n(),
    .groups = "drop"
  ) %>%
  filter(n_months >= 6)  # Require at least 6 months of data

cat("  SNAP annual:", nrow(snap_annual), "state-years\n")

# ============================================================
# 3. Process population (annual, in thousands)
# ============================================================
cat("Processing population data...\n")

pop <- pop_fred %>%
  mutate(
    date = as.Date(date),
    year = year(date),
    population = value * 1000  # FRED pop is in thousands
  ) %>%
  select(state_abbr, fips, year, population)

cat("  Population:", nrow(pop), "state-years\n")

# ============================================================
# 4. Extract treatment timing from policy database
# ============================================================
cat("Extracting treatment timing...\n")

# Convert yearmonth (YYYYMM) to year
policy <- policy_raw %>%
  mutate(
    year = as.integer(substr(as.character(yearmonth), 1, 4)),
    month = as.integer(substr(as.character(yearmonth), 5, 6))
  )

# First adoption year per state (when oapp first becomes 1)
treatment_timing <- policy %>%
  filter(oapp == 1) %>%
  group_by(state_pc, statename, state_fips) %>%
  summarize(
    first_oapp_ym = min(yearmonth),
    first_oapp_year = min(year),
    .groups = "drop"
  )

# Add never-treated states
never_treated <- policy %>%
  group_by(state_pc, statename, state_fips) %>%
  summarize(ever_oapp = max(oapp, na.rm = TRUE), .groups = "drop") %>%
  filter(ever_oapp == 0) %>%
  mutate(first_oapp_ym = NA_real_, first_oapp_year = 0L) %>%
  select(-ever_oapp)

treatment_all <- bind_rows(treatment_timing, never_treated)

cat("  Treated:", sum(treatment_all$first_oapp_year > 0), "\n")
cat("  Never-treated:", sum(treatment_all$first_oapp_year == 0), "\n")
cat("  Adoption years:\n")
print(table(treatment_all$first_oapp_year))

# ============================================================
# 5. Annual policy controls from policy DB
# ============================================================
cat("\nAggregating policy controls to annual level...\n")

# Select key concurrent policy variables (annual modal value)
policy_controls <- policy %>%
  group_by(state_pc, state_fips, year) %>%
  summarize(
    bbce = as.integer(round(mean(bbce, na.rm = TRUE))),
    cap = as.integer(round(mean(cap, na.rm = TRUE))),
    call_any = as.integer(round(mean(call_any, na.rm = TRUE))),
    outreach = as.integer(round(mean(outreach, na.rm = TRUE))),
    reportsimple = as.integer(round(mean(reportsimple, na.rm = TRUE))),
    transben = as.integer(round(mean(transben, na.rm = TRUE))),
    faceini = as.integer(round(mean(faceini, na.rm = TRUE))),
    facerec = as.integer(round(mean(facerec, na.rm = TRUE))),
    fingerprint = as.integer(round(mean(fingerprint, na.rm = TRUE))),
    ebtissuance = as.integer(round(mean(ebtissuance, na.rm = TRUE))),
    .groups = "drop"
  )

# ============================================================
# 6. Merge everything into analysis panel
# ============================================================
cat("Building analysis panel...\n")

# Link state codes
state_link <- state_fips %>%
  select(state_abbr, fips)

treat_link <- treatment_all %>%
  mutate(fips = sprintf("%02d", state_fips)) %>%
  select(state_pc, fips, first_oapp_year)

# Merge SNAP + population
panel <- snap_annual %>%
  left_join(pop, by = c("state_abbr", "fips", "year"))

# Add treatment timing
panel <- panel %>%
  left_join(treat_link, by = "fips")

# Add policy controls
panel <- panel %>%
  left_join(
    policy_controls %>% mutate(fips = sprintf("%02d", state_fips)),
    by = c("fips", "year")
  )

# Construct key variables
panel <- panel %>%
  mutate(
    # Participation rate (SNAP persons per 1000 population)
    snap_rate = (snap_persons / population) * 1000,
    # Treatment indicator (binary)
    treated = as.integer(!is.na(first_oapp_year) & first_oapp_year > 0 & year >= first_oapp_year),
    # For CS estimator: first_treat = 0 for never-treated
    first_treat = ifelse(is.na(first_oapp_year) | first_oapp_year == 0, 0L, first_oapp_year),
    # State numeric ID
    state_id = as.integer(factor(fips)),
    # Log SNAP persons
    log_snap = log(snap_persons + 1)
  ) %>%
  filter(!is.na(snap_rate), !is.na(population), population > 0)

cat("  Panel:", nrow(panel), "state-years\n")
cat("  States:", n_distinct(panel$fips), "\n")
cat("  Years:", range(panel$year), "\n")
cat("  Treated obs:", sum(panel$treated), "\n")
cat("  Control obs:", sum(panel$treated == 0), "\n")

# ============================================================
# 7. Summary statistics
# ============================================================
cat("\nSummary statistics:\n")
cat("  SNAP persons: mean =", round(mean(panel$snap_persons)),
    "sd =", round(sd(panel$snap_persons)), "\n")
cat("  SNAP rate (per 1000): mean =", round(mean(panel$snap_rate), 1),
    "sd =", round(sd(panel$snap_rate), 1), "\n")
cat("  Population: mean =", round(mean(panel$population)),
    "sd =", round(sd(panel$population)), "\n")

# ============================================================
# 8. Save analysis dataset
# ============================================================
saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
cat("\nSaved analysis panel:", nrow(panel), "obs\n")

# Also save treatment timing separately (useful for diagnostics)
saveRDS(treatment_all, file.path(data_dir, "treatment_timing.rds"))

cat("=== Data cleaning complete ===\n")
