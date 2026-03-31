# 04_robustness.R — Robustness checks
# APEP-1200: Swiss Mass Immigration Initiative Close-Vote RDD

source("00_packages.R")

cat("=== Running Robustness Checks ===\n")

analysis <- readRDS("../data/analysis.rds")
results <- readRDS("../data/main_results.rds")

# ---------------------------------------------------------------
# 1. Placebo cutoffs
# ---------------------------------------------------------------

cat("\n--- Placebo Cutoffs ---\n")

# Test at fake thresholds (40%, 45%, 55%, 60%)
placebo_cutoffs <- c(-10, -5, 5, 10)  # Relative to 50%
placebo_results <- list()

for (pc in placebo_cutoffs) {
  cat("  Placebo at", 50 + pc, "%: ")
  rdd_p <- tryCatch(
    rdrobust(
      y = analysis$delta_foreign_share,
      x = analysis$yes_margin,
      c = pc,
      kernel = "triangular",
      bwselect = "mserd"
    ),
    error = function(e) NULL
  )

  if (!is.null(rdd_p)) {
    placebo_results[[as.character(pc)]] <- list(
      cutoff = 50 + pc,
      coef = rdd_p$coef[2],
      se = rdd_p$se[3],
      pval = rdd_p$pv[3]
    )
    cat("coef =", round(rdd_p$coef[2], 3), "p =", round(rdd_p$pv[3], 3), "\n")
  } else {
    cat("failed\n")
  }
}

# ---------------------------------------------------------------
# 2. Alternative kernels
# ---------------------------------------------------------------

cat("\n--- Alternative Kernels ---\n")

kernels <- c("triangular", "epanechnikov", "uniform")
kernel_results <- list()

for (k in kernels) {
  rdd_k <- rdrobust(
    y = analysis$delta_foreign_share,
    x = analysis$yes_margin,
    c = 0,
    kernel = k,
    bwselect = "mserd",
    cluster = analysis$canton_id
  )
  kernel_results[[k]] <- list(
    kernel = k,
    coef = rdd_k$coef[2],
    se = rdd_k$se[3],
    pval = rdd_k$pv[3],
    bw = rdd_k$bws[1, 1]
  )
  cat("  ", k, ": coef =", round(rdd_k$coef[2], 3),
      "SE =", round(rdd_k$se[3], 3),
      "p =", round(rdd_k$pv[3], 3), "\n")
}

# ---------------------------------------------------------------
# 3. Polynomial order sensitivity
# ---------------------------------------------------------------

cat("\n--- Polynomial Order ---\n")

poly_results <- list()
for (p in 1:2) {
  rdd_p <- rdrobust(
    y = analysis$delta_foreign_share,
    x = analysis$yes_margin,
    c = 0,
    p = p,
    kernel = "triangular",
    bwselect = "mserd",
    cluster = analysis$canton_id
  )
  poly_results[[as.character(p)]] <- list(
    order = p,
    coef = rdd_p$coef[2],
    se = rdd_p$se[3],
    pval = rdd_p$pv[3],
    bw = rdd_p$bws[1, 1]
  )
  cat("  p =", p, ": coef =", round(rdd_p$coef[2], 3),
      "SE =", round(rdd_p$se[3], 3),
      "p =", round(rdd_p$pv[3], 3), "\n")
}

# ---------------------------------------------------------------
# 4. With covariates
# ---------------------------------------------------------------

cat("\n--- RDD with Covariates ---\n")

covs <- as.matrix(analysis[, c("log_pop_pre", "foreign_share_pre", "turnout")])

rdd_covs <- rdrobust(
  y = analysis$delta_foreign_share,
  x = analysis$yes_margin,
  c = 0,
  covs = covs,
  kernel = "triangular",
  bwselect = "mserd",
  cluster = analysis$canton_id
)

cat("With covariates: coef =", round(rdd_covs$coef[2], 3),
    "SE =", round(rdd_covs$se[3], 3),
    "p =", round(rdd_covs$pv[3], 3), "\n")

# ---------------------------------------------------------------
# 5. Placebo outcome: pre-treatment foreign share change
# ---------------------------------------------------------------

cat("\n--- Placebo Outcome: Pre-Treatment Change (2010-2013) ---\n")

# The pre-treatment period should show no discontinuity at the threshold
pop_panel <- readRDS("../data/pop_panel.rds")

pre_early <- pop_panel %>%
  filter(year >= 2010 & year <= 2011) %>%
  group_by(mun_id) %>%
  summarise(fs_early = mean(foreign_share, na.rm = TRUE), .groups = "drop")

pre_late <- pop_panel %>%
  filter(year >= 2012 & year <= 2013) %>%
  group_by(mun_id) %>%
  summarise(fs_late = mean(foreign_share, na.rm = TRUE), .groups = "drop")

pre_change <- inner_join(pre_early, pre_late, by = "mun_id") %>%
  mutate(delta_fs_pre = fs_late - fs_early)

# Merge with vote data
pre_analysis <- inner_join(
  analysis %>% select(mun_id, yes_margin, canton_id),
  pre_change,
  by = "mun_id"
)

rdd_placebo <- rdrobust(
  y = pre_analysis$delta_fs_pre,
  x = pre_analysis$yes_margin,
  c = 0,
  kernel = "triangular",
  bwselect = "mserd"
)

cat("Placebo (pre-treatment): coef =", round(rdd_placebo$coef[2], 3),
    "SE =", round(rdd_placebo$se[3], 3),
    "p =", round(rdd_placebo$pv[3], 3), "\n")

# ---------------------------------------------------------------
# 6. Save robustness results
# ---------------------------------------------------------------

robust_results <- list(
  placebo_cutoffs = placebo_results,
  kernels = kernel_results,
  polynomial = poly_results,
  with_covariates = list(
    coef = rdd_covs$coef[2],
    se = rdd_covs$se[3],
    pval = rdd_covs$pv[3]
  ),
  placebo_outcome = list(
    coef = rdd_placebo$coef[2],
    se = rdd_placebo$se[3],
    pval = rdd_placebo$pv[3]
  )
)

saveRDS(robust_results, "../data/robust_results.rds")

cat("\n✓ Robustness results saved\n")
cat("=== Robustness checks complete ===\n")
