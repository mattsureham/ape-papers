# ==============================================================================
# 03_main_analysis.R — Main DiD and DDD regressions
# APEP-0570: Malaysia GST-to-SST Tax Pass-Through
# ==============================================================================

source("00_packages.R")

panel <- fread("../data/analysis_panel.csv")
panel[, date := as.Date(date)]
panel[, class_id := as.factor(class)]
panel[, date_id := as.factor(date)]

cat("=== Main Analysis ===\n")
cat("Panel:", nrow(panel), "obs,", uniqueN(panel$class), "classes,",
    uniqueN(panel$date), "months\n")

# ==============================================================================
# 1. DIFFERENCE-IN-DIFFERENCES: GST Removal (June 2018)
# ==============================================================================
# Treated: standard-rated products (Groups A + B)
# Control: zero-rated/exempt products (Group C)
# Post: June 2018 onward

cat("\n--- DiD: Effect of GST Removal on Prices ---\n")

# Specification 1: Basic DiD
m1 <- feols(log_cpi ~ treat_post_june | class_id + date_id,
            data = panel, cluster = ~class_id)

# Specification 2: Separate tax holiday and post-SST periods
m2 <- feols(log_cpi ~ treated:tax_holiday + treated:post_sept |
              class_id + date_id,
            data = panel, cluster = ~class_id)

# Specification 3: Full DDD — include SST interaction
m3 <- feols(log_cpi ~ treat_post_june + treat_sst_post_sept |
              class_id + date_id,
            data = panel, cluster = ~class_id)

# Specification 4: Separate all three periods × treatment
panel[, `:=`(
  gst_era = as.integer(date >= as.Date("2015-04-01") & date < as.Date("2018-06-01")),
  holiday_era = as.integer(date >= as.Date("2018-06-01") & date < as.Date("2018-09-01")),
  sst_era = as.integer(date >= as.Date("2018-09-01"))
)]

m4 <- feols(log_cpi ~ treated:gst_era + treated:holiday_era + treated:sst_era |
              class_id + date_id,
            data = panel, cluster = ~class_id)

# Specification 5: Full triple-diff with all interactions
m5 <- feols(log_cpi ~ treated:holiday_era + treated:sst_era +
              sst_covered:holiday_era + sst_covered:sst_era |
              class_id + date_id,
            data = panel, cluster = ~class_id)

cat("\nModel 1 (Basic DiD - GST removal):\n")
summary(m1)
cat("\nModel 2 (Separate tax holiday vs post-SST):\n")
summary(m2)
cat("\nModel 3 (DDD - with SST reimposition):\n")
summary(m3)
cat("\nModel 4 (Four-period design):\n")
summary(m4)
cat("\nModel 5 (Full triple-diff):\n")
summary(m5)

# Save model results
main_results <- data.table(
  model = c("Basic DiD", "Two-period DiD", "DDD", "Four-period", "Full Triple-Diff"),
  spec = 1:5,
  n_obs = sapply(list(m1, m2, m3, m4, m5), function(m) m$nobs),
  n_clusters = sapply(list(m1, m2, m3, m4, m5), function(m) m$nparams)
)

# ==============================================================================
# 2. EVENT STUDY
# ==============================================================================

cat("\n--- Event Study: Monthly Treatment Effects ---\n")

# Create event-time dummies (relative to May 2018 = -1)
# Reference month: May 2018 (last month of GST at 6%)
panel[, event_month := as.integer(12 * (year(date) - 2018) + month(date) - 5)]

# Cap at -36 to +36 for tractability
panel[, event_month_capped := pmax(pmin(event_month, 36), -36)]

# Drop the reference period (event_month == 0 means June 2018 in this coding,
# so reference = -1 = May 2018)
# Actually, let's set reference = 0 (May 2018) and event starts at 1 (June 2018)
# Recode: May 2018 = month 5 of 2018 → event_month should be 0 for May 2018
# event_month = months since May 2018
# May 2018 → 0, June 2018 → 1, April 2018 → -1, etc.
panel[, event_month := as.integer(12 * (year(date) - 2018) + month(date) - 5)]

# Trim for estimation
es_panel <- panel[event_month >= -36 & event_month <= 36]

# Event study: treated × event-time dummies
es1 <- feols(log_cpi ~ i(event_month, treated, ref = 0) |
               class_id + date_id,
             data = es_panel, cluster = ~class_id)

cat("\nEvent study coefficients:\n")
summary(es1)

# Extract event study coefficients for plotting
es_coefs <- as.data.table(coeftable(es1))
es_coefs[, term := rownames(coeftable(es1))]
# Parse event_month from coefficient names
es_coefs[, event_month := as.integer(gsub(".*::(-?\\d+):.*", "\\1", term))]
es_coefs <- es_coefs[!is.na(event_month)]
setnames(es_coefs, c("Estimate", "Std. Error"), c("estimate", "se"))
es_coefs[, `:=`(ci_lo = estimate - 1.96 * se, ci_hi = estimate + 1.96 * se)]

fwrite(es_coefs[, .(event_month, estimate, se, ci_lo, ci_hi)],
       "../data/event_study_coefs.csv")

# ==============================================================================
# 3. EVENT STUDY BY GROUP (A vs B vs C)
# ==============================================================================

cat("\n--- Event Study by Product Group ---\n")

# Run interacted event study in full sample
# Group A and B coefficients are relative to Group C (absorbed by date FE)
es_panel[, group_A := as.integer(group == "A")]
es_panel[, group_B := as.integer(group == "B")]

es_groups <- feols(log_cpi ~ i(event_month, group_A, ref = 0) +
                     i(event_month, group_B, ref = 0) |
                     class_id + date_id,
                   data = es_panel, cluster = ~class_id)

# Extract coefficients for each group
extract_es_group <- function(model, var_pattern, grp) {
  ct <- coeftable(model)
  rows <- grep(var_pattern, rownames(ct))
  dt <- data.table(
    term = rownames(ct)[rows],
    estimate = ct[rows, "Estimate"],
    se = ct[rows, "Std. Error"]
  )
  dt[, event_month := as.integer(gsub(".*::(-?\\d+):.*", "\\1", term))]
  dt <- dt[!is.na(event_month)]
  dt[, `:=`(ci_lo = estimate - 1.96 * se, ci_hi = estimate + 1.96 * se,
            group = grp)]
  return(dt[, .(event_month, estimate, se, ci_lo, ci_hi, group)])
}

es_by_group <- rbind(
  extract_es_group(es_groups, "group_A", "A"),
  extract_es_group(es_groups, "group_B", "B")
)

fwrite(es_by_group, "../data/event_study_by_group.csv")

# ==============================================================================
# 4. PASS-THROUGH RATE CALCULATION
# ==============================================================================

cat("\n--- Pass-Through Rate Estimates ---\n")

# GST was 6%, so full pass-through from removal = log(1) - log(1.06) ≈ -0.0583
gst_rate <- 0.06
full_passthrough_removal <- -log(1 + gst_rate)  # -0.0583

# DiD estimate for GST removal
beta_removal <- coef(m1)["treat_post_june"]

# Pass-through rate = beta / full_expected_change
ptr_removal <- beta_removal / full_passthrough_removal

cat(sprintf("\nGST removal (full pass-through benchmark): %.4f\n", full_passthrough_removal))
cat(sprintf("DiD estimate (beta_1): %.4f (SE = %.4f)\n",
            beta_removal, se(m1)["treat_post_june"]))
cat(sprintf("Pass-through rate: %.1f%%\n", ptr_removal * 100))

# For SST reimposition
# SST rate varies by product (5-10% for goods, 6% for services)
# Use average effective rate from price recovery
beta_sst <- coef(m3)["treat_sst_post_sept"]
cat(sprintf("\nSST reimposition increment (beta_2): %.4f (SE = %.4f)\n",
            beta_sst, se(m3)["treat_sst_post_sept"]))

# Asymmetry test: compare |removal pass-through| vs |reimposition pass-through|
# Note: SST is typically lower effective rate than GST (single-stage vs multi-stage)
# and narrower base
cat(sprintf("\nAsymmetry test:\n"))
cat(sprintf("  |Price drop from GST removal|: %.4f\n", abs(beta_removal)))
cat(sprintf("  |Price rise from SST reimposition| (Group A vs B): %.4f\n", abs(beta_sst)))
cat(sprintf("  Ratio (rise/drop): %.3f\n", abs(beta_sst) / abs(beta_removal)))

# Save pass-through estimates
pt_results <- data.table(
  parameter = c("beta_removal", "beta_sst", "full_passthrough_benchmark",
                "ptr_removal", "asymmetry_ratio"),
  estimate = c(beta_removal, beta_sst, full_passthrough_removal,
               ptr_removal, abs(beta_sst) / abs(beta_removal)),
  se = c(se(m1)["treat_post_june"], se(m3)["treat_sst_post_sept"],
         NA, NA, NA)
)
fwrite(pt_results, "../data/passthrough_estimates.csv")

# ==============================================================================
# 5. SUMMARY STATISTICS TABLE
# ==============================================================================

cat("\n--- Summary Statistics ---\n")

# Compute summary stats by group (na.rm = TRUE for any missing CPI values)
summ_stats <- panel[, .(
  mean_index = mean(index, na.rm = TRUE),
  sd_index = sd(index, na.rm = TRUE),
  mean_log = mean(log_cpi, na.rm = TRUE),
  sd_log = sd(log_cpi, na.rm = TRUE),
  min_index = min(index, na.rm = TRUE),
  max_index = max(index, na.rm = TRUE),
  n_months = uniqueN(date),
  n_classes = uniqueN(class)
), by = .(group)]

# Overall
summ_overall <- panel[, .(
  group = "All",
  mean_index = mean(index, na.rm = TRUE),
  sd_index = sd(index, na.rm = TRUE),
  mean_log = mean(log_cpi, na.rm = TRUE),
  sd_log = sd(log_cpi, na.rm = TRUE),
  min_index = min(index, na.rm = TRUE),
  max_index = max(index, na.rm = TRUE),
  n_months = uniqueN(date),
  n_classes = uniqueN(class)
)]

summ_stats <- rbind(summ_stats, summ_overall)

# By treatment period
summ_period <- panel[, .(
  mean_index = mean(index, na.rm = TRUE),
  sd_index = sd(index, na.rm = TRUE),
  n_obs = .N
), by = .(group, period = fcase(
  date < as.Date("2015-04-01"), "Pre-GST (2010-2015)",
  date >= as.Date("2015-04-01") & date < as.Date("2018-06-01"), "GST era (2015-2018)",
  date >= as.Date("2018-06-01") & date < as.Date("2018-09-01"), "Tax holiday (Jun-Aug 2018)",
  date >= as.Date("2018-09-01"), "SST era (2018+)"
))]

fwrite(summ_stats, "../data/summary_stats.csv")
fwrite(summ_period, "../data/summary_stats_period.csv")

cat("\nSummary statistics by group:\n")
print(summ_stats)

cat("\nSummary statistics by period:\n")
print(summ_period[order(group, period)])

# Save main regression results for table generation
save(m1, m2, m3, m4, m5, es1,
     file = "../data/main_models.RData")

cat("\n=== Main analysis complete ===\n")
