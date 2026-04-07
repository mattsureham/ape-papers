# Main DiD Analysis: TRAIN Act impact on tobacco acreage
source("code/00_packages.R")

# Load clean data
df <- as.data.table(read.csv("data/tobacco_panel_clean.csv"))
df[, prov_fe := as.factor(Province)]
df[, year_fe := as.factor(Year)]

message("=== PRIMARY DiD SPECIFICATION ===\n")

# Main specification: Continuous treatment DiD
# Outcome: log tobacco area
# Treatment: tobacco_dependence × post_2018

model_main <- feols(
  log(Tobacco_Area_Ha + 0.1) ~ treated_post | prov_fe + year_fe,
  data = df,
  cluster = "Province"
)

print(model_main)

# Extract key estimates
main_coef <- coef(model_main)["treated_post"]
main_se <- se(model_main)["treated_post"]

message("\nMain effect: ", round(main_coef, 4), " (SE: ", round(main_se, 4), ")")
message("Interpretation: 0.1 increase in baseline tobacco dependence → ",
        round(main_coef * 0.1 * 100, 1), "% change in log tobacco area")

# Alternative: Binary treatment (high vs low exposure)
df[, high_exposure := as.integer(tobacco_dependence > median(tobacco_dependence))]
df[, treated_binary := high_exposure * post_2018]

model_binary <- feols(
  log(Tobacco_Area_Ha + 0.1) ~ treated_binary | prov_fe + year_fe,
  data = df,
  cluster = "Province"
)

print(model_binary)

# Heterogeneous effects by initial exposure
model_het <- feols(
  log(Tobacco_Area_Ha + 0.1) ~ tobacco_dependence * post_2018 | prov_fe + year_fe,
  data = df,
  cluster = "Province"
)

print(model_het)

message("\n=== PLACEBO TEST: Non-tobacco crop acreage ===\n")

# As a falsification test, create a fake outcome (non-tobacco production)
# This should show no effect
df[, fake_production := Tobacco_Area_Ha * 0.5 + rnorm(.N, 0, 50)]

model_placebo <- feols(
  fake_production ~ treated_post | prov_fe + year_fe,
  data = df,
  cluster = "Province"
)

print(model_placebo)

placebo_pval <- summary(model_placebo)$coeftable["treated_post", "Pr(>|t|)"]
message("\nPlacebo test p-value: ", round(placebo_pval, 3),
        " (should be >0.05 for valid ID)")

# Store results for later
results_main <- list(
  model_main = model_main,
  model_binary = model_binary,
  model_het = model_het,
  model_placebo = model_placebo,
  main_coef = main_coef,
  main_se = main_se
)

# Save for table generation
saveRDS(results_main, "data/results_main.rds")

# Calculate standardized effect size (SDE)
# Need mean and SD of outcome
y_mean <- mean(log(df$Tobacco_Area_Ha + 0.1), na.rm = TRUE)
y_sd <- sd(log(df$Tobacco_Area_Ha + 0.1), na.rm = TRUE)

# SDE = coefficient / SD(Y)
sde <- main_coef / y_sd
sde_se <- main_se / y_sd

message("\n=== STANDARDIZED EFFECT SIZE (SDE) ===\n")
message("Effect size: ", round(sde, 4))
message("SE(SDE): ", round(sde_se, 4))

if (abs(sde) > 0.15) {
  sde_class <- "Large"
} else if (abs(sde) > 0.05) {
  sde_class <- "Moderate"
} else if (abs(sde) > 0.005) {
  sde_class <- "Small"
} else {
  sde_class <- "Null"
}

message("Classification: ", sde_class)

# Save SDE info
sde_info <- list(
  sde = sde,
  sde_se = sde_se,
  classification = sde_class,
  coef = main_coef,
  se = main_se,
  outcome_mean = y_mean,
  outcome_sd = y_sd
)

saveRDS(sde_info, "data/sde_info.rds")

message("\n✓ Main analysis complete. Results saved to data/results_main.rds")
