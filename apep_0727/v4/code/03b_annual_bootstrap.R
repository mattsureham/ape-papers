## 03b_annual_bootstrap.R — Bootstrap SEs for Annual Bunching Estimates (V4)
## apep_0727 v4: Uses unified estimator from 00_bunching_estimator.R

source("00_packages.R")
source("00_bunching_estimator.R")

cat("Loading data for annual bootstrap...\n")
dt_10 <- fread("../data/solar_clean_10.csv")
dt_10[, bin_int := as.integer(floor(capacity_kwp * 10))]
all_bins <- data.table(bin_int = 30L:199L)

set.seed(20260331)

annual_results <- list()
for (yr in 2008:2024) {
  cat(sprintf("Year %d: ", yr))
  dt_yr <- dt_10[year == yr & capacity_kwp >= 3 & capacity_kwp < 20]
  N <- nrow(dt_yr)

  # Point estimate using unified estimator
  yr_bins <- make_bins_int(dt_yr, all_bins)
  est <- bunching_estimate_int(yr_bins)

  # Raw bin counts
  n99 <- yr_bins[bin_int == 99L, count]
  n101 <- yr_bins[bin_int == 101L, count]

  # Bootstrap using unified function
  boot <- bootstrap_bunching_int(dt_10, n_boot = 500L,
                                  subset_expr = substitute(year == YR, list(YR = yr)),
                                  all_bins = all_bins)

  cat(sprintf("b = %.1f (SE = %.1f) [%.1f, %.1f]\n",
      est$bunching_ratio,
      ifelse(is.na(boot$se_bunching), NA, boot$se_bunching),
      ifelse(is.na(boot$ci_lower), NA, boot$ci_lower),
      ifelse(is.na(boot$ci_upper), NA, boot$ci_upper)))

  annual_results[[length(annual_results) + 1]] <- data.frame(
    year = yr,
    bunching_ratio = round(est$bunching_ratio, 2),
    se = round(ifelse(is.na(boot$se_bunching), NA, boot$se_bunching), 2),
    ci_lower = round(ifelse(is.na(boot$ci_lower), NA, boot$ci_lower), 2),
    ci_upper = round(ifelse(is.na(boot$ci_upper), NA, boot$ci_upper), 2),
    excess_mass = round(est$excess_mass),
    missing_mass = round(est$missing_mass),
    mass_balance = round(est$mass_balance, 3),
    n_99 = n99,
    n_101 = n101,
    n_total = N,
    stringsAsFactors = FALSE)
}

annual_dt <- as.data.table(do.call(rbind, annual_results))
fwrite(annual_dt, "../data/bunching_10_annual_with_se.csv")
cat("\nAnnual estimates with bootstrap SEs saved.\n")
print(annual_dt[, .(year, bunching_ratio, se, ci_lower, ci_upper, mass_balance)])
