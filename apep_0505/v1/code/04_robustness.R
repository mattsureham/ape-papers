## ============================================================
## 04_robustness.R — Robustness checks and sensitivity analysis
## apep_0505: Council Tax Support Localization
## ============================================================

source("00_packages.R")

## ============================================================
## 1. Load Data
## ============================================================
cat("=== Loading Data ===\n")

panel <- readRDS(file.path(DATA_DIR, "analysis_panel_final.rds"))
results <- readRDS(file.path(DATA_DIR, "main_results.rds"))

cat("Panel:", nrow(panel), "obs,", n_distinct(panel$la_code), "LAs\n")

## ============================================================
## 2. Restricted Pre-Period (Drop 2008-2009 Recession)
## ============================================================
cat("\n=== Robustness 1: Restricted Pre-Period (2010-2019) ===\n")

panel_r1 <- panel[year >= 2010]

r1_jsa <- feols(jsa_rate ~ cut_intensity:post | la_code + year,
                data = panel_r1, cluster = "la_code")
cat("JSA (2010-2019):", round(coef(r1_jsa), 3), "SE:",
    round(se(r1_jsa), 3), "\n")

r1_price <- feols(mean_log_price ~ cut_intensity:post | la_code + year,
                  data = panel_r1[!is.na(mean_log_price)],
                  cluster = "la_code")
cat("Price (2010-2019):", round(coef(r1_price), 4), "SE:",
    round(se(r1_price), 4), "\n")

## Pre-trend test in restricted sample
pre_r1 <- panel_r1[year < 2013]
pre_r1[, trend := year - 2010]
r1_pretrend <- feols(jsa_rate ~ cut_intensity:trend | la_code + year,
                     data = pre_r1, cluster = "la_code")
cat("Pre-trend (2010-2012):", round(coef(r1_pretrend), 3), "p:",
    round(fixest::pvalue(r1_pretrend), 3), "\n")

## ============================================================
## 3. Symmetric Window (2010-2016)
## ============================================================
cat("\n=== Robustness 2: Symmetric Window (2010-2016) ===\n")

panel_r2 <- panel[year >= 2010 & year <= 2016]

r2_jsa <- feols(jsa_rate ~ cut_intensity:post | la_code + year,
                data = panel_r2, cluster = "la_code")
cat("JSA (2010-2016):", round(coef(r2_jsa), 3), "SE:",
    round(se(r2_jsa), 3), "\n")

r2_price <- feols(mean_log_price ~ cut_intensity:post | la_code + year,
                  data = panel_r2[!is.na(mean_log_price)],
                  cluster = "la_code")
cat("Price (2010-2016):", round(coef(r2_price), 4), "SE:",
    round(se(r2_price), 4), "\n")

## ============================================================
## 4. Controlling for Pre-Reform Trends
## ============================================================
cat("\n=== Robustness 3: LA-Specific Linear Trends ===\n")

## Add LA-specific linear trends to absorb pre-existing divergence
panel[, la_trend := as.numeric(factor(la_code)) * year]

r3_jsa <- feols(jsa_rate ~ cut_intensity:post | la_code[year],
                data = panel, cluster = "la_code")
cat("JSA with LA-specific trends:", round(coef(r3_jsa), 3), "SE:",
    round(se(r3_jsa), 3), "\n")

r3_price <- feols(mean_log_price ~ cut_intensity:post | la_code[year],
                  data = panel[!is.na(mean_log_price)],
                  cluster = "la_code")
cat("Price with LA-specific trends:", round(coef(r3_price), 4), "SE:",
    round(se(r3_price), 4), "\n")

## ============================================================
## 5. Horse Race: WA vs Pensioner Treatment
## ============================================================
cat("\n=== Robustness 4: Horse Race (WA vs Pensioner) ===\n")

## Include both treatments to see which drives results
if ("pen_intensity" %in% names(panel)) {
  r4_horse <- feols(jsa_rate ~ cut_intensity:post + pen_intensity:post |
                      la_code + year,
                    data = panel[!is.na(pen_intensity)],
                    cluster = "la_code")
  cat("Horse race (JSA):\n")
  print(summary(r4_horse))

  r4_horse_price <- feols(mean_log_price ~ cut_intensity:post + pen_intensity:post |
                            la_code + year,
                          data = panel[!is.na(pen_intensity) & !is.na(mean_log_price)],
                          cluster = "la_code")
  cat("Horse race (price):\n")
  print(summary(r4_horse_price))
}

## ============================================================
## 6. Exclude London Boroughs
## ============================================================
cat("\n=== Robustness 5: Exclude London Boroughs ===\n")

## London boroughs have E09 codes
panel_no_london <- panel[!grepl("^E09", la_code)]
cat("Non-London LAs:", n_distinct(panel_no_london$la_code), "\n")

r5_jsa <- feols(jsa_rate ~ cut_intensity:post | la_code + year,
                data = panel_no_london, cluster = "la_code")
cat("JSA (excl. London):", round(coef(r5_jsa), 3), "SE:",
    round(se(r5_jsa), 3), "\n")

r5_price <- feols(mean_log_price ~ cut_intensity:post | la_code + year,
                  data = panel_no_london[!is.na(mean_log_price)],
                  cluster = "la_code")
cat("Price (excl. London):", round(coef(r5_price), 4), "SE:",
    round(se(r5_price), 4), "\n")

## ============================================================
## 7. Alternative Treatment: Pre-Reform JSA Level
## ============================================================
cat("\n=== Robustness 6: Pre-Reform JSA as Treatment Proxy ===\n")

## Use pre-reform (2010-2012) average JSA rate as a proxy for
## CTS exposure. LAs with higher pre-reform JSA had more CTB claimants,
## hence were more exposed to the CTS reform.

pre_jsa <- panel[year %in% 2010:2012, .(
  pre_jsa_mean = mean(jsa_rate, na.rm = TRUE)
), by = la_code]

panel_r6 <- merge(panel, pre_jsa, by = "la_code", all.x = TRUE)
panel_r6[, pre_jsa_z := scale(pre_jsa_mean)[, 1]]

r6_price <- feols(mean_log_price ~ pre_jsa_z:post | la_code + year,
                  data = panel_r6[!is.na(mean_log_price) & !is.na(pre_jsa_z)],
                  cluster = "la_code")
cat("Price (pre-reform JSA exposure):", round(coef(r6_price), 4), "SE:",
    round(se(r6_price), 4), "\n")

## Event study with alternative treatment
r6_es <- feols(mean_log_price ~ i(event_time, pre_jsa_z, ref = -1) |
                 la_code + year,
               data = panel_r6[!is.na(mean_log_price) & !is.na(pre_jsa_z)],
               cluster = "la_code")
cat("Event study (price, pre-JSA treatment):\n")
print(summary(r6_es))

## ============================================================
## 8. Wild Cluster Bootstrap (Main Specification)
## ============================================================
cat("\n=== Robustness 7: Wild Cluster Bootstrap ===\n")

## Bootstrap inference for the primary specification
## Use fwildclusterboot for improved small-cluster inference
tryCatch({
  boot_jsa <- boottest(results$m1_jsa, param = "cut_intensity:post",
                       B = 999, clustid = "la_code", type = "webb")
  cat("Bootstrap JSA: p =", round(boot_jsa$p_val, 4), "\n")
  cat("Bootstrap 95% CI:", round(boot_jsa$conf_int, 3), "\n")
}, error = function(e) {
  cat("Bootstrap failed:", e$message, "\n")
  cat("Falling back to cluster-robust SE (already reported)\n")
})

## ============================================================
## 9. Placebo Reform Year (2010)
## ============================================================
cat("\n=== Robustness 8: Placebo Reform Year (2010) ===\n")

## If effects are real, we should NOT see effects at a fake reform date
panel_placebo <- panel[year >= 2008 & year <= 2012]
panel_placebo[, post_placebo := as.integer(year >= 2010)]

r8_placebo <- feols(jsa_rate ~ cut_intensity:post_placebo | la_code + year,
                    data = panel_placebo, cluster = "la_code")
cat("Placebo (2010): β =", round(coef(r8_placebo), 3), "SE:",
    round(se(r8_placebo), 3), "p:",
    round(fixest::pvalue(r8_placebo), 3), "\n")

## ============================================================
## 10. Continuous Treatment × Year (Full Flexibility)
## ============================================================
cat("\n=== Robustness 9: Year-by-Year Price Effects ===\n")

## Property price event study with CTS treatment
## (replicating from main but printing cleaner)
es_price_clean <- feols(mean_log_price ~ i(year, cut_intensity, ref = 2012) |
                          la_code + year,
                        data = panel[!is.na(mean_log_price)],
                        cluster = "la_code")
cat("Year-by-year price effects (ref = 2012):\n")
ct <- coeftable(es_price_clean)
print(ct)

## ============================================================
## 11. HonestDiD Sensitivity (Rambachan-Roth Bounds)
## ============================================================
cat("\n=== Robustness 10: HonestDiD Sensitivity ===\n")

## Extract event study coefficients for HonestDiD
## Need the event study to use year × treatment, reference = last pre-period

## For JSA:
es_jsa_honest <- feols(jsa_rate ~ i(year, cut_intensity, ref = 2012) |
                         la_code + year,
                       data = panel, cluster = "la_code")

tryCatch({
  ## Get the coefficient vector and variance-covariance matrix
  betahat <- coef(es_jsa_honest)
  sigma <- vcov(es_jsa_honest)

  ## HonestDiD needs pre-period and post-period coefficients
  ## Pre: 2008-2011 (relative to 2012)
  ## Post: 2013-2019
  pre_idx <- grep("year::200[89]:|year::201[01]:", names(betahat))
  post_idx <- grep("year::201[3-9]:", names(betahat))

  if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
    ## Rambachan-Roth relative magnitudes
    l_vec <- basisVector(index = 1, size = length(post_idx))

    honest_results <- createSensitivityResults_relativeMagnitudes(
      betahat = betahat,
      sigma = sigma,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mbarvec = seq(0, 2, by = 0.5),
      l_vec = l_vec
    )
    cat("HonestDiD Results (JSA, first post-period):\n")
    print(honest_results)
    saveRDS(honest_results, file.path(DATA_DIR, "honestdid_jsa.rds"))
  }
}, error = function(e) {
  cat("HonestDiD JSA error:", e$message, "\n")
})

## For prices:
tryCatch({
  es_price_honest <- feols(mean_log_price ~ i(year, cut_intensity, ref = 2012) |
                             la_code + year,
                           data = panel[!is.na(mean_log_price)],
                           cluster = "la_code")

  betahat_p <- coef(es_price_honest)
  sigma_p <- vcov(es_price_honest)

  pre_idx_p <- grep("year::200[89]:|year::201[01]:", names(betahat_p))
  post_idx_p <- grep("year::201[3-9]:", names(betahat_p))

  if (length(pre_idx_p) >= 2 && length(post_idx_p) >= 1) {
    l_vec_p <- basisVector(index = 1, size = length(post_idx_p))

    honest_price <- createSensitivityResults_relativeMagnitudes(
      betahat = betahat_p,
      sigma = sigma_p,
      numPrePeriods = length(pre_idx_p),
      numPostPeriods = length(post_idx_p),
      Mbarvec = seq(0, 2, by = 0.5),
      l_vec = l_vec_p
    )
    cat("HonestDiD Results (Price, first post-period):\n")
    print(honest_price)
    saveRDS(honest_price, file.path(DATA_DIR, "honestdid_price.rds"))
  }
}, error = function(e) {
  cat("HonestDiD price error:", e$message, "\n")
})

## ============================================================
## 12. Save All Robustness Results
## ============================================================
cat("\n=== Saving Robustness Results ===\n")

robustness <- list(
  ## Restricted pre-period
  r1_jsa = r1_jsa, r1_price = r1_price,
  ## Symmetric window
  r2_jsa = r2_jsa, r2_price = r2_price,
  ## LA-specific trends
  r3_jsa = r3_jsa, r3_price = r3_price,
  ## Exclude London
  r5_jsa = r5_jsa, r5_price = r5_price,
  ## Alternative treatment
  r6_price = r6_price, r6_es = r6_es,
  ## Placebo reform year
  r8_placebo = r8_placebo,
  ## Year-by-year prices
  es_price_clean = es_price_clean,
  ## HonestDiD event study inputs
  es_jsa_honest = es_jsa_honest
)

## Add horse race if estimated
if (exists("r4_horse")) {
  robustness$r4_horse <- r4_horse
  robustness$r4_horse_price <- r4_horse_price
}

saveRDS(robustness, file.path(DATA_DIR, "robustness_results.rds"))
cat("Robustness results saved.\n")
