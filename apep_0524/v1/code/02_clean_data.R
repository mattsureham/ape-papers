## ============================================================
## 02_clean_data.R — Construct analysis datasets
## ============================================================

source("00_packages.R")

DATA_DIR <- "../data"
panel <- fread(file.path(DATA_DIR, "state_year_race_panel.csv"))
crown_dates <- fread(file.path(DATA_DIR, "crown_act_dates.csv"))

cat("Loaded panel:", nrow(panel), "rows\n")

## ---- State abbreviation crosswalk ----
fips_to_abbr <- setNames(
  c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI","ID","IL","IN",
    "IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
    "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT",
    "VT","VA","WA","WV","WI","WY","PR"),
  sprintf("%02d", c(1:2, 4:6, 8:13, 15:42, 44:51, 53:56, 72))
)

panel$state_abbr <- fips_to_abbr[panel$state_fips]

## ---- Construct Black-White gap panel ----
bw_panel <- panel %>%
  filter(race_group %in% c("Black", "White")) %>%
  select(year, state_fips, state_abbr, race_group, first_treat,
         emp_rate, lfp_rate, log_median_earn, median_earnings,
         share_professional, share_customer_facing, share_service,
         female_emp_rate, male_emp_rate,
         female_share_prof, female_share_customer,
         male_share_prof, male_share_customer,
         pop_16_64, total_employed, state_id)

## Pivot to wide to compute gaps
bw_gap <- bw_panel %>%
  select(year, state_fips, state_abbr, first_treat, state_id, race_group,
         emp_rate, log_median_earn, share_professional, share_customer_facing,
         female_emp_rate, male_emp_rate, pop_16_64) %>%
  pivot_wider(
    names_from = race_group,
    values_from = c(emp_rate, log_median_earn, share_professional,
                    share_customer_facing, female_emp_rate, male_emp_rate, pop_16_64)
  ) %>%
  mutate(
    emp_gap = emp_rate_Black - emp_rate_White,
    earn_gap = log_median_earn_Black - log_median_earn_White,
    prof_gap = share_professional_Black - share_professional_White,
    cust_gap = share_customer_facing_Black - share_customer_facing_White,
    female_emp_gap = female_emp_rate_Black - female_emp_rate_White,
    male_emp_gap = male_emp_rate_Black - male_emp_rate_White,
    crown_active = as.integer(first_treat > 0 & year >= first_treat),
    cohort_group = case_when(
      first_treat == 0 ~ "Never treated",
      first_treat <= 2020 ~ "Early (2019-2020)",
      first_treat <= 2022 ~ "Middle (2021-2022)",
      first_treat >= 2023 ~ "Late (2023-2024)"
    )
  )

fwrite(bw_gap, file.path(DATA_DIR, "bw_gap_panel.csv"))
cat("Saved BW gap panel:", nrow(bw_gap), "rows\n")

## ---- Triple-diff panel (state × race × year) ----
triple_diff <- panel %>%
  filter(race_group %in% c("Black", "White")) %>%
  mutate(
    treated_triple = as.integer(black == 1 & crown_active == 1),
    first_treat_triple = ifelse(black == 1 & first_treat > 0, first_treat, 0L),
    unit_id = as.integer(factor(paste(state_fips, race_group)))
  )

fwrite(triple_diff, file.path(DATA_DIR, "triple_diff_panel.csv"))
cat("Saved triple-diff panel:", nrow(triple_diff), "rows\n")

## ---- Summary statistics ----
sumstats <- panel %>%
  filter(race_group %in% c("Black", "White")) %>%
  mutate(period = ifelse(crown_active == 1, "Post-CROWN", "Pre-CROWN")) %>%
  group_by(race_group, period) %>%
  summarize(
    emp_rate = weighted.mean(emp_rate, pop_16_64, na.rm = TRUE),
    lfp_rate = weighted.mean(lfp_rate, pop_16_64, na.rm = TRUE),
    median_earnings = weighted.mean(median_earnings, pop_16_64, na.rm = TRUE),
    share_professional = weighted.mean(share_professional, pop_16_64, na.rm = TRUE),
    share_customer_facing = weighted.mean(share_customer_facing, pop_16_64, na.rm = TRUE),
    n_state_years = n(),
    .groups = "drop"
  )

fwrite(sumstats, file.path(DATA_DIR, "summary_statistics.csv"))

cat("\n=== SUMMARY STATISTICS ===\n")
print(sumstats)

## ---- Cohort trends ----
cohort_trends <- bw_gap %>%
  group_by(year, cohort_group) %>%
  summarize(
    emp_gap = mean(emp_gap, na.rm = TRUE),
    earn_gap = mean(earn_gap, na.rm = TRUE),
    prof_gap = mean(prof_gap, na.rm = TRUE),
    cust_gap = mean(cust_gap, na.rm = TRUE),
    n_states = n(),
    .groups = "drop"
  )

fwrite(cohort_trends, file.path(DATA_DIR, "cohort_trends.csv"))
cat("Saved cohort trends.\n")

## ---- Treatment rollout data ----
rollout_data <- crown_dates %>%
  arrange(crown_year) %>%
  mutate(cum_states = row_number())
fwrite(rollout_data, file.path(DATA_DIR, "rollout_data.csv"))

cat("\n=== CLEANING COMPLETE ===\n")
