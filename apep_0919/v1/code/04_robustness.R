# ===========================================================================
# 04_robustness.R — Robustness checks for apep_0919
# Whistleblower Shield and Corruption Exposure
# ===========================================================================

source("00_packages.R")

data_dir <- "../data/"
tables_dir <- "../tables/"

panel <- fread(paste0(data_dir, "analysis_panel.csv"))
panel[, iso2 := as.factor(iso2)]
panel[, year_f := as.factor(year)]
panel[, id := as.integer(as.factor(iso2))]

results <- readRDS(paste0(data_dir, "main_results.rds"))

cat("=== ROBUSTNESS CHECKS ===\n\n")

# ===========================================================================
# 1. Wild Cluster Bootstrap (addresses small cluster count = 27)
# ===========================================================================

cat("--- 1. Wild Cluster Bootstrap ---\n")

# WCB for main TWFE corruption result
wcb_corruption <- boottest(
  results$twfe_corruption,
  param = "treated",
  B = 9999,
  clustid = "iso2",
  type = "webb"
)
cat("WCB p-value (corruption):", wcb_corruption$p_val, "\n")
cat("WCB CI:", wcb_corruption$conf_int, "\n")

# Fraud WCB: re-estimate excluding singletons
fraud_data <- panel[!is.na(ln_fraud_pc)]
fraud_data <- fraud_data[, n_yr := .N, by = iso2][n_yr > 1][, n_yr := NULL]
fraud_data <- fraud_data[, n_ct := .N, by = year_f][n_ct > 1][, n_ct := NULL]
twfe_fraud_clean <- feols(
  ln_fraud_pc ~ treated + ln_gdp_pc | iso2 + year_f,
  data = fraud_data,
  cluster = ~iso2,
  fixef.rm = "none"
)
wcb_fraud <- tryCatch({
  boottest(twfe_fraud_clean, param = "treated", B = 9999, clustid = "iso2", type = "webb")
}, error = function(e) {
  cat("WCB fraud failed:", e$message, "\n")
  list(p_val = NA, conf_int = c(NA, NA))
})
cat("WCB p-value (fraud):", wcb_fraud$p_val, "\n")

wcb_cpi <- boottest(
  results$twfe_cpi,
  param = "treated",
  B = 9999,
  clustid = "iso2",
  type = "webb"
)
cat("WCB p-value (CPI):", wcb_cpi$p_val, "\n")

# ===========================================================================
# 2. Placebo: Non-crime outcomes (GDP growth should NOT respond)
# ===========================================================================

cat("\n--- 2. Placebo: GDP per capita ---\n")

placebo_gdp <- feols(
  ln_gdp_pc ~ treated | iso2 + year_f,
  data = panel[!is.na(ln_gdp_pc)],
  cluster = ~iso2
)
cat("Placebo (GDP):\n")
print(summary(placebo_gdp))

# ===========================================================================
# 3. Exclude COVID years (2020-2021) from pre-period
# ===========================================================================

cat("\n--- 3. Exclude COVID years ---\n")

panel_no_covid <- panel[!(year %in% c(2020, 2021))]

twfe_nocovid <- feols(
  ln_corruption_pc ~ treated + ln_gdp_pc | iso2 + year_f,
  data = panel_no_covid[!is.na(ln_corruption_pc)],
  cluster = ~iso2
)
cat("TWFE excluding 2020-2021:\n")
print(summary(twfe_nocovid))

# ===========================================================================
# 4. Leave-one-out: drop each country
# ===========================================================================

cat("\n--- 4. Leave-one-out ---\n")

countries <- unique(panel$iso2)
loo_results <- data.table()

for (c in countries) {
  loo_data <- panel[iso2 != c & !is.na(ln_corruption_pc)]
  loo_fit <- feols(
    ln_corruption_pc ~ treated + ln_gdp_pc | iso2 + year_f,
    data = loo_data,
    cluster = ~iso2
  )
  loo_results <- rbind(loo_results, data.table(
    dropped = as.character(c),
    coef = coef(loo_fit)["treated"],
    se = se(loo_fit)["treated"]
  ))
}

cat("Leave-one-out range:\n")
cat("  Min coef:", round(min(loo_results$coef), 4), "\n")
cat("  Max coef:", round(max(loo_results$coef), 4), "\n")
cat("  Most influential country (max |change|):",
    loo_results[which.max(abs(coef - coef(results$twfe_corruption)["treated"])), dropped], "\n")

# ===========================================================================
# 5. Heterogeneity: Early vs. late adopters
# ===========================================================================

cat("\n--- 5. Heterogeneity: Early vs Late Adopters ---\n")

panel[, early_adopter := fifelse(g > 0 & g <= 2022, 1L, 0L)]

het_early <- feols(
  ln_corruption_pc ~ treated:early_adopter + treated:I(1 - early_adopter) + ln_gdp_pc | iso2 + year_f,
  data = panel[!is.na(ln_corruption_pc)],
  cluster = ~iso2
)
cat("Early vs Late Adopters:\n")
print(summary(het_early))

# ===========================================================================
# 6. Heterogeneity: Prior whistleblower laws
# Pre-existing frameworks: UK (n/a), France, Italy, Ireland had partial protections
# ===========================================================================

cat("\n--- 6. Heterogeneity: Prior WB Framework ---\n")

# Countries with pre-existing (partial) whistleblower laws before the directive
prior_wb <- c("FR", "IE", "IT", "NL", "SE", "DK", "LU", "HR")
panel[, has_prior_wb := fifelse(iso2 %in% prior_wb, 1L, 0L)]

het_prior <- feols(
  ln_corruption_pc ~ treated:has_prior_wb + treated:I(1 - has_prior_wb) + ln_gdp_pc | iso2 + year_f,
  data = panel[!is.na(ln_corruption_pc)],
  cluster = ~iso2
)
cat("Prior WB Framework:\n")
print(summary(het_prior))

# ===========================================================================
# 7. Alternative outcome: raw counts (not per-capita)
# ===========================================================================

cat("\n--- 7. Alternative: Log counts (not per-capita) ---\n")

panel[, ln_corruption_count := log(corruption_count + 1)]

twfe_counts <- feols(
  ln_corruption_count ~ treated + ln_gdp_pc + log(population) | iso2 + year_f,
  data = panel[!is.na(ln_corruption_count)],
  cluster = ~iso2
)
cat("TWFE with log counts + log(pop):\n")
print(summary(twfe_counts))

# ===========================================================================
# 8. Save robustness results
# ===========================================================================

rob_results <- list(
  wcb_corruption = wcb_corruption,
  wcb_fraud = wcb_fraud,
  wcb_cpi = wcb_cpi,
  placebo_gdp = placebo_gdp,
  twfe_nocovid = twfe_nocovid,
  loo_results = loo_results,
  het_early = het_early,
  het_prior = het_prior,
  twfe_counts = twfe_counts
)

saveRDS(rob_results, paste0(data_dir, "robustness_results.rds"))

cat("\n=== Robustness checks complete ===\n")
