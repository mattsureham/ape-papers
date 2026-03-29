# 04_robustness.R — Robustness checks
# APEP-1106: The Pollinator Dividend

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")

# -------------------------------------------------------------------
# 1. Alternative outcome: Log bee observations with effort control
# -------------------------------------------------------------------
cat("=== ALTERNATIVE OUTCOME: LOG BEE OBS ===\n")

m_log <- feols(log_bee_obs ~ treat_dd + log_insecta | country_iso2 + year,
               data = panel,
               cluster = ~country_iso2)
summary(m_log)

m_log_ddd <- feols(log_bee_obs ~ treat_ddd + treat_dd +
                     post_ban:sugar_beet_country + log_insecta |
                     country_iso2 + year,
                   data = panel,
                   cluster = ~country_iso2)
summary(m_log_ddd)

# -------------------------------------------------------------------
# 2. Leave-one-country-out
# -------------------------------------------------------------------
cat("\n=== LEAVE-ONE-COUNTRY-OUT ===\n")

derog_countries <- unique(panel$country_iso2[panel$ever_derog == 1])
loo_results <- list()

for (cc in derog_countries) {
  loo_data <- panel %>% filter(country_iso2 != cc)
  m_loo <- feols(bee_share ~ treat_dd | country_iso2 + year,
                 data = loo_data,
                 cluster = ~country_iso2)
  loo_results[[cc]] <- data.frame(
    dropped = cc,
    coef = coef(m_loo)["treat_dd"],
    se = se(m_loo)["treat_dd"],
    stringsAsFactors = FALSE
  )
}

loo_df <- bind_rows(loo_results)
cat("Leave-one-out coefficient range:",
    round(min(loo_df$coef), 5), "to", round(max(loo_df$coef), 5), "\n")
print(loo_df)

# -------------------------------------------------------------------
# 3. Pre-trend test: Leads specification
# -------------------------------------------------------------------
cat("\n=== PRE-TREND TEST ===\n")

# Create relative time indicators manually
panel <- panel %>%
  mutate(
    rel_time = ifelse(ever_derog == 1,
                      year - first_derog_year,
                      NA_integer_)
  )

# Event study with leads and lags using TWFE
# Create dummies for rel_time = -4, -3, -2, 0, 1, 2, 3 (omit -1)
panel_es <- panel %>%
  filter(ever_derog == 1 | ever_derog == 0) %>%
  mutate(
    # For never-treated, assign arbitrary rel_time far from zero
    rel_time_fill = ifelse(is.na(rel_time), -99, rel_time),
    lead4 = as.integer(rel_time_fill == -4),
    lead3 = as.integer(rel_time_fill == -3),
    lead2 = as.integer(rel_time_fill == -2),
    # lag0 through lag3
    lag0  = as.integer(rel_time_fill == 0),
    lag1  = as.integer(rel_time_fill == 1),
    lag2  = as.integer(rel_time_fill == 2),
    lag3  = as.integer(rel_time_fill == 3)
  )

m_es <- feols(bee_share ~ lead4 + lead3 + lead2 +
                lag0 + lag1 + lag2 + lag3 | country_iso2 + year,
              data = panel_es,
              cluster = ~country_iso2)
summary(m_es)

cat("Pre-trend coefficients (should be near zero):\n")
cat("  t-4:", round(coef(m_es)["lead4"], 5), "\n")
cat("  t-3:", round(coef(m_es)["lead3"], 5), "\n")
cat("  t-2:", round(coef(m_es)["lead2"], 5), "\n")

# -------------------------------------------------------------------
# 4. HonestDiD sensitivity analysis
# -------------------------------------------------------------------
cat("\n=== HONESTDID SENSITIVITY ===\n")

honest_result <- tryCatch({
  # Extract event study coefficients and variance-covariance matrix
  es_coefs <- coef(m_es)
  es_vcov <- vcov(m_es)

  # Identify pre-period and post-period indices
  pre_names <- c("lead4", "lead3", "lead2")
  post_names <- c("lag0", "lag1", "lag2", "lag3")

  pre_idx <- which(names(es_coefs) %in% pre_names)
  post_idx <- which(names(es_coefs) %in% post_names)

  # Relative magnitudes approach
  delta_rm_results <- HonestDiD::createSensitivityResults_relativeMagnitudes(
    betahat = es_coefs[c(pre_idx, post_idx)],
    sigma = es_vcov[c(pre_idx, post_idx), c(pre_idx, post_idx)],
    numPrePeriods = length(pre_idx),
    numPostPeriods = length(post_idx),
    Mbarvec = seq(0.5, 2, by = 0.5)
  )
  cat("HonestDiD relative magnitudes:\n")
  print(delta_rm_results)
  delta_rm_results
}, error = function(e) {
  cat("HonestDiD failed:", e$message, "\n")
  NULL
})

# -------------------------------------------------------------------
# 5. Intensive margin: Sugar beet area as continuous treatment
# -------------------------------------------------------------------
cat("\n=== INTENSIVE MARGIN ===\n")

panel <- panel %>%
  mutate(
    sb_area_treat = ifelse(has_derogation == 1, avg_sb_area_ha / 1000, 0)
  )

m_intensive <- feols(bee_share ~ sb_area_treat | country_iso2 + year,
                     data = panel,
                     cluster = ~country_iso2)
summary(m_intensive)

# -------------------------------------------------------------------
# 6. Save robustness results
# -------------------------------------------------------------------
robust_results <- list(
  m_log = m_log,
  m_log_ddd = m_log_ddd,
  loo_df = loo_df,
  m_es = m_es,
  honest_result = honest_result,
  m_intensive = m_intensive
)
saveRDS(robust_results, "../data/robustness_results.rds")

cat("\nRobustness checks complete.\n")
