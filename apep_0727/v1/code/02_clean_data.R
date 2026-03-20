## 02_clean_data.R — Construct variables for bunching analysis
## apep_0727: German Solar PV Bunching at 10 kWp Threshold

source("00_packages.R")

cat("Loading raw data...\n")
dt <- fread("../data/solar_installations.csv")

# ---- Filter and construct variables ----

# Keep valid observations with positive capacity and known year
dt <- dt[!is.na(capacity_kwp) & capacity_kwp > 0 & !is.na(year)]

# Create period indicators
# Pre-policy: 2008-2013 (EEG 2014 self-consumption surcharge not yet in effect)
# Policy: August 2014-2018 (surcharge active; threshold at 10 kWp)
# Note: EEG 2014 effective August 1, 2014 but we use full calendar years for bins
dt[, period := fcase(
  year >= 2008 & year <= 2013, "pre_policy",
  year >= 2014 & year <= 2018, "policy",
  default = NA_character_
)]
dt <- dt[!is.na(period)]

# Create 0.1 kWp bins for bunching analysis
# Round DOWN to nearest 0.1 kWp (left-closed bins)
dt[, bin_01 := floor(capacity_kwp * 10) / 10]

# Create 0.5 kWp bins for robustness
dt[, bin_05 := floor(capacity_kwp * 2) / 2]

# Mark large vs small systems
dt[, large_system := capacity_kwp >= 30]

# ---- Construct bin-level counts ----

# Main analysis window: 3-20 kWp (generous around 10 kWp threshold)
dt_window <- dt[capacity_kwp >= 3 & capacity_kwp <= 20]

# Bin counts by period (0.1 kWp bins)
bin_counts <- dt_window[, .(count = .N), by = .(bin_01, period)]
bin_counts <- dcast(bin_counts, bin_01 ~ period, value.var = "count", fill = 0)

# Bin counts by year (0.1 kWp bins) for annual event study
bin_counts_year <- dt_window[, .(count = .N), by = .(bin_01, year)]

# ---- Summary statistics ----

cat("\n=== Analysis Sample ===\n")
cat(sprintf("Total records (3-20 kWp): %s\n", format(nrow(dt_window), big.mark = ",")))
cat(sprintf("Pre-policy (2008-2013):   %s\n", format(sum(dt_window$period == "pre_policy"), big.mark = ",")))
cat(sprintf("Policy (2014-2018):       %s\n", format(sum(dt_window$period == "policy"), big.mark = ",")))

# Key bins around threshold
cat("\n=== Counts near 10 kWp threshold (0.1 kWp bins) ===\n")
near_10 <- bin_counts[bin_01 >= 9.0 & bin_01 <= 11.0]
print(near_10)

# ---- Save cleaned data ----

fwrite(dt_window, "../data/solar_clean.csv")
fwrite(bin_counts, "../data/bin_counts_period.csv")
fwrite(bin_counts_year, "../data/bin_counts_year.csv")

cat(sprintf("\nCleaned data saved: %s records\n", format(nrow(dt_window), big.mark = ",")))
