## 04_robustness.R — Robustness checks and heterogeneity
## apep_1157: Seguro Popular and Cause-Specific Infant Mortality

source("00_packages.R")

panel <- fread("../data/panel_clean.csv")
results <- readRDS("../data/main_results.rds")

cat("=== ROBUSTNESS CHECKS ===\n")

# ============================================================
# 1. Heterogeneity: High vs Low baseline mortality
# ============================================================
cat("\n--- Heterogeneity by baseline mortality ---\n")

panel_high <- panel[high_baseline_imr == 1]
panel_low <- panel[high_baseline_imr == 0]

cs_high <- att_gt(
  yname = "amenable_mr", tname = "year", idname = "mun_num",
  gname = "first_treat", data = as.data.frame(panel_high),
  control_group = "notyettreated", base_period = "universal",
  est_method = "dr", clustervars = "state_code", print_details = FALSE
)
att_high <- aggte(cs_high, type = "simple")

cs_low <- att_gt(
  yname = "amenable_mr", tname = "year", idname = "mun_num",
  gname = "first_treat", data = as.data.frame(panel_low),
  control_group = "notyettreated", base_period = "universal",
  est_method = "dr", clustervars = "state_code", print_details = FALSE
)
att_low <- aggte(cs_low, type = "simple")

cat(sprintf("  High baseline IMR: ATT = %.3f (SE = %.3f)\n",
            att_high$overall.att, att_high$overall.se))
cat(sprintf("  Low baseline IMR:  ATT = %.3f (SE = %.3f)\n",
            att_low$overall.att, att_low$overall.se))

# ============================================================
# 2. Exclude pilot states (robustness to selection)
# ============================================================
cat("\n--- Excluding pilot states (2002 cohort) ---\n")

panel_nopilot <- panel[first_treat > 2002]

cs_nopilot <- att_gt(
  yname = "amenable_mr", tname = "year", idname = "mun_num",
  gname = "first_treat", data = as.data.frame(panel_nopilot),
  control_group = "notyettreated", base_period = "universal",
  est_method = "dr", clustervars = "state_code", print_details = FALSE
)
att_nopilot <- aggte(cs_nopilot, type = "simple")
cat(sprintf("  ATT (no pilots): %.3f (SE = %.3f)\n",
            att_nopilot$overall.att, att_nopilot$overall.se))

# ============================================================
# 3. Balanced panel only
# ============================================================
cat("\n--- Balanced panel only ---\n")

panel_bal <- panel[balanced == TRUE]

cs_bal <- att_gt(
  yname = "amenable_mr", tname = "year", idname = "mun_num",
  gname = "first_treat", data = as.data.frame(panel_bal),
  control_group = "notyettreated", base_period = "universal",
  est_method = "dr", clustervars = "state_code", print_details = FALSE
)
att_bal <- aggte(cs_bal, type = "simple")
cat(sprintf("  ATT (balanced): %.3f (SE = %.3f)\n",
            att_bal$overall.att, att_bal$overall.se))

# ============================================================
# 4. Alternative outcome: log infant deaths
# ============================================================
cat("\n--- Log infant deaths (semi-elasticity) ---\n")

cs_log <- att_gt(
  yname = "log_amenable", tname = "year", idname = "mun_num",
  gname = "first_treat", data = as.data.frame(panel),
  control_group = "notyettreated", base_period = "universal",
  est_method = "dr", clustervars = "state_code", print_details = FALSE
)
att_log <- aggte(cs_log, type = "simple")
cat(sprintf("  ATT (log amenable deaths): %.3f (SE = %.3f)\n",
            att_log$overall.att, att_log$overall.se))

# ============================================================
# 5. Sun-Abraham estimator (alternative heterogeneity-robust)
# ============================================================
cat("\n--- Sun-Abraham estimator ---\n")

# Create event time relative to treatment
panel[, event_time := year - first_treat]

# Sunab with fixest
sa_amenable <- feols(amenable_mr ~ sunab(first_treat, year) | mun_num + year,
                     data = panel, cluster = ~state_code)
sa_nonamenable <- feols(non_amenable_mr ~ sunab(first_treat, year) | mun_num + year,
                        data = panel, cluster = ~state_code)

# Extract ATT (average of post-treatment coefficients)
sa_coefs_am <- coef(sa_amenable)
sa_post_am <- sa_coefs_am[grep("year::.*::[0-9]", names(sa_coefs_am))]
# sunab naming: year::YYYY::relative_period
# Post-treatment periods have positive relative period
sa_post_idx <- grep("::[0-9]+$", names(sa_coefs_am))
if (length(sa_post_idx) > 0) {
  sa_att_am <- mean(sa_coefs_am[sa_post_idx])
  cat(sprintf("  Sun-Abraham ATT (amenable): %.3f\n", sa_att_am))
}

sa_post_idx_na <- grep("::[0-9]+$", names(coef(sa_nonamenable)))
if (length(sa_post_idx_na) > 0) {
  sa_att_na <- mean(coef(sa_nonamenable)[sa_post_idx_na])
  cat(sprintf("  Sun-Abraham ATT (non-amenable): %.3f\n", sa_att_na))
}

# ============================================================
# 6. Cause-specific decomposition
# ============================================================
cat("\n--- Cause-specific decomposition ---\n")

for (cause in c("diarrheal_mr", "respiratory_mr", "perinatal_mr")) {
  # Construct rate if not present
  if (!(cause %in% names(panel))) {
    cause_base <- gsub("_mr$", "_deaths", cause)
    panel[, (cause) := get(cause_base) / est_births * 1000]
  }

  cs_cause <- tryCatch({
    att_gt(
      yname = cause, tname = "year", idname = "mun_num",
      gname = "first_treat", data = as.data.frame(panel),
      control_group = "notyettreated", base_period = "universal",
      est_method = "dr", clustervars = "state_code", print_details = FALSE
    )
  }, error = function(e) {
    cat(sprintf("  %s: CS-DiD failed (%s)\n", cause, e$message))
    return(NULL)
  })

  if (!is.null(cs_cause)) {
    att_cause <- aggte(cs_cause, type = "simple")
    cat(sprintf("  %s: ATT = %.3f (SE = %.3f)\n",
                cause, att_cause$overall.att, att_cause$overall.se))
  }
}

# ============================================================
# Save robustness results
# ============================================================

robust_results <- list(
  att_high = att_high,
  att_low = att_low,
  att_nopilot = att_nopilot,
  att_bal = att_bal,
  att_log = att_log,
  sa_amenable = sa_amenable,
  sa_nonamenable = sa_nonamenable
)

saveRDS(robust_results, "../data/robustness_results.rds")
cat("\nRobustness results saved.\n")
