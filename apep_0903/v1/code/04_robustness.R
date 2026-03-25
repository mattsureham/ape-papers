# 04_robustness.R — Robustness checks for Swiss Second Home Ban RDD
# apep_0903

base_dir <- normalizePath(file.path(getwd(), ".."))
source(file.path(base_dir, "code", "00_packages.R"))
data_dir <- file.path(base_dir, "data")

cat("=== Robustness Checks ===\n")

rdd_data <- readRDS(file.path(data_dir, "rdd_data.rds"))

# ---------------------------------------------------------------
# 1. Bandwidth sensitivity
# ---------------------------------------------------------------

cat("\n=== Bandwidth Sensitivity ===\n")

# Get MSE-optimal bandwidth from main spec
main_rdd <- rdrobust::rdrobust(
  y = rdd_data$delta_pct_secondary,
  x = rdd_data$running_var,
  c = 0, kernel = "triangular", p = 1, bwselect = "mserd",
  masspoints = "adjust"
)
h_opt <- main_rdd$bws[1, 1]

bw_multipliers <- c(0.5, 0.75, 1.0, 1.25, 1.5, 2.0)
bw_results <- data.table(
  multiplier = bw_multipliers,
  bandwidth = bw_multipliers * h_opt,
  coef = NA_real_,
  se_robust = NA_real_,
  p_value = NA_real_,
  n_eff = NA_integer_
)

for (i in seq_along(bw_multipliers)) {
  bw_i <- bw_multipliers[i] * h_opt
  rdd_i <- rdrobust::rdrobust(
    y = rdd_data$delta_pct_secondary,
    x = rdd_data$running_var,
    c = 0, kernel = "triangular", p = 1,
    h = bw_i, masspoints = "adjust"
  )
  bw_results[i, coef := rdd_i$coef[1]]
  bw_results[i, se_robust := rdd_i$se[3]]
  bw_results[i, p_value := rdd_i$pv[3]]
  bw_results[i, n_eff := rdd_i$N_h[1] + rdd_i$N_h[2]]
}

cat("Bandwidth sensitivity (outcome: change in secondary share):\n")
print(bw_results)

# ---------------------------------------------------------------
# 2. Polynomial order sensitivity
# ---------------------------------------------------------------

cat("\n=== Polynomial Order Sensitivity ===\n")

poly_results <- data.table(
  order = 1:3,
  coef = NA_real_,
  se_robust = NA_real_,
  p_value = NA_real_,
  bw = NA_real_
)

for (p_order in 1:3) {
  rdd_p <- rdrobust::rdrobust(
    y = rdd_data$delta_pct_secondary,
    x = rdd_data$running_var,
    c = 0, kernel = "triangular", p = p_order, bwselect = "mserd",
    masspoints = "adjust"
  )
  poly_results[p_order, coef := rdd_p$coef[1]]
  poly_results[p_order, se_robust := rdd_p$se[3]]
  poly_results[p_order, p_value := rdd_p$pv[3]]
  poly_results[p_order, bw := rdd_p$bws[1, 1]]
}

cat("Polynomial order sensitivity:\n")
print(poly_results)

# ---------------------------------------------------------------
# 3. Placebo cutoffs
# ---------------------------------------------------------------

cat("\n=== Placebo Cutoffs ===\n")

placebo_cutoffs <- c(10, 15, 25, 30)
placebo_results <- data.table(
  cutoff = placebo_cutoffs,
  coef = NA_real_,
  se_robust = NA_real_,
  p_value = NA_real_,
  n_eff = NA_integer_
)

for (i in seq_along(placebo_cutoffs)) {
  pc <- placebo_cutoffs[i]
  rv_placebo <- rdd_data$first_pct_secondary - pc

  tryCatch({
    rdd_pl <- rdrobust::rdrobust(
      y = rdd_data$delta_pct_secondary,
      x = rv_placebo,
      c = 0, kernel = "triangular", p = 1, bwselect = "mserd",
      masspoints = "adjust"
    )
    placebo_results[i, coef := rdd_pl$coef[1]]
    placebo_results[i, se_robust := rdd_pl$se[3]]
    placebo_results[i, p_value := rdd_pl$pv[3]]
    placebo_results[i, n_eff := rdd_pl$N_h[1] + rdd_pl$N_h[2]]
  }, error = function(e) {
    cat(sprintf("  Placebo %d%% failed: %s\n", pc, conditionMessage(e)))
  })
}

cat("Placebo cutoffs (expected: no significant effects):\n")
print(placebo_results)

# ---------------------------------------------------------------
# 4. Donut RDD (exclude ±1pp around threshold)
# ---------------------------------------------------------------

cat("\n=== Donut RDD ===\n")

donut_sizes <- c(0.5, 1.0, 2.0)
donut_results <- data.table(
  donut_pp = donut_sizes,
  coef = NA_real_,
  se_robust = NA_real_,
  p_value = NA_real_,
  n_eff = NA_integer_
)

for (i in seq_along(donut_sizes)) {
  d <- donut_sizes[i]
  donut_data <- rdd_data[abs(running_var) >= d]

  tryCatch({
    rdd_d <- rdrobust::rdrobust(
      y = donut_data$delta_pct_secondary,
      x = donut_data$running_var,
      c = 0, kernel = "triangular", p = 1, bwselect = "mserd",
      masspoints = "adjust"
    )
    donut_results[i, coef := rdd_d$coef[1]]
    donut_results[i, se_robust := rdd_d$se[3]]
    donut_results[i, p_value := rdd_d$pv[3]]
    donut_results[i, n_eff := rdd_d$N_h[1] + rdd_d$N_h[2]]
  }, error = function(e) {
    cat(sprintf("  Donut ±%.1fpp failed: %s\n", d, conditionMessage(e)))
  })
}

cat("Donut RDD results:\n")
print(donut_results)

# ---------------------------------------------------------------
# 5. Kernel sensitivity
# ---------------------------------------------------------------

cat("\n=== Kernel Sensitivity ===\n")

kernels <- c("triangular", "epanechnikov", "uniform")
kernel_results <- data.table(
  kernel = kernels,
  coef = NA_real_,
  se_robust = NA_real_,
  p_value = NA_real_
)

for (i in seq_along(kernels)) {
  rdd_k <- rdrobust::rdrobust(
    y = rdd_data$delta_pct_secondary,
    x = rdd_data$running_var,
    c = 0, kernel = kernels[i], p = 1, bwselect = "mserd",
    masspoints = "adjust"
  )
  kernel_results[i, coef := rdd_k$coef[1]]
  kernel_results[i, se_robust := rdd_k$se[3]]
  kernel_results[i, p_value := rdd_k$pv[3]]
}

cat("Kernel sensitivity:\n")
print(kernel_results)

# ---------------------------------------------------------------
# 6. Panel RDD: Wave-specific estimates
# ---------------------------------------------------------------

cat("\n=== Panel RDD: Wave-by-Wave Effects ===\n")

# Load full panel
analysis <- readRDS(file.path(data_dir, "analysis_panel.rds"))

# For each wave, compute change from baseline
waves <- sort(unique(analysis$wave))
wave_results <- data.table(
  wave = character(),
  wave_date = as.Date(character()),
  coef = numeric(),
  se_robust = numeric(),
  p_value = numeric(),
  n_eff = integer()
)

for (w in waves) {
  wave_data <- analysis[wave == w, .(
    mun_id, delta_pct_secondary, running_var, treated
  )]
  wave_data <- wave_data[!is.na(delta_pct_secondary) & !is.na(running_var)]

  if (nrow(wave_data) < 50) next

  tryCatch({
    rdd_w <- rdrobust::rdrobust(
      y = wave_data$delta_pct_secondary,
      x = wave_data$running_var,
      c = 0, kernel = "triangular", p = 1, bwselect = "mserd",
      masspoints = "adjust"
    )
    wave_results <- rbind(wave_results, data.table(
      wave = w,
      wave_date = analysis[wave == w]$wave_date[1],
      coef = rdd_w$coef[1],
      se_robust = rdd_w$se[3],
      p_value = rdd_w$pv[3],
      n_eff = rdd_w$N_h[1] + rdd_w$N_h[2]
    ))
  }, error = function(e) {
    cat(sprintf("  Wave %s failed: %s\n", w, conditionMessage(e)))
  })
}

cat("Wave-specific RDD estimates:\n")
print(wave_results)

# ---------------------------------------------------------------
# 7. Dwelling growth bandwidth sensitivity
# ---------------------------------------------------------------

cat("\n=== Dwelling Growth Bandwidth Sensitivity ===\n")

growth_bw_results <- data.table(
  multiplier = bw_multipliers,
  coef = NA_real_,
  se_robust = NA_real_,
  p_value = NA_real_
)

rdd_growth_main <- rdrobust::rdrobust(
  y = rdd_data$pct_growth_dwellings,
  x = rdd_data$running_var,
  c = 0, kernel = "triangular", p = 1, bwselect = "mserd",
  masspoints = "adjust"
)
h_opt_growth <- rdd_growth_main$bws[1, 1]

for (i in seq_along(bw_multipliers)) {
  bw_i <- bw_multipliers[i] * h_opt_growth
  rdd_g <- rdrobust::rdrobust(
    y = rdd_data$pct_growth_dwellings,
    x = rdd_data$running_var,
    c = 0, kernel = "triangular", p = 1,
    h = bw_i, masspoints = "adjust"
  )
  growth_bw_results[i, coef := rdd_g$coef[1]]
  growth_bw_results[i, se_robust := rdd_g$se[3]]
  growth_bw_results[i, p_value := rdd_g$pv[3]]
}

cat("Dwelling growth bandwidth sensitivity:\n")
print(growth_bw_results)

# ---------------------------------------------------------------
# Save all robustness results
# ---------------------------------------------------------------

robustness <- list(
  bw_sensitivity = bw_results,
  poly_sensitivity = poly_results,
  placebo_cutoffs = placebo_results,
  donut = donut_results,
  kernel = kernel_results,
  wave_specific = wave_results,
  growth_bw = growth_bw_results
)

saveRDS(robustness, file.path(data_dir, "robustness_results.rds"))
cat("\n=== Robustness checks complete ===\n")
