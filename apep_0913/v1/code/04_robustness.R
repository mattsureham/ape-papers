## 04_robustness.R — Robustness checks and heterogeneity
## apep_0913: Wilderness spatial RDD

source("00_packages.R")
data_dir <- file.path(dirname(getwd()), "data")

df <- readRDS(file.path(data_dir, "analysis_clean.rds"))
results <- readRDS(file.path(data_dir, "rdd_results.rds"))

df_main <- df %>% filter(forested == 1, within_5km)

# ============================================================
# 1. Bandwidth sensitivity
# ============================================================
cat("=== BANDWIDTH SENSITIVITY ===\n")

bandwidths <- c(1, 1.5, 2, 3, 4, 5)
bw_results <- data.frame(
  bandwidth = numeric(),
  coef_bc = numeric(),
  se_rb = numeric(),
  ci_lower = numeric(),
  ci_upper = numeric(),
  n_left = integer(),
  n_right = integer(),
  stringsAsFactors = FALSE
)

for (bw in bandwidths) {
  df_bw <- df_main %>% filter(abs(dist_km) <= bw)
  if (nrow(df_bw) < 100) next

  cat("  Bandwidth:", bw, "km (n =", nrow(df_bw), ")\n")
  rdd_bw <- tryCatch(
    rdrobust(y = df_bw$any_loss, x = df_bw$dist_km, c = 0,
             kernel = "triangular", p = 1, h = bw, all = TRUE),
    error = function(e) NULL
  )

  if (!is.null(rdd_bw)) {
    bw_results <- rbind(bw_results, data.frame(
      bandwidth = bw,
      coef_bc = rdd_bw$coef[2],
      se_rb = rdd_bw$se[3],
      ci_lower = rdd_bw$ci[3, 1],
      ci_upper = rdd_bw$ci[3, 2],
      n_left = rdd_bw$N_h[1],
      n_right = rdd_bw$N_h[2]
    ))
  }
}

cat("\nBandwidth sensitivity results:\n")
print(bw_results)

# ============================================================
# 2. Placebo cutoffs
# ============================================================
cat("\n=== PLACEBO CUTOFFS ===\n")

placebo_cutoffs <- c(-3, -2, -1, 1, 2, 3)  # km from real boundary
placebo_results <- data.frame(
  cutoff = numeric(),
  coef_bc = numeric(),
  se_rb = numeric(),
  pval = numeric(),
  stringsAsFactors = FALSE
)

for (pc in placebo_cutoffs) {
  rdd_pl <- tryCatch(
    rdrobust(y = df_main$any_loss, x = df_main$dist_km, c = pc,
             kernel = "triangular", p = 1, bwselect = "mserd"),
    error = function(e) NULL
  )

  if (!is.null(rdd_pl)) {
    placebo_results <- rbind(placebo_results, data.frame(
      cutoff = pc,
      coef_bc = rdd_pl$coef[2],
      se_rb = rdd_pl$se[3],
      pval = rdd_pl$pv[3]
    ))
    cat("  Cutoff", pc, "km: coef =", round(rdd_pl$coef[2], 4),
        ", p =", round(rdd_pl$pv[3], 3), "\n")
  }
}

# ============================================================
# 3. Polynomial sensitivity (linear vs quadratic)
# ============================================================
cat("\n=== POLYNOMIAL SENSITIVITY ===\n")

poly_results <- data.frame(
  polynomial = integer(),
  coef_bc = numeric(),
  se_rb = numeric(),
  stringsAsFactors = FALSE
)

for (p_order in 1:2) {
  rdd_p <- tryCatch(
    rdrobust(y = df_main$any_loss, x = df_main$dist_km, c = 0,
             kernel = "triangular", p = p_order, bwselect = "mserd", all = TRUE),
    error = function(e) NULL
  )

  if (!is.null(rdd_p)) {
    poly_results <- rbind(poly_results, data.frame(
      polynomial = p_order,
      coef_bc = rdd_p$coef[2],
      se_rb = rdd_p$se[3]
    ))
    cat("  Order", p_order, ": coef =", round(rdd_p$coef[2], 4),
        ", SE =", round(rdd_p$se[3], 4), "\n")
  }
}

# ============================================================
# 4. Kernel sensitivity
# ============================================================
cat("\n=== KERNEL SENSITIVITY ===\n")

kernel_results <- data.frame(
  kernel = character(),
  coef_bc = numeric(),
  se_rb = numeric(),
  stringsAsFactors = FALSE
)

for (kern in c("triangular", "epanechnikov", "uniform")) {
  rdd_k <- tryCatch(
    rdrobust(y = df_main$any_loss, x = df_main$dist_km, c = 0,
             kernel = kern, p = 1, bwselect = "mserd", all = TRUE),
    error = function(e) NULL
  )

  if (!is.null(rdd_k)) {
    kernel_results <- rbind(kernel_results, data.frame(
      kernel = kern,
      coef_bc = rdd_k$coef[2],
      se_rb = rdd_k$se[3]
    ))
    cat("  Kernel", kern, ": coef =", round(rdd_k$coef[2], 4),
        ", SE =", round(rdd_k$se[3], 4), "\n")
  }
}

# ============================================================
# 5. Heterogeneity: by elevation quintile
# ============================================================
cat("\n=== HETEROGENEITY: ELEVATION ===\n")

elev_het <- data.frame(
  quintile = integer(),
  coef_bc = numeric(),
  se_rb = numeric(),
  n = integer(),
  stringsAsFactors = FALSE
)

for (q in 1:5) {
  df_q <- df_main %>% filter(elev_quintile == q)
  if (nrow(df_q) < 500) next

  rdd_q <- tryCatch(
    rdrobust(y = df_q$any_loss, x = df_q$dist_km, c = 0,
             kernel = "triangular", p = 1, bwselect = "mserd"),
    error = function(e) NULL
  )

  if (!is.null(rdd_q)) {
    elev_het <- rbind(elev_het, data.frame(
      quintile = q,
      coef_bc = rdd_q$coef[2],
      se_rb = rdd_q$se[3],
      n = nrow(df_q)
    ))
    cat("  Quintile", q, ": coef =", round(rdd_q$coef[2], 4),
        " (n =", nrow(df_q), ")\n")
  }
}

# ============================================================
# 6. Heterogeneity: by baseline tree cover
# ============================================================
cat("\n=== HETEROGENEITY: BASELINE TREE COVER ===\n")

tc_het <- data.frame(
  tc_group = character(),
  coef_bc = numeric(),
  se_rb = numeric(),
  n = integer(),
  stringsAsFactors = FALSE
)

tc_splits <- list(
  "25-50%" = c(25, 50),
  "50-75%" = c(50, 75),
  "75-100%" = c(75, 100)
)

for (grp_name in names(tc_splits)) {
  bounds <- tc_splits[[grp_name]]
  df_tc <- df_main %>%
    filter(treecover2000 >= bounds[1], treecover2000 < bounds[2])
  if (nrow(df_tc) < 500) next

  rdd_tc <- tryCatch(
    rdrobust(y = df_tc$any_loss, x = df_tc$dist_km, c = 0,
             kernel = "triangular", p = 1, bwselect = "mserd"),
    error = function(e) NULL
  )

  if (!is.null(rdd_tc)) {
    tc_het <- rbind(tc_het, data.frame(
      tc_group = grp_name,
      coef_bc = rdd_tc$coef[2],
      se_rb = rdd_tc$se[3],
      n = nrow(df_tc)
    ))
    cat("  TC", grp_name, ": coef =", round(rdd_tc$coef[2], 4),
        " (n =", nrow(df_tc), ")\n")
  }
}

# ============================================================
# Save all robustness results
# ============================================================

robustness <- list(
  bandwidth = bw_results,
  placebo = placebo_results,
  polynomial = poly_results,
  kernel = kernel_results,
  het_elevation = elev_het,
  het_treecover = tc_het
)

saveRDS(robustness, file.path(data_dir, "robustness_results.rds"))
cat("\nAll robustness results saved.\n")
