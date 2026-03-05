# =============================================================================
# 03_main_analysis.R — Pills and Diplomas (apep_0510)
# =============================================================================
# Primary analysis:
#   A. Callaway & Sant'Anna DiD for retention, graduation, enrollment
#   B. First-stage: PDMP → overdose mortality (mechanism)
#   C. Drug-type decomposition: prescription vs. fentanyl (substitution test)
#   D. TWFE benchmark (with Bacon decomposition diagnostic)
# =============================================================================

source("code/00_packages.R")

panel <- readRDS(file.path(DATA_DIR, "analysis_panel.rds"))

# =============================================================================
# SECTION A: CALLAWAY & SANT'ANNA DiD — PRIMARY OUTCOMES
# =============================================================================
cat("=== Section A: CS-DiD primary outcomes ===\n")

# --- A1: Retention rate (full-time) ---
cat("  A1: Retention rate...\n")

# Prepare data for did package
# CS-DiD needs: yname, tname, idname, gname
# g = first treated year (0 for never-treated)
panel_ret <- panel[!is.na(ret_pcf) & inst_type == "4-year"]

# Remove institutions with too few observations
obs_count <- panel_ret[, .N, by = unitid]
panel_ret <- panel_ret[unitid %in% obs_count[N >= 10]$unitid]

cat("    N:", nrow(panel_ret), "| Institutions:", length(unique(panel_ret$unitid)),
    "| Cohorts:", length(unique(panel_ret[g > 0]$g)), "\n")

cs_ret <- att_gt(
  yname = "ret_pcf",
  tname = "year",
  idname = "unitid",
  gname = "g",
  data = as.data.frame(panel_ret),
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "universal"
)

# Aggregate to dynamic ATT (event study)
es_ret <- aggte(cs_ret, type = "dynamic", min_e = -5, max_e = 8)
cat("    Overall ATT:", round(es_ret$overall.att, 3),
    "SE:", round(es_ret$overall.se, 3), "\n")

# Save results
saveRDS(cs_ret, file.path(DATA_DIR, "cs_ret_gt.rds"))
saveRDS(es_ret, file.path(DATA_DIR, "cs_ret_es.rds"))

# Export event-study coefficients to CSV for figures
es_ret_df <- data.table(
  event_time = es_ret$egt,
  att = es_ret$att.egt,
  se = es_ret$se.egt,
  ci_lower = es_ret$att.egt - 1.96 * es_ret$se.egt,
  ci_upper = es_ret$att.egt + 1.96 * es_ret$se.egt
)
fwrite(es_ret_df, file.path(DATA_DIR, "es_retention.csv"))

# Simple ATT
simple_ret <- aggte(cs_ret, type = "simple")
cat("    Simple ATT:", round(simple_ret$overall.att, 3),
    "SE:", round(simple_ret$overall.se, 3), "\n\n")

# --- A2: Total enrollment (log) ---
cat("  A2: Log enrollment...\n")

panel_enr <- panel[!is.na(log_enrollment) & log_enrollment > 0 & inst_type == "4-year"]
obs_count2 <- panel_enr[, .N, by = unitid]
panel_enr <- panel_enr[unitid %in% obs_count2[N >= 10]$unitid]

cs_enr <- att_gt(
  yname = "log_enrollment",
  tname = "year",
  idname = "unitid",
  gname = "g",
  data = as.data.frame(panel_enr),
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "universal"
)

es_enr <- aggte(cs_enr, type = "dynamic", min_e = -5, max_e = 8)
cat("    Overall ATT:", round(es_enr$overall.att, 4),
    "SE:", round(es_enr$overall.se, 4), "\n")

saveRDS(cs_enr, file.path(DATA_DIR, "cs_enr_gt.rds"))
saveRDS(es_enr, file.path(DATA_DIR, "cs_enr_es.rds"))

es_enr_df <- data.table(
  event_time = es_enr$egt,
  att = es_enr$att.egt,
  se = es_enr$se.egt,
  ci_lower = es_enr$att.egt - 1.96 * es_enr$se.egt,
  ci_upper = es_enr$att.egt + 1.96 * es_enr$se.egt
)
fwrite(es_enr_df, file.path(DATA_DIR, "es_enrollment.csv"))

simple_enr <- aggte(cs_enr, type = "simple")
cat("    Simple ATT:", round(simple_enr$overall.att, 4),
    "SE:", round(simple_enr$overall.se, 4), "\n\n")

# --- A3: Total completions ---
cat("  A3: Completions...\n")

panel_comp <- panel[!is.na(total_completions) & total_completions > 0 & inst_type == "4-year"]
panel_comp[, log_completions := log(total_completions)]
obs_count3 <- panel_comp[, .N, by = unitid]
panel_comp <- panel_comp[unitid %in% obs_count3[N >= 10]$unitid]

cs_comp <- att_gt(
  yname = "log_completions",
  tname = "year",
  idname = "unitid",
  gname = "g",
  data = as.data.frame(panel_comp),
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "universal"
)

es_comp <- aggte(cs_comp, type = "dynamic", min_e = -5, max_e = 8)
cat("    Overall ATT:", round(es_comp$overall.att, 4),
    "SE:", round(es_comp$overall.se, 4), "\n")

saveRDS(cs_comp, file.path(DATA_DIR, "cs_comp_gt.rds"))
saveRDS(es_comp, file.path(DATA_DIR, "cs_comp_es.rds"))

es_comp_df <- data.table(
  event_time = es_comp$egt,
  att = es_comp$att.egt,
  se = es_comp$se.egt,
  ci_lower = es_comp$att.egt - 1.96 * es_comp$se.egt,
  ci_upper = es_comp$att.egt + 1.96 * es_comp$se.egt
)
fwrite(es_comp_df, file.path(DATA_DIR, "es_completions.csv"))

simple_comp <- aggte(cs_comp, type = "simple")
cat("    Simple ATT:", round(simple_comp$overall.att, 4),
    "SE:", round(simple_comp$overall.se, 4), "\n\n")

# =============================================================================
# SECTION B: FIRST STAGE — PDMP → OVERDOSE MORTALITY
# =============================================================================
cat("=== Section B: First stage (overdose mortality) ===\n")

# State-level panel of overdose rates (all ages — youth suppressed by CDC at state level)
state_panel <- panel[, .(
  od_crude_rate = mean(od_crude_rate, na.rm = TRUE),
  unemp_rate = mean(unemp_rate, na.rm = TRUE),
  pdmp_treated = max(pdmp_treated, na.rm = TRUE),
  g = max(g, na.rm = TRUE)
), by = .(state, year)]

state_panel <- state_panel[!is.na(od_crude_rate)]
state_panel[, state_id := as.integer(as.factor(state))]

cat("  State panel: N =", nrow(state_panel),
    "| States:", length(unique(state_panel$state)), "\n")

# TWFE with state and year FE (state-level DiD)
fs_twfe <- feols(od_crude_rate ~ pdmp_treated | state_id + year,
                 data = state_panel, cluster = ~state_id)
cat("  First stage (TWFE):",
    round(coef(fs_twfe)["pdmp_treated"], 3),
    "SE:", round(se(fs_twfe)["pdmp_treated"], 3), "\n")

# Event study for first stage
state_panel[, event_time := year - g]
state_panel[g == 0, event_time := NA]
state_panel[, event_time_f := factor(event_time)]

fs_es <- feols(od_crude_rate ~ i(event_time, ref = -1) | state_id + year,
               data = state_panel[!is.na(event_time) & event_time >= -5 & event_time <= 5],
               cluster = ~state_id)

# Save first stage results
fs_coefs <- data.table(
  event_time = as.integer(gsub("event_time::", "", names(coef(fs_es)))),
  coef = coef(fs_es),
  se = se(fs_es)
)
fs_coefs[, `:=`(ci_lower = coef - 1.96 * se, ci_upper = coef + 1.96 * se)]
fwrite(fs_coefs, file.path(DATA_DIR, "first_stage_event_study.csv"))

saveRDS(fs_twfe, file.path(DATA_DIR, "first_stage_twfe.rds"))
saveRDS(fs_es, file.path(DATA_DIR, "first_stage_es.rds"))

cat("  First stage event study saved.\n\n")

# =============================================================================
# SECTION C: DRUG-TYPE DECOMPOSITION (Substitution Test)
# =============================================================================
cat("=== Section C: Drug-type decomposition ===\n")

# Use VSRR data: state × year, decomposed by drug type
vsrr_raw <- fread(file.path(DATA_DIR, "vsrr_overdose_by_drug.csv"))
pdmp <- fread(file.path(DATA_DIR, "pdmp_mandate_dates.csv"))

# Map state names to abbreviations for VSRR
sn2a <- data.table(
  state_name = c("Alabama","Alaska","Arizona","Arkansas","California","Colorado",
    "Connecticut","Delaware","District of Columbia","Florida","Georgia","Hawaii",
    "Idaho","Illinois","Indiana","Iowa","Kansas","Kentucky","Louisiana","Maine",
    "Maryland","Massachusetts","Michigan","Minnesota","Mississippi","Missouri",
    "Montana","Nebraska","Nevada","New Hampshire","New Jersey","New Mexico",
    "New York","North Carolina","North Dakota","Ohio","Oklahoma","Oregon",
    "Pennsylvania","Rhode Island","South Carolina","South Dakota","Tennessee",
    "Texas","Utah","Vermont","Virginia","Washington","West Virginia","Wisconsin","Wyoming"),
  state = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI","ID",
    "IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT",
    "NE","NV","NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
    "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY")
)

vsrr_raw <- merge(vsrr_raw, sn2a, by = "state_name", all.x = TRUE)
vsrr_raw <- vsrr_raw[!is.na(state)]

# Create separate panels for each drug type
drug_types <- list(
  "prescription" = "Natural & semi-synthetic opioids (T40.2)",
  "fentanyl" = "Synthetic opioids, excl. methadone (T40.4)",
  "heroin" = "Heroin (T40.1)",
  "total_od" = "Number of Drug Overdose Deaths"
)

decomp_results <- list()
for (drug_name in names(drug_types)) {
  indicator <- drug_types[[drug_name]]
  ind_label <- drug_types[[drug_name]]
  drug_panel <- vsrr_raw[indicator == ind_label,
                          .(deaths = mean(data_value, na.rm = TRUE)),
                          by = .(state, year)]
  drug_panel <- merge(drug_panel, pdmp[, .(state, pdmp_mandate_year)],
                      by = "state", all.x = TRUE)
  drug_panel[, pdmp_treated := as.integer(!is.na(pdmp_mandate_year) & year >= pdmp_mandate_year)]
  drug_panel[, state_id := as.integer(as.factor(state))]

  if (nrow(drug_panel[!is.na(deaths)]) > 50) {
    mod <- feols(log(deaths + 1) ~ pdmp_treated | state_id + year,
                 data = drug_panel[!is.na(deaths)],
                 cluster = ~state_id)
    decomp_results[[drug_name]] <- data.table(
      drug_type = drug_name,
      coef = coef(mod)["pdmp_treated"],
      se = se(mod)["pdmp_treated"],
      n = nobs(mod)
    )
    cat("  ", drug_name, ":", round(coef(mod)["pdmp_treated"], 4),
        "SE:", round(se(mod)["pdmp_treated"], 4), "\n")
  }
}

decomp_df <- rbindlist(decomp_results)
decomp_df[, `:=`(ci_lower = coef - 1.96 * se, ci_upper = coef + 1.96 * se)]
fwrite(decomp_df, file.path(DATA_DIR, "drug_decomposition.csv"))

cat("  Drug decomposition saved.\n\n")

# =============================================================================
# SECTION D: TWFE BENCHMARK + BACON DECOMPOSITION
# =============================================================================
cat("=== Section D: TWFE benchmark ===\n")

# TWFE for retention
twfe_ret <- feols(ret_pcf ~ pdmp_treated +
                    naloxone_active + good_sam_active + medicaid_expanded + cannabis_legal +
                    unemp_rate |
                    unitid + year,
                  data = panel_ret, cluster = ~state)

cat("  TWFE retention:", round(coef(twfe_ret)["pdmp_treated"], 3),
    "SE:", round(se(twfe_ret)["pdmp_treated"], 3), "\n")

saveRDS(twfe_ret, file.path(DATA_DIR, "twfe_retention.rds"))

# TWFE for log enrollment
twfe_enr <- feols(log_enrollment ~ pdmp_treated +
                    naloxone_active + good_sam_active + medicaid_expanded + cannabis_legal +
                    unemp_rate |
                    unitid + year,
                  data = panel_enr, cluster = ~state)

cat("  TWFE enrollment:", round(coef(twfe_enr)["pdmp_treated"], 4),
    "SE:", round(se(twfe_enr)["pdmp_treated"], 4), "\n")

saveRDS(twfe_enr, file.path(DATA_DIR, "twfe_enrollment.rds"))

# TWFE for log completions
twfe_comp <- feols(log_completions ~ pdmp_treated +
                    naloxone_active + good_sam_active + medicaid_expanded + cannabis_legal +
                    unemp_rate |
                    unitid + year,
                  data = panel_comp, cluster = ~state)

cat("  TWFE completions:", round(coef(twfe_comp)["pdmp_treated"], 4),
    "SE:", round(se(twfe_comp)["pdmp_treated"], 4), "\n")

saveRDS(twfe_comp, file.path(DATA_DIR, "twfe_completions.rds"))

# Bacon decomposition (diagnostic for TWFE bias)
cat("\n  Bacon decomposition (retention)...\n")
panel_bacon <- panel_ret[, .(ret_pcf = mean(ret_pcf, na.rm = TRUE),
                              pdmp_treated = max(pdmp_treated)),
                          by = .(state, year)]
panel_bacon[, state_id := as.integer(as.factor(state))]
panel_bacon <- panel_bacon[!is.na(ret_pcf)]

tryCatch({
  bacon_out <- bacon(ret_pcf ~ pdmp_treated,
                     data = as.data.frame(panel_bacon),
                     id_var = "state_id",
                     time_var = "year")
  bacon_summary <- as.data.table(bacon_out)
  fwrite(bacon_summary, file.path(DATA_DIR, "bacon_decomposition.csv"))
  cat("  Bacon decomposition saved.\n")
}, error = function(e) {
  cat("  Bacon decomposition error:", e$message, "\n")
})

# =============================================================================
# SAVE SUMMARY TABLE
# =============================================================================
cat("\n=== Summary of main results ===\n")

summary_table <- data.table(
  outcome = c("Retention rate (CS-DiD)", "Retention rate (TWFE)",
              "Log enrollment (CS-DiD)", "Log enrollment (TWFE)",
              "Log completions (CS-DiD)", "Log completions (TWFE)"),
  estimate = c(simple_ret$overall.att, coef(twfe_ret)["pdmp_treated"],
               simple_enr$overall.att, coef(twfe_enr)["pdmp_treated"],
               simple_comp$overall.att, coef(twfe_comp)["pdmp_treated"]),
  se = c(simple_ret$overall.se, se(twfe_ret)["pdmp_treated"],
         simple_enr$overall.se, se(twfe_enr)["pdmp_treated"],
         simple_comp$overall.se, se(twfe_comp)["pdmp_treated"]),
  n = c(nrow(panel_ret), nobs(twfe_ret),
        nrow(panel_enr), nobs(twfe_enr),
        nrow(panel_comp), nobs(twfe_comp)),
  n_institutions = c(length(unique(panel_ret$unitid)), length(unique(panel_ret$unitid)),
                     length(unique(panel_enr$unitid)), length(unique(panel_enr$unitid)),
                     length(unique(panel_comp$unitid)), length(unique(panel_comp$unitid)))
)
summary_table[, `:=`(
  ci_lower = estimate - 1.96 * se,
  ci_upper = estimate + 1.96 * se,
  pvalue = 2 * pnorm(-abs(estimate / se))
)]

fwrite(summary_table, file.path(DATA_DIR, "main_results_summary.csv"))

cat("\n")
print(summary_table)
cat("\nMain analysis complete.\n")
