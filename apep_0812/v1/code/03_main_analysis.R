## 03_main_analysis.R — Main regressions
## apep_0812: Pump Prices and Le Pen

source("00_packages.R")

data_dir <- "../data"
df <- readRDS(file.path(data_dir, "analysis_panel.rds"))

cat(sprintf("Analysis sample: %d communes\n", nrow(df)))
cat(sprintf("Departments: %d\n", n_distinct(df$dept)))

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("\n=== Summary Statistics ===\n")

summ_vars <- df %>%
  summarise(
    n = n(),
    # Treatment
    car_share_mean = mean(car_share_11),
    car_share_sd = sd(car_share_11),
    car_share_p10 = quantile(car_share_11, 0.10),
    car_share_p90 = quantile(car_share_11, 0.90),
    # Outcomes
    lepen_12_mean = mean(lepen_pct_12, na.rm = TRUE),
    lepen_17_mean = mean(lepen_pct_17, na.rm = TRUE),
    lepen_22_mean = mean(lepen_pct_22, na.rm = TRUE),
    delta_17_mean = mean(delta_lepen_17_12, na.rm = TRUE),
    delta_17_sd = sd(delta_lepen_17_12, na.rm = TRUE),
    delta_22_mean = mean(delta_lepen_22_12, na.rm = TRUE),
    delta_22_sd = sd(delta_lepen_22_12, na.rm = TRUE),
    # Controls
    pop_mean = mean(pop, na.rm = TRUE),
    income_mean = mean(median_income, na.rm = TRUE),
    transit_share_mean = mean(transit_share_11, na.rm = TRUE)
  )

cat(sprintf("Car share 2011: %.1f%% (sd=%.1f%%), p10=%.1f%%, p90=%.1f%%\n",
            summ_vars$car_share_mean, summ_vars$car_share_sd,
            summ_vars$car_share_p10, summ_vars$car_share_p90))
cat(sprintf("LE PEN 2012: %.1f%%, 2017: %.1f%%, 2022: %.1f%%\n",
            summ_vars$lepen_12_mean, summ_vars$lepen_17_mean, summ_vars$lepen_22_mean))

# ============================================================
# TABLE 2: Main Results — First-Difference Regressions
# ============================================================
cat("\n=== Main Regressions ===\n")

# Model 1: No controls
m1 <- feols(delta_lepen_17_12 ~ car_share_11, data = df)

# Model 2: With département FE
m2 <- feols(delta_lepen_17_12 ~ car_share_11 | dept, data = df)

# Model 3: With département FE + controls
m3 <- feols(delta_lepen_17_12 ~ car_share_11 + log_pop + median_income |
              dept, data = df)

# Model 4: 2022 outcome (long-run)
m4 <- feols(delta_lepen_22_12 ~ car_share_11 | dept, data = df)

# Model 5: 2022 with controls
m5 <- feols(delta_lepen_22_12 ~ car_share_11 + log_pop + median_income |
              dept, data = df)

cat("Model 1 (no controls):\n")
cat(sprintf("  β = %.4f (se = %.4f), t = %.2f\n",
            coef(m1)["car_share_11"], se(m1)["car_share_11"],
            coef(m1)["car_share_11"] / se(m1)["car_share_11"]))
cat("Model 2 (dept FE):\n")
cat(sprintf("  β = %.4f (se = %.4f), t = %.2f\n",
            coef(m2)["car_share_11"], se(m2)["car_share_11"],
            coef(m2)["car_share_11"] / se(m2)["car_share_11"]))
cat("Model 3 (dept FE + controls):\n")
cat(sprintf("  β = %.4f (se = %.4f), t = %.2f\n",
            coef(m3)["car_share_11"], se(m3)["car_share_11"],
            coef(m3)["car_share_11"] / se(m3)["car_share_11"]))

# Interpretation
beta <- coef(m3)["car_share_11"]
iqr <- IQR(df$car_share_11)
cat(sprintf("\nInterpretation: A 1pp increase in car-commuting share →\n"))
cat(sprintf("  %.3f pp increase in ΔLE PEN (2017-2012)\n", beta))
cat(sprintf("  IQR (%.1f pp) effect: %.2f pp shift\n", iqr, beta * iqr))

# ============================================================
# TABLE 3: Pre-Trend Test (2007 → 2012)
# ============================================================
cat("\n=== Pre-Trend Test (Placebo: 2007→2012) ===\n")

df_pre <- df[!is.na(df$delta_lepen_12_07), ]
cat(sprintf("  %d communes with 2007 data\n", nrow(df_pre)))

m_pre1 <- feols(delta_lepen_12_07 ~ car_share_11, data = df_pre)
m_pre2 <- feols(delta_lepen_12_07 ~ car_share_11 | dept, data = df_pre)

cat(sprintf("  No controls: β = %.4f (se = %.4f), t = %.2f\n",
            coef(m_pre1)["car_share_11"], se(m_pre1)["car_share_11"],
            coef(m_pre1)["car_share_11"] / se(m_pre1)["car_share_11"]))
cat(sprintf("  Dept FE: β = %.4f (se = %.4f), t = %.2f\n",
            coef(m_pre2)["car_share_11"], se(m_pre2)["car_share_11"],
            coef(m_pre2)["car_share_11"] / se(m_pre2)["car_share_11"]))

# ============================================================
# Cluster SEs at département level
# ============================================================
cat("\n=== Département-Clustered SEs ===\n")

m2_cl <- feols(delta_lepen_17_12 ~ car_share_11 | dept,
               cluster = ~dept, data = df)
m3_cl <- feols(delta_lepen_17_12 ~ car_share_11 + log_pop + median_income |
                 dept, cluster = ~dept, data = df)

cat(sprintf("  Model 2 (cluster): β = %.4f (se = %.4f)\n",
            coef(m2_cl)["car_share_11"], se(m2_cl)["car_share_11"]))
cat(sprintf("  Model 3 (cluster): β = %.4f (se = %.4f)\n",
            coef(m3_cl)["car_share_11"], se(m3_cl)["car_share_11"]))

# ============================================================
# Save model objects
# ============================================================
models <- list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5,
               m_pre1 = m_pre1, m_pre2 = m_pre2,
               m2_cl = m2_cl, m3_cl = m3_cl)
saveRDS(models, file.path(data_dir, "models.rds"))

# ============================================================
# Write diagnostics.json for validator
# ============================================================
diag <- list(
  n_treated = nrow(df),  # continuous treatment, all communes treated
  n_pre = 2,  # 2007, 2012 pre-periods
  n_obs = nrow(df),
  n_departments = n_distinct(df$dept),
  car_share_sd = sd(df$car_share_11),
  outcome_sd = sd(df$delta_lepen_17_12, na.rm = TRUE)
)
write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat(sprintf("\nDiagnostics saved. N=%d, n_dept=%d\n", diag$n_obs, diag$n_departments))
