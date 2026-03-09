## 04_robustness.R — Robustness checks and sensitivity analysis
## APEP-0548: Selective Licensing and Housing Markets in England

source("00_packages.R")

data_dir <- "../data"

la_qtr <- fread(file.path(data_dir, "la_quarter_panel.csv"))
la_qtr[, qtr_date := as.Date(qtr_date)]

la_annual <- fread(file.path(data_dir, "la_annual_panel.csv"))

## Load CS-DiD results if available
cs_result <- tryCatch(readRDS(file.path(data_dir, "cs_did_result.rds")),
                      error = function(e) NULL)
cs_es <- tryCatch(readRDS(file.path(data_dir, "cs_did_es_result.rds")),
                  error = function(e) NULL)

## Treatment indicator for annual panel
la_annual[, treated := as.integer(treated_ever & year >= cohort & cohort > 0)]
la_annual[is.na(treated), treated := 0L]

## ===================================================================
## 1. SUN & ABRAHAM (2021) INTERACTION-WEIGHTED ESTIMATOR
## ===================================================================
cat("--- Sun & Abraham IW Estimator ---\n")

## sunab needs: cohort variable (Inf or large number for never-treated)
sa_data <- copy(la_annual)
sa_data[cohort == 0 | treated_ever == FALSE, cohort_sa := 10000L]
sa_data[cohort > 0 & treated_ever == TRUE, cohort_sa := as.integer(cohort)]

sa_model <- tryCatch({
  feols(mean_log_price ~ sunab(cohort_sa, year, ref.p = -1) |
          la_id + year,
        data = sa_data,
        cluster = ~la_id)
}, error = function(e) {
  cat("Sun-Abraham failed:", e$message, "\n")
  NULL
})

if (!is.null(sa_model)) {
  cat("Sun-Abraham event study:\n")
  print(summary(sa_model))

  ## Extract event-study coefficients
  sa_coefs <- as.data.table(coeftable(sa_model), keep.rownames = TRUE)
  setnames(sa_coefs, c("term", "estimate", "se", "tstat", "pval"))

  ## Parse relative time from coefficient names
  sa_coefs[, rel_year := as.integer(gsub(".*::", "", term))]
  sa_coefs <- sa_coefs[!is.na(rel_year)]

  fwrite(sa_coefs[, .(rel_year, att = estimate, se, ci_lower = estimate - 1.96 * se,
                       ci_upper = estimate + 1.96 * se)],
         file.path(data_dir, "sun_abraham_event_study.csv"))
  cat("Saved Sun-Abraham event study coefficients.\n")
}

## ===================================================================
## 2. GOODMAN-BACON DECOMPOSITION
## ===================================================================
cat("\n--- Goodman-Bacon Decomposition ---\n")

if (requireNamespace("bacondecomp", quietly = TRUE)) {
  library(bacondecomp)

  ## Prepare balanced annual panel for bacon decomposition
  gb_data <- copy(la_annual)
  gb_data <- gb_data[!is.na(mean_log_price)]

  gb_result <- tryCatch({
    bacon(mean_log_price ~ treated,
          data = as.data.frame(gb_data),
          id_var = "la_id",
          time_var = "year")
  }, error = function(e) {
    cat("Bacon decomposition failed:", e$message, "\n")
    NULL
  })

  if (!is.null(gb_result)) {
    cat("Goodman-Bacon decomposition:\n")
    print(gb_result)
    fwrite(as.data.table(gb_result), file.path(data_dir, "bacon_decomposition.csv"))
  }
} else {
  cat("bacondecomp not installed. Installing...\n")
  install.packages("bacondecomp", repos = "https://cloud.r-project.org")
  library(bacondecomp)

  gb_data <- copy(la_annual)
  gb_data <- gb_data[!is.na(mean_log_price)]

  gb_result <- tryCatch({
    bacon(mean_log_price ~ treated,
          data = as.data.frame(gb_data),
          id_var = "la_id",
          time_var = "year")
  }, error = function(e) {
    cat("Bacon decomposition failed:", e$message, "\n")
    NULL
  })

  if (!is.null(gb_result)) {
    cat("Goodman-Bacon decomposition:\n")
    print(gb_result)
    fwrite(as.data.table(gb_result), file.path(data_dir, "bacon_decomposition.csv"))
  }
}

## ===================================================================
## 3. PLACEBO BY PROPERTY TYPE
## ===================================================================
cat("\n--- Placebo: By Property Type ---\n")

## Build LA-year panel by property type from quarter panel
## la_qtr already has pct_detached, pct_flat, pct_terraced — but we need
## separate models by type. Use the LA-annual panel with composition as proxy,
## or build from raw LR data.

## Try reading transaction-level parquet
lr <- tryCatch({
  dt <- arrow::read_parquet(file.path(data_dir, "lr_transactions_treated.parquet"))
  setDT(dt)
  dt
}, error = function(e) {
  cat("Parquet read failed:", e$message, "\n")
  NULL
})

if (!is.null(lr) && "ptype" %in% names(lr)) {
  ## Build LA-year-ptype panel
  lr[, log_price := log(price)]
  la_yr_ptype <- lr[year >= 2008 & year <= 2024, .(
    mean_log_price = mean(log_price, na.rm = TRUE),
    n_transactions = .N
  ), by = .(la_name, year, ptype, treated)]

  ## Merge la_id
  la_yr_ptype <- merge(la_yr_ptype,
                       unique(la_annual[, .(la_name, la_id)]),
                       by = "la_name", all.x = TRUE)

  placebo_results <- data.table()
  for (pt in c("D", "S", "T", "F")) {
    pt_label <- c(D = "Detached", S = "Semi-detached",
                  T = "Terraced", F = "Flat")[pt]

    pt_model <- tryCatch({
      feols(mean_log_price ~ treated | la_id + year,
            data = la_yr_ptype[ptype == pt],
            cluster = ~la_id)
    }, error = function(e) NULL)

    if (!is.null(pt_model)) {
      pt_pval <- coeftable(pt_model)["treated", "Pr(>|t|)"]
      cat(sprintf("  %s: coef = %.4f (SE = %.4f, p = %.4f, N = %d)\n",
                  pt_label, coef(pt_model)["treated"], se(pt_model)["treated"],
                  pt_pval, nobs(pt_model)))
      placebo_results <- rbind(placebo_results, data.table(
        property_type = pt,
        label = pt_label,
        coef = coef(pt_model)["treated"],
        se = se(pt_model)["treated"],
        pval = pt_pval,
        n = nobs(pt_model)
      ))
    }
  }
  fwrite(placebo_results, file.path(data_dir, "placebo_property_type.csv"))

  rm(lr)
  gc()
} else {
  cat("Transaction-level data not available for property-type placebo.\n")
  cat("Using LA-level proxies based on composition...\n")

  ## Alternative: Use LA-annual with pct_flat as proxy for PRS exposure
  ## High-flat LAs vs low-flat LAs as soft placebo
  flat_med <- median(la_annual$pct_flat, na.rm = TRUE)
  high_flat <- feols(mean_log_price ~ treated | la_id + year,
                     data = la_annual[pct_flat > flat_med], cluster = ~la_id)
  low_flat <- feols(mean_log_price ~ treated | la_id + year,
                    data = la_annual[pct_flat <= flat_med], cluster = ~la_id)

  placebo_results <- data.table(
    property_type = c("high_flat", "low_flat"),
    label = c("High-Flat LAs", "Low-Flat LAs"),
    coef = c(coef(high_flat)["treated"], coef(low_flat)["treated"]),
    se = c(se(high_flat)["treated"], se(low_flat)["treated"]),
    pval = c(coeftable(high_flat)["treated", "Pr(>|t|)"],
             coeftable(low_flat)["treated", "Pr(>|t|)"]),
    n = c(nobs(high_flat), nobs(low_flat))
  )
  fwrite(placebo_results, file.path(data_dir, "placebo_property_type.csv"))
}

## ===================================================================
## 4. LEAVE-ONE-OUT SENSITIVITY
## ===================================================================
cat("\n--- Leave-One-Out ---\n")

## Add treated variable to la_qtr
la_qtr[, treated_twfe := as.integer(treated_ever & qtr_date >= as.Date(licensing_start))]
la_qtr[is.na(treated_twfe), treated_twfe := 0L]

treated_las <- unique(la_qtr[treated_ever == TRUE]$la_name)
loo_results <- list()

for (i in seq_along(treated_las)) {
  drop_la <- treated_las[i]
  loo_model <- tryCatch({
    feols(mean_log_price ~ treated_twfe | la_name + year,
          data = la_qtr[la_name != drop_la],
          cluster = ~la_name)
  }, error = function(e) NULL)

  if (!is.null(loo_model)) {
    loo_results[[i]] <- data.table(
      dropped_la = drop_la,
      coef = coef(loo_model)["treated_twfe"],
      se = se(loo_model)["treated_twfe"]
    )
  }
}

if (length(loo_results) > 0) {
  loo_dt <- rbindlist(loo_results)
  cat("Leave-one-out range: [", round(min(loo_dt$coef), 4), ", ",
      round(max(loo_dt$coef), 4), "]\n")

  ## Full-sample
  full_model <- feols(mean_log_price ~ treated_twfe | la_name + year,
                      data = la_qtr, cluster = ~la_name)
  cat("Full-sample TWFE coef: ", round(coef(full_model)["treated_twfe"], 4), "\n")
  fwrite(loo_dt, file.path(data_dir, "leave_one_out.csv"))
}

## ===================================================================
## 5. RANDOMIZATION INFERENCE
## ===================================================================
cat("\n--- Randomization Inference ---\n")

## Permute treatment assignment across LAs
n_perms <- 500
set.seed(20260309)

## Get actual treated LA names and their treatment patterns
actual_treated <- unique(la_annual[treated_ever == TRUE]$la_name)
n_treated <- length(actual_treated)
all_las <- unique(la_annual$la_name)

## Actual effect
actual_model <- feols(mean_log_price ~ treated | la_id + year,
                      data = la_annual, cluster = ~la_id)
actual_coef <- coef(actual_model)["treated"]

ri_coefs <- numeric(n_perms)
for (p in seq_len(n_perms)) {
  ## Randomly permute which LAs get treatment
  ## Preserve the timing structure: shuffle LA labels
  perm_la_labels <- sample(all_las, n_treated)

  la_perm <- copy(la_annual)
  la_perm[, perm_treated := 0L]

  ## Assign original treatment pattern to random LAs
  for (j in seq_len(n_treated)) {
    orig_la <- actual_treated[j]
    perm_la <- perm_la_labels[j]
    orig_pattern <- la_annual[la_name == orig_la, .(year, treated)]
    la_perm[la_name == perm_la,
            perm_treated := orig_pattern$treated[match(year, orig_pattern$year)]]
  }
  la_perm[is.na(perm_treated), perm_treated := 0L]

  perm_model <- tryCatch({
    feols(mean_log_price ~ perm_treated | la_id + year,
          data = la_perm, cluster = ~la_id)
  }, error = function(e) NULL)

  if (!is.null(perm_model)) {
    ri_coefs[p] <- coef(perm_model)["perm_treated"]
  }

  if (p %% 100 == 0) cat("  Permutation", p, "/", n_perms, "\n")
}

ri_pval <- mean(abs(ri_coefs) >= abs(actual_coef), na.rm = TRUE)
cat("RI p-value (two-sided): ", round(ri_pval, 4), "\n")
cat("Actual coefficient: ", round(actual_coef, 4), "\n")
cat("RI distribution: mean = ", round(mean(ri_coefs, na.rm = TRUE), 4),
    ", sd = ", round(sd(ri_coefs, na.rm = TRUE), 4), "\n")

fwrite(data.table(ri_coefs = ri_coefs),
       file.path(data_dir, "ri_permutation_coefs.csv"))
fwrite(data.table(actual_coef = actual_coef, ri_pval = ri_pval,
                  ri_mean = mean(ri_coefs, na.rm = TRUE),
                  ri_sd = sd(ri_coefs, na.rm = TRUE)),
       file.path(data_dir, "ri_summary.csv"))

## ===================================================================
## 6. HONESTDID SENSITIVITY BOUNDS
## ===================================================================
cat("\n--- HonestDiD Sensitivity ---\n")

if (!is.null(cs_es) && requireNamespace("HonestDiD", quietly = TRUE)) {
  tryCatch({
    ## Apply HonestDiD to CS-DiD event study
    honest_result <- HonestDiD::honest_did(cs_es,
                                            type = "relative_magnitude",
                                            Mbarvec = seq(0, 2, by = 0.5))
    cat("HonestDiD sensitivity bounds:\n")
    print(honest_result)

    ## Save
    saveRDS(honest_result, file.path(data_dir, "honestdid_result.rds"))
  }, error = function(e) {
    cat("HonestDiD failed:", e$message, "\n")
  })
} else {
  cat("CS-DiD event study result or HonestDiD not available.\n")
}

## ===================================================================
## 7. ALTERNATIVE TIME WINDOWS
## ===================================================================
cat("\n--- Alternative Time Windows ---\n")

window_results <- list()
for (window in c(3, 5, 8)) {
  la_qtr_window <- la_qtr[treated_ever == TRUE &
                            abs(as.numeric(difftime(qtr_date, as.Date(licensing_start),
                                                     units = "days")) / 365.25) <= window]
  la_qtr_window <- rbind(la_qtr_window, la_qtr[treated_ever == FALSE])
  la_qtr_window[, treated_w := as.integer(treated_ever &
                                            qtr_date >= as.Date(licensing_start))]
  la_qtr_window[is.na(treated_w), treated_w := 0L]

  window_model <- tryCatch({
    feols(mean_log_price ~ treated_w | la_name + year,
          data = la_qtr_window, cluster = ~la_name)
  }, error = function(e) NULL)

  if (!is.null(window_model)) {
    w_coef <- coef(window_model)["treated_w"]
    w_se <- se(window_model)["treated_w"]
    w_pval <- coeftable(window_model)["treated_w", "Pr(>|t|)"]
    cat(sprintf("  Window ±%d years: coef = %.4f (SE = %.4f, p = %.4f, N = %d)\n",
                window, w_coef, w_se, w_pval, nobs(window_model)))
    window_results[[as.character(window)]] <- data.table(
      window = window, coef = w_coef, se = w_se, pval = w_pval,
      n = nobs(window_model)
    )
  }
}
if (length(window_results) > 0) {
  fwrite(rbindlist(window_results), file.path(data_dir, "window_results.csv"))
}

cat("\n=== Robustness Analysis Complete ===\n")
cat("Ready for 05_figures.R\n")
