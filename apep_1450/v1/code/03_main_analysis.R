# 03_main_analysis.R — Sharp RDD at HACRP 75th percentile
source("00_packages.R")

data_dir <- "../data"
analysis <- readRDS(file.path(data_dir, "analysis.rds"))
cutoff <- readRDS(file.path(data_dir, "cutoff.rds"))

cat("=== HACRP RDD Main Analysis ===\n")
cat("Sample:", nrow(analysis), "hospitals\n")
cat("Cutoff:", cutoff, "\n\n")

# ============================================================
# 1. McCrary Density Test (Manipulation Check)
# ============================================================
cat("=== 1. McCrary Density Test ===\n")
density_test <- rddensity(X = analysis$score_centered, vce = "jackknife")
cat("  T-statistic:", round(density_test$test$t_jk, 3), "\n")
cat("  P-value:", round(density_test$test$p_jk, 3), "\n")
cat("  Interpretation:", ifelse(density_test$test$p_jk > 0.05,
    "PASS - No evidence of manipulation", "WARN - Possible manipulation"), "\n\n")

# ============================================================
# 2. RDD: Hospital Overall Star Rating (quality outcome)
# ============================================================
cat("=== 2. RDD: Hospital Star Rating ===\n")

# Convert star rating to numeric
analysis[, stars := as.numeric(hospital_overall_rating)]
cat("  Valid star ratings:", sum(!is.na(analysis$stars)), "\n")
cat("  Mean stars:", round(mean(analysis$stars, na.rm = TRUE), 2), "\n")

# Main RDD specification: local linear, triangular kernel, CCT bandwidth
rdd_stars <- rdrobust(
  y = analysis$stars,
  x = analysis$score_centered,
  c = 0,
  kernel = "triangular",
  bwselect = "mserd"
)
cat("\n  RDD estimate (stars):\n")
summary(rdd_stars)

# Store results
stars_coef <- rdd_stars$coef[1]  # Conventional
stars_se <- rdd_stars$se[3]       # Robust SE
stars_bw <- rdd_stars$bws[1, 1]   # Bandwidth
stars_n_left <- rdd_stars$N_h[1]
stars_n_right <- rdd_stars$N_h[2]

# ============================================================
# 3. RDD: Safety Measures Performance
# ============================================================
cat("\n=== 3. RDD: Safety Measures ===\n")

# Number of safety measures rated "worse than national"
analysis[, safety_worse := as.numeric(count_of_safety_measures_worse)]

rdd_safety <- tryCatch({
  rdrobust(
    y = analysis$safety_worse,
    x = analysis$score_centered,
    c = 0,
    kernel = "triangular",
    bwselect = "mserd"
  )
}, error = function(e) {
  cat("  Safety RDD failed:", e$message, "\n")
  NULL
})

if (!is.null(rdd_safety)) {
  cat("  RDD estimate (safety worse count):\n")
  summary(rdd_safety)
}

# ============================================================
# 4. RDD: Individual HAI SIRs (infection outcomes)
# ============================================================
cat("\n=== 4. RDD: Individual HAI SIRs ===\n")

hai_measures <- c("HAI_1_SIR", "HAI_2_SIR", "HAI_3_SIR",
                   "HAI_4_SIR", "HAI_5_SIR", "HAI_6_SIR")
hai_labels <- c("CLABSI", "CAUTI", "SSI Colon", "SSI Hysterectomy",
                "MRSA", "C. diff")

rdd_hai_results <- list()
for (i in seq_along(hai_measures)) {
  m <- hai_measures[i]
  if (m %in% names(analysis)) {
    y <- as.numeric(analysis[[m]])
    valid <- !is.na(y) & !is.na(analysis$score_centered)
    cat(sprintf("\n  %s (%s): n=%d valid\n", m, hai_labels[i], sum(valid)))

    rdd_m <- tryCatch({
      rdrobust(
        y = y[valid],
        x = analysis$score_centered[valid],
        c = 0,
        kernel = "triangular",
        bwselect = "mserd"
      )
    }, error = function(e) {
      cat("    Failed:", e$message, "\n")
      NULL
    })

    if (!is.null(rdd_m)) {
      rdd_hai_results[[hai_labels[i]]] <- list(
        coef = rdd_m$coef[1],
        se_robust = rdd_m$se[3],
        pval_robust = rdd_m$pv[3],
        bw = rdd_m$bws[1, 1],
        n_left = rdd_m$N_h[1],
        n_right = rdd_m$N_h[2]
      )
      cat(sprintf("    Coef: %.3f, Robust SE: %.3f, p=%.3f, bw=%.3f\n",
                  rdd_m$coef[1], rdd_m$se[3], rdd_m$pv[3], rdd_m$bws[1, 1]))
    }
  }
}

# ============================================================
# 5. Balance Tests: Hospital Characteristics at the Cutoff
# ============================================================
cat("\n=== 5. Balance Tests ===\n")

# Teaching status proxy: hospital type
analysis[, is_teaching := as.integer(grepl("Teaching", hospital_type, ignore.case = TRUE))]

# Ownership categories
analysis[, is_nonprofit := as.integer(grepl("Voluntary|Non-Profit", hospital_ownership, ignore.case = TRUE))]
analysis[, is_government := as.integer(grepl("Government", hospital_ownership, ignore.case = TRUE))]
analysis[, is_forprofit := as.integer(grepl("Proprietary|For-Profit", hospital_ownership, ignore.case = TRUE))]

# Emergency services
analysis[, has_emergency := as.integer(emergency_services == "Yes")]

balance_vars <- c("is_nonprofit", "is_government", "is_forprofit", "has_emergency")
balance_labels <- c("Nonprofit", "Government", "For-Profit", "Emergency Services")

balance_results <- list()
for (i in seq_along(balance_vars)) {
  v <- balance_vars[i]
  y <- analysis[[v]]
  valid <- !is.na(y) & !is.na(analysis$score_centered)

  rdd_b <- tryCatch({
    rdrobust(
      y = y[valid],
      x = analysis$score_centered[valid],
      c = 0,
      kernel = "triangular",
      bwselect = "mserd"
    )
  }, error = function(e) {
    cat(sprintf("  %s: failed - %s\n", balance_labels[i], e$message))
    NULL
  })

  if (!is.null(rdd_b)) {
    balance_results[[balance_labels[i]]] <- list(
      coef = rdd_b$coef[1],
      se_robust = rdd_b$se[3],
      pval_robust = rdd_b$pv[3]
    )
    cat(sprintf("  %s: coef=%.3f, robust p=%.3f %s\n",
                balance_labels[i], rdd_b$coef[1], rdd_b$pv[3],
                ifelse(rdd_b$pv[3] < 0.05, "*", "")))
  }
}

# ============================================================
# 6. Domain Decomposition: What Tips Marginal Hospitals?
# ============================================================
cat("\n=== 6. Domain Decomposition (Marginal Hospitals) ===\n")

# Define marginal hospitals: within 0.2 of cutoff
bw_margin <- 0.2
marginal <- analysis[abs(score_centered) < bw_margin]
cat("  Marginal hospitals (bw=", bw_margin, "):", nrow(marginal), "\n")
cat("    Penalized:", sum(marginal$penalized), "\n")
cat("    Not penalized:", sum(!marginal$penalized), "\n")

# For each domain, compute contribution to being above/below cutoff
domains <- c("psi_90_w_z_score", "clabsi_w_z_score", "cauti_w_z_score",
             "ssi_w_z_score", "cdi_w_z_score", "mrsa_w_z_score")
domain_labels <- c("PSI-90", "CLABSI", "CAUTI", "SSI", "C. diff", "MRSA")

cat("\n  Mean domain z-scores for marginal hospitals:\n")
for (i in seq_along(domains)) {
  d <- domains[i]
  pen_mean <- mean(marginal[penalized == 1][[d]], na.rm = TRUE)
  nopen_mean <- mean(marginal[penalized == 0][[d]], na.rm = TRUE)
  diff <- pen_mean - nopen_mean
  cat(sprintf("    %s: penalized=%.3f, not=%.3f, diff=%.3f\n",
              domain_labels[i], pen_mean, nopen_mean, diff))
}

# Variance decomposition: which domain explains most of the total HAC score variance?
cat("\n  Variance contribution to Total HAC Score:\n")
score_var <- var(analysis$total_hac_score, na.rm = TRUE)
for (i in seq_along(domains)) {
  d <- domains[i]
  cov_d <- cov(analysis$total_hac_score, analysis[[d]], use = "complete.obs")
  contrib <- cov_d / score_var
  cat(sprintf("    %s: %.1f%% of total variance\n", domain_labels[i], 100 * contrib))
}

# ============================================================
# 7. Save diagnostics for validation
# ============================================================
diag <- list(
  n_treated = sum(analysis$penalized),
  n_pre = 10,  # 10 years of program existence (FY2015-2024 as "pre")
  n_obs = nrow(analysis),
  cutoff = cutoff,
  mccrary_pvalue = density_test$test$p_jk,
  stars_rdd_coef = stars_coef,
  stars_rdd_se = stars_se,
  stars_rdd_bw = stars_bw
)
jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE, pretty = TRUE)

# Save all results for table generation
results <- list(
  density_test = density_test,
  rdd_stars = rdd_stars,
  rdd_safety = rdd_safety,
  rdd_hai = rdd_hai_results,
  balance = balance_results,
  cutoff = cutoff,
  n_total = nrow(analysis),
  n_penalized = sum(analysis$penalized)
)
saveRDS(results, file.path(data_dir, "results.rds"))
saveRDS(analysis, file.path(data_dir, "analysis.rds"))

cat("\n=== Analysis complete ===\n")
