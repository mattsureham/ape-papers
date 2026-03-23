# 03_main_analysis.R — Main econometric analysis
source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))

# Drop observations without gender gap data
panel <- panel[!is.na(pre_gender_gap)]
cat(sprintf("Analysis sample: %d observations\n", nrow(panel)))
cat(sprintf("  Cantons: %d, NOGA: %d, Years: %d-%d\n",
            uniqueN(panel$canton), uniqueN(panel$noga_code),
            min(panel$year), max(panel$year)))

# ============================================================
# Main outcomes:
# 1. female_share — Did female employment share change?
# 2. log_emp — Did total employment change?
# 3. log_est — Did number of establishments change?
# 4. log_fte — Did FTE change?
# ============================================================

# Standardize treatment intensity (for interpretation)
panel[, gap_std := (pre_gender_gap - mean(pre_gender_gap)) / sd(pre_gender_gap)]

# ============================================================
# Table 1: Main results — continuous treatment intensity
# ============================================================

cat("\n=== TABLE 1: Main DiD Results ===\n")

# Model 1: Female share ~ post × gender_gap
m1 <- feols(female_share ~ treat_intensity | canton_noga + year,
            data = panel, cluster = ~noga_code)

# Model 2: Log employment
m2 <- feols(log_emp ~ treat_intensity | canton_noga + year,
            data = panel, cluster = ~noga_code)

# Model 3: Log establishments
m3 <- feols(log_est ~ treat_intensity | canton_noga + year,
            data = panel, cluster = ~noga_code)

# Model 4: Log FTE
m4 <- feols(log_fte ~ treat_intensity | canton_noga + year,
            data = panel, cluster = ~noga_code)

# Model 5: Average establishment size
m5 <- feols(log(avg_size + 1) ~ treat_intensity | canton_noga + year,
            data = panel[is.finite(avg_size)], cluster = ~noga_code)

cat("\nModel 1: Female share\n")
print(summary(m1))
cat("\nModel 2: Log employment\n")
print(summary(m2))
cat("\nModel 3: Log establishments\n")
print(summary(m3))

# ============================================================
# Table 2: Binary treatment (high vs low gender gap)
# ============================================================

cat("\n=== TABLE 2: Binary Treatment (Above/Below Median Gap) ===\n")

m2_1 <- feols(female_share ~ high_gap_post | canton_noga + year,
              data = panel, cluster = ~noga_code)
m2_2 <- feols(log_emp ~ high_gap_post | canton_noga + year,
              data = panel, cluster = ~noga_code)
m2_3 <- feols(log_est ~ high_gap_post | canton_noga + year,
              data = panel, cluster = ~noga_code)
m2_4 <- feols(log_fte ~ high_gap_post | canton_noga + year,
              data = panel, cluster = ~noga_code)

cat("\nBinary — Female share:\n")
print(summary(m2_1))
cat("\nBinary — Log employment:\n")
print(summary(m2_2))

# ============================================================
# Table 3: Event study — year-by-year effects
# ============================================================

cat("\n=== TABLE 3: Event Study ===\n")

# Create relative time indicators (base: 2019)
panel[, rel_year := year - 2020]
panel[, event_time := factor(rel_year)]

# Continuous intensity event study
m_event <- feols(female_share ~ i(event_time, pre_gender_gap, ref = -1) |
                   canton_noga + year,
                 data = panel, cluster = ~noga_code)

cat("\nEvent study (female share):\n")
print(summary(m_event))

# Event study for log employment
m_event_emp <- feols(log_emp ~ i(event_time, pre_gender_gap, ref = -1) |
                       canton_noga + year,
                     data = panel, cluster = ~noga_code)

cat("\nEvent study (log employment):\n")
print(summary(m_event_emp))

# ============================================================
# Save results for tables
# ============================================================

# Compute SDE components
y_pre <- panel[post == 0, .(
  sd_female_share = sd(female_share, na.rm = TRUE),
  sd_log_emp = sd(log_emp, na.rm = TRUE),
  sd_log_est = sd(log_est, na.rm = TRUE),
  sd_log_fte = sd(log_fte, na.rm = TRUE)
)]

cat("\n=== Pre-treatment SDs ===\n")
print(y_pre)

# Save coefficient estimates
results <- data.table(
  outcome = c("Female share", "Log employment", "Log establishments", "Log FTE", "Log avg. size"),
  beta = c(coef(m1)["treat_intensity"],
           coef(m2)["treat_intensity"],
           coef(m3)["treat_intensity"],
           coef(m4)["treat_intensity"],
           coef(m5)["treat_intensity"]),
  se = c(se(m1)["treat_intensity"],
         se(m2)["treat_intensity"],
         se(m3)["treat_intensity"],
         se(m4)["treat_intensity"],
         se(m5)["treat_intensity"]),
  n = c(m1$nobs, m2$nobs, m3$nobs, m4$nobs, m5$nobs)
)
results[, tstat := beta / se]
results[, pval := 2 * pnorm(-abs(tstat))]

cat("\n=== MAIN RESULTS SUMMARY ===\n")
print(results)

# Save diagnostics
diag <- list(
  n_treated = uniqueN(panel[post == 1 & high_gap == 1]$canton_noga),
  n_pre = uniqueN(panel[post == 0]$year),
  n_obs = nrow(panel),
  n_cantons = uniqueN(panel$canton),
  n_industries = uniqueN(panel$noga_code),
  n_years = uniqueN(panel$year),
  sd_y_female_share = y_pre$sd_female_share,
  sd_y_log_emp = y_pre$sd_log_emp
)
jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

# Save model objects for table generation
save(m1, m2, m3, m4, m5, m2_1, m2_2, m2_3, m2_4,
     m_event, m_event_emp, results, y_pre, panel,
     file = file.path(data_dir, "models.RData"))

cat("\nMain analysis complete.\n")
