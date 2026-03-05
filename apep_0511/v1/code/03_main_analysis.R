## ============================================================================
## 03_main_analysis.R — RDD estimation at DSH = 11.75% threshold
## ============================================================================

source("00_packages.R")

DATA <- "../data"
RESULTS <- "../results"
dir.create(RESULTS, showWarnings = FALSE, recursive = TRUE)

## ============================================================================
## 1. Load analysis data
## ============================================================================

cat("\n=== Loading analysis data ===\n")
analysis <- readRDS(file.path(DATA, "analysis_panel.rds"))
analysis_xs <- readRDS(file.path(DATA, "analysis_xs.rds"))

cat(sprintf("Panel: %d hospital-years\n", nrow(analysis)))
cat(sprintf("Cross-section: %d hospitals\n", nrow(analysis_xs)))

## ============================================================================
## 2. Primary RDD: Medicaid drug billing (cross-sectional)
## ============================================================================

cat("\n=== PRIMARY RDD: Medicaid Drug Billing ===\n")

# Outcome: asinh(Medicaid drug spending)
# Running variable: DSH% centered at 11.75
rdd_sample <- analysis_xs[!is.na(dsh_centered) & is.finite(asinh_mcaid_drug)]

cat(sprintf("RDD sample: %d hospitals\n", nrow(rdd_sample)))

# Main specification: local linear, triangular kernel, CCT bandwidth
rdd_mcaid <- rdrobust(y = rdd_sample$asinh_mcaid_drug,
                       x = rdd_sample$dsh_centered,
                       kernel = "triangular",
                       p = 1,
                       bwselect = "mserd")

cat("\n--- Medicaid Drug Spending (asinh) ---\n")
summary(rdd_mcaid)

# Store results
main_results <- list()
main_results$mcaid_drug <- list(
  coef = rdd_mcaid$coef[3],  # Bias-corrected estimate (matches robust p-value)
  se = rdd_mcaid$se[3],      # Robust SE
  pval = rdd_mcaid$pv[3],
  ci_lower = rdd_mcaid$ci[3, 1],
  ci_upper = rdd_mcaid$ci[3, 2],
  bw = rdd_mcaid$bws[1, 1],
  n_left = rdd_mcaid$N_h[1],
  n_right = rdd_mcaid$N_h[2]
)

## ============================================================================
## 3. Medicare drug billing (comparison)
## ============================================================================

cat("\n=== COMPARISON: Medicare Drug Billing ===\n")

rdd_mcare <- rdrobust(y = rdd_sample$asinh_mcare_drug,
                       x = rdd_sample$dsh_centered,
                       kernel = "triangular",
                       p = 1,
                       bwselect = "mserd")

cat("\n--- Medicare Drug Spending (asinh, zip-level) ---\n")
summary(rdd_mcare)

main_results$mcare_drug <- list(
  coef = rdd_mcare$coef[3],  # Bias-corrected
  se = rdd_mcare$se[3],
  pval = rdd_mcare$pv[3],
  ci_lower = rdd_mcare$ci[3, 1],
  ci_upper = rdd_mcare$ci[3, 2],
  bw = rdd_mcare$bws[1, 1],
  n_left = rdd_mcare$N_h[1],
  n_right = rdd_mcare$N_h[2]
)

## ============================================================================
## 4. Cross-payer ratio
## ============================================================================

cat("\n=== CROSS-PAYER: Medicaid Drug Share ===\n")

rdd_ratio <- rdd_sample[!is.na(mcaid_drug_share)]
if (nrow(rdd_ratio) > 50) {
  rdd_share <- rdrobust(y = rdd_ratio$mcaid_drug_share,
                         x = rdd_ratio$dsh_centered,
                         kernel = "triangular",
                         p = 1,
                         bwselect = "mserd")

  cat("\n--- Medicaid Drug Share ---\n")
  summary(rdd_share)

  main_results$drug_share <- list(
    coef = rdd_share$coef[3],  # Bias-corrected
    se = rdd_share$se[3],
    pval = rdd_share$pv[3],
    ci_lower = rdd_share$ci[3, 1],
    ci_upper = rdd_share$ci[3, 2],
    bw = rdd_share$bws[1, 1],
    n_left = rdd_share$N_h[1],
    n_right = rdd_share$N_h[2]
  )
}

## ============================================================================
## 5. Placebo outcomes
## ============================================================================

cat("\n=== PLACEBO: Non-Drug Medicaid Billing ===\n")

rdd_sample[, asinh_mcaid_nondrug := asinh(mcaid_nondrug_paid)]

rdd_nondrug <- rdrobust(y = rdd_sample$asinh_mcaid_nondrug,
                         x = rdd_sample$dsh_centered,
                         kernel = "triangular",
                         p = 1,
                         bwselect = "mserd")

cat("\n--- Non-Drug Medicaid Spending (asinh) ---\n")
summary(rdd_nondrug)

main_results$placebo_nondrug <- list(
  coef = rdd_nondrug$coef[3],  # Bias-corrected
  se = rdd_nondrug$se[3],
  pval = rdd_nondrug$pv[3],
  bw = rdd_nondrug$bws[1, 1],
  n_left = rdd_nondrug$N_h[1],
  n_right = rdd_nondrug$N_h[2]
)

## ============================================================================
## 6. Extensive margin: probability of any Medicaid drug billing
## ============================================================================

cat("\n=== EXTENSIVE MARGIN: Any Medicaid Drug Billing ===\n")

rdd_extensive <- rdrobust(y = rdd_sample$has_mcaid_drugs,
                           x = rdd_sample$dsh_centered,
                           kernel = "triangular",
                           p = 1,
                           bwselect = "mserd")

cat("\n--- Pr(Any Medicaid Drug Billing) ---\n")
summary(rdd_extensive)

main_results$extensive_margin <- list(
  coef = rdd_extensive$coef[3],  # Bias-corrected
  se = rdd_extensive$se[3],
  pval = rdd_extensive$pv[3],
  bw = rdd_extensive$bws[1, 1],
  n_left = rdd_extensive$N_h[1],
  n_right = rdd_extensive$N_h[2]
)

## ============================================================================
## 7. Log-level specification
## ============================================================================

cat("\n=== LOG SPECIFICATION ===\n")

# Conditional on positive billing
pos_sample <- rdd_sample[mcaid_drug_paid > 0]
cat(sprintf("Positive Medicaid drug billing: %d hospitals\n", nrow(pos_sample)))

if (nrow(pos_sample) > 100) {
  rdd_log <- rdrobust(y = pos_sample$log_mcaid_drug,
                       x = pos_sample$dsh_centered,
                       kernel = "triangular",
                       p = 1,
                       bwselect = "mserd")

  cat("\n--- Log Medicaid Drug Spending (conditional on >0) ---\n")
  summary(rdd_log)

  main_results$log_mcaid_cond <- list(
    coef = rdd_log$coef[3],  # Bias-corrected
    se = rdd_log$se[3],
    pval = rdd_log$pv[3],
    bw = rdd_log$bws[1, 1],
    n_left = rdd_log$N_h[1],
    n_right = rdd_log$N_h[2]
  )
}

## ============================================================================
## 8. Panel specification with year FE
## ============================================================================

cat("\n=== PANEL SPECIFICATION ===\n")

panel <- analysis[!is.na(dsh_centered)]
panel[, asinh_mcaid_drug := asinh(mcaid_drug_paid)]

# RDD with year fixed effects using fixest
panel_rdd <- feols(asinh_mcaid_drug ~ treated * dsh_centered | fiscal_year,
                   data = panel[abs(dsh_centered) <= 10],
                   vcov = ~prvdr_num)

cat("\n--- Panel RDD (±10pp, year FE, clustered) ---\n")
summary(panel_rdd)

main_results$panel_rdd <- list(
  coef = coef(panel_rdd)["treated"],
  se = sqrt(vcov(panel_rdd)["treated", "treated"]),
  pval = fixest::pvalue(panel_rdd)["treated"],
  n = nobs(panel_rdd),
  n_clusters = length(unique(panel[abs(dsh_centered) <= 10]$prvdr_num))
)

## ============================================================================
## 9. Summary of all results
## ============================================================================

cat("\n=== RESULTS SUMMARY ===\n")

cat(sprintf("\n%-30s %10s %10s %10s %10s\n",
            "Outcome", "Coef", "SE", "p-val", "BW"))
cat(paste(rep("-", 75), collapse = ""), "\n")

for (nm in names(main_results)) {
  r <- main_results[[nm]]
  cat(sprintf("%-30s %10.3f %10.3f %10.3f %10.1f\n",
              nm,
              r$coef,
              r$se,
              r$pval,
              if (!is.null(r$bw)) r$bw else NA))
}

## ============================================================================
## 10. Save results
## ============================================================================

saveRDS(main_results, file.path(RESULTS, "main_results.rds"))
cat("\n=== Main analysis complete ===\n")
