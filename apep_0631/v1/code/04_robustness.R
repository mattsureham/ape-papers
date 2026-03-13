## 04_robustness.R — Robustness checks: placebo, dose-response, symmetry test
## APEP paper apep_0631

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel[, date := as.Date(date)]

## ── 1. Placebo: Low-SALT zip codes (bite = 0) ──
cat("=== Placebo: Low-SALT zips ===\n")

# For zips with salt_bite == 0, use raw avg_salt as "fake" treatment
# These zips were under the cap, so TCJA should have zero effect
panel_low <- panel[salt_bite == 0]
panel_low[, pseudo_treat := avg_salt / 10000]  # in $10K, but all < 1.0

fit_placebo <- feols(log_zhvi ~ post_tcja:pseudo_treat | zip_id + time_id,
                     data = panel_low, cluster = ~state_fips)
cat("Placebo (low-SALT zips):\n")
summary(fit_placebo)

## ── 2. Dose-Response: Binned treatment intensity ──
cat("\n=== Dose-Response ===\n")

# Create bins of SALT bite
panel[, bite_bin := cut(salt_bite,
                        breaks = c(-Inf, 0, 0.5, 1.0, 1.5, 2.0, Inf),
                        labels = c("Under cap", "$0-5K above", "$5-10K above",
                                   "$10-15K above", "$15-20K above", "$20K+ above"))]

fit_dose <- feols(log_zhvi ~ i(bite_bin, post_tcja, ref = "Under cap") | zip_id + time_id,
                  data = panel, cluster = ~state_fips)
cat("Dose-response:\n")
summary(fit_dose)

## ── 3. Symmetry test: TCJA vs OBBB reversal ──
cat("\n=== Symmetry Test ===\n")

# Create a period indicator: pre-TCJA, post-TCJA/pre-OBBB, post-OBBB
panel[, period := fifelse(date < as.Date("2018-01-01"), "pre",
                   fifelse(date < as.Date("2025-07-01"), "tcja", "obbb"))]
panel[, period_f := relevel(factor(period), ref = "pre")]

# Separate TCJA and OBBB effects
fit_sym <- feols(log_zhvi ~ i(period_f, salt_bite, ref = "pre") | zip_id + time_id,
                 data = panel, cluster = ~state_fips)
cat("Symmetry test results:\n")
summary(fit_sym)

# Extract coefficients for symmetry comparison
beta_tcja <- coef(fit_sym)["period_f::tcja:salt_bite"]
beta_obbb <- coef(fit_sym)["period_f::obbb:salt_bite"]
se_tcja <- se(fit_sym)["period_f::tcja:salt_bite"]
se_obbb <- se(fit_sym)["period_f::obbb:salt_bite"]

cat(sprintf("\nTCJA cap effect: %.4f (SE: %.4f)\n", beta_tcja, se_tcja))
cat(sprintf("OBBB reversal effect: %.4f (SE: %.4f)\n", beta_obbb, se_obbb))
cat(sprintf("Sum (test of full reversal): %.4f\n", beta_tcja + beta_obbb))

# F-test: H0: beta_tcja + beta_obbb = 0 (full reversal)
wald_stat <- (beta_tcja + beta_obbb)^2 / (se_tcja^2 + se_obbb^2)
wald_p <- 1 - pchisq(wald_stat, df = 1)
cat(sprintf("Wald test of full reversal: chi2 = %.3f, p = %.4f\n", wald_stat, wald_p))

## ── 4. Alternative clustering: zip-code level ──
cat("\n=== Alternative Clustering ===\n")
panel_metro <- panel[!is.na(Metro) & Metro != ""]

fit_zip_cluster <- feols(log_zhvi ~ post_tcja:salt_bite | zip_id + time_id,
                         data = panel, cluster = ~zip)
cat("Zip-clustered SEs:\n")
cat(sprintf("  Coef: %.4f, SE: %.4f\n",
            coef(fit_zip_cluster)["post_tcja:salt_bite"],
            se(fit_zip_cluster)["post_tcja:salt_bite"]))

## ── 5. Pre-TCJA only: Test for pre-trends ──
cat("\n=== Pre-Trend Test ===\n")

# Linear pre-trend: interact salt_bite with year trend 2012-2017
panel_pre <- panel[year >= 2012 & year < 2018]
panel_pre[, year_trend := year - 2012]

fit_pretrend <- feols(log_zhvi ~ year_trend:salt_bite | zip_id + time_id,
                      data = panel_pre, cluster = ~state_fips)
cat("Pre-trend (salt_bite × year_trend, 2012-2017):\n")
summary(fit_pretrend)

## ── Save all robustness results ──
saveRDS(list(
  fit_placebo = fit_placebo,
  fit_dose = fit_dose,
  fit_sym = fit_sym,
  fit_zip_cluster = fit_zip_cluster,
  fit_pretrend = fit_pretrend,
  symmetry = list(
    beta_tcja = beta_tcja, beta_obbb = beta_obbb,
    se_tcja = se_tcja, se_obbb = se_obbb,
    wald_stat = wald_stat, wald_p = wald_p
  )
), file.path(data_dir, "robustness_results.rds"))

cat("\nRobustness checks complete.\n")
