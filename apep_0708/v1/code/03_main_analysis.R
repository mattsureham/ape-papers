# ==============================================================================
# 03_main_analysis.R — Primary regressions
# ==============================================================================

source("00_packages.R")
library(fixest)
library(data.table)

women <- readRDS("../data/analysis_sample.rds")
setDT(women)

cat("Analysis sample:", nrow(women), "women\n")

# --------------------------------------------------------------------------
# Table 1: Summary Statistics
# --------------------------------------------------------------------------
cat("\n=== Summary Statistics ===\n")

sumstats <- women[, .(
  N = .N,
  LFP_1920 = mean(lfp_1920),
  LFP_1930 = mean(lfp_1930),
  Delta_LFP = mean(d_lfp),
  Domestic_1920 = mean(domestic_1920),
  Married_pct = mean(married_1920),
  Age_1920 = mean(age_1920),
  Literate_pct = mean(lit_1920 == 4, na.rm = TRUE),
  Farm_pct = mean(farm_1920 == 2),
  Mean_exposure = mean(exposure)
)]

cat("Overall:\n")
print(sumstats)

# By marital status
sumstats_marst <- women[, .(
  N = .N,
  LFP_1920 = mean(lfp_1920),
  LFP_1930 = mean(lfp_1930),
  Delta_LFP = mean(d_lfp),
  Domestic_1920 = mean(domestic_1920),
  Mean_exposure = mean(exposure)
), by = married_1920]

cat("\nBy marital status:\n")
print(sumstats_marst)

# By exposure quartile
sumstats_q <- women[, .(
  N = .N,
  Delta_LFP = mean(d_lfp),
  Delta_LFP_married = mean(d_lfp[married_1920 == 1]),
  Delta_LFP_unmarried = mean(d_lfp[married_1920 == 0])
), by = exposure_q]

cat("\nBy exposure quartile:\n")
print(sumstats_q)

# --------------------------------------------------------------------------
# Table 2: Main Results — Effect of Immigration Restriction on Women's LFP
# --------------------------------------------------------------------------
cat("\n=== Main Regressions ===\n")

# Standardize exposure for interpretability
women[, exposure_std := (exposure - mean(exposure)) / sd(exposure)]

# Panel A: All women
m1 <- feols(d_lfp ~ exposure_std | state,
            data = women, cluster = ~county_id)

m2 <- feols(d_lfp ~ exposure_std + age_1920 + I(age_1920^2) +
              lit_1920 + i(farm_1920) + nchild_1920 | state,
            data = women, cluster = ~county_id)

# Panel B: Married women
m3 <- feols(d_lfp ~ exposure_std | state,
            data = women[married_1920 == 1], cluster = ~county_id)

m4 <- feols(d_lfp ~ exposure_std + age_1920 + I(age_1920^2) +
              lit_1920 + i(farm_1920) + nchild_1920 | state,
            data = women[married_1920 == 1], cluster = ~county_id)

# Panel C: Unmarried women
m5 <- feols(d_lfp ~ exposure_std | state,
            data = women[married_1920 == 0], cluster = ~county_id)

m6 <- feols(d_lfp ~ exposure_std + age_1920 + I(age_1920^2) +
              lit_1920 + i(farm_1920) + nchild_1920 | state,
            data = women[married_1920 == 0], cluster = ~county_id)

cat("\n--- All Women ---\n")
print(summary(m1))
print(summary(m2))

cat("\n--- Married Women ---\n")
print(summary(m3))
print(summary(m4))

cat("\n--- Unmarried Women ---\n")
print(summary(m5))
print(summary(m6))

# --------------------------------------------------------------------------
# Table 3: Mechanism — Effect on Domestic Service Employment
# --------------------------------------------------------------------------
cat("\n=== Domestic Service Mechanism ===\n")

# Change in domestic service employment
d1 <- feols(d_domestic ~ exposure_std + age_1920 + I(age_1920^2) +
              lit_1920 + i(farm_1920) + nchild_1920 | state,
            data = women, cluster = ~county_id)

# Married women entering domestic service vs leaving
d2 <- feols(d_domestic ~ exposure_std + age_1920 + I(age_1920^2) +
              lit_1920 + i(farm_1920) + nchild_1920 | state,
            data = women[married_1920 == 1], cluster = ~county_id)

# Unmarried women in domestic service
d3 <- feols(d_domestic ~ exposure_std + age_1920 + I(age_1920^2) +
              lit_1920 + i(farm_1920) + nchild_1920 | state,
            data = women[married_1920 == 0], cluster = ~county_id)

# Occupational score change (conditional on working)
d4 <- feols(d_occscore ~ exposure_std + age_1920 + I(age_1920^2) +
              lit_1920 + i(farm_1920) + nchild_1920 | state,
            data = women[lfp_1920 == 1 | lfp_1930 == 1], cluster = ~county_id)

cat("Domestic service mechanism:\n")
print(summary(d1))
print(summary(d2))
print(summary(d3))
cat("Occupational score change:\n")
print(summary(d4))

# --------------------------------------------------------------------------
# Save results objects
# --------------------------------------------------------------------------
results <- list(
  m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5, m6 = m6,
  d1 = d1, d2 = d2, d3 = d3, d4 = d4,
  sumstats = sumstats, sumstats_marst = sumstats_marst, sumstats_q = sumstats_q,
  n_women = nrow(women),
  n_married = sum(women$married_1920),
  n_unmarried = sum(women$married_1920 == 0),
  n_counties = uniqueN(women$county_id),
  sd_y = sd(women$d_lfp),
  sd_y_married = sd(women[married_1920 == 1]$d_lfp),
  sd_y_unmarried = sd(women[married_1920 == 0]$d_lfp),
  sd_exposure = sd(women$exposure),
  mean_exposure = mean(women$exposure)
)

saveRDS(results, "../data/main_results.rds")

# --------------------------------------------------------------------------
# Write diagnostics.json for validator
# --------------------------------------------------------------------------
diag <- list(
  n_treated = uniqueN(women[exposure_q %in% c("Q3", "Q4")]$county_id),
  n_pre = 1L,  # Placebo period: 1910-1920
  n_obs = nrow(women)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

cat("Main analysis complete. Results saved.\n")
