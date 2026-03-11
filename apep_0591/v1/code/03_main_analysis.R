# =============================================================================
# 03_main_analysis.R — OLS, 2SLS, and first-stage regressions
# APEP-0591: The Erasmus Drain
# =============================================================================

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
cross <- fread(file.path(data_dir, "analysis_cross_section.csv"))

# ---------------------------------------------------------------
# 1. Summary statistics
# ---------------------------------------------------------------
sum_vars <- c("tert_share_25_34", "tert_share_25_64", "lfp_25_34",
              "out_rate", "net_out_rate", "bartik_growth",
              "predicted_out_rate", "gdp_pc")

sumstats_long <- rbindlist(lapply(intersect(sum_vars, names(panel)), function(v) {
  vals <- panel[[v]]
  vals <- vals[!is.na(vals)]
  data.table(variable = v,
             mean = mean(vals), sd = sd(vals),
             min = min(vals), max = max(vals),
             n = length(vals))
}))

fwrite(sumstats_long, file.path(data_dir, "sumstats_long.csv"))
cat("Summary statistics computed and saved\n")

# ---------------------------------------------------------------
# 2. Panel regressions: OLS baseline
# ---------------------------------------------------------------
# Outcome: tertiary education share (25-34)
# Treatment: outflow rate (per 1k youth)
# FE: region + year

ols_tert <- feols(tert_share_25_34 ~ out_rate | nuts2 + year,
                  data = panel[!is.na(tert_share_25_34) & !is.na(out_rate)],
                  cluster = ~nuts2)

cat("\n=== OLS: Tertiary Share ~ Outflow Rate ===\n")
print(summary(ols_tert))

# ---------------------------------------------------------------
# 3. First stage: Outflow rate ~ Bartik growth
# ---------------------------------------------------------------
first_stage <- feols(out_rate ~ bartik_growth | nuts2 + year,
                     data = panel[!is.na(bartik_growth) & !is.na(out_rate)],
                     cluster = ~nuts2)

# Alternative first stage with predicted outflow rate
first_stage_pred <- feols(out_rate ~ predicted_out_rate | nuts2 + year,
                          data = panel[!is.na(predicted_out_rate) & !is.na(out_rate)],
                          cluster = ~nuts2)

cat("\n=== FIRST STAGE (Bartik growth) ===\n")
print(summary(first_stage))

cat("\n=== FIRST STAGE (Predicted outflow rate) ===\n")
print(summary(first_stage_pred))

# ---------------------------------------------------------------
# 4. 2SLS: Main specifications
# ---------------------------------------------------------------

# Main: Tertiary share (25-34) instrumented by predicted outflow rate
iv_tert <- feols(tert_share_25_34 ~ 1 | nuts2 + year |
                 out_rate ~ predicted_out_rate,
                 data = panel[!is.na(tert_share_25_34) &
                              !is.na(predicted_out_rate) & !is.na(out_rate)],
                 cluster = ~nuts2)

cat("\n=== 2SLS: Tertiary Share (25-34) ~ Outflow Rate ===\n")
print(summary(iv_tert))

# Alternative instrument: Bartik growth rate
iv_tert_bg <- feols(tert_share_25_34 ~ 1 | nuts2 + year |
                    out_rate ~ bartik_growth,
                    data = panel[!is.na(tert_share_25_34) &
                                 !is.na(bartik_growth) & !is.na(out_rate)],
                    cluster = ~nuts2)

cat("\n=== 2SLS: Tertiary Share ~ Bartik Growth ===\n")
print(summary(iv_tert_bg))

# LFP (25-34) in thousands — convert to per-capita for interpretation
panel[, lfp_rate_25_34 := lfp_25_34 / (pop_20_29 / 1000)]

iv_lfp <- feols(lfp_25_34 ~ 1 | nuts2 + year |
                out_rate ~ predicted_out_rate,
                data = panel[!is.na(lfp_25_34) & !is.na(predicted_out_rate) &
                             !is.na(out_rate)],
                cluster = ~nuts2)

cat("\n=== 2SLS: LFP (25-34) ~ Outflow Rate ===\n")
print(summary(iv_lfp))

# Employment (25-34)
iv_emp <- feols(emp_25_34 ~ 1 | nuts2 + year |
                out_rate ~ predicted_out_rate,
                data = panel[!is.na(emp_25_34) & !is.na(predicted_out_rate) &
                             !is.na(out_rate)],
                cluster = ~nuts2)

cat("\n=== 2SLS: Employment (25-34) ~ Outflow Rate ===\n")
print(summary(iv_emp))

# ---------------------------------------------------------------
# 5. Placebo: Tertiary share (25-64) — broader cohort
# ---------------------------------------------------------------
iv_placebo <- feols(tert_share_25_64 ~ 1 | nuts2 + year |
                    out_rate ~ predicted_out_rate,
                    data = panel[!is.na(tert_share_25_64) &
                                 !is.na(predicted_out_rate) & !is.na(out_rate)],
                    cluster = ~nuts2)

cat("\n=== 2SLS PLACEBO: Tertiary Share (25-64) ===\n")
print(summary(iv_placebo))

# Employment (25-64) — broader employment placebo
iv_emp_placebo <- feols(emp_25_64 ~ 1 | nuts2 + year |
                        out_rate ~ predicted_out_rate,
                        data = panel[!is.na(emp_25_64) & !is.na(predicted_out_rate) &
                                     !is.na(out_rate)],
                        cluster = ~nuts2)

cat("\n=== 2SLS PLACEBO: Employment (25-64) ===\n")
print(summary(iv_emp_placebo))

# ---------------------------------------------------------------
# 6. Two-way clustering (region + year)
# ---------------------------------------------------------------
iv_tert_2way <- feols(tert_share_25_34 ~ 1 | nuts2 + year |
                      out_rate ~ predicted_out_rate,
                      data = panel[!is.na(tert_share_25_34) &
                                   !is.na(predicted_out_rate) & !is.na(out_rate)],
                      cluster = ~nuts2 + year)

cat("\n=== 2SLS with two-way clustering ===\n")
print(summary(iv_tert_2way))

# ---------------------------------------------------------------
# 7. Reduced form
# ---------------------------------------------------------------
rf_tert <- feols(tert_share_25_34 ~ predicted_out_rate | nuts2 + year,
                 data = panel[!is.na(tert_share_25_34) &
                              !is.na(predicted_out_rate)],
                 cluster = ~nuts2)

cat("\n=== REDUCED FORM ===\n")
print(summary(rf_tert))

# ---------------------------------------------------------------
# 8. Cross-sectional long-difference
# ---------------------------------------------------------------
ols_cross <- feols(delta_tert ~ delta_out | country,
                   data = cross[!is.na(delta_tert) & !is.na(delta_out)])

iv_cross <- feols(delta_tert ~ 1 | country | delta_out ~ bartik_growth_post,
                  data = cross[!is.na(delta_tert) & !is.na(bartik_growth_post) &
                               !is.na(delta_out)])

iv_cross_placebo <- feols(delta_tert_old ~ 1 | country |
                          delta_out ~ bartik_growth_post,
                          data = cross[!is.na(delta_tert_old) &
                                       !is.na(bartik_growth_post) &
                                       !is.na(delta_out)])

cat("\n=== CROSS-SECTION: OLS ===\n")
print(summary(ols_cross))
cat("\n=== CROSS-SECTION: IV ===\n")
print(summary(iv_cross))
cat("\n=== CROSS-SECTION PLACEBO ===\n")
print(summary(iv_cross_placebo))

# ---------------------------------------------------------------
# 9. Save results
# ---------------------------------------------------------------
results <- list(
  ols_tert = ols_tert,
  first_stage = first_stage,
  first_stage_pred = first_stage_pred,
  iv_tert = iv_tert,
  iv_tert_bg = iv_tert_bg,
  iv_lfp = iv_lfp,
  iv_emp = iv_emp,
  iv_placebo = iv_placebo,
  iv_emp_placebo = iv_emp_placebo,
  iv_tert_2way = iv_tert_2way,
  rf_tert = rf_tert,
  ols_cross = ols_cross,
  iv_cross = iv_cross,
  iv_cross_placebo = iv_cross_placebo
)

saveRDS(results, file.path(data_dir, "main_results.rds"))

# Save coefficient table
main_coefs <- data.table(
  model = c("OLS", "2SLS (pred)", "2SLS (growth)", "2SLS (2-way)",
            "2SLS LFP", "2SLS Emp", "2SLS Placebo (25-64)"),
  outcome = c("tert_25_34", "tert_25_34", "tert_25_34", "tert_25_34",
              "lfp_25_34", "emp_25_34", "tert_25_64"),
  beta = c(coef(ols_tert)["out_rate"],
           coef(iv_tert)["fit_out_rate"],
           coef(iv_tert_bg)["fit_out_rate"],
           coef(iv_tert_2way)["fit_out_rate"],
           coef(iv_lfp)["fit_out_rate"],
           coef(iv_emp)["fit_out_rate"],
           coef(iv_placebo)["fit_out_rate"]),
  se = c(se(ols_tert)["out_rate"],
         se(iv_tert)["fit_out_rate"],
         se(iv_tert_bg)["fit_out_rate"],
         se(iv_tert_2way)["fit_out_rate"],
         se(iv_lfp)["fit_out_rate"],
         se(iv_emp)["fit_out_rate"],
         se(iv_placebo)["fit_out_rate"]),
  n = c(nobs(ols_tert), nobs(iv_tert), nobs(iv_tert_bg), nobs(iv_tert_2way),
        nobs(iv_lfp), nobs(iv_emp), nobs(iv_placebo))
)

fwrite(main_coefs, file.path(data_dir, "main_coefficients.csv"))

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
