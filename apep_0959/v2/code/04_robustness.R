## 04_robustness.R — V2 Robustness and Sensitivity
## HonestDiD, wild cluster bootstrap, enforcement confound tests

source("00_packages.R")

panel_did <- readRDS("../data/panel_did.rds")
results <- readRDS("../data/results_v2.rds")
cs_yearly <- readRDS("../data/cs_yearly.rds")

cat("=== V2 Robustness Checks ===\n")

# ================================================================
# 1. HonestDiD: Pre-trend sensitivity analysis
# ================================================================
cat("\n--- 1. HonestDiD Pre-Trend Sensitivity ---\n")

# Run Sun-Abraham event study for HonestDiD input
cs_yearly[, rel_year := fifelse(cohort > 0, survey_year - cohort, -1000L)]
sa_es <- tryCatch({
  feols(n_deficiencies ~ sunab(cohort, survey_year) | fac_id + survey_year,
        data = cs_yearly[cohort > 0 | cohort == 0],
        vcov = ~state)
}, error = function(e) { cat("SA error:", e$message, "\n"); NULL })

if (!is.null(sa_es)) {
  cat("Sun-Abraham event study coefficients:\n")
  print(summary(sa_es))

  # HonestDiD: sensitivity to pre-trend violations
  honest_result <- tryCatch({
    # Extract the event-study coefficients and variance-covariance matrix
    betahat <- coef(sa_es)
    sigma <- vcov(sa_es)

    # Identify pre and post period indices from coefficient names
    coef_names <- names(betahat)
    pre_idx <- grep("::-[2-9]|::-1[0-9]", coef_names)
    post_idx <- grep("::0$|::[1-9]|::[1-9][0-9]", coef_names)

    if (length(pre_idx) >= 1 && length(post_idx) >= 1) {
      cat(sprintf("Pre-period indices: %d, Post-period indices: %d\n",
                  length(pre_idx), length(post_idx)))

      # Relative magnitudes approach
      delta_rm <- createSensitivityResults_relativeMagnitudes(
        betahat = betahat,
        sigma = sigma,
        numPrePeriods = length(pre_idx),
        numPostPeriods = length(post_idx),
        Mbarvec = seq(0, 2, by = 0.5)
      )
      cat("\nHonestDiD (Relative Magnitudes):\n")
      print(delta_rm)
      delta_rm
    } else {
      cat("Could not identify pre/post indices for HonestDiD\n")
      NULL
    }
  }, error = function(e) {
    cat("HonestDiD error:", e$message, "\n")
    NULL
  })

  if (!is.null(honest_result)) {
    saveRDS(honest_result, "../data/honestdid_results.rds")
  }
}

# ================================================================
# 2. LEAVE-ONE-STATE-OUT
# ================================================================
cat("\n--- 2. Leave-one-state-out ---\n")

treated_states <- unique(panel_did$state[panel_did$cohort > 0])
loo_results <- data.table()

for (drop_st in treated_states) {
  loo_data <- panel_did[state != drop_st]
  loo_reg <- tryCatch({
    feols(n_deficiencies ~ treated | ccn + survey_year,
          data = loo_data, vcov = ~state)
  }, error = function(e) NULL)
  if (!is.null(loo_reg)) {
    loo_results <- rbind(loo_results, data.table(
      dropped = drop_st,
      coef = coef(loo_reg)["treated"],
      se = sqrt(vcov(loo_reg)["treated", "treated"])
    ))
  }
}

cat("Leave-one-out results:\n")
print(loo_results)
cat(sprintf("Coefficient range: [%.3f, %.3f]\n",
            min(loo_results$coef), max(loo_results$coef)))

# ================================================================
# 3. PLACEBO: Complaint deficiencies (no detection channel)
# ================================================================
cat("\n--- 3. Complaint placebo ---\n")

placebo_complaint <- feols(n_complaint ~ treated | ccn + survey_year,
                           data = panel_did, vcov = ~state)
cat("Complaint deficiency placebo:\n")
print(summary(placebo_complaint))

# V2: Placebo by detection mode
placebo_report <- feols(n_report ~ treated | ccn + survey_year,
                        data = panel_did, vcov = ~state)
cat("Report-dependent deficiency placebo:\n")
print(summary(placebo_report))

# ================================================================
# 4. SEVERITY: Extra citations by severity level
# ================================================================
cat("\n--- 4. Severity decomposition ---\n")

sev_minimal <- feols(n_minimal ~ treated | ccn + survey_year,
                     data = panel_did, vcov = ~state)
sev_moderate <- feols(n_moderate ~ treated | ccn + survey_year,
                      data = panel_did, vcov = ~state)
sev_harm <- feols(n_actual_harm ~ treated | ccn + survey_year,
                  data = panel_did, vcov = ~state)
sev_jeopardy <- feols(n_jeopardy ~ treated | ccn + survey_year,
                      data = panel_did, vcov = ~state)

cat("Severity decomposition (pooled):\n")
cat(sprintf("  Minimal (A-C): %.3f (%.3f)\n", coef(sev_minimal)["treated"],
            sqrt(vcov(sev_minimal)["treated", "treated"])))
cat(sprintf("  Moderate (D-F): %.3f (%.3f)\n", coef(sev_moderate)["treated"],
            sqrt(vcov(sev_moderate)["treated", "treated"])))
cat(sprintf("  Actual harm (G-I): %.3f (%.3f)\n", coef(sev_harm)["treated"],
            sqrt(vcov(sev_harm)["treated", "treated"])))
cat(sprintf("  Jeopardy (J-L): %.3f (%.3f)\n", coef(sev_jeopardy)["treated"],
            sqrt(vcov(sev_jeopardy)["treated", "treated"])))

# ================================================================
# 5. EXCLUDE COVID
# ================================================================
cat("\n--- 5. Exclude COVID ---\n")

panel_nocovid <- panel_did[!(survey_year == 2020 & survey_quarter >= 2) &
                            !(survey_year == 2021 & survey_quarter <= 1)]
rob_nocovid <- feols(n_deficiencies ~ treated | ccn + survey_year,
                     data = panel_nocovid, vcov = ~state)
cat("Excluding COVID:\n")
print(summary(rob_nocovid))

# ================================================================
# 6. FACILITY-LEVEL CLUSTERING
# ================================================================
cat("\n--- 6. Facility-level clustering ---\n")

rob_fac <- feols(n_deficiencies ~ treated | ccn + survey_year,
                 data = panel_did, vcov = ~ccn)
cat(sprintf("Facility-clustered: β=%.3f, SE=%.3f (vs state SE=%.3f)\n",
            coef(rob_fac)["treated"],
            sqrt(vcov(rob_fac)["treated", "treated"]),
            sqrt(vcov(results$pooled$twfe)["treated", "treated"])))

# ================================================================
# 7. NY-ONLY EVENT STUDY (detailed)
# ================================================================
cat("\n--- 7. NY event study (detailed) ---\n")

ny_data <- panel_did[state == "NY" | cohort == 0]
# All facilities get relative year (centered on NY mandate 2022)
ny_data[, rel_year := survey_year - 2022L]
ny_data[, ny_treat := as.integer(state == "NY")]
ny_data <- ny_data[abs(rel_year) <= 4]

# Main outcome: diff-in-diff event study (NY vs controls over time)
ny_es_main <- tryCatch({
  feols(n_deficiencies ~ i(rel_year, ny_treat, ref = -1) | ccn + survey_year,
        data = ny_data, vcov = ~state)
}, error = function(e) { cat("NY ES error:", e$message, "\n"); NULL })
if (!is.null(ny_es_main)) {
  cat("NY event study (total deficiencies):\n")
  print(summary(ny_es_main))
}

# By detection mode
ny_es_obs <- tryCatch({
  feols(n_observation ~ i(rel_year, ny_treat, ref = -1) | ccn + survey_year,
        data = ny_data, vcov = ~state)
}, error = function(e) NULL)
ny_es_rpt <- tryCatch({
  feols(n_report ~ i(rel_year, ny_treat, ref = -1) | ccn + survey_year,
        data = ny_data, vcov = ~state)
}, error = function(e) NULL)

cat("\nNY event study (observation-dependent):\n")
print(summary(ny_es_obs))
cat("\nNY event study (report-dependent):\n")
print(summary(ny_es_rpt))

# ================================================================
# 8. DOWNSTREAM: Star Rating Changes
# ================================================================
cat("\n--- 8. Downstream: Star ratings ---\n")

# Health inspection rating (1-5 star)
if ("health_rating" %in% colnames(panel_did) && sum(!is.na(panel_did$health_rating)) > 100) {
  ds_health <- feols(health_rating ~ treated | ccn + survey_year,
                     data = panel_did, vcov = ~state)
  cat("Health inspection rating:\n")
  print(summary(ds_health))

  ds_overall <- feols(overall_rating ~ treated | ccn + survey_year,
                      data = panel_did, vcov = ~state)
  cat("Overall rating:\n")
  print(summary(ds_overall))
} else {
  cat("Star rating data not available in panel\n")
}

# ================================================================
# Save all robustness results
# ================================================================
rob_results <- list(
  loo = loo_results,
  placebo_complaint = placebo_complaint,
  placebo_report = placebo_report,
  severity = list(minimal = sev_minimal, moderate = sev_moderate,
                  harm = sev_harm, jeopardy = sev_jeopardy),
  nocovid = rob_nocovid,
  fac_cluster = rob_fac,
  ny_es = list(main = ny_es_main, obs = ny_es_obs, rpt = ny_es_rpt),
  sa_es = sa_es
)

saveRDS(rob_results, "../data/robustness_v2.rds")

cat("\n=== Robustness checks complete ===\n")
