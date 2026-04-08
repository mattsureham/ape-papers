# 04_robustness.R — Robustness checks for PHMSA pipeline RDD
source("00_packages.R")

analysis <- readRDS("../data/analysis.rds")

cat("=== ROBUSTNESS CHECKS ===\n\n")

# -------------------------------------------------------
# 1. Bandwidth sensitivity
# -------------------------------------------------------
cat("--- Bandwidth Sensitivity ---\n")

# Get CCT-optimal bandwidth first
rd_opt <- rdrobust(
  y = analysis$future_incidents,
  x = analysis$norm_cost_centered,
  c = 0, kernel = "triangular", bwselect = "mserd",
  cluster = analysis$operator_id
)
h_opt <- rd_opt$bws[1, 1]

bw_fracs <- c(0.5, 0.75, 1.0, 1.25, 1.5)
bw_results <- list()

for (frac in bw_fracs) {
  h <- h_opt * frac
  rd <- rdrobust(
    y = analysis$future_incidents,
    x = analysis$norm_cost_centered,
    c = 0, h = h, kernel = "triangular",
    cluster = analysis$operator_id
  )
  bw_results[[as.character(frac)]] <- data.table(
    frac = frac,
    bandwidth = h,
    coef = rd$coef[1],
    se = rd$se[3],
    ci_low = rd$ci[3, 1],
    ci_high = rd$ci[3, 2],
    n_left = rd$N_h[1],
    n_right = rd$N_h[2]
  )
  cat(sprintf("  h=%.3f (%.0f%% CCT): beta=%.3f (%.3f), N=%d+%d\n",
    h, frac * 100, rd$coef[1], rd$se[3], rd$N_h[1], rd$N_h[2]))
}
bw_tab <- rbindlist(bw_results)

# -------------------------------------------------------
# 2. Placebo thresholds
# -------------------------------------------------------
cat("\n--- Placebo Thresholds ---\n")

placebo_cuts <- c(-0.3, -0.15, 0.15, 0.3)  # Offsets from true cutoff
placebo_results <- list()

for (pc in placebo_cuts) {
  rd <- tryCatch({
    rdrobust(
      y = analysis$future_incidents,
      x = analysis$norm_cost_centered,
      c = pc, kernel = "triangular", bwselect = "mserd",
      cluster = analysis$operator_id
    )
  }, error = function(e) NULL)

  if (!is.null(rd)) {
    placebo_results[[as.character(pc)]] <- data.table(
      cutoff = pc + 1,
      coef = rd$coef[1],
      se = rd$se[3],
      p_value = 2 * pnorm(-abs(rd$coef[1] / rd$se[3]))
    )
    cat(sprintf("  Placebo at %.2f: beta=%.3f (%.3f), p=%.3f\n",
      pc + 1, rd$coef[1], rd$se[3], 2 * pnorm(-abs(rd$coef[1] / rd$se[3]))))
  }
}
placebo_tab <- rbindlist(placebo_results)

# -------------------------------------------------------
# 3. Donut-hole RDD
# -------------------------------------------------------
cat("\n--- Donut-Hole RDD ---\n")

donut_sizes <- c(0.02, 0.05, 0.10)
donut_results <- list()

for (ds in donut_sizes) {
  sub <- analysis[abs(norm_cost_centered) > ds]
  if (nrow(sub) > 50) {
    rd <- tryCatch({
      rdrobust(
        y = sub$future_incidents,
        x = sub$norm_cost_centered,
        c = 0, kernel = "triangular", bwselect = "mserd",
        cluster = sub$operator_id
      )
    }, error = function(e) NULL)

    if (!is.null(rd)) {
      donut_results[[as.character(ds)]] <- data.table(
        donut = ds,
        coef = rd$coef[1],
        se = rd$se[3],
        n = rd$N_h[1] + rd$N_h[2]
      )
      cat(sprintf("  Donut ±%.0f%%: beta=%.3f (%.3f), N=%d\n",
        ds * 100, rd$coef[1], rd$se[3], rd$N_h[1] + rd$N_h[2]))
    }
  }
}
donut_tab <- rbindlist(donut_results)

# -------------------------------------------------------
# 4. Alternative kernels
# -------------------------------------------------------
cat("\n--- Alternative Kernels ---\n")

for (kern in c("triangular", "epanechnikov", "uniform")) {
  rd <- rdrobust(
    y = analysis$future_incidents,
    x = analysis$norm_cost_centered,
    c = 0, kernel = kern, bwselect = "mserd",
    cluster = analysis$operator_id
  )
  cat(sprintf("  %s: beta=%.3f (%.3f)\n", kern, rd$coef[1], rd$se[3]))
}

# -------------------------------------------------------
# 5. Alternative outcomes
# -------------------------------------------------------
cat("\n--- Alternative Outcomes ---\n")

# Future cost
rd_cost <- rdrobust(
  y = log1p(analysis$future_cost),
  x = analysis$norm_cost_centered,
  c = 0, kernel = "triangular", bwselect = "mserd",
  cluster = analysis$operator_id
)
cat(sprintf("  Log future cost: beta=%.3f (%.3f)\n", rd_cost$coef[1], rd_cost$se[3]))

# Binary: any future incident
analysis[, any_future := as.integer(future_incidents > 0)]
rd_any <- rdrobust(
  y = analysis$any_future,
  x = analysis$norm_cost_centered,
  c = 0, kernel = "triangular", bwselect = "mserd",
  cluster = analysis$operator_id
)
cat(sprintf("  Any future incident: beta=%.3f (%.3f)\n", rd_any$coef[1], rd_any$se[3]))

# Save robustness results
rob_results <- list(
  bandwidth_sensitivity = bw_tab,
  placebo = placebo_tab,
  donut = donut_tab
)
saveRDS(rob_results, "../data/robustness_results.rds")

cat("\nRobustness results saved.\n")
