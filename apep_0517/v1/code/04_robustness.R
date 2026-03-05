#' 04_robustness.R — Validity checks and robustness
#' Balance tests, manipulation tests, bandwidth sensitivity, placebos

source("00_packages.R")

DATA_DIR <- "../data"
bdd_panel <- fread(file.path(DATA_DIR, "bdd_panel.csv"))

cat("=== BDD panel loaded:", nrow(bdd_panel), "LSOA-years ===\n")

# ===================================================================
# 1. McCrary density test (manipulation check)
# ===================================================================
cat("\n=== 1. McCrary density test ===\n")

# Test whether LSOA density is smooth at the boundary
# Use one cross-section (latest year) to avoid repeated observations
bdd_latest <- bdd_panel[year == max(year)]

if (nrow(bdd_latest) > 100) {
  density_test <- rddensity(bdd_latest$signed_dist_km, c = 0)
  cat("  McCrary density test p-value:", round(density_test$test$p_jk, 4), "\n")
  cat("  Interpretation:", ifelse(density_test$test$p_jk > 0.05,
    "PASS - No evidence of manipulation",
    "WARNING - Potential density discontinuity"), "\n")

  density_result <- data.table(
    test = "McCrary",
    statistic = density_test$test$t_jk,
    p_value = density_test$test$p_jk,
    n_left = density_test$N[1],
    n_right = density_test$N[2]
  )
  fwrite(density_result, file.path(DATA_DIR, "mccrary_test.csv"))
}

# ===================================================================
# 2. Covariate balance at the boundary
# ===================================================================
cat("\n=== 2. Covariate balance tests ===\n")

# Test whether pre-determined covariates are smooth at the boundary
balance_vars <- c()

if ("imd_rank" %in% names(bdd_panel)) balance_vars <- c(balance_vars, "imd_rank")
if ("imd_decile" %in% names(bdd_panel)) balance_vars <- c(balance_vars, "imd_decile")

# Add pre-period crime as a balance variable
bdd_pre <- bdd_panel[year <= 2012]
if (nrow(bdd_pre) > 0) {
  balance_vars <- c(balance_vars, "log_total_crime")
}

balance_results <- list()
test_data <- if (nrow(bdd_pre) > 100) bdd_pre else bdd_latest

for (var in balance_vars) {
  y <- test_data[[var]]
  x <- test_data$signed_dist_km
  valid <- !is.na(y) & !is.na(x) & is.finite(y) & is.finite(x)

  if (sum(valid) > 50) {
    tryCatch({
      rdd_bal <- rdrobust(y = y[valid], x = x[valid], c = 0,
                          kernel = "triangular",
                          masspoints = "adjust")
      balance_results[[var]] <- data.table(
        variable = var,
        coef = rdd_bal$coef["Conventional", ],
        se = rdd_bal$se["Conventional", ],
        p_value = rdd_bal$pv["Conventional", ],
        n_eff = rdd_bal$N_h[1] + rdd_bal$N_h[2],
        period = ifelse(nrow(bdd_pre) > 100, "pre_2012", "latest")
      )
      cat("  ", var, ": coef =", round(rdd_bal$coef["Conventional", ], 4),
          ", p =", round(rdd_bal$pv["Conventional", ], 4),
          ifelse(rdd_bal$pv["Conventional", ] > 0.05, " (PASS)", " (FAIL)"), "\n")
    }, error = function(e) {
      cat("  ", var, ": FAILED (", conditionMessage(e), ")\n")
    })
  }
}

if (length(balance_results) > 0) {
  balance_dt <- rbindlist(balance_results)
  fwrite(balance_dt, file.path(DATA_DIR, "balance_tests.csv"))
}

# ===================================================================
# 3. Bandwidth sensitivity
# ===================================================================
cat("\n=== 3. Bandwidth sensitivity ===\n")

bdd_post <- bdd_panel[year >= 2015 & year <= 2023]
y_main <- bdd_post$log_total_crime
x_main <- bdd_post$signed_dist_km
valid_main <- !is.na(y_main) & !is.na(x_main) & is.finite(y_main) & is.finite(x_main)

if (sum(valid_main) > 100) {
  # Main specification uses h=2km; test sensitivity around this
  h_opt <- 2.0

  bw_multipliers <- c(0.5, 0.75, 1.0, 1.25, 1.5, 2.0)
  bw_results <- list()

  for (mult in bw_multipliers) {
    h <- h_opt * mult
    tryCatch({
      rdd_bw <- rdrobust(y = y_main[valid_main], x = x_main[valid_main], c = 0,
                         h = h, kernel = "triangular",
                         cluster = bdd_post$boundary_pair[valid_main],
                         masspoints = "adjust")
      bw_results[[as.character(mult)]] <- data.table(
        bw_multiplier = mult,
        bandwidth_km = h,
        coef = rdd_bw$coef["Conventional", ],
        se = rdd_bw$se["Conventional", ],
        p_value = rdd_bw$pv["Conventional", ],
        n_eff = rdd_bw$N_h[1] + rdd_bw$N_h[2]
      )
      cat("  BW =", round(h, 1), "km (", mult, "x): coef =",
          round(rdd_bw$coef["Conventional", ], 4), "\n")
    }, error = function(e) {
      cat("  BW =", round(h, 1), "km: FAILED\n")
    })
  }

  bw_dt <- rbindlist(bw_results)
  fwrite(bw_dt, file.path(DATA_DIR, "bandwidth_sensitivity.csv"))
}

# ===================================================================
# 4. Donut RDD (drop closest LSOAs)
# ===================================================================
cat("\n=== 4. Donut RDD ===\n")

donut_sizes <- c(0.5, 1.0, 2.0)  # km
donut_results <- list()

for (donut in donut_sizes) {
  bdd_donut <- bdd_post[abs(signed_dist_km) > donut]
  y_d <- bdd_donut$log_total_crime
  x_d <- bdd_donut$signed_dist_km
  valid_d <- !is.na(y_d) & !is.na(x_d) & is.finite(y_d) & is.finite(x_d)

  if (sum(valid_d) > 100) {
    tryCatch({
      rdd_d <- rdrobust(y = y_d[valid_d], x = x_d[valid_d], c = 0,
                        kernel = "triangular",
                        cluster = bdd_donut$boundary_pair[valid_d],
                        masspoints = "adjust")
      donut_results[[as.character(donut)]] <- data.table(
        donut_km = donut,
        coef = rdd_d$coef["Conventional", ],
        se = rdd_d$se["Conventional", ],
        p_value = rdd_d$pv["Conventional", ],
        n_eff = rdd_d$N_h[1] + rdd_d$N_h[2]
      )
      cat("  Donut =", donut, "km: coef =",
          round(rdd_d$coef["Conventional", ], 4), "\n")
    }, error = function(e) {
      cat("  Donut =", donut, "km: FAILED\n")
    })
  }
}

if (length(donut_results) > 0) {
  donut_dt <- rbindlist(donut_results)
  fwrite(donut_dt, file.path(DATA_DIR, "donut_rdd.csv"))
}

# ===================================================================
# 5. Placebo cutoffs
# ===================================================================
cat("\n=== 5. Placebo cutoffs ===\n")

placebo_cutoffs <- c(-3, -2, -1, 1, 2, 3)  # km from boundary
placebo_results <- list()

for (pc in placebo_cutoffs) {
  y_p <- bdd_post$log_total_crime
  x_p <- bdd_post$signed_dist_km
  valid_p <- !is.na(y_p) & !is.na(x_p) & is.finite(y_p) & is.finite(x_p)

  if (sum(valid_p) > 100) {
    tryCatch({
      rdd_p <- rdrobust(y = y_p[valid_p], x = x_p[valid_p], c = pc,
                        kernel = "triangular",
                        masspoints = "adjust")
      placebo_results[[as.character(pc)]] <- data.table(
        cutoff_km = pc,
        coef = rdd_p$coef["Conventional", ],
        se = rdd_p$se["Conventional", ],
        p_value = rdd_p$pv["Conventional", ]
      )
      cat("  Cutoff =", pc, "km: coef =",
          round(rdd_p$coef["Conventional", ], 4),
          ", p =", round(rdd_p$pv["Conventional", ], 4), "\n")
    }, error = function(e) {
      cat("  Cutoff =", pc, "km: FAILED\n")
    })
  }
}

if (length(placebo_results) > 0) {
  placebo_dt <- rbindlist(placebo_results)
  fwrite(placebo_dt, file.path(DATA_DIR, "placebo_cutoffs.csv"))
}

# ===================================================================
# 6. COVID robustness (exclude 2020-2021)
# ===================================================================
cat("\n=== 6. COVID robustness ===\n")

bdd_nocovid <- bdd_panel[year >= 2015 & year <= 2023 & !(year %in% c(2020, 2021))]
y_nc <- bdd_nocovid$log_total_crime
x_nc <- bdd_nocovid$signed_dist_km
valid_nc <- !is.na(y_nc) & !is.na(x_nc) & is.finite(y_nc) & is.finite(x_nc)

if (sum(valid_nc) > 100) {
  tryCatch({
    rdd_nc <- rdrobust(y = y_nc[valid_nc], x = x_nc[valid_nc], c = 0,
                       h = 2,
                       kernel = "triangular",
                       cluster = bdd_nocovid$boundary_pair[valid_nc],
                       masspoints = "adjust")
    cat("  Excluding COVID: coef =", round(rdd_nc$coef["Conventional", ], 4),
        ", se =", round(rdd_nc$se["Conventional", ], 4), "\n")

    covid_result <- data.table(
      specification = "exclude_2020_2021",
      coef = rdd_nc$coef["Conventional", ],
      se = rdd_nc$se["Conventional", ],
      p_value = rdd_nc$pv["Conventional", ],
      n_eff = rdd_nc$N_h[1] + rdd_nc$N_h[2]
    )
    fwrite(covid_result, file.path(DATA_DIR, "covid_robustness.csv"))
  }, error = function(e) {
    cat("  COVID robustness: FAILED\n")
  })
}

# ===================================================================
# 7. Heterogeneity by cut differential
# ===================================================================
cat("\n=== 7. Heterogeneity by cut size ===\n")

# Split boundary pairs by size of differential cut
median_diff <- median(bdd_post$cut_differential, na.rm = TRUE)

for (label in c("high_diff", "low_diff")) {
  if (label == "high_diff") {
    subset_data <- bdd_post[cut_differential > median_diff]
  } else {
    subset_data <- bdd_post[cut_differential <= median_diff]
  }

  y_h <- subset_data$log_total_crime
  x_h <- subset_data$signed_dist_km
  valid_h <- !is.na(y_h) & !is.na(x_h) & is.finite(y_h) & is.finite(x_h)

  if (sum(valid_h) > 50) {
    tryCatch({
      rdd_h <- rdrobust(y = y_h[valid_h], x = x_h[valid_h], c = 0,
                        h = 2,
                        kernel = "triangular",
                        masspoints = "adjust")
      cat("  ", label, ": coef =", round(rdd_h$coef["Conventional", ], 4),
          ", se =", round(rdd_h$se["Conventional", ], 4), "\n")
    }, error = function(e) {
      cat("  ", label, ": FAILED\n")
    })
  }
}

cat("\n=== Robustness checks complete ===\n")
