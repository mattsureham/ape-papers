# ==============================================================================
# 03_main_analysis.R — Main Analysis
# The Credential Cliff: Multi-Cutoff RDD on South Africa Matric Pass Levels
# ==============================================================================
# This script estimates:
# 1. The credential gradient in employment and earnings
# 2. Cross-country comparison of education returns
# 3. Province-level pass type → enrollment pipeline analysis
# 4. Formal multi-cutoff RDD framework estimation with aggregate data
# ==============================================================================

source("00_packages.R")

data_dir <- "../data/"

# Load cleaned data
wb <- fread(file.path(data_dir, "wb_panel_clean.csv"))
nsc <- fread(file.path(data_dir, "nsc_national.csv"))
nsc_long <- fread(file.path(data_dir, "nsc_long.csv"))
prov <- fread(file.path(data_dir, "province_nsc_clean.csv"))
qlfs <- fread(file.path(data_dir, "qlfs_clean.csv"))
pto <- fread(file.path(data_dir, "pass_type_clean.csv"))
nsc_tert <- fread(file.path(data_dir, "nsc_tertiary_merged.csv"))
za_ts <- fread(file.path(data_dir, "za_wb_timeseries.csv"))

# ==============================================================================
# 1. THE CREDENTIAL GRADIENT — Employment by Education Level
# ==============================================================================
cat("=== Analysis 1: Credential Gradient ===\n")

# Estimate the step-function relationship between education and employment
# Using QLFS aggregate data: absorption rate ~ education level

# Pre-COVID period (2014-2019) for stable estimates
qlfs_pre <- qlfs %>% filter(year <= 2019)

# Fixed effects regression: absorption = f(education) + year FE
qlfs_pre$educ_factor <- factor(qlfs_pre$educ_order)

# Level regression (no individual-level data, so OLS on cell means)
model_absorption <- feols(
  absorption_rate ~ educ_factor | year,
  data = qlfs_pre,
  cluster = ~year
)
cat("\nAbsorption rate by education level (ref: No schooling):\n")
summary(model_absorption)

# Unemployment regression
model_unemployment <- feols(
  unemployment_rate ~ educ_factor | year,
  data = qlfs_pre,
  cluster = ~year
)
cat("\nUnemployment rate by education level:\n")
summary(model_unemployment)

# Compute the "credential cliff" — difference between adjacent levels
gradient <- qlfs_pre %>%
  group_by(education, education_short, educ_order) %>%
  summarise(
    mean_absorption = mean(absorption_rate, na.rm = TRUE),
    sd_absorption = sd(absorption_rate, na.rm = TRUE),
    mean_unemp = mean(unemployment_rate, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(educ_order) %>%
  mutate(
    marginal_absorption = mean_absorption - lag(mean_absorption),
    marginal_unemp = mean_unemp - lag(mean_unemp)
  )

cat("\nCredential gradient (2014-2019 averages):\n")
print(gradient)

fwrite(gradient, file.path(data_dir, "credential_gradient.csv"))

# ==============================================================================
# 2. THE MATRIC PASS TYPE CLIFF — Returns Within Matric Credential
# ==============================================================================
cat("\n=== Analysis 2: Pass Type Returns ===\n")

# This is the key analysis — comparing outcomes across matric pass types
pto_pre <- pto %>% filter(year <= 2019)

# Model: absorption = f(credential type) + year FE
pto_pre$cred_factor <- factor(pto_pre$credential_order)

model_pass_absorption <- feols(
  absorption ~ cred_factor | year,
  data = pto_pre,
  cluster = ~year
)
cat("\nAbsorption rate by pass type (ref: Higher Certificate):\n")
summary(model_pass_absorption)

# Earnings model
model_pass_earnings <- feols(
  log_earnings ~ cred_factor | year,
  data = pto_pre,
  cluster = ~year
)
cat("\nLog earnings by pass type:\n")
summary(model_pass_earnings)

# Pass type gradient
pass_gradient <- pto_pre %>%
  group_by(credential_short, credential_order) %>%
  summarise(
    mean_absorption = mean(absorption, na.rm = TRUE),
    sd_absorption = sd(absorption, na.rm = TRUE),
    mean_earnings = mean(median_earnings, na.rm = TRUE),
    mean_log_earnings = mean(log_earnings, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(credential_order) %>%
  mutate(
    step_absorption = mean_absorption - lag(mean_absorption),
    step_log_earnings = mean_log_earnings - lag(mean_log_earnings),
    # Percentage increase in earnings
    pct_earnings_increase = (mean_earnings / lag(mean_earnings) - 1) * 100
  )

cat("\nPass type gradient (2014-2019 averages):\n")
print(pass_gradient)

fwrite(pass_gradient, file.path(data_dir, "pass_type_gradient.csv"))

# ==============================================================================
# 3. CROSS-COUNTRY COMPARISON — SA's Education-Employment Disconnect
# ==============================================================================
cat("\n=== Analysis 3: Cross-Country Comparison ===\n")

# Compare SA's unemployment rate to comparator countries, conditional on
# education expenditure and tertiary enrollment
wb_2019 <- wb %>%
  filter(year == 2019) %>%
  select(country_code, country_name, is_south_africa, region,
         unemployment, youth_unemployment, tertiary_enroll,
         gdp_pc_ppp, educ_expenditure) %>%
  filter(!is.na(unemployment))

# SA's position
za_2019 <- wb_2019 %>% filter(country_code %in% c("ZAF", "ZA"))
cat("\nSouth Africa 2019:\n")
cat("  Unemployment:", za_2019$unemployment, "%\n")
cat("  Youth unemployment:", za_2019$youth_unemployment, "%\n")
cat("  Tertiary enrollment:", za_2019$tertiary_enroll, "%\n")
cat("  GDP per capita (PPP):", format(za_2019$gdp_pc_ppp, big.mark = ","), "\n")

# Cross-country regression: unemployment ~ f(education system features)
model_xc <- lm(
  unemployment ~ tertiary_enroll + gdp_pc_ppp + educ_expenditure,
  data = wb_2019
)
cat("\nCross-country unemployment model (2019):\n")
summary(model_xc)

# SA's residual (unexplained unemployment)
if ("ZAF" %in% wb_2019$country_code) {
  za_residual <- residuals(model_xc)[wb_2019$country_code %in% c("ZAF", "ZA")]
  cat("\nSouth Africa residual unemployment:", round(za_residual, 1),
      "pp (above prediction)\n")
}

fwrite(wb_2019, file.path(data_dir, "cross_country_2019.csv"))

# ==============================================================================
# 4. PROVINCE-LEVEL ANALYSIS — Pass Type Composition and Outcomes
# ==============================================================================
cat("\n=== Analysis 4: Province-Level Pass Type Analysis ===\n")

# Merge province NSC data with province-level outcomes from World Bank
# (WB doesn't have province-level, so we use within-province variation over time)

# Panel regression: bachelors_rate ~ year FE + province FE
prov$province_factor <- factor(prov$province)

# Within-province trends in Bachelor's pass rate
model_prov_bach <- feols(
  bachelors_rate ~ year | province,
  data = prov,
  cluster = ~province
)
cat("\nProvince-level Bachelor's pass rate trend:\n")
summary(model_prov_bach)

# Province inequality in credential access
prov_inequality <- prov %>%
  group_by(year) %>%
  summarise(
    mean_bach = mean(bachelors_rate),
    sd_bach = sd(bachelors_rate),
    cv_bach = sd_bach / mean_bach,
    range_bach = max(bachelors_rate) - min(bachelors_rate),
    top_province = province[which.max(bachelors_rate)],
    bottom_province = province[which.min(bachelors_rate)],
    .groups = "drop"
  )

cat("\nProvince inequality in Bachelor's pass rates:\n")
print(prov_inequality)

fwrite(prov_inequality, file.path(data_dir, "province_inequality.csv"))

# ==============================================================================
# 5. NSC → TERTIARY PIPELINE — Transition Rates
# ==============================================================================
cat("\n=== Analysis 5: NSC to Tertiary Pipeline ===\n")

# How many Bachelor's pass holders actually enroll in university?
pipeline <- nsc_tert %>%
  filter(!is.na(transition_rate)) %>%
  select(year, bachelors_pass, first_time_ug, university_total,
         tvet_total, transition_rate, grad_rate)

cat("\nNSC → University pipeline:\n")
print(pipeline)

# Time trend in transition rate
model_transition <- lm(transition_rate ~ year, data = pipeline)
cat("\nTransition rate trend:\n")
summary(model_transition)

fwrite(pipeline, file.path(data_dir, "pipeline_analysis.csv"))

# ==============================================================================
# 6. AGGREGATE CREDENTIAL-STEP PARAMETER ESTIMATION — Using Aggregate Data
# ==============================================================================
cat("\n=== Analysis 6: Aggregate Credential-Step Parameter Estimation ===\n")

# Even without individual-level exam scores, we can estimate
# the aggregate difference in outcomes across credential tiers:
#
# At the Bachelor's cutoff (50%):
#   Y(Bachelor's) - Y(Diploma) = credential-step difference for university access
#
# At the Diploma cutoff (40%):
#   Y(Diploma) - Y(Higher Certificate) = credential-step difference for diploma access
#
# These are upper bounds on the causal credential effect because they
# compare AVERAGE outcomes across credential types, not outcomes
# at the MARGIN of the cutoff. They reflect aggregate credential-step
# differences, not regression discontinuity estimates.

# Compute pairwise comparisons using pass type outcomes
pto_avg <- pto %>%
  filter(year >= 2014 & year <= 2019) %>%
  group_by(credential_short, credential_order) %>%
  summarise(
    mean_absorption = mean(absorption),
    mean_earnings = mean(median_earnings),
    mean_log_earn = mean(log_earnings),
    n_years = n(),
    .groups = "drop"
  ) %>%
  arrange(credential_order)

# Bachelor's credential-step difference (Degree vs Diploma-eligible matric)
bach_effect_abs <- pto_avg$mean_absorption[4] - pto_avg$mean_absorption[2]
bach_effect_earn <- pto_avg$mean_log_earn[4] - pto_avg$mean_log_earn[2]

# Diploma credential-step difference (Post-school diploma vs Higher Certificate matric)
dip_effect_abs <- pto_avg$mean_absorption[3] - pto_avg$mean_absorption[1]
dip_effect_earn <- pto_avg$mean_log_earn[3] - pto_avg$mean_log_earn[1]

# Within-matric credential-step difference (Diploma-eligible vs HC matric)
within_matric_abs <- pto_avg$mean_absorption[2] - pto_avg$mean_absorption[1]
within_matric_earn <- pto_avg$mean_log_earn[2] - pto_avg$mean_log_earn[1]

# NOTE: data frame name rdd_params retained for backward compatibility with
# downstream scripts (06_tables.R, etc.) — these are aggregate credential-step
# differences (upper bounds on causal effects), not RDD estimates.
rdd_params <- data.frame(
  cutoff = c(
    "Bachelor's (50%): Degree vs Diploma matric",
    "Diploma (40%): Post-school vs HC matric",
    "Within-matric: Diploma vs HC matric"
  ),
  absorption_diff_pp = c(bach_effect_abs, dip_effect_abs, within_matric_abs),
  log_earnings_diff = c(bach_effect_earn, dip_effect_earn, within_matric_earn),
  interpretation = c(
    "Aggregate credential-step difference (upper bound on causal effect at Bachelor's cutoff)",
    "Aggregate credential-step difference (upper bound on causal effect at Diploma cutoff)",
    "Aggregate within-matric credential-step difference"
  ),
  stringsAsFactors = FALSE
)

cat("\nAggregate credential-step differences (upper bounds on causal effects):\n")
print(rdd_params)

fwrite(rdd_params, file.path(data_dir, "rdd_parameters.csv"))

# ==============================================================================
# 7. COVID IMPACT ON CREDENTIAL RETURNS
# ==============================================================================
cat("\n=== Analysis 7: COVID Impact ===\n")

# Did COVID differentially affect credential returns?
covid_impact <- pto %>%
  mutate(period = case_when(
    year <= 2019 ~ "Pre-COVID (2014-2019)",
    year == 2020 ~ "COVID (2020)",
    year >= 2021 ~ "Post-COVID (2021-2022)"
  )) %>%
  group_by(credential_short, credential_order, period) %>%
  summarise(
    mean_absorption = mean(absorption),
    mean_earnings = mean(median_earnings),
    .groups = "drop"
  ) %>%
  arrange(credential_order, period) %>%
  pivot_wider(
    id_cols = c(credential_short, credential_order),
    names_from = period,
    values_from = c(mean_absorption, mean_earnings)
  )

cat("\nCOVID impact by credential type:\n")
print(covid_impact)

fwrite(as.data.frame(covid_impact), file.path(data_dir, "covid_impact.csv"))

# ==============================================================================
# 8. SUMMARY STATISTICS TABLE
# ==============================================================================
cat("\n=== Computing summary statistics ===\n")

# NSC summary
nsc_summary <- nsc %>%
  filter(year >= 2010 & year <= 2022) %>%
  summarise(
    across(c(total_wrote, total_passed, bachelors_pass, diploma_pass,
             higher_cert_pass, failed),
           list(mean = mean, sd = sd, min = min, max = max),
           .names = "{.col}_{.fn}")
  )

# QLFS summary
qlfs_summary <- qlfs %>%
  filter(year >= 2014 & year <= 2019) %>%
  group_by(education_short) %>%
  summarise(
    mean_absorption = mean(absorption_rate),
    sd_absorption = sd(absorption_rate),
    mean_unemp = mean(unemployment_rate),
    sd_unemp = sd(unemployment_rate),
    .groups = "drop"
  )

# Province summary
prov_summary <- prov %>%
  summarise(
    mean_pass = mean(pass_rate),
    sd_pass = sd(pass_rate),
    mean_bach = mean(bachelors_rate),
    sd_bach = sd(bachelors_rate),
    n_prov_years = n()
  )

# Save for table generation
fwrite(as.data.frame(nsc_summary), file.path(data_dir, "nsc_summary_stats.csv"))
fwrite(qlfs_summary, file.path(data_dir, "qlfs_summary_stats.csv"))
fwrite(as.data.frame(prov_summary), file.path(data_dir, "province_summary_stats.csv"))

cat("\n=== Main analysis complete ===\n")
