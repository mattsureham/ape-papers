## ============================================================================
## 03_main_analysis.R — Primary Regressions
## Japan Dual-Rate Consumption Tax Paper (apep_0563)
## ============================================================================

source("00_packages.R")

data_dir <- "../data"
cpi <- fread(file.path(data_dir, "cpi_analysis.csv"))
panel <- fread(file.path(data_dir, "cpi_panel.csv"))
cpi_detail <- fread(file.path(data_dir, "cpi_detail_analysis.csv"))

# Set panel identifiers for Newey-West SEs
# Time series: single unit, time = yyyymm
cpi[, unit := 1L]
setorder(cpi, yyyymm)

# For panel data: category-month panel
panel[, yyyymm_num := as.integer(yyyymm)]
setorder(panel, category, yyyymm_num)

## ============================================================================
## ANALYSIS 1: Tax Pass-Through to Relative Prices (DD)
## ============================================================================
cat("=== Analysis 1: Tax Pass-Through ===\n\n")

# DD specification: log(eating_out CPI) - log(cooked_food CPI) = α + β·Post + ε
# β captures the differential price change between 10% and 8% rate categories

# 1a. Simple DD on relative price (full sample)
dd_full <- feols(log_relative_eatin ~ post | month_factor, data = cpi,
                 vcov = NW(12) ~ unit + yyyymm)
cat("--- DD: Full sample (Newey-West) ---\n")
print(summary(dd_full))

# Also compute HC1 for comparison
dd_full_hc1 <- feols(log_relative_eatin ~ post | month_factor, data = cpi,
                     vcov = "HC1")

# 1b. DD with clean post-treatment window (pre-COVID)
cpi_clean <- cpi[covid == 0 | post == 0]
dd_clean <- feols(log_relative_eatin ~ post | month_factor, data = cpi_clean,
                  vcov = NW(12) ~ unit + yyyymm)
cat("\n--- DD: Clean (pre-COVID, Newey-West) ---\n")
print(summary(dd_clean))

dd_clean_hc1 <- feols(log_relative_eatin ~ post | month_factor, data = cpi_clean,
                      vcov = "HC1")

# 1c. DD with COVID control
dd_covid <- feols(log_relative_eatin ~ post + covid | month_factor, data = cpi,
                  vcov = NW(12) ~ unit + yyyymm)
cat("\n--- DD: With COVID control (Newey-West) ---\n")
print(summary(dd_covid))

dd_covid_hc1 <- feols(log_relative_eatin ~ post + covid | month_factor, data = cpi,
                      vcov = "HC1")

## Formal test of full pass-through: H0: beta = 0.0183
cat("\n--- Formal Tests of Full Pass-Through (H0: beta = 0.0183) ---\n")
benchmark <- log(1.10/1.08)  # = 0.01835 in log points
for (nm in c("Full Sample", "Pre-COVID", "COVID Control")) {
  mod <- switch(nm, "Full Sample" = dd_full, "Pre-COVID" = dd_clean,
                "COVID Control" = dd_covid)
  b <- coef(mod)["post"]
  se_nw <- sqrt(diag(vcov(mod)))["post"]
  t_zero <- b / se_nw
  t_full <- (b - benchmark) / se_nw
  p_zero <- 2 * pt(-abs(t_zero), df = nobs(mod) - 2)
  p_full <- 2 * pt(-abs(t_full), df = nobs(mod) - 2)
  cat(sprintf("  %s: beta=%.4f, SE=%.4f | H0:beta=0 p=%.4f | H0:beta=0.0183 p=%.4f\n",
              nm, b, se_nw, p_zero, p_full))
}

## ============================================================================
## ANALYSIS 2: Triple Difference (DDD)
## ============================================================================
cat("\n=== Analysis 2: Triple Difference ===\n\n")

# DDD: Use alcohol as placebo (uniform 10% increase)
# log(CPI) = α + β₁·EatingOut + β₂·Post + β₃·EatingOut×Post
#           + γ₁·Alcohol + γ₂·Alcohol×Post + δ·month_FE + ε
#
# β₃ captures: Did eating-out prices increase MORE than cooked-food prices?
# If we add alcohol: the DDD controls for the general 8%→10% increase

# Panel restricted to eating_out, cooked_food, alcoholic_beverages
panel_3 <- panel[category %in% c("eating_out", "cooked_food", "alcoholic_beverages")]
panel_3[, category_f := factor(category, levels = c("cooked_food", "eating_out", "alcoholic_beverages"))]

# 2a. DD within food types
# Note: HC1 (heteroskedasticity-robust) SEs used because the panel has only
# 3 cross-sectional units (categories). Clustering at the category level would
# yield only 3 clusters — far too few for valid cluster-robust inference
# (Cameron, Gelbach & Miller 2008 recommend >= 30-50 clusters).
dd_panel <- feols(log_cpi ~ differential:post + full_rate:post |
                    category_f + yyyymm, data = panel_3, vcov = "HC1")
cat("--- DD Panel ---\n")
print(summary(dd_panel))

# 2b. Full DDD specification
# Treatment = eating_out (10% for eat-in, but 8% for takeout version)
# Control 1 = cooked_food (8% for takeout)
# Control 2 = alcoholic_beverages (10% regardless — uniform increase)
ddd <- feols(log_cpi ~ is_eating_out:post + is_alcohol:post |
               category_f + yyyymm, data = panel_3, vcov = "HC1")
cat("\n--- DDD ---\n")
print(summary(ddd))

# 2c. Pre-COVID DDD (restrict to months before Feb 2020)
panel_3_clean <- panel_3[yyyymm < 202002 | yyyymm < 201910]
# Actually: keep all pre-treatment + only pre-COVID post-treatment
panel_3_clean <- panel_3[yyyymm < 202002]
ddd_clean <- feols(log_cpi ~ is_eating_out:post + is_alcohol:post |
                     category_f + yyyymm, data = panel_3_clean, vcov = "HC1")
cat("\n--- DDD Pre-COVID ---\n")
print(summary(ddd_clean))

## ============================================================================
## ANALYSIS 3: Event Study
## ============================================================================
cat("\n=== Analysis 3: Event Study ===\n\n")

# Event study on relative price: log(eating_out/cooked_food)
# Since this is a time series (no cross-sectional variation), we use
# the raw log relative price indexed to September 2019
# and compute rolling-window averages for pre/post comparison

# Approach: Plot raw series + compute semi-annual averages with CIs
# For the event study, use the DDD panel which has category variation

# Panel event study: interact category with event-time bins
# Use only eating_out and cooked_food (2 categories) so the control group
# is clean — alcohol has its own tax change and would contaminate the control
panel_es <- panel[category %in% c("eating_out", "cooked_food")]
panel_es[, yyyymm_int := as.integer(yyyymm)]
panel_es[, event_time := (as.integer(substr(as.character(yyyymm), 1, 4)) - 2019) * 12 +
          (as.integer(substr(as.character(yyyymm), 5, 6)) - 10)]
panel_es[, log_cpi := log(cpi_index)]
panel_es[, is_eating_out := as.integer(category == "eating_out")]

# Bin event time into semi-annual periods
# Use full post-treatment data so the last bin genuinely includes 30+ months
panel_es[, event_bin := cut(event_time,
  breaks = c(-Inf, -19, -13, -7, -1, 5, 11, 17, 23, 29, Inf),
  labels = c("[-24,-19]", "[-18,-13]", "[-12,-7]", "[-6,-1]", "[0,5]", "[6,11]",
             "[12,17]", "[18,23]", "[24,29]", "[30+]"),
  right = TRUE)]
panel_es[, event_bin := relevel(factor(event_bin), ref = "[-6,-1]")]

es_panel <- feols(log_cpi ~ i(event_bin, is_eating_out, ref = "[-6,-1]") |
                    category + yyyymm_int,
                  data = panel_es[event_time >= -24],
                  vcov = "HC1")
cat("--- Panel Event Study ---\n")
print(summary(es_panel))

# Also compute simple time-series event study coefficients for plotting
# Use de-seasonalized relative price (subtract within-month mean)
cpi[, month_mean := mean(log_relative_eatin), by = month]
cpi[, log_rel_deseason := log_relative_eatin - month_mean]

# Index to September 2019
base_val <- cpi[yyyymm == 201909, log_rel_deseason]
es_coefs <- cpi[, .(event_time = event_time,
                     estimate = log_rel_deseason - base_val)]

# Compute SEs via pre-period residual variance
pre_sd <- sd(cpi[post == 0, log_rel_deseason])
es_coefs[, se := pre_sd]
es_coefs[, ci_lower := estimate - 1.96 * se]
es_coefs[, ci_upper := estimate + 1.96 * se]

# Set the reference period to 0
es_coefs[event_time == -1, c("estimate", "se", "ci_lower", "ci_upper") := 0]

setorder(es_coefs, event_time)
fwrite(es_coefs, file.path(data_dir, "event_study_coefs.csv"))

## ============================================================================
## ANALYSIS 4: Magnitude Decomposition
## ============================================================================
cat("\n=== Analysis 4: Magnitude Decomposition ===\n\n")

# Compare actual price changes to predicted under full pass-through
# Tax wedge: 2/108 ≈ 1.85% (the price should rise by 1.85% for eat-in items)

# Actual change at impact (October 2019 vs September 2019)
oct <- cpi[yyyymm == 201910]
sep <- cpi[yyyymm == 201909]
delta_eating <- (oct$eating_out - sep$eating_out) / sep$eating_out * 100
delta_cooked <- (oct$cooked_food - sep$cooked_food) / sep$cooked_food * 100
delta_alcohol <- (oct$alcoholic_beverages - sep$alcoholic_beverages) / sep$alcoholic_beverages * 100

cat("Month-over-month change at treatment (Oct vs Sep 2019):\n")
cat(sprintf("  Eating out:    %+.2f%%\n", delta_eating))
cat(sprintf("  Cooked food:   %+.2f%%\n", delta_cooked))
cat(sprintf("  Alcohol:       %+.2f%%\n", delta_alcohol))
cat(sprintf("  Differential:  %+.2f%% (eating_out - cooked_food)\n",
            delta_eating - delta_cooked))
cat(sprintf("  Predicted:     +1.85%% (full pass-through of 2/108)\n"))
cat(sprintf("  Pass-through:  %.0f%%\n",
            (delta_eating - delta_cooked) / 1.85 * 100))

# Year-over-year comparison (Oct 2019 vs Oct 2018)
oct18 <- cpi[yyyymm == 201810]
yoy_eating <- (oct$eating_out - oct18$eating_out) / oct18$eating_out * 100
yoy_cooked <- (oct$cooked_food - oct18$cooked_food) / oct18$cooked_food * 100
yoy_alcohol <- (oct$alcoholic_beverages - oct18$alcoholic_beverages) / oct18$alcoholic_beverages * 100

cat("\nYear-over-year change (Oct 2019 vs Oct 2018):\n")
cat(sprintf("  Eating out:    %+.2f%%\n", yoy_eating))
cat(sprintf("  Cooked food:   %+.2f%%\n", yoy_cooked))
cat(sprintf("  Alcohol:       %+.2f%%\n", yoy_alcohol))

magnitude <- data.table(
  comparison = c("MoM (Oct vs Sep 2019)", "YoY (Oct 2019 vs Oct 2018)"),
  eating_out_pct = c(delta_eating, yoy_eating),
  cooked_food_pct = c(delta_cooked, yoy_cooked),
  alcohol_pct = c(delta_alcohol, yoy_alcohol),
  differential_pct = c(delta_eating - delta_cooked, yoy_eating - yoy_cooked),
  predicted_pct = 1.85,
  passthrough_pct = c((delta_eating - delta_cooked) / 1.85 * 100,
                      (yoy_eating - yoy_cooked) / 1.85 * 100)
)

fwrite(magnitude, file.path(data_dir, "magnitude_decomposition.csv"))
print(magnitude)

## ============================================================================
## Save Regression Results
## ============================================================================

# Save coefficient table for paper (Newey-West as primary for time-series)
benchmark <- log(1.10/1.08)
results <- data.table(
  Specification = c("DD Full Sample", "DD Pre-COVID", "DD COVID Control",
                     "DD Panel", "DDD", "DDD Pre-COVID"),
  Coefficient = c(coef(dd_full)["post"],
                  coef(dd_clean)["post"],
                  coef(dd_covid)["post"],
                  coef(dd_panel)["differential:post"],
                  coef(ddd)["is_eating_out:post"],
                  coef(ddd_clean)["is_eating_out:post"]),
  SE_NW = c(sqrt(diag(vcov(dd_full)))["post"],
            sqrt(diag(vcov(dd_clean)))["post"],
            sqrt(diag(vcov(dd_covid)))["post"],
            sqrt(diag(vcov(dd_panel)))["differential:post"],
            sqrt(diag(vcov(ddd)))["is_eating_out:post"],
            sqrt(diag(vcov(ddd_clean)))["is_eating_out:post"]),
  SE_HC1 = c(sqrt(diag(vcov(dd_full_hc1)))["post"],
             sqrt(diag(vcov(dd_clean_hc1)))["post"],
             sqrt(diag(vcov(dd_covid_hc1)))["post"],
             sqrt(diag(vcov(dd_panel)))["differential:post"],
             sqrt(diag(vcov(ddd)))["is_eating_out:post"],
             sqrt(diag(vcov(ddd_clean)))["is_eating_out:post"]),
  N = c(nobs(dd_full), nobs(dd_clean), nobs(dd_covid),
        nobs(dd_panel), nobs(ddd), nobs(ddd_clean))
)
results[, t_stat := Coefficient / SE_NW]
results[, p_value := 2 * pt(-abs(t_stat), df = N - 2)]
results[, stars := ifelse(p_value < 0.01, "***",
                   ifelse(p_value < 0.05, "**",
                   ifelse(p_value < 0.10, "*", "")))]
# Test of full pass-through: H0: beta = 0.0183
results[, t_full_pt := (Coefficient - benchmark) / SE_NW]
results[, p_full_pt := 2 * pt(-abs(t_full_pt), df = N - 2)]

fwrite(results, file.path(data_dir, "main_results.csv"))
print(results)

cat("\n✓ Main analysis complete.\n")
