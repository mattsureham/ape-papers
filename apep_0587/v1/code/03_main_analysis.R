## =============================================================================
## 03_main_analysis.R — Bunching estimation at the HICBC notch
## APEP-0587: Bunching at the UK High Income Child Benefit Charge Notch
## =============================================================================
source("00_packages.R")

data_dir <- "../data"

## ---- Load cleaned data ------------------------------------------------------
spi_pct    <- fread(file.path(data_dir, "spi_percentiles.csv"))
spi_dens   <- fread(file.path(data_dir, "spi_density.csv"))
ashe_dens  <- fread(file.path(data_dir, "ashe_density.csv"))
ashe_gend  <- fread(file.path(data_dir, "ashe_gender_density.csv"))
cb_admin   <- fread(file.path(data_dir, "cb_admin.csv"))
pension_dt <- fread(file.path(data_dir, "pension_by_income.csv"))
se_income  <- fread(file.path(data_dir, "selfemployment_by_income.csv"))

## =============================================================================
## ANALYSIS 1: Quantile-based bunching detection
## Strategy: Compare the income density near £50,000 in pre-HICBC (2005-2012)
## vs post-HICBC (2013-2022) years.
## =============================================================================

NOTCH_INCOME <- 50000  # HICBC threshold
WINDOW_LOW   <- 40000  # Lower bound of analysis window
WINDOW_HIGH  <- 65000  # Upper bound of analysis window

## ---- 1a. Compute the "excess density" at £50k by year ----------------------
## For each year, find the density bin containing £50k and its neighbors

find_density_at_income <- function(dens_dt, target_income, year_col = "tax_year") {
  # For each year, find the bin that contains the target income
  dens_dt[income_lower <= target_income & income_upper > target_income,
          .(year = get(year_col),
            density_at_target = density,
            bin_lower = income_lower,
            bin_upper = income_upper,
            pctile_lower = percentile_lower,
            pctile_upper = percentile_upper)]
}

spi_at_50k <- find_density_at_income(spi_dens, NOTCH_INCOME)

## ---- 1b. Compute counterfactual density at £50k ----------------------------
## Method: For each year, fit a polynomial to log-density excluding the bunching
## window [£45k, £55k], then predict at £50k

estimate_counterfactual <- function(dt, year_val, exclude_low = 45000,
                                     exclude_high = 55000, poly_deg = 7,
                                     window_low = 25000, window_high = 100000) {
  yr_dt <- dt[tax_year == year_val &
                income_midpoint >= window_low &
                income_midpoint <= window_high]
  if (nrow(yr_dt) < poly_deg + 3) return(NA_real_)

  # Flag bins in the exclusion zone
  yr_dt[, in_bunching_zone := income_midpoint >= exclude_low &
                               income_midpoint <= exclude_high]

  # Fit polynomial to bins OUTSIDE the exclusion zone
  fit_data <- yr_dt[in_bunching_zone == FALSE & density > 0]
  if (nrow(fit_data) < poly_deg + 2) return(NA_real_)

  fit <- lm(log(density) ~ poly(income_midpoint, poly_deg, raw = TRUE),
            data = fit_data)

  # Predict at midpoints inside the exclusion zone
  bunching_data <- yr_dt[in_bunching_zone == TRUE]
  if (nrow(bunching_data) == 0) return(NA_real_)

  bunching_data[, log_cf_density := predict(fit, newdata = bunching_data)]
  bunching_data[, cf_density := exp(log_cf_density)]

  # Excess mass = sum of (actual - counterfactual) density * bin_width
  excess_mass <- sum((bunching_data$density - bunching_data$cf_density) *
                       bunching_data$bin_width)
  cf_mass <- sum(bunching_data$cf_density * bunching_data$bin_width)

  # Bunching statistic b = excess_mass / cf_mass
  b <- excess_mass / cf_mass
  return(b)
}

## ---- 1c. Estimate bunching for each year ------------------------------------
years_avail <- sort(unique(spi_dens$tax_year))
years_avail <- years_avail[years_avail >= 2005]  # Start from 2005 for stability

bunching_by_year <- data.table(
  tax_year = years_avail,
  b_hat = sapply(years_avail, function(yr) {
    estimate_counterfactual(spi_dens, yr)
  })
)
bunching_by_year[, period := fifelse(tax_year < 2013, "pre_hicbc", "post_hicbc")]

cat("=== BUNCHING BY YEAR ===\n")
print(bunching_by_year)

## ---- 1d. Bootstrap standard errors ------------------------------------------
bootstrap_bunching <- function(dt, year_val, n_boot = 500, poly_deg = 7) {
  yr_dt <- dt[tax_year == year_val &
                income_midpoint >= 25000 &
                income_midpoint <= 100000]
  if (nrow(yr_dt) < poly_deg + 5) return(NA_real_)

  # Residual bootstrap: fit the full model, resample residuals
  yr_dt[, in_bunching_zone := income_midpoint >= 45000 &
                               income_midpoint <= 55000]
  fit_data <- yr_dt[in_bunching_zone == FALSE & density > 0]
  if (nrow(fit_data) < poly_deg + 2) return(NA_real_)

  fit_full <- lm(log(density) ~ poly(income_midpoint, poly_deg, raw = TRUE),
                 data = fit_data)
  resids <- residuals(fit_full)

  b_boot <- numeric(n_boot)
  for (b in seq_len(n_boot)) {
    # Resample residuals
    boot_resids <- sample(resids, length(resids), replace = TRUE)
    boot_data <- copy(fit_data)
    boot_data[, log_density_boot := fitted(fit_full) + boot_resids]

    # Refit on bootstrap data
    fit_b <- tryCatch(
      lm(log_density_boot ~ poly(income_midpoint, poly_deg, raw = TRUE),
         data = boot_data),
      error = function(e) NULL
    )
    if (is.null(fit_b)) { b_boot[b] <- NA; next }

    bunching_data <- yr_dt[in_bunching_zone == TRUE & density > 0]
    if (nrow(bunching_data) == 0) { b_boot[b] <- NA; next }

    bunching_data[, log_cf := predict(fit_b, newdata = bunching_data)]
    bunching_data[, cf_dens := exp(log_cf)]

    excess <- sum((bunching_data$density - bunching_data$cf_dens) *
                    bunching_data$bin_width)
    cf <- sum(bunching_data$cf_dens * bunching_data$bin_width)
    b_boot[b] <- if (cf > 0) excess / cf else NA
  }
  sd(b_boot, na.rm = TRUE)
}

# Bootstrap SE for ALL years (required for complete inference)
key_years <- years_avail

set.seed(20130107)  # HICBC effective date, ensures reproducibility
cat("\nBootstrapping standard errors...\n")
boot_se <- sapply(key_years, function(yr) {
  cat("  Year", yr, "...")
  se <- bootstrap_bunching(spi_dens, yr, n_boot = 500)
  cat(" SE =", round(se, 4), "\n")
  se
})

boot_results <- data.table(
  tax_year = key_years,
  b_hat = bunching_by_year[tax_year %in% key_years, b_hat],
  se = boot_se
)
boot_results[, t_stat := b_hat / se]
boot_results[, p_value := 2 * pnorm(-abs(t_stat))]

cat("\n=== BUNCHING ESTIMATES WITH SE ===\n")
print(boot_results)

## =============================================================================
## ANALYSIS 2: ASHE-based bunching (PAYE employees only)
## =============================================================================

ashe_at_50k <- find_density_at_income(ashe_dens, NOTCH_INCOME, year_col = "year")
setnames(ashe_at_50k, "year", "ashe_year")

cat("\n=== ASHE DENSITY AT £50k ===\n")
print(ashe_at_50k[order(ashe_year)])

## ---- ASHE bunching by year --------------------------------------------------
ashe_bunching <- data.table(
  year = sort(unique(ashe_dens$year)),
  b_hat_ashe = NA_real_
)

for (yr in ashe_bunching$year) {
  yr_dt <- ashe_dens[year == yr &
                       income_midpoint >= 20000 &
                       income_midpoint <= 90000]
  if (nrow(yr_dt) < 5) next

  yr_dt[, in_zone := income_midpoint >= 45000 & income_midpoint <= 55000]
  fit_data <- yr_dt[in_zone == FALSE & density > 0]
  if (nrow(fit_data) < 4) next

  # Lower polynomial degree for ASHE (fewer bins)
  fit <- tryCatch(
    lm(log(density) ~ poly(income_midpoint, 3, raw = TRUE), data = fit_data),
    error = function(e) NULL
  )
  if (is.null(fit)) next

  bz <- yr_dt[in_zone == TRUE & density > 0]
  if (nrow(bz) == 0) next

  bz[, cf_dens := exp(predict(fit, newdata = bz))]
  excess <- sum((bz$density - bz$cf_dens) * bz$bin_width)
  cf_mass <- sum(bz$cf_dens * bz$bin_width)

  ashe_bunching[year == yr, b_hat_ashe := if (cf_mass > 0) excess / cf_mass else NA]
}

ashe_bunching[, period := fifelse(year < 2013, "pre_hicbc", "post_hicbc")]
cat("\n=== ASHE BUNCHING BY YEAR ===\n")
print(ashe_bunching[year >= 2005])

## =============================================================================
## ANALYSIS 3: Difference-in-bunching (SPI overall vs ASHE PAYE)
## =============================================================================

# Merge SPI and ASHE bunching estimates
dib <- merge(
  bunching_by_year[, .(tax_year, b_spi = b_hat)],
  ashe_bunching[, .(tax_year = year, b_ashe = b_hat_ashe)],
  by = "tax_year", all = TRUE
)
dib[, b_diff := b_spi - b_ashe]  # Self-employed + personal pension channel
dib[, period := fifelse(tax_year < 2013, "pre_hicbc", "post_hicbc")]

cat("\n=== DIFFERENCE IN BUNCHING (SPI - ASHE) ===\n")
print(dib[tax_year >= 2005])

## =============================================================================
## ANALYSIS 4: Gender decomposition (ASHE)
## =============================================================================

gender_at_50k <- ashe_gend[income_lower <= 50000 & income_upper > 50000,
                            .(density_at_50k = density), by = .(year, sex)]
gender_wide <- dcast(gender_at_50k, year ~ sex, value.var = "density_at_50k")

cat("\n=== GENDER DENSITY AT £50k (ASHE) ===\n")
print(gender_wide[year >= 2005])

## =============================================================================
## ANALYSIS 5: Summary statistics
## =============================================================================

# Mean pre-HICBC and post-HICBC bunching
pre_b  <- bunching_by_year[period == "pre_hicbc" & !is.na(b_hat), mean(b_hat)]
post_b <- bunching_by_year[period == "post_hicbc" & !is.na(b_hat), mean(b_hat)]

# Restrict ASHE to 2009-2012 (pre) and 2013-2022 (post) for consistency with SPI
pre_ashe  <- ashe_bunching[year %in% 2009:2012 & !is.na(b_hat_ashe), mean(b_hat_ashe)]
post_ashe <- ashe_bunching[year %in% 2013:2022 & !is.na(b_hat_ashe), mean(b_hat_ashe)]

summary_stats <- data.table(
  measure = c("Mean bunching (SPI, pre-HICBC)",
              "Mean bunching (SPI, post-HICBC)",
              "Difference (post - pre)",
              "Mean bunching (ASHE/PAYE, pre-HICBC)",
              "Mean bunching (ASHE/PAYE, post-HICBC)",
              "ASHE Difference (post - pre)",
              "Non-PAYE residual (SPI - ASHE, post)"),
  value = c(pre_b, post_b, post_b - pre_b,
            pre_ashe, post_ashe, post_ashe - pre_ashe,
            post_b - post_ashe)
)

cat("\n=== SUMMARY OF BUNCHING ESTIMATES ===\n")
print(summary_stats)

## ---- Save results -----------------------------------------------------------
fwrite(bunching_by_year, file.path(data_dir, "bunching_by_year_spi.csv"))
fwrite(boot_results, file.path(data_dir, "bunching_bootstrap.csv"))
fwrite(ashe_bunching, file.path(data_dir, "bunching_by_year_ashe.csv"))
fwrite(dib, file.path(data_dir, "difference_in_bunching.csv"))
fwrite(gender_wide, file.path(data_dir, "gender_density_50k.csv"))
fwrite(summary_stats, file.path(data_dir, "summary_bunching.csv"))

cat("\nAll analysis results saved.\n")
