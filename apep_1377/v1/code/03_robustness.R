# Robustness checks
source("00_packages.R")

cat("\n=== ROBUSTNESS CHECKS ===\n")

analysis_data <- readRDS("../data/analysis_data.rds")
analysis_data <- analysis_data %>%
  mutate(
    wave_num = as.numeric(wave),
    state_str = as.character(state),
    disco_str = as.character(disco),
    hh_id_str = as.character(hh_id)
  )

# ============================================================================
# 1. Heterogeneous effects by DisCo quality
# ============================================================================
cat("\n--- Heterogeneous Effects by DisCo Quality ---\n")

# Split sample by pre-2013 DisCo efficiency (median)
disco_pre <- analysis_data %>%
  filter(wave <= 2012) %>%
  group_by(disco) %>%
  summarise(pre_eff = mean(collection_efficiency, na.rm = TRUE)) %>%
  mutate(high_eff = pre_eff > median(pre_eff))

analysis_data <- analysis_data %>%
  left_join(select(disco_pre, disco, high_eff), by = "disco")

# High efficiency DisCos
mod_het_high <- feols(
  electricity_hours ~
    treatment | hh_id + wave,
  data = filter(analysis_data, high_eff == TRUE),
  vcov = ~state_str
)

cat("High pre-reform efficiency DisCos:\n")
print(summary(mod_het_high, vcov = "hetero"))

# Low efficiency DisCos
mod_het_low <- feols(
  electricity_hours ~
    treatment | hh_id + wave,
  data = filter(analysis_data, high_eff == FALSE),
  vcov = ~state_str
)

cat("\nLow pre-reform efficiency DisCos:\n")
print(summary(mod_het_low, vcov = "hetero"))

# ============================================================================
# 2. Heterogeneous effects by Urban/Rural
# ============================================================================
cat("\n--- Heterogeneous Effects by Urban/Rural ---\n")

mod_het_urban <- feols(
  electricity_hours ~
    treatment | hh_id + wave,
  data = filter(analysis_data, urban == TRUE),
  vcov = ~state_str
)

cat("Urban areas:\n")
print(summary(mod_het_urban, vcov = "hetero"))

mod_het_rural <- feols(
  electricity_hours ~
    treatment | hh_id + wave,
  data = filter(analysis_data, urban == FALSE),
  vcov = ~state_str
)

cat("\nRural areas:\n")
print(summary(mod_het_rural, vcov = "hetero"))

# ============================================================================
# 3. Event Study: Dynamic treatment effects
# ============================================================================
cat("\n--- Event Study / Dynamic Treatment ---\n")

analysis_data <- analysis_data %>%
  mutate(
    time_to_reform = case_when(
      wave == 2010 ~ -3,
      wave == 2012 ~ -1,
      wave == 2015 ~ 2,
      wave == 2018 ~ 5,
      wave == 2023 ~ 10,
      TRUE ~ NA_real_
    ),
    post_2015 = as.numeric(wave >= 2015),
    post_2018 = as.numeric(wave >= 2018),
    post_2023 = as.numeric(wave >= 2023)
  )

# Dynamic treatment (separate effects for each post period)
analysis_data <- analysis_data %>%
  mutate(
    eff_post_2015 = (collection_efficiency/100) * post_2015,
    eff_post_2018 = (collection_efficiency/100) * post_2018,
    eff_post_2023 = (collection_efficiency/100) * post_2023
  )

mod_event <- feols(
  electricity_hours ~
    eff_post_2015 + eff_post_2018 + eff_post_2023 |
    hh_id + wave,
  data = analysis_data,
  vcov = ~state_str
)

cat("Event study coefficients (by post-reform period):\n")
print(summary(mod_event, vcov = "hetero"))

# ============================================================================
# 4. Subgroup by household size
# ============================================================================
cat("\n--- Effects by Household Size ---\n")

analysis_data <- analysis_data %>%
  mutate(large_hh = hh_size >= 6)

mod_large <- feols(
  electricity_hours ~
    treatment | hh_id + wave,
  data = filter(analysis_data, large_hh == TRUE),
  vcov = ~state_str
)

cat("Large households (6+ members):\n")
print(summary(mod_large, vcov = "hetero"))

mod_small <- feols(
  electricity_hours ~
    treatment | hh_id + wave,
  data = filter(analysis_data, large_hh == FALSE),
  vcov = ~state_str
)

cat("\nSmall households (<6 members):\n")
print(summary(mod_small, vcov = "hetero"))

# ============================================================================
# 5. Placebo test: Other post-periods (fake reform)
# ============================================================================
cat("\n--- Placebo Test: Fake Reform in 2010 ---\n")

analysis_data_placebo <- analysis_data %>%
  mutate(
    fake_post = as.numeric(wave >= 2012),
    fake_treatment = fake_post * (collection_efficiency / 100)
  )

mod_placebo <- feols(
  electricity_hours ~
    fake_treatment | hh_id + wave,
  data = filter(analysis_data_placebo, wave <= 2015),
  vcov = ~state_str
)

cat("Placebo coefficient (should be ~zero):\n")
print(summary(mod_placebo, vcov = "hetero"))

cat("\n✓ Robustness checks complete\n")
