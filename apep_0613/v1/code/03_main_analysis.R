# 03_main_analysis.R — RDD estimates of female mayor effect on spending
# apep_0613: Female mayors and fiscal composition in Mexico

source("00_packages.R")
library(rdrobust)
library(rddensity)

data_dir <- "../data"
tables_dir <- "../tables"

analysis <- readRDS(file.path(data_dir, "analysis_rdd.rds"))
cat(sprintf("Analysis sample: %d elections\n", nrow(analysis)))

# ─── 1. McCrary manipulation test ──────────────────────────────────────────
cat("\n=== McCrary Density Test ===\n")
density_test <- rddensity(analysis$female_margin, c = 0)
cat(sprintf("McCrary p-value: %.4f\n", density_test$test$p_jk))
cat(sprintf("  N left: %d, N right: %d\n",
            density_test$N$left, density_test$N$right))

density_result <- list(
  p_value = density_test$test$p_jk,
  t_stat = density_test$test$t_jk,
  n_left = density_test$N$left,
  n_right = density_test$N$right
)

# ─── 2. Balance tests on pre-election covariates ───────────────────────────
cat("\n=== Covariate Balance Tests ===\n")

balance_vars <- c("pre_total_exp", "pre_share_serv_pers",
                  "pre_share_transfers", "pre_share_inv_pub",
                  "pre_log_total_exp")

balance_results <- list()
for (v in balance_vars) {
  y <- analysis[[v]]
  valid <- !is.na(y)

  if (sum(valid) < 50) {
    cat(sprintf("  %s: insufficient observations (%d)\n", v, sum(valid)))
    next
  }

  rd <- rdrobust(y[valid], analysis$female_margin[valid], c = 0)
  balance_results[[v]] <- list(
    coef = rd$coef[1],
    se = rd$se[3],       # robust SE
    p = rd$pv[3],        # robust p-value
    bw = rd$bws[1, 1],
    n_eff = rd$N_h[1] + rd$N_h[2]
  )
  cat(sprintf("  %s: coef=%.4f, robust p=%.3f, bw=%.3f, N_eff=%d\n",
              v, rd$coef[1], rd$pv[3], rd$bws[1, 1],
              rd$N_h[1] + rd$N_h[2]))
}

# ─── 3. Main RDD estimates ─────────────────────────────────────────────────
cat("\n=== Main RDD Results ===\n")

outcome_vars <- c("share_serv_pers", "share_transfers", "share_inv_pub",
                  "share_mat_sum", "share_serv_gen", "log_total_exp")

outcome_labels <- c("Admin Payroll Share", "Social Transfers Share",
                    "Public Investment Share", "Materials Share",
                    "General Services Share", "Log Total Expenditure")

rdd_results <- list()
for (i in seq_along(outcome_vars)) {
  v <- outcome_vars[i]
  y <- analysis[[v]]
  x <- analysis$female_margin

  valid <- !is.na(y) & !is.na(x)

  rd <- rdrobust(y[valid], x[valid], c = 0)

  rdd_results[[v]] <- list(
    label = outcome_labels[i],
    coef_conv = rd$coef[1],
    coef_bc = rd$coef[2],
    coef_robust = rd$coef[3],
    se_conv = rd$se[1],
    se_bc = rd$se[2],
    se_robust = rd$se[3],
    p_conv = rd$pv[1],
    p_bc = rd$pv[2],
    p_robust = rd$pv[3],
    ci_lower = rd$ci[3, 1],
    ci_upper = rd$ci[3, 2],
    bw = rd$bws[1, 1],
    bw_bias = rd$bws[2, 1],
    n_left = rd$N_h[1],
    n_right = rd$N_h[2],
    n_total = rd$N_h[1] + rd$N_h[2],
    dep_mean = mean(y[valid]),
    dep_sd = sd(y[valid])
  )

  cat(sprintf("\n%s (%s):\n", outcome_labels[i], v))
  cat(sprintf("  Conventional: %.4f (%.4f), p=%.3f\n",
              rd$coef[1], rd$se[1], rd$pv[1]))
  cat(sprintf("  Robust:       %.4f (%.4f), p=%.3f\n",
              rd$coef[3], rd$se[3], rd$pv[3]))
  cat(sprintf("  BW: %.3f, N_eff: %d+%d=%d\n",
              rd$bws[1, 1], rd$N_h[1], rd$N_h[2],
              rd$N_h[1] + rd$N_h[2]))
  cat(sprintf("  Dep. var mean: %.3f, SD: %.3f\n",
              mean(y[valid]), sd(y[valid])))
}

# ─── 4. Write diagnostics.json ─────────────────────────────────────────────
# Identify RDD effective sample for primary outcome
primary <- rdd_results[["share_transfers"]]

diagnostics <- list(
  n_treated = primary$n_right,   # Female mayor wins (right of cutoff)
  n_pre = 1,                     # RDD is cross-sectional (not panel)
  n_obs = nrow(analysis),
  method = "RDD",
  n_close_5pct = sum(abs(analysis$female_margin) < 0.05),
  n_close_10pct = sum(abs(analysis$female_margin) < 0.10),
  mccrary_p = density_result$p_value
)

write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
           auto_unbox = TRUE, pretty = TRUE)
cat("\nDiagnostics written to data/diagnostics.json\n")

# ─── 5. Covariate-adjusted RDD for payroll (addressing pre-period imbalance)
cat("\n=== Covariate-Adjusted RDD (controlling for pre-election payroll) ===\n")

# Residualize payroll outcome on pre-election payroll
valid_cov <- !is.na(analysis$share_serv_pers) &
             !is.na(analysis$female_margin) &
             !is.na(analysis$pre_share_serv_pers)

if (sum(valid_cov) > 50) {
  # Residualize outcome on pre-period covariate
  resid_payroll <- residuals(lm(share_serv_pers ~ pre_share_serv_pers,
                                data = analysis[valid_cov, ]))

  rd_cov <- rdrobust(resid_payroll, analysis$female_margin[valid_cov], c = 0)
  cov_adj_payroll <- list(
    coef = rd_cov$coef[1],
    se_robust = rd_cov$se[3],
    p_robust = rd_cov$pv[3],
    n_eff = rd_cov$N_h[1] + rd_cov$N_h[2],
    bw = rd_cov$bws[1, 1]
  )
  cat(sprintf("  Payroll (cov-adjusted): coef=%.4f, p=%.3f, N=%d\n",
              rd_cov$coef[1], rd_cov$pv[3], rd_cov$N_h[1] + rd_cov$N_h[2]))

  # Also do change specification: outcome - pre-period
  change_payroll <- analysis$share_serv_pers[valid_cov] -
                    analysis$pre_share_serv_pers[valid_cov]
  rd_change <- rdrobust(change_payroll, analysis$female_margin[valid_cov], c = 0)
  change_result <- list(
    coef = rd_change$coef[1],
    se_robust = rd_change$se[3],
    p_robust = rd_change$pv[3],
    n_eff = rd_change$N_h[1] + rd_change$N_h[2]
  )
  cat(sprintf("  Payroll (change): coef=%.4f, p=%.3f, N=%d\n",
              rd_change$coef[1], rd_change$pv[3],
              rd_change$N_h[1] + rd_change$N_h[2]))
} else {
  cov_adj_payroll <- NULL
  change_result <- NULL
}

# ─── 6. Minimum detectable effects ────────────────────────────────────────
cat("\n=== Minimum Detectable Effects (80% power, alpha=0.05) ===\n")
for (v in c("share_serv_pers", "share_transfers", "share_inv_pub")) {
  r <- rdd_results[[v]]
  # MDE ≈ 2.8 * SE (for 80% power, two-sided 5% test)
  mde <- 2.8 * r$se_robust
  mde_sd <- mde / r$dep_sd
  cat(sprintf("  %s: MDE = %.4f (%.2f SD)\n", v, mde, mde_sd))
}

# ─── 7. Save results for table generation ──────────────────────────────────
save(rdd_results, balance_results, density_result, analysis,
     cov_adj_payroll, change_result,
     file = file.path(data_dir, "rdd_results.RData"))
cat("Results saved to data/rdd_results.RData\n")
