## 04_robustness.R — Robustness checks for ULEZ expansion paper
## APEP paper apep_0918: ULEZ expansion and NO2

source("code/00_packages.R")

panel <- fread("data/panel_clean.csv")
panel[, site_code := as.character(site_code)]
panel[, year_month := as.character(year_month)]

results <- readRDS("data/main_results.rds")

cat("=== Robustness Checks ===\n")

## ---- 1. Placebo: Pre-period fake treatment (Oct 2019) ----
cat("\n--- R1: Placebo treatment at Oct 2019 ---\n")
panel_pre <- panel[year_month <= "2021-10"]
panel_pre[, placebo_post := as.integer(time_index >= 22L)]  # Oct 2019 = month 22
panel_pre[, placebo_did := treat * placebo_post]

r1 <- feols(no2_mean ~ placebo_did | site_code + year_month,
            data = panel_pre, cluster = ~site_code)
cat(sprintf("  Placebo ATT: %.3f (SE: %.3f, p=%.3f)\n",
            coef(r1)["placebo_did"], se(r1)["placebo_did"],
            pvalue(r1)["placebo_did"]))

## ---- 2. Exclude COVID period (Mar 2020 - Jun 2021) ----
cat("\n--- R2: Exclude COVID lockdown months ---\n")
panel_nocovid <- panel[!(year_month >= "2020-03" & year_month <= "2021-06")]

r2 <- feols(no2_mean ~ treat_post | site_code + year_month,
            data = panel_nocovid, cluster = ~site_code)
cat(sprintf("  Excl. COVID ATT: %.3f (SE: %.3f)\n",
            coef(r2)["treat_post"], se(r2)["treat_post"]))

## ---- 3. Add borough-specific linear trends ----
cat("\n--- R3: Borough-specific linear trends ---\n")
panel[, ym_numeric := as.numeric(factor(year_month))]

r3 <- feols(no2_mean ~ treat_post | site_code + year_month + borough[ym_numeric],
            data = panel[borough != ""], cluster = ~site_code)
cat(sprintf("  Borough trends ATT: %.3f (SE: %.3f)\n",
            coef(r3)["treat_post"], se(r3)["treat_post"]))

## ---- 4. Leave-one-station-out ----
cat("\n--- R4: Leave-one-out (inner stations) ---\n")
inner_sites <- unique(panel[treat == 1]$site_code)
loo_coefs <- numeric(length(inner_sites))

for (k in seq_along(inner_sites)) {
  panel_loo <- panel[site_code != inner_sites[k]]
  fit_loo <- feols(no2_mean ~ treat_post | site_code + year_month,
                   data = panel_loo, cluster = ~site_code)
  loo_coefs[k] <- coef(fit_loo)["treat_post"]
}

cat(sprintf("  LOO range: [%.3f, %.3f]\n", min(loo_coefs), max(loo_coefs)))
cat(sprintf("  LOO mean: %.3f (main: %.3f)\n", mean(loo_coefs), coef(results$twfe_level)["treat_post"]))

## ---- 5. Wild cluster bootstrap ----
cat("\n--- R5: Wild cluster bootstrap ---\n")
r5_boot <- feols(no2_mean ~ treat_post | site_code + year_month,
                 data = panel, cluster = ~site_code)
## Use fixest's built-in bootstrap for p-value
boot_pval <- tryCatch({
  bt <- boot(r5_boot, type = "wild", nboot = 999, cluster = ~site_code)
  bt$p.value["treat_post"]
}, error = function(e) {
  cat("  Bootstrap failed:", e$message, "\n")
  NA
})
cat(sprintf("  Wild bootstrap p-value: %s\n", ifelse(is.na(boot_pval), "N/A", sprintf("%.4f", boot_pval))))

## ---- 6. Log NO2 specification ----
cat("\n--- R6: Log NO2 ---\n")
r6 <- results$twfe_log
cat(sprintf("  Log NO2 ATT: %.4f (SE: %.4f) => %.1f%% change\n",
            coef(r6)["treat_post"], se(r6)["treat_post"],
            (exp(coef(r6)["treat_post"]) - 1) * 100))

## ---- 7. Weekday only ----
cat("\n--- R7: Weekday-only subsample ---\n")
## We need hourly data for this check — approximate using the panel
## (weekday effects should be larger since ULEZ charges apply daily)
## Actually we computed monthly means so this check requires going back to hourly.
## Skip or note this as future work.
cat("  (Requires hourly-level reanalysis — noted in paper)\n")

## ---- 8. HonestDiD sensitivity ----
cat("\n--- R8: HonestDiD sensitivity bounds ---\n")

## Extract event study coefficients and variance-covariance
es_model <- results$event_study
es_coefs <- coef(es_model)
es_vcov <- vcov(es_model)

## Pre-trend coefficients: rel_time -12 to -2 (excl ref -1)
pre_names <- grep("rel_time_bin::-?[0-9]+:treat", names(es_coefs), value = TRUE)
pre_idx <- grep("rel_time_bin::-([2-9]|1[0-2]):treat", names(es_coefs))
post_idx <- grep("rel_time_bin::[0-9]+:treat", names(es_coefs))

if (length(pre_idx) > 2 && length(post_idx) > 0) {
  honest_result <- tryCatch({
    ## Relative magnitudes approach
    beta_hat <- es_coefs[c(pre_idx, post_idx)]
    sigma_hat <- es_vcov[c(pre_idx, post_idx), c(pre_idx, post_idx)]

    honest_did <- createSensitivityResults_relativeMagnitudes(
      betahat = beta_hat,
      sigma = sigma_hat,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mbarvec = seq(0, 2, by = 0.5)
    )
    cat("  HonestDiD bounds computed.\n")
    print(honest_did)
    honest_did
  }, error = function(e) {
    cat("  HonestDiD failed:", e$message, "\n")
    NULL
  })
} else {
  cat("  Insufficient pre/post periods for HonestDiD\n")
  honest_result <- NULL
}

## ---- Save all robustness results ----
rob_results <- list(
  placebo = r1,
  no_covid = r2,
  borough_trends = r3,
  loo_coefs = loo_coefs,
  loo_sites = inner_sites,
  bootstrap_pval = boot_pval,
  honest_did = honest_result
)
saveRDS(rob_results, "data/robustness_results.rds")
cat("\n=== Robustness results saved ===\n")
