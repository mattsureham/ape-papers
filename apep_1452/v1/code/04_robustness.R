## 04_robustness.R — Robustness checks and placebo tests
source("00_packages.R")

data_dir <- "../data/"
panel <- readRDS(file.path(data_dir, "analysis_panel_final.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))

cat("=== Robustness Checks ===\n")

# ========================================================================
# 1. Placebo test: pre-2022 period only (fake treatment at 2020-Q1)
# ========================================================================
panel_pre <- panel |>
  filter(time_q < 2022.0) |>
  mutate(
    fake_post = as.integer(time_q >= 2020.0),
    early = as.integer(regime %in% c("pivot", "quarterly")),
    fake_treat = early * fake_post
  )

m_placebo <- feols(log_emp ~ fake_treat | nace + quarter,
                   data = panel_pre, cluster = ~nace)

cat("\n--- Placebo: Fake treatment at 2020-Q1 ---\n")
print(summary(m_placebo))

# ========================================================================
# 2. Alternative clustering: regime-level
# ========================================================================
m_regime_cluster <- feols(log_emp ~ treatment_intensity | nace + quarter,
                          data = panel, cluster = ~regime)

cat("\n--- Clustering by regime (3 clusters) ---\n")
print(summary(m_regime_cluster))

# ========================================================================
# 3. Wild cluster bootstrap (given few clusters)
# ========================================================================
# Use regime as cluster variable for wild bootstrap
m_wild <- feols(log_emp ~ treatment_intensity | nace + quarter,
                data = panel, vcov = twoway ~ nace + quarter)

cat("\n--- Two-way clustering (nace + quarter) ---\n")
print(summary(m_wild))

# ========================================================================
# 4. Exclude public sector (NACE O, P, Q — pivot-triggered, may have
#    different labor market dynamics)
# ========================================================================
panel_private <- panel |> filter(!nace %in% c("O", "P", "Q"))

m_private <- feols(log_emp ~ treatment_intensity | nace + quarter,
                   data = panel_private, cluster = ~nace)

cat("\n--- Private sector only (excl. O, P, Q) ---\n")
print(summary(m_private))

# ========================================================================
# 5. Alternative treatment: lag structure
# ========================================================================
# 1-quarter lagged indexation (adjustment takes time)
panel <- panel |>
  group_by(nace) |>
  arrange(time_q) |>
  mutate(treatment_lag1 = lag(treatment_intensity, 1)) |>
  ungroup()

m_lag <- feols(log_emp ~ treatment_lag1 | nace + quarter,
               data = panel |> filter(!is.na(treatment_lag1)),
               cluster = ~nace)

cat("\n--- Lagged treatment (1 quarter) ---\n")
print(summary(m_lag))

# ========================================================================
# 6. Hours worked as alternative outcome (if available)
# ========================================================================
if ("hours_worked" %in% names(panel) && sum(!is.na(panel$hours_worked)) > 50) {
  m_hours <- feols(log(hours_worked) ~ treatment_intensity | nace + quarter,
                   data = panel |> filter(!is.na(hours_worked) & hours_worked > 0),
                   cluster = ~nace)
  cat("\n--- Hours worked ---\n")
  print(summary(m_hours))
  results$m_hours <- m_hours
}

# Save all robustness results
results$m_placebo <- m_placebo
results$m_regime_cluster <- m_regime_cluster
results$m_private <- m_private
results$m_lag <- m_lag
saveRDS(results, file.path(data_dir, "all_results.rds"))

cat("\nRobustness checks complete.\n")
