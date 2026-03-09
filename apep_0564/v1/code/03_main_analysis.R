## =============================================================================
## 03_main_analysis.R — IV Estimation: Judge Leniency → Labor Markets
## Paper: The Economic Integration Lottery
## =============================================================================

source("00_packages.R")

data_dir <- "../data/"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))

cat("Panel loaded:", nrow(panel), "observations,",
    n_distinct(panel$court_city), "courts,",
    n_distinct(panel$year), "years\n")

# Drop missing instrument observations
panel <- panel[!is.na(avg_judge_leniency) & !is.na(court_grant_rate)]
cat("After dropping missing IV:", nrow(panel), "observations\n")

# NOTE: The instrument (avg_judge_leniency) is cross-sectional — it does NOT
# vary within courts over time. Therefore we CANNOT include court FE (it would
# absorb the instrument). We use state FE to control for regional confounders
# while preserving cross-court variation in judge composition.

## ---------------------------------------------------------------------------
## A. First Stage: Judge Leniency → Court Grant Rate
## ---------------------------------------------------------------------------

cat("\n=== FIRST STAGE ===\n")

# Cross-sectional first stage (court is the unit)
court_cross <- panel[, .(
  court_grant_rate = mean(court_grant_rate),
  avg_judge_leniency = mean(avg_judge_leniency),
  loo_leniency = mean(loo_leniency, na.rm = TRUE),
  n_judges = mean(n_judges),
  state_fips = first(state_fips),
  region = first(region),
  total_pop = mean(total_pop, na.rm = TRUE),
  noncitizen_share = mean(noncitizen_share, na.rm = TRUE),
  unemployment_rate = mean(unemployment_rate, na.rm = TRUE),
  foreign_born_share = mean(foreign_born_share, na.rm = TRUE),
  poverty_rate = mean(poverty_rate, na.rm = TRUE)
), by = court_city]

cat("Cross-sectional units (courts):", nrow(court_cross), "\n")

# First stage: no FE
fs0 <- feols(court_grant_rate ~ avg_judge_leniency, data = court_cross)
cat("\nFirst stage (no FE):\n")
cat(sprintf("  β = %.4f (SE = %.4f), R² = %.3f\n",
            coef(fs0)["avg_judge_leniency"], se(fs0)["avg_judge_leniency"],
            r2(fs0, "r2")))

# First stage: region FE
fs1 <- feols(court_grant_rate ~ avg_judge_leniency | region, data = court_cross)
cat("\nFirst stage (region FE):\n")
cat(sprintf("  β = %.4f (SE = %.4f)\n",
            coef(fs1)["avg_judge_leniency"], se(fs1)["avg_judge_leniency"]))

# First stage: state FE (if enough variation)
n_states <- n_distinct(court_cross$state_fips)
if (n_states >= 5) {
  fs_state <- tryCatch({
    feols(court_grant_rate ~ avg_judge_leniency | state_fips, data = court_cross)
  }, error = function(e) NULL)

  if (!is.null(fs_state)) {
    cat("\nFirst stage (state FE):\n")
    cat(sprintf("  β = %.4f (SE = %.4f)\n",
                coef(fs_state)["avg_judge_leniency"],
                se(fs_state)["avg_judge_leniency"]))
  }
}

# Panel first stage with year FE
fs_panel <- feols(court_grant_rate ~ avg_judge_leniency | year, data = panel,
                  cluster = ~court_city)
cat("\nFirst stage (panel, year FE, court-clustered):\n")
cat(sprintf("  β = %.4f (SE = %.4f), F = %.1f\n",
            coef(fs_panel)["avg_judge_leniency"],
            se(fs_panel)["avg_judge_leniency"],
            (coef(fs_panel)["avg_judge_leniency"] / se(fs_panel)["avg_judge_leniency"])^2))

# Save first stage results
fs_results <- data.table(
  spec = c("No FE", "Region FE", "Year FE (panel)"),
  coef = c(coef(fs0)["avg_judge_leniency"],
           coef(fs1)["avg_judge_leniency"],
           coef(fs_panel)["avg_judge_leniency"]),
  se = c(se(fs0)["avg_judge_leniency"],
         se(fs1)["avg_judge_leniency"],
         se(fs_panel)["avg_judge_leniency"]),
  n_obs = c(nobs(fs0), nobs(fs1), nobs(fs_panel))
)
fs_results[, f_stat := (coef / se)^2]
fwrite(fs_results, file.path(data_dir, "first_stage_results.csv"))

## ---------------------------------------------------------------------------
## B. Reduced Form: Judge Leniency → Outcomes
## ---------------------------------------------------------------------------

cat("\n=== REDUCED FORM ===\n")

outcomes <- c("log_total", "log_wage_total", "log_est_total",
              "log_accom_food", "log_admin_svc",
              "log_finance", "log_professional",
              "noncitizen_share")

outcome_labels <- c("Log Total Employment", "Log Weekly Wage", "Log Establishments",
                     "Log Accommodation Emp", "Log Admin Services Emp",
                     "Log Finance Emp (Placebo)", "Log Professional Emp (Placebo)",
                     "Noncitizen Share")

rf_results <- list()
for (i in seq_along(outcomes)) {
  y <- outcomes[i]
  if (!y %in% names(panel) || all(is.na(panel[[y]]))) {
    cat("  Skipping", y, "(missing)\n")
    next
  }

  # Reduced form with year FE, clustered at court
  rf <- feols(as.formula(paste(y, "~ avg_judge_leniency | year")),
              data = panel, cluster = ~court_city)

  rf_results[[y]] <- data.table(
    outcome = outcome_labels[i],
    outcome_var = y,
    coef = coef(rf)["avg_judge_leniency"],
    se = se(rf)["avg_judge_leniency"],
    pval = fixest::pvalue(rf)["avg_judge_leniency"],
    n_obs = nobs(rf),
    n_courts = n_distinct(panel[!is.na(get(y)), court_city])
  )

  cat(sprintf("  %-35s β=%.4f (SE=%.4f) p=%.3f N=%d\n",
              outcome_labels[i], coef(rf)["avg_judge_leniency"],
              se(rf)["avg_judge_leniency"], fixest::pvalue(rf)["avg_judge_leniency"],
              nobs(rf)))
}

rf_dt <- rbindlist(rf_results)
fwrite(rf_dt, file.path(data_dir, "reduced_form_results.csv"))

## ---------------------------------------------------------------------------
## C. IV Estimation: 2SLS
## ---------------------------------------------------------------------------

cat("\n=== IV ESTIMATION (2SLS) ===\n")

iv_results <- list()
for (i in seq_along(outcomes)) {
  y <- outcomes[i]
  if (!y %in% names(panel) || all(is.na(panel[[y]]))) next

  # 2SLS: Y ~ 1 | year | court_grant_rate ~ avg_judge_leniency
  iv <- tryCatch({
    feols(as.formula(paste(y, "~ 1 | year | court_grant_rate ~ avg_judge_leniency")),
          data = panel, cluster = ~court_city)
  }, error = function(e) {
    cat("  IV failed for", y, ":", e$message, "\n")
    NULL
  })

  if (!is.null(iv)) {
    iv_results[[y]] <- data.table(
      outcome = outcome_labels[i],
      outcome_var = y,
      coef_iv = coef(iv)["fit_court_grant_rate"],
      se_iv = se(iv)["fit_court_grant_rate"],
      pval_iv = fixest::pvalue(iv)["fit_court_grant_rate"],
      n_obs = nobs(iv)
    )

    cat(sprintf("  %-35s β_IV=%.4f (SE=%.4f) p=%.3f N=%d\n",
                outcome_labels[i], coef(iv)["fit_court_grant_rate"],
                se(iv)["fit_court_grant_rate"], fixest::pvalue(iv)["fit_court_grant_rate"],
                nobs(iv)))
  }
}

iv_dt <- rbindlist(iv_results)
fwrite(iv_dt, file.path(data_dir, "iv_results.csv"))

## ---------------------------------------------------------------------------
## D. IV with Controls
## ---------------------------------------------------------------------------

cat("\n=== IV WITH CONTROLS ===\n")

iv_ctrl_results <- list()
for (i in seq_along(outcomes)) {
  y <- outcomes[i]
  if (!y %in% names(panel) || all(is.na(panel[[y]]))) next

  iv_ctrl <- tryCatch({
    feols(as.formula(paste(y, "~ total_pop + unemployment_rate + poverty_rate | year | court_grant_rate ~ avg_judge_leniency")),
          data = panel, cluster = ~court_city)
  }, error = function(e) NULL)

  if (!is.null(iv_ctrl)) {
    iv_ctrl_results[[y]] <- data.table(
      outcome = outcome_labels[i],
      outcome_var = y,
      coef_iv = coef(iv_ctrl)["fit_court_grant_rate"],
      se_iv = se(iv_ctrl)["fit_court_grant_rate"],
      pval_iv = fixest::pvalue(iv_ctrl)["fit_court_grant_rate"],
      n_obs = nobs(iv_ctrl)
    )

    cat(sprintf("  %-35s β_IV=%.4f (SE=%.4f) p=%.3f\n",
                outcome_labels[i], coef(iv_ctrl)["fit_court_grant_rate"],
                se(iv_ctrl)["fit_court_grant_rate"], fixest::pvalue(iv_ctrl)["fit_court_grant_rate"]))
  }
}

iv_ctrl_dt <- rbindlist(iv_ctrl_results)
fwrite(iv_ctrl_dt, file.path(data_dir, "iv_controls_results.csv"))

## ---------------------------------------------------------------------------
## E. OLS Comparison
## ---------------------------------------------------------------------------

cat("\n=== OLS COMPARISON ===\n")

ols_results <- list()
for (i in seq_along(outcomes)) {
  y <- outcomes[i]
  if (!y %in% names(panel) || all(is.na(panel[[y]]))) next

  ols <- feols(as.formula(paste(y, "~ court_grant_rate | year")),
               data = panel, cluster = ~court_city)

  ols_results[[y]] <- data.table(
    outcome = outcome_labels[i],
    outcome_var = y,
    coef_ols = coef(ols)["court_grant_rate"],
    se_ols = se(ols)["court_grant_rate"],
    pval_ols = fixest::pvalue(ols)["court_grant_rate"],
    n_obs = nobs(ols)
  )

  cat(sprintf("  %-35s β_OLS=%.4f (SE=%.4f) p=%.3f\n",
              outcome_labels[i], coef(ols)["court_grant_rate"],
              se(ols)["court_grant_rate"], fixest::pvalue(ols)["court_grant_rate"]))
}

ols_dt <- rbindlist(ols_results)
fwrite(ols_dt, file.path(data_dir, "ols_results.csv"))

## ---------------------------------------------------------------------------
## F. Balance Test: Judge Leniency vs Pre-determined Characteristics
## ---------------------------------------------------------------------------

cat("\n=== BALANCE TEST ===\n")

# Judge leniency should not predict pre-existing county characteristics
balance_vars <- c("total_pop", "foreign_born_share", "poverty_rate", "unemployment_rate")
balance_labels <- c("Total Population", "Foreign Born Share", "Poverty Rate", "Unemployment Rate")

balance_results <- list()
for (i in seq_along(balance_vars)) {
  bv <- balance_vars[i]
  if (!bv %in% names(court_cross)) next

  vals <- court_cross[[bv]]
  if (all(is.na(vals))) next

  bal_reg <- feols(as.formula(paste(bv, "~ avg_judge_leniency")),
                   data = court_cross[!is.na(get(bv))])

  balance_results[[bv]] <- data.table(
    variable = balance_labels[i],
    coef = coef(bal_reg)["avg_judge_leniency"],
    se = se(bal_reg)["avg_judge_leniency"],
    pval = fixest::pvalue(bal_reg)["avg_judge_leniency"]
  )

  cat(sprintf("  %-25s β=%.4f (SE=%.4f) p=%.3f %s\n",
              balance_labels[i], coef(bal_reg)["avg_judge_leniency"],
              se(bal_reg)["avg_judge_leniency"], fixest::pvalue(bal_reg)["avg_judge_leniency"],
              ifelse(fixest::pvalue(bal_reg)["avg_judge_leniency"] > 0.1, "PASS", "WARN")))
}

balance_dt <- rbindlist(balance_results)
fwrite(balance_dt, file.path(data_dir, "balance_test_results.csv"))

## ---------------------------------------------------------------------------
## G. Summary Statistics Table
## ---------------------------------------------------------------------------

cat("\n=== SUMMARY STATISTICS ===\n")

# Generate comprehensive summary statistics
summ_vars <- c("court_grant_rate", "avg_judge_leniency", "n_judges",
               "emp_total", "emp_accom_food", "emp_admin_svc",
               "emp_finance", "emp_professional",
               "estabs_total", "wage_total",
               "noncitizen_share", "foreign_born_share",
               "total_pop", "poverty_rate", "unemployment_rate")

summ_labels <- c("Asylum Grant Rate", "Avg Judge Leniency",
                  "Number of Judges per Court",
                  "Total Employment", "Accommodation & Food Employment",
                  "Admin Services Employment",
                  "Finance Employment", "Professional Services Employment",
                  "Total Establishments", "Average Weekly Wage ($)",
                  "Noncitizen Population Share", "Foreign-Born Share",
                  "Total Population", "Poverty Rate", "Unemployment Rate")

summ_results <- list()
for (i in seq_along(summ_vars)) {
  v <- summ_vars[i]
  if (!v %in% names(panel)) next
  vals <- panel[[v]]
  vals <- vals[!is.na(vals)]
  if (length(vals) == 0) next

  summ_results[[v]] <- data.table(
    variable = summ_labels[i],
    mean = mean(vals),
    sd = sd(vals),
    p25 = quantile(vals, 0.25),
    median = median(vals),
    p75 = quantile(vals, 0.75),
    n = length(vals)
  )
}

summ_dt <- rbindlist(summ_results)
fwrite(summ_dt, file.path(data_dir, "summary_statistics.csv"))
cat("Summary statistics saved.\n")
print(summ_dt[, .(variable, mean = round(mean, 4), sd = round(sd, 4), n)])

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
