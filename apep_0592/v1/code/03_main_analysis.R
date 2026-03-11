# ==============================================================================
# 03_main_analysis.R — Primary regressions
# Paper: State Prohibition and Labor Market Restructuring (apep_0592)
# ==============================================================================

source("00_packages.R")

dt <- fread("../data/analysis_sample.csv")
pretrend <- fread("../data/pretrend_sample.csv")
longrun <- fread("../data/longrun_sample.csv")
county_alc <- fread("../data/county_alcohol_shares.csv")

cat("Main sample:", format(nrow(dt), big.mark = ","), "individuals\n")

# ==============================================================================
# 1. SUMMARY STATISTICS
# ==============================================================================

# Summary statistics table
sum_stats <- dt[male == 1, .(
  N = .N,
  mean_age = mean(age_1910),
  sd_age = sd(age_1910),
  pct_immigrant = mean(immigrant) * 100,
  pct_black = mean(black) * 100,
  pct_married = mean(married) * 100,
  pct_literate = mean(literate) * 100,
  mean_occscore_1910 = mean(occscore_1910),
  sd_occscore_1910 = sd(occscore_1910),
  mean_occscore_1920 = mean(occscore_1920),
  sd_occscore_1920 = sd(occscore_1920),
  mean_delta_occ = mean(delta_occscore),
  sd_delta_occ = sd(delta_occscore),
  pct_occ_switch = mean(occ_switch) * 100,
  pct_mover = mean(mover) * 100,
  pct_self_emp_1910 = mean(self_employed_1910) * 100,
  mean_alc_share = mean(alc_share) * 100,
  sd_alc_share = sd(alc_share) * 100
), by = state_group]

fwrite(sum_stats, "../data/summary_stats.csv")
cat("Summary statistics saved.\n")

# Overall SD of key variables (for SDE computation)
sd_delta_occ <- sd(dt[male == 1, delta_occscore])
sd_occscore <- sd(dt[male == 1, occscore_1910])
sd_treatment <- sd(dt[male == 1, treatment])
cat("SD(delta_occscore) =", round(sd_delta_occ, 3), "\n")
cat("SD(occscore_1910) =", round(sd_occscore, 3), "\n")
cat("SD(treatment) =", round(sd_treatment, 5), "\n")

# ==============================================================================
# 2. MAIN RESULTS: Effect of Prohibition × Alcohol Share on ΔOCCSCORE
# ==============================================================================
# Sample: Males, exclude already-dry states
males <- dt[male == 1]

# Specification 1: No fixed effects, just controls
m1 <- feols(delta_occscore ~ treatment + alc_share + treated_state +
              age_1910 + age_sq + immigrant + black + married + literate,
            data = males, cluster = ~statefip_1910)

# Specification 2: Region FE
m2 <- feols(delta_occscore ~ treatment + alc_share + treated_state +
              age_1910 + age_sq + immigrant + black + married + literate | region,
            data = males, cluster = ~statefip_1910)

# Specification 3: Region FE + 1910 OCCSCORE control (initial conditions)
m3 <- feols(delta_occscore ~ treatment + alc_share + treated_state +
              age_1910 + age_sq + immigrant + black + married + literate +
              occscore_1910 | region,
            data = males, cluster = ~statefip_1910)

# Specification 4: State FE (absorbs treated_state; uses within-state variation)
m4 <- feols(delta_occscore ~ alc_share +
              age_1910 + age_sq + immigrant + black + married + literate +
              occscore_1910 | statefip_1910,
            data = males, cluster = ~statefip_1910)

# Specification 5: Dose-response (years of prohibition × alcohol share)
m5 <- feols(delta_occscore ~ treatment_years + alc_share +
              age_1910 + age_sq + immigrant + black + married + literate +
              occscore_1910 | region,
            data = males, cluster = ~statefip_1910)

cat("\n=== MAIN RESULTS ===\n")
etable(m1, m2, m3, m4, m5,
       keep = c("%treatment", "%alc_share", "%treated_state", "%treatment_years"),
       se.below = TRUE)

# Save main coefficients for tables
main_coefs <- data.table(
  spec = paste0("m", 1:5),
  beta = c(coef(m1)["treatment"], coef(m2)["treatment"],
           coef(m3)["treatment"], coef(m4)["alc_share"],
           coef(m5)["treatment_years"]),
  se = c(se(m1)["treatment"], se(m2)["treatment"],
         se(m3)["treatment"], se(m4)["alc_share"],
         se(m5)["treatment_years"]),
  n = c(nobs(m1), nobs(m2), nobs(m3), nobs(m4), nobs(m5))
)
main_coefs[, pval := 2 * pnorm(-abs(beta / se))]
fwrite(main_coefs, "../data/main_coefficients.csv")

# ==============================================================================
# 3. PRE-TREND TEST (1900-1910)
# ==============================================================================
cat("\n=== PRE-TREND TEST (1900-1910) ===\n")

# Free memory before loading pre-trend data
rm(dt, males, county_alc, sum_stats)
gc()

pre_males <- pretrend[male == 1]

pre_m1 <- feols(delta_occscore ~ treatment + alc_share_1900 + treated_state +
                  age_1900 + age_sq + immigrant + black,
                data = pre_males, cluster = ~statefip_1910)

pre_m2 <- feols(delta_occscore ~ treatment + alc_share_1900 + treated_state +
                  age_1900 + age_sq + immigrant + black | region,
                data = pre_males, cluster = ~statefip_1910)

etable(pre_m1, pre_m2,
       keep = c("%treatment", "%alc_share_1900"),
       se.below = TRUE)

pre_coefs <- data.table(
  spec = c("pre_m1", "pre_m2"),
  beta = c(coef(pre_m1)["treatment"], coef(pre_m2)["treatment"]),
  se = c(se(pre_m1)["treatment"], se(pre_m2)["treatment"])
)
fwrite(pre_coefs, "../data/pretrend_coefficients.csv")

# Mechanisms, heterogeneity, women, long-run are in 03b_mechanisms.R (separate memory)

# ==============================================================================
# 4. Save Main + Pre-Trend Model Objects
# ==============================================================================
save(m1, m2, m3, m4, m5, sd_delta_occ, sd_occscore, sd_treatment,
     pre_m1, pre_m2,
     file = "../data/model_objects.RData")

cat("\nMain analysis + pre-trend complete. Model objects saved.\n")
cat("Run 03b_mechanisms.R for mechanism tests, heterogeneity, women, long-run.\n")
