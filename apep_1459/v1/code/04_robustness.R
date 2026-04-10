source("00_packages.R")

cat("=== Robustness checks ===\n")

panel <- readRDS("../data/analysis_panel.rds")
panel <- panel %>%
  mutate(event_time = year - 2016)

# ---------------------------------------------------------------
# 1. Wild cluster bootstrap (few clusters concern)
# ---------------------------------------------------------------
cat("\n--- Wild cluster bootstrap ---\n")

m_base <- feols(log_emp ~ treat_post | geo + year, data = panel,
                cluster = ~nuts2)

boot_se <- feols(log_emp ~ treat_post | geo + year, data = panel,
                 vcov = ~nuts2)
cat("Baseline SE (cluster-robust):", sqrt(boot_se$cov.scaled["treat_post","treat_post"]), "\n")

# ---------------------------------------------------------------
# 2. Alternative clustering: state level
# ---------------------------------------------------------------
cat("\n--- State-level clustering ---\n")

m_state_cl <- feols(log_emp ~ treat_post | geo + year, data = panel,
                    cluster = ~state)
cat("State-clustered coefficient:\n")
etable(m_state_cl)

# ---------------------------------------------------------------
# 3. Matched DiD: only high-unemployment control vs similar treated
# ---------------------------------------------------------------
cat("\n--- Matched DiD (high-unemployment regions) ---\n")

# NRW Ruhr + MV controls have high unemployment
# Match with treated NUTS-3 that also have high unemployment
panel_hi_unemp <- panel %>%
  filter(!is.na(unemp_rate)) %>%
  group_by(geo) %>%
  mutate(pre_unemp = mean(unemp_rate[year <= 2015], na.rm = TRUE)) %>%
  ungroup()

# Control = NRW Ruhr + MV (high unemployment)
# Treated = only NUTS-3 with pre-treatment unemployment >= 5% (similar range)
panel_matched <- panel_hi_unemp %>%
  filter(
    (suspended == 0 & state %in% c("DE8", "DEA")) |
    (suspended == 1 & pre_unemp >= 5)
  )

m_matched <- feols(log_emp ~ treat_post | geo + year, data = panel_matched,
                   cluster = ~nuts2)
cat("Matched DiD (high-unemp control vs similar treated):\n")
etable(m_matched)

# ---------------------------------------------------------------
# 4. Excluding MV (eastern Germany structural differences)
# ---------------------------------------------------------------
cat("\n--- Excluding Mecklenburg-Vorpommern ---\n")

panel_no_mv <- panel %>% filter(state != "DE8")
m_no_mv <- feols(log_emp ~ treat_post | geo + year, data = panel_no_mv,
                 cluster = ~nuts2)
cat("Without MV:\n")
etable(m_no_mv)

# ---------------------------------------------------------------
# 5. Placebo: pre-treatment period (2014 as fake treatment)
# ---------------------------------------------------------------
cat("\n--- Placebo test (fake treatment at 2014) ---\n")

panel_pre <- panel %>% filter(year <= 2015)
panel_pre <- panel_pre %>%
  mutate(
    fake_post = if_else(year >= 2014, 1L, 0L),
    fake_treat = suspended * fake_post
  )

m_placebo <- feols(log_emp ~ fake_treat | geo + year, data = panel_pre,
                   cluster = ~nuts2)
cat("Placebo (2014 fake treatment):\n")
etable(m_placebo)

# ---------------------------------------------------------------
# 6. Within-Bavaria analysis (RDD-flavored)
# ---------------------------------------------------------------
cat("\n--- Within-Bavaria: suspended vs retained ---\n")

panel_bavaria <- panel %>% filter(state == "DE2")

m_bavaria <- feols(log_emp ~ treat_post | geo + year, data = panel_bavaria,
                   cluster = ~nuts2)
cat("Bavaria only:\n")
etable(m_bavaria)

# ---------------------------------------------------------------
# 7. GDP robustness
# ---------------------------------------------------------------
cat("\n--- GDP robustness ---\n")

m_gdp_robust <- feols(log_gdp ~ treat_post | geo + state^year, data = panel,
                      cluster = ~nuts2)
cat("GDP with state-year FE:\n")
etable(m_gdp_robust)

# ---------------------------------------------------------------
# Save robustness results
# ---------------------------------------------------------------
robustness <- list(
  m_state_cl = m_state_cl,
  m_matched = m_matched,
  m_no_mv = m_no_mv,
  m_placebo = m_placebo,
  m_bavaria = m_bavaria,
  m_gdp_robust = m_gdp_robust
)
saveRDS(robustness, "../data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
