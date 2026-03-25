# 03_main_analysis.R — Main regressions for apep_0943
source("00_packages.R")

panel <- readRDS("../data/panel_clean.rds")

cat("=== Main Analysis ===\n\n")

# =========================================================================
# ANALYSIS 1: Does CO2 Act vote share predict post-2021 climate policy?
# =========================================================================
cat("--- Analysis 1: Climate Policy Adoption (Cross-Section) ---\n")

# Linear probability model: adopted ~ co2_frac
lpm1 <- lm(adopted_climate_law ~ co2_frac, data = panel[year == 2022])
cat("\nLPM: Climate law adoption ~ CO2 vote share\n")
print(summary(lpm1))

# Probit for robustness
probit1 <- glm(adopted_climate_law ~ co2_frac,
               family = binomial(link = "probit"),
               data = panel[year == 2022])
cat("\nProbit marginal effect at mean:\n")
beta_p <- coef(probit1)["co2_frac"]
xbar <- mean(panel[year == 2022]$co2_frac)
mfx <- beta_p * dnorm(coef(probit1)[1] + beta_p * xbar)
cat(sprintf("  dP/dx = %.3f (a 10pp increase in CO2 yes share → %.1f pp increase in adoption prob)\n",
            mfx, mfx * 0.10 * 100))

# =========================================================================
# ANALYSIS 2: Continuous DiD — New buildings per capita
# =========================================================================
cat("\n\n--- Analysis 2: Continuous DiD — New Building Construction ---\n")

# Main spec: new_bld_pc ~ co2_frac × post + canton FE + year FE
m1 <- feols(new_bld_pc ~ treat_post | canton + year, data = panel,
            cluster = ~canton)
cat("\nModel 1: new_bld_pc ~ CO2 × Post | canton + year FE\n")
summary(m1)

# With standardized treatment
m2 <- feols(new_bld_pc ~ treat_std_post | canton + year, data = panel,
            cluster = ~canton)
cat("\nModel 2: new_bld_pc ~ CO2_std × Post | canton + year FE\n")
summary(m2)

# Binary high/low
m3 <- feols(new_bld_pc ~ treat_high_post | canton + year, data = panel,
            cluster = ~canton)
cat("\nModel 3: new_bld_pc ~ CO2_high × Post | canton + year FE\n")
summary(m3)

# Log specification
m4 <- feols(log_bld_pc ~ treat_post | canton + year, data = panel,
            cluster = ~canton)
cat("\nModel 4: log(new_bld_pc) ~ CO2 × Post | canton + year FE\n")
summary(m4)

# With population control
m5 <- feols(new_bld_pc ~ treat_post + log(population) | canton + year,
            data = panel, cluster = ~canton)
cat("\nModel 5: new_bld_pc ~ CO2 × Post + log(pop) | canton + year FE\n")
summary(m5)

# =========================================================================
# ANALYSIS 3: Event Study
# =========================================================================
cat("\n\n--- Analysis 3: Event Study ---\n")

# Event study: new_bld_pc ~ Σ(1{t=k} × co2_frac) + canton FE + year FE
# Omit t = -1 (2021, the year of the vote)
et_vars <- paste0("et_", c(paste0("m", 8:2), 0:1))
et_formula <- as.formula(paste("new_bld_pc ~", paste(et_vars, collapse = " + "),
                               "| canton + year"))

m_es <- feols(et_formula, data = panel, cluster = ~canton)
cat("\nEvent study results:\n")
summary(m_es)

# Extract event study coefficients for plotting/table
es_coefs <- data.table(
  event_time = c(-8:-2, 0:1),
  coef = coef(m_es)[et_vars],
  se = sqrt(diag(vcov(m_es)))[et_vars]
)
es_coefs[, `:=`(ci_lo = coef - 1.96 * se, ci_hi = coef + 1.96 * se)]
cat("\nEvent study coefficients:\n")
print(es_coefs)

# =========================================================================
# ANALYSIS 4: DDD — Vacuum Period vs Post-KlG
# =========================================================================
cat("\n\n--- Analysis 4: Triple Difference (Vacuum vs Post-KlG) ---\n")

# The "vacuum period" is 2022-2023 (after CO2 Act rejection, before KlG)
# The post-KlG period is 2024+ (but we only have data through 2023)
# So the DDD tests whether the effect is concentrated in the vacuum period

m_ddd <- feols(new_bld_pc ~ co2_frac:vacuum_period + co2_frac:post_klg |
                 canton + year, data = panel, cluster = ~canton)
cat("\nDDD: Vacuum period (2022-2023) vs Post-KlG (2024+)\n")
summary(m_ddd)

# =========================================================================
# SAVE RESULTS
# =========================================================================
cat("\n--- Saving results ---\n")

# Save model objects
results <- list(
  lpm_adoption = lpm1,
  probit_adoption = probit1,
  did_levels = m1,
  did_std = m2,
  did_binary = m3,
  did_log = m4,
  did_popcontrol = m5,
  event_study = m_es,
  ddd = m_ddd,
  es_coefs = es_coefs
)
saveRDS(results, "../data/results.rds")
cat("Results saved to data/results.rds\n")

# Write diagnostics.json
diagnostics <- list(
  n_treated = sum(panel$co2_high == 1 & panel$year == 2022),
  n_pre = length(unique(panel$year[panel$year < 2022])),
  n_obs = nrow(panel),
  n_cantons = uniqueN(panel$canton),
  n_years = uniqueN(panel$year),
  treatment_range = c(min(panel$co2_yes), max(panel$co2_yes)),
  adoption_rate = mean(panel[year == 2022]$adopted_climate_law)
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat("Diagnostics saved to data/diagnostics.json\n")
