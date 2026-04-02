# =============================================================================
# 03_main_analysis.R — Reduced-form estimation: HEERF formula exposure → outcomes
# =============================================================================
# DESIGN: The predicted HEERF per student (from the 2018 Pell share × FTE formula)
# is exogenous by construction. We estimate the reduced-form / ITT effect of
# formula-predicted HEERF exposure on institutional outcomes directly.
# No 2SLS needed — the allocation formula IS the exogenous treatment intensity.

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")

# Treatment variable: predicted HEERF per student ($1,000s) × post-2020
# This captures continuous variation in HEERF formula exposure
cat(sprintf("Treatment: predicted_heerf_post (in $1,000s)\n"))
cat(sprintf("Range in post period: [%.2f, %.2f]\n",
            min(panel$predicted_heerf_post[panel$post == 1]),
            max(panel$predicted_heerf_post[panel$post == 1])))

# =============================================================================
# 1. MAIN RESULTS: Effect of formula exposure on outcomes
# =============================================================================

outcomes <- list(
  in_state_tuition = "In-state tuition ($)",
  grant_per_student = "Grant aid per student ($)",
  pell_per_recipient = "Pell grant per recipient ($)",
  inst_grant_per = "Institutional grant per student ($)",
  net_price_q1 = "Net price, Q1 income ($)",
  net_price_q5 = "Net price, Q5 income ($)",
  enrollment = "Enrollment (12-month)",
  completions = "Completions"
)

# Specification: Y_it = α_i + δ_s(i),t + β × PredictedHEERF_i × Post_t + ε_it
main_results <- list()
for (y in names(outcomes)) {
  n_valid <- sum(!is.na(panel[[y]]))
  if (n_valid < 100) {
    cat(sprintf("Skipping %s: only %d non-NA\n", y, n_valid))
    next
  }
  f <- as.formula(paste(y, "~ predicted_heerf_post | unitid + state_id^year"))
  tryCatch({
    main_results[[y]] <- feols(f, data = panel, cluster = ~unitid)
  }, error = function(e) cat(sprintf("Failed for %s: %s\n", y, e$message)))
}

cat("\n=== MAIN RESULTS ===\n")
cat("Effect of $1,000 increase in predicted HEERF per student (post-2020):\n\n")
for (y in names(main_results)) {
  m <- main_results[[y]]
  est <- coef(m)["predicted_heerf_post"]
  se_val <- se(m)["predicted_heerf_post"]
  p_val <- 2 * pnorm(-abs(est / se_val))
  pre_mean <- mean(panel[[y]][panel$year < 2020], na.rm = TRUE)
  pct <- est / pre_mean * 100
  cat(sprintf("%-30s: β = %10.2f  (SE = %8.2f)  p = %.4f  [%.1f%% of pre-mean]\n",
              outcomes[[y]], est, se_val, p_val, pct))
}

# Also run with simpler FE (unit + year only)
main_simple <- list()
for (y in names(main_results)) {
  f <- as.formula(paste(y, "~ predicted_heerf_post | unitid + year"))
  main_simple[[y]] <- feols(f, data = panel, cluster = ~unitid)
}

# =============================================================================
# 2. TOTAL REVENUE DECOMPOSITION
# =============================================================================

# Where does the HEERF money go? Check revenue composition
rev_outcomes <- c("total_revenue", "federal_revenue", "state_revenue",
                  "tuition_revenue")

rev_results <- list()
for (y in rev_outcomes) {
  # Per-student version
  panel[[paste0(y, "_ps")]] <- panel[[y]] / panel$enrollment
  f <- as.formula(paste0(y, "_ps ~ predicted_heerf_post | unitid + state_id^year"))
  tryCatch({
    rev_results[[y]] <- feols(f, data = panel, cluster = ~unitid)
  }, error = function(e) cat(sprintf("Rev failed for %s: %s\n", y, e$message)))
}

cat("\n=== REVENUE DECOMPOSITION (per student) ===\n")
for (y in names(rev_results)) {
  est <- coef(rev_results[[y]])["predicted_heerf_post"]
  se_val <- se(rev_results[[y]])["predicted_heerf_post"]
  cat(sprintf("%-25s: β = %10.2f  (SE = %8.2f)\n", y, est, se_val))
}

# =============================================================================
# 3. EVENT STUDY: Year-by-year effects
# =============================================================================

panel <- panel %>%
  mutate(year_factor = relevel(factor(year), ref = "2019"))

es_results <- list()
es_outcomes <- c("in_state_tuition", "grant_per_student", "enrollment", "net_price_q1")
for (y in es_outcomes) {
  n_valid <- sum(!is.na(panel[[y]]))
  if (n_valid < 100) next
  f <- as.formula(paste(y, "~ i(year_factor, predicted_heerf_per_student, ref = '2019') | unitid + state_id^year"))
  tryCatch({
    es_results[[y]] <- feols(f, data = panel, cluster = ~unitid)
  }, error = function(e) cat(sprintf("ES failed for %s: %s\n", y, e$message)))
}

cat("\n=== EVENT STUDY (pre-trend check) ===\n")
for (y in names(es_results)) {
  cat(sprintf("\n--- %s ---\n", y))
  ct <- coeftable(es_results[[y]])
  for (i in 1:nrow(ct)) {
    cat(sprintf("  %s: β = %.4f  (SE = %.4f)  p = %.4f\n",
                rownames(ct)[i], ct[i, 1], ct[i, 2], ct[i, 4]))
  }
}

# =============================================================================
# 4. DIAGNOSTICS
# =============================================================================

med_heerf <- median(panel$predicted_heerf_per_student)
n_high_exposure <- length(unique(panel$unitid[panel$predicted_heerf_per_student > med_heerf]))

diagnostics <- list(
  n_treated = n_high_exposure,
  n_pre = length(unique(panel$year[panel$year < 2020])),
  n_obs = nrow(panel),
  n_institutions = length(unique(panel$unitid)),
  n_years = length(unique(panel$year)),
  first_stage_f = 999,  # Reduced form — no first stage needed
  mean_predicted_heerf = mean(panel$predicted_heerf_per_student),
  sd_predicted_heerf = sd(panel$predicted_heerf_per_student)
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_high_exposure=%d, n_pre=%d, n_obs=%d\n",
            diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))

# =============================================================================
# 5. SAVE RESULTS
# =============================================================================

saveRDS(list(
  main = main_results,
  main_simple = main_simple,
  revenue = rev_results,
  event_study = es_results,
  panel = panel
), "../data/results.rds")

cat("\nAll main results saved.\n")
