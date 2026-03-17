## 04_robustness.R — Robustness checks for apep_0714
## Marijuana Expungement × Black Employment DDD

source("code/00_packages.R")

df <- readRDS("data/qwi_analysis.rds")
models <- readRDS("data/models.rds")

# ============================================================
# 1. ROBUSTNESS TABLE 1: ALTERNATIVE SAMPLES
# ============================================================

cat("=== ROBUSTNESS: ALTERNATIVE SAMPLES ===\n")

# R1: Full sample (include never-legalized states as additional controls)
df_full <- df %>%
  filter(!is.na(log_emp_black)) %>%
  mutate(state_year_fe = paste0(state_fips, "_", year))

rob1_emp <- feols(
  log_emp_black ~ expunge_state:post_expunge + legal_state:post_legal
                  | county_fips + state_year_fe,
  data = df_full,
  cluster = ~state_fips
)

rob1_earn <- feols(
  log_earn_black ~ expunge_state:post_expunge + legal_state:post_legal
                   | county_fips + state_year_fe,
  data = df_full %>% filter(!is.na(log_earn_black)),
  cluster = ~state_fips
)

cat("R1 (full sample, employment):\n")
print(coeftable(rob1_emp)[1,])
cat("R1 (full sample, earnings):\n")
print(coeftable(rob1_earn)[1,])

# R2: Drop border counties (robustness to cross-border sorting)
# Get border counties by state
border_counties <- c(
  # CA-AZ, CA-NV, CA-OR border counties
  "06025", "06027", "06039", "06049", "06093",
  # IL-WI, IL-IN, IL-MO, IL-KY border counties
  "17031", "17093", "17097", "17099", "17133", "17163", "17199",
  # NJ-NY, NJ-PA border counties
  "34017", "34023", "34027", "34039"
)

df_noborder <- df %>%
  filter(group %in% c("expunge", "legalize_only")) %>%
  filter(!county_fips %in% border_counties) %>%
  filter(!is.na(log_earn_black)) %>%
  mutate(state_year_fe = paste0(state_fips, "_", year))

rob2_earn <- feols(
  log_earn_black ~ expunge_state:post_expunge + legal_state:post_legal
                   | county_fips + state_year_fe,
  data = df_noborder,
  cluster = ~state_fips
)

cat("R2 (drop border counties, earnings):\n")
print(coeftable(rob2_earn)[1,])

# R3: Exclude California (largest expunge state, might dominate)
df_noca <- df %>%
  filter(group %in% c("expunge", "legalize_only")) %>%
  filter(state_fips != "06") %>%
  filter(!is.na(log_earn_black)) %>%
  mutate(state_year_fe = paste0(state_fips, "_", year))

rob3_earn <- feols(
  log_earn_black ~ expunge_state:post_expunge + legal_state:post_legal
                   | county_fips + state_year_fe,
  data = df_noca,
  cluster = ~state_fips
)

cat("R3 (exclude CA, earnings):\n")
print(coeftable(rob3_earn)[1,])

# R4: Pre-2020 sample (avoid COVID confounding)
df_precovid <- df %>%
  filter(group %in% c("expunge", "legalize_only")) %>%
  filter(year <= 2019) %>%
  filter(!is.na(log_earn_black)) %>%
  mutate(state_year_fe = paste0(state_fips, "_", year))

rob4_earn <- feols(
  log_earn_black ~ expunge_state:post_expunge + legal_state:post_legal
                   | county_fips + state_year_fe,
  data = df_precovid,
  cluster = ~state_fips
)

cat("R4 (pre-COVID, 2013-2019, earnings):\n")
print(coeftable(rob4_earn)[1,])

# ============================================================
# 2. PLACEBO TEST: White earnings (should show no/smaller effect)
# ============================================================

cat("\n=== PLACEBO: WHITE EARNINGS ===\n")

df_clean_earn <- df %>%
  filter(group %in% c("expunge", "legalize_only")) %>%
  filter(!is.na(log_earn_white)) %>%
  mutate(state_year_fe = paste0(state_fips, "_", year))

placebo_white_earn <- feols(
  log_earn_white ~ expunge_state:post_expunge + legal_state:post_legal
                   | county_fips + state_year_fe,
  data = df_clean_earn,
  cluster = ~state_fips
)

cat("Placebo: White earnings (should be much smaller than Black):\n")
print(coeftable(placebo_white_earn))

# ============================================================
# 3. PLACEBO: Manufacturing (sector with less background-check screening)
# ============================================================
# Note: using all-industry QWI so we can only do this at state-level

cat("\n=== PLACEBO: STATE-YEAR VARIATION ===\n")
# Test: does expungement affect overall state-level employment composition?
# We'd expect: more high-wage employment (positive earnings) without big employment gains

df_state_earn <- df %>%
  filter(!is.na(log_earn_black)) %>%
  group_by(state_fips, year, quarter, group, expunge_state, legal_state, post_expunge, post_legal) %>%
  summarise(
    mean_earn_black = mean(earn_black, na.rm=TRUE),
    mean_emp_black = mean(emp_black, na.rm=TRUE),
    .groups = "drop"
  ) %>%
  filter(!is.na(mean_earn_black)) %>%
  mutate(
    log_earn_black = log(mean_earn_black),
    log_emp_black = log(mean_emp_black)
  )

state_rob <- feols(
  log_earn_black ~ expunge_state:post_expunge + legal_state:post_legal
                   | state_fips + year,
  data = df_state_earn %>% filter(group %in% c("expunge", "legalize_only")),
  cluster = ~state_fips
)

cat("State-level regression (earnings):\n")
print(coeftable(state_rob))

# ============================================================
# 3. ALTERNATIVE SPECIFICATION: State-level regression
# ============================================================

cat("\n=== STATE-LEVEL REGRESSION ===\n")

df_state <- df %>%
  filter(!is.na(log_earn_black)) %>%
  group_by(state_fips, year, quarter, group, expunge_state, legal_state, post_expunge, post_legal) %>%
  summarise(
    mean_log_earn_black = mean(log_earn_black, na.rm=TRUE),
    mean_log_emp_black = mean(log_emp_black, na.rm=TRUE),
    n_counties = n(),
    .groups = "drop"
  ) %>%
  mutate(state_year_fe = paste0(state_fips, "_", year))

state_earn <- feols(
  mean_log_earn_black ~ expunge_state:post_expunge + legal_state:post_legal
                        | state_fips + year + quarter,
  data = df_state %>% filter(group %in% c("expunge", "legalize_only")),
  cluster = ~state_fips
)

cat("State-level regression (earnings):\n")
print(coeftable(state_earn))

# Save all robustness objects
rob_list <- list(
  rob1_emp = rob1_emp,
  rob1_earn = rob1_earn,
  rob2_earn = rob2_earn,
  rob3_earn = rob3_earn,
  rob4_earn = rob4_earn,
  placebo_white_earn = placebo_white_earn,
  state_earn = state_earn
)
saveRDS(rob_list, "data/robustness_models.rds")

cat("\nRobustness checks complete.\n")
