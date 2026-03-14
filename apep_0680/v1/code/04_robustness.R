## 04_robustness.R — Robustness checks and validity tests
## apep_0680: ZFE Spatial RDD on Property Values

source("code/00_packages.R")

cat("=== Robustness Checks ===\n\n")

dvf <- readRDS("data/analysis_data.rds")
post <- dvf[post == 1 & in_sample_2km == TRUE]

# ---- 1. McCrary Density Test ----
cat("--- McCrary Density Test (Post-ZFE) ---\n")
density_test <- rddensity(X = post$signed_dist_km, c = 0)
cat(sprintf("McCrary test p-value: %.4f\n", density_test$test$p_jk))
cat(sprintf("  (p > 0.05 supports no manipulation)\n"))

# Also test pre-period
pre <- dvf[post == 0 & in_sample_2km == TRUE]
density_pre <- rddensity(X = pre$signed_dist_km, c = 0)
cat(sprintf("Pre-period density test p-value: %.4f\n", density_pre$test$p_jk))

# ---- 2. Bandwidth Sensitivity ----
cat("\n--- Bandwidth Sensitivity ---\n")
bandwidths <- c(0.5, 0.75, 1.0, 1.5, 2.0)
bw_results <- data.frame(
  bandwidth_km = numeric(),
  tau = numeric(),
  se_robust = numeric(),
  n_eff = integer()
)

for (bw in bandwidths) {
  sub <- post[abs(signed_dist_km) <= bw]
  if (nrow(sub) < 50) {
    cat(sprintf("BW = %.1f km: insufficient obs (%d)\n", bw, nrow(sub)))
    next
  }
  rdd_bw <- rdrobust(y = sub$log_price_m2, x = sub$signed_dist_km, c = 0,
                     kernel = "triangular", p = 1, h = bw)
  bw_results <- rbind(bw_results, data.frame(
    bandwidth_km = bw,
    tau = rdd_bw$coef[1],
    se_robust = rdd_bw$se[3],
    n_eff = sum(rdd_bw$N_h)
  ))
  cat(sprintf("BW = %.1f km: τ = %.4f (SE = %.4f), N = %d\n",
              bw, rdd_bw$coef[1], rdd_bw$se[3], sum(rdd_bw$N_h)))
}

# ---- 3. Polynomial Sensitivity ----
cat("\n--- Polynomial Order Sensitivity ---\n")
for (p_order in 1:3) {
  rdd_p <- rdrobust(y = post$log_price_m2, x = post$signed_dist_km, c = 0,
                    kernel = "triangular", p = p_order, bwselect = "mserd")
  cat(sprintf("Polynomial p=%d: τ = %.4f (SE = %.4f), BW = %.3f km\n",
              p_order, rdd_p$coef[1], rdd_p$se[3], rdd_p$bws[1, 1]))
}

# ---- 4. Placebo Cutoffs ----
cat("\n--- Placebo Cutoff Tests ---\n")
placebo_cutoffs <- c(-1.5, -1.0, -0.5, 0.5, 1.0, 1.5)
placebo_results <- data.frame(
  cutoff_km = numeric(),
  tau = numeric(),
  se_robust = numeric(),
  pval = numeric()
)

for (pc in placebo_cutoffs) {
  # Only use observations on one side of true boundary
  if (pc < 0) {
    sub <- post[signed_dist_km < 0 & signed_dist_km > (pc - 1)]
  } else {
    sub <- post[signed_dist_km > 0 & signed_dist_km < (pc + 1)]
  }
  if (nrow(sub) < 50) next
  rdd_pc <- tryCatch(
    rdrobust(y = sub$log_price_m2, x = sub$signed_dist_km, c = pc,
             kernel = "triangular", p = 1, bwselect = "mserd"),
    error = function(e) NULL
  )
  if (is.null(rdd_pc)) next
  placebo_results <- rbind(placebo_results, data.frame(
    cutoff_km = pc,
    tau = rdd_pc$coef[1],
    se_robust = rdd_pc$se[3],
    pval = rdd_pc$pv[3]
  ))
  cat(sprintf("Placebo at %.1f km: τ = %.4f (SE = %.4f, p = %.3f)\n",
              pc, rdd_pc$coef[1], rdd_pc$se[3], rdd_pc$pv[3]))
}

# ---- 5. Covariate Balance at Boundary ----
cat("\n--- Covariate Balance Test ---\n")
post_near <- post[abs(signed_dist_km) <= 0.5]
balance_vars <- c("surface_reelle_bati", "rooms", "is_apartment")

balance_results <- data.frame(
  variable = character(),
  mean_inside = numeric(),
  mean_outside = numeric(),
  diff = numeric(),
  pval = numeric()
)

for (v in balance_vars) {
  inside_vals <- post_near[inside_zfe == TRUE, get(v)]
  outside_vals <- post_near[inside_zfe == FALSE, get(v)]
  tt <- t.test(inside_vals, outside_vals)
  balance_results <- rbind(balance_results, data.frame(
    variable = v,
    mean_inside = mean(inside_vals, na.rm = TRUE),
    mean_outside = mean(outside_vals, na.rm = TRUE),
    diff = tt$estimate[1] - tt$estimate[2],
    pval = tt$p.value
  ))
  cat(sprintf("%s: inside = %.2f, outside = %.2f, diff = %.2f (p = %.3f)\n",
              v, mean(inside_vals, na.rm = TRUE), mean(outside_vals, na.rm = TRUE),
              tt$estimate[1] - tt$estimate[2], tt$p.value))
}

# ---- 6. Kernel Sensitivity ----
cat("\n--- Kernel Sensitivity ---\n")
for (kern in c("triangular", "epanechnikov", "uniform")) {
  rdd_k <- rdrobust(y = post$log_price_m2, x = post$signed_dist_km, c = 0,
                    kernel = kern, p = 1, bwselect = "mserd")
  cat(sprintf("Kernel = %s: τ = %.4f (SE = %.4f)\n",
              kern, rdd_k$coef[1], rdd_k$se[3]))
}

# ---- 7. Save robustness results ----
rob_results <- list(
  mccrary_pval = density_test$test$p_jk,
  mccrary_pre_pval = density_pre$test$p_jk,
  bandwidth_sensitivity = bw_results,
  placebo_cutoffs = placebo_results,
  balance = balance_results
)
saveRDS(rob_results, "data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
