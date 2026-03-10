#' 03_main_analysis.R — Main DDD regressions
#' REACH 2018 Deadline and Chemical Industry Restructuring

source("00_packages.R")

data_dir <- "../data/"
panel <- fread(paste0(data_dir, "analysis_panel.csv"))

cat("Analysis panel:", nrow(panel), "rows\n")
cat("Countries:", uniqueN(panel$geo), "\n")
cat("Sectors:", paste(unique(panel$nace_r2), collapse = ", "), "\n")
cat("Years:", min(panel$year), "-", max(panel$year), "\n")

# ===========================================================================
# 1. Main DDD — Log Enterprises
# ===========================================================================
cat("\n=== MAIN DDD REGRESSIONS ===\n")

# Model 1: Simple DD (chem × post2018)
m1_ent <- feols(ln_enterprises ~ chem_post2018 |
                  cs_id + year,
                data = panel, cluster = ~geo)

# Model 2: DDD with continuous micro-share
m2_ent <- feols(ln_enterprises ~ ddd_2018 + chem_post2018 |
                  cs_id + cy_id + sy_id,
                data = panel, cluster = ~geo)

# Model 3: DDD with binary high/low micro intensity
m3_ent <- feols(ln_enterprises ~ i(high_micro, chem_post2018) |
                  cs_id + cy_id + sy_id,
                data = panel, cluster = ~geo)

cat("Model 1 (DD):", coef(m1_ent), "\n")
cat("Model 2 (DDD continuous):", coef(m2_ent)[1], "\n")

# ===========================================================================
# 2. DDD for Employment and Turnover
# ===========================================================================
cat("\n=== EMPLOYMENT AND TURNOVER ===\n")

# Employment
m2_emp <- feols(ln_employment ~ ddd_2018 + chem_post2018 |
                  cs_id + cy_id + sy_id,
                data = panel, cluster = ~geo)

# Turnover
m2_turn <- feols(ln_turnover ~ ddd_2018 + chem_post2018 |
                   cs_id + cy_id + sy_id,
                 data = panel, cluster = ~geo)

# Turnover per enterprise (market concentration proxy)
panel[, ln_turnover_per_ent := log((turnover + 1) / (enterprises + 1))]
m2_tpe <- feols(ln_turnover_per_ent ~ ddd_2018 + chem_post2018 |
                  cs_id + cy_id + sy_id,
                data = panel, cluster = ~geo)

# ===========================================================================
# 2b. Trend-adjusted DDD — addressing pre-trend concerns
# ===========================================================================
cat("\n=== TREND-ADJUSTED SPECIFICATIONS ===\n")

# Add differential linear trend: chem × micro_share × year
m_trend_ent <- feols(ln_enterprises ~ ddd_2018 + chem_post2018 + chem_micro_trend |
                       cs_id + cy_id + sy_id,
                     data = panel, cluster = ~geo)

m_trend_emp <- feols(ln_employment ~ ddd_2018 + chem_post2018 + chem_micro_trend |
                       cs_id + cy_id + sy_id,
                     data = panel, cluster = ~geo)

cat("Trend-adjusted DDD (enterprises):", round(coef(m_trend_ent)["ddd_2018"], 4), "\n")
cat("Trend-adjusted DDD (employment):", round(coef(m_trend_emp)["ddd_2018"], 4), "\n")

# ===========================================================================
# 2c. Alternative treatment intensity: 2008 micro-share (pre-REACH)
# ===========================================================================
cat("\n=== PRE-REACH TREATMENT INTENSITY ===\n")

panel_2008 <- panel[!is.na(ddd_2018_early)]
m_early_ent <- feols(ln_enterprises ~ ddd_2018_early + chem_post2018 |
                       cs_id + cy_id + sy_id,
                     data = panel_2008, cluster = ~geo)

m_early_emp <- feols(ln_employment ~ ddd_2018_early + chem_post2018 |
                       cs_id + cy_id + sy_id,
                     data = panel_2008, cluster = ~geo)

cat("Pre-REACH intensity DDD (enterprises):", round(coef(m_early_ent)[1], 4), "\n")
cat("Pre-REACH intensity DDD (employment):", round(coef(m_early_emp)[1], 4), "\n")

# ===========================================================================
# 2d. Common sample estimation
# ===========================================================================
cat("\n=== COMMON SAMPLE ===\n")

panel_common <- panel[!is.na(ln_enterprises) & !is.na(ln_employment) &
                       is.finite(ln_enterprises) & is.finite(ln_employment)]
cat("Common sample:", nrow(panel_common), "obs (full panel:", nrow(panel), ")\n")

m_common_ent <- feols(ln_enterprises ~ ddd_2018 + chem_post2018 |
                        cs_id + cy_id + sy_id,
                      data = panel_common, cluster = ~geo)
m_common_emp <- feols(ln_employment ~ ddd_2018 + chem_post2018 |
                        cs_id + cy_id + sy_id,
                      data = panel_common, cluster = ~geo)

cat("Common sample DDD (enterprises):", round(coef(m_common_ent)[1], 4), "\n")
cat("Common sample DDD (employment):", round(coef(m_common_emp)[1], 4), "\n")

# ===========================================================================
# 3. 2013 Placebo (Falsification Test)
# ===========================================================================
cat("\n=== 2013 PLACEBO ===\n")

# Restrict to pre-2018 data only for clean placebo
panel_pre2018 <- panel[year < 2018]

m_placebo <- feols(ln_enterprises ~ ddd_2013 +
                     i(chem, post2013) |
                     cs_id + cy_id + sy_id,
                   data = panel_pre2018, cluster = ~geo)

# Employment placebo
m_placebo_emp <- feols(ln_employment ~ ddd_2013 +
                         i(chem, post2013) |
                         cs_id + cy_id + sy_id,
                       data = panel_pre2018, cluster = ~geo)

cat("2013 Placebo DDD (enterprises):", coef(m_placebo)[1], "\n")
cat("2013 Placebo DDD (employment):", coef(m_placebo_emp)[1], "\n")

# ===========================================================================
# 4. Event Study — year-by-year DDD coefficients
# ===========================================================================
cat("\n=== EVENT STUDY ===\n")

# Create event-time interactions
panel[, event_year := year]  # Treatment is 2018 for all
panel[, rel_year := year - 2018]

# Year-by-year DDD: interact each year with chem × micro_share
# Omit 2017 as reference year
panel[, `:=`(
  chem_micro = chem * micro_share_pre
)]

es_model <- feols(ln_enterprises ~ i(year, chem_micro, ref = 2017) +
                    i(year, chem, ref = 2017) |
                    cs_id + cy_id + sy_id,
                  data = panel, cluster = ~geo)

# Extract event study coefficients
es_coefs <- as.data.table(coeftable(es_model))
es_coefs[, term := rownames(coeftable(es_model))]

# Filter to the DDD terms (chem_micro interactions)
es_ddd <- es_coefs[grepl("chem_micro", term)]
es_ddd[, year := as.integer(gsub("year::(\\d+):chem_micro", "\\1", term))]
es_ddd[, rel_year := year - 2018]

setnames(es_ddd, c("Estimate", "Std. Error"), c("estimate", "se"))
es_ddd[, `:=`(
  ci_lower = estimate - 1.96 * se,
  ci_upper = estimate + 1.96 * se
)]

# Add reference year
es_ddd <- rbind(es_ddd, data.table(
  estimate = 0, se = 0, ci_lower = 0, ci_upper = 0,
  term = "ref", year = 2017, rel_year = -1
), fill = TRUE)

es_ddd <- es_ddd[order(year)]

fwrite(es_ddd[, .(year, rel_year, estimate, se, ci_lower, ci_upper)],
       paste0(data_dir, "event_study_ddd.csv"))

cat("Event study coefficients saved.\n")

# Employment event study
es_model_emp <- feols(ln_employment ~ i(year, chem_micro, ref = 2017) +
                        i(year, chem, ref = 2017) |
                        cs_id + cy_id + sy_id,
                      data = panel, cluster = ~geo)

es_coefs_emp <- as.data.table(coeftable(es_model_emp))
es_coefs_emp[, term := rownames(coeftable(es_model_emp))]
es_ddd_emp <- es_coefs_emp[grepl("chem_micro", term)]
es_ddd_emp[, year := as.integer(gsub("year::(\\d+):chem_micro", "\\1", term))]
es_ddd_emp[, rel_year := year - 2018]
setnames(es_ddd_emp, c("Estimate", "Std. Error"), c("estimate", "se"))
es_ddd_emp[, `:=`(ci_lower = estimate - 1.96 * se, ci_upper = estimate + 1.96 * se)]
es_ddd_emp <- rbind(es_ddd_emp, data.table(
  estimate = 0, se = 0, ci_lower = 0, ci_upper = 0,
  term = "ref", year = 2017, rel_year = -1
), fill = TRUE)
es_ddd_emp <- es_ddd_emp[order(year)]
fwrite(es_ddd_emp[, .(year, rel_year, estimate, se, ci_lower, ci_upper)],
       paste0(data_dir, "event_study_employment.csv"))

cat("Employment event study saved.\n")

# Formal joint F-test of pre-treatment coefficients
pre_terms_ent <- grep("year::(200[89]|201[0-6]):chem_micro", names(coef(es_model)), value = TRUE)
pre_terms_emp <- grep("year::(200[89]|201[0-6]):chem_micro", names(coef(es_model_emp)), value = TRUE)

ftest_ent <- tryCatch({
  wald(es_model, keep = pre_terms_ent)
}, error = function(e) NULL)
ftest_emp <- tryCatch({
  wald(es_model_emp, keep = pre_terms_emp)
}, error = function(e) NULL)

if (!is.null(ftest_ent)) {
  cat("Joint F-test (enterprises pre-trends): F =", round(ftest_ent$stat, 3),
      ", p =", round(ftest_ent$p, 4), "\n")
}
if (!is.null(ftest_emp)) {
  cat("Joint F-test (employment pre-trends): F =", round(ftest_emp$stat, 3),
      ", p =", round(ftest_emp$p, 4), "\n")
}

ftest_results <- data.table(
  outcome = c("enterprises", "employment"),
  F_stat = c(if (!is.null(ftest_ent)) ftest_ent$stat else NA,
             if (!is.null(ftest_emp)) ftest_emp$stat else NA),
  p_value = c(if (!is.null(ftest_ent)) ftest_ent$p else NA,
              if (!is.null(ftest_emp)) ftest_emp$p else NA),
  n_terms = c(length(pre_terms_ent), length(pre_terms_emp))
)
fwrite(ftest_results, paste0(data_dir, "pretrend_ftest.csv"))

# ===========================================================================
# 5. Save all model results
# ===========================================================================

# Main results table
main_results <- data.table(
  outcome = c("Log Enterprises", "Log Enterprises", "Log Enterprises",
              "Log Employment", "Log Turnover", "Log Turnover/Enterprise"),
  model = c("DD", "DDD (continuous)", "DDD (binary)",
            "DDD (continuous)", "DDD (continuous)", "DDD (continuous)"),
  coef = c(coef(m1_ent)[1],
           coef(m2_ent)[1],
           coef(m3_ent)[1],
           coef(m2_emp)[1],
           coef(m2_turn)[1],
           coef(m2_tpe)[1]),
  se = c(se(m1_ent)[1],
         se(m2_ent)[1],
         se(m3_ent)[1],
         se(m2_emp)[1],
         se(m2_turn)[1],
         se(m2_tpe)[1]),
  pval = c(pvalue(m1_ent)[1],
           pvalue(m2_ent)[1],
           pvalue(m3_ent)[1],
           pvalue(m2_emp)[1],
           pvalue(m2_turn)[1],
           pvalue(m2_tpe)[1]),
  N = c(m1_ent$nobs, m2_ent$nobs, m3_ent$nobs,
        m2_emp$nobs, m2_turn$nobs, m2_tpe$nobs),
  n_clusters = c(m1_ent$nobs_origin, m2_ent$nobs_origin, m3_ent$nobs_origin,
                 m2_emp$nobs_origin, m2_turn$nobs_origin, m2_tpe$nobs_origin)
)

# Add placebos
placebo_results <- rbind(
  data.table(
    outcome = "Log Enterprises (Placebo)",
    model = "DDD 2013 (continuous)",
    coef = coef(m_placebo)[1],
    se = se(m_placebo)[1],
    pval = pvalue(m_placebo)[1],
    N = m_placebo$nobs,
    n_clusters = m_placebo$nobs_origin
  ),
  data.table(
    outcome = "Log Employment (Placebo)",
    model = "DDD 2013 (continuous)",
    coef = coef(m_placebo_emp)[1],
    se = se(m_placebo_emp)[1],
    pval = pvalue(m_placebo_emp)[1],
    N = m_placebo_emp$nobs,
    n_clusters = m_placebo_emp$nobs_origin
  )
)

all_results <- rbind(main_results, placebo_results)
fwrite(all_results, paste0(data_dir, "main_results.csv"))

cat("\n=== MAIN RESULTS SUMMARY ===\n")
print(all_results[, .(outcome, model, coef = round(coef, 4),
                       se = round(se, 4), pval = round(pval, 4), N)])

# Save model objects for table generation
saveRDS(list(
  m1_ent = m1_ent, m2_ent = m2_ent, m3_ent = m3_ent,
  m2_emp = m2_emp, m2_turn = m2_turn, m2_tpe = m2_tpe,
  m_placebo = m_placebo, m_placebo_emp = m_placebo_emp,
  es_model = es_model, es_model_emp = es_model_emp,
  m_trend_ent = m_trend_ent, m_trend_emp = m_trend_emp,
  m_early_ent = m_early_ent, m_early_emp = m_early_emp,
  m_common_ent = m_common_ent, m_common_emp = m_common_emp
), paste0(data_dir, "model_objects.rds"))

cat("Main analysis complete.\n")
