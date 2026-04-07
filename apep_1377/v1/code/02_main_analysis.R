# Main analysis: Continuous-treatment DiD
source("00_packages.R")

cat("\n=== MAIN ANALYSIS ===\n")

# Load analysis data
analysis_data <- readRDS("../data/analysis_data.rds")

# Create numeric wave variable for regression
analysis_data <- analysis_data %>%
  mutate(
    wave_num = as.numeric(wave),
    state_str = as.character(state),
    disco_str = as.character(disco),
    hh_id_str = as.character(hh_id)
  )

cat("Sample:", nrow(analysis_data), "observations from", n_distinct(analysis_data$hh_id), "households\n")

# ============================================================================
# 1. Main Outcome: Electricity Hours per Week
# ============================================================================
cat("\n--- Outcome 1: Electricity Hours per Week ---\n")

# Specification 1: HH FE + Wave FE with treatment intensity
mod1_hours <- feols(
  electricity_hours ~
    treatment | hh_id + wave,
  data = analysis_data,
  vcov = ~state_str  # Cluster at state level (11 DisCos / 37 states)
)

cat("Treatment effect (collection efficiency × post_2013):\n")
print(summary(mod1_hours, vcov = "hetero"))

# Store for reporting
coef_hours <- coef(mod1_hours)["treatment"]
se_hours <- sqrt(diag(vcov(mod1_hours, type = "hetero")))["treatment"]

cat("  β̂ =", round(coef_hours, 3), ",  SE =", round(se_hours, 3), "\n")

# ============================================================================
# 2. Employment
# ============================================================================
cat("\n--- Outcome 2: Employment (Binary) ---\n")

mod1_emp <- feols(
  employment ~
    treatment | hh_id + wave,
  data = analysis_data,
  vcov = ~state_str
)

print(summary(mod1_emp, vcov = "hetero"))

coef_emp <- coef(mod1_emp)["treatment"]
se_emp <- sqrt(diag(vcov(mod1_emp, type = "hetero")))["treatment"]

cat("  β̂ =", round(coef_emp, 4), ",  SE =", round(se_emp, 4), "\n")

# ============================================================================
# 3. Non-Farm Enterprise
# ============================================================================
cat("\n--- Outcome 3: Non-Farm Enterprise ---\n")

mod1_ent <- feols(
  enterprise ~
    treatment | hh_id + wave,
  data = analysis_data,
  vcov = ~state_str
)

print(summary(mod1_ent, vcov = "hetero"))

coef_ent <- coef(mod1_ent)["treatment"]
se_ent <- sqrt(diag(vcov(mod1_ent, type = "hetero")))["treatment"]

cat("  β̂ =", round(coef_ent, 4), ",  SE =", round(se_ent, 4), "\n")

# ============================================================================
# 4. Study Hours (Children)
# ============================================================================
cat("\n--- Outcome 4: Study Hours per Week (Children) ---\n")

mod1_study <- feols(
  study_hours ~
    treatment | hh_id + wave,
  data = analysis_data,
  vcov = ~state_str
)

print(summary(mod1_study, vcov = "hetero"))

coef_study <- coef(mod1_study)["treatment"]
se_study <- sqrt(diag(vcov(mod1_study, type = "hetero")))["treatment"]

cat("  β̂ =", round(coef_study, 3), ",  SE =", round(se_study, 3), "\n")

# ============================================================================
# 5. Energy Expenditure Share
# ============================================================================
cat("\n--- Outcome 5: Energy Expenditure Share (%) ---\n")

mod1_enexp <- feols(
  energy_expend_share ~
    treatment | hh_id + wave,
  data = analysis_data,
  vcov = ~state_str
)

print(summary(mod1_enexp, vcov = "hetero"))

coef_enexp <- coef(mod1_enexp)["treatment"]
se_enexp <- sqrt(diag(vcov(mod1_enexp, type = "hetero")))["treatment"]

cat("  β̂ =", round(coef_enexp, 3), ",  SE =", round(se_enexp, 3), "\n")

# ============================================================================
# Pre-trends test: Pre-2013 only
# ============================================================================
cat("\n--- Pre-Trends Test (2010-2012 only) ---\n")

analysis_data_pre <- analysis_data %>%
  filter(wave <= 2012) %>%
  mutate(fake_post_2012 = as.numeric(wave >= 2012),
         fake_treatment = fake_post_2012 * (collection_efficiency / 100))

# Since there's no real "post" in pre-period, use a fake cutoff at 2012
mod_pretrend <- feols(
  electricity_hours ~
    fake_treatment | hh_id + wave,
  data = analysis_data_pre,
  vcov = ~state_str
)

cat("Pre-trend coefficient (fake cutoff at 2012, should be ~zero if parallel trends hold):\n")
print(summary(mod_pretrend, vcov = "hetero"))

coef_pretrend <- coef(mod_pretrend)["fake_treatment"]
se_pretrend <- sqrt(diag(vcov(mod_pretrend, type = "hetero")))["fake_treatment"]

cat("  β̂ =", round(coef_pretrend, 3), ",  SE =", round(se_pretrend, 3), "\n")

# ============================================================================
# Calculate standardized effect sizes (SDE)
# ============================================================================
cat("\n--- Standardized Effect Sizes ---\n")

# SDE = β̂ / SD(Y) for primary outcome
sd_hours <- sd(analysis_data$electricity_hours, na.rm = TRUE)
sd_emp <- sd(analysis_data$employment, na.rm = TRUE)
sd_ent <- sd(analysis_data$enterprise, na.rm = TRUE)
sd_study <- sd(analysis_data$study_hours, na.rm = TRUE)
sd_enexp <- sd(analysis_data$energy_expend_share, na.rm = TRUE)

sde_hours <- coef_hours / sd_hours
sde_emp <- coef_emp / sd_emp
sde_ent <- coef_ent / sd_ent
sde_study <- coef_study / sd_study
sde_enexp <- coef_enexp / sd_enexp

cat("Hours per week: β̂ =", round(coef_hours, 3), " | SD =", round(sd_hours, 3),
    " | SDE =", round(sde_hours, 4), "\n")
cat("Employment: β̂ =", round(coef_emp, 4), " | SD =", round(sd_emp, 3),
    " | SDE =", round(sde_emp, 4), "\n")
cat("Enterprise: β̂ =", round(coef_ent, 4), " | SD =", round(sd_ent, 3),
    " | SDE =", round(sde_ent, 4), "\n")
cat("Study hours: β̂ =", round(coef_study, 3), " | SD =", round(sd_study, 3),
    " | SDE =", round(sde_study, 4), "\n")
cat("Energy expend: β̂ =", round(coef_enexp, 3), " | SD =", round(sd_enexp, 3),
    " | SDE =", round(sde_enexp, 4), "\n")

# ============================================================================
# Save results and diagnostics
# ============================================================================

results_summary <- tibble(
  outcome = c("Electricity hours/week", "Employment", "Enterprise", "Study hours", "Energy expend share"),
  estimate = c(coef_hours, coef_emp, coef_ent, coef_study, coef_enexp),
  se = c(se_hours, se_emp, se_ent, se_study, se_enexp),
  sd_y = c(sd_hours, sd_emp, sd_ent, sd_study, sd_enexp),
  sde = c(sde_hours, sde_emp, sde_ent, sde_study, sde_enexp)
)

write_csv(results_summary, "../data/results_summary.csv")

# Save diagnostics JSON
diagnostics <- list(
  n_treated = n_distinct(analysis_data$disco),
  n_pre = length(unique(analysis_data$wave[analysis_data$wave < 2013])),
  n_obs = nrow(analysis_data),
  n_households = n_distinct(analysis_data$hh_id),
  n_states = n_distinct(analysis_data$state),
  n_waves = n_distinct(analysis_data$wave),
  mean_electricity_hours = mean(analysis_data$electricity_hours, na.rm = TRUE),
  mean_collection_efficiency = mean(analysis_data$collection_efficiency, na.rm = TRUE),
  treatment_effect_hours = coef_hours,
  sde_primary = sde_hours
)

write_json(diagnostics, "../data/diagnostics.json", pretty = TRUE, auto_unbox = TRUE)

cat("\n✓ Main analysis complete\n")
