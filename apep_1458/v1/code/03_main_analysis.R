source("00_packages.R")

cat("=== Main RDD Analysis ===\n")

df_rdd <- readRDS("../data/analysis_rdd.rds")
df_full <- readRDS("../data/analysis_full.rds")
thresholds <- readRDS("../data/thresholds.rds")

results <- list()

# ============================================================
# A. Pooled multi-cutoff RDD
# ============================================================
cat("\n--- Pooled multi-cutoff RDD ---\n")

outcomes <- c("any_coliform_mcl", "any_health", "any_noncoliform", "n_coliform_mcl")
outcome_labels <- c("Coliform MCL (any)", "Health-based (any)",
                     "Non-coliform MCL (any)", "Coliform MCL (count)")

for (i in seq_along(outcomes)) {
  y <- df_rdd[[outcomes[i]]]
  if (sd(y, na.rm = TRUE) == 0) {
    cat("  Skipping", outcome_labels[i], "(zero variance)\n")
    next
  }
  cat("\n  Outcome:", outcome_labels[i], "\n")
  fit <- rdrobust(y = y, x = df_rdd$dist_to_cutoff, c = 0,
                   kernel = "triangular", p = 1, bwselect = "mserd")
  cat("    Estimate:", round(fit$coef[1], 4),
      " Robust SE:", round(fit$se[3], 4),
      " Robust p:", round(fit$pv[3], 4),
      " BW:", round(fit$bws[1, 1], 0),
      " N_eff:", sum(fit$N_h), "\n")
  results[[outcomes[i]]] <- fit
}

# ============================================================
# B. Threshold-specific RDDs
# ============================================================
cat("\n--- Threshold-specific RDDs ---\n")

top_cutoffs <- c(1000, 2500, 3300, 4100, 4900)

threshold_results <- list()
for (cutoff in top_cutoffs) {
  cat("\n  Cutoff:", cutoff, "\n")
  df_c <- df_full %>%
    filter(abs(pop - cutoff) <= 5000) %>%
    mutate(running = pop - cutoff)

  n_below <- sum(df_c$running < 0)
  n_above <- sum(df_c$running > 0)
  cat("    N below:", n_below, " N above:", n_above, "\n")

  if (min(n_below, n_above) < 50) {
    cat("    Insufficient obs on one side, skipping\n")
    next
  }

  tryCatch({
    fit <- rdrobust(y = df_c$any_coliform_mcl, x = df_c$running, c = 0,
                     kernel = "triangular", p = 1, bwselect = "mserd")
    cat("    Estimate:", round(fit$coef[1], 4),
        " SE:", round(fit$se[3], 4),
        " p:", round(fit$pv[3], 4),
        " BW:", round(fit$bws[1, 1], 0), "\n")
    threshold_results[[as.character(cutoff)]] <- fit
  }, error = function(e) cat("    Error:", e$message, "\n"))
}
results$threshold <- threshold_results

# ============================================================
# C. Heterogeneity: source water type
# ============================================================
cat("\n--- Heterogeneity: source water type ---\n")

for (src in c("Groundwater", "Surface water")) {
  df_src <- df_rdd %>% filter(source_type == src)
  n_src <- nrow(df_src)
  cat("\n  Source:", src, "(N =", n_src, ")\n")
  if (n_src < 200) {
    cat("    Too few, skipping\n")
    next
  }
  tryCatch({
    fit <- rdrobust(y = df_src$any_coliform_mcl, x = df_src$dist_to_cutoff,
                     c = 0, kernel = "triangular", p = 1, bwselect = "mserd")
    cat("    Estimate:", round(fit$coef[1], 4),
        " SE:", round(fit$se[3], 4),
        " p:", round(fit$pv[3], 4), "\n")
    results[[paste0("het_", gsub(" ", "_", tolower(src)))]] <- fit
  }, error = function(e) cat("    Error:", e$message, "\n"))
}

# ============================================================
# D. Heterogeneity: ownership type (public vs private)
# ============================================================
cat("\n--- Heterogeneity: ownership type ---\n")

for (own in c("F", "P", "L")) {
  own_label <- c("F" = "Federal", "P" = "Private", "L" = "Local gov")[own]
  df_own <- df_rdd %>% filter(owner_type == own)
  cat("\n  Owner:", own_label, "(N =", nrow(df_own), ")\n")
  if (nrow(df_own) < 200) {
    cat("    Too few, skipping\n")
    next
  }
  tryCatch({
    fit <- rdrobust(y = df_own$any_coliform_mcl, x = df_own$dist_to_cutoff,
                     c = 0, kernel = "triangular", p = 1, bwselect = "mserd")
    cat("    Estimate:", round(fit$coef[1], 4),
        " SE:", round(fit$se[3], 4),
        " p:", round(fit$pv[3], 4), "\n")
    results[[paste0("het_", tolower(own_label))]] <- fit
  }, error = function(e) cat("    Error:", e$message, "\n"))
}

# ============================================================
# E. Write diagnostics.json
# ============================================================
bw <- results$any_coliform_mcl$bws[1, 1]
df_in_bw <- df_rdd %>% filter(abs(dist_to_cutoff) <= bw)

diagnostics <- list(
  n_treated = sum(df_in_bw$above == 1),
  n_pre = 9L,
  n_obs = nrow(df_in_bw),
  n_systems_total = nrow(df_full),
  n_thresholds = 9L,
  optimal_bandwidth = round(bw, 1),
  method = "multi_cutoff_rdd"
)
write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

saveRDS(results, "../data/rdd_results.rds")

cat("\n=== Main analysis complete ===\n")
cat("\nSummary of pooled estimates:\n")
for (nm in c("any_coliform_mcl", "any_health", "any_noncoliform", "n_coliform_mcl")) {
  if (!is.null(results[[nm]])) {
    cat("  ", nm, ": tau =", round(results[[nm]]$coef[1], 4),
        ", p =", round(results[[nm]]$pv[3], 4), "\n")
  }
}
