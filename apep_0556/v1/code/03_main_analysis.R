## ============================================================
## 03_main_analysis.R — Primary regression analysis
## APEP Paper: India's NRHM and Neonatal Mortality Transition
## ============================================================

source("00_packages.R")
data_dir <- "../data"

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
srs   <- fread(file.path(data_dir, "srs_analysis_panel.csv"))

cat("=== Main Analysis ===\n")
cat(sprintf("Panel: %d obs, %d states, %d surveys\n",
            nrow(panel), uniqueN(panel$state), uniqueN(panel$SurveyYear)))

## ── 1. Primary DiD: Institutional Delivery ─────────────────────

cat("\n--- Table 2: Effect of NRHM on Institutional Delivery ---\n")

# Restrict to states with NFHS-3 (2006) and NFHS-4 (2015) at minimum
panel_main <- panel[SurveyYear %in% c(2006, 2015, 2020)]
panel_main[, post := as.integer(SurveyYear >= 2015)]

# Column 1: Simple DiD (OLS)
m1 <- feols(inst_delivery ~ high_focus:post | state + SurveyYear,
            data = panel_main, cluster = ~state)

# Column 2: With survey year as numeric trend
panel_main[, year_num := SurveyYear - 2006]
m2 <- feols(inst_delivery ~ high_focus:post + high_focus:year_num | state + SurveyYear,
            data = panel_main, cluster = ~state)

# Column 3: JSY incentive intensity (continuous treatment)
panel_main[, jsy_intensity := jsy_incentive_inr / 1000]  # in thousands INR
m3 <- feols(inst_delivery ~ jsy_intensity:post | state + SurveyYear,
            data = panel_main, cluster = ~state)

# Column 4: Exclude NE states (different geography)
m4 <- feols(inst_delivery ~ high_focus:post | state + SurveyYear,
            data = panel_main[ne_state == 0], cluster = ~state)

# Column 5: EAG states only vs non-HF (most comparable groups)
panel_eag <- panel_main[eag_state == 1 | high_focus == 0]
m5 <- feols(inst_delivery ~ eag_state:post | state + SurveyYear,
            data = panel_eag, cluster = ~state)

# Column 6: Full panel (1993, 1999, 2006, 2015, 2020) — event study
panel_full <- panel[!is.na(inst_delivery)]
panel_full[, post := as.integer(SurveyYear >= 2015)]
m6 <- feols(inst_delivery ~ high_focus:post | state + SurveyYear,
            data = panel_full, cluster = ~state)

cat("\n")
etable(m1, m2, m3, m4, m5, m6,
       headers = c("Baseline", "Trend", "JSY Intensity",
                    "Excl NE", "EAG Only", "Full Panel"))

# Save coefficients for table generation
results_instdel <- data.table(
  model = c("Baseline", "Linear Trend", "JSY Intensity",
            "Exclude NE", "EAG Only", "Full Panel"),
  coef = c(coef(m1)["high_focus:post"], coef(m2)["high_focus:post"],
           coef(m3)["jsy_intensity:post"], coef(m4)["high_focus:post"],
           coef(m5)["eag_state:post"], coef(m6)["high_focus:post"]),
  se = c(se(m1)["high_focus:post"], se(m2)["high_focus:post"],
         se(m3)["jsy_intensity:post"], se(m4)["high_focus:post"],
         se(m5)["eag_state:post"], se(m6)["high_focus:post"]),
  n_obs = c(nobs(m1), nobs(m2), nobs(m3), nobs(m4), nobs(m5), nobs(m6)),
  n_states = c(uniqueN(panel_main$state), uniqueN(panel_main$state),
               uniqueN(panel_main$state),
               uniqueN(panel_main[ne_state == 0]$state),
               uniqueN(panel_eag$state),
               uniqueN(panel_full$state))
)
results_instdel[, pval := 2 * pnorm(-abs(coef / se))]
results_instdel[, stars := fifelse(pval < 0.01, "***",
                           fifelse(pval < 0.05, "**",
                           fifelse(pval < 0.10, "*", "")))]

fwrite(results_instdel, file.path(data_dir, "results_inst_delivery.csv"))
cat("\nInstitutional delivery results saved.\n")


## ── 2. Mechanism: ANC 4+ Visits ────────────────────────────────

cat("\n--- Table 3: Effect on ANC 4+ Visits (Mechanism) ---\n")

panel_anc <- panel_main[!is.na(anc_4plus)]

m_anc1 <- feols(anc_4plus ~ high_focus:post | state + SurveyYear,
                data = panel_anc, cluster = ~state)

m_anc2 <- feols(anc_4plus ~ high_focus:post | state + SurveyYear,
                data = panel_anc[ne_state == 0], cluster = ~state)

m_anc3 <- feols(anc_4plus ~ jsy_intensity:post | state + SurveyYear,
                data = panel_anc, cluster = ~state)

cat("\n")
etable(m_anc1, m_anc2, m_anc3,
       headers = c("All States", "Excl NE", "JSY Intensity"))

results_anc <- data.table(
  model = c("All States", "Exclude NE", "JSY Intensity"),
  coef = c(coef(m_anc1)["high_focus:post"],
           coef(m_anc2)["high_focus:post"],
           coef(m_anc3)["jsy_intensity:post"]),
  se = c(se(m_anc1)["high_focus:post"],
         se(m_anc2)["high_focus:post"],
         se(m_anc3)["jsy_intensity:post"]),
  n_obs = c(nobs(m_anc1), nobs(m_anc2), nobs(m_anc3))
)
results_anc[, pval := 2 * pnorm(-abs(coef / se))]
fwrite(results_anc, file.path(data_dir, "results_anc.csv"))


## ── 3. Placebo: Anemia (should NOT be affected by NRHM) ───────

cat("\n--- Table 4: Placebo Test — Anemia ---\n")

panel_anem <- panel[!is.na(anemia_women) & SurveyYear %in% c(2015, 2020)]
panel_anem[, post := as.integer(SurveyYear == 2020)]

if (nrow(panel_anem) > 10) {
  m_placebo <- feols(anemia_women ~ high_focus:post | state + SurveyYear,
                     data = panel_anem, cluster = ~state)
  cat("\n")
  etable(m_placebo, headers = "Anemia (Placebo)")

  results_placebo <- data.table(
    outcome = "Anemia (women)",
    coef = coef(m_placebo)["high_focus:post"],
    se = se(m_placebo)["high_focus:post"],
    n_obs = nobs(m_placebo)
  )
  results_placebo[, pval := 2 * pnorm(-abs(coef / se))]
  fwrite(results_placebo, file.path(data_dir, "results_placebo.csv"))
} else {
  cat("Insufficient anemia data for placebo test.\n")
}


## ── 4. SRS Panel: Annual IMR DiD ──────────────────────────────

cat("\n--- SRS Panel: Annual IMR DiD ---\n")

# Fix high_focus merge for SRS (may have .x/.y suffixes from merge)
hf_col <- grep("^high_focus", names(srs), value = TRUE)[1]
if (!is.null(hf_col) && hf_col != "high_focus") {
  setnames(srs, hf_col, "high_focus")
  # Drop other high_focus columns
  drop_cols <- grep("^high_focus\\.", names(srs), value = TRUE)
  if (length(drop_cols) > 0) srs[, (drop_cols) := NULL]
}
srs[is.na(high_focus), high_focus := 0]
srs[, post := as.integer(year >= 2008)]
srs[, year_centered := year - 2005]

if (nrow(srs[!is.na(imr)]) > 50) {
  # Main SRS DiD
  m_srs1 <- feols(imr ~ high_focus:post | state + year, data = srs, cluster = ~state)

  # With state-specific trends
  m_srs2 <- feols(imr ~ high_focus:post | state[year_centered] + year,
                  data = srs, cluster = ~state)

  # Event study
  srs[, year_f := factor(year)]
  srs[, ref_2007 := as.integer(year == 2007)]
  m_srs_es <- feols(imr ~ i(year, high_focus, ref = 2007) | state + year,
                    data = srs, cluster = ~state)

  cat("\n")
  etable(m_srs1, m_srs2, headers = c("SRS DiD", "State Trends"))

  # Event study coefficients for figure
  es_names <- names(coef(m_srs_es))
  es_years <- as.integer(gsub("year::([0-9]+):high_focus", "\\1", es_names))
  es_coefs <- data.table(
    year = es_years,
    coef = as.numeric(coef(m_srs_es)),
    se = as.numeric(se(m_srs_es))
  )
  es_coefs <- es_coefs[!is.na(year)]
  es_coefs[, `:=`(ci_lo = coef - 1.96 * se, ci_hi = coef + 1.96 * se)]
  fwrite(es_coefs, file.path(data_dir, "srs_event_study.csv"))

  results_srs <- data.table(
    model = c("SRS DiD", "State Trends"),
    coef = c(coef(m_srs1)["high_focus:post"], coef(m_srs2)["high_focus:post"]),
    se = c(se(m_srs1)["high_focus:post"], se(m_srs2)["high_focus:post"]),
    n_obs = c(nobs(m_srs1), nobs(m_srs2))
  )
  results_srs[, pval := 2 * pnorm(-abs(coef / se))]
  fwrite(results_srs, file.path(data_dir, "results_srs.csv"))
} else {
  cat("Insufficient SRS data for DiD.\n")
}


## ── 5. Pre-Trend Falsification (NFHS-1/2) ─────────────────────

cat("\n--- Pre-Trend Falsification: NFHS-1 (1993) to NFHS-2 (1999) ---\n")

panel_pre <- panel[SurveyYear %in% c(1993, 1999) & !is.na(inst_delivery)]
if (nrow(panel_pre) > 10) {
  panel_pre[, post_1999 := as.integer(SurveyYear == 1999)]
  m_pretrend <- feols(inst_delivery ~ high_focus:post_1999 | state + SurveyYear,
                      data = panel_pre, cluster = ~state)
  cat("\n")
  etable(m_pretrend, headers = "Pre-Trend (1993→1999)")

  pt_coef <- coef(m_pretrend)["high_focus:post_1999"]
  pt_se <- se(m_pretrend)["high_focus:post_1999"]
  pt_pval <- 2 * pnorm(-abs(pt_coef / pt_se))
  results_pretrend <- data.table(
    test = "Pre-trend (1993 to 1999)",
    coef = pt_coef,
    se = pt_se,
    pval = pt_pval
  )
  fwrite(results_pretrend, file.path(data_dir, "results_pretrend.csv"))
  cat(sprintf("\nPre-trend coef: %.2f (p=%.3f) — %s\n",
              results_pretrend$coef, results_pretrend$pval,
              fifelse(results_pretrend$pval > 0.10, "PASS (no differential pre-trend)",
                      "WARNING: Significant pre-trend")))
} else {
  cat("Insufficient pre-1999 data for pre-trend test.\n")
}


## ── 6. Wild Cluster Bootstrap ──────────────────────────────────

cat("\n--- Wild Cluster Bootstrap for Main Result ---\n")

tryCatch({
  set.seed(12345)
  boot_result <- boottest(m1, param = "high_focus:post",
                          B = 9999, clustid = "state", type = "webb")
  boot_p <- boot_result$p_val
  boot_ci <- c(boot_result$conf_int[1], boot_result$conf_int[2])
  cat(sprintf("Wild bootstrap p-value: %.4f\n", boot_p))
  cat(sprintf("95%% CI: [%.2f, %.2f]\n", boot_ci[1], boot_ci[2]))

  results_boot <- data.table(
    test = "Wild Cluster Bootstrap",
    pval = boot_p, ci_lo = boot_ci[1], ci_hi = boot_ci[2]
  )
  fwrite(results_boot, file.path(data_dir, "results_bootstrap.csv"))
}, error = function(e) {
  cat(sprintf("Bootstrap error: %s\n", e$message))
  cat("Proceeding without bootstrap.\n")
})


## ── 7. Summary of all results ─────────────────────────────────

cat("\n\n=== RESULTS SUMMARY ===\n")
cat("Primary: Institutional delivery DiD\n")
cat(sprintf("  Coefficient: %.2f pp (SE: %.2f)\n",
            coef(m1)["high_focus:post"], se(m1)["high_focus:post"]))
cat(sprintf("  Baseline HF: 33.2%%, NHF: 64.6%%\n"))
cat(sprintf("  N = %d state-survey obs, %d states\n\n",
            nobs(m1), uniqueN(panel_main$state)))

cat("✓ All main analysis complete.\n")
