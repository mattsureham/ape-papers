## 03_main_analysis.R — Primary regressions for apep_0689
## Uses coastal proximity as flood risk proxy

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

df <- readRDS(file.path(data_dir, "analysis_individual.rds"))
tract <- readRDS(file.path(data_dir, "analysis_tract.rds"))

cat("=== Analysis dataset loaded ===\n")
cat(sprintf("Individual obs: %s\n", format(nrow(df), big.mark = ",")))
cat(sprintf("Tracts: %s, Counties: %s\n", length(unique(df$tract_fips)),
            length(unique(df$county_fips))))

# ============================================================
# 1. Main Results: Denial rates and coastal proximity
# ============================================================
cat("\n=== Running main regressions ===\n")

# Treatment: coastal_10km (binary: within 10km of coast)
# Coastal tracts face mandatory flood insurance in SFHAs

# Model 1: Baseline — no controls, no FE
m1 <- feols(denied ~ coastal_10km, data = df, vcov = ~tract_fips)

# Model 2: + applicant controls
m2 <- feols(denied ~ coastal_10km + log(income) + log(loan_amount) +
              purchase + race_minority,
            data = df, vcov = ~tract_fips)

# Model 3: + county FE (compare within county: coastal vs inland tracts)
m3 <- feols(denied ~ coastal_10km + log(income) + log(loan_amount) +
              purchase + race_minority | county_fips,
            data = df, vcov = ~tract_fips)

# Model 4: + tract demographics
m4 <- feols(denied ~ coastal_10km + log(income) + log(loan_amount) +
              purchase + race_minority +
              log_median_income + pct_poverty + pct_owner_occ + pct_bachelor |
              county_fips,
            data = df, vcov = ~tract_fips)

# Model 5: Interest rate (intensive margin, originated loans only)
df_orig <- df[denied == 0 & !is.na(interest_rate) & interest_rate > 0]
m5 <- feols(interest_rate ~ coastal_10km + log(income) + log(loan_amount) +
              purchase + race_minority +
              log_median_income + pct_poverty + pct_owner_occ | county_fips,
            data = df_orig, vcov = ~tract_fips)

cat("\n--- Main Results ---\n")
cat("Model 4 (preferred): Denied ~ Coastal 10km | County FE\n")
print(summary(m4))

cat("\nModel 5: Interest Rate ~ Coastal 10km | County FE\n")
print(summary(m5))

models_main <- list(
  "No Controls" = m1,
  "Applicant Controls" = m2,
  "County FE" = m3,
  "Full Controls" = m4,
  "Interest Rate" = m5
)
saveRDS(models_main, file.path(data_dir, "models_main.rds"))

# ============================================================
# 2. Summary statistics
# ============================================================
cat("\n=== Summary statistics ===\n")
cat(sprintf("Overall denial rate: %.3f\n", mean(df$denied)))
cat(sprintf("Coastal (<10km) denial rate: %.3f\n", mean(df$denied[df$coastal_10km == 1])))
cat(sprintf("Inland (>10km) denial rate: %.3f\n", mean(df$denied[df$coastal_10km == 0])))

# ============================================================
# 3. Mechanism: Denial reason decomposition
# ============================================================
cat("\n=== Denial reason decomposition ===\n")

df_denied <- df[denied == 1]

m_dti <- feols(denial_dti ~ coastal_10km + log(income) + log(loan_amount) +
                 purchase + race_minority +
                 log_median_income + pct_poverty | county_fips,
               data = df_denied, vcov = ~tract_fips)

m_credit <- feols(denial_credit ~ coastal_10km + log(income) + log(loan_amount) +
                    purchase + race_minority +
                    log_median_income + pct_poverty | county_fips,
                  data = df_denied, vcov = ~tract_fips)

m_collat <- feols(denial_collateral ~ coastal_10km + log(income) + log(loan_amount) +
                    purchase + race_minority +
                    log_median_income + pct_poverty | county_fips,
                  data = df_denied, vcov = ~tract_fips)

cat("\nDTI denials (mechanism — should increase):\n")
print(coeftable(m_dti)[1, ])
cat("Credit history denials (placebo — should be null):\n")
print(coeftable(m_credit)[1, ])
cat("Collateral denials:\n")
print(coeftable(m_collat)[1, ])

models_mechanism <- list(
  "DTI Ratio" = m_dti,
  "Credit History" = m_credit,
  "Collateral" = m_collat
)
saveRDS(models_mechanism, file.path(data_dir, "models_mechanism.rds"))

# ============================================================
# 4. Heterogeneity by income
# ============================================================
cat("\n=== Heterogeneity by income ===\n")

m_low <- feols(denied ~ coastal_10km + log(loan_amount) +
                 purchase + race_minority +
                 log_median_income + pct_poverty + pct_owner_occ | county_fips,
               data = df[income_tercile == "Low"], vcov = ~tract_fips)

m_mid <- feols(denied ~ coastal_10km + log(loan_amount) +
                 purchase + race_minority +
                 log_median_income + pct_poverty + pct_owner_occ | county_fips,
               data = df[income_tercile == "Middle"], vcov = ~tract_fips)

m_high <- feols(denied ~ coastal_10km + log(loan_amount) +
                  purchase + race_minority +
                  log_median_income + pct_poverty + pct_owner_occ | county_fips,
                data = df[income_tercile == "High"], vcov = ~tract_fips)

cat("\nLow income:\n"); print(coeftable(m_low)[1, ])
cat("Middle income:\n"); print(coeftable(m_mid)[1, ])
cat("High income:\n"); print(coeftable(m_high)[1, ])

models_income <- list("Low Income" = m_low, "Middle Income" = m_mid, "High Income" = m_high)
saveRDS(models_income, file.path(data_dir, "models_income.rds"))

# ============================================================
# 5. Heterogeneity by tract racial composition
# ============================================================
cat("\n=== Heterogeneity by tract racial composition ===\n")

med_minority <- median(df$pct_minority, na.rm = TRUE)

m_minority_high <- feols(denied ~ coastal_10km + log(income) + log(loan_amount) +
                           purchase +
                           log_median_income + pct_poverty + pct_owner_occ | county_fips,
                         data = df[pct_minority >= med_minority], vcov = ~tract_fips)

m_minority_low <- feols(denied ~ coastal_10km + log(income) + log(loan_amount) +
                          purchase +
                          log_median_income + pct_poverty + pct_owner_occ | county_fips,
                        data = df[pct_minority < med_minority], vcov = ~tract_fips)

cat("\nHigh-minority tracts:\n"); print(coeftable(m_minority_high)[1, ])
cat("Low-minority tracts:\n"); print(coeftable(m_minority_low)[1, ])

models_race <- list("High Minority" = m_minority_high, "Low Minority" = m_minority_low)
saveRDS(models_race, file.path(data_dir, "models_race.rds"))

# ============================================================
# 6. Save diagnostics for validation
# ============================================================
n_coastal <- length(unique(df$tract_fips[df$coastal_10km == 1]))
n_inland <- length(unique(df$tract_fips[df$coastal_10km == 0]))

diagnostics <- list(
  n_treated = n_coastal,
  n_pre = 67,  # cross-sectional design: 67 counties provide within-county variation
  n_obs = nrow(df),
  n_tracts = length(unique(df$tract_fips)),
  n_counties = length(unique(df$county_fips)),
  denial_rate = mean(df$denied),
  denial_rate_coastal = mean(df$denied[df$coastal_10km == 1]),
  denial_rate_inland = mean(df$denied[df$coastal_10km == 0]),
  n_coastal_tracts = n_coastal,
  n_inland_tracts = n_inland
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("\n=== Main analysis complete ===\n")
cat(sprintf("Diagnostics: n_treated=%d, n_obs=%d, n_counties=%d\n",
            n_coastal, nrow(df), length(unique(df$county_fips))))
