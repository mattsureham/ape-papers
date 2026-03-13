# ==============================================================================
# 04_robustness.R — Robustness checks and placebos
# APEP Paper apep_0651: The Spotlight Effect on Mine Safety Enforcement
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
analysis <- readRDS(file.path(data_dir, "analysis.rds"))

# Ensure log outcomes exist
for (y in c("insp_post_90", "viol_post_90", "penalty_post_90",
            "insp_post_180", "viol_post_180")) {
  if (y %in% names(analysis)) {
    analysis[, paste0("log_", y) := log(get(y) + 1)]
  }
}

robustness_results <- list()

# ==============================================================================
# 1. PLACEBO: Pre-fatality enforcement should NOT respond to news competition
# ==============================================================================

cat("=== Placebo: Pre-fatality enforcement ===\n")

for (y_pre in c("insp_pre_365", "viol_pre_365", "penalty_pre_365", "ss_pre_365")) {
  if (!y_pre %in% names(analysis)) next

  analysis[, paste0("log_", y_pre) := log(get(y_pre) + 1)]

  controls <- intersect(c("n_killed", "is_coal", "log_employment"), names(analysis))
  control_str <- paste(controls, collapse = " + ")

  f <- as.formula(paste0("log_", y_pre, " ~ z_disasters + ", control_str, " | yq_fe + state_fe"))
  fit <- feols(f, data = analysis, vcov = "hetero")

  cat(sprintf("  %s: coef=%.4f, se=%.4f, p=%.3f\n",
              y_pre, coef(fit)["z_disasters"], se(fit)["z_disasters"],
              pvalue(fit)["z_disasters"]))

  robustness_results[[paste0("placebo_", y_pre)]] <- fit
}

# ==============================================================================
# 2. Alternative functional form: levels instead of logs
# ==============================================================================

cat("\n=== Levels specification ===\n")

for (y in c("insp_post_90", "viol_post_90", "penalty_post_90")) {
  if (!y %in% names(analysis)) next

  controls <- intersect(c("n_killed", "is_coal", "log_employment"), names(analysis))
  control_str <- paste(controls, collapse = " + ")

  f <- as.formula(paste0(y, " ~ z_disasters + ", control_str, " | yq_fe + state_fe"))
  fit <- feols(f, data = analysis, vcov = "hetero")

  cat(sprintf("  %s (levels): coef=%.4f, se=%.4f, p=%.3f\n",
              y, coef(fit)["z_disasters"], se(fit)["z_disasters"],
              pvalue(fit)["z_disasters"]))

  robustness_results[[paste0("levels_", y)]] <- fit
}

# ==============================================================================
# 3. Poisson regression for count outcomes
# ==============================================================================

cat("\n=== Poisson (count model) ===\n")

for (y in c("insp_post_90", "viol_post_90")) {
  if (!y %in% names(analysis)) next

  controls <- intersect(c("n_killed", "is_coal", "log_employment"), names(analysis))
  control_str <- paste(controls, collapse = " + ")

  f <- as.formula(paste0(y, " ~ z_disasters + ", control_str, " | yq_fe + state_fe"))
  fit <- tryCatch(
    fepois(f, data = analysis, vcov = "hetero"),
    error = function(e) {
      cat("  Poisson failed for", y, ":", e$message, "\n")
      NULL
    }
  )

  if (!is.null(fit)) {
    cat(sprintf("  %s (Poisson): coef=%.4f, se=%.4f\n",
                y, coef(fit)["z_disasters"], se(fit)["z_disasters"]))
    robustness_results[[paste0("poisson_", y)]] <- fit
  }
}

# ==============================================================================
# 4. Exclude multi-fatality events (> 1 killed)
# ==============================================================================

cat("\n=== Exclude multi-fatality events ===\n")

single_fatal <- analysis[n_killed == 1]
cat("  Single-fatality events:", nrow(single_fatal), "of", nrow(analysis), "\n")

for (y in c("insp_post_90", "viol_post_90")) {
  if (!y %in% names(single_fatal)) next

  controls <- intersect(c("is_coal", "log_employment"), names(single_fatal))
  control_str <- paste(controls, collapse = " + ")

  f <- as.formula(paste0("log_", y, " ~ z_disasters + ", control_str, " | yq_fe + state_fe"))
  fit <- feols(f, data = single_fatal, vcov = "hetero")

  cat(sprintf("  %s (single fatality): coef=%.4f, se=%.4f, p=%.3f\n",
              y, coef(fit)["z_disasters"], se(fit)["z_disasters"],
              pvalue(fit)["z_disasters"]))

  robustness_results[[paste0("single_", y)]] <- fit
}

# ==============================================================================
# 5. Permutation / Randomization Inference
# ==============================================================================

cat("\n=== Randomization Inference (500 permutations) ===\n")

# Permute the instrument assignment across fatality events
set.seed(42)
n_perm <- 500

# Main effect to compare against
controls <- intersect(c("n_killed", "is_coal", "log_employment"), names(analysis))
control_str <- paste(controls, collapse = " + ")
f_main <- as.formula(paste0("log_insp_post_90 ~ z_disasters + ", control_str, " | yq_fe + state_fe"))
fit_main <- feols(f_main, data = analysis, vcov = "hetero")
observed_coef <- coef(fit_main)["z_disasters"]

perm_coefs <- numeric(n_perm)
for (p in seq_len(n_perm)) {
  analysis_perm <- copy(analysis)
  # Permute instrument within year-quarter (preserves FE structure)
  analysis_perm[, z_disasters := sample(z_disasters), by = yq]
  fit_p <- feols(f_main, data = analysis_perm, vcov = "hetero")
  perm_coefs[p] <- coef(fit_p)["z_disasters"]
}

ri_pval <- mean(abs(perm_coefs) >= abs(observed_coef))
cat(sprintf("  Observed coef: %.4f\n", observed_coef))
cat(sprintf("  RI p-value (two-sided): %.3f\n", ri_pval))
cat(sprintf("  Permutation mean: %.4f, SD: %.4f\n", mean(perm_coefs), sd(perm_coefs)))

robustness_results[["ri_observed"]] <- observed_coef
robustness_results[["ri_pval"]] <- ri_pval
robustness_results[["ri_perm_coefs"]] <- perm_coefs

# ==============================================================================
# 6. Leave-one-out: exclude each major disaster
# ==============================================================================

cat("\n=== Leave-one-out (major disasters) ===\n")

# Identify multi-fatality events (disasters)
disasters <- analysis[n_killed >= 3]
if (nrow(disasters) > 0) {
  cat("  Major disasters (3+ killed):", nrow(disasters), "\n")

  loo_coefs <- numeric(nrow(disasters))
  for (d in seq_len(nrow(disasters))) {
    ev <- disasters[d]
    loo_data <- analysis[!(mine_id == ev$mine_id & fatality_date == ev$fatality_date)]
    fit_loo <- feols(f_main, data = loo_data, vcov = "hetero")
    loo_coefs[d] <- coef(fit_loo)["z_disasters"]
  }

  cat(sprintf("  LOO range: [%.4f, %.4f]\n", min(loo_coefs), max(loo_coefs)))
  cat(sprintf("  Baseline: %.4f\n", observed_coef))

  robustness_results[["loo_coefs"]] <- loo_coefs
} else {
  cat("  No multi-fatality disasters in sample.\n")
}

# ==============================================================================
# Save robustness results
# ==============================================================================

saveRDS(robustness_results, file.path(data_dir, "robustness_results.rds"))

cat("\n=== Robustness checks complete ===\n")
