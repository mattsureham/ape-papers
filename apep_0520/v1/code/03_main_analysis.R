## ============================================================================
## 03_main_analysis.R — CS-DiD estimation, event studies, first-stage
## ============================================================================

source("00_packages.R")

DATA <- "../data"
main_sample <- readRDS(file.path(DATA, "main_sample.rds"))

## ---- 1. CS-DiD Setup ----
# Callaway & Sant'Anna (2021) requires:
# - yname: outcome
# - tname: time period (integer)
# - idname: unit id (integer)
# - gname: cohort group (first treated period; 0 = never treated)

# Create integer time: months since Jan 2018
main_sample[, t_period := as.integer(difftime(month_date, as.Date("2018-01-01"), units = "days")) %/% 30L + 1L]

# Cohort group: first treated period (integer), 0 for never-treated
main_sample[!is.na(waiver_date),
            g_period := as.integer(difftime(waiver_date, as.Date("2018-01-01"), units = "days")) %/% 30L + 1L]
main_sample[is.na(waiver_date), g_period := 0L]

# State numeric ID
main_sample[, state_num := as.integer(factor(state))]

cat("CS-DiD setup complete.\n")
cat(sprintf("Treatment cohorts: %s\n",
            paste(sort(unique(main_sample[g_period > 0, g_period])), collapse = ", ")))

## ---- 2. Main CS-DiD: Behavioral Health Providers ----
cat("\n=== CS-DiD: Log BH Providers ===\n")

cs_bh_providers <- att_gt(
  yname = "ln_bh_providers",
  tname = "t_period",
  idname = "state_num",
  gname = "g_period",
  data = as.data.frame(main_sample),
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "universal"
)

cat("Group-time ATTs estimated.\n")

# Aggregate: overall ATT
agg_bh_simple <- aggte(cs_bh_providers, type = "simple")
cat(sprintf("Overall ATT (ln BH providers): %.4f (SE: %.4f, p: %.4f)\n",
            agg_bh_simple$overall.att, agg_bh_simple$overall.se,
            2 * pnorm(-abs(agg_bh_simple$overall.att / agg_bh_simple$overall.se))))

# Aggregate: dynamic (event study)
agg_bh_dynamic <- aggte(cs_bh_providers, type = "dynamic", min_e = -12, max_e = 36)

# Save
saveRDS(cs_bh_providers, file.path(DATA, "cs_bh_providers.rds"))
saveRDS(agg_bh_simple, file.path(DATA, "agg_bh_simple.rds"))
saveRDS(agg_bh_dynamic, file.path(DATA, "agg_bh_dynamic.rds"))

# Extract event study coefficients for plotting
es_bh <- data.table(
  event_time = agg_bh_dynamic$egt,
  att = agg_bh_dynamic$att.egt,
  se = agg_bh_dynamic$se.egt,
  ci_lower = agg_bh_dynamic$att.egt - 1.96 * agg_bh_dynamic$se.egt,
  ci_upper = agg_bh_dynamic$att.egt + 1.96 * agg_bh_dynamic$se.egt,
  outcome = "BH Providers (log)"
)
fwrite(es_bh, file.path(DATA, "es_bh_providers.csv"))

## ---- 3. CS-DiD: SUD-Specific Providers ----
cat("\n=== CS-DiD: Log SUD Providers ===\n")

cs_sud_providers <- att_gt(
  yname = "ln_sud_providers",
  tname = "t_period",
  idname = "state_num",
  gname = "g_period",
  data = as.data.frame(main_sample),
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "universal"
)

agg_sud_simple <- aggte(cs_sud_providers, type = "simple")
agg_sud_dynamic <- aggte(cs_sud_providers, type = "dynamic", min_e = -12, max_e = 36)

cat(sprintf("Overall ATT (ln SUD providers): %.4f (SE: %.4f, p: %.4f)\n",
            agg_sud_simple$overall.att, agg_sud_simple$overall.se,
            2 * pnorm(-abs(agg_sud_simple$overall.att / agg_sud_simple$overall.se))))

saveRDS(cs_sud_providers, file.path(DATA, "cs_sud_providers.rds"))
saveRDS(agg_sud_simple, file.path(DATA, "agg_sud_simple.rds"))
saveRDS(agg_sud_dynamic, file.path(DATA, "agg_sud_dynamic.rds"))

es_sud <- data.table(
  event_time = agg_sud_dynamic$egt,
  att = agg_sud_dynamic$att.egt,
  se = agg_sud_dynamic$se.egt,
  ci_lower = agg_sud_dynamic$att.egt - 1.96 * agg_sud_dynamic$se.egt,
  ci_upper = agg_sud_dynamic$att.egt + 1.96 * agg_sud_dynamic$se.egt,
  outcome = "SUD Providers (log)"
)
fwrite(es_sud, file.path(DATA, "es_sud_providers.csv"))

## ---- 4. CS-DiD: MAT Drug Providers ----
cat("\n=== CS-DiD: Log MAT Providers ===\n")

cs_mat_providers <- att_gt(
  yname = "ln_mat_providers",
  tname = "t_period",
  idname = "state_num",
  gname = "g_period",
  data = as.data.frame(main_sample),
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "universal"
)

agg_mat_simple <- aggte(cs_mat_providers, type = "simple")
agg_mat_dynamic <- aggte(cs_mat_providers, type = "dynamic", min_e = -12, max_e = 36)

cat(sprintf("Overall ATT (ln MAT providers): %.4f (SE: %.4f, p: %.4f)\n",
            agg_mat_simple$overall.att, agg_mat_simple$overall.se,
            2 * pnorm(-abs(agg_mat_simple$overall.att / agg_mat_simple$overall.se))))

saveRDS(cs_mat_providers, file.path(DATA, "cs_mat_providers.rds"))

es_mat <- data.table(
  event_time = agg_mat_dynamic$egt,
  att = agg_mat_dynamic$att.egt,
  se = agg_mat_dynamic$se.egt,
  ci_lower = agg_mat_dynamic$att.egt - 1.96 * agg_mat_dynamic$se.egt,
  ci_upper = agg_mat_dynamic$att.egt + 1.96 * agg_mat_dynamic$se.egt,
  outcome = "MAT Providers (log)"
)
fwrite(es_mat, file.path(DATA, "es_mat_providers.csv"))

## ---- 5. CS-DiD: Beneficiaries Served ----
cat("\n=== CS-DiD: Log BH Beneficiaries ===\n")

cs_bh_benef <- att_gt(
  yname = "ln_bh_beneficiaries",
  tname = "t_period",
  idname = "state_num",
  gname = "g_period",
  data = as.data.frame(main_sample),
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "universal"
)

agg_benef_simple <- aggte(cs_bh_benef, type = "simple")
agg_benef_dynamic <- aggte(cs_bh_benef, type = "dynamic", min_e = -12, max_e = 36)

cat(sprintf("Overall ATT (ln BH beneficiaries): %.4f (SE: %.4f, p: %.4f)\n",
            agg_benef_simple$overall.att, agg_benef_simple$overall.se,
            2 * pnorm(-abs(agg_benef_simple$overall.att / agg_benef_simple$overall.se))))

saveRDS(cs_bh_benef, file.path(DATA, "cs_bh_benef.rds"))

es_benef <- data.table(
  event_time = agg_benef_dynamic$egt,
  att = agg_benef_dynamic$att.egt,
  se = agg_benef_dynamic$se.egt,
  ci_lower = agg_benef_dynamic$att.egt - 1.96 * agg_benef_dynamic$se.egt,
  ci_upper = agg_benef_dynamic$att.egt + 1.96 * agg_benef_dynamic$se.egt,
  outcome = "BH Beneficiaries (log)"
)
fwrite(es_benef, file.path(DATA, "es_bh_beneficiaries.csv"))

## ---- 6. CS-DiD: Placebo (Personal Care T-codes) ----
cat("\n=== CS-DiD: PLACEBO — Log Personal Care Providers ===\n")

cs_placebo <- att_gt(
  yname = "ln_pc_providers",
  tname = "t_period",
  idname = "state_num",
  gname = "g_period",
  data = as.data.frame(main_sample),
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "universal"
)

agg_placebo_simple <- aggte(cs_placebo, type = "simple")
agg_placebo_dynamic <- aggte(cs_placebo, type = "dynamic", min_e = -12, max_e = 36)

cat(sprintf("PLACEBO ATT (ln PC providers): %.4f (SE: %.4f, p: %.4f)\n",
            agg_placebo_simple$overall.att, agg_placebo_simple$overall.se,
            2 * pnorm(-abs(agg_placebo_simple$overall.att / agg_placebo_simple$overall.se))))

saveRDS(cs_placebo, file.path(DATA, "cs_placebo.rds"))

es_placebo <- data.table(
  event_time = agg_placebo_dynamic$egt,
  att = agg_placebo_dynamic$att.egt,
  se = agg_placebo_dynamic$se.egt,
  ci_lower = agg_placebo_dynamic$att.egt - 1.96 * agg_placebo_dynamic$se.egt,
  ci_upper = agg_placebo_dynamic$att.egt + 1.96 * agg_placebo_dynamic$se.egt,
  outcome = "Personal Care Providers (log) [PLACEBO]"
)
fwrite(es_placebo, file.path(DATA, "es_placebo.csv"))

## ---- 7. Extensive Margin: New Provider Entry ----
cat("\n=== CS-DiD: New BH Provider Entry ===\n")

cs_entry <- att_gt(
  yname = "ln_new_bh_providers",
  tname = "t_period",
  idname = "state_num",
  gname = "g_period",
  data = as.data.frame(main_sample),
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "universal"
)

agg_entry_simple <- aggte(cs_entry, type = "simple")
agg_entry_dynamic <- aggte(cs_entry, type = "dynamic", min_e = -12, max_e = 36)

cat(sprintf("Overall ATT (ln new BH entries): %.4f (SE: %.4f, p: %.4f)\n",
            agg_entry_simple$overall.att, agg_entry_simple$overall.se,
            2 * pnorm(-abs(agg_entry_simple$overall.att / agg_entry_simple$overall.se))))

saveRDS(cs_entry, file.path(DATA, "cs_entry.rds"))

es_entry <- data.table(
  event_time = agg_entry_dynamic$egt,
  att = agg_entry_dynamic$att.egt,
  se = agg_entry_dynamic$se.egt,
  ci_lower = agg_entry_dynamic$att.egt - 1.96 * agg_entry_dynamic$se.egt,
  ci_upper = agg_entry_dynamic$att.egt + 1.96 * agg_entry_dynamic$se.egt,
  outcome = "New BH Provider Entry (log)"
)
fwrite(es_entry, file.path(DATA, "es_entry.csv"))

## ---- 8. TWFE Comparison (for Bacon decomposition) ----
cat("\n=== TWFE Baseline (fixest) ===\n")

# Standard TWFE for comparison with CS-DiD
twfe_bh <- feols(ln_bh_providers ~ treated | state_id + t_period,
                  data = main_sample, cluster = ~state_id)
twfe_sud <- feols(ln_sud_providers ~ treated | state_id + t_period,
                   data = main_sample, cluster = ~state_id)
twfe_placebo <- feols(ln_pc_providers ~ treated | state_id + t_period,
                       data = main_sample, cluster = ~state_id)

cat("\nTWFE results:\n")
cat(sprintf("  BH providers:  %.4f (%.4f)\n", coef(twfe_bh), se(twfe_bh)))
cat(sprintf("  SUD providers: %.4f (%.4f)\n", coef(twfe_sud), se(twfe_sud)))
cat(sprintf("  PLACEBO (PC):  %.4f (%.4f)\n", coef(twfe_placebo), se(twfe_placebo)))

saveRDS(list(bh = twfe_bh, sud = twfe_sud, placebo = twfe_placebo),
        file.path(DATA, "twfe_results.rds"))

## ---- 9. Summary of Main Results ----
results_summary <- data.table(
  outcome = c("BH Providers", "SUD Providers", "MAT Providers",
              "BH Beneficiaries", "New BH Entry", "Personal Care [PLACEBO]"),
  att = c(agg_bh_simple$overall.att, agg_sud_simple$overall.att,
          agg_mat_simple$overall.att, agg_benef_simple$overall.att,
          agg_entry_simple$overall.att, agg_placebo_simple$overall.att),
  se = c(agg_bh_simple$overall.se, agg_sud_simple$overall.se,
         agg_mat_simple$overall.se, agg_benef_simple$overall.se,
         agg_entry_simple$overall.se, agg_placebo_simple$overall.se)
)
results_summary[, `:=`(
  t_stat = att / se,
  p_value = 2 * pnorm(-abs(att / se)),
  pct_change = (exp(att) - 1) * 100
)]

fwrite(results_summary, file.path(DATA, "results_summary.csv"))

cat("\n=== MAIN RESULTS SUMMARY ===\n")
print(results_summary)

cat("\n=== Main analysis complete ===\n")
