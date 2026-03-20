# =============================================================================
# 04_robustness.R — Robustness checks and placebos
# Paper: Fiscal Windfalls and Violence Against Women (apep_0726)
# =============================================================================

source("code/00_packages.R")

cat("=== ROBUSTNESS CHECKS ===\n")

df <- readRDS("data/analysis_df.rds")
cs_df <- df %>%
  group_by(mun_code, nearest_threshold) %>%
  summarise(
    population = mean(population, na.rm = TRUE),
    running_var = mean(running_var, na.rm = TRUE),
    above_threshold = first(above_threshold),
    dv_rate = mean(dv_rate, na.rm = TRUE),
    fem_homicide_rate = mean(fem_homicide_rate, na.rm = TRUE),
    male_homicide_rate = mean(male_homicide_rate, na.rm = TRUE),
    traffic_rate = mean(traffic_rate, na.rm = TRUE),
    state_code = first(state_code),
    threshold_fe = first(as.factor(nearest_threshold)),
    .groups = "drop"
  )

results <- readRDS("data/main_results.rds")
opt_bw <- results$opt_bw

# ---- 1. BANDWIDTH SENSITIVITY ----
cat("\n--- Bandwidth Sensitivity ---\n")

bw_grid <- c(opt_bw * 0.5, opt_bw * 0.75, opt_bw, opt_bw * 1.25, opt_bw * 1.5)
bw_results <- list()

for (bw in bw_grid) {
  df_bw <- cs_df %>% filter(abs(running_var) <= bw)
  m <- feols(dv_rate ~ above_threshold + running_var + I(above_threshold * running_var) |
               threshold_fe + state_code,
             data = df_bw, vcov = "hetero")
  bw_results[[as.character(bw)]] <- list(
    bandwidth = bw,
    coef = coef(m)["above_threshold"],
    se = se(m)["above_threshold"],
    n = nobs(m)
  )
  cat(sprintf("  bw=%.0f: β = %.3f (%.3f), N = %d\n",
              bw, coef(m)["above_threshold"], se(m)["above_threshold"], nobs(m)))
}

# ---- 2. PLACEBO: MALE HOMICIDE ----
cat("\n--- Placebo: Male Homicide Rate ---\n")

df_bw <- cs_df %>% filter(abs(running_var) <= opt_bw)

m_male_viol <- feols(male_homicide_rate ~ above_threshold + running_var +
                       I(above_threshold * running_var) |
                       threshold_fe + state_code,
                     data = df_bw, vcov = "hetero")

cat(sprintf("Male homicide: β = %.3f (%.3f)\n",
            coef(m_male_viol)["above_threshold"], se(m_male_viol)["above_threshold"]))

# ---- 3. PLACEBO: MALE HOMICIDE ----
cat("\n--- Placebo: Male Homicide Rate ---\n")

m_male_hom <- feols(male_homicide_rate ~ above_threshold + running_var +
                      I(above_threshold * running_var) |
                      threshold_fe + state_code,
                    data = df_bw, vcov = "hetero")

cat(sprintf("Male homicide: β = %.3f (%.3f)\n",
            coef(m_male_hom)["above_threshold"], se(m_male_hom)["above_threshold"]))

# ---- 4. PLACEBO: TRAFFIC ACCIDENTS ----
cat("\n--- Placebo: Traffic Death Rate ---\n")

m_traffic <- feols(traffic_rate ~ above_threshold + running_var +
                     I(above_threshold * running_var) |
                     threshold_fe + state_code,
                   data = df_bw, vcov = "hetero")

cat(sprintf("Traffic deaths: β = %.3f (%.3f)\n",
            coef(m_traffic)["above_threshold"], se(m_traffic)["above_threshold"]))

# ---- 5. PLACEBO CUTOFFS ----
cat("\n--- Placebo Cutoffs (fake thresholds at ±1500) ---\n")

placebo_cutoffs <- c(-1500, 1500)
placebo_results <- list()

for (pc in placebo_cutoffs) {
  cs_placebo <- cs_df %>%
    mutate(
      rv_placebo = running_var - pc,
      above_placebo = as.integer(rv_placebo >= 0)
    ) %>%
    filter(abs(rv_placebo) <= opt_bw)

  if (nrow(cs_placebo) > 50) {
    m_placebo <- feols(dv_rate ~ above_placebo + rv_placebo +
                         I(above_placebo * rv_placebo) |
                         threshold_fe,
                       data = cs_placebo, vcov = "hetero")
    placebo_results[[as.character(pc)]] <- list(
      cutoff = pc,
      coef = coef(m_placebo)["above_placebo"],
      se = se(m_placebo)["above_placebo"],
      n = nobs(m_placebo)
    )
    cat(sprintf("  Placebo cutoff at %+d: β = %.3f (%.3f)\n",
                pc, coef(m_placebo)["above_placebo"], se(m_placebo)["above_placebo"]))
  }
}

# ---- 6. DONUT RDD ----
cat("\n--- Donut RDD (exclude ±250 around cutoff) ---\n")

df_donut <- cs_df %>%
  filter(abs(running_var) <= opt_bw, abs(running_var) > 250)

m_donut <- feols(dv_rate ~ above_threshold + running_var +
                   I(above_threshold * running_var) |
                   threshold_fe + state_code,
                 data = df_donut, vcov = "hetero")

cat(sprintf("Donut RDD: β = %.3f (%.3f), N = %d\n",
            coef(m_donut)["above_threshold"], se(m_donut)["above_threshold"],
            nobs(m_donut)))

# ---- 7. QUADRATIC POLYNOMIAL ----
cat("\n--- Quadratic Polynomial ---\n")

m_quad <- feols(dv_rate ~ above_threshold + running_var + I(running_var^2) +
                  I(above_threshold * running_var) + I(above_threshold * running_var^2) |
                  threshold_fe + state_code,
                data = df_bw, vcov = "hetero")

cat(sprintf("Quadratic: β = %.3f (%.3f)\n",
            coef(m_quad)["above_threshold"], se(m_quad)["above_threshold"]))

# ---- 8. COVARIATE BALANCE ----
cat("\n--- Covariate Balance at Threshold ---\n")

# Test whether pre-determined covariates jump at threshold
rdd_pop <- tryCatch(
  rdrobust(y = log(cs_df$population), x = cs_df$running_var, c = 0, p = 1),
  error = function(e) NULL
)

if (!is.null(rdd_pop)) {
  cat(sprintf("Log(population) jump: %.3f (p=%.3f)\n",
              rdd_pop$coef[1], rdd_pop$pv[3]))
}

# ---- SAVE ROBUSTNESS RESULTS ----

robust_results <- list(
  bw_results = bw_results,
  m_male_viol = m_male_viol,
  m_male_hom = m_male_hom,
  m_traffic = m_traffic,
  placebo_results = placebo_results,
  m_donut = m_donut,
  m_quad = m_quad,
  rdd_pop = rdd_pop
)

saveRDS(robust_results, "data/robust_results.rds")

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
