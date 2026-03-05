## 04_robustness.R — Robustness checks and sensitivity analysis
## apep_0519: MuKEn 2014 Building Energy Codes and Heat Pump Adoption

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))

cat("================================================================\n")
cat("  ROBUSTNESS CHECKS — MuKEn 2014 and Heat Pump Adoption\n")
cat("================================================================\n\n")

## ============================================================================
## 1. BACON DECOMPOSITION (TWFE Diagnostic)
## ============================================================================
## Decomposes the TWFE estimate into 2x2 DiD components to check for
## contamination from problematic comparisons (late-vs-early treated).

cat("=== 1. BACON DECOMPOSITION ===\n\n")

## bacondecomp requires a balanced numeric panel with binary treatment.
## Construct a clean version for the decomposition.
bacon_dt <- copy(panel)
bacon_dt[, canton_id := as.integer(factor(canton))]

## Run Bacon decomposition on the main outcome
bacon_out <- tryCatch({
  bacon(share_heat_pump ~ treated, data = as.data.frame(bacon_dt),
        id_var = "canton_id", time_var = "year")
}, error = function(e) {
  cat("  Bacon decomposition error:", conditionMessage(e), "\n")
  cat("  Attempting with unpooled = TRUE...\n")
  bacon(share_heat_pump ~ treated, data = as.data.frame(bacon_dt),
        id_var = "canton_id", time_var = "year", quietly = TRUE)
})

if (!is.null(bacon_out)) {
  ## Summarize by comparison type
  bacon_summary <- as.data.table(bacon_out)
  ## bacondecomp returns columns: treated, untreated, estimate, weight, type
  ## Keep only estimate, weight, type for aggregation
  bacon_cols <- names(bacon_summary)
  cat("  Bacon columns:", paste(bacon_cols, collapse = ", "), "\n")

  ## Ensure we have the key columns
  if (!"type" %in% bacon_cols) {
    ## Some versions name it differently — find the character column
    type_col <- bacon_cols[sapply(bacon_summary, is.character)]
    if (length(type_col) > 0) setnames(bacon_summary, type_col[1], "type")
  }

  bacon_by_type <- bacon_summary[, .(
    avg_estimate = weighted.mean(estimate, weight),
    total_weight = sum(weight),
    n_comparisons = .N
  ), by = type]

  cat("Bacon decomposition summary by comparison type:\n")
  print(bacon_by_type)
  cat("\n")

  ## Save full decomposition
  fwrite(bacon_summary, file.path(data_dir, "bacon_decomposition.csv"))
  fwrite(bacon_by_type, file.path(data_dir, "bacon_summary.csv"))

  cat("  Total TWFE estimate (weighted sum):",
      round(bacon_summary[, weighted.mean(estimate, weight)], 5), "\n\n")
} else {
  cat("  Bacon decomposition could not be computed.\n\n")
}


## ============================================================================
## 2. WILD CLUSTER BOOTSTRAP (Inference with few clusters)
## ============================================================================
## With only 26 cantons, cluster-robust SEs may be unreliable.
## Wild cluster bootstrap (Webb 6-point distribution) provides more
## reliable p-values following Cameron, Gelbach & Miller (2008).

cat("=== 2. WILD CLUSTER BOOTSTRAP ===\n\n")

## fwildclusterboot requires numeric cluster variables
panel[, canton_id := as.integer(factor(canton))]

## Main specification — use canton_id for compatibility with boottest
m_twfe <- feols(share_heat_pump ~ treated | canton_id + year, data = panel,
                cluster = ~canton_id)

## Run wild cluster bootstrap
set.seed(20260305)
boot_hp <- tryCatch({
  boottest(m_twfe, param = "treated", clustid = c("canton_id"),
           B = 9999, type = "webb", impose_null = TRUE)
}, error = function(e) {
  cat("  boottest error:", conditionMessage(e), "\n")
  cat("  Trying with Rademacher weights...\n")
  tryCatch({
    boottest(m_twfe, param = "treated", clustid = c("canton_id"),
             B = 9999, type = "rademacher", impose_null = TRUE)
  }, error = function(e2) {
    cat("  Rademacher also failed:", conditionMessage(e2), "\n")
    NULL
  })
})

cat("Wild cluster bootstrap results (share_heat_pump ~ treated):\n")
cat("  TWFE point estimate:", round(coef(m_twfe)["treated"], 5), "\n")
cat("  Cluster-robust SE:  ", round(se(m_twfe)["treated"], 5), "\n")
cat("  Cluster-robust p:   ", round(fixest::pvalue(m_twfe)["treated"], 4), "\n")

if (!is.null(boot_hp)) {
  boot_pval <- boot_hp$p_val
  boot_ci <- boot_hp$conf_int
  cat("  Bootstrap p-value:  ", round(boot_pval, 4), "\n")
  cat("  Bootstrap 95% CI:    [", round(boot_ci[1], 5), ",",
      round(boot_ci[2], 5), "]\n\n")
} else {
  boot_pval <- NA_real_
  boot_ci <- c(NA_real_, NA_real_)
  cat("  Bootstrap failed.\n\n")
}

## Also bootstrap the oil share specification
m_oil <- feols(share_oil ~ treated | canton_id + year, data = panel,
               cluster = ~canton_id)

boot_oil <- tryCatch({
  boottest(m_oil, param = "treated", clustid = c("canton_id"),
           B = 9999, type = "webb", impose_null = TRUE)
}, error = function(e) {
  cat("  Oil bootstrap error:", conditionMessage(e), "\n")
  NULL
})

cat("Wild cluster bootstrap results (share_oil ~ treated):\n")
cat("  TWFE point estimate:", round(coef(m_oil)["treated"], 5), "\n")
cat("  Cluster-robust SE:  ", round(se(m_oil)["treated"], 5), "\n")
cat("  Cluster-robust p:   ", round(fixest::pvalue(m_oil)["treated"], 4), "\n")

if (!is.null(boot_oil)) {
  cat("  Bootstrap p-value:  ", round(boot_oil$p_val, 4), "\n")
  cat("  Bootstrap 95% CI:    [", round(boot_oil$conf_int[1], 5), ",",
      round(boot_oil$conf_int[2], 5), "]\n\n")
}

## Save bootstrap results
boot_results <- data.table(
  outcome = c("share_heat_pump", "share_oil"),
  twfe_coef = c(coef(m_twfe)["treated"], coef(m_oil)["treated"]),
  cluster_se = c(se(m_twfe)["treated"], se(m_oil)["treated"]),
  cluster_pval = c(fixest::pvalue(m_twfe)["treated"],
                   fixest::pvalue(m_oil)["treated"]),
  boot_pval = c(
    ifelse(!is.null(boot_hp), boot_hp$p_val, NA_real_),
    ifelse(!is.null(boot_oil), boot_oil$p_val, NA_real_)
  ),
  boot_ci_lo = c(
    ifelse(!is.null(boot_hp), boot_hp$conf_int[1], NA_real_),
    ifelse(!is.null(boot_oil), boot_oil$conf_int[1], NA_real_)
  ),
  boot_ci_hi = c(
    ifelse(!is.null(boot_hp), boot_hp$conf_int[2], NA_real_),
    ifelse(!is.null(boot_oil), boot_oil$conf_int[2], NA_real_)
  )
)
fwrite(boot_results, file.path(data_dir, "wild_bootstrap_results.csv"))


## ============================================================================
## 3. RANDOMIZATION INFERENCE (Fisher exact test)
## ============================================================================
## Permute treatment assignment across cantons (preserving treatment timing
## structure) and re-estimate TWFE. Tests sharp null of zero effect for
## every unit. More credible than asymptotic inference with 26 clusters.

cat("=== 3. RANDOMIZATION INFERENCE ===\n\n")

set.seed(42)
n_perms <- 1000

## Extract the actual treatment assignment (canton -> adoption_year mapping)
treat_map <- unique(panel[, .(canton, adoption_year)])
actual_adoption <- treat_map$adoption_year
canton_list <- treat_map$canton

## Actual estimate
actual_coef <- coef(m_twfe)["treated"]

## Permutation loop: shuffle adoption_year assignments across cantons
perm_coefs <- numeric(n_perms)

cat("  Running", n_perms, "permutations...\n")

for (i in seq_len(n_perms)) {
  ## Randomly permute adoption years across cantons
  perm_adoption <- sample(actual_adoption)

  ## Build permuted treatment map
  perm_map <- data.table(canton = canton_list, adoption_year_perm = perm_adoption)

  ## Merge into panel and construct permuted treatment
  perm_panel <- merge(panel[, .(canton, year, share_heat_pump)],
                      perm_map, by = "canton", all.x = TRUE)
  perm_panel[, treated_perm := fifelse(
    !is.na(adoption_year_perm) & year >= adoption_year_perm, 1L, 0L
  )]

  ## Estimate TWFE with permuted treatment
  m_perm <- tryCatch({
    perm_panel[, canton_id := as.integer(factor(canton))]
    feols(share_heat_pump ~ treated_perm | canton_id + year, data = perm_panel,
          warn = FALSE, notes = FALSE)
  }, error = function(e) NULL)

  if (!is.null(m_perm) && "treated_perm" %in% names(coef(m_perm))) {
    perm_coefs[i] <- coef(m_perm)["treated_perm"]
  } else {
    perm_coefs[i] <- NA_real_
  }

  if (i %% 200 == 0) cat("    Completed", i, "of", n_perms, "permutations\n")
}

## Calculate RI p-value (two-sided)
valid_perms <- perm_coefs[!is.na(perm_coefs)]
ri_pval <- mean(abs(valid_perms) >= abs(actual_coef))

cat("\nRandomization Inference results:\n")
cat("  Actual TWFE coefficient:   ", round(actual_coef, 5), "\n")
cat("  Mean of permuted estimates:", round(mean(valid_perms), 5), "\n")
cat("  SD of permuted estimates:  ", round(sd(valid_perms), 5), "\n")
cat("  RI p-value (two-sided):    ", round(ri_pval, 4), "\n")
cat("  Valid permutations:        ", length(valid_perms), "of", n_perms, "\n\n")

## Save permutation distribution for figure
ri_results <- data.table(
  perm_id = seq_along(valid_perms),
  perm_coef = valid_perms
)
fwrite(ri_results, file.path(data_dir, "ri_permutation_dist.csv"))

## Save RI summary
ri_summary <- data.table(
  actual_coef = actual_coef,
  perm_mean = mean(valid_perms),
  perm_sd = sd(valid_perms),
  perm_p05 = quantile(valid_perms, 0.05),
  perm_p95 = quantile(valid_perms, 0.95),
  ri_pvalue = ri_pval,
  n_valid = length(valid_perms),
  n_total = n_perms
)
fwrite(ri_summary, file.path(data_dir, "ri_summary.csv"))


## ============================================================================
## 4. PLACEBO OUTCOME: WOOD HEATING SHARE
## ============================================================================
## MuKEn 2014 promotes heat pumps and restricts fossil fuels in new buildings.
## Wood heating is a renewable energy source and should NOT be directly
## targeted by the policy. A significant effect on wood would suggest
## confounding from general energy transition trends.

cat("=== 4. PLACEBO OUTCOME: WOOD HEATING SHARE ===\n\n")

m_placebo_wood <- feols(share_wood ~ treated | canton_id + year, data = panel,
                        cluster = ~canton_id)

cat("Placebo test: Wood heating share ~ treated\n")
cat("  Coefficient:", round(coef(m_placebo_wood)["treated"], 5), "\n")
cat("  SE:         ", round(se(m_placebo_wood)["treated"], 5), "\n")
cat("  p-value:    ", round(fixest::pvalue(m_placebo_wood)["treated"], 4), "\n")
cat("  Expected: NOT significant (wood is not targeted by MuKEn 2014)\n\n")

## Also test district heating as a second placebo
m_placebo_district <- feols(share_district ~ treated | canton_id + year, data = panel,
                            cluster = ~canton_id)

cat("Placebo test: District heating share ~ treated\n")
cat("  Coefficient:", round(coef(m_placebo_district)["treated"], 5), "\n")
cat("  SE:         ", round(se(m_placebo_district)["treated"], 5), "\n")
cat("  p-value:    ", round(fixest::pvalue(m_placebo_district)["treated"], 4), "\n\n")

## Save placebo results
placebo_results <- data.table(
  outcome = c("share_wood", "share_district"),
  coef = c(coef(m_placebo_wood)["treated"],
           coef(m_placebo_district)["treated"]),
  se = c(se(m_placebo_wood)["treated"],
         se(m_placebo_district)["treated"]),
  pval = c(fixest::pvalue(m_placebo_wood)["treated"],
           fixest::pvalue(m_placebo_district)["treated"]),
  significant_05 = c(fixest::pvalue(m_placebo_wood)["treated"] < 0.05,
                     fixest::pvalue(m_placebo_district)["treated"] < 0.05)
)
fwrite(placebo_results, file.path(data_dir, "placebo_results.csv"))


## ============================================================================
## 5. EXCLUDE 2022 (Energy crisis sensitivity)
## ============================================================================
## The 2022 energy crisis (Russia-Ukraine war) caused sharp increases in
## gas and oil prices, potentially accelerating heat pump adoption
## independently of MuKEn 2014. Test robustness by using only 2021 as
## the post-treatment period.

cat("=== 5. EXCLUDE 2022 (Energy Crisis Sensitivity) ===\n\n")

panel_no2022 <- panel[year != 2022]
panel_no2022[, canton_id := as.integer(factor(canton))]

## Main spec without 2022
m_no2022_hp <- feols(share_heat_pump ~ treated | canton_id + year,
                     data = panel_no2022, cluster = ~canton_id)

m_no2022_oil <- feols(share_oil ~ treated | canton_id + year,
                      data = panel_no2022, cluster = ~canton_id)

m_no2022_fossil <- feols(share_fossil ~ treated | canton_id + year,
                         data = panel_no2022, cluster = ~canton_id)

## Full sample comparison
m_full_hp <- feols(share_heat_pump ~ treated | canton_id + year,
                   data = panel, cluster = ~canton_id)

cat("Sensitivity: Excluding 2022 (energy crisis year)\n")
cat("\n  Heat pump share:\n")
cat("    Full sample:  coef =", round(coef(m_full_hp)["treated"], 5),
    " SE =", round(se(m_full_hp)["treated"], 5),
    " p =", round(fixest::pvalue(m_full_hp)["treated"], 4), "\n")
cat("    Excl. 2022:   coef =", round(coef(m_no2022_hp)["treated"], 5),
    " SE =", round(se(m_no2022_hp)["treated"], 5),
    " p =", round(fixest::pvalue(m_no2022_hp)["treated"], 4), "\n")

cat("\n  Oil share:\n")
cat("    Full sample:  coef =", round(coef(feols(share_oil ~ treated | canton + year,
                                                  data = panel, cluster = ~canton))["treated"], 5), "\n")
cat("    Excl. 2022:   coef =", round(coef(m_no2022_oil)["treated"], 5), "\n")

cat("\n  Fossil share:\n")
cat("    Full sample:  coef =", round(coef(feols(share_fossil ~ treated | canton + year,
                                                  data = panel, cluster = ~canton))["treated"], 5), "\n")
cat("    Excl. 2022:   coef =", round(coef(m_no2022_fossil)["treated"], 5), "\n\n")

## Save exclude-2022 results
excl2022_results <- data.table(
  outcome = rep(c("share_heat_pump", "share_oil", "share_fossil"), each = 2),
  sample = rep(c("Full (2009-15, 2021-22)", "Excl 2022 (2009-15, 2021)"), 3),
  coef = c(coef(m_full_hp)["treated"], coef(m_no2022_hp)["treated"],
           coef(feols(share_oil ~ treated | canton_id + year, data = panel,
                      cluster = ~canton_id))["treated"],
           coef(m_no2022_oil)["treated"],
           coef(feols(share_fossil ~ treated | canton + year, data = panel,
                      cluster = ~canton))["treated"],
           coef(m_no2022_fossil)["treated"]),
  se = c(se(m_full_hp)["treated"], se(m_no2022_hp)["treated"],
         se(feols(share_oil ~ treated | canton + year, data = panel,
                  cluster = ~canton))["treated"],
         se(m_no2022_oil)["treated"],
         se(feols(share_fossil ~ treated | canton + year, data = panel,
                  cluster = ~canton))["treated"],
         se(m_no2022_fossil)["treated"]),
  pval = c(fixest::pvalue(m_full_hp)["treated"],
           fixest::pvalue(m_no2022_hp)["treated"],
           fixest::pvalue(feols(share_oil ~ treated | canton + year, data = panel,
                                cluster = ~canton))["treated"],
           fixest::pvalue(m_no2022_oil)["treated"],
           fixest::pvalue(feols(share_fossil ~ treated | canton_id + year, data = panel,
                                cluster = ~canton_id))["treated"],
           fixest::pvalue(m_no2022_fossil)["treated"])
)
fwrite(excl2022_results, file.path(data_dir, "exclude_2022_results.csv"))


## ============================================================================
## 6. BALANCED PANEL CHECK
## ============================================================================
## Verify that results hold when restricting to cantons observed in
## every year of the panel (should be all 26, but confirm).

cat("=== 6. BALANCED PANEL CHECK ===\n\n")

## Check balance
years_available <- sort(unique(panel$year))
n_years <- length(years_available)

canton_counts <- panel[, .(n_years = uniqueN(year)), by = canton]
balanced_cantons <- canton_counts[n_years == n_years, canton]

cat("Panel balance diagnostic:\n")
cat("  Total years in panel: ", n_years, "\n")
cat("  Years:", paste(years_available, collapse = ", "), "\n")
cat("  Cantons with all years:", length(balanced_cantons), "of", uniqueN(panel$canton), "\n")

if (length(balanced_cantons) < uniqueN(panel$canton)) {
  ## Some cantons are missing years — restrict to balanced subset
  unbalanced <- canton_counts[n_years < n_years]
  cat("  Unbalanced cantons:\n")
  print(unbalanced)

  panel_balanced <- panel[canton %in% balanced_cantons]

  m_balanced_hp <- feols(share_heat_pump ~ treated | canton_id + year,
                         data = panel_balanced, cluster = ~canton_id)
  m_balanced_oil <- feols(share_oil ~ treated | canton_id + year,
                          data = panel_balanced, cluster = ~canton_id)

  cat("\n  Balanced panel results:\n")
  cat("    HP share:  coef =", round(coef(m_balanced_hp)["treated"], 5),
      " SE =", round(se(m_balanced_hp)["treated"], 5),
      " p =", round(fixest::pvalue(m_balanced_hp)["treated"], 4), "\n")
  cat("    Oil share: coef =", round(coef(m_balanced_oil)["treated"], 5),
      " SE =", round(se(m_balanced_oil)["treated"], 5),
      " p =", round(fixest::pvalue(m_balanced_oil)["treated"], 4), "\n")

  balanced_results <- data.table(
    outcome = c("share_heat_pump", "share_oil"),
    sample = "Balanced panel",
    n_cantons = length(balanced_cantons),
    coef = c(coef(m_balanced_hp)["treated"], coef(m_balanced_oil)["treated"]),
    se = c(se(m_balanced_hp)["treated"], se(m_balanced_oil)["treated"]),
    pval = c(fixest::pvalue(m_balanced_hp)["treated"],
             fixest::pvalue(m_balanced_oil)["treated"])
  )
} else {
  cat("  Panel is fully balanced — all cantons observed in all years.\n")
  cat("  Balanced panel results identical to main specification.\n")

  balanced_results <- data.table(
    outcome = c("share_heat_pump", "share_oil"),
    sample = "Balanced panel (all cantons)",
    n_cantons = length(balanced_cantons),
    coef = c(coef(m_twfe)["treated"],
             coef(m_oil)["treated"]),
    se = c(se(m_twfe)["treated"],
           se(m_oil)["treated"]),
    pval = c(fixest::pvalue(m_twfe)["treated"],
             fixest::pvalue(m_oil)["treated"])
  )
}

fwrite(balanced_results, file.path(data_dir, "balanced_panel_results.csv"))


## ============================================================================
## 7. CONSOLIDATED ROBUSTNESS SUMMARY TABLE
## ============================================================================
## Combine all robustness results into a single table for the paper.

cat("\n=== CONSOLIDATED ROBUSTNESS SUMMARY ===\n\n")

robustness_summary <- data.table(
  test = character(),
  outcome = character(),
  coef = numeric(),
  se = numeric(),
  pval = numeric(),
  ci_lo = numeric(),
  ci_hi = numeric(),
  notes = character()
)

## Row 1: Main TWFE (baseline for comparison)
robustness_summary <- rbind(robustness_summary, data.table(
  test = "Main TWFE",
  outcome = "share_heat_pump",
  coef = coef(m_twfe)["treated"],
  se = se(m_twfe)["treated"],
  pval = fixest::pvalue(m_twfe)["treated"],
  ci_lo = coef(m_twfe)["treated"] - 1.96 * se(m_twfe)["treated"],
  ci_hi = coef(m_twfe)["treated"] + 1.96 * se(m_twfe)["treated"],
  notes = "Cluster-robust SE"
))

## Row 2: Wild cluster bootstrap
robustness_summary <- rbind(robustness_summary, data.table(
  test = "Wild Cluster Bootstrap",
  outcome = "share_heat_pump",
  coef = coef(m_twfe)["treated"],
  se = NA_real_,
  pval = ifelse(!is.null(boot_hp), boot_hp$p_val, NA_real_),
  ci_lo = ifelse(!is.null(boot_hp), boot_hp$conf_int[1], NA_real_),
  ci_hi = ifelse(!is.null(boot_hp), boot_hp$conf_int[2], NA_real_),
  notes = "Webb 6-pt, 9999 reps, H0 imposed"
))

## Row 3: Randomization inference
robustness_summary <- rbind(robustness_summary, data.table(
  test = "Randomization Inference",
  outcome = "share_heat_pump",
  coef = actual_coef,
  se = sd(valid_perms),
  pval = ri_pval,
  ci_lo = quantile(valid_perms, 0.025),
  ci_hi = quantile(valid_perms, 0.975),
  notes = paste0(length(valid_perms), " permutations, two-sided")
))

## Row 4: Placebo — wood
robustness_summary <- rbind(robustness_summary, data.table(
  test = "Placebo: Wood Share",
  outcome = "share_wood",
  coef = coef(m_placebo_wood)["treated"],
  se = se(m_placebo_wood)["treated"],
  pval = fixest::pvalue(m_placebo_wood)["treated"],
  ci_lo = coef(m_placebo_wood)["treated"] - 1.96 * se(m_placebo_wood)["treated"],
  ci_hi = coef(m_placebo_wood)["treated"] + 1.96 * se(m_placebo_wood)["treated"],
  notes = "Should be insignificant"
))

## Row 5: Exclude 2022
robustness_summary <- rbind(robustness_summary, data.table(
  test = "Exclude 2022",
  outcome = "share_heat_pump",
  coef = coef(m_no2022_hp)["treated"],
  se = se(m_no2022_hp)["treated"],
  pval = fixest::pvalue(m_no2022_hp)["treated"],
  ci_lo = coef(m_no2022_hp)["treated"] - 1.96 * se(m_no2022_hp)["treated"],
  ci_hi = coef(m_no2022_hp)["treated"] + 1.96 * se(m_no2022_hp)["treated"],
  notes = "Removes energy crisis year"
))

## Row 6: Balanced panel
robustness_summary <- rbind(robustness_summary, data.table(
  test = "Balanced Panel",
  outcome = "share_heat_pump",
  coef = balanced_results[outcome == "share_heat_pump", coef],
  se = balanced_results[outcome == "share_heat_pump", se],
  pval = balanced_results[outcome == "share_heat_pump", pval],
  ci_lo = balanced_results[outcome == "share_heat_pump", coef] -
    1.96 * balanced_results[outcome == "share_heat_pump", se],
  ci_hi = balanced_results[outcome == "share_heat_pump", coef] +
    1.96 * balanced_results[outcome == "share_heat_pump", se],
  notes = paste0(balanced_results[1, n_cantons], " cantons, all years")
))

## Print and save
cat("Robustness summary table:\n")
print(robustness_summary[, .(test, coef = round(coef, 5), se = round(se, 5),
                              pval = round(pval, 4))])

fwrite(robustness_summary, file.path(data_dir, "robustness_summary.csv"))

## Save model objects for table generation
save(m_twfe, m_oil, m_placebo_wood, m_placebo_district,
     m_no2022_hp, m_no2022_oil, m_no2022_fossil,
     file = file.path(data_dir, "robustness_models.RData"))

cat("\n================================================================\n")
cat("  All robustness checks complete. Results saved to ../data/\n")
cat("================================================================\n")
