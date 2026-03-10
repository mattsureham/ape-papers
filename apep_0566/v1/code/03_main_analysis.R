# ============================================================================
# 03_main_analysis.R — Callaway-Sant'Anna DiD + event studies
# APEP Paper apep_0566
# ============================================================================

source("00_packages.R")

data_dir <- "../data/"
panel <- fread(paste0(data_dir, "analysis_panel.csv"))

# Drop DC for main analysis (robustness with DC)
panel_states <- panel[is_state == TRUE]

cat("Analysis panel:", nrow(panel_states), "obs,",
    uniqueN(panel_states$state_fips), "states\n")

# ============================================================================
# 1. Callaway-Sant'Anna DiD — Main Specification
# ============================================================================

cat("\n=== CS-DiD: Drug Overdose Rate ===\n")

cs_result <- att_gt(
  yname = "drug_od_rate",
  tname = "year",
  idname = "state_fips",
  gname = "gvar",
  data = as.data.frame(panel_states),
  control_group = "notyettreated",
  anticipation = 0,
  est_method = "dr",          # Doubly-robust
  base_period = "universal"
)

cat("CS ATT(g,t) estimated.\n")
summary(cs_result)

# Save group-time ATTs
gt_df <- data.table(
  group = cs_result$group,
  time = cs_result$t,
  att = cs_result$att,
  se = cs_result$se,
  ci_lower = cs_result$att - 1.96 * cs_result$se,
  ci_upper = cs_result$att + 1.96 * cs_result$se
)
fwrite(gt_df, paste0(data_dir, "cs_gt_results.csv"))

# ============================================================================
# 2. Aggregate to overall ATT
# ============================================================================

cat("\n=== Overall ATT ===\n")

agg_simple <- aggte(cs_result, type = "simple")
cat("Simple ATT:", round(agg_simple$overall.att, 4),
    "(SE:", round(agg_simple$overall.se, 4), ")\n")

# Save
agg_df <- data.table(
  estimand = "simple_att",
  estimate = agg_simple$overall.att,
  se = agg_simple$overall.se,
  ci_lower = agg_simple$overall.att - 1.96 * agg_simple$overall.se,
  ci_upper = agg_simple$overall.att + 1.96 * agg_simple$overall.se
)

# ============================================================================
# 3. Dynamic (event-study) aggregation
# ============================================================================

cat("\n=== Event Study ===\n")

agg_dynamic <- aggte(cs_result, type = "dynamic", min_e = -8, max_e = 6)
summary(agg_dynamic)

es_df <- data.table(
  event_time = agg_dynamic$egt,
  att = agg_dynamic$att.egt,
  se = agg_dynamic$se.egt,
  ci_lower = agg_dynamic$att.egt - 1.96 * agg_dynamic$se.egt,
  ci_upper = agg_dynamic$att.egt + 1.96 * agg_dynamic$se.egt
)
fwrite(es_df, paste0(data_dir, "cs_event_study.csv"))

cat("Event study coefficients saved.\n")

# ============================================================================
# 4. Group-specific ATTs (by cohort)
# ============================================================================

cat("\n=== Cohort-Specific ATTs ===\n")

agg_group <- aggte(cs_result, type = "group")
summary(agg_group)

group_df <- data.table(
  cohort = agg_group$egt,
  att = agg_group$att.egt,
  se = agg_group$se.egt,
  ci_lower = agg_group$att.egt - 1.96 * agg_group$se.egt,
  ci_upper = agg_group$att.egt + 1.96 * agg_group$se.egt
)
fwrite(group_df, paste0(data_dir, "cs_cohort_atts.csv"))

# ============================================================================
# 5. TWFE (standard) for comparison
# ============================================================================

cat("\n=== TWFE Comparison ===\n")

twfe_base <- feols(drug_od_rate ~ treated | state_fips + year,
                   data = panel_states, cluster = ~state_fips)
cat("TWFE estimate:", round(coef(twfe_base)["treated"], 4),
    "(SE:", round(se(twfe_base)["treated"], 4), ")\n")

# TWFE event study
panel_states[, rel_time_fac := factor(rel_time)]
panel_states[is.na(rel_time), rel_time_fac := factor(NA)]

# For SUNAB
twfe_es <- feols(drug_od_rate ~ sunab(gvar, year) | state_fips + year,
                 data = panel_states[gvar > 0 | gvar == 0],
                 cluster = ~state_fips)

sunab_df <- data.table(
  event_time = as.numeric(gsub("year::", "", names(coef(twfe_es)))),
  att = as.numeric(coef(twfe_es)),
  se = as.numeric(se(twfe_es))
)
sunab_df[, ci_lower := att - 1.96 * se]
sunab_df[, ci_upper := att + 1.96 * se]
fwrite(sunab_df, paste0(data_dir, "sunab_event_study.csv"))

# ============================================================================
# 6. Log specification
# ============================================================================

cat("\n=== CS-DiD: Log Drug Overdose Rate ===\n")

cs_log <- att_gt(
  yname = "log_drug_od_rate",
  tname = "year",
  idname = "state_fips",
  gname = "gvar",
  data = as.data.frame(panel_states),
  control_group = "notyettreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "universal"
)

agg_log <- aggte(cs_log, type = "simple")
cat("Log ATT:", round(agg_log$overall.att, 4),
    "(SE:", round(agg_log$overall.se, 4), ")\n")

agg_log_dynamic <- aggte(cs_log, type = "dynamic", min_e = -8, max_e = 6)

es_log_df <- data.table(
  event_time = agg_log_dynamic$egt,
  att = agg_log_dynamic$att.egt,
  se = agg_log_dynamic$se.egt,
  ci_lower = agg_log_dynamic$att.egt - 1.96 * agg_log_dynamic$se.egt,
  ci_upper = agg_log_dynamic$att.egt + 1.96 * agg_log_dynamic$se.egt
)
fwrite(es_log_df, paste0(data_dir, "cs_event_study_log.csv"))

# ============================================================================
# 7. Dose-response by reform intensity
# ============================================================================

cat("\n=== Dose-Response: Reform Intensity ===\n")

# Create intensity-specific treatment indicators
panel_states[, treat_abolished := as.integer(treated == 1 & reform_intensity == 3)]
panel_states[, treat_conviction := as.integer(treated == 1 & reform_intensity == 2)]
panel_states[, treat_burden := as.integer(treated == 1 & reform_intensity == 1)]

dose_twfe <- feols(drug_od_rate ~ treat_abolished + treat_conviction + treat_burden |
                   state_fips + year,
                   data = panel_states, cluster = ~state_fips)
cat("Dose-response TWFE:\n")
print(summary(dose_twfe))

dose_df <- data.table(
  intensity = c("Abolished", "Conviction Required", "Burden Raised"),
  intensity_code = c(3, 2, 1),
  estimate = coef(dose_twfe),
  se = se(dose_twfe),
  ci_lower = coef(dose_twfe) - 1.96 * se(dose_twfe),
  ci_upper = coef(dose_twfe) + 1.96 * se(dose_twfe)
)
fwrite(dose_df, paste0(data_dir, "dose_response.csv"))

# ============================================================================
# 8. Save all main results
# ============================================================================

main_results <- data.table(
  spec = c("CS-DiD (levels)", "CS-DiD (log)", "TWFE"),
  estimate = c(agg_simple$overall.att, agg_log$overall.att,
               coef(twfe_base)["treated"]),
  se = c(agg_simple$overall.se, agg_log$overall.se,
         se(twfe_base)["treated"]),
  n_obs = nrow(panel_states),
  n_states = uniqueN(panel_states$state_fips),
  n_treated = uniqueN(panel_states[treated_ever == TRUE]$state_fips)
)
main_results[, ci_lower := estimate - 1.96 * se]
main_results[, ci_upper := estimate + 1.96 * se]
main_results[, p_value := 2 * pnorm(-abs(estimate / se))]

cat("\n=== Main Results Summary ===\n")
print(main_results)

fwrite(main_results, paste0(data_dir, "main_results.csv"))

# Save CS result object for figures
saveRDS(cs_result, paste0(data_dir, "cs_result.rds"))
saveRDS(cs_log, paste0(data_dir, "cs_result_log.rds"))

cat("\nMain analysis complete.\n")
