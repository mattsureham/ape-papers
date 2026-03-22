## 04_robustness.R — Robustness checks for spatial RDD
## APEP-0746

source("00_packages.R")

data_dir <- "../data"

cat("Loading analysis dataset...\n")
dt <- fread(file.path(data_dir, "analysis_data.csv.gz"))
cat(sprintf("N = %d\n", nrow(dt)))

## ===================================================================
## 1. Bandwidth sensitivity (rdrobust with fixed bandwidths)
## ===================================================================

cat("\n=== Bandwidth Sensitivity ===\n")

bw_results <- data.table()
for (bw in c(100, 200, 300, 400, 500, 750, 1000)) {
  dt_bw <- dt[dist_m <= bw]
  if (nrow(dt_bw) < 200) {
    cat(sprintf("BW=%dm: too few obs (%d), skipping\n", bw, nrow(dt_bw)))
    next
  }

  rdd <- tryCatch(
    rdrobust(y = dt_bw$log_price, x = dt_bw$signed_dist_m, c = 0,
             kernel = "triangular", bwselect = "mserd"),
    error = function(e) NULL
  )

  if (!is.null(rdd)) {
    bw_results <- rbind(bw_results, data.table(
      bandwidth = bw,
      n_eff = rdd$N_h[1] + rdd$N_h[2],
      tau_bc = rdd$coef[3],
      se_robust = rdd$se[3],
      p_value = rdd$pv[3],
      ci_lower = rdd$ci[3, 1],
      ci_upper = rdd$ci[3, 2]
    ))
    cat(sprintf("BW=%dm: tau=%.4f (SE=%.4f), p=%.3f, N_eff=%d\n",
                bw, rdd$coef[3], rdd$se[3], rdd$pv[3],
                rdd$N_h[1] + rdd$N_h[2]))
  }
}

fwrite(bw_results, file.path(data_dir, "robustness_bandwidth.csv"))

## ===================================================================
## 2. Donut hole test (exclude 50m near boundary)
## ===================================================================

cat("\n=== Donut Hole Test (exclude <50m) ===\n")

dt_donut <- dt[dist_m >= 50 & dist_m <= 500]
if (nrow(dt_donut) >= 200) {
  rdd_donut <- rdrobust(y = dt_donut$log_price, x = dt_donut$signed_dist_m,
                         c = 0, kernel = "triangular", bwselect = "mserd")
  cat(sprintf("Donut [50-500m]: tau=%.4f (SE=%.4f), p=%.3f\n",
              rdd_donut$coef[3], rdd_donut$se[3], rdd_donut$pv[3]))
}

## ===================================================================
## 3. Polynomial order sensitivity
## ===================================================================

cat("\n=== Polynomial Order ===\n")

for (p in 1:2) {
  rdd_p <- tryCatch(
    rdrobust(y = dt$log_price, x = dt$signed_dist_m, c = 0,
             p = p, kernel = "triangular", bwselect = "mserd"),
    error = function(e) NULL
  )
  if (!is.null(rdd_p)) {
    cat(sprintf("p=%d: tau=%.4f (SE=%.4f), BW=%.0fm\n",
                p, rdd_p$coef[3], rdd_p$se[3], rdd_p$bws[1,1]))
  }
}

## ===================================================================
## 4. Property type heterogeneity
## ===================================================================

cat("\n=== Property Type Heterogeneity ===\n")

for (prop_type in c("Appartement", "Maison")) {
  dt_type <- dt[type_local == prop_type]
  if (nrow(dt_type) < 500) next

  rdd_type <- tryCatch(
    rdrobust(y = dt_type$log_price, x = dt_type$signed_dist_m,
             c = 0, kernel = "triangular", bwselect = "mserd"),
    error = function(e) NULL
  )
  if (!is.null(rdd_type)) {
    cat(sprintf("%s: tau=%.4f (SE=%.4f), p=%.3f, N=%d\n",
                prop_type, rdd_type$coef[3], rdd_type$se[3],
                rdd_type$pv[3], rdd_type$N_h[1] + rdd_type$N_h[2]))
  }
}

## ===================================================================
## 5. Placebo cutoffs (fake boundaries at ±200m, ±400m)
## ===================================================================

cat("\n=== Placebo Cutoffs ===\n")

for (placebo_c in c(-400, -200, 200, 400)) {
  rdd_placebo <- tryCatch(
    rdrobust(y = dt$log_price, x = dt$signed_dist_m, c = placebo_c,
             kernel = "triangular", bwselect = "mserd"),
    error = function(e) NULL
  )
  if (!is.null(rdd_placebo)) {
    cat(sprintf("Placebo at %+dm: tau=%.4f (SE=%.4f), p=%.3f\n",
                placebo_c, rdd_placebo$coef[3], rdd_placebo$se[3], rdd_placebo$pv[3]))
  }
}

## ===================================================================
## 6. Alternative kernel
## ===================================================================

cat("\n=== Alternative Kernel (Uniform) ===\n")

rdd_uniform <- tryCatch(
  rdrobust(y = dt$log_price, x = dt$signed_dist_m, c = 0,
           kernel = "uniform", bwselect = "mserd"),
  error = function(e) NULL
)
if (!is.null(rdd_uniform)) {
  cat(sprintf("Uniform kernel: tau=%.4f (SE=%.4f), BW=%.0fm\n",
              rdd_uniform$coef[3], rdd_uniform$se[3], rdd_uniform$bws[1,1]))
}

cat("\n=== Robustness checks complete ===\n")
