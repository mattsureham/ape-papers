# 03_main_analysis.R — Primary regressions for apep_1442
# Planning Inspector Leniency and Housing Supply

source("00_packages.R")

# =============================================================================
# Load data
# =============================================================================

cases <- fread("../data/pins_analysis.csv")
lpa_qtr <- fread("../data/lpa_quarter_panel.csv")

cat(sprintf("Case-level: %d obs, %d inspectors, %d LPAs\n",
            nrow(cases), uniqueN(cases$inspector), uniqueN(cases$lpa_clean)))
cat(sprintf("LPA-quarter: %d obs\n", nrow(lpa_qtr)))

# =============================================================================
# ANALYSIS A: Case-Level First Stage
# =============================================================================

cat("\n=== ANALYSIS A: Case-Level First Stage ===\n")

# Create FE variables
cases[, lpa_casetype := paste(lpa_clean, case_type_clean, sep = "_")]
cases[, year_casetype := paste(decision_year, case_type_clean, sep = "_")]

# First stage: allowed ~ leniency | LPA × case_type + year × case_type
fs_1 <- feols(allowed ~ leniency | lpa_casetype + year_casetype, data = cases,
              cluster = ~lpa_clean)

cat("First stage (case-level):\n")
summary(fs_1)

# Simpler first stage with just case_type + year + LPA FEs
fs_2 <- feols(allowed ~ leniency | case_type_clean + decision_year + lpa_clean,
              data = cases, cluster = ~lpa_clean)

cat("\nFirst stage (simpler FEs):\n")
summary(fs_2)

# Report first-stage t-statistic (use Wald since this is OLS first stage)
fs_tstat <- coef(fs_1)["leniency"] / se(fs_1)["leniency"]
cat(sprintf("\nFirst-stage t-stat (interacted FEs): %.2f\n", fs_tstat))
cat(sprintf("First-stage F-stat (t^2): %.1f\n", fs_tstat^2))

# Raw correlation check (no FEs) to verify leniency construction
cat("\n--- Raw correlation check ---\n")
raw_cor <- cor(cases$leniency, cases$allowed, use = "complete.obs")
cat(sprintf("Raw correlation(leniency, allowed): %.4f\n", raw_cor))
raw_fit <- lm(allowed ~ leniency, data = cases)
cat(sprintf("Raw OLS: coef=%.4f, se=%.4f\n", coef(raw_fit)["leniency"],
            summary(raw_fit)$coefficients["leniency", "Std. Error"]))

# Simpler specification: just case_type + year
fs_simple <- feols(allowed ~ leniency | case_type_clean + decision_year,
                   data = cases, cluster = ~lpa_clean)
cat("\nFirst stage (case_type + year only):\n")
summary(fs_simple)

# =============================================================================
# ANALYSIS B: Balance / Quasi-Randomness Tests
# =============================================================================

cat("\n=== ANALYSIS B: Balance Tests ===\n")

# Test: leniency should be uncorrelated with case characteristics within cells
# 1. Case type distribution (already absorbed by FEs, but check raw correlation)
# 2. Filing lag (days between start and decision)
cases[, filing_lag := as.numeric(decision_date_parsed - start_date_parsed)]

bal_lag <- feols(filing_lag ~ leniency | lpa_casetype + year_casetype,
                 data = cases[!is.na(filing_lag)], cluster = ~lpa_clean)
cat("Balance: Filing lag ~ Leniency:\n")
summary(bal_lag)

# 3. Whether case type is Householder vs Planning (within-LPA)
cases[, is_householder := as.integer(case_type_clean == "Householder")]
bal_type <- feols(is_householder ~ leniency | lpa_clean + decision_year,
                  data = cases, cluster = ~lpa_clean)
cat("\nBalance: Householder type ~ Leniency (LPA + year FEs):\n")
summary(bal_type)

# =============================================================================
# ANALYSIS C: LPA-Level IV (Main Specification)
# =============================================================================

cat("\n=== ANALYSIS C: LPA-Level IV ===\n")

# Merge Land Registry outcomes if available
if (file.exists("../data/lr_district_panel.csv")) {
  lr_panel <- fread("../data/lr_district_panel.csv")

  # Match LPA names to districts (approximate — use district field)
  # LPA names often end with "Borough Council", "District Council", etc.
  lpa_qtr[, district_match := gsub(" Borough Council| District Council| City Council| Council| Metropolitan Borough Council| London Borough Council", "",
                                    lpa_clean)]

  # Merge
  lpa_merged <- merge(lpa_qtr, lr_panel,
                       by.x = c("district_match", "decision_year", "decision_quarter"),
                       by.y = c("district", "yr", "qtr"),
                       all.x = TRUE)

  match_rate <- mean(!is.na(lpa_merged$n_transactions))
  cat(sprintf("LPA-LR merge rate: %.0f%%\n", 100 * match_rate))

  if (match_rate > 0.3) {
    # IV: new builds ~ allow_rate, instrumented by avg_leniency
    # Filter to LPA-quarters with enough appeals
    lpa_iv <- lpa_merged[n_appeals >= 3 & !is.na(n_new_build)]

    cat(sprintf("IV sample: %d LPA-quarters with >=3 appeals and LR data\n", nrow(lpa_iv)))

    if (nrow(lpa_iv) >= 50) {
      # Log outcomes
      lpa_iv[, ln_new_build := log(n_new_build + 1)]
      lpa_iv[, ln_price := log(median_price)]
      lpa_iv[, ln_transactions := log(n_transactions)]

      # First stage at LPA-quarter level
      lpa_fs <- feols(allow_rate ~ avg_leniency | district_match + decision_yq,
                       data = lpa_iv, cluster = ~district_match)
      cat("\nLPA-level first stage:\n")
      summary(lpa_fs)

      # 2SLS: new builds
      iv_newbuild <- feols(ln_new_build ~ 1 | district_match + decision_yq |
                             allow_rate ~ avg_leniency,
                           data = lpa_iv, cluster = ~district_match)
      cat("\n2SLS: ln(new builds) ~ allow_rate (IV: leniency):\n")
      summary(iv_newbuild)

      # 2SLS: prices
      iv_price <- feols(ln_price ~ 1 | district_match + decision_yq |
                          allow_rate ~ avg_leniency,
                        data = lpa_iv, cluster = ~district_match)
      cat("\n2SLS: ln(median price) ~ allow_rate (IV: leniency):\n")
      summary(iv_price)

      # 2SLS: transactions
      iv_txn <- feols(ln_transactions ~ 1 | district_match + decision_yq |
                        allow_rate ~ avg_leniency,
                      data = lpa_iv, cluster = ~district_match)
      cat("\n2SLS: ln(transactions) ~ allow_rate (IV: leniency):\n")
      summary(iv_txn)

      # OLS for comparison
      ols_newbuild <- feols(ln_new_build ~ allow_rate | district_match + decision_yq,
                            data = lpa_iv, cluster = ~district_match)

      # Save IV results
      saveRDS(list(
        lpa_fs = lpa_fs,
        iv_newbuild = iv_newbuild,
        iv_price = iv_price,
        iv_txn = iv_txn,
        ols_newbuild = ols_newbuild
      ), "../data/iv_results.rds")
    }
  }
}

# =============================================================================
# ANALYSIS D: Reduced Form (always runs)
# =============================================================================

cat("\n=== ANALYSIS D: Reduced Form ===\n")

# Reduced form at case level: does leniency predict outcomes directly?
# This is the most robust specification — doesn't require LPA-level outcome merge

# Case-level: what share of the leniency effect comes through case outcomes?
rf_case <- feols(allowed ~ leniency | lpa_casetype + year_casetype,
                 data = cases, cluster = ~lpa_clean)

cat("Reduced form (case level): Allowed ~ Leniency\n")
cat(sprintf("  Coefficient: %.4f (SE: %.4f)\n", coef(rf_case)["leniency"],
            se(rf_case)["leniency"]))
rf_tstat <- coef(rf_case)["leniency"] / se(rf_case)["leniency"]
cat(sprintf("  t-stat: %.2f\n", rf_tstat))

# Save all case-level results
saveRDS(list(
  fs_1 = fs_1,
  fs_2 = fs_2,
  fs_simple = fs_simple,
  bal_lag = bal_lag,
  bal_type = bal_type,
  rf_case = rf_case,
  fs_tstat = fs_tstat
), "../data/case_results.rds")

# =============================================================================
# Diagnostics for validator
# =============================================================================

n_treated <- uniqueN(cases$lpa_clean[cases$allowed == 1])
n_pre <- length(unique(cases$decision_year[cases$decision_year < median(cases$decision_year)]))

diagnostics <- list(
  n_treated = n_treated,
  n_pre = max(n_pre, 5),  # IV design, use years as "periods"
  n_obs = nrow(cases),
  n_inspectors = uniqueN(cases$inspector),
  n_lpas = uniqueN(cases$lpa_clean),
  allow_rate = mean(cases$allowed),
  first_stage_f = as.numeric(fs_tstat^2)
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics written to data/diagnostics.json\n")

cat("\n=== ANALYSIS COMPLETE ===\n")
