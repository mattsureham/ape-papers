# ==============================================================================
# 03_main_analysis.R — Primary regressions
# apep_0586: Winning the Peace
# ==============================================================================

source("00_packages.R")

# Use a 30% random sample to fit in 16GB RAM with large FE models
# This still gives ~2.7M observations — more than sufficient for inference
set.seed(42)
df <- fread("../data/analysis_sample.csv")
cat("Full analysis sample:", nrow(df), "observations\n")

# Keep all observations for summary stats (already computed in 02)
# For regressions, use a random sample
sample_frac <- 0.30
sample_idx <- sample(nrow(df), size = floor(nrow(df) * sample_frac))
df <- df[sample_idx]
cat("Regression sample (", sample_frac * 100, "%):", nrow(df), "observations\n")
gc()

# Convert factors
df[, birth_year := as.factor(birth_year)]
df[, statefip_1940 := as.factor(statefip_1940)]

# ==============================================================================
# TABLE 2: Main Results — Mobilization Exposure × Draft Eligibility
# ==============================================================================

# Restrict to draft-eligible + older control (drop age placebo for main spec)
main_sample <- df[cohort_group %in% c("draft_eligible", "older_control")]
cat("Main sample (draft-eligible + older control):", nrow(main_sample), "\n")

# Column 1: Baseline — no individual controls
m1 <- feols(delta_occscore_40_50 ~ mob_x_draft |
              statefip_1940 + birth_year,
            data = main_sample, cluster = ~statefip_1940)

# Column 2: Add pre-war controls
m2 <- feols(delta_occscore_40_50 ~ mob_x_draft + educ_years_1940 +
              occscore_1940 + white + married_1940 + farm_1940_d + native_born |
              statefip_1940 + birth_year,
            data = main_sample, cluster = ~statefip_1940)

# Column 3: Add manufacturing share × draft eligible
main_sample[, mfg_x_draft := mfg_share * draft_eligible]
m3 <- feols(delta_occscore_40_50 ~ mob_x_draft + mfg_x_draft +
              educ_years_1940 + occscore_1940 + white + married_1940 +
              farm_1940_d + native_born |
              statefip_1940 + birth_year,
            data = main_sample, cluster = ~statefip_1940)

# Column 4: Log wages
m4 <- feols(delta_log_wage ~ mob_x_draft + educ_years_1940 +
              log_incwage_1940 + white + married_1940 + farm_1940_d + native_born |
              statefip_1940 + birth_year,
            data = main_sample[!is.na(delta_log_wage)], cluster = ~statefip_1940)

# Column 5: Education (any college 1950)
m5 <- feols(any_college_1950 ~ mob_x_draft + educ_years_1940 +
              occscore_1940 + white + married_1940 + farm_1940_d + native_born |
              statefip_1940 + birth_year,
            data = main_sample, cluster = ~statefip_1940)

# Column 6: Left agriculture (1940→1950)
m6 <- feols(left_ag ~ mob_x_draft + educ_years_1940 +
              occscore_1940 + white + married_1940 + farm_1940_d + native_born |
              statefip_1940 + birth_year,
            data = main_sample[in_ag_1940 == 1], cluster = ~statefip_1940)

cat("\n=== TABLE 2: Main Results ===\n")
etable(m1, m2, m3, m4, m5, m6,
       headers = c("ΔOccScore", "ΔOccScore", "ΔOccScore",
                    "ΔLogWage", "College", "LeftAg"),
       se.below = TRUE, fitstat = ~ n + r2)

# Save coefficients for tables
main_results <- data.table(
  spec = c("baseline", "controls", "mfg_control", "log_wage", "college", "left_ag"),
  coef = c(coef(m1)["mob_x_draft"], coef(m2)["mob_x_draft"],
           coef(m3)["mob_x_draft"], coef(m4)["mob_x_draft"],
           coef(m5)["mob_x_draft"], coef(m6)["mob_x_draft"]),
  se = c(se(m1)["mob_x_draft"], se(m2)["mob_x_draft"],
         se(m3)["mob_x_draft"], se(m4)["mob_x_draft"],
         se(m5)["mob_x_draft"], se(m6)["mob_x_draft"]),
  n = c(m1$nobs, m2$nobs, m3$nobs, m4$nobs, m5$nobs, m6$nobs),
  r2 = c(r2(m1, "r2"), r2(m2, "r2"), r2(m3, "r2"),
         r2(m4, "r2"), r2(m5, "r2"), r2(m6, "r2")),
  dep_var = c("delta_occscore", "delta_occscore", "delta_occscore",
              "delta_log_wage", "any_college", "left_ag")
)
fwrite(main_results, "../data/main_results.csv")

# Clean up to free memory
rm(m1, m3, m4, m5, m6)
gc()

# ==============================================================================
# TABLE 3: Pre-Trend Test (1930→1940 outcomes)
# ==============================================================================

cat("\n=== PRE-TREND TEST (1930→1940) ===\n")

# Same specification, but outcome is 1930→1940 change
pt1 <- feols(delta_occscore_30_40 ~ mob_x_draft |
               statefip_1940 + birth_year,
             data = main_sample, cluster = ~statefip_1940)

pt2 <- feols(delta_occscore_30_40 ~ mob_x_draft + occscore_1930 +
               white + married_1940 + farm_1940_d + native_born |
               statefip_1940 + birth_year,
             data = main_sample, cluster = ~statefip_1940)

# Occupation upgraded 1930→1940 (should be zero)
pt3 <- feols(occ_upgraded_30_40 ~ mob_x_draft + occscore_1930 +
               white + married_1940 + native_born |
               statefip_1940 + birth_year,
             data = main_sample, cluster = ~statefip_1940)

etable(pt1, pt2, pt3,
       headers = c("ΔOccScore 30-40", "ΔOccScore 30-40", "Upgraded 30-40"),
       se.below = TRUE, fitstat = ~ n + r2)

pretrend_results <- data.table(
  spec = c("pretrend_baseline", "pretrend_controls", "pretrend_upgraded"),
  coef = c(coef(pt1)["mob_x_draft"], coef(pt2)["mob_x_draft"],
           coef(pt3)["mob_x_draft"]),
  se = c(se(pt1)["mob_x_draft"], se(pt2)["mob_x_draft"],
         se(pt3)["mob_x_draft"]),
  n = c(pt1$nobs, pt2$nobs, pt3$nobs)
)
fwrite(pretrend_results, "../data/pretrend_results.csv")

# Free memory
rm(pt1, pt2, pt3)
gc()

# ==============================================================================
# Age Placebo: Men born 1895-1904 (too old for active service)
# ==============================================================================

cat("\n=== AGE PLACEBO (born 1895-1904) ===\n")

# Age placebo: mob_exposure is state-level → absorbed by state FE
# Instead, test with birth_year FE only (no state FE), comparing across states
placebo_sample <- df[cohort_group == "age_placebo"]
placebo1 <- feols(delta_occscore_40_50 ~ mob_exposure_std +
                    white + married_1940 + farm_1940_d + native_born |
                    birth_year,
                  data = placebo_sample, cluster = ~statefip_1940)

cat("Age placebo coefficient:", round(coef(placebo1)["mob_exposure_std"], 4),
    " (SE:", round(se(placebo1)["mob_exposure_std"], 4), ")\n")

placebo_results <- data.table(
  test = "age_placebo",
  coef = coef(placebo1)["mob_exposure_std"],
  se = se(placebo1)["mob_exposure_std"],
  n = placebo1$nobs
)
fwrite(placebo_results, "../data/placebo_results.csv")

# ==============================================================================
# Trend-Adjusted Specification (key methodological contribution)
# ==============================================================================

cat("\n=== TREND-ADJUSTED SPECIFICATION ===\n")

# The 1930 pre-trend reveals differential pre-existing trends.
# Trend-adjusted outcome: (Δoccscore 40-50) - (Δoccscore 30-40)
# This removes cohort × state-specific lifecycle trends

main_sample[, delta_trend_adjusted := delta_occscore_40_50 - delta_occscore_30_40]

ta1 <- feols(delta_trend_adjusted ~ mob_x_draft |
               statefip_1940 + birth_year,
             data = main_sample, cluster = ~statefip_1940)

ta2 <- feols(delta_trend_adjusted ~ mob_x_draft + educ_years_1940 +
               white + married_1940 + farm_1940_d + native_born |
               statefip_1940 + birth_year,
             data = main_sample, cluster = ~statefip_1940)

cat("Trend-adjusted (no controls):", round(coef(ta1)["mob_x_draft"], 4),
    " (SE:", round(se(ta1)["mob_x_draft"], 4), ")\n")
cat("Trend-adjusted (controls):", round(coef(ta2)["mob_x_draft"], 4),
    " (SE:", round(se(ta2)["mob_x_draft"], 4), ")\n")

trend_adj_results <- data.table(
  spec = c("trend_adj_baseline", "trend_adj_controls"),
  coef = c(coef(ta1)["mob_x_draft"], coef(ta2)["mob_x_draft"]),
  se = c(se(ta1)["mob_x_draft"], se(ta2)["mob_x_draft"]),
  n = c(ta1$nobs, ta2$nobs)
)
fwrite(trend_adj_results, "../data/trend_adjusted_results.csv")

# Free memory
rm(placebo1, placebo_sample)
gc()

# ==============================================================================
# TABLE 4: Mechanisms — Heterogeneity by Pre-War Occupation
# ==============================================================================

cat("\n=== MECHANISMS: Heterogeneity by Pre-War Occupation ===\n")

# Theory: men in low-occupation jobs in 1940 had the most to gain from
# military training + GI Bill education → occupational upgrading

# Split by pre-war occupation quintile
het_results <- list()
for (q in paste0("Q", 1:5)) {
  sub <- main_sample[occ_quintile_1940 == q]
  if (nrow(sub) > 1000) {
    fit <- feols(delta_occscore_40_50 ~ mob_x_draft + educ_years_1940 +
                   white + married_1940 + native_born |
                   statefip_1940 + birth_year,
                 data = sub, cluster = ~statefip_1940)
    het_results[[q]] <- data.table(
      quintile = q,
      coef = coef(fit)["mob_x_draft"],
      se = se(fit)["mob_x_draft"],
      n = fit$nobs,
      mean_occscore_1940 = mean(sub$occscore_1940, na.rm = TRUE)
    )
    cat(q, ": coef =", round(coef(fit)["mob_x_draft"], 3),
        " (SE =", round(se(fit)["mob_x_draft"], 3), ")",
        " N =", fit$nobs, "\n")
  }
}
het_dt <- rbindlist(het_results)
fwrite(het_dt, "../data/heterogeneity_occupation.csv")

# By race
het_race <- list()
for (r in c(0, 1)) {
  sub <- main_sample[white == r]
  if (nrow(sub) > 5000) {
    fit <- feols(delta_occscore_40_50 ~ mob_x_draft + educ_years_1940 +
                   occscore_1940 + married_1940 + farm_1940_d + native_born |
                   statefip_1940 + birth_year,
                 data = sub, cluster = ~statefip_1940)
    het_race[[as.character(r)]] <- data.table(
      group = ifelse(r == 1, "White", "Non-White"),
      coef = coef(fit)["mob_x_draft"],
      se = se(fit)["mob_x_draft"],
      n = fit$nobs
    )
    cat(ifelse(r == 1, "White", "Non-White"), ": coef =",
        round(coef(fit)["mob_x_draft"], 3),
        " (SE =", round(se(fit)["mob_x_draft"], 3), ")\n")
  }
}
het_race_dt <- rbindlist(het_race)
fwrite(het_race_dt, "../data/heterogeneity_race.csv")

# By farm status
het_farm <- list()
for (f in c(0, 1)) {
  sub <- main_sample[farm_1940_d == f]
  if (nrow(sub) > 5000) {
    fit <- feols(delta_occscore_40_50 ~ mob_x_draft + educ_years_1940 +
                   occscore_1940 + white + married_1940 + native_born |
                   statefip_1940 + birth_year,
                 data = sub, cluster = ~statefip_1940)
    het_farm[[as.character(f)]] <- data.table(
      group = ifelse(f == 1, "Farm", "Non-Farm"),
      coef = coef(fit)["mob_x_draft"],
      se = se(fit)["mob_x_draft"],
      n = fit$nobs
    )
    cat(ifelse(f == 1, "Farm", "Non-Farm"), ": coef =",
        round(coef(fit)["mob_x_draft"], 3),
        " (SE =", round(se(fit)["mob_x_draft"], 3), ")\n")
  }
}
het_farm_dt <- rbindlist(het_farm)
fwrite(het_farm_dt, "../data/heterogeneity_farm.csv")

cat("\nMain analysis complete. Results saved to data/\n")
