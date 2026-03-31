# 04_robustness.R — Robustness checks for IV analysis
source("00_packages.R")
setwd("../")

cat("=== Robustness Checks ===\n")

load("data/models.RData")
panel <- readRDS("data/analysis_panel.rds")

# ---- 1. Anderson-Rubin weak-IV-robust inference ----
cat("\n[1] Anderson-Rubin test (weak-IV robust)...\n")

# For the main spec, compute AR confidence set
# AR test: reduced-form F-test that is valid regardless of instrument strength
rf_full <- feols(total_nurse_hprd ~ loo_state_stringency + log(beds) + i(ownership_cat),
                 data = main, vcov = ~state)
ar_fstat <- (coef(rf_full)["loo_state_stringency"] / se(rf_full)["loo_state_stringency"])^2
ar_pval <- 1 - pf(as.numeric(ar_fstat), 1, uniqueN(main$state) - 1)
cat("  AR F-stat:", round(as.numeric(ar_fstat), 2), "p-value:", round(ar_pval, 4), "\n")

# ---- 2. Leave-one-state-out jackknife ----
cat("\n[2] Leave-one-state-out jackknife...\n")

states <- unique(main$state)
loo_coefs <- numeric(length(states))
names(loo_coefs) <- states

for (i in seq_along(states)) {
  sub <- main[state != states[i]]
  # Use existing loo_state_stringency (already excludes focal facility, dropping
  # an entire state just checks sensitivity to influential states)
  fit <- tryCatch(
    feols(total_nurse_hprd ~ log(beds) + i(ownership_cat) |
          mean_severity ~ loo_state_stringency, data = sub, vcov = ~state),
    error = function(e) NULL
  )
  if (!is.null(fit)) {
    loo_coefs[i] <- coef(fit)["fit_mean_severity"]
  } else {
    loo_coefs[i] <- NA
  }
}

cat("  Jackknife IV coefficients:\n")
cat("    Mean:", round(mean(loo_coefs, na.rm = TRUE), 4), "\n")
cat("    Median:", round(median(loo_coefs, na.rm = TRUE), 4), "\n")
cat("    Min:", round(min(loo_coefs, na.rm = TRUE), 4), "\n")
cat("    Max:", round(max(loo_coefs, na.rm = TRUE), 4), "\n")
cat("    SD:", round(sd(loo_coefs, na.rm = TRUE), 4), "\n")

# ---- 3. Heterogeneity: ownership type ----
cat("\n[3] Heterogeneity by ownership type...\n")

fp <- main[ownership_cat == "For-profit"]
np <- main[ownership_cat == "Non-profit"]
gov <- main[ownership_cat == "Government"]

iv_fp <- feols(total_nurse_hprd ~ log(beds) | mean_severity ~ loo_state_stringency,
               data = fp, vcov = ~state)
iv_np <- tryCatch(
  feols(total_nurse_hprd ~ log(beds) | mean_severity ~ loo_state_stringency,
        data = np, vcov = ~state),
  error = function(e) NULL
)

cat("  For-profit:", round(coef(iv_fp)["fit_mean_severity"], 4),
    "(SE:", round(se(iv_fp)["fit_mean_severity"], 4), ") N =", nobs(iv_fp), "\n")
if (!is.null(iv_np)) {
  cat("  Non-profit:", round(coef(iv_np)["fit_mean_severity"], 4),
      "(SE:", round(se(iv_np)["fit_mean_severity"], 4), ") N =", nobs(iv_np), "\n")
}

# ---- 4. Heterogeneity: chain vs independent ----
cat("\n[4] Heterogeneity: chain vs independent...\n")

chain_only <- main[in_chain == 1]
indep_only <- main[in_chain == 0]

iv_chain <- feols(total_nurse_hprd ~ log(beds) + i(ownership_cat) |
                  mean_severity ~ loo_state_stringency,
                  data = chain_only, vcov = ~state)
iv_indep <- feols(total_nurse_hprd ~ log(beds) + i(ownership_cat) |
                  mean_severity ~ loo_state_stringency,
                  data = indep_only, vcov = ~state)

cat("  Chain facilities:", round(coef(iv_chain)["fit_mean_severity"], 4),
    "(SE:", round(se(iv_chain)["fit_mean_severity"], 4), ") N =", nobs(iv_chain), "\n")
cat("  Independent:", round(coef(iv_indep)["fit_mean_severity"], 4),
    "(SE:", round(se(iv_indep)["fit_mean_severity"], 4), ") N =", nobs(iv_indep), "\n")

# ---- 5. Alternative severity measures ----
cat("\n[5] Alternative endogenous variables...\n")

# Use max severity instead of mean
main[, loo_state_max_severity := {
  st_total <- sum(max_severity)
  st_n <- .N
  (st_total - max_severity) / (st_n - 1)
}, by = .(state)]

iv_max <- feols(total_nurse_hprd ~ log(beds) + i(ownership_cat) |
                max_severity ~ loo_state_stringency,
                data = main, vcov = ~state)
cat("  Using max severity:", round(coef(iv_max)["fit_max_severity"], 4),
    "(SE:", round(se(iv_max)["fit_max_severity"], 4), ")\n")

# Use number of deficiencies
iv_ndef <- feols(total_nurse_hprd ~ log(beds) + i(ownership_cat) |
                 n_deficiencies ~ loo_state_stringency,
                 data = main, vcov = ~state)
cat("  Using n_deficiencies:", round(coef(iv_ndef)["fit_n_deficiencies"], 4),
    "(SE:", round(se(iv_ndef)["fit_n_deficiencies"], 4), ")\n")

# ---- 6. Balance test: instrument on pre-determined covariates ----
cat("\n[6] Balance tests: stringency on covariates...\n")

bal_beds <- feols(log(beds) ~ loo_state_stringency, data = main, vcov = ~state)
bal_urban <- feols(as.numeric(urban == "Y") ~ loo_state_stringency, data = main[!is.na(urban)], vcov = ~state)
bal_fp <- feols(as.numeric(ownership_cat == "For-profit") ~ loo_state_stringency,
                data = main, vcov = ~state)

cat("  log(beds):", round(coef(bal_beds)["loo_state_stringency"], 4),
    "(SE:", round(se(bal_beds)["loo_state_stringency"], 4), ")\n")
cat("  Urban:", round(coef(bal_urban)["loo_state_stringency"], 4),
    "(SE:", round(se(bal_urban)["loo_state_stringency"], 4), ")\n")
cat("  For-profit:", round(coef(bal_fp)["loo_state_stringency"], 4),
    "(SE:", round(se(bal_fp)["loo_state_stringency"], 4), ")\n")

# ---- 7. RN staffing decomposition ----
cat("\n[7] Staff-type decomposition...\n")

iv_rn <- feols(rn_hprd ~ log(beds) + i(ownership_cat) |
               mean_severity ~ loo_state_stringency, data = main, vcov = ~state)
iv_lpn <- feols(lpn_hprd ~ log(beds) + i(ownership_cat) |
                mean_severity ~ loo_state_stringency, data = main[!is.na(lpn_hprd)], vcov = ~state)
iv_cna <- feols(cna_hprd ~ log(beds) + i(ownership_cat) |
                mean_severity ~ loo_state_stringency, data = main[!is.na(cna_hprd)], vcov = ~state)

cat("  RN HPRD:", round(coef(iv_rn)["fit_mean_severity"], 4),
    "(SE:", round(se(iv_rn)["fit_mean_severity"], 4), ")\n")
cat("  LPN HPRD:", round(coef(iv_lpn)["fit_mean_severity"], 4),
    "(SE:", round(se(iv_lpn)["fit_mean_severity"], 4), ")\n")
cat("  CNA HPRD:", round(coef(iv_cna)["fit_mean_severity"], 4),
    "(SE:", round(se(iv_cna)["fit_mean_severity"], 4), ")\n")

# Sum check
sum_iv <- coef(iv_rn)["fit_mean_severity"] + coef(iv_lpn)["fit_mean_severity"] + coef(iv_cna)["fit_mean_severity"]
cat("  Sum (RN+LPN+CNA):", round(as.numeric(sum_iv), 4), "vs Total:", round(coef(iv2)["fit_mean_severity"], 4), "\n")

# ---- 8. Outcome: turnover ----
cat("\n[8] Turnover outcomes...\n")

iv_turnover <- tryCatch(
  feols(total_turnover ~ log(beds) + i(ownership_cat) |
        mean_severity ~ loo_state_stringency,
        data = main[!is.na(total_turnover)], vcov = ~state),
  error = function(e) NULL
)
if (!is.null(iv_turnover)) {
  cat("  Total turnover:", round(coef(iv_turnover)["fit_mean_severity"], 4),
      "(SE:", round(se(iv_turnover)["fit_mean_severity"], 4), ") N =", nobs(iv_turnover), "\n")
}

iv_rn_turn <- tryCatch(
  feols(rn_turnover ~ log(beds) + i(ownership_cat) |
        mean_severity ~ loo_state_stringency,
        data = main[!is.na(rn_turnover)], vcov = ~state),
  error = function(e) NULL
)
if (!is.null(iv_rn_turn)) {
  cat("  RN turnover:", round(coef(iv_rn_turn)["fit_mean_severity"], 4),
      "(SE:", round(se(iv_rn_turn)["fit_mean_severity"], 4), ") N =", nobs(iv_rn_turn), "\n")
}

# ---- Save robustness results ----
save(loo_coefs, ar_fstat, ar_pval,
     iv_fp, iv_np, iv_chain, iv_indep, iv_max, iv_ndef,
     bal_beds, bal_urban, bal_fp,
     iv_rn, iv_lpn, iv_cna, iv_turnover, iv_rn_turn,
     file = "data/robustness_models.RData")

cat("\n=== Robustness Complete ===\n")
