## 02_clean_data.R — Construct analysis panel
## apep_1419: UK Auto-Enrollment Contribution Step-Up and Wages

source("00_packages.R")
data_dir <- "../data"
load(file.path(data_dir, "raw_data.RData"))

## ========================================================================
## 1. Construct treatment intensity: micro/small firm share by LA (2018)
## ========================================================================

# Employment-weighted firm size shares
# Use midpoint employment for each band to approximate total employment
emp_midpoints <- c(
  "0 to 4" = 2.5, "5 to 9" = 7, "10 to 19" = 15,
  "20 to 49" = 35, "50 to 99" = 75, "100 to 249" = 175,
  "250 to 499" = 375, "500 to 999" = 750, "1000+" = 1500
)

biz_emp <- biz_raw %>%
  select(la_code, la_name, size_band, n_units) %>%
  mutate(
    emp_midpoint = emp_midpoints[size_band],
    approx_emp = n_units * emp_midpoint,
    is_small = size_band %in% c("0 to 4", "5 to 9", "10 to 19", "20 to 49"),
    is_micro = size_band %in% c("0 to 4", "5 to 9"),
    is_large = size_band %in% c("250 to 499", "500 to 999", "1000+")
  )

biz_wide <- biz_emp %>%
  group_by(la_code, la_name) %>%
  summarise(
    total_emp = sum(approx_emp, na.rm = TRUE),
    small_emp = sum(approx_emp[is_small], na.rm = TRUE),
    micro_emp = sum(approx_emp[is_micro], na.rm = TRUE),
    large_emp = sum(approx_emp[is_large], na.rm = TRUE),
    n_units_total = sum(n_units, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    small_share = small_emp / total_emp,   # employment-weighted share at small firms
    micro_share = micro_emp / total_emp,
    large_share = large_emp / total_emp
  )

cat(sprintf("Business structure (employment-weighted): %d LAs\n", nrow(biz_wide)))
cat(sprintf("  Small-emp share (<50): mean=%.3f, sd=%.3f, range=[%.3f, %.3f]\n",
            mean(biz_wide$small_share, na.rm = TRUE),
            sd(biz_wide$small_share, na.rm = TRUE),
            min(biz_wide$small_share, na.rm = TRUE),
            max(biz_wide$small_share, na.rm = TRUE)))
cat(sprintf("  Large-emp share (250+): mean=%.3f, sd=%.3f\n",
            mean(biz_wide$large_share, na.rm = TRUE),
            sd(biz_wide$large_share, na.rm = TRUE)))

## ========================================================================
## 2. Merge ASHE earnings with treatment intensity
## ========================================================================

# Merge annual pay, hourly pay, and job counts
panel <- ashe_raw %>%
  left_join(ashe_hourly %>% select(year, la_code, median_hourly_pay),
            by = c("year", "la_code")) %>%
  left_join(ashe_jobs %>% select(year, la_code, n_jobs),
            by = c("year", "la_code"))

# Merge with business structure (time-invariant 2018 values)
panel <- panel %>%
  left_join(biz_wide %>% select(la_code, micro_share, small_share, large_share),
            by = "la_code")

# Merge CPI and deflate
panel <- panel %>%
  left_join(cpi_data, by = "year") %>%
  mutate(
    real_annual_pay = median_annual_pay / cpi * 100,
    real_hourly_pay = median_hourly_pay / cpi * 100
  )

## ========================================================================
## 3. Create treatment variables
## ========================================================================

panel <- panel %>%
  mutate(
    post = as.integer(year >= 2019),
    # Treatment intensity: continuous (micro+small share)
    treat_intensity = small_share,
    # Binary: above/below median small-firm share
    high_small = as.integer(small_share > median(small_share, na.rm = TRUE)),
    # Log outcomes
    log_annual_pay = log(real_annual_pay),
    log_hourly_pay = log(real_hourly_pay),
    # Annual pay growth
    year_fac = factor(year)
  )

## ========================================================================
## 4. Balanced panel check
## ========================================================================

la_counts <- panel %>%
  group_by(la_code) %>%
  summarise(n_years = sum(!is.na(median_annual_pay)), .groups = "drop")

balanced_las <- la_counts %>%
  filter(n_years >= 8) %>%  # at least 8 of 9 years

  pull(la_code)

panel_bal <- panel %>%
  filter(la_code %in% balanced_las)

cat(sprintf("\nPanel construction:\n"))
cat(sprintf("  Raw panel: %d obs, %d LAs\n", nrow(panel), length(unique(panel$la_code))))
cat(sprintf("  Balanced (≥8 years): %d obs, %d LAs\n",
            nrow(panel_bal), length(unique(panel_bal$la_code))))
cat(sprintf("  Post-treatment obs: %d\n", sum(panel_bal$post)))
cat(sprintf("  Treatment intensity range: [%.3f, %.3f]\n",
            min(panel_bal$treat_intensity, na.rm = TRUE),
            max(panel_bal$treat_intensity, na.rm = TRUE)))

## ========================================================================
## 5. Summary statistics
## ========================================================================

sumstats <- panel_bal %>%
  group_by(high_small) %>%
  summarise(
    n_la = n_distinct(la_code),
    mean_pay = mean(real_annual_pay, na.rm = TRUE),
    sd_pay = sd(real_annual_pay, na.rm = TRUE),
    mean_hourly = mean(real_hourly_pay, na.rm = TRUE),
    mean_small_share = mean(small_share, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nSummary by treatment group:\n")
print(sumstats)

## ========================================================================
## Save
## ========================================================================

save(panel_bal, biz_wide, file = file.path(data_dir, "analysis_panel.RData"))
cat("\nSaved analysis_panel.RData\n")
