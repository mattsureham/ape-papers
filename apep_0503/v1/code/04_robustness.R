## ============================================================================
## 04_robustness.R — RDD validity tests and robustness checks
## apep_0503: DPE Energy Labels + Rental Ban Multi-Cutoff RDD
## ============================================================================

source("00_packages.R")

DATA_DIR <- "../data"
RESULTS_DIR <- "../tables"
FIGURES_DIR <- "../figures"
dir.create(RESULTS_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(FIGURES_DIR, showWarnings = FALSE, recursive = TRUE)

cat("=== Loading analysis data ===\n")
analysis <- arrow::read_parquet(file.path(DATA_DIR, "analysis.parquet"))

## ============================================================================
## TEST 1: McCrary density tests
## ============================================================================

cat("\n=== McCrary Density Tests ===\n")

density_results <- list()

for (cut_name in names(DPE_ENERGY_CUTS)) {
  cut_val <- DPE_ENERGY_CUTS[cut_name]
  df_cut <- analysis %>% filter(nearest_cutoff == cut_name)

  if (nrow(df_cut) < 200) next

  tryCatch({
    dens_test <- rddensity(
      X = df_cut$energy_kwh_m2,
      c = cut_val,
      kernel = "triangular"
    )

    density_results[[cut_name]] <- tibble(
      cutoff = cut_name,
      cutoff_value = cut_val,
      n = nrow(df_cut),
      t_stat = dens_test$test$t_jk,
      p_value = dens_test$test$p_jk,
      manipulation = ifelse(dens_test$test$p_jk < 0.05, "YES", "NO")
    )

    cat(sprintf("  %s (%d kWh): t=%.3f, p=%.4f %s\n",
                cut_name, cut_val,
                dens_test$test$t_jk, dens_test$test$p_jk,
                ifelse(dens_test$test$p_jk < 0.05, "** BUNCHING DETECTED **", "")))

  }, error = function(e) {
    cat(sprintf("  %s: density test failed: %s\n", cut_name, e$message))
  })
}

density_table <- bind_rows(density_results)
write_csv(density_table, file.path(RESULTS_DIR, "mccrary_tests.csv"))

## ============================================================================
## TEST 2: Covariate balance at cutoffs
## ============================================================================

cat("\n=== Covariate Balance Tests ===\n")

covariates <- c("surface_reelle_bati", "nombre_pieces_principales", "property_age")
balance_results <- list()

for (cut_name in names(DPE_ENERGY_CUTS)) {
  cut_val <- DPE_ENERGY_CUTS[cut_name]
  df_cut <- analysis %>% filter(nearest_cutoff == cut_name)

  if (nrow(df_cut) < 200) next

  for (cov in covariates) {
    if (!(cov %in% names(df_cut)) || sum(!is.na(df_cut[[cov]])) < 100) next

    tryCatch({
      bal_fit <- rdrobust(
        y = df_cut[[cov]],
        x = df_cut$energy_kwh_m2,
        c = cut_val,
        kernel = "triangular",
        p = 1,
        bwselect = "mserd"
      )

      balance_results[[paste(cut_name, cov)]] <- tibble(
        cutoff = cut_name,
        covariate = cov,
        estimate = bal_fit$coef[1],
        se_bc = bal_fit$se[3],
        pval = bal_fit$pv[3]
      )

    }, error = function(e) {
      # Skip silently
    })
  }
}

balance_table <- bind_rows(balance_results)
if (nrow(balance_table) > 0) {
  cat("\nCovariate balance results:\n")
  print(balance_table %>%
          mutate(across(c(estimate, se_bc, pval), ~round(., 4))) %>%
          mutate(balanced = ifelse(pval > 0.05, "YES", "NO")))
  write_csv(balance_table, file.path(RESULTS_DIR, "covariate_balance.csv"))
}

## ============================================================================
## TEST 3: Bandwidth sensitivity
## ============================================================================

cat("\n=== Bandwidth Sensitivity ===\n")

bw_results <- list()
bw_multipliers <- c(0.5, 0.75, 1.0, 1.25, 1.5, 2.0)

for (cut_name in c("F", "E", "D", "C")) {
  cut_val <- DPE_ENERGY_CUTS[cut_name]
  df_cut <- analysis %>% filter(nearest_cutoff == cut_name)

  if (nrow(df_cut) < 200) next

  # Get optimal bandwidth first
  rdd_opt <- rdrobust(
    y = df_cut$log_price_m2,
    x = df_cut$energy_kwh_m2,
    c = cut_val, kernel = "triangular", p = 1, bwselect = "mserd"
  )
  bw_opt <- rdd_opt$bws[1, 1]
  b_opt <- rdd_opt$bws[1, 2]  # bias bandwidth

  for (mult in bw_multipliers) {
    bw_use <- bw_opt * mult
    b_use <- b_opt * mult  # maintain h/b ratio

    tryCatch({
      rdd_bw <- rdrobust(
        y = df_cut$log_price_m2,
        x = df_cut$energy_kwh_m2,
        c = cut_val, kernel = "triangular", p = 1,
        h = bw_use, b = b_use
      )

      bw_results[[paste(cut_name, mult)]] <- tibble(
        cutoff = cut_name,
        bw_multiplier = mult,
        bandwidth = bw_use,
        n_effective = rdd_bw$N_h[1] + rdd_bw$N_h[2],
        estimate = -rdd_bw$coef[1],  # Negated: below - above
        se_bc = rdd_bw$se[3],
        pval = rdd_bw$pv[3],
        se_conv = rdd_bw$se[1],
        pval_conv = rdd_bw$pv[1]
      )
    }, error = function(e) {
      # Skip
    })
  }
}

bw_table <- bind_rows(bw_results)
if (nrow(bw_table) > 0) {
  write_csv(bw_table, file.path(RESULTS_DIR, "bandwidth_sensitivity.csv"))
  cat("  Saved bandwidth sensitivity results\n")
}

## ============================================================================
## TEST 4: Donut RDD
## ============================================================================

cat("\n=== Donut RDD ===\n")

donut_results <- list()
donut_widths <- c(0, 3, 5, 10)  # kWh/m² to exclude on each side

for (cut_name in c("F", "E", "D")) {
  cut_val <- DPE_ENERGY_CUTS[cut_name]
  df_cut <- analysis %>% filter(nearest_cutoff == cut_name)

  if (nrow(df_cut) < 200) next

  for (donut in donut_widths) {
    df_donut <- df_cut %>%
      filter(abs(energy_kwh_m2 - cut_val) > donut)

    if (nrow(df_donut) < 200) next

    tryCatch({
      rdd_donut <- rdrobust(
        y = df_donut$log_price_m2,
        x = df_donut$energy_kwh_m2,
        c = cut_val, kernel = "triangular", p = 1, bwselect = "mserd"
      )

      donut_results[[paste(cut_name, donut)]] <- tibble(
        cutoff = cut_name,
        donut_width = donut,
        n_effective = rdd_donut$N_h[1] + rdd_donut$N_h[2],
        estimate = -rdd_donut$coef[1],  # Negated: below - above
        se_bc = rdd_donut$se[3],
        pval = rdd_donut$pv[3]
      )

      cat(sprintf("  %s donut=%d: effect=%.4f (SE=%.4f)\n",
                  cut_name, donut, rdd_donut$coef[1], rdd_donut$se[3]))

    }, error = function(e) {
      # Skip
    })
  }
}

donut_table <- bind_rows(donut_results)
if (nrow(donut_table) > 0) {
  write_csv(donut_table, file.path(RESULTS_DIR, "donut_rdd.csv"))
}

## ============================================================================
## TEST 5: Placebo cutoffs
## ============================================================================

cat("\n=== Placebo Cutoff Tests ===\n")

# Test at midpoints between real cutoffs
placebo_cutoffs <- c(90, 145, 215, 290, 375, 460)
placebo_results <- list()

for (pc in placebo_cutoffs) {
  # Find the real cutoff this placebo is nearest to
  nearest_real <- names(DPE_ENERGY_CUTS)[which.min(abs(DPE_ENERGY_CUTS - pc))]
  df_placebo <- analysis %>% filter(nearest_cutoff == nearest_real)

  if (nrow(df_placebo) < 200) next

  tryCatch({
    rdd_placebo <- rdrobust(
      y = df_placebo$log_price_m2,
      x = df_placebo$energy_kwh_m2,
      c = pc, kernel = "triangular", p = 1, bwselect = "mserd"
    )

    placebo_results[[as.character(pc)]] <- tibble(
      cutoff = pc,
      type = "placebo",
      n_effective = rdd_placebo$N_h[1] + rdd_placebo$N_h[2],
      estimate = -rdd_placebo$coef[1],  # Negated: below - above
      se_bc = rdd_placebo$se[3],
      pval = rdd_placebo$pv[3]
    )

    cat(sprintf("  Placebo at %d: effect=%.4f (p=%.4f)\n",
                pc, rdd_placebo$coef[1], rdd_placebo$pv[3]))

  }, error = function(e) {
    # Skip
  })
}

placebo_table <- bind_rows(placebo_results)
if (nrow(placebo_table) > 0) {
  write_csv(placebo_table, file.path(RESULTS_DIR, "placebo_cutoffs.csv"))
}

## ============================================================================
## TEST 6: Polynomial order sensitivity
## ============================================================================

cat("\n=== Polynomial Order Sensitivity ===\n")

poly_results <- list()

for (cut_name in c("F", "E", "D")) {
  cut_val <- DPE_ENERGY_CUTS[cut_name]
  df_cut <- analysis %>% filter(nearest_cutoff == cut_name)

  if (nrow(df_cut) < 200) next

  for (poly_order in c(1, 2)) {
    tryCatch({
      rdd_poly <- rdrobust(
        y = df_cut$log_price_m2,
        x = df_cut$energy_kwh_m2,
        c = cut_val, kernel = "triangular",
        p = poly_order, bwselect = "mserd"
      )

      poly_results[[paste(cut_name, poly_order)]] <- tibble(
        cutoff = cut_name,
        polynomial = poly_order,
        estimate = -rdd_poly$coef[1],  # Negated: below - above
        se_bc = rdd_poly$se[3],
        pval = rdd_poly$pv[3]
      )
    }, error = function(e) {
      # Skip
    })
  }
}

poly_table <- bind_rows(poly_results)
if (nrow(poly_table) > 0) {
  write_csv(poly_table, file.path(RESULTS_DIR, "polynomial_sensitivity.csv"))
}

## ============================================================================
## TEST 7: Transaction volume RDD (displacement test)
## ============================================================================

cat("\n=== Transaction Volume RDD (Displacement Test) ===\n")

# Aggregate transaction counts by energy score bins (1 kWh wide)
vol_by_score <- analysis %>%
  filter(nearest_cutoff == "F") %>%
  group_by(energy_bin = round(energy_kwh_m2)) %>%
  summarise(n_transactions = n(), .groups = "drop")

if (nrow(vol_by_score) > 50) {
  tryCatch({
    rdd_vol <- rdrobust(
      y = vol_by_score$n_transactions,
      x = vol_by_score$energy_bin,
      c = 420,
      kernel = "triangular",
      p = 1,
      bwselect = "mserd"
    )

    cat(sprintf("  Volume discontinuity at G/F: effect=%.2f (SE=%.2f, p=%.4f)\n",
                rdd_vol$coef[1], rdd_vol$se[3], rdd_vol$pv[3]))

    volume_result <- tibble(
      test = "volume_gf",
      estimate = rdd_vol$coef[1],
      se_bc = rdd_vol$se[3],
      pval = rdd_vol$pv[3]
    )
    write_csv(volume_result, file.path(RESULTS_DIR, "volume_rdd.csv"))

  }, error = function(e) {
    cat(sprintf("  Volume RDD failed: %s\n", e$message))
  })
}

cat("\n=== All robustness checks complete ===\n")
