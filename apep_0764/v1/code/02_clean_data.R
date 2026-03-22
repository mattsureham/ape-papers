# 02_clean_data.R — Clean and construct analysis variables
# apep_0764: Brazil Intermittent Contracts

source("00_packages.R")

cat("Loading panel data...\n")
panel <- fread("../data/panel_muni_year.csv")
sector_rates <- fread("../data/sector_intermittent_rates.csv")
muni_exposure <- fread("../data/muni_exposure.csv")

# =============================================================================
# 1. VARIABLE CONSTRUCTION
# =============================================================================

# Ensure state_code is character for FE
panel[, state_code := as.character(state_code)]
panel[, muni_code := as.character(muni_code)]

# Create treatment intensity × post interaction
panel[, exposure_x_post := bartik_exposure * post]

# Create year indicators for event study
panel[, year_factor := factor(year)]

# Create exposure terciles for heterogeneity
panel[, exposure_tercile := cut(bartik_exposure,
  breaks = quantile(bartik_exposure, probs = c(0, 1/3, 2/3, 1), na.rm = TRUE),
  labels = c("Low", "Medium", "High"),
  include.lowest = TRUE
)]

# Pre-treatment outcome means for SDE computation
pre_means <- panel[year <= 2017, .(
  pre_mean_wage = mean(avg_wage, na.rm = TRUE),
  pre_sd_wage = sd(avg_wage, na.rm = TRUE),
  pre_mean_log_wage = mean(log_avg_wage, na.rm = TRUE),
  pre_sd_log_wage = sd(log_avg_wage, na.rm = TRUE),
  pre_mean_employment = mean(total_employment, na.rm = TRUE),
  pre_sd_employment = sd(total_employment, na.rm = TRUE),
  pre_mean_log_emp = mean(log_employment, na.rm = TRUE),
  pre_sd_log_emp = sd(log_employment, na.rm = TRUE),
  pre_mean_hours = mean(avg_hours, na.rm = TRUE),
  pre_sd_hours = sd(avg_hours, na.rm = TRUE),
  pre_mean_intermittent_share = mean(intermittent_share, na.rm = TRUE),
  pre_sd_intermittent_share = sd(intermittent_share, na.rm = TRUE)
)]

saveRDS(pre_means, "../data/pre_treatment_means.rds")

# =============================================================================
# 2. SAMPLE RESTRICTIONS
# =============================================================================

# Drop municipalities with fewer than 3 years of data
muni_years <- panel[, .N, by = muni_code]
valid_munis <- muni_years[N >= 7, muni_code]  # At least 7 of 9 years
panel <- panel[muni_code %in% valid_munis]

cat(sprintf("After sample restrictions: %d rows, %d municipalities\n",
            nrow(panel), uniqueN(panel$muni_code)))

# =============================================================================
# 3. SUMMARY STATISTICS
# =============================================================================

cat("\n=== Summary Statistics ===\n")
cat(sprintf("Municipalities: %d\n", uniqueN(panel$muni_code)))
cat(sprintf("States: %d\n", uniqueN(panel$state_code)))
cat(sprintf("Years: %d-%d\n", min(panel$year), max(panel$year)))
cat(sprintf("Total observations: %d\n", nrow(panel)))

cat("\nPre-reform (2014-2017) averages:\n")
pre <- panel[year <= 2017]
cat(sprintf("  Average formal wage: R$ %.0f\n", mean(pre$avg_wage)))
cat(sprintf("  Average formal employment per municipality: %.0f\n", mean(pre$total_employment)))
cat(sprintf("  Average contracted hours: %.1f\n", mean(pre$avg_hours)))

cat("\nPost-reform (2018-2022) averages:\n")
post_data <- panel[year >= 2018]
cat(sprintf("  Average formal wage: R$ %.0f\n", mean(post_data$avg_wage)))
cat(sprintf("  Average formal employment per municipality: %.0f\n", mean(post_data$total_employment)))
cat(sprintf("  Intermittent share: %.4f\n", mean(post_data$intermittent_share)))
cat(sprintf("  Average contracted hours: %.1f\n", mean(post_data$avg_hours)))

cat("\nExposure distribution:\n")
cat(sprintf("  Mean: %.4f\n", mean(muni_exposure$bartik_exposure)))
cat(sprintf("  SD: %.4f\n", sd(muni_exposure$bartik_exposure)))
cat(sprintf("  P10: %.4f\n", quantile(muni_exposure$bartik_exposure, 0.10)))
cat(sprintf("  P50: %.4f\n", quantile(muni_exposure$bartik_exposure, 0.50)))
cat(sprintf("  P90: %.4f\n", quantile(muni_exposure$bartik_exposure, 0.90)))

# =============================================================================
# 4. SAVE CLEAN PANEL
# =============================================================================
fwrite(panel, "../data/panel_clean.csv")
cat("\nClean panel saved.\n")
