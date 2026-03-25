# 02_clean_data.R — Construct bunching analysis dataset
# Creates binned capacity distributions for each threshold and period

source("00_packages.R")

cat("=== Constructing Bunching Analysis Dataset ===\n")

solar <- fread("../data/solar_clean.csv")
cat(sprintf("Loaded %s records\n", format(nrow(solar), big.mark = ",")))

# ---------------------------------------------------------------
# Define EEG thresholds and their regulatory consequences
# ---------------------------------------------------------------
thresholds <- data.table(
  threshold_kw = c(10, 30, 40, 100, 750),
  label = c(
    "10 kWp: EEG surcharge exemption (pre-2021)",
    "30 kWp: Expanded surcharge exemption (post-2021)",
    "40 kWp: Feed-in tariff rate break",
    "100 kWp: Mandatory direct marketing",
    "750 kWp: Mandatory tender participation"
  ),
  short_label = c("10kWp", "30kWp", "40kWp", "100kWp", "750kWp"),
  # Financial incentive magnitude (approximate EUR/kWp/year saved by staying below)
  incentive_eur = c(25, 25, 8, 15, 40)
)

# ---------------------------------------------------------------
# Create capacity bins for each threshold
# Bin width: 0.1 kW for thresholds ≤100; 1 kW for 750
# ---------------------------------------------------------------

# Function to create binned distribution around a threshold
create_bins <- function(dt, threshold, bin_width, window_mult = 3) {
  # Window: threshold ± window_mult * threshold (symmetric in log space)
  if (threshold <= 100) {
    lower <- max(0.5, threshold * 0.3)
    upper <- threshold * 2.0
  } else {
    lower <- threshold * 0.4
    upper <- threshold * 1.8
  }

  # Filter to window
  sub <- dt[capacity_kw >= lower & capacity_kw <= upper]

  # Create bins
  sub[, bin := floor(capacity_kw / bin_width) * bin_width]

  # Count per bin
  binned <- sub[, .(count = .N), by = bin]
  setorder(binned, bin)

  binned[, threshold := threshold]
  binned[, bin_width := bin_width]

  return(binned)
}

# ---------------------------------------------------------------
# Period definitions for diff-in-bunching
# ---------------------------------------------------------------
# Pre-2021: Before EEG amendment expanded 10→30 kWp exemption
# Post-2021: After January 2021 EEG amendment (EEG 2021)

solar[, period := fifelse(comm_year < 2021, "pre", "post")]

# Create separate binned distributions by period
cat("\nCreating binned distributions by threshold and period...\n")

all_bins <- list()
for (thr in thresholds$threshold_kw) {
  bw <- ifelse(thr <= 100, 0.1, 1.0)

  for (per in c("pre", "post")) {
    sub <- solar[period == per]
    bins <- create_bins(sub, thr, bw)
    bins[, period := per]
    all_bins[[paste(thr, per)]] <- bins
    cat(sprintf("  Threshold %d kWp, %s: %d bins, %s installations\n",
                thr, per, nrow(bins), format(sum(bins$count), big.mark = ",")))
  }
}

binned_data <- rbindlist(all_bins)

# ---------------------------------------------------------------
# Also create overall (pooled) distributions
# ---------------------------------------------------------------
for (thr in thresholds$threshold_kw) {
  bw <- ifelse(thr <= 100, 0.1, 1.0)
  bins <- create_bins(solar, thr, bw)
  bins[, period := "pooled"]
  binned_data <- rbind(binned_data, bins)
}

# ---------------------------------------------------------------
# Detailed year-by-year distributions for event study
# ---------------------------------------------------------------
year_bins <- list()
for (yr in 2010:2024) {
  for (thr in c(10, 30)) {  # Focus on the shifted thresholds
    sub <- solar[comm_year == yr]
    bins <- create_bins(sub, thr, 0.1)
    bins[, year := yr]
    year_bins[[paste(yr, thr)]] <- bins
  }
}
year_binned <- rbindlist(year_bins)

# ---------------------------------------------------------------
# Installation-type heterogeneity
# ---------------------------------------------------------------
type_bins <- list()
for (itype in c("rooftop", "ground_mount")) {
  for (thr in thresholds$threshold_kw) {
    bw <- ifelse(thr <= 100, 0.1, 1.0)
    sub <- solar[install_type == itype]
    bins <- create_bins(sub, thr, bw)
    bins[, install_type := itype]
    type_bins[[paste(itype, thr)]] <- bins
  }
}
type_binned <- rbindlist(type_bins)

# ---------------------------------------------------------------
# Save all binned datasets
# ---------------------------------------------------------------
fwrite(binned_data, "../data/binned_by_threshold_period.csv")
fwrite(year_binned, "../data/binned_by_year_threshold.csv")
fwrite(type_binned, "../data/binned_by_type_threshold.csv")

# Save threshold definitions
fwrite(thresholds, "../data/thresholds.csv")

cat("\n=== Summary Statistics for Paper ===\n")
cat(sprintf("Total installations: %s\n", format(nrow(solar), big.mark = ",")))
cat(sprintf("Pre-2021: %s\n", format(solar[period == "pre", .N], big.mark = ",")))
cat(sprintf("Post-2021: %s\n", format(solar[period == "post", .N], big.mark = ",")))

cat("\nCapacity distribution (percentiles):\n")
cat(sprintf("  10th: %.1f kWp\n", quantile(solar$capacity_kw, 0.10)))
cat(sprintf("  25th: %.1f kWp\n", quantile(solar$capacity_kw, 0.25)))
cat(sprintf("  50th: %.1f kWp\n", quantile(solar$capacity_kw, 0.50)))
cat(sprintf("  75th: %.1f kWp\n", quantile(solar$capacity_kw, 0.75)))
cat(sprintf("  90th: %.1f kWp\n", quantile(solar$capacity_kw, 0.90)))
cat(sprintf("  99th: %.1f kWp\n", quantile(solar$capacity_kw, 0.99)))

cat("\nRooftop vs ground-mount:\n")
print(solar[, .(.N, mean_kw = round(mean(capacity_kw), 1),
                 median_kw = round(median(capacity_kw), 1)),
             by = install_type])

cat("\nDone. Binned data saved.\n")
