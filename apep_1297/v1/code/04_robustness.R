# 04_robustness.R — Robustness checks for Ireland HTB bunching
# Ireland HTB Price Bunching (apep_1297)

source("00_packages.R")

# Re-source the bunching function from 03
source("03_main_analysis.R")

df <- readRDS("../data/ppr_analysis.rds")
nb_htb <- df[new_build == TRUE & year >= 2017]
sh_htb <- df[new_build == FALSE & year >= 2017]

# ============================================================
# ROBUSTNESS 1: Vary polynomial order (5, 6, 7, 8, 9)
# ============================================================

cat("\n========================================\n")
cat("ROBUSTNESS: Polynomial order sensitivity\n")
cat("========================================\n")

poly_results <- data.frame()
for (p in 5:9) {
  res <- estimate_bunching(nb_htb, poly_order = p, n_boot = 200)
  poly_results <- rbind(poly_results, data.frame(
    poly_order = p,
    excess_mass = res$excess_mass,
    se = res$se_excess,
    bunching_ratio = res$bunching_ratio,
    se_ratio = res$se_ratio
  ))
  cat("Order", p, ": B =", round(res$bunching_ratio, 2),
      " (SE:", round(res$se_ratio, 2), ")\n")
}

# ============================================================
# ROBUSTNESS 2: Vary bin width (2500, 5000, 10000)
# ============================================================

cat("\n========================================\n")
cat("ROBUSTNESS: Bin width sensitivity\n")
cat("========================================\n")

bin_results <- data.frame()
for (bw in c(2500, 5000, 10000)) {
  # Adjust exclusion window proportionally
  excl_l <- 500000 - 5 * bw
  excl_u <- 500000 + 4 * bw
  res <- estimate_bunching(nb_htb, bin_width = bw, excl_lower = excl_l,
                            excl_upper = excl_u, n_boot = 200)
  bin_results <- rbind(bin_results, data.frame(
    bin_width = bw,
    excess_mass = res$excess_mass,
    se = res$se_excess,
    bunching_ratio = res$bunching_ratio,
    se_ratio = res$se_ratio
  ))
  cat("Bin width €", bw, ": B =", round(res$bunching_ratio, 2),
      " (SE:", round(res$se_ratio, 2), ")\n")
}

# ============================================================
# ROBUSTNESS 3: Vary exclusion window
# ============================================================

cat("\n========================================\n")
cat("ROBUSTNESS: Exclusion window sensitivity\n")
cat("========================================\n")

window_results <- data.frame()
for (w in c(15000, 20000, 25000, 30000, 35000)) {
  res <- estimate_bunching(nb_htb, excl_lower = 500000 - w,
                            excl_upper = 500000 + w, n_boot = 200)
  window_results <- rbind(window_results, data.frame(
    window = w,
    excl_lower = 500000 - w,
    excl_upper = 500000 + w,
    excess_mass = res$excess_mass,
    se = res$se_excess,
    bunching_ratio = res$bunching_ratio,
    se_ratio = res$se_ratio
  ))
  cat("Window ±€", w, ": B =", round(res$bunching_ratio, 2),
      " (SE:", round(res$se_ratio, 2), ")\n")
}

# ============================================================
# ROBUSTNESS 4: Formal difference-in-bunching (new vs second-hand)
# ============================================================

cat("\n========================================\n")
cat("DIFFERENCE-IN-BUNCHING: New builds vs Second-hand (same period)\n")
cat("========================================\n")

res_nb <- estimate_bunching(nb_htb, n_boot = 300)
res_sh <- estimate_bunching(sh_htb, n_boot = 300)

dib_cross <- res_nb$bunching_ratio - res_sh$bunching_ratio
dib_cross_se <- sqrt(res_nb$se_ratio^2 + res_sh$se_ratio^2)
cat("New builds B:", round(res_nb$bunching_ratio, 2), "\n")
cat("Second-hand B:", round(res_sh$bunching_ratio, 2), "\n")
cat("DiB (new - SH):", round(dib_cross, 2), " (SE:", round(dib_cross_se, 2), ")\n")
cat("t-stat:", round(dib_cross / dib_cross_se, 2), "\n")

# ============================================================
# ROBUSTNESS 5: Round-number test at €400K and €450K (placebo thresholds)
# ============================================================

cat("\n========================================\n")
cat("PLACEBO THRESHOLDS: €400K and €450K\n")
cat("========================================\n")

for (placebo_t in c(400000, 450000)) {
  res_p <- estimate_bunching(nb_htb, threshold = placebo_t,
                              excl_lower = placebo_t - 25000,
                              excl_upper = placebo_t + 20000,
                              n_boot = 200)
  cat("Threshold €", placebo_t / 1000, "K: B =", round(res_p$bunching_ratio, 2),
      " (SE:", round(res_p$se_ratio, 2), ")\n")
}

# ============================================================
# SAVE ROBUSTNESS RESULTS
# ============================================================

robustness <- list(
  poly_order = poly_results,
  bin_width = bin_results,
  exclusion_window = window_results,
  dib_cross = list(dib = dib_cross, se = dib_cross_se),
  nb_ratio = res_nb$bunching_ratio,
  sh_ratio = res_sh$bunching_ratio
)
saveRDS(robustness, "../data/robustness_results.rds")

cat("\nRobustness results saved.\n")
