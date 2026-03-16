## 03_main_analysis.R — Main RDD estimation
## APEP Paper apep_0706: FPM Fiscal Windfalls and Homicide Rates
## Uses annual assignment as primary specification

source("00_packages.R")

cat("=== Main RDD Analysis ===\n")

rdd_data <- readRDS("../data/rdd_analysis.rds")
panel <- readRDS("../data/panel_rdd.rds")

# ─────────────────────────────────────────────────────────────────────
# 1. Pooled Multi-Cutoff RDD — ANNUAL PANEL (Primary Specification)
# ─────────────────────────────────────────────────────────────────────
cat("--- Panel RDD with Annual Assignment (PRIMARY) ---\n")

# Each obs is a municipality-year. Running variable is annual distance
# to nearest threshold. This tracks the institutional assignment rule.

rd_panel <- rdrobust(
  y = panel$homicide_rate,
  x = panel$running_var,
  kernel = "triangular",
  bwselect = "mserd",
  cluster = panel$state_code,
  all = TRUE
)

cat("\nPanel RDD result (homicide rate per 100K):\n")
summary(rd_panel)

main_coef <- rd_panel$coef[1]
main_se <- rd_panel$se[3]
main_bw <- rd_panel$bws[1, 1]
main_n_l <- rd_panel$N_h[1]
main_n_r <- rd_panel$N_h[2]
main_pval <- rd_panel$pv[3]

cat(sprintf("\nPrimary RDD estimate: %.3f (robust SE = %.3f, p = %.4f)\n",
            main_coef, main_se, main_pval))
cat(sprintf("Bandwidth: %.0f, Eff N: %d + %d = %d\n",
            main_bw, main_n_l, main_n_r, main_n_l + main_n_r))

# ─────────────────────────────────────────────────────────────────────
# 2. Log specification (panel)
# ─────────────────────────────────────────────────────────────────────
cat("\n--- Log Homicide Rate (Panel) ---\n")

rd_log <- rdrobust(
  y = panel$log_homicide_rate,
  x = panel$running_var,
  kernel = "triangular",
  bwselect = "mserd",
  cluster = panel$state_code,
  all = TRUE
)

log_coef <- rd_log$coef[1]
log_se <- rd_log$se[3]
log_pval <- rd_log$pv[3]
log_bw <- rd_log$bws[1, 1]

cat(sprintf("Log RDD: %.4f (SE = %.4f, p = %.4f)\n", log_coef, log_se, log_pval))

# ─────────────────────────────────────────────────────────────────────
# 3. Panel RDD with Year FE (fixest within bandwidth)
# ─────────────────────────────────────────────────────────────────────
cat("\n--- Panel with Year FE (within MSE-optimal bandwidth) ---\n")

panel_bw <- panel %>%
  filter(abs(running_var) <= main_bw) %>%
  mutate(kern_weight = 1 - abs(running_var) / main_bw)

cat(sprintf("Within bandwidth: %d mun-years, %d municipalities\n",
            nrow(panel_bw), n_distinct(panel_bw$mun_code)))

panel_reg_yr <- feols(
  homicide_rate ~ above_threshold * running_var | year,
  data = panel_bw,
  weights = panel_bw$kern_weight,
  cluster = ~state_code
)
summary(panel_reg_yr)

# ─────────────────────────────────────────────────────────────────────
# 4. Panel with State + Year FE
# ─────────────────────────────────────────────────────────────────────
cat("\n--- Panel with State + Year FE ---\n")

panel_reg_sy <- feols(
  homicide_rate ~ above_threshold * running_var | state_code + year,
  data = panel_bw,
  weights = panel_bw$kern_weight,
  cluster = ~state_code
)
summary(panel_reg_sy)

# ─────────────────────────────────────────────────────────────────────
# 5. Cross-sectional RDD (robustness, averages)
# ─────────────────────────────────────────────────────────────────────
cat("\n--- Cross-Sectional RDD (Robustness) ---\n")

rd_xs <- rdrobust(
  y = rdd_data$mean_homicide_rate,
  x = rdd_data$running_var,
  kernel = "triangular",
  bwselect = "mserd",
  cluster = rdd_data$state_code,
  all = TRUE
)

xs_coef <- rd_xs$coef[1]
xs_se <- rd_xs$se[3]
xs_pval <- rd_xs$pv[3]

cat(sprintf("Cross-section RDD: %.3f (SE = %.3f, p = %.4f)\n",
            xs_coef, xs_se, xs_pval))

# ─────────────────────────────────────────────────────────────────────
# 6. Youth Homicide Rate (Mechanism)
# ─────────────────────────────────────────────────────────────────────
cat("\n--- Youth Homicide Rate (Ages 15-29) ---\n")

if ("youth_homicide_rate" %in% names(panel)) {
  rd_youth <- tryCatch(
    rdrobust(
      y = panel$youth_homicide_rate,
      x = panel$running_var,
      kernel = "triangular",
      bwselect = "mserd",
      cluster = panel$state_code,
      all = TRUE
    ),
    error = function(e) { cat("Youth RDD failed:", e$message, "\n"); NULL }
  )

  if (!is.null(rd_youth)) {
    youth_coef <- rd_youth$coef[1]
    youth_se <- rd_youth$se[3]
    youth_pval <- rd_youth$pv[3]
    cat(sprintf("Youth homicide RDD: %.3f (SE = %.3f, p = %.4f)\n",
                youth_coef, youth_se, youth_pval))
  }
} else {
  cat("Youth homicide data not available.\n")
  youth_coef <- NA; youth_se <- NA; youth_pval <- NA
}

# ─────────────────────────────────────────────────────────────────────
# 7. Cutoff-by-cutoff estimates (panel)
# ─────────────────────────────────────────────────────────────────────
cat("\n--- Cutoff-by-Cutoff Estimates ---\n")

thresholds_pop <- c(10189, 13585, 16981, 23773, 30564, 37356,
                    44148, 50940, 61128, 71316, 81504, 91692,
                    101880, 115464, 129048, 142632, 156216)

cutoff_results <- list()
for (idx in sort(unique(panel$threshold_idx))) {
  sub <- panel %>% filter(threshold_idx == idx)
  if (nrow(sub) < 200) next

  rd_cut <- tryCatch(
    rdrobust(y = sub$homicide_rate, x = sub$running_var,
             kernel = "triangular", bwselect = "mserd", all = TRUE),
    error = function(e) NULL
  )

  if (!is.null(rd_cut)) {
    cutoff_results[[as.character(idx)]] <- data.frame(
      threshold_idx = idx,
      threshold_pop = thresholds_pop[idx],
      coef = rd_cut$coef[1],
      se_robust = rd_cut$se[3],
      pval = rd_cut$pv[3],
      bw = rd_cut$bws[1, 1],
      n_eff = rd_cut$N_h[1] + rd_cut$N_h[2]
    )
    cat(sprintf("  Cutoff %d (~%s): %.3f (SE %.3f, p %.3f, N=%d)\n",
                idx, format(thresholds_pop[idx], big.mark = ","),
                rd_cut$coef[1], rd_cut$se[3], rd_cut$pv[3],
                rd_cut$N_h[1] + rd_cut$N_h[2]))
  }
}

cutoff_df <- bind_rows(cutoff_results)
saveRDS(cutoff_df, "../data/cutoff_estimates.rds")

# ─────────────────────────────────────────────────────────────────────
# 8. Save all main results
# ─────────────────────────────────────────────────────────────────────
main_results <- list(
  panel_rd = list(coef = main_coef, se = main_se, pval = main_pval,
                  bw = main_bw, n_left = main_n_l, n_right = main_n_r),
  log = list(coef = log_coef, se = log_se, pval = log_pval, bw = log_bw),
  panel_yr_fe = broom::tidy(panel_reg_yr),
  panel_sy_fe = broom::tidy(panel_reg_sy),
  xs_rd = list(coef = xs_coef, se = xs_se, pval = xs_pval),
  youth = list(coef = youth_coef, se = youth_se, pval = youth_pval),
  cutoffs = cutoff_df
)
saveRDS(main_results, "../data/main_results.rds")

# Write diagnostics.json
n_treated <- sum(panel$above_threshold == 1 & abs(panel$running_var) <= main_bw)
n_control <- sum(panel$above_threshold == 0 & abs(panel$running_var) <= main_bw)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = 17,
  n_obs = nrow(panel),
  n_control = n_control,
  bandwidth = main_bw,
  main_coef = main_coef,
  main_se = main_se,
  main_pval = main_pval,
  n_cutoffs = nrow(cutoff_df),
  n_municipalities = n_distinct(panel$mun_code),
  n_mun_years = nrow(panel)
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

cat(sprintf("\nDiagnostics: n_treated=%d, n_control=%d, n_obs=%d\n",
            n_treated, n_control, nrow(panel)))
cat("Main analysis complete.\n")
