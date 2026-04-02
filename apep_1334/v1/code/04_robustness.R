##############################################################################
# 04_robustness.R — Balance tests, monotonicity, robustness checks
# Paper: "Paper Patents and Real Markets" (apep_1334)
##############################################################################

source("code/00_packages.R")

cat("=== Loading analysis data ===\n")
df <- as.data.table(read_parquet("data/analysis_data.parquet"))

# -----------------------------------------------------------------------
# Step 1: Balance test — Examiner leniency should not predict app chars
# -----------------------------------------------------------------------
cat("\n=== Balance Tests (Leniency ≠ Application Characteristics) ===\n")

# Small entity status
bal_entity <- feols(small_entity ~ loo_grant_rate | cell, data = df,
                    cluster = ~examiner_art_unit)
cat(sprintf("  Leniency → Small Entity: %.5f (SE: %.5f, p=%.4f)\n",
            coef(bal_entity)["loo_grant_rate"],
            se(bal_entity)["loo_grant_rate"],
            pvalue(bal_entity)["loo_grant_rate"]))

# USPC class diversity (proxy for application type) — use number of conveyances
# as a pre-determined characteristic (conveyances that happen before grant decision
# like employer assignments)
bal_employer <- feols(as.integer(has_employer_assign) ~ loo_grant_rate | cell,
                      data = df, cluster = ~examiner_art_unit)
cat(sprintf("  Leniency → Employer Assign: %.5f (SE: %.5f, p=%.4f)\n",
            coef(bal_employer)["loo_grant_rate"],
            se(bal_employer)["loo_grant_rate"],
            pvalue(bal_employer)["loo_grant_rate"]))

# -----------------------------------------------------------------------
# Step 2: Monotonicity check — Leniency decile grant rates
# -----------------------------------------------------------------------
cat("\n=== Monotonicity: Grant Rate by Leniency Decile ===\n")

df[, leniency_decile := cut(loo_grant_rate,
                             breaks = quantile(loo_grant_rate, probs = 0:10/10),
                             labels = 1:10, include.lowest = TRUE)]

mono_check <- df[, .(grant_rate = mean(granted),
                      transfer_rate = mean(market_transfer),
                      security_rate = mean(collateralized),
                      n = .N),
                  by = leniency_decile][order(leniency_decile)]

cat("  Decile | Grant Rate | Transfer | Security | N\n")
mono_check[, cat(sprintf("  D%-5s | %.3f      | %.3f    | %.3f    | %s\n",
                          leniency_decile, grant_rate, transfer_rate,
                          security_rate, format(n, big.mark = ",")), sep = ""),
           by = leniency_decile]

# Check monotonicity: grant rate should be non-decreasing
grant_rates <- mono_check$grant_rate
is_monotone <- all(diff(grant_rates) >= -0.001)
cat(sprintf("\n  Monotonicity (grant rate): %s\n",
            ifelse(is_monotone, "PASS", "WARNING - minor violations")))

# -----------------------------------------------------------------------
# Step 3: OLS comparison
# -----------------------------------------------------------------------
cat("\n=== OLS vs. IV Comparison ===\n")

ols_transfer <- feols(market_transfer ~ granted | cell, data = df,
                      cluster = ~examiner_art_unit)
cat(sprintf("  OLS (transfer): %.4f (SE: %.4f)\n",
            coef(ols_transfer)["granted"],
            se(ols_transfer)["granted"]))

iv_transfer <- feols(market_transfer ~ 1 | cell | granted ~ loo_grant_rate,
                     data = df, cluster = ~examiner_art_unit)
cat(sprintf("  IV  (transfer): %.4f (SE: %.4f)\n",
            coef(iv_transfer)["fit_granted"],
            se(iv_transfer)["fit_granted"]))

ols_security <- feols(collateralized ~ granted | cell, data = df,
                      cluster = ~examiner_art_unit)
cat(sprintf("  OLS (security): %.4f (SE: %.4f)\n",
            coef(ols_security)["granted"],
            se(ols_security)["granted"]))

iv_security <- feols(collateralized ~ 1 | cell | granted ~ loo_grant_rate,
                     data = df, cluster = ~examiner_art_unit)
cat(sprintf("  IV  (security): %.4f (SE: %.4f)\n",
            coef(iv_security)["fit_granted"],
            se(iv_security)["fit_granted"]))

# -----------------------------------------------------------------------
# Step 4: Alternative instrument definitions
# -----------------------------------------------------------------------
cat("\n=== Alternative Instruments ===\n")

# Art-unit × 3-year filing window (coarser cells)
df[, filing_3yr := floor(filing_year / 3) * 3]
df[, cell_3yr := paste(examiner_art_unit, filing_3yr, sep = "_")]

examiner_3yr <- df[, .(n_apps = .N, n_grants = sum(granted)),
                    by = .(examiner_id, cell_3yr)]
df <- merge(df, examiner_3yr[, .(examiner_id, cell_3yr, n_apps_3yr = n_apps,
                                  n_grants_3yr = n_grants)],
            by = c("examiner_id", "cell_3yr"), all.x = TRUE)
df[, loo_3yr := fifelse(n_apps_3yr > 1,
                         (n_grants_3yr - granted) / (n_apps_3yr - 1),
                         NA_real_)]

iv_alt <- feols(market_transfer ~ 1 | cell | granted ~ loo_3yr,
                data = df[!is.na(loo_3yr)],
                cluster = ~examiner_art_unit)
cat(sprintf("  3-year window IV: %.4f (SE: %.4f)\n",
            coef(iv_alt)["fit_granted"],
            se(iv_alt)["fit_granted"]))

# -----------------------------------------------------------------------
# Step 5: Exclude top/bottom 5% of examiners (extreme leniency)
# -----------------------------------------------------------------------
cat("\n=== Trimmed Sample (excl. extreme examiners) ===\n")

p05 <- quantile(df$loo_grant_rate, 0.05)
p95 <- quantile(df$loo_grant_rate, 0.95)
df_trim <- df[loo_grant_rate >= p05 & loo_grant_rate <= p95]

iv_trim <- feols(market_transfer ~ 1 | cell | granted ~ loo_grant_rate,
                 data = df_trim, cluster = ~examiner_art_unit)
cat(sprintf("  Trimmed IV: %.4f (SE: %.4f), N=%s\n",
            coef(iv_trim)["fit_granted"],
            se(iv_trim)["fit_granted"],
            format(nrow(df_trim), big.mark = ",")))

# -----------------------------------------------------------------------
# Step 6: Save robustness results
# -----------------------------------------------------------------------
cat("\n=== Saving robustness results ===\n")

save(bal_entity, bal_employer,
     mono_check,
     ols_transfer, ols_security,
     iv_alt, iv_trim,
     file = "data/robustness_models.RData")

cat("Saved data/robustness_models.RData\n")
cat("\n=== Robustness checks complete ===\n")
