## 03_main_analysis.R — Bunching estimation and McCrary tests
## APEP Working Paper apep_1067

source("00_packages.R")

data_dir <- "../data"
nbi <- fread(file.path(data_dir, "nbi_clean.csv"))

cat(sprintf("Loaded %s bridge-year observations\n", format(nrow(nbi), big.mark = ",")))

# ============================================================
# 1. BUNCHING ESTIMATION AT SR=50
# ============================================================

# Polynomial counterfactual density (Kleven 2016 approach)
# Estimate smooth polynomial on integer SR bins, excluding manipulation region
# Manipulation region: [46, 53] (conservative window around 50)

estimate_bunching <- function(dt, exclude_lower = 46, exclude_upper = 53,
                              threshold = 50, poly_order = 7,
                              bin_range = c(10, 90)) {
  # Count bridges per integer SR bin
  counts <- dt[sr_int >= bin_range[1] & sr_int <= bin_range[2],
               .(count = .N), by = sr_int][order(sr_int)]

  # Ensure all bins present
  all_bins <- data.table(sr_int = bin_range[1]:bin_range[2])
  counts <- merge(all_bins, counts, by = "sr_int", all.x = TRUE)
  counts[is.na(count), count := 0]

  # Indicator for exclusion region
  counts[, excluded := sr_int >= exclude_lower & sr_int <= exclude_upper]
  counts[, below_threshold := sr_int < threshold]

  # Fit polynomial on non-excluded bins
  fit_data <- counts[excluded == FALSE]
  poly_fit <- lm(count ~ poly(sr_int, poly_order), data = fit_data)

  # Predict counterfactual for ALL bins
  counts[, counterfactual := predict(poly_fit, newdata = counts)]

  # Bunching: excess mass below threshold in manipulation region
  bunching_region <- counts[excluded == TRUE]
  below_50 <- bunching_region[sr_int < threshold]
  above_50 <- bunching_region[sr_int >= threshold]

  excess_below <- sum(below_50$count) - sum(below_50$counterfactual)
  deficit_above <- sum(above_50$counterfactual) - sum(above_50$count)

  # Normalized excess mass (relative to counterfactual height at threshold)
  h0 <- counts[sr_int == threshold, counterfactual]
  b_hat <- excess_below / h0

  # Standard error via bootstrap (done separately in robustness)
  list(
    counts = counts,
    excess_below = excess_below,
    deficit_above = deficit_above,
    b_hat = b_hat,
    h0 = h0,
    n_total = sum(counts$count),
    n_bunching_region = sum(bunching_region$count)
  )
}

# --- Full sample bunching ---
cat("\n=== FULL SAMPLE BUNCHING ===\n")
full_bunch <- estimate_bunching(nbi)
cat(sprintf("Excess mass below 50: %s bridges\n", format(round(full_bunch$excess_below), big.mark = ",")))
cat(sprintf("Deficit above 50: %s bridges\n", format(round(full_bunch$deficit_above), big.mark = ",")))
cat(sprintf("Normalized excess mass (b̂): %.3f\n", full_bunch$b_hat))

# --- Pre-MAP-21 vs Post-MAP-21 ---
cat("\n=== PRE vs POST MAP-21 ===\n")
pre_bunch <- estimate_bunching(nbi[post_map21 == 0])
post_bunch <- estimate_bunching(nbi[post_map21 == 1])

cat(sprintf("Pre-MAP-21 (2000-2012):  b̂ = %.3f\n", pre_bunch$b_hat))
cat(sprintf("Post-MAP-21 (2013-2018): b̂ = %.3f\n", post_bunch$b_hat))
cat(sprintf("Change: %.3f (%.1f%% reduction)\n",
            post_bunch$b_hat - pre_bunch$b_hat,
            100 * (1 - post_bunch$b_hat / pre_bunch$b_hat)))

# ============================================================
# 2. MCCRARY DENSITY TEST
# ============================================================

# McCrary (2008) test: is there a discontinuity in the density at SR=50?
# We implement a simplified version using local linear regression
# on binned counts on each side of the cutoff

mccrary_test <- function(dt, cutoff = 50, bandwidth = 10) {
  counts <- dt[sr_int >= (cutoff - bandwidth) & sr_int <= (cutoff + bandwidth),
               .(count = .N), by = sr_int][order(sr_int)]

  # Log counts for density estimation
  counts[, log_count := log(count + 1)]
  counts[, below := as.integer(sr_int < cutoff)]
  counts[, dist := sr_int - cutoff]

  # Local linear regression on each side
  below_fit <- lm(log_count ~ dist, data = counts[below == 1])
  above_fit <- lm(log_count ~ dist, data = counts[below == 0])

  # Log-density gap at cutoff
  log_gap <- predict(below_fit, newdata = data.frame(dist = -0.5)) -
    predict(above_fit, newdata = data.frame(dist = 0.5))

  # SE via delta method (simplified)
  se_below <- summary(below_fit)$sigma / sqrt(nrow(counts[below == 1]))
  se_above <- summary(above_fit)$sigma / sqrt(nrow(counts[below == 0]))
  se_gap <- sqrt(se_below^2 + se_above^2)

  t_stat <- log_gap / se_gap

  list(log_gap = log_gap, se = se_gap, t_stat = t_stat,
       p_value = 2 * (1 - pnorm(abs(t_stat))))
}

cat("\n=== MCCRARY DENSITY TESTS ===\n")
mc_full <- mccrary_test(nbi)
mc_pre <- mccrary_test(nbi[post_map21 == 0])
mc_post <- mccrary_test(nbi[post_map21 == 1])

cat(sprintf("Full sample:  log-gap = %.3f (SE = %.3f, t = %.2f, p = %.4f)\n",
            mc_full$log_gap, mc_full$se, mc_full$t_stat, mc_full$p_value))
cat(sprintf("Pre-MAP-21:   log-gap = %.3f (SE = %.3f, t = %.2f, p = %.4f)\n",
            mc_pre$log_gap, mc_pre$se, mc_pre$t_stat, mc_pre$p_value))
cat(sprintf("Post-MAP-21:  log-gap = %.3f (SE = %.3f, t = %.2f, p = %.4f)\n",
            mc_post$log_gap, mc_post$se, mc_post$t_stat, mc_post$p_value))

# ============================================================
# 3. OWNER HETEROGENEITY
# ============================================================

cat("\n=== BUNCHING BY OWNER TYPE ===\n")
for (otype in c("State DOT", "Local Government", "Federal")) {
  sub <- nbi[owner_type == otype]
  if (nrow(sub) > 10000) {
    bunch <- estimate_bunching(sub)
    cat(sprintf("%-20s: b̂ = %.3f (N = %s)\n",
                otype, bunch$b_hat, format(nrow(sub), big.mark = ",")))
  }
}

# ============================================================
# 4. YEAR-BY-YEAR BUNCHING RATIO
# ============================================================

cat("\n=== YEAR-BY-YEAR BUNCHING AT SR=50 ===\n")
year_bunching <- nbi[, {
  n_below <- sum(sr_int >= 46 & sr_int <= 49)
  n_above <- sum(sr_int >= 50 & sr_int <= 53)
  ratio <- n_below / n_above
  n_49 <- sum(sr_int == 49)
  n_50 <- sum(sr_int == 50)
  drop_pct <- 100 * (1 - n_50 / n_49)
  list(n_below = n_below, n_above = n_above, ratio = ratio,
       n_49 = n_49, n_50 = n_50, drop_pct = drop_pct)
}, by = year][order(year)]

print(year_bunching)

# Save for table generation
fwrite(year_bunching, file.path(data_dir, "year_bunching.csv"))

# ============================================================
# 5. PLACEBO TESTS
# ============================================================

cat("\n=== PLACEBO: BUNCHING AT SR=60, 70, 80 ===\n")
for (cutoff in c(60, 70, 80)) {
  below <- nbi[sr_int == (cutoff - 1), .N]
  above <- nbi[sr_int == cutoff, .N]
  ratio <- below / above
  cat(sprintf("SR=%d: count at %d = %s, at %d = %s, ratio = %.3f\n",
              cutoff, cutoff - 1, format(below, big.mark = ","),
              cutoff, format(above, big.mark = ","), ratio))
}

# Formal bunching test at SR=80 (rehabilitation threshold)
cat("\n=== PLACEBO: BUNCHING ESTIMATION AT SR=80 ===\n")
placebo_80 <- estimate_bunching(nbi, exclude_lower = 76, exclude_upper = 83,
                                 threshold = 80)
cat(sprintf("b̂ at SR=80: %.3f\n", placebo_80$b_hat))

# ============================================================
# 6. DIAGNOSTICS OUTPUT
# ============================================================

# For validate_v1.py
diagnostics <- list(
  n_treated = nbi[sr_int >= 46 & sr_int <= 53, uniqueN(STRUCTURE_NUMBER_008)],
  n_pre = length(unique(nbi[post_map21 == 0, year])),
  n_obs = nrow(nbi)
)
write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%s\n",
            diagnostics$n_treated, diagnostics$n_pre,
            format(diagnostics$n_obs, big.mark = ",")))

# Save key results for tables
results <- list(
  full_bhat = full_bunch$b_hat,
  pre_bhat = pre_bunch$b_hat,
  post_bhat = post_bunch$b_hat,
  bhat_change_pct = 100 * (1 - post_bunch$b_hat / pre_bunch$b_hat),
  mccrary_full = mc_full,
  mccrary_pre = mc_pre,
  mccrary_post = mc_post,
  full_excess = full_bunch$excess_below,
  full_deficit = full_bunch$deficit_above
)
saveRDS(results, file.path(data_dir, "main_results.rds"))
cat("\nMain results saved.\n")
