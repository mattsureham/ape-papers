# ============================================================================
# 03_main_analysis.R — Main regression analysis
# Denmark's 2013 Disability Pension Reform (apep_0599)
#
# Inputs:  ../data/panel_benefits.csv, panel_employment.csv, panel_national.csv
# Outputs: ../data/reg_did_main.csv, reg_ddd_main.csv,
#          reg_event_study_dp.csv, reg_event_study_fl.csv,
#          reg_event_study_kh.csv, reg_dose_response.csv, reg_models.rds
# ============================================================================

source("00_packages.R")

DATA_DIR <- "../data"

cat("=== 03_main_analysis.R: Main regression analysis ===\n")

# ============================================================================
# 0. LOAD DATA
# ============================================================================

cat("\n--- Loading cleaned panels ---\n")

panel <- fread(file.path(DATA_DIR, "panel_benefits.csv"))
panel_emp <- fread(file.path(DATA_DIR, "panel_employment.csv"))
panel_nat <- fread(file.path(DATA_DIR, "panel_national.csv"))

cat(sprintf("  panel_benefits: %d rows, %d cols\n", nrow(panel), ncol(panel)))
cat(sprintf("  panel_employment: %d rows, %d cols\n", nrow(panel_emp), ncol(panel_emp)))
cat(sprintf("  panel_national: %d rows, %d cols\n", nrow(panel_nat), ncol(panel_nat)))

# Ensure factor types
panel[, treat_group := factor(treat_group,
                              levels = c("High (25-39)", "Moderate (40-49)",
                                         "Control (50-59)"))]
panel_nat[, treat_group := factor(treat_group,
                                  levels = c("High (25-39)", "Moderate (40-49)",
                                             "Control (50-59)"))]

# Create string fixed-effect identifiers for fixest
panel[, age_f := as.factor(age)]
panel[, yq_f := as.factor(yq)]
panel[, muni_f := as.factor(municipality)]

panel_nat[, age_f := as.factor(age)]
panel_nat[, yq_f := as.factor(yq)]

# ============================================================================
# HELPER: Extract coefficient table from fixest model
# ============================================================================

extract_coefs <- function(model, outcome_name, spec_name = "") {
  ct <- as.data.table(coeftable(model), keep.rownames = "term")
  setnames(ct, c("term", "estimate", "std_error", "t_value", "p_value"))
  ct[, outcome := outcome_name]
  ct[, spec := spec_name]
  ct[, stars := fifelse(p_value < 0.001, "***",
                        fifelse(p_value < 0.01, "**",
                                fifelse(p_value < 0.05, "*",
                                        fifelse(p_value < 0.1, ".", ""))))]
  ct[, ci_lower := estimate - 1.96 * std_error]
  ct[, ci_upper := estimate + 1.96 * std_error]
  ct[, nobs := model$nobs]
  ct
}

# ============================================================================
# 1. SIMPLE DiD (AGE x TIME, NATIONAL LEVEL)
# ============================================================================

cat("\n--- Section 1: Simple DiD (national level) ---\n")

# Use panel_benefits filtered to young == 0 or young == 1 (exclude moderate)
did_panel <- panel[!is.na(young)]
cat(sprintf("  DiD panel (excl. moderate): %d rows\n", nrow(did_panel)))

# Outcomes to test
did_outcomes <- c("rate_fp", "rate_fl", "rate_kh", "rate_sy", "rate_res", "rate_ja")
did_labels <- c("Disability Pension", "Flex Jobs", "Cash Benefits",
                "Sickness Benefits", "Rehabilitation", "Job Clarification")

# Store models and coefficient tables
did_models <- list()
did_coefs <- list()

for (i in seq_along(did_outcomes)) {
  outcome <- did_outcomes[i]
  label <- did_labels[i]

  # DiD: Y_at = beta * (young * post) + age_FE + quarter_FE + epsilon
  # Cluster at municipality level (many clusters) for the muni-level panel
  fml <- as.formula(paste0(outcome, " ~ young:post | age_f + yq_f"))
  mod <- feols(fml, data = did_panel, cluster = ~municipality)

  did_models[[outcome]] <- mod
  coef_tab <- extract_coefs(mod, label, "DiD")
  # Keep only the interaction term
  coef_tab <- coef_tab[grepl("young.*post|post.*young", term)]
  did_coefs[[outcome]] <- coef_tab

  cat(sprintf("  %-25s: beta = %8.3f (SE = %.3f), p = %.4f %s\n",
              label,
              coef_tab$estimate[1],
              coef_tab$std_error[1],
              coef_tab$p_value[1],
              coef_tab$stars[1]))
}

did_coefs_dt <- rbindlist(did_coefs)

cat("\nDiD results summary:\n")
print(did_coefs_dt[, .(outcome, estimate, std_error, p_value, stars, nobs)])

# ============================================================================
# 2. DDD (AGE x MUNICIPALITY x TIME)
# ============================================================================

cat("\n--- Section 2: Triple-Difference (DDD) ---\n")

# Use the binary DiD panel (young == 0 or 1) with municipality variation
# Y_amt = beta * (young * post * high_base_dp) + age:muni FE + age:quarter FE
#         + muni:quarter FE + epsilon
ddd_outcomes <- c("rate_fp", "rate_fl", "rate_kh", "rate_res")
ddd_labels <- c("Disability Pension", "Flex Jobs", "Cash Benefits", "Rehabilitation")

ddd_models <- list()
ddd_coefs <- list()

for (i in seq_along(ddd_outcomes)) {
  outcome <- ddd_outcomes[i]
  label <- ddd_labels[i]

  # Triple-difference with three-way interaction and all lower-order interactions
  # fixest absorbs high-dimensional FE efficiently
  # Full interaction: young:post:high_base_dp + young:post + young:high_base_dp + post:high_base_dp
  # But with age:muni, age:quarter, and muni:quarter FE, main effects and many
  # two-way interactions are absorbed. We include the full set of interactions.
  fml <- as.formula(paste0(
    outcome,
    " ~ young:post:high_base_dp + young:post + young:high_base_dp + post:high_base_dp",
    " | age_f^muni_f + age_f^yq_f + muni_f^yq_f"
  ))

  mod <- feols(fml, data = did_panel, cluster = ~municipality)

  ddd_models[[outcome]] <- mod
  coef_tab <- extract_coefs(mod, label, "DDD")
  ddd_coefs[[outcome]] <- coef_tab

  # Extract the triple interaction coefficient
  triple_row <- coef_tab[grepl("young.*post.*high_base_dp", term)]
  if (nrow(triple_row) > 0) {
    cat(sprintf("  %-25s: DDD beta = %8.3f (SE = %.3f), p = %.4f %s\n",
                label,
                triple_row$estimate[1],
                triple_row$std_error[1],
                triple_row$p_value[1],
                triple_row$stars[1]))
  }
}

ddd_coefs_dt <- rbindlist(ddd_coefs)

cat("\nDDD results summary (triple interaction):\n")
print(ddd_coefs_dt[grepl("young.*post.*high_base_dp", term),
                   .(outcome, term, estimate, std_error, p_value, stars, nobs)])

# ============================================================================
# 2b. DDD EVENT STUDY (DYNAMIC TRIPLE-DIFFERENCE)
# ============================================================================

cat("\n--- Section 2b: DDD Event Study ---\n")

# Create interaction variable for i() in fixest
did_panel[, young_highbase := young * high_base_dp]

ddd_es_outcomes <- c("rate_fp", "rate_res", "rate_fl", "rate_kh")
ddd_es_labels <- c("Disability Pension", "Rehabilitation", "Flex Jobs", "Cash Benefits")

ddd_es_models <- list()
ddd_es_coefs <- list()

for (i in seq_along(ddd_es_outcomes)) {
  outcome <- ddd_es_outcomes[i]
  label <- ddd_es_labels[i]

  # DDD event study: Y_amt = sum_k delta_k (Young_a * HighBase_m * 1[t=k])
  #   + age*muni FE + age*quarter FE + muni*quarter FE
  # Lower-order interactions (young*event_time, highbase*event_time) are absorbed
  # by age*quarter and muni*quarter FEs respectively.
  fml <- as.formula(paste0(
    outcome, " ~ i(event_time, young_highbase, ref = -1) | age_f^muni_f + age_f^yq_f + muni_f^yq_f"
  ))

  mod <- tryCatch(
    feols(fml, data = did_panel, cluster = ~municipality),
    error = function(e) {
      cat(sprintf("  ERROR in DDD event study for %s: %s\n", label, e$message))
      NULL
    }
  )

  if (!is.null(mod)) {
    ddd_es_models[[outcome]] <- mod
    coef_tab <- extract_coefs(mod, label, "DDD_EventStudy")
    ddd_es_coefs[[outcome]] <- coef_tab

    # Count sig pre-trend coefficients
    pre_coefs <- coef_tab[grepl("event_time", term)]
    pre_coefs[, et := as.integer(gsub(".*::(-?[0-9]+):.*", "\\1", term))]
    pre_only <- pre_coefs[et < -1]
    n_sig_pre <- sum(pre_only$p_value < 0.05, na.rm = TRUE)

    cat(sprintf("  %-25s: %d/%d pre-trend coefs sig (p<.05)\n",
                label, n_sig_pre, nrow(pre_only)))
  }
}

ddd_es_coefs_dt <- rbindlist(ddd_es_coefs)
ddd_es_coefs_dt[, event_time_val := as.integer(gsub(".*::(-?[0-9]+):.*", "\\1", term))]

# Save DDD event study coefficients
fwrite(ddd_es_coefs_dt, file.path(DATA_DIR, "reg_ddd_event_study.csv"))
cat(sprintf("  reg_ddd_event_study.csv: %d rows\n", nrow(ddd_es_coefs_dt)))

# Joint test of pre-period DDD coefficients for resource scheme
ddd_es_res_pre <- ddd_es_coefs_dt[outcome == "Rehabilitation" &
                                    event_time_val < -1]
if (nrow(ddd_es_res_pre) > 0) {
  n_sig <- sum(ddd_es_res_pre$p_value < 0.05, na.rm = TRUE)
  cat(sprintf("  Resource Scheme DDD pre-trends: %d/%d significant at 5%%\n",
              n_sig, nrow(ddd_es_res_pre)))
}

# ============================================================================
# 3. EVENT STUDY (DYNAMIC DiD)
# ============================================================================

cat("\n--- Section 3: Event Study (dynamic DiD) ---\n")

# Event study outcomes
es_outcomes <- c("rate_fp", "rate_fl", "rate_kh")
es_labels <- c("Disability Pension", "Flex Jobs", "Cash Benefits")

es_models <- list()
es_coefs <- list()

for (i in seq_along(es_outcomes)) {
  outcome <- es_outcomes[i]
  label <- es_labels[i]

  # Y_at = sum_k beta_k * (young * 1(event_time=k)) + age_FE + quarter_FE
  # Use fixest's i() function; ref = -1 omits the period just before reform
  fml <- as.formula(paste0(
    outcome, " ~ i(event_time, young, ref = -1) | age_f + yq_f"
  ))

  mod <- feols(fml, data = did_panel, cluster = ~municipality)

  es_models[[outcome]] <- mod
  coef_tab <- extract_coefs(mod, label, "EventStudy")
  es_coefs[[outcome]] <- coef_tab

  # Count significant pre-trend coefficients
  pre_coefs <- coef_tab[grepl("event_time.*::-", term) |
                          (grepl("event_time", term) &
                           as.numeric(gsub(".*::(-?[0-9]+):.*", "\\1",
                                           term)) < -1)]
  n_sig_pre <- sum(pre_coefs$p_value < 0.05, na.rm = TRUE)
  n_pre <- nrow(pre_coefs)

  # Count significant post coefficients
  post_coefs <- coef_tab[grepl("event_time", term) &
                           as.numeric(gsub(".*::(-?[0-9]+):.*", "\\1",
                                           term)) >= 0]
  n_sig_post <- sum(post_coefs$p_value < 0.05, na.rm = TRUE)
  n_post <- nrow(post_coefs)

  cat(sprintf("  %-25s: %d/%d pre-trend coefs sig (p<.05), %d/%d post coefs sig\n",
              label, n_sig_pre, n_pre, n_sig_post, n_post))
}

es_coefs_dt <- rbindlist(es_coefs)

# Parse event_time from coefficient names for saving
es_coefs_dt[, event_time_val := as.integer(
  gsub(".*::(-?[0-9]+):.*", "\\1", term)
)]

# ============================================================================
# 4. DOSE-RESPONSE (THREE TREATMENT GROUPS)
# ============================================================================

cat("\n--- Section 4: Dose-Response ---\n")

# Use full panel including moderate group (40-49)
# Create treatment dummies: high (25-39), moderate (40-49), control (50-59) = reference
panel[, high := as.integer(treat_group == "High (25-39)")]
panel[, moderate := as.integer(treat_group == "Moderate (40-49)")]

# Y_at = beta1*(high*post) + beta2*(moderate*post) + age_FE + quarter_FE
dose_outcomes <- c("rate_fp", "rate_fl", "rate_kh", "rate_sy", "rate_res", "rate_ja")
dose_labels <- c("Disability Pension", "Flex Jobs", "Cash Benefits",
                 "Sickness Benefits", "Rehabilitation", "Job Clarification")

dose_models <- list()
dose_coefs <- list()

for (i in seq_along(dose_outcomes)) {
  outcome <- dose_outcomes[i]
  label <- dose_labels[i]

  fml <- as.formula(paste0(
    outcome, " ~ high:post + moderate:post | age_f + yq_f"
  ))

  mod <- feols(fml, data = panel, cluster = ~municipality)

  dose_models[[outcome]] <- mod
  coef_tab <- extract_coefs(mod, label, "DoseResponse")
  dose_coefs[[outcome]] <- coef_tab

  # Extract high and moderate interaction terms
  high_row <- coef_tab[grepl("high.*post|post.*high", term)]
  mod_row <- coef_tab[grepl("moderate.*post|post.*moderate", term)]

  if (nrow(high_row) > 0 && nrow(mod_row) > 0) {
    cat(sprintf("  %-25s: High = %7.3f%s, Moderate = %7.3f%s  [monotonic: %s]\n",
                label,
                high_row$estimate[1], high_row$stars[1],
                mod_row$estimate[1], mod_row$stars[1],
                ifelse(abs(high_row$estimate[1]) > abs(mod_row$estimate[1]),
                       "YES", "NO")))
  }
}

dose_coefs_dt <- rbindlist(dose_coefs)

cat("\nDose-response summary:\n")
print(dose_coefs_dt[, .(outcome, term, estimate, std_error, p_value, stars)])

# ============================================================================
# 4b. EMPLOYMENT DiD (Annual data from RAS200)
# ============================================================================

cat("\n--- Employment DiD (annual) ---\n")

# Ensure factor
panel_emp[, treat_group := factor(treat_group,
                                  levels = c("High (25-39)", "Moderate (40-49)",
                                             "Control (50-59)"))]

# Binary treatment panel: drop Moderate
emp_did_panel <- panel_emp[treat_group != "Moderate (40-49)"]
emp_did_panel[, young := as.integer(treat_group == "High (25-39)")]

# DiD: emp_rate ~ young:post | age + year, cluster = municipality
emp_did_mod <- feols(emp_rate ~ young:post | age + year,
                     data = emp_did_panel, cluster = ~municipality)

emp_did_coef <- extract_coefs(emp_did_mod, "Employment Rate", "DiD_Emp")
cat("  Employment DiD:\n")
print(emp_did_coef[, .(term, estimate, std_error, p_value, stars)])

# Save employment results
fwrite(emp_did_coef, file.path(DATA_DIR, "reg_emp_did.csv"))
cat("  reg_emp_did.csv saved.\n")

# Employment Event Study (annual)
cat("\n--- Employment Event Study (annual) ---\n")
emp_did_panel[, event_year := year - 2013L]
emp_did_panel[, age_f := as.factor(age)]
emp_did_panel[, year_f := as.factor(year)]
emp_did_panel[, muni_f := as.factor(municipality)]

emp_es_mod <- feols(emp_rate ~ i(event_year, young, ref = -1) | age_f + year_f,
                    data = emp_did_panel, cluster = ~municipality)

emp_es_coef <- extract_coefs(emp_es_mod, "Employment Rate", "EmpEventStudy")
emp_es_coef[, event_time_val := as.integer(gsub(".*::(-?[0-9]+):.*", "\\1", term))]

# Count sig pre-trend
emp_pre <- emp_es_coef[event_time_val < -1 & !is.na(event_time_val)]
n_sig_emp_pre <- sum(emp_pre$p_value < 0.05, na.rm = TRUE)
cat(sprintf("  Employment pre-trends: %d/%d significant at 5%%\n",
            n_sig_emp_pre, nrow(emp_pre)))

fwrite(emp_es_coef, file.path(DATA_DIR, "reg_emp_event_study.csv"))
cat("  reg_emp_event_study.csv saved.\n")

# Employment DDD
cat("\n--- Employment DDD ---\n")
emp_ddd_mod <- feols(emp_rate ~ young:post:high_base_dp + young:post +
                       young:high_base_dp + post:high_base_dp |
                       age_f^muni_f + age_f^year_f + muni_f^year_f,
                     data = emp_did_panel, cluster = ~municipality)

emp_ddd_coef <- extract_coefs(emp_ddd_mod, "Employment Rate", "DDD_Emp")
emp_ddd_triple <- emp_ddd_coef[grepl("young.*post.*high_base_dp", term)]
if (nrow(emp_ddd_triple) > 0) {
  cat(sprintf("  Employment DDD: beta = %8.3f (SE = %.3f), p = %.4f %s\n",
              emp_ddd_triple$estimate[1], emp_ddd_triple$std_error[1],
              emp_ddd_triple$p_value[1], emp_ddd_triple$stars[1]))
}
fwrite(emp_ddd_coef, file.path(DATA_DIR, "reg_emp_ddd.csv"))
cat("  reg_emp_ddd.csv saved.\n")

# ============================================================================
# 5. SAVE RESULTS
# ============================================================================

cat("\n--- Saving regression results ---\n")

# 5a. DiD coefficients
fwrite(did_coefs_dt, file.path(DATA_DIR, "reg_did_main.csv"))
cat(sprintf("  reg_did_main.csv: %d rows\n", nrow(did_coefs_dt)))

# 5b. DDD coefficients
fwrite(ddd_coefs_dt, file.path(DATA_DIR, "reg_ddd_main.csv"))
cat(sprintf("  reg_ddd_main.csv: %d rows\n", nrow(ddd_coefs_dt)))

# 5c. Event study coefficients (separate files by outcome)
for (j in seq_along(es_outcomes)) {
  es_label_j <- es_labels[j]
  es_sub <- es_coefs_dt[outcome == es_label_j]
  fname <- paste0("reg_event_study_",
                  gsub("rate_", "", es_outcomes[j]), ".csv")
  fwrite(es_sub, file.path(DATA_DIR, fname))
  cat(sprintf("  %s: %d rows\n", fname, nrow(es_sub)))
}

# 5d. Dose-response coefficients
fwrite(dose_coefs_dt, file.path(DATA_DIR, "reg_dose_response.csv"))
cat(sprintf("  reg_dose_response.csv: %d rows\n", nrow(dose_coefs_dt)))

# 5e. All model objects saved for later use
all_models <- list(
  did = did_models,
  ddd = ddd_models,
  event_study = es_models,
  dose_response = dose_models
)
saveRDS(all_models, file.path(DATA_DIR, "reg_models.rds"))
cat("  reg_models.rds saved.\n")

# ============================================================================
# 6. KEY RESULTS SUMMARY
# ============================================================================

cat("\n============================================================\n")
cat("KEY RESULTS SUMMARY\n")
cat("============================================================\n")

cat("\n1. Simple DiD (Young vs Control, national):\n")
for (i in seq_along(did_outcomes)) {
  ct <- did_coefs[[did_outcomes[i]]]
  if (nrow(ct) > 0) {
    cat(sprintf("   %-22s: %+8.3f (%.3f) %s\n",
                did_labels[i], ct$estimate[1], ct$std_error[1], ct$stars[1]))
  }
}

cat("\n2. DDD (Young x Post x High Baseline DP):\n")
for (i in seq_along(ddd_outcomes)) {
  ct <- ddd_coefs[[ddd_outcomes[i]]]
  triple <- ct[grepl("young.*post.*high_base_dp", term)]
  if (nrow(triple) > 0) {
    cat(sprintf("   %-22s: %+8.3f (%.3f) %s\n",
                ddd_labels[i], triple$estimate[1], triple$std_error[1], triple$stars[1]))
  }
}

cat("\n3. Event Study pre-trend tests (# sig at 5%% / total pre-period):\n")
for (i in seq_along(es_outcomes)) {
  ct <- es_coefs[[es_outcomes[i]]]
  pre <- ct[grepl("event_time", term)]
  pre[, et := as.integer(gsub(".*::(-?[0-9]+):.*", "\\1", term))]
  pre_only <- pre[et < -1]
  n_sig <- sum(pre_only$p_value < 0.05, na.rm = TRUE)
  cat(sprintf("   %-22s: %d / %d\n", es_labels[i], n_sig, nrow(pre_only)))
}

cat("\n4. Dose-Response (High vs Moderate, disability pension):\n")
dp_dose <- dose_coefs[["rate_fp"]]
if (!is.null(dp_dose)) {
  high_r <- dp_dose[grepl("high.*post|post.*high", term)]
  mod_r <- dp_dose[grepl("moderate.*post|post.*moderate", term)]
  if (nrow(high_r) > 0 && nrow(mod_r) > 0) {
    cat(sprintf("   High (25-39):     %+8.3f (%.3f) %s\n",
                high_r$estimate[1], high_r$std_error[1], high_r$stars[1]))
    cat(sprintf("   Moderate (40-49): %+8.3f (%.3f) %s\n",
                mod_r$estimate[1], mod_r$std_error[1], mod_r$stars[1]))
    cat(sprintf("   Monotonic ordering: %s\n",
                ifelse(abs(high_r$estimate[1]) > abs(mod_r$estimate[1]),
                       "YES (|High| > |Moderate|)", "NO")))
  }
}

cat("\n============================================================\n")
cat("03_main_analysis.R complete.\n")
