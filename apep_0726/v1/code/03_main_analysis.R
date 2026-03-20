# =============================================================================
# 03_main_analysis.R — Main RDD analysis
# Paper: Fiscal Windfalls and Violence Against Women (apep_0726)
# =============================================================================

source("code/00_packages.R")

cat("=== MAIN ANALYSIS ===\n")

df <- readRDS("data/analysis_df.rds")

# ---- 1. COLLAPSE TO CROSS-SECTION (POOLED) ----
# Pool across years for cross-sectional RDD
# Average outcomes and average population across years

cs_df <- df %>%
  group_by(mun_code, nearest_threshold) %>%
  summarise(
    population = mean(population, na.rm = TRUE),
    running_var = mean(running_var, na.rm = TRUE),
    above_threshold = first(above_threshold),
    fpm_coef = first(fpm_coef),
    fem_homicide_rate = mean(fem_homicide_rate, na.rm = TRUE),
    male_homicide_rate = mean(male_homicide_rate, na.rm = TRUE),
    traffic_rate = mean(traffic_rate, na.rm = TRUE),
    dv_rate = mean(dv_rate, na.rm = TRUE),
    n_female_homicide = sum(n_female_homicide, na.rm = TRUE),
    female_pop = mean(female_pop, na.rm = TRUE),
    n_years = n(),
    state_code = first(state_code),
    .groups = "drop"
  ) %>%
  mutate(threshold_fe = as.factor(nearest_threshold))

cat(sprintf("Cross-sectional dataset: %d municipalities\n", nrow(cs_df)))

# ---- 2. MCCRARY DENSITY TEST ----
# Test for manipulation of the running variable

cat("\n--- McCrary Density Test ---\n")

density_test <- tryCatch({
  rddensity(X = cs_df$running_var, vce = "jackknife")
}, error = function(e) {
  cat(sprintf("rddensity error: %s\n", e$message))
  NULL
})

if (!is.null(density_test)) {
  cat(sprintf("T-statistic: %.3f\n", density_test$test$t_jk))
  cat(sprintf("P-value: %.4f\n", density_test$test$p_jk))
  density_pval <- density_test$test$p_jk
} else {
  density_pval <- NA
}

# ---- 3. MAIN RDD: FEMALE HOMICIDE (PRIMARY) ----

cat("\n--- Main RDD: Female Homicide Rate ---\n")

rdd_dv <- tryCatch({
  rdrobust(
    y = cs_df$fem_homicide_rate,
    x = cs_df$running_var,
    c = 0,
    kernel = "triangular",
    p = 1,
    bwselect = "mserd"
  )
}, error = function(e) {
  cat(sprintf("rdrobust error: %s\n", e$message))
  NULL
})

if (!is.null(rdd_dv)) {
  cat(sprintf("Bandwidth (h): %.1f\n", rdd_dv$bws[1, 1]))
  cat(sprintf("N left: %d, N right: %d\n", rdd_dv$N_h[1], rdd_dv$N_h[2]))
  cat(sprintf("RD Estimate: %.3f\n", rdd_dv$coef[1]))
  cat(sprintf("Robust p-value: %.4f\n", rdd_dv$pv[3]))
}

# ---- 4. MAIN RDD: MALE HOMICIDE (PLACEBO) ----

cat("\n--- Main RDD: Male Homicide Rate (Placebo) ---\n")

rdd_hom <- tryCatch({
  rdrobust(
    y = cs_df$male_homicide_rate,
    x = cs_df$running_var,
    c = 0,
    kernel = "triangular",
    p = 1,
    bwselect = "mserd"
  )
}, error = function(e) {
  cat(sprintf("rdrobust error for male homicide: %s\n", e$message))
  NULL
})

if (!is.null(rdd_hom)) {
  cat(sprintf("Bandwidth (h): %.1f\n", rdd_hom$bws[1, 1]))
  cat(sprintf("N left: %d, N right: %d\n", rdd_hom$N_h[1], rdd_hom$N_h[2]))
  cat(sprintf("RD Estimate: %.3f\n", rdd_hom$coef[1]))
  cat(sprintf("Robust p-value: %.4f\n", rdd_hom$pv[3]))
}

# ---- 5. PARAMETRIC RDD WITH CONTROLS ----
# Local linear regression with threshold FE and state FE

# Use optimal bandwidth from rdrobust
opt_bw <- ifelse(!is.null(rdd_dv), rdd_dv$bws[1, 1], 3000)

df_bw <- cs_df %>% filter(abs(running_var) <= opt_bw)

cat(sprintf("\n--- Parametric RDD (bw = %.0f) ---\n", opt_bw))
cat(sprintf("Observations in bandwidth: %d\n", nrow(df_bw)))

# Model 1: Female homicide, simple RDD
m1 <- feols(fem_homicide_rate ~ above_threshold + running_var + I(above_threshold * running_var),
            data = df_bw, vcov = "hetero")

# Model 2: Female homicide, with threshold FE
m2 <- feols(fem_homicide_rate ~ above_threshold + running_var + I(above_threshold * running_var) |
              threshold_fe,
            data = df_bw, vcov = "hetero")

# Model 3: Female homicide, with threshold FE + state FE
m3 <- feols(fem_homicide_rate ~ above_threshold + running_var + I(above_threshold * running_var) |
              threshold_fe + state_code,
            data = df_bw, vcov = "hetero")

# Male homicide (placebo)
m4 <- feols(male_homicide_rate ~ above_threshold + running_var + I(above_threshold * running_var),
            data = df_bw, vcov = "hetero")

m5 <- feols(male_homicide_rate ~ above_threshold + running_var + I(above_threshold * running_var) |
              threshold_fe + state_code,
            data = df_bw, vcov = "hetero")

cat("\nDomestic Violence Models:\n")
cat(sprintf("  M1 (simple): β = %.3f (%.3f)\n", coef(m1)["above_threshold"], se(m1)["above_threshold"]))
cat(sprintf("  M2 (threshold FE): β = %.3f (%.3f)\n", coef(m2)["above_threshold"], se(m2)["above_threshold"]))
cat(sprintf("  M3 (threshold + state FE): β = %.3f (%.3f)\n", coef(m3)["above_threshold"], se(m3)["above_threshold"]))

cat("\nFemale Homicide Models:\n")
cat(sprintf("  M4 (simple): β = %.3f (%.3f)\n", coef(m4)["above_threshold"], se(m4)["above_threshold"]))
cat(sprintf("  M5 (threshold + state FE): β = %.3f (%.3f)\n", coef(m5)["above_threshold"], se(m5)["above_threshold"]))

# ---- 6. PANEL RDD ----
# Use the municipality-year panel with year FE

cat("\n--- Panel RDD ---\n")

panel_bw <- df %>% filter(abs(running_var) <= opt_bw)

m_panel_dv <- feols(fem_homicide_rate ~ above_threshold + running_var + I(above_threshold * running_var) |
                      threshold_fe + year + state_code,
                    data = panel_bw, vcov = ~mun_code)

m_panel_hom <- feols(male_homicide_rate ~ above_threshold + running_var + I(above_threshold * running_var) |
                       threshold_fe + year + state_code,
                     data = panel_bw, vcov = ~mun_code)

cat(sprintf("Panel DV: β = %.3f (%.3f), N = %d\n",
            coef(m_panel_dv)["above_threshold"], se(m_panel_dv)["above_threshold"],
            nobs(m_panel_dv)))
cat(sprintf("Panel Homicide: β = %.3f (%.3f), N = %d\n",
            coef(m_panel_hom)["above_threshold"], se(m_panel_hom)["above_threshold"],
            nobs(m_panel_hom)))

# ---- 7. SAVE RESULTS ----

results <- list(
  rdd_dv = rdd_dv,
  rdd_hom = rdd_hom,
  density_test = density_test,
  density_pval = density_pval,
  m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5,
  m_panel_dv = m_panel_dv, m_panel_hom = m_panel_hom,
  opt_bw = opt_bw,
  n_mun = nrow(cs_df),
  n_mun_bw = nrow(df_bw),
  n_panel_bw = nrow(panel_bw)
)

saveRDS(results, "data/main_results.rds")

# ---- 8. DIAGNOSTICS JSON ----
jsonlite::write_json(
  list(
    n_treated = sum(df_bw$above_threshold == 1),
    n_control = sum(df_bw$above_threshold == 0),
    n_pre = 0L,  # Cross-sectional RDD, not DiD
    n_obs = nrow(df_bw),
    n_panel = nrow(panel_bw),
    n_thresholds = n_distinct(df_bw$nearest_threshold),
    bandwidth = opt_bw,
    density_pval = density_pval
  ),
  "data/diagnostics.json",
  auto_unbox = TRUE
)

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
