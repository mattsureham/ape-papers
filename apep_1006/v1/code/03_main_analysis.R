# 03_main_analysis.R — Main CS-DiD analysis for APEP 1006
# Callaway-Sant'Anna staggered DiD: effect of FATF grey-listing on remittance costs

source("00_packages.R")

data_dir <- "../data"

# ============================================================================
# 1. Load data
# ============================================================================
cs_sample <- fread(file.path(data_dir, "cs_sample.csv"))
full_panel <- fread(file.path(data_dir, "corridor_panel.csv"))

cat("CS-DiD sample:", nrow(cs_sample), "obs,",
    uniqueN(cs_sample$corridor_id), "corridors,",
    uniqueN(cs_sample[first_treat > 0, first_treat]), "treatment cohorts\n")

# ============================================================================
# 2. Callaway-Sant'Anna Estimation
# ============================================================================
cat("\n=== CALLAWAY-SANT'ANNA ESTIMATION ===\n")

# Ensure required variables are correct types
cs_sample[, corridor_num := as.integer(factor(corridor_id))]
cs_sample[, time_index := as.integer(time_index)]
cs_sample[, first_treat := as.integer(first_treat)]

# Main specification: ATT(g,t) with never-treated controls
cs_out <- att_gt(
  yname  = "avg_cost",
  tname  = "time_index",
  idname = "corridor_num",
  gname  = "first_treat",
  data   = as.data.frame(cs_sample),
  control_group = "nevertreated",
  anticipation  = 0,
  est_method    = "dr",     # Doubly robust (Sant'Anna & Zhao)
  base_period   = "varying" # Use period just before treatment
)

cat("ATT(g,t) estimated for", length(cs_out$att), "group-time cells\n")

# ============================================================================
# 3. Aggregate ATT
# ============================================================================

# Simple weighted average ATT
agg_simple <- aggte(cs_out, type = "simple", na.rm = TRUE)
cat("\n--- Simple ATT ---\n")
cat("ATT:", round(agg_simple$overall.att, 4), "\n")
cat("SE:", round(agg_simple$overall.se, 4), "\n")
cat("95% CI: [", round(agg_simple$overall.att - 1.96 * agg_simple$overall.se, 4),
    ",", round(agg_simple$overall.att + 1.96 * agg_simple$overall.se, 4), "]\n")

# ============================================================================
# 4. Event Study (Dynamic Effects)
# ============================================================================
cat("\n=== EVENT STUDY ===\n")
es <- aggte(cs_out, type = "dynamic", min_e = -8, max_e = 12, na.rm = TRUE)

# Print event study coefficients
cat("Event-time coefficients:\n")
es_dt <- data.table(
  event_time = es$egt,
  att = es$att.egt,
  se = es$se.egt,
  crit_val = es$crit.val.egt
)
es_dt[, ci_lo := att - crit_val * se]
es_dt[, ci_hi := att + crit_val * se]
es_dt[, sig := ifelse(ci_lo > 0 | ci_hi < 0, "*", "")]

cat(sprintf("%4s %8s %8s %10s %10s %s\n",
            "e", "ATT", "SE", "CI_lo", "CI_hi", "sig"))
for (i in seq_len(nrow(es_dt))) {
  cat(sprintf("%4d %8.4f %8.4f %10.4f %10.4f %s\n",
              es_dt$event_time[i], es_dt$att[i], es_dt$se[i],
              es_dt$ci_lo[i], es_dt$ci_hi[i], es_dt$sig[i]))
}

# Check pre-trends
pre_trend_coefs <- es_dt[event_time < 0]
cat("\nPre-trend test (H0: all pre-treatment effects = 0):\n")
cat("  Max absolute pre-treatment coefficient:", round(max(abs(pre_trend_coefs$att)), 4), "\n")
cat("  Any individually significant pre-treatment coef:",
    any(pre_trend_coefs$sig == "*"), "\n")

# Save event study results
fwrite(es_dt, file.path(data_dir, "event_study_results.csv"))

# ============================================================================
# 5. Group-level ATTs
# ============================================================================
cat("\n=== GROUP-LEVEL ATT ===\n")
agg_group <- aggte(cs_out, type = "group", na.rm = TRUE)
group_dt <- data.table(
  group = agg_group$egt,
  att = agg_group$att.egt,
  se = agg_group$se.egt
)
cat("Group-level ATTs:\n")
print(group_dt[order(group)])

# ============================================================================
# 6. TWFE Comparison (for reference only)
# ============================================================================
cat("\n=== TWFE COMPARISON ===\n")

# Basic TWFE with corridor + time FE
twfe_basic <- feols(avg_cost ~ grey_listed | corridor_num + time_index,
                    data = cs_sample, cluster = ~destination_code)
cat("TWFE (corridor + time FE):\n")
cat("  Coefficient:", round(coef(twfe_basic)["grey_listed"], 4), "\n")
cat("  SE:", round(se(twfe_basic)["grey_listed"], 4), "\n")

# TWFE with source×time and destination FE
twfe_strict <- feols(avg_cost ~ grey_listed | corridor_num + source_code^time_index,
                     data = full_panel, cluster = ~destination_code)
cat("TWFE (corridor + source×time FE):\n")
cat("  Coefficient:", round(coef(twfe_strict)["grey_listed"], 4), "\n")
cat("  SE:", round(se(twfe_strict)["grey_listed"], 4), "\n")

# ============================================================================
# 7. Calendar-time effects (by period since listing)
# ============================================================================
cat("\n=== CALENDAR-TIME EFFECTS ===\n")
agg_cal <- aggte(cs_out, type = "calendar", na.rm = TRUE)
cal_dt <- data.table(
  calendar_time = agg_cal$egt,
  att = agg_cal$att.egt,
  se = agg_cal$se.egt
)
cat("Calendar-time effects (selected):\n")
print(cal_dt[seq(1, min(nrow(cal_dt), 20), by = 2)])

# ============================================================================
# 8. Save main results and diagnostics
# ============================================================================

# Main results for tables
main_results <- list(
  cs_att = agg_simple$overall.att,
  cs_se = agg_simple$overall.se,
  cs_ci_lo = agg_simple$overall.att - 1.96 * agg_simple$overall.se,
  cs_ci_hi = agg_simple$overall.att + 1.96 * agg_simple$overall.se,
  twfe_coef = as.numeric(coef(twfe_basic)["grey_listed"]),
  twfe_se = as.numeric(se(twfe_basic)["grey_listed"]),
  twfe_strict_coef = as.numeric(coef(twfe_strict)["grey_listed"]),
  twfe_strict_se = as.numeric(se(twfe_strict)["grey_listed"]),
  n_obs_cs = nrow(cs_sample),
  n_corridors_cs = uniqueN(cs_sample$corridor_id),
  n_treated_corridors = uniqueN(cs_sample[first_treat > 0, corridor_id]),
  n_control_corridors = uniqueN(cs_sample[first_treat == 0, corridor_id]),
  n_cohorts = uniqueN(cs_sample[first_treat > 0, first_treat]),
  mean_cost = mean(cs_sample$avg_cost, na.rm = TRUE),
  sd_cost = sd(cs_sample$avg_cost, na.rm = TRUE)
)

write_json(main_results, file.path(data_dir, "main_results.json"), auto_unbox = TRUE, pretty = TRUE)

# Diagnostics for validate_v1
n_treated_units <- uniqueN(cs_sample[first_treat > 0, destination_code])
n_pre <- max(0, sum(es_dt$event_time < 0))
diagnostics <- list(
  n_treated = n_treated_units,
  n_pre = n_pre,
  n_obs = nrow(cs_sample)
)
write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("\nDiagnostics:", toJSON(diagnostics, auto_unbox = TRUE), "\n")

# Save model objects for table generation
saveRDS(list(
  cs_out = cs_out,
  agg_simple = agg_simple,
  es = es,
  es_dt = es_dt,
  twfe_basic = twfe_basic,
  twfe_strict = twfe_strict,
  main_results = main_results
), file.path(data_dir, "main_models.rds"))

cat("\nMain analysis complete. Results saved.\n")
