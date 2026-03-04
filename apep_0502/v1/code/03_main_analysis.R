# ==============================================================================
# 03_main_analysis.R — RDD estimation of nonattainment effects on energy
# Clean Air, Dirty Power? NAAQS Nonattainment and the Clean Energy Transition
# ==============================================================================

source("00_packages.R")

# Load cross-sectional RDD dataset (primary) and panel (supplementary)
cs <- readRDS(file.path(data_dir, "cross_section_rdd.rds"))
panel <- readRDS(file.path(data_dir, "analysis_with_energy.rds"))

cat("=== Main Analysis: Cross-Sectional RDD at NAAQS PM2.5 Thresholds ===\n")
cat(sprintf("Cross-section: %d counties\n", nrow(cs)))
cat(sprintf("Counties with energy data: %d\n", sum(cs$total_capacity > 0, na.rm = TRUE)))
cat(sprintf("Nonattainment (DV > 12): %d (%.1f%%)\n",
            sum(cs$treat_12 == 1, na.rm = TRUE),
            100 * mean(cs$treat_12 == 1, na.rm = TRUE)))

# Primary RDD: cross-sectional
rdd_data <- cs[!is.na(running_12)]
cat(sprintf("RDD sample: %d counties\n", nrow(rdd_data)))

# ==============================================================================
# 1. McCrary Density Test
# ==============================================================================

cat("\n--- McCrary Density Test ---\n")

tryCatch({
  density_test_12 <- rddensity(X = rdd_data$running_12, c = 0)
  cat(sprintf("  12 μg/m³ cutoff: T=%.3f, p=%.4f → %s\n",
              density_test_12$test$t_jk, density_test_12$test$p_jk,
              ifelse(density_test_12$test$p_jk > 0.05, "PASS (no manipulation)", "CONCERN")))
}, error = function(e) cat(sprintf("  Error: %s\n", e$message)))

# Pre-2012 standard (15 μg/m³) — use panel for this as it reflects historical variation
rdd_pre <- panel[Year >= 2003 & Year < 2012 & !is.na(running_15)]
tryCatch({
  density_test_15 <- rddensity(X = rdd_pre$running_15, c = 0)
  cat(sprintf("  15 μg/m³ cutoff: T=%.3f, p=%.4f → %s\n",
              density_test_15$test$t_jk, density_test_15$test$p_jk,
              ifelse(density_test_15$test$p_jk > 0.05, "PASS", "CONCERN")))
}, error = function(e) cat(sprintf("  Error: %s\n", e$message)))

# ==============================================================================
# 2. Covariate Balance
# ==============================================================================

cat("\n--- Covariate Balance at 12 μg/m³ Cutoff ---\n")

balance_vars <- c("total_pop", "median_income", "total_workers", "n_monitors")
balance_results <- list()

for (var in balance_vars) {
  if (var %in% names(rdd_data) && sum(!is.na(rdd_data[[var]])) > 50) {
    tryCatch({
      rd_bal <- rdrobust(y = rdd_data[[var]], x = rdd_data$running_12, c = 0,
                          kernel = "triangular", bwselect = "mserd")
      balance_results[[var]] <- data.table(
        variable = var,
        coef = rd_bal$coef["Conventional", ],
        se = rd_bal$se["Conventional", ],
        pvalue = rd_bal$pv["Conventional", ],
        bw = rd_bal$bws["h", "left"],
        N_left = rd_bal$N_h[1], N_right = rd_bal$N_h[2]
      )
      cat(sprintf("  %s: coef=%.1f, p=%.3f (bw=%.2f) %s\n", var,
                  rd_bal$coef["Conventional", ], rd_bal$pv["Conventional", ],
                  rd_bal$bws["h", "left"],
                  ifelse(rd_bal$pv["Conventional", ] > 0.10, "✓", "⚠")))
    }, error = function(e) cat(sprintf("  %s: error\n", var)))
  }
}

if (length(balance_results) > 0) {
  balance_dt <- rbindlist(balance_results)
  saveRDS(balance_dt, file.path(data_dir, "balance_test_results.rds"))
}

# ==============================================================================
# 3. Main RDD: PM2.5 Reduced Form (Policy Bite)
# ==============================================================================

cat("\n--- Reduced Form: Nonattainment → PM2.5 (Panel) ---\n")

# PM2.5 reduced form uses panel data (time-varying outcome)
panel_rdd <- panel[Year >= 2012 & !is.na(running_12)]
rdd_pm25 <- panel_rdd[!is.na(pm25_fwd)]
tryCatch({
  rd_pm25 <- rdrobust(y = rdd_pm25$pm25_fwd, x = rdd_pm25$running_12, c = 0,
                       kernel = "triangular", bwselect = "mserd")
  cat(sprintf("  Next-year PM2.5: coef=%.3f (SE=%.3f), p=%.4f, bw=%.2f, N=%d+%d\n",
              rd_pm25$coef["Conventional", ], rd_pm25$se["Conventional", ],
              rd_pm25$pv["Conventional", ], rd_pm25$bws["h", "left"],
              rd_pm25$N_h[1], rd_pm25$N_h[2]))
}, error = function(e) cat(sprintf("  Error: %s\n", e$message)))

# ==============================================================================
# 4. Main RDD: Energy Infrastructure Outcomes
# ==============================================================================

cat("\n--- Energy Outcomes at 12 μg/m³ Cutoff ---\n")

energy_outcomes <- c(
  "Fossil Capacity (MW)" = "fossil_capacity",
  "Renewable Capacity (MW)" = "renewable_capacity",
  "Coal Capacity (MW)" = "coal_capacity",
  "Gas Capacity (MW)" = "gas_capacity",
  "Solar Capacity (MW)" = "solar_capacity",
  "Wind Capacity (MW)" = "wind_capacity",
  "Total Capacity (MW)" = "total_capacity",
  "Renewable Share" = "renewable_share",
  "N Fossil Plants" = "n_fossil",
  "N Renewable Plants" = "n_renewable",
  "CO2 Emissions (tons)" = "co2_total"
)

rdd_results <- list()

for (label in names(energy_outcomes)) {
  var <- energy_outcomes[label]
  if (!var %in% names(rdd_data)) next
  y <- rdd_data[[var]]
  if (sum(!is.na(y)) < 50) next

  tryCatch({
    rd <- rdrobust(y = y, x = rdd_data$running_12, c = 0,
                    kernel = "triangular", bwselect = "mserd")

    rdd_results[[label]] <- data.table(
      outcome = label,
      coef_conv = rd$coef["Conventional", ],
      se_conv = rd$se["Conventional", ],
      pv_conv = rd$pv["Conventional", ],
      coef_robust = rd$coef["Robust", ],
      se_robust = rd$se["Robust", ],
      pv_robust = rd$pv["Robust", ],
      bw_h = rd$bws["h", "left"],
      N_left = rd$N_h[1],
      N_right = rd$N_h[2],
      N_eff = rd$N_h[1] + rd$N_h[2]
    )

    stars <- ifelse(rd$pv["Conventional", ] < 0.01, "***",
             ifelse(rd$pv["Conventional", ] < 0.05, "**",
             ifelse(rd$pv["Conventional", ] < 0.10, "*", "")))
    cat(sprintf("  %s: coef=%.1f (SE=%.1f)%s, p=%.3f, bw=%.2f, N=%d\n",
                label, rd$coef["Conventional", ], rd$se["Conventional", ],
                stars, rd$pv["Conventional", ], rd$bws["h", "left"],
                rd$N_h[1] + rd$N_h[2]))
  }, error = function(e) cat(sprintf("  %s: error — %s\n", label, e$message)))
}

if (length(rdd_results) > 0) {
  rdd_dt <- rbindlist(rdd_results)
  saveRDS(rdd_dt, file.path(data_dir, "main_rdd_results.rds"))
  cat(sprintf("\nSaved %d RDD results\n", nrow(rdd_dt)))
}

# ==============================================================================
# 5. Multi-Cutoff: 15 μg/m³ Standard (Pre-2012)
# ==============================================================================

cat("\n--- Multi-Cutoff: 15 μg/m³ Standard (2003-2011) ---\n")

if (nrow(rdd_pre) > 50) {
  for (label in c("Fossil Capacity (MW)", "Renewable Capacity (MW)", "CO2 Emissions (tons)")) {
    var <- energy_outcomes[label]
    if (!var %in% names(rdd_pre)) next
    y <- rdd_pre[[var]]
    if (sum(!is.na(y)) < 50) next

    tryCatch({
      rd <- rdrobust(y = y, x = rdd_pre$running_15, c = 0,
                      kernel = "triangular", bwselect = "mserd")
      cat(sprintf("  %s (15 cutoff): coef=%.1f (SE=%.1f), p=%.3f\n",
                  label, rd$coef["Conventional", ], rd$se["Conventional", ],
                  rd$pv["Conventional", ]))
    }, error = function(e) cat(sprintf("  %s: error\n", label)))
  }
}

# ==============================================================================
# 6. Placebo Outcome: Renewables Should Show No Effect
# ==============================================================================

cat("\n--- Placebo: Renewable Capacity (Should Be Null) ---\n")
cat("Renewables emit zero criteria pollutants → exempt from NSR.\n")
cat("If nonattainment affects renewable capacity, it suggests confounding.\n")

tryCatch({
  rd_placebo <- rdrobust(y = rdd_data$renewable_capacity, x = rdd_data$running_12, c = 0,
                          kernel = "triangular", bwselect = "mserd")
  cat(sprintf("  Renewable capacity: coef=%.1f (SE=%.1f), p=%.3f → %s\n",
              rd_placebo$coef["Conventional", ], rd_placebo$se["Conventional", ],
              rd_placebo$pv["Conventional", ],
              ifelse(rd_placebo$pv["Conventional", ] > 0.10, "PLACEBO PASSES", "INVESTIGATE")))
}, error = function(e) cat(sprintf("  Error: %s\n", e$message)))

# ==============================================================================
# 7. Summary
# ==============================================================================

cat("\n=== ANALYSIS COMPLETE ===\n")
cat("Key outputs saved to data/:\n")
cat("  balance_test_results.rds, main_rdd_results.rds\n")
