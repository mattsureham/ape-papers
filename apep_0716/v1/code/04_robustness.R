# 04_robustness.R — Additional robustness and mechanism tests
# apep_0716: Nonprofit Disclosure Cost Bunching

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"

df <- readRDS(file.path(data_dir, "eo_cleaned.rds"))
results <- readRDS(file.path(data_dir, "bunching_results.rds"))

# ===================================================================
# TEST 1: ROUND NUMBER PLACEBO
# Check if bunching at $200K is just round-number heaping
# Compare bunching at $100K, $150K, $250K, $300K (no policy threshold)
# ===================================================================

cat("=== ROUND NUMBER PLACEBO TEST ===\n")

# Source the bunching function from 03
source("03_main_analysis.R")  # This reloads results but also defines estimate_bunching()

round_placebos <- data.frame()
for (threshold in c(100000, 150000, 250000, 300000)) {
  # Create bins around each placebo threshold
  window_low <- threshold - 50000
  window_high <- threshold + 50000
  df_sub <- df[revenue >= window_low & revenue <= window_high]
  df_sub[, rev_bin_1k := floor(revenue / 1000) * 1000]
  bins_sub <- df_sub[, .(count = .N), by = rev_bin_1k]
  bins_sub <- bins_sub[order(rev_bin_1k)]
  bins_sub[, bin_center := rev_bin_1k + 500]

  if (nrow(bins_sub) < 30) {
    cat(sprintf("  $%dK: insufficient data, skipping\n", threshold/1000))
    next
  }

  res <- estimate_bunching(bins_sub, threshold,
                           exclude_lower = threshold - 20000,
                           exclude_upper = threshold + 10000,
                           n_boot = 500)
  round_placebos <- rbind(round_placebos, data.frame(
    threshold = threshold,
    b_normalized = res$b_normalized,
    se_b = res$se_b,
    t_stat = res$b_normalized / res$se_b
  ))
  cat(sprintf("  $%dK: b = %.3f (SE = %.3f), t = %.2f\n",
              threshold/1000, res$b_normalized, res$se_b,
              res$b_normalized / res$se_b))
}

cat(sprintf("\n  $200K (treatment): b = %.3f (SE = %.3f), t = %.2f\n",
            results$main_200k$b_normalized, results$main_200k$se_b,
            results$main_200k$b_normalized / results$main_200k$se_b))

# ===================================================================
# TEST 2: McCRARY DENSITY TEST
# Formal test for discontinuity in the density at $200K
# ===================================================================

cat("\n=== McCRARY-STYLE DENSITY TEST ===\n")

# Simple bin-level t-test for density discontinuity
bins_main <- results$main_200k$bins
bins_below <- bins_main$count[bins_main$bin_center >= 190000 & bins_main$bin_center < 200000]
bins_above <- bins_main$count[bins_main$bin_center >= 200000 & bins_main$bin_center < 210000]

ttest <- t.test(bins_below, bins_above, alternative = "greater")
cat(sprintf("Mean count below $200K: %.1f per $1K bin\n", mean(bins_below)))
cat(sprintf("Mean count above $200K: %.1f per $1K bin\n", mean(bins_above)))
cat(sprintf("Difference: %.1f (t = %.2f, p = %.4f)\n",
            mean(bins_below) - mean(bins_above), ttest$statistic, ttest$p.value))

# ===================================================================
# TEST 3: DONUT ANALYSIS
# Exclude bins right at threshold to check if result driven by heaping
# ===================================================================

cat("\n=== DONUT ROBUSTNESS ===\n")

donut_results <- data.frame()
for (donut in c(0, 2000, 5000, 10000)) {
  res <- estimate_bunching(
    results$main_200k$bins,
    200000,
    exclude_lower = 200000 - 20000,
    exclude_upper = 200000 + 10000 + donut,
    n_boot = 500
  )
  donut_results <- rbind(donut_results, data.frame(
    donut_size = donut,
    b_normalized = res$b_normalized,
    se_b = res$se_b
  ))
  cat(sprintf("  Donut $%dK above: b = %.3f (SE = %.3f)\n",
              donut/1000, res$b_normalized, res$se_b))
}

# ===================================================================
# TEST 4: STATE-LEVEL HETEROGENEITY
# States with additional charitable solicitation audit thresholds
# ===================================================================

cat("\n=== STATE-LEVEL HETEROGENEITY ===\n")

# States with notable charitable solicitation requirements around $200K
# New York: audit required for >$250K revenue (close to $200K zone)
# California: audit for >$2M
# Group states by regulatory intensity
high_reg_states <- c("NY", "CA", "MA", "CT", "NJ", "IL", "PA", "OH")
low_reg_states <- setdiff(unique(df$state), high_reg_states)

for (group_name in c("High Regulation", "Low Regulation")) {
  states <- if (group_name == "High Regulation") high_reg_states else low_reg_states
  df_sub <- df[state %in% states & revenue >= 100000 & revenue <= 300000]
  df_sub[, rev_bin_1k := floor(revenue / 1000) * 1000]
  bins_sub <- df_sub[, .(count = .N), by = rev_bin_1k]
  bins_sub <- bins_sub[order(rev_bin_1k)]
  bins_sub[, bin_center := rev_bin_1k + 500]

  if (nrow(bins_sub) < 50) next

  res <- estimate_bunching(bins_sub, 200000, n_boot = 500)
  cat(sprintf("  %s states (n=%d): b = %.3f (SE = %.3f)\n",
              group_name, sum(bins_sub$count), res$b_normalized, res$se_b))
}

# ===================================================================
# TEST 5: FILING REQUIREMENT CODE CONSISTENCY
# Check if actual filing codes match revenue-based predictions
# ===================================================================

cat("\n=== FILING CODE CONSISTENCY ===\n")

# Organizations just below $200K should file EZ (code 03 or similar)
# Organizations just above should file full 990 (code 01 or similar)
near_threshold <- df[revenue >= 190000 & revenue <= 210000]
near_threshold[, above := revenue >= 200000]

cat("Filing requirement codes near threshold:\n")
filing_tab <- near_threshold[, .(count = .N), by = .(above, filing_req)]
filing_tab <- filing_tab[order(above, -count)]
print(filing_tab)

# ===================================================================
# SAVE ROBUSTNESS RESULTS
# ===================================================================

robustness <- list(
  round_placebos = round_placebos,
  donut_results = donut_results,
  density_test = list(
    mean_below = mean(bins_below),
    mean_above = mean(bins_above),
    t_stat = as.numeric(ttest$statistic),
    p_value = ttest$p.value
  )
)

saveRDS(robustness, file.path(data_dir, "robustness_results.rds"))
cat("\nRobustness results saved.\n")
