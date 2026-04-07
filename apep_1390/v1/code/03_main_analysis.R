# ==============================================================================
# 03_main_analysis.R — DDD regressions for Sheppard-Towner Act
# ==============================================================================

source("00_packages.R")

cat("Loading analysis sample...\n")
df <- arrow::read_parquet("../data/analysis_sample.parquet")
setDT(df)

# --------------------------------------------------------------------------
# Summary statistics
# --------------------------------------------------------------------------

cat("\n=== Summary Statistics ===\n")

sumstats <- df[cohort_group %in% c("pre", "exposed"), .(
  n = .N,
  n_wage = sum(!is.na(incwage_1950)),
  mean_wage = mean(incwage_1950, na.rm = TRUE),
  sd_wage = sd(incwage_1950, na.rm = TRUE),
  mean_educ = mean(educ_years, na.rm = TRUE),
  sd_educ = sd(educ_years, na.rm = TRUE),
  mean_occscore = mean(occscore_1950, na.rm = TRUE),
  pct_male = mean(male, na.rm = TRUE),
  pct_white = mean(white, na.rm = TRUE),
  pct_rural = mean(rural_1930, na.rm = TRUE),
  pct_employed = mean(employed_1950, na.rm = TRUE)
), by = .(participant, exposed)]

print(sumstats)
fwrite(sumstats, "../tables/summary_stats.csv")

# --------------------------------------------------------------------------
# Main DDD specification
# --------------------------------------------------------------------------

cat("\n=== Main DDD Regressions ===\n")

main <- df[cohort_group %in% c("pre", "exposed")]

# Model 1: Basic DDD (no controls)
m1 <- feols(incwage_1950 ~ ddd + participant + exposed |
              birthyr + bpl_1930,
            data = main[!is.na(incwage_1950)],
            cluster = ~bpl_1930)

# Model 2: DDD with demographic controls
m2 <- feols(incwage_1950 ~ ddd + male + white + age_1950 + I(age_1950^2) |
              birthyr + bpl_1930,
            data = main[!is.na(incwage_1950)],
            cluster = ~bpl_1930)

# Model 3: DDD with state-specific trends
m3 <- feols(incwage_1950 ~ ddd + male + white + age_1950 + I(age_1950^2) |
              birthyr + bpl_1930 + birthyr[participant],
            data = main[!is.na(incwage_1950)],
            cluster = ~bpl_1930)

# Model 4: Log wages
m4 <- feols(log_wage ~ ddd + male + white + age_1950 + I(age_1950^2) |
              birthyr + bpl_1930,
            data = main[!is.na(log_wage) & is.finite(log_wage)],
            cluster = ~bpl_1930)

# Model 5: Education (years)
m5 <- feols(educ_years ~ ddd + male + white + age_1950 + I(age_1950^2) |
              birthyr + bpl_1930,
            data = main[!is.na(educ_years)],
            cluster = ~bpl_1930)

# Model 6: Occupational income score
m6 <- feols(occscore_1950 ~ ddd + male + white + age_1950 + I(age_1950^2) |
              birthyr + bpl_1930,
            data = main[!is.na(occscore_1950)],
            cluster = ~bpl_1930)

cat("\n--- Wage Income (levels) ---\n")
print(summary(m2))

cat("\n--- Log Wages ---\n")
print(summary(m4))

cat("\n--- Education ---\n")
print(summary(m5))

cat("\n--- Occupational Score ---\n")
print(summary(m6))

# --------------------------------------------------------------------------
# Event study: birth-year x participant interactions
# --------------------------------------------------------------------------

cat("\n=== Event Study ===\n")

es_df <- df[birthyr >= 1912 & birthyr <= 1932 & !is.na(incwage_1950)]

es_wage <- feols(incwage_1950 ~ i(birthyr, participant, ref = 1921) +
                   male + white + age_1950 + I(age_1950^2) |
                   birthyr + bpl_1930,
                 data = es_df,
                 cluster = ~bpl_1930)

cat("Event study (wages) estimated.\n")

es_educ <- feols(educ_years ~ i(birthyr, participant, ref = 1921) +
                   male + white + age_1950 + I(age_1950^2) |
                   birthyr + bpl_1930,
                 data = df[birthyr >= 1912 & birthyr <= 1932 & !is.na(educ_years)],
                 cluster = ~bpl_1930)

cat("Event study (education) estimated.\n")

# --------------------------------------------------------------------------
# Diagnostics for validator
# --------------------------------------------------------------------------

n_treated <- uniqueN(main[participant == 1, bpl_1930])
n_control <- uniqueN(main[participant == 0, bpl_1930])
n_pre <- length(unique(main[cohort_group == "pre", birthyr]))
n_obs <- nrow(main[!is.na(incwage_1950)])

cat(sprintf("\nDiagnostics: %d treated states, %d control states, %d pre-periods, %s obs\n",
            n_treated, n_control, n_pre, format(n_obs, big.mark = ",")))

jsonlite::write_json(list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_control = n_control
), "../data/diagnostics.json", auto_unbox = TRUE)

save(m1, m2, m3, m4, m5, m6, es_wage, es_educ, sumstats,
     file = "../data/main_results.RData")

cat("Main analysis complete.\n")
