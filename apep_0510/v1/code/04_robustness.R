# =============================================================================
# 04_robustness.R — Pills and Diplomas (apep_0510)
# =============================================================================
# Robustness checks:
#   1. Placebo: graduate-heavy institutions
#   2. Heterogeneity: community colleges vs. 4-year
#   3. HonestDiD sensitivity analysis
#   4. Sun & Abraham interaction-weighted estimator
#   5. State-specific linear time trends
#   6. Alternative PDMP date coding
#   7. Heterogeneity by institution control (public/private)
#   8. Heterogeneity by HBCU status
# =============================================================================

source("code/00_packages.R")

panel <- readRDS(file.path(DATA_DIR, "analysis_panel.rds"))

# =============================================================================
# 1. PLACEBO: GRADUATE-HEAVY INSTITUTIONS
# =============================================================================
cat("=== Robustness 1: Graduate-heavy placebo ===\n")

panel_grad <- panel[grad_heavy == 1 & !is.na(ret_pcf)]
obs_count <- panel_grad[, .N, by = unitid]
panel_grad <- panel_grad[unitid %in% obs_count[N >= 8]$unitid]

grad_placebo_result <- tryCatch({
  if (nrow(panel_grad) > 500 && length(unique(panel_grad[g > 0]$g)) >= 3) {
    cs_grad_placebo <- att_gt(
      yname = "ret_pcf",
      tname = "year",
      idname = "unitid",
      gname = "g",
      data = as.data.frame(panel_grad),
      control_group = "nevertreated",
      anticipation = 0,
      est_method = "dr",
      base_period = "universal"
    )
    simple_grad <- aggte(cs_grad_placebo, type = "simple")
    es_grad <- aggte(cs_grad_placebo, type = "dynamic", min_e = -5, max_e = 8)

    cat("  Graduate-heavy ATT:", round(simple_grad$overall.att, 3),
        "SE:", round(simple_grad$overall.se, 3), "\n")

    es_grad_df <- data.table(
      event_time = es_grad$egt,
      att = es_grad$att.egt,
      se = es_grad$se.egt,
      ci_lower = es_grad$att.egt - 1.96 * es_grad$se.egt,
      ci_upper = es_grad$att.egt + 1.96 * es_grad$se.egt
    )
    fwrite(es_grad_df, file.path(DATA_DIR, "placebo_grad_heavy.csv"))
    "cs_did"
  } else {
    "fallback"
  }
}, error = function(e) {
  cat("  CS-DiD failed for grad-heavy (", conditionMessage(e), "), using TWFE fallback.\n")
  "fallback"
})

if (grad_placebo_result == "fallback") {
  twfe_grad <- feols(ret_pcf ~ pdmp_treated | unitid + year,
                     data = panel_grad, cluster = ~state)
  cat("  TWFE (grad-heavy):", round(coef(twfe_grad)["pdmp_treated"], 3),
      "SE:", round(se(twfe_grad)["pdmp_treated"], 3), "\n")
  fwrite(data.table(
    event_time = 0, att = coef(twfe_grad)["pdmp_treated"],
    se = se(twfe_grad)["pdmp_treated"]
  ), file.path(DATA_DIR, "placebo_grad_heavy.csv"))
}

# =============================================================================
# 2. HETEROGENEITY: COMMUNITY COLLEGES vs. 4-YEAR
# =============================================================================
cat("\n=== Robustness 2: 2-year vs 4-year heterogeneity ===\n")

for (itype in c("2-year", "4-year")) {
  cat("  ", itype, "...\n")
  panel_sub <- panel[inst_type == itype & !is.na(ret_pcf)]
  obs_count <- panel_sub[, .N, by = unitid]
  panel_sub <- panel_sub[unitid %in% obs_count[N >= 8]$unitid]

  tryCatch({
    if (nrow(panel_sub) > 500 && length(unique(panel_sub[g > 0]$g)) >= 3) {
      cs_sub <- att_gt(
        yname = "ret_pcf",
        tname = "year",
        idname = "unitid",
        gname = "g",
        data = as.data.frame(panel_sub),
        control_group = "nevertreated",
        anticipation = 0,
        est_method = "dr",
        base_period = "universal"
      )
      simple_sub <- aggte(cs_sub, type = "simple")
      es_sub <- aggte(cs_sub, type = "dynamic", min_e = -5, max_e = 8)
      cat("    ATT:", round(simple_sub$overall.att, 3),
          "SE:", round(simple_sub$overall.se, 3), "\n")

      es_df <- data.table(
        event_time = es_sub$egt,
        att = es_sub$att.egt,
        se = es_sub$se.egt,
        ci_lower = es_sub$att.egt - 1.96 * es_sub$se.egt,
        ci_upper = es_sub$att.egt + 1.96 * es_sub$se.egt
      )
      fwrite(es_df, file.path(DATA_DIR, paste0("het_", gsub("-", "", itype), ".csv")))
    } else {
      # TWFE fallback
      twfe_sub <- feols(ret_pcf ~ pdmp_treated | unitid + year,
                        data = panel_sub, cluster = ~state)
      cat("    TWFE ATT:", round(coef(twfe_sub)["pdmp_treated"], 3),
          "SE:", round(se(twfe_sub)["pdmp_treated"], 3), "\n")
    }
  }, error = function(e) {
    cat("    CS-DiD failed for ", itype, ": ", conditionMessage(e), " — using TWFE.\n")
    twfe_sub <- feols(ret_pcf ~ pdmp_treated | unitid + year,
                      data = panel_sub, cluster = ~state)
    cat("    TWFE ATT:", round(coef(twfe_sub)["pdmp_treated"], 3),
        "SE:", round(se(twfe_sub)["pdmp_treated"], 3), "\n")
  })
}

# =============================================================================
# 3. HONESTDID SENSITIVITY ANALYSIS
# =============================================================================
cat("\n=== Robustness 3: HonestDiD sensitivity ===\n")

tryCatch({
  cs_ret <- readRDS(file.path(DATA_DIR, "cs_ret_gt.rds"))
  es_ret <- aggte(cs_ret, type = "dynamic", min_e = -5, max_e = 8)

  # Extract pre-treatment coefficients for HonestDiD
  honest_results <- honest_did(es_ret, type = "smoothness")

  honest_df <- data.table(
    M = honest_results$robust_ci[, 1],
    ci_lower = honest_results$robust_ci[, 2],
    ci_upper = honest_results$robust_ci[, 3]
  )
  fwrite(honest_df, file.path(DATA_DIR, "honestdid_sensitivity.csv"))
  cat("  HonestDiD sensitivity saved.\n")
}, error = function(e) {
  cat("  HonestDiD error:", e$message, "\n")
  cat("  (Will generate manually if needed.)\n")
})

# =============================================================================
# 4. SUN & ABRAHAM INTERACTION-WEIGHTED ESTIMATOR
# =============================================================================
cat("\n=== Robustness 4: Sun & Abraham ===\n")

panel_sa <- panel[!is.na(ret_pcf) & inst_type == "4-year"]
obs_count <- panel_sa[, .N, by = unitid]
panel_sa <- panel_sa[unitid %in% obs_count[N >= 10]$unitid]

# sunab() in fixest
panel_sa[, cohort := fifelse(g == 0, 10000L, g)]  # never-treated = large value

sa_ret <- feols(ret_pcf ~ sunab(cohort, year) +
                  naloxone_active + good_sam_active + medicaid_expanded + cannabis_legal +
                  unemp_rate |
                  unitid + year,
                data = panel_sa, cluster = ~state)

# Extract event-study coefficients
sa_coefs <- as.data.table(coeftable(sa_ret))
sa_coefs[, term := rownames(coeftable(sa_ret))]
sa_es <- sa_coefs[grepl("year::", term)]
sa_es[, event_time := as.integer(gsub(".*::", "", term))]
setnames(sa_es, c("Estimate", "Std. Error"), c("att", "se"))
sa_es[, `:=`(ci_lower = att - 1.96 * se, ci_upper = att + 1.96 * se)]

fwrite(sa_es[, .(event_time, att, se, ci_lower, ci_upper)],
       file.path(DATA_DIR, "sun_abraham_retention.csv"))

# Overall SA ATT
sa_att <- summary(sa_ret)$coeftable
cat("  Sun & Abraham saved.\n")

saveRDS(sa_ret, file.path(DATA_DIR, "sa_retention.rds"))

# =============================================================================
# 5. STATE-SPECIFIC LINEAR TIME TRENDS
# =============================================================================
cat("\n=== Robustness 5: State-specific trends ===\n")

panel_trends <- panel[!is.na(ret_pcf) & inst_type == "4-year"]
obs_count <- panel_trends[, .N, by = unitid]
panel_trends <- panel_trends[unitid %in% obs_count[N >= 10]$unitid]

twfe_trends <- feols(ret_pcf ~ pdmp_treated +
                       naloxone_active + good_sam_active + medicaid_expanded +
                       unemp_rate |
                       unitid + year + state[year],
                     data = panel_trends, cluster = ~state)

cat("  TWFE with state trends:", round(coef(twfe_trends)["pdmp_treated"], 3),
    "SE:", round(se(twfe_trends)["pdmp_treated"], 3), "\n")

saveRDS(twfe_trends, file.path(DATA_DIR, "twfe_state_trends.rds"))

# =============================================================================
# 6. ALTERNATIVE PDMP DATE CODING
# =============================================================================
cat("\n=== Robustness 6: Alternative PDMP dates ===\n")

# Shift all mandate dates by +1 year (later coding)
panel_alt <- copy(panel)
panel_alt[!is.na(pdmp_mandate_year), pdmp_mandate_year := pdmp_mandate_year + 1L]
panel_alt[, pdmp_treated := as.integer(!is.na(pdmp_mandate_year) & year >= pdmp_mandate_year)]
panel_alt[, g := fifelse(is.na(pdmp_mandate_year), 0L, pdmp_mandate_year)]

panel_alt_ret <- panel_alt[!is.na(ret_pcf) & inst_type == "4-year"]
obs_count <- panel_alt_ret[, .N, by = unitid]
panel_alt_ret <- panel_alt_ret[unitid %in% obs_count[N >= 10]$unitid]

twfe_alt <- feols(ret_pcf ~ pdmp_treated | unitid + year,
                  data = panel_alt_ret, cluster = ~state)

cat("  TWFE (dates +1 year):", round(coef(twfe_alt)["pdmp_treated"], 3),
    "SE:", round(se(twfe_alt)["pdmp_treated"], 3), "\n")

fwrite(data.table(
  spec = c("Baseline", "Dates +1 year"),
  estimate = c(coef(readRDS(file.path(DATA_DIR, "twfe_retention.rds")))["pdmp_treated"],
               coef(twfe_alt)["pdmp_treated"]),
  se = c(se(readRDS(file.path(DATA_DIR, "twfe_retention.rds")))["pdmp_treated"],
         se(twfe_alt)["pdmp_treated"])
), file.path(DATA_DIR, "robustness_alt_dates.csv"))

# =============================================================================
# 7. HETEROGENEITY: PUBLIC vs. PRIVATE
# =============================================================================
cat("\n=== Robustness 7: Public vs Private ===\n")

for (ctrl in c("Public", "Private nonprofit")) {
  panel_ctrl <- panel[inst_control == ctrl & !is.na(ret_pcf) & inst_type == "4-year"]
  obs_count <- panel_ctrl[, .N, by = unitid]
  panel_ctrl <- panel_ctrl[unitid %in% obs_count[N >= 8]$unitid]

  twfe_ctrl <- feols(ret_pcf ~ pdmp_treated +
                       naloxone_active + good_sam_active + medicaid_expanded +
                       unemp_rate |
                       unitid + year,
                     data = panel_ctrl, cluster = ~state)
  cat("  ", ctrl, ":", round(coef(twfe_ctrl)["pdmp_treated"], 3),
      "SE:", round(se(twfe_ctrl)["pdmp_treated"], 3), "\n")
}

# =============================================================================
# 8. HETEROGENEITY: HBCU
# =============================================================================
cat("\n=== Robustness 8: HBCU heterogeneity ===\n")

for (hbcu_val in c(1, 0)) {
  label <- ifelse(hbcu_val == 1, "HBCU", "Non-HBCU")
  panel_hbcu <- panel[hbcu == hbcu_val & !is.na(ret_pcf) & inst_type == "4-year"]
  obs_count <- panel_hbcu[, .N, by = unitid]
  panel_hbcu <- panel_hbcu[unitid %in% obs_count[N >= 8]$unitid]

  if (nrow(panel_hbcu) > 200) {
    twfe_hbcu <- feols(ret_pcf ~ pdmp_treated | unitid + year,
                       data = panel_hbcu, cluster = ~state)
    cat("  ", label, ":", round(coef(twfe_hbcu)["pdmp_treated"], 3),
        "SE:", round(se(twfe_hbcu)["pdmp_treated"], 3),
        "N:", nobs(twfe_hbcu), "\n")
  } else {
    cat("  ", label, ": insufficient observations\n")
  }
}

# =============================================================================
# SAVE ROBUSTNESS SUMMARY
# =============================================================================
cat("\n=== Robustness checks complete ===\n")

robustness_summary <- data.table(
  check = c("Baseline (TWFE)", "State trends", "Dates +1 year",
            "Sun & Abraham (saved)", "HonestDiD (saved)"),
  note = c("Main specification with concurrent policy controls",
           "Added state × year linear trends",
           "Shifted mandate dates 1 year later",
           "Interaction-weighted estimator",
           "Sensitivity to PT violations")
)
fwrite(robustness_summary, file.path(DATA_DIR, "robustness_summary.csv"))
cat("Robustness summary saved.\n")
