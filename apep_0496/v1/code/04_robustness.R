## =============================================================================
## 04_robustness.R — Robustness checks and placebo tests
## apep_0496: Education Priority Labels and Housing Markets in France
## =============================================================================

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

## ---------------------------------------------------------------------------
## 1. Load data
## ---------------------------------------------------------------------------

cat("=== Loading data ===\n")

dt <- readRDS(file.path(data_dir, "analysis_data.rds"))
dt_near <- dt[abs(dist_signed) <= 2000]
dt_near[, log_price_m2 := log(price_m2)]

cat("Analysis sample:", format(nrow(dt_near), big.mark = ","), "\n")

## ---------------------------------------------------------------------------
## 2. McCrary density test at boundary
## ---------------------------------------------------------------------------

cat("\n=== McCrary Density Test ===\n")

density_test <- rddensity(dt_near$dist_signed, c = 0)
cat("McCrary density test:\n")
summary(density_test)

density_result <- data.table(
  test = "McCrary density",
  T_stat = density_test$test$t_jk,
  p_value = density_test$test$p_jk,
  n_left = density_test$N[1],
  n_right = density_test$N[2]
)
cat("T-statistic:", round(density_test$test$t_jk, 3),
    "p-value:", round(density_test$test$p_jk, 3), "\n")

## ---------------------------------------------------------------------------
## 3. Covariate balance at boundary
## ---------------------------------------------------------------------------

cat("\n=== Covariate Balance Tests ===\n")

covariates <- c("surface_reelle_bati", "nombre_pieces_principales")
covariates <- covariates[covariates %in% names(dt_near)]

balance_results <- data.table()

for (cov in covariates) {
  dt_cov <- dt_near[!is.na(get(cov))]
  if (nrow(dt_cov) < 500) next

  rdd_cov <- tryCatch({
    rdrobust(y = dt_cov[[cov]], x = dt_cov$dist_signed,
             c = 0, kernel = "triangular", bwselect = "mserd")
  }, error = function(e) NULL)

  if (!is.null(rdd_cov)) {
    balance_results <- rbind(balance_results, data.table(
      covariate = cov,
      coef = rdd_cov$coef["Conventional", ],
      se = rdd_cov$se["Conventional", ],
      p_value = 2 * pnorm(-abs(rdd_cov$coef["Conventional", ] /
                                 rdd_cov$se["Conventional", ])),
      bw = rdd_cov$bws["h", "left"]
    ))
    cat(cov, ": coef =", round(rdd_cov$coef["Conventional", ], 3),
        "p =", round(2 * pnorm(-abs(rdd_cov$coef["Conventional", ] /
                                       rdd_cov$se["Conventional", ])), 3), "\n")
  }
}

# Property type composition
dt_near[, is_apt := as.integer(type_local == "Appartement")]
rdd_type <- tryCatch({
  rdrobust(y = dt_near$is_apt, x = dt_near$dist_signed,
           c = 0, kernel = "triangular", bwselect = "mserd")
}, error = function(e) NULL)

if (!is.null(rdd_type)) {
  balance_results <- rbind(balance_results, data.table(
    covariate = "pct_apartment",
    coef = rdd_type$coef["Conventional", ],
    se = rdd_type$se["Conventional", ],
    p_value = 2 * pnorm(-abs(rdd_type$coef["Conventional", ] /
                               rdd_type$se["Conventional", ])),
    bw = rdd_type$bws["h", "left"]
  ))
  cat("pct_apartment: coef =", round(rdd_type$coef["Conventional", ], 3),
      "p =", round(2 * pnorm(-abs(rdd_type$coef["Conventional", ] /
                                     rdd_type$se["Conventional", ])), 3), "\n")
}

fwrite(balance_results, file.path(tables_dir, "covariate_balance.csv"))

## ---------------------------------------------------------------------------
## 4. Bandwidth sensitivity
## ---------------------------------------------------------------------------

cat("\n=== Bandwidth Sensitivity ===\n")

main_rdd <- rdrobust(y = dt_near$log_price_m2, x = dt_near$dist_signed,
                     c = 0, kernel = "triangular", bwselect = "mserd")
h_opt <- main_rdd$bws["h", "left"]

bw_multiples <- c(0.5, 0.75, 1.0, 1.25, 1.5, 2.0)
bw_results <- data.table()

for (mult in bw_multiples) {
  bw <- h_opt * mult
  rdd_bw <- tryCatch({
    rdrobust(y = dt_near$log_price_m2, x = dt_near$dist_signed,
             c = 0, kernel = "triangular", h = bw)
  }, error = function(e) NULL)

  if (!is.null(rdd_bw)) {
    bw_results <- rbind(bw_results, data.table(
      bw_multiple = mult,
      bandwidth = bw,
      coef = rdd_bw$coef["Conventional", ],
      se = rdd_bw$se["Conventional", ],
      ci_lower = rdd_bw$ci["Conventional", 1],
      ci_upper = rdd_bw$ci["Conventional", 2],
      n_eff = rdd_bw$N_h[1] + rdd_bw$N_h[2]
    ))
    cat("  h =", round(bw, 0), "m (", mult, "x): coef =",
        round(rdd_bw$coef["Conventional", ], 4), "\n")
  }
}

fwrite(bw_results, file.path(tables_dir, "bandwidth_sensitivity.csv"))

## ---------------------------------------------------------------------------
## 5. Donut specifications
## ---------------------------------------------------------------------------

cat("\n=== Donut Specifications ===\n")

donut_sizes <- c(50, 100, 200, 500)
donut_results <- data.table()

for (d in donut_sizes) {
  dt_donut <- dt_near[abs(dist_signed) >= d]
  if (nrow(dt_donut) < 500) next

  rdd_donut <- tryCatch({
    rdrobust(y = dt_donut$log_price_m2, x = dt_donut$dist_signed,
             c = 0, kernel = "triangular", bwselect = "mserd")
  }, error = function(e) NULL)

  if (!is.null(rdd_donut)) {
    donut_results <- rbind(donut_results, data.table(
      donut_m = d,
      coef = rdd_donut$coef["Conventional", ],
      se = rdd_donut$se["Conventional", ],
      n_eff = rdd_donut$N_h[1] + rdd_donut$N_h[2]
    ))
    cat("  Donut", d, "m: coef =",
        round(rdd_donut$coef["Conventional", ], 4), "\n")
  }
}

fwrite(donut_results, file.path(tables_dir, "donut_specifications.csv"))

## ---------------------------------------------------------------------------
## 6. Alternative kernel (uniform)
## ---------------------------------------------------------------------------

cat("\n=== Uniform Kernel ===\n")

rdd_uniform <- tryCatch({
  rdrobust(y = dt_near$log_price_m2, x = dt_near$dist_signed,
           c = 0, kernel = "uniform", bwselect = "mserd")
}, error = function(e) NULL)

if (!is.null(rdd_uniform)) {
  cat("Uniform kernel: coef =",
      round(rdd_uniform$coef["Conventional", ], 4),
      "SE =", round(rdd_uniform$se["Conventional", ], 4), "\n")
}

## ---------------------------------------------------------------------------
## 7. PLACEBO: Shifted boundary
## ---------------------------------------------------------------------------

cat("\n=== Placebo: Shifted Boundaries ===\n")

# Test at placebo cutoffs away from 0
placebo_cutoffs <- c(-500, -250, 250, 500)
placebo_results <- data.table()

for (pc in placebo_cutoffs) {
  rdd_placebo <- tryCatch({
    rdrobust(y = dt_near$log_price_m2, x = dt_near$dist_signed,
             c = pc, kernel = "triangular", bwselect = "mserd")
  }, error = function(e) NULL)

  if (!is.null(rdd_placebo)) {
    placebo_results <- rbind(placebo_results, data.table(
      cutoff = pc,
      coef = rdd_placebo$coef["Conventional", ],
      se = rdd_placebo$se["Conventional", ],
      p_value = 2 * pnorm(-abs(rdd_placebo$coef["Conventional", ] /
                                  rdd_placebo$se["Conventional", ]))
    ))
    cat("  Placebo c =", pc, "m: coef =",
        round(rdd_placebo$coef["Conventional", ], 4),
        "p =", round(2 * pnorm(-abs(rdd_placebo$coef["Conventional", ] /
                                       rdd_placebo$se["Conventional", ])), 3), "\n")
  }
}

fwrite(placebo_results, file.path(tables_dir, "placebo_cutoffs.csv"))

## ---------------------------------------------------------------------------
## 8. Exclude Île-de-France
## ---------------------------------------------------------------------------

cat("\n=== Excluding Île-de-France ===\n")

idf_depts <- c("75", "77", "78", "91", "92", "93", "94", "95")
dt_no_idf <- dt_near[!code_departement %in% idf_depts]

if (nrow(dt_no_idf) > 500) {
  rdd_no_idf <- tryCatch({
    rdrobust(y = dt_no_idf$log_price_m2, x = dt_no_idf$dist_signed,
             c = 0, kernel = "triangular", bwselect = "mserd")
  }, error = function(e) NULL)

  if (!is.null(rdd_no_idf)) {
    cat("Excluding IDF: coef =",
        round(rdd_no_idf$coef["Conventional", ], 4),
        "SE =", round(rdd_no_idf$se["Conventional", ], 4), "\n")
  }
}

## ---------------------------------------------------------------------------
## 9. REP+ vs REP (intensive margin)
## ---------------------------------------------------------------------------

cat("\n=== REP+ vs REP (Intensive Margin) ===\n")

dt_rep_only <- dt[nearest_rep_status %in% c("REP", "REP+") & abs(dist_signed) <= 2000]
if (nrow(dt_rep_only) > 500) {
  dt_rep_only[, log_price_m2 := log(price_m2)]
  dt_rep_only[, is_rep_plus := as.integer(nearest_rep_status == "REP+")]

  m_intensive <- tryCatch({
    feols(log_price_m2 ~ is_rep_plus + dist_signed + I(dist_signed^2) |
            year + code_departement,
          data = dt_rep_only, cluster = ~code_commune)
  }, error = function(e) NULL)

  if (!is.null(m_intensive)) {
    cat("REP+ vs REP coefficient:\n")
    summary(m_intensive)
  }
}

## ---------------------------------------------------------------------------
## 10. Save all robustness results
## ---------------------------------------------------------------------------

cat("\n=== Saving robustness results ===\n")

robustness <- list(
  density_test = density_result,
  balance = balance_results,
  bandwidth = bw_results,
  donut = donut_results,
  placebo = placebo_results,
  uniform_kernel = if (!is.null(rdd_uniform)) {
    data.table(coef = rdd_uniform$coef["Conventional", ],
               se = rdd_uniform$se["Conventional", ])
  },
  excl_idf = if (exists("rdd_no_idf") && !is.null(rdd_no_idf)) {
    data.table(coef = rdd_no_idf$coef["Conventional", ],
               se = rdd_no_idf$se["Conventional", ])
  }
)

saveRDS(robustness, file.path(data_dir, "robustness_results.rds"))
cat("Robustness results saved.\n")
