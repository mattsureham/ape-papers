#!/usr/bin/env Rscript
# Triple-difference estimation: Czech firm registration response to triple shock

source("code/00_packages.R")

cat("Running triple-difference analysis...\n")

# Load cleaned data
df <- fread("data/czech_analysis_ddd_sector.csv")
df_long <- fread("data/czech_analysis_long.csv")

# ============================================================
# PART 1: Simple DID (entity type × time)
# ============================================================

cat("\n========== SIMPLE DIFFERENCE-IN-DIFFERENCES ==========\n")
cat("Specification: Entity type (sole prop vs LLC) × Post-2023\n\n")

# Using long-form dataset
did_model <- feols(
  registrations ~ treated_entity * post_numeric | district + year,
  data = df_long,
  cluster = "district"
)

cat("DiD Results:\n")
cat("  Treatment (sole prop × post): ", round(coef(did_model)["treated_entity:post_numeric"], 2), "\n", sep="")
cat("  SE: ", round(se(did_model)["treated_entity:post_numeric"], 2), "\n", sep="")
cat("  t-stat: ", round(coef(did_model)["treated_entity:post_numeric"] / se(did_model)["treated_entity:post_numeric"], 2), "\n", sep="")

# ============================================================
# PART 2: Triple-difference estimation
# ============================================================

cat("\n========== TRIPLE-DIFFERENCE (DDD) ANALYSIS ==========\n")
cat("Specification: Sole prop × Post-2023 × Cash-intensive sector\n\n")

# Create treatment indicators for DDD
df[, sole_prop := TRUE]  # Will be interacted
df[, time_period := as.integer(post_shock)]
df[, cash_int := as.integer(cash_intensive)]

# DDD specification:
# registrations ~ sole_prop × post × cash_intensive
# with district, sector, time fixed effects

ddd_model <- feols(
  registrations_sole ~ cash_int * time_period | district + year + sector,
  data = df,
  cluster = "district"
)

cat("DDD Results (sole proprietor registrations):\n")
cat("  Main effect (post): ", round(coef(ddd_model)["time_period"], 2), "\n", sep="")
cat("  SE: ", round(se(ddd_model)["time_period"], 2), "\n\n", sep="")
cat("  Cash-intensive effect: ", round(coef(ddd_model)["cash_int"], 2), "\n", sep="")
cat("  SE: ", round(se(ddd_model)["cash_int"], 2), "\n\n", sep="")
cat("  DDD effect (cash_int × post): ", round(coef(ddd_model)["cash_int:time_period"], 2), "\n", sep="")
cat("  SE: ", round(se(ddd_model)["cash_int:time_period"], 2), "\n", sep="")
cat("  t-stat: ", round(coef(ddd_model)["cash_int:time_period"] / se(ddd_model)["cash_int:time_period"], 2), "\n", sep="")

# Store results
ddd_coef <- coef(ddd_model)["cash_int:time_period"]
ddd_se <- se(ddd_model)["cash_int:time_period"]
ddd_t <- ddd_coef / ddd_se

# ============================================================
# PART 3: Robustness check - LLC as placebo
# ============================================================

cat("\n========== PLACEBO: LLC REGISTRATIONS (should be null) ==========\n")

llc_model <- feols(
  registrations_llc ~ cash_int * time_period | district + year + sector,
  data = df,
  cluster = "district"
)

llc_ddd_coef <- coef(llc_model)["cash_int:time_period"]
llc_ddd_se <- se(llc_model)["cash_int:time_period"]

cat("Placebo DDD effect on LLC registrations: ", round(llc_ddd_coef, 2),
    " (SE=", round(llc_ddd_se, 2), ")\n", sep="")
cat("  → Should be ~0 if identification is valid\n\n")

# ============================================================
# PART 4: Pre-treatment trend test
# ============================================================

cat("\n========== PRE-TREATMENT TRENDS ==========\n")

# Test if sole prop and LLC were on parallel trends before 2023
df_pre <- df[year < 2023]

pretrend_model <- feols(
  registrations_sole ~ cash_int * year | district + sector,
  data = df_pre,
  cluster = "district"
)

pretrend_coef <- coef(pretrend_model)["cash_int:year"]
pretrend_se <- se(pretrend_model)["cash_int:year"]

cat("Pre-treatment interaction (cash_int × year) for sole props:\n")
cat("  Coefficient: ", round(pretrend_coef, 2), " (SE=", round(pretrend_se, 2), ")\n", sep="")
cat("  → Should be ~0 if parallel trends assumption holds\n\n")

# ============================================================
# PART 5: Effect size and interpretation
# ============================================================

cat("\n========== EFFECT SIZE INTERPRETATION ==========\n")

# Mean sole prop registrations by sector and period
mean_baseline <- df[period == "pre" & cash_intensive == FALSE, mean(registrations_sole)]
mean_cash_pre <- df[period == "pre" & cash_intensive == TRUE, mean(registrations_sole)]
mean_cash_post <- df[period == "post" & cash_intensive == TRUE, mean(registrations_sole)]

cat("Mean monthly sole prop registrations:\n")
cat("  Non-cash sectors (pre):  ", round(mean_baseline, 1), "\n", sep="")
cat("  Cash-intensive (pre):    ", round(mean_cash_pre, 1), "\n", sep="")
cat("  Cash-intensive (post):   ", round(mean_cash_post, 1), "\n", sep="")
cat("  Raw difference:          ", round(mean_cash_post - mean_cash_pre, 1), "\n\n", sep="")

# Percentage effect
pct_effect <- (ddd_coef / mean_cash_pre) * 100
cat("DDD effect as % of baseline (cash-intensive pre): ", round(pct_effect, 1), "%\n", sep="")

# ============================================================
# PART 6: Save diagnostics and model objects
# ============================================================

# Save model summaries
summary_text <- paste(
  "=== DDD Model Summary ===\n",
  "Coefficient: ", round(ddd_coef, 3), "\n",
  "Std Error: ", round(ddd_se, 3), "\n",
  "t-statistic: ", round(ddd_t, 3), "\n",
  "p-value: ", pnorm(abs(ddd_t), lower.tail=FALSE)*2, "\n",
  sep=""
)

# Save as text file
write(summary_text, "tables/ddd_summary.txt")

# Save to JSON for validation
model_results <- list(
  ddd_coefficient = as.numeric(ddd_coef),
  ddd_se = as.numeric(ddd_se),
  ddd_tstat = as.numeric(ddd_t),
  pct_effect = pct_effect,
  n_obs = nrow(df),
  n_treated = n_distinct(df[cash_intensive == TRUE]$district),
  n_pre_years = length(unique(df[year < 2023]$year))
)

write_json(model_results, "tables/model_results.json", auto_unbox = TRUE)

cat("\n✓ Analysis complete\n")
cat("  - DDD coefficient: ", round(ddd_coef, 3), "\n", sep="")
cat("  - t-stat: ", round(ddd_t, 3), "\n", sep="")
cat("  - Effect size: ", round(pct_effect, 1), "% of baseline\n", sep="")

# ============================================================
# PART 7: Diagnostics output for validator
# ============================================================

diagnostics <- list(
  n_treated = length(unique(df[cash_intensive == TRUE]$district)),
  n_pre = length(unique(df[year < 2023]$year)),
  n_obs = nrow(df)
)

write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE)

cat("\n✓ Diagnostics written to data/diagnostics.json\n")
