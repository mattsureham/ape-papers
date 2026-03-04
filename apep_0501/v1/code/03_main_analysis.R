## 03_main_analysis.R — Primary DiD estimation
## apep_0501: Municipal Mergers and Direct Democracy in Switzerland

source("00_packages.R")

DATA_DIR <- "../data"

# =============================================================================
# 1. LOAD ANALYSIS PANEL
# =============================================================================

cat("=== Loading analysis panel ===\n")

panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
panel[, vote_date := as.Date(vote_date)]

cat(sprintf("Panel: %s observations, %d communes, %d votes\n",
            format(nrow(panel), big.mark = ","),
            uniqueN(panel$commune_code),
            uniqueN(panel$vote_date)))

# =============================================================================
# 2. DESCRIPTIVE STATISTICS
# =============================================================================

cat("\n=== Descriptive statistics ===\n")

# Turnout trends by treatment status
turnout_trends <- panel[, .(
  mean_turnout = mean(turnout_final, na.rm = TRUE),
  sd_turnout = sd(turnout_final, na.rm = TRUE),
  n_obs = .N,
  n_communes = uniqueN(commune_code)
), by = .(vote_year, treated)]

cat("Mean turnout by year and treatment status (sample):\n")
print(turnout_trends[vote_year %in% c(1980, 1990, 2000, 2010, 2020)])

# Balance table: pre-treatment means
pre_treatment <- panel[treated == TRUE & post == FALSE |
                        treated == FALSE]
balance <- pre_treatment[vote_year >= 2000 & vote_year <= 2005, .(
  mean_turnout = mean(turnout_final, na.rm = TRUE),
  mean_eligible = mean(as.numeric(eligible), na.rm = TRUE),
  mean_yes_share = mean(yes_share, na.rm = TRUE),
  n_communes = uniqueN(commune_code)
), by = treated]
cat("\nPre-treatment balance (2000-2005):\n")
print(balance)

# =============================================================================
# 3. TWFE BASELINE
# =============================================================================

cat("\n=== TWFE baseline estimation ===\n")

# Main specification: turnout ~ post | commune + vote_date
baseline_twfe <- feols(turnout_final ~ post | commune_id + vote_id,
                        data = panel, cluster = ~commune_id)
cat("Baseline TWFE:\n")
print(summary(baseline_twfe))

# With treatment intensity (log eligible change)
panel[, log_eligible_num := log(as.numeric(eligible) + 1)]
intensity_twfe <- feols(turnout_final ~ post + post:log_eligible_num |
                          commune_id + vote_id,
                        data = panel, cluster = ~commune_id)

# =============================================================================
# 4. EVENT STUDY (TWFE)
# =============================================================================

cat("\n=== Event study ===\n")

# Create event-time bins (relative to merger year)
# Bin at ±10 years, with endpoints absorbing tails
panel[, event_bin := fcase(
  treated == FALSE, NA_integer_,
  event_year < -10, -10L,
  event_year > 10, 10L,
  default = as.integer(event_year)
)]

# Reference period: event_bin = -1 (year before merger)
panel[, event_bin_factor := factor(event_bin)]
panel[, event_bin_factor := relevel(event_bin_factor, ref = "-1")]

# TWFE event study
event_twfe <- feols(turnout_final ~ i(event_bin, ref = -1) | commune_id + vote_id,
                     data = panel[treated == TRUE | treated == FALSE],
                     cluster = ~commune_id)
cat("Event study coefficients:\n")
print(coeftable(event_twfe))

# Save event study coefficients for plotting
es_coefs <- as.data.table(coeftable(event_twfe), keep.rownames = TRUE)
setnames(es_coefs, c("term", "estimate", "se", "tstat", "pvalue"))
es_coefs[, event_time := as.integer(str_extract(term, "-?\\d+"))]
es_coefs <- es_coefs[!is.na(event_time)]
fwrite(es_coefs, file.path(DATA_DIR, "event_study_twfe.csv"))

# =============================================================================
# 5. CALLAWAY & SANT'ANNA (2021) — HETEROGENEITY-ROBUST
# =============================================================================

cat("\n=== Callaway & Sant'Anna estimation ===\n")

# Prepare data for did::att_gt
# Need: yname, tname, idname, gname (group = first treatment year, 0 = never treated)
did_data <- panel[, .(
  commune_id = commune_id,
  vote_year = vote_year,
  turnout = turnout_final,
  group = fifelse(treated == TRUE, as.integer(treatment_year), 0L)
)]

# Remove duplicates (take mean turnout per commune-year)
did_data <- did_data[, .(
  turnout = mean(turnout, na.rm = TRUE),
  group = first(group)
), by = .(commune_id, vote_year)]

# Remove rows with NA and ensure balanced-ish panel
did_data <- did_data[!is.na(turnout) & !is.na(vote_year)]

# Ensure group is clean integer (0 for never-treated)
did_data[, group := as.integer(group)]
did_data[is.na(group), group := 0L]

cat(sprintf("CS-DiD data: %d obs, %d units, %d groups\n",
            nrow(did_data), uniqueN(did_data$commune_id),
            uniqueN(did_data$group)))

# Callaway & Sant'Anna
cs_result <- tryCatch({
  att_gt(
    yname = "turnout",
    tname = "vote_year",
    idname = "commune_id",
    gname = "group",
    data = as.data.frame(did_data),
    control_group = "nevertreated",
    anticipation = 0,
    est_method = "reg"
  )
}, error = function(e) {
  cat("CS-DiD error:", e$message, "\n")
  NULL
})

if (!is.null(cs_result)) {
  # Aggregate to event-study and overall ATT
  cs_agg <- aggte(cs_result, type = "dynamic", min_e = -10, max_e = 10)
  cat("\nCS-DiD Dynamic ATT:\n")
  print(summary(cs_agg))

  cs_overall <- aggte(cs_result, type = "simple")
  cat("\nCS-DiD Overall ATT:\n")
  print(summary(cs_overall))

  # Save CS event study
  cs_es <- data.table(
    event_time = cs_agg$egt,
    estimate = cs_agg$att.egt,
    se = cs_agg$se.egt
  )
  cs_es[, ci_lower := estimate - 1.96 * se]
  cs_es[, ci_upper := estimate + 1.96 * se]
  fwrite(cs_es, file.path(DATA_DIR, "event_study_cs.csv"))
}

# =============================================================================
# 6. PRE-TREND TESTS
# =============================================================================

cat("\n=== Pre-trend diagnostics ===\n")

# Joint F-test on pre-treatment event-study coefficients
pre_coefs <- es_coefs[event_time < -1]
if (nrow(pre_coefs) > 0) {
  # Joint significance test
  pre_f_stat <- sum(pre_coefs$estimate^2 / pre_coefs$se^2) / nrow(pre_coefs)
  pre_f_pval <- 1 - pf(pre_f_stat, nrow(pre_coefs), baseline_twfe$nobs - baseline_twfe$nparams)
  cat(sprintf("Pre-trend F-test: F = %.3f, p = %.4f\n", pre_f_stat, pre_f_pval))
  cat(sprintf("  (Null: all pre-treatment coefficients = 0)\n"))

  # Max pre-treatment coefficient magnitude
  max_pre <- max(abs(pre_coefs$estimate))
  cat(sprintf("Max pre-treatment coefficient: %.4f\n", max_pre))
}

# =============================================================================
# 7. HONESTDID SENSITIVITY
# =============================================================================

cat("\n=== HonestDiD sensitivity analysis ===\n")

# Run HonestDiD on the TWFE event study
tryCatch({
  # Extract the pre- and post-treatment estimates
  betahat <- coef(event_twfe)
  sigma <- vcov(event_twfe)

  # Identify pre and post indices
  coef_names <- names(betahat)
  pre_idx <- which(grepl("event_bin::-[0-9]", coef_names) &
                     !grepl("::-1$", coef_names))
  post_idx <- which(grepl("event_bin::[0-9]", coef_names))

  if (length(pre_idx) > 0 && length(post_idx) > 0) {
    # Subset to only pre and post indices for HonestDiD
    all_idx <- c(pre_idx, post_idx)
    betahat_sub <- betahat[all_idx]
    sigma_sub <- sigma[all_idx, all_idx]

    honest_result <- tryCatch({
      HonestDiD::createSensitivityResults(
        betahat = betahat_sub,
        sigma = sigma_sub,
        numPrePeriods = length(pre_idx),
        numPostPeriods = length(post_idx),
        Mvec = c(0, 0.5, 1, 2) * max_pre
      )
    }, error = function(e) {
      cat("HonestDiD createSensitivityResults failed:", e$message, "\n")
      NULL
    })
    cat("HonestDiD results (M = relative violation of parallel trends):\n")
    print(honest_result)

    saveRDS(honest_result, file.path(DATA_DIR, "honest_did_results.rds"))
  }
}, error = function(e) {
  cat("HonestDiD failed:", e$message, "\n")
  cat("(Will include in paper as planned but could not compute.)\n")
})

# =============================================================================
# 8. SAVE ALL RESULTS
# =============================================================================

cat("\n=== Saving results ===\n")

results <- list(
  baseline_twfe = summary(baseline_twfe),
  n_treated = uniqueN(panel[treated == TRUE, commune_code]),
  n_control = uniqueN(panel[treated == FALSE, commune_code]),
  att_twfe = coef(baseline_twfe)["postTRUE"],
  se_twfe = se(baseline_twfe)["postTRUE"]
)

if (!is.null(cs_result)) {
  results$att_cs <- cs_overall$overall.att
  results$se_cs <- cs_overall$overall.se
}

saveRDS(results, file.path(DATA_DIR, "main_results.rds"))
cat("Main analysis complete.\n")
