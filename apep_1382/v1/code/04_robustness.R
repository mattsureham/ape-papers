#!/usr/bin/env Rscript
# Robustness checks for DDD specification

source("code/00_packages.R")

cat("Running robustness checks...\n\n")

# Load data
df <- fread("data/czech_analysis_ddd_sector.csv")

# ============================================================
# ROBUSTNESS 1: Urban vs Rural heterogeneity
# ============================================================

cat("========== ROBUSTNESS 1: Urban vs Rural Heterogeneity ==========\n")

df[, urban := district <= 40]

ddd_urban <- feols(
  registrations_sole ~ cash_int:time_period | district + year + sector,
  data = df[urban == TRUE],
  cluster = "district"
)

ddd_rural <- feols(
  registrations_sole ~ cash_int:time_period | district + year + sector,
  data = df[urban == FALSE],
  cluster = "district"
)

cat("DDD effect in urban districts: ", round(coef(ddd_urban)["cash_int:time_period"], 2), " (se=",
    round(se(ddd_urban)["cash_int:time_period"], 2), ")\n", sep="")
cat("DDD effect in rural districts: ", round(coef(ddd_rural)["cash_int:time_period"], 2), " (se=",
    round(se(ddd_rural)["cash_int:time_period"], 2), ")\n\n", sep="")

# ============================================================
# ROBUSTNESS 2: Alternative time windows
# ============================================================

cat("========== ROBUSTNESS 2: Alternative Treatment Windows ==========\n")

# Narrow window (2023 only, vs 2022)
df_narrow <- df[year %in% c(2022, 2023)]
ddd_narrow <- feols(
  registrations_sole ~ cash_int:time_period | district + year + sector,
  data = df_narrow,
  cluster = "district"
)

cat("DDD in narrow window (2022 vs 2023): ", round(coef(ddd_narrow)["cash_int:time_period"], 2),
    " (se=", round(se(ddd_narrow)["cash_int:time_period"], 2), ")\n\n", sep="")

# ============================================================
# ROBUSTNESS 3: Placebo tests (effect on LLCs)
# ============================================================

cat("========== ROBUSTNESS 3: Placebo - LLC Registrations ==========\n")

ddd_llc <- feols(
  registrations_llc ~ cash_int:time_period | district + year + sector,
  data = df,
  cluster = "district"
)

cat("Placebo DDD on LLC registrations: ", round(coef(ddd_llc)["cash_int:time_period"], 2),
    " (se=", round(se(ddd_llc)["cash_int:time_period"], 2), ")\n")
cat("  → Should be smaller than sole prop DDD if treatment is real\n\n", sep="")

# ============================================================
# ROBUSTNESS 4: Pre-treatment trends
# ============================================================

cat("========== ROBUSTNESS 4: Pre-treatment Trends ==========\n")

df_pre <- df[year < 2023]

pretrend <- feols(
  registrations_sole ~ cash_int:year | district + sector,
  data = df_pre,
  cluster = "district"
)

cat("Pre-treatment interaction (cash_int × year): ",
    round(coef(pretrend)["cash_int:year"], 2),
    " (se=", round(se(pretrend)["cash_int:year"], 2), ")\n")
cat("  → Should be ~0 if parallel trends hold\n\n", sep="")

# ============================================================
# ROBUSTNESS 5: Continuous sector intensity
# ============================================================

cat("========== ROBUSTNESS 5: Continuous Sector Intensity ==========\n")

df[, cash_intensity_pct := ifelse(cash_intensive, 0.75, 0.25)]

ddd_continuous <- feols(
  registrations_sole ~ cash_intensity_pct:time_period | district + year + sector,
  data = df,
  cluster = "district"
)

cat("DDD with continuous cash intensity: ",
    round(coef(ddd_continuous)["cash_intensity_pct:time_period"], 2),
    " (se=", round(se(ddd_continuous)["cash_intensity_pct:time_period"], 2), ")\n\n", sep="")

# ============================================================
# ROBUSTNESS 6: Summary table
# ============================================================

cat("\n========== ROBUSTNESS SUMMARY TABLE ==========\n\n")

robustness_table <- data.table(
  Specification = c(
    "Main DDD",
    "Urban only",
    "Rural only",
    "Narrow window (2022-2023)",
    "LLC placebo",
    "Pre-trend test",
    "Continuous intensity"
  ),
  Coefficient = c(
    -10.36,
    round(coef(ddd_urban)["cash_int:time_period"], 2),
    round(coef(ddd_rural)["cash_int:time_period"], 2),
    round(coef(ddd_narrow)["cash_int:time_period"], 2),
    round(coef(ddd_llc)["cash_int:time_period"], 2),
    round(coef(pretrend)["cash_int:year"], 2),
    round(coef(ddd_continuous)["cash_intensity_pct:time_period"], 2)
  ),
  SE = c(
    0.85,
    round(se(ddd_urban)["cash_int:time_period"], 2),
    round(se(ddd_rural)["cash_int:time_period"], 2),
    round(se(ddd_narrow)["cash_int:time_period"], 2),
    round(se(ddd_llc)["cash_int:time_period"], 2),
    round(se(pretrend)["cash_int:year"], 2),
    round(se(ddd_continuous)["cash_intensity_pct:time_period"], 2)
  )
)

print(robustness_table)

# Save
fwrite(robustness_table, "tables/robustness_summary.csv")

cat("\n✓ Robustness checks complete\n")
cat("  Summary saved to tables/robustness_summary.csv\n")
