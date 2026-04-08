## 02_clean_data.R — Variable construction
## apep_1394: PFL × Healthcare Workforce Retention

source("00_packages.R")

cat("=== CLEANING DATA ===\n")

panel <- readRDS("../data/panel.rds")
pfl_states <- readRDS("../data/pfl_states.rds")

# -----------------------------------------------------------------------
# 1. Construct analysis variables
# -----------------------------------------------------------------------

panel <- panel |>
  mutate(
    turnover = as.numeric(TurnOvrS),
    separations = as.numeric(SepS),
    earnings = as.numeric(EarnS),
    emp_end = as.numeric(EmpEnd),
    hires = as.numeric(HirAS),

    ln_sep = log(separations + 1),
    ln_earn = log(earnings + 1),
    ln_emp = log(emp_end + 1),

    sep_rate = ifelse(emp_end > 0, separations / emp_end, NA_real_),
    hire_rate = ifelse(emp_end > 0, hires / emp_end, NA_real_),

    state_sex = paste0(state_fips, "_", sex),
    state_sex_id = as.integer(factor(state_sex)),

    event_time = ifelse(pfl_state, time_id - ((pfl_year - 2001) * 4 + pfl_quarter), NA_integer_),

    sex_label = ifelse(female == 1, "Female", "Male"),
    yq_label = paste0(year, "Q", quarter)
  )

# -----------------------------------------------------------------------
# 2. Summary statistics
# -----------------------------------------------------------------------

cat("\n--- Summary by Sex and PFL Status ---\n")
panel |>
  filter(!is.na(turnover)) |>
  group_by(sex_label, pfl_state) |>
  summarise(
    n = n(),
    mean_turnover = mean(turnover, na.rm = TRUE),
    sd_turnover = sd(turnover, na.rm = TRUE),
    mean_earnings = mean(earnings, na.rm = TRUE),
    .groups = "drop"
  ) |>
  print()

cat("\n--- Pre-treatment turnover gap (female - male) ---\n")
pre_gap <- panel |>
  filter(!is.na(turnover), post_pfl == 0) |>
  group_by(state_fips, date_q) |>
  summarise(
    gap = turnover[female == 1] - turnover[female == 0],
    .groups = "drop"
  )
cat("Mean pre-treatment gender gap:", round(mean(pre_gap$gap, na.rm = TRUE), 4), "\n")
cat("SD of gap:", round(sd(pre_gap$gap, na.rm = TRUE), 4), "\n")

# -----------------------------------------------------------------------
# 3. Validate
# -----------------------------------------------------------------------

stopifnot("Panel has data" = nrow(panel) > 1000)
stopifnot("Has female obs" = sum(panel$female == 1) > 100)
stopifnot("Has male obs" = sum(panel$female == 0) > 100)
stopifnot("Has PFL states" = sum(panel$pfl_state) > 100)
stopifnot("Turnover not all NA" = sum(!is.na(panel$turnover)) > 1000)

# -----------------------------------------------------------------------
# 4. Save
# -----------------------------------------------------------------------

saveRDS(panel, "../data/panel_clean.rds")
write_csv(panel |> select(state_fips, sex, female, year, quarter, yq, date_q, time_id,
                           pfl_state, post_pfl, treated_ddd, cohort_year, event_time,
                           turnover, separations, earnings, emp_end, sep_rate, hire_rate,
                           ln_sep, ln_earn, state_sex_id, sex_label),
          "../data/panel_clean.csv")

cat("\n=== CLEAN DATA SAVED ===\n")
cat("Observations:", nrow(panel), "\n")
cat("Non-missing turnover:", sum(!is.na(panel$turnover)), "\n")
