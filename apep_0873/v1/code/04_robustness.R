# 04_robustness.R — apep_0873: The Pill Pipeline
# Robustness checks for the disability-opioid relationship
source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "panel_clean.csv"))
cat("Panel loaded:", nrow(panel), "obs\n")

# ═══════════════════════════════════════════════════════════════════
# 1. Lagged disability rate (ACS is 5-year rolling; try 1-year lag)
# ═══════════════════════════════════════════════════════════════════
cat("\n=== Lagged specifications ===\n")

panel[, disability_lag1 := shift(disability_rate, 1), by = state_fips]
panel[, disability_lag2 := shift(disability_rate, 2), by = state_fips]

m_lag1 <- feols(opioid_rate ~ disability_lag1 + unemp_rate |
                state_fips + year,
                data = panel, vcov = ~state_fips)

m_lag2 <- feols(opioid_rate ~ disability_lag2 + unemp_rate |
                state_fips + year,
                data = panel, vcov = ~state_fips)

cat("  Lag 1: β =", round(coef(m_lag1)["disability_lag1"], 1), "\n")
cat("  Lag 2: β =", round(coef(m_lag2)["disability_lag2"], 1), "\n")

# ═══════════════════════════════════════════════════════════════════
# 2. Log-log specification
# ═══════════════════════════════════════════════════════════════════
cat("\n=== Log-log specification ===\n")

m_log <- feols(log_opioid_rate ~ log_disability + unemp_rate |
               state_fips + year,
               data = panel, vcov = ~state_fips)

m_log_rx <- feols(log_rx_opioid_rate ~ log_disability + unemp_rate |
                  state_fips + year,
                  data = panel[!is.na(rx_opioid_rate) & rx_opioid_rate > 0],
                  vcov = ~state_fips)

cat("  Log opioid: ε =", round(coef(m_log)["log_disability"], 3), "\n")
cat("  Log Rx opioid: ε =", round(coef(m_log_rx)["log_disability"], 3), "\n")

# ═══════════════════════════════════════════════════════════════════
# 3. Population-weighted regressions
# ═══════════════════════════════════════════════════════════════════
cat("\n=== Population-weighted ===\n")

m_wt <- feols(opioid_rate ~ disability_rate + unemp_rate |
              state_fips + year,
              data = panel, vcov = ~state_fips,
              weights = ~population)

m_wt_rx <- feols(rx_opioid_rate ~ disability_rate + unemp_rate |
                 state_fips + year,
                 data = panel[!is.na(rx_opioid_rate)], vcov = ~state_fips,
                 weights = ~population)

cat("  Weighted opioid: β =", round(coef(m_wt)["disability_rate"], 1), "\n")
cat("  Weighted Rx: β =", round(coef(m_wt_rx)["disability_rate"], 1), "\n")

# ═══════════════════════════════════════════════════════════════════
# 4. Exclude extreme states (WV, OH, NH — highest opioid rates)
# ═══════════════════════════════════════════════════════════════════
cat("\n=== Excluding high-opioid states ===\n")

# Identify top 3 states by mean opioid rate
state_means <- panel[, .(mean_rate = mean(opioid_rate, na.rm = TRUE)), by = state]
top3 <- state_means[order(-mean_rate)]$state[1:3]
cat("  Excluding:", paste(top3, collapse = ", "), "\n")

m_excl <- feols(opioid_rate ~ disability_rate + unemp_rate |
                state_fips + year,
                data = panel[!state %in% top3], vcov = ~state_fips)

cat("  Excl. top 3: β =", round(coef(m_excl)["disability_rate"], 1), "\n")

# ═══════════════════════════════════════════════════════════════════
# 5. Pre-fentanyl vs fentanyl era
# ═══════════════════════════════════════════════════════════════════
cat("\n=== Era comparison ===\n")

# Pre-2019 (prescription-dominated) vs post-2019 (fentanyl-dominated)
m_pre <- feols(opioid_rate ~ disability_rate + unemp_rate |
               state_fips + year,
               data = panel[year <= 2018], vcov = ~state_fips)

m_post <- feols(opioid_rate ~ disability_rate + unemp_rate |
                state_fips + year,
                data = panel[year >= 2019], vcov = ~state_fips)

# Rx opioid rate in early period
m_rx_pre <- feols(rx_opioid_rate ~ disability_rate + unemp_rate |
                  state_fips + year,
                  data = panel[year <= 2018 & !is.na(rx_opioid_rate)],
                  vcov = ~state_fips)

m_rx_post <- feols(rx_opioid_rate ~ disability_rate + unemp_rate |
                   state_fips + year,
                   data = panel[year >= 2019 & !is.na(rx_opioid_rate)],
                   vcov = ~state_fips)

cat("  Pre-2019 (all opioids): β =", round(coef(m_pre)["disability_rate"], 1), "\n")
cat("  Post-2019 (all opioids): β =", round(coef(m_post)["disability_rate"], 1), "\n")
cat("  Pre-2019 (Rx): β =", round(coef(m_rx_pre)["disability_rate"], 1), "\n")
cat("  Post-2019 (Rx): β =", round(coef(m_rx_post)["disability_rate"], 1), "\n")

# ═══════════════════════════════════════════════════════════════════
# 6. State-specific linear trends
# ═══════════════════════════════════════════════════════════════════
cat("\n=== State trends ===\n")

panel[, year_c := year - 2015]
m_trends <- feols(opioid_rate ~ disability_rate + unemp_rate |
                  state_fips[year_c] + year,
                  data = panel, vcov = ~state_fips)

cat("  State trends: β =", round(coef(m_trends)["disability_rate"], 1), "\n")

# ═══════════════════════════════════════════════════════════════════
# Save all robustness results
# ═══════════════════════════════════════════════════════════════════
save(m_lag1, m_lag2, m_log, m_log_rx, m_wt, m_wt_rx, m_excl,
     m_pre, m_post, m_rx_pre, m_rx_post, m_trends,
     file = file.path(data_dir, "robustness_results.RData"))
cat("\n  Saved robustness_results.RData\n")

cat("=== Robustness checks complete ===\n")
