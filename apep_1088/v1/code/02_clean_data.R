## 02_clean_data.R — Construct analysis panel using two-threshold comparison
## apep_1088: IRS 990 Threshold Reform and Nonprofit Growth
##
## REVISED STRATEGY: ProPublica data is sparse pre-2010 (IRS e-filing era starts ~2011).
## Instead of pre/post DiD, we compare bunching behavior at TWO thresholds:
##   $100K (old threshold — incentive REMOVED in 2010)
##   $200K (new threshold — incentive CREATED in 2010)
## Using rich 2011-2022 data with ~40K org-year observations.

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# STEP 1: Load raw revenue panel
# ============================================================
cat("=== Loading data ===\n")
revenue_data <- fread(file.path(data_dir, "revenue_panel.csv"))
cat(sprintf("Raw panel: %s rows, %s EINs\n",
    format(nrow(revenue_data), big.mark = ","),
    format(length(unique(revenue_data$ein)), big.mark = ",")))

# ============================================================
# STEP 2: Clean and filter
# ============================================================
cat("\n=== Cleaning ===\n")

panel <- revenue_data[!is.na(gross_receipts) & !is.na(tax_year) & !is.na(ein)]
panel <- panel[gross_receipts >= 0 & gross_receipts < 2e6]
panel <- panel[tax_year >= 2011 & tax_year <= 2022]
panel <- panel[!duplicated(panel[, .(ein, tax_year)])]

cat(sprintf("After cleaning: %s rows, %s EINs, years %d-%d\n",
    format(nrow(panel), big.mark = ","),
    format(length(unique(panel$ein)), big.mark = ","),
    min(panel$tax_year), max(panel$tax_year)))

# ============================================================
# STEP 3: Revenue density for bunching analysis
# ============================================================
cat("\n=== Computing revenue density ===\n")

# $2K bins spanning $20K to $350K
panel_range <- panel[gross_receipts >= 20000 & gross_receipts <= 350000]
panel_range[, rev_bin := floor(gross_receipts / 2000) * 2000]

# Split into periods
panel_range[, period := fcase(
  tax_year >= 2011 & tax_year <= 2014, "early",
  tax_year >= 2015 & tax_year <= 2018, "middle",
  tax_year >= 2019 & tax_year <= 2022, "late"
)]

density_all <- panel_range[, .(count = .N), by = .(rev_bin, period)][order(period, rev_bin)]

# Full-period density
density_full <- panel_range[, .(count = .N), by = rev_bin][order(rev_bin)]

fwrite(density_all, file.path(data_dir, "density_by_period.csv"))
fwrite(density_full, file.path(data_dir, "density_full.csv"))

# Print around thresholds
cat("\n--- Density around $100K (OLD threshold — no bunching expected) ---\n")
print(density_full[rev_bin >= 80000 & rev_bin <= 120000])

cat("\n--- Density around $200K (NEW threshold — bunching expected) ---\n")
print(density_full[rev_bin >= 180000 & rev_bin <= 220000])

# ============================================================
# STEP 4: Classify orgs for DiD-style growth analysis
# ============================================================
cat("\n=== Classifying organizations ===\n")

# Use 2011-2015 as baseline period to classify organizations (5 pre-periods for validation)
baseline <- panel[tax_year >= 2011 & tax_year <= 2015]
baseline_stats <- baseline[, .(
  mean_rev = mean(gross_receipts, na.rm = TRUE),
  n_years_base = .N
), by = ein]
baseline_stats <- baseline_stats[n_years_base >= 3]

# Groups based on proximity to the TWO thresholds:
# near_100k: orgs with mean rev $80K-$110K (near old threshold, now freed)
# near_200k: orgs with mean rev $170K-$220K (near new threshold, now constrained)
# control_low: orgs with mean rev $50K-$80K (far below both thresholds)
# control_mid: orgs with mean rev $120K-$160K (between thresholds, unconstrained)

baseline_stats[, group := fcase(
  mean_rev >= 80000 & mean_rev <= 110000, "near_100k",
  mean_rev >= 170000 & mean_rev <= 220000, "near_200k",
  mean_rev >= 50000 & mean_rev < 80000,   "control_low",
  mean_rev >= 120000 & mean_rev <= 160000, "control_mid",
  default = "other"
)]

cat("Group sizes:\n")
print(baseline_stats[, .N, by = group][order(-N)])

# ============================================================
# STEP 5: Construct analysis panel
# ============================================================
cat("\n=== Constructing analysis panel ===\n")

analysis <- merge(panel, baseline_stats[, .(ein, group, mean_rev, n_years_base)],
                  by = "ein", all.x = FALSE)

# Keep analysis groups only
analysis <- analysis[group %in% c("near_100k", "near_200k", "control_low", "control_mid")]

# Create variables
analysis[, `:=`(
  log_rev = log(gross_receipts + 1),
  log_exp = log(pmax(total_expenses, 1, na.rm = TRUE)),
  rev_growth = gross_receipts / mean_rev,
  year_fe = factor(tax_year),
  ein_fe = factor(ein),
  # For DiD comparing near_200k (constrained) vs control_mid (unconstrained)
  constrained = as.integer(group == "near_200k"),
  # Time periods: 2011-2013 = baseline, 2014+ = post
  post = as.integer(tax_year >= 2016)
)]

cat(sprintf("Analysis panel: %s rows, %s EINs\n",
    format(nrow(analysis), big.mark = ","),
    format(length(unique(analysis$ein)), big.mark = ",")))

cat("\nGroup composition:\n")
print(analysis[, .(
  n_orgs = uniqueN(ein),
  n_obs = .N,
  mean_revenue = round(mean(gross_receipts)),
  median_revenue = round(median(gross_receipts))
), by = group])

# ============================================================
# STEP 6: Transition probability analysis
# ============================================================
cat("\n=== Revenue transition probabilities ===\n")

# For orgs near $100K in 2011-2013: what fraction cross $100K by 2017-2022?
# For orgs near $200K in 2011-2013: what fraction cross $200K by 2017-2022?
# If $200K is a binding ceiling but $100K is not, crossing rate should be higher at $100K

near_100k_eins <- baseline_stats[group == "near_100k", ein]
near_200k_eins <- baseline_stats[group == "near_200k", ein]

late_data <- panel[tax_year >= 2017 & tax_year <= 2022]

# Crossing rates
cross_100k <- late_data[ein %in% near_100k_eins,
  .(ever_cross = as.integer(any(gross_receipts > 100000))), by = ein]
cross_200k <- late_data[ein %in% near_200k_eins,
  .(ever_cross = as.integer(any(gross_receipts > 200000))), by = ein]

rate_100k <- mean(cross_100k$ever_cross, na.rm = TRUE)
rate_200k <- mean(cross_200k$ever_cross, na.rm = TRUE)

cat(sprintf("Orgs near $100K: %.1f%% crossed $100K by 2017-2022 (N=%d)\n",
    rate_100k * 100, nrow(cross_100k)))
cat(sprintf("Orgs near $200K: %.1f%% crossed $200K by 2017-2022 (N=%d)\n",
    rate_200k * 100, nrow(cross_200k)))

transition_data <- data.table(
  threshold = c("$100K (freed)", "$200K (constrained)"),
  crossing_rate = c(rate_100k, rate_200k),
  n_orgs = c(nrow(cross_100k), nrow(cross_200k))
)
fwrite(transition_data, file.path(data_dir, "transition_rates.csv"))

# ============================================================
# STEP 7: Save analysis dataset
# ============================================================
fwrite(analysis, file.path(data_dir, "analysis_panel.csv"))

cat(sprintf("\nFinal analysis panel: %s obs, %s organizations\n",
    format(nrow(analysis), big.mark = ","),
    format(length(unique(analysis$ein)), big.mark = ",")))
cat("02_clean_data.R complete.\n")
