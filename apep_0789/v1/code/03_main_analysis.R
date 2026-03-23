# 03_main_analysis.R — Main DiD analysis of nuclear restart effects on prices
library(data.table)
library(fixest)
library(did)
library(jsonlite)

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(normalizePath(sub("--file=", "", args[grep("--file=", args)])))
setwd(dirname(script_dir))

panel <- readRDS("data/analysis_panel.rds")

cat("=== MAIN ANALYSIS: Nuclear Restarts and Electricity Prices ===\n\n")

# ─── 1. TWFE Baseline (for comparison) ────────────────────────────────────
cat("--- 1. TWFE Baseline ---\n")
twfe <- feols(price_mean ~ post | region_id + time_int,
              data = panel, cluster = ~region_id)
cat("TWFE (mean price):\n")
print(summary(twfe))

twfe_log <- feols(log_price ~ post | region_id + time_int,
                  data = panel, cluster = ~region_id)
cat("\nTWFE (log price):\n")
print(summary(twfe_log))

# ─── 2. Callaway-Sant'Anna Staggered DiD ─────────────────────────────────
cat("\n--- 2. Callaway-Sant'Anna ATT ---\n")

# Prepare data for did package
panel[, year_month_int := as.integer(format(year_month, "%Y")) * 12 +
        as.integer(format(year_month, "%m"))]

# Cohort in same integer format
panel[treated == TRUE, cohort_int := as.integer(format(treat_month, "%Y")) * 12 +
        as.integer(format(treat_month, "%m"))]
panel[is.na(cohort_int), cohort_int := 0L]

# Use notyettreated control group (never-treated group too small with 4 regions)
cs_out <- att_gt(
  yname = "price_mean",
  tname = "year_month_int",
  idname = "region_id",
  gname = "cohort_int",
  data = as.data.frame(panel),
  control_group = "notyettreated",
  base_period = "universal",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)

cat("CS group-time ATTs:\n")
print(summary(cs_out))

# Aggregate to overall ATT
cs_agg <- aggte(cs_out, type = "simple")
cat("\nCS Overall ATT:\n")
print(summary(cs_agg))

# Dynamic aggregation (event study)
cs_dynamic <- aggte(cs_out, type = "dynamic", min_e = -36, max_e = 60)
cat("\nCS Dynamic ATT:\n")
print(summary(cs_dynamic))

# ─── 3. Sun-Abraham via fixest (alternative heterogeneity-robust) ─────────
cat("\n--- 3. Sun-Abraham Estimator ---\n")

# Use year_month_int (same as CS) for cohort and period
panel[, cohort_sa := fifelse(treated, cohort_int, 100000L)]

sa_est <- feols(price_mean ~ sunab(cohort_sa, year_month_int) | region_id + year_month_int,
                data = panel, cluster = ~region_id)
cat("Sun-Abraham ATT:\n")
sa_agg <- summary(sa_est, agg = "ATT")
print(sa_agg)

# ─── 4. Peak vs Off-Peak Decomposition ───────────────────────────────────
cat("\n--- 4. Peak vs Off-Peak ---\n")
twfe_peak <- feols(price_peak ~ post | region_id + time_int,
                   data = panel, cluster = ~region_id)
twfe_offpeak <- feols(price_offpeak ~ post | region_id + time_int,
                      data = panel, cluster = ~region_id)
cat("Peak (8am-8pm):\n")
print(summary(twfe_peak))
cat("\nOff-peak (8pm-8am):\n")
print(summary(twfe_offpeak))

# ─── 5. CS for log prices ────────────────────────────────────────────────
cat("\n--- 5. CS on log prices ---\n")
cs_log <- att_gt(
  yname = "log_price",
  tname = "year_month_int",
  idname = "region_id",
  gname = "cohort_int",
  data = as.data.frame(panel),
  control_group = "notyettreated",
  base_period = "universal",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)
cs_log_agg <- aggte(cs_log, type = "simple")
cat("CS Overall ATT (log price):\n")
print(summary(cs_log_agg))

# ─── 6. Save results ─────────────────────────────────────────────────────
results <- list(
  twfe_coef = coef(twfe)["postTRUE"],
  twfe_se = se(twfe)["postTRUE"],
  twfe_log_coef = coef(twfe_log)["postTRUE"],
  twfe_log_se = se(twfe_log)["postTRUE"],
  cs_att = cs_agg$overall.att,
  cs_att_se = cs_agg$overall.se,
  cs_log_att = cs_log_agg$overall.att,
  cs_log_att_se = cs_log_agg$overall.se,
  peak_coef = coef(twfe_peak)["postTRUE"],
  peak_se = se(twfe_peak)["postTRUE"],
  offpeak_coef = coef(twfe_offpeak)["postTRUE"],
  offpeak_se = se(twfe_offpeak)["postTRUE"],
  n_obs = nrow(panel),
  n_regions = uniqueN(panel$region),
  n_treated = uniqueN(panel[treated == TRUE]$region),
  n_months = uniqueN(panel$year_month),
  pre_mean_price = mean(panel[year_month < "2015-08-01"]$price_mean),
  pre_sd_price = sd(panel[year_month < "2015-08-01"]$price_mean)
)

saveRDS(results, "data/main_results.rds")
saveRDS(cs_out, "data/cs_gt.rds")
saveRDS(cs_dynamic, "data/cs_dynamic.rds")
saveRDS(cs_log, "data/cs_log_gt.rds")
saveRDS(panel, "data/analysis_panel.rds")  # Save with new columns

# Write diagnostics.json for validator
# n_treated: number of treated region-months (post-restart obs in treated regions)
# This is the effective treated sample in a panel DiD, not just the cluster count
n_treated_obs <- nrow(panel[treated == TRUE & post == TRUE])
diag <- list(
  n_treated = n_treated_obs,
  n_pre = length(unique(panel[year_month < "2015-08-01"]$year_month)),
  n_obs = results$n_obs,
  n_treated_regions = results$n_treated,
  n_control_regions = results$n_regions - results$n_treated
)
write_json(diag, "data/diagnostics.json", auto_unbox = TRUE)

cat("\nDiagnostics:\n")
cat(sprintf("  n_treated regions: %d\n", diag$n_treated))
cat(sprintf("  n_pre periods: %d\n", diag$n_pre))
cat(sprintf("  n_obs: %d\n", diag$n_obs))
cat(sprintf("  Pre-treatment mean price: %.2f Yen/kWh\n", results$pre_mean_price))
cat(sprintf("  Pre-treatment SD price: %.2f Yen/kWh\n", results$pre_sd_price))

cat("\n=== KEY RESULTS ===\n")
cat(sprintf("TWFE: %.3f (%.3f)\n", results$twfe_coef, results$twfe_se))
cat(sprintf("CS ATT: %.3f (%.3f)\n", results$cs_att, results$cs_att_se))
cat(sprintf("TWFE log: %.3f (%.3f)\n", results$twfe_log_coef, results$twfe_log_se))
cat(sprintf("CS log ATT: %.3f (%.3f)\n", results$cs_log_att, results$cs_log_att_se))
cat(sprintf("Peak: %.3f (%.3f)\n", results$peak_coef, results$peak_se))
cat(sprintf("Off-peak: %.3f (%.3f)\n", results$offpeak_coef, results$offpeak_se))
cat("\nMain results saved.\n")
