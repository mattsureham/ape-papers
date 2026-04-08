# 04_robustness.R — Robustness checks
# BVG Conversion Rate and Capital Withdrawal Choice

source("00_packages.R")

cat("=== Robustness Checks ===\n")

# ---------------------------------------------------------------
# Load data
# ---------------------------------------------------------------
panel_agg <- readRDS("../data/panel_aggregate.rds")
gender_panel <- readRDS("../data/panel_gender.rds")
risk_panel <- readRDS("../data/panel_risk_type.rds")
results <- readRDS("../data/main_results.rds")

# ---------------------------------------------------------------
# 1. Pre-trend test: is there a trend 2004-2006 (before Step 2)?
# ---------------------------------------------------------------
cat("\n--- Robustness 1: Pre-trend / early period stability ---\n")

# Test: among the earliest period, is there already a trend?
early <- panel_agg[year <= 2006]
if (nrow(early) >= 3) {
  r1 <- lm(capital_share ~ year, data = early)
  cat("Linear trend 2004-2006:\n")
  print(summary(r1))
  cat("  Slope = ", round(coef(r1)["year"], 6),
      " (p = ", round(summary(r1)$coefficients["year", 4], 4), ")\n")
}

# ---------------------------------------------------------------
# 2. Structural break at each step
# ---------------------------------------------------------------
cat("\n--- Robustness 2: Structural breaks at reform steps ---\n")

panel_agg[, post_2005 := as.integer(year >= 2005)]
panel_agg[, post_2007 := as.integer(year >= 2007)]
panel_agg[, post_2010 := as.integer(year >= 2010)]
panel_agg[, post_2014 := as.integer(year >= 2014)]

r2 <- feols(capital_share ~ post_2005 + post_2007 + post_2010 + post_2014,
            data = panel_agg, vcov = "hetero")
cat("Structural breaks model:\n")
print(summary(r2))

# ---------------------------------------------------------------
# 3. Controlling for time trend
# ---------------------------------------------------------------
cat("\n--- Robustness 3: Rate cut with quadratic trend ---\n")

panel_agg[, year_c := year - 2004]
r3 <- feols(capital_share ~ rate_cut + year_c + I(year_c^2),
            data = panel_agg, vcov = "hetero")
cat("Rate cut with quadratic trend:\n")
print(summary(r3))

# ---------------------------------------------------------------
# 4. Capital amount share (instead of beneficiary share)
# ---------------------------------------------------------------
cat("\n--- Robustness 4: Capital amount share ---\n")

r4 <- feols(capital_amount_share ~ rate_cut,
            data = panel_agg, vcov = "hetero")
cat("Capital amount share on rate cut:\n")
print(summary(r4))

# ---------------------------------------------------------------
# 5. Post-2014 stability (rate constant at 6.8%)
# ---------------------------------------------------------------
cat("\n--- Robustness 5: Post-2014 stability ---\n")

post2014 <- panel_agg[year >= 2014]
r5 <- lm(capital_share ~ year, data = post2014)
cat("Linear trend 2014-2024 (constant rate period):\n")
print(summary(r5))
cat("  Slope = ", round(coef(r5)["year"], 6),
    " (p = ", round(summary(r5)$coefficients["year", 4], 4), ")\n")

# ---------------------------------------------------------------
# 6. Exclude outlier years (COVID-19: 2020)
# ---------------------------------------------------------------
cat("\n--- Robustness 6: Exclude 2020 (COVID) ---\n")

r6 <- feols(capital_share ~ rate_cut,
            data = panel_agg[year != 2020], vcov = "hetero")
cat("Excluding 2020:\n")
print(summary(r6))

# ---------------------------------------------------------------
# 7. Ratio of capital to annuity amount per beneficiary
# ---------------------------------------------------------------
cat("\n--- Robustness 7: Relative generosity ---\n")

panel_agg[, cap_annuity_ratio := avg_capital_per_ben / avg_annuity_per_ben]
r7 <- feols(cap_annuity_ratio ~ rate_cut,
            data = panel_agg[!is.na(cap_annuity_ratio)], vcov = "hetero")
cat("Capital/annuity per-beneficiary ratio:\n")
print(summary(r7))

# ---------------------------------------------------------------
# 8. By fund legal form (public vs private law)
# ---------------------------------------------------------------
cat("\n--- Robustness 8: Already captured in risk-type panel ---\n")
cat("See main analysis m6 for fund-type heterogeneity.\n")

# ---------------------------------------------------------------
# Save robustness results
# ---------------------------------------------------------------
rob_results <- list(
  r1_pretrend = if (exists("r1")) r1 else NULL,
  r2_breaks = r2,
  r3_quadtrend = r3,
  r4_amount_share = r4,
  r5_post2014 = r5,
  r6_excl_covid = r6,
  r7_generosity = r7
)
saveRDS(rob_results, "../data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
