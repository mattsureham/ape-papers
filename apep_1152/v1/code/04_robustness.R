## 04_robustness.R — The Stranded Signal (apep_1152)
source(file.path(here::here(), "output", "apep_1152", "v1", "code", "00_packages.R"))
DATA_DIR <- file.path(here::here(), "output", "apep_1152", "v1", "data")

panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
load(file.path(DATA_DIR, "main_results.RData"))

cat("=== ROBUSTNESS CHECKS ===\n\n")

# =============================================================================
# R1. POWER / MDE ANALYSIS
# =============================================================================
cat("--- R1: Minimum Detectable Effect ---\n")
# SE from CS DiD is 0.016. MDE at 80% power, alpha=0.05 = 2.8 * SE
mde <- 2.8 * agg_overall$overall.se
baseline_rate <- mean(panel$retired_this_year[panel$ces_year == 0], na.rm = TRUE)
cat(sprintf("CS DiD SE: %.4f\n", agg_overall$overall.se))
cat(sprintf("MDE (80%% power): %.4f (%.1f%% of baseline rate %.4f)\n",
            mde, 100 * mde / baseline_rate, baseline_rate))
cat(sprintf("95%% CI: [%.4f, %.4f]\n",
            agg_overall$overall.att - 1.96 * agg_overall$overall.se,
            agg_overall$overall.att + 1.96 * agg_overall$overall.se))
cat(sprintf("Can rule out effects larger than %.1fpp\n",
            1.96 * agg_overall$overall.se * 100))

# =============================================================================
# R2. COMPOSITION DECOMPOSITION
# =============================================================================
cat("\n--- R2: Composition Decomposition ---\n")

# Show that CES vs non-CES generators differ on observables
panel[, ces_state := as.integer(ces_year > 0)]
baseline <- panel[year == 2008]

cat("Generator characteristics at baseline (2008):\n")
cat(sprintf("  Capacity: CES=%.0f MW, No-CES=%.0f MW (diff=%.0f, p=%.4f)\n",
            mean(baseline[ces_state == 1]$capacity_mw, na.rm = TRUE),
            mean(baseline[ces_state == 0]$capacity_mw, na.rm = TRUE),
            mean(baseline[ces_state == 1]$capacity_mw, na.rm = TRUE) -
              mean(baseline[ces_state == 0]$capacity_mw, na.rm = TRUE),
            t.test(capacity_mw ~ ces_state, data = baseline)$p.value))

cat(sprintf("  Vintage: CES=%.1f yrs, No-CES=%.1f yrs (diff=%.1f, p=%.4f)\n",
            mean(baseline[ces_state == 1]$vintage, na.rm = TRUE),
            mean(baseline[ces_state == 0]$vintage, na.rm = TRUE),
            mean(baseline[ces_state == 1]$vintage, na.rm = TRUE) -
              mean(baseline[ces_state == 0]$vintage, na.rm = TRUE),
            t.test(vintage ~ ces_state, data = baseline)$p.value))

# TWFE with generator controls
cat("\nTWFE with controls:\n")
twfe_base <- feols(retired_this_year ~ post_ces | gen_key + year,
                   data = panel, cluster = ~state)
twfe_ctrl <- feols(retired_this_year ~ post_ces + capacity_mw + vintage |
                     gen_key + year,
                   data = panel, cluster = ~state)
cat(sprintf("  Without controls: %.4f (SE: %.4f)\n",
            coef(twfe_base)["post_ces"], se(twfe_base)["post_ces"]))
cat(sprintf("  With controls: %.4f (SE: %.4f)\n",
            coef(twfe_ctrl)["post_ces"], se(twfe_ctrl)["post_ces"]))

# =============================================================================
# R3. REWEIGHTED/MATCHED SAMPLE
# =============================================================================
cat("\n--- R3: Reweighted by capacity ---\n")

# Weight by inverse capacity to down-weight small generators
panel[, wt := 1 / (capacity_mw + 1)]
twfe_wt <- feols(retired_this_year ~ post_ces | gen_key + year,
                 data = panel, cluster = ~state, weights = ~wt)
cat(sprintf("Capacity-weighted TWFE: %.4f (SE: %.4f)\n",
            coef(twfe_wt)["post_ces"], se(twfe_wt)["post_ces"]))

# =============================================================================
# R4. EXCLUDING SMALL STATES
# =============================================================================
cat("\n--- R4: Excluding small CES states (<10 generators) ---\n")
small_ces <- panel[ces_year > 0, .N, by = state][N < 10 * 17]$state  # less than 10 gen-years per year
panel_big <- panel[!(state %in% small_ces & ces_year > 0)]
twfe_big <- feols(retired_this_year ~ post_ces | gen_key + year,
                  data = panel_big, cluster = ~state)
cat(sprintf("Excl. small CES states: %.4f (SE: %.4f)\n",
            coef(twfe_big)["post_ces"], se(twfe_big)["post_ces"]))

# =============================================================================
# R5. HAZARD MODEL
# =============================================================================
cat("\n--- R5: Cox proportional hazard ---\n")
if (requireNamespace("survival", quietly = TRUE)) {
  library(survival)
  # Duration = years from operating start to retirement (or censored at 2024)
  hazard_dt <- unique(panel[, .(gen_key, state, ces_year, capacity_mw, op_year,
                                 ret_year, vintage = 2024 - op_year)])
  hazard_dt[, `:=`(
    duration = ifelse(is.na(ret_year), 2024 - op_year, ret_year - op_year),
    event = as.integer(!is.na(ret_year)),
    ces_state = as.integer(ces_year > 0)
  )]
  hazard_dt <- hazard_dt[duration > 0]

  cox <- coxph(Surv(duration, event) ~ ces_state + capacity_mw + strata(state),
               data = hazard_dt)
  cat(sprintf("Cox hazard ratio for CES state: %.3f (p=%.4f)\n",
              exp(coef(cox)["ces_state"]),
              summary(cox)$coefficients["ces_state", "Pr(>|z|)"]))
}

# Save
save(twfe_base, twfe_ctrl, twfe_wt,
     file = file.path(DATA_DIR, "robustness_results.RData"))
cat("\nRobustness results saved.\n")
