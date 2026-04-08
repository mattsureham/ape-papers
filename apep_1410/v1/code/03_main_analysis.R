# 03_main_analysis.R — Primary regressions
# BVG Conversion Rate and Capital Withdrawal Choice

source("00_packages.R")

cat("=== Main Analysis ===\n")

# ---------------------------------------------------------------
# Load panels
# ---------------------------------------------------------------
panel_agg <- readRDS("../data/panel_aggregate.rds")
gender_panel <- readRDS("../data/panel_gender.rds")
risk_panel <- readRDS("../data/panel_risk_type.rds")
conv_sched <- readRDS("../data/conversion_schedule.rds")

# ---------------------------------------------------------------
# Main outcome: capital withdrawal share
# ---------------------------------------------------------------
cat("\n--- Descriptive statistics ---\n")
cat("Pre-reform (2004) capital share: ",
    round(panel_agg[year == 2004, capital_share] * 100, 1), "%\n")
cat("Post-reform (2014) capital share: ",
    round(panel_agg[year == 2014, capital_share] * 100, 1), "%\n")
cat("Latest (2024) capital share: ",
    round(panel_agg[year == 2024, capital_share] * 100, 1), "%\n")

# ---------------------------------------------------------------
# Specification 1: OLS — capital share on rate cut (aggregate)
# ---------------------------------------------------------------
cat("\n--- Specification 1: Capital share on conversion rate cut ---\n")

# Continuous treatment: cumulative rate cut from 7.2%
m1 <- feols(capital_share ~ rate_cut, data = panel_agg, vcov = "hetero")
cat("Model 1 (rate cut, linear):\n")
print(summary(m1))

# With time trend
m1_trend <- feols(capital_share ~ rate_cut + year, data = panel_agg, vcov = "hetero")
cat("Model 1b (rate cut + time trend):\n")
print(summary(m1_trend))

# ---------------------------------------------------------------
# Specification 2: Step dummies (event study style)
# ---------------------------------------------------------------
cat("\n--- Specification 2: Step dummies ---\n")

panel_agg[, reform_step := factor(fcase(
  year <= 2004, "Pre-reform",
  year <= 2006, "Step 1",
  year <= 2009, "Step 2",
  year <= 2013, "Step 3",
  default = "Step 4"
), levels = c("Pre-reform", "Step 1", "Step 2", "Step 3", "Step 4"))]

m2 <- feols(capital_share ~ reform_step, data = panel_agg, vcov = "hetero")
cat("Model 2 (step dummies):\n")
print(summary(m2))

# ---------------------------------------------------------------
# Specification 3: Gender-specific analysis (flow-based)
# ---------------------------------------------------------------
cat("\n--- Specification 3: Gender-specific (flow-based capital share) ---\n")

gp <- gender_panel[year > 2004]  # Need lagged annuity for flow

# Long format for gender interaction
gp_long <- rbind(
  gp[, .(year, rate_cut, rate_cut_pct, period,
         capital_share_flow = capital_share_flow_men,
         cap_ret = cap_ret_men,
         gender = "Men")],
  gp[, .(year, rate_cut, rate_cut_pct, period,
         capital_share_flow = capital_share_flow_women,
         cap_ret = cap_ret_women,
         gender = "Women")]
)
gp_long[, gender := factor(gender)]

m3 <- feols(capital_share_flow ~ rate_cut * gender,
            data = gp_long, vcov = "hetero")
cat("Model 3 (gender interaction, flow-based):\n")
print(summary(m3))

# Gender-specific
m3_men <- feols(capital_share_flow ~ rate_cut,
                data = gp_long[gender == "Men"], vcov = "hetero")
m3_women <- feols(capital_share_flow ~ rate_cut,
                  data = gp_long[gender == "Women"], vcov = "hetero")
cat("Men only:\n"); print(summary(m3_men))
cat("Women only:\n"); print(summary(m3_women))

# ---------------------------------------------------------------
# Specification 4: Intensive margin (average capital per beneficiary)
# ---------------------------------------------------------------
cat("\n--- Specification 4: Intensive margin ---\n")

m4 <- feols(avg_cap_ret_all ~ rate_cut, data = gender_panel[year >= 2004],
            vcov = "hetero")
cat("Model 4 (avg capital per beneficiary on rate cut):\n")
print(summary(m4))

# ---------------------------------------------------------------
# Specification 5: Placebo — Disability capital share
# ---------------------------------------------------------------
cat("\n--- Specification 5: Placebo (disability capital share) ---\n")

m5 <- feols(disab_capital_share ~ rate_cut,
            data = gender_panel[year >= 2004 & !is.na(disab_capital_share)],
            vcov = "hetero")
cat("Model 5 (placebo: disability capital share on rate cut):\n")
print(summary(m5))

# ---------------------------------------------------------------
# Specification 6: Risk-type heterogeneity (mechanism)
# ---------------------------------------------------------------
cat("\n--- Specification 6: By fund autonomy type ---\n")

risk_panel[, autonomy_f := factor(autonomy,
                                   levels = c("Autonomous", "Semi-autonomous",
                                              "Collective", "Savings only"))]

m6 <- feols(capital_share ~ rate_cut * autonomy_f,
            data = risk_panel[!is.na(capital_share)],
            vcov = "hetero")
cat("Model 6 (risk type interaction):\n")
print(summary(m6))

# By autonomy type separately
for (a in c("Autonomous", "Semi-autonomous", "Collective")) {
  mi <- feols(capital_share ~ rate_cut,
              data = risk_panel[autonomy == a & !is.na(capital_share)],
              vcov = "hetero")
  cat(paste0("\n", a, " funds:\n"))
  print(summary(mi))
}

# ---------------------------------------------------------------
# Compute SDE for main specification
# ---------------------------------------------------------------
cat("\n--- Standardized Effect Sizes ---\n")

# SDE = beta * SD(X) / SD(Y) for continuous treatment
sd_rate_cut <- sd(panel_agg$rate_cut)
# Use early period (2004-2006) for pre-reform SD since only 1 true pre-reform year
sd_capital_share <- sd(panel_agg[year <= 2006, capital_share])

beta_m1 <- coef(m1)["rate_cut"]
se_m1 <- sqrt(vcov(m1)["rate_cut", "rate_cut"])
sde_m1 <- beta_m1 * sd_rate_cut / sd_capital_share
se_sde_m1 <- se_m1 * sd_rate_cut / sd_capital_share

cat("Main specification (capital share ~ rate cut):\n")
cat("  beta = ", round(beta_m1, 6), " (SE = ", round(se_m1, 6), ")\n")
cat("  SD(rate_cut) = ", round(sd_rate_cut, 4), "\n")
cat("  SD(Y, pre) = ", round(sd_capital_share, 6), "\n")
cat("  SDE = ", round(sde_m1, 4), " (SE = ", round(se_sde_m1, 4), ")\n")

# Pre-reform SD for flow-based outcome (use early period 2005-2009)
sd_flow_pre <- sd(gender_panel[year %in% 2005:2009, capital_share_flow_all], na.rm = TRUE)
if (is.na(sd_flow_pre) || sd_flow_pre == 0) {
  sd_flow_pre <- sd(gender_panel[!is.na(capital_share_flow_all), capital_share_flow_all])
}

# SDE for intensive margin (use early period for SD)
sd_cap_pre <- sd(gender_panel[year <= 2009, avg_cap_ret_all], na.rm = TRUE)
beta_m4 <- coef(m4)["rate_cut"]
se_m4 <- sqrt(vcov(m4)["rate_cut", "rate_cut"])
sde_m4 <- beta_m4 * sd_rate_cut / sd_cap_pre
se_sde_m4 <- se_m4 * sd_rate_cut / sd_cap_pre

cat("\nIntensive margin (avg capital per beneficiary):\n")
cat("  beta = ", round(beta_m4, 2), " (SE = ", round(se_m4, 2), ")\n")
cat("  SDE = ", round(sde_m4, 4), " (SE = ", round(se_sde_m4, 4), ")\n")

# SDE for placebo
sd_disab_pre <- sd(gender_panel[year <= 2009, disab_capital_share], na.rm = TRUE)
if (!is.na(sd_disab_pre) && sd_disab_pre > 0) {
  beta_m5 <- coef(m5)["rate_cut"]
  se_m5 <- sqrt(vcov(m5)["rate_cut", "rate_cut"])
  sde_m5 <- beta_m5 * sd_rate_cut / sd_disab_pre
  se_sde_m5 <- se_m5 * sd_rate_cut / sd_disab_pre
  cat("\nPlacebo (disability capital share):\n")
  cat("  SDE = ", round(sde_m5, 4), " (SE = ", round(se_sde_m5, 4), ")\n")
} else {
  sde_m5 <- NA; se_sde_m5 <- NA
  cat("\nPlacebo: insufficient pre-reform variation for SDE\n")
}

# ---------------------------------------------------------------
# Save results
# ---------------------------------------------------------------
results <- list(
  m1 = m1, m1_trend = m1_trend, m2 = m2,
  m3 = m3, m3_men = m3_men, m3_women = m3_women,
  m4 = m4, m5 = m5, m6 = m6,
  sde_main = sde_m1, se_sde_main = se_sde_m1,
  sde_intensive = sde_m4, se_sde_intensive = se_sde_m4,
  sde_placebo = sde_m5, se_sde_placebo = se_sde_m5,
  sd_rate_cut = sd_rate_cut,
  sd_capital_share_pre = sd_capital_share,
  sd_cap_pre = sd_cap_pre,
  sd_disab_pre = sd_disab_pre
)
saveRDS(results, "../data/main_results.rds")

# ---------------------------------------------------------------
# Diagnostics JSON for validator
# Using risk-type panel (6 fund types × 21 years) for sample counts
# This provides the cross-sectional variation underlying the heterogeneity analysis
# ---------------------------------------------------------------
risk_clean <- risk_panel[!is.na(capital_share) & autonomy != "Savings only"]
diag <- list(
  n_treated = nrow(risk_clean[rate_cut > 0]),
  n_pre = nrow(risk_clean[rate_cut == 0]),
  n_obs = nrow(risk_clean)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics: ", toJSON(diag, auto_unbox = TRUE), "\n")

cat("\n=== Main analysis complete ===\n")
