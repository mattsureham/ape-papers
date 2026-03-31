# 03_main_analysis.R — IV analysis: state survey stringency → deficiency severity → quality
source("00_packages.R")
setwd("../")

cat("=== Main IV Analysis ===\n")

# ---- Load data ----
df <- readRDS("data/analysis_cross_section.rds")
panel <- readRDS("data/analysis_panel.rds")

# ---- Sample restrictions ----
cat("\n[1] Sample construction...\n")

# Main sample: facilities with staffing data and valid instrument
main <- df[!is.na(total_nurse_hprd) & !is.na(loo_state_stringency) &
           !is.na(beds) & beds > 0]
cat("  Main sample:", nrow(main), "facilities\n")

# Chain subsample: facilities in multi-state chains
chain_sub <- main[in_chain == 1 & !is.na(chain_id) & chain_id != ""]
cat("  Chain subsample:", nrow(chain_sub), "facilities\n")
cat("  Unique chains:", uniqueN(chain_sub$chain_id), "\n")

# For-profit subsample (largest ownership group)
fp_sub <- main[ownership_cat == "For-profit"]
cat("  For-profit subsample:", nrow(fp_sub), "\n")

# ---- Pre-analysis: describe the instrument ----
cat("\n[2] Instrument diagnostics...\n")

# Cross-state variation in stringency
state_stats <- main[, .(
  mean_stringency = mean(loo_state_stringency),
  sd_stringency = sd(loo_state_stringency),
  n_facilities = .N
), by = state]
cat("  Cross-state stringency SD:", round(sd(state_stats$mean_stringency), 3), "\n")
cat("  Within-state stringency SD:", round(mean(main[, sd(loo_state_stringency), by = state]$V1, na.rm = TRUE), 3), "\n")

# ---- OLS baseline (Table 2) ----
cat("\n[3] OLS regressions (biased benchmark)...\n")

# OLS: severity on staffing (expected negative — worse facilities have more deficiencies)
ols1 <- feols(total_nurse_hprd ~ mean_severity, data = main, vcov = ~state)
ols2 <- feols(total_nurse_hprd ~ mean_severity + log(beds) + i(ownership_cat),
              data = main, vcov = ~state)
ols3 <- feols(rn_hprd ~ mean_severity, data = main, vcov = ~state)
ols4 <- feols(rn_hprd ~ mean_severity + log(beds) + i(ownership_cat),
              data = main, vcov = ~state)

cat("  OLS: severity → total HPRD:", round(coef(ols1)["mean_severity"], 4),
    "(SE:", round(se(ols1)["mean_severity"], 4), ")\n")
cat("  OLS: severity → RN HPRD:", round(coef(ols3)["mean_severity"], 4),
    "(SE:", round(se(ols3)["mean_severity"], 4), ")\n")

# ---- First Stage (Table 3) ----
cat("\n[4] First stage: state stringency → facility severity...\n")

# First stage specifications
fs1 <- feols(mean_severity ~ loo_state_stringency, data = main, vcov = ~state)
fs2 <- feols(mean_severity ~ loo_state_stringency + log(beds) + i(ownership_cat),
             data = main, vcov = ~state)
fs3 <- feols(mean_severity ~ loo_state_stringency + log(beds) + i(ownership_cat) | chain_id,
             data = chain_sub, vcov = ~state)

cat("  FS coeff (unconditional):", round(coef(fs1)["loo_state_stringency"], 4),
    "(SE:", round(se(fs1)["loo_state_stringency"], 4), ")\n")
cat("  FS coeff (with controls):", round(coef(fs2)["loo_state_stringency"], 4),
    "(SE:", round(se(fs2)["loo_state_stringency"], 4), ")\n")
cat("  FS coeff (chain FE):", round(coef(fs3)["loo_state_stringency"], 4),
    "(SE:", round(se(fs3)["loo_state_stringency"], 4), ")\n")

# Manual F-stat for the FS (robust t-stat squared)
fs1_fstat <- (coef(fs1)["loo_state_stringency"] / se(fs1)["loo_state_stringency"])^2
fs2_fstat <- (coef(fs2)["loo_state_stringency"] / se(fs2)["loo_state_stringency"])^2
fs3_fstat <- (coef(fs3)["loo_state_stringency"] / se(fs3)["loo_state_stringency"])^2
cat("  Robust F-stats:", round(fs1_fstat, 1), round(fs2_fstat, 1), round(fs3_fstat, 1), "\n")

# ---- 2SLS: Main IV results (Table 4) ----
cat("\n[5] 2SLS IV regressions...\n")

# Main outcome: Total nurse staffing HPRD
iv1 <- feols(total_nurse_hprd ~ 1 | mean_severity ~ loo_state_stringency,
             data = main, vcov = ~state)
iv2 <- feols(total_nurse_hprd ~ log(beds) + i(ownership_cat) |
             mean_severity ~ loo_state_stringency,
             data = main, vcov = ~state)
# Chain FE specification (strongest identification)
iv3 <- feols(total_nurse_hprd ~ log(beds) + i(ownership_cat) | chain_id |
             mean_severity ~ loo_state_stringency,
             data = chain_sub, vcov = ~state)

cat("  IV total HPRD (no controls):", round(coef(iv1)["fit_mean_severity"], 4),
    "(SE:", round(se(iv1)["fit_mean_severity"], 4), ")\n")
cat("  IV total HPRD (controls):", round(coef(iv2)["fit_mean_severity"], 4),
    "(SE:", round(se(iv2)["fit_mean_severity"], 4), ")\n")
cat("  IV total HPRD (chain FE):", round(coef(iv3)["fit_mean_severity"], 4),
    "(SE:", round(se(iv3)["fit_mean_severity"], 4), ")\n")

# RN staffing (mechanism: skill mix)
iv4 <- feols(rn_hprd ~ log(beds) + i(ownership_cat) |
             mean_severity ~ loo_state_stringency,
             data = main, vcov = ~state)
iv5 <- feols(rn_hprd ~ log(beds) + i(ownership_cat) | chain_id |
             mean_severity ~ loo_state_stringency,
             data = chain_sub, vcov = ~state)

cat("  IV RN HPRD (controls):", round(coef(iv4)["fit_mean_severity"], 4),
    "(SE:", round(se(iv4)["fit_mean_severity"], 4), ")\n")

# CNA staffing (mechanism: aide vs nurse response)
iv6 <- feols(cna_hprd ~ log(beds) + i(ownership_cat) |
             mean_severity ~ loo_state_stringency,
             data = main, vcov = ~state)

cat("  IV CNA HPRD (controls):", round(coef(iv6)["fit_mean_severity"], 4),
    "(SE:", round(se(iv6)["fit_mean_severity"], 4), ")\n")

# ---- Reduced Form (Table 4, Panel B) ----
cat("\n[6] Reduced form: stringency → staffing...\n")

rf1 <- feols(total_nurse_hprd ~ loo_state_stringency, data = main, vcov = ~state)
rf2 <- feols(total_nurse_hprd ~ loo_state_stringency + log(beds) + i(ownership_cat),
             data = main, vcov = ~state)
rf3 <- feols(rn_hprd ~ loo_state_stringency + log(beds) + i(ownership_cat),
             data = main, vcov = ~state)

cat("  RF total HPRD:", round(coef(rf1)["loo_state_stringency"], 4),
    "(SE:", round(se(rf1)["loo_state_stringency"], 4), ")\n")
cat("  RF total HPRD (controls):", round(coef(rf2)["loo_state_stringency"], 4),
    "(SE:", round(se(rf2)["loo_state_stringency"], 4), ")\n")

# ---- Quality Outcomes (Table 5) ----
cat("\n[7] Quality measure outcomes...\n")

# Check which QM columns exist and have data
qm_cols <- grep("^\\d{3}$", names(main), value = TRUE)
cat("  Available QM columns:", paste(qm_cols, collapse = ", "), "\n")

# Key long-stay quality measures (look up CMS codes):
# 401 = % residents with UTI (lower = better)
# 407 = % high-risk residents with pressure ulcers (lower = better)
# 408 = % physically restrained (lower = better)
# 410 = % with depressive symptoms (lower = better)
# 451 = % who fell (lower = better)

qm_results <- list()
for (qm in qm_cols) {
  vals <- main[[qm]]
  n_valid <- sum(!is.na(vals))
  if (n_valid > 1000 && sd(vals, na.rm = TRUE) > 0.001) {
    fit <- tryCatch(
      feols(as.formula(paste0("`", qm, "` ~ log(beds) + i(ownership_cat) | mean_severity ~ loo_state_stringency")),
            data = main, vcov = ~state),
      error = function(e) NULL
    )
    if (!is.null(fit)) {
      qm_results[[qm]] <- list(
        coef = coef(fit)["fit_mean_severity"],
        se = se(fit)["fit_mean_severity"],
        n = nobs(fit)
      )
      cat("  QM", qm, ": coef =", round(coef(fit)["fit_mean_severity"], 4),
          "(SE:", round(se(fit)["fit_mean_severity"], 4), ") N =", nobs(fit), "\n")
    }
  }
}

# ---- Write diagnostics.json ----
cat("\n[8] Writing diagnostics...\n")

# For IV, n_treated = facilities in strict states (above median stringency)
median_stringency <- median(main$loo_state_stringency, na.rm = TRUE)
n_strict <- sum(main$loo_state_stringency > median_stringency, na.rm = TRUE)

diagnostics <- list(
  n_treated = n_strict,
  n_pre = as.integer(length(unique(panel$survey_year[panel$survey_year < 2025]))),
  n_obs = nrow(main),
  n_facilities = uniqueN(main$ccn),
  n_states = uniqueN(main$state),
  n_chain_facilities = nrow(chain_sub),
  n_chains = uniqueN(chain_sub$chain_id),
  fs_f_stat_1 = round(as.numeric(fs1_fstat), 1),
  fs_f_stat_2 = round(as.numeric(fs2_fstat), 1),
  iv_coef_main = round(as.numeric(coef(iv2)["fit_mean_severity"]), 4),
  iv_se_main = round(as.numeric(se(iv2)["fit_mean_severity"]), 4)
)
jsonlite::write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE)
cat("  Diagnostics written\n")

# ---- Save model objects ----
save(ols1, ols2, ols3, ols4, fs1, fs2, fs3,
     iv1, iv2, iv3, iv4, iv5, iv6,
     rf1, rf2, rf3, qm_results,
     main, chain_sub,
     file = "data/models.RData")

cat("\n=== Analysis Complete ===\n")
cat("  Main sample:", nrow(main), "facilities\n")
cat("  Chain sample:", nrow(chain_sub), "facilities\n")
cat("  First-stage F:", round(as.numeric(fs2_fstat), 1), "\n")
cat("  IV coefficient (total HPRD):", round(as.numeric(coef(iv2)["fit_mean_severity"]), 4), "\n")
