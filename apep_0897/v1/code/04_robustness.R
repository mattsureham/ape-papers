## 04_robustness.R — Robustness checks and placebo tests
## apep_0897: The Carboniferous Lottery

source("00_packages.R")

DATA_DIR <- "../data"
TABLE_DIR <- "../tables"

df <- readRDS(file.path(DATA_DIR, "analysis_full.rds"))
df$log_conductance <- log(df$avg_conductance)

placebo <- tryCatch(readRDS(file.path(DATA_DIR, "placebo_counties.rds")),
                    error = function(e) NULL)

cat("Analysis sample:", nrow(df), "counties\n")
if (!is.null(placebo)) cat("Placebo sample:", nrow(placebo), "counties\n")

# ======================================================================
# 1. BALANCE TABLE — Instrument vs. Covariates
# ======================================================================
cat("\n=== Balance Test: Geo Surface Share vs Covariates ===\n")

# Split counties at median geological surface share
df$high_geo_surface <- df$geo_surface_share > median(df$geo_surface_share)

balance_vars <- c("log_pop", "log_income", "pct_poverty", "pct_black",
                   "median_age", "log_production")

balance_results <- list()
for (v in balance_vars) {
  if (v %in% names(df)) {
    bal <- feols(as.formula(paste(v, "~ geo_surface_share")),
                 data = df, vcov = "HC1")
    balance_results[[v]] <- data.frame(
      variable = v,
      coef = coef(bal)["geo_surface_share"],
      se = se(bal)["geo_surface_share"],
      pval = pvalue(bal)["geo_surface_share"]
    )
    cat(sprintf("  %-20s β=%7.3f (SE=%6.3f) p=%5.3f\n",
                v, coef(bal)["geo_surface_share"],
                se(bal)["geo_surface_share"],
                pvalue(bal)["geo_surface_share"]))
  }
}
balance_df <- bind_rows(balance_results)

# ======================================================================
# 2. PLACEBO OUTCOME — Geological instrument should NOT predict
#    water quality in non-coal counties
# ======================================================================
cat("\n=== Placebo: Non-Coal Counties ===\n")

if (!is.null(placebo) && nrow(placebo) >= 10) {
  # For non-coal counties, there's no surface mining to affect outcomes
  # So geological features should not predict water quality
  # We test if being near coal counties (proxy for similar geology)
  # predicts conductance
  placebo_test <- placebo %>%
    mutate(
      log_pop = log(total_pop),
      log_income = log(median_income),
      state_fips = substr(fips, 1, 2)
    ) %>%
    filter(!is.na(avg_conductance), !is.na(log_pop), !is.na(log_income))

  if (nrow(placebo_test) >= 10) {
    # Simple test: conductance in non-coal counties vs coal counties
    cat("  Non-coal counties conductance: mean =",
        round(mean(placebo_test$avg_conductance, na.rm = TRUE), 1), "\n")
    cat("  Coal counties conductance: mean =",
        round(mean(df$avg_conductance, na.rm = TRUE), 1), "\n")
    cat("  Difference:", round(mean(df$avg_conductance, na.rm = TRUE) -
                                 mean(placebo_test$avg_conductance, na.rm = TRUE), 1),
        "μS/cm\n")
  }
} else {
  cat("  Insufficient non-coal counties for placebo\n")
}

# ======================================================================
# 3. ALTERNATIVE SPECIFICATIONS
# ======================================================================
cat("\n=== Alternative Specifications ===\n")

# Baseline is controls WITHOUT state FE (F=34, strong first stage)
# 3a. Drop largest producers (outlier check)
q90_prod <- quantile(df$total_production, 0.90)
df_trim <- df %>% filter(total_production <= q90_prod)

iv_trim <- feols(avg_conductance ~ log_production + log_pop + log_income +
                   pct_poverty + pct_black + median_age |
                   surface_share ~ geo_surface_share,
                 data = df_trim, vcov = "HC1")

cat("  Drop top 10% producers (N =", nrow(df_trim), "):\n")
cat("    β_IV =", round(coef(iv_trim)["fit_surface_share"], 2),
    " (SE =", round(se(iv_trim)["fit_surface_share"], 2), ")\n")

# 3b. Log-log specification
iv_loglog <- feols(log_conductance ~ log_production + log_pop + log_income +
                     pct_poverty + pct_black + median_age |
                     surface_share ~ geo_surface_share,
                   data = df, vcov = "HC1")

cat("  Log-log specification:\n")
cat("    β_IV =", round(coef(iv_loglog)["fit_surface_share"], 3),
    " (SE =", round(se(iv_loglog)["fit_surface_share"], 3), ")\n")

# 3c. With state FE (absorbs much cross-state geological variation)
iv_state_fe <- feols(avg_conductance ~ log_production + log_pop + log_income +
                     pct_poverty + pct_black + median_age |
                     state_fips |
                     surface_share ~ geo_surface_share,
                   data = df, vcov = "HC1")

cat("  With state FE:\n")
cat("    β_IV =", round(coef(iv_state_fe)["fit_surface_share"], 2),
    " (SE =", round(se(iv_state_fe)["fit_surface_share"], 2), ")\n")

# 3d. No controls at all
iv_no_fe <- feols(avg_conductance ~ 1 |
                    surface_share ~ geo_surface_share,
                  data = df, vcov = "HC1")

cat("  Without state FE:\n")
cat("    β_IV =", round(coef(iv_no_fe)["fit_surface_share"], 2),
    " (SE =", round(se(iv_no_fe)["fit_surface_share"], 2), ")\n")

# 3e. Anderson-Rubin weak-IV robust confidence interval
cat("\n=== Anderson-Rubin Test ===\n")
# Manual AR test: regress Y - β*X on Z for grid of β values
# Check where F-test does not reject
ar_grid <- seq(-500, 1500, by = 10)
ar_pvals <- sapply(ar_grid, function(b) {
  df$y_tilde <- df$avg_conductance - b * df$surface_share
  m <- feols(y_tilde ~ geo_surface_share + log_production + log_pop +
               log_income + pct_poverty + pct_black + median_age,
             data = df, vcov = "HC1")
  pvalue(m)["geo_surface_share"]
})

ar_ci <- ar_grid[ar_pvals > 0.05]
if (length(ar_ci) > 0) {
  cat("  AR 95% CI: [", min(ar_ci), ",", max(ar_ci), "]\n")
} else {
  cat("  AR 95% CI: empty set (all rejected)\n")
}

# ======================================================================
# 4. LEAVE-ONE-STATE-OUT
# ======================================================================
cat("\n=== Leave-One-State-Out ===\n")

states <- unique(df$state_fips)
loo_results <- list()

for (st in states) {
  df_loo <- df %>% filter(state_fips != st)
  if (nrow(df_loo) >= 20) {
    iv_loo <- tryCatch({
      feols(avg_conductance ~ log_production + log_pop + log_income +
              pct_poverty + pct_black + median_age |
              state_fips |
              surface_share ~ geo_surface_share,
            data = df_loo, vcov = "HC1")
    }, error = function(e) NULL)

    if (!is.null(iv_loo)) {
      loo_results[[st]] <- data.frame(
        dropped_state = st,
        coef = coef(iv_loo)["fit_surface_share"],
        se = se(iv_loo)["fit_surface_share"],
        n = nrow(df_loo)
      )
      cat(sprintf("  Drop %s: β_IV = %7.2f (SE = %6.2f, N = %d)\n",
                  st, coef(iv_loo)["fit_surface_share"],
                  se(iv_loo)["fit_surface_share"], nrow(df_loo)))
    }
  }
}

loo_df <- bind_rows(loo_results)

# ======================================================================
# 5. SAVE ROBUSTNESS RESULTS
# ======================================================================
rob_results <- list(
  balance = balance_df,
  iv_trim = iv_trim,
  iv_loglog = iv_loglog,
  iv_state_fe = iv_state_fe,
  iv_no_fe = iv_no_fe,
  ar_ci = if (length(ar_ci) > 0) c(min(ar_ci), max(ar_ci)) else NULL,
  loo = loo_df
)

saveRDS(rob_results, file.path(DATA_DIR, "robustness_results.rds"))

cat("\n=== Robustness checks complete ===\n")
