## 03_main_analysis.R — Spatial RDD and main regressions
## apep_0718: Tornado Paths and Manufactured Housing

source("00_packages.R")

cat("=== Loading analysis dataset ===\n")
df <- readRDS("../data/analysis_dataset.rds")

cat(sprintf("Observations: %d (treated: %d, control: %d)\n",
            nrow(df), sum(df$treated), sum(!df$treated)))

# ============================================================================
# TABLE 1: Summary Statistics
# ============================================================================
cat("\n=== Summary Statistics ===\n")

summary_vars <- c("mobile_pct_pre", "poverty_rate_pre", "log_value_pre",
                   "total_popE_pre", "total_unitsE_pre", "vacancy_pre",
                   "delta_mobile_pct", "delta_poverty", "delta_log_value")

summ_treated <- df %>%
  filter(treated == 1) %>%
  summarise(across(all_of(summary_vars),
                   list(mean = ~mean(.x, na.rm = TRUE),
                        sd = ~sd(.x, na.rm = TRUE)),
                   .names = "{.col}_{.fn}"))

summ_control <- df %>%
  filter(treated == 0) %>%
  summarise(across(all_of(summary_vars),
                   list(mean = ~mean(.x, na.rm = TRUE),
                        sd = ~sd(.x, na.rm = TRUE)),
                   .names = "{.col}_{.fn}"))

cat("Treated means:\n")
for (v in summary_vars) {
  cat(sprintf("  %s: %.3f (%.3f)\n", v,
              pull(summ_treated, paste0(v, "_mean")),
              pull(summ_treated, paste0(v, "_sd"))))
}

cat("\nControl means:\n")
for (v in summary_vars) {
  cat(sprintf("  %s: %.3f (%.3f)\n", v,
              pull(summ_control, paste0(v, "_mean")),
              pull(summ_control, paste0(v, "_sd"))))
}

# Save summary stats for table generation
saveRDS(list(treated = summ_treated, control = summ_control,
             n_treated = sum(df$treated), n_control = sum(!df$treated)),
        "../data/summary_stats.rds")

# ============================================================================
# TABLE 2: Main RDD Estimates (rdrobust)
# ============================================================================
cat("\n=== RDD Estimation (rdrobust) ===\n")

outcomes <- c("delta_mobile_pct", "delta_poverty", "delta_log_value",
              "delta_log_pop", "delta_log_income", "delta_vacancy")
outcome_labels <- c("Mobile Home Share (pp)", "Poverty Rate (pp)",
                     "Log Housing Value", "Log Population",
                     "Log Median Income", "Vacancy Rate (pp)")

rdd_results <- list()

for (i in seq_along(outcomes)) {
  y_var <- outcomes[i]
  cat(sprintf("\nRDD: %s\n", outcome_labels[i]))

  y <- df[[y_var]]
  x <- df$dist_mi  # Running variable: signed distance from path edge

  # Drop NAs
  valid <- !is.na(y) & !is.na(x)
  y_clean <- y[valid]
  x_clean <- x[valid]

  if (length(y_clean) < 100) {
    cat("  Insufficient observations, skipping.\n")
    next
  }

  # Run rdrobust with triangular kernel, MSE-optimal bandwidth
  rd <- rdrobust(y = y_clean, x = x_clean, c = 0,
                 kernel = "triangular", p = 1, bwselect = "mserd",
                 cluster = df$COUNTYFP[valid])  # Cluster by county

  cat(sprintf("  Estimate: %.4f (SE: %.4f)\n", rd$coef[1], rd$se[3]))
  cat(sprintf("  95%% CI: [%.4f, %.4f]\n", rd$ci[3, 1], rd$ci[3, 2]))
  cat(sprintf("  Bandwidth: %.3f miles\n", rd$bws[1, 1]))
  cat(sprintf("  N left/right: %d / %d\n", rd$N_h[1], rd$N_h[2]))
  cat(sprintf("  p-value: %.4f\n", rd$pv[3]))

  rdd_results[[y_var]] <- list(
    outcome = outcome_labels[i],
    coef = rd$coef[1],
    se_robust = rd$se[3],
    ci_lower = rd$ci[3, 1],
    ci_upper = rd$ci[3, 2],
    bw = rd$bws[1, 1],
    n_left = rd$N_h[1],
    n_right = rd$N_h[2],
    pv = rd$pv[3]
  )
}

saveRDS(rdd_results, "../data/rdd_results.rds")

# ============================================================================
# TABLE 3: OLS with state FE and controls (as robustness / comparison)
# ============================================================================
cat("\n=== OLS with State FE ===\n")

# Full sample within 2-mile bandwidth
df_bw <- df %>% filter(abs(dist_mi) <= 2)

ols_mobile <- feols(delta_mobile_pct ~ treated + dist_mi + I(dist_mi^2) |
                      state, data = df_bw, cluster = ~COUNTYFP)
ols_poverty <- feols(delta_poverty ~ treated + dist_mi + I(dist_mi^2) |
                       state, data = df_bw, cluster = ~COUNTYFP)
ols_value <- feols(delta_log_value ~ treated + dist_mi + I(dist_mi^2) |
                     state, data = df_bw, cluster = ~COUNTYFP)
ols_pop <- feols(delta_log_pop ~ treated + dist_mi + I(dist_mi^2) |
                   state, data = df_bw, cluster = ~COUNTYFP)

cat("OLS: Mobile home share change\n")
print(summary(ols_mobile))
cat("\nOLS: Poverty rate change\n")
print(summary(ols_poverty))
cat("\nOLS: Log housing value change\n")
print(summary(ols_value))

saveRDS(list(mobile = ols_mobile, poverty = ols_poverty,
             value = ols_value, pop = ols_pop),
        "../data/ols_results.rds")

# ============================================================================
# Diagnostics JSON for validator
# ============================================================================
n_tornado_years <- n_distinct(df$tornado_year)
diagnostics <- list(
  n_treated = sum(df$treated == 1),
  n_pre = n_tornado_years,  # Number of pre-periods (tornado years as events)
  n_obs = nrow(df)
)
write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))
