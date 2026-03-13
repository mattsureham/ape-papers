# =============================================================================
# 02_clean_data.R — Construct analytical variables
# =============================================================================

source("00_packages.R")

qwi <- readRDS("../data/qwi_panel.rds")
qwi_race <- readRDS("../data/qwi_race_panel.rds")
ban_dates <- readRDS("../data/ban_dates.rds")

# ── Construct gender gap at state×industry×quarter level ─────────────────────
# Pivot from long (one row per sex) to wide (male/female columns side by side)
panel <- qwi %>%
  filter(!is.na(EarnHirNS), EarnHirNS > 0) %>%
  select(state_fips, industry, year, quarter, yq, sex_label,
         first_treat_yq, treated, post,
         Emp, HirN, Sep, FrmJbGn, FrmJbLs, EarnHirNS, EarnS, TurnOvrS) %>%
  pivot_wider(
    names_from = sex_label,
    values_from = c(Emp, HirN, Sep, FrmJbGn, FrmJbLs, EarnHirNS, EarnS, TurnOvrS),
    names_sep = "_"
  ) %>%
  filter(!is.na(EarnHirNS_Female), !is.na(EarnHirNS_Male)) %>%
  mutate(
    # Gender gap measures
    earn_gap_ratio = EarnHirNS_Female / EarnHirNS_Male,
    earn_gap_log = log(EarnHirNS_Female) - log(EarnHirNS_Male),
    earn_gap_abs = EarnHirNS_Female - EarnHirNS_Male,
    # Hiring rate gender gap
    hire_rate_female = HirN_Female / pmax(Emp_Female, 1),
    hire_rate_male = HirN_Male / pmax(Emp_Male, 1),
    hire_gap = hire_rate_female - hire_rate_male,
    # Separation rate gap
    sep_rate_female = Sep_Female / pmax(Emp_Female, 1),
    sep_rate_male = Sep_Male / pmax(Emp_Male, 1),
    sep_gap = sep_rate_female - sep_rate_male,
    # Total employment for weighting
    total_emp = Emp_Female + Emp_Male,
    # Unit ID for panel
    unit_id = paste0(state_fips, "_", industry),
    # Time period as integer (quarters since 2013Q1)
    time_int = (year - 2013) * 4 + quarter,
    # First treatment as integer quarters
    first_treat_int = ifelse(first_treat_yq == 0, 0,
                             (floor(first_treat_yq) - 2013) * 4 +
                               round((first_treat_yq - floor(first_treat_yq)) * 4) + 1)
  )

cat("Analytical panel: ", nrow(panel), " obs\n")
cat("State×industry units: ", n_distinct(panel$unit_id), "\n")
cat("Time periods: ", n_distinct(panel$time_int), "\n")

# ── Industry-level pre-ban gender gap (for mechanism test) ───────────────────
pre_gaps <- panel %>%
  filter(yq < 2017.75) %>%
  group_by(industry) %>%
  summarise(
    pre_gap_ratio = weighted.mean(earn_gap_ratio, total_emp, na.rm = TRUE),
    pre_gap_log = weighted.mean(earn_gap_log, total_emp, na.rm = TRUE),
    pre_female_earn = weighted.mean(EarnHirNS_Female, Emp_Female, na.rm = TRUE),
    pre_male_earn = weighted.mean(EarnHirNS_Male, Emp_Male, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    # Classify industries by pre-ban gap size
    gap_pct = (1 - pre_gap_ratio) * 100,
    high_gap = gap_pct > median(gap_pct, na.rm = TRUE)
  )

cat("\nIndustry pre-ban gender gaps (% female underpayment):\n")
pre_gaps %>%
  arrange(desc(gap_pct)) %>%
  select(industry, gap_pct, high_gap) %>%
  print(n = 25)

panel <- panel %>%
  left_join(pre_gaps %>% select(industry, high_gap, gap_pct), by = "industry")

# ── Race panel: construct Black-White earnings gap ───────────────────────────
race_panel <- qwi_race %>%
  filter(!is.na(EarnHirNS), EarnHirNS > 0) %>%
  select(state_fips, industry, year, quarter, yq, race_label,
         first_treat_yq, treated, post,
         Emp, HirN, EarnHirNS) %>%
  pivot_wider(
    names_from = race_label,
    values_from = c(Emp, HirN, EarnHirNS),
    names_sep = "_"
  ) %>%
  filter(!is.na(EarnHirNS_Black), !is.na(EarnHirNS_White)) %>%
  mutate(
    race_gap_log = log(EarnHirNS_Black) - log(EarnHirNS_White),
    race_gap_ratio = EarnHirNS_Black / EarnHirNS_White,
    hire_rate_black = HirN_Black / pmax(Emp_Black, 1),
    hire_rate_white = HirN_White / pmax(Emp_White, 1),
    hire_gap_race = hire_rate_black - hire_rate_white,
    total_emp = Emp_Black + Emp_White,
    unit_id = paste0(state_fips, "_", industry),
    time_int = (year - 2013) * 4 + quarter,
    first_treat_int = ifelse(first_treat_yq == 0, 0,
                             (floor(first_treat_yq) - 2013) * 4 +
                               round((first_treat_yq - floor(first_treat_yq)) * 4) + 1)
  )

cat("\nRace panel:", nrow(race_panel), "obs\n")

# ── Save ─────────────────────────────────────────────────────────────────────
saveRDS(panel, "../data/panel_clean.rds")
saveRDS(race_panel, "../data/race_panel_clean.rds")
saveRDS(pre_gaps, "../data/pre_gaps.rds")

cat("\n=== Clean data saved ===\n")
