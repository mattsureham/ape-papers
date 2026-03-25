# 03_main_analysis.R — Main regressions
# apep_0937: Grenfell fire and fire safety industry formation

source("00_packages.R")

data_dir <- "../data/"
tables_dir <- "../tables/"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "panel.csv"))
panel[, inc_ym := as.Date(inc_ym)]
panel[, la_code := as.factor(la_code)]

cat("Panel loaded:", nrow(panel), "obs,", uniqueN(panel$la_code), "LAs,",
    uniqueN(panel$inc_ym), "months\n")

# ===========================================================================
# 1. Descriptive statistics
# ===========================================================================
cat("\n=== Descriptive Statistics ===\n")

# National time series: total monthly fire safety incorporations
national <- panel[, .(
  fire_total = sum(fire_incorp),
  control_total = sum(control_incorp),
  n_las = .N
), by = inc_ym]

pre_mean <- national[inc_ym < "2017-06-01", mean(fire_total)]
post_mean <- national[inc_ym >= "2017-07-01", mean(fire_total)]
cat("National monthly fire safety incorporations:\n")
cat("  Pre-Grenfell (2008-2017Q2):", round(pre_mean, 1), "\n")
cat("  Post-Grenfell (2017Q3-2024):", round(post_mean, 1), "\n")
cat("  Ratio:", round(post_mean / pre_mean, 2), "x\n")

pre_ctrl <- national[inc_ym < "2017-06-01", mean(control_total)]
post_ctrl <- national[inc_ym >= "2017-07-01", mean(control_total)]
cat("National monthly control construction incorporations:\n")
cat("  Pre-Grenfell:", round(pre_ctrl, 1), "\n")
cat("  Post-Grenfell:", round(post_ctrl, 1), "\n")
cat("  Ratio:", round(post_ctrl / pre_ctrl, 2), "x\n")

# ===========================================================================
# 2. Main DiD specification: fire safety incorporations
# ===========================================================================
cat("\n=== Main DiD Regressions ===\n")

# Model 1: Basic DiD with LA and month FE
m1 <- feols(fire_incorp ~ treat_x_post | la_code + inc_ym,
            data = panel, cluster = ~la_code)

# Model 2: Add controls (control SIC incorporations as proxy for local business conditions)
m2 <- feols(fire_incorp ~ treat_x_post + control_incorp | la_code + inc_ym,
            data = panel, cluster = ~la_code)

# Model 3: Log specification
m3 <- feols(log_fire ~ treat_x_post | la_code + inc_ym,
            data = panel, cluster = ~la_code)

# Model 4: Poisson (count data)
m4 <- fepois(fire_incorp ~ treat_x_post | la_code + inc_ym,
             data = panel, cluster = ~la_code)

cat("\n--- Model 1: Basic DiD ---\n")
cat("  β (FlatShare × Post):", round(coef(m1)["treat_x_post"], 4), "\n")
cat("  SE:", round(se(m1)["treat_x_post"], 4), "\n")
cat("  p-value:", round(pvalue(m1)["treat_x_post"], 4), "\n")
cat("  N:", nobs(m1), "\n")

cat("\n--- Model 2: With control SIC ---\n")
cat("  β (FlatShare × Post):", round(coef(m2)["treat_x_post"], 4), "\n")
cat("  SE:", round(se(m2)["treat_x_post"], 4), "\n")

cat("\n--- Model 3: Log specification ---\n")
cat("  β (FlatShare × Post):", round(coef(m3)["treat_x_post"], 4), "\n")
cat("  SE:", round(se(m3)["treat_x_post"], 4), "\n")

cat("\n--- Model 4: Poisson ---\n")
cat("  β (FlatShare × Post):", round(coef(m4)["treat_x_post"], 4), "\n")
cat("  SE:", round(se(m4)["treat_x_post"], 4), "\n")

# ===========================================================================
# 3. Placebo: control construction SICs
# ===========================================================================
cat("\n=== Placebo: Control Construction SICs ===\n")

m_placebo <- feols(control_incorp ~ treat_x_post | la_code + inc_ym,
                   data = panel, cluster = ~la_code)

cat("  β (FlatShare × Post) on control SICs:", round(coef(m_placebo)["treat_x_post"], 4), "\n")
cat("  SE:", round(se(m_placebo)["treat_x_post"], 4), "\n")
cat("  p-value:", round(pvalue(m_placebo)["treat_x_post"], 4), "\n")

# ===========================================================================
# 4. Event study specification
# ===========================================================================
cat("\n=== Event Study ===\n")

# Bin months relative to Grenfell into half-years for power
panel[, period_bin := floor(months_since / 6)]

# Reference period: -1 (6 months before Grenfell)
panel[, period_bin_f := relevel(factor(period_bin), ref = as.character(-1))]

# Event study: interact flat_share with period bins
es_model <- feols(fire_incorp ~ i(period_bin, flat_share, ref = -1) | la_code + inc_ym,
                  data = panel, cluster = ~la_code)

cat("Event study coefficients (selected):\n")
es_coefs <- coeftable(es_model)
# Print pre-treatment and early post-treatment coefficients
for (rn in rownames(es_coefs)) {
  if (grepl("period_bin", rn)) {
    p <- as.numeric(gsub(".*::([-0-9]+):.*", "\\1", rn))
    if (p >= -5 & p <= 5) {
      cat(sprintf("  Period %+d: β = %7.4f (SE = %6.4f)\n",
                  p, es_coefs[rn, 1], es_coefs[rn, 2]))
    }
  }
}

# Save event study results for table
es_results <- data.table(
  period = as.numeric(gsub(".*::([-0-9]+):.*", "\\1", rownames(es_coefs))),
  coef = es_coefs[, 1],
  se = es_coefs[, 2],
  pval = es_coefs[, 4]
)
es_results[, ci_lo := coef - 1.96 * se]
es_results[, ci_hi := coef + 1.96 * se]
fwrite(es_results, file.path(data_dir, "event_study_results.csv"))

# ===========================================================================
# 5. Regulatory milestone analysis
# ===========================================================================
cat("\n=== Regulatory Milestone Analysis ===\n")

# Create indicators for each regulatory phase
panel[, phase := fcase(
  inc_ym < "2017-07-01", "Pre-Grenfell",
  inc_ym >= "2017-07-01" & inc_ym < "2018-01-01", "Phase 1: Fire (Jul-Dec 2017)",
  inc_ym >= "2018-01-01" & inc_ym < "2020-01-01", "Phase 2: Hackitt (2018-2019)",
  inc_ym >= "2020-01-01" & inc_ym < "2021-11-01", "Phase 3: EWS1 (2020-2021)",
  inc_ym >= "2021-11-01", "Phase 4: BSA (2021-2024)"
)]

panel[, phase_f := factor(phase, levels = c(
  "Pre-Grenfell",
  "Phase 1: Fire (Jul-Dec 2017)",
  "Phase 2: Hackitt (2018-2019)",
  "Phase 3: EWS1 (2020-2021)",
  "Phase 4: BSA (2021-2024)"
))]

m_phases <- feols(fire_incorp ~ i(phase_f, flat_share, ref = "Pre-Grenfell") | la_code + inc_ym,
                  data = panel, cluster = ~la_code)

cat("Regulatory phase coefficients:\n")
phase_coefs <- coeftable(m_phases)
for (rn in rownames(phase_coefs)) {
  cat(sprintf("  %s: β = %.4f (SE = %.4f, p = %.4f)\n",
              rn, phase_coefs[rn, 1], phase_coefs[rn, 2], phase_coefs[rn, 4]))
}

# ===========================================================================
# 6. Save key results for diagnostics
# ===========================================================================
n_treated_above_median <- uniqueN(panel[flat_share > median(panel$flat_share, na.rm = TRUE)]$la_code)
n_pre <- length(unique(panel[inc_ym < "2017-07-01"]$inc_ym))

diagnostics <- list(
  n_treated = n_treated_above_median,
  n_pre = n_pre,
  n_obs = nrow(panel),
  n_las = uniqueN(panel$la_code),
  n_months = uniqueN(panel$inc_ym),
  mean_fire_pre = pre_mean,
  mean_fire_post = post_mean,
  main_coef = as.numeric(coef(m1)["treat_x_post"]),
  main_se = as.numeric(se(m1)["treat_x_post"]),
  main_pval = as.numeric(pvalue(m1)["treat_x_post"]),
  placebo_coef = as.numeric(coef(m_placebo)["treat_x_post"]),
  placebo_pval = as.numeric(pvalue(m_placebo)["treat_x_post"]),
  sd_y_pre = sd(panel[post_grenfell == 0]$fire_incorp, na.rm = TRUE)
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE, pretty = TRUE)
cat("\nDiagnostics saved.\n")

# Save regression objects for table construction
save(m1, m2, m3, m4, m_placebo, m_phases, es_model, panel,
     file = file.path(data_dir, "regression_results.RData"))
cat("Regression results saved.\n")
