# 03_main_analysis.R — Multi-threshold bunching estimation
# APEP-1150: The Regulatory Anatomy of US Hospitals
#
# Estimates excess mass at 25, 50, and 100 bed thresholds
# Decomposes regulatory bunching from round-number heaping

source("00_packages.R")

dt <- fread("../data/hospital_bed_panel_clean.csv")
freq <- fread("../data/bed_frequency.csv")

# ============================================================
# 1. BUNCHING ESTIMATION FUNCTION
# ============================================================
# Following Kleven (2016), Chetty et al. (2011)
# Fits polynomial to empirical distribution excluding manipulation window
# Estimates excess mass relative to counterfactual

estimate_bunching <- function(freq_data, threshold, window_below, window_above,
                              poly_degree = 7, range_low = NULL, range_high = NULL,
                              n_boot = 200) {
  # freq_data: data.table with columns 'beds' and 'count'
  # threshold: the notch/kink point
  # window_below: number of bins below threshold to exclude
  # window_above: number of bins above threshold to exclude
  # poly_degree: degree of polynomial for counterfactual
  # range_low/high: estimation range

  if (is.null(range_low)) range_low <- max(1, threshold - 30)
  if (is.null(range_high)) range_high <- threshold + 30

  # Ensure all bed counts in range are represented
  all_beds <- data.table(beds = range_low:range_high)
  fd <- merge(all_beds, freq_data, by = "beds", all.x = TRUE)
  fd[is.na(count), count := 0]
  fd <- fd[order(beds)]

  # Mark manipulation window
  fd[, excluded := beds >= (threshold - window_below) & beds <= (threshold + window_above)]

  # Polynomial regression on non-excluded bins
  fd[, z := beds - threshold]  # center at threshold
  fd_est <- fd[excluded == FALSE]

  if (nrow(fd_est) < poly_degree + 1) {
    warning("Insufficient non-excluded bins for polynomial estimation")
    return(NULL)
  }

  # Fit polynomial
  formula_str <- paste0("count ~ ", paste(sprintf("I(z^%d)", 1:poly_degree), collapse = " + "))
  fit <- lm(as.formula(formula_str), data = fd_est)

  # Predict counterfactual for all bins
  fd[, counterfactual := predict(fit, newdata = fd)]
  fd[counterfactual < 0, counterfactual := 0]

  # Excess mass in manipulation window
  excess <- fd[excluded == TRUE, sum(count - counterfactual)]
  avg_cf <- fd[excluded == TRUE, mean(counterfactual)]
  excess_normalized <- excess / avg_cf  # standard bunching statistic b

  # Excess mass at the threshold point specifically
  excess_at_point <- fd[beds == threshold, count - counterfactual]

  # Missing mass (hole above threshold)
  missing <- fd[beds > threshold & beds <= (threshold + window_above),
                sum(counterfactual - count)]

  # ---- Bootstrap standard errors ----
  boot_b <- numeric(n_boot)
  for (b_iter in seq_len(n_boot)) {
    # Resample counts with Poisson noise
    fd_boot <- copy(fd)
    fd_boot[, count_boot := rpois(.N, lambda = pmax(count, 1))]

    fd_est_boot <- fd_boot[excluded == FALSE]
    fit_boot <- tryCatch(
      lm(as.formula(formula_str), data = fd_est_boot[, .(count = count_boot, z)]),
      error = function(e) NULL
    )
    if (is.null(fit_boot)) { boot_b[b_iter] <- NA; next }

    fd_boot[, cf_boot := predict(fit_boot, newdata = fd_boot[, .(z)])]
    fd_boot[cf_boot < 0, cf_boot := 0]

    excess_boot <- fd_boot[excluded == TRUE, sum(count_boot - cf_boot)]
    avg_cf_boot <- fd_boot[excluded == TRUE, mean(cf_boot)]
    boot_b[b_iter] <- excess_boot / max(avg_cf_boot, 1)
  }

  se_b <- sd(boot_b, na.rm = TRUE)

  list(
    threshold = threshold,
    excess_mass = excess,
    normalized_b = excess_normalized,
    se_b = se_b,
    excess_at_point = excess_at_point,
    missing_mass = missing,
    avg_counterfactual = avg_cf,
    data = fd,
    fit = fit
  )
}

# ============================================================
# 2. ESTIMATE BUNCHING AT EACH THRESHOLD
# ============================================================
cat("=== Multi-Threshold Bunching Estimation ===\n\n")

# --- 25-bed threshold (CAH) ---
# Use ALL hospitals — the bunching at 25 is primarily CAH
freq_all <- freq[hospital_type == "All"]

cat("--- 25-Bed Threshold (CAH) ---\n")
bunch_25 <- estimate_bunching(freq_all, threshold = 25,
                               window_below = 2, window_above = 3,
                               poly_degree = 7, range_low = 5, range_high = 55)
cat(sprintf("  Excess mass: %.0f hospital-years\n", bunch_25$excess_mass))
cat(sprintf("  Normalized b: %.2f (SE: %.2f)\n", bunch_25$normalized_b, bunch_25$se_b))
cat(sprintf("  Excess at 25: %.0f\n", bunch_25$excess_at_point))
cat(sprintf("  Missing mass (26-28): %.0f\n", bunch_25$missing_mass))

# --- 25-bed threshold (non-CAH only — round-number heaping benchmark) ---
freq_nc <- freq[hospital_type == "Non-CAH"]

cat("\n--- 25-Bed Threshold (Non-CAH — Heaping Benchmark) ---\n")
bunch_25_nc <- estimate_bunching(freq_nc, threshold = 25,
                                  window_below = 2, window_above = 3,
                                  poly_degree = 7, range_low = 5, range_high = 55)
cat(sprintf("  Excess mass: %.0f hospital-years\n", bunch_25_nc$excess_mass))
cat(sprintf("  Normalized b: %.2f (SE: %.2f)\n", bunch_25_nc$normalized_b, bunch_25_nc$se_b))

# --- 50-bed threshold (RHC/REH) --- non-CAH only
cat("\n--- 50-Bed Threshold (RHC/REH) ---\n")
bunch_50 <- estimate_bunching(freq_nc, threshold = 50,
                               window_below = 2, window_above = 3,
                               poly_degree = 7, range_low = 20, range_high = 80)
cat(sprintf("  Excess mass: %.0f hospital-years\n", bunch_50$excess_mass))
cat(sprintf("  Normalized b: %.2f (SE: %.2f)\n", bunch_50$normalized_b, bunch_50$se_b))
cat(sprintf("  Excess at 50: %.0f\n", bunch_50$excess_at_point))

# --- 100-bed threshold (DSH) --- non-CAH only
cat("\n--- 100-Bed Threshold (DSH) ---\n")
bunch_100 <- estimate_bunching(freq_nc, threshold = 100,
                                window_below = 3, window_above = 3,
                                poly_degree = 7, range_low = 60, range_high = 140)
cat(sprintf("  Excess mass: %.0f hospital-years\n", bunch_100$excess_mass))
cat(sprintf("  Normalized b: %.2f (SE: %.2f)\n", bunch_100$normalized_b, bunch_100$se_b))
cat(sprintf("  Excess at 100: %.0f\n", bunch_100$excess_at_point))

# ============================================================
# 3. ROUND-NUMBER HEAPING DECOMPOSITION
# ============================================================
cat("\n=== Round-Number Heaping Decomposition ===\n")

# Estimate heaping at non-regulatory multiples of 10 (non-CAH)
# Use 30, 40, 60, 70, 80 as benchmarks (10 and 20 are too close to 25-bed cliff)
heaping_thresholds <- c(30, 40, 60, 70, 80)
heaping_results <- list()

for (ht in heaping_thresholds) {
  res <- estimate_bunching(freq_nc, threshold = ht,
                           window_below = 1, window_above = 1,
                           poly_degree = 5,
                           range_low = max(10, ht - 20),
                           range_high = ht + 20,
                           n_boot = 200)
  if (!is.null(res)) {
    heaping_results[[as.character(ht)]] <- res
    cat(sprintf("  Heaping at %d beds: b=%.2f (SE=%.2f), excess=%.0f\n",
                ht, res$normalized_b, res$se_b, res$excess_mass))
  }
}

# Average heaping statistic at non-regulatory round numbers
avg_heaping_b <- mean(sapply(heaping_results, function(x) x$normalized_b))
se_avg_heaping <- sd(sapply(heaping_results, function(x) x$normalized_b)) / sqrt(length(heaping_results))
cat(sprintf("\nAverage heaping b (non-regulatory round-10): %.2f (SE: %.2f)\n",
            avg_heaping_b, se_avg_heaping))

# Regulatory-specific excess at each threshold
cat("\n=== Regulatory-Specific Bunching (Total - Heaping) ===\n")

# At 25 beds: regulatory = all-hospital bunching minus non-CAH heaping
reg_25_b <- bunch_25$normalized_b - bunch_25_nc$normalized_b
cat(sprintf("  25 beds (CAH): Total b=%.2f, Non-CAH heaping=%.2f, CAH-specific=%.2f\n",
            bunch_25$normalized_b, bunch_25_nc$normalized_b, reg_25_b))

# At 50 beds: regulatory = observed bunching minus average heaping
reg_50_b <- bunch_50$normalized_b - avg_heaping_b
cat(sprintf("  50 beds (RHC/REH): Total b=%.2f, Heaping=%.2f, Regulatory=%.2f\n",
            bunch_50$normalized_b, avg_heaping_b, reg_50_b))

# At 100 beds: regulatory = observed bunching minus average heaping
reg_100_b <- bunch_100$normalized_b - avg_heaping_b
cat(sprintf("  100 beds (DSH): Total b=%.2f, Heaping=%.2f, Regulatory=%.2f\n",
            bunch_100$normalized_b, avg_heaping_b, reg_100_b))

# ============================================================
# 4. TEMPORAL ANALYSIS — bunching over time
# ============================================================
cat("\n=== Temporal Analysis ===\n")

# Year-specific bunching at 25 beds (all hospitals)
yearly_bunch_25 <- list()
for (yr in sort(unique(dt$fiscal_year))) {
  yr_freq <- dt[fiscal_year == yr, .(count = .N), by = beds]
  res <- estimate_bunching(yr_freq, threshold = 25,
                           window_below = 2, window_above = 3,
                           poly_degree = 7, range_low = 5, range_high = 55,
                           n_boot = 100)
  if (!is.null(res)) {
    yearly_bunch_25[[as.character(yr)]] <- data.table(
      year = yr, b = res$normalized_b, se = res$se_b,
      excess = res$excess_mass, at_25 = res$excess_at_point
    )
  }
}
yearly_25 <- rbindlist(yearly_bunch_25)
cat("Year-by-year bunching at 25 beds:\n")
print(yearly_25)

# Year-specific bunching at 50 beds (non-CAH)
yearly_bunch_50 <- list()
for (yr in sort(unique(dt$fiscal_year))) {
  yr_freq <- dt[fiscal_year == yr & is_cah == FALSE, .(count = .N), by = beds]
  res <- estimate_bunching(yr_freq, threshold = 50,
                           window_below = 2, window_above = 3,
                           poly_degree = 7, range_low = 20, range_high = 80,
                           n_boot = 100)
  if (!is.null(res)) {
    yearly_bunch_50[[as.character(yr)]] <- data.table(
      year = yr, b = res$normalized_b, se = res$se_b,
      excess = res$excess_mass
    )
  }
}
yearly_50 <- rbindlist(yearly_bunch_50)
cat("\nYear-by-year bunching at 50 beds (non-CAH):\n")
print(yearly_50)

# ============================================================
# 5. PLACEBO TESTS
# ============================================================
cat("\n=== Placebo Tests ===\n")

# Placebo 1: Urban hospitals at 25 beds (should NOT bunch — not CAH-eligible)
freq_urban <- dt[is_urban_stac == TRUE, .(count = .N), by = beds]
bunch_25_urban <- estimate_bunching(freq_urban, threshold = 25,
                                     window_below = 2, window_above = 3,
                                     poly_degree = 7, range_low = 5, range_high = 55,
                                     n_boot = 200)
cat(sprintf("Placebo: Urban STAC at 25 beds: b=%.2f (SE=%.2f)\n",
            bunch_25_urban$normalized_b, bunch_25_urban$se_b))

# Placebo 2: Non-regulatory round numbers (already computed above)
cat("Placebo: Non-regulatory round-10 bunching (non-CAH):\n")
for (ht in names(heaping_results)) {
  r <- heaping_results[[ht]]
  cat(sprintf("  %s beds: b=%.2f (SE=%.2f)\n", ht, r$normalized_b, r$se_b))
}

# Placebo 3: Bunching at 15 beds (old CAH limit, pre-2003)
bunch_15 <- estimate_bunching(freq_all, threshold = 15,
                               window_below = 2, window_above = 2,
                               poly_degree = 5, range_low = 3, range_high = 35,
                               n_boot = 200)
cat(sprintf("\nPlacebo: 15 beds (historical CAH limit): b=%.2f (SE=%.2f)\n",
            bunch_15$normalized_b, bunch_15$se_b))

# ============================================================
# 6. SAVE RESULTS AND DIAGNOSTICS
# ============================================================

# Diagnostics for validation
diagnostics <- list(
  n_treated = uniqueN(dt[beds == 25]$provider_id) +
              uniqueN(dt[beds == 50 & is_cah == FALSE]$provider_id) +
              uniqueN(dt[beds == 100 & is_cah == FALSE]$provider_id),
  n_pre = length(unique(dt$fiscal_year)),  # Cross-sectional pooled, all years are "pre"
  n_obs = nrow(dt)
)
write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

# Save bunching estimates for table generation
results <- list(
  bunch_25 = list(threshold = 25, program = "CAH", sample = "All",
                  b = bunch_25$normalized_b, se = bunch_25$se_b,
                  excess = bunch_25$excess_mass,
                  excess_at_point = bunch_25$excess_at_point),
  bunch_25_nc = list(threshold = 25, program = "Heaping", sample = "Non-CAH",
                     b = bunch_25_nc$normalized_b, se = bunch_25_nc$se_b,
                     excess = bunch_25_nc$excess_mass),
  bunch_50 = list(threshold = 50, program = "RHC/REH", sample = "Non-CAH",
                  b = bunch_50$normalized_b, se = bunch_50$se_b,
                  excess = bunch_50$excess_mass,
                  excess_at_point = bunch_50$excess_at_point),
  bunch_100 = list(threshold = 100, program = "DSH", sample = "Non-CAH",
                   b = bunch_100$normalized_b, se = bunch_100$se_b,
                   excess = bunch_100$excess_mass,
                   excess_at_point = bunch_100$excess_at_point),
  avg_heaping = list(b = avg_heaping_b, se = se_avg_heaping),
  reg_specific = list(
    cah_25 = reg_25_b,
    rhc_50 = reg_50_b,
    dsh_100 = reg_100_b
  ),
  yearly_25 = yearly_25,
  yearly_50 = yearly_50,
  placebo_urban_25 = list(b = bunch_25_urban$normalized_b, se = bunch_25_urban$se_b),
  placebo_15 = list(b = bunch_15$normalized_b, se = bunch_15$se_b)
)

saveRDS(results, "../data/bunching_results.rds")
cat("\nResults saved to ../data/bunching_results.rds\n")
cat("Diagnostics saved to ../data/diagnostics.json\n")

# Print final summary
cat("\n" %+% strrep("=", 60) %+% "\n")
cat("SUMMARY: Multi-Threshold Bunching Estimates\n")
cat(strrep("=", 60) %+% "\n")
cat(sprintf("%-15s %8s %8s %10s %10s\n", "Threshold", "b", "SE(b)", "Excess", "Reg-Spec"))
cat(strrep("-", 60) %+% "\n")
cat(sprintf("%-15s %8.2f %8.2f %10.0f %10.2f\n",
            "25 beds (CAH)", bunch_25$normalized_b, bunch_25$se_b,
            bunch_25$excess_mass, reg_25_b))
cat(sprintf("%-15s %8.2f %8.2f %10.0f %10.2f\n",
            "25 beds (heap)", bunch_25_nc$normalized_b, bunch_25_nc$se_b,
            bunch_25_nc$excess_mass, NA_real_))
cat(sprintf("%-15s %8.2f %8.2f %10.0f %10.2f\n",
            "50 beds (RHC)", bunch_50$normalized_b, bunch_50$se_b,
            bunch_50$excess_mass, reg_50_b))
cat(sprintf("%-15s %8.2f %8.2f %10.0f %10.2f\n",
            "100 beds (DSH)", bunch_100$normalized_b, bunch_100$se_b,
            bunch_100$excess_mass, reg_100_b))
cat(strrep("-", 60) %+% "\n")
cat(sprintf("%-15s %8.2f %8.2f\n",
            "Avg heaping", avg_heaping_b, se_avg_heaping))
cat(strrep("=", 60) %+% "\n")
