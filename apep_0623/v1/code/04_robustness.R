## 04_robustness.R — Robustness checks and mechanism tests
## APEP apep_0623: The Symmetric Tax Shock

source("00_packages.R")

data_dir <- "../data"

## ============================================================
## 1. Load data and main results
## ============================================================
cat("=== Loading data ===\n")
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
results_list <- readRDS(file.path(data_dir, "main_results.rds"))

# Re-create needed variables
panel[, tcja_only := as.integer(date >= as.Date("2018-01-01") & date < as.Date("2025-01-01"))]
panel[, obbb_on := as.integer(date >= as.Date("2025-01-01"))]
panel[, treat_tcja_sym := tcja_only * salt_exposure]
panel[, treat_obbb_sym := obbb_on * salt_exposure]
panel[, date := as.Date(date)]

tcja_panel <- panel[date < as.Date("2025-01-01")]

## ============================================================
## 2. Placebo test: Low-SALT zip codes (below $5K)
## ============================================================
cat("\n=== Placebo: Sub-$5K SALT zip codes ===\n")

placebo_panel <- tcja_panel[avg_salt < 5000]
placebo_panel[, treat_placebo := post_tcja * salt_exposure]

fit_placebo <- feols(log_zhvi ~ treat_placebo | zip_id + ym,
                      data = placebo_panel,
                      cluster = ~state_fips)

cat("  Placebo coefficient:", round(coef(fit_placebo)["treat_placebo"], 6), "\n")
cat("  SE:", round(se(fit_placebo)["treat_placebo"], 6), "\n")
cat("  p-value:", round(pvalue(fit_placebo)["treat_placebo"], 4), "\n")

## ============================================================
## 3. Pre-COVID subsample (2014-2019)
## ============================================================
cat("\n=== Pre-COVID subsample (2014-2019) ===\n")

precovid <- tcja_panel[date < as.Date("2020-03-01")]

fit_precovid <- feols(log_zhvi ~ treat_tcja | zip_id + ym,
                       data = precovid,
                       cluster = ~state_fips)

cat("  Pre-COVID coefficient:", round(coef(fit_precovid)["treat_tcja"], 6), "\n")
cat("  SE:", round(se(fit_precovid)["treat_tcja"], 6), "\n")

## ============================================================
## 4. Dose-response by SALT quintile
## ============================================================
cat("\n=== Dose-response by SALT quintile ===\n")

# Create quintile indicators interacted with post
for (q in paste0("Q", 2:5)) {
  tcja_panel[, paste0("post_", q) := as.integer(post_tcja == 1 & salt_quintile == q)]
}

fit_quintile <- feols(log_zhvi ~ post_Q2 + post_Q3 + post_Q4 + post_Q5 | zip_id + ym,
                       data = tcja_panel,
                       cluster = ~state_fips)

cat("Quintile effects (Q1 = lowest SALT = reference):\n")
print(coeftable(fit_quintile))

## ============================================================
## 5. Alternative clustering: county level
## ============================================================
cat("\n=== Alternative clustering ===\n")

# Cluster at zip level (conservative)
fit_zip_cluster <- feols(log_zhvi ~ treat_tcja | zip_id + ym,
                          data = tcja_panel,
                          cluster = ~zip5)

cat("  Zip-clustered SE:", round(se(fit_zip_cluster)["treat_tcja"], 6), "\n")
cat("  State-clustered SE (from main results):", round(results_list$tcja_1$se["treat_tcja"], 6), "\n")

## ============================================================
## 6. FHFA HPI robustness (if available)
## ============================================================
cat("\n=== FHFA HPI robustness ===\n")

fhfa_file <- file.path(data_dir, "fhfa_hpi_zip.xlsx")
if (file.exists(fhfa_file)) {
  tryCatch({
    fhfa <- readxl::read_excel(fhfa_file, skip = 6)
    fhfa <- as.data.table(fhfa)

    # Standardize column names
    if ("Five-Digit ZIP Code" %in% names(fhfa)) {
      setnames(fhfa, "Five-Digit ZIP Code", "zip5")
    } else if (ncol(fhfa) >= 3) {
      setnames(fhfa, 1:4, c("zip5", "year", "hpi", "hpi_1990"))
    }

    fhfa[, zip5 := sprintf("%05d", as.integer(zip5))]
    fhfa[, year := as.integer(year)]
    fhfa[, hpi := as.numeric(hpi)]

    # Merge with SALT data
    salt_data <- fread(file.path(data_dir, "salt_exposure.csv"))
    fhfa_panel <- merge(fhfa[year >= 2014 & year <= 2024],
                         salt_data[, .(zip5, salt_exposure, above_cap)],
                         by = "zip5")

    fhfa_panel[, post_tcja := as.integer(year >= 2018)]
    fhfa_panel[, treat_tcja := post_tcja * salt_exposure]
    fhfa_panel[, log_hpi := log(hpi)]
    fhfa_panel[, zip_id := as.integer(factor(zip5))]

    fit_fhfa <- feols(log_hpi ~ treat_tcja | zip_id + year,
                       data = fhfa_panel,
                       cluster = ~zip5)

    cat("  FHFA coefficient:", round(coef(fit_fhfa)["treat_tcja"], 6), "\n")
    cat("  SE:", round(se(fit_fhfa)["treat_tcja"], 6), "\n")
  }, error = function(e) {
    cat("  FHFA robustness skipped:", e$message, "\n")
    fit_fhfa <<- NULL
  })
} else {
  cat("  FHFA data not available (non-fatal)\n")
  fit_fhfa <- NULL
}

## ============================================================
## 7. Migration mechanism (IRS SOI outflows)
## ============================================================
cat("\n=== Migration mechanism ===\n")

migration_files <- list.files(data_dir, pattern = "stateoutflow", full.names = TRUE)
if (length(migration_files) > 0) {
  migration_list <- lapply(migration_files, function(f) {
    tryCatch({
      dt <- fread(f)
      # Extract year from filename
      yr_match <- regmatches(basename(f), regexpr("\\d{4}", basename(f)))
      if (length(yr_match) > 0) dt[, file_year := as.integer(yr_match)]
      dt
    }, error = function(e) NULL)
  })
  migration_list <- Filter(Negate(is.null), migration_list)

  if (length(migration_list) > 0) {
    migration <- rbindlist(migration_list, fill = TRUE)
    # Standardize column names
    old_n <- names(migration)
    setnames(migration, toupper(old_n))

    cat("  Migration data loaded:", nrow(migration), "rows\n")
    cat("  Columns:", paste(names(migration)[1:min(8, ncol(migration))], collapse = ", "), "\n")

    # High-SALT states for migration analysis
    high_salt_states <- c("NY", "NJ", "CT", "CA", "MA", "IL", "MD")

    # Check if state columns exist
    if ("Y1_STATE" %in% names(migration) || "Y1_STATEFIPS" %in% names(migration)) {
      cat("  Migration data has state identifiers — can analyze flows\n")
    }
  }
} else {
  cat("  Migration data not available\n")
}

## ============================================================
## 8. Save robustness results
## ============================================================
cat("\n=== Saving robustness results ===\n")

robust_results <- list(
  placebo = list(coef = coef(fit_placebo), se = se(fit_placebo), pval = pvalue(fit_placebo), nobs = fit_placebo$nobs),
  precovid = list(coef = coef(fit_precovid), se = se(fit_precovid), pval = pvalue(fit_precovid), nobs = fit_precovid$nobs),
  zip_cluster = list(coef = coef(fit_zip_cluster), se = se(fit_zip_cluster), pval = pvalue(fit_zip_cluster), nobs = fit_zip_cluster$nobs)
)
saveRDS(robust_results, file.path(data_dir, "robustness_results.rds"))

cat("Robustness analysis complete.\n")
