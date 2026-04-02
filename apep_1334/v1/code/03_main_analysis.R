##############################################################################
# 03_main_analysis.R — First stage, reduced form, 2SLS regressions
# Paper: "Paper Patents and Real Markets" (apep_1334)
##############################################################################

source("code/00_packages.R")

cat("=== Loading analysis data ===\n")
df <- as.data.table(read_parquet("data/analysis_data.parquet"))
cat(sprintf("  %s applications\n", format(nrow(df), big.mark = ",")))

# -----------------------------------------------------------------------
# Step 1: First Stage — Examiner leniency → Grant
# -----------------------------------------------------------------------
cat("\n=== First Stage ===\n")

# OLS first stage with art-unit × filing-year FE
fs <- feols(granted ~ loo_grant_rate | cell, data = df,
            cluster = ~examiner_art_unit)
cat(sprintf("  Coefficient on leniency: %.4f (SE: %.4f)\n",
            coef(fs)["loo_grant_rate"], se(fs)["loo_grant_rate"]))
fs_wald <- wald(fs, "loo_grant_rate")
cat(sprintf("  F-statistic: %.1f\n", fs_wald$stat))

# -----------------------------------------------------------------------
# Step 2: Reduced Form — Leniency → Market Outcomes
# -----------------------------------------------------------------------
cat("\n=== Reduced Form ===\n")

# Market transfer
rf_transfer <- feols(market_transfer ~ loo_grant_rate | cell, data = df,
                     cluster = ~examiner_art_unit)
cat(sprintf("  Leniency → Transfer: %.5f (SE: %.5f)\n",
            coef(rf_transfer)["loo_grant_rate"],
            se(rf_transfer)["loo_grant_rate"]))

# Security interest
rf_security <- feols(collateralized ~ loo_grant_rate | cell, data = df,
                     cluster = ~examiner_art_unit)
cat(sprintf("  Leniency → Security: %.5f (SE: %.5f)\n",
            coef(rf_security)["loo_grant_rate"],
            se(rf_security)["loo_grant_rate"]))

# -----------------------------------------------------------------------
# Step 3: 2SLS — Grant → Market Outcomes
# -----------------------------------------------------------------------
cat("\n=== 2SLS (IV) ===\n")

# Market transfer (any assignment)
iv_transfer <- feols(market_transfer ~ 1 | cell | granted ~ loo_grant_rate,
                     data = df, cluster = ~examiner_art_unit)
cat(sprintf("  Grant → Transfer: %.4f (SE: %.4f)\n",
            coef(iv_transfer)["fit_granted"],
            se(iv_transfer)["fit_granted"]))

# Security interest (collateralization)
iv_security <- feols(collateralized ~ 1 | cell | granted ~ loo_grant_rate,
                     data = df, cluster = ~examiner_art_unit)
cat(sprintf("  Grant → Security: %.4f (SE: %.4f)\n",
            coef(iv_security)["fit_granted"],
            se(iv_security)["fit_granted"]))

# -----------------------------------------------------------------------
# Step 4: Entity Heterogeneity — The Key Test
# -----------------------------------------------------------------------
cat("\n=== Entity Size Heterogeneity ===\n")

# Split sample by entity size
df_small <- df[small_entity == 1]
df_large <- df[small_entity == 0]

cat(sprintf("  Small entities: %s\n", format(nrow(df_small), big.mark = ",")))
cat(sprintf("  Large entities: %s\n", format(nrow(df_large), big.mark = ",")))

# 2SLS: Small entities
iv_small <- feols(market_transfer ~ 1 | cell | granted ~ loo_grant_rate,
                  data = df_small, cluster = ~examiner_art_unit)
cat(sprintf("  Small entity: Grant → Transfer: %.4f (SE: %.4f)\n",
            coef(iv_small)["fit_granted"],
            se(iv_small)["fit_granted"]))

# 2SLS: Large entities
iv_large <- feols(market_transfer ~ 1 | cell | granted ~ loo_grant_rate,
                  data = df_large, cluster = ~examiner_art_unit)
cat(sprintf("  Large entity: Grant → Transfer: %.4f (SE: %.4f)\n",
            coef(iv_large)["fit_granted"],
            se(iv_large)["fit_granted"]))

# Security interest heterogeneity
iv_sec_small <- feols(collateralized ~ 1 | cell | granted ~ loo_grant_rate,
                      data = df_small, cluster = ~examiner_art_unit)
iv_sec_large <- feols(collateralized ~ 1 | cell | granted ~ loo_grant_rate,
                      data = df_large, cluster = ~examiner_art_unit)
cat(sprintf("  Small entity: Grant → Security: %.4f (SE: %.4f)\n",
            coef(iv_sec_small)["fit_granted"],
            se(iv_sec_small)["fit_granted"]))
cat(sprintf("  Large entity: Grant → Security: %.4f (SE: %.4f)\n",
            coef(iv_sec_large)["fit_granted"],
            se(iv_sec_large)["fit_granted"]))

# -----------------------------------------------------------------------
# Step 5: Technology heterogeneity (3-digit art unit = tech center)
# -----------------------------------------------------------------------
cat("\n=== Technology Center Heterogeneity ===\n")

tech_results <- df[, {
  tryCatch({
    mod <- feols(market_transfer ~ 1 | cell | granted ~ loo_grant_rate,
                 data = .SD, cluster = ~examiner_art_unit)
    list(coef = coef(mod)["fit_granted"],
         se = se(mod)["fit_granted"],
         n = .N)
  }, error = function(e) list(coef = NA_real_, se = NA_real_, n = .N))
}, by = art_unit_3]

tech_results <- tech_results[!is.na(coef)]
tech_results[, cat(sprintf("  TC %s: coef=%.4f (SE=%.4f), N=%s\n",
                           art_unit_3, coef, se,
                           format(n, big.mark = ",")), sep = ""),
             by = art_unit_3]

# -----------------------------------------------------------------------
# Step 6: Save results and diagnostics
# -----------------------------------------------------------------------
cat("\n=== Saving results ===\n")

# Diagnostics for validation
diagnostics <- list(
  n_treated = uniqueN(df$examiner_id),
  n_pre = 0L,  # Not applicable for IV (no pre-periods)
  n_obs = nrow(df),
  n_clusters = uniqueN(df$examiner_art_unit),
  first_stage_F = wald(fs, "loo_grant_rate")$stat,
  iv_transfer_coef = coef(iv_transfer)["fit_granted"],
  iv_transfer_se = se(iv_transfer)["fit_granted"],
  iv_security_coef = coef(iv_security)["fit_granted"],
  iv_security_se = se(iv_security)["fit_granted"],
  iv_small_transfer_coef = coef(iv_small)["fit_granted"],
  iv_large_transfer_coef = coef(iv_large)["fit_granted"]
)
write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE)

# Save model objects for table generation
save(fs, rf_transfer, rf_security,
     iv_transfer, iv_security,
     iv_small, iv_large,
     iv_sec_small, iv_sec_large,
     tech_results,
     file = "data/models.RData")

cat("Saved data/diagnostics.json and data/models.RData\n")
cat("\n=== Main analysis complete ===\n")
