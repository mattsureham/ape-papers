# 03_main_analysis.R — Primary IV regressions
# The Deportation Dividend: Immigration Judge Leniency and Origin-Country Remittances

source("00_packages.R")

analysis <- readRDS("../data/analysis.rds")

# ===================================================================
# 1. Summary statistics
# ===================================================================
cat("=== Summary Statistics ===\n")

# Panel dimensions
cat(sprintf("  Countries: %d\n", uniqueN(analysis$iso3)))
cat(sprintf("  Years: %d-%d\n", min(analysis$year), max(analysis$year)))
cat(sprintf("  Observations: %d\n", nrow(analysis)))

# Key variable means
summ <- analysis[!is.na(log_remit) & !is.na(leniency_iv), .(
  mean_cases = mean(n_cases),
  mean_grants = mean(n_grants),
  mean_grant_rate = mean(grant_rate),
  mean_leniency = mean(leniency_iv),
  sd_leniency = sd(leniency_iv),
  mean_remit_bn = mean(remittances_usd, na.rm = TRUE) / 1e9,
  sd_log_remit = sd(log_remit, na.rm = TRUE)
)]
print(summ)

# Save summary stats for tables
saveRDS(summ, "../data/summary_stats.rds")

# ===================================================================
# 2. First Stage: Judge Leniency → Grant Rate
# ===================================================================
cat("\n=== First Stage ===\n")

# Estimation sample: non-missing remittances and instrument
est <- analysis[!is.na(log_remit) & !is.na(leniency_iv) & !is.na(gdp_growth)]

cat(sprintf("  Estimation sample: %d obs, %d countries\n",
            nrow(est), uniqueN(est$iso3)))

# First stage with country + year FE
fs <- feols(grant_rate ~ leniency_iv + gdp_growth | iso3 + year,
            data = est, cluster = ~iso3)
cat("  First Stage Results:\n")
print(summary(fs))

# F-statistic: use t-value squared as F-stat for single instrument
fs_tval <- summary(fs)$coeftable["leniency_iv", "t value"]
fs_fstat <- fs_tval^2
cat(sprintf("  First-stage F-statistic: %.1f\n", fs_fstat))

# ===================================================================
# 3. OLS: Grant Rate → Remittances
# ===================================================================
cat("\n=== OLS Estimates ===\n")

# OLS with country + year FE
ols1 <- feols(log_remit ~ grant_rate + gdp_growth | iso3 + year,
              data = est, cluster = ~iso3)
cat("  OLS (log remittances):\n")
print(summary(ols1))

# OLS: remittance/GDP share
ols2 <- feols(remit_gdp_share ~ grant_rate + gdp_growth | iso3 + year,
              data = est, cluster = ~iso3)

# ===================================================================
# 4. 2SLS: Judge Leniency IV for Grant Rate
# ===================================================================
cat("\n=== 2SLS Estimates ===\n")

# Main specification: log(remittances) = β × grant_rate + γ × gdp_growth | iso3 + year
# Instrumented: grant_rate ~ leniency_iv
iv1 <- feols(log_remit ~ gdp_growth | iso3 + year | grant_rate ~ leniency_iv,
             data = est, cluster = ~iso3)
cat("  2SLS (log remittances):\n")
print(summary(iv1))

# Per-capita remittances
iv2 <- feols(log_remit_pc ~ gdp_growth | iso3 + year | grant_rate ~ leniency_iv,
             data = est, cluster = ~iso3)

# Remittance/GDP share
iv3 <- feols(remit_gdp_share ~ gdp_growth | iso3 + year | grant_rate ~ leniency_iv,
             data = est, cluster = ~iso3)

# ===================================================================
# 5. Reduced Form: Leniency → Remittances directly
# ===================================================================
cat("\n=== Reduced Form ===\n")

rf <- feols(log_remit ~ leniency_iv + gdp_growth | iso3 + year,
            data = est, cluster = ~iso3)
cat("  Reduced Form:\n")
print(summary(rf))

# ===================================================================
# 6. Save regression objects
# ===================================================================
results <- list(
  fs = fs,
  ols1 = ols1,
  ols2 = ols2,
  iv1 = iv1,
  iv2 = iv2,
  iv3 = iv3,
  rf = rf,
  est_sample = est
)
saveRDS(results, "../data/results.rds")

# ===================================================================
# 7. Diagnostics for validator
# ===================================================================
diag <- list(
  n_treated = uniqueN(est$iso3),
  n_pre = length(unique(est$year[est$year <= 2010])),
  n_obs = nrow(est)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\n  Diagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diag$n_treated, diag$n_pre, diag$n_obs))

cat("\n=== Main analysis complete ===\n")
