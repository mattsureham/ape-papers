## 04_robustness.R — Robustness checks for RDD
## apep_0796: Swiss Second Home Ban RDD

source("00_packages.R")

data_dir <- "../data"
rdd <- readRDS(file.path(data_dir, "rdd_cross_section.rds"))
results <- readRDS(file.path(data_dir, "rdd_results.rds"))

cat("=== Robustness Checks ===\n\n")

## ================================================================
## 1. Bandwidth Sensitivity
## ================================================================
cat("--- Bandwidth Sensitivity ---\n")

bw_opt <- results$main$bw
bw_grid <- c(bw_opt * 0.5, bw_opt * 0.75, bw_opt, bw_opt * 1.25, bw_opt * 1.5, 2, 3, 5)
bw_grid <- sort(unique(round(bw_grid, 2)))

bw_results <- data.frame(
  bandwidth = numeric(),
  coef = numeric(),
  se_robust = numeric(),
  pval = numeric(),
  n_eff = numeric(),
  stringsAsFactors = FALSE
)

for (bw in bw_grid) {
  rd_bw <- tryCatch(
    rdrobust::rdrobust(
      y = rdd$delta_primary,
      x = rdd$running_var,
      c = 0, kernel = "triangular", p = 1,
      h = bw
    ),
    error = function(e) NULL
  )

  if (!is.null(rd_bw)) {
    bw_results <- rbind(bw_results, data.frame(
      bandwidth = bw,
      coef = rd_bw$coef[1],
      se_robust = rd_bw$se[3],
      pval = rd_bw$pv[3],
      n_eff = rd_bw$N_h[1] + rd_bw$N_h[2],
      stringsAsFactors = FALSE
    ))
  }
}

cat("Bandwidth sensitivity:\n")
print(bw_results)

## ================================================================
## 2. Placebo Cutoffs (15%, 25%, 30%)
## ================================================================
cat("\n--- Placebo Cutoffs ---\n")

placebo_cutoffs <- c(15, 25, 30)

placebo_results <- data.frame(
  cutoff = numeric(),
  coef = numeric(),
  se_robust = numeric(),
  pval = numeric(),
  n_eff = numeric(),
  stringsAsFactors = FALSE
)

for (pc in placebo_cutoffs) {
  rv_placebo <- rdd$baseline_secondary_pct - pc

  rd_p <- tryCatch(
    rdrobust::rdrobust(
      y = rdd$delta_primary,
      x = rv_placebo,
      c = 0, kernel = "triangular", p = 1, bwselect = "mserd"
    ),
    error = function(e) NULL
  )

  if (!is.null(rd_p)) {
    placebo_results <- rbind(placebo_results, data.frame(
      cutoff = pc,
      coef = rd_p$coef[1],
      se_robust = rd_p$se[3],
      pval = rd_p$pv[3],
      n_eff = rd_p$N_h[1] + rd_p$N_h[2],
      stringsAsFactors = FALSE
    ))
    cat("  Cutoff", pc, "%: coef =", round(rd_p$coef[1], 3),
        ", p =", round(rd_p$pv[3], 3), "\n")
  }
}

## ================================================================
## 3. Donut Hole (exclude municipalities at exactly 20% +/- 0.5pp)
## ================================================================
cat("\n--- Donut Hole (exclude |running_var| < 0.5pp) ---\n")

rdd_donut <- rdd %>% filter(abs(running_var) >= 0.5)
cat("Excluded", nrow(rdd) - nrow(rdd_donut), "municipalities within donut\n")

rd_donut <- tryCatch(
  rdrobust::rdrobust(
    y = rdd_donut$delta_primary,
    x = rdd_donut$running_var,
    c = 0, kernel = "triangular", p = 1, bwselect = "mserd"
  ),
  error = function(e) NULL
)

if (!is.null(rd_donut)) {
  cat("Donut RDD: coef =", round(rd_donut$coef[1], 3),
      ", robust SE =", round(rd_donut$se[3], 3),
      ", p =", round(rd_donut$pv[3], 4), "\n")
}

## ================================================================
## 4. Polynomial Order: Local Quadratic
## ================================================================
cat("\n--- Local Quadratic ---\n")

rd_quad <- tryCatch(
  rdrobust::rdrobust(
    y = rdd$delta_primary,
    x = rdd$running_var,
    c = 0, kernel = "triangular", p = 2, bwselect = "mserd"
  ),
  error = function(e) NULL
)

if (!is.null(rd_quad)) {
  cat("Quadratic RDD: coef =", round(rd_quad$coef[1], 3),
      ", robust SE =", round(rd_quad$se[3], 3),
      ", p =", round(rd_quad$pv[3], 4), "\n")
}

## ================================================================
## 5. Alternative Kernel: Uniform
## ================================================================
cat("\n--- Uniform Kernel ---\n")

rd_uniform <- tryCatch(
  rdrobust::rdrobust(
    y = rdd$delta_primary,
    x = rdd$running_var,
    c = 0, kernel = "uniform", p = 1, bwselect = "mserd"
  ),
  error = function(e) NULL
)

if (!is.null(rd_uniform)) {
  cat("Uniform kernel: coef =", round(rd_uniform$coef[1], 3),
      ", robust SE =", round(rd_uniform$se[3], 3),
      ", p =", round(rd_uniform$pv[3], 4), "\n")
}

## ================================================================
## 6. Heterogeneity: Alpine vs Non-Alpine
## ================================================================
cat("\n--- Heterogeneity: Alpine vs Non-Alpine ---\n")

for (alp in c(1, 0)) {
  rdd_sub <- rdd %>% filter(alpine == alp)
  label <- ifelse(alp == 1, "Alpine", "Non-Alpine")

  rd_sub <- tryCatch(
    rdrobust::rdrobust(
      y = rdd_sub$delta_primary,
      x = rdd_sub$running_var,
      c = 0, kernel = "triangular", p = 1, bwselect = "mserd"
    ),
    error = function(e) NULL
  )

  if (!is.null(rd_sub)) {
    cat("  ", label, ": coef =", round(rd_sub$coef[1], 3),
        ", p =", round(rd_sub$pv[3], 3),
        ", N_eff =", rd_sub$N_h[1] + rd_sub$N_h[2], "\n")
  } else {
    cat("  ", label, ": insufficient observations for RDD\n")
  }
}

## ================================================================
## 7. Save robustness results
## ================================================================

robustness <- list(
  bandwidth_sensitivity = bw_results,
  placebo_cutoffs = placebo_results,
  donut = if (!is.null(rd_donut)) list(
    coef = rd_donut$coef[1], se = rd_donut$se[3], pval = rd_donut$pv[3]
  ) else NULL,
  quadratic = if (!is.null(rd_quad)) list(
    coef = rd_quad$coef[1], se = rd_quad$se[3], pval = rd_quad$pv[3]
  ) else NULL,
  uniform = if (!is.null(rd_uniform)) list(
    coef = rd_uniform$coef[1], se = rd_uniform$se[3], pval = rd_uniform$pv[3]
  ) else NULL
)

saveRDS(robustness, file.path(data_dir, "robustness_results.rds"))
cat("\nSaved robustness_results.rds\n")
