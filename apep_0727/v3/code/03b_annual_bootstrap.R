## 03b_annual_bootstrap.R — Bootstrap SEs for Annual Bunching Estimates
## apep_0727 v3: Addresses referee concern about missing annual inference

source("00_packages.R")

cat("Loading data for annual bootstrap...\n")
dt_10 <- fread("../data/solar_clean_10.csv")
dt_10[, bin_int := as.integer(floor(capacity_kwp * 10))]
all_bins <- data.table(bin_int = 30L:199L)

bunching_est_int <- function(bin_data, kink_int = 100L,
                              excl_lower = 90L, excl_upper = 110L,
                              window_lower = 30L, window_upper = 199L,
                              poly_degree = 7) {
  bd <- copy(bin_data[bin_int >= window_lower & bin_int <= window_upper])
  bd[, excluded := bin_int >= excl_lower & bin_int < excl_upper]
  bd[, z := bin_int - kink_int]
  for (p in 1:poly_degree) bd[, paste0("z", p) := z^p]
  fit <- lm(as.formula(paste0("count ~ ", paste(paste0("z", 1:poly_degree), collapse = " + "))),
             data = bd[excluded == FALSE])
  bd[, counterfactual := pmax(predict(fit, newdata = bd), 0)]
  excess <- sum(bd[excluded == TRUE, count - counterfactual])
  f0 <- bd[bin_int == kink_int, counterfactual]
  if (length(f0) == 0 || is.na(f0) || f0 <= 0) f0 <- mean(bd[excluded == FALSE]$counterfactual)
  list(bunching_ratio = excess / f0, excess_mass = excess)
}

# Bootstrap annual estimates
set.seed(20260328)
n_boot <- 500  # Increased from 200 per referee feedback

annual_results <- list()
for (yr in 2008:2024) {
  cat(sprintf("Year %d: ", yr))
  dt_yr <- dt_10[year == yr & capacity_kwp >= 3 & capacity_kwp < 20]
  N <- nrow(dt_yr)

  # Point estimate
  yr_bins <- dt_yr[, .(count = .N), by = bin_int]
  yr_bins <- merge(all_bins, yr_bins, by = "bin_int", all.x = TRUE)
  yr_bins[is.na(count), count := 0L]
  est <- bunching_est_int(yr_bins)

  # Raw bin counts
  n99 <- sum(yr_bins[bin_int == 99L, count])
  n101 <- sum(yr_bins[bin_int == 101L, count])

  # Bootstrap
  boot_b <- numeric(n_boot)
  for (b in 1:n_boot) {
    idx <- sample.int(N, N, replace = TRUE)
    boot_dt <- dt_yr[idx]
    boot_bins <- boot_dt[, .(count = .N), by = .(bin_int = as.integer(floor(capacity_kwp * 10)))]
    boot_bins <- merge(all_bins, boot_bins, by = "bin_int", all.x = TRUE)
    boot_bins[is.na(count), count := 0L]
    boot_est <- tryCatch(bunching_est_int(boot_bins), error = function(e) NULL)
    boot_b[b] <- if (!is.null(boot_est)) boot_est$bunching_ratio else NA
  }

  se <- sd(boot_b, na.rm = TRUE)
  ci_lo <- quantile(boot_b, 0.025, na.rm = TRUE)
  ci_hi <- quantile(boot_b, 0.975, na.rm = TRUE)

  cat(sprintf("b = %.1f (SE = %.1f) [%.1f, %.1f]\n",
      est$bunching_ratio, se, ci_lo, ci_hi))

  annual_results[[length(annual_results) + 1]] <- data.frame(
    year = yr,
    bunching_ratio = round(est$bunching_ratio, 2),
    se = round(se, 2),
    ci_lower = round(ci_lo, 2),
    ci_upper = round(ci_hi, 2),
    excess_mass = round(est$excess_mass),
    n_99 = n99,
    n_101 = n101,
    n_total = N,
    stringsAsFactors = FALSE)
}

annual_dt <- as.data.table(do.call(rbind, annual_results))
fwrite(annual_dt, "../data/bunching_10_annual_with_se.csv")
cat("\nAnnual estimates with bootstrap SEs saved.\n")
print(annual_dt[, .(year, bunching_ratio, se, ci_lower, ci_upper)])
