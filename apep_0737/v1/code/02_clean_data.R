## 02_clean_data.R — Construct analysis variables
## APEP paper apep_0737: Dodd-Frank $10B Bunching

source("00_packages.R")

bank_data <- readRDS("../data/bank_data.rds")
cat(sprintf("Loaded %s observations\n", format(nrow(bank_data), big.mark = ",")))

# --- Create bunching analysis bins ---
# Total assets in $100M bins from $1B to $25B
bank_data <- bank_data %>%
  mutate(
    # $100M bins (0.1B)
    asset_bin_100M = floor(total_assets_B * 10) / 10,
    # $250M bins for robustness
    asset_bin_250M = floor(total_assets_B * 4) / 4,
    # $500M bins for coarser view
    asset_bin_500M = floor(total_assets_B * 2) / 2,
    # Log assets
    log_assets = log(total_assets_B),
    # Distance from threshold in $B
    dist_from_10B = total_assets_B - 10,
    # Binary: below $10B
    below_10B = as.integer(total_assets_B < 10),
    # Binary: in bunching window ($8B-$10B)
    in_bunching_window = as.integer(total_assets_B >= 8 & total_assets_B < 10),
    # Binary: in hole region ($10B-$12B)
    in_hole_region = as.integer(total_assets_B >= 10 & total_assets_B < 12)
  )

# --- Period-specific aggregations for density estimation ---
# Count banks per bin per period
density_data <- bank_data %>%
  group_by(asset_bin_100M, period) %>%
  summarise(
    n_banks = n(),
    n_quarters = n_distinct(yearq),
    avg_banks_per_quarter = n() / n_distinct(yearq),
    .groups = "drop"
  )

# Also compute by year-quarter for panel analysis
density_panel <- bank_data %>%
  group_by(asset_bin_100M, year, quarter, yearq) %>%
  summarise(
    n_banks = n(),
    .groups = "drop"
  )

# --- Summary statistics ---
cat("\n=== Summary by Period ===\n")
bank_data %>%
  group_by(period) %>%
  summarise(
    n_obs = n(),
    n_banks = n_distinct(cert),
    n_quarters = n_distinct(yearq),
    mean_assets_B = mean(total_assets_B),
    median_assets_B = median(total_assets_B),
    pct_below_10B = mean(below_10B) * 100,
    .groups = "drop"
  ) %>%
  print()

# Banks in the bunching window ($8B-$12B) by period
cat("\n=== Banks in $8B-$12B Window by Period ===\n")
bank_data %>%
  filter(total_assets_B >= 8, total_assets_B <= 12) %>%
  group_by(period) %>%
  summarise(
    n_obs = n(),
    n_below_10 = sum(below_10B),
    n_above_10 = sum(1 - below_10B),
    pct_below = mean(below_10B) * 100,
    .groups = "drop"
  ) %>%
  print()

# --- Save ---
saveRDS(bank_data, "../data/bank_data_clean.rds")
saveRDS(density_data, "../data/density_data.rds")
saveRDS(density_panel, "../data/density_panel.rds")

cat("\nCleaned data saved.\n")
