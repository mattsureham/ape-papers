## ============================================================================
## 04_robustness.R — Robustness checks for 340B RDD
## ============================================================================

source("00_packages.R")

DATA <- "../data"
RESULTS <- "../results"

analysis <- readRDS(file.path(DATA, "analysis_panel.rds"))
analysis_xs <- readRDS(file.path(DATA, "analysis_xs.rds"))

robustness <- list()

## ============================================================================
## 1. McCrary density test (manipulation)
## ============================================================================

cat("\n=== 1. McCrary Density Test ===\n")

density_test <- rddensity(X = analysis_xs$dsh_centered)
cat("McCrary density test at DSH = 11.75%:\n")
cat(sprintf("  T-statistic: %.3f\n", density_test$test$t_jk))
cat(sprintf("  P-value: %.3f\n", density_test$test$p_jk))

robustness$mccrary <- list(
  t_stat = density_test$test$t_jk,
  p_value = density_test$test$p_jk,
  verdict = ifelse(density_test$test$p_jk > 0.05, "PASS", "CONCERN")
)

## ============================================================================
## 2. Bandwidth sensitivity
## ============================================================================

cat("\n=== 2. Bandwidth Sensitivity ===\n")

bw_results <- list()
bandwidths <- c(2, 3, 4, 5, 7, 10)

for (bw in bandwidths) {
  sub <- analysis_xs[abs(dsh_centered) <= bw]
  if (sum(sub$dsh_centered < 0) >= 10 & sum(sub$dsh_centered >= 0) >= 10) {
    rd <- rdrobust(y = sub$asinh_mcaid_drug,
                    x = sub$dsh_centered,
                    kernel = "triangular", p = 1, h = bw)
    bw_results[[as.character(bw)]] <- list(
      bw = bw,
      coef = rd$coef[3],  # Bias-corrected
      se = rd$se[3],
      pval = rd$pv[3],
      n_left = rd$N_h[1],
      n_right = rd$N_h[2]
    )
    cat(sprintf("  BW=%dpp: coef=%.3f, se=%.3f, p=%.3f (N=%d/%d)\n",
                bw, rd$coef[3], rd$se[3], rd$pv[3], rd$N_h[1], rd$N_h[2]))
  }
}

robustness$bandwidth <- bw_results

## ============================================================================
## 3. Polynomial order sensitivity
## ============================================================================

cat("\n=== 3. Polynomial Order ===\n")

for (p_order in 1:2) {
  rd <- rdrobust(y = analysis_xs$asinh_mcaid_drug,
                  x = analysis_xs$dsh_centered,
                  kernel = "triangular", p = p_order, bwselect = "mserd")
  cat(sprintf("  Order %d: coef=%.3f, se=%.3f, p=%.3f, bw=%.1f\n",
              p_order, rd$coef[1], rd$se[3], rd$pv[3], rd$bws[1,1]))
}

## ============================================================================
## 4. Donut hole (exclude near-threshold)
## ============================================================================

cat("\n=== 4. Donut Hole ===\n")

donut_results <- list()
for (donut in c(0.25, 0.5, 1.0)) {
  sub <- analysis_xs[abs(dsh_centered) > donut]
  if (sum(sub$dsh_centered < 0) >= 20 & sum(sub$dsh_centered > 0) >= 20) {
    rd <- rdrobust(y = sub$asinh_mcaid_drug,
                    x = sub$dsh_centered,
                    kernel = "triangular", p = 1, bwselect = "mserd")
    donut_results[[as.character(donut)]] <- list(
      donut = donut,
      coef = rd$coef[3],  # Bias-corrected
      se = rd$se[3],
      pval = rd$pv[3]
    )
    cat(sprintf("  Donut=%.2fpp: coef=%.3f, se=%.3f, p=%.3f\n",
                donut, rd$coef[3], rd$se[3], rd$pv[3]))
  }
}

robustness$donut <- donut_results

## ============================================================================
## 5. Placebo cutoffs
## ============================================================================

cat("\n=== 5. Placebo Cutoffs ===\n")

placebo_cutoffs <- c(5, 8, 15, 20, 25, 35)
placebo_results <- list()

for (cutoff in placebo_cutoffs) {
  sub <- analysis_xs
  sub[, dsh_c_placebo := dsh_pct - cutoff]
  if (sum(sub$dsh_c_placebo < 0) >= 20 & sum(sub$dsh_c_placebo >= 0) >= 20) {
    rd <- tryCatch(
      rdrobust(y = sub$asinh_mcaid_drug,
               x = sub$dsh_c_placebo,
               kernel = "triangular", p = 1, bwselect = "mserd"),
      error = function(e) NULL
    )
    if (!is.null(rd)) {
      placebo_results[[as.character(cutoff)]] <- list(
        cutoff = cutoff,
        coef = rd$coef[3],  # Bias-corrected
        se = rd$se[3],
        pval = rd$pv[3]
      )
      cat(sprintf("  Cutoff=%.1f%%: coef=%.3f, se=%.3f, p=%.3f\n",
                  cutoff, rd$coef[3], rd$se[3], rd$pv[3]))
    }
  }
}

robustness$placebo_cutoffs <- placebo_results

## ============================================================================
## 6. Covariate balance (smoothness)
## ============================================================================

cat("\n=== 6. Covariate Balance ===\n")

# Test if covariates are smooth across threshold
covariates <- c("mcaid_nondrug_paid", "mcaid_hcbs_paid")
balance_results <- list()

for (cov in covariates) {
  sub <- analysis_xs[!is.na(get(cov))]
  rd <- tryCatch(
    rdrobust(y = sub[[cov]],
             x = sub$dsh_centered,
             kernel = "triangular", p = 1, bwselect = "mserd"),
    error = function(e) NULL
  )
  if (!is.null(rd)) {
    balance_results[[cov]] <- list(
      coef = rd$coef[3],  # Bias-corrected
      se = rd$se[3],
      pval = rd$pv[3]
    )
    cat(sprintf("  %s: coef=%.1f, p=%.3f\n", cov, rd$coef[3], rd$pv[3]))
  }
}

robustness$balance <- balance_results

## ============================================================================
## 7. Panel robustness: state FE, different bandwidths
## ============================================================================

cat("\n=== 7. Panel Specifications ===\n")

panel <- analysis[!is.na(dsh_centered)]
panel[, asinh_mcaid_drug := asinh(mcaid_drug_paid)]

# State + year FE
panel_state <- feols(asinh_mcaid_drug ~ treated * dsh_centered | state_abbr + fiscal_year,
                     data = panel[abs(dsh_centered) <= 10],
                     vcov = ~prvdr_num)
cat("\n  State + Year FE (±10pp):\n")
cat(sprintf("    treated: %.3f (%.3f), p=%.3f\n",
            coef(panel_state)["treated"],
            sqrt(vcov(panel_state)["treated","treated"]),
            fixest::pvalue(panel_state)["treated"]))

# Narrower bandwidth
panel_5pp <- feols(asinh_mcaid_drug ~ treated * dsh_centered | fiscal_year,
                   data = panel[abs(dsh_centered) <= 5],
                   vcov = ~prvdr_num)
cat("\n  Year FE (±5pp):\n")
cat(sprintf("    treated: %.3f (%.3f), p=%.3f\n",
            coef(panel_5pp)["treated"],
            sqrt(vcov(panel_5pp)["treated","treated"]),
            fixest::pvalue(panel_5pp)["treated"]))

# Medicare comparison (panel)
panel[, asinh_mcare_drug := asinh(mcare_drug_paid)]
panel_mcare <- feols(asinh_mcare_drug ~ treated * dsh_centered | fiscal_year,
                     data = panel[abs(dsh_centered) <= 10],
                     vcov = ~prvdr_num)
cat("\n  Medicare Drug (±10pp, year FE):\n")
cat(sprintf("    treated: %.3f (%.3f), p=%.3f\n",
            coef(panel_mcare)["treated"],
            sqrt(vcov(panel_mcare)["treated","treated"]),
            fixest::pvalue(panel_mcare)["treated"]))

## ============================================================================
## 8. Year-by-year estimates
## ============================================================================

cat("\n=== 8. Year-by-Year RDD ===\n")

yearly_results <- list()
analysis_years <- sort(unique(panel$fiscal_year))
analysis_years <- analysis_years[analysis_years <= 2023]  # HCRIS covers FY2019-2023 only
for (yr in analysis_years) {
  sub <- panel[fiscal_year == yr & abs(dsh_centered) <= 10]
  if (nrow(sub) > 50) {
    rd <- tryCatch(
      rdrobust(y = sub$asinh_mcaid_drug,
               x = sub$dsh_centered,
               kernel = "triangular", p = 1, bwselect = "mserd"),
      error = function(e) NULL
    )
    if (!is.null(rd)) {
      yearly_results[[as.character(yr)]] <- list(
        year = yr,
        coef = rd$coef[3],  # Bias-corrected
        se = rd$se[3],
        pval = rd$pv[3],
        n_eff = rd$N_h[1] + rd$N_h[2]
      )
      cat(sprintf("  %d: coef=%.3f (%.3f), p=%.3f, N_eff=%d\n",
                  yr, rd$coef[3], rd$se[3], rd$pv[3],
                  rd$N_h[1] + rd$N_h[2]))
    }
  }
}

robustness$yearly <- yearly_results

## ============================================================================
## 9. Save
## ============================================================================

saveRDS(robustness, file.path(RESULTS, "robustness.rds"))
cat("\n=== Robustness checks complete ===\n")
