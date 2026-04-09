# 04_robustness.R — Robustness checks for Ecuador pension RDD
source("00_packages.R")

df <- as.data.table(readRDS("../data/analysis_sample.rds"))

robustness <- list()

# ============================================================================
# 1. BANDWIDTH SENSITIVITY
# ============================================================================
cat("=== Bandwidth sensitivity (LFP, full sample) ===\n")
bandwidths <- c(4, 5, 6, 7, 8, 9, 10)
bw_results <- data.frame(bw = numeric(), coef = numeric(), se = numeric(),
                         pval = numeric(), n_eff = numeric())
for (h in bandwidths) {
  rd <- rdrobust(y = df$lfp, x = df$age_c, c = 0, h = h, p = 1, q = 2)
  bw_results <- rbind(bw_results, data.frame(
    bw = h, coef = rd$coef[1], se = rd$se[1],
    pval = rd$pv[1], n_eff = rd$N_h[1] + rd$N_h[2]
  ))
}
print(bw_results)
robustness$bandwidth <- bw_results

# ============================================================================
# 2. POLYNOMIAL ORDER SENSITIVITY
# ============================================================================
cat("\n=== Polynomial order sensitivity (LFP, full sample) ===\n")
for (p_order in 1:3) {
  rd <- rdrobust(y = df$lfp, x = df$age_c, c = 0, p = p_order)
  cat(sprintf("p=%d: coef=%.4f, se=%.4f, p=%.3f, bw=%.2f\n",
              p_order, rd$coef[1], rd$se[1], rd$pv[1], rd$bws[1,1]))
}

# ============================================================================
# 3. KERNEL SENSITIVITY
# ============================================================================
cat("\n=== Kernel sensitivity (LFP, full sample) ===\n")
for (kern in c("triangular", "uniform", "epanechnikov")) {
  rd <- rdrobust(y = df$lfp, x = df$age_c, c = 0, kernel = kern)
  cat(sprintf("%s: coef=%.4f, se=%.4f, p=%.3f\n",
              kern, rd$coef[1], rd$se[1], rd$pv[1]))
}

# ============================================================================
# 4. PLACEBO CUTOFFS
# ============================================================================
cat("\n=== Placebo cutoffs (LFP) ===\n")
placebo_cuts <- c(-7, -5, -3, 3, 5, 7)  # relative to age 65, avoid near-cutoff
placebo_results <- data.frame(cutoff_age = numeric(), coef = numeric(),
                               se = numeric(), pval = numeric())
for (pc in placebo_cuts) {
  rd <- tryCatch(rdrobust(y = df$lfp, x = df$age_c, c = pc, h = 5, p = 1, q = 2),
                 error = function(e) NULL)
  if (is.null(rd)) { cat(sprintf("Age %d: SKIPPED (numerical issue)\n", 65+pc)); next }
  placebo_results <- rbind(placebo_results, data.frame(
    cutoff_age = 65 + pc, coef = rd$coef[1], se = rd$se[1], pval = rd$pv[1]
  ))
  cat(sprintf("Age %d: coef=%.4f, se=%.4f, p=%.3f\n",
              65 + pc, rd$coef[1], rd$se[1], rd$pv[1]))
}
robustness$placebo <- placebo_results

# ============================================================================
# 5. DONUT-HOLE RDD (exclude ages 64-65)
# ============================================================================
cat("\n=== Donut-hole RDD (excluding ages 64-65) ===\n")
df_donut <- df[!(age %in% c(64, 65))]
rd_donut <- rdrobust(y = df_donut$lfp, x = df_donut$age_c, c = 0, h = 6, p = 1, q = 2)
cat(sprintf("LFP donut: coef=%.4f, se=%.4f, p=%.3f\n",
            rd_donut$coef[1], rd_donut$se[1], rd_donut$pv[1]))

# Employment donut
rd_donut_emp <- rdrobust(y = df_donut$employed, x = df_donut$age_c, c = 0, h = 6, p = 1, q = 2)
cat(sprintf("Employment donut: coef=%.4f, se=%.4f, p=%.3f\n",
            rd_donut_emp$coef[1], rd_donut_emp$se[1], rd_donut_emp$pv[1]))

# Hours donut
rd_donut_hrs <- rdrobust(y = df_donut$hours, x = df_donut$age_c, c = 0, h = 6, p = 1, q = 2)
cat(sprintf("Hours donut: coef=%.4f, se=%.4f, p=%.3f\n",
            rd_donut_hrs$coef[1], rd_donut_hrs$se[1], rd_donut_hrs$pv[1]))

# ============================================================================
# 6. YEAR-BY-YEAR ESTIMATES
# ============================================================================
cat("\n=== Year-by-year estimates (LFP) ===\n")
for (yr in sort(unique(df$year))) {
  sub <- df[year == yr]
  rd <- rdrobust(y = sub$lfp, x = sub$age_c, c = 0)
  cat(sprintf("%d: coef=%.4f, se=%.4f, p=%.3f, N=%s\n",
              yr, rd$coef[1], rd$se[1], rd$pv[1], format(nrow(sub), big.mark=",")))
}

saveRDS(robustness, "../data/robustness_results.rds")
cat("\n=== Robustness checks complete ===\n")
