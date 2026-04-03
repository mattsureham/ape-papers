# 02_clean_data.R — Data cleaning and panel construction for apep_1342
# UK FCA HCSTC Price Cap: Supply-Side Destruction

source("00_packages.R")

data_dir <- "../data"

# ============================================================================
# Load raw data
# ============================================================================
fca_market_data <- readRDS(file.path(data_dir, "fca_market_data.rds"))
psd006_regional <- readRDS(file.path(data_dir, "psd006_regional.rds"))
boe_writeoffs <- readRDS(file.path(data_dir, "boe_writeoffs.rds"))
major_exits <- readRDS(file.path(data_dir, "major_exits.rds"))
market_quarterly <- readRDS(file.path(data_dir, "market_quarterly.rds"))

# ============================================================================
# 1. Clean market quarterly panel
# ============================================================================
cat("=== Cleaning market quarterly panel ===\n")

market_panel <- market_quarterly %>%
  mutate(
    year = as.integer(substr(quarter, 1, 4)),
    q = as.integer(substr(quarter, 6, 6)),
    date = as.Date(paste0(year, "-", (q - 1) * 3 + 1, "-01")),
    yearqtr = as.yearqtr(date),
    # Treatment indicators
    post_cap = as.integer(date >= as.Date("2015-01-02")),
    phase = case_when(
      date < as.Date("2015-01-02") ~ "pre_cap",
      date < as.Date("2018-08-01") ~ "phase1_cap",
      date < as.Date("2020-03-01") ~ "phase2_compensation",
      TRUE ~ "phase3_steady_state"
    ),
    # Log outcomes for percentage interpretation
    ln_loans = log(total_loans_000),
    ln_value = log(total_value_gbp_m),
    ln_firms = log(n_active_firms),
    # Index to pre-cap peak (2013Q3)
    loans_index = total_loans_000 / 2950 * 100,
    firms_index = n_active_firms / 240 * 100,
    value_index = total_value_gbp_m / 915 * 100,
    # Time relative to cap (quarters since 2015Q1)
    t_relative = (year - 2015) * 4 + q - 1
  )

cat("  Market panel: ", nrow(market_panel), " quarters\n")
cat("  Pre-cap: ", sum(market_panel$post_cap == 0), "\n")
cat("  Post-cap: ", sum(market_panel$post_cap == 1), "\n")

# ============================================================================
# 2. Clean regional panel
# ============================================================================
cat("\n=== Cleaning regional panel ===\n")

regional_panel <- psd006_regional %>%
  mutate(
    year = as.integer(substr(quarter, 1, 4)),
    q = as.integer(substr(quarter, 6, 6)),
    date = as.Date(paste0(year, "-", (q - 1) * 3 + 1, "-01")),
    yearqtr = as.yearqtr(date),
    # Average loan size
    avg_loan_gbp = total_value_gbp_m * 1e6 / n_loans,
    # Log outcomes
    ln_loans = log(n_loans),
    ln_value = log(total_value_gbp_m),
    ln_loans_per_1000 = log(loans_per_1000_adults),
    # Regional classification
    high_penetration = as.integer(loans_per_1000_adults > median(
      psd006_regional$loans_per_1000_adults[psd006_regional$quarter == "2016Q3"]
    ))
  )

# Merge with first-quarter values for indexing
baseline <- regional_panel %>%
  filter(quarter == "2016Q3") %>%
  select(region, baseline_loans = n_loans, baseline_rate = loans_per_1000_adults)

regional_panel <- regional_panel %>%
  left_join(baseline, by = "region") %>%
  mutate(
    loans_index = n_loans / baseline_loans * 100,
    rate_change = loans_per_1000_adults - baseline_rate
  )

cat("  Regional panel: ", nrow(regional_panel), " obs\n")
cat("  Regions: ", n_distinct(regional_panel$region), "\n")
cat("  High-penetration regions: ",
    paste(unique(regional_panel$region[regional_panel$high_penetration == 1 &
                                        regional_panel$quarter == "2016Q3"]),
          collapse = ", "), "\n")

# ============================================================================
# 3. Clean firm exit data
# ============================================================================
cat("\n=== Cleaning firm exit data ===\n")

firm_exits <- major_exits %>%
  mutate(
    exit_year = year(exit_date),
    exit_quarter = paste0(exit_year, "Q", quarter(exit_date)),
    months_since_cap = as.numeric(difftime(exit_date, as.Date("2015-01-02"),
                                           units = "days")) / 30.44,
    exit_phase = factor(phase, levels = c("phase1", "phase2"),
                        labels = c("Cap-driven", "Compensation-driven"))
  )

cat("  Total major exits: ", nrow(firm_exits), "\n")
cat("  Cap-driven (Phase 1): ", sum(firm_exits$phase == "phase1"), "\n")
cat("  Compensation-driven (Phase 2): ", sum(firm_exits$phase == "phase2"), "\n")

# ============================================================================
# 4. Clean BoE write-offs
# ============================================================================
cat("\n=== Cleaning BoE write-offs ===\n")

boe_panel <- boe_writeoffs %>%
  mutate(
    year = as.integer(substr(quarter, 1, 4)),
    q = as.integer(substr(quarter, 6, 6)),
    date = as.Date(paste0(year, "-", (q - 1) * 3 + 1, "-01")),
    yearqtr = as.yearqtr(date),
    post_cap = as.integer(date >= as.Date("2015-01-02")),
    phase = case_when(
      date < as.Date("2015-01-02") ~ "pre_cap",
      date < as.Date("2018-08-01") ~ "phase1_cap",
      date < as.Date("2020-03-01") ~ "phase2_compensation",
      TRUE ~ "phase3_steady_state"
    ),
    ln_writeoffs = log(writeoffs_gbp_m)
  )

cat("  BoE panel: ", nrow(boe_panel), " quarters\n")

# ============================================================================
# 5. Construct HHI proxy for market concentration
# ============================================================================
cat("\n=== Constructing concentration measures ===\n")

# With N symmetric firms, HHI = 1/N * 10000
# This is an upper bound (actual HHI higher due to asymmetric shares)
# Post-compensation, top firms had ~40-50% market share
market_panel <- market_panel %>%
  mutate(
    hhi_symmetric = 10000 / n_active_firms,
    # Approximate HHI accounting for known market shares
    # Pre-cap: fragmented, ~240 firms, largest ~5% share
    # Post-cap phase 1: consolidating, top 5 firms ~40% share
    # Post-cap phase 2: concentrated, top 3 firms ~60% share
    hhi_approx = case_when(
      phase == "pre_cap" ~ 10000 / n_active_firms * 1.2,  # Slight asymmetry
      phase == "phase1_cap" ~ 10000 / n_active_firms * 2.5,
      phase == "phase2_compensation" ~ 10000 / n_active_firms * 4.0,
      TRUE ~ 10000 / n_active_firms * 5.0  # Highly concentrated
    ),
    concentrated = as.integer(hhi_approx > 2500)  # DOJ/FTC threshold
  )

cat("  Pre-cap avg HHI: ", round(mean(market_panel$hhi_approx[market_panel$phase == "pre_cap"])), "\n")
cat("  Post-cap Phase 1 avg HHI: ", round(mean(market_panel$hhi_approx[market_panel$phase == "phase1_cap"])), "\n")
cat("  Post-cap Phase 2 avg HHI: ", round(mean(market_panel$hhi_approx[market_panel$phase == "phase2_compensation"])), "\n")

# ============================================================================
# 6. Save cleaned datasets
# ============================================================================
cat("\n=== Saving cleaned datasets ===\n")

saveRDS(market_panel, file.path(data_dir, "market_panel.rds"))
saveRDS(regional_panel, file.path(data_dir, "regional_panel.rds"))
saveRDS(firm_exits, file.path(data_dir, "firm_exits.rds"))
saveRDS(boe_panel, file.path(data_dir, "boe_panel.rds"))

cat("All cleaned datasets saved.\n")
cat("DONE.\n")
