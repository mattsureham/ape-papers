## 03_main_analysis.R — Primary regressions and event study
## apep_0594: Spain's 2022 Temporary Contract Ban

source("00_packages.R")

cat("=== Main Analysis ===\n")

# Load data
dt <- fread(file.path(data_dir, "analysis_panel.csv"))
dt_sector <- fread(file.path(data_dir, "sector_panel.csv"))
dt_national <- fread(file.path(data_dir, "national_aggregates.csv"))

# Ensure factor for fixed effects
dt[, region_f := as.factor(region)]
dt[, yq_f := as.factor(yq)]
dt[, time_f := as.factor(time_num)]

# =============================================================================
# 1. MAIN SPECIFICATION: Continuous-treatment DiD
# Y_{rt} = alpha_r + gamma_t + beta * (PreTempShare_r * Post_t) + eps_{rt}
# =============================================================================

cat("\n--- Specification 1: Temporary employment share ---\n")

# Main outcome: temporary share
m1 <- feols(temp_share ~ treat | region_f + time_f,
            data = dt, cluster = ~region_f)
summary(m1)

# Secondary: permanent share
m2 <- feols(perm_share ~ treat | region_f + time_f,
            data = dt, cluster = ~region_f)
summary(m2)

# Log total wage earners (employment level effect)
dt[, log_total := log(wage_earners_total)]
m3 <- feols(log_total ~ treat | region_f + time_f,
            data = dt, cluster = ~region_f)
summary(m3)

# Unemployment rate (if available)
m4 <- NULL
if ("unemployment" %in% names(dt)) {
  m4 <- feols(unemployment ~ treat | region_f + time_f,
              data = dt, cluster = ~region_f)
  summary(m4)
}

cat("\n--- Relabeling test: permanent share should rise 1-for-1 ---\n")
cat("Temp share beta:", round(coef(m1)["treat"], 4), "\n")
cat("Perm share beta:", round(coef(m2)["treat"], 4), "\n")
cat("Sum (if relabeling = 0):", round(coef(m1)["treat"] + coef(m2)["treat"], 4), "\n")

# =============================================================================
# 2. EVENT STUDY: quarter-by-quarter treatment intensity interactions
# =============================================================================

cat("\n--- Event Study ---\n")

# Create event time dummies interacted with pre_temp_share
# Reference: event_time = -1 (2022Q1, just before reform effective 2022Q2)
dt[, event_time_f := relevel(as.factor(event_time), ref = as.character(-1))]

# Event study regression
es_model <- feols(temp_share ~ i(event_time, pre_temp_share, ref = -1) |
                    region_f + time_f,
                  data = dt, cluster = ~region_f)
summary(es_model)

# Extract event study coefficients
es_coefs <- as.data.table(coeftable(es_model))
es_coefs[, event_time := as.integer(str_extract(rownames(coeftable(es_model)), "-?\\d+"))]
setnames(es_coefs, c("Estimate", "Std. Error", "t value", "Pr(>|t|)"),
         c("estimate", "se", "t_stat", "p_value"))
es_coefs[, ci_lo := estimate - 1.96 * se]
es_coefs[, ci_hi := estimate + 1.96 * se]

fwrite(es_coefs, file.path(data_dir, "event_study_coefs.csv"))

# Event study for permanent share
es_perm <- feols(perm_share ~ i(event_time, pre_temp_share, ref = -1) |
                   region_f + time_f,
                 data = dt, cluster = ~region_f)

es_perm_coefs <- as.data.table(coeftable(es_perm))
es_perm_coefs[, event_time := as.integer(str_extract(rownames(coeftable(es_perm)), "-?\\d+"))]
setnames(es_perm_coefs, c("Estimate", "Std. Error", "t value", "Pr(>|t|)"),
         c("estimate", "se", "t_stat", "p_value"))
es_perm_coefs[, ci_lo := estimate - 1.96 * se]
es_perm_coefs[, ci_hi := estimate + 1.96 * se]

fwrite(es_perm_coefs, file.path(data_dir, "event_study_perm_coefs.csv"))

# Event study for log employment
es_emp <- feols(log_total ~ i(event_time, pre_temp_share, ref = -1) |
                  region_f + time_f,
                data = dt, cluster = ~region_f)

es_emp_coefs <- as.data.table(coeftable(es_emp))
es_emp_coefs[, event_time := as.integer(str_extract(rownames(coeftable(es_emp)), "-?\\d+"))]
setnames(es_emp_coefs, c("Estimate", "Std. Error", "t value", "Pr(>|t|)"),
         c("estimate", "se", "t_stat", "p_value"))
es_emp_coefs[, ci_lo := estimate - 1.96 * se]
es_emp_coefs[, ci_hi := estimate + 1.96 * se]

fwrite(es_emp_coefs, file.path(data_dir, "event_study_emp_coefs.csv"))

# =============================================================================
# 3. PRE-TREND TEST: Joint significance of pre-reform coefficients
# =============================================================================

cat("\n--- Pre-trend test ---\n")

# F-test for pre-reform coefficients (event_time < 0)
pre_coefs <- es_coefs[event_time < -1]
if (nrow(pre_coefs) > 0) {
  pre_f_stat <- sum(pre_coefs$estimate^2 / pre_coefs$se^2) / nrow(pre_coefs)
  pre_f_pval <- 1 - pf(pre_f_stat, nrow(pre_coefs), m1$nobs - length(coef(es_model)))
  cat("Pre-trend F-stat:", round(pre_f_stat, 3), "p-value:", round(pre_f_pval, 4), "\n")
} else {
  cat("Warning: No pre-reform coefficients found for F-test\n")
}

# Wald test using fixest
pre_vars <- grep("event_time::-[2-9]|event_time::-[1-9][0-9]",
                 names(coef(es_model)), value = TRUE)
if (length(pre_vars) > 0) {
  wald_result <- wald(es_model, pre_vars)
  cat("Wald test for pre-trends:", "stat =", round(wald_result$stat, 3),
      "p =", round(wald_result$p, 4), "\n")
}

# =============================================================================
# 4. HETEROGENEITY: By sector (national level)
# =============================================================================

cat("\n--- Sector-level results ---\n")

# Pre-reform sector temporary shares
sector_pre <- dt_sector[year == 2021, .(
  pre_sector_temp = mean(sector_temp_share, na.rm = TRUE)
), by = sector]

dt_sector <- merge(dt_sector, sector_pre, by = "sector", all.x = TRUE)
dt_sector[, post := as.integer(year > 2022 | (year == 2022 & quarter >= 2))]
dt_sector[, time_num := (year - 2010) * 4 + quarter]
dt_sector[, sector_f := as.factor(sector)]
dt_sector[, time_f := as.factor(time_num)]

# Save sector summary
sector_summary <- dt_sector[, .(
  pre_temp_share = mean(sector_temp_share[year <= 2021], na.rm = TRUE),
  post_temp_share = mean(sector_temp_share[year >= 2023], na.rm = TRUE)
), by = sector]
sector_summary[, change := post_temp_share - pre_temp_share]

cat("Sector changes in temporary share:\n")
print(sector_summary[order(change)])

fwrite(sector_summary, file.path(data_dir, "sector_summary.csv"))

# =============================================================================
# 5. Save main regression results for table generation
# =============================================================================

# Save coefficients and SEs for Table 2
main_results <- data.table(
  outcome = c("Temporary Share", "Permanent Share", "Log Employment",
              if (!is.null(m4)) "Unemployment Rate" else NULL),
  beta = c(coef(m1)["treat"], coef(m2)["treat"], coef(m3)["treat"],
           if (!is.null(m4)) coef(m4)["treat"] else NULL),
  se = c(se(m1)["treat"], se(m2)["treat"], se(m3)["treat"],
         if (!is.null(m4)) se(m4)["treat"] else NULL),
  n_obs = c(m1$nobs, m2$nobs, m3$nobs,
            if (!is.null(m4)) m4$nobs else NULL),
  n_clusters = c(m1$nparams_FEs_nested["region_f"],
                 m2$nparams_FEs_nested["region_f"],
                 m3$nparams_FEs_nested["region_f"],
                 if (!is.null(m4)) m4$nparams_FEs_nested["region_f"] else NULL)
)
main_results[, t_stat := beta / se]
main_results[, p_value := 2 * pt(-abs(t_stat), df = 17)]
main_results[, ci_lo := beta - qt(0.975, 17) * se]
main_results[, ci_hi := beta + qt(0.975, 17) * se]
main_results[, stars := ifelse(p_value < 0.01, "***",
                        ifelse(p_value < 0.05, "**",
                        ifelse(p_value < 0.10, "*", "")))]

cat("\nMain results:\n")
print(main_results)

fwrite(main_results, file.path(data_dir, "main_results.csv"))

# Save model objects for SDE table
save(m1, m2, m3, m4, es_model, es_perm, es_emp,
     file = file.path(data_dir, "main_models.RData"))

# =============================================================================
# 6. Summary statistics for Table 1
# =============================================================================

cat("\n--- Summary statistics ---\n")

# Compute summary statistics for each variable separately then bind
vars_list <- c("temp_share", "perm_share", "wage_earners_total", "pre_temp_share")
if ("unemployment" %in% names(dt)) vars_list <- c(vars_list, "unemployment", "employment")

summ_rows <- lapply(vars_list, function(v) {
  vals <- dt[[v]]
  data.table(
    variable = v,
    mean = mean(vals, na.rm = TRUE),
    sd = sd(vals, na.rm = TRUE),
    min = min(vals, na.rm = TRUE),
    max = max(vals, na.rm = TRUE),
    n = sum(!is.na(vals))
  )
})
summ_dt <- rbindlist(summ_rows)

cat("Summary statistics:\n")
print(summ_dt)

fwrite(summ_dt, file.path(data_dir, "summary_stats.csv"))

cat("\n=== Main analysis complete ===\n")
