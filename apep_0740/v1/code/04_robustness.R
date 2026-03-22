## 04_robustness.R — Robustness checks and placebos
## APEP-0740: QPV Designation Paradox

source("00_packages.R")
script_dir <- tryCatch(dirname(sys.frame(1)$ofile), error = function(e) ".")
setwd(file.path(script_dir, ".."))
data_dir <- "data"

cat("=== Loading data ===\n")
df <- data.table::fread(file.path(data_dir, "analysis_data.csv"))
results <- readRDS(file.path(data_dir, "rdd_results.rds"))

post <- df  ## All data is post-QPV (2020-2024)

## ---- 1. Temporal placebo: 2020 (earliest year) vs 2024 (latest) ----
cat("\n=== Temporal Placebo: Earliest Year (2020) ===\n")
## If QPV designation matters, effect should be similar across all post-treatment years
early <- df[year == 2020]
cat(sprintf("Year 2020 observations: %s\n", format(nrow(early), big.mark = ",")))

if (nrow(early) > 200) {
  rdd_early <- tryCatch(
    rdrobust::rdrobust(
      y = early$log_price_m2,
      x = early$signed_dist,
      c = 0,
      kernel = "triangular",
      bwselect = "mserd",
      cluster = early$commune
    ),
    error = function(e) {
      cat(sprintf("  Early-year RDD failed: %s\n", e$message))
      NULL
    }
  )
  if (!is.null(rdd_early)) {
    cat(sprintf("2020 estimate: tau=%.4f (robust SE=%.4f), p=%.3f\n",
                rdd_early$coef[2], rdd_early$se[3], rdd_early$pv[3]))
    results$temporal_2020 <- list(
      tau_bc = rdd_early$coef[2],
      se_robust = rdd_early$se[3],
      pval = rdd_early$pv[3],
      bw = rdd_early$bws[1, 1],
      n_left = rdd_early$N[1],
      n_right = rdd_early$N[2]
    )
  }
}

## ---- 2. Placebo cutoffs ----
cat("\n=== Placebo Cutoffs ===\n")

placebo_cutoffs <- c(-500, -250, 250, 500)
placebo_results <- list()

for (pc in placebo_cutoffs) {
  tryCatch({
    rdd_pc <- rdrobust::rdrobust(
      y = post$log_price_m2,
      x = post$signed_dist,
      c = pc,
      kernel = "triangular",
      bwselect = "mserd",
      cluster = post$commune
    )
    placebo_results[[as.character(pc)]] <- list(
      cutoff = pc,
      tau_bc = rdd_pc$coef[2],
      se_robust = rdd_pc$se[3],
      pval = rdd_pc$pv[3]
    )
    cat(sprintf("  Cutoff=%+dm: tau=%.4f (p=%.3f)\n", pc, rdd_pc$coef[2], rdd_pc$pv[3]))
  }, error = function(e) {
    cat(sprintf("  Cutoff=%+dm: FAILED\n", pc))
  })
}
results$placebo_cutoffs <- placebo_results

## ---- 3. Donut hole (exclude 50m around boundary) ----
cat("\n=== Donut Hole (exclude 50m) ===\n")

donut <- post[abs(signed_dist) >= 50]
rdd_donut <- tryCatch(
  rdrobust::rdrobust(
    y = donut$log_price_m2,
    x = donut$signed_dist,
    c = 0,
    kernel = "triangular",
    bwselect = "mserd",
    cluster = donut$commune
  ),
  error = function(e) { cat(sprintf("Donut RDD failed: %s\n", e$message)); NULL }
)
if (!is.null(rdd_donut)) {
  cat(sprintf("Donut (50m): tau=%.4f (robust SE=%.4f)\n",
              rdd_donut$coef[2], rdd_donut$se[3]))
  results$donut <- list(
    tau_bc = rdd_donut$coef[2],
    se_robust = rdd_donut$se[3],
    bw = rdd_donut$bws[1, 1]
  )
}

## ---- 4. By property type ----
cat("\n=== Heterogeneity by Property Type ===\n")

for (ptype in c("Appartement", "Maison")) {
  sub <- post[type == ptype]
  if (nrow(sub) < 200) {
    cat(sprintf("  %s: too few observations (%d)\n", ptype, nrow(sub)))
    next
  }
  rdd_type <- tryCatch(
    rdrobust::rdrobust(
      y = sub$log_price_m2,
      x = sub$signed_dist,
      c = 0,
      kernel = "triangular",
      bwselect = "mserd",
      cluster = sub$commune
    ),
    error = function(e) { cat(sprintf("  %s: FAILED\n", ptype)); NULL }
  )
  if (!is.null(rdd_type)) {
    cat(sprintf("  %s: tau=%.4f (robust SE=%.4f), N=%d+%d\n",
                ptype, rdd_type$coef[2], rdd_type$se[3],
                rdd_type$N[1], rdd_type$N[2]))
    results[[paste0("type_", tolower(ptype))]] <- list(
      tau_bc = rdd_type$coef[2],
      se_robust = rdd_type$se[3],
      n_left = rdd_type$N[1],
      n_right = rdd_type$N[2]
    )
  }
}

## ---- 5. By period (early vs late) ----
cat("\n=== Heterogeneity by Period ===\n")

for (period in list(c(2020, 2021), c(2022, 2024))) {
  sub <- post[year >= period[1] & year <= period[2]]
  label <- sprintf("%d-%d", period[1], period[2])
  if (nrow(sub) < 200) next
  rdd_per <- tryCatch(
    rdrobust::rdrobust(
      y = sub$log_price_m2,
      x = sub$signed_dist,
      c = 0,
      kernel = "triangular",
      bwselect = "mserd",
      cluster = sub$commune
    ),
    error = function(e) NULL
  )
  if (!is.null(rdd_per)) {
    cat(sprintf("  %s: tau=%.4f (robust SE=%.4f)\n",
                label, rdd_per$coef[2], rdd_per$se[3]))
    results[[paste0("period_", gsub("-", "_", label))]] <- list(
      tau_bc = rdd_per$coef[2],
      se_robust = rdd_per$se[3]
    )
  }
}

## ---- 6. Polynomial order sensitivity ----
cat("\n=== Polynomial Order Sensitivity ===\n")

for (p_order in c(1, 2)) {
  rdd_poly <- tryCatch(
    rdrobust::rdrobust(
      y = post$log_price_m2,
      x = post$signed_dist,
      c = 0,
      p = p_order,
      kernel = "triangular",
      bwselect = "mserd",
      cluster = post$commune
    ),
    error = function(e) NULL
  )
  if (!is.null(rdd_poly)) {
    cat(sprintf("  p=%d: tau=%.4f (robust SE=%.4f), BW=%.0fm\n",
                p_order, rdd_poly$coef[2], rdd_poly$se[3], rdd_poly$bws[1, 1]))
    results[[paste0("poly_", p_order)]] <- list(
      tau_bc = rdd_poly$coef[2],
      se_robust = rdd_poly$se[3],
      bw = rdd_poly$bws[1, 1]
    )
  }
}

## Save all results
saveRDS(results, file.path(data_dir, "rdd_results.rds"))
cat("\n=== Robustness checks complete ===\n")
