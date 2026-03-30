# =============================================================================
# 02_clean_data.R — Construct analysis panel and exposure measures
# =============================================================================

source("00_packages.R")

qwi_state <- readRDS("../data/qwi_state_mfg.rds")
qwi_county <- readRDS("../data/qwi_county_mfg.rds")

# =============================================================================
# 1. Create time variables
# =============================================================================
qwi_state <- qwi_state %>%
  mutate(
    state_fips = as.character(geography),
    yq = year + (quarter - 1) / 4,
    time_id = (year - 2013) * 4 + quarter,
    post = as.integer(yq >= 2018.25),  # 2018Q2 = first full post-tariff quarter
    downstream = as.integer(industry %in% c("332", "333", "336")),
    edu_label = case_when(
      education == "E1" ~ "Less than HS",
      education == "E2" ~ "HS diploma",
      education == "E3" ~ "Some college",
      education == "E4" ~ "Bachelor's+",
      education == "E0" ~ "All",
      TRUE ~ education
    )
  )

qwi_county <- qwi_county %>%
  mutate(
    county_fips = as.character(geography),
    state_fips = substr(as.character(geography), 1,
                        nchar(as.character(geography)) - 3),
    yq = year + (quarter - 1) / 4,
    time_id = (year - 2013) * 4 + quarter,
    post = as.integer(yq >= 2018.25),
    downstream = as.integer(industry %in% c("332", "333", "336"))
  )

# =============================================================================
# 2. Construct state-level downstream exposure (pre-period share)
# =============================================================================
# Use 2016Q1 (last full year before tariff discussion)
state_exposure <- qwi_state %>%
  filter(year == 2016, quarter == 1, education == "E0") %>%
  group_by(state_fips) %>%
  summarise(
    emp_downstream = sum(Emp[downstream == 1], na.rm = TRUE),
    emp_total_mfg = sum(Emp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    exposure = ifelse(emp_total_mfg > 0, emp_downstream / emp_total_mfg, NA_real_)
  ) %>%
  filter(!is.na(exposure), emp_total_mfg > 100)

cat("State exposure distribution:\n")
print(summary(state_exposure$exposure))
cat("N states with exposure:", nrow(state_exposure), "\n")

# =============================================================================
# 3. Construct county-level downstream exposure (pre-period share)
# =============================================================================
county_exposure <- qwi_county %>%
  filter(year == 2016, quarter == 1, education == "E0") %>%
  group_by(county_fips, state_fips) %>%
  summarise(
    emp_downstream = sum(Emp[downstream == 1], na.rm = TRUE),
    emp_total_mfg = sum(Emp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    exposure = ifelse(emp_total_mfg > 0, emp_downstream / emp_total_mfg, NA_real_)
  ) %>%
  filter(!is.na(exposure), emp_total_mfg >= 50)

cat("\nCounty exposure distribution:\n")
print(summary(county_exposure$exposure))
cat("N counties with exposure:", nrow(county_exposure), "\n")

# =============================================================================
# 4. Build state-level analysis panel
# =============================================================================
# Aggregate to state × education × quarter for downstream industries
state_panel <- qwi_state %>%
  filter(downstream == 1, education %in% c("E1", "E2", "E3", "E4")) %>%
  group_by(state_fips, education, edu_label, year, quarter, yq, time_id, post) %>%
  summarise(
    emp = sum(Emp, na.rm = TRUE),
    hires = sum(HirA, na.rm = TRUE),
    seps = sum(Sep, na.rm = TRUE),
    earn_beg = weighted.mean(EarnBeg, w = Emp, na.rm = TRUE),
    frm_job_gain = sum(FrmJbGn, na.rm = TRUE),
    frm_job_loss = sum(FrmJbLs, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(emp > 0) %>%
  mutate(
    log_emp = log(emp),
    sep_rate = seps / emp,
    hire_rate = hires / emp,
    log_earn = log(earn_beg)
  )

# Merge exposure
state_panel <- state_panel %>%
  inner_join(state_exposure %>% select(state_fips, exposure), by = "state_fips")

# Create interaction terms
state_panel <- state_panel %>%
  mutate(
    high_edu = as.integer(education %in% c("E3", "E4")),
    ba_plus = as.integer(education == "E4"),
    exposure_post = exposure * post,
    exposure_post_highedu = exposure * post * high_edu,
    exposure_post_ba = exposure * post * ba_plus,
    state_edu = paste0(state_fips, "_", education),
    edu_time = paste0(education, "_", time_id),
    state_time = paste0(state_fips, "_", time_id)
  )

cat("\nState panel: ", nrow(state_panel), " obs\n")
cat("States:", n_distinct(state_panel$state_fips), "\n")
cat("Education groups:", n_distinct(state_panel$education), "\n")
cat("Quarters:", n_distinct(state_panel$time_id), "\n")

# =============================================================================
# 5. Build county-level analysis panel
# =============================================================================
county_panel <- qwi_county %>%
  filter(downstream == 1, education %in% c("E1", "E2", "E3", "E4")) %>%
  group_by(county_fips, state_fips, education, year, quarter, yq, time_id, post) %>%
  summarise(
    emp = sum(Emp, na.rm = TRUE),
    hires = sum(HirA, na.rm = TRUE),
    seps = sum(Sep, na.rm = TRUE),
    earn_beg = weighted.mean(EarnBeg, w = Emp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(emp > 0) %>%
  mutate(
    log_emp = log(emp),
    sep_rate = seps / emp,
    hire_rate = hires / emp,
    log_earn = log(earn_beg)
  )

county_panel <- county_panel %>%
  inner_join(county_exposure %>% select(county_fips, exposure), by = "county_fips")

county_panel <- county_panel %>%
  mutate(
    high_edu = as.integer(education %in% c("E3", "E4")),
    ba_plus = as.integer(education == "E4"),
    exposure_post = exposure * post,
    exposure_post_highedu = exposure * post * high_edu,
    exposure_post_ba = exposure * post * ba_plus,
    county_edu = paste0(county_fips, "_", education),
    edu_time = paste0(education, "_", time_id),
    county_time = paste0(county_fips, "_", time_id)
  )

cat("County panel: ", nrow(county_panel), " obs\n")
cat("Counties:", n_distinct(county_panel$county_fips), "\n")

# =============================================================================
# 6. Save analysis-ready panels
# =============================================================================
saveRDS(state_panel, "../data/state_panel.rds")
saveRDS(county_panel, "../data/county_panel.rds")
saveRDS(state_exposure, "../data/state_exposure.rds")
saveRDS(county_exposure, "../data/county_exposure.rds")

cat("\nAnalysis panels saved.\n")
