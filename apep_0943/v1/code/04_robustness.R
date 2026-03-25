# 04_robustness.R — Robustness checks for apep_0943
source("00_packages.R")

panel <- readRDS("../data/panel_clean.rds")
results <- readRDS("../data/results.rds")

cat("=== Robustness Checks ===\n\n")

# =========================================================================
# 1. PLACEBO TREATMENT: Immigration referendum vote share
# =========================================================================
cat("--- Placebo 1: Immigration referendum as treatment ---\n")

# If CO2 vote share captures general political orientation rather than
# climate-specific preferences, immigration vote should also "predict"
m_placebo1 <- feols(new_bld_pc ~ immig_post | canton + year, data = panel,
                    cluster = ~canton)
cat("Immigration vote × Post:\n")
summary(m_placebo1)

# =========================================================================
# 2. PLACEBO OUTCOME: Population growth
# =========================================================================
cat("\n--- Placebo 2: Population growth as outcome ---\n")

panel[, pop_growth := (population - shift(population)) / shift(population),
      by = canton]
m_placebo2 <- feols(pop_growth ~ treat_post | canton + year, data = panel,
                    cluster = ~canton)
cat("CO2 × Post → Population growth:\n")
summary(m_placebo2)

# =========================================================================
# 3. ALTERNATIVE CLUSTERING
# =========================================================================
cat("\n--- Alternative clustering ---\n")

# HC1 robust (no clustering)
m_robust <- feols(new_bld_pc ~ treat_post | canton + year, data = panel,
                  vcov = "hetero")
cat("Heteroskedasticity-robust SEs:\n")
summary(m_robust)

# =========================================================================
# 4. PRE-TREND TEST
# =========================================================================
cat("\n--- Pre-trend test ---\n")

# Test whether CO2 vote share predicted construction trends BEFORE 2021
panel_pre <- panel[year <= 2020]
panel_pre[, co2_trend := co2_frac * (year - 2013)]

m_pretrend <- feols(new_bld_pc ~ co2_trend | canton + year, data = panel_pre,
                    cluster = ~canton)
cat("Pre-trend (CO2 × linear time, 2013-2020):\n")
summary(m_pretrend)

# Year-by-year pre-trend test
panel_pre[, yr := factor(year)]
m_pretrend2 <- feols(new_bld_pc ~ co2_frac:yr | canton + year,
                     data = panel_pre, cluster = ~canton)
cat("\nYear-by-year pre-trend coefficients:\n")
summary(m_pretrend2)

# =========================================================================
# 5. EXCLUDING OUTLIER CANTONS
# =========================================================================
cat("\n--- Leave-one-out: excluding each canton ---\n")

loo_results <- data.table()
for (ct in unique(panel$canton)) {
  m_loo <- feols(new_bld_pc ~ treat_post | canton + year,
                 data = panel[canton != ct], cluster = ~canton)
  loo_results <- rbind(loo_results, data.table(
    excluded = ct,
    coef = coef(m_loo)["treat_post"],
    se = sqrt(diag(vcov(m_loo)))["treat_post"]
  ))
}

cat("Leave-one-out analysis:\n")
cat(sprintf("  Coefficient range: [%.4f, %.4f]\n",
            min(loo_results$coef), max(loo_results$coef)))
cat(sprintf("  Main estimate: %.4f\n", coef(results$did_levels)["treat_post"]))
cat(sprintf("  Most influential canton: %s (exclusion → coef = %.4f)\n",
            loo_results[which.max(abs(coef - coef(results$did_levels)["treat_post"]))]$excluded,
            loo_results[which.max(abs(coef - coef(results$did_levels)["treat_post"]))]$coef))

# =========================================================================
# 6. WILD CLUSTER BOOTSTRAP (few clusters)
# =========================================================================
cat("\n--- Wild cluster bootstrap (26 clusters) ---\n")

if (!requireNamespace("fwildclusterboot", quietly = TRUE)) {
  install.packages("fwildclusterboot", repos = "https://cloud.r-project.org", quiet = TRUE)
}

tryCatch({
  library(fwildclusterboot)
  boot_result <- boottest(results$did_levels, param = "treat_post",
                          B = 9999, clustid = "canton", type = "webb")
  cat(sprintf("Wild bootstrap p-value: %.4f\n", pval(boot_result)))
  cat(sprintf("Wild bootstrap 95%% CI: [%.4f, %.4f]\n",
              boot_result$conf_int[1], boot_result$conf_int[2]))
}, error = function(e) {
  cat("Wild cluster bootstrap error:", e$message, "\n")
  cat("(26 cantons — standard clustering may be sufficient)\n")
})

# =========================================================================
# 7. ENERGY ACT 2017 AS ALTERNATIVE TREATMENT
# =========================================================================
cat("\n--- Energy Act 2017 vote share as treatment ---\n")

panel[, energy_post := energy_frac * post_co2]
m_energy <- feols(new_bld_pc ~ energy_post | canton + year, data = panel,
                  cluster = ~canton)
cat("Energy Act 2017 × Post:\n")
summary(m_energy)

# =========================================================================
# SAVE
# =========================================================================
rob_results <- list(
  placebo_immigration = m_placebo1,
  placebo_popgrowth = m_placebo2,
  robust_se = m_robust,
  pretrend_linear = m_pretrend,
  pretrend_yearly = m_pretrend2,
  loo = loo_results,
  energy_act = m_energy
)
saveRDS(rob_results, "../data/robustness_results.rds")
cat("\nRobustness results saved.\n")
