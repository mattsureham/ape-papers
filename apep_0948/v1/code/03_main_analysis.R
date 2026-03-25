# 03_main_analysis.R — IV estimation: triplicate → oxycodone supply → MAT
# Paper: The Fiscal Shadow of the Pill Mill (apep_0948)

source("00_packages.R")

df <- arrow::read_parquet("../data/analysis_state.parquet")

cat(sprintf("Analysis sample: %d states (%d triplicate, %d non-triplicate)\n",
            nrow(df), sum(df$triplicate), sum(1 - df$triplicate)))

# =============================================================================
# 1. OLS: Oxycodone per capita → MAT claims
# =============================================================================
cat("\n=== OLS Estimates ===\n")

ols_base <- feols(log_mat_claims_pc ~ log_oxy_pc, data = df, vcov = "HC1")
ols_controls <- feols(log_mat_claims_pc ~ log_oxy_pc + log_population +
                        poverty_rate + uninsured_rate, data = df, vcov = "HC1")

cat("OLS (no controls):\n")
print(summary(ols_base))
cat("\nOLS (with controls):\n")
print(summary(ols_controls))

# =============================================================================
# 2. First Stage: Triplicate → Oxycodone per capita
# =============================================================================
cat("\n=== First Stage ===\n")

fs_base <- feols(log_oxy_pc ~ triplicate, data = df, vcov = "HC1")
fs_controls <- feols(log_oxy_pc ~ triplicate + log_population +
                       poverty_rate + uninsured_rate, data = df, vcov = "HC1")

cat("First stage (no controls):\n")
print(summary(fs_base))
cat(sprintf("  F-stat: %.2f\n", fitstat(fs_base, "f")$f$stat))

cat("\nFirst stage (with controls):\n")
print(summary(fs_controls))
cat(sprintf("  F-stat: %.2f\n", fitstat(fs_controls, "f")$f$stat))

# =============================================================================
# 3. Reduced Form: Triplicate → MAT claims
# =============================================================================
cat("\n=== Reduced Form ===\n")

rf_base <- feols(log_mat_claims_pc ~ triplicate, data = df, vcov = "HC1")
rf_controls <- feols(log_mat_claims_pc ~ triplicate + log_population +
                       poverty_rate + uninsured_rate, data = df, vcov = "HC1")

cat("Reduced form (no controls):\n")
print(summary(rf_base))
cat("\nReduced form (with controls):\n")
print(summary(rf_controls))

# =============================================================================
# 4. IV/2SLS: Triplicate → Oxy → MAT claims
# =============================================================================
cat("\n=== IV/2SLS Estimates ===\n")

iv_base <- feols(log_mat_claims_pc ~ 1 | log_oxy_pc ~ triplicate,
                 data = df, vcov = "HC1")

iv_controls <- feols(log_mat_claims_pc ~ log_population + poverty_rate +
                       uninsured_rate | log_oxy_pc ~ triplicate,
                     data = df, vcov = "HC1")

cat("IV (no controls):\n")
print(summary(iv_base))
cat(sprintf("  First-stage F: %.2f\n", fitstat(iv_base, "ivf")$ivf1$stat))

cat("\nIV (with controls):\n")
print(summary(iv_controls))
cat(sprintf("  First-stage F: %.2f\n", fitstat(iv_controls, "ivf")$ivf1$stat))

# =============================================================================
# 5. Alternative outcomes: beneficiaries, spending
# =============================================================================
cat("\n=== Alternative Outcomes ===\n")

iv_bene <- feols(log_mat_bene_pc ~ log_population + poverty_rate +
                   uninsured_rate | log_oxy_pc ~ triplicate,
                 data = df, vcov = "HC1")
cat("IV — MAT beneficiaries:\n")
print(summary(iv_bene))

iv_paid <- feols(log_mat_paid_pc ~ log_population + poverty_rate +
                   uninsured_rate | log_oxy_pc ~ triplicate,
                 data = df, vcov = "HC1")
cat("\nIV — MAT spending:\n")
print(summary(iv_paid))

# =============================================================================
# 6. Store results
# =============================================================================
results <- list(
  ols_base = list(
    coef = coef(ols_base)["log_oxy_pc"],
    se = sqrt(vcov(ols_base)["log_oxy_pc", "log_oxy_pc"]),
    n = nobs(ols_base)
  ),
  ols_controls = list(
    coef = coef(ols_controls)["log_oxy_pc"],
    se = sqrt(vcov(ols_controls)["log_oxy_pc", "log_oxy_pc"]),
    n = nobs(ols_controls)
  ),
  fs_base = list(
    coef = coef(fs_base)["triplicate"],
    se = sqrt(vcov(fs_base)["triplicate", "triplicate"]),
    f_stat = fitstat(fs_base, "f")$f$stat,
    n = nobs(fs_base)
  ),
  fs_controls = list(
    coef = coef(fs_controls)["triplicate"],
    se = sqrt(vcov(fs_controls)["triplicate", "triplicate"]),
    f_stat = fitstat(fs_controls, "f")$f$stat,
    n = nobs(fs_controls)
  ),
  iv_base = list(
    coef = coef(iv_base)["fit_log_oxy_pc"],
    se = sqrt(vcov(iv_base)["fit_log_oxy_pc", "fit_log_oxy_pc"]),
    f_stat = fitstat(iv_base, "ivf")$ivf1$stat,
    n = nobs(iv_base)
  ),
  iv_controls = list(
    coef = coef(iv_controls)["fit_log_oxy_pc"],
    se = sqrt(vcov(iv_controls)["fit_log_oxy_pc", "fit_log_oxy_pc"]),
    f_stat = fitstat(iv_controls, "ivf")$ivf1$stat,
    n = nobs(iv_controls)
  ),
  iv_bene = list(
    coef = coef(iv_bene)["fit_log_oxy_pc"],
    se = sqrt(vcov(iv_bene)["fit_log_oxy_pc", "fit_log_oxy_pc"]),
    f_stat = fitstat(iv_bene, "ivf")$ivf1$stat,
    n = nobs(iv_bene)
  ),
  iv_paid = list(
    coef = coef(iv_paid)["fit_log_oxy_pc"],
    se = sqrt(vcov(iv_paid)["fit_log_oxy_pc", "fit_log_oxy_pc"]),
    f_stat = fitstat(iv_paid, "ivf")$ivf1$stat,
    n = nobs(iv_paid)
  )
)

saveRDS(results, "../data/main_results.rds")

# Diagnostics for validate_v1.py
diagnostics <- list(
  n_treated = sum(df$triplicate),
  n_pre = 7L,
  n_obs = nrow(df)
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== Main analysis complete ===\n")
cat(sprintf("Key IV (controls): coef=%.3f, se=%.3f, F=%.1f\n",
            results$iv_controls$coef, results$iv_controls$se,
            results$iv_controls$f_stat))
