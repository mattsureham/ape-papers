# 03_main_analysis.R — Main RDD, DiD, and triple-diff estimation
# apep_0712: UK Ground Rent Abolition

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"

rdd_sample <- readRDS(file.path(data_dir, "rdd_sample.rds"))
did_sample <- readRDS(file.path(data_dir, "did_sample.rds"))
triplediff_sample <- readRDS(file.path(data_dir, "triplediff_sample.rds"))

# ============================================================
# 1. RDD: Temporal discontinuity at June 30, 2022
# ============================================================
cat("=== RDD ESTIMATION ===\n")

# --- 1a. McCrary density test ---
cat("\n--- Density test (rddensity) ---\n")
density_test <- rddensity(X = rdd_sample$days_from_cutoff, c = 0)
cat(sprintf("Test statistic: %.3f\n", density_test$test$t_jk))
cat(sprintf("P-value: %.4f\n", density_test$test$p_jk))

# --- 1b. Main RDD: log(price) ---
cat("\n--- Main RDD: log(price) on days from cutoff ---\n")
rdd_main <- rdrobust(
  y = rdd_sample$log_price,
  x = rdd_sample$days_from_cutoff,
  c = 0,
  kernel = "triangular",
  p = 1,  # local linear
  bwselect = "mserd"
)
summary(rdd_main)

# Store key results
rdd_coef <- rdd_main$coef[1]       # conventional estimate
rdd_se <- rdd_main$se[3]           # robust SE
rdd_bw <- rdd_main$bws[1, 1]      # bandwidth (left=right with mserd)
rdd_n_left <- rdd_main$N_h[1]     # obs below
rdd_n_right <- rdd_main$N_h[2]    # obs above
rdd_ci_lo <- rdd_main$ci[3, 1]    # robust CI lower
rdd_ci_hi <- rdd_main$ci[3, 2]    # robust CI upper

cat(sprintf("\nRDD estimate: %.4f (SE = %.4f)\n", rdd_coef, rdd_se))
cat(sprintf("Robust 95%% CI: [%.4f, %.4f]\n", rdd_ci_lo, rdd_ci_hi))
cat(sprintf("Bandwidth: %.1f days\n", rdd_bw))
cat(sprintf("Effective N: %d (left) + %d (right) = %d\n",
            rdd_n_left, rdd_n_right, rdd_n_left + rdd_n_right))

# In GBP terms
mean_price <- mean(rdd_sample$price)
gbp_effect <- mean_price * (exp(rdd_coef) - 1)
cat(sprintf("In GBP: ~£%.0f (at mean price £%.0f)\n", gbp_effect, mean_price))

# --- 1c. RDD with multiple bandwidths ---
cat("\n--- Bandwidth sensitivity ---\n")
bw_grid <- c(30, 60, 90, 120, 180, 270, 365)
rdd_bw_results <- lapply(bw_grid, function(h) {
  fit <- rdrobust(
    y = rdd_sample$log_price,
    x = rdd_sample$days_from_cutoff,
    c = 0, kernel = "triangular", p = 1, h = h
  )
  data.frame(
    bandwidth = h,
    coef = fit$coef[1],
    se_robust = fit$se[3],
    ci_lo = fit$ci[3, 1],
    ci_hi = fit$ci[3, 2],
    n_eff = fit$N_h[1] + fit$N_h[2],
    pval = fit$pv[3]
  )
})
rdd_bw_df <- bind_rows(rdd_bw_results)
print(rdd_bw_df)

# ============================================================
# 2. Difference-in-Differences
# ============================================================
cat("\n\n=== DiD ESTIMATION ===\n")

# New-build leasehold flats (treated) vs new-build freehold (control)
# Before/after June 30, 2022

# Simple 2x2 DiD with fixest
did_fit <- feols(
  log_price ~ treated * post | postcode_area + ym,
  data = did_sample,
  cluster = ~postcode_area
)
cat("\n--- DiD: log(price) ~ treated × post ---\n")
summary(did_fit)

did_coef <- coef(did_fit)["treated:post"]
did_se <- se(did_fit)["treated:post"]
cat(sprintf("\nDiD estimate: %.4f (SE = %.4f)\n", did_coef, did_se))

# ============================================================
# 3. Triple-Difference
# ============================================================
cat("\n\n=== TRIPLE-DIFF ESTIMATION ===\n")

# The three-way interaction `leasehold × new-build × post` is collinear with ym FE
# because `post` is a deterministic function of time. Solution: manually construct
# the DDD variable and include the two-way interactions explicitly.
triplediff_sample[, `:=`(
  ddd_var = treated_lease * treated_new * post,
  lease_post = treated_lease * post,
  new_post = treated_new * post,
  lease_new = treated_lease * treated_new
)]

# Drop ym FE; use year + quarter FE to avoid perfect collinearity with post
ddd_fit <- feols(
  log_price ~ treated_lease + treated_new + lease_new +
    lease_post + new_post + ddd_var | postcode_area + year + quarter,
  data = triplediff_sample,
  cluster = ~postcode_area
)
cat("\n--- Triple-diff: log(price) ~ leasehold × new-build × post ---\n")
summary(ddd_fit)

ddd_coef <- coef(ddd_fit)["ddd_var"]
ddd_se <- se(ddd_fit)["ddd_var"]
cat(sprintf("\nDDD estimate: %.4f (SE = %.4f)\n", ddd_coef, ddd_se))

# ============================================================
# 4. Save diagnostics for validator
# ============================================================
diagnostics <- list(
  n_treated = sum(rdd_sample$post == 1),
  n_pre = length(unique(rdd_sample$ym[rdd_sample$post == 0])),
  n_obs = nrow(rdd_sample),
  rdd_coef = rdd_coef,
  rdd_se = rdd_se,
  rdd_bw = rdd_bw,
  did_coef = did_coef,
  did_se = did_se,
  ddd_coef = ddd_coef,
  ddd_se = ddd_se,
  density_pval = density_test$test$p_jk,
  mean_price = mean_price,
  sd_log_price = sd(rdd_sample$log_price)
)
write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

# Save model objects for tables
save(rdd_main, rdd_bw_df, did_fit, ddd_fit, density_test,
     rdd_sample, did_sample, triplediff_sample,
     file = file.path(data_dir, "main_models.RData"))

cat("\nMain analysis complete. Results saved.\n")
