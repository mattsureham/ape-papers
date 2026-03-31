## 00_bunching_estimator.R — Unified Kleven-Waseem Bunching Estimator
## apep_0727 v4: Single estimator used by ALL analysis scripts
##
## Design decisions (per duet/lessons.md):
##   - Integer bins: as.integer(floor(x * 10)) — never float division
##   - Degree 7 baseline (adjustable per call)
##   - 500 bootstrap replications
##   - Returns: bunching_ratio, excess_mass, missing_mass, mass_balance, f0

# ============================================================
# CORE ESTIMATOR (integer bins)
# ============================================================

bunching_estimate_int <- function(bin_data,
                                   kink_int = 100L,
                                   excl_lower = 90L,
                                   excl_upper = 110L,
                                   window_lower = 30L,
                                   window_upper = 199L,
                                   poly_degree = 7L) {
  bd <- copy(bin_data[bin_int >= window_lower & bin_int <= window_upper])
  bd[, excluded := bin_int >= excl_lower & bin_int < excl_upper]
  bd[, z := bin_int - kink_int]

  for (p in 1:poly_degree) {
    bd[, paste0("z", p) := z^p]
  }

  formula_str <- paste0("count ~ ",
                         paste(paste0("z", 1:poly_degree), collapse = " + "))
  fit <- lm(as.formula(formula_str), data = bd[excluded == FALSE])
  bd[, counterfactual := pmax(predict(fit, newdata = bd), 0)]

  # Excess mass: observed - counterfactual in excluded zone

  excess_mass <- sum(bd[excluded == TRUE, count - counterfactual])

  # Counterfactual density at threshold for bunching ratio
  f0 <- bd[bin_int == kink_int, counterfactual]
  if (length(f0) == 0 || is.na(f0) || f0 <= 0) {
    f0 <- mean(bd[excluded == FALSE]$counterfactual)
  }
  bunching_ratio <- excess_mass / f0

  # Missing mass: counterfactual - observed ABOVE threshold within exclusion
  missing_above <- bd[bin_int >= kink_int & bin_int < excl_upper]
  missing_mass <- sum(missing_above$counterfactual - missing_above$count)

  # Mass balance: excess_below / missing_above (should be ~1 if well-specified)
  mass_balance <- if (missing_mass > 0) excess_mass / missing_mass else NA_real_

  # Extended missing mass in wider windows (for welfare)
  missing_10_12 <- sum(bd[bin_int >= kink_int & bin_int < 120L,
                           counterfactual - count])
  missing_10_13 <- sum(bd[bin_int >= kink_int & bin_int < 130L,
                           counterfactual - count])

  list(
    excess_mass = excess_mass,
    missing_mass = missing_mass,
    mass_balance = mass_balance,
    missing_10_12 = missing_10_12,
    missing_10_13 = missing_10_13,
    bunching_ratio = bunching_ratio,
    f0 = f0,
    poly_degree = poly_degree,
    excl_lower = excl_lower,
    excl_upper = excl_upper,
    bin_data = bd
  )
}

# ============================================================
# BOOTSTRAP (integer bins)
# ============================================================

bootstrap_bunching_int <- function(dt_raw,
                                    kink_int = 100L,
                                    excl_lower = 90L,
                                    excl_upper = 110L,
                                    window_lower = 30L,
                                    window_upper = 199L,
                                    poly_degree = 7L,
                                    n_boot = 500L,
                                    subset_expr = NULL,
                                    all_bins = NULL) {
  # Subset if needed
  dt_sub <- dt_raw[capacity_kwp >= (window_lower / 10) &
                    capacity_kwp < ((window_upper + 1) / 10)]
  if (!is.null(subset_expr)) {
    dt_sub <- dt_sub[eval(subset_expr)]
  }

  N <- nrow(dt_sub)
  if (N < 500) {
    return(list(se_bunching = NA_real_, ci_lower = NA_real_, ci_upper = NA_real_,
                se_excess = NA_real_, boot_ratios = numeric(0)))
  }

  if (is.null(all_bins)) {
    all_bins <- data.table(bin_int = seq(window_lower, window_upper, by = 1L))
  }

  boot_ratios <- numeric(n_boot)
  boot_excess <- numeric(n_boot)

  for (b_idx in 1:n_boot) {
    idx <- sample.int(N, N, replace = TRUE)
    boot_dt <- dt_sub[idx]
    boot_bins <- boot_dt[, .(count = .N),
                          by = .(bin_int = as.integer(floor(capacity_kwp * 10)))]
    boot_bins <- merge(all_bins, boot_bins, by = "bin_int", all.x = TRUE)
    boot_bins[is.na(count), count := 0L]

    boot_est <- tryCatch(
      bunching_estimate_int(boot_bins,
                            kink_int = kink_int,
                            excl_lower = excl_lower,
                            excl_upper = excl_upper,
                            window_lower = window_lower,
                            window_upper = window_upper,
                            poly_degree = poly_degree),
      error = function(e) NULL
    )

    if (!is.null(boot_est)) {
      boot_ratios[b_idx] <- boot_est$bunching_ratio
      boot_excess[b_idx] <- boot_est$excess_mass
    } else {
      boot_ratios[b_idx] <- NA_real_
      boot_excess[b_idx] <- NA_real_
    }
  }

  list(
    se_bunching = sd(boot_ratios, na.rm = TRUE),
    ci_lower = quantile(boot_ratios, 0.025, na.rm = TRUE),
    ci_upper = quantile(boot_ratios, 0.975, na.rm = TRUE),
    se_excess = sd(boot_excess, na.rm = TRUE),
    boot_ratios = boot_ratios
  )
}

# ============================================================
# HELPER: Create bin counts from raw data
# ============================================================

make_bins_int <- function(dt_sub, all_bins = NULL,
                           window_lower = 30L, window_upper = 199L) {
  if (is.null(all_bins)) {
    all_bins <- data.table(bin_int = seq(window_lower, window_upper, by = 1L))
  }
  bins <- dt_sub[, .(count = .N),
                  by = .(bin_int = as.integer(floor(capacity_kwp * 10)))]
  bins <- merge(all_bins, bins, by = "bin_int", all.x = TRUE)
  bins[is.na(count), count := 0L]
  bins
}

cat("Unified bunching estimator loaded (integer bins, degree 7 default, 500 boot).\n")
