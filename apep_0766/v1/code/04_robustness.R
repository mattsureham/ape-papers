## 04_robustness.R — Robustness checks for multi-cutoff RDD
## apep_0766: Council size thresholds and infant mortality in Brazil

source("00_packages.R")
set.seed(20260322)

data_dir <- "../data/"
tables_dir <- "../tables/"

# ============================================================
# 1. LOAD MAIN RESULTS
# ============================================================
cat("=== Loading main results ===\n")
res <- readRDS(file.path(data_dir, "main_results.rds"))
main <- res$main
cutoffs <- res$cutoffs
pooled_bw <- res$diagnostics$pooled_bandwidth

# Create cutoff dummies for pooled specs
cutoff_dummies <- model.matrix(~ factor(nearest_cutoff) - 1, data = main)
cutoff_covs <- cutoff_dummies[, -1, drop = FALSE]

# ============================================================
# 2. BANDWIDTH SENSITIVITY
# ============================================================
cat("\n=== Bandwidth sensitivity ===\n")

bw_multipliers <- c(0.5, 0.75, 1.0, 1.25, 1.5, 2.0)
bw_results <- list()

for (mult in bw_multipliers) {
  bw <- pooled_bw * mult
  cat(sprintf("  BW = %.0f (%.0fx optimal)... ", bw, mult))

  rdd_bw <- tryCatch(
    rdrobust(
      y = main$imr,
      x = main$run_var,
      c = 0,
      covs = cutoff_covs,
      h = bw,
      kernel = "triangular",
      cluster = main$muni_code6,
      all = TRUE
    ),
    error = function(e) NULL
  )

  if (!is.null(rdd_bw)) {
    bw_results[[as.character(mult)]] <- data.table(
      multiplier = mult,
      bandwidth = bw,
      coef = rdd_bw$coef[1],
      se_robust = rdd_bw$se[3],
      ci_lower = rdd_bw$ci[3, 1],
      ci_upper = rdd_bw$ci[3, 2],
      n_eff = rdd_bw$N_h[1] + rdd_bw$N_h[2]
    )
    cat(sprintf("coef=%.3f (SE=%.3f)\n", rdd_bw$coef[1], rdd_bw$se[3]))
  }
}

bw_dt <- rbindlist(bw_results)
print(bw_dt)

# ============================================================
# 3. DONUT RDD (exclude observations very close to cutoff)
# ============================================================
cat("\n=== Donut RDD ===\n")

donut_gaps <- c(500, 1000, 2000)
donut_results <- list()

for (gap in donut_gaps) {
  cat(sprintf("  Donut ±%d... ", gap))
  donut_data <- main[abs(run_var) >= gap]
  donut_covs <- model.matrix(~ factor(nearest_cutoff) - 1, data = donut_data)[, -1, drop = FALSE]

  rdd_donut <- tryCatch(
    rdrobust(
      y = donut_data$imr,
      x = donut_data$run_var,
      c = 0,
      covs = donut_covs,
      kernel = "triangular",
      bwselect = "mserd",
      cluster = donut_data$muni_code6,
      all = TRUE
    ),
    error = function(e) NULL
  )

  if (!is.null(rdd_donut)) {
    donut_results[[as.character(gap)]] <- data.table(
      donut = gap,
      coef = rdd_donut$coef[1],
      se_robust = rdd_donut$se[3],
      n_eff = rdd_donut$N_h[1] + rdd_donut$N_h[2]
    )
    cat(sprintf("coef=%.3f (SE=%.3f)\n", rdd_donut$coef[1], rdd_donut$se[3]))
  }
}

donut_dt <- rbindlist(donut_results)

# ============================================================
# 4. PLACEBO CUTOFFS
# ============================================================
cat("\n=== Placebo cutoffs ===\n")

# Test at population values where there is NO threshold change
placebo_cuts <- c(10000, 20000, 40000, 65000, 100000)
placebo_results <- list()

panel_full <- fread(file.path(data_dir, "analysis_panel.csv"))

for (pc in placebo_cuts) {
  cat(sprintf("  Placebo at %s... ", format(pc, big.mark = ",")))

  # Restrict to municipalities near this placebo cutoff
  sub <- panel_full[abs(population - pc) < 20000]
  sub[, placebo_run := population - pc]

  if (nrow(sub) < 200) {
    cat("Too few obs\n")
    next
  }

  rdd_placebo <- tryCatch(
    rdrobust(
      y = sub$imr,
      x = sub$placebo_run,
      c = 0,
      kernel = "triangular",
      bwselect = "mserd",
      cluster = sub$muni_code6,
      all = TRUE
    ),
    error = function(e) NULL
  )

  if (!is.null(rdd_placebo)) {
    placebo_results[[as.character(pc)]] <- data.table(
      placebo_cutoff = pc,
      coef = rdd_placebo$coef[1],
      se_robust = rdd_placebo$se[3],
      p_value = rdd_placebo$pv[3]
    )
    cat(sprintf("coef=%.3f (p=%.3f)\n", rdd_placebo$coef[1], rdd_placebo$pv[3]))
  }
}

placebo_dt <- rbindlist(placebo_results)

# ============================================================
# 5. ALTERNATIVE POLYNOMIAL ORDER
# ============================================================
cat("\n=== Alternative polynomial orders ===\n")

poly_results <- list()
for (p_order in c(1, 2)) {
  cat(sprintf("  Polynomial order %d... ", p_order))

  rdd_poly <- tryCatch(
    rdrobust(
      y = main$imr,
      x = main$run_var,
      c = 0,
      covs = cutoff_covs,
      p = p_order,
      kernel = "triangular",
      bwselect = "mserd",
      cluster = main$muni_code6,
      all = TRUE
    ),
    error = function(e) NULL
  )

  if (!is.null(rdd_poly)) {
    poly_results[[as.character(p_order)]] <- data.table(
      poly_order = p_order,
      coef = rdd_poly$coef[1],
      se_robust = rdd_poly$se[3]
    )
    cat(sprintf("coef=%.3f (SE=%.3f)\n", rdd_poly$coef[1], rdd_poly$se[3]))
  }
}

poly_dt <- rbindlist(poly_results)

# ============================================================
# 6. ROBUSTNESS TABLE (Table 3)
# ============================================================
cat("\n=== Generating Table 3: Robustness ===\n")

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  "Specification & Estimate & Robust SE & Eff.\\ $N$ & Notes \\\\\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Bandwidth sensitivity}} \\\\\n"
)

for (i in seq_len(nrow(bw_dt))) {
  r <- bw_dt[i]
  z <- abs(r$coef / r$se_robust)
  stars <- ifelse(z > 2.576, "***", ifelse(z > 1.96, "**", ifelse(z > 1.645, "*", "")))
  tab3_tex <- paste0(tab3_tex, sprintf(
    "\\quad %.0f\\%% of optimal & %.3f%s & (%.3f) & %s & $h = %s$ \\\\\n",
    r$multiplier * 100, r$coef, stars, r$se_robust,
    format(r$n_eff, big.mark = ","),
    format(round(r$bandwidth), big.mark = ",")
  ))
}

tab3_tex <- paste0(tab3_tex, "\\midrule\n",
                   "\\multicolumn{5}{l}{\\textit{Panel B: Donut RDD}} \\\\\n")

for (i in seq_len(nrow(donut_dt))) {
  r <- donut_dt[i]
  z <- abs(r$coef / r$se_robust)
  stars <- ifelse(z > 2.576, "***", ifelse(z > 1.96, "**", ifelse(z > 1.645, "*", "")))
  tab3_tex <- paste0(tab3_tex, sprintf(
    "\\quad Exclude $\\pm$%s & %.3f%s & (%.3f) & %s & \\\\\n",
    format(r$donut, big.mark = ","), r$coef, stars, r$se_robust,
    format(r$n_eff, big.mark = ",")
  ))
}

tab3_tex <- paste0(tab3_tex, "\\midrule\n",
                   "\\multicolumn{5}{l}{\\textit{Panel C: Polynomial order}} \\\\\n")

for (i in seq_len(nrow(poly_dt))) {
  r <- poly_dt[i]
  z <- abs(r$coef / r$se_robust)
  stars <- ifelse(z > 2.576, "***", ifelse(z > 1.96, "**", ifelse(z > 1.645, "*", "")))
  tab3_tex <- paste0(tab3_tex, sprintf(
    "\\quad Order %d & %.3f%s & (%.3f) & & \\\\\n",
    r$poly_order, r$coef, stars, r$se_robust
  ))
}

tab3_tex <- paste0(tab3_tex, "\\midrule\n",
                   "\\multicolumn{5}{l}{\\textit{Panel D: Placebo cutoffs}} \\\\\n")

for (i in seq_len(nrow(placebo_dt))) {
  r <- placebo_dt[i]
  z <- abs(r$coef / r$se_robust)
  stars <- ifelse(z > 2.576, "***", ifelse(z > 1.96, "**", ifelse(z > 1.645, "*", "")))
  tab3_tex <- paste0(tab3_tex, sprintf(
    "\\quad Pop.~= %s & %.3f%s & (%.3f) & & $p = %.3f$ \\\\\n",
    format(r$placebo_cutoff, big.mark = ","), r$coef, stars, r$se_robust, r$p_value
  ))
}

tab3_tex <- paste0(
  tab3_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Panel A varies the bandwidth around the CCT (2014) optimal. ",
  "Panel B implements donut RDD, excluding municipalities within the specified distance ",
  "of each threshold. Panel C varies the local polynomial order. ",
  "Panel D tests for discontinuities at population values where the Constitution ",
  "does not mandate a change in council size. ",
  "All specifications cluster standard errors at the municipality level. ",
  "*** $p<0.01$, ** $p<0.05$, * $p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, file.path(tables_dir, "tab3_robustness.tex"))
cat("Table 3 saved.\n")

# Save robustness results
saveRDS(list(
  bw_dt = bw_dt,
  donut_dt = donut_dt,
  placebo_dt = placebo_dt,
  poly_dt = poly_dt
), file.path(data_dir, "robustness_results.rds"))

cat("\n=== Robustness checks complete ===\n")
