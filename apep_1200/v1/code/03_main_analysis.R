# 03_main_analysis.R — RDD estimation
# APEP-1200: Swiss Mass Immigration Initiative Close-Vote RDD

source("00_packages.R")

cat("=== Running Main RDD Analysis ===\n")

analysis <- readRDS("../data/analysis.rds")

# ---------------------------------------------------------------
# 1. McCrary density test (manipulation check)
# ---------------------------------------------------------------

cat("\n--- McCrary Density Test ---\n")

density_test <- rddensity(X = analysis$yes_margin)
cat("McCrary test p-value:", round(density_test$test$p_jk, 4), "\n")
cat("Interpretation:", ifelse(density_test$test$p_jk > 0.05,
    "No evidence of manipulation (good)", "Potential manipulation concern"), "\n")

saveRDS(density_test, "../data/density_test.rds")

# ---------------------------------------------------------------
# 2. Main RDD: Effect on foreign population share change
# ---------------------------------------------------------------

cat("\n--- Main RDD: Foreign Population Share Change ---\n")

# Primary specification: rdrobust with MSE-optimal bandwidth
rdd_foreign <- rdrobust(
  y = analysis$delta_foreign_share,
  x = analysis$yes_margin,
  c = 0,
  kernel = "triangular",
  bwselect = "mserd",
  cluster = analysis$canton_id,
  all = TRUE
)

cat("\nRDD estimate (delta foreign share):\n")
print(summary(rdd_foreign))

# ---------------------------------------------------------------
# 3. RDD: Effect on total population change
# ---------------------------------------------------------------

cat("\n--- RDD: Total Population Change ---\n")

rdd_pop <- rdrobust(
  y = analysis$delta_pop_pct,
  x = analysis$yes_margin,
  c = 0,
  kernel = "triangular",
  bwselect = "mserd",
  cluster = analysis$canton_id,
  all = TRUE
)

cat("\nRDD estimate (delta total pop):\n")
print(summary(rdd_pop))

# ---------------------------------------------------------------
# 4. RDD: Effect on foreign population change (%)
# ---------------------------------------------------------------

cat("\n--- RDD: Foreign Population Change (%) ---\n")

rdd_foreign_pct <- rdrobust(
  y = analysis$delta_foreign_pct,
  x = analysis$yes_margin,
  c = 0,
  kernel = "triangular",
  bwselect = "mserd",
  cluster = analysis$canton_id,
  all = TRUE
)

cat("\nRDD estimate (delta foreign pop %):\n")
print(summary(rdd_foreign_pct))

# ---------------------------------------------------------------
# 5. Covariate balance at the threshold
# ---------------------------------------------------------------

cat("\n--- Covariate Balance Tests ---\n")

# Pre-treatment covariates that should be smooth at threshold
covariates <- c("pop_total_pre", "foreign_share_pre", "turnout", "eligible")

balance_results <- list()
for (cov in covariates) {
  cat("  Testing:", cov, "\n")
  bal <- rdrobust(
    y = analysis[[cov]],
    x = analysis$yes_margin,
    c = 0,
    kernel = "triangular",
    bwselect = "mserd"
  )
  balance_results[[cov]] <- list(
    coef = bal$coef[1],
    se = bal$se[3],  # Robust SE
    pval = bal$pv[3],  # Robust p-value
    bw = bal$bws[1, 1]
  )
  cat("    Coefficient:", round(bal$coef[1], 3),
      "p-value:", round(bal$pv[3], 3), "\n")
}

# ---------------------------------------------------------------
# 6. Bandwidth sensitivity
# ---------------------------------------------------------------

cat("\n--- Bandwidth Sensitivity ---\n")

main_bw <- rdd_foreign$bws[1, 1]
bw_multiples <- c(0.5, 0.75, 1.0, 1.25, 1.5, 2.0)

bw_results <- list()
for (mult in bw_multiples) {
  bw <- main_bw * mult
  rdd_bw <- rdrobust(
    y = analysis$delta_foreign_share,
    x = analysis$yes_margin,
    c = 0,
    h = bw,
    kernel = "triangular",
    cluster = analysis$canton_id
  )
  bw_results[[as.character(mult)]] <- list(
    multiplier = mult,
    bandwidth = bw,
    coef = rdd_bw$coef[1],
    se = rdd_bw$se[3],
    pval = rdd_bw$pv[3],
    n_left = rdd_bw$N[1],
    n_right = rdd_bw$N[2]
  )
  cat("  BW =", round(bw, 1), "pp: coef =",
      round(rdd_bw$coef[1], 3), "SE =", round(rdd_bw$se[3], 3),
      "N =", sum(rdd_bw$N), "\n")
}

# ---------------------------------------------------------------
# 7. Save all results
# ---------------------------------------------------------------

results <- list(
  rdd_foreign = rdd_foreign,
  rdd_pop = rdd_pop,
  rdd_foreign_pct = rdd_foreign_pct,
  density_test = density_test,
  balance_results = balance_results,
  bw_results = bw_results
)

saveRDS(results, "../data/main_results.rds")

# Write diagnostics.json
diagnostics <- list(
  n_treated = sum(analysis$above_50),
  n_pre = 10L,  # 10 years of population data; RDD method (exempt from n_pre check)
  n_obs = nrow(analysis),
  method = "RDD"
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n✓ Main results saved\n")
cat("  n_treated:", diagnostics$n_treated, "\n")
cat("  n_obs:", diagnostics$n_obs, "\n")
cat("=== Main analysis complete ===\n")
