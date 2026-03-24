## 03_main_analysis.R — Primary regressions
source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")

cat("=== Main Analysis ===\n")
cat("Panel:", nrow(df), "obs;", uniqueN(df$statefips), "states;",
    uniqueN(df$year), "years;", uniqueN(df$agi_bracket), "brackets\n\n")

## ------------------------------------------------------------------
## 1. SALT Cap Triple-Difference (main specification)
## ------------------------------------------------------------------
cat("--- Specification 1: SALT Cap Triple-Difference ---\n")

# Y_{s,t,b} = β(HighSALT_s × Post2018_t × HighIncome_b) + FE + ε
# FE: state×bracket, year×bracket, state×year
# This is the cleanest design: within-state, across-bracket variation

m1_triple <- feols(
  net_mig_rate ~ high_salt_post +
    high_post + i(high_salt, post_salt) + i(high_income, high_salt) |
    state_bracket + year_bracket + state_year,
  data = df,
  cluster = ~statefips
)
cat("Triple-diff (HighSALT × Post × HighIncome):\n")
summary(m1_triple)

## ------------------------------------------------------------------
## 2. Continuous SALT Exposure (dose-response)
## ------------------------------------------------------------------
cat("\n--- Specification 2: Continuous SALT Dose-Response ---\n")

m2_dose <- feols(
  net_mig_rate ~ salt_post_high + salt_post + high_post |
    state_bracket + year_bracket + state_year,
  data = df,
  cluster = ~statefips
)
cat("Dose-response (SALT_z × Post × HighIncome):\n")
summary(m2_dose)

## ------------------------------------------------------------------
## 3. Bracket-by-bracket SALT effects
## ------------------------------------------------------------------
cat("\n--- Specification 3: Bracket-Specific SALT Effects ---\n")

# Estimate bracket-specific SALT effects using pooled model with bracket interactions
# This uses the SAME state×year FE structure as the main DDD (reviewer feedback)
# Interact salt_z × post_salt with bracket dummies, bracket 4 ($50-75K) as reference
df[, bracket_f := factor(agi_bracket)]
m_gradient <- feols(
  net_mig_rate ~ i(bracket_f, salt_z * post_salt, ref = "4") | statefips^agi_bracket + year^agi_bracket + statefips^year,
  data = df,
  cluster = ~statefips
)
cat("Pooled gradient model:\n")
summary(m_gradient)

# Extract bracket-specific SALT×Post effects relative to bracket 4
bracket_results <- list()
for (b in 1:7) {
  if (b == 4) {
    # Reference category — coefficient is 0 by construction
    # Use separate regression for this bracket to get the level
    bdf <- df[agi_bracket == b]
    mb <- feols(net_mig_rate ~ salt_z:post_salt | statefips + year,
                data = bdf, cluster = ~statefips)
    bracket_results[[b]] <- data.table(
      bracket = b,
      label = levels(df$bracket_label)[b],
      coef = coef(mb)["salt_z:post_salt"],
      se = sqrt(vcov(mb)["salt_z:post_salt", "salt_z:post_salt"]),
      nobs = nobs(mb)
    )
  } else {
    bdf <- df[agi_bracket == b]
    mb <- feols(net_mig_rate ~ salt_z:post_salt | statefips + year,
                data = bdf, cluster = ~statefips)
    bracket_results[[b]] <- data.table(
      bracket = b,
      label = levels(df$bracket_label)[b],
      coef = coef(mb)["salt_z:post_salt"],
      se = sqrt(vcov(mb)["salt_z:post_salt", "salt_z:post_salt"]),
      nobs = nobs(mb)
    )
  }
  cat("  Bracket", b, "(", levels(df$bracket_label)[b], "):",
      round(bracket_results[[b]]$coef, 5), "\n")
}
bracket_dt <- rbindlist(bracket_results)
bracket_dt[, ci_lo := coef - 1.96 * se]
bracket_dt[, ci_hi := coef + 1.96 * se]

cat("\nIncome Gradient of Migration Response to SALT Cap:\n")
print(bracket_dt[, .(bracket, label, coef = round(coef, 5),
                      se = round(se, 5), sig = fifelse(abs(coef/se) > 1.96, "**",
                                                        fifelse(abs(coef/se) > 1.65, "*", "")))])

## ------------------------------------------------------------------
## 4. Outflow vs Inflow Decomposition
## ------------------------------------------------------------------
cat("\n--- Specification 4: Outflow vs Inflow Decomposition ---\n")

m4_out <- feols(
  outflow_rate ~ high_salt_post + high_post + i(high_salt, post_salt) + i(high_income, high_salt) |
    state_bracket + year_bracket + state_year,
  data = df,
  cluster = ~statefips
)

m4_in <- feols(
  inflow_rate ~ high_salt_post + high_post + i(high_salt, post_salt) + i(high_income, high_salt) |
    state_bracket + year_bracket + state_year,
  data = df,
  cluster = ~statefips
)

cat("Outflow (HighSALT × Post × HighIncome):", round(coef(m4_out)["high_salt_post"], 5), "\n")
cat("Inflow (HighSALT × Post × HighIncome):", round(coef(m4_in)["high_salt_post"], 5), "\n")

## ------------------------------------------------------------------
## 5. Summary statistics for the paper
## ------------------------------------------------------------------
cat("\n--- Summary Statistics ---\n")

# Overall
cat("Net migration rate: mean =", round(mean(df$net_mig_rate, na.rm = TRUE), 5),
    "sd =", round(sd(df$net_mig_rate, na.rm = TRUE), 5), "\n")

# By bracket
sumstats <- df[, .(
  mean_net_mig = mean(net_mig_rate, na.rm = TRUE),
  sd_net_mig = sd(net_mig_rate, na.rm = TRUE),
  mean_outflow = mean(outflow_rate, na.rm = TRUE),
  mean_inflow = mean(inflow_rate, na.rm = TRUE),
  mean_total_returns = mean(total_returns, na.rm = TRUE),
  n_obs = .N
), by = .(agi_bracket, bracket_label)]
setorder(sumstats, agi_bracket)

cat("\nSummary by AGI Bracket:\n")
print(sumstats)

## ------------------------------------------------------------------
## 6. Save results
## ------------------------------------------------------------------
# Store key objects for tables/robustness
saveRDS(list(
  m1_triple = m1_triple,
  m2_dose = m2_dose,
  bracket_dt = bracket_dt,
  m4_out = m4_out,
  m4_in = m4_in,
  sumstats = sumstats
), "../data/main_results.rds")

# Diagnostics for validator
# Triple-diff: treated cells are state×bracket pairs where high_salt=1
# 9 high-SALT states × 7 brackets = 63 treated state-bracket cells
diag <- list(
  n_treated = uniqueN(df[high_salt == 1, .(statefips, agi_bracket)]),
  n_pre = length(unique(df[year < 2018, year])),
  n_obs = nrow(df)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\nDiagnostics:", paste(names(diag), unlist(diag), sep = "=", collapse = ", "), "\n")
cat("=== Main analysis complete ===\n")
