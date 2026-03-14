## 04_robustness.R — Robustness checks for apep_0689

source("00_packages.R")

data_dir <- "../data"
df <- readRDS(file.path(data_dir, "analysis_individual.rds"))

cat("=== Robustness checks ===\n")

# 1. Alternative distance thresholds
cat("\n--- Alternative coastal distance thresholds ---\n")

m_5km <- feols(denied ~ coastal_5km + log(income) + log(loan_amount) +
                 purchase + race_minority +
                 log_median_income + pct_poverty + pct_owner_occ + pct_bachelor |
                 county_fips, data = df, vcov = ~tract_fips)

m_20km <- feols(denied ~ coastal_20km + log(income) + log(loan_amount) +
                  purchase + race_minority +
                  log_median_income + pct_poverty + pct_owner_occ + pct_bachelor |
                  county_fips, data = df, vcov = ~tract_fips)

cat("5km threshold:\n"); print(coeftable(m_5km)[1, ])
cat("20km threshold:\n"); print(coeftable(m_20km)[1, ])

# 2. Continuous distance (log)
cat("\n--- Continuous coastal distance ---\n")
df[, log_coast_dist := log(coast_dist_km + 0.1)]

m_cont <- feols(denied ~ log_coast_dist + log(income) + log(loan_amount) +
                  purchase + race_minority +
                  log_median_income + pct_poverty + pct_owner_occ + pct_bachelor |
                  county_fips, data = df, vcov = ~tract_fips)
cat("Log coastal distance:\n"); print(coeftable(m_cont)[1, ])

# 3. Purchase loans only
cat("\n--- Purchase loans only ---\n")
m_purch <- feols(denied ~ coastal_10km + log(income) + log(loan_amount) +
                   race_minority +
                   log_median_income + pct_poverty + pct_owner_occ + pct_bachelor |
                   county_fips, data = df[purchase == 1], vcov = ~tract_fips)
cat("Purchase only:\n"); print(coeftable(m_purch)[1, ])

# 4. Refinance only
m_refi <- feols(denied ~ coastal_10km + log(income) + log(loan_amount) +
                  race_minority +
                  log_median_income + pct_poverty + pct_owner_occ + pct_bachelor |
                  county_fips, data = df[purchase == 0], vcov = ~tract_fips)
cat("Refinance only:\n"); print(coeftable(m_refi)[1, ])

# 5. Exclude Miami-Dade
cat("\n--- Excluding Miami-Dade ---\n")
m_no_miami <- feols(denied ~ coastal_10km + log(income) + log(loan_amount) +
                      purchase + race_minority +
                      log_median_income + pct_poverty + pct_owner_occ + pct_bachelor |
                      county_fips, data = df[county_fips != "12086"], vcov = ~tract_fips)
cat("Excl Miami-Dade:\n"); print(coeftable(m_no_miami)[1, ])

# 6. Tract-level weighted regression
cat("\n--- Tract-level regression ---\n")
tract <- readRDS(file.path(data_dir, "analysis_tract.rds"))
tract[, flood_exposure_std := (coast_dist_km - mean(coast_dist_km, na.rm = TRUE)) /
        sd(coast_dist_km, na.rm = TRUE)]

m_tract <- feols(denial_rate ~ flood_exposure_std +
                   log_median_income + pct_poverty + pct_owner_occ + pct_bachelor |
                   county_fips,
                 data = tract[n_applications >= 10],
                 weights = ~n_applications, vcov = "HC1")
cat("Tract-level:\n"); print(coeftable(m_tract)[1, ])

models_robust <- list(
  "5km" = m_5km, "20km" = m_20km, "Continuous" = m_cont,
  "Purchase" = m_purch, "Refinance" = m_refi,
  "Excl Miami" = m_no_miami, "Tract Level" = m_tract
)
saveRDS(models_robust, file.path(data_dir, "models_robustness.rds"))

cat("\n=== Robustness checks complete ===\n")
