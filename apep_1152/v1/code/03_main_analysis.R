## 03_main_analysis.R — The Stranded Signal (apep_1152)
source(file.path(here::here(), "output", "apep_1152", "v1", "code", "00_packages.R"))
DATA_DIR <- file.path(here::here(), "output", "apep_1152", "v1", "data")

panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
cat(sprintf("Panel: %d obs, %d generators\n", nrow(panel), length(unique(panel$gen_key))))

# =============================================================================
# A. CALLAWAY-SANT'ANNA DiD
# =============================================================================
cat("\n=== A. CALLAWAY-SANT'ANNA DiD ===\n")

# Prepare for did package
# g = group (year of CES adoption), 0 = never treated
# t = year
# yname = retired_this_year (binary)
# idname = generator ID (numeric)

# Create numeric ID for generators
panel[, gen_num := as.integer(as.factor(gen_key))]

# Run CS DiD
cs_result <- tryCatch({
  att_gt(
    yname = "retired_this_year",
    tname = "year",
    idname = "gen_num",
    gname = "g",
    data = as.data.frame(panel[g != 0 | year <= 2024]),  # include never-treated (g=0)
    control_group = "notyettreated",
    anticipation = 0,
    est_method = "dr",  # doubly-robust
    clustervars = "state",
    print_details = FALSE
  )
}, error = function(e) {
  cat(sprintf("CS DiD error: %s\n", e$message))
  NULL
})

if (!is.null(cs_result)) {
  # Aggregate to overall ATT
  agg_overall <- aggte(cs_result, type = "simple")
  cat(sprintf("CS DiD Overall ATT: %.4f (SE: %.4f, p=%.4f)\n",
              agg_overall$overall.att, agg_overall$overall.se,
              2 * pnorm(-abs(agg_overall$overall.att / agg_overall$overall.se))))

  # Dynamic (event study) aggregation
  agg_dynamic <- aggte(cs_result, type = "dynamic", min_e = -6, max_e = 5)
  cat("\nEvent study coefficients:\n")
  es_dt <- data.table(
    e = agg_dynamic$egt,
    att = agg_dynamic$att.egt,
    se = agg_dynamic$se.egt
  )
  es_dt[, `:=`(ci_lo = att - 1.96 * se, ci_hi = att + 1.96 * se)]
  print(es_dt)

  # Group-level aggregation
  agg_group <- aggte(cs_result, type = "group")
  cat("\nGroup-level ATTs:\n")
  grp_dt <- data.table(
    g = agg_group$egt,
    att = agg_group$att.egt,
    se = agg_group$se.egt,
    n = sapply(agg_group$egt, function(gg) nrow(panel[g == gg & year == gg]))
  )
  print(grp_dt)
}

# =============================================================================
# B. TWFE (for comparison — expected to be biased)
# =============================================================================
cat("\n=== B. TWFE (biased benchmark) ===\n")

twfe <- feols(retired_this_year ~ post_ces | gen_num + year,
              data = panel, cluster = ~state)
cat(sprintf("TWFE coefficient: %.4f (SE: %.4f)\n",
            coef(twfe)["post_ces"], se(twfe)["post_ces"]))

# =============================================================================
# C. BALANCE TESTS
# =============================================================================
cat("\n=== C. BALANCE TESTS ===\n")

# Test: Do CES states have different generator characteristics?
panel_baseline <- panel[year == 2008]
panel_baseline[, ces_state := as.integer(ces_year > 0)]

bal_cap <- feols(capacity_mw ~ ces_state, data = panel_baseline)
cat(sprintf("Capacity (CES vs no-CES): %.1f MW difference (p=%.4f)\n",
            coef(bal_cap)["ces_state"], pvalue(bal_cap)["ces_state"]))

bal_vintage <- feols(vintage ~ ces_state, data = panel_baseline)
cat(sprintf("Vintage (CES vs no-CES): %.1f years difference (p=%.4f)\n",
            coef(bal_vintage)["ces_state"], pvalue(bal_vintage)["ces_state"]))

# =============================================================================
# D. HETEROGENEITY
# =============================================================================
cat("\n=== D. HETEROGENEITY ===\n")

# By generator size
panel[, large_gen := as.integer(capacity_mw >= 200)]
for (size in c(0, 1)) {
  lab <- if (size == 1) "Large (>=200 MW)" else "Small (<200 MW)"
  dt_sub <- panel[large_gen == size]
  twfe_sub <- tryCatch({
    feols(retired_this_year ~ post_ces | gen_num + year,
          data = dt_sub, cluster = ~state)
  }, error = function(e) NULL)
  if (!is.null(twfe_sub)) {
    cat(sprintf("  %s (N=%d): %.4f (SE: %.4f)\n",
                lab, nrow(dt_sub),
                coef(twfe_sub)["post_ces"], se(twfe_sub)["post_ces"]))
  }
}

# =============================================================================
# E. PLACEBO: GAS GENERATORS
# =============================================================================
cat("\n=== E. PLACEBO: GAS GENERATORS ===\n")
cat("  (Would require separate gas generator data download — deferred to robustness)\n")

# =============================================================================
# SAVE RESULTS
# =============================================================================
cat("\n=== SAVING RESULTS ===\n")

# Update diagnostics
diag <- list(
  n_treated = sum(panel$ces_year > 0 & panel$year == max(panel$year)),
  n_pre = length(unique(panel$year[panel$year < 2015])),
  n_obs = nrow(panel),
  cs_att = if (!is.null(cs_result)) agg_overall$overall.att else NA,
  cs_se = if (!is.null(cs_result)) agg_overall$overall.se else NA,
  twfe_coef = unname(coef(twfe)["post_ces"]),
  twfe_se = unname(se(twfe)["post_ces"])
)
writeLines(toJSON(diag, auto_unbox = TRUE, pretty = TRUE),
           file.path(DATA_DIR, "diagnostics.json"))

save(cs_result, agg_overall, agg_dynamic, agg_group, twfe,
     file = file.path(DATA_DIR, "main_results.RData"))
cat("Results saved.\n")
