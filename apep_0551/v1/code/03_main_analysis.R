## ============================================================
## 03_main_analysis.R — Continuous DiD + Event Study
## APEP-0551: Disaster Salience and Regulatory Acceleration
## ============================================================

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "panel_dept_year.csv"))

cat("Panel loaded:", nrow(panel), "obs\n")
cat("Years:", range(panel$year), "\n")
cat("Departments:", uniqueN(panel$dept), "\n")

# ----------------------------------------------------------------
# 1. Main continuous DiD specifications
# ----------------------------------------------------------------
cat("\n=== MAIN RESULTS: CONTINUOUS DiD ===\n")

# Specification 1: Total accidents
m1_total <- feols(n_total ~ treatment | dept + year, data = panel,
                  cluster = ~dept)

# Specification 2: Severe accidents (severity_max >= 3)
m2_severe <- feols(n_severe ~ treatment | dept + year, data = panel,
                   cluster = ~dept)

# Specification 3: Fatal accidents (human severity >= 4)
m3_fatal <- feols(n_fatal ~ treatment | dept + year, data = panel,
                  cluster = ~dept)

# Specification 4: Minor/near-miss (detection channel)
m4_minor <- feols(n_minor ~ treatment | dept + year, data = panel,
                  cluster = ~dept)

# Specification 5: IC-specific accidents
m5_ic <- feols(n_ic ~ treatment | dept + year, data = panel,
               cluster = ~dept)

# Specification 6: Log(total + 1)
panel[, log_total := log(n_total + 1)]
panel[, log_severe := log(n_severe + 1)]
m6_log_total <- feols(log_total ~ treatment | dept + year, data = panel,
                      cluster = ~dept)

m7_log_severe <- feols(log_severe ~ treatment | dept + year, data = panel,
                       cluster = ~dept)

# Print results
cat("\n--- Continuous DiD Results ---\n")
cat("Treatment = log(Seveso H + 1) × Post2003\n\n")

models <- list(
  "Total" = m1_total,
  "Severe" = m2_severe,
  "Fatal" = m3_fatal,
  "Minor" = m4_minor,
  "IC Only" = m5_ic,
  "Log Total" = m6_log_total,
  "Log Severe" = m7_log_severe
)

for (name in names(models)) {
  m <- models[[name]]
  coef_val <- coef(m)["treatment"]
  se_val <- sqrt(vcov(m)["treatment", "treatment"])
  p_val <- 2 * pnorm(-abs(coef_val / se_val))
  stars <- ifelse(p_val < 0.01, "***",
           ifelse(p_val < 0.05, "**",
           ifelse(p_val < 0.1, "*", "")))
  cat(sprintf("  %-12s: β = %8.4f (SE = %6.4f) p = %.4f %s\n",
              name, coef_val, se_val, p_val, stars))
}

# Save main results
main_results <- data.table(
  outcome = names(models),
  coefficient = sapply(models, function(m) coef(m)["treatment"]),
  se = sapply(models, function(m) sqrt(vcov(m)["treatment", "treatment"])),
  n_obs = sapply(models, function(m) nobs(m))
)
main_results[, t_stat := coefficient / se]
main_results[, p_value := 2 * pnorm(-abs(t_stat))]
fwrite(main_results, file.path(data_dir, "main_results.csv"))

# ----------------------------------------------------------------
# 2. Event Study — Dynamic treatment effects
# ----------------------------------------------------------------
cat("\n=== EVENT STUDY ===\n")

# Create year indicators relative to AZF (2001)
# Omit year 2001 (t=-0, year before law) as reference
panel[, rel_year := year - 2001]

# Create interaction terms: rel_year × log_seveso
# Using i() notation in fixest
es_total <- feols(n_total ~ i(rel_year, log_seveso, ref = 0) | dept + year,
                  data = panel, cluster = ~dept)

es_severe <- feols(n_severe ~ i(rel_year, log_seveso, ref = 0) | dept + year,
                   data = panel, cluster = ~dept)

es_minor <- feols(n_minor ~ i(rel_year, log_seveso, ref = 0) | dept + year,
                  data = panel, cluster = ~dept)

# Extract event study coefficients
extract_es <- function(model, outcome_name) {
  cf <- coef(model)
  se <- sqrt(diag(vcov(model)))
  idx <- grep("rel_year", names(cf))
  data.table(
    outcome = outcome_name,
    rel_year = as.integer(gsub(".*::([-0-9]+):.*", "\\1", names(cf)[idx])),
    estimate = cf[idx],
    se = se[idx],
    ci_lo = cf[idx] - 1.96 * se[idx],
    ci_hi = cf[idx] + 1.96 * se[idx]
  )
}

es_total_dt <- extract_es(es_total, "Total accidents")
es_severe_dt <- extract_es(es_severe, "Severe accidents")
es_minor_dt <- extract_es(es_minor, "Minor accidents")

es_all <- rbind(es_total_dt, es_severe_dt, es_minor_dt)
fwrite(es_all, file.path(data_dir, "event_study_results.csv"))

cat("Event study coefficients saved\n")

# Pre-trend joint test
cat("\n--- Pre-trend Joint F-test ---\n")
pre_coefs_total <- grep("rel_year.*::-[0-9]", names(coef(es_total)), value = TRUE)
if (length(pre_coefs_total) > 0) {
  pre_test <- wald(es_total, pre_coefs_total)
  cat("  Total accidents: F =", round(pre_test$stat, 3),
      ", p =", round(pre_test$p, 4), "\n")
}

pre_coefs_severe <- grep("rel_year.*::-[0-9]", names(coef(es_severe)), value = TRUE)
if (length(pre_coefs_severe) > 0) {
  pre_test_s <- wald(es_severe, pre_coefs_severe)
  cat("  Severe accidents: F =", round(pre_test_s$stat, 3),
      ", p =", round(pre_test_s$p, 4), "\n")
}

# ----------------------------------------------------------------
# 3. Binary treatment specification (high vs low Seveso)
# ----------------------------------------------------------------
cat("\n=== BINARY TREATMENT (High vs Low Seveso) ===\n")

# Median split: high_seveso × post2003
panel[, binary_treatment := high_seveso * post2003]

m_binary_total <- feols(n_total ~ binary_treatment | dept + year,
                        data = panel, cluster = ~dept)
m_binary_severe <- feols(n_severe ~ binary_treatment | dept + year,
                         data = panel, cluster = ~dept)

cat("  Total:  β =", round(coef(m_binary_total)["binary_treatment"], 4),
    "(SE =", round(sqrt(vcov(m_binary_total)["binary_treatment", "binary_treatment"]), 4), ")\n")
cat("  Severe: β =", round(coef(m_binary_severe)["binary_treatment"], 4),
    "(SE =", round(sqrt(vcov(m_binary_severe)["binary_treatment", "binary_treatment"]), 4), ")\n")

binary_results <- data.table(
  outcome = c("Total", "Severe"),
  coefficient = c(coef(m_binary_total)["binary_treatment"],
                  coef(m_binary_severe)["binary_treatment"]),
  se = c(sqrt(vcov(m_binary_total)["binary_treatment", "binary_treatment"]),
         sqrt(vcov(m_binary_severe)["binary_treatment", "binary_treatment"]))
)
fwrite(binary_results, file.path(data_dir, "binary_treatment_results.csv"))

# ----------------------------------------------------------------
# 4. Extended panel (1992-2020) for long-run effects
# ----------------------------------------------------------------
cat("\n=== LONG-RUN EFFECTS (1992-2020) ===\n")

panel_ext <- fread(file.path(data_dir, "panel_dept_year_extended.csv"))

m_long_total <- feols(n_total ~ treatment | dept + year,
                      data = panel_ext, cluster = ~dept)
m_long_severe <- feols(n_severe ~ treatment | dept + year,
                       data = panel_ext, cluster = ~dept)

cat("  Total (1992-2020):  β =", round(coef(m_long_total)["treatment"], 4),
    "(SE =", round(sqrt(vcov(m_long_total)["treatment", "treatment"]), 4), ")\n")
cat("  Severe (1992-2020): β =", round(coef(m_long_severe)["treatment"], 4),
    "(SE =", round(sqrt(vcov(m_long_severe)["treatment", "treatment"]), 4), ")\n")

# Long-run event study
panel_ext[, rel_year := year - 2001]
es_long <- feols(n_total ~ i(rel_year, log_seveso, ref = 0) | dept + year,
                 data = panel_ext, cluster = ~dept)
es_long_dt <- extract_es(es_long, "Total (extended)")
fwrite(es_long_dt, file.path(data_dir, "event_study_extended.csv"))

# ----------------------------------------------------------------
# 5. Save all model objects for table generation
# ----------------------------------------------------------------
saveRDS(list(
  m1_total = m1_total,
  m2_severe = m2_severe,
  m3_fatal = m3_fatal,
  m4_minor = m4_minor,
  m5_ic = m5_ic,
  m6_log_total = m6_log_total,
  m7_log_severe = m7_log_severe,
  es_total = es_total,
  es_severe = es_severe,
  es_minor = es_minor,
  m_binary_total = m_binary_total,
  m_binary_severe = m_binary_severe,
  m_long_total = m_long_total,
  m_long_severe = m_long_severe
), file.path(data_dir, "main_models.rds"))

cat("\nAll main analysis complete. Models saved.\n")
