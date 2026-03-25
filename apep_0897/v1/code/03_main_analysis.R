## 03_main_analysis.R — Main IV regressions
## apep_0897: The Carboniferous Lottery

source("00_packages.R")

DATA_DIR <- "../data"
TABLE_DIR <- "../tables"
dir.create(TABLE_DIR, showWarnings = FALSE)

# ======================================================================
# LOAD DATA
# ======================================================================
df <- readRDS(file.path(DATA_DIR, "analysis_full.rds"))
cat("Analysis sample:", nrow(df), "counties\n")
cat("States:", paste(sort(unique(df$state_fips)), collapse = ", "), "\n")

# ======================================================================
# 1. DESCRIPTIVE STATISTICS
# ======================================================================
cat("\n=== Descriptive Statistics ===\n")

desc_vars <- c("surface_share", "avg_conductance", "log_production",
               "total_pop", "median_income", "pct_poverty", "pct_black",
               "median_age", "geo_surface_share")

desc_stats <- df %>%
  select(any_of(desc_vars)) %>%
  summarize(across(everything(), list(
    mean = ~mean(.x, na.rm = TRUE),
    sd = ~sd(.x, na.rm = TRUE),
    min = ~min(.x, na.rm = TRUE),
    max = ~max(.x, na.rm = TRUE),
    n = ~sum(!is.na(.x))
  )))

# Print summary
for (v in desc_vars) {
  if (v %in% names(df)) {
    cat(sprintf("  %-25s mean=%8.2f  sd=%8.2f  n=%d\n",
                v, mean(df[[v]], na.rm = TRUE),
                sd(df[[v]], na.rm = TRUE),
                sum(!is.na(df[[v]]))))
  }
}

# Save descriptive statistics table
desc_table <- df %>%
  select(any_of(desc_vars)) %>%
  pivot_longer(everything()) %>%
  group_by(name) %>%
  summarize(
    Mean = mean(value, na.rm = TRUE),
    SD = sd(value, na.rm = TRUE),
    Min = min(value, na.rm = TRUE),
    Max = max(value, na.rm = TRUE),
    N = sum(!is.na(value)),
    .groups = "drop"
  )

# ======================================================================
# 2. OLS BASELINE
# ======================================================================
cat("\n=== OLS Regressions ===\n")

# Naive OLS: conductance ~ surface_share
ols1 <- feols(avg_conductance ~ surface_share,
              data = df, vcov = ~state_fips)

# OLS with controls
ols2 <- feols(avg_conductance ~ surface_share + log_production +
                log_pop + log_income + pct_poverty + pct_black +
                median_age,
              data = df, vcov = ~state_fips)

# OLS with state FE
ols3 <- feols(avg_conductance ~ surface_share + log_production +
                log_pop + log_income + pct_poverty + pct_black +
                median_age | state_fips,
              data = df, vcov = ~state_fips)

cat("  OLS (naive):    β =", round(coef(ols1)["surface_share"], 2),
    " (SE =", round(se(ols1)["surface_share"], 2), ")\n")
cat("  OLS (controls): β =", round(coef(ols2)["surface_share"], 2),
    " (SE =", round(se(ols2)["surface_share"], 2), ")\n")
cat("  OLS (state FE): β =", round(coef(ols3)["surface_share"], 2),
    " (SE =", round(se(ols3)["surface_share"], 2), ")\n")

# ======================================================================
# 3. FIRST STAGE: geo_surface_share → surface_share
# ======================================================================
cat("\n=== First Stage ===\n")

# The instrument: geological surface share (share of all mines ever opened
# that are surface mines) → current production-weighted surface share

fs1 <- feols(surface_share ~ geo_surface_share,
             data = df, vcov = ~state_fips)

fs2 <- feols(surface_share ~ geo_surface_share + log_production +
               log_pop + log_income + pct_poverty + pct_black +
               median_age,
             data = df, vcov = ~state_fips)

fs3 <- feols(surface_share ~ geo_surface_share + log_production +
               log_pop + log_income + pct_poverty + pct_black +
               median_age | state_fips,
             data = df, vcov = ~state_fips)

cat("  FS (no controls):  γ =", round(coef(fs1)["geo_surface_share"], 3),
    " (SE =", round(se(fs1)["geo_surface_share"], 3), ")\n")
cat("  FS (controls):     γ =", round(coef(fs2)["geo_surface_share"], 3),
    " (SE =", round(se(fs2)["geo_surface_share"], 3), ")\n")
cat("  FS (state FE):     γ =", round(coef(fs3)["geo_surface_share"], 3),
    " (SE =", round(se(fs3)["geo_surface_share"], 3), ")\n")

# First-stage F-statistics (Wald test on instrument coefficient)
fs1_F <- (coef(fs1)["geo_surface_share"] / se(fs1)["geo_surface_share"])^2
fs2_F <- (coef(fs2)["geo_surface_share"] / se(fs2)["geo_surface_share"])^2
fs3_F <- (coef(fs3)["geo_surface_share"] / se(fs3)["geo_surface_share"])^2
cat("\n  First-stage F-statistics (t^2):\n")
cat("    No controls: F =", round(fs1_F, 1), "\n")
cat("    Controls:    F =", round(fs2_F, 1), "\n")
cat("    State FE:    F =", round(fs3_F, 1), "\n")

# ======================================================================
# 4. REDUCED FORM: geo_surface_share → avg_conductance
# ======================================================================
cat("\n=== Reduced Form ===\n")

rf1 <- feols(avg_conductance ~ geo_surface_share,
             data = df, vcov = ~state_fips)

rf2 <- feols(avg_conductance ~ geo_surface_share + log_production +
               log_pop + log_income + pct_poverty + pct_black +
               median_age,
             data = df, vcov = ~state_fips)

rf3 <- feols(avg_conductance ~ geo_surface_share + log_production +
               log_pop + log_income + pct_poverty + pct_black +
               median_age | state_fips,
             data = df, vcov = ~state_fips)

cat("  RF (no controls):  π =", round(coef(rf1)["geo_surface_share"], 2),
    " (SE =", round(se(rf1)["geo_surface_share"], 2), ")\n")
cat("  RF (state FE):     π =", round(coef(rf3)["geo_surface_share"], 2),
    " (SE =", round(se(rf3)["geo_surface_share"], 2), ")\n")

# ======================================================================
# 5. 2SLS: surface_share (instrumented) → avg_conductance
# ======================================================================
cat("\n=== Two-Stage Least Squares ===\n")

# 2SLS with fixest — use HC1 as primary (7 clusters is too few for clustering)
iv1 <- feols(avg_conductance ~ 1 | surface_share ~ geo_surface_share,
             data = df, vcov = "HC1")

iv2 <- feols(avg_conductance ~ log_production + log_pop + log_income +
               pct_poverty + pct_black + median_age |
               surface_share ~ geo_surface_share,
             data = df, vcov = "HC1")

iv3 <- feols(avg_conductance ~ log_production + log_pop + log_income +
               pct_poverty + pct_black + median_age |
               state_fips |
               surface_share ~ geo_surface_share,
             data = df, vcov = "HC1")

cat("  2SLS (no controls):  β_IV =", round(coef(iv1)["fit_surface_share"], 2),
    " (SE =", round(se(iv1)["fit_surface_share"], 2), ")\n")
cat("  2SLS (controls):     β_IV =", round(coef(iv2)["fit_surface_share"], 2),
    " (SE =", round(se(iv2)["fit_surface_share"], 2), ")\n")
cat("  2SLS (state FE):     β_IV =", round(coef(iv3)["fit_surface_share"], 2),
    " (SE =", round(se(iv3)["fit_surface_share"], 2), ")\n")

# Hausman-type comparison
cat("\n  OLS vs 2SLS comparison (state FE spec):\n")
cat("    OLS: ", round(coef(ols3)["surface_share"], 2), "\n")
cat("    2SLS:", round(coef(iv3)["fit_surface_share"], 2), "\n")

# ======================================================================
# 6. ADDITIONAL OUTCOMES (if data available)
# ======================================================================
cat("\n=== Additional Outcomes ===\n")

# Log conductance for elasticity interpretation
df$log_conductance <- log(df$avg_conductance)

iv_log <- feols(log_conductance ~ log_production + log_pop + log_income +
                  pct_poverty + pct_black + median_age |
                  state_fips |
                  surface_share ~ geo_surface_share,
                data = df, vcov = "HC1")

cat("  2SLS (log conductance, state FE): β_IV =",
    round(coef(iv_log)["fit_surface_share"], 3),
    " (SE =", round(se(iv_log)["fit_surface_share"], 3), ")\n")

# Selenium (if available)
if ("avg_selenium" %in% names(df) && sum(!is.na(df$avg_selenium)) >= 20) {
  iv_se <- feols(avg_selenium ~ log_production + log_pop + log_income +
                   pct_poverty + pct_black + median_age |
                   state_fips |
                   surface_share ~ geo_surface_share,
                 data = df %>% filter(!is.na(avg_selenium)),
                 vcov = "HC1")
  cat("  2SLS (selenium, state FE): β_IV =",
      round(coef(iv_se)["fit_surface_share"], 3),
      " (SE =", round(se(iv_se)["fit_surface_share"], 3), ")\n")
}

# ======================================================================
# 7. SAVE RESULTS FOR TABLES
# ======================================================================
results <- list(
  ols1 = ols1, ols2 = ols2, ols3 = ols3,
  fs1 = fs1, fs2 = fs2, fs3 = fs3,
  rf1 = rf1, rf2 = rf2, rf3 = rf3,
  iv1 = iv1, iv2 = iv2, iv3 = iv3,
  iv_log = iv_log,
  desc_table = desc_table,
  n_obs = nrow(df),
  n_states = length(unique(df$state_fips))
)

if (exists("iv_se")) results$iv_se <- iv_se

saveRDS(results, file.path(DATA_DIR, "regression_results.rds"))

# ======================================================================
# 8. DIAGNOSTICS JSON
# ======================================================================
diag <- list(
  n_treated = sum(df$surface_share > 0.5, na.rm = TRUE),
  n_pre = 10,  # cross-sectional design, use number of pre-ACS years
  n_obs = nrow(df),
  n_states = length(unique(df$state_fips)),
  mean_surface_share = mean(df$surface_share, na.rm = TRUE),
  sd_surface_share = sd(df$surface_share, na.rm = TRUE),
  mean_conductance = mean(df$avg_conductance, na.rm = TRUE),
  sd_conductance = sd(df$avg_conductance, na.rm = TRUE),
  first_stage_F = (coef(fs3)["geo_surface_share"] / se(fs3)["geo_surface_share"])^2
)

jsonlite::write_json(diag, file.path(DATA_DIR, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)

cat("\n=== Main analysis complete ===\n")
cat("Results saved. Diagnostics written.\n")
