# 04_robustness.R — Robustness checks for HACRP RDD
source("00_packages.R")

data_dir <- "../data"
analysis <- readRDS(file.path(data_dir, "analysis.rds"))
cutoff <- readRDS(file.path(data_dir, "cutoff.rds"))

cat("=== Robustness Checks ===\n\n")

# ============================================================
# 1. Bandwidth Sensitivity: Star Rating RDD
# ============================================================
cat("=== 1. Bandwidth Sensitivity (Star Rating) ===\n")

analysis[, stars := as.numeric(hospital_overall_rating)]

# Optimal bandwidth from main spec
main_rdd <- rdrobust(y = analysis$stars, x = analysis$score_centered, c = 0)
h_opt <- main_rdd$bws[1, 1]
cat("  Optimal bandwidth:", round(h_opt, 3), "\n")

# Test at 0.5×, 0.75×, 1.0×, 1.25×, 1.5×, 2.0× optimal
bw_mults <- c(0.5, 0.75, 1.0, 1.25, 1.5, 2.0)
bw_results <- data.table(
  multiplier = bw_mults,
  bandwidth = bw_mults * h_opt,
  coef = NA_real_,
  se_robust = NA_real_,
  pval_robust = NA_real_,
  n_eff = NA_integer_
)

for (j in seq_along(bw_mults)) {
  bw <- bw_mults[j] * h_opt
  rdd_j <- tryCatch({
    rdrobust(y = analysis$stars, x = analysis$score_centered, c = 0, h = bw)
  }, error = function(e) NULL)

  if (!is.null(rdd_j)) {
    bw_results[j, coef := rdd_j$coef[1]]
    bw_results[j, se_robust := rdd_j$se[3]]
    bw_results[j, pval_robust := rdd_j$pv[3]]
    bw_results[j, n_eff := sum(rdd_j$N_h)]
  }
}

cat("  Bandwidth sensitivity:\n")
print(bw_results[, .(multiplier, bandwidth = round(bandwidth, 3),
                      coef = round(coef, 3), se = round(se_robust, 3),
                      p = round(pval_robust, 3), n = n_eff)])

# ============================================================
# 2. Alternative Kernels
# ============================================================
cat("\n=== 2. Alternative Kernels ===\n")

for (kern in c("triangular", "epanechnikov", "uniform")) {
  rdd_k <- tryCatch({
    rdrobust(y = analysis$stars, x = analysis$score_centered, c = 0, kernel = kern)
  }, error = function(e) NULL)

  if (!is.null(rdd_k)) {
    cat(sprintf("  %s: coef=%.3f, robust p=%.3f\n",
                kern, rdd_k$coef[1], rdd_k$pv[3]))
  }
}

# ============================================================
# 3. Polynomial Order Sensitivity
# ============================================================
cat("\n=== 3. Polynomial Order ===\n")

for (p_ord in 1:3) {
  rdd_p <- tryCatch({
    rdrobust(y = analysis$stars, x = analysis$score_centered, c = 0, p = p_ord)
  }, error = function(e) NULL)

  if (!is.null(rdd_p)) {
    cat(sprintf("  Order %d: coef=%.3f, robust p=%.3f, bw=%.3f\n",
                p_ord, rdd_p$coef[1], rdd_p$pv[3], rdd_p$bws[1, 1]))
  }
}

# ============================================================
# 4. Donut Hole RDD (exclude hospitals closest to cutoff)
# ============================================================
cat("\n=== 4. Donut Hole RDD ===\n")

for (donut in c(0.01, 0.02, 0.05)) {
  donut_sample <- analysis[abs(score_centered) > donut]
  rdd_d <- tryCatch({
    rdrobust(y = donut_sample$stars, x = donut_sample$score_centered, c = 0)
  }, error = function(e) NULL)

  if (!is.null(rdd_d)) {
    cat(sprintf("  Donut %.2f: coef=%.3f, robust p=%.3f, n=%d\n",
                donut, rdd_d$coef[1], rdd_d$pv[3], nrow(donut_sample)))
  }
}

# ============================================================
# 5. Placebo Cutoffs
# ============================================================
cat("\n=== 5. Placebo Cutoffs ===\n")

# Test at 25th, 50th, and 90th percentiles (should find nothing)
for (pct in c(0.25, 0.50, 0.90)) {
  placebo_cutoff <- quantile(analysis$total_hac_score, pct, na.rm = TRUE)
  analysis[, score_placebo := total_hac_score - placebo_cutoff]

  rdd_placebo <- tryCatch({
    rdrobust(y = analysis$stars, x = analysis$score_placebo, c = 0)
  }, error = function(e) NULL)

  if (!is.null(rdd_placebo)) {
    cat(sprintf("  Placebo at p%d (%.3f): coef=%.3f, robust p=%.3f\n",
                as.integer(100 * pct), placebo_cutoff,
                rdd_placebo$coef[1], rdd_placebo$pv[3]))
  }
}

# ============================================================
# 6. Heterogeneity: Ownership Type
# ============================================================
cat("\n=== 6. Heterogeneity by Ownership ===\n")

analysis[, is_nonprofit := as.integer(grepl("Voluntary|Non-Profit", hospital_ownership, ignore.case = TRUE))]
analysis[, is_forprofit := as.integer(grepl("Proprietary|For-Profit", hospital_ownership, ignore.case = TRUE))]

for (sub_label in c("Nonprofit", "For-Profit")) {
  sub_var <- ifelse(sub_label == "Nonprofit", "is_nonprofit", "is_forprofit")
  sub_data <- analysis[get(sub_var) == 1]
  cat(sprintf("\n  %s (n=%d):\n", sub_label, nrow(sub_data)))

  rdd_sub <- tryCatch({
    rdrobust(y = sub_data$stars, x = sub_data$score_centered, c = 0)
  }, error = function(e) {
    cat("    Failed:", e$message, "\n")
    NULL
  })

  if (!is.null(rdd_sub)) {
    cat(sprintf("    Stars: coef=%.3f, robust p=%.3f\n",
                rdd_sub$coef[1], rdd_sub$pv[3]))
  }
}

# ============================================================
# Save robustness results
# ============================================================
saveRDS(bw_results, file.path(data_dir, "bw_sensitivity.rds"))
saveRDS(analysis, file.path(data_dir, "analysis.rds"))

cat("\n=== Robustness checks complete ===\n")
