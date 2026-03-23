# 04_robustness.R — Robustness checks
# apep_0839: TFP Revision and Food Security

source("00_packages.R")

this_dir <- tryCatch(
  dirname(rstudioapi::getSourceEditorContext()$path),
  error = function(e) {
    args <- commandArgs(trailingOnly = FALSE)
    file_arg <- grep("--file=", args, value = TRUE)
    if (length(file_arg) > 0) dirname(sub("--file=", "", file_arg))
    else getwd()
  }
)
setwd(this_dir)

data_dir <- "../data/"
panel <- fread(paste0(data_dir, "analysis_panel.csv"))
panel_clean <- panel[year != 2021]

cat("=== ROBUSTNESS CHECKS: APEP_0839 ===\n\n")

# ═══════════════════════════════════════════════════════════════
# 1. Alternative dosage measures
# ═══════════════════════════════════════════════════════════════
cat("--- 1. Alternative dosage: 2019 poverty rate ---\n")

# Use 2019 poverty rate instead of SNAP rate as dosage
panel_clean[, treat_poverty := post_tfp * poverty_rate_2019]

r1 <- feols(poverty_rate_pct ~ treat_poverty | fips + year,
            data = panel_clean, cluster = ~fips)
cat(sprintf("  Poverty dosage → Poverty: β=%.3f (%.3f)\n",
            coef(r1)["treat_poverty"], se(r1)["treat_poverty"]))

r1b <- feols(snap_rate_pct ~ treat_poverty | fips + year,
             data = panel_clean, cluster = ~fips)
cat(sprintf("  Poverty dosage → SNAP: β=%.3f (%.3f)\n",
            coef(r1b)["treat_poverty"], se(r1b)["treat_poverty"]))

# ═══════════════════════════════════════════════════════════════
# 2. Placebo test: Pre-treatment fake shock at 2018
# ═══════════════════════════════════════════════════════════════
cat("\n--- 2. Placebo test: fake treatment at 2019 ---\n")

# Restrict to pre-treatment period (2017-2019)
# Set fake treatment at 2019
panel_pre <- panel[year <= 2019]
panel_pre[, fake_post := fifelse(year >= 2019, 1L, 0L)]
panel_pre[, fake_treat := fake_post * snap_rate_2019]

r2_pov <- feols(poverty_rate_pct ~ fake_treat | fips + year,
                data = panel_pre, cluster = ~fips)
r2_snap <- feols(snap_rate_pct ~ fake_treat | fips + year,
                 data = panel_pre, cluster = ~fips)

cat(sprintf("  Placebo poverty: β=%.3f (%.3f), p=%.3f\n",
            coef(r2_pov)["fake_treat"], se(r2_pov)["fake_treat"],
            pvalue(r2_pov)["fake_treat"]))
cat(sprintf("  Placebo SNAP: β=%.3f (%.3f), p=%.3f\n",
            coef(r2_snap)["fake_treat"], se(r2_snap)["fake_treat"],
            pvalue(r2_snap)["fake_treat"]))

# ═══════════════════════════════════════════════════════════════
# 3. Exclude outlier states
# ═══════════════════════════════════════════════════════════════
cat("\n--- 3. Exclude extreme-dosage states ---\n")

# Drop top/bottom 10% of SNAP rate distribution
q10 <- quantile(panel_clean$snap_rate_2019, 0.10)
q90 <- quantile(panel_clean$snap_rate_2019, 0.90)
panel_trim <- panel_clean[snap_rate_2019 > q10 & snap_rate_2019 < q90]

r3_pov <- feols(poverty_rate_pct ~ treat_intensity | fips + year,
                data = panel_trim, cluster = ~fips)
r3_snap <- feols(snap_rate_pct ~ treat_intensity | fips + year,
                 data = panel_trim, cluster = ~fips)

cat(sprintf("  Trimmed poverty: β=%.3f (%.3f) [N=%d states]\n",
            coef(r3_pov)["treat_intensity"], se(r3_pov)["treat_intensity"],
            uniqueN(panel_trim$fips)))
cat(sprintf("  Trimmed SNAP: β=%.3f (%.3f)\n",
            coef(r3_snap)["treat_intensity"], se(r3_snap)["treat_intensity"]))

# ═══════════════════════════════════════════════════════════════
# 4. Leave-one-out (jackknife) sensitivity
# ═══════════════════════════════════════════════════════════════
cat("\n--- 4. Leave-one-out sensitivity ---\n")

states <- unique(panel_clean$fips)
loo_coefs <- numeric(length(states))
for (i in seq_along(states)) {
  dt_loo <- panel_clean[fips != states[i]]
  m_loo <- feols(poverty_rate_pct ~ treat_intensity | fips + year,
                 data = dt_loo, cluster = ~fips)
  loo_coefs[i] <- coef(m_loo)["treat_intensity"]
}

cat(sprintf("  LOO coefficients: mean=%.3f, min=%.3f, max=%.3f, SD=%.4f\n",
            mean(loo_coefs), min(loo_coefs), max(loo_coefs), sd(loo_coefs)))

# Identify most influential state
most_inf <- states[which.max(abs(loo_coefs - mean(loo_coefs)))]
cat(sprintf("  Most influential state: %s\n", most_inf))

# ═══════════════════════════════════════════════════════════════
# 5. State-specific time trends
# ═══════════════════════════════════════════════════════════════
cat("\n--- 5. State-specific linear time trends ---\n")

panel_clean[, time_trend := year - 2019]

r5_pov <- feols(poverty_rate_pct ~ treat_intensity | fips[time_trend] + year,
                data = panel_clean, cluster = ~fips)
r5_snap <- feols(snap_rate_pct ~ treat_intensity | fips[time_trend] + year,
                 data = panel_clean, cluster = ~fips)

cat(sprintf("  With state trends, poverty: β=%.3f (%.3f)\n",
            coef(r5_pov)["treat_intensity"], se(r5_pov)["treat_intensity"]))
cat(sprintf("  With state trends, SNAP: β=%.3f (%.3f)\n",
            coef(r5_snap)["treat_intensity"], se(r5_snap)["treat_intensity"]))

# ═══════════════════════════════════════════════════════════════
# 6. Conley standard errors (spatial correlation)
# ═══════════════════════════════════════════════════════════════
cat("\n--- 6. Alternative SEs: two-way clustering ---\n")

# Two-way clustering: state and year
r6_pov <- feols(poverty_rate_pct ~ treat_intensity | fips + year,
                data = panel_clean, cluster = ~fips + year)

r6_base <- feols(poverty_rate_pct ~ treat_intensity | fips + year,
                 data = panel_clean, cluster = ~fips)

cat(sprintf("  Poverty: β=%.3f, one-way SE=%.3f, two-way SE=%.3f\n",
            coef(r6_pov)["treat_intensity"],
            se(r6_base)["treat_intensity"],
            se(r6_pov)["treat_intensity"]))

# ═══════════════════════════════════════════════════════════════
# Save robustness results
# ═══════════════════════════════════════════════════════════════

save(r1, r1b, r2_pov, r2_snap, r3_pov, r3_snap, r5_pov, r5_snap, r6_pov, r6_base,
     loo_coefs, most_inf,
     file = paste0(data_dir, "robustness_results.RData"))

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
