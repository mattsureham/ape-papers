# 03_main_analysis.R — Event study + windfall estimation
# apep_1346: The Lag Windfall

source("00_packages.R")

data_dir <- "../data"

# =============================================================================
# Load cleaned data
# =============================================================================
event_panel <- fread(file.path(data_dir, "event_study_panel.csv"))
entry_drugs <- fread(file.path(data_dir, "generic_entry_events.csv"))
entry_spending <- fread(file.path(data_dir, "entry_drugs_spending.csv"))

cat("Event study panel:", nrow(event_panel), "obs,",
    uniqueN(event_panel$hcpcs), "drugs\n")
cat("Generic entry events:", nrow(entry_drugs), "\n")

# =============================================================================
# KEY INSIGHT: Reframe the event
# =============================================================================
# What we detect as "event_time = 0" is when the ASP formula CATCHES UP to
# generic entry (the price drop quarter). The actual generic entry happened
# ~2 quarters earlier. The lag windfall is the elevated payment at ET -2 and -1.
#
# Reinterpretation:
#   ET < -2: Pre-generic (brand only, stable payment)
#   ET -2, -1: LAG WINDOW (generic available, but ASP still uses old data)
#   ET 0: ASP adjustment (payment drops as generic prices flow through)
#   ET > 0: Post-adjustment equilibrium

# =============================================================================
# 1. Event study regression (within-drug)
# =============================================================================
cat("\n=== Event Study Regression ===\n")

# Drop event_time = -3 as reference period (last "clean" pre-entry quarter)
event_panel[, et_factor := factor(event_time)]
event_panel[, et_factor := relevel(et_factor, ref = "-3")]

# Model 1: Event study with drug FEs
# Note: Quarter FEs not included because with staggered events,
# calendar time FEs can absorb identifying variation
m1 <- feols(norm_payment ~ et_factor | hcpcs,
            data = event_panel,
            cluster = ~ hcpcs)

cat("\nEvent study coefficients (relative to ET = -3):\n")
print(summary(m1))

# =============================================================================
# 2. Windfall quantification
# =============================================================================
cat("\n=== Windfall Quantification ===\n")

# For each drug, compute:
# (a) Post-adjustment equilibrium: average payment at ET 2-4
# (b) Lag-window payment: average payment at ET -2, -1
# (c) Windfall per unit = lag_window_payment - post_eq_payment
# (d) Windfall as % of pre-entry payment

drug_windfall <- event_panel[, .(
  # Pre-entry baseline (ET -6 to -3)
  pre_baseline = mean(payment_limit[event_time >= -6 & event_time <= -3], na.rm = TRUE),

  # Lag window (ET -2 and -1: generic available, old ASP still used)
  lag_window_payment = mean(payment_limit[event_time >= -2 & event_time <= -1], na.rm = TRUE),

  # Adjustment quarter (ET 0)
  adjustment_payment = mean(payment_limit[event_time == 0], na.rm = TRUE),

  # Post-adjustment equilibrium (ET 2-4)
  post_eq_payment = mean(payment_limit[event_time >= 2 & event_time <= 4], na.rm = TRUE),

  # Number of observations
  n_pre = sum(event_time >= -6 & event_time <= -3),
  n_lag = sum(event_time >= -2 & event_time <= -1),
  n_post = sum(event_time >= 2 & event_time <= 4)
), by = hcpcs]

# Require at least 1 obs in each window
drug_windfall <- drug_windfall[n_pre >= 1 & n_lag >= 1 & n_post >= 1]

# Compute windfall measures
drug_windfall[, windfall_per_unit := lag_window_payment - post_eq_payment]
drug_windfall[, windfall_pct := (lag_window_payment - post_eq_payment) / pre_baseline]
drug_windfall[, drop_at_adjustment := (adjustment_payment - pre_baseline) / pre_baseline]
drug_windfall[, total_drop := (post_eq_payment - pre_baseline) / pre_baseline]

# Winsorize at 1st/99th percentile to remove outliers
winsorize <- function(x, p = 0.01) {
  q <- quantile(x, c(p, 1 - p), na.rm = TRUE)
  pmin(pmax(x, q[1]), q[2])
}
drug_windfall[, windfall_pct_w := winsorize(windfall_pct)]

cat("\nDrug-level windfall statistics (N =", nrow(drug_windfall), "drugs):\n")
cat(sprintf("  Mean windfall per unit: $%.2f\n",
            mean(drug_windfall$windfall_per_unit, na.rm = TRUE)))
cat(sprintf("  Median windfall per unit: $%.2f\n",
            median(drug_windfall$windfall_per_unit, na.rm = TRUE)))
cat(sprintf("  Mean windfall as %% of pre-entry: %.1f%%\n",
            mean(drug_windfall$windfall_pct, na.rm = TRUE) * 100))
cat(sprintf("  Median windfall as %% of pre-entry: %.1f%%\n",
            median(drug_windfall$windfall_pct, na.rm = TRUE) * 100))
cat(sprintf("  Share with positive windfall: %.1f%%\n",
            mean(drug_windfall$windfall_per_unit > 0, na.rm = TRUE) * 100))

# =============================================================================
# 3. Aggregate cost to Medicare
# =============================================================================
cat("\n=== Aggregate Cost Estimation ===\n")

# Merge spending data
agg <- merge(drug_windfall, entry_spending,
             by = "hcpcs", all.x = TRUE)

# Use average annual spending to approximate quarterly spending during lag window
# For each year available, compute spending per dosage unit
spending_years <- 2019:2023
agg[, avg_annual_spending := rowMeans(
  .SD, na.rm = TRUE
), .SDcols = paste0("Tot_Spndng_", spending_years)]

agg[, avg_annual_units := rowMeans(
  .SD, na.rm = TRUE
), .SDcols = paste0("Tot_Dsg_Unts_", spending_years)]

# Quarterly spending ≈ annual / 4
agg[, quarterly_units := avg_annual_units / 4]

# Total windfall cost per drug = windfall_per_unit × quarterly_units × 2 quarters
agg[, total_drug_windfall := windfall_per_unit * quarterly_units * 2]

# Aggregate
agg_matched <- agg[!is.na(avg_annual_spending) & !is.na(windfall_per_unit)]
cat("Drugs with spending data:", nrow(agg_matched), "\n")

total_windfall <- sum(agg_matched$total_drug_windfall, na.rm = TRUE)
cat(sprintf("Estimated total windfall across %d drugs: $%.1f million\n",
            nrow(agg_matched), total_windfall / 1e6))
cat(sprintf("Average windfall per drug: $%.0f thousand\n",
            mean(agg_matched$total_drug_windfall, na.rm = TRUE) / 1e3))

# Annual cost: divide by years of observation (~7 years, 2017-2024)
# But not all entries happen every year. Better: total entries over period
annual_cost <- total_windfall / 7
cat(sprintf("Estimated annual Medicare cost of lag formula: $%.1f million\n",
            annual_cost / 1e6))

# =============================================================================
# 4. Heterogeneity: by size of generic price discount
# =============================================================================
cat("\n=== Heterogeneity by Price Discount Size ===\n")

# Split by magnitude of the drop (proxy for brand-generic price gap)
drug_windfall[, drop_tercile := cut(total_drop,
                                    quantile(total_drop, c(0, 1/3, 2/3, 1), na.rm = TRUE),
                                    labels = c("Small drop", "Medium drop", "Large drop"),
                                    include.lowest = TRUE)]

het_summary <- drug_windfall[!is.na(drop_tercile), .(
  n = .N,
  mean_windfall_pct = mean(windfall_pct, na.rm = TRUE),
  se_windfall_pct = sd(windfall_pct, na.rm = TRUE) / sqrt(.N),
  mean_pre_baseline = mean(pre_baseline, na.rm = TRUE),
  mean_total_drop = mean(total_drop, na.rm = TRUE)
), by = drop_tercile]

cat("\nWindfall by price discount tercile:\n")
print(het_summary)

# =============================================================================
# 5. Cross-sectional regression: windfall predicts payment persistence
# =============================================================================
cat("\n=== Cross-Sectional: Does Windfall Size Predict Payment Persistence? ===\n")

# For each drug, compute payment persistence: how long until payment reaches
# post-eq level (i.e., how many quarters after ET 0 until norm_payment < threshold)
persistence <- event_panel[event_time >= 0, .(
  # Payment at ET 0, 1, 2 relative to post-eq
  payment_et0 = mean(norm_payment[event_time == 0], na.rm = TRUE),
  payment_et1 = mean(norm_payment[event_time == 1], na.rm = TRUE),
  payment_et2 = mean(norm_payment[event_time == 2], na.rm = TRUE),
  # Speed of adjustment: % of total drop happening at ET 0
  adjustment_speed = mean(
    (norm_payment[event_time == -1] - norm_payment[event_time == 0]) /
    (norm_payment[event_time == -1] - norm_payment[event_time == 2]),
    na.rm = TRUE
  )
), by = hcpcs]

persistence <- merge(persistence, drug_windfall, by = "hcpcs")

# Model 2: Does larger price gap → larger windfall?
m2 <- feols(windfall_pct ~ total_drop, data = drug_windfall)
cat("\nWindfall % ~ Total Drop:\n")
print(summary(m2))

# Model 3: Does windfall size vary with pre-entry payment level?
m3 <- feols(windfall_pct ~ log(pre_baseline) + total_drop, data = drug_windfall)
cat("\nWindfall % ~ log(Pre-Baseline) + Total Drop:\n")
print(summary(m3))

# =============================================================================
# 6. Save regression results and diagnostics
# =============================================================================

# Write diagnostics.json
n_treated <- uniqueN(event_panel$hcpcs)
n_pre <- sum(event_panel$event_time < 0)
n_obs <- nrow(event_panel)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = length(unique(event_panel$event_time[event_panel$event_time < 0])),
  n_obs = n_obs
)
write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

# Save windfall data
fwrite(drug_windfall, file.path(data_dir, "drug_windfall.csv"))
fwrite(het_summary, file.path(data_dir, "heterogeneity_summary.csv"))

# Save regression objects
saveRDS(list(m1 = m1, m2 = m2, m3 = m3),
        file.path(data_dir, "regression_results.rds"))

cat("\nMain analysis complete.\n")
