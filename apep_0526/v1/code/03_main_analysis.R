# =============================================================================
# 03_main_analysis.R — Staggered DiD estimation (CS + TWFE + Event Study)
# =============================================================================
source("00_packages.R")

panel <- fread(file.path(DATA_DIR, "panel_state_quarter.csv"))
cat("Panel loaded:", nrow(panel), "rows\n")

# ---------------------------------------------------------------------------
# A. TWFE baseline (for reference — known to be biased with staggered adoption)
# ---------------------------------------------------------------------------
twfe_trials <- feols(
  ln_trials ~ treated | state_fips + time_id,
  data = panel, cluster = ~state_fips
)

twfe_enrollment <- feols(
  ln_enrollment ~ treated | state_fips + time_id,
  data = panel, cluster = ~state_fips
)

twfe_terminal <- feols(
  ln_terminal ~ treated | state_fips + time_id,
  data = panel, cluster = ~state_fips
)

cat("\n=== TWFE Results (reference only) ===\n")
cat("Trial sites:   ", round(coef(twfe_trials)["treated"], 4),
    " (se:", round(se(twfe_trials)["treated"], 4), ")\n")
cat("Enrollment:    ", round(coef(twfe_enrollment)["treated"], 4),
    " (se:", round(se(twfe_enrollment)["treated"], 4), ")\n")
cat("Terminal:      ", round(coef(twfe_terminal)["treated"], 4),
    " (se:", round(se(twfe_terminal)["treated"], 4), ")\n")

# Save TWFE coefficients
twfe_results <- data.table(
  outcome = c("ln_trials", "ln_enrollment", "ln_terminal"),
  coef = c(coef(twfe_trials)["treated"], coef(twfe_enrollment)["treated"],
           coef(twfe_terminal)["treated"]),
  se = c(se(twfe_trials)["treated"], se(twfe_enrollment)["treated"],
         se(twfe_terminal)["treated"]),
  pval = c(fixest::pvalue(twfe_trials)["treated"], fixest::pvalue(twfe_enrollment)["treated"],
           fixest::pvalue(twfe_terminal)["treated"]),
  n_obs = c(nobs(twfe_trials), nobs(twfe_enrollment), nobs(twfe_terminal))
)
fwrite(twfe_results, file.path(DATA_DIR, "twfe_results.csv"))

# ---------------------------------------------------------------------------
# B. Callaway-Sant'Anna (2021) — main estimator
# ---------------------------------------------------------------------------

# CS requires: yname (outcome), tname (time), idname (unit), gname (cohort)
# Cohort = 0 for never-treated

# Convert quarter to integer time index
panel[, state_id := as.integer(factor(state_fips))]

# Cohort: quarter index of adoption (0 for never-treated)
panel[, cohort_time := fifelse(cohort_yq > 0,
                                (floor(cohort_yq) - 2008) * 4 + round((cohort_yq %% 1) * 4) + 1,
                                0)]

# --- CS DiD for ln_trials ---
cat("\nRunning CS estimator for trial site counts...\n")
cs_trials <- tryCatch({
  att_gt(
    yname = "ln_trials",
    tname = "time_id",
    idname = "state_id",
    gname = "cohort_time",
    data = as.data.frame(panel),
    control_group = "notyettreated",
    anticipation = 0,
    est_method = "dr",
    base_period = "universal"
  )
}, error = function(e) {
  cat("CS estimator error:", e$message, "\n")
  cat("Attempting with nevertreated control group...\n")
  att_gt(
    yname = "ln_trials",
    tname = "time_id",
    idname = "state_id",
    gname = "cohort_time",
    data = as.data.frame(panel),
    control_group = "nevertreated",
    anticipation = 0,
    est_method = "dr",
    base_period = "universal"
  )
})

# Aggregate ATT
cs_agg_trials <- aggte(cs_trials, type = "simple")
cat("\nCS ATT (trial sites):", round(cs_agg_trials$overall.att, 4),
    " se:", round(cs_agg_trials$overall.se, 4),
    " p:", round(2 * pnorm(-abs(cs_agg_trials$overall.att / cs_agg_trials$overall.se)), 4), "\n")

# Dynamic effects (event study)
cs_es_trials <- aggte(cs_trials, type = "dynamic", min_e = -8, max_e = 8)

# Save event study coefficients
es_data_trials <- data.table(
  event_time = cs_es_trials$egt,
  att = cs_es_trials$att.egt,
  se = cs_es_trials$se.egt,
  ci_lower = cs_es_trials$att.egt - 1.96 * cs_es_trials$se.egt,
  ci_upper = cs_es_trials$att.egt + 1.96 * cs_es_trials$se.egt,
  outcome = "ln_trials"
)
fwrite(es_data_trials, file.path(DATA_DIR, "es_trials.csv"))

# --- CS DiD for ln_enrollment ---
cat("\nRunning CS estimator for enrollment...\n")
cs_enrollment <- tryCatch({
  att_gt(
    yname = "ln_enrollment",
    tname = "time_id",
    idname = "state_id",
    gname = "cohort_time",
    data = as.data.frame(panel),
    control_group = "notyettreated",
    anticipation = 0,
    est_method = "dr",
    base_period = "universal"
  )
}, error = function(e) {
  cat("CS estimator error for enrollment:", e$message, "\n")
  att_gt(
    yname = "ln_enrollment",
    tname = "time_id",
    idname = "state_id",
    gname = "cohort_time",
    data = as.data.frame(panel),
    control_group = "nevertreated",
    anticipation = 0,
    est_method = "dr",
    base_period = "universal"
  )
})

cs_agg_enrollment <- aggte(cs_enrollment, type = "simple")
cat("CS ATT (enrollment):", round(cs_agg_enrollment$overall.att, 4),
    " se:", round(cs_agg_enrollment$overall.se, 4), "\n")

cs_es_enrollment <- aggte(cs_enrollment, type = "dynamic", min_e = -8, max_e = 8)
es_data_enrollment <- data.table(
  event_time = cs_es_enrollment$egt,
  att = cs_es_enrollment$att.egt,
  se = cs_es_enrollment$se.egt,
  ci_lower = cs_es_enrollment$att.egt - 1.96 * cs_es_enrollment$se.egt,
  ci_upper = cs_es_enrollment$att.egt + 1.96 * cs_es_enrollment$se.egt,
  outcome = "ln_enrollment"
)
fwrite(es_data_enrollment, file.path(DATA_DIR, "es_enrollment.csv"))

# --- CS DiD for ln_terminal (terminal condition trials) ---
cat("\nRunning CS estimator for terminal condition trials...\n")
cs_terminal <- tryCatch({
  att_gt(
    yname = "ln_terminal",
    tname = "time_id",
    idname = "state_id",
    gname = "cohort_time",
    data = as.data.frame(panel),
    control_group = "notyettreated",
    anticipation = 0,
    est_method = "dr",
    base_period = "universal"
  )
}, error = function(e) {
  att_gt(
    yname = "ln_terminal",
    tname = "time_id",
    idname = "state_id",
    gname = "cohort_time",
    data = as.data.frame(panel),
    control_group = "nevertreated",
    anticipation = 0,
    est_method = "dr",
    base_period = "universal"
  )
})

cs_agg_terminal <- aggte(cs_terminal, type = "simple")
cat("CS ATT (terminal):", round(cs_agg_terminal$overall.att, 4),
    " se:", round(cs_agg_terminal$overall.se, 4), "\n")

cs_es_terminal <- aggte(cs_terminal, type = "dynamic", min_e = -8, max_e = 8)
es_data_terminal <- data.table(
  event_time = cs_es_terminal$egt,
  att = cs_es_terminal$att.egt,
  se = cs_es_terminal$se.egt,
  ci_lower = cs_es_terminal$att.egt - 1.96 * cs_es_terminal$se.egt,
  ci_upper = cs_es_terminal$att.egt + 1.96 * cs_es_terminal$se.egt,
  outcome = "ln_terminal"
)
fwrite(es_data_terminal, file.path(DATA_DIR, "es_terminal.csv"))

# ---------------------------------------------------------------------------
# C. Placebo outcomes (CS DiD)
# ---------------------------------------------------------------------------

# Placebo 1: Non-terminal condition trials
cat("\nRunning CS for PLACEBO: non-terminal trials...\n")
cs_nonterminal <- tryCatch({
  att_gt(
    yname = "ln_nonterminal",
    tname = "time_id",
    idname = "state_id",
    gname = "cohort_time",
    data = as.data.frame(panel),
    control_group = "notyettreated",
    anticipation = 0,
    est_method = "dr",
    base_period = "universal"
  )
}, error = function(e) {
  att_gt(
    yname = "ln_nonterminal",
    tname = "time_id",
    idname = "state_id",
    gname = "cohort_time",
    data = as.data.frame(panel),
    control_group = "nevertreated",
    anticipation = 0,
    est_method = "dr",
    base_period = "universal"
  )
})
cs_agg_nonterminal <- aggte(cs_nonterminal, type = "simple")
cat("CS ATT (non-terminal placebo):", round(cs_agg_nonterminal$overall.att, 4),
    " se:", round(cs_agg_nonterminal$overall.se, 4), "\n")

# Placebo 2: Phase I trials
cat("\nRunning CS for PLACEBO: Phase I trials...\n")
cs_phase1 <- tryCatch({
  att_gt(
    yname = "ln_phase1",
    tname = "time_id",
    idname = "state_id",
    gname = "cohort_time",
    data = as.data.frame(panel),
    control_group = "notyettreated",
    anticipation = 0,
    est_method = "dr",
    base_period = "universal"
  )
}, error = function(e) {
  att_gt(
    yname = "ln_phase1",
    tname = "time_id",
    idname = "state_id",
    gname = "cohort_time",
    data = as.data.frame(panel),
    control_group = "nevertreated",
    anticipation = 0,
    est_method = "dr",
    base_period = "universal"
  )
})
cs_agg_phase1 <- aggte(cs_phase1, type = "simple")
cat("CS ATT (Phase I placebo):", round(cs_agg_phase1$overall.att, 4),
    " se:", round(cs_agg_phase1$overall.se, 4), "\n")

# Placebo 3: Observational studies
cat("\nRunning CS for PLACEBO: observational studies...\n")
cs_obs <- tryCatch({
  att_gt(
    yname = "ln_observational",
    tname = "time_id",
    idname = "state_id",
    gname = "cohort_time",
    data = as.data.frame(panel),
    control_group = "notyettreated",
    anticipation = 0,
    est_method = "dr",
    base_period = "universal"
  )
}, error = function(e) {
  att_gt(
    yname = "ln_observational",
    tname = "time_id",
    idname = "state_id",
    gname = "cohort_time",
    data = as.data.frame(panel),
    control_group = "nevertreated",
    anticipation = 0,
    est_method = "dr",
    base_period = "universal"
  )
})
cs_agg_obs <- aggte(cs_obs, type = "simple")
cat("CS ATT (observational placebo):", round(cs_agg_obs$overall.att, 4),
    " se:", round(cs_agg_obs$overall.se, 4), "\n")

# Save placebo event study data
for (obj in list(
  list(cs = cs_nonterminal, name = "nonterminal"),
  list(cs = cs_phase1, name = "phase1"),
  list(cs = cs_obs, name = "observational")
)) {
  es <- aggte(obj$cs, type = "dynamic", min_e = -8, max_e = 8)
  es_dt <- data.table(
    event_time = es$egt, att = es$att.egt, se = es$se.egt,
    ci_lower = es$att.egt - 1.96 * es$se.egt,
    ci_upper = es$att.egt + 1.96 * es$se.egt,
    outcome = paste0("placebo_", obj$name)
  )
  fwrite(es_dt, file.path(DATA_DIR, paste0("es_placebo_", obj$name, ".csv")))
}

# ---------------------------------------------------------------------------
# D. Compile all CS results
# ---------------------------------------------------------------------------
cs_summary <- data.table(
  outcome = c("Trial Sites (Phase II/III)", "Total Enrollment",
              "Terminal Condition Trials",
              "PLACEBO: Non-Terminal Trials", "PLACEBO: Phase I Trials",
              "PLACEBO: Observational Studies"),
  att = c(cs_agg_trials$overall.att, cs_agg_enrollment$overall.att,
          cs_agg_terminal$overall.att,
          cs_agg_nonterminal$overall.att, cs_agg_phase1$overall.att,
          cs_agg_obs$overall.att),
  se = c(cs_agg_trials$overall.se, cs_agg_enrollment$overall.se,
         cs_agg_terminal$overall.se,
         cs_agg_nonterminal$overall.se, cs_agg_phase1$overall.se,
         cs_agg_obs$overall.se)
)
cs_summary[, pval := 2 * pnorm(-abs(att / se))]
cs_summary[, sig := fifelse(pval < 0.01, "***",
                    fifelse(pval < 0.05, "**",
                    fifelse(pval < 0.10, "*", "")))]

fwrite(cs_summary, file.path(DATA_DIR, "cs_summary.csv"))

cat("\n=== CS-DiD SUMMARY ===\n")
print(cs_summary)

# ---------------------------------------------------------------------------
# E. TWFE Event Study (fixest)
# ---------------------------------------------------------------------------

# Create relative time variable
panel[, rel_time := fifelse(cohort_yq > 0, time_id - cohort_time, NA_integer_)]

# Bin endpoints
panel[, rel_time_binned := fcase(
  is.na(rel_time), NA_integer_,
  rel_time < -8, -8L,
  rel_time > 8, 8L,
  default = as.integer(rel_time)
)]

# Event study with fixest (Sun-Abraham style)
es_fixest <- feols(
  ln_trials ~ i(rel_time_binned, ref = -1) | state_fips + time_id,
  data = panel[!is.na(rel_time_binned)],
  cluster = ~state_fips
)

# Save event study coefficients
es_fixest_dt <- data.table(
  event_time = as.integer(gsub("rel_time_binned::", "", names(coef(es_fixest)))),
  coef = coef(es_fixest),
  se = se(es_fixest)
)
es_fixest_dt[, ci_lower := coef - 1.96 * se]
es_fixest_dt[, ci_upper := coef + 1.96 * se]
fwrite(es_fixest_dt, file.path(DATA_DIR, "es_fixest.csv"))

cat("\nAll main analysis results saved.\n")
