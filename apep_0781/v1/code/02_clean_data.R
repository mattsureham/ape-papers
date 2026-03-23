## 02_clean_data.R — Construct analysis panel
## apep_0781: UI Taxable Wage Base and Employer Separations

source("00_packages.R")

qwi_raw <- readRDS("../data/qwi_raw.rds")
suta_events <- readRDS("../data/suta_events.rds")
state_fips_map <- readRDS("../data/state_fips_map.rds")

# ── Parse numeric variables ──
qwi <- qwi_raw %>%
  mutate(
    Emp = as.numeric(Emp),
    Sep = as.numeric(Sep),
    EarnS = as.numeric(EarnS),
    HirN = as.numeric(HirN),
    state_fips = as.character(state),
    year = as.integer(sub("-Q.*", "", time)),
    quarter = as.integer(sub(".*-Q", "", time)),
    yq = year + (quarter - 1) / 4
  ) %>%
  left_join(state_fips_map, by = "state_fips")

# ── Merge SUTA treatment ──
federal_min_states <- c("AZ", "CA", "FL", "GA", "MI", "MS", "NE", "TN")

qwi <- qwi %>%
  left_join(suta_events %>% select(state_abbr, first_big_increase_year),
            by = "state_abbr") %>%
  mutate(
    # Treatment groups
    treated_state = !is.na(first_big_increase_year),
    control_state = state_abbr %in% federal_min_states,
    # Post-treatment indicator
    post_increase = !is.na(first_big_increase_year) & year >= first_big_increase_year,
    # Industry wage level classification
    low_wage = industry_code %in% c("44-45", "72"),  # Retail, food/accommodation
    high_wage = industry_code %in% c("52", "54"),     # Finance, professional services
    industry_label = case_when(
      industry_code == "44-45" ~ "Retail",
      industry_code == "72"    ~ "Food/Accommodation",
      industry_code == "52"    ~ "Finance",
      industry_code == "54"    ~ "Professional",
      industry_code == "31-33" ~ "Manufacturing",
      TRUE ~ industry_code
    ),
    # Separation rate
    sep_rate = Sep / (Emp + 1),
    log_sep = log(Sep + 1),
    log_emp = log(Emp + 1),
    log_earn = log(EarnS + 1),
    # Numeric time index (quarter from 2001Q1)
    time_idx = (year - 2001) * 4 + quarter,
    # For CS-DiD: first treatment quarter (0 = never treated)
    first_treat_q = ifelse(
      treated_state,
      (first_big_increase_year - 2001) * 4 + 1L,  # Q1 of increase year
      0L
    )
  )

# ── Filter to treatment + control states ──
# Keep: treated states + federal minimum states + a few mid-range controls
panel <- qwi %>%
  filter(!is.na(state_abbr), !is.na(Emp), Emp > 0, !is.na(Sep)) %>%
  mutate(
    group = case_when(
      treated_state ~ "Treated",
      control_state ~ "Control (Fed Min)",
      TRUE ~ "Other"
    )
  )

# ── Summary ──
cat("Panel structure:\n")
cat("  Total obs:", nrow(panel), "\n")
cat("  States:", n_distinct(panel$state_fips), "\n")
cat("  Industries:", n_distinct(panel$industry_code), "\n")
cat("  Quarters:", n_distinct(panel$yq), "\n")
cat("  Treated states:", n_distinct(panel$state_fips[panel$treated_state]), "\n")
cat("  Control (fed min) states:", n_distinct(panel$state_fips[panel$control_state]), "\n\n")

# Pre/post summary for low-wage industries
cat("Separation rates by group and wage level (pre vs post):\n")
summ <- panel %>%
  filter(group %in% c("Treated", "Control (Fed Min)")) %>%
  mutate(period = ifelse(post_increase | (!treated_state & year >= 2010), "Post", "Pre")) %>%
  group_by(group, low_wage, period) %>%
  summarise(
    mean_sep_rate = mean(sep_rate, na.rm = TRUE),
    mean_earn = mean(EarnS, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  )
print(summ)

saveRDS(panel, "../data/panel.rds")
cat("\nSaved panel.rds\n")
