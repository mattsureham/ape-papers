# 04_robustness.R — Robustness checks
# Section 60 Stop-and-Search Relaxation and Knife Crime

source("00_packages.R")

panel <- fread("../data/panel_analysis.csv")
panel[, date := as.Date(date)]
results <- readRDS("../data/results.rds")

cohort1_forces <- c("metropolitan", "west-midlands", "greater-manchester",
                    "merseyside", "south-yorkshire", "south-wales", "west-yorkshire")

# ── 1. WILD CLUSTER BOOTSTRAP ────────────────────────────────────────────
cat("=== WILD CLUSTER BOOTSTRAP ===\n")

# Main weapons result with wild bootstrap
main_ols <- lm(weapons_rate ~ treated + factor(force_id) + factor(t), data = panel)

set.seed(12345)
boot_result <- boottest(main_ols, param = "treated", clustid = ~force_id,
                        B = 9999, type = "webb")

cat(sprintf("Wild bootstrap p-value: %.4f\n", boot_result$p_val))
cat(sprintf("Wild bootstrap CI: [%.3f, %.3f]\n",
            boot_result$conf_int[1], boot_result$conf_int[2]))

# ── 2. LEAVE-ONE-OUT (Cohort 1 forces) ──────────────────────────────────
cat("\n=== LEAVE-ONE-OUT ===\n")

loo_results <- list()
for (drop_force in cohort1_forces) {
  panel_loo <- panel[force != drop_force]
  cs_loo <- att_gt(
    yname = "weapons_rate",
    tname = "t",
    idname = "force_id",
    gname = "g",
    data = as.data.frame(panel_loo),
    control_group = "notyettreated",
    anticipation = 0,
    base_period = "universal"
  )
  agg_loo <- aggte(cs_loo, type = "simple")
  loo_results[[drop_force]] <- list(
    dropped = drop_force,
    att = agg_loo$overall.att,
    se = agg_loo$overall.se
  )
  cat(sprintf("  Drop %s: ATT = %.3f (SE = %.3f)\n",
              drop_force, agg_loo$overall.att, agg_loo$overall.se))
}

loo_dt <- rbindlist(lapply(loo_results, as.data.table))
fwrite(loo_dt, "../data/loo_results.csv")

# ── 3. COVID SENSITIVITY ─────────────────────────────────────────────────
cat("\n=== COVID SENSITIVITY ===\n")

# Vary the end date of the post-period
end_dates <- c("2019-12-01", "2020-01-01", "2020-02-01")

covid_results <- list()
for (end_d in end_dates) {
  panel_sub <- panel[date <= as.Date(end_d)]
  cs_sub <- att_gt(
    yname = "weapons_rate",
    tname = "t",
    idname = "force_id",
    gname = "g",
    data = as.data.frame(panel_sub),
    control_group = "notyettreated",
    anticipation = 0,
    base_period = "universal"
  )
  agg_sub <- aggte(cs_sub, type = "simple")
  covid_results[[end_d]] <- list(
    end_date = end_d,
    att = agg_sub$overall.att,
    se = agg_sub$overall.se
  )
  cat(sprintf("  End %s: ATT = %.3f (SE = %.3f)\n", end_d, agg_sub$overall.att, agg_sub$overall.se))
}

covid_dt <- rbindlist(lapply(covid_results, as.data.table))
fwrite(covid_dt, "../data/covid_sensitivity.csv")

# ── 4. TWFE vs CS COMPARISON ─────────────────────────────────────────────
cat("\n=== TWFE vs CALLAWAY-SANT'ANNA ===\n")
cat(sprintf("TWFE weapons ATT: %.3f (SE = %.3f)\n", results$main_twfe_coef, results$main_twfe_se))
cat(sprintf("CS weapons ATT:   %.3f (SE = %.3f)\n", results$main_cs_att, results$main_cs_se))

# ── 5. ETHNICITY HETEROGENEITY (from S&S data) ──────────────────────────
cat("\n=== ETHNICITY ANALYSIS (S60 stops) ===\n")

# Load the raw S&S data for ethnicity breakdown
ss_raw <- fread("../data/ss_force_month.csv")

# Note: The force-month aggregation doesn't have ethnicity breakdown.
# This is a limitation — the aggregated data doesn't preserve ethnicity detail.
# We can still note this as a discussion point about disproportionality.

cat("Note: Ethnicity-disaggregated analysis requires raw S&S records.\n")
cat("Force-month aggregation loses ethnicity detail.\n")
cat("Disproportionality is discussed qualitatively using published Home Office statistics.\n")

# ── 6. SAVE ROBUSTNESS RESULTS ──────────────────────────────────────────
robustness <- list(
  wild_bootstrap_p = boot_result$p_val,
  wild_bootstrap_ci_lo = boot_result$conf_int[1],
  wild_bootstrap_ci_hi = boot_result$conf_int[2],
  loo = loo_results,
  covid_sensitivity = covid_results
)
saveRDS(robustness, "../data/robustness.rds")
cat("\nRobustness results saved.\n")
