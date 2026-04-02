# 03_main_analysis.R — Bunching estimation for Ireland HTB
# Ireland HTB Price Bunching (apep_1297)
#
# Methodology: Polynomial bunching estimator (Kleven 2016; Chetty et al. 2011)
# Threshold: €500,000 (HTB eligibility cap)
# Treatment: New-build properties (eligible for HTB)
# Placebo: Second-hand properties (ineligible)

source("00_packages.R")

df <- readRDS("../data/ppr_analysis.rds")
cat("Loaded", nrow(df), "transactions\n")

# ============================================================
# BUNCHING ESTIMATION FUNCTION
# ============================================================

estimate_bunching <- function(data, threshold = 500000, bin_width = 5000,
                               poly_order = 7, excl_lower = 475000,
                               excl_upper = 520000,
                               lower_bound = 200000, upper_bound = 800000,
                               n_boot = 500) {
  # Bin the data
  dt <- data.table(price = data$price_adj)
  dt[, bin := floor(price / bin_width) * bin_width + bin_width / 2]

  # Create bin counts
  all_bins <- seq(lower_bound + bin_width / 2, upper_bound - bin_width / 2, by = bin_width)
  counts <- dt[bin >= lower_bound & bin <= upper_bound, .N, by = bin]
  bin_df <- data.table(bin = all_bins)
  bin_df <- merge(bin_df, counts, by = "bin", all.x = TRUE)
  bin_df[is.na(N), N := 0]
  setorder(bin_df, bin)

  # Normalize bin position relative to threshold
  bin_df[, z := (bin - threshold) / bin_width]

  # Identify excluded region (bunching + missing mass window)
  bin_df[, excluded := bin >= excl_lower & bin <= excl_upper]

  # Fit polynomial on non-excluded bins
  fit_data <- bin_df[excluded == FALSE]

  if (nrow(fit_data) < poly_order + 1) {
    stop("Not enough non-excluded bins for polynomial fit")
  }

  # Polynomial regression
  fit <- lm(N ~ poly(z, poly_order, raw = TRUE), data = fit_data)

  # Predict counterfactual for all bins (including excluded)
  bin_df[, counterfactual := predict(fit, newdata = bin_df)]
  bin_df[counterfactual < 0, counterfactual := 0]

  # Excess mass in bunching region (below threshold)
  bunch_region <- bin_df[bin >= excl_lower & bin <= threshold]
  excess_mass <- sum(bunch_region$N) - sum(bunch_region$counterfactual)

  # Missing mass above threshold
  missing_region <- bin_df[bin > threshold & bin <= excl_upper]
  missing_mass <- sum(missing_region$counterfactual) - sum(missing_region$N)

  # Bunching ratio: excess mass / average counterfactual bin count in bunching region
  avg_cf <- mean(bunch_region$counterfactual)
  b_ratio <- excess_mass / avg_cf

  # Normalized excess mass (Kleven 2016): B / (h0 * N_bins_below)
  n_bins_below <- nrow(bunch_region)
  normalized_b <- excess_mass / (avg_cf * n_bins_below)

  # --- Bootstrap for standard errors ---
  boot_b <- numeric(n_boot)
  boot_ratio <- numeric(n_boot)
  n_total <- nrow(data)

  for (i in seq_len(n_boot)) {
    # Resample transactions
    boot_idx <- sample.int(n_total, replace = TRUE)
    boot_dt <- data.table(price = data$price_adj[boot_idx])
    boot_dt[, bin := floor(price / bin_width) * bin_width + bin_width / 2]

    boot_counts <- boot_dt[bin >= lower_bound & bin <= upper_bound, .N, by = bin]
    boot_bin <- data.table(bin = all_bins)
    boot_bin <- merge(boot_bin, boot_counts, by = "bin", all.x = TRUE)
    boot_bin[is.na(N), N := 0]
    boot_bin[, z := (bin - threshold) / bin_width]
    boot_bin[, excluded := bin >= excl_lower & bin <= excl_upper]

    boot_fit_data <- boot_bin[excluded == FALSE]
    if (nrow(boot_fit_data) < poly_order + 1) next

    boot_fit <- tryCatch(
      lm(N ~ poly(z, poly_order, raw = TRUE), data = boot_fit_data),
      error = function(e) NULL
    )
    if (is.null(boot_fit)) next

    boot_bin[, cf := predict(boot_fit, newdata = boot_bin)]
    boot_bin[cf < 0, cf := 0]

    boot_bunch <- boot_bin[bin >= excl_lower & bin <= threshold]
    boot_excess <- sum(boot_bunch$N) - sum(boot_bunch$cf)
    boot_avg_cf <- mean(boot_bunch$cf)

    boot_b[i] <- boot_excess
    boot_ratio[i] <- boot_excess / boot_avg_cf
  }

  se_excess <- sd(boot_b, na.rm = TRUE)
  se_ratio <- sd(boot_ratio, na.rm = TRUE)

  list(
    bin_data = bin_df,
    excess_mass = excess_mass,
    se_excess = se_excess,
    missing_mass = missing_mass,
    bunching_ratio = b_ratio,
    se_ratio = se_ratio,
    normalized_b = normalized_b,
    avg_counterfactual = avg_cf,
    poly_order = poly_order,
    bin_width = bin_width,
    threshold = threshold
  )
}

# ============================================================
# MAIN ESTIMATES
# ============================================================

cat("\n========================================\n")
cat("BUNCHING ESTIMATION: NEW BUILDS (HTB period 2017-2025)\n")
cat("========================================\n")

# New builds, HTB period (2017-2025)
nb_htb <- df[new_build == TRUE & year >= 2017]
cat("New builds in HTB period:", nrow(nb_htb), "\n")

result_nb <- estimate_bunching(nb_htb, n_boot = 500)
cat("\n--- New Build Results ---\n")
cat("Excess mass:", round(result_nb$excess_mass, 0), " (SE:", round(result_nb$se_excess, 0), ")\n")
cat("Bunching ratio:", round(result_nb$bunching_ratio, 2), " (SE:", round(result_nb$se_ratio, 2), ")\n")
cat("Normalized b:", round(result_nb$normalized_b, 3), "\n")
cat("Average counterfactual bin count:", round(result_nb$avg_counterfactual, 1), "\n")

# Second-hand, same period (placebo)
cat("\n========================================\n")
cat("PLACEBO: SECOND-HAND (HTB period 2017-2025)\n")
cat("========================================\n")

sh_htb <- df[new_build == FALSE & year >= 2017]
cat("Second-hand in HTB period:", nrow(sh_htb), "\n")

result_sh <- estimate_bunching(sh_htb, n_boot = 500)
cat("\n--- Second-Hand Results (Placebo) ---\n")
cat("Excess mass:", round(result_sh$excess_mass, 0), " (SE:", round(result_sh$se_excess, 0), ")\n")
cat("Bunching ratio:", round(result_sh$bunching_ratio, 2), " (SE:", round(result_sh$se_ratio, 2), ")\n")
cat("Normalized b:", round(result_sh$normalized_b, 3), "\n")

# Pre-HTB new builds (another placebo)
cat("\n========================================\n")
cat("PLACEBO: NEW BUILDS PRE-HTB (2010-2016)\n")
cat("========================================\n")

nb_pre <- df[new_build == TRUE & year < 2017]
cat("New builds pre-HTB:", nrow(nb_pre), "\n")

result_pre <- estimate_bunching(nb_pre, n_boot = 500)
cat("\n--- Pre-HTB New Build Results (Placebo) ---\n")
cat("Excess mass:", round(result_pre$excess_mass, 0), " (SE:", round(result_pre$se_excess, 0), ")\n")
cat("Bunching ratio:", round(result_pre$bunching_ratio, 2), " (SE:", round(result_pre$se_ratio, 2), ")\n")
cat("Normalized b:", round(result_pre$normalized_b, 3), "\n")

# ============================================================
# DIFFERENCE-IN-BUNCHING: HTB Enhanced vs Standard
# ============================================================

cat("\n========================================\n")
cat("DIFFERENCE-IN-BUNCHING: Enhanced vs Standard HTB\n")
cat("========================================\n")

# Standard HTB period (2017-01 to 2020-07)
nb_standard <- df[new_build == TRUE & period == "htb_standard"]
result_standard <- estimate_bunching(nb_standard, n_boot = 500)
cat("Standard HTB - Bunching ratio:", round(result_standard$bunching_ratio, 2),
    " (SE:", round(result_standard$se_ratio, 2), ")\n")
cat("Standard HTB - Excess mass:", round(result_standard$excess_mass, 0), "\n")

# Enhanced HTB period (2020-07 to 2022-01)
nb_enhanced <- df[new_build == TRUE & period == "htb_enhanced"]
result_enhanced <- estimate_bunching(nb_enhanced, n_boot = 500)
cat("Enhanced HTB - Bunching ratio:", round(result_enhanced$bunching_ratio, 2),
    " (SE:", round(result_enhanced$se_ratio, 2), ")\n")
cat("Enhanced HTB - Excess mass:", round(result_enhanced$excess_mass, 0), "\n")

# Post-enhanced period (2022+)
nb_post <- df[new_build == TRUE & period == "htb_post_enhanced"]
result_post <- estimate_bunching(nb_post, n_boot = 500)
cat("Post-enhanced HTB - Bunching ratio:", round(result_post$bunching_ratio, 2),
    " (SE:", round(result_post$se_ratio, 2), ")\n")
cat("Post-enhanced HTB - Excess mass:", round(result_post$excess_mass, 0), "\n")

# DiB: Enhanced minus Standard
dib <- result_enhanced$bunching_ratio - result_standard$bunching_ratio
dib_se <- sqrt(result_enhanced$se_ratio^2 + result_standard$se_ratio^2)
cat("\nDifference-in-bunching (enhanced - standard):", round(dib, 2),
    " (SE:", round(dib_se, 2), ")\n")

# ============================================================
# HETEROGENEITY: Dublin vs Non-Dublin
# ============================================================

cat("\n========================================\n")
cat("HETEROGENEITY: Dublin vs Non-Dublin (HTB period)\n")
cat("========================================\n")

nb_dublin <- df[new_build == TRUE & year >= 2017 & dublin == TRUE]
nb_nondublin <- df[new_build == TRUE & year >= 2017 & dublin == FALSE]

result_dublin <- estimate_bunching(nb_dublin, n_boot = 500)
result_nondublin <- estimate_bunching(nb_nondublin, n_boot = 500)

cat("Dublin - Bunching ratio:", round(result_dublin$bunching_ratio, 2),
    " (SE:", round(result_dublin$se_ratio, 2), "), N =", nrow(nb_dublin), "\n")
cat("Non-Dublin - Bunching ratio:", round(result_nondublin$bunching_ratio, 2),
    " (SE:", round(result_nondublin$se_ratio, 2), "), N =", nrow(nb_nondublin), "\n")

het_diff <- result_dublin$bunching_ratio - result_nondublin$bunching_ratio
het_se <- sqrt(result_dublin$se_ratio^2 + result_nondublin$se_ratio^2)
cat("Dublin - Non-Dublin:", round(het_diff, 2), " (SE:", round(het_se, 2), ")\n")

# ============================================================
# SAVE ALL RESULTS
# ============================================================

results <- list(
  main_nb = result_nb,
  placebo_sh = result_sh,
  placebo_pre = result_pre,
  htb_standard = result_standard,
  htb_enhanced = result_enhanced,
  htb_post = result_post,
  dublin = result_dublin,
  nondublin = result_nondublin,
  dib = dib,
  dib_se = dib_se
)

saveRDS(results, "../data/bunching_results.rds")

# Diagnostics JSON
diag <- list(
  n_treated = nrow(nb_htb),  # new builds in HTB period
  n_pre = length(unique(df[new_build == TRUE & year < 2017]$year)),  # pre-HTB years
  n_obs = nrow(df),
  bunching_ratio_nb = result_nb$bunching_ratio,
  bunching_ratio_sh = result_sh$bunching_ratio,
  bunching_ratio_pre = result_pre$bunching_ratio,
  excess_mass = result_nb$excess_mass,
  se_excess = result_nb$se_excess
)
write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

cat("\nAll results saved.\n")
