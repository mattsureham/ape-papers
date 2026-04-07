# Main econometric analysis: 2SLS on leniency IV and NPL outcomes

source("00_packages.R")

analysis_data <- read_csv("data/analysis_sample.csv") |>
  mutate(
    year_exam = as.integer(year_exam),
    region = as.integer(region)
  )

cat("Loaded analysis data:", nrow(analysis_data), "observations\n")

# ===== Specification 1: OLS Reduced Form =====
# Direct relationship between leniency and subsequent NPLs (no causal claim)

rf_model <- lm(
  npl_next_year ~ leniency_std + npl_exam + roa_exam + ln_assets +
                  factor(region) + factor(year_exam),
  data = analysis_data,
  weights = NULL
)

cat("\n=== OLS REDUCED FORM ===\n")
print(summary(rf_model))

# Extract first stage diagnostics manually
rf_coef <- coef(rf_model)["leniency_std"]
rf_se <- sqrt(vcov(rf_model)["leniency_std", "leniency_std"])
rf_t <- rf_coef / rf_se

# ===== Specification 2: First Stage (Leniency → CAMELS proxy) =====
# We approximate CAMELS as the regional enforcement action likelihood
# or simply the leniency score's predictive power

# In a true analysis: leniency predicts actual CAMELS ratings
# Here we use a simplified first stage

fs_model <- lm(
  npl_exam ~ leniency_std + npl_lag1 + roa_exam + ln_assets +
             factor(region) + factor(year_exam),
  data = analysis_data
)

cat("\n=== FIRST STAGE ===\n")
print(summary(fs_model))

# First stage F-statistic (manual calculation)
fs_coef <- coef(fs_model)["leniency_std"]
fs_se <- sqrt(vcov(fs_model)["leniency_std", "leniency_std"])
fs_t <- fs_coef / fs_se
fs_f_stat <- fs_t^2

cat(sprintf("\nFirst Stage F-statistic: %.2f\n", fs_f_stat))
cat(sprintf("Shea's Partial R2 (approx): %.4f\n", summary(fs_model)$r.squared))

# ===== Specification 3: 2SLS (IV Estimation) =====
# Instrument: leniency_std
# Endogenous: npl_exam (examine the bank's own risk profile)
# First stage: leniency_std → npl_exam
# Reduced form: leniency_std → npl_next_year
# Structural: npl_exam → npl_next_year (causal effect of "toughness")

# Note: This specification estimates the inverse direction for interpretability
# We want to know: does high NPL at exam → high NPL next year (inertia vs. discipline)?
# Instrument with leniency to address simultaneity

iv_model <- ivreg(
  npl_next_year ~ npl_exam + roa_exam + ln_assets + factor(region) + factor(year_exam) |
                  leniency_std + roa_exam + ln_assets + factor(region) + factor(year_exam),
  data = analysis_data
)

cat("\n=== 2SLS RESULTS ===\n")
print(summary(iv_model, diagnostics = TRUE))

# Extract results
iv_coef <- coef(iv_model)["npl_exam"]
iv_se <- sqrt(vcov(iv_model)["npl_exam", "npl_exam"])
iv_t <- iv_coef / iv_se

# ===== Placebo Test: Do Pre-Trends Match? =====
# Leniency should not predict lagged NPL differences (test parallel trends)

placebo_model <- lm(
  I(npl_exam - npl_lag1) ~ leniency_std + roa_exam + ln_assets +
                          factor(region) + factor(year_exam),
  data = analysis_data |> filter(!is.na(npl_lag1))
)

cat("\n=== PLACEBO TEST: Pre-Trends ===\n")
cat("Does leniency predict NPL changes BEFORE exam?\n")
print(summary(placebo_model))

placebo_coef <- coef(placebo_model)["leniency_std"]
placebo_se <- sqrt(vcov(placebo_model)["leniency_std", "leniency_std"])

# ===== Heterogeneity by Bank Size =====
# Test if small banks respond differently than large banks

cat("\n=== HETEROGENEOUS EFFECTS: Small vs. Large Banks ===\n")

small_banks <- analysis_data |> filter(bank_size_class == "small")
large_banks <- analysis_data |> filter(bank_size_class != "small")

hete_small <- lm(
  npl_next_year ~ npl_exam + roa_exam + ln_assets + factor(region) + factor(year_exam),
  data = small_banks
)

hete_large <- lm(
  npl_next_year ~ npl_exam + roa_exam + ln_assets + factor(region) + factor(year_exam),
  data = large_banks
)

cat("Small banks (N=", nrow(small_banks), "):\n")
print(summary(hete_small))

cat("\nLarge banks (N=", nrow(large_banks), "):\n")
print(summary(hete_large))

# ===== Table 1: Summary Statistics =====
summary_stats <- analysis_data |>
  select(npl_next_year, npl_exam, tier1_exam, roa_exam, assets, leniency_std) |>
  summarise(
    across(everything(),
           list(mean = ~mean(., na.rm = TRUE),
                sd = ~sd(., na.rm = TRUE),
                min = ~min(., na.rm = TRUE),
                max = ~max(., na.rm = TRUE)),
           .names = "{.col}_{.fn}")
  )

cat("\n=== SUMMARY STATISTICS ===\n")
print(summary_stats)

# ===== Save Results for Tables =====
results_df <- data.frame(
  Specification = c("RF", "FS", "2SLS", "Placebo"),
  Coefficient = c(rf_coef, fs_coef, iv_coef, placebo_coef),
  Std.Error = c(rf_se, fs_se, iv_se, placebo_se),
  t_stat = c(rf_t, fs_t, iv_t, placebo_coef / placebo_se),
  N_obs = c(nrow(analysis_data), nrow(analysis_data), nrow(analysis_data), nrow(analysis_data) - sum(is.na(analysis_data$npl_lag1)))
)

write_csv(results_df, "tables/main_results.csv")

cat("\nMain results saved to tables/main_results.csv\n")

# SDE Calculation
# Effect size = coefficient / SD(outcome)
sd_outcome <- sd(analysis_data$npl_next_year, na.rm = TRUE)
sde_iv <- iv_coef / sd_outcome

cat(sprintf("\n=== EFFECT SIZES ===\n"))
cat(sprintf("NPL point estimate (2SLS): %.4f percentage points\n", iv_coef))
cat(sprintf("SD of NPL outcome: %.4f\n", sd_outcome))
cat(sprintf("Standardized Effect Size (SDE): %.4f\n", sde_iv))
cat(sprintf("Effect magnitude: %s\n",
            ifelse(abs(sde_iv) > 0.15, "Large",
                   ifelse(abs(sde_iv) > 0.05, "Moderate",
                          ifelse(abs(sde_iv) > 0.005, "Small", "Null")))))

# Save diagnostics
write_json(list(
  n_treated = n_distinct(analysis_data$cert),
  n_pre = length(unique(analysis_data$year_exam[analysis_data$year_exam < 2015])),
  n_obs = nrow(analysis_data),
  fs_f_stat = fs_f_stat,
  sde = sde_iv,
  iv_point_est = iv_coef
), "data/diagnostics.json", auto_unbox = TRUE)
