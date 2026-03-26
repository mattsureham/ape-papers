# 04_robustness.R — Robustness checks for bunching estimation
# apep_1024: France DPE Rental Ban Bunching

source("00_packages.R")

dt <- fread("../data/dpe_clean.csv")
load("../data/bunching_results.RData")

cat("=== ROBUSTNESS CHECKS ===\n\n")

# Re-use bunching function from 03
estimate_bunching <- function(data, threshold, bin_width = 5,
                               window_left = 100, window_right = 100,
                               poly_order = 7, excl_width = 20,
                               label = "") {
  conso_min <- threshold - window_left
  conso_max <- threshold + window_right
  d <- data[conso >= conso_min & conso <= conso_max]
  d[, bin := floor(conso / bin_width) * bin_width]
  bin_counts <- d[, .(count = .N), by = bin][order(bin)]
  excl_lo <- threshold - excl_width
  excl_hi <- threshold
  cf_data <- bin_counts[bin < excl_lo | bin >= excl_hi]
  cf_data[, bin_norm := bin - threshold]
  poly_formula <- as.formula(paste0("count ~ ",
                                     paste0("I(bin_norm^", 1:poly_order, ")",
                                            collapse = " + ")))
  fit <- lm(poly_formula, data = cf_data)
  all_bins <- bin_counts[, .(bin, bin_norm = bin - threshold)]
  all_bins[, counterfactual := predict(fit, newdata = all_bins)]
  bin_counts <- merge(bin_counts, all_bins[, .(bin, counterfactual)], by = "bin")
  excl_bins <- bin_counts[bin >= excl_lo & bin < excl_hi]
  excess_mass <- sum(excl_bins$count - excl_bins$counterfactual)
  cf_at_threshold <- mean(excl_bins$counterfactual)
  if (cf_at_threshold <= 0) cf_at_threshold <- 1
  b_normalized <- excess_mass / cf_at_threshold
  set.seed(42)
  n_boot <- 200
  b_boot <- numeric(n_boot)
  for (i in 1:n_boot) {
    boot_counts <- bin_counts[, .(bin, count = rpois(.N, count), bin_norm = bin - threshold)]
    cf_boot <- boot_counts[bin < excl_lo | bin >= excl_hi]
    fit_b <- tryCatch(lm(poly_formula, data = cf_boot), error = function(e) NULL)
    if (is.null(fit_b)) { b_boot[i] <- NA; next }
    boot_counts[, cf_boot := predict(fit_b, newdata = boot_counts)]
    excl_b <- boot_counts[bin >= excl_lo & bin < excl_hi]
    denom <- max(mean(excl_b$cf_boot), 1)
    b_boot[i] <- sum(excl_b$count - excl_b$cf_boot) / denom
  }
  se_b <- sd(b_boot, na.rm = TRUE)
  return(list(b = b_normalized, se = se_b, excess = excess_mass,
              total_obs = sum(bin_counts$count), label = label))
}

# ============================================================
# R1. SENSITIVITY TO POLYNOMIAL ORDER
# ============================================================

cat("--- R1: Polynomial order sensitivity ---\n")
poly_results <- list()
for (p in c(5, 6, 7, 8, 9)) {
  r <- estimate_bunching(dt, threshold = 420, poly_order = p,
                          label = sprintf("F/G, poly=%d", p))
  poly_results[[as.character(p)]] <- data.table(
    poly_order = p, b = r$b, se = r$se
  )
  cat(sprintf("  Poly %d: b = %.3f (SE = %.3f)\n", p, r$b, r$se))
}
poly_dt <- rbindlist(poly_results)

# ============================================================
# R2. SENSITIVITY TO BIN WIDTH
# ============================================================

cat("\n--- R2: Bin width sensitivity ---\n")
bin_results <- list()
for (bw in c(2, 5, 10)) {
  r <- estimate_bunching(dt, threshold = 420, bin_width = bw,
                          label = sprintf("F/G, bin=%d", bw))
  bin_results[[as.character(bw)]] <- data.table(
    bin_width = bw, b = r$b, se = r$se
  )
  cat(sprintf("  Bin %d kWh: b = %.3f (SE = %.3f)\n", bw, r$b, r$se))
}
bin_dt <- rbindlist(bin_results)

# ============================================================
# R3. SENSITIVITY TO EXCLUSION WINDOW
# ============================================================

cat("\n--- R3: Exclusion window sensitivity ---\n")
excl_results <- list()
for (ew in c(10, 15, 20, 25, 30)) {
  r <- estimate_bunching(dt, threshold = 420, excl_width = ew,
                          label = sprintf("F/G, excl=%d", ew))
  excl_results[[as.character(ew)]] <- data.table(
    excl_width = ew, b = r$b, se = r$se
  )
  cat(sprintf("  Excl %d kWh: b = %.3f (SE = %.3f)\n", ew, r$b, r$se))
}
excl_dt <- rbindlist(excl_results)

# ============================================================
# R4. BUILDING TYPE HETEROGENEITY
# ============================================================

cat("\n--- R4: Building type heterogeneity ---\n")
building_types <- dt[, unique(type_batiment)]
building_types <- building_types[!is.na(building_types)]
bt_results <- list()
for (bt in building_types) {
  dt_bt <- dt[type_batiment == bt]
  if (nrow(dt_bt[conso >= 320 & conso <= 520]) < 200) {
    cat(sprintf("  Skipping %s (too few obs)\n", bt))
    next
  }
  r <- estimate_bunching(dt_bt, threshold = 420,
                          label = sprintf("F/G (%s)", bt))
  bt_results[[bt]] <- data.table(
    building_type = bt, b = r$b, se = r$se, n = r$total_obs
  )
}
if (length(bt_results) > 0) {
  bt_dt <- rbindlist(bt_results)
  cat("\nBuilding type bunching:\n")
  print(bt_dt)
}

# ============================================================
# R5. GHG DIMENSION PLACEBO
# ============================================================

cat("\n--- R5: GHG dimension placebo ---\n")
# DPE label depends on the WORSE of energy or GHG. If bunching is about
# the rental ban (which depends on label, not just energy), we should see
# bunching in GHG too. But if bunching is purely energy-driven manipulation,
# GHG should show less response.

# GHG thresholds: G > 100 kgCO2/m2, F > 70, E > 50
dt_ghg <- dt[!is.na(ghg) & ghg > 0 & ghg < 300]
if (nrow(dt_ghg) > 1000) {
  # GHG at 100 kgCO2/m2 threshold (G label)
  d_ghg <- dt_ghg[ghg >= 50 & ghg <= 150]
  d_ghg[, ghg_bin := floor(ghg / 2) * 2]
  ghg_bins <- d_ghg[, .(count = .N), by = ghg_bin][order(ghg_bin)]
  cat(sprintf("GHG records near 100 kgCO2 threshold: %d\n", nrow(d_ghg)))

  # Simple excess mass test
  below_100 <- ghg_bins[ghg_bin >= 90 & ghg_bin < 100, sum(count)]
  above_100 <- ghg_bins[ghg_bin >= 100 & ghg_bin < 110, sum(count)]
  cat(sprintf("Records 90-100 kgCO2: %d\n", below_100))
  cat(sprintf("Records 100-110 kgCO2: %d\n", above_100))
  cat(sprintf("Ratio below/above: %.2f\n", below_100 / max(above_100, 1)))
}

# ============================================================
# R6. PLACEBO AT ROUND NUMBERS
# ============================================================

cat("\n--- R6: Round-number placebo ---\n")
# Test bunching at 300, 350, 400, 450, 500 (round numbers without regulatory significance)
for (rn in c(300, 350, 400, 450, 500)) {
  if (rn == 420 || rn == 330 || rn == 250) next  # Skip actual thresholds
  r <- estimate_bunching(dt, threshold = rn,
                          label = sprintf("Round number %d", rn))
  cat(sprintf("  %d kWh/m2: b = %.3f (SE = %.3f)\n", rn, r$b, r$se))
}

# ============================================================
# SAVE ROBUSTNESS RESULTS
# ============================================================

save(poly_dt, bin_dt, excl_dt,
     file = "../data/robustness_results.RData")
cat("\nRobustness results saved.\n")
