## 04_robustness.R — Robustness and sensitivity analysis

source("00_packages.R")

panel_did <- readRDS("../data/panel_did.rds")
results <- readRDS("../data/results.rds")

cat("=== Robustness Checks ===\n")

# ================================================================
# 1. EXCLUDE COVID PERIOD (2020Q2 - 2021Q1)
# ================================================================
cat("\n--- 1. Excluding COVID period ---\n")

panel_nocovid <- panel_did[!(survey_year == 2020 & survey_quarter >= 2) &
                            !(survey_year == 2021 & survey_quarter <= 1)]

rob_nocovid <- feols(n_deficiencies ~ treated | ccn + survey_year,
                     data = panel_nocovid, vcov = ~state)
cat("TWFE excluding COVID (2020Q2-2021Q1):\n")
print(summary(rob_nocovid))

# ================================================================
# 2. LEAVE-ONE-STATE-OUT
# ================================================================
cat("\n--- 2. Leave-one-state-out sensitivity ---\n")

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
  } else {
    cat(sprintf("  LOO: dropping %s caused estimation failure (skipped)\n", drop_st))
  }
}

cat("Leave-one-out results (dropping treated states):\n")
print(loo_results)

cat(sprintf("Coefficient range: [%.3f, %.3f]\n",
            min(loo_results$coef), max(loo_results$coef)))

# ================================================================
# 3. PLACEBO: Use complaint deficiencies (less likely affected by staffing)
# ================================================================
cat("\n--- 3. Placebo: Complaint deficiencies ---\n")

rob_complaint <- feols(n_complaint ~ treated | ccn + survey_year,
                       data = panel_did, vcov = ~state)
cat("TWFE: treated → complaint deficiencies (placebo):\n")
print(summary(rob_complaint))

# ================================================================
# 4. SEVERITY: Restrict to severe deficiencies only
# ================================================================
cat("\n--- 4. Severe deficiencies only ---\n")

rob_severe <- feols(has_severe ~ treated | ccn + survey_year,
                    data = panel_did, vcov = ~state)
cat("TWFE: treated → has severe deficiency (G-L):\n")
print(summary(rob_severe))

# ================================================================
# 5. ALTERNATIVE CLUSTERING: Facility level
# ================================================================
cat("\n--- 5. Alternative clustering (facility) ---\n")

rob_fac_cluster <- feols(n_deficiencies ~ treated | ccn + survey_year,
                         data = panel_did, vcov = ~ccn)
cat("Clustered at facility level:\n")
cat(sprintf("  Coef: %.3f, SE: %.3f (vs state SE: %.3f)\n",
            coef(rob_fac_cluster)["treated"],
            sqrt(vcov(rob_fac_cluster)["treated","treated"]),
            results$twfe$n_def$se))

# ================================================================
# 6. BACON DECOMPOSITION (diagnostic for TWFE contamination)
# ================================================================
cat("\n--- 6. Bacon decomposition ---\n")

# Use facility-year panel for bacon
cs_yearly <- panel_did[, .(
  n_deficiencies = sum(n_deficiencies),
  treated = max(treated),
  cohort = cohort[1]
), by = .(ccn, state, survey_year)]

cs_yearly[, fac_id := as.integer(factor(ccn))]

bacon_data <- cs_yearly[, .(
  n_deficiencies = mean(n_deficiencies),
  treated = max(treated)
), by = .(fac_id, survey_year, cohort, state)]

tryCatch({
  # Bacon decomposition requires bacondecomp package
  if (requireNamespace("bacondecomp", quietly = TRUE)) {
    library(bacondecomp)
    bacon_out <- bacon(n_deficiencies ~ treated,
                       data = as.data.frame(bacon_data),
                       id_var = "fac_id",
                       time_var = "survey_year")
    cat("Bacon decomposition:\n")
    print(summary(bacon_out))
  } else {
    cat("bacondecomp package not available; skipping\n")
  }
}, error = function(e) {
  cat("Bacon decomposition error:", e$message, "\n")
})

# ================================================================
# 7. NY-SPECIFIC EVENT STUDY (cleanest cohort)
# ================================================================
cat("\n--- 7. NY-specific event study ---\n")

# NY has the cleanest mandate (Jan 2022, well within data window)
ny_data <- panel_did[state == "NY" | cohort == 0]
ny_data[, rel_year := survey_year - 2022L]
ny_data[, ny_treated := as.integer(state == "NY")]

# Event study
ny_es <- feols(n_deficiencies ~ i(rel_year, ny_treated, ref = -1) | ccn + survey_year,
               data = ny_data[abs(rel_year) <= 4],
               vcov = ~state)

cat("NY event study (relative to mandate year 2022):\n")
print(summary(ny_es))

# ================================================================
# Save robustness results
# ================================================================
rob_results <- list(
  nocovid = list(coef = coef(rob_nocovid)["treated"],
                 se = sqrt(vcov(rob_nocovid)["treated","treated"])),
  loo = loo_results,
  complaint_placebo = list(coef = coef(rob_complaint)["treated"],
                           se = sqrt(vcov(rob_complaint)["treated","treated"])),
  severe = list(coef = coef(rob_severe)["treated"],
                se = sqrt(vcov(rob_severe)["treated","treated"])),
  fac_cluster = list(coef = coef(rob_fac_cluster)["treated"],
                     se = sqrt(vcov(rob_fac_cluster)["treated","treated"]))
)

saveRDS(rob_results, "../data/robustness_results.rds")
saveRDS(ny_es, "../data/ny_event_study.rds")

cat("\n=== Robustness checks complete ===\n")
