# 04_robustness.R — Robustness checks for RDD
# apep_0613: Female mayors and fiscal composition in Mexico

source("00_packages.R")

data_dir <- "../data"
analysis <- readRDS(file.path(data_dir, "analysis_rdd.rds"))

# ─── 1. Bandwidth sensitivity ──────────────────────────────────────────────
cat("=== Bandwidth Sensitivity ===\n")

# Use three key outcomes
key_outcomes <- c("share_serv_pers", "share_transfers", "share_inv_pub")
key_labels <- c("Admin Payroll", "Social Transfers", "Public Investment")

bw_sensitivity <- list()
for (i in seq_along(key_outcomes)) {
  v <- key_outcomes[i]
  y <- analysis[[v]]
  x <- analysis$female_margin
  valid <- !is.na(y) & !is.na(x)

  # Get optimal bandwidth first
  rd_opt <- rdrobust(y[valid], x[valid], c = 0)
  h_opt <- rd_opt$bws[1, 1]

  # Test at h/2, h, 1.5h, 2h
  bw_mult <- c(0.5, 0.75, 1.0, 1.5, 2.0)
  bw_res <- list()

  for (m in bw_mult) {
    h <- h_opt * m
    rd <- rdrobust(y[valid], x[valid], c = 0, h = h)
    bw_res[[as.character(m)]] <- list(
      bw_mult = m,
      bw = h,
      coef = rd$coef[1],
      se_robust = rd$se[3],
      p_robust = rd$pv[3],
      n_eff = rd$N_h[1] + rd$N_h[2]
    )
  }
  bw_sensitivity[[v]] <- bw_res

  cat(sprintf("\n%s (h_opt=%.3f):\n", key_labels[i], h_opt))
  for (m in bw_mult) {
    r <- bw_res[[as.character(m)]]
    sig <- ifelse(r$p_robust < 0.01, "***",
           ifelse(r$p_robust < 0.05, "**",
           ifelse(r$p_robust < 0.10, "*", "")))
    cat(sprintf("  h=%.3f (%.1fx): coef=%.4f, p=%.3f%s, N=%d\n",
                r$bw, m, r$coef, r$p_robust, sig, r$n_eff))
  }
}

# ─── 2. Placebo cutoffs ────────────────────────────────────────────────────
cat("\n=== Placebo Cutoffs ===\n")

placebo_cutoffs <- c(-0.10, -0.05, 0.05, 0.10)
placebo_results <- list()

for (v in key_outcomes) {
  y <- analysis[[v]]
  x <- analysis$female_margin
  valid <- !is.na(y) & !is.na(x)

  p_res <- list()
  for (pc in placebo_cutoffs) {
    # Only use observations on one side of the real cutoff for placebo
    if (pc < 0) {
      subset <- valid & x < 0
    } else {
      subset <- valid & x > 0
    }

    if (sum(subset) < 30) {
      p_res[[as.character(pc)]] <- list(cutoff = pc, coef = NA, p = NA, n = sum(subset))
      next
    }

    tryCatch({
      rd <- rdrobust(y[subset], x[subset], c = pc)
      p_res[[as.character(pc)]] <- list(
        cutoff = pc,
        coef = rd$coef[1],
        se_robust = rd$se[3],
        p_robust = rd$pv[3],
        n_eff = rd$N_h[1] + rd$N_h[2]
      )
    }, error = function(e) {
      p_res[[as.character(pc)]] <<- list(cutoff = pc, coef = NA, p = NA, n = sum(subset))
    })
  }
  placebo_results[[v]] <- p_res
}

cat("Placebo cutoff results (should be insignificant):\n")
for (v in key_outcomes) {
  cat(sprintf("  %s:\n", v))
  for (r in placebo_results[[v]]) {
    if (is.na(r$coef)) {
      cat(sprintf("    c=%.2f: insufficient data\n", r$cutoff))
    } else {
      cat(sprintf("    c=%.2f: coef=%.4f, p=%.3f\n", r$cutoff, r$coef, r$p))
    }
  }
}

# ─── 3. Donut RDD ──────────────────────────────────────────────────────────
cat("\n=== Donut RDD (exclude |margin| < 0.5%) ===\n")

donut_results <- list()
for (i in seq_along(key_outcomes)) {
  v <- key_outcomes[i]
  y <- analysis[[v]]
  x <- analysis$female_margin
  valid <- !is.na(y) & !is.na(x) & abs(x) >= 0.005

  rd <- rdrobust(y[valid], x[valid], c = 0)
  donut_results[[v]] <- list(
    coef = rd$coef[1],
    se_robust = rd$se[3],
    p_robust = rd$pv[3],
    n_eff = rd$N_h[1] + rd$N_h[2]
  )
  cat(sprintf("  %s: coef=%.4f, p=%.3f, N=%d\n",
              key_labels[i], rd$coef[1], rd$pv[3],
              rd$N_h[1] + rd$N_h[2]))
}

# ─── 4. Alternative polynomial orders ─────────────────────────────────────
cat("\n=== Polynomial Order Sensitivity ===\n")

poly_results <- list()
for (i in seq_along(key_outcomes)) {
  v <- key_outcomes[i]
  y <- analysis[[v]]
  x <- analysis$female_margin
  valid <- !is.na(y) & !is.na(x)

  for (p in 1:2) {
    rd <- rdrobust(y[valid], x[valid], c = 0, p = p)
    poly_results[[paste0(v, "_p", p)]] <- list(
      outcome = v,
      poly = p,
      coef = rd$coef[1],
      se_robust = rd$se[3],
      p_robust = rd$pv[3],
      n_eff = rd$N_h[1] + rd$N_h[2]
    )
    cat(sprintf("  %s (p=%d): coef=%.4f, p=%.3f, N=%d\n",
                key_labels[i], p, rd$coef[1], rd$pv[3],
                rd$N_h[1] + rd$N_h[2]))
  }
}

# ─── 5. Placebo outcome: revenue composition ──────────────────────────────
cat("\n=== Placebo: Pre-Election Spending (should be zero) ===\n")

pre_outcomes <- c("pre_share_serv_pers", "pre_share_transfers", "pre_share_inv_pub")
pre_labels <- c("Pre Admin Payroll", "Pre Transfers", "Pre Investment")

pre_results <- list()
for (i in seq_along(pre_outcomes)) {
  v <- pre_outcomes[i]
  y <- analysis[[v]]
  x <- analysis$female_margin
  valid <- !is.na(y) & !is.na(x)

  if (sum(valid) < 50) {
    cat(sprintf("  %s: insufficient data (%d)\n", pre_labels[i], sum(valid)))
    next
  }

  rd <- rdrobust(y[valid], x[valid], c = 0)
  pre_results[[v]] <- list(
    coef = rd$coef[1],
    se_robust = rd$se[3],
    p_robust = rd$pv[3],
    n_eff = rd$N_h[1] + rd$N_h[2]
  )
  cat(sprintf("  %s: coef=%.4f, p=%.3f, N=%d\n",
              pre_labels[i], rd$coef[1], rd$pv[3],
              rd$N_h[1] + rd$N_h[2]))
}

# Save all robustness results
save(bw_sensitivity, placebo_results, donut_results, poly_results,
     pre_results, file = file.path(data_dir, "robustness_results.RData"))
cat("\nAll robustness results saved to data/robustness_results.RData\n")
