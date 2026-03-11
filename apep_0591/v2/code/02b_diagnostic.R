# =============================================================================
# 02b_diagnostic.R — Go/No-Go NUTS3 within-country diagnostic
# APEP-0591 v2: The Erasmus Drain
# =============================================================================
# Critical gate: Does the NUTS3 Bartik have within-country variation?
# Test: Regress bartik_avg on country FE, check residual variance
#       Then: first-stage F with country FE at NUTS3 level
# Decision: If within-country first-stage F > 10 → Track A (NUTS3)
#           If F < 10 → Track B (minor revision)
# =============================================================================

source("00_packages.R")

data_dir <- "../data"

nuts3_cross <- fread(file.path(data_dir, "nuts3_cross_section.csv"))
panel_n3 <- fread(file.path(data_dir, "nuts3_panel.csv"))

cat("=== GO/NO-GO DIAGNOSTIC: NUTS3 WITHIN-COUNTRY VARIATION ===\n\n")

# ---------------------------------------------------------------
# Test 1: Within-country variance of NUTS3 Bartik
# ---------------------------------------------------------------
cat("--- Test 1: Within-country variance of NUTS3 Bartik ---\n")

# Total variance
total_var <- var(nuts3_cross$bartik_avg, na.rm = TRUE)

# Within-country residual variance
if (nrow(nuts3_cross[!is.na(bartik_avg) & !is.na(country)]) > 10) {
  bartik_resid <- feols(bartik_avg ~ 1 | country,
                         data = nuts3_cross[!is.na(bartik_avg)])
  within_var <- var(resid(bartik_resid), na.rm = TRUE)
  r2_country <- 1 - within_var / total_var

  cat("  Total variance of bartik_avg:", round(total_var, 6), "\n")
  cat("  Within-country variance:", round(within_var, 6), "\n")
  cat("  R² (country FE only):", round(r2_country, 3), "\n")
  cat("  Share of variance within-country:", round(1 - r2_country, 3), "\n")
  cat("  → ", ifelse(1 - r2_country > 0.3, "GOOD: substantial within-country variation",
                     "WARNING: most variation is cross-country"), "\n\n")
} else {
  cat("  INSUFFICIENT DATA for variance decomposition\n\n")
}

# ---------------------------------------------------------------
# Test 2: NUTS3 panel first stage WITH country FE
# ---------------------------------------------------------------
cat("--- Test 2: Panel first stage with country FE ---\n")

# Need to merge predicted outflow into panel (handle if already merged)
if (!"total_pre_annual" %in% names(panel_n3) && "total_pre_annual.x" %in% names(panel_n3)) {
  setnames(panel_n3, "total_pre_annual.x", "total_pre_annual")
} else if (!"total_pre_annual" %in% names(panel_n3)) {
  pre_totals <- nuts3_cross[!is.na(total_pre_annual),
                             .(nuts3, total_pre_annual)]
  pre_totals <- unique(pre_totals, by = "nuts3")
  panel_n3 <- merge(panel_n3, pre_totals, by = "nuts3", all.x = TRUE)
}
if (!"predicted_out_rate" %in% names(panel_n3) || all(is.na(panel_n3$predicted_out_rate))) {
  panel_n3[!is.na(bartik_growth) & !is.na(total_pre_annual) & pop_20_29 > 0,
           predicted_out_rate := (total_pre_annual * (1 + bartik_growth)) / (pop_20_29 / 1000)]
}

# First stage without country FE (baseline)
fs_base <- tryCatch({
  feols(out_rate ~ bartik_growth | nuts3 + year,
        data = panel_n3[!is.na(out_rate) & !is.na(bartik_growth)],
        cluster = ~nuts3)
}, error = function(e) {
  cat("  Baseline first stage failed:", e$message, "\n")
  NULL
})

if (!is.null(fs_base)) {
  cat("  Baseline (NUTS3 + year FE):\n")
  cat("    Coefficient:", round(coef(fs_base)["bartik_growth"], 4), "\n")
  cat("    t-stat:", round(coef(fs_base)["bartik_growth"] /
                           se(fs_base)["bartik_growth"], 2), "\n")
  cat("    F-stat:", round((coef(fs_base)["bartik_growth"] /
                            se(fs_base)["bartik_growth"])^2, 1), "\n\n")
}

# First stage WITH country×year FE — the critical test
fs_cy <- tryCatch({
  feols(out_rate ~ bartik_growth | nuts3 + country^year,
        data = panel_n3[!is.na(out_rate) & !is.na(bartik_growth)],
        cluster = ~nuts3)
}, error = function(e) {
  cat("  Country×year first stage failed:", e$message, "\n")
  NULL
})

if (!is.null(fs_cy)) {
  t_stat_cy <- coef(fs_cy)["bartik_growth"] / se(fs_cy)["bartik_growth"]
  f_stat_cy <- t_stat_cy^2

  cat("  With country×year FE:\n")
  cat("    Coefficient:", round(coef(fs_cy)["bartik_growth"], 4), "\n")
  cat("    t-stat:", round(t_stat_cy, 2), "\n")
  cat("    F-stat:", round(f_stat_cy, 1), "\n\n")

  # GO/NO-GO DECISION
  cat("================================================\n")
  if (f_stat_cy > 10) {
    cat("  DECISION: GO — Track A (NUTS3 within-country)\n")
    cat("  First-stage F with country×year FE =", round(f_stat_cy, 1), "> 10\n")
    cat("  The NUTS3 Bartik has meaningful within-country variation!\n")
    decision <- "TRACK_A"
  } else if (f_stat_cy > 5) {
    cat("  DECISION: BORDERLINE — Track A with caution\n")
    cat("  First-stage F with country×year FE =", round(f_stat_cy, 1), "\n")
    cat("  Proceed with NUTS3 but flag weak instrument concern.\n")
    decision <- "TRACK_A_BORDERLINE"
  } else {
    cat("  DECISION: NO-GO — Fall back to Track B (minor revision)\n")
    cat("  First-stage F with country×year FE =", round(f_stat_cy, 1), "< 10\n")
    cat("  Insufficient within-country variation at NUTS3.\n")
    decision <- "TRACK_B"
  }
  cat("================================================\n\n")
} else {
  cat("  Cannot compute country×year first stage.\n")
  cat("  Proceeding with alternative tests...\n\n")
  decision <- "INCONCLUSIVE"
}

# ---------------------------------------------------------------
# Test 3: Cross-sectional first stage with country FE
# ---------------------------------------------------------------
cat("--- Test 3: Cross-sectional first stage (NUTS3) ---\n")

# For long-difference: does Bartik predict actual outflow across NUTS3 within countries?
if (sum(!is.na(nuts3_cross$bartik_avg) & !is.na(nuts3_cross$out_rate)) > 50) {
  fs_cross <- feols(out_rate ~ bartik_avg | country,
                     data = nuts3_cross[!is.na(out_rate) & !is.na(bartik_avg)])
  cat("  Cross-sectional (country FE):\n")
  cat("    Coefficient:", round(coef(fs_cross)["bartik_avg"], 4), "\n")
  cat("    t-stat:", round(coef(fs_cross)["bartik_avg"] /
                           se(fs_cross)["bartik_avg"], 2), "\n")
  cat("    F-stat:", round((coef(fs_cross)["bartik_avg"] /
                            se(fs_cross)["bartik_avg"])^2, 1), "\n")
  cat("    N:", nobs(fs_cross), "\n\n")

  # Also with predicted outflow rate
  if (sum(!is.na(nuts3_cross$predicted_out_rate)) > 50) {
    fs_cross2 <- feols(out_rate ~ predicted_out_rate | country,
                        data = nuts3_cross[!is.na(out_rate) & !is.na(predicted_out_rate)])
    cat("  Cross-sectional with predicted_out_rate (country FE):\n")
    cat("    Coefficient:", round(coef(fs_cross2)["predicted_out_rate"], 4), "\n")
    cat("    t-stat:", round(coef(fs_cross2)["predicted_out_rate"] /
                             se(fs_cross2)["predicted_out_rate"], 2), "\n")
    cat("    F-stat:", round((coef(fs_cross2)["predicted_out_rate"] /
                              se(fs_cross2)["predicted_out_rate"])^2, 1), "\n\n")
  }
}

# ---------------------------------------------------------------
# Test 4: How many effective NUTS3 regions per country?
# ---------------------------------------------------------------
cat("--- Test 4: NUTS3 regions per country ---\n")
regions_per_country <- nuts3_cross[!is.na(bartik_avg),
                                    .(n_regions = .N,
                                      sd_bartik = sd(bartik_avg, na.rm = TRUE)),
                                    by = country]
regions_per_country <- regions_per_country[order(-n_regions)]
cat("  Countries with NUTS3 regions (top 15):\n")
print(head(regions_per_country, 15))
cat("\n  Total NUTS3 regions with Bartik:", sum(regions_per_country$n_regions), "\n")
cat("  Countries with >10 regions:", sum(regions_per_country$n_regions > 10), "\n")

# ---------------------------------------------------------------
# Test 5: Preview of the long-difference reduced form (youth share)
# ---------------------------------------------------------------
if ("delta_youth_share" %in% names(nuts3_cross) &&
    sum(!is.na(nuts3_cross$delta_youth_share) & !is.na(nuts3_cross$bartik_avg)) > 50) {
  cat("\n--- Test 5: Long-difference reduced form (NUTS3 youth share) ---\n")

  rf_cross <- feols(delta_youth_share ~ bartik_avg | country,
                     data = nuts3_cross[!is.na(delta_youth_share) & !is.na(bartik_avg)])
  cat("  Δ(youth share 25-34) ~ bartik_avg | country FE:\n")
  cat("    Coefficient:", round(coef(rf_cross)["bartik_avg"], 4), "\n")
  cat("    t-stat:", round(coef(rf_cross)["bartik_avg"] /
                           se(rf_cross)["bartik_avg"], 2), "\n")
  cat("    N:", nobs(rf_cross), "\n\n")
} else {
  cat("\n--- Test 5: Skipped (insufficient NUTS3 youth share data) ---\n\n")
}

# ---------------------------------------------------------------
# Test 6: Compare within-country variation: NUTS3 vs NUTS2 Bartik
# ---------------------------------------------------------------
cat("--- Test 6: NUTS3 vs NUTS2 Bartik within-country variation ---\n")

# Load NUTS2 panel to compare
panel_n2 <- fread(file.path(data_dir, "nuts2_panel.csv"))

if ("bartik_growth_n3agg" %in% names(panel_n2) &&
    sum(!is.na(panel_n2$bartik_growth_n3agg)) > 100) {

  # Within-country R² for NUTS2-level Bartik
  bg_r2 <- tryCatch({
    bg_fit <- feols(bartik_growth ~ 1 | country^year,
                     data = panel_n2[!is.na(bartik_growth)])
    1 - var(resid(bg_fit)) / var(panel_n2$bartik_growth[!is.na(panel_n2$bartik_growth)])
  }, error = function(e) NA)

  # Within-country R² for NUTS3-aggregated Bartik
  n3_r2 <- tryCatch({
    n3_fit <- feols(bartik_growth_n3agg ~ 1 | country^year,
                     data = panel_n2[!is.na(bartik_growth_n3agg)])
    1 - var(resid(n3_fit)) / var(panel_n2$bartik_growth_n3agg[!is.na(panel_n2$bartik_growth_n3agg)])
  }, error = function(e) NA)

  cat("  NUTS2 Bartik: R²(country×year) =", round(bg_r2, 3),
      " → within-country share =", round(1 - bg_r2, 3), "\n")
  cat("  NUTS3-agg Bartik: R²(country×year) =", round(n3_r2, 3),
      " → within-country share =", round(1 - n3_r2, 3), "\n")
  cat("  Correlation between NUTS2 and NUTS3-agg Bartik:",
      round(cor(panel_n2$bartik_growth, panel_n2$bartik_growth_n3agg,
                use = "complete.obs"), 3), "\n\n")
}

# ---------------------------------------------------------------
# Save diagnostic results
# ---------------------------------------------------------------
diag_results <- list(
  decision = decision,
  total_var = total_var,
  within_var = if (exists("within_var")) within_var else NA,
  r2_country = if (exists("r2_country")) r2_country else NA,
  f_stat_baseline = if (!is.null(fs_base)) (coef(fs_base)["bartik_growth"] /
                                              se(fs_base)["bartik_growth"])^2 else NA,
  f_stat_country_year = if (!is.null(fs_cy)) f_stat_cy else NA,
  n_nuts3_regions = nrow(nuts3_cross[!is.na(bartik_avg)]),
  n_countries = nrow(regions_per_country)
)

saveRDS(diag_results, file.path(data_dir, "diagnostic_results.rds"))

cat("\n=== DIAGNOSTIC COMPLETE ===\n")
cat("Decision:", decision, "\n")
cat("Results saved to diagnostic_results.rds\n")
