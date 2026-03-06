###############################################################################
# 03_main_analysis.R — Main analysis: panel + event study
# APEP-0541: How Many Generics Does It Take?
###############################################################################

source("00_packages.R")

data_dir <- "../data"
panel   <- fread(file.path(data_dir, "analysis_panel.csv"))
events  <- fread(file.path(data_dir, "event_panel.csv"))

cat("Panel:", nrow(panel), "obs,", uniqueN(panel$market), "markets\n")
cat("Event panel:", nrow(events), "obs,", uniqueN(events$event_id), "events\n")

# ==========================================================================
# 1. PANEL REGRESSION: Within-market effect of competitor count
# ==========================================================================

cat("\n=== Panel Regressions ===\n")

panel[, week_date := as.Date(week)]

# Main specification: log(price) on N_competitors with market + week FE
# This uses within-market variation over time
est_main <- feols(log_price ~ n_competitors | market_id + week_date,
                  data = panel, cluster = ~market_id)

cat("Main: log(price) ~ N | market + week FE\n")
cat("  Coefficient on N:", round(coef(est_main)["n_competitors"], 4), "\n")
cat("  SE:", round(se(est_main)["n_competitors"], 4), "\n")
cat("  t-stat:", round(tstat(est_main)["n_competitors"], 2), "\n")
cat("  N:", nobs(est_main), ", Markets:", length(unique(panel$market_id)), "\n")

# Log-log specification
panel[, log_n := log(n_competitors)]
est_loglog <- feols(log_price ~ log_n | market_id + week_date,
                    data = panel, cluster = ~market_id)
cat("\nLog-log: log(price) ~ log(N) | market + week FE\n")
cat("  Elasticity:", round(coef(est_loglog)["log_n"], 4), "\n")
cat("  SE:", round(se(est_loglog)["log_n"], 4), "\n")

# Non-parametric: dummy variables for each competitor count
panel[, n_bin := pmin(n_competitors, 15)]  # Cap at 15+
est_nonparam <- feols(log_price ~ i(n_bin, ref = 1) | market_id + week_date,
                      data = panel, cluster = ~market_id)

# Extract the non-parametric competition curve
np_coefs <- as.data.table(coeftable(est_nonparam), keep.rownames = "term")
setnames(np_coefs, c("term", "estimate", "se", "tstat", "pval"))
np_coefs[, n_competitors := as.integer(gsub("n_bin::", "", term))]
np_coefs <- np_coefs[!is.na(n_competitors)]
np_coefs[, `:=`(ci_lo = estimate - 1.96 * se, ci_hi = estimate + 1.96 * se)]

cat("\nNon-parametric competition curve (market + week FE):\n")
cat(sprintf("%-8s %-12s %-10s %-10s\n", "N", "Effect", "SE", "Sig"))
for (i in seq_len(nrow(np_coefs))) {
  r <- np_coefs[i]
  cat(sprintf("%-8d %-12.4f %-10.4f %-10s\n",
              r$n_competitors, r$estimate, r$se,
              ifelse(abs(r$tstat) > 1.96, "***", "")))
}

fwrite(np_coefs, file.path(data_dir, "nonparam_curve.csv"))

# ==========================================================================
# 2. EVENT STUDY: Price dynamics around new competitor entry
# ==========================================================================

cat("\n=== Event Study ===\n")

events[, event_time_int := as.integer(event_time)]

# Pool all events: price response to a new competitor arriving
est_event_all <- tryCatch({
  feols(log_price ~ i(event_time_int, ref = -1) | event_id + week,
        data = events, cluster = ~event_id)
}, error = function(e) {
  cat("Pooled event study failed:", e$message, "\n")
  NULL
})

if (!is.null(est_event_all)) {
  es_coefs <- as.data.table(coeftable(est_event_all), keep.rownames = "term")
  setnames(es_coefs, c("term", "estimate", "se", "tstat", "pval"))
  es_coefs[, event_time := as.integer(gsub("event_time_int::", "", term))]
  es_coefs <- es_coefs[!is.na(event_time)]
  es_coefs[, `:=`(ci_lo = estimate - 1.96 * se, ci_hi = estimate + 1.96 * se)]
  es_coefs[, specification := "all_events"]

  # Pre-trend test
  pre <- es_coefs[event_time < 0]
  f_pre <- sum((pre$estimate / pre$se)^2) / nrow(pre)
  p_pre <- pf(f_pre, nrow(pre), Inf, lower.tail = FALSE)
  cat(sprintf("Pooled event study: F(pre) = %.2f, p = %.4f %s\n",
              f_pre, p_pre, ifelse(p_pre > 0.05, "PASS", "FAIL")))

  avg_post <- mean(es_coefs[event_time > 0]$estimate, na.rm = TRUE)
  cat(sprintf("  Average post-entry effect: %.4f\n", avg_post))

  fwrite(es_coefs, file.path(data_dir, "event_study_coefficients.csv"))
}

# By pre-entry competitor count groups: low (1-3), medium (4-8), high (9+)
events[, n_group := ifelse(n_before <= 3, "Low (1-3)",
                   ifelse(n_before <= 8, "Medium (4-8)", "High (9+)"))]

group_results <- list()
for (grp in c("Low (1-3)", "Medium (4-8)", "High (9+)")) {
  grp_data <- events[n_group == grp]
  n_ev <- uniqueN(grp_data$event_id)
  if (n_ev < 15) {
    cat(sprintf("  %s: %d events — skipping\n", grp, n_ev))
    next
  }

  est_grp <- tryCatch({
    feols(log_price ~ i(event_time_int, ref = -1) | event_id + week,
          data = grp_data, cluster = ~event_id)
  }, error = function(e) NULL)

  if (!is.null(est_grp)) {
    ct <- as.data.table(coeftable(est_grp), keep.rownames = "term")
    setnames(ct, c("term", "estimate", "se", "tstat", "pval"))
    ct[, event_time := as.integer(gsub("event_time_int::", "", term))]
    ct <- ct[!is.na(event_time)]
    ct[, `:=`(ci_lo = estimate - 1.96 * se, ci_hi = estimate + 1.96 * se,
              n_group = grp, n_events = n_ev)]

    avg_p <- mean(ct[event_time > 0]$estimate, na.rm = TRUE)
    cat(sprintf("  %s: %d events, avg post = %.4f\n", grp, n_ev, avg_p))

    group_results[[grp]] <- ct
  }
}

if (length(group_results) > 0) {
  group_coefs <- rbindlist(group_results)
  fwrite(group_coefs, file.path(data_dir, "event_study_by_group.csv"))
}

# ==========================================================================
# 3. Marginal competition curve from panel
# ==========================================================================

cat("\n=== Marginal Competition Curve ===\n")

# The marginal curve comes from the non-parametric panel regression
# β_N gives the price at N competitors relative to N=1
# The MARGINAL effect of the Nth competitor is β_N - β_{N-1}

marginal <- np_coefs[order(n_competitors)]
marginal[, marginal_effect := estimate - shift(estimate, type = "lag")]
marginal[, marginal_effect := ifelse(is.na(marginal_effect), estimate, marginal_effect)]
marginal[, marginal_se := sqrt(se^2 + shift(se, type = "lag")^2)]
marginal[, marginal_se := ifelse(is.na(marginal_se), se, marginal_se)]
marginal[, `:=`(
  marginal_ci_lo = marginal_effect - 1.96 * marginal_se,
  marginal_ci_hi = marginal_effect + 1.96 * marginal_se,
  marginal_sig = abs(marginal_effect / marginal_se) > 1.96
)]

cat("Marginal Competition Curve:\n")
cat(sprintf("%-5s %-12s %-12s %-12s %-12s %-8s\n",
            "N", "Cumul Eff", "Marginal", "95% CI Lo", "95% CI Hi", "Sig"))
for (i in seq_len(nrow(marginal))) {
  r <- marginal[i]
  cat(sprintf("%-5d %-12.4f %-12.4f %-12.4f %-12.4f %-8s\n",
              r$n_competitors, r$estimate, r$marginal_effect,
              r$marginal_ci_lo, r$marginal_ci_hi,
              ifelse(r$marginal_sig, "***", "")))
}

# Find threshold: first N where marginal effect is not significant
threshold_row <- marginal[marginal_sig == FALSE, .SD[1]]
if (nrow(threshold_row) > 0) {
  cat(sprintf("\nEffectively competitive threshold: N* = %d\n",
              threshold_row$n_competitors))
} else {
  cat("\nAll marginal effects significant — threshold beyond sample\n")
}

# Save marginal curve (compatible with figures/tables scripts)
marginal_out <- marginal[, .(
  entry_position = n_competitors,
  effect_52wk = estimate,        # cumulative effect
  se_52wk = se,
  ci_lo_52 = ci_lo,
  ci_hi_52 = ci_hi,
  avg_post_effect = marginal_effect,  # marginal effect
  se_avg_post = marginal_se,
  effect_24wk = estimate,        # same for compatibility
  n_events = as.integer(NA),
  ci_lo_avg = marginal_ci_lo,
  ci_hi_avg = marginal_ci_hi,
  sig_at_52 = abs(tstat) > 1.96
)]

fwrite(marginal_out, file.path(data_dir, "marginal_curve.csv"))

# Pre-trend tests (from event study)
pretrend_tests <- data.table(
  entry_position = 0,
  n_pre_coefs = nrow(pre),
  f_stat = f_pre,
  p_value = p_pre,
  max_abs_pre_coef = max(abs(pre$estimate)),
  passes = p_pre > 0.05
)
fwrite(pretrend_tests, file.path(data_dir, "pretrend_tests.csv"))

# ==========================================================================
# 4. Save regression results for tables
# ==========================================================================

# Main regression table
reg_results <- list(
  "Linear" = est_main,
  "Log-Log" = est_loglog,
  "Non-Parametric" = est_nonparam
)

# Save coefficient summary
main_results <- data.table(
  specification = c("Linear (N)", "Log-Log (log N)"),
  coefficient = c(coef(est_main)["n_competitors"],
                  coef(est_loglog)["log_n"]),
  se = c(se(est_main)["n_competitors"],
         se(est_loglog)["log_n"]),
  tstat = c(tstat(est_main)["n_competitors"],
            tstat(est_loglog)["log_n"]),
  n_obs = c(nobs(est_main), nobs(est_loglog)),
  n_markets = c(uniqueN(panel$market_id), uniqueN(panel$market_id))
)

fwrite(main_results, file.path(data_dir, "main_regression_results.csv"))

cat("\nMain analysis complete.\n")
