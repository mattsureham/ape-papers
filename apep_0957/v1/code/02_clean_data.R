## 02_clean_data.R — Variable construction and sample restrictions
source("00_packages.R")

qwi <- readRDS("../data/qwi_eitc_panel.rds")
cat(sprintf("Loaded panel: %d rows\n", nrow(qwi)))

# --- Collapse to state × year × industry × ethnicity ---
# QWI is at county level — aggregate to state level
panel <- qwi %>%
  group_by(state_fips, year, quarter, ind_2d, ethnicity, first_treat,
           eitc_year, eitc_pct, naics56, hispanic) %>%
  summarise(
    EmpS = sum(EmpS, na.rm = TRUE),
    HirA = sum(HirA, na.rm = TRUE),
    Sep  = sum(Sep, na.rm = TRUE),
    Payroll = sum(Payroll, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    has_eitc = as.integer(!is.na(eitc_year) & year >= eitc_year),
    ln_emp = log(EmpS + 1),
    ln_hire = log(HirA + 1),
    ln_sep = log(Sep + 1),
    # Earnings per worker (quarterly)
    earn_pw = ifelse(!is.na(EmpS) & EmpS > 0 & !is.na(Payroll) & Payroll > 0,
                     Payroll / EmpS, NA_real_),
    ln_earn = log(ifelse(!is.na(earn_pw) & is.finite(earn_pw) & earn_pw > 0,
                         earn_pw, NA_real_)),
    # Time period index (annual for CS estimator)
    time_id = year,
    # Unit ID: state × industry × ethnicity
    unit_id = paste(state_fips, ind_2d, ethnicity, sep = "_")
  )

cat(sprintf("State-level panel: %d rows\n", nrow(panel)))
cat(sprintf("Unique units (state × industry × ethnicity): %d\n", n_distinct(panel$unit_id)))

# --- Annualize (average across quarters within year) ---
# CS estimator needs balanced annual panel
annual <- panel %>%
  group_by(state_fips, year, ind_2d, ethnicity, first_treat,
           eitc_year, eitc_pct, naics56, hispanic, unit_id, time_id) %>%
  summarise(
    EmpS = mean(EmpS, na.rm = TRUE),
    HirA = mean(HirA, na.rm = TRUE),
    Sep  = mean(Sep, na.rm = TRUE),
    earn_pw = mean(earn_pw, na.rm = TRUE),
    n_quarters = n(),
    .groups = "drop"
  ) %>%
  mutate(
    has_eitc = !is.na(eitc_year) & year >= eitc_year,
    ln_emp = log(EmpS + 1),
    ln_hire = log(HirA + 1),
    ln_sep = log(Sep + 1),
    ln_earn = log(ifelse(is.finite(earn_pw) & earn_pw > 0, earn_pw, NA_real_))
  )

# --- Restrict to 2000-2022 for analysis ---
# Keep pre-2000 EITC states as always-treated
annual <- annual %>%
  filter(year >= 2000 & year <= 2022)

cat(sprintf("Annual panel (2000-2022): %d rows\n", nrow(annual)))

# --- Balance check ---
year_counts <- annual %>%
  group_by(unit_id) %>%
  summarise(n_years = n_distinct(year), .groups = "drop")

cat(sprintf("Units with all 23 years: %d / %d\n",
            sum(year_counts$n_years == 23), nrow(year_counts)))

# Keep only units with at least 15 years of data (allows some missingness)
balanced_units <- year_counts %>% filter(n_years >= 15) %>% pull(unit_id)
annual <- annual %>% filter(unit_id %in% balanced_units)
cat(sprintf("After balance filter (>=15 years): %d rows, %d units\n",
            nrow(annual), n_distinct(annual$unit_id)))

# --- Create numeric unit IDs for CS estimator ---
annual <- annual %>%
  mutate(unit_num = as.integer(factor(unit_id)))

# --- Summary statistics ---
cat("\n=== Sample Summary ===\n")
cat(sprintf("States: %d\n", n_distinct(annual$state_fips)))
cat(sprintf("  EITC states (ever-treated): %d\n",
            n_distinct(annual$state_fips[annual$first_treat > 0])))
cat(sprintf("  Never-EITC states: %d\n",
            n_distinct(annual$state_fips[annual$first_treat == 0])))
cat(sprintf("Industries: %s\n", paste(sort(unique(annual$ind_2d)), collapse = ", ")))
cat(sprintf("Years: %d-%d\n", min(annual$year), max(annual$year)))
cat(sprintf("Total obs: %d\n", nrow(annual)))

# Triple-diff cell sizes
td_summary <- annual %>%
  group_by(naics56, hispanic) %>%
  summarise(
    n = n(),
    mean_emp = mean(EmpS, na.rm = TRUE),
    .groups = "drop"
  )
cat("\nTriple-diff cells:\n")
print(td_summary)

# --- Save ---
saveRDS(annual, "../data/analysis_panel.rds")
cat("\nSaved analysis_panel.rds\n")
