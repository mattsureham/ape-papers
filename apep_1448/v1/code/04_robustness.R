# 04_robustness.R — Robustness checks for MA star rating RDD
# apep_1448

source("00_packages.R")

data_dir <- "../data"
panel <- read_csv(file.path(data_dir, "panel_star_ratings.csv"), show_col_types = FALSE)

# ============================================================================
# 1. Polynomial Order Sensitivity
# ============================================================================
cat("=== Polynomial Order Sensitivity ===\n")

poly_results <- data.frame()
for (p in 1:3) {
  rdd <- tryCatch(
    rdrobust(y = panel$star_4plus, x = panel$summary_score, c = 3.75,
             kernel = "triangular", p = p, bwselect = "mserd"),
    error = function(e) NULL
  )
  if (!is.null(rdd)) {
    poly_results <- rbind(poly_results, data.frame(
      polynomial = p,
      coef = rdd$coef[1],
      se = rdd$se[1],
      pvalue = rdd$pv[1],
      bw = rdd$bws[1,1]
    ))
  }
}
print(poly_results)

# ============================================================================
# 2. Kernel Sensitivity
# ============================================================================
cat("\n=== Kernel Sensitivity ===\n")

kernel_results <- data.frame()
for (k in c("triangular", "epanechnikov", "uniform")) {
  rdd <- tryCatch(
    rdrobust(y = panel$star_4plus, x = panel$summary_score, c = 3.75,
             kernel = k, bwselect = "mserd"),
    error = function(e) NULL
  )
  if (!is.null(rdd)) {
    kernel_results <- rbind(kernel_results, data.frame(
      kernel = k,
      coef = rdd$coef[1],
      se = rdd$se[1],
      pvalue = rdd$pv[1],
      bw = rdd$bws[1,1]
    ))
  }
}
print(kernel_results)

# ============================================================================
# 3. Year-by-Year RDD
# ============================================================================
cat("\n=== Year-by-Year RDD ===\n")

year_results <- data.frame()
for (yr in sort(unique(panel$year))) {
  sub <- panel %>% filter(year == yr)
  rdd <- tryCatch(
    rdrobust(y = sub$star_4plus, x = sub$summary_score, c = 3.75,
             kernel = "triangular", bwselect = "mserd"),
    error = function(e) NULL
  )
  if (!is.null(rdd)) {
    year_results <- rbind(year_results, data.frame(
      year = yr,
      n = nrow(sub),
      coef = rdd$coef[1],
      se = rdd$se[1],
      pvalue = rdd$pv[1],
      bw = rdd$bws[1,1],
      n_eff = rdd$N_h[1] + rdd$N_h[2]
    ))
  }
}
print(year_results)

# ============================================================================
# 4. Donut RDD — exclude contracts very close to cutoff
# ============================================================================
cat("\n=== Donut RDD ===\n")

donut_results <- data.frame()
for (hole in c(0.01, 0.02, 0.05)) {
  sub <- panel %>%
    filter(abs(summary_score - 3.75) > hole)
  rdd <- tryCatch(
    rdrobust(y = sub$star_4plus, x = sub$summary_score, c = 3.75,
             kernel = "triangular", bwselect = "mserd"),
    error = function(e) NULL
  )
  if (!is.null(rdd)) {
    donut_results <- rbind(donut_results, data.frame(
      donut = hole,
      coef = rdd$coef[1],
      se = rdd$se[1],
      pvalue = rdd$pv[1],
      n_eff = rdd$N_h[1] + rdd$N_h[2]
    ))
  }
}
print(donut_results)

# ============================================================================
# 5. Multiple Placebo Thresholds
# ============================================================================
cat("\n=== Multiple Placebo Thresholds ===\n")

placebo_thresholds <- seq(2.75, 4.75, by = 0.25)
placebo_thresholds <- placebo_thresholds[placebo_thresholds != 3.75]

placebo_results <- data.frame()
for (c_val in placebo_thresholds) {
  rdd <- tryCatch(
    rdrobust(y = panel$star_4plus, x = panel$summary_score, c = c_val,
             kernel = "triangular", bwselect = "mserd"),
    error = function(e) NULL
  )
  if (!is.null(rdd)) {
    placebo_results <- rbind(placebo_results, data.frame(
      threshold = c_val,
      coef = rdd$coef[1],
      se = rdd$se[1],
      pvalue = rdd$pv[1]
    ))
  }
}
print(placebo_results)

# ============================================================================
# 6. Score Dynamics: Do Plans Near the Threshold Improve?
# ============================================================================
cat("\n=== Score Improvement Dynamics ===\n")

panel_lag <- panel %>%
  arrange(contract_id, year) %>%
  group_by(contract_id) %>%
  mutate(
    prev_score = lag(summary_score),
    prev_stars = lag(partc_stars),
    score_change = summary_score - prev_score,
    just_missed = as.integer(prev_stars == 3.5),  # Just missed 4-star bonus
    near_threshold_below = as.integer(prev_score >= 3.50 & prev_score < 3.75),
    near_threshold_above = as.integer(prev_score >= 3.75 & prev_score < 4.00)
  ) %>%
  ungroup() %>%
  filter(!is.na(prev_score))

# Mean score change by previous position
dynamics_summary <- panel_lag %>%
  mutate(
    position = case_when(
      prev_score < 3.25 ~ "Far below",
      prev_score < 3.50 ~ "Below 3.5",
      prev_score < 3.75 ~ "3.5-3.75 (just missed)",
      prev_score < 4.00 ~ "3.75-4.0 (just made it)",
      prev_score < 4.25 ~ "4.0-4.25",
      TRUE ~ "Above 4.25"
    )
  ) %>%
  group_by(position) %>%
  summarise(
    n = n(),
    mean_change = mean(score_change),
    sd_change = sd(score_change),
    se_change = sd(score_change) / sqrt(n()),
    .groups = "drop"
  )

print(dynamics_summary)

# Formal test: plans at 3.5 stars improve more than plans at 4.0 stars?
test_df <- panel_lag %>%
  filter(prev_stars %in% c(3.5, 4.0))
if (nrow(test_df) > 50) {
  t_test <- t.test(score_change ~ just_missed, data = test_df)
  cat(sprintf("\nt-test: 3.5-star plans vs 4.0-star plans\n"))
  cat(sprintf("  Mean change (3.5-star): %.4f\n", t_test$estimate[2]))
  cat(sprintf("  Mean change (4.0-star): %.4f\n", t_test$estimate[1]))
  cat(sprintf("  Difference: %.4f, p=%.4f\n", diff(t_test$estimate), t_test$p.value))
}

# Controlled regression: score change on just_missed, controlling for lagged score
cat("\n=== Controlled Dynamics Regression ===\n")
panel_lag_near <- panel_lag %>%
  filter(prev_score >= 3.25 & prev_score <= 4.25 & !is.na(score_change))

# Model 1: Raw difference
m1 <- feols(score_change ~ just_missed, data = panel_lag_near)
# Model 2: Control for lagged score (linear)
m2 <- feols(score_change ~ just_missed + prev_score, data = panel_lag_near)
# Model 3: Control for lagged score (quadratic) + year FE
m3 <- feols(score_change ~ just_missed + prev_score + I(prev_score^2) | year, data = panel_lag_near)
# Model 4: Add parent org FE
panel_lag_near <- panel_lag_near %>%
  mutate(parent_id = as.factor(parent_org))
m4 <- tryCatch(
  feols(score_change ~ just_missed + prev_score + I(prev_score^2) | year + parent_id, data = panel_lag_near),
  error = function(e) NULL
)

cat("Model 1 (raw):\n")
print(summary(m1))
cat("\nModel 2 (+ lagged score):\n")
print(summary(m2))
cat("\nModel 3 (+ quadratic + year FE):\n")
print(summary(m3))
if (!is.null(m4)) {
  cat("\nModel 4 (+ parent org FE):\n")
  print(summary(m4))
}

# Save controlled results
controlled_results <- list(
  m1_coef = coef(m1)["just_missed"],
  m1_se = se(m1)["just_missed"],
  m2_coef = coef(m2)["just_missed"],
  m2_se = se(m2)["just_missed"],
  m3_coef = coef(m3)["just_missed"],
  m3_se = se(m3)["just_missed"]
)
if (!is.null(m4)) {
  controlled_results$m4_coef <- coef(m4)["just_missed"]
  controlled_results$m4_se <- se(m4)["just_missed"]
}
write_json(controlled_results, file.path(data_dir, "controlled_dynamics.json"), auto_unbox = TRUE)

# ============================================================================
# Save all robustness results
# ============================================================================
robustness <- list(
  polynomial = poly_results,
  kernel = kernel_results,
  year_by_year = year_results,
  donut = donut_results,
  placebo = placebo_results,
  dynamics = as.data.frame(dynamics_summary)
)
write_json(robustness, file.path(data_dir, "robustness_results.json"), auto_unbox = TRUE)
cat("\nRobustness results saved.\n")
