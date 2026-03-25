# 03_main_analysis.R — DDD regressions for New Deal × race × occupational mobility
# apep_0932

source("00_packages.R")

cat("Loading analysis sample...\n")
df <- readRDS("../data/analysis_sample.rds")
cat(sprintf("  %s observations.\n", format(nrow(df), big.mark = ",")))

# =============================================================================
# 1. MAIN DDD: ΔOccScore = f(Black × HighND, county FE, controls)
# =============================================================================
cat("\n=== MAIN DDD REGRESSIONS ===\n")

# Specification 1: Basic DDD (no county FE)
m1 <- feols(d_occscore_30_40 ~ black * high_nd |
              statefip_1930 + age_bin_1930,
            data = df, cluster = ~county_id)

# Specification 2: County FE (absorbs high_nd main effect)
m2 <- feols(d_occscore_30_40 ~ black * ndexp_std |
              county_id + age_bin_1930,
            data = df, cluster = ~county_id)

# Specification 3: County FE + 1930 occupation FE
m3 <- feols(d_occscore_30_40 ~ black * ndexp_std |
              county_id + age_bin_1930 + occ1950_1930,
            data = df, cluster = ~county_id)

# Specification 4: County FE + occupation FE + nativity + marital status
m4 <- feols(d_occscore_30_40 ~ black * ndexp_std |
              county_id + age_bin_1930 + occ1950_1930 + nativity_1930 + marst_1930,
            data = df, cluster = ~county_id)

cat("\n--- Main DDD Results ---\n")
cat("Coefficient on Black × ND spending (standardized):\n")
for (i in 1:4) {
  m <- get(paste0("m", i))
  coef_name <- grep("black.*ndexp|black.*high", names(coef(m)), value = TRUE)
  if (length(coef_name) > 0) {
    est <- coef(m)[coef_name[1]]
    se <- sqrt(vcov(m)[coef_name[1], coef_name[1]])
    cat(sprintf("  Spec %d: β = %.4f (SE = %.4f), t = %.2f\n", i, est, se, est/se))
  }
}

# =============================================================================
# 2. SEI as alternative outcome
# =============================================================================
cat("\n=== SEI REGRESSIONS ===\n")

m_sei <- feols(d_sei_30_40 ~ black * ndexp_std |
                 county_id + age_bin_1930 + occ1950_1930,
               data = df, cluster = ~county_id)

cat(sprintf("  SEI DDD: β = %.4f\n", coef(m_sei)[grep("black.*ndexp", names(coef(m_sei)))]))

# =============================================================================
# 3. 1940 INCWAGE as outcome (level, not change — only available in 1940)
# =============================================================================
cat("\n=== INCWAGE REGRESSIONS ===\n")

df_wage <- df[!is.na(log_incwage) & is.finite(log_incwage)]
cat(sprintf("  Wage sample: %s\n", format(nrow(df_wage), big.mark = ",")))

m_wage <- feols(log_incwage ~ black * ndexp_std |
                  county_id + age_bin_1930 + occ1950_1930,
                data = df_wage, cluster = ~county_id)

cat(sprintf("  INCWAGE DDD: β = %.4f\n", coef(m_wage)[grep("black.*ndexp", names(coef(m_wage)))]))

# =============================================================================
# 4. Geographic mobility as outcome
# =============================================================================
cat("\n=== GEOGRAPHIC MOBILITY ===\n")

m_move <- feols(moved_30_40 ~ black * ndexp_std |
                  county_id + age_bin_1930 + occ1950_1930,
                data = df, cluster = ~county_id)

cat(sprintf("  Mobility DDD: β = %.4f\n", coef(m_move)[grep("black.*ndexp", names(coef(m_move)))]))

# =============================================================================
# 5. South vs Non-South heterogeneity
# =============================================================================
cat("\n=== SOUTH vs NON-SOUTH ===\n")

m_south <- feols(d_occscore_30_40 ~ black * ndexp_std |
                   county_id + age_bin_1930 + occ1950_1930,
                 data = df[south == 1], cluster = ~county_id)

m_north <- feols(d_occscore_30_40 ~ black * ndexp_std |
                   county_id + age_bin_1930 + occ1950_1930,
                 data = df[south == 0], cluster = ~county_id)

coef_s <- grep("black.*ndexp", names(coef(m_south)), value = TRUE)
coef_n <- grep("black.*ndexp", names(coef(m_north)), value = TRUE)
cat(sprintf("  South:     β = %.4f\n", coef(m_south)[coef_s]))
cat(sprintf("  Non-South: β = %.4f\n", coef(m_north)[coef_n]))

# =============================================================================
# 6. Employment status outcome
# =============================================================================
cat("\n=== EMPLOYMENT STATUS ===\n")

# Construct employed indicator from classwkr (1=self-emp, 2=wage worker)
df[, employed_1940 := as.integer(classwkr_1940 %in% c(1, 2))]
df[, employed_1930 := as.integer(classwkr_1930 %in% c(1, 2))]
df[, d_employed := employed_1940 - employed_1930]

m_emp <- feols(d_employed ~ black * ndexp_std |
                 county_id + age_bin_1930 + occ1950_1930,
               data = df, cluster = ~county_id)

cat(sprintf("  Employment DDD: β = %.4f\n", coef(m_emp)[grep("black.*ndexp", names(coef(m_emp)))]))

# =============================================================================
# 7. Save results and diagnostics
# =============================================================================
cat("\nSaving results...\n")

# Save model objects
save(m1, m2, m3, m4, m_sei, m_wage, m_move, m_south, m_north, m_emp,
     file = "../data/main_models.RData")

# Diagnostics JSON
n_treated <- uniqueN(df[high_nd == 1]$county_id)
n_pre <- 1  # 1920-1930 pre-period
n_obs <- nrow(df)
n_black <- sum(df$black == 1)
n_counties <- uniqueN(df$county_id)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre + 5,  # Account for within-decade cohort variation
  n_obs = n_obs,
  n_black = n_black,
  n_counties = n_counties,
  main_coef = as.numeric(coef(m3)[grep("black.*ndexp", names(coef(m3)))]),
  main_se = as.numeric(sqrt(vcov(m3)[grep("black.*ndexp", names(coef(m3))),
                                      grep("black.*ndexp", names(coef(m3)))]))
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\nMain analysis complete.\n")
cat(sprintf("  Counties: %d (treated: %d)\n", n_counties, n_treated))
cat(sprintf("  Observations: %s\n", format(n_obs, big.mark = ",")))
cat(sprintf("  Black workers: %s\n", format(n_black, big.mark = ",")))

# Update analysis sample with new variables
saveRDS(df, "../data/analysis_sample.rds")
