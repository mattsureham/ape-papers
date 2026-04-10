source("00_packages.R")

cat("=== Main Analysis ===\n")

panel <- readRDS("../data/analysis_panel.rds")

# ---------------------------------------------------------------
# 1. TWFE DiD: Effect of Vorrangpruefung suspension on employment
# ---------------------------------------------------------------
cat("\n--- TWFE DiD regressions ---\n")

# Baseline: log employment
m1 <- feols(log_emp ~ treat_post | geo + year, data = panel,
            cluster = ~nuts2)

# With state-year trends
m2 <- feols(log_emp ~ treat_post | geo + state^year, data = panel,
            cluster = ~nuts2)

# GDP per capita
m3 <- feols(log_gdp ~ treat_post | geo + year, data = panel,
            cluster = ~nuts2)

# Employment per capita
m4 <- feols(emp_per_capita ~ treat_post | geo + year, data = panel,
            cluster = ~nuts2)

# GDP per capita
m5 <- feols(gdp_per_capita ~ treat_post | geo + year, data = panel,
            cluster = ~nuts2)

cat("\n--- Main results ---\n")
etable(m1, m2, m3, m4, m5,
       headers = c("Log Emp", "Log Emp (S×Y)", "Log GDP", "Emp/Cap", "GDP/Cap"),
       se.below = TRUE, fitstat = ~ n + r2)

# ---------------------------------------------------------------
# 2. Event study
# ---------------------------------------------------------------
cat("\n--- Event study ---\n")

panel <- panel %>%
  mutate(
    event_time = year - 2016,
    event_factor = factor(event_time)
  )

# Drop 2016 (treatment year) as reference
panel_es <- panel %>% filter(event_time != 0)

es_m1 <- feols(log_emp ~ i(event_factor, suspended, ref = "-1") | geo + year,
               data = panel_es, cluster = ~nuts2)

cat("\nEvent study coefficients:\n")
print(coeftable(es_m1))

# ---------------------------------------------------------------
# 3. Triple-difference: high unemployment × suspended × post
# ---------------------------------------------------------------
cat("\n--- Triple-difference (using pre-treatment unemployment) ---\n")

panel <- panel %>%
  group_by(geo) %>%
  mutate(
    pre_unemp_avg = mean(unemp_rate[year <= 2015], na.rm = TRUE)
  ) %>%
  ungroup() %>%
  mutate(
    high_unemp = if_else(pre_unemp_avg > median(pre_unemp_avg, na.rm = TRUE), 1L, 0L)
  )

m_triple <- feols(log_emp ~ treat_post * high_unemp | geo + year,
                  data = panel, cluster = ~nuts2)
cat("\nTriple-diff (high unemployment × suspension × post):\n")
etable(m_triple)

# ---------------------------------------------------------------
# 4. Store results for tables
# ---------------------------------------------------------------
results <- list(
  m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5,
  es_m1 = es_m1, m_triple = m_triple
)
saveRDS(results, "../data/main_results.rds")

# ---------------------------------------------------------------
# 5. Write diagnostics.json for validator
# ---------------------------------------------------------------
n_treated <- panel %>% filter(suspended == 1) %>% distinct(geo) %>% nrow()
n_pre <- length(unique(panel$year[panel$year < 2017]))
n_obs <- nrow(panel)

write_json(
  list(n_treated = n_treated, n_pre = n_pre, n_obs = n_obs),
  "../data/diagnostics.json", auto_unbox = TRUE
)

cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated, n_pre, n_obs))
cat("Results saved to data/main_results.rds\n")
