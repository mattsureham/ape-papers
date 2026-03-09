## 03_main_analysis.R — Primary regressions
## APEP-0548: Selective Licensing and Housing Markets in England

source("00_packages.R")

data_dir <- "../data"

## ===================================================================
## 1. LOAD PANELS
## ===================================================================
cat("Loading analysis panels...\n")

la_qtr <- fread(file.path(data_dir, "la_quarter_panel.csv"))
la_qtr[, qtr_date := as.Date(qtr_date)]

la_annual <- fread(file.path(data_dir, "la_annual_panel.csv"))

cat("LA-quarter panel: ", nrow(la_qtr), " obs, ",
    n_distinct(la_qtr$la_name), " LAs\n")
cat("LA-annual panel: ", nrow(la_annual), " obs, ",
    n_distinct(la_annual$la_name), " LAs\n")

## ===================================================================
## 2. SUMMARY STATISTICS
## ===================================================================
cat("\nComputing summary statistics...\n")

## Full sample summary
full_stats <- la_annual[, .(
  Variable = c("Mean log price", "SD log price", "Median price (GBP)",
                "Transactions/year", "Pct detached", "Pct flat",
                "Pct terraced", "Pct new build"),
  Mean = c(mean(mean_log_price, na.rm = TRUE),
           mean(sd_log_price, na.rm = TRUE),
           mean(median_price, na.rm = TRUE),
           mean(n_transactions, na.rm = TRUE),
           mean(pct_detached, na.rm = TRUE),
           mean(pct_flat, na.rm = TRUE),
           mean(pct_terraced, na.rm = TRUE),
           mean(pct_new, na.rm = TRUE)),
  SD = c(sd(mean_log_price, na.rm = TRUE),
         sd(sd_log_price, na.rm = TRUE),
         sd(median_price, na.rm = TRUE),
         sd(n_transactions, na.rm = TRUE),
         sd(pct_detached, na.rm = TRUE),
         sd(pct_flat, na.rm = TRUE),
         sd(pct_terraced, na.rm = TRUE),
         sd(pct_new, na.rm = TRUE))
)]
fwrite(full_stats, file.path(data_dir, "summary_statistics.csv"))

## By treatment status (pre-treatment only)
for (grp in c(TRUE, FALSE)) {
  pre <- la_annual[treated_ever == grp & (cohort == 0 | year < cohort)]
  label <- if (grp) "Ever-treated" else "Never-treated"
  cat(sprintf("  %s: mean log price = %.3f, median price = %.0f, N = %d LAs\n",
              label, mean(pre$mean_log_price, na.rm = TRUE),
              mean(pre$median_price, na.rm = TRUE),
              n_distinct(pre$la_name)))
}

## ===================================================================
## 3. TWFE BASELINE
## ===================================================================
cat("\n--- TWFE Baseline ---\n")

## Treatment indicator for annual panel
la_annual[, treated := as.integer(treated_ever & year >= cohort & cohort > 0)]
la_annual[is.na(treated), treated := 0L]

twfe_base <- feols(mean_log_price ~ treated | la_name + year,
                   data = la_annual, cluster = ~la_name)
cat("TWFE baseline:\n")
print(summary(twfe_base))

## TWFE with controls
twfe_ctrl <- feols(mean_log_price ~ treated + pct_detached + pct_flat +
                     pct_new + log(n_transactions + 1) | la_name + year,
                   data = la_annual, cluster = ~la_name)
cat("\nTWFE with controls:\n")
print(summary(twfe_ctrl))

twfe_pval1 <- coeftable(twfe_base)["treated", "Pr(>|t|)"]
twfe_pval2 <- coeftable(twfe_ctrl)["treated", "Pr(>|t|)"]
fwrite(data.table(
  model = c("TWFE baseline", "TWFE + controls"),
  coef = c(coef(twfe_base)["treated"], coef(twfe_ctrl)["treated"]),
  se = c(se(twfe_base)["treated"], se(twfe_ctrl)["treated"]),
  pval = c(twfe_pval1, twfe_pval2),
  n = c(nobs(twfe_base), nobs(twfe_ctrl))
), file.path(data_dir, "twfe_results.csv"))

## ===================================================================
## 4. CALLAWAY-SANT'ANNA STAGGERED DiD
## ===================================================================
cat("\n--- Callaway-Sant'Anna DiD ---\n")

## CS-DiD needs: gname (cohort year, 0 for never-treated)
cs_data <- copy(la_annual)
cs_data[treated_ever == FALSE | cohort == 0, cohort := 0L]

## Drop rows with missing outcome
cs_data <- cs_data[!is.na(mean_log_price)]

cat("CS-DiD data: ", nrow(cs_data), " obs, ",
    n_distinct(cs_data$la_name), " LAs\n")
cat("Cohorts: ", paste(sort(unique(cs_data$cohort[cs_data$cohort > 0])),
                        collapse = ", "), "\n")
cat("Never-treated LAs: ", n_distinct(cs_data[cohort == 0]$la_name), "\n")

cs_result <- tryCatch({
  att_gt(yname = "mean_log_price",
         tname = "year",
         idname = "la_id",
         gname = "cohort",
         data = as.data.frame(cs_data),
         control_group = "notyettreated",
         anticipation = 0,
         est_method = "dr",
         base_period = "universal")
}, error = function(e) {
  cat("CS-DiD (not-yet-treated) failed:", e$message, "\n")
  cat("Trying with never-treated control...\n")
  tryCatch({
    att_gt(yname = "mean_log_price",
           tname = "year",
           idname = "la_id",
           gname = "cohort",
           data = as.data.frame(cs_data),
           control_group = "nevertreated",
           anticipation = 0,
           est_method = "dr",
           base_period = "universal")
  }, error = function(e2) {
    cat("CS-DiD (never-treated) also failed:", e2$message, "\n")
    NULL
  })
})

if (!is.null(cs_result)) {
  ## Overall ATT
  cs_agg <- aggte(cs_result, type = "simple")
  cat("\nOverall ATT:\n")
  print(summary(cs_agg))

  ## Event study
  cs_es <- tryCatch(
    aggte(cs_result, type = "dynamic", min_e = -5, max_e = 8),
    error = function(e) {
      cat("Event study aggregation failed:", e$message, "\n")
      aggte(cs_result, type = "dynamic")
    }
  )
  cat("\nEvent-study ATTs:\n")
  print(summary(cs_es))

  ## Save overall ATT
  fwrite(data.table(
    estimator = "CS-DiD",
    att = cs_agg$overall.att,
    se = cs_agg$overall.se,
    ci_lower = cs_agg$overall.att - 1.96 * cs_agg$overall.se,
    ci_upper = cs_agg$overall.att + 1.96 * cs_agg$overall.se
  ), file.path(data_dir, "cs_did_overall_att.csv"))

  ## Save event study
  es_dt <- data.table(
    rel_year = cs_es$egt,
    att = cs_es$att.egt,
    se = cs_es$se.egt,
    ci_lower = cs_es$att.egt - 1.96 * cs_es$se.egt,
    ci_upper = cs_es$att.egt + 1.96 * cs_es$se.egt
  )
  fwrite(es_dt, file.path(data_dir, "cs_did_event_study.csv"))

  ## Pre-trend joint test
  pre_coefs <- es_dt[rel_year < 0 & !is.na(att)]
  if (nrow(pre_coefs) > 1) {
    wald_stat <- sum((pre_coefs$att / pre_coefs$se)^2)
    wald_df <- nrow(pre_coefs)
    wald_pval <- 1 - pchisq(wald_stat, df = wald_df)
    cat("\nPre-trend joint test:\n")
    cat("  Wald stat = ", round(wald_stat, 3),
        ", df = ", wald_df,
        ", p = ", round(wald_pval, 4), "\n")
    cat("  ", ifelse(wald_pval > 0.05,
                     "PASS: Cannot reject parallel trends",
                     "WARNING: Pre-trends detected"), "\n")

    fwrite(data.table(wald_stat, wald_df, wald_pval),
           file.path(data_dir, "pretrend_test.csv"))
  }

  saveRDS(cs_result, file.path(data_dir, "cs_did_result.rds"))
  saveRDS(cs_es, file.path(data_dir, "cs_did_es_result.rds"))
}

## ===================================================================
## 5. TRANSACTION-LEVEL HEDONIC MODEL
## ===================================================================
cat("\n--- Transaction-Level Hedonic Model ---\n")

## Read the parquet in chunks if needed
lr <- tryCatch({
  arrow::read_parquet(file.path(data_dir, "lr_transactions_treated.parquet"))
}, error = function(e) {
  cat("Large parquet read failed. Reconstructing from LA panel data.\n")
  ## Reconstruct from CSV
  tryCatch(fread(file.path(data_dir, "la_quarter_panel.csv")),
           error = function(e2) NULL)
})

if (!is.null(lr) && "price" %in% names(lr)) {
  setDT(lr)
  lr_analysis <- lr[year >= 2008 & year <= 2024]

  ## Sample for computational feasibility
  if (nrow(lr_analysis) > 3e6) {
    set.seed(20260309)
    lr_analysis <- lr_analysis[sample(.N, 3e6)]
    cat("Sampled to 3M transactions\n")
  }

  lr_analysis[, log_price := log(price)]
  lr_analysis[, year_qtr := paste0(year, "Q", quarter(date))]

  hedonic <- feols(log_price ~ treated + i(ptype, ref = "T") +
                     i(oldnew, ref = "N") + i(duration, ref = "F") |
                     la_name + year_qtr,
                   data = lr_analysis, cluster = ~la_name)
  cat("Hedonic model:\n")
  print(summary(hedonic))

  hedonic_pval <- coeftable(hedonic)["treated", "Pr(>|t|)"]
  fwrite(data.table(
    model = "Hedonic",
    coef = coef(hedonic)["treated"],
    se = se(hedonic)["treated"],
    pval = hedonic_pval,
    n = nobs(hedonic)
  ), file.path(data_dir, "hedonic_results.csv"))

  rm(lr, lr_analysis)
  gc()
} else {
  cat("Transaction-level data not available. Using LA-level results only.\n")
  ## Write placeholder hedonic result based on TWFE
  fwrite(data.table(
    model = "Hedonic",
    coef = NA_real_, se = NA_real_, pval = NA_real_, n = NA_integer_
  ), file.path(data_dir, "hedonic_results.csv"))
}

## ===================================================================
## 6. PRS DOSE-RESPONSE
## ===================================================================
cat("\n--- PRS Dose-Response ---\n")

if ("prs_share" %in% names(la_annual) &&
    sum(!is.na(la_annual$prs_share)) > 100) {

  prs_med <- median(la_annual$prs_share, na.rm = TRUE)
  la_annual[, high_prs := as.integer(prs_share > prs_med)]

  ## Continuous dose
  dose_cont <- feols(mean_log_price ~ treated * prs_share | la_name + year,
                     data = la_annual, cluster = ~la_name)
  cat("Dose-response (continuous):\n")
  print(summary(dose_cont))

  ## High vs low PRS
  high_model <- feols(mean_log_price ~ treated | la_name + year,
                      data = la_annual[high_prs == 1], cluster = ~la_name)
  low_model <- feols(mean_log_price ~ treated | la_name + year,
                     data = la_annual[high_prs == 0], cluster = ~la_name)

  cat("\nHigh-PRS LAs:\n"); print(summary(high_model))
  cat("\nLow-PRS LAs:\n"); print(summary(low_model))

  fwrite(data.table(
    model = c("Continuous dose", "High-PRS", "Low-PRS"),
    coef_treated = c(coef(dose_cont)["treated"],
                     coef(high_model)["treated"],
                     coef(low_model)["treated"]),
    se_treated = c(se(dose_cont)["treated"],
                   se(high_model)["treated"],
                   se(low_model)["treated"])
  ), file.path(data_dir, "dose_response_results.csv"))
} else {
  cat("PRS share not available. Skipping.\n")
}

cat("\n=== Main Analysis Complete ===\n")
