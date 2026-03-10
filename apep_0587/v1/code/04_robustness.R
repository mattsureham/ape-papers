## =============================================================================
## 04_robustness.R — Robustness checks for bunching estimates
## APEP-0587: Bunching at the UK High Income Child Benefit Charge Notch
## =============================================================================
source("00_packages.R")

data_dir <- "../data"
spi_dens <- fread(file.path(data_dir, "spi_density.csv"))

## =============================================================================
## ROBUSTNESS 1: Polynomial degree sensitivity (5, 7, 9, 11)
## =============================================================================

poly_degrees <- c(5, 7, 9, 11)
post_years <- 2013:2022

poly_sensitivity <- rbindlist(lapply(poly_degrees, function(deg) {
  rbindlist(lapply(post_years, function(yr) {
    yr_dt <- spi_dens[tax_year == yr &
                        income_midpoint >= 25000 &
                        income_midpoint <= 100000]
    if (nrow(yr_dt) < deg + 3) return(NULL)

    yr_dt[, in_zone := income_midpoint >= 45000 & income_midpoint <= 55000]
    fit_data <- yr_dt[in_zone == FALSE & density > 0]
    if (nrow(fit_data) < deg + 2) return(NULL)

    fit <- tryCatch(
      lm(log(density) ~ poly(income_midpoint, deg, raw = TRUE), data = fit_data),
      error = function(e) NULL
    )
    if (is.null(fit)) return(NULL)

    bz <- yr_dt[in_zone == TRUE & density > 0]
    if (nrow(bz) == 0) return(NULL)

    bz[, cf_dens := exp(predict(fit, newdata = bz))]
    excess <- sum((bz$density - bz$cf_dens) * bz$bin_width)
    cf <- sum(bz$cf_dens * bz$bin_width)

    data.table(tax_year = yr, poly_deg = deg,
               b_hat = if (cf > 0) excess / cf else NA_real_)
  }))
}))

poly_summary <- poly_sensitivity[, .(mean_b = mean(b_hat, na.rm = TRUE),
                                      sd_b = sd(b_hat, na.rm = TRUE)),
                                  by = poly_deg]

cat("=== POLYNOMIAL DEGREE SENSITIVITY ===\n")
print(poly_summary)

## =============================================================================
## ROBUSTNESS 2: Exclusion window sensitivity
## =============================================================================

windows <- list(
  c(47000, 53000),   # ±£3k
  c(45000, 55000),   # ±£5k (baseline)
  c(43000, 57000),   # ±£7k
  c(40000, 60000)    # ±£10k
)
window_labels <- c("pm3k", "pm5k", "pm7k", "pm10k")

window_sensitivity <- rbindlist(lapply(seq_along(windows), function(w) {
  wl <- windows[[w]][1]; wh <- windows[[w]][2]
  rbindlist(lapply(post_years, function(yr) {
    yr_dt <- spi_dens[tax_year == yr &
                        income_midpoint >= 20000 &
                        income_midpoint <= 100000]
    yr_dt[, in_zone := income_midpoint >= wl & income_midpoint <= wh]
    fit_data <- yr_dt[in_zone == FALSE & density > 0]
    if (nrow(fit_data) < 9) return(NULL)

    fit <- tryCatch(
      lm(log(density) ~ poly(income_midpoint, 7, raw = TRUE), data = fit_data),
      error = function(e) NULL
    )
    if (is.null(fit)) return(NULL)

    bz <- yr_dt[in_zone == TRUE & density > 0]
    if (nrow(bz) == 0) return(NULL)

    bz[, cf_dens := exp(predict(fit, newdata = bz))]
    excess <- sum((bz$density - bz$cf_dens) * bz$bin_width)
    cf <- sum(bz$cf_dens * bz$bin_width)

    data.table(tax_year = yr, window = window_labels[w],
               window_low = wl, window_high = wh,
               b_hat = if (cf > 0) excess / cf else NA_real_)
  }))
}))

window_summary <- window_sensitivity[, .(mean_b = mean(b_hat, na.rm = TRUE),
                                          sd_b = sd(b_hat, na.rm = TRUE)),
                                      by = window]

cat("\n=== EXCLUSION WINDOW SENSITIVITY ===\n")
print(window_summary)

## =============================================================================
## ROBUSTNESS 3: Round-number placebo tests
## Test for bunching at £40k, £45k, £55k, £60k (round numbers without notches)
## =============================================================================

placebo_incomes <- c(40000, 45000, 55000, 60000)

placebo_tests <- rbindlist(lapply(placebo_incomes, function(pl) {
  rbindlist(lapply(post_years, function(yr) {
    yr_dt <- spi_dens[tax_year == yr &
                        income_midpoint >= (pl - 25000) &
                        income_midpoint <= (pl + 25000)]
    yr_dt[, in_zone := income_midpoint >= (pl - 5000) &
                        income_midpoint <= (pl + 5000)]
    fit_data <- yr_dt[in_zone == FALSE & density > 0]
    if (nrow(fit_data) < 9) return(NULL)

    fit <- tryCatch(
      lm(log(density) ~ poly(income_midpoint, 7, raw = TRUE), data = fit_data),
      error = function(e) NULL
    )
    if (is.null(fit)) return(NULL)

    bz <- yr_dt[in_zone == TRUE & density > 0]
    if (nrow(bz) == 0) return(NULL)

    bz[, cf_dens := exp(predict(fit, newdata = bz))]
    excess <- sum((bz$density - bz$cf_dens) * bz$bin_width)
    cf <- sum(bz$cf_dens * bz$bin_width)

    data.table(tax_year = yr, placebo_income = pl,
               b_hat = if (cf > 0) excess / cf else NA_real_)
  }))
}))

# Add the actual £50k estimates for comparison
actual_50k <- window_sensitivity[window == "pm5k",
                                  .(tax_year, placebo_income = 50000L, b_hat)]
placebo_all <- rbind(placebo_tests, actual_50k)

placebo_summary <- placebo_all[, .(mean_b = mean(b_hat, na.rm = TRUE),
                                    sd_b = sd(b_hat, na.rm = TRUE)),
                                by = placebo_income]

cat("\n=== ROUND-NUMBER PLACEBO TESTS ===\n")
print(placebo_summary)

## =============================================================================
## ROBUSTNESS 4: Pre-2013 placebo (no HICBC should mean no bunching at £50k)
## =============================================================================

pre_years <- 2005:2012
pre_bunching <- rbindlist(lapply(pre_years, function(yr) {
  yr_dt <- spi_dens[tax_year == yr &
                      income_midpoint >= 25000 &
                      income_midpoint <= 100000]
  yr_dt[, in_zone := income_midpoint >= 45000 & income_midpoint <= 55000]
  fit_data <- yr_dt[in_zone == FALSE & density > 0]
  if (nrow(fit_data) < 9) return(NULL)

  fit <- tryCatch(
    lm(log(density) ~ poly(income_midpoint, 7, raw = TRUE), data = fit_data),
    error = function(e) NULL
  )
  if (is.null(fit)) return(NULL)

  bz <- yr_dt[in_zone == TRUE & density > 0]
  if (nrow(bz) == 0) return(NULL)

  bz[, cf_dens := exp(predict(fit, newdata = bz))]
  excess <- sum((bz$density - bz$cf_dens) * bz$bin_width)
  cf <- sum(bz$cf_dens * bz$bin_width)

  data.table(tax_year = yr, b_hat = if (cf > 0) excess / cf else NA_real_)
}))

cat("\n=== PRE-2013 PLACEBO (should be ~0) ===\n")
cat("Mean pre-2013 bunching:", mean(pre_bunching$b_hat, na.rm = TRUE), "\n")
cat("SD:", sd(pre_bunching$b_hat, na.rm = TRUE), "\n")
print(pre_bunching)

## =============================================================================
## ROBUSTNESS 5: Time-series stability (annual bunching estimates with CI)
## =============================================================================

# Already computed in main analysis — combine pre and post
all_years_bunching <- rbind(
  pre_bunching[, .(tax_year, b_hat, period = "pre_hicbc")],
  window_sensitivity[window == "pm5k", .(tax_year, b_hat, period = "post_hicbc")]
)

cat("\n=== FULL TIME SERIES ===\n")
print(all_years_bunching)

## ---- Save robustness results ------------------------------------------------
fwrite(poly_sensitivity, file.path(data_dir, "robustness_polynomial.csv"))
fwrite(poly_summary, file.path(data_dir, "robustness_polynomial_summary.csv"))
fwrite(window_sensitivity, file.path(data_dir, "robustness_window.csv"))
fwrite(window_summary, file.path(data_dir, "robustness_window_summary.csv"))
fwrite(placebo_all, file.path(data_dir, "robustness_placebo.csv"))
fwrite(placebo_summary, file.path(data_dir, "robustness_placebo_summary.csv"))
fwrite(pre_bunching, file.path(data_dir, "robustness_pre2013.csv"))
fwrite(all_years_bunching, file.path(data_dir, "robustness_timeseries.csv"))

cat("\nAll robustness results saved.\n")
