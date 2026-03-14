## 04_robustness.R — Bandwidth sensitivity, placebo cutoffs, donut-hole RDD
## apep_0686: UK Housing Delivery Test RDD

source("code/00_packages.R")

data_dir <- "data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
rdd_results <- readRDS(file.path(data_dir, "rdd_results.rds"))

main_bw <- rdd_results[["approval_rate_major_dwell"]]$bw

## ============================================================
## 1. Bandwidth Sensitivity
## ============================================================

cat("=== Bandwidth Sensitivity (Major Dwelling Approval Rate) ===\n")

bw_multipliers <- c(0.5, 0.75, 1.0, 1.25, 1.5, 2.0)
bw_results <- list()

y <- panel$approval_rate_major_dwell
x <- panel$running_var
valid <- !is.na(y) & !is.na(x)

for (mult in bw_multipliers) {
  bw_test <- main_bw * mult
  rd <- rdrobust::rdrobust(y[valid], x[valid], c = 0, h = bw_test, p = 1,
                            cluster = panel$la_code[valid])

  bw_results[[as.character(mult)]] <- list(
    multiplier = mult,
    bandwidth = bw_test,
    tau_bc = rd$coef[2],
    se_robust = rd$se[3],
    ci_lower = rd$ci[3, 1],
    ci_upper = rd$ci[3, 2],
    pval = rd$pv[3],
    n_eff = rd$N_h[1] + rd$N_h[2]
  )

  cat(sprintf("  BW=%.1f (%.0fx): tau=%.2f, SE=%.2f, p=%.3f, N=%d\n",
              bw_test, mult, rd$coef[2], rd$se[3], rd$pv[3],
              rd$N_h[1] + rd$N_h[2]))
}

## ============================================================
## 2. Placebo Cutoffs
## ============================================================

cat("\n=== Placebo Cutoffs ===\n")

placebo_cutoffs <- c(50, 60, 85, 95, 100, 110)
placebo_results <- list()

for (cutoff in placebo_cutoffs) {
  x_shifted <- panel$hdt_score - cutoff
  valid <- !is.na(y) & !is.na(x_shifted)

  rd_p <- tryCatch(
    rdrobust::rdrobust(y[valid], x_shifted[valid], c = 0, p = 1,
                        cluster = panel$la_code[valid]),
    error = function(e) NULL
  )

  if (!is.null(rd_p)) {
    placebo_results[[as.character(cutoff)]] <- list(
      cutoff = cutoff,
      tau_bc = rd_p$coef[2],
      se_robust = rd_p$se[3],
      pval = rd_p$pv[3],
      n_eff = rd_p$N_h[1] + rd_p$N_h[2]
    )
    cat(sprintf("  Cutoff=%d%%: tau=%.2f, SE=%.2f, p=%.3f, N=%d %s\n",
                cutoff, rd_p$coef[2], rd_p$se[3], rd_p$pv[3],
                rd_p$N_h[1] + rd_p$N_h[2],
                ifelse(rd_p$pv[3] < 0.1, "(!)", "")))
  } else {
    cat(sprintf("  Cutoff=%d%%: FAILED (insufficient data near cutoff)\n", cutoff))
  }
}

## ============================================================
## 3. Donut-Hole RDD
## ============================================================

cat("\n=== Donut-Hole RDD (Excluding Observations Within 1pp of Cutoff) ===\n")

panel_donut <- panel %>%
  filter(abs(running_var) > 1)

y_donut <- panel_donut$approval_rate_major_dwell
x_donut <- panel_donut$running_var
valid_d <- !is.na(y_donut) & !is.na(x_donut)

rd_donut <- rdrobust::rdrobust(y_donut[valid_d], x_donut[valid_d], c = 0, p = 1,
                                cluster = panel_donut$la_code[valid_d])

cat(sprintf("  Donut (±1pp excluded): tau=%.2f, SE=%.2f, p=%.3f, N=%d\n",
            rd_donut$coef[2], rd_donut$se[3], rd_donut$pv[3],
            rd_donut$N_h[1] + rd_donut$N_h[2]))

## ============================================================
## 4. Polynomial Order Sensitivity
## ============================================================

cat("\n=== Polynomial Order Sensitivity ===\n")

for (poly_order in c(1, 2)) {
  rd_poly <- rdrobust::rdrobust(y[valid], x[valid], c = 0, p = poly_order,
                                 cluster = panel$la_code[valid])
  cat(sprintf("  p=%d: tau=%.2f, SE=%.2f, p=%.3f\n",
              poly_order, rd_poly$coef[2], rd_poly$se[3], rd_poly$pv[3]))
}

## ============================================================
## 5. Year-by-Year Estimates
## ============================================================

cat("\n=== Year-by-Year RDD Estimates ===\n")

year_results <- list()

for (yr in sort(unique(panel$hdt_year))) {
  panel_yr <- panel %>% filter(hdt_year == yr)
  y_yr <- panel_yr$approval_rate_major_dwell
  x_yr <- panel_yr$running_var
  valid_yr <- !is.na(y_yr) & !is.na(x_yr)

  if (sum(valid_yr) < 30) {
    cat(sprintf("  %d: SKIPPED (N=%d)\n", yr, sum(valid_yr)))
    next
  }

  rd_yr <- tryCatch(
    rdrobust::rdrobust(y_yr[valid_yr], x_yr[valid_yr], c = 0, p = 1),
    error = function(e) NULL
  )

  if (!is.null(rd_yr)) {
    year_results[[as.character(yr)]] <- list(
      year = yr,
      tau_bc = rd_yr$coef[2],
      se_robust = rd_yr$se[3],
      pval = rd_yr$pv[3],
      n_eff = rd_yr$N_h[1] + rd_yr$N_h[2]
    )
    cat(sprintf("  %d: tau=%.2f, SE=%.2f, p=%.3f, N=%d\n",
                yr, rd_yr$coef[2], rd_yr$se[3], rd_yr$pv[3],
                rd_yr$N_h[1] + rd_yr$N_h[2]))
  }
}

## ============================================================
## 6. Save All Robustness Results
## ============================================================

robustness <- list(
  bandwidth = bw_results,
  placebo = placebo_results,
  donut = list(
    tau_bc = rd_donut$coef[2],
    se_robust = rd_donut$se[3],
    pval = rd_donut$pv[3],
    n_eff = rd_donut$N_h[1] + rd_donut$N_h[2]
  ),
  year_by_year = year_results
)
saveRDS(robustness, file.path(data_dir, "robustness_results.rds"))

cat("\nRobustness checks complete. Results saved.\n")
