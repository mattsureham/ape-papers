# 04_robustness.R — Robustness checks for apep_1442

source("00_packages.R")

cases <- fread("../data/pins_analysis.csv")

# =============================================================================
# 1. Monotonicity: Leniency quintile plot
# =============================================================================

cat("=== Monotonicity check: Allow rate by leniency quintile ===\n")

cases[, leniency_quintile := cut(leniency, breaks = quantile(leniency, probs = 0:5/5, na.rm = TRUE),
                                  include.lowest = TRUE, labels = 1:5)]

mono_check <- cases[!is.na(leniency_quintile), .(
  allow_rate = mean(allowed),
  n = .N
), by = leniency_quintile][order(leniency_quintile)]

print(mono_check)
cat("Allow rate should be monotonically increasing in leniency quintile.\n")

# =============================================================================
# 2. Leave-one-inspector-out: stability of first stage
# =============================================================================

cat("\n=== Leave-one-inspector-out sensitivity ===\n")

cases[, lpa_casetype := paste(lpa_clean, case_type_clean, sep = "_")]
cases[, year_casetype := paste(decision_year, case_type_clean, sep = "_")]

top_inspectors <- cases[, .N, by = inspector][order(-N)][1:min(20, .N), inspector]

loio_results <- data.table()
for (insp in top_inspectors) {
  tryCatch({
    subset <- cases[inspector != insp]
    fit <- feols(allowed ~ leniency | lpa_casetype + year_casetype,
                 data = subset, cluster = ~lpa_clean)
    loio_results <- rbind(loio_results, data.table(
      dropped = insp,
      coef = coef(fit)["leniency"],
      se = se(fit)["leniency"],
      n = nrow(subset)
    ))
  }, error = function(e) NULL)
}

cat("Leave-one-inspector-out first stage coefficients:\n")
cat(sprintf("  Range: [%.4f, %.4f]\n", min(loio_results$coef), max(loio_results$coef)))
cat(sprintf("  Mean:  %.4f\n", mean(loio_results$coef)))

# Full sample coefficient for comparison
full_fit <- feols(allowed ~ leniency | lpa_casetype + year_casetype,
                  data = cases, cluster = ~lpa_clean)
cat(sprintf("  Full sample: %.4f\n", coef(full_fit)["leniency"]))

fwrite(loio_results, "../data/loio_results.csv")

# =============================================================================
# 3. Alternative leniency definitions
# =============================================================================

cat("\n=== Alternative leniency definitions ===\n")

# a) Overall inspector rate (not cell-specific)
cases[, insp_overall_total := sum(allowed), by = inspector]
cases[, insp_overall_n := .N, by = inspector]
cases[, leniency_overall := (insp_overall_total - allowed) / (insp_overall_n - 1)]

fs_overall <- feols(allowed ~ leniency_overall | lpa_casetype + year_casetype,
                    data = cases, cluster = ~lpa_clean)
cat("Alt leniency (overall, no cell): coef =", round(coef(fs_overall)[1], 4),
    "SE =", round(se(fs_overall)[1], 4), "\n")

# b) Excluding same-LPA cases from leniency calculation
# (addresses concern about LPA-specific unobservables)
cases[, insp_lpa_total := sum(allowed), by = .(inspector, lpa_clean)]
cases[, insp_lpa_n := .N, by = .(inspector, lpa_clean)]
cases[, leniency_exlpa := (insp_overall_total - insp_lpa_total) /
        pmax(insp_overall_n - insp_lpa_n, 1)]

fs_exlpa <- feols(allowed ~ leniency_exlpa | lpa_casetype + year_casetype,
                  data = cases[insp_overall_n > insp_lpa_n], cluster = ~lpa_clean)
cat("Alt leniency (ex-LPA): coef =", round(coef(fs_exlpa)[1], 4),
    "SE =", round(se(fs_exlpa)[1], 4), "\n")

# =============================================================================
# 4. Subsample: Planning appeals only (exclude householder)
# =============================================================================

cat("\n=== Subsample: Planning appeals only ===\n")

planning_only <- cases[case_type_clean == "Planning"]
if (nrow(planning_only) > 100) {
  fs_planning <- feols(allowed ~ leniency | lpa_clean + decision_year,
                       data = planning_only, cluster = ~lpa_clean)
  cat("Planning appeals only: coef =", round(coef(fs_planning)[1], 4),
      "SE =", round(se(fs_planning)[1], 4), "N =", nrow(planning_only), "\n")
}

# Householder appeals only
hh_only <- cases[case_type_clean == "Householder"]
if (nrow(hh_only) > 100) {
  fs_hh <- feols(allowed ~ leniency | lpa_clean + decision_year,
                 data = hh_only, cluster = ~lpa_clean)
  cat("Householder appeals only: coef =", round(coef(fs_hh)[1], 4),
      "SE =", round(se(fs_hh)[1], 4), "N =", nrow(hh_only), "\n")
}

# =============================================================================
# 5. Placebo: Pre-period leniency should not predict outcomes
# =============================================================================

cat("\n=== Placebo: lagged leniency ===\n")

# Create lagged leniency by shifting one year
cases[, lag_year := decision_year - 1]
lag_leniency <- cases[, .(lag_leniency = mean(leniency)), by = .(inspector, decision_year)]
setnames(lag_leniency, "decision_year", "lag_year")

cases_lag <- merge(cases, lag_leniency, by.x = c("inspector", "decision_year"),
                   by.y = c("inspector", "lag_year"), all.x = TRUE)

if (sum(!is.na(cases_lag$lag_leniency)) > 200) {
  fs_placebo <- feols(allowed ~ lag_leniency | lpa_casetype + year_casetype,
                      data = cases_lag[!is.na(lag_leniency)], cluster = ~lpa_clean)
  cat("Placebo (lagged leniency): coef =", round(coef(fs_placebo)[1], 4),
      "SE =", round(se(fs_placebo)[1], 4), "\n")
}

# Save robustness results
saveRDS(list(
  mono_check = mono_check,
  loio_results = loio_results,
  fs_overall = fs_overall,
  fs_exlpa = fs_exlpa
), "../data/robustness_results.rds")

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
