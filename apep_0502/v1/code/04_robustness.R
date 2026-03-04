# ==============================================================================
# 04_robustness.R — Robustness checks for RDD analysis
# Clean Air, Dirty Power? NAAQS Nonattainment and the Clean Energy Transition
# ==============================================================================

source("00_packages.R")

# Load cross-sectional RDD dataset (primary)
cs <- readRDS(file.path(data_dir, "cross_section_rdd.rds"))
analysis <- tryCatch(
  readRDS(file.path(data_dir, "analysis_with_energy.rds")),
  error = function(e) readRDS(file.path(data_dir, "analysis_panel.rds"))
)

cat("=== Robustness Checks ===\n\n")

# ==============================================================================
# 1. Bandwidth Sensitivity
# ==============================================================================

cat("--- Bandwidth Sensitivity ---\n")

main_outcome <- if ("fossil_capacity" %in% names(cs)) "fossil_capacity" else "pm25_mean"
rdd_data <- cs[!is.na(running_12)]

# Get optimal bandwidth first
tryCatch({
  rd_opt <- rdrobust(
    y = rdd_data[[main_outcome]],
    x = rdd_data$running_12,
    c = 0,
    kernel = "triangular",
    bwselect = "mserd"
  )
  h_opt <- rd_opt$bws["h", "left"]

  # Test at 50%, 75%, 100%, 125%, 150%, 200% of optimal
  bw_mults <- c(0.5, 0.75, 1.0, 1.25, 1.5, 2.0)
  bw_results <- list()

  for (mult in bw_mults) {
    h <- h_opt * mult
    tryCatch({
      rd <- rdrobust(
        y = rdd_data[[main_outcome]],
        x = rdd_data$running_12,
        c = 0,
        h = h,
        kernel = "triangular"
      )
      bw_results[[as.character(mult)]] <- data.table(
        bandwidth_mult = mult,
        bandwidth = h,
        coef = rd$coef["Conventional", ],
        se = rd$se["Conventional", ],
        pvalue = rd$pv["Conventional", ],
        N_left = rd$N_h[1],
        N_right = rd$N_h[2]
      )
      cat(sprintf("  h=%.2f (%.0f%%): coef=%.2f, se=%.2f, p=%.3f, N=%d+%d\n",
                  h, mult*100, rd$coef["Conventional", ], rd$se["Conventional", ],
                  rd$pv["Conventional", ], rd$N_h[1], rd$N_h[2]))
    }, error = function(e) {
      cat(sprintf("  h=%.2f (%.0f%%): error — %s\n", h, mult*100, e$message))
    })
  }

  if (length(bw_results) > 0) {
    bw_dt <- rbindlist(bw_results)
    saveRDS(bw_dt, file.path(data_dir, "robustness_bandwidth.rds"))
  }
}, error = function(e) {
  cat(sprintf("  Bandwidth sensitivity error: %s\n", e$message))
})

# ==============================================================================
# 2. Polynomial Order Sensitivity
# ==============================================================================

cat("\n--- Polynomial Order ---\n")

poly_results <- list()
for (p in 1:3) {
  tryCatch({
    rd <- rdrobust(
      y = rdd_data[[main_outcome]],
      x = rdd_data$running_12,
      c = 0,
      p = p,
      kernel = "triangular",
      bwselect = "mserd"
    )
    poly_results[[as.character(p)]] <- data.table(
      order = p,
      coef = rd$coef["Conventional", ],
      se = rd$se["Conventional", ],
      pvalue = rd$pv["Conventional", ],
      N_eff = rd$N_h[1] + rd$N_h[2]
    )
    cat(sprintf("  Order %d: coef=%.2f, se=%.2f, p=%.3f\n",
                p, rd$coef["Conventional", ], rd$se["Conventional", ], rd$pv["Conventional", ]))
  }, error = function(e) {
    cat(sprintf("  Order %d: error — %s\n", p, e$message))
  })
}
if (length(poly_results) > 0) {
  poly_dt <- rbindlist(poly_results)
  saveRDS(poly_dt, file.path(data_dir, "robustness_polynomial.rds"))
}

# ==============================================================================
# 3. Donut RDD (exclude observations very close to cutoff)
# ==============================================================================

cat("\n--- Donut RDD ---\n")

donut_sizes <- c(0.25, 0.5, 1.0)

for (donut in donut_sizes) {
  donut_data <- rdd_data[abs(running_12) >= donut]
  tryCatch({
    rd <- rdrobust(
      y = donut_data[[main_outcome]],
      x = donut_data$running_12,
      c = 0,
      kernel = "triangular",
      bwselect = "mserd"
    )
    cat(sprintf("  Donut ±%.2f: coef=%.2f, se=%.2f, p=%.3f (N=%d)\n",
                donut, rd$coef["Conventional", ], rd$se["Conventional", ],
                rd$pv["Conventional", ], rd$N_h[1] + rd$N_h[2]))
  }, error = function(e) {
    cat(sprintf("  Donut ±%.2f: error — %s\n", donut, e$message))
  })
}

# ==============================================================================
# 4. Placebo Cutoffs
# ==============================================================================

cat("\n--- Placebo Cutoffs ---\n")

# Test at cutoffs away from the true threshold
placebo_cutoffs <- c(-4, -3, -2, -1, 1, 2, 3, 4)
placebo_results <- list()

for (pc in placebo_cutoffs) {
  tryCatch({
    rd <- rdrobust(
      y = rdd_data[[main_outcome]],
      x = rdd_data$running_12,
      c = pc,
      kernel = "triangular",
      bwselect = "mserd"
    )
    placebo_results[[as.character(pc)]] <- data.table(
      cutoff_shift = pc,
      coef = rd$coef["Conventional", ],
      se = rd$se["Conventional", ],
      pvalue = rd$pv["Conventional", ],
      bw = rd$bws["h", "left"],
      N_left = rd$N_h[1],
      N_right = rd$N_h[2]
    )
    cat(sprintf("  Placebo c=%+d: coef=%.2f, p=%.3f %s\n",
                pc, rd$coef["Conventional", ], rd$pv["Conventional", ],
                ifelse(rd$pv["Conventional", ] < 0.05, "**", "")))
  }, error = function(e) {
    cat(sprintf("  Placebo c=%+d: error\n", pc))
  })
}

if (length(placebo_results) > 0) {
  placebo_dt <- rbindlist(placebo_results)
  saveRDS(placebo_dt, file.path(data_dir, "robustness_placebos.rds"))
}

# ==============================================================================
# 5. Multi-Cutoff Analysis (15 μg/m³ and 12 μg/m³)
# ==============================================================================

cat("\n--- Multi-Cutoff Analysis ---\n")

# Cutoff at 15 μg/m³ (pre-2012 standard)
pre2012 <- analysis[Year >= 2003 & Year < 2012 & !is.na(running_15)]
if (nrow(pre2012) > 50) {
  tryCatch({
    rd_15 <- rdrobust(
      y = pre2012[[main_outcome]],
      x = pre2012$running_15,
      c = 0,
      kernel = "triangular",
      bwselect = "mserd"
    )
    cat(sprintf("  15 μg/m³ cutoff (pre-2012):\n"))
    cat(sprintf("    Coefficient: %.2f (SE: %.2f), p=%.3f\n",
                rd_15$coef["Conventional", ], rd_15$se["Conventional", ],
                rd_15$pv["Conventional", ]))
    cat(sprintf("    Bandwidth: %.2f, N: %d+%d\n",
                rd_15$bws["h", "left"], rd_15$N_h[1], rd_15$N_h[2]))
  }, error = function(e) {
    cat(sprintf("  15 μg/m³ cutoff error: %s\n", e$message))
  })
}

# Pooled multi-cutoff using rdmulti
cat("\n  Pooled multi-cutoff (rdmc):\n")
tryCatch({
  # Stack both cutoffs
  stack_15 <- analysis[Year >= 2003 & Year < 2012 & !is.na(running_15),
                       .(Y = get(main_outcome), X = running_15, cutoff = 0, era = "pre2012")]
  stack_12 <- analysis[Year >= 2012 & !is.na(running_12),
                       .(Y = get(main_outcome), X = running_12, cutoff = 0, era = "post2012")]
  stacked <- rbind(stack_15, stack_12)

  if (nrow(stacked) > 100) {
    # Use rdmulti for multi-cutoff analysis
    mc <- rdmc(
      Y = stacked$Y,
      X = stacked$X,
      C = rep(0, nrow(stacked)),
      kernel = "triangular",
      bwselect = "mserd"
    )
    cat(sprintf("  Multi-cutoff pooled estimate:\n"))
    print(summary(mc))
  }
}, error = function(e) {
  cat(sprintf("  Multi-cutoff error: %s\n", e$message))
})

# ==============================================================================
# 6. Kernel Sensitivity
# ==============================================================================

cat("\n--- Kernel Sensitivity ---\n")

kern_results <- list()
for (kern in c("triangular", "epanechnikov", "uniform")) {
  tryCatch({
    rd <- rdrobust(
      y = rdd_data[[main_outcome]],
      x = rdd_data$running_12,
      c = 0,
      kernel = kern,
      bwselect = "mserd"
    )
    kern_results[[kern]] <- data.table(
      kernel = kern,
      coef = rd$coef["Conventional", ],
      se = rd$se["Conventional", ],
      pvalue = rd$pv["Conventional", ],
      N_eff = rd$N_h[1] + rd$N_h[2]
    )
    cat(sprintf("  %s: coef=%.2f, se=%.2f, p=%.3f\n",
                kern, rd$coef["Conventional", ], rd$se["Conventional", ],
                rd$pv["Conventional", ]))
  }, error = function(e) {
    cat(sprintf("  %s: error\n", kern))
  })
}
if (length(kern_results) > 0) {
  kern_dt <- rbindlist(kern_results)
  saveRDS(kern_dt, file.path(data_dir, "robustness_kernel.rds"))
}

# ==============================================================================
# 7. Save Robustness Summary
# ==============================================================================

cat("\n=== Robustness checks complete ===\n")

robustness_summary <- list(
  bandwidth = if (exists("bw_dt")) bw_dt else NULL,
  placebos = if (exists("placebo_dt")) placebo_dt else NULL
)
saveRDS(robustness_summary, file.path(data_dir, "robustness_summary.rds"))
