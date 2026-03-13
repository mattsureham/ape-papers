## 03_main_analysis.R — Main RDD analysis (full sample, fuzzy design)
## APEP paper apep_0614: CEJST Justice40 RDD

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

analysis <- readRDS(file.path(data_dir, "analysis_dataset.rds"))

# ============================================================
# Full sample RDD: income percentile as running variable
# ============================================================
# CEJST designates tracts that meet income AND burden thresholds.
# Among ALL tracts, crossing the income threshold (~0.65) sharply
# increases designation probability (for those with burden).
# This is a FUZZY RDD at the income threshold.

# Use all tracts with valid income percentile
rdd_full <- analysis[!is.na(income_pctile)]
cat("Full RDD sample:", nrow(rdd_full), "tracts\n")

# Check designation rates above/below cutoff
rdd_full[, above_cutoff := as.integer(rv_centered >= 0)]
designation_by_cutoff <- rdd_full[, .(
  n = .N,
  n_designated = sum(designated == 1),
  pct_designated = round(100 * mean(designated), 1)
), by = above_cutoff]
cat("\nDesignation rates by income cutoff position:\n")
print(designation_by_cutoff)

# The first stage: does crossing the income threshold increase designation?
# Above cutoff: ~X% designated; Below cutoff: ~Y% designated
# The JUMP at the cutoff is the first stage

# ============================================================
# 1. McCrary Density Test (with mass point correction)
# ============================================================
cat("\n=== McCrary Density Test ===\n")
# Income percentile has mass points (discrete values). Use rddensity with care.
density_test <- tryCatch(
  rddensity(X = rdd_full$rv_centered, vce = "jackknife"),
  error = function(e) { cat("Density test error:", e$message, "\n"); NULL }
)
if (!is.null(density_test)) {
  cat("T-statistic:", density_test$test$t_jk, "\n")
  cat("P-value:", density_test$test$p_jk, "\n")
  # Note: rejection likely due to mass points, not manipulation
}

# ============================================================
# 2. First Stage: Income Threshold → Designation
# ============================================================
cat("\n=== First Stage: Income Threshold → Designation ===\n")

first_stage <- rdrobust(
  y = rdd_full$designated,
  x = rdd_full$rv_centered,
  c = 0,
  kernel = "triangular",
  bwselect = "mserd",
  vce = "hc1",
  masspoints = "adjust"  # Handle mass points
)
cat("\n--- First Stage ---\n")
summary(first_stage)

# ============================================================
# 3. Reduced Form: Income Threshold → EV Chargers
# ============================================================
cat("\n=== Reduced Form: EV Charger Deployment ===\n")

# Outcome 1: Any new EV charger (extensive margin)
rf_ev_any <- rdrobust(
  y = rdd_full$any_ev_post,
  x = rdd_full$rv_centered,
  c = 0,
  kernel = "triangular",
  bwselect = "mserd",
  vce = "hc1",
  masspoints = "adjust"
)
cat("\n--- Any New EV Charger (Reduced Form) ---\n")
summary(rf_ev_any)

# Outcome 2: EV charger count
rf_ev_count <- rdrobust(
  y = rdd_full$ev_count_post,
  x = rdd_full$rv_centered,
  c = 0,
  kernel = "triangular",
  bwselect = "mserd",
  vce = "hc1",
  masspoints = "adjust"
)
cat("\n--- EV Charger Count (Reduced Form) ---\n")
summary(rf_ev_count)

# Outcome 3: EV change (post - pre)
rf_ev_change <- rdrobust(
  y = rdd_full$ev_change,
  x = rdd_full$rv_centered,
  c = 0,
  kernel = "triangular",
  bwselect = "mserd",
  vce = "hc1",
  masspoints = "adjust"
)
cat("\n--- EV Charger Change (Reduced Form) ---\n")
summary(rf_ev_change)

# ============================================================
# 4. Reduced Form: Income Threshold → Mortgage Originations
# ============================================================
cat("\n=== Reduced Form: Mortgage Originations ===\n")

rdd_hmda <- rdd_full[!is.na(orig_post)]
cat("HMDA RDD sample:", nrow(rdd_hmda), "\n")

if (nrow(rdd_hmda) > 1000) {
  rf_orig <- rdrobust(
    y = rdd_hmda$orig_post,
    x = rdd_hmda$rv_centered,
    c = 0,
    kernel = "triangular",
    bwselect = "mserd",
    vce = "hc1",
    masspoints = "adjust"
  )
  cat("\n--- Post-Period Originations (Reduced Form) ---\n")
  summary(rf_orig)

  rf_orig_change <- rdrobust(
    y = rdd_hmda$orig_change,
    x = rdd_hmda$rv_centered,
    c = 0,
    kernel = "triangular",
    bwselect = "mserd",
    vce = "hc1",
    masspoints = "adjust"
  )
  cat("\n--- Origination Change (Reduced Form) ---\n")
  summary(rf_orig_change)
} else {
  rf_orig <- NULL
  rf_orig_change <- NULL
}

# ============================================================
# 5. Fuzzy RDD (2SLS): Designation → Outcomes
# ============================================================
cat("\n=== Fuzzy RDD: Designation → EV Chargers ===\n")

fuzzy_ev_any <- rdrobust(
  y = rdd_full$any_ev_post,
  x = rdd_full$rv_centered,
  c = 0,
  fuzzy = rdd_full$designated,
  kernel = "triangular",
  bwselect = "mserd",
  vce = "hc1",
  masspoints = "adjust"
)
cat("\n--- Fuzzy RDD: Any New EV Charger ---\n")
summary(fuzzy_ev_any)

# ============================================================
# 6. Bandwidth Sensitivity
# ============================================================
cat("\n=== Bandwidth Sensitivity ===\n")

h_opt <- rf_ev_any$bws[1, 1]
bw_multipliers <- c(0.5, 0.75, 1.0, 1.25, 1.5)
bw_results <- list()

for (m in bw_multipliers) {
  h <- h_opt * m
  fit <- rdrobust(
    y = rdd_full$any_ev_post,
    x = rdd_full$rv_centered,
    c = 0,
    h = h,
    kernel = "triangular",
    vce = "hc1",
    masspoints = "adjust"
  )
  bw_results[[as.character(m)]] <- data.table(
    multiplier = m,
    bandwidth = h,
    estimate = fit$coef[1],
    se = fit$se[1],
    ci_lower = fit$ci[1, 1],
    ci_upper = fit$ci[1, 2],
    pval = fit$pv[1],
    n_left = fit$N_h[1],
    n_right = fit$N_h[2]
  )
}

bw_sensitivity <- rbindlist(bw_results)
cat("\nBandwidth sensitivity (Any EV, Reduced Form):\n")
print(bw_sensitivity)

# ============================================================
# 7. Covariate Balance
# ============================================================
cat("\n=== Covariate Balance ===\n")

covariates <- c("population", "ev_count_pre", "DM_W", "DM_B", "DM_H")
if ("orig_pre" %in% names(rdd_full)) covariates <- c(covariates, "orig_pre")

balance_results <- list()
for (cov in covariates) {
  y_cov <- rdd_full[[cov]]
  if (sum(!is.na(y_cov)) < 500) next

  fit_cov <- tryCatch(
    rdrobust(y = y_cov, x = rdd_full$rv_centered, c = 0,
             kernel = "triangular", bwselect = "mserd", vce = "hc1",
             masspoints = "adjust"),
    error = function(e) NULL
  )
  if (!is.null(fit_cov)) {
    balance_results[[cov]] <- data.table(
      covariate = cov,
      estimate = fit_cov$coef[1],
      se = fit_cov$se[1],
      pval = fit_cov$pv[1],
      n_eff = fit_cov$N_h[1] + fit_cov$N_h[2]
    )
  }
}

balance_dt <- if (length(balance_results) > 0) rbindlist(balance_results) else NULL
if (!is.null(balance_dt)) {
  cat("\nCovariate balance:\n")
  print(balance_dt)
}

# ============================================================
# 8. Save Results
# ============================================================

results <- list(
  first_stage = first_stage,
  rf_ev_any = rf_ev_any,
  rf_ev_count = rf_ev_count,
  rf_ev_change = rf_ev_change,
  rf_orig = if (exists("rf_orig")) rf_orig else NULL,
  rf_orig_change = if (exists("rf_orig_change")) rf_orig_change else NULL,
  fuzzy_ev_any = fuzzy_ev_any,
  bw_sensitivity = bw_sensitivity,
  balance = balance_dt,
  density_test = density_test,
  designation_by_cutoff = designation_by_cutoff,
  rdd_sample_n = nrow(rdd_full),
  n_designated = sum(rdd_full$designated == 1),
  n_not_designated = sum(rdd_full$designated == 0)
)

saveRDS(results, file.path(data_dir, "main_results.rds"))

# Write diagnostics.json
diagnostics <- list(
  n_treated = sum(rdd_full$designated == 1),
  n_pre = 24L,  # 24 months of pre-treatment EV data (Nov 2020 - Oct 2022)
  n_obs = nrow(rdd_full),
  n_control = sum(rdd_full$designated == 0),
  design = "fuzzy_rdd",
  running_variable = "income_percentile",
  cutoff = 0.65,
  mse_bandwidth = h_opt,
  density_test_pval = if (!is.null(density_test)) density_test$test$p_jk else NA,
  first_stage_coef = first_stage$coef[1],
  first_stage_se = first_stage$se[1]
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("\nResults saved.\n")
