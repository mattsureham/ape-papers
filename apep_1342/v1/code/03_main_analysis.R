# 03_main_analysis.R — Main regressions for apep_1342
# UK FCA HCSTC Price Cap: Supply-Side Destruction

source("00_packages.R")

data_dir <- "../data"

# Load cleaned data
market_panel <- readRDS(file.path(data_dir, "market_panel.rds"))
regional_panel <- readRDS(file.path(data_dir, "regional_panel.rds"))
firm_exits <- readRDS(file.path(data_dir, "firm_exits.rds"))
boe_panel <- readRDS(file.path(data_dir, "boe_panel.rds"))

# ============================================================================
# 1. Aggregate market-level event study
# ============================================================================
cat("=== Aggregate Market Event Study ===\n")

# Create event-time dummies (omit t=-1 as reference)
market_panel <- market_panel %>%
  mutate(
    event_time = t_relative,
    # Bin endpoints
    event_time_binned = pmax(pmin(event_time, 28), -12)
  )

# OLS regression: log outcomes on event-time dummies
# Omit t=-1 (2014Q4) as reference period
m1_loans <- feols(ln_loans ~ i(event_time_binned, ref = -1),
                  data = market_panel,
                  vcov = NW ~ yearqtr)

m1_firms <- feols(ln_firms ~ i(event_time_binned, ref = -1),
                  data = market_panel,
                  vcov = NW ~ yearqtr)

m1_value <- feols(ln_value ~ i(event_time_binned, ref = -1),
                  data = market_panel,
                  vcov = NW ~ yearqtr)

cat("\n--- Log Loans Event Study ---\n")
summary(m1_loans)

cat("\n--- Log Active Firms Event Study ---\n")
summary(m1_firms)

# ============================================================================
# 2. Phase decomposition: Cap effect vs Compensation effect
# ============================================================================
cat("\n=== Phase Decomposition ===\n")

# Simple phase decomposition (no phase-specific trends to avoid confusing signs)
market_panel <- market_panel %>%
  mutate(
    phase1 = as.integer(phase == "phase1_cap"),
    phase2 = as.integer(phase == "phase2_compensation"),
    phase3 = as.integer(phase == "phase3_steady_state"),
    trend = row_number()
  )

# Firm exit decomposition — phase dummies capture average shift from pre-cap
m2_firms <- feols(ln_firms ~ phase1 + phase2 + phase3,
                  data = market_panel,
                  vcov = NW ~ yearqtr)

cat("\n--- Firm Exit Phase Decomposition ---\n")
summary(m2_firms)

# Loan volume decomposition
m2_loans <- feols(ln_loans ~ phase1 + phase2 + phase3,
                  data = market_panel,
                  vcov = NW ~ yearqtr)

cat("\n--- Loan Volume Phase Decomposition ---\n")
summary(m2_loans)

# ============================================================================
# 3. Regional panel: High vs Low pre-cap penetration
# ============================================================================
cat("\n=== Regional Panel Analysis ===\n")

# Within the PSD006 period (all post-cap), test whether high-penetration
# regions show different trajectories
# This is cross-sectional variation in treatment intensity

# Create time trend within PSD006 window
regional_panel <- regional_panel %>%
  mutate(
    t = as.integer(factor(quarter)),
    region_id = as.integer(factor(region))
  )

# Region FE + time trend × penetration interaction
m3_regional <- feols(ln_loans ~ high_penetration:i(quarter) |
                       region + quarter,
                     data = regional_panel,
                     vcov = ~region)

cat("\n--- Regional Penetration × Time ---\n")
summary(m3_regional)

# Continuous penetration measure
m3_continuous <- feols(ln_loans ~ baseline_rate:i(quarter) |
                         region + quarter,
                       data = regional_panel,
                       vcov = ~region)

cat("\n--- Regional Continuous Penetration × Time ---\n")
summary(m3_continuous)

# ============================================================================
# 4. Supply Destruction Multiplier
# ============================================================================
cat("\n=== Supply Destruction Multiplier ===\n")

# FCA CBA prediction (CP14/10): 7-11% of borrowers would lose access
fca_predicted_loss_low <- 0.07
fca_predicted_loss_high <- 0.11

# Actual market collapse
pre_cap_peak_loans <- market_panel$total_loans_000[market_panel$quarter == "2013Q3"]
post_cap_trough_loans <- min(market_panel$total_loans_000[market_panel$phase == "phase3_steady_state"])
actual_loss_pct <- 1 - post_cap_trough_loans / pre_cap_peak_loans

# Multiplier
multiplier_low <- actual_loss_pct / fca_predicted_loss_high
multiplier_high <- actual_loss_pct / fca_predicted_loss_low

cat("  Pre-cap peak loans (2013Q3): ", pre_cap_peak_loans, "k\n")
cat("  Post-cap steady state minimum: ", post_cap_trough_loans, "k\n")
cat("  Actual volume decline: ", round(actual_loss_pct * 100, 1), "%\n")
cat("  FCA predicted loss: ", fca_predicted_loss_low * 100, "-",
    fca_predicted_loss_high * 100, "%\n")
cat("  Supply destruction multiplier: ", round(multiplier_low, 1), "x to ",
    round(multiplier_high, 1), "x\n")

# ============================================================================
# 5. Firm-level exit analysis
# ============================================================================
cat("\n=== Firm Exit Analysis ===\n")

# Quarterly exit counts by phase
exit_by_quarter <- firm_exits %>%
  count(exit_quarter, exit_phase) %>%
  arrange(exit_quarter)

cat("\n--- Exits by Quarter and Phase ---\n")
print(exit_by_quarter)

# Median time-to-exit by phase
cat("\n--- Median Months to Exit ---\n")
firm_exits %>%
  group_by(exit_phase) %>%
  summarise(
    n = n(),
    median_months = median(months_since_cap),
    mean_months = mean(months_since_cap),
    min_months = min(months_since_cap),
    max_months = max(months_since_cap)
  ) %>%
  print()

# ============================================================================
# 6. Write-off analysis (downstream consequence)
# ============================================================================
cat("\n=== Write-off Analysis ===\n")

boe_panel <- boe_panel %>%
  mutate(
    phase1 = as.integer(phase == "phase1_cap"),
    phase2 = as.integer(phase == "phase2_compensation"),
    phase3 = as.integer(phase == "phase3_steady_state")
  )

m5_writeoffs <- feols(ln_writeoffs ~ phase1 + phase2 + phase3,
                      data = boe_panel,
                      vcov = NW ~ yearqtr)

cat("\n--- Write-offs by Phase ---\n")
summary(m5_writeoffs)

# ============================================================================
# 7. Save diagnostics for validation
# ============================================================================
cat("\n=== Saving diagnostics ===\n")

diagnostics <- list(
  n_treated = n_distinct(firm_exits$firm_name),  # 20 major exits tracked
  n_pre = sum(market_panel$post_cap == 0),       # 12 pre-cap quarters
  n_obs = nrow(market_panel) + nrow(regional_panel),  # Total observations
  n_regions = n_distinct(regional_panel$region),
  n_quarters_market = nrow(market_panel),
  n_quarters_regional = n_distinct(regional_panel$quarter),
  actual_decline_pct = round(actual_loss_pct * 100, 1),
  supply_multiplier_range = paste0(round(multiplier_low, 1), "x-", round(multiplier_high, 1), "x")
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)

cat("Diagnostics saved.\n")

# Save regression objects for table generation
saveRDS(list(
  m1_loans = m1_loans,
  m1_firms = m1_firms,
  m1_value = m1_value,
  m2_firms = m2_firms,
  m2_loans = m2_loans,
  m3_regional = m3_regional,
  m3_continuous = m3_continuous,
  m5_writeoffs = m5_writeoffs
), file.path(data_dir, "regression_results.rds"))

cat("Regression results saved.\nDONE.\n")
