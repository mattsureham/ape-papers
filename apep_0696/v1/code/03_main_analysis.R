## 03_main_analysis.R — Main RDD analysis
## apep_0696: FPM fiscal windfalls and agricultural expansion in Brazil
##
## Multi-cutoff RDD: 17 FPM population thresholds × Brazilian municipalities
## Primary specification: stacked multi-cutoff OLS with threshold FE

library(tidyverse)
library(rdrobust)
library(rddensity)
library(fixest)
library(jsonlite)

# Run from the v1/ directory (e.g., Rscript code/$(basename $0))

cat("=== Main Analysis for apep_0696 ===\n")

## ─────────────────────────────────────────────────────────────────────────────
## Load data
## ─────────────────────────────────────────────────────────────────────────────
df_cross   <- read_csv("data/cross_section_rdd.csv",
                       col_types = cols(mun_code = col_character()))
df_stacked <- read_csv("data/stacked_multicutoff.csv",
                       col_types = cols(mun_code = col_character()))
df_panel   <- read_csv("data/panel_clean.csv",
                       col_types = cols(mun_code = col_character()))

cat("Cross-section:", nrow(df_cross), "municipalities\n")
cat("Stacked:", nrow(df_stacked), "municipality-threshold obs\n")
cat("Panel:", nrow(df_panel), "municipality-year obs\n")

## ─────────────────────────────────────────────────────────────────────────────
## 1. rdrobust for bandwidth selection (on stacked dataset)
##    Run pooled nonparametric RD on the stacked multi-cutoff data
##    This gives the MSE-optimal bandwidth used in subsequent OLS specs
## ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Spec 1: rdrobust bandwidth selection (stacked data) ---\n")

# Use all municipality-threshold pairs (pooled running variable = run_var_k)
# Each observation: one municipality near one threshold
# Treatment: above_k = 1 if pop >= threshold_k

rdd_pilot <- tryCatch(
  rdrobust(
    y = df_stacked$avg_log_crop,
    x = df_stacked$run_var_k,
    c = 0,
    p = 1,
    kernel = "triangular",
    bwselect = "mserd",
    cluster = df_stacked$mun_code
  ),
  error = function(e) {
    cat("rdrobust error:", conditionMessage(e), "\n")
    NULL
  }
)

if (!is.null(rdd_pilot)) {
  h_opt <- rdd_pilot$bws[1, 1]
  cat(sprintf("MSE-optimal bandwidth: %.4f (%.1f%% of threshold)\n", h_opt, h_opt * 100))
  rdd1_coef <- rdd_pilot$coef[1]
  rdd1_se   <- rdd_pilot$se[3]  # robust SE
  cat(sprintf("rdrobust estimate: %.4f (robust SE: %.4f)\n", rdd1_coef, rdd1_se))
  cat(sprintf("p-value: %.4f\n", rdd_pilot$pv[3]))
} else {
  # Default bandwidth if rdrobust fails
  h_opt <- 0.20
  rdd1_coef <- NA
  rdd1_se <- NA
  cat("Using default bandwidth:", h_opt, "\n")
}

## ─────────────────────────────────────────────────────────────────────────────
## 2. RDD on first threshold only (canonical single-cutoff RD)
##    Threshold 1: pop = 10,189 (bracket 1→2, coefficient 0.6→0.8)
##    Largest coefficient jump relative to mean revenue
## ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Spec 2: Single-threshold RD (threshold 1: pop = 10,189) ---\n")

thresh1 <- 10189
df_thresh1 <- df_cross %>%
  mutate(
    run_var_t1 = (pop - thresh1) / thresh1,
    above_t1 = as.integer(pop >= thresh1)
  ) %>%
  filter(abs(run_var_t1) <= 0.30)

cat("Threshold 1 sample:", nrow(df_thresh1), "municipalities\n")

rdd2 <- tryCatch(
  rdrobust(
    y = df_thresh1$avg_log_crop,
    x = df_thresh1$run_var_t1,
    c = 0, p = 1, kernel = "triangular", bwselect = "mserd"
  ),
  error = function(e) { cat("Error:", conditionMessage(e), "\n"); NULL }
)

if (!is.null(rdd2)) {
  cat("Threshold 1 RD:\n")
  print(summary(rdd2))
  rdd2_coef <- rdd2$coef[1]
  rdd2_se   <- rdd2$se[3]
  rdd2_bw   <- rdd2$bws[1, 1]
} else {
  rdd2_coef <- rdd2_se <- rdd2_bw <- NA
}

## ─────────────────────────────────────────────────────────────────────────────
## 3. Main specification: Stacked multi-cutoff OLS with threshold FE
##    Pool all 17 thresholds; local linear on each side; triangular kernel
## ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Spec 3: Stacked multi-cutoff OLS (main specification) ---\n")

df_stacked_bw <- df_stacked %>%
  filter(abs(run_var_k) <= h_opt) %>%
  mutate(
    w_tri = 1 - abs(run_var_k) / h_opt,
    above_k_num = as.numeric(above_k)
  )

cat("Obs within bandwidth:", nrow(df_stacked_bw), "\n")
cat("Municipalities:", n_distinct(df_stacked_bw$mun_code), "\n")
cat("Above threshold:", sum(df_stacked_bw$above_k_num), "\n")
cat("Below threshold:", sum(1 - df_stacked_bw$above_k_num), "\n")

# Main OLS: log crop area ~ treatment + linear slopes on each side + threshold FE
rdd3 <- feols(
  avg_log_crop ~ above_k_num +
    run_var_k:I(above_k_num == 0) +   # slope below
    run_var_k:I(above_k_num == 1) |   # slope above
    k_index,                           # threshold FE
  data = df_stacked_bw,
  weights = ~w_tri,
  cluster = ~mun_code
)

cat("Stacked multi-cutoff OLS:\n")
print(summary(rdd3))

rdd3_coef <- coef(rdd3)["above_k_num"]
rdd3_se   <- se(rdd3)["above_k_num"]
rdd3_pval <- pvalue(rdd3)["above_k_num"]
cat(sprintf("  Estimate: %.4f (SE: %.4f, p=%.4f)\n", rdd3_coef, rdd3_se, rdd3_pval))

## ─────────────────────────────────────────────────────────────────────────────
## 4. Donut-hole robustness (exclude ±1% near threshold)
## ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Spec 4: Donut-hole (excl. |x|<0.01) ---\n")

df_donut <- df_stacked_bw %>% filter(abs(run_var_k) >= 0.01)

rdd4 <- feols(
  avg_log_crop ~ above_k_num +
    run_var_k:I(above_k_num == 0) +
    run_var_k:I(above_k_num == 1) | k_index,
  data = df_donut, weights = ~w_tri, cluster = ~mun_code
)
rdd4_coef <- coef(rdd4)["above_k_num"]
rdd4_se   <- se(rdd4)["above_k_num"]
cat(sprintf("  Donut estimate: %.4f (SE: %.4f)\n", rdd4_coef, rdd4_se))

## ─────────────────────────────────────────────────────────────────────────────
## 5. Bandwidth sensitivity
## ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Spec 5: Bandwidth sensitivity ---\n")

bw_results <- list()
for (h in c(0.10, 0.15, 0.20, 0.25, 0.30, 0.40)) {
  df_h <- df_stacked %>%
    filter(abs(run_var_k) <= h) %>%
    mutate(w_tri = 1 - abs(run_var_k) / h, above_k_num = as.numeric(above_k))

  if (nrow(df_h) < 100) next

  fit <- tryCatch(feols(
    avg_log_crop ~ above_k_num +
      run_var_k:I(above_k_num == 0) +
      run_var_k:I(above_k_num == 1) | k_index,
    data = df_h, weights = ~w_tri, cluster = ~mun_code
  ), error = function(e) NULL)

  if (!is.null(fit)) {
    bw_results[[as.character(h)]] <- data.frame(
      bandwidth = h, n_obs = nrow(df_h),
      coef = coef(fit)["above_k_num"],
      se = se(fit)["above_k_num"]
    )
    cat(sprintf("  h=%.2f: coef=%.4f (SE=%.4f), n=%d\n",
                h, coef(fit)["above_k_num"], se(fit)["above_k_num"], nrow(df_h)))
  }
}

bw_df <- bind_rows(bw_results)

## ─────────────────────────────────────────────────────────────────────────────
## 6. Density test (no manipulation)
## ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Spec 6: Density test ---\n")

# Test each threshold for bunching in population
# Use the cross-sectional population to test for manipulation
# For the pooled test, use the stacked normalized running variable

density_pval <- tryCatch({
  dt <- rddensity(X = df_stacked$run_var_k, c = 0)
  pval <- dt$test$p_jk
  cat(sprintf("  Density test p-value: %.4f\n", pval))
  pval
}, error = function(e) {
  cat("Density test error:", conditionMessage(e), "\n")
  NA
})

## ─────────────────────────────────────────────────────────────────────────────
## 7. Placebo test: Outcome in pre-period (2000-2004)
##    If RD captures a causal effect of FPM on post-period outcomes,
##    we should not see it in pre-period (when FPM brackets were same or similar)
## ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Spec 7: Placebo — Pre-period outcome ---\n")

# Compute pre-period avg crop area (2000-2004)
pre_cross <- df_panel %>%
  filter(year <= 2004) %>%
  group_by(mun_code) %>%
  summarise(avg_log_crop_pre = mean(log(crop_area_ha + 1), na.rm = TRUE), .groups = "drop")

df_stacked_pre <- df_stacked %>%
  filter(abs(run_var_k) <= h_opt) %>%
  left_join(pre_cross, by = "mun_code") %>%
  mutate(
    w_tri = 1 - abs(run_var_k) / h_opt,
    above_k_num = as.numeric(above_k)
  ) %>%
  filter(!is.na(avg_log_crop_pre))

rdd_placebo <- tryCatch(feols(
  avg_log_crop_pre ~ above_k_num +
    run_var_k:I(above_k_num == 0) +
    run_var_k:I(above_k_num == 1) | k_index,
  data = df_stacked_pre, weights = ~w_tri, cluster = ~mun_code
), error = function(e) { cat("Error:", conditionMessage(e), "\n"); NULL })

if (!is.null(rdd_placebo)) {
  placebo_coef <- coef(rdd_placebo)["above_k_num"]
  placebo_se   <- se(rdd_placebo)["above_k_num"]
  cat(sprintf("  Pre-period placebo: %.4f (SE: %.4f)\n", placebo_coef, placebo_se))
} else {
  placebo_coef <- placebo_se <- NA
}

## ─────────────────────────────────────────────────────────────────────────────
## 8. Covariate balance (municipality area as baseline check)
## ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Spec 8: Covariate balance ---\n")

# Log population as covariate (should be continuous through threshold)
rdd_pop <- tryCatch(feols(
  log(pop) ~ above_k_num +
    run_var_k:I(above_k_num == 0) +
    run_var_k:I(above_k_num == 1) | k_index,
  data = df_stacked_bw, weights = ~w_tri, cluster = ~mun_code
), error = function(e) NULL)

if (!is.null(rdd_pop)) {
  bal_coef <- coef(rdd_pop)["above_k_num"]
  bal_se   <- se(rdd_pop)["above_k_num"]
  cat(sprintf("  Population balance: %.4f (SE: %.4f)\n", bal_coef, bal_se))
} else {
  bal_coef <- bal_se <- NA
}

## ─────────────────────────────────────────────────────────────────────────────
## 9. Fiscal cost calculation
## ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Fiscal Cost ---\n")

# FPM interior pool in 2005 ≈ R$22 billion (22.5% of federal tax × 0.43)
# Municipal allocation = coeff_m / total_coefficients
total_coeff_sum  <- sum(df_cross$fpm_coeff_2000, na.rm = TRUE)
fpm_pool_2005_bn <- 22
annual_fpm_jump_mln <- 0.2 / total_coeff_sum * fpm_pool_2005_bn * 1e9 / 1e6

mean_crop_above <- df_stacked_bw %>%
  filter(above_k_num == 1) %>%
  pull(avg_crop_area) %>% mean(na.rm = TRUE)

pct_increase <- exp(rdd3_coef) - 1
ha_increase  <- mean_crop_above * pct_increase

cat(sprintf("  FPM bracket jump: R$%.1f million/year\n", annual_fpm_jump_mln))
cat(sprintf("  Mean crop area (above threshold): %.0f ha\n", mean_crop_above))
cat(sprintf("  Log-crop effect: %.4f → %.1f%% → %.0f ha additional\n",
            rdd3_coef, pct_increase * 100, ha_increase))

## ─────────────────────────────────────────────────────────────────────────────
## Save results
## ─────────────────────────────────────────────────────────────────────────────
write_json(list(
  n_obs     = nrow(df_stacked_bw),
  n_treated = as.integer(sum(df_stacked_bw$above_k_num)),
  n_pre     = as.integer(length(unique(df_panel$year[df_panel$year < 2005]))),
  n_municipalities = as.integer(n_distinct(df_stacked_bw$mun_code))
), "data/diagnostics.json", auto_unbox = TRUE)

saveRDS(
  list(rdd3 = rdd3, rdd4 = rdd4, rdd_placebo = rdd_placebo,
       bw_df = bw_df, h_opt = h_opt,
       rdd3_coef = rdd3_coef, rdd3_se = rdd3_se,
       rdd4_coef = rdd4_coef, rdd4_se = rdd4_se,
       placebo_coef = placebo_coef, placebo_se = placebo_se,
       density_pval = density_pval,
       annual_fpm_jump_mln = annual_fpm_jump_mln,
       pct_increase = pct_increase, ha_increase = ha_increase,
       mean_crop_above = mean_crop_above,
       df_stacked_bw = df_stacked_bw),
  "data/models.rds"
)

cat("\nAnalysis complete.\n")
cat(sprintf("  Main estimate: %.4f (SE=%.4f, p=%.4f)\n", rdd3_coef, rdd3_se, rdd3_pval))
cat(sprintf("  Donut: %.4f (%.4f)\n", rdd4_coef, rdd4_se))
cat(sprintf("  Placebo: %.4f (%.4f)\n", placebo_coef, placebo_se))
