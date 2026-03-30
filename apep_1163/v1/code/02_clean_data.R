## 02_clean_data.R — Construct analysis variables for bunching estimation

source("00_packages.R")

# --- Load raw data ---
payments <- readRDS("../data/payments_raw.rds")
thresholds <- read.csv("../data/thresholds.csv")

cat(sprintf("Raw data: %s records\n", format(nrow(payments), big.mark = ",")))

# --- Create bins for histogram/density estimation ---
# Use $0.25 bins for main analysis (fine enough for bunching, not too noisy)
payments[, bin_25 := floor(amount / 0.25) * 0.25]

# Also create $0.50 bins for robustness
payments[, bin_50 := floor(amount / 0.50) * 0.50]

# --- Distance from threshold ---
payments[, dist_from_threshold := amount - threshold]

# --- Binary indicators ---
payments[, below_threshold := as.integer(amount < threshold)]
payments[, near_threshold := as.integer(abs(dist_from_threshold) <= 2)]

# --- Round-number indicators (for heaping tests) ---
payments[, is_round_dollar := as.integer(amount == round(amount))]
payments[, is_round_50c := as.integer(amount == round(amount * 2) / 2)]

# --- Create year-specific bin counts ---
# This is the primary input for bunching estimation
bin_counts <- payments[, .(
  count = .N,
  n_food = sum(payment_type == "Food & Beverage"),
  n_other = sum(payment_type != "Food & Beverage")
), by = .(program_year, bin_25, threshold)]

# Compute distance from threshold for each bin
bin_counts[, dist := bin_25 - threshold]

# --- Pooled bin counts (normalizing by threshold) ---
# Center all distributions on their year-specific threshold
pooled_bins <- payments[, .(
  count = .N,
  n_food = sum(payment_type == "Food & Beverage"),
  n_other = sum(payment_type != "Food & Beverage")
), by = .(dist_bin = floor(dist_from_threshold / 0.25) * 0.25)]

# --- Summary statistics ---
cat("\nBin counts by year (near threshold):\n")
print(bin_counts[abs(dist) <= 2][order(program_year, dist)][, head(.SD, 5), by = program_year])

cat("\nPayment type shares:\n")
print(payments[, .N, by = payment_type][order(-N)])

cat("\nRound number prevalence:\n")
cat(sprintf("  Exact dollar amounts: %.1f%%\n", 100 * mean(payments$is_round_dollar)))
cat(sprintf("  50-cent amounts: %.1f%%\n", 100 * mean(payments$is_round_50c)))

# --- Save analysis-ready data ---
saveRDS(payments, "../data/payments_clean.rds")
saveRDS(bin_counts, "../data/bin_counts.rds")
saveRDS(pooled_bins, "../data/pooled_bins.rds")

cat("\nCleaned data saved.\n")
