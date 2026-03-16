## 04_robustness.R — Validity checks and robustness
## APEP Paper apep_0706: FPM Fiscal Windfalls and Homicide Rates

source("00_packages.R")

cat("=== Robustness and Validity Checks ===\n")

rdd_data <- readRDS("../data/rdd_analysis.rds")
main_results <- readRDS("../data/main_results.rds")
main_bw <- main_results$pooled$bw

# ─────────────────────────────────────────────────────────────────────
# 1. McCrary Density Test
# ─────────────────────────────────────────────────────────────────────
cat("\n--- McCrary Density Test (rddensity) ---\n")

density_test <- rddensity(rdd_data$running_var, c = 0)
cat(sprintf("McCrary test: T-stat = %.3f, p-value = %.4f\n",
            density_test$test$t_jk, density_test$test$p_jk))

if (density_test$test$p_jk < 0.05) {
  cat("WARNING: Density discontinuity detected at threshold!\n")
} else {
  cat("PASS: No evidence of manipulation at threshold.\n")
}

density_result <- list(
  t_stat = density_test$test$t_jk,
  p_value = density_test$test$p_jk,
  n_left = density_test$N[1],
  n_right = density_test$N[2]
)

# ─────────────────────────────────────────────────────────────────────
# 2. Covariate Balance (Pre-determined characteristics)
# ─────────────────────────────────────────────────────────────────────
cat("\n--- Covariate Balance at Threshold ---\n")

# Use available covariates: region, state, population itself
# For a proper balance test, we check if pre-determined characteristics
# jump at the threshold

# Test whether log(population) is smooth
# (This is mechanical near threshold, so instead test geographic covariates)

# State composition should be smooth
# Test: fraction in each region

balance_vars <- c("mean_population")
balance_results <- list()

for (v in balance_vars) {
  if (v %in% names(rdd_data) && sum(!is.na(rdd_data[[v]])) > 100) {
    rd_bal <- tryCatch(
      rdrobust(
        y = rdd_data[[v]],
        x = rdd_data$running_var,
        kernel = "triangular",
        bwselect = "mserd",
        all = TRUE
      ),
      error = function(e) NULL
    )

    if (!is.null(rd_bal)) {
      balance_results[[v]] <- data.frame(
        variable = v,
        coef = rd_bal$coef[1],
        se = rd_bal$se[3],
        pval = rd_bal$pv[3]
      )
      cat(sprintf("  %s: coef = %.3f (SE = %.3f, p = %.3f)\n",
                  v, rd_bal$coef[1], rd_bal$se[3], rd_bal$pv[3]))
    }
  }
}

# ─────────────────────────────────────────────────────────────────────
# 3. Bandwidth Sensitivity
# ─────────────────────────────────────────────────────────────────────
cat("\n--- Bandwidth Sensitivity ---\n")

bw_multipliers <- c(0.5, 0.75, 1.0, 1.25, 1.5, 2.0)
bw_results <- list()

for (mult in bw_multipliers) {
  bw_test <- main_bw * mult
  rd_bw <- tryCatch(
    rdrobust(
      y = rdd_data$mean_homicide_rate,
      x = rdd_data$running_var,
      h = bw_test,
      kernel = "triangular",
      cluster = rdd_data$state_code,
      all = TRUE
    ),
    error = function(e) NULL
  )

  if (!is.null(rd_bw)) {
    bw_results[[as.character(mult)]] <- data.frame(
      multiplier = mult,
      bandwidth = bw_test,
      coef = rd_bw$coef[1],
      se_robust = rd_bw$se[3],
      pval = rd_bw$pv[3],
      n_eff = rd_bw$N_h[1] + rd_bw$N_h[2]
    )
    cat(sprintf("  BW × %.2f (h = %.0f): coef = %.3f (SE = %.3f, p = %.3f, N = %d)\n",
                mult, bw_test, rd_bw$coef[1], rd_bw$se[3], rd_bw$pv[3],
                rd_bw$N_h[1] + rd_bw$N_h[2]))
  }
}

bw_df <- bind_rows(bw_results)

# ─────────────────────────────────────────────────────────────────────
# 4. Donut-Hole RDD (exclude ±500 of threshold)
# ─────────────────────────────────────────────────────────────────────
cat("\n--- Donut-Hole RDD ---\n")

donut_sizes <- c(200, 500, 1000)
donut_results <- list()

for (d in donut_sizes) {
  sub_donut <- rdd_data %>% filter(abs(running_var) >= d)

  rd_donut <- tryCatch(
    rdrobust(
      y = sub_donut$mean_homicide_rate,
      x = sub_donut$running_var,
      kernel = "triangular",
      bwselect = "mserd",
      cluster = sub_donut$state_code,
      all = TRUE
    ),
    error = function(e) NULL
  )

  if (!is.null(rd_donut)) {
    donut_results[[as.character(d)]] <- data.frame(
      donut = d,
      coef = rd_donut$coef[1],
      se_robust = rd_donut$se[3],
      pval = rd_donut$pv[3],
      n_eff = rd_donut$N_h[1] + rd_donut$N_h[2]
    )
    cat(sprintf("  Donut ±%d: coef = %.3f (SE = %.3f, p = %.3f)\n",
                d, rd_donut$coef[1], rd_donut$se[3], rd_donut$pv[3]))
  }
}

donut_df <- bind_rows(donut_results)

# ─────────────────────────────────────────────────────────────────────
# 5. Placebo Cutoffs
# ─────────────────────────────────────────────────────────────────────
cat("\n--- Placebo Cutoffs ---\n")

# Test at midpoints between real thresholds
real_thresholds <- c(10189, 13585, 16981, 23773, 30564, 37356,
                     44148, 50940, 61128, 71316, 81504, 91692,
                     101880, 115464, 129048, 142632, 156216)

placebo_cutoffs <- (real_thresholds[-length(real_thresholds)] +
                      real_thresholds[-1]) / 2

placebo_results <- list()

for (i in seq_along(placebo_cutoffs)) {
  pc <- placebo_cutoffs[i]

  # Recompute running variable centered at placebo cutoff
  rdd_data$placebo_rv <- rdd_data$mean_population - pc
  rdd_data$placebo_above <- as.integer(rdd_data$mean_population > pc)

  # Only use municipalities NOT near a real threshold
  # (within ±2000 of the placebo cutoff but NOT near a real one)
  near_real <- sapply(rdd_data$mean_population, function(p) {
    min(abs(p - real_thresholds)) < 2000
  })
  sub_placebo <- rdd_data %>% filter(!near_real)

  rd_plac <- tryCatch(
    rdrobust(
      y = sub_placebo$mean_homicide_rate,
      x = sub_placebo$placebo_rv,
      kernel = "triangular",
      bwselect = "mserd",
      all = TRUE
    ),
    error = function(e) NULL
  )

  if (!is.null(rd_plac)) {
    placebo_results[[as.character(i)]] <- data.frame(
      placebo_idx = i,
      placebo_cutoff = pc,
      coef = rd_plac$coef[1],
      se_robust = rd_plac$se[3],
      pval = rd_plac$pv[3]
    )
    cat(sprintf("  Placebo at %.0f: coef = %.3f (SE = %.3f, p = %.3f)\n",
                pc, rd_plac$coef[1], rd_plac$se[3], rd_plac$pv[3]))
  }
}

placebo_df <- bind_rows(placebo_results)

# ─────────────────────────────────────────────────────────────────────
# 6. Placebo Outcome (non-homicide external deaths, if available)
# ─────────────────────────────────────────────────────────────────────
cat("\n--- Placebo Outcome ---\n")

if (file.exists("../data/external_deaths_raw.rds")) {
  ext_df <- readRDS("../data/external_deaths_raw.rds")

  if (exists("homicide_df")) {
    homicide_df <- readRDS("../data/homicides_raw.rds")
    # Non-homicide external deaths = external - homicide
    ext_merged <- ext_df %>%
      left_join(homicide_df %>% select(mun_code6, year, homicides),
                by = c("mun_code6", "year")) %>%
      mutate(
        homicides = ifelse(is.na(homicides), 0, homicides),
        non_homicide_ext = external_deaths - homicides
      )

    pop_df <- readRDS("../data/population_raw.rds")
    ext_merged <- ext_merged %>%
      left_join(pop_df %>% select(mun_code6, year, population),
                by = c("mun_code6", "year")) %>%
      filter(!is.na(population), population > 0) %>%
      mutate(non_hom_rate = (non_homicide_ext / population) * 100000)

    # Average across years
    placebo_out <- ext_merged %>%
      group_by(mun_code6) %>%
      summarise(mean_non_hom_rate = mean(non_hom_rate, na.rm = TRUE),
                .groups = "drop")

    placebo_out <- placebo_out %>%
      left_join(readRDS("../data/population_brackets.rds") %>%
                  select(mun_code6, running_var, above_threshold, state_code),
                by = "mun_code6") %>%
      filter(!is.na(running_var))

    rd_placebo_out <- tryCatch(
      rdrobust(
        y = placebo_out$mean_non_hom_rate,
        x = placebo_out$running_var,
        kernel = "triangular",
        bwselect = "mserd",
        all = TRUE
      ),
      error = function(e) NULL
    )

    if (!is.null(rd_placebo_out)) {
      cat(sprintf("Placebo outcome (non-homicide external deaths):\n"))
      cat(sprintf("  coef = %.3f (SE = %.3f, p = %.3f)\n",
                  rd_placebo_out$coef[1], rd_placebo_out$se[3], rd_placebo_out$pv[3]))
    }
  }
} else {
  cat("No external deaths data available for placebo outcome test.\n")
}

# ─────────────────────────────────────────────────────────────────────
# 7. Save all robustness results
# ─────────────────────────────────────────────────────────────────────
robustness <- list(
  density = density_result,
  bandwidth_sensitivity = bw_df,
  donut = donut_df,
  placebo_cutoffs = placebo_df,
  balance = bind_rows(balance_results)
)

saveRDS(robustness, "../data/robustness_results.rds")
cat("\n=== Robustness checks complete ===\n")
