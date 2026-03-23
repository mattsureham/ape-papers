## 03_main_analysis.R — Main RDD analysis
## apep_0796: Swiss Second Home Ban RDD

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

rdd <- readRDS(file.path(data_dir, "rdd_cross_section.rds"))
panel <- readRDS(file.path(data_dir, "zwg_panel_analysis.rds"))

cat("Cross-section:", nrow(rdd), "municipalities\n")
cat("Panel:", nrow(panel), "obs\n")

## ================================================================
## 1. McCrary Density Test
## ================================================================
cat("\n=== McCrary Density Test ===\n")

density_test <- rddensity::rddensity(rdd$running_var, c = 0)
cat("T-statistic:", round(density_test$test$t_jk, 3), "\n")
cat("P-value:", round(density_test$test$p_jk, 4), "\n")

# Save density test results
density_results <- list(
  t_stat = density_test$test$t_jk,
  p_value = density_test$test$p_jk,
  n_left = density_test$N$eff_left,
  n_right = density_test$N$eff_right
)

## ================================================================
## 2. Main RDD: Change in Primary Home Share
## ================================================================
cat("\n=== Main RDD: Delta Primary Home Share ===\n")

# CCT-optimal bandwidth
rd_main <- rdrobust::rdrobust(
  y = rdd$delta_primary,
  x = rdd$running_var,
  c = 0,
  kernel = "triangular",
  p = 1,  # local linear
  bwselect = "mserd"
)

cat("\nMain RDD results:\n")
summary(rd_main)

# Store key results
main_coef <- rd_main$coef[1]  # conventional
main_se <- rd_main$se[3]      # robust
main_pval <- rd_main$pv[3]    # robust p-value
main_bw <- rd_main$bws[1, 1]  # bandwidth
main_n_eff <- rd_main$N_h[1] + rd_main$N_h[2]  # effective sample

cat("\nKey results:\n")
cat("  Coefficient:", round(main_coef, 3), "pp\n")
cat("  Robust SE:", round(main_se, 3), "\n")
cat("  Robust p-value:", round(main_pval, 4), "\n")
cat("  Optimal bandwidth:", round(main_bw, 2), "pp\n")
cat("  Effective N:", main_n_eff, "\n")

## ================================================================
## 3. RDD on Secondary Home Share Change (mirror image)
## ================================================================
cat("\n=== RDD: Delta Secondary Home Share ===\n")

rd_secondary <- rdrobust::rdrobust(
  y = rdd$delta_secondary,
  x = rdd$running_var,
  c = 0,
  kernel = "triangular",
  p = 1,
  bwselect = "mserd"
)
summary(rd_secondary)

## ================================================================
## 4. RDD on Total Dwelling Growth
## ================================================================
cat("\n=== RDD: Total Dwelling Growth (%) ===\n")

rd_growth <- rdrobust::rdrobust(
  y = rdd$pct_change_total,
  x = rdd$running_var,
  c = 0,
  kernel = "triangular",
  p = 1,
  bwselect = "mserd"
)
summary(rd_growth)

## ================================================================
## 5. Covariate Balance Tests
## ================================================================
cat("\n=== Covariate Balance at Cutoff ===\n")

covariates <- list(
  "Baseline Total Dwellings" = rdd$baseline_total,
  "Alpine Canton" = rdd$alpine,
  "German-speaking" = rdd$lang_german
)

if (any(!is.na(rdd$population_2020))) {
  covariates[["Population (2020)"]] <- rdd$population_2020
}

balance_results <- data.frame(
  Variable = character(),
  Coef = numeric(),
  SE = numeric(),
  Pval = numeric(),
  stringsAsFactors = FALSE
)

for (vname in names(covariates)) {
  y_cov <- covariates[[vname]]
  valid <- !is.na(y_cov) & !is.na(rdd$running_var)
  if (sum(valid) < 50) {
    cat("  Skipping", vname, "- too few obs\n")
    next
  }

  rd_cov <- tryCatch(
    rdrobust::rdrobust(y = y_cov[valid], x = rdd$running_var[valid], c = 0,
                       kernel = "triangular", p = 1, bwselect = "mserd"),
    error = function(e) NULL
  )

  if (!is.null(rd_cov)) {
    balance_results <- rbind(balance_results, data.frame(
      Variable = vname,
      Coef = rd_cov$coef[1],
      SE = rd_cov$se[3],
      Pval = rd_cov$pv[3],
      stringsAsFactors = FALSE
    ))
    cat("  ", vname, ": coef =", round(rd_cov$coef[1], 3),
        ", p =", round(rd_cov$pv[3], 3), "\n")
  }
}

## ================================================================
## 6. Panel RDD: Dynamic Effects by Wave
## ================================================================
cat("\n=== Dynamic Panel RDD ===\n")

dynamic_results <- data.frame(
  wave = character(),
  wave_year = numeric(),
  coef = numeric(),
  se_robust = numeric(),
  pval = numeric(),
  bw = numeric(),
  n_eff = numeric(),
  stringsAsFactors = FALSE
)

waves_to_test <- sort(unique(panel$wave_num))
# Skip first wave (baseline, delta = 0 by construction)
waves_to_test <- waves_to_test[waves_to_test > min(waves_to_test)]

for (wn in waves_to_test) {
  panel_w <- panel %>% filter(wave_num == wn)

  rd_w <- tryCatch(
    rdrobust::rdrobust(
      y = panel_w$delta_primary,
      x = panel_w$running_var,
      c = 0, kernel = "triangular", p = 1, bwselect = "mserd"
    ),
    error = function(e) NULL
  )

  if (!is.null(rd_w)) {
    wlabel <- panel_w$wave[1]
    wyear <- panel_w$wave_year[1]
    dynamic_results <- rbind(dynamic_results, data.frame(
      wave = wlabel,
      wave_year = wyear,
      coef = rd_w$coef[1],
      se_robust = rd_w$se[3],
      pval = rd_w$pv[3],
      bw = rd_w$bws[1, 1],
      n_eff = rd_w$N_h[1] + rd_w$N_h[2],
      stringsAsFactors = FALSE
    ))
  }
}

cat("\nDynamic RDD results:\n")
print(dynamic_results)

## ================================================================
## 7. Save diagnostics for validator
## ================================================================

# Count treated units within bandwidth
n_treated_bw <- sum(rdd$running_var > 0 & rdd$running_var <= main_bw)
n_control_bw <- sum(rdd$running_var <= 0 & rdd$running_var >= -main_bw)

diagnostics <- list(
  n_treated = sum(rdd$treated == 1),
  n_pre = as.integer(n_distinct(panel$wave) - 1),  # waves after baseline
  n_obs = nrow(rdd),
  n_treated_bandwidth = n_treated_bw,
  n_control_bandwidth = n_control_bw,
  density_test_pval = density_results$p_value,
  main_coef = main_coef,
  main_se_robust = main_se,
  main_pval_robust = main_pval,
  optimal_bandwidth = main_bw
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)
cat("\nSaved diagnostics.json\n")

## ================================================================
## 8. Save all results for table generation
## ================================================================

results <- list(
  main = list(
    coef = main_coef,
    se = main_se,
    pval = main_pval,
    bw = main_bw,
    n_eff = main_n_eff,
    n_left = rd_main$N_h[1],
    n_right = rd_main$N_h[2]
  ),
  secondary = list(
    coef = rd_secondary$coef[1],
    se = rd_secondary$se[3],
    pval = rd_secondary$pv[3],
    bw = rd_secondary$bws[1, 1],
    n_eff = rd_secondary$N_h[1] + rd_secondary$N_h[2]
  ),
  growth = list(
    coef = rd_growth$coef[1],
    se = rd_growth$se[3],
    pval = rd_growth$pv[3],
    bw = rd_growth$bws[1, 1],
    n_eff = rd_growth$N_h[1] + rd_growth$N_h[2]
  ),
  density = density_results,
  balance = balance_results,
  dynamic = dynamic_results
)

saveRDS(results, file.path(data_dir, "rdd_results.rds"))
cat("Saved rdd_results.rds\n")
