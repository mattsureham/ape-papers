## 04_robustness.R — Robustness checks
## APEP apep_0831: Section 232 Tariffs and the Racial Wage Gap

source("00_packages.R")

df <- readRDS("../data/analysis.rds")
reg_df <- df %>%
  filter(!is.na(log_earn) & is.finite(log_earn)) %>%
  mutate(race_yq = paste0(race, "_", yq))

cat("=== Robustness Checks ===\n")

## ========================================================
## R1: Drop small counties (< 100 mfg workers)
## ========================================================
cat("\n--- R1: Drop counties with < 100 manufacturing workers ---\n")

m_large <- feols(
  log_earn ~ post_exposure + post_exposure_black | county_race + race_yq,
  data = reg_df %>% filter(emp_mfg >= 100),
  cluster = ~state_fips
)
cat("Large counties only:\n")
print(summary(m_large))

## ========================================================
## R2: Tighter pre-COVID window (stop at 2019Q4)
## ========================================================
cat("\n--- R2: Stop at 2019Q4 ---\n")

m_tight <- feols(
  log_earn ~ post_exposure + post_exposure_black | county_race + race_yq,
  data = reg_df %>% filter(year <= 2019),
  cluster = ~state_fips
)
cat("Tight window (through 2019Q4):\n")
print(summary(m_tight))

## ========================================================
## R3: Placebo — non-manufacturing sectors in same counties
## ========================================================
cat("\n--- R3: Placebo test with non-manufacturing ---\n")

qwi_all <- readRDS("../data/qwi_manufacturing.rds")
treatment <- readRDS("../data/treatment_exposure.rds")

## Non-manufacturing sectors: retail (44-45), professional services (54),
## accommodation/food (72), wholesale (42)
placebo_sectors <- c("42", "44-45", "54", "72")

placebo_df <- qwi_all %>%
  filter(industry %in% placebo_sectors) %>%
  mutate(
    fips = sprintf("%05d", geography),
    state_fips = substr(fips, 1, 2),
    yq = paste0(year, "Q", quarter),
    post = as.integer(year > 2018 | (year == 2018 & quarter >= 2)),
    log_earn = ifelse(!is.na(earn) & earn > 0, log(earn), NA_real_),
    black = as.integer(race == "A2")
  ) %>%
  filter(!(year == 2020 & quarter >= 2)) %>%
  left_join(treatment %>% select(fips, exposure), by = "fips") %>%
  filter(!is.na(exposure)) %>%
  mutate(
    post_exposure = post * exposure,
    post_black = post * black,
    post_exposure_black = post * exposure * black,
    county_race = paste0(fips, "_", race),
    race_yq = paste0(race, "_", yq)
  ) %>%
  filter(!is.na(log_earn) & is.finite(log_earn))

cat(sprintf("Placebo sample: %s rows\n", format(nrow(placebo_df), big.mark = ",")))

m_placebo <- feols(
  log_earn ~ post_exposure + post_exposure_black | county_race + race_yq,
  data = placebo_df,
  cluster = ~state_fips
)
cat("Placebo (non-manufacturing):\n")
print(summary(m_placebo))

## ========================================================
## R4: Binary treatment (high vs low exposure)
## ========================================================
cat("\n--- R4: Binary treatment ---\n")

reg_df <- reg_df %>%
  mutate(
    post_high = post * high_exposure,
    post_high_black = post * high_exposure * black
  )

m_binary <- feols(
  log_earn ~ post_high + post_high_black | county_race + race_yq,
  data = reg_df,
  cluster = ~state_fips
)
cat("Binary treatment:\n")
print(summary(m_binary))

## ========================================================
## R5: Dose-response by exposure quartile
## ========================================================
cat("\n--- R5: Dose-response by exposure quartile ---\n")

reg_df <- reg_df %>%
  mutate(
    exposure_q_fac = factor(exposure_q),
    post_black = post * black
  )

m_dose <- feols(
  log_earn ~ i(exposure_q_fac, post_black, ref = 0) +
    i(exposure_q_fac, post, ref = 0) |
    county_race + race_yq,
  data = reg_df,
  cluster = ~state_fips
)
cat("Dose-response:\n")
print(summary(m_dose))

## ========================================================
## Save robustness models
## ========================================================
robustness_models <- list(
  m_large = m_large,
  m_tight = m_tight,
  m_placebo = m_placebo,
  m_binary = m_binary,
  m_dose = m_dose
)
saveRDS(robustness_models, "../data/robustness_models.rds")

cat("\nAll robustness checks completed.\n")
