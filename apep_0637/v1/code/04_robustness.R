# 04_robustness.R — Robustness checks
# apep_0637: Patent Examiner Leniency & Defensive Patenting

source("00_packages.R")

df <- readRDS("../data/analysis_clean.rds")
results <- readRDS("../data/main_results.rds")

cat("=== ROBUSTNESS CHECKS ===\n\n")

# ============================================================================
# 1. Alternative examiner minimum case thresholds
# ============================================================================
cat("--- 1. Alternative examiner case thresholds ---\n")

for (min_n in c(20, 30, 50)) {
  df_sub <- df %>% filter(exam_n_cases >= min_n)
  if (nrow(df_sub) > 100 & "log_class_filings_t1" %in% names(df_sub)) {
    fit <- feols(log_class_filings_t1 ~ 1 | au_year | granted ~ examiner_leniency,
                 data = df_sub, vcov = ~examiner_art_unit)
    cat(sprintf("  Min %d cases: N=%s, β=%.4f (SE=%.4f)\n",
                min_n, format(nrow(df_sub), big.mark = ","),
                coef(fit)["fit_granted"], se(fit)["fit_granted"]))
    results[[paste0("mincases_", min_n)]] <- fit
  }
}

# ============================================================================
# 2. Asinh transformation (robustness to log(x+1) choice)
# ============================================================================
cat("\n--- 2. Asinh transformation ---\n")

if ("asinh_class_filings_t1" %in% names(df)) {
  iv_asinh <- feols(asinh_class_filings_t1 ~ 1 | au_year | granted ~ examiner_leniency,
                    data = df, vcov = ~examiner_art_unit)
  cat(sprintf("  Asinh(t+1): β=%.4f (SE=%.4f)\n",
              coef(iv_asinh)["fit_granted"], se(iv_asinh)["fit_granted"]))
  results[["asinh"]] <- iv_asinh
}

# ============================================================================
# 3. Levels (not log) specification
# ============================================================================
cat("\n--- 3. Levels specification ---\n")

if ("class_filings_t1" %in% names(df)) {
  iv_levels <- feols(class_filings_t1 ~ 1 | au_year | granted ~ examiner_leniency,
                     data = df, vcov = ~examiner_art_unit)
  cat(sprintf("  Levels(t+1): β=%.1f (SE=%.1f)\n",
              coef(iv_levels)["fit_granted"], se(iv_levels)["fit_granted"]))
  results[["levels"]] <- iv_levels
}

# ============================================================================
# 4. Art-unit FE + Year FE (not interacted)
# ============================================================================
cat("\n--- 4. Separate AU and Year FE ---\n")

if ("log_class_filings_t1" %in% names(df)) {
  iv_sep_fe <- feols(log_class_filings_t1 ~ 1 | examiner_art_unit + filing_year |
                       granted ~ examiner_leniency,
                     data = df, vcov = ~examiner_art_unit)
  cat(sprintf("  Separate FE: β=%.4f (SE=%.4f)\n",
              coef(iv_sep_fe)["fit_granted"], se(iv_sep_fe)["fit_granted"]))
  results[["separate_fe"]] <- iv_sep_fe
}

# ============================================================================
# 5. Balance test: examiner leniency vs observables
# ============================================================================
cat("\n--- 5. Balance test ---\n")

# Test whether examiner leniency predicts pre-determined characteristics
# Small entity indicator (determined before examiner assignment)
if ("small_entity" %in% names(df)) {
  bal <- feols(small_entity ~ examiner_leniency | au_year,
               data = df, vcov = ~examiner_art_unit)
  cat(sprintf("  Leniency → Small entity: β=%.4f (SE=%.4f, p=%.3f)\n",
              coef(bal)["examiner_leniency"],
              se(bal)["examiner_leniency"],
              fixest::pvalue(bal)["examiner_leniency"]))
}

# Filing quarter (should be uncorrelated with leniency)
if ("filing_quarter" %in% names(df)) {
  bal_q <- feols(filing_quarter ~ examiner_leniency | au_year,
                 data = df, vcov = ~examiner_art_unit)
  cat(sprintf("  Leniency → Filing quarter: β=%.4f (SE=%.4f, p=%.3f)\n",
              coef(bal_q)["examiner_leniency"],
              se(bal_q)["examiner_leniency"],
              fixest::pvalue(bal_q)["examiner_leniency"]))
}

# ============================================================================
# 6. Monotonicity check
# ============================================================================
cat("\n--- 6. Monotonicity check ---\n")

# Verify that more lenient examiners have weakly higher grant rates
# across different subsamples (filing years)
mono_results <- df %>%
  group_by(filing_year) %>%
  summarise(
    cor_leniency_grant = cor(examiner_leniency, granted),
    n = n(),
    .groups = "drop"
  )
cat("  Correlation between leniency and grant, by year:\n")
for (i in seq_len(nrow(mono_results))) {
  cat(sprintf("    %d: r=%.3f (N=%s)\n",
              mono_results$filing_year[i],
              mono_results$cor_leniency_grant[i],
              format(mono_results$n[i], big.mark = ",")))
}

# ============================================================================
# 7. Permutation inference (randomization inference)
# ============================================================================
cat("\n--- 7. Permutation inference ---\n")

# Permute examiner assignment within AU-year cells
# This tests whether the reduced-form effect is driven by examiner assignment

n_perms <- 50

if ("log_class_filings_t1" %in% names(df)) {
  # Actual reduced-form coefficient
  rf_actual <- feols(log_class_filings_t1 ~ examiner_leniency | au_year,
                     data = df)
  actual_coef <- coef(rf_actual)["examiner_leniency"]

  cat(sprintf("  Actual reduced-form coefficient: %.6f\n", actual_coef))

  # Permutation distribution
  set.seed(42)
  perm_coefs <- numeric(n_perms)
  au_years <- unique(df$au_year)

  # Vectorized permutation using data.table for speed
  library(data.table)
  dt <- as.data.table(df[, c("log_class_filings_t1", "examiner_leniency", "au_year")])

  for (p in seq_len(n_perms)) {
    dt[, perm_leniency := sample(examiner_leniency), by = au_year]
    fit_perm <- feols(log_class_filings_t1 ~ perm_leniency | au_year, data = dt)
    perm_coefs[p] <- coef(fit_perm)["perm_leniency"]

    if (p %% 10 == 0) cat(sprintf("    Completed %d/%d permutations\n", p, n_perms))
  }

  perm_p <- mean(abs(perm_coefs) >= abs(actual_coef))
  cat(sprintf("  Permutation p-value (two-sided, %d perms): %.4f\n", n_perms, perm_p))

  results[["perm_p"]] <- perm_p
  results[["perm_coefs"]] <- perm_coefs
}

# ============================================================================
# Save all results
# ============================================================================

saveRDS(results, "../data/main_results.rds")
cat("\nRobustness checks complete. Results saved.\n")
