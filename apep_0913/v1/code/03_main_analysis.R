## 03_main_analysis.R — Main spatial RDD estimation
## apep_0913: Wilderness spatial RDD

source("00_packages.R")
data_dir <- file.path(dirname(getwd()), "data")

df <- readRDS(file.path(data_dir, "analysis_clean.rds"))
cat("Loaded", nrow(df), "observations\n")

# ============================================================
# Primary sample: forested pixels within 5km
# ============================================================
df_main <- df %>% filter(forested == 1, within_5km)
cat("Primary sample (forested, 5km):", nrow(df_main), "\n")

# ============================================================
# 1. MAIN RDD: Tree cover loss at wilderness boundary
# ============================================================
cat("\n=== MAIN RDD ESTIMATION ===\n")

# rdrobust: local polynomial RDD with robust bias-corrected inference
# Running variable: dist_km (negative = inside wilderness)
# Outcome: any_loss (binary: any tree cover loss 2001-2023)
# Cutoff: 0 (the wilderness boundary)

rdd_main <- rdrobust(
  y = df_main$any_loss,
  x = df_main$dist_km,
  c = 0,
  kernel = "triangular",
  p = 1,  # Local linear
  bwselect = "mserd",  # MSE-optimal bandwidth
  cluster = NULL,  # Point-level data, no clustering needed at this stage
  all = TRUE
)

cat("\n--- Main RDD Result ---\n")
summary(rdd_main)

# Store results
main_coef <- rdd_main$coef[1]  # Conventional
main_coef_bc <- rdd_main$coef[2]  # Bias-corrected
main_se_rb <- rdd_main$se[3]  # Robust
main_ci_rb <- rdd_main$ci[3, ]  # Robust CI
main_bw <- rdd_main$bws[1, 1]  # Optimal bandwidth
main_n_left <- rdd_main$N_h[1]
main_n_right <- rdd_main$N_h[2]

cat("\nKey results:\n")
cat("  Conventional estimate:", round(main_coef, 4), "\n")
cat("  Bias-corrected estimate:", round(main_coef_bc, 4), "\n")
cat("  Robust SE:", round(main_se_rb, 4), "\n")
cat("  Robust 95% CI:", round(main_ci_rb, 4), "\n")
cat("  Optimal bandwidth:", round(main_bw, 2), "km\n")
cat("  N (left/right):", main_n_left, "/", main_n_right, "\n")

# ============================================================
# 2. RDD with elevation control
# ============================================================
cat("\n=== RDD WITH ELEVATION CONTROL ===\n")

df_elev <- df_main %>% filter(!is.na(elevation))

if (nrow(df_elev) > 1000) {
  rdd_elev <- rdrobust(
    y = df_elev$any_loss,
    x = df_elev$dist_km,
    c = 0,
    covs = cbind(df_elev$elevation),
    kernel = "triangular",
    p = 1,
    bwselect = "mserd",
    all = TRUE
  )
  cat("\n--- RDD with elevation control ---\n")
  summary(rdd_elev)
  elev_coef_bc <- rdd_elev$coef[2]
  elev_se_rb <- rdd_elev$se[3]
} else {
  cat("Insufficient observations with elevation data\n")
  elev_coef_bc <- NA
  elev_se_rb <- NA
}

# ============================================================
# 3. RDD on high-forest subsample (treecover >= 50%)
# ============================================================
cat("\n=== RDD ON HIGH-FOREST SUBSAMPLE ===\n")

df_hf <- df %>% filter(high_forest == 1, within_5km)
cat("High-forest sample:", nrow(df_hf), "\n")

if (nrow(df_hf) > 5000) {
  rdd_hf <- rdrobust(
    y = df_hf$any_loss,
    x = df_hf$dist_km,
    c = 0,
    kernel = "triangular",
    p = 1,
    bwselect = "mserd",
    all = TRUE
  )
  cat("\n--- High-forest RDD ---\n")
  summary(rdd_hf)
  hf_coef_bc <- rdd_hf$coef[2]
  hf_se_rb <- rdd_hf$se[3]
} else {
  cat("Insufficient high-forest observations\n")
  hf_coef_bc <- NA
  hf_se_rb <- NA
}

# ============================================================
# 4. RDD on baseline tree cover (balance test)
# ============================================================
cat("\n=== COVARIATE BALANCE: Treecover2000 at boundary ===\n")

rdd_tc <- rdrobust(
  y = df_main$treecover2000,
  x = df_main$dist_km,
  c = 0,
  kernel = "triangular",
  p = 1,
  bwselect = "mserd",
  all = TRUE
)
summary(rdd_tc)

# ============================================================
# 5. RDD on elevation (balance test)
# ============================================================
cat("\n=== COVARIATE BALANCE: Elevation at boundary ===\n")

if (nrow(df_elev) > 1000) {
  rdd_elev_bal <- rdrobust(
    y = df_elev$elevation,
    x = df_elev$dist_km,
    c = 0,
    kernel = "triangular",
    p = 1,
    bwselect = "mserd",
    all = TRUE
  )
  summary(rdd_elev_bal)
  elev_bal_coef <- rdd_elev_bal$coef[2]
  elev_bal_se <- rdd_elev_bal$se[3]
} else {
  elev_bal_coef <- NA
  elev_bal_se <- NA
}

# ============================================================
# 6. Density test (McCrary-style)
# ============================================================
cat("\n=== DENSITY TEST ===\n")

dens_test <- rddensity(X = df_main$dist_km, c = 0)
summary(dens_test)

# ============================================================
# Save all results
# ============================================================
results <- list(
  main = list(
    coef = main_coef,
    coef_bc = main_coef_bc,
    se_rb = main_se_rb,
    ci_rb = main_ci_rb,
    bw = main_bw,
    n_left = main_n_left,
    n_right = main_n_right,
    pval = rdd_main$pv[3]
  ),
  elev_control = list(
    coef_bc = elev_coef_bc,
    se_rb = elev_se_rb
  ),
  high_forest = list(
    coef_bc = hf_coef_bc,
    se_rb = hf_se_rb
  ),
  balance = list(
    tc2000_coef = rdd_tc$coef[2],
    tc2000_se = rdd_tc$se[3],
    tc2000_pval = rdd_tc$pv[3],
    elev_coef = elev_bal_coef,
    elev_se = elev_bal_se
  ),
  density_test = list(
    T_stat = dens_test$test$t_jk,
    p_val = dens_test$test$p_jk
  ),
  sample = list(
    n_main = nrow(df_main),
    n_high_forest = nrow(df_hf),
    mean_loss_inside = mean(df_main$any_loss[df_main$wilderness == 1], na.rm = TRUE),
    mean_loss_outside = mean(df_main$any_loss[df_main$wilderness == 0], na.rm = TRUE),
    sd_loss = sd(df_main$any_loss, na.rm = TRUE)
  )
)

saveRDS(results, file.path(data_dir, "rdd_results.rds"))

# Diagnostics for validator
n_wilderness_areas <- readRDS(file.path(data_dir, "metadata.rds"))$n_wilderness
diagnostics <- list(
  n_treated = results$main$n_left,  # Points inside wilderness (left of cutoff)
  n_pre = n_wilderness_areas,  # Number of wilderness areas (unit count)
  n_obs = nrow(df_main)
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE)

cat("\n=== RESULTS SAVED ===\n")
cat("Main effect (bias-corrected):", round(main_coef_bc, 4), "\n")
cat("Robust SE:", round(main_se_rb, 4), "\n")
cat("P-value:", round(rdd_main$pv[3], 4), "\n")
cat("Interpretation: Wilderness designation",
    ifelse(main_coef_bc > 0, "reduces", "increases"),
    "tree cover loss at the boundary by",
    round(abs(main_coef_bc) * 100, 2), "pp\n",
    "(positive coef = outside > inside = wilderness reduces loss)\n")
