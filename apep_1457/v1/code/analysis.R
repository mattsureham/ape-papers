## ============================================================================
## Insuring Against Nothing: Crop Insurance Bunching at the 75% Subsidy Kink
## Main Analysis Script
## ============================================================================

library(data.table)

## --- 1. DATA LOADING --------------------------------------------------------

data_dir <- file.path(dirname(getwd()), "data")
files <- list.files(data_dir, pattern = "^sobcov.*\\.txt$", full.names = TRUE)
cat("Found", length(files), "data files\n")

col_names <- c("year", "state_fips", "state_abbr", "county_code", "county_name",
               "crop_code", "crop_name", "plan_code", "plan_abbr",
               "cov_category", "delivery_type", "coverage_level",
               "policies_sold", "policies_earning", "policies_indemnified",
               "units_earning", "units_indemnified", "quantity_type",
               "net_quantity", "endorsed_companion_acres",
               "liability", "total_premium", "subsidy", "state_private_subsidy",
               "additional_subsidy", "efa_discount", "indemnity", "loss_ratio")

col_classes <- c("integer", "character", "character", "character", "character",
                 "character", "character", "character", "character",
                 "character", "character", "numeric",
                 "integer", "integer", "integer",
                 "integer", "integer", "character",
                 "numeric", "numeric",
                 "numeric", "numeric", "numeric", "numeric",
                 "numeric", "numeric", "numeric", "numeric")

# Read all files
dt_list <- lapply(files, function(f) {
  cat("  Reading:", basename(f), "\n")
  tryCatch({
    d <- fread(f, sep = "|", header = FALSE, col.names = col_names,
               colClasses = col_classes, strip.white = TRUE)
    d
  }, error = function(e) {
    cat("    ERROR:", conditionMessage(e), "\n")
    NULL
  })
})

# Remove NULLs and bind
dt_list <- dt_list[!sapply(dt_list, is.null)]
if (length(dt_list) == 0) stop("No data files loaded successfully")
sob <- rbindlist(dt_list, fill = TRUE)
cat("Total records:", nrow(sob), "\n")

## --- 2. FILTER TO ANALYSIS SAMPLE -------------------------------------------

# Major crops: Corn (0041), Soybeans (0081), Wheat (0011), Cotton (0021)
major_crops <- c("0041", "0081", "0011", "0021")
crop_labels <- c("0041" = "Corn", "0081" = "Soybeans", "0011" = "Wheat", "0021" = "Cotton")

# Buyup coverage only (A), exclude CAT
# Standard coverage levels: 50-85% in 5pp increments
standard_levels <- c(0.50, 0.55, 0.60, 0.65, 0.70, 0.75, 0.80, 0.85)

d <- sob[crop_code %in% major_crops &
         grepl("A", cov_category) &
         coverage_level %in% standard_levels &
         year >= 2000 & year <= 2023]

d[, crop_label := crop_labels[crop_code]]
d[, cov_pct := as.integer(coverage_level * 100)]

cat("Analysis sample:", nrow(d), "records\n")
cat("Years:", range(d$year), "\n")
cat("Crops:", unique(d$crop_label), "\n")

## --- 3. AGGREGATE TO COVERAGE LEVEL × YEAR ----------------------------------

# Aggregate policies and financials by coverage level and year
agg_yr <- d[, .(
  policies  = sum(policies_earning, na.rm = TRUE),
  liability = sum(liability, na.rm = TRUE),
  premium   = sum(total_premium, na.rm = TRUE),
  subsidy_amt = sum(subsidy, na.rm = TRUE),
  indemnity = sum(indemnity, na.rm = TRUE),
  sco_acres = sum(endorsed_companion_acres, na.rm = TRUE)
), by = .(year, cov_pct)]

agg_yr[, subsidy_rate := ifelse(premium > 0, subsidy_amt / premium, NA_real_)]
agg_yr[, loss_ratio_calc := ifelse(premium > 0, indemnity / premium, NA_real_)]
agg_yr[, farmer_premium := premium - subsidy_amt]

# Total policies per year (for shares)
agg_yr[, total_policies_year := sum(policies), by = year]
agg_yr[, share := policies / total_policies_year]

## --- 4. POOLED COVERAGE DISTRIBUTION ----------------------------------------

agg_pool <- agg_yr[, .(
  policies  = sum(policies),
  premium   = sum(premium),
  subsidy_amt = sum(subsidy_amt),
  indemnity = sum(indemnity),
  sco_acres = sum(sco_acres)
), by = cov_pct]

agg_pool[, subsidy_rate := subsidy_amt / premium]
agg_pool[, share := policies / sum(policies)]
agg_pool[, loss_ratio := indemnity / premium]

cat("\n=== POOLED COVERAGE DISTRIBUTION (2000-2023) ===\n")
print(agg_pool[order(cov_pct), .(cov_pct, policies, share = round(share, 4),
                                  subsidy_rate = round(subsidy_rate, 4),
                                  loss_ratio = round(loss_ratio, 4))])

## --- 5. BUNCHING ESTIMATION -------------------------------------------------

# Bunching at 75%: estimate counterfactual using polynomial fitted to other levels

bunching_estimate <- function(counts, levels, bunch_point = 75,
                              exclude_window = c(75, 75), poly_order = 5) {
  # counts: named vector of policy counts by coverage level
  # levels: coverage levels (e.g., 50, 55, ..., 85)

  # Exclude the bunching region
  include <- levels < exclude_window[1] | levels > exclude_window[2]

  # Fit polynomial to included levels
  fit_data <- data.frame(level = levels[include], count = counts[include])

  if (nrow(fit_data) < poly_order + 1) {
    # Not enough points for this polynomial order
    poly_order <- nrow(fit_data) - 1
  }

  fit <- lm(count ~ poly(level, poly_order, raw = TRUE), data = fit_data)

  # Predict counterfactual at bunching point
  cf <- predict(fit, newdata = data.frame(level = bunch_point))

  # Observed at bunching point
  obs <- counts[levels == bunch_point]

  # Excess mass
  excess <- obs - cf
  excess_ratio <- excess / cf  # b = B / h0

  list(observed = obs, counterfactual = cf, excess = excess,
       excess_ratio = excess_ratio, poly_order = poly_order)
}

# Bootstrap standard errors
bootstrap_bunching <- function(data, year_range, bunch_point = 75,
                               exclude_window = c(75, 75), poly_order = 5,
                               n_boot = 500) {
  # data: agg_yr with year, cov_pct, policies
  sub <- data[year >= year_range[1] & year <= year_range[2]]
  years <- unique(sub$year)

  # Point estimate using all data
  pool <- sub[, .(policies = sum(policies)), by = cov_pct][order(cov_pct)]
  levels <- pool$cov_pct
  counts <- pool$policies

  point_est <- bunching_estimate(counts, levels, bunch_point, exclude_window, poly_order)

  # Bootstrap: resample years with replacement
  boot_b <- numeric(n_boot)
  for (i in seq_len(n_boot)) {
    boot_years <- sample(years, length(years), replace = TRUE)
    boot_data <- rbindlist(lapply(boot_years, function(y) sub[year == y]))
    boot_pool <- boot_data[, .(policies = sum(policies)), by = cov_pct][order(cov_pct)]

    # Ensure all levels present
    boot_counts <- merge(data.table(cov_pct = levels),
                         boot_pool, by = "cov_pct", all.x = TRUE)
    boot_counts[is.na(policies), policies := 0]
    boot_counts <- boot_counts[order(cov_pct)]

    tryCatch({
      b <- bunching_estimate(boot_counts$policies, boot_counts$cov_pct,
                             bunch_point, exclude_window, poly_order)
      boot_b[i] <- b$excess_ratio
    }, error = function(e) {
      boot_b[i] <<- NA
    })
  }

  boot_b <- boot_b[!is.na(boot_b)]

  list(estimate = point_est,
       se = sd(boot_b),
       ci_lower = quantile(boot_b, 0.025),
       ci_upper = quantile(boot_b, 0.975),
       n_boot_valid = length(boot_b))
}

cat("\n=== BUNCHING ESTIMATION ===\n")

# Main estimate: full period
set.seed(42)
main_bunch <- bootstrap_bunching(agg_yr, c(2000, 2023), poly_order = 5, n_boot = 500)
cat("\nFull Period (2000-2023):\n")
cat("  Observed at 75%:", format(main_bunch$estimate$observed, big.mark = ","), "policies\n")
cat("  Counterfactual:", format(round(main_bunch$estimate$counterfactual), big.mark = ","), "policies\n")
cat("  Excess mass:", format(round(main_bunch$estimate$excess), big.mark = ","), "policies\n")
cat("  Excess mass ratio (b):", round(main_bunch$estimate$excess_ratio, 3), "\n")
cat("  Bootstrap SE:", round(main_bunch$se, 3), "\n")
cat("  95% CI: [", round(main_bunch$ci_lower, 3), ",", round(main_bunch$ci_upper, 3), "]\n")

# Pre-2014 (before SCO)
pre_bunch <- bootstrap_bunching(agg_yr, c(2000, 2013), poly_order = 5, n_boot = 500)
cat("\nPre-2014 (2000-2013):\n")
cat("  Excess mass ratio (b):", round(pre_bunch$estimate$excess_ratio, 3), "\n")
cat("  Bootstrap SE:", round(pre_bunch$se, 3), "\n")

# Post-2014 (after SCO)
post_bunch <- bootstrap_bunching(agg_yr, c(2014, 2023), poly_order = 5, n_boot = 500)
cat("\nPost-2014 (2014-2023):\n")
cat("  Excess mass ratio (b):", round(post_bunch$estimate$excess_ratio, 3), "\n")
cat("  Bootstrap SE:", round(post_bunch$se, 3), "\n")

# Difference in bunching
delta_b <- post_bunch$estimate$excess_ratio - pre_bunch$estimate$excess_ratio
delta_se <- sqrt(pre_bunch$se^2 + post_bunch$se^2)
cat("\nDifference-in-Bunching (Post - Pre):\n")
cat("  Delta b:", round(delta_b, 3), "\n")
cat("  SE:", round(delta_se, 3), "\n")
cat("  t-stat:", round(delta_b / delta_se, 3), "\n")

## --- 6. PLACEBO TESTS -------------------------------------------------------

cat("\n=== PLACEBO TESTS ===\n")

# Placebo at 65% (no kink)
placebo_65 <- bootstrap_bunching(agg_yr, c(2000, 2023), bunch_point = 65,
                                  exclude_window = c(65, 65), poly_order = 4, n_boot = 500)
cat("\nPlacebo at 65%:\n")
cat("  Excess mass ratio:", round(placebo_65$estimate$excess_ratio, 3), "\n")
cat("  SE:", round(placebo_65$se, 3), "\n")

# Placebo at 70%
placebo_70 <- bootstrap_bunching(agg_yr, c(2000, 2023), bunch_point = 70,
                                  exclude_window = c(70, 70), poly_order = 4, n_boot = 500)
cat("\nPlacebo at 70%:\n")
cat("  Excess mass ratio:", round(placebo_70$estimate$excess_ratio, 3), "\n")
cat("  SE:", round(placebo_70$se, 3), "\n")

## --- 7. BUNCHING BY CROP ----------------------------------------------------

cat("\n=== BUNCHING BY CROP ===\n")

# Aggregate by crop × coverage level × year
agg_crop_yr <- d[, .(policies = sum(policies_earning, na.rm = TRUE)),
                  by = .(year, cov_pct, crop_label)]

crop_results <- list()
for (crop in c("Corn", "Soybeans", "Wheat", "Cotton")) {
  crop_data <- agg_crop_yr[crop_label == crop, .(year, cov_pct, policies)]
  res <- bootstrap_bunching(crop_data, c(2000, 2023), poly_order = 5, n_boot = 500)
  crop_results[[crop]] <- res
  cat(sprintf("  %s: b = %.3f (SE = %.3f)\n", crop, res$estimate$excess_ratio, res$se))
}

## --- 8. ANNUAL BUNCHING TIME SERIES -----------------------------------------

cat("\n=== ANNUAL BUNCHING ESTIMATES ===\n")

annual_b <- data.table(year = 2000:2023, b = NA_real_, se = NA_real_)

for (yr in 2000:2023) {
  yr_data <- agg_yr[year == yr]
  if (nrow(yr_data) == 0) next

  levels <- yr_data[order(cov_pct)]$cov_pct
  counts <- yr_data[order(cov_pct)]$policies

  tryCatch({
    est <- bunching_estimate(counts, levels, 75, c(75, 75), poly_order = 5)
    annual_b[year == yr, b := est$excess_ratio]
  }, error = function(e) NULL)
}

print(annual_b[!is.na(b), .(year, b = round(b, 3))])

## --- 9. ALTERNATIVE POLYNOMIAL ORDERS ---------------------------------------

cat("\n=== POLYNOMIAL ROBUSTNESS ===\n")

for (p in 3:7) {
  res <- bootstrap_bunching(agg_yr, c(2000, 2023), poly_order = p, n_boot = 200)
  cat(sprintf("  Order %d: b = %.3f (SE = %.3f)\n", p, res$estimate$excess_ratio, res$se))
}

## --- 10. SUBSIDY RATE SCHEDULE TABLE ----------------------------------------

cat("\n=== EFFECTIVE SUBSIDY RATES BY COVERAGE LEVEL AND PERIOD ===\n")

subsidy_table <- agg_yr[, .(
  premium = sum(premium),
  subsidy_amt = sum(subsidy_amt),
  policies = sum(policies)
), by = .(cov_pct, period = ifelse(year < 2014, "Pre-2014", "Post-2014"))]

subsidy_table[, subsidy_rate := subsidy_amt / premium]
subsidy_table[, farmer_share := 1 - subsidy_rate]

print(subsidy_table[order(period, cov_pct),
                     .(cov_pct, period, policies, subsidy_rate = round(subsidy_rate, 4),
                       farmer_share = round(farmer_share, 4))])

## --- 11. MORAL HAZARD: LOSS RATIOS BY COVERAGE LEVEL -----------------------

cat("\n=== LOSS RATIOS BY COVERAGE LEVEL ===\n")

# Aggregate at county × crop × year × coverage level
moral_hazard <- d[policies_earning > 0, .(
  premium   = sum(total_premium, na.rm = TRUE),
  indemnity = sum(indemnity, na.rm = TRUE),
  policies  = sum(policies_earning, na.rm = TRUE)
), by = .(year, state_fips, county_code, crop_code, cov_pct)]

moral_hazard[, loss_ratio := ifelse(premium > 0, indemnity / premium, NA_real_)]

# Summary by coverage level
lr_summary <- moral_hazard[!is.na(loss_ratio) & premium > 1000,
                            .(mean_lr = weighted.mean(loss_ratio, premium, na.rm = TRUE),
                              median_lr = median(loss_ratio, na.rm = TRUE),
                              n_cells = .N,
                              total_premium = sum(premium)),
                            by = cov_pct][order(cov_pct)]

cat("Loss ratios by coverage level:\n")
print(lr_summary[, .(cov_pct, mean_lr = round(mean_lr, 4),
                      median_lr = round(median_lr, 4), n_cells)])

# Regression: loss ratio ~ I(cov == 75) + county×crop×year FEs
# Using weighted regression at the cell level
moral_hazard[, at_75 := as.integer(cov_pct == 75)]
moral_hazard[, at_70 := as.integer(cov_pct == 70)]
moral_hazard[, at_80 := as.integer(cov_pct == 80)]

# Compare 75% vs 70% and 80%
mh_compare <- moral_hazard[cov_pct %in% c(70, 75, 80) & !is.na(loss_ratio) & premium > 1000]
mh_compare[, fe := paste(state_fips, county_code, crop_code, year, sep = "_")]

cat("\nMean loss ratios (70% vs 75% vs 80%):\n")
print(mh_compare[, .(mean_lr = weighted.mean(loss_ratio, premium),
                      n = .N, total_prem_B = round(sum(premium)/1e9, 1)),
                  by = cov_pct][order(cov_pct)])

# Moral hazard: compare mean loss ratios using within-cell differences
# (memory-efficient alternative to full FE regression)
mh_wide <- dcast(mh_compare[, .(loss_ratio = weighted.mean(loss_ratio, premium)),
                              by = .(fe, cov_pct)],
                  fe ~ cov_pct, value.var = "loss_ratio")
setnames(mh_wide, c("fe", "lr_70", "lr_75", "lr_80"))
mh_wide <- mh_wide[!is.na(lr_75) & (!is.na(lr_70) | !is.na(lr_80))]
mh_wide[, diff_70 := lr_75 - lr_70]
mh_wide[, diff_80 := lr_75 - lr_80]
cat("\nMoral hazard (within county-crop-year):\n")
cat("  75% vs 70%: mean diff =", round(mean(mh_wide$diff_70, na.rm = TRUE), 4),
    "  t =", round(mean(mh_wide$diff_70, na.rm = TRUE) /
                    (sd(mh_wide$diff_70, na.rm = TRUE) / sqrt(sum(!is.na(mh_wide$diff_70)))), 3), "\n")
cat("  75% vs 80%: mean diff =", round(mean(mh_wide$diff_80, na.rm = TRUE), 4),
    "  t =", round(mean(mh_wide$diff_80, na.rm = TRUE) /
                    (sd(mh_wide$diff_80, na.rm = TRUE) / sqrt(sum(!is.na(mh_wide$diff_80)))), 3), "\n")

## --- 12. REGIONAL ANALYSIS --------------------------------------------------

cat("\n=== REGIONAL BUNCHING ===\n")

# Define regions
corn_belt <- c("17", "18", "19", "26", "27", "29", "39", "55")  # IL, IN, IA, MI, MN, MO, OH, WI
plains <- c("20", "31", "38", "46")  # KS, NE, ND, SD
southeast <- c("01", "13", "28", "37", "45", "47")  # AL, GA, MS, NC, SC, TN

d[, region := fifelse(state_fips %in% corn_belt, "Corn Belt",
              fifelse(state_fips %in% plains, "Plains",
              fifelse(state_fips %in% southeast, "Southeast", "Other")))]

agg_region_yr <- d[, .(policies = sum(policies_earning, na.rm = TRUE)),
                    by = .(year, cov_pct, region)]

for (reg in c("Corn Belt", "Plains", "Southeast")) {
  reg_data <- agg_region_yr[region == reg, .(year, cov_pct, policies)]
  res <- bootstrap_bunching(reg_data, c(2000, 2023), poly_order = 5, n_boot = 300)
  cat(sprintf("  %s: b = %.3f (SE = %.3f)\n", reg, res$estimate$excess_ratio, res$se))
}

## --- 13. SCO TAKE-UP -------------------------------------------------------

cat("\n=== SCO / ENDORSED ACRES ===\n")

sco_yr <- agg_yr[, .(sco_acres = sum(sco_acres), policies = sum(policies)),
                  by = .(year, cov_pct)]
sco_yr[, sco_per_policy := sco_acres / policies]

cat("SCO acres by coverage level and year (post-2014):\n")
print(sco_yr[year >= 2014 & cov_pct %in% c(70, 75, 80, 85),
              .(year, cov_pct, sco_acres = format(sco_acres, big.mark = ","),
                sco_per_policy = round(sco_per_policy, 1))][order(year, cov_pct)])

## --- 14. DEMAND ELASTICITY --------------------------------------------------

cat("\n=== DEMAND ELASTICITY CALCULATION ===\n")

# The elasticity is recovered from the bunching mass and the size of the price change
# at the kink point. Following Saez (2010):
# b ≈ e * (Δlog(1-s)) where (1-s) is the farmer's share of premium
# and Δlog(1-s) is the change in log farmer share at the kink

# Use effective subsidy rates at 75% and 80%
sub_rates <- agg_yr[year >= 2000, .(premium = sum(premium), subsidy_amt = sum(subsidy_amt)),
                     by = cov_pct]
sub_rates[, sub_rate := subsidy_amt / premium]
sub_rates[, farmer_share := 1 - sub_rate]

s75 <- sub_rates[cov_pct == 75]$farmer_share
s80 <- sub_rates[cov_pct == 80]$farmer_share

delta_log_price <- log(s80) - log(s75)
b_main <- main_bunch$estimate$excess_ratio

# Elasticity following Saez (2010) kink formula
elasticity <- b_main / delta_log_price
cat("  Farmer share at 75%:", round(s75, 4), "\n")
cat("  Farmer share at 80%:", round(s80, 4), "\n")
cat("  Delta log(farmer share):", round(delta_log_price, 4), "\n")
cat("  Excess mass ratio b:", round(b_main, 3), "\n")
cat("  Implied elasticity:", round(elasticity, 3), "\n")

## --- 15. SUMMARY STATISTICS TABLE -------------------------------------------

cat("\n=== SUMMARY STATISTICS ===\n")

# Overall summary
summ <- d[, .(
  total_policies  = sum(policies_earning, na.rm = TRUE),
  total_liability = sum(liability, na.rm = TRUE),
  total_premium   = sum(total_premium, na.rm = TRUE),
  total_subsidy   = sum(subsidy, na.rm = TRUE),
  total_indemnity = sum(indemnity, na.rm = TRUE),
  n_counties      = uniqueN(paste(state_fips, county_code)),
  n_years         = uniqueN(year)
)]

cat("Sample: Major crops (corn, soybeans, wheat, cotton), buyup coverage, 2000-2023\n")
cat("Total policy-coverage-county-year cells:", nrow(d), "\n")
cat("Total policies earning premium:", format(summ$total_policies, big.mark = ","), "\n")
cat("Total liability: $", format(round(summ$total_liability / 1e12, 2)), "T\n")
cat("Total premium: $", format(round(summ$total_premium / 1e9, 1)), "B\n")
cat("Total federal subsidy: $", format(round(summ$total_subsidy / 1e9, 1)), "B\n")
cat("Total indemnity: $", format(round(summ$total_indemnity / 1e9, 1)), "B\n")
cat("Counties:", summ$n_counties, "\n")
cat("Years:", summ$n_years, "\n")

# By coverage level
by_cov <- d[, .(
  policies = sum(policies_earning, na.rm = TRUE),
  mean_premium = mean(total_premium[policies_earning > 0], na.rm = TRUE),
  total_premium = sum(total_premium, na.rm = TRUE),
  total_subsidy = sum(subsidy, na.rm = TRUE),
  total_indemnity = sum(indemnity, na.rm = TRUE)
), by = cov_pct][order(cov_pct)]

by_cov[, share := policies / sum(policies)]
by_cov[, subsidy_rate := total_subsidy / total_premium]
by_cov[, loss_ratio := total_indemnity / total_premium]

cat("\nBy coverage level:\n")
print(by_cov[, .(cov_pct, policies = format(policies, big.mark = ","),
                  share = round(share, 4),
                  subsidy_rate = round(subsidy_rate, 4),
                  loss_ratio = round(loss_ratio, 4))])

## --- 16. SAVE ALL RESULTS ---------------------------------------------------

results <- list(
  main_bunching = list(
    b = main_bunch$estimate$excess_ratio,
    se = main_bunch$se,
    ci = c(main_bunch$ci_lower, main_bunch$ci_upper),
    observed = main_bunch$estimate$observed,
    counterfactual = main_bunch$estimate$counterfactual
  ),
  pre_bunching = list(b = pre_bunch$estimate$excess_ratio, se = pre_bunch$se),
  post_bunching = list(b = post_bunch$estimate$excess_ratio, se = post_bunch$se),
  delta_b = list(estimate = delta_b, se = delta_se, t = delta_b / delta_se),
  placebo_65 = list(b = placebo_65$estimate$excess_ratio, se = placebo_65$se),
  placebo_70 = list(b = placebo_70$estimate$excess_ratio, se = placebo_70$se),
  crop_results = lapply(crop_results, function(x) list(b = x$estimate$excess_ratio, se = x$se)),
  elasticity = list(value = elasticity, delta_log_price = delta_log_price, b = b_main),
  subsidy_rates = sub_rates,
  by_cov = by_cov,
  summary_stats = summ,
  annual_b = annual_b
)

saveRDS(results, file.path(dirname(getwd()), "code", "results.rds"))
cat("\nResults saved to code/results.rds\n")
cat("\n=== ANALYSIS COMPLETE ===\n")
