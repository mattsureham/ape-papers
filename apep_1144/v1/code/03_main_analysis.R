# ─── Main 2SLS Analysis: Patent Grants → County Employment ──────────────────
source("code/00_packages.R")
library(jsonlite)

panel <- fread("data/county_analysis_panel.csv")
cat(sprintf("Panel: %d obs, %d counties, years %d-%d\n",
            nrow(panel), uniqueN(panel$county_fips), min(panel$year), max(panel$year)))

# Analysis sample: need non-missing t+1 employment and instrument
panel_main <- panel[!is.na(log_Emp_t1) & !is.na(log_grants) & !is.na(bartik) & is.finite(log_Emp_t1)]
cat(sprintf("Analysis sample: %d obs, %d counties\n", nrow(panel_main), uniqueN(panel_main$county_fips)))

# ═══════════════════════════════════════════════════════════════════════════════
# 1. FIRST STAGE: Bartik → log(Grants)
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n=== FIRST STAGE ===\n")
fs <- feols(log_grants ~ bartik | county_fips + year, data = panel_main, cluster = ~county_fips)
cat(sprintf("  Bartik coef: %.3f (SE: %.3f)\n", coef(fs)["bartik"], se(fs)["bartik"]))
cat(sprintf("  t-stat: %.2f\n", coef(fs)["bartik"] / se(fs)["bartik"]))
f_stat <- (coef(fs)["bartik"] / se(fs)["bartik"])^2
cat(sprintf("  First-stage F: %.1f\n", f_stat))
cat(sprintf("  N: %d\n", nobs(fs)))

# ═══════════════════════════════════════════════════════════════════════════════
# 2. OLS BENCHMARK
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n=== OLS ===\n")
ols <- feols(log_Emp_t1 ~ log_grants | county_fips + year, data = panel_main, cluster = ~county_fips)
cat(sprintf("  log_grants coef: %.5f (SE: %.5f)\n", coef(ols)["log_grants"], se(ols)["log_grants"]))

# ═══════════════════════════════════════════════════════════════════════════════
# 3. 2SLS: Bartik → log(Grants) → log(Emp_{t+1})
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n=== 2SLS: MAIN RESULT ===\n")
iv_emp <- feols(log_Emp_t1 ~ 1 | county_fips + year | log_grants ~ bartik,
                data = panel_main, cluster = ~county_fips)
coef_iv <- coef(iv_emp)["fit_log_grants"]
se_iv <- se(iv_emp)["fit_log_grants"]
cat(sprintf("  IV coef: %.5f (SE: %.5f)\n", coef_iv, se_iv))
cat(sprintf("  t-stat: %.2f\n", coef_iv / se_iv))
cat(sprintf("  N: %d\n", nobs(iv_emp)))

# ═══════════════════════════════════════════════════════════════════════════════
# 4. REDUCED FORM: Bartik → log(Emp_{t+1})
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n=== REDUCED FORM ===\n")
rf <- feols(log_Emp_t1 ~ bartik | county_fips + year, data = panel_main, cluster = ~county_fips)
cat(sprintf("  Bartik coef: %.5f (SE: %.5f)\n", coef(rf)["bartik"], se(rf)["bartik"]))

# ═══════════════════════════════════════════════════════════════════════════════
# 5. SECONDARY OUTCOMES
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n=== SECONDARY: New Hires (t+1) ===\n")
panel_hirn <- panel_main[!is.na(log_HirN_t1) & is.finite(log_HirN_t1)]
iv_hires <- feols(log_HirN_t1 ~ 1 | county_fips + year | log_grants ~ bartik,
                  data = panel_hirn, cluster = ~county_fips)
cat(sprintf("  IV coef: %.5f (SE: %.5f), N=%d\n",
            coef(iv_hires)["fit_log_grants"], se(iv_hires)["fit_log_grants"], nobs(iv_hires)))

cat("\n=== SECONDARY: Earnings (t+1) ===\n")
panel_earn <- panel_main[!is.na(log_EarnS_t1) & is.finite(log_EarnS_t1)]
iv_earn <- feols(log_EarnS_t1 ~ 1 | county_fips + year | log_grants ~ bartik,
                 data = panel_earn, cluster = ~county_fips)
cat(sprintf("  IV coef: %.5f (SE: %.5f), N=%d\n",
            coef(iv_earn)["fit_log_grants"], se(iv_earn)["fit_log_grants"], nobs(iv_earn)))

# ═══════════════════════════════════════════════════════════════════════════════
# 6. MECHANISM: Exposed vs Local-Service
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n=== MECHANISM: Exposed Sectors (t+1) ===\n")
panel_exp <- panel_main[!is.na(log_Emp_exposed_t1) & is.finite(log_Emp_exposed_t1)]
iv_exposed <- feols(log_Emp_exposed_t1 ~ 1 | county_fips + year | log_grants ~ bartik,
                    data = panel_exp, cluster = ~county_fips)
cat(sprintf("  IV coef: %.5f (SE: %.5f), N=%d\n",
            coef(iv_exposed)["fit_log_grants"], se(iv_exposed)["fit_log_grants"], nobs(iv_exposed)))

cat("\n=== MECHANISM: Local-Service Sectors (t+1) ===\n")
panel_loc <- panel_main[!is.na(log_Emp_local_svc_t1) & is.finite(log_Emp_local_svc_t1)]
iv_local <- feols(log_Emp_local_svc_t1 ~ 1 | county_fips + year | log_grants ~ bartik,
                  data = panel_loc, cluster = ~county_fips)
cat(sprintf("  IV coef: %.5f (SE: %.5f), N=%d\n",
            coef(iv_local)["fit_log_grants"], se(iv_local)["fit_log_grants"], nobs(iv_local)))

# ═══════════════════════════════════════════════════════════════════════════════
# 7. PLACEBO: Employment at t-1
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n=== PLACEBO: Employment at t-1 ===\n")
panel_pl <- panel_main[!is.na(log_Emp_tm1) & is.finite(log_Emp_tm1)]
placebo <- feols(log_Emp_tm1 ~ bartik | county_fips + year, data = panel_pl, cluster = ~county_fips)
cat(sprintf("  Bartik coef: %.5f (SE: %.5f), N=%d\n",
            coef(placebo)["bartik"], se(placebo)["bartik"], nobs(placebo)))

# ═══════════════════════════════════════════════════════════════════════════════
# 8. ROBUSTNESS: State × year FE
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n=== ROBUSTNESS: State × Year FE ===\n")
panel_main[, state_year := paste0(state_fips, "_", year)]
iv_sxyr <- feols(log_Emp_t1 ~ 1 | county_fips + state_year | log_grants ~ bartik,
                 data = panel_main, cluster = ~county_fips)
cat(sprintf("  IV coef: %.5f (SE: %.5f), N=%d\n",
            coef(iv_sxyr)["fit_log_grants"], se(iv_sxyr)["fit_log_grants"], nobs(iv_sxyr)))

# ═══════════════════════════════════════════════════════════════════════════════
# 9. DIAGNOSTICS
# ═══════════════════════════════════════════════════════════════════════════════
diag <- list(
  n_treated = as.integer(uniqueN(panel_main$county_fips)),
  n_pre = 0L,
  n_obs = as.integer(nrow(panel_main)),
  first_stage_F = round(f_stat, 1),
  iv_coef = round(coef_iv, 6),
  iv_se = round(se_iv, 6),
  ols_coef = round(coef(ols)["log_grants"], 6),
  reduced_form_coef = round(coef(rf)["bartik"], 6),
  placebo_coef = round(coef(placebo)["bartik"], 6)
)
write_json(diag, "data/diagnostics.json", pretty = TRUE, auto_unbox = TRUE)

# ═══════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n========================================\n")
cat("           RESULTS SUMMARY\n")
cat("========================================\n")
cat(sprintf("First-stage F: %.1f (coef=%.3f, SE=%.3f)\n", f_stat,
            coef(fs)["bartik"], se(fs)["bartik"]))
cat(sprintf("OLS:  β=%.5f (SE=%.5f)\n", coef(ols)["log_grants"], se(ols)["log_grants"]))
cat(sprintf("2SLS: β=%.5f (SE=%.5f), t=%.2f\n", coef_iv, se_iv, coef_iv/se_iv))
cat(sprintf("RF:   β=%.5f (SE=%.5f)\n", coef(rf)["bartik"], se(rf)["bartik"]))
cat(sprintf("Placebo (t-1): β=%.5f (SE=%.5f)\n",
            coef(placebo)["bartik"], se(placebo)["bartik"]))
cat(sprintf("Exposed: β=%.5f, Local: β=%.5f\n",
            coef(iv_exposed)["fit_log_grants"], coef(iv_local)["fit_log_grants"]))
cat(sprintf("State×Year FE: β=%.5f (SE=%.5f)\n",
            coef(iv_sxyr)["fit_log_grants"], se(iv_sxyr)["fit_log_grants"]))

save(fs, ols, iv_emp, rf, iv_hires, iv_earn, iv_exposed, iv_local, placebo, iv_sxyr,
     file = "data/models.RData")
cat("\nSaved data/models.RData and data/diagnostics.json\n")
