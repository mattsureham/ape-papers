# ==============================================================================
# 04_robustness.R — Robustness Checks
# The Credential Cliff: Multi-Cutoff RDD on South Africa Matric Pass Levels
# ==============================================================================

source("00_packages.R")

data_dir <- "../data/"

# Load data
qlfs <- fread(file.path(data_dir, "qlfs_clean.csv"))
pto <- fread(file.path(data_dir, "pass_type_clean.csv"))
prov <- fread(file.path(data_dir, "province_nsc_clean.csv"))
nsc <- fread(file.path(data_dir, "nsc_national.csv"))
wb <- fread(file.path(data_dir, "wb_panel_clean.csv"))

# ==============================================================================
# 1. TEMPORAL STABILITY — Are credential returns stable over time?
# ==============================================================================
cat("=== Robustness 1: Temporal Stability ===\n")

# Test if the credential gradient is stable across sub-periods
pto_early <- pto %>% filter(year >= 2014 & year <= 2016)
pto_mid <- pto %>% filter(year >= 2017 & year <= 2019)
pto_late <- pto %>% filter(year >= 2020 & year <= 2022)

compute_gradient <- function(df, period_label) {
  df %>%
    group_by(credential_short, credential_order) %>%
    summarise(
      mean_absorption = mean(absorption),
      mean_log_earn = mean(log_earnings),
      .groups = "drop"
    ) %>%
    arrange(credential_order) %>%
    mutate(
      step_absorption = mean_absorption - lag(mean_absorption),
      step_log_earn = mean_log_earn - lag(mean_log_earn),
      period = period_label
    )
}

temporal_stability <- bind_rows(
  compute_gradient(pto_early, "2014-2016"),
  compute_gradient(pto_mid, "2017-2019"),
  compute_gradient(pto_late, "2020-2022")
)

cat("\nCredential steps by period:\n")
print(temporal_stability %>% filter(!is.na(step_absorption)))

fwrite(temporal_stability, file.path(data_dir, "temporal_stability.csv"))

# ==============================================================================
# 2. CROSS-COUNTRY PLACEBO — Is SA's credential return unusual?
# ==============================================================================
cat("\n=== Robustness 2: Cross-Country Comparison ===\n")

# Compare SA's education-employment gradient to other countries
# Using WB data: compute the "tertiary premium" (unemployment with advanced
# education vs total unemployment)

wb_premium <- wb %>%
  filter(year >= 2015 & year <= 2019) %>%
  group_by(country_code, country_name, is_south_africa) %>%
  summarise(
    mean_unemp = mean(unemployment, na.rm = TRUE),
    mean_youth_unemp = mean(youth_unemployment, na.rm = TRUE),
    mean_unemp_adv = mean(unemp_advanced, na.rm = TRUE),
    mean_tertiary = mean(tertiary_enroll, na.rm = TRUE),
    mean_gdp = mean(gdp_pc_ppp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(!is.na(mean_unemp) & !is.na(mean_unemp_adv)) %>%
  mutate(
    # Education premium = gap between general and advanced unemployment
    education_premium = mean_unemp - mean_unemp_adv,
    # Youth penalty = excess youth unemployment
    youth_penalty = mean_youth_unemp - mean_unemp
  )

cat("\nCross-country education premium (2015-2019):\n")
print(wb_premium %>% arrange(-education_premium))

# SA's premium relative to comparators
za_premium <- wb_premium %>% filter(country_code == "ZAF")
other_mean <- wb_premium %>% filter(country_code != "ZAF") %>%
  summarise(mean_prem = mean(education_premium, na.rm = TRUE))
cat("\nSA education premium:", round(za_premium$education_premium, 1), "pp")
cat("\nComparator mean:", round(other_mean$mean_prem, 1), "pp\n")

fwrite(wb_premium, file.path(data_dir, "cross_country_premium.csv"))

# ==============================================================================
# 3. PROVINCE HETEROGENEITY — Do returns vary by province?
# ==============================================================================
cat("\n=== Robustness 3: Province Heterogeneity ===\n")

# Province-level variation in credential access and outcomes
# Within-province trends in Bachelor's pass rate
prov_trends <- prov %>%
  group_by(province) %>%
  do({
    mod <- lm(bachelors_rate ~ year, data = .)
    data.frame(
      slope = coef(mod)[2],
      se = summary(mod)$coefficients[2, 2],
      r2 = summary(mod)$r.squared,
      mean_bach = mean(.$bachelors_rate),
      mean_pass = mean(.$pass_rate)
    )
  }) %>%
  ungroup() %>%
  arrange(-slope)

cat("\nProvince trends in Bachelor's pass rate (pp/year):\n")
print(prov_trends)

fwrite(prov_trends, file.path(data_dir, "province_trends.csv"))

# ==============================================================================
# 4. NSC COMPOSITION STABILITY — Is the credential mix changing?
# ==============================================================================
cat("\n=== Robustness 4: NSC Composition Changes ===\n")

# Track the share of each pass type over time
nsc_composition <- nsc %>%
  select(year, bachelors_rate, diploma_rate, higher_cert_rate, fail_rate) %>%
  mutate(
    bach_trend = (year - 2008) * NA,
    # Compute a simple trend
    bach_diff = bachelors_rate - lag(bachelors_rate),
    pass_diff = (100 - fail_rate) - lag(100 - fail_rate)
  )

# Trend test
nsc_trend_test <- lm(bachelors_rate ~ year, data = nsc)
cat("\nBachelor's pass rate trend (2008-2022):\n")
summary(nsc_trend_test)

fwrite(nsc_composition, file.path(data_dir, "nsc_composition.csv"))

# ==============================================================================
# 5. EARNINGS PREMIUM DECOMPOSITION — Within vs Between Credential
# ==============================================================================
cat("\n=== Robustness 5: Earnings Premium Decomposition ===\n")

# Decompose the total variance in earnings into:
# - Between-credential variation (the "cliff")
# - Within-credential over-time variation (growth)

pto_decomp <- pto %>%
  filter(year >= 2014 & year <= 2019)

total_var <- var(pto_decomp$log_earnings)
between_var <- var(tapply(pto_decomp$log_earnings, pto_decomp$credential_order, mean))
within_var <- mean(tapply(pto_decomp$log_earnings, pto_decomp$credential_order, var))

decomp <- data.frame(
  component = c("Total", "Between credential", "Within credential (over time)"),
  variance = c(total_var, between_var, within_var),
  share = c(1, between_var / total_var, within_var / total_var)
)

cat("\nEarnings variance decomposition:\n")
print(decomp)

fwrite(decomp, file.path(data_dir, "earnings_decomposition.csv"))

# ==============================================================================
# 6. PLACEBO TEST — Non-Matric Education Levels
# ==============================================================================
cat("\n=== Robustness 6: Placebo — Non-Matric Levels ===\n")

# The "cliff" should be largest between matric pass types and post-matric.
# It should be smaller between non-matric adjacent levels.
# This tests whether the credential effect is specific to matric thresholds.

qlfs_steps <- qlfs %>%
  filter(year >= 2014 & year <= 2019) %>%
  group_by(education_short, educ_order) %>%
  summarise(
    mean_abs = mean(absorption_rate),
    mean_unemp = mean(unemployment_rate),
    .groups = "drop"
  ) %>%
  arrange(educ_order) %>%
  mutate(
    step = mean_abs - lag(mean_abs),
    is_matric_step = educ_order %in% c(4, 5)  # Steps from matric to post-matric
  )

cat("\nEducation level steps (pp absorption rate):\n")
print(qlfs_steps)

# The matric→post-matric steps should be larger than sub-matric steps
matric_steps <- qlfs_steps %>% filter(is_matric_step)
other_steps <- qlfs_steps %>% filter(!is_matric_step & !is.na(step))

cat("\nMean matric-related step:", round(mean(matric_steps$step), 1), "pp")
cat("\nMean other steps:", round(mean(other_steps$step), 1), "pp\n")

fwrite(qlfs_steps, file.path(data_dir, "education_steps.csv"))

cat("\n=== Robustness checks complete ===\n")
