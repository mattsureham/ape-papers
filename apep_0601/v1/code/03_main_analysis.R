## 03_main_analysis.R — Main RDD estimation and bunching analysis
## APEP-0601: PDUFA Deadline Bunching and Drug Safety

source("code/00_packages.R")

cat("=== Loading analysis data ===\n")
df <- readRDS("data/clean_analysis.rds")
df_full <- readRDS("data/clean_full.rds")
cat("Analysis sample:", nrow(df), "drugs with FAERS data\n")
cat("Full sample:", nrow(df_full), "drugs (for bunching)\n\n")

# ============================================================
# 1. McCrary Density Test — Document manipulation at day 300
# ============================================================
cat("=== 1. McCrary Density Test ===\n")

# Use rddensity to test for bunching
dens_test <- rddensity(X = df_full$rv, c = 0)
cat("McCrary density test at c=300:\n")
cat("  T-statistic:", round(dens_test$test$t_jk, 3), "\n")
cat("  P-value:", round(dens_test$test$p_jk, 4), "\n")
cat("  Interpretation: ", ifelse(dens_test$test$p_jk < 0.05,
    "SIGNIFICANT bunching detected (manipulation confirmed)",
    "No significant bunching"), "\n\n")

# Save density test results
density_result <- list(
  t_stat = dens_test$test$t_jk,
  p_value = dens_test$test$p_jk,
  n_left = dens_test$N$eff_left,
  n_right = dens_test$N$eff_right
)
saveRDS(density_result, "data/density_test.rds")

# ============================================================
# 2. Bunching Estimator — Excess mass at deadline
# ============================================================
cat("=== 2. Bunching Analysis ===\n")

# Count drugs in 10-day bins
bins <- df_full %>%
  filter(review_days >= 200, review_days <= 500) %>%
  mutate(bin = floor(review_days / 10) * 10) %>%
  count(bin) %>%
  arrange(bin)

# Estimate counterfactual distribution (exclude bunching window [290,320))
cf_bins <- bins %>% filter(bin < 290 | bin >= 320)
poly_fit <- lm(n ~ poly(bin, 5), data = cf_bins)
bins$counterfactual <- predict(poly_fit, newdata = bins)

# Excess mass
bunching_window <- bins %>% filter(bin >= 290, bin < 320)
excess_mass <- sum(bunching_window$n) - sum(bunching_window$counterfactual)
total_in_window <- sum(bunching_window$n)
expected_in_window <- sum(bunching_window$counterfactual)

cat("Drugs in bunching window [290,320):", total_in_window, "\n")
cat("Expected (counterfactual):", round(expected_in_window, 1), "\n")
cat("Excess mass:", round(excess_mass, 1), "\n")
cat("Bunching ratio (b = excess/counterfactual):", round(excess_mass/expected_in_window, 2), "\n\n")

# Save bunching results
saveRDS(list(bins = bins, excess_mass = excess_mass,
             total = total_in_window, expected = expected_in_window,
             ratio = excess_mass/expected_in_window), "data/bunching_results.rds")

# ============================================================
# 3. Main RDD — Effect of review timing on AE rates
# ============================================================
cat("=== 3. Main RDD Estimation ===\n")

# Use drugs with review_days in [200, 500] for sufficient bandwidth
df_rdd <- df %>% filter(review_days >= 200, review_days <= 500)
cat("RDD sample:", nrow(df_rdd), "drugs\n")

# 3a. Main outcome: log(serious AEs per year on market)
cat("\n--- 3a. Log serious AE rate ---\n")
if (nrow(df_rdd) > 30) {
  rd_serious <- tryCatch({
    rdrobust(y = df_rdd$log_serious_ae, x = df_rdd$rv, c = 0,
             kernel = "triangular", p = 1)
  }, error = function(e) {
    cat("rdrobust failed:", e$message, "\n")
    NULL
  })

  if (!is.null(rd_serious)) {
    cat("  RD estimate:", round(rd_serious$coef[1], 3), "\n")
    cat("  Robust SE:", round(rd_serious$se[3], 3), "\n")
    cat("  Robust p-value:", round(rd_serious$pv[3], 4), "\n")
    cat("  95% CI: [", round(rd_serious$ci[3,1], 3), ",",
        round(rd_serious$ci[3,2], 3), "]\n")
    cat("  Bandwidth:", round(rd_serious$bws[1,1], 1), "days\n")
    cat("  N left:", rd_serious$N_h[1], "N right:", rd_serious$N_h[2], "\n")
  }
}

# 3b. Death reports
cat("\n--- 3b. Log death AE count ---\n")
if (nrow(df_rdd) > 30) {
  rd_death <- tryCatch({
    rdrobust(y = df_rdd$log_death_ae, x = df_rdd$rv, c = 0,
             kernel = "triangular", p = 1)
  }, error = function(e) {
    cat("rdrobust failed:", e$message, "\n")
    NULL
  })

  if (!is.null(rd_death)) {
    cat("  RD estimate:", round(rd_death$coef[1], 3), "\n")
    cat("  Robust SE:", round(rd_death$se[3], 3), "\n")
    cat("  Robust p-value:", round(rd_death$pv[3], 4), "\n")
    cat("  95% CI: [", round(rd_death$ci[3,1], 3), ",",
        round(rd_death$ci[3,2], 3), "]\n")
    cat("  Bandwidth:", round(rd_death$bws[1,1], 1), "days\n")
  }
}

# 3c. Boxed warning
cat("\n--- 3c. Boxed warning (binary) ---\n")
if (nrow(df_rdd) > 30) {
  rd_boxed <- tryCatch({
    rdrobust(y = as.numeric(df_rdd$has_boxed), x = df_rdd$rv, c = 0,
             kernel = "triangular", p = 1)
  }, error = function(e) {
    cat("rdrobust failed:", e$message, "\n")
    NULL
  })

  if (!is.null(rd_boxed)) {
    cat("  RD estimate:", round(rd_boxed$coef[1], 3), "\n")
    cat("  Robust SE:", round(rd_boxed$se[3], 3), "\n")
    cat("  Robust p-value:", round(rd_boxed$pv[3], 4), "\n")
    cat("  95% CI: [", round(rd_boxed$ci[3,1], 3), ",",
        round(rd_boxed$ci[3,2], 3), "]\n")
  }
}

# 3d. Any recall
cat("\n--- 3d. Any recall/enforcement action ---\n")
if (nrow(df_rdd) > 30) {
  rd_recall <- tryCatch({
    rdrobust(y = as.numeric(df_rdd$any_recall), x = df_rdd$rv, c = 0,
             kernel = "triangular", p = 1)
  }, error = function(e) {
    cat("rdrobust failed:", e$message, "\n")
    NULL
  })

  if (!is.null(rd_recall)) {
    cat("  RD estimate:", round(rd_recall$coef[1], 3), "\n")
    cat("  Robust SE:", round(rd_recall$se[3], 3), "\n")
    cat("  Robust p-value:", round(rd_recall$pv[3], 4), "\n")
    cat("  95% CI: [", round(rd_recall$ci[3,1], 3), ",",
        round(rd_recall$ci[3,2], 3), "]\n")
  }
}

# ============================================================
# 4. Donut-RD — Exclude most manipulated observations
# ============================================================
cat("\n=== 4. Donut-RD (excluding [295,310)) ===\n")
df_donut <- df %>%
  filter(review_days >= 200, review_days <= 500) %>%
  filter(review_days < 295 | review_days >= 310)

cat("Donut sample:", nrow(df_donut), "drugs (excluded",
    nrow(df_rdd) - nrow(df_donut), "in bunching window)\n")

if (nrow(df_donut) > 30) {
  rd_donut <- tryCatch({
    rdrobust(y = df_donut$log_serious_ae, x = df_donut$rv, c = 0,
             kernel = "triangular", p = 1)
  }, error = function(e) {
    cat("rdrobust failed:", e$message, "\n")
    NULL
  })

  if (!is.null(rd_donut)) {
    cat("  RD estimate:", round(rd_donut$coef[1], 3), "\n")
    cat("  Robust SE:", round(rd_donut$se[3], 3), "\n")
    cat("  Robust p-value:", round(rd_donut$pv[3], 4), "\n")
    cat("  Bandwidth:", round(rd_donut$bws[1,1], 1), "days\n")
  }
}

# ============================================================
# 5. Comparison estimator — Bunched vs non-bunched drugs
# ============================================================
cat("\n=== 5. Bunched vs Non-Bunched Comparison ===\n")

# Define bunched drugs: review_days in [295, 310)
df_comp <- df %>%
  filter(review_days >= 250, review_days <= 400) %>%
  mutate(
    bunched = review_days >= 295 & review_days < 310
  )

cat("Comparison sample:", nrow(df_comp), "drugs\n")
cat("  Bunched:", sum(df_comp$bunched), "\n")
cat("  Non-bunched:", sum(!df_comp$bunched), "\n")

# Simple t-test
if (sum(df_comp$bunched) > 5 & sum(!df_comp$bunched) > 5) {
  tt_serious <- t.test(log_serious_ae ~ bunched, data = df_comp)
  cat("\nT-test: log(serious AEs) bunched vs non-bunched:\n")
  cat("  Bunched mean:", round(tt_serious$estimate[2], 3), "\n")
  cat("  Non-bunched mean:", round(tt_serious$estimate[1], 3), "\n")
  cat("  Difference:", round(diff(tt_serious$estimate), 3), "\n")
  cat("  P-value:", round(tt_serious$p.value, 4), "\n")

  tt_death <- t.test(log_death_ae ~ bunched, data = df_comp)
  cat("\nT-test: log(death AEs) bunched vs non-bunched:\n")
  cat("  Bunched mean:", round(tt_death$estimate[2], 3), "\n")
  cat("  Non-bunched mean:", round(tt_death$estimate[1], 3), "\n")
  cat("  Difference:", round(diff(tt_death$estimate), 3), "\n")
  cat("  P-value:", round(tt_death$p.value, 4), "\n")

  tt_boxed <- t.test(as.numeric(has_boxed) ~ bunched, data = df_comp)
  cat("\nT-test: Boxed warning bunched vs non-bunched:\n")
  cat("  Bunched mean:", round(tt_boxed$estimate[2], 3), "\n")
  cat("  Non-bunched mean:", round(tt_boxed$estimate[1], 3), "\n")
  cat("  Difference:", round(diff(tt_boxed$estimate), 3), "\n")
  cat("  P-value:", round(tt_boxed$p.value, 4), "\n")
}

# OLS with controls
cat("\n--- OLS: bunched + controls ---\n")
ols1 <- lm(log_serious_ae ~ bunched + factor(therapeutic_class) +
             approval_year + is_orphan + is_accelerated + years_on_market,
           data = df_comp)
cat("Bunched coefficient:", round(coef(ols1)["bunchedTRUE"], 3), "\n")
cat("SE:", round(summary(ols1)$coefficients["bunchedTRUE", "Std. Error"], 3), "\n")
cat("P-value:", round(summary(ols1)$coefficients["bunchedTRUE", "Pr(>|t|)"], 4), "\n")

ols2 <- lm(log_death_ae ~ bunched + factor(therapeutic_class) +
             approval_year + is_orphan + is_accelerated + years_on_market,
           data = df_comp)
cat("\nDeath AE bunched coefficient:", round(coef(ols2)["bunchedTRUE"], 3), "\n")
cat("SE:", round(summary(ols2)$coefficients["bunchedTRUE", "Std. Error"], 3), "\n")
cat("P-value:", round(summary(ols2)$coefficients["bunchedTRUE", "Pr(>|t|)"], 4), "\n")

# ============================================================
# 6. Save main results for table generation
# ============================================================
cat("\n=== Saving results ===\n")

results <- list(
  density_test = density_result,
  rd_serious = if (exists("rd_serious") && !is.null(rd_serious)) {
    list(coef = rd_serious$coef, se = rd_serious$se, pv = rd_serious$pv,
         ci = rd_serious$ci, bws = rd_serious$bws, N_h = rd_serious$N_h)
  } else NULL,
  rd_death = if (exists("rd_death") && !is.null(rd_death)) {
    list(coef = rd_death$coef, se = rd_death$se, pv = rd_death$pv,
         ci = rd_death$ci, bws = rd_death$bws, N_h = rd_death$N_h)
  } else NULL,
  rd_boxed = if (exists("rd_boxed") && !is.null(rd_boxed)) {
    list(coef = rd_boxed$coef, se = rd_boxed$se, pv = rd_boxed$pv,
         ci = rd_boxed$ci, bws = rd_boxed$bws)
  } else NULL,
  rd_recall = if (exists("rd_recall") && !is.null(rd_recall)) {
    list(coef = rd_recall$coef, se = rd_recall$se, pv = rd_recall$pv,
         ci = rd_recall$ci, bws = rd_recall$bws)
  } else NULL,
  rd_donut = if (exists("rd_donut") && !is.null(rd_donut)) {
    list(coef = rd_donut$coef, se = rd_donut$se, pv = rd_donut$pv,
         ci = rd_donut$ci, bws = rd_donut$bws)
  } else NULL,
  ols_serious = list(coef = coef(ols1)["bunchedTRUE"],
                     se = summary(ols1)$coefficients["bunchedTRUE", "Std. Error"],
                     pv = summary(ols1)$coefficients["bunchedTRUE", "Pr(>|t|)"]),
  ols_death = list(coef = coef(ols2)["bunchedTRUE"],
                   se = summary(ols2)$coefficients["bunchedTRUE", "Std. Error"],
                   pv = summary(ols2)$coefficients["bunchedTRUE", "Pr(>|t|)"]),
  sample = list(
    n_total = nrow(df),
    n_rdd = nrow(df_rdd),
    n_donut = nrow(df_donut),
    n_comp = nrow(df_comp),
    n_bunched = sum(df_comp$bunched),
    mean_review_days = mean(df$review_days),
    median_review_days = median(df$review_days)
  )
)

saveRDS(results, "data/main_results.rds")

# Write diagnostics.json for validator
diagnostics <- list(
  n_treated = sum(df_comp$bunched),
  n_pre = length(unique(df_full$approval_year[df_full$approval_year < 2000])),
  n_obs = nrow(df)
)
jsonlite::write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE)

cat("Results saved to data/main_results.rds\n")
cat("Diagnostics saved to data/diagnostics.json\n")
cat("\n=== Main analysis complete ===\n")
