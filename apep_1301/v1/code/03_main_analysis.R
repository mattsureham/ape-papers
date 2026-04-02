## ============================================================
## 03_main_analysis.R — Main DiD + IV Regressions (State Level)
## APEP Paper apep_1301: SNAP Retailer Exits and Birth Outcomes
## ============================================================

source("code/00_packages.R")

data_dir <- "data"
tables_dir <- "tables"
dir.create(tables_dir, showWarnings = FALSE)

## ---- Load Data ----
df <- fread(file.path(data_dir, "analysis_panel.csv"))
cat(sprintf("Analysis panel: %d obs, %d states, years %d-%d\n",
            nrow(df), length(unique(df$state_fips)),
            min(df$year), max(df$year)))

## ---- 1. Summary Statistics ----
cat("\n=== Summary Statistics ===\n")

summary_stats <- data.table(
  Variable = c("Low birth weight rate (%)", "Preterm birth rate (%)",
               "C-section rate (%)", "Mean birth weight (g)",
               "Births per state-year", "Active supermarkets",
               "Supermarket exits/year", "Medicaid share (%)",
               "Unemployment rate (%)"),
  Mean = c(
    mean(df$lbw_rate_100, na.rm = TRUE),
    mean(df$preterm_rate_100, na.rm = TRUE),
    mean(df$csection_rate_100, na.rm = TRUE),
    mean(df$mean_bwt, na.rm = TRUE),
    mean(df$births, na.rm = TRUE),
    mean(df$n_supermarkets, na.rm = TRUE),
    mean(df$super_exits, na.rm = TRUE),
    mean(df$medicaid_share * 100, na.rm = TRUE),
    mean(df$unemp_rate, na.rm = TRUE)
  ),
  SD = c(
    sd(df$lbw_rate_100, na.rm = TRUE),
    sd(df$preterm_rate_100, na.rm = TRUE),
    sd(df$csection_rate_100, na.rm = TRUE),
    sd(df$mean_bwt, na.rm = TRUE),
    sd(df$births, na.rm = TRUE),
    sd(df$n_supermarkets, na.rm = TRUE),
    sd(df$super_exits, na.rm = TRUE),
    sd(df$medicaid_share * 100, na.rm = TRUE),
    sd(df$unemp_rate, na.rm = TRUE)
  )
)
print(summary_stats, digits = 2)

# Store SDs for SDE
sd_lbw <- sd(df$lbw_rate_100, na.rm = TRUE)
sd_preterm <- sd(df$preterm_rate_100, na.rm = TRUE)
sd_csection <- sd(df$csection_rate_100, na.rm = TRUE)
sd_bwt <- sd(df$mean_bwt, na.rm = TRUE)


## ---- 2. OLS DiD: Exit Rate → Birth Outcomes ----
cat("\n=== OLS DiD Regressions ===\n")

# Primary treatment: supermarket exit rate (exits per 1000 supermarkets)
# This is a continuous treatment — captures intensity of food access loss

m1_lbw <- feols(lbw_rate_100 ~ exit_rate | state_fips + year, data = df, cluster = ~state_fips)
m2_lbw <- feols(lbw_rate_100 ~ exit_rate + unemp_rate | state_fips + year, data = df, cluster = ~state_fips)

m1_preterm <- feols(preterm_rate_100 ~ exit_rate | state_fips + year, data = df, cluster = ~state_fips)
m2_preterm <- feols(preterm_rate_100 ~ exit_rate + unemp_rate | state_fips + year, data = df, cluster = ~state_fips)

m1_csection <- feols(csection_rate_100 ~ exit_rate | state_fips + year, data = df, cluster = ~state_fips)
m2_csection <- feols(csection_rate_100 ~ exit_rate + unemp_rate | state_fips + year, data = df, cluster = ~state_fips)

cat("\n--- LBW ---\n"); summary(m2_lbw)
cat("\n--- Preterm ---\n"); summary(m2_preterm)
cat("\n--- C-section (placebo) ---\n"); summary(m2_csection)


## ---- 3. Reduced Form + IV ----
cat("\n=== Reduced Form: Chain Bankruptcy Exposure → Birth Outcomes ===\n")

# Reduced form: does chain bankruptcy exposure directly predict birth outcomes?
# This avoids weak instrument concerns
rf_lbw <- feols(lbw_rate_100 ~ iv_chain_intensity | state_fips + year, data = df, cluster = ~state_fips)
rf_preterm <- feols(preterm_rate_100 ~ iv_chain_intensity | state_fips + year, data = df, cluster = ~state_fips)
rf_csection <- feols(csection_rate_100 ~ iv_chain_intensity | state_fips + year, data = df, cluster = ~state_fips)

cat("\n--- Reduced Form: LBW ---\n"); summary(rf_lbw)
cat("\n--- Reduced Form: Preterm ---\n"); summary(rf_preterm)
cat("\n--- Reduced Form: C-section ---\n"); summary(rf_csection)

cat("\n=== IV Regressions ===\n")

# First stage: chain bankruptcy exposure → exit rate
fs <- feols(exit_rate ~ iv_chain_intensity | state_fips + year, data = df, cluster = ~state_fips)
cat("\n--- First Stage ---\n")
summary(fs)
fs_f <- tryCatch({
  fst <- fitstat(fs, "ivf")
  if (is.list(fst)) fst$ivf$stat else fst
}, error = function(e) {
  # Manual F-stat: t^2 for single instrument
  t_val <- coef(fs)["iv_chain_intensity"] / se(fs)["iv_chain_intensity"]
  t_val^2
})
cat(sprintf("First-stage F-statistic: %.1f\n", fs_f))

# 2SLS
iv_lbw <- feols(lbw_rate_100 ~ 1 | state_fips + year | exit_rate ~ iv_chain_intensity,
                data = df, cluster = ~state_fips)
iv_preterm <- feols(preterm_rate_100 ~ 1 | state_fips + year | exit_rate ~ iv_chain_intensity,
                    data = df, cluster = ~state_fips)
iv_csection <- feols(csection_rate_100 ~ 1 | state_fips + year | exit_rate ~ iv_chain_intensity,
                     data = df, cluster = ~state_fips)

cat("\n--- IV: LBW ---\n"); summary(iv_lbw)
cat("\n--- IV: Preterm ---\n"); summary(iv_preterm)
cat("\n--- IV: C-section (placebo) ---\n"); summary(iv_csection)


## ---- 4. Event Study ----
cat("\n=== Event Study ===\n")

# Event study around first chain bankruptcy closure year
# Chain bankruptcy years: A&P 2015, Tops/SE Grocers 2018, Lucky's/Earth Fare 2020
# Use first chain closure year as the event for exposed states

df[, first_chain_year := fifelse(
  any(chain_closures > 0), min(year[chain_closures > 0]), NA_integer_),
  by = state_fips]
df[, chain_exposed := as.integer(!is.na(first_chain_year))]
df[, chain_rel_time := year - first_chain_year]
df[, chain_rel_binned := pmax(pmin(chain_rel_time, 3), -3)]

cat(sprintf("Chain-exposed states: %d, Never-exposed: %d\n",
            sum(df[year == 2016, chain_exposed]),
            sum(df[year == 2016, chain_exposed == 0])))

# Check if -1 exists in the data
ref_available <- -1 %in% unique(df[chain_exposed == 1, chain_rel_binned])
cat(sprintf("Reference period t=-1 available: %s\n", ref_available))

if (ref_available) {
  es_lbw <- feols(lbw_rate_100 ~ i(chain_rel_binned, chain_exposed, ref = -1) |
                    state_fips + year,
                  data = df, cluster = ~state_fips)

  es_preterm <- feols(preterm_rate_100 ~ i(chain_rel_binned, chain_exposed, ref = -1) |
                        state_fips + year,
                      data = df, cluster = ~state_fips)

  cat("\n--- Event Study: LBW ---\n"); summary(es_lbw)
  cat("\n--- Event Study: Preterm ---\n"); summary(es_preterm)
} else {
  cat("No pre-treatment period available for event study.\n")
  # Use binary pre/post chain exposure instead
  df[, post_chain := as.integer(!is.na(first_chain_year) & year >= first_chain_year)]
  es_lbw <- feols(lbw_rate_100 ~ post_chain | state_fips + year,
                  data = df, cluster = ~state_fips)
  es_preterm <- feols(preterm_rate_100 ~ post_chain | state_fips + year,
                      data = df, cluster = ~state_fips)
  cat("\n--- Binary Pre/Post Chain: LBW ---\n"); summary(es_lbw)
  cat("\n--- Binary Pre/Post Chain: Preterm ---\n"); summary(es_preterm)
}


## ---- 5. Heterogeneity: Medicaid Share ----
cat("\n=== Heterogeneity by Medicaid Share ===\n")

median_med <- median(df$medicaid_share, na.rm = TRUE)
cat(sprintf("Median Medicaid share: %.1f%%\n", median_med * 100))

m_hi_lbw <- feols(lbw_rate_100 ~ exit_rate | state_fips + year,
                  data = df[high_medicaid == 1], cluster = ~state_fips)
m_lo_lbw <- feols(lbw_rate_100 ~ exit_rate | state_fips + year,
                  data = df[high_medicaid == 0], cluster = ~state_fips)
m_hi_preterm <- feols(preterm_rate_100 ~ exit_rate | state_fips + year,
                      data = df[high_medicaid == 1], cluster = ~state_fips)
m_lo_preterm <- feols(preterm_rate_100 ~ exit_rate | state_fips + year,
                      data = df[high_medicaid == 0], cluster = ~state_fips)

cat("\n--- High Medicaid: LBW ---\n"); summary(m_hi_lbw)
cat("\n--- Low Medicaid: LBW ---\n"); summary(m_lo_lbw)


## ---- 6. Save Results ----
cat("\n=== Saving Results ===\n")

results <- list(
  ols_lbw = m2_lbw, ols_preterm = m2_preterm, ols_csection = m2_csection,
  rf_lbw = rf_lbw, rf_preterm = rf_preterm, rf_csection = rf_csection,
  iv_lbw = iv_lbw, iv_preterm = iv_preterm, iv_csection = iv_csection,
  first_stage = fs,
  es_lbw = es_lbw, es_preterm = es_preterm,
  het_hi_lbw = m_hi_lbw, het_lo_lbw = m_lo_lbw,
  het_hi_preterm = m_hi_preterm, het_lo_preterm = m_lo_preterm,
  sds = list(lbw = sd_lbw, preterm = sd_preterm, csection = sd_csection, bwt = sd_bwt),
  summary_stats = summary_stats
)

saveRDS(results, file.path(data_dir, "regression_results.rds"))

# Diagnostics for validation
# Use chain bankruptcy timing for n_treated and n_pre
n_treated <- length(unique(df[chain_exposed == 1, state_fips]))
n_pre <- length(unique(df[chain_rel_time < 0 & chain_exposed == 1, year]))
n_obs <- nrow(df)
n_chain <- length(unique(df[iv_any_chain == 1, state_fips]))

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_states = length(unique(df$state_fips)),
  n_years = length(unique(df$year)),
  n_chain_exposed = n_chain,
  first_stage_f = round(fs_f, 1)
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d, n_chain=%d, F=%.1f\n",
            n_treated, n_pre, n_obs, n_chain, fs_f))
cat("Results saved.\n")
