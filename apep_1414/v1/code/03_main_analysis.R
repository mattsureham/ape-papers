## 03_main_analysis.R — Main RDD analysis for UK MOT threshold
## apep_1414: UK MOT First-Inspection RDD

source("code/00_packages.R")
setwd(here::here("output", "apep_1414", "v1"))

df <- readRDS("data/analysis_dataset.rds")
cat(sprintf("Analysis dataset loaded: %d observations\n", nrow(df)))

## ──────────────────────────────────────────────────────────────
## 1. McCrary Density Test (sorting/manipulation check)
## ──────────────────────────────────────────────────────────────

cat("\n--- McCrary Density Test ---\n")

density_result <- rddensity(df$rv, c = 0)
density_summary <- summary(density_result)
print(density_summary)

# Save density test results
density_stats <- list(
  t_stat = density_result$test$t_jk,
  p_value = density_result$test$p_jk,
  bw_left = density_result$h$left,
  bw_right = density_result$h$right,
  interpretation = ifelse(density_result$test$p_jk > 0.05,
                           "No evidence of manipulation (p > 0.05)",
                           "CAUTION: Possible bunching at threshold")
)
cat(sprintf("\nDensity test: t=%.3f, p=%.4f\n%s\n",
            density_stats$t_stat, density_stats$p_value, density_stats$interpretation))

saveRDS(density_result, "data/density_result.rds")
saveRDS(density_stats, "data/density_stats.rds")

## ──────────────────────────────────────────────────────────────
## 2. Covariate Balance at Threshold
## ──────────────────────────────────────────────────────────────

cat("\n--- Covariate Balance ---\n")

# Check balance for key covariates
covariates_to_check <- intersect(
  c("test_mileage", "reg_year"),
  names(df)
)

covariate_balance <- list()
for (cov in covariates_to_check) {
  df_cov <- df %>% filter(!is.na(.data[[cov]]))
  if (nrow(df_cov) < 100) next

  balance_rdd <- tryCatch({
    rdrobust(y = df_cov[[cov]], x = df_cov$rv, c = 0)
  }, error = function(e) {
    cat(sprintf("Warning: balance check failed for %s: %s\n", cov, e$message))
    NULL
  })

  if (!is.null(balance_rdd)) {
    covariate_balance[[cov]] <- list(
      coef = balance_rdd$coef[1],
      se = balance_rdd$se[1],
      p_value = balance_rdd$pv[1],
      bw = balance_rdd$bws[1]
    )
    cat(sprintf("Balance: %s — coef=%.3f (se=%.3f, p=%.3f)\n",
                cov, balance_rdd$coef[1], balance_rdd$se[1], balance_rdd$pv[1]))
  }
}
saveRDS(covariate_balance, "data/covariate_balance.rds")

## ──────────────────────────────────────────────────────────────
## 3. Main RDD — First-test failure rate outcome
## ──────────────────────────────────────────────────────────────

cat("\n--- Main RDD: First-Test Failure Rate ---\n")

df_rdd <- df %>% filter(!is.na(y_first))
cat(sprintf("Using %d observations for main RDD\n", nrow(df_rdd)))
cat(sprintf("Overall failure rate: %.3f\n", mean(df_rdd$y_first)))

# Main specification: rdrobust with bias-corrected CI
rdd_main <- rdrobust(y = df_rdd$y_first, x = df_rdd$rv, c = 0,
                     kernel = "triangular", bwselect = "mserd")
summary(rdd_main)

cat(sprintf("\nMain RDD estimate (conventional): %.4f (SE=%.4f, p=%.4f)\n",
            rdd_main$coef[1], rdd_main$se[1], rdd_main$pv[1]))
cat(sprintf("Main RDD estimate (robust): %.4f (SE=%.4f, p=%.4f)\n",
            rdd_main$coef[3], rdd_main$se[3], rdd_main$pv[3]))
cat(sprintf("Optimal bandwidth: %.2f months\n", rdd_main$bws[1]))
cat(sprintf("N within bandwidth: Left=%d, Right=%d\n",
            rdd_main$N_h[1], rdd_main$N_h[2]))

saveRDS(rdd_main, "data/rdd_main.rds")

## ──────────────────────────────────────────────────────────────
## 4. Second-test outcome (if available)
## ──────────────────────────────────────────────────────────────

rdd_second <- NULL
if (any(!is.na(df$y_second))) {
  df_second <- df %>% filter(!is.na(y_second))
  cat(sprintf("\n--- Main RDD: Second-Test Failure Rate (N=%d) ---\n", nrow(df_second)))
  cat(sprintf("Second-test failure rate: %.3f\n", mean(df_second$y_second)))

  rdd_second <- tryCatch({
    rdrobust(y = df_second$y_second, x = df_second$rv, c = 0,
             kernel = "triangular", bwselect = "mserd")
  }, error = function(e) {
    cat("Warning: Second-test RDD failed:", e$message, "\n")
    NULL
  })

  if (!is.null(rdd_second)) {
    summary(rdd_second)
    cat(sprintf("\nSecond-test RDD estimate (robust): %.4f (SE=%.4f, p=%.4f)\n",
                rdd_second$coef[3], rdd_second$se[3], rdd_second$pv[3]))
    saveRDS(rdd_second, "data/rdd_second.rds")
  }
}

## ──────────────────────────────────────────────────────────────
## 5. Summary statistics
## ──────────────────────────────────────────────────────────────

cat("\n--- Summary Statistics ---\n")

# Overall summary
summary_stats <- df %>%
  mutate(side = ifelse(rv >= 0, "At/After 36m (Mandatory)", "Before 36m (Voluntary)")) %>%
  group_by(side) %>%
  summarise(
    n = n(),
    age_months_mean = mean(age_months_at_test, na.rm = TRUE),
    age_months_sd = sd(age_months_at_test, na.rm = TRUE),
    failure_rate_first = mean(y_first, na.rm = TRUE),
    failure_rate_second = mean(y_second, na.rm = TRUE),
    mileage_mean = mean(test_mileage, na.rm = TRUE),
    .groups = "drop"
  )
print(summary_stats)

# Within-bandwidth summary (IK bandwidth)
bw <- rdd_main$bws[1]
df_bw <- df %>% filter(abs(rv) <= bw, !is.na(y_first))
summary_bw <- df_bw %>%
  mutate(side = ifelse(rv >= 0, "Mandatory (right of cutoff)", "Voluntary (left of cutoff)")) %>%
  group_by(side) %>%
  summarise(
    n = n(),
    age_at_test_mean = mean(age_months_at_test, na.rm = TRUE),
    failure_rate = mean(y_first, na.rm = TRUE),
    failure_rate_sd = sd(y_first, na.rm = TRUE),
    mileage_mean = mean(test_mileage, na.rm = TRUE),
    mileage_sd = sd(test_mileage, na.rm = TRUE),
    .groups = "drop"
  )
cat("\nWithin-bandwidth summary:\n")
print(summary_bw)

saveRDS(summary_stats, "data/summary_stats.rds")
saveRDS(summary_bw, "data/summary_bw.rds")

## ──────────────────────────────────────────────────────────────
## 6. diagnostics.json for validate_v1.py
## ──────────────────────────────────────────────────────────────

n_treated <- sum(df_rdd$rv >= 0)
n_control <- sum(df_rdd$rv < 0)
n_obs <- nrow(df_rdd)
n_pre <- abs(min(df_rdd$rv))  # months before threshold in data

jsonlite::write_json(list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_control = n_control,
  failure_rate_overall = mean(df_rdd$y_first),
  rdd_estimate_conventional = rdd_main$coef[1],
  rdd_estimate_robust = rdd_main$coef[3],
  optimal_bw = rdd_main$bws[1],
  density_p_value = density_stats$p_value
), "data/diagnostics.json", auto_unbox = TRUE)

cat("\n03_main_analysis.R complete.\n")
cat(sprintf("Key result: RDD estimate = %.4f (robust p = %.4f)\n",
            rdd_main$coef[3], rdd_main$pv[3]))
