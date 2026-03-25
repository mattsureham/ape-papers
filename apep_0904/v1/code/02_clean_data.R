# 02_clean_data.R — Prepare contract density data for bunching estimation
source("00_packages.R")

PROJ_DIR <- normalizePath(file.path(getwd(), ".."))
DATA_DIR <- file.path(PROJ_DIR, "data")

# --- Load raw bin counts ---
dt <- fread(file.path(DATA_DIR, "contract_bins.csv"))
cat(sprintf("Loaded %d bin-year observations\n", nrow(dt)))
cat(sprintf("Years: %d-%d\n", min(dt$fiscal_year), max(dt$fiscal_year)))
cat(sprintf("Total contracts: %s\n", format(sum(dt$count), big.mark = ",")))

# --- Define threshold regime periods ---
# SAT history:
# Pre-2006: $100K (not in our data, but residual bunching may appear in 2008)
# 2006-Aug 2020: $150K
# Aug 2020-Oct 2025: $250K  (FAR implementation of 2018 NDAA Sec 805)
# Oct 2025+: $350K (not yet in data)
#
# The $150K→$250K change was effective in FAR on Aug 31, 2020
# FY2020 straddles (Oct 2019 - Sep 2020), so FY2021 is first full year at $250K

dt[, regime := fifelse(fiscal_year <= 2020, "SAT_150K", "SAT_250K")]

# --- Create normalized density (contracts per $10K per year) ---
# Already in counts per $10K bin, so density = count
dt[, density := count]

# --- Create relative position variables for each threshold ---
# For $150K threshold
dt[, dist_from_150 := bin_midpoint - 150000]
# For $250K threshold
dt[, dist_from_250 := bin_midpoint - 250000]
# For $100K threshold (residual)
dt[, dist_from_100 := bin_midpoint - 100000]

# --- Create pre/post indicator for the 2020 threshold change ---
dt[, post_2020 := as.integer(fiscal_year >= 2021)]

# --- Aggregate into analysis periods ---
# Period 1: FY2008-2011 (early post-2006, may show residual $100K bunching dissolution)
# Period 2: FY2012-2019 (stable $150K regime)
# Period 3: FY2021-2025 (stable $250K regime)
# FY2020 excluded (transition year)

dt[, period := fcase(
  fiscal_year >= 2008 & fiscal_year <= 2011, "early_150K",
  fiscal_year >= 2012 & fiscal_year <= 2019, "stable_150K",
  fiscal_year == 2020, "transition",
  fiscal_year >= 2021, "stable_250K"
)]

# --- Compute period-averaged densities ---
period_means <- dt[period != "transition",
                   .(mean_count = mean(count),
                     total_count = sum(count),
                     n_years = uniqueN(fiscal_year)),
                   by = .(period, bin_lower, bin_upper, bin_midpoint)]

# --- Summary statistics ---
cat("\n--- Summary by period ---\n")
period_summary <- dt[period != "transition",
                     .(n_years = uniqueN(fiscal_year),
                       total_contracts = sum(count),
                       avg_per_year = mean(sum(count), na.rm = TRUE)),
                     by = period]
print(period_summary)

# --- Bunching preview at $150K (pre-2020) ---
cat("\n--- Density around $150K, FY2015-2019 ---\n")
preview_150 <- dt[fiscal_year >= 2015 & fiscal_year <= 2019 &
                  bin_midpoint >= 100000 & bin_midpoint <= 200000,
                  .(avg_count = mean(count)), by = .(bin_lower, bin_upper)]
print(preview_150)

# --- Bunching preview at $250K (post-2020) ---
cat("\n--- Density around $250K, FY2022-2024 ---\n")
preview_250 <- dt[fiscal_year >= 2022 & fiscal_year <= 2024 &
                  bin_midpoint >= 200000 & bin_midpoint <= 300000,
                  .(avg_count = mean(count)), by = .(bin_lower, bin_upper)]
print(preview_250)

# --- Save cleaned data ---
fwrite(dt, file.path(DATA_DIR, "contract_bins_clean.csv"))
fwrite(period_means, file.path(DATA_DIR, "period_means.csv"))

cat("\nCleaned data saved.\n")
