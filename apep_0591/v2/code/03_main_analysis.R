# =============================================================================
# 03_main_analysis.R — Main estimation: NUTS3 long-difference + NUTS2 panel
# APEP-0591 v2: The Erasmus Drain
# =============================================================================
# Primary: NUTS3 long-difference 2SLS with country FE
#   Δ(tert share 25-34)_{NUTS3, 2011→2021} = α_country + β × Bartik + X'γ + ε
# Supplementary: NUTS2 panel 2SLS (from v1, now secondary)
# =============================================================================

source("00_packages.R")

data_dir <- "../data"

nuts3_cross <- fread(file.path(data_dir, "nuts3_cross_section.csv"))
panel_n2 <- fread(file.path(data_dir, "nuts2_panel.csv"))
panel_n3 <- fread(file.path(data_dir, "nuts3_panel.csv"))
diag <- readRDS(file.path(data_dir, "diagnostic_results.rds"))

cat("=== MAIN ANALYSIS ===\n")
cat("Diagnostic decision:", diag$decision, "\n\n")

# ---------------------------------------------------------------
# 1. Summary statistics
# ---------------------------------------------------------------
cat("--- Summary Statistics ---\n")

# NUTS3 cross-section
sum_vars_n3 <- c("tert_share_2011", "tert_share_2021", "delta_tert",
                   "out_rate", "net_out_rate", "bartik_avg",
                   "predicted_out_rate", "gdp_pc_2011", "pop_20_29_avg")

sumstats_n3 <- rbindlist(lapply(intersect(sum_vars_n3, names(nuts3_cross)), function(v) {
  vals <- nuts3_cross[[v]]
  vals <- vals[!is.na(vals)]
  if (length(vals) == 0) return(NULL)
  data.table(variable = v, mean = mean(vals), sd = sd(vals),
             min = min(vals), max = max(vals), n = length(vals))
}))

fwrite(sumstats_n3, file.path(data_dir, "sumstats_nuts3.csv"))
cat("NUTS3 summary statistics:\n")
print(sumstats_n3)

# NUTS2 panel
sum_vars_n2 <- c("tert_share_25_34", "tert_share_25_64", "out_rate",
                   "net_out_rate", "bartik_growth", "predicted_out_rate",
                   "gdp_pc", "lfp_25_34", "emp_25_34")

sumstats_n2 <- rbindlist(lapply(intersect(sum_vars_n2, names(panel_n2)), function(v) {
  vals <- panel_n2[[v]]
  vals <- vals[!is.na(vals)]
  if (length(vals) == 0) return(NULL)
  data.table(variable = v, mean = mean(vals), sd = sd(vals),
             min = min(vals), max = max(vals), n = length(vals))
}))

fwrite(sumstats_n2, file.path(data_dir, "sumstats_nuts2.csv"))

# ================================================================
# PART A: NUTS3 LONG-DIFFERENCE (PRIMARY SPECIFICATION)
# ================================================================

cat("\n\n========================================\n")
cat("PART A: NUTS3 LONG-DIFFERENCE (PRIMARY)\n")
cat("========================================\n\n")

# NUTS3 education is not available — use NUTS3 youth share change instead
# and NUTS2 census long-difference for education
has_nuts3_youth <- "delta_youth_share" %in% names(nuts3_cross) &&
                    sum(!is.na(nuts3_cross$delta_youth_share) &
                        !is.na(nuts3_cross$bartik_avg)) > 100

# Also load NUTS2 cross-section for census long-difference
cross_n2 <- fread(file.path(data_dir, "nuts2_cross_section.csv"))
has_n2_long_diff <- "delta_tert" %in% names(cross_n2) &&
                     sum(!is.na(cross_n2$delta_tert)) > 50

# ---------------------------------------------------------------
# A1-A4: NUTS3 youth population share (long-difference)
# ---------------------------------------------------------------
if (has_nuts3_youth) {
  cat("\n--- NUTS3 Long-Difference: Youth Population Share ---\n")

  ols_n3_youth <- feols(delta_youth_share ~ out_rate | country,
                          data = nuts3_cross[!is.na(delta_youth_share) & !is.na(out_rate)])
  cat("OLS (NUTS3 youth share):\n")
  print(summary(ols_n3_youth))

  fs_n3 <- feols(out_rate ~ bartik_avg | country,
                   data = nuts3_cross[!is.na(out_rate) & !is.na(bartik_avg) &
                                       !is.na(delta_youth_share)])
  cat("\nFirst Stage (NUTS3, country FE):\n")
  print(summary(fs_n3))

  iv_n3_youth <- tryCatch({
    feols(delta_youth_share ~ 1 | country | out_rate ~ bartik_avg,
          data = nuts3_cross[!is.na(delta_youth_share) & !is.na(bartik_avg) &
                              !is.na(out_rate)])
  }, error = function(e) { cat("  IV failed:", e$message, "\n"); NULL })

  if (!is.null(iv_n3_youth)) {
    cat("\n2SLS (NUTS3 youth share):\n")
    print(summary(iv_n3_youth))
  }

  rf_n3 <- feols(delta_youth_share ~ bartik_avg | country,
                   data = nuts3_cross[!is.na(delta_youth_share) & !is.na(bartik_avg)])
  cat("\nReduced Form (NUTS3):\n")
  print(summary(rf_n3))
} else {
  ols_n3_youth <- NULL; fs_n3 <- NULL; iv_n3_youth <- NULL; rf_n3 <- NULL
}

# ---------------------------------------------------------------
# A5-A7: NUTS2 Census Long-Difference (education outcome)
# ---------------------------------------------------------------
if (has_n2_long_diff) {
  cat("\n--- NUTS2 Census Long-Difference (Education) ---\n")

  ols_n2_ld <- feols(delta_tert ~ delta_out | country,
                       data = cross_n2[!is.na(delta_tert) & !is.na(delta_out)])
  cat("OLS (NUTS2 long-diff):\n")
  print(summary(ols_n2_ld))

  iv_n2_ld <- tryCatch({
    feols(delta_tert ~ 1 | country | delta_out ~ bartik_n3_post,
          data = cross_n2[!is.na(delta_tert) & !is.na(delta_out) &
                           !is.na(bartik_n3_post)])
  }, error = function(e) { cat("  IV failed:", e$message, "\n"); NULL })

  if (!is.null(iv_n2_ld)) {
    cat("\n2SLS (NUTS2 long-diff, NUTS3-aggregated Bartik):\n")
    print(summary(iv_n2_ld))
  }

  # Also try with original NUTS2 Bartik
  iv_n2_ld_orig <- tryCatch({
    feols(delta_tert ~ 1 | country | delta_out ~ bartik_post,
          data = cross_n2[!is.na(delta_tert) & !is.na(delta_out) &
                           !is.na(bartik_post)])
  }, error = function(e) { cat("  IV (orig) failed:", e$message, "\n"); NULL })

  # Placebo: 25-64
  iv_n2_ld_placebo <- tryCatch({
    feols(delta_tert_old ~ 1 | country | delta_out ~ bartik_n3_post,
          data = cross_n2[!is.na(delta_tert_old) & !is.na(delta_out) &
                           !is.na(bartik_n3_post)])
  }, error = function(e) NULL)
} else {
  ols_n2_ld <- NULL; iv_n2_ld <- NULL; iv_n2_ld_orig <- NULL; iv_n2_ld_placebo <- NULL
}

has_long_diff <- FALSE  # Set to FALSE for backward compat with table scripts

if (FALSE) {  # ORIGINAL CODE — disabled since education not at NUTS3
  # ---------------------------------------------------------------
  # A1. OLS baseline (NUTS3 long-difference)
  # ---------------------------------------------------------------
  ols_n3 <- feols(delta_tert ~ out_rate | country,
                   data = nuts3_cross[!is.na(delta_tert) & !is.na(out_rate)])

  cat("--- A1: OLS (NUTS3 long-difference) ---\n")
  print(summary(ols_n3))

  # ---------------------------------------------------------------
  # A2. First stage (NUTS3 cross-section, country FE)
  # ---------------------------------------------------------------
  fs_n3 <- feols(out_rate ~ bartik_avg | country,
                  data = nuts3_cross[!is.na(out_rate) & !is.na(bartik_avg) &
                                      !is.na(delta_tert)])

  cat("\n--- A2: First Stage (NUTS3, country FE) ---\n")
  print(summary(fs_n3))

  # ---------------------------------------------------------------
  # A3. 2SLS main specification
  # ---------------------------------------------------------------
  # Δ(tert share 25-34)_{2011→2021} = α_country + β × out_rate + ε
  # Instrument: bartik_avg (average Bartik growth 2014-2022)
  iv_n3_main <- feols(delta_tert ~ 1 | country | out_rate ~ bartik_avg,
                       data = nuts3_cross[!is.na(delta_tert) & !is.na(bartik_avg) &
                                           !is.na(out_rate)])

  cat("\n--- A3: 2SLS Main (NUTS3, country FE) ---\n")
  print(summary(iv_n3_main))

  # ---------------------------------------------------------------
  # A4. 2SLS with controls (GDP, population)
  # ---------------------------------------------------------------
  iv_n3_controls <- feols(delta_tert ~ log_gdp_2011 + log(pop_total_avg) | country |
                           out_rate ~ bartik_avg,
                           data = nuts3_cross[!is.na(delta_tert) & !is.na(bartik_avg) &
                                               !is.na(out_rate) & !is.na(log_gdp_2011) &
                                               !is.na(pop_total_avg) & pop_total_avg > 0])

  cat("\n--- A4: 2SLS with controls (NUTS3) ---\n")
  print(summary(iv_n3_controls))

  # ---------------------------------------------------------------
  # A5. Reduced form (NUTS3)
  # ---------------------------------------------------------------
  rf_n3 <- feols(delta_tert ~ bartik_avg | country,
                  data = nuts3_cross[!is.na(delta_tert) & !is.na(bartik_avg)])

  cat("\n--- A5: Reduced Form (NUTS3) ---\n")
  print(summary(rf_n3))

  # ---------------------------------------------------------------
  # A6. Placebo: older cohort (if available)
  # ---------------------------------------------------------------
  # Check if we have 25-64 or 35-64 long-difference
  if ("tert_share_25_64_2021" %in% names(nuts3_cross) &&
      "tert_share_25_64_2011" %in% names(nuts3_cross)) {
    nuts3_cross[, delta_tert_old := tert_share_25_64_2021 - tert_share_25_64_2011]

    iv_n3_placebo <- feols(delta_tert_old ~ 1 | country | out_rate ~ bartik_avg,
                            data = nuts3_cross[!is.na(delta_tert_old) & !is.na(bartik_avg) &
                                                !is.na(out_rate)])
    cat("\n--- A6: 2SLS Placebo (25-64, NUTS3) ---\n")
    print(summary(iv_n3_placebo))
  } else {
    cat("\n--- A6: Placebo skipped (no older cohort data) ---\n")
    iv_n3_placebo <- NULL
  }

} else {
  cat("\nWARNING: Original NUTS3 education code disabled.\n")
}  # END of if(FALSE) block

# Set variables that weren't created
if (!exists("iv_n3_main")) iv_n3_main <- NULL
if (!exists("iv_n3_controls")) iv_n3_controls <- NULL
if (!exists("iv_n3_placebo")) iv_n3_placebo <- NULL
if (!exists("ols_n3")) ols_n3 <- NULL

# ---------------------------------------------------------------
# A7. NUTS3 panel specifications (annual, with distributed lags)
# ---------------------------------------------------------------
cat("\n--- A7: NUTS3 Panel Specifications ---\n")

# Merge predicted outflow rate into NUTS3 panel (handle duplicate cols)
if (!"total_pre_annual" %in% names(panel_n3)) {
  if ("total_pre_annual.x" %in% names(panel_n3)) {
    setnames(panel_n3, "total_pre_annual.x", "total_pre_annual")
    if ("total_pre_annual.y" %in% names(panel_n3))
      panel_n3[, total_pre_annual.y := NULL]
  } else {
    pre_totals <- unique(nuts3_cross[!is.na(total_pre_annual),
                                      .(nuts3, total_pre_annual)], by = "nuts3")
    panel_n3 <- merge(panel_n3, pre_totals, by = "nuts3", all.x = TRUE)
  }
}
if (!"predicted_out_rate" %in% names(panel_n3) || all(is.na(panel_n3$predicted_out_rate))) {
  panel_n3[!is.na(bartik_growth) & !is.na(total_pre_annual) & pop_20_29 > 0,
           predicted_out_rate := (total_pre_annual * (1 + bartik_growth)) / (pop_20_29 / 1000)]
}

# Panel first stage (NUTS3 + year FE)
fs_n3_panel <- tryCatch({
  feols(out_rate ~ bartik_growth | nuts3 + year,
        data = panel_n3[!is.na(out_rate) & !is.na(bartik_growth)],
        cluster = ~nuts3)
}, error = function(e) { cat("Failed:", e$message, "\n"); NULL })

if (!is.null(fs_n3_panel)) {
  cat("  Panel first stage (NUTS3 + year FE):\n")
  cat("    Coefficient:", round(coef(fs_n3_panel)["bartik_growth"], 4), "\n")
  cat("    F:", round((coef(fs_n3_panel)["bartik_growth"] /
                       se(fs_n3_panel)["bartik_growth"])^2, 1), "\n")
}

# Panel first stage with country×year FE
fs_n3_cy <- tryCatch({
  feols(out_rate ~ bartik_growth | nuts3 + country^year,
        data = panel_n3[!is.na(out_rate) & !is.na(bartik_growth)],
        cluster = ~nuts3)
}, error = function(e) { cat("Failed:", e$message, "\n"); NULL })

if (!is.null(fs_n3_cy)) {
  cat("  Panel first stage (NUTS3 + country×year FE):\n")
  cat("    Coefficient:", round(coef(fs_n3_cy)["bartik_growth"], 4), "\n")
  cat("    F:", round((coef(fs_n3_cy)["bartik_growth"] /
                       se(fs_n3_cy)["bartik_growth"])^2, 1), "\n")
}


# ================================================================
# PART B: NUTS2 PANEL (SUPPLEMENTARY)
# ================================================================

cat("\n\n========================================\n")
cat("PART B: NUTS2 PANEL (SUPPLEMENTARY)\n")
cat("========================================\n\n")

# ---------------------------------------------------------------
# B1. OLS baseline
# ---------------------------------------------------------------
ols_n2 <- feols(tert_share_25_34 ~ out_rate | nuts2 + year,
                 data = panel_n2[!is.na(tert_share_25_34) & !is.na(out_rate)],
                 cluster = ~nuts2)

cat("--- B1: OLS (NUTS2 panel) ---\n")
print(summary(ols_n2))

# ---------------------------------------------------------------
# B2. First stage
# ---------------------------------------------------------------
fs_n2 <- feols(out_rate ~ predicted_out_rate | nuts2 + year,
                data = panel_n2[!is.na(predicted_out_rate) & !is.na(out_rate)],
                cluster = ~nuts2)

cat("\n--- B2: First Stage (NUTS2 panel) ---\n")
print(summary(fs_n2))

# ---------------------------------------------------------------
# B3. 2SLS main
# ---------------------------------------------------------------
iv_n2_main <- feols(tert_share_25_34 ~ 1 | nuts2 + year |
                     out_rate ~ predicted_out_rate,
                     data = panel_n2[!is.na(tert_share_25_34) &
                                      !is.na(predicted_out_rate) & !is.na(out_rate)],
                     cluster = ~nuts2)

cat("\n--- B3: 2SLS Main (NUTS2 panel) ---\n")
print(summary(iv_n2_main))

# ---------------------------------------------------------------
# B4. 2SLS with country×year FE (the killer test from v1)
# ---------------------------------------------------------------
iv_n2_cy <- feols(tert_share_25_34 ~ 1 | nuts2 + country^year |
                   out_rate ~ predicted_out_rate,
                   data = panel_n2[!is.na(tert_share_25_34) &
                                    !is.na(predicted_out_rate) & !is.na(out_rate)],
                   cluster = ~nuts2)

cat("\n--- B4: 2SLS with country×year FE (NUTS2) ---\n")
print(summary(iv_n2_cy))

# ---------------------------------------------------------------
# B5. Distributed lags (addressing timing mismatch)
# ---------------------------------------------------------------
cat("\n--- B5: Distributed Lags (NUTS2) ---\n")

# Create lagged outflow rates
panel_n2 <- panel_n2[order(nuts2, year)]
panel_n2[, out_rate_lag1 := shift(out_rate, 1), by = nuts2]
panel_n2[, out_rate_lag2 := shift(out_rate, 2), by = nuts2]
panel_n2[, out_rate_lag3 := shift(out_rate, 3), by = nuts2]

# Lagged predicted outflow rates
panel_n2[, pred_out_lag1 := shift(predicted_out_rate, 1), by = nuts2]
panel_n2[, pred_out_lag2 := shift(predicted_out_rate, 2), by = nuts2]
panel_n2[, pred_out_lag3 := shift(predicted_out_rate, 3), by = nuts2]

# 2-year lag specification
iv_lag2 <- tryCatch({
  feols(tert_share_25_34 ~ 1 | nuts2 + year |
        out_rate_lag2 ~ pred_out_lag2,
        data = panel_n2[!is.na(tert_share_25_34) &
                         !is.na(pred_out_lag2) & !is.na(out_rate_lag2)],
        cluster = ~nuts2)
}, error = function(e) { cat("  Lag-2 failed:", e$message, "\n"); NULL })

if (!is.null(iv_lag2)) {
  cat("  2SLS with 2-year lag:\n")
  print(summary(iv_lag2))
}

# 3-year lag specification
iv_lag3 <- tryCatch({
  feols(tert_share_25_34 ~ 1 | nuts2 + year |
        out_rate_lag3 ~ pred_out_lag3,
        data = panel_n2[!is.na(tert_share_25_34) &
                         !is.na(pred_out_lag3) & !is.na(out_rate_lag3)],
        cluster = ~nuts2)
}, error = function(e) { cat("  Lag-3 failed:", e$message, "\n"); NULL })

if (!is.null(iv_lag3)) {
  cat("  2SLS with 3-year lag:\n")
  print(summary(iv_lag3))
}

# ---------------------------------------------------------------
# B6. Placebo: broader cohort (25-64)
# ---------------------------------------------------------------
iv_n2_placebo <- feols(tert_share_25_64 ~ 1 | nuts2 + year |
                        out_rate ~ predicted_out_rate,
                        data = panel_n2[!is.na(tert_share_25_64) &
                                         !is.na(predicted_out_rate) & !is.na(out_rate)],
                        cluster = ~nuts2)

cat("\n--- B6: Placebo (NUTS2, tert 25-64) ---\n")
print(summary(iv_n2_placebo))

# ---------------------------------------------------------------
# B7. Two-way clustering
# ---------------------------------------------------------------
iv_n2_2way <- feols(tert_share_25_34 ~ 1 | nuts2 + year |
                     out_rate ~ predicted_out_rate,
                     data = panel_n2[!is.na(tert_share_25_34) &
                                      !is.na(predicted_out_rate) & !is.na(out_rate)],
                     cluster = ~nuts2 + year)

cat("\n--- B7: Two-way clustering (NUTS2) ---\n")
print(summary(iv_n2_2way))

# ---------------------------------------------------------------
# B8. Receiver-side analysis (NEW: do core regions gain?)
# ---------------------------------------------------------------
cat("\n--- B8: Receiver-side analysis ---\n")

# Inflow rate as treatment
inflows_n2 <- fread(file.path(data_dir, "bilateral_nuts2_flows.csv"))
inflow_agg <- inflows_n2[, .(total_in = sum(flow)), by = .(nuts2 = dest, year)]

# Handle potential duplicate column from prior merge
if ("total_in" %in% names(panel_n2)) {
  panel_n2[, total_in := NULL]
}
if ("total_in.x" %in% names(panel_n2)) panel_n2[, total_in.x := NULL]
if ("total_in.y" %in% names(panel_n2)) panel_n2[, total_in.y := NULL]

panel_n2 <- merge(panel_n2, inflow_agg, by = c("nuts2", "year"), all.x = TRUE)
panel_n2[is.na(total_in), total_in := 0]
panel_n2[pop_20_29 > 0, in_rate := total_in / (pop_20_29 / 1000)]

# OLS: inflow rate on tertiary share
ols_inflow <- feols(tert_share_25_34 ~ in_rate | nuts2 + year,
                     data = panel_n2[!is.na(tert_share_25_34) & !is.na(in_rate)],
                     cluster = ~nuts2)

cat("  OLS: Tertiary share ~ Inflow rate:\n")
print(summary(ols_inflow))

# ---------------------------------------------------------------
# Save all results
# ---------------------------------------------------------------
results <- list(
  # NUTS3 youth share (long-difference)
  ols_n3_youth = ols_n3_youth,
  fs_n3 = fs_n3,
  iv_n3_youth = iv_n3_youth,
  rf_n3 = rf_n3,
  # NUTS2 census long-difference
  ols_n2_ld = ols_n2_ld,
  iv_n2_ld = iv_n2_ld,
  iv_n2_ld_orig = iv_n2_ld_orig,
  iv_n2_ld_placebo = iv_n2_ld_placebo,
  # NUTS3 panel
  fs_n3_panel = fs_n3_panel,
  fs_n3_cy = fs_n3_cy,
  # NUTS2 panel (supplementary)
  ols_n2 = ols_n2,
  fs_n2 = fs_n2,
  iv_n2_main = iv_n2_main,
  iv_n2_cy = iv_n2_cy,
  iv_lag2 = iv_lag2,
  iv_lag3 = iv_lag3,
  iv_n2_placebo = iv_n2_placebo,
  iv_n2_2way = iv_n2_2way,
  ols_inflow = ols_inflow
)

saveRDS(results, file.path(data_dir, "main_results.rds"))

# Coefficient summary table
safe_coef <- function(mod, var) if (!is.null(mod)) tryCatch(coef(mod)[var], error = function(e) NA) else NA
safe_se <- function(mod, var) if (!is.null(mod)) tryCatch(se(mod)[var], error = function(e) NA) else NA
safe_n <- function(mod) if (!is.null(mod)) tryCatch(nobs(mod), error = function(e) NA) else NA

coef_summary <- data.table(
  specification = c(
    "NUTS3 OLS youth share (long-diff)", "NUTS3 2SLS youth share (long-diff)",
    "NUTS2 OLS (census long-diff)", "NUTS2 2SLS (census long-diff, N3 Bartik)",
    "NUTS2 2SLS (census long-diff, N2 Bartik)", "NUTS2 census placebo (25-64)",
    "NUTS2 OLS (panel)", "NUTS2 2SLS (panel)", "NUTS2 2SLS + country×year",
    "NUTS2 2SLS lag-2", "NUTS2 2SLS lag-3",
    "NUTS2 2SLS 2-way cluster", "NUTS2 panel placebo (25-64)",
    "NUTS2 inflow OLS"
  ),
  beta = c(
    safe_coef(ols_n3_youth, "out_rate"),
    safe_coef(iv_n3_youth, "fit_out_rate"),
    safe_coef(ols_n2_ld, "delta_out"),
    safe_coef(iv_n2_ld, "fit_delta_out"),
    safe_coef(iv_n2_ld_orig, "fit_delta_out"),
    safe_coef(iv_n2_ld_placebo, "fit_delta_out"),
    safe_coef(ols_n2, "out_rate"),
    safe_coef(iv_n2_main, "fit_out_rate"),
    safe_coef(iv_n2_cy, "fit_out_rate"),
    safe_coef(iv_lag2, "fit_out_rate_lag2"),
    safe_coef(iv_lag3, "fit_out_rate_lag3"),
    safe_coef(iv_n2_2way, "fit_out_rate"),
    safe_coef(iv_n2_placebo, "fit_out_rate"),
    safe_coef(ols_inflow, "in_rate")
  ),
  se = c(
    safe_se(ols_n3_youth, "out_rate"),
    safe_se(iv_n3_youth, "fit_out_rate"),
    safe_se(ols_n2_ld, "delta_out"),
    safe_se(iv_n2_ld, "fit_delta_out"),
    safe_se(iv_n2_ld_orig, "fit_delta_out"),
    safe_se(iv_n2_ld_placebo, "fit_delta_out"),
    safe_se(ols_n2, "out_rate"),
    safe_se(iv_n2_main, "fit_out_rate"),
    safe_se(iv_n2_cy, "fit_out_rate"),
    safe_se(iv_lag2, "fit_out_rate_lag2"),
    safe_se(iv_lag3, "fit_out_rate_lag3"),
    safe_se(iv_n2_2way, "fit_out_rate"),
    safe_se(iv_n2_placebo, "fit_out_rate"),
    safe_se(ols_inflow, "in_rate")
  ),
  n = c(
    safe_n(ols_n3_youth), safe_n(iv_n3_youth),
    safe_n(ols_n2_ld), safe_n(iv_n2_ld), safe_n(iv_n2_ld_orig), safe_n(iv_n2_ld_placebo),
    safe_n(ols_n2), safe_n(iv_n2_main), safe_n(iv_n2_cy),
    safe_n(iv_lag2), safe_n(iv_lag3),
    safe_n(iv_n2_2way), safe_n(iv_n2_placebo), safe_n(ols_inflow)
  )
)

fwrite(coef_summary, file.path(data_dir, "coefficient_summary.csv"))

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
print(coef_summary)
