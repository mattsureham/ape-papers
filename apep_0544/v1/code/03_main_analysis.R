## =============================================================
## 03_main_analysis.R — Primary regressions
## apep_0544: Russian Gas Shock and European Manufacturing
## =============================================================

source("00_packages.R")

cat("=== MAIN ANALYSIS ===\n")

## -----------------------------------------------------------------
## 1. Load panel
## -----------------------------------------------------------------
panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
panel[, year_month := as.Date(year_month)]

cat("Panel loaded:", nrow(panel), "rows\n")
cat("Countries:", uniqueN(panel$geo), "\n")
cat("Sectors:", uniqueN(panel$nace_r2), "\n")

## -----------------------------------------------------------------
## 2. Main specification: Triple-FE DiD
##    Y = alpha_cs + gamma_ct + delta_st + beta*(GasShare*GasInt*Post) + e
## -----------------------------------------------------------------

# Model 1: Baseline — country + sector + time FE (no interactions)
m1 <- feols(log_ip ~ treatment_intensity:post |
              geo + nace_r2 + time,
            data = panel, cluster = ~geo + nace_r2)

# Model 2: Country x sector + time FE
m2 <- feols(log_ip ~ treatment_intensity:post |
              country_sector + time,
            data = panel, cluster = ~geo + nace_r2)

# Model 3: Country x sector + sector x time FE
m3 <- feols(log_ip ~ treatment_intensity:post |
              country_sector + sector_month,
            data = panel, cluster = ~geo + nace_r2)

# Model 4: PREFERRED — Country x sector + country x time + sector x time
m4 <- feols(log_ip ~ treatment_intensity:post |
              country_sector + country_month + sector_month,
            data = panel, cluster = ~geo + nace_r2)

cat("\n--- Main Results ---\n")
cat("Model 1 (additive FE):        beta =", round(coef(m1)[1], 4),
    "  SE =", round(sqrt(vcov(m1)[1,1]), 4), "\n")
cat("Model 2 (CS + time FE):       beta =", round(coef(m2)[1], 4),
    "  SE =", round(sqrt(vcov(m2)[1,1]), 4), "\n")
cat("Model 3 (CS + ST FE):         beta =", round(coef(m3)[1], 4),
    "  SE =", round(sqrt(vcov(m3)[1,1]), 4), "\n")
cat("Model 4 (CS + CT + ST FE):    beta =", round(coef(m4)[1], 4),
    "  SE =", round(sqrt(vcov(m4)[1,1]), 4), "\n")

## -----------------------------------------------------------------
## 3. Event study specification
##    Y = alpha_cs + gamma_ct + delta_st +
##        sum_k [beta_k * GasShare * GasInt * 1(t=k)] + e
## -----------------------------------------------------------------

# Create relative time variable (months since Feb 2022)
panel[, rel_month := as.integer(
  (year(year_month) - 2022L) * 12L + month(year_month) - 2L
)]

# Bin endpoints: everything before -24 into -24, after +30 into +30
panel[, rel_month_bin := pmin(pmax(rel_month, -24L), 30L)]

# Event study with triple FE
es <- feols(log_ip ~ i(rel_month_bin, treatment_intensity, ref = -1) |
              country_sector + country_month + sector_month,
            data = panel, cluster = ~geo + nace_r2)

cat("\nEvent study estimated with", length(coef(es)), "coefficients\n")

# Extract event study coefficients
nms <- names(coef(es))
rel_months <- as.integer(regmatches(nms, regexpr("-?[0-9]+", nms)))
es_coefs <- data.table(
  rel_month = rel_months,
  estimate = coef(es),
  se = sqrt(diag(vcov(es)))
)
es_coefs[, ci_lo := estimate - 1.96 * se]
es_coefs[, ci_hi := estimate + 1.96 * se]
es_coefs <- rbind(es_coefs,
                   data.table(rel_month = -1, estimate = 0, se = 0,
                              ci_lo = 0, ci_hi = 0))
setorder(es_coefs, rel_month)

# Pre-trend F-test
pre_coefs <- names(coef(es))[grepl("^rel_month_bin::-[0-9]", names(coef(es)))]
if (length(pre_coefs) > 1) {
  pre_test <- wald(es, pre_coefs)
  cat("\nPre-trend joint F-test:\n")
  cat("  F-stat:", round(pre_test$stat, 2), "\n")
  cat("  p-value:", round(pre_test$p, 4), "\n")
}

fwrite(es_coefs, file.path(DATA_DIR, "event_study_coefs.csv"))

## -----------------------------------------------------------------
## 4. Mechanism: Producer prices
## -----------------------------------------------------------------

pp_panel <- fread(file.path(DATA_DIR, "pp_panel.csv"))
if (nrow(pp_panel) > 0) {
  pp_panel[, year_month := as.Date(year_month)]

  m_pp <- feols(log_pp ~ treatment_intensity:post |
                  country_sector + country_month + sector_month,
                data = pp_panel, cluster = ~geo + nace_r2)

  cat("\n--- Producer Price Mechanism ---\n")
  cat("beta (prices):", round(coef(m_pp)[1], 4),
      " SE:", round(sqrt(vcov(m_pp)[1,1]), 4), "\n")
  cat("(Positive = gas-intensive sectors in gas-dependent countries saw HIGHER prices)\n")
}

## -----------------------------------------------------------------
## 5. Save model objects and key results
## -----------------------------------------------------------------

results <- list(
  main_models = list(m1 = m1, m2 = m2, m3 = m3, m4 = m4),
  event_study = es,
  mechanism_pp = if (exists("m_pp")) m_pp else NULL
)
saveRDS(results, file.path(DATA_DIR, "main_results.rds"))

# Key results CSV for tables
key_results <- data.table(
  model = c("Additive FE", "CS + Time FE", "CS + ST FE", "CS + CT + ST FE"),
  beta = c(coef(m1)[1], coef(m2)[1], coef(m3)[1], coef(m4)[1]),
  se = c(sqrt(vcov(m1)[1,1]), sqrt(vcov(m2)[1,1]),
         sqrt(vcov(m3)[1,1]), sqrt(vcov(m4)[1,1])),
  n_obs = c(nobs(m1), nobs(m2), nobs(m3), nobs(m4))
)
key_results[, t_stat := beta / se]
key_results[, p_value := 2 * pt(-abs(t_stat), df = pmin(
  uniqueN(panel$geo), uniqueN(panel$nace_r2)) - 1)]
key_results[, stars := fifelse(p_value < 0.01, "***",
                                fifelse(p_value < 0.05, "**",
                                        fifelse(p_value < 0.10, "*", "")))]

cat("\n--- Key Results Table ---\n")
print(key_results)

fwrite(key_results, file.path(DATA_DIR, "key_results.csv"))

## -----------------------------------------------------------------
## 6. Summary statistics for paper
## -----------------------------------------------------------------

# Overall summary statistics
sum_stats <- data.table(
  Variable = c("Industrial Production Index",
               "Russian Gas Share (2021)",
               "Sector Gas Intensity (2019)",
               "Treatment Intensity"),
  N = c(nrow(panel),
        uniqueN(panel$geo),
        uniqueN(panel$nace_r2),
        nrow(panel)),
  mean = c(mean(panel$value, na.rm = TRUE),
           mean(unique(panel[, .(geo, russian_gas_share_2021)])$russian_gas_share_2021),
           mean(unique(panel[, .(nace_r2, gas_intensity)])$gas_intensity),
           mean(panel$treatment_intensity, na.rm = TRUE)),
  sd = c(sd(panel$value, na.rm = TRUE),
         sd(unique(panel[, .(geo, russian_gas_share_2021)])$russian_gas_share_2021),
         sd(unique(panel[, .(nace_r2, gas_intensity)])$gas_intensity),
         sd(panel$treatment_intensity, na.rm = TRUE)),
  min = c(min(panel$value, na.rm = TRUE),
          min(panel$russian_gas_share_2021, na.rm = TRUE),
          min(panel$gas_intensity, na.rm = TRUE),
          min(panel$treatment_intensity, na.rm = TRUE)),
  max = c(max(panel$value, na.rm = TRUE),
          max(panel$russian_gas_share_2021, na.rm = TRUE),
          max(panel$gas_intensity, na.rm = TRUE),
          max(panel$treatment_intensity, na.rm = TRUE))
)

cat("\nSummary statistics:\n")
print(sum_stats)
fwrite(sum_stats, file.path(DATA_DIR, "summary_statistics.csv"))

# SD of log outcome (for SDE appendix)
cat("\nSD of log(IP):", round(sd(panel$log_ip, na.rm = TRUE), 4), "\n")
cat("SD of treatment intensity:", round(sd(panel$treatment_intensity, na.rm = TRUE), 6), "\n")

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
