# =============================================================================
# 04_robustness.R — Robustness checks and placebo tests
# apep_1015: The First Wage Floor for Women
# =============================================================================

source("00_packages.R")

dt <- as.data.table(arrow::read_parquet("../data/est_sample_women.parquet"))

# Reconstruct variables
dt[, mw_x_covered := mw_state * covered_ind]
dt[, age_sq := age_1910^2]
dt[, native := as.integer(nativity_1910 <= 1)]
dt[, literate := as.integer(lit_1910 == 4)]
dt[, married := as.integer(marst_1910 <= 2)]
dt[, white := as.integer(race_1910 == 1)]
dt[, ind_group := fcase(
  ind1950_1910 >= 100 & ind1950_1910 <= 126, 1L,
  ind1950_1910 >= 306 & ind1950_1910 <= 399, 2L,
  ind1950_1910 >= 400 & ind1950_1910 <= 499, 3L,
  ind1950_1910 >= 606 & ind1950_1910 <= 699, 4L,
  ind1950_1910 >= 806 & ind1950_1910 <= 829, 5L,
  ind1950_1910 == 856, 6L,
  default = 7L
)]

# Remove singletons
cell_counts <- dt[, .N, by = .(statefip_1910, ind_group)]
dt <- dt[!cell_counts[N == 1], on = .(statefip_1910, ind_group)]

controls <- "age_1910 + age_sq + native + literate + married + white"

# ===========================================================================
# 1. PLACEBO: MEN in the same covered industries
#    Laws targeted women only — men should show no DDD effect
# ===========================================================================
cat("\n=== PLACEBO: Men in same industries ===\n")

men <- as.data.table(arrow::read_parquet("../data/men_1910_1920.parquet"))

mw_states <- c(4, 5, 6, 8, 20, 25, 27, 31, 38, 41, 48, 49, 53, 55)
men[, mw_state := as.integer(statefip_1910 %in% mw_states)]
men[, covered_ind := as.integer(
  (ind1950_1910 >= 306 & ind1950_1910 <= 499) |
  (ind1950_1910 >= 606 & ind1950_1910 <= 699) |
  (ind1950_1910 >= 806 & ind1950_1910 <= 829)
)]
men[, exempt_ind := as.integer(
  (ind1950_1910 >= 100 & ind1950_1910 <= 126) |
  (ind1950_1910 == 856)
)]
men[, in_lf_1910 := as.integer(occ1950_1910 > 0 & occ1950_1910 < 979)]
men[, in_lf_1920 := as.integer(occ1950_1920 > 0 & occ1950_1920 < 979)]
men[, retention := in_lf_1920]
men[, same_industry := as.integer(ind1950_1910 == ind1950_1920)]
men[, occ_change := occscore_1920 - occscore_1910]

men_est <- men[in_lf_1910 == 1 & (covered_ind == 1 | exempt_ind == 1)]
men_est[, mw_x_covered := mw_state * covered_ind]
men_est[, age_sq := age_1910^2]
men_est[, native := as.integer(nativity_1910 <= 1)]
men_est[, literate := as.integer(lit_1910 == 4)]
men_est[, married := as.integer(marst_1910 <= 2)]
men_est[, white := as.integer(race_1910 == 1)]
men_est[, ind_group := fcase(
  ind1950_1910 >= 100 & ind1950_1910 <= 126, 1L,
  ind1950_1910 >= 306 & ind1950_1910 <= 399, 2L,
  ind1950_1910 >= 400 & ind1950_1910 <= 499, 3L,
  ind1950_1910 >= 606 & ind1950_1910 <= 699, 4L,
  ind1950_1910 >= 806 & ind1950_1910 <= 829, 5L,
  ind1950_1910 == 856, 6L,
  default = 7L
)]

# Remove singletons
cell_counts_m <- men_est[, .N, by = .(statefip_1910, ind_group)]
men_est <- men_est[!cell_counts_m[N == 1], on = .(statefip_1910, ind_group)]

cat(sprintf("Men estimation sample: %s\n", format(nrow(men_est), big.mark = ",")))

placebo_ret <- feols(retention ~ mw_x_covered +
                       age_1910 + age_sq + native + literate + married + white |
                       statefip_1910 + ind_group,
                     data = men_est, cluster = ~statefip_1910)
cat("Men retention:\n"); print(coeftable(placebo_ret))

placebo_ind <- feols(same_industry ~ mw_x_covered +
                       age_1910 + age_sq + native + literate + married + white |
                       statefip_1910 + ind_group,
                     data = men_est, cluster = ~statefip_1910)
cat("Men industry persistence:\n"); print(coeftable(placebo_ind))

rm(men, men_est)
gc()

# ===========================================================================
# 2. COUNTY FIXED EFFECTS (finer geography)
# ===========================================================================
cat("\n=== COUNTY FIXED EFFECTS ===\n")

# Create state x county FE
dt[, county_fe := statefip_1910 * 10000L + countyicp_1910]

# Remove county singletons
county_counts <- dt[, .N, by = county_fe]
dt_county <- dt[county_counts[N > 1], on = "county_fe"]
cat(sprintf("County FE sample: %s (dropped %s singletons)\n",
            format(nrow(dt_county), big.mark = ","),
            format(nrow(dt) - nrow(dt_county), big.mark = ",")))

m_county <- feols(retention ~ mw_x_covered +
                    age_1910 + age_sq + native + literate + married + white |
                    county_fe + ind_group,
                  data = dt_county, cluster = ~statefip_1910)
cat("County FE retention:\n"); print(coeftable(m_county))
rm(dt_county)

# ===========================================================================
# 3. HETEROGENEITY: By early vs late adopters
# ===========================================================================
cat("\n=== HETEROGENEITY: Early (1912-1913) vs Late (1915-1920) adopters ===\n")

early_states <- c(6, 8, 25, 27, 31, 41, 49, 53, 55)  # 1912-1913
late_states <- c(4, 5, 20, 38, 48)                     # 1915-1920

dt[, early_mw := as.integer(statefip_1910 %in% early_states)]
dt[, late_mw := as.integer(statefip_1910 %in% late_states)]
dt[, early_x_covered := early_mw * covered_ind]
dt[, late_x_covered := late_mw * covered_ind]

m_timing <- feols(retention ~ early_x_covered + late_x_covered +
                    age_1910 + age_sq + native + literate + married + white |
                    statefip_1910 + ind_group,
                  data = dt, cluster = ~statefip_1910)
cat("Early vs Late:\n"); print(coeftable(m_timing))

# ===========================================================================
# 4. HETEROGENEITY: By race
# ===========================================================================
cat("\n=== HETEROGENEITY: White vs Non-White ===\n")

m_white <- feols(retention ~ mw_x_covered +
                   age_1910 + age_sq + native + literate + married |
                   statefip_1910 + ind_group,
                 data = dt[white == 1], cluster = ~statefip_1910)

m_nonwhite <- feols(retention ~ mw_x_covered +
                      age_1910 + age_sq + native + literate + married |
                      statefip_1910 + ind_group,
                    data = dt[white == 0], cluster = ~statefip_1910)
cat(sprintf("White: coef=%.4f, se=%.4f, N=%s\n",
            coef(m_white)["mw_x_covered"], se(m_white)["mw_x_covered"],
            format(nobs(m_white), big.mark = ",")))
cat(sprintf("Non-White: coef=%.4f, se=%.4f, N=%s\n",
            coef(m_nonwhite)["mw_x_covered"], se(m_nonwhite)["mw_x_covered"],
            format(nobs(m_nonwhite), big.mark = ",")))

# ===========================================================================
# 5. HETEROGENEITY: By marital status
# ===========================================================================
cat("\n=== HETEROGENEITY: Married vs Unmarried ===\n")

m_married <- feols(retention ~ mw_x_covered +
                     age_1910 + age_sq + native + literate + white |
                     statefip_1910 + ind_group,
                   data = dt[married == 1], cluster = ~statefip_1910)

m_unmarried <- feols(retention ~ mw_x_covered +
                       age_1910 + age_sq + native + literate + white |
                       statefip_1910 + ind_group,
                     data = dt[married == 0], cluster = ~statefip_1910)
cat(sprintf("Married: coef=%.4f, se=%.4f, N=%s\n",
            coef(m_married)["mw_x_covered"], se(m_married)["mw_x_covered"],
            format(nobs(m_married), big.mark = ",")))
cat(sprintf("Unmarried: coef=%.4f, se=%.4f, N=%s\n",
            coef(m_unmarried)["mw_x_covered"], se(m_unmarried)["mw_x_covered"],
            format(nobs(m_unmarried), big.mark = ",")))

# ===========================================================================
# 6. LEAVE-ONE-OUT: Drop each MW state
# ===========================================================================
cat("\n=== LEAVE-ONE-OUT (retention, dropping each MW state) ===\n")

mw_state_list <- c(4, 5, 6, 8, 20, 25, 27, 31, 38, 41, 48, 49, 53, 55)
loo_results <- data.table(
  dropped = integer(),
  coef = numeric(),
  se = numeric()
)

for (s in mw_state_list) {
  m_loo <- feols(retention ~ mw_x_covered +
                   age_1910 + age_sq + native + literate + married + white |
                   statefip_1910 + ind_group,
                 data = dt[statefip_1910 != s], cluster = ~statefip_1910)
  loo_results <- rbind(loo_results, data.table(
    dropped = s,
    coef = coef(m_loo)["mw_x_covered"],
    se = se(m_loo)["mw_x_covered"]
  ))
}
print(loo_results)
cat(sprintf("LOO range: [%.4f, %.4f]\n", min(loo_results$coef), max(loo_results$coef)))

# ===========================================================================
# Save robustness results
# ===========================================================================
rob_results <- list(
  placebo_men_ret = placebo_ret,
  placebo_men_ind = placebo_ind,
  county_fe = m_county,
  early_late = m_timing,
  white = m_white, nonwhite = m_nonwhite,
  married = m_married, unmarried = m_unmarried,
  loo = loo_results
)
saveRDS(rob_results, "../data/robustness_results.rds")

cat("\n04_robustness.R complete.\n")
