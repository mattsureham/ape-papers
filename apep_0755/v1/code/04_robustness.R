## =============================================================================
## 04_robustness.R — Robustness checks and mechanism tests
## Paper: Estrato Boundaries and Educational Sorting in Colombia (apep_0755)
## =============================================================================

source("00_packages.R")

cat("=== Robustness Checks ===\n")

## Load cleaned data
df <- fread("../data/icfes_clean.csv")

## -----------------------------------------------------------------------------
## 1. PLACEBO TEST: 5|6 boundary (built-in placebo)
##    Both estratos 5 and 6 pay surcharges (no subsidy differential)
##    Any discontinuity here = label/stigma effect, not subsidy effect
## -----------------------------------------------------------------------------
cat("\n--- Placebo: 5|6 boundary (both pay surcharges) ---\n")

bd56 <- df[estrato %in% c(5, 6)]
bd56[, treated := as.integer(estrato == 6)]

## Check if we have enough observations
valid_munis_56 <- bd56[, .(has_both = length(unique(estrato)) == 2),
                        by = cole_mcpio_ubicacion][has_both == TRUE, cole_mcpio_ubicacion]
bd56 <- bd56[cole_mcpio_ubicacion %in% valid_munis_56]

cat(sprintf("  5|6 sample: %s students, %d municipalities\n",
            format(nrow(bd56), big.mark = ","), length(valid_munis_56)))

if (nrow(bd56) >= 50) {
  placebo_56 <- feols(
    punt_global ~ treated | cole_mcpio_ubicacion,
    data = bd56,
    cluster = ~cole_mcpio_ubicacion
  )
  cat(sprintf("  Placebo effect (5|6): %.2f (SE: %.2f, p: %.3f)\n",
              coef(placebo_56)["treated"],
              se(placebo_56)["treated"],
              pvalue(placebo_56)["treated"]))
} else {
  cat("  Insufficient observations for 5|6 placebo\n")
  placebo_56 <- NULL
}

## -----------------------------------------------------------------------------
## 2. YEAR-BY-YEAR STABILITY
##    Estimate the boundary effect separately for each year
##    If estrato classification is stable, effects should be stable
## -----------------------------------------------------------------------------
cat("\n--- Year-by-year stability (3|4 boundary) ---\n")

year_results <- list()
for (yr in sort(unique(df$year))) {
  bd_yr <- df[year == yr & estrato %in% c(3, 4)]
  bd_yr[, treated := as.integer(estrato == 4)]

  valid_m <- bd_yr[, .(has_both = length(unique(estrato)) == 2),
                    by = cole_mcpio_ubicacion][has_both == TRUE, cole_mcpio_ubicacion]
  bd_yr <- bd_yr[cole_mcpio_ubicacion %in% valid_m]

  if (nrow(bd_yr) < 50) next

  reg_yr <- feols(
    punt_global ~ treated | cole_mcpio_ubicacion,
    data = bd_yr,
    cluster = ~cole_mcpio_ubicacion
  )

  year_results[[as.character(yr)]] <- data.table(
    year = yr,
    coef = coef(reg_yr)["treated"],
    se   = se(reg_yr)["treated"],
    n    = nrow(bd_yr)
  )
}

year_stability <- rbindlist(year_results)
cat("Year-by-year effects at 3|4 boundary:\n")
print(year_stability)

## -----------------------------------------------------------------------------
## 3. DONUT RDD: Exclude students at exactly the modal estrato
##    to check for potential misclassification at boundaries
## -----------------------------------------------------------------------------
cat("\n--- Donut test: Exclude schools with mixed estrato (HHI < 0.3) ---\n")

school_df <- fread("../data/school_panel.csv")

donut_results <- list()
for (k in 1:5) {
  ## Only keep schools with relatively pure estrato composition
  sd <- school_df[modal_estrato %in% c(k, k + 1) &
                  n_students >= 10]

  ## Compute estrato purity (share from modal estrato)
  pct_col <- paste0("pct_estrato_", sd$modal_estrato)
  sd[, purity := ifelse(modal_estrato == k,
                        pct_estrato_1 * (k == 1) + pct_estrato_2 * (k == 2) +
                        pct_estrato_3 * (k == 3) + pct_estrato_4 * (k == 4) +
                        pct_estrato_5 * (k == 5),
                        pct_estrato_2 * (k == 1) + pct_estrato_3 * (k == 2) +
                        pct_estrato_4 * (k == 3) + pct_estrato_5 * (k == 4) +
                        pct_estrato_6 * (k == 5))]

  ## Donut: keep only "pure" schools (>70% from modal estrato)
  sd_pure <- sd[purity > 0.7]
  sd_pure[, treated := as.integer(modal_estrato == k + 1)]

  valid_munis <- sd_pure[, .(has_both = length(unique(modal_estrato)) == 2),
                          by = municipality][has_both == TRUE, municipality]
  sd_pure <- sd_pure[municipality %in% valid_munis]

  if (nrow(sd_pure) < 20 || length(valid_munis) < 2) {
    cat(sprintf("  Boundary %d|%d: too few pure schools (%d) or municipalities\n", k, k + 1, nrow(sd_pure)))
    next
  }

  reg_donut <- tryCatch(
    feols(
      mean_global ~ treated | municipality,
      data = sd_pure,
      cluster = ~municipality
    ),
    error = function(e) { cat(sprintf("  Donut %d|%d error: %s\n", k, k+1, e$message)); NULL }
  )
  if (is.null(reg_donut)) next

  donut_results[[paste0("b", k)]] <- data.table(
    boundary = paste0(k, "|", k + 1),
    n_schools = nrow(sd_pure),
    coef = coef(reg_donut)["treated"],
    se = se(reg_donut)["treated"],
    pval = pvalue(reg_donut)["treated"]
  )

  cat(sprintf("  Boundary %d|%d: %.2f (SE: %.2f, N=%d pure schools)\n",
              k, k + 1,
              coef(reg_donut)["treated"],
              se(reg_donut)["treated"],
              nrow(sd_pure)))
}

donut_dt <- rbindlist(donut_results)

## -----------------------------------------------------------------------------
## 4. MECHANISM: School type decomposition
##    Official (public) vs Non-official (private) schools
##    If subsidy channel operates through residential sorting → public
##    schools more affected
## -----------------------------------------------------------------------------
cat("\n--- Mechanism: Official vs Non-official schools ---\n")

mech_results <- list()
for (k in c(2, 3)) {  # Focus on 2|3 and 3|4 (largest effects expected)
  for (type in c(0, 1)) {
    type_label <- ifelse(type == 1, "official", "private")
    bd <- df[estrato %in% c(k, k + 1) & official == type]
    bd[, treated := as.integer(estrato == k + 1)]

    valid_m <- bd[, .(has_both = length(unique(estrato)) == 2),
                   by = cole_mcpio_ubicacion][has_both == TRUE, cole_mcpio_ubicacion]
    bd <- bd[cole_mcpio_ubicacion %in% valid_m]

    if (nrow(bd) < 100 || length(valid_m) < 2) next

    reg_mech <- tryCatch(
      feols(
        punt_global ~ treated | cole_mcpio_ubicacion,
        data = bd,
        cluster = ~cole_mcpio_ubicacion
      ),
      error = function(e) { cat(sprintf("  Skipping %s %d|%d: %s\n", type_label, k, k+1, e$message)); NULL }
    )

    if (is.null(reg_mech)) next

    mech_results[[paste0("b", k, "_", type_label)]] <- data.table(
      boundary = paste0(k, "|", k + 1),
      school_type = type_label,
      n = nrow(bd),
      coef = coef(reg_mech)["treated"],
      se = se(reg_mech)["treated"],
      pval = pvalue(reg_mech)["treated"]
    )
  }
}

mech_dt <- rbindlist(mech_results)
cat("Mechanism decomposition (official vs private):\n")
print(mech_dt)

## -----------------------------------------------------------------------------
## 5. SUBSIDY INTENSITY TEST
##    The subsidy differential is largest at 1|2 (60% vs 40% = 20pp gap)
##    and 3|4 (15% vs 0% = 15pp gap). If the subsidy channel drives
##    sorting, effects should be monotone in subsidy intensity.
## -----------------------------------------------------------------------------
cat("\n--- Subsidy intensity correlation ---\n")

main_results <- readRDS("../data/main_results_dt.rds")

## Approximate subsidy differentials (percentage points)
subsidy_diff <- data.table(
  boundary = c("1|2", "2|3", "3|4", "4|5", "5|6"),
  subsidy_gap_pp = c(20, 25, 15, 0, 0)
  # 1→60%, 2→40%, 3→15%, 4→0%, 5→-20% surcharge, 6→-20%
  # So: 1|2 gap = 20pp, 2|3 gap = 25pp, 3|4 gap = 15pp, 4|5 and 5|6 = 0
)

intensity_test <- merge(main_results, subsidy_diff, by = "boundary")
cat("Score discontinuity vs subsidy differential:\n")
print(intensity_test[, .(boundary, coef_main, se_main, subsidy_gap_pp)])

## Rank correlation
if (nrow(intensity_test) >= 3) {
  corr <- cor(intensity_test$coef_main, intensity_test$subsidy_gap_pp,
              method = "spearman", use = "complete.obs")
  cat(sprintf("\nSpearman rank correlation (effect vs subsidy gap): %.3f\n", corr))
}

## Save all robustness results
saveRDS(list(
  placebo_56    = placebo_56,
  year_stability = year_stability,
  donut         = donut_dt,
  mechanism     = mech_dt,
  intensity     = intensity_test
), "../data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
