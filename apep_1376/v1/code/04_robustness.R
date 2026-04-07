# Robustness Checks & Sensitivity Analysis
source("code/00_packages.R")

message("Running robustness checks...")

df <- read_csv("data/florida_liquor_clean.csv", show_col_types = FALSE)

# ============================================================================
# ROBUSTNESS 1: RDD Polynomial Order (Linear, Quadratic, Cubic)
# ============================================================================

message("\n[Robustness 1] RDD Polynomial Sensitivity")

rdd_linear <- feols(
  log_employees ~ threshold_indicator + pop_distance_lin | year_fe + county_fe,
  data = df, cluster = ~ county_fe
)

rdd_quad <- feols(
  log_employees ~ threshold_indicator + pop_distance_lin + pop_distance_sq +
                  threshold_x_lin | year_fe + county_fe,
  data = df, cluster = ~ county_fe
)

rdd_cub <- feols(
  log_employees ~ threshold_indicator + pop_distance_lin + pop_distance_sq + pop_distance_cub +
                  threshold_x_lin + threshold_x_sq | year_fe + county_fe,
  data = df, cluster = ~ county_fe
)

poly_sens <- tibble(
  Model = c("Linear", "Quadratic", "Cubic"),
  Coefficient = c(coef(rdd_linear)[1], coef(rdd_quad)[1], coef(rdd_cub)[1]),
  SE = c(
    sqrt(diag(vcov(rdd_linear)))[1],
    sqrt(diag(vcov(rdd_quad)))[1],
    sqrt(diag(vcov(rdd_cub)))[1]
  ),
  t_stat = Coefficient / SE,
  p_value = 2 * pnorm(abs(t_stat), lower.tail = FALSE)
)

message("Polynomial order sensitivity:")
print(poly_sens)

# ============================================================================
# ROBUSTNESS 2: Bandwidth Sensitivity (5k, 7.5k, 10k)
# ============================================================================

message("\n[Robustness 2] Bandwidth Sensitivity")

bw_5k <- feols(
  log_employees ~ threshold_indicator + pop_distance_lin | year_fe + county_fe,
  data = df %>% filter(in_bandwidth_5k), cluster = ~ county_fe
)

bw_7.5k <- feols(
  log_employees ~ threshold_indicator + pop_distance_lin | year_fe + county_fe,
  data = df %>% filter(in_bandwidth_7.5k), cluster = ~ county_fe
)

bw_10k <- feols(
  log_employees ~ threshold_indicator + pop_distance_lin | year_fe + county_fe,
  data = df %>% filter(in_bandwidth_10k), cluster = ~ county_fe
)

bw_sens <- tibble(
  Bandwidth = c("±5,000", "±7,500", "±10,000"),
  Coefficient = c(coef(bw_5k)[1], coef(bw_7.5k)[1], coef(bw_10k)[1]),
  SE = c(
    sqrt(diag(vcov(bw_5k)))[1],
    sqrt(diag(vcov(bw_7.5k)))[1],
    sqrt(diag(vcov(bw_10k)))[1]
  ),
  N = c(nrow(df %>% filter(in_bandwidth_5k)),
        nrow(df %>% filter(in_bandwidth_7.5k)),
        nrow(df %>% filter(in_bandwidth_10k)))
)

message("Bandwidth sensitivity:")
print(bw_sens)

# ============================================================================
# ROBUSTNESS 3: Pre-Trends (Parallel Trends Assumption)
# ============================================================================

message("\n[Robustness 3] Pre-Trends (Falsification Test)")

# Create a lead: treat threshold crossings one year early
df_pretrend <- df %>%
  mutate(
    threshold_indicator_lead = lead(threshold_indicator),
    threshold_indicator_lag = lag(threshold_indicator)
  )

# False specification: does the threshold NEXT year affect employment THIS year?
pretrend_false <- feols(
  log_employees ~ threshold_indicator_lead + pop_distance_lin | year_fe + county_fe,
  data = df_pretrend, cluster = ~ county_fe
)

# True specification (actual)
pretrend_true <- feols(
  log_employees ~ threshold_indicator + pop_distance_lin | year_fe + county_fe,
  data = df_pretrend, cluster = ~ county_fe
)

# Lag specification: does past threshold affect current employment?
pretrend_lag <- feols(
  log_employees ~ threshold_indicator_lag + pop_distance_lin | year_fe + county_fe,
  data = df_pretrend, cluster = ~ county_fe
)

pretrend_results <- tibble(
  Specification = c("Lead (False)", "Contemporaneous (True)", "Lag"),
  Coefficient = c(
    coef(pretrend_false)[1],
    coef(pretrend_true)[1],
    coef(pretrend_lag)[1]
  ),
  SE = c(
    sqrt(diag(vcov(pretrend_false)))[1],
    sqrt(diag(vcov(pretrend_true)))[1],
    sqrt(diag(vcov(pretrend_lag)))[1]
  )
)

message("Pre-trends (lead should be ~0):")
print(pretrend_results)

# ============================================================================
# ROBUSTNESS 4: Placebo Outcomes (No Expected Effect)
# ============================================================================

message("\n[Robustness 4] Placebo Outcomes")

# Create a fake outcome: population (which is the RV, not outcome of policy)
placebo_pop <- feols(
  log(population + 1) ~ threshold_indicator + pop_distance_lin | year_fe + county_fe,
  data = df, cluster = ~ county_fe
)

# Alternative placebo: future employment (not affected by current threshold?)
df_placebo <- df %>%
  mutate(log_employees_future = lead(log_employees))

placebo_future <- feols(
  log_employees_future ~ threshold_indicator + pop_distance_lin | year_fe + county_fe,
  data = df_placebo, cluster = ~ county_fe
)

placebo_results <- tibble(
  Placebo = c("Population (RV)", "Future Employment"),
  Coefficient = c(coef(placebo_pop)[1], coef(placebo_future)[1]),
  SE = c(
    sqrt(diag(vcov(placebo_pop)))[1],
    sqrt(diag(vcov(placebo_future)))[1]
  ),
  Expect = c("~0", "~0")
)

message("Placebo outcomes (expect ~0):")
print(placebo_results)

# ============================================================================
# ROBUSTNESS 5: Donut RDD (Exclude boundary counties)
# ============================================================================

message("\n[Robustness 5] Donut RDD (Exclude counties near threshold)")

# Exclude counties within 1,000 of threshold
donut_df <- df %>% filter(abs(pop_distance_centered) > 1000)

donut_rdd <- feols(
  log_employees ~ threshold_indicator + pop_distance_lin | year_fe + county_fe,
  data = donut_df, cluster = ~ county_fe
)

message(glue("Donut RDD (n={nrow(donut_df)}, excluding ±1,000 of threshold):"))
message(glue("  Coefficient: {round(coef(donut_rdd)[1], 4)}"))
message(glue("  SE: {round(sqrt(diag(vcov(donut_rdd)))[1], 4)}")

# ============================================================================
# ROBUSTNESS 6: Alternative Clustering (No Clustering, State-Level)
# ============================================================================

message("\n[Robustness 6] Standard Error Robustness")

rdd_no_cluster <- feols(
  log_employees ~ threshold_indicator + pop_distance_lin | year_fe + county_fe,
  data = df, cluster = NULL  # No clustering
)

rdd_robust <- feols(
  log_employees ~ threshold_indicator + pop_distance_lin | year_fe + county_fe,
  data = df, se = "hetero"  # Heteroskedastic-robust
)

se_comparison <- tibble(
  Specification = c("Clustered (County)", "No Clustering", "HC Robust"),
  Coefficient = rep(coef(rdd_linear)[1], 3),
  SE = c(
    sqrt(diag(vcov(rdd_linear)))[1],
    sqrt(diag(vcov(rdd_no_cluster)))[1],
    sqrt(diag(vcov(rdd_robust)))[1]
  )
)

message("Standard error robustness:")
print(se_comparison)

# ============================================================================
# SUMMARY TABLE & SAVE
# ============================================================================

message("\n[Summary] Robustness Checks Complete")

robustness_summary <- list(
  polynomial_sensitivity = poly_sens,
  bandwidth_sensitivity = bw_sens,
  pretrend_results = pretrend_results,
  placebo_results = placebo_results,
  se_comparison = se_comparison
)

jsonlite::write_json(
  robustness_summary,
  "tables/robustness_summary.json",
  auto_unbox = TRUE,
  pretty = TRUE
)

write_csv(poly_sens, "tables/robustness_polynomial.csv")
write_csv(bw_sens, "tables/robustness_bandwidth.csv")
write_csv(pretrend_results, "tables/robustness_pretrends.csv")
write_csv(placebo_results, "tables/robustness_placebo.csv")

message("✓ Robustness checks saved")
