# 03_main_analysis.R — RDD estimation
source("00_packages.R")

analysis <- readRDS("../data/analysis.rds")
df <- readRDS("../data/incidents_clean.rds")

cat("=== MAIN RDD ANALYSIS ===\n\n")

# -------------------------------------------------------
# 1. McCrary density test (rddensity)
# -------------------------------------------------------
cat("--- McCrary Density Test ---\n")
density_test <- rddensity(X = analysis$norm_cost_centered, c = 0)
cat("T-statistic:", density_test$test$t_jk, "\n")
cat("P-value:", density_test$test$p_jk, "\n")
cat("Interpretation:", ifelse(density_test$test$p_jk > 0.05,
  "PASS — no evidence of manipulation", "WARNING — potential manipulation"), "\n\n")

# -------------------------------------------------------
# 2. Main RDD: future incidents (t+1 to t+3)
# -------------------------------------------------------
cat("--- Main RDD: Future Incident Count ---\n")
rd_main <- rdrobust(
  y = analysis$future_incidents,
  x = analysis$norm_cost_centered,
  c = 0,
  kernel = "triangular",
  bwselect = "mserd",
  cluster = analysis$operator_id
)
summary(rd_main)

# Store results
main_coef <- rd_main$coef[1]  # Conventional
main_se <- rd_main$se[3]      # Robust SE
main_bw <- rd_main$bws[1, 1]  # Bandwidth
main_n_left <- rd_main$N_h[1]
main_n_right <- rd_main$N_h[2]

cat("\nMain result: beta =", round(main_coef, 3),
    ", robust SE =", round(main_se, 3),
    ", bandwidth =", round(main_bw, 3), "\n")

# -------------------------------------------------------
# 3. RDD: future cost
# -------------------------------------------------------
cat("\n--- RDD: Future Total Cost ---\n")
rd_cost <- rdrobust(
  y = analysis$future_cost,
  x = analysis$norm_cost_centered,
  c = 0,
  kernel = "triangular",
  bwselect = "mserd",
  cluster = analysis$operator_id
)
summary(rd_cost)

# -------------------------------------------------------
# 4. RDD: normalized future rate
# -------------------------------------------------------
cat("\n--- RDD: Normalized Future Rate ---\n")
rd_norm <- rdrobust(
  y = analysis$norm_future,
  x = analysis$norm_cost_centered,
  c = 0,
  kernel = "triangular",
  bwselect = "mserd",
  cluster = analysis$operator_id
)
summary(rd_norm)

# -------------------------------------------------------
# 5. Covariate balance tests
# -------------------------------------------------------
cat("\n--- Covariate Balance ---\n")

# Test balance on pre-treatment characteristics
if ("FATALITY_IND" %in% names(df)) {
  # Merge covariates to analysis
  covs <- df[, .(REPORT_NUMBER, FATALITY_IND, INJURY_IND, EXPLODE_IND)]
  # Try matching
}

# Balance on pre-incidents
rd_pre <- rdrobust(
  y = analysis$pre_incidents,
  x = analysis$norm_cost_centered,
  c = 0,
  kernel = "triangular",
  bwselect = "mserd",
  cluster = analysis$operator_id
)
cat("Pre-incidents balance: coef =", round(rd_pre$coef[1], 3),
    ", p =", round(2 * pnorm(-abs(rd_pre$coef[1] / rd_pre$se[3])), 3), "\n")

# -------------------------------------------------------
# 6. Save results
# -------------------------------------------------------
results <- list(
  density_test = list(
    t_stat = density_test$test$t_jk,
    p_value = density_test$test$p_jk
  ),
  main_rd = list(
    outcome = "future_incidents",
    coef = main_coef,
    se_robust = main_se,
    bandwidth = main_bw,
    n_left = main_n_left,
    n_right = main_n_right
  ),
  cost_rd = list(
    outcome = "future_cost",
    coef = rd_cost$coef[1],
    se_robust = rd_cost$se[3],
    bandwidth = rd_cost$bws[1, 1]
  ),
  norm_rd = list(
    outcome = "norm_future_rate",
    coef = rd_norm$coef[1],
    se_robust = rd_norm$se[3],
    bandwidth = rd_norm$bws[1, 1]
  ),
  pre_balance = list(
    coef = rd_pre$coef[1],
    se = rd_pre$se[3]
  )
)

saveRDS(results, "../data/main_results.rds")

# Write diagnostics.json for validator
diag <- list(
  n_treated = as.integer(sum(analysis$significant == 1)),
  n_pre = as.integer(length(unique(analysis$year[analysis$year < 2016]))),
  n_obs = as.integer(nrow(analysis))
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\nResults and diagnostics saved.\n")
