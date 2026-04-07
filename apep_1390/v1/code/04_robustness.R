# ==============================================================================
# 04_robustness.R — Robustness checks
# ==============================================================================

source("00_packages.R")

cat("Loading analysis sample...\n")
df <- arrow::read_parquet("../data/analysis_sample.parquet")
setDT(df)

main <- df[cohort_group %in% c("pre", "exposed")]

# --------------------------------------------------------------------------
# 1. Placebo: Pre-treatment cohorts only (born 1905-1921)
# --------------------------------------------------------------------------

cat("\n=== Placebo Test: Pre-Treatment Cohorts ===\n")

placebo_df <- df[birthyr >= 1905 & birthyr <= 1921 & !is.na(incwage_1950)]
# Fake "exposed" = born 1912-1918 (same gap as real treatment)
placebo_df[, fake_exposed := fifelse(birthyr >= 1912 & birthyr <= 1918, 1L, 0L)]
placebo_df[, fake_ddd := participant * fake_exposed]

placebo_m <- feols(incwage_1950 ~ fake_ddd + male + white + age_1950 + I(age_1950^2) |
                     birthyr + bpl_1930,
                   data = placebo_df,
                   cluster = ~bpl_1930)

cat("Placebo DDD coefficient:\n")
cat(sprintf("  Estimate: %.2f, SE: %.2f, p: %.4f\n", coef(placebo_m)["fake_ddd"], se(placebo_m)["fake_ddd"], fixest::pvalue(placebo_m)["fake_ddd"]))

# --------------------------------------------------------------------------
# 2. Border-state restriction
# --------------------------------------------------------------------------

cat("\n=== Border-State Restriction ===\n")

# States bordering MA, CT, IL:
# MA borders: CT(9), NY(36), RI(44), VT(50), NH(33)
# CT borders: MA(25), NY(36), RI(44)
# IL borders: WI(55), IN(18), MO(29), IA(19), KY(21)
border_fips <- c(9L, 17L, 25L,  # non-participants
                 36L, 44L, 50L, 33L,  # MA/CT neighbors
                 55L, 18L, 29L, 19L, 21L)  # IL neighbors

border_df <- main[bpl_1930 %in% border_fips & !is.na(incwage_1950)]

border_m <- feols(incwage_1950 ~ ddd + male + white + age_1950 + I(age_1950^2) |
                    birthyr + bpl_1930,
                  data = border_df,
                  cluster = ~bpl_1930)

cat("Border-state DDD:\n")
cat(sprintf("  Estimate: %.2f, SE: %.2f, p: %.4f\n", coef(border_m)["ddd"], se(border_m)["ddd"], fixest::pvalue(border_m)["ddd"]))

# --------------------------------------------------------------------------
# 3. By race
# --------------------------------------------------------------------------

cat("\n=== Heterogeneity: By Race ===\n")

m_white <- feols(incwage_1950 ~ ddd + male + age_1950 + I(age_1950^2) |
                   birthyr + bpl_1930,
                 data = main[white == 1 & !is.na(incwage_1950)],
                 cluster = ~bpl_1930)

m_black <- feols(incwage_1950 ~ ddd + male + age_1950 + I(age_1950^2) |
                   birthyr + bpl_1930,
                 data = main[black == 1 & !is.na(incwage_1950)],
                 cluster = ~bpl_1930)

cat("White sample:\n")
cat(sprintf("  Estimate: %.2f, SE: %.2f, p: %.4f\n", coef(m_white)["ddd"], se(m_white)["ddd"], fixest::pvalue(m_white)["ddd"]))
cat("Black sample:\n")
cat(sprintf("  Estimate: %.2f, SE: %.2f, p: %.4f\n", coef(m_black)["ddd"], se(m_black)["ddd"], fixest::pvalue(m_black)["ddd"]))

# --------------------------------------------------------------------------
# 4. By sex
# --------------------------------------------------------------------------

cat("\n=== Heterogeneity: By Sex ===\n")

m_male <- feols(incwage_1950 ~ ddd + white + age_1950 + I(age_1950^2) |
                  birthyr + bpl_1930,
                data = main[male == 1 & !is.na(incwage_1950)],
                cluster = ~bpl_1930)

m_female <- feols(incwage_1950 ~ ddd + white + age_1950 + I(age_1950^2) |
                    birthyr + bpl_1930,
                  data = main[male == 0 & !is.na(incwage_1950)],
                  cluster = ~bpl_1930)

cat("Male sample:\n")
cat(sprintf("  Estimate: %.2f, SE: %.2f, p: %.4f\n", coef(m_male)["ddd"], se(m_male)["ddd"], fixest::pvalue(m_male)["ddd"]))
cat("Female sample:\n")
cat(sprintf("  Estimate: %.2f, SE: %.2f, p: %.4f\n", coef(m_female)["ddd"], se(m_female)["ddd"], fixest::pvalue(m_female)["ddd"]))

# --------------------------------------------------------------------------
# 5. By urban/rural birth
# --------------------------------------------------------------------------

cat("\n=== Heterogeneity: Urban vs Rural Birth ===\n")

m_rural <- feols(incwage_1950 ~ ddd + male + white + age_1950 + I(age_1950^2) |
                   birthyr + bpl_1930,
                 data = main[rural_1930 == 1 & !is.na(incwage_1950)],
                 cluster = ~bpl_1930)

m_urban <- feols(incwage_1950 ~ ddd + male + white + age_1950 + I(age_1950^2) |
                   birthyr + bpl_1930,
                 data = main[rural_1930 == 0 & !is.na(incwage_1950)],
                 cluster = ~bpl_1930)

cat("Rural-born:\n")
cat(sprintf("  Estimate: %.2f, SE: %.2f, p: %.4f\n", coef(m_rural)["ddd"], se(m_rural)["ddd"], fixest::pvalue(m_rural)["ddd"]))
cat("Urban-born:\n")
cat(sprintf("  Estimate: %.2f, SE: %.2f, p: %.4f\n", coef(m_urban)["ddd"], se(m_urban)["ddd"], fixest::pvalue(m_urban)["ddd"]))

# --------------------------------------------------------------------------
# 6. Employment and homeownership (extensive margin)
# --------------------------------------------------------------------------

cat("\n=== Employment and Homeownership ===\n")

m_emp <- feols(employed_1950 ~ ddd + male + white + age_1950 + I(age_1950^2) |
                 birthyr + bpl_1930,
               data = main,
               cluster = ~bpl_1930)

m_married <- feols(married_1950 ~ ddd + male + white + age_1950 + I(age_1950^2) |
                     birthyr + bpl_1930,
                   data = main,
                   cluster = ~bpl_1930)

cat("Employment:\n")
cat(sprintf("  Estimate: %.2f, SE: %.2f, p: %.4f\n", coef(m_emp)["ddd"], se(m_emp)["ddd"], fixest::pvalue(m_emp)["ddd"]))
cat("Marriage:\n")
cat(sprintf("  Estimate: %.2f, SE: %.2f, p: %.4f\n", coef(m_married)["ddd"], se(m_married)["ddd"], fixest::pvalue(m_married)["ddd"]))

# --------------------------------------------------------------------------
# 7. Post-repeal cohort check (born 1929-1932 should show diminishing effect)
# --------------------------------------------------------------------------

cat("\n=== Post-Repeal Cohort Check ===\n")

post_df <- df[cohort_group %in% c("pre", "post") & !is.na(incwage_1950)]
post_df[, post_exposed := fifelse(birthyr >= 1929, 1L, 0L)]
post_df[, post_ddd := participant * post_exposed]

m_post <- feols(incwage_1950 ~ post_ddd + male + white + age_1950 + I(age_1950^2) |
                  birthyr + bpl_1930,
                data = post_df,
                cluster = ~bpl_1930)

cat("Post-repeal DDD (should be smaller/null):\n")
cat(sprintf("  Estimate: %.2f, SE: %.2f, p: %.4f\n", coef(m_post)["post_ddd"], se(m_post)["post_ddd"], fixest::pvalue(m_post)["post_ddd"]))

# Save all robustness results
save(placebo_m, border_m, m_white, m_black, m_male, m_female,
     m_rural, m_urban, m_emp, m_married, m_post,
     file = "../data/robustness_results.RData")

cat("\nRobustness checks complete.\n")
