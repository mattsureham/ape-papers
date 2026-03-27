## 04_robustness.R — Robustness checks and placebos
## apep_1069: The Compensation Cliff

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))

# Ensure rel_year and year_factor exist
panel <- panel %>%
  mutate(
    rel_year = year - 2020,
    year_factor = factor(year),
    tercile_2 = as.integer(exposure_tercile == 2),
    tercile_3 = as.integer(exposure_tercile == 3)
  )

# ============================================================================
# 1. Varying Exposure Thresholds
# ============================================================================
cat("=== Robustness: Varying treatment thresholds ===\n")

# Define treatment at different quantiles
for (q in c(0.25, 0.33, 0.50, 0.67, 0.75)) {
  threshold <- quantile(panel$cum_pga[!duplicated(panel$buurt_code)], q)
  panel_temp <- panel %>% mutate(treated_q = as.integer(cum_pga > threshold))
  n_t <- sum(panel_temp$treated_q == 1 & panel_temp$year == 2019)
  n_c <- sum(panel_temp$treated_q == 0 & panel_temp$year == 2019)

  mod <- feols(woz ~ treated_q:post | buurt_code + year,
               data = panel_temp, cluster = ~buurt_code)

  cat(sprintf("  Q%.0f threshold (%.1f): β=%.3f (SE=%.3f), t=%.3f, treated=%d, control=%d\n",
              q*100, threshold, coef(mod), sqrt(diag(vcov(mod))),
              coef(mod)/sqrt(diag(vcov(mod))), n_t, n_c))
}

# ============================================================================
# 2. Placebo Treatment Year (2018)
# ============================================================================
cat("\n=== Placebo: Fake treatment in 2018 ===\n")

panel_pre <- panel %>% filter(year <= 2020)
panel_pre <- panel_pre %>%
  mutate(fake_post = as.integer(year >= 2018))

placebo_2018 <- feols(woz ~ treated_median:fake_post | buurt_code + year,
                      data = panel_pre, cluster = ~buurt_code)

cat("Placebo (treatment = 2018):\n")
summary(placebo_2018)

# ============================================================================
# 3. Restricting to Groningen Province Only
# ============================================================================
cat("\n=== Robustness: Groningen province only ===\n")

municipalities <- readRDS(file.path(data_dir, "study_municipalities.rds"))

if ("gemeente" %in% names(panel)) {
  panel_gron <- panel %>% filter(gemeente %in% municipalities$groningen)
  cat("Groningen-only panel:", nrow(panel_gron), "obs,",
      n_distinct(panel_gron$buurt_code), "buurten\n")

  if (nrow(panel_gron) > 100) {
    gron_did <- feols(woz ~ treated_median:post | buurt_code + year,
                      data = panel_gron, cluster = ~buurt_code)
    cat("DiD (Groningen only):\n")
    summary(gron_did)
  }
} else {
  cat("No municipality column — skipping geographic restriction\n")
}

# ============================================================================
# 4. Quartile Treatment Intensity
# ============================================================================
cat("\n=== Dose-Response: Quartile treatment effects ===\n")

panel <- panel %>%
  mutate(
    q2 = as.integer(exposure_quartile == 2),
    q3 = as.integer(exposure_quartile == 3),
    q4 = as.integer(exposure_quartile == 4)
  )

dose_resp <- feols(woz ~ q2:post + q3:post + q4:post | buurt_code + year,
                   data = panel, cluster = ~buurt_code)

cat("Quartile dose-response (Q1 = reference):\n")
summary(dose_resp)

# ============================================================================
# 5. Owner-Occupied Subsample
# ============================================================================
cat("\n=== Heterogeneity: High vs Low Owner-Occupancy ===\n")

# Split at median owner-occupancy rate
med_owner <- median(panel$pct_owner, na.rm = TRUE)
cat("Median owner-occupancy:", med_owner, "%\n")

if (!is.na(med_owner)) {
  panel_high_own <- panel %>% filter(pct_owner >= med_owner)
  panel_low_own <- panel %>% filter(pct_owner < med_owner)

  if (nrow(panel_high_own) > 100 & nrow(panel_low_own) > 100) {
    did_high <- feols(woz ~ treated_median:post | buurt_code + year,
                      data = panel_high_own, cluster = ~buurt_code)
    did_low <- feols(woz ~ treated_median:post | buurt_code + year,
                     data = panel_low_own, cluster = ~buurt_code)

    cat("High owner-occupancy:\n")
    summary(did_high)
    cat("\nLow owner-occupancy:\n")
    summary(did_low)
  }
}

# ============================================================================
# 6. Power Calculation
# ============================================================================
cat("\n=== Power Analysis ===\n")

# What effect size can we detect with 80% power?
# Using the main specification SE
main_se <- sqrt(diag(vcov(results$did_binary_levels)))[1]
mean_woz <- mean(panel$woz, na.rm = TRUE)
sd_y <- results$sd_y_pre

# MDE at 80% power = 2.8 * SE (one-sided) or 3.5 * SE (two-sided, approx)
mde_level <- 2.8 * main_se
mde_pct <- mde_level / mean_woz * 100
mde_sde <- mde_level / sd_y

cat("Standard error:", round(main_se, 2), "thousand EUR\n")
cat("MDE (80% power):", round(mde_level, 2), "thousand EUR\n")
cat("MDE as % of mean WOZ:", round(mde_pct, 2), "%\n")
cat("MDE in SDE units:", round(mde_sde, 4), "\n")
cat("Mean compensation (midpoint):", "~7% of property value =", round(0.07 * mean_woz, 1), "thousand EUR\n")
cat("95% CI for main effect:", round(coef(results$did_binary_levels) - 1.96*main_se, 2),
    "to", round(coef(results$did_binary_levels) + 1.96*main_se, 2), "thousand EUR\n")
cat("95% CI as % of mean WOZ:",
    round((coef(results$did_binary_levels) - 1.96*main_se)/mean_woz*100, 2), "%",
    "to", round((coef(results$did_binary_levels) + 1.96*main_se)/mean_woz*100, 2), "%\n")

# ============================================================================
# 7. Save Robustness Results
# ============================================================================

rob_results <- list(
  placebo_2018 = placebo_2018,
  dose_response = dose_resp,
  mde_level = mde_level,
  mde_pct = mde_pct,
  mde_sde = mde_sde,
  main_se = main_se
)

saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))

cat("\n=== Robustness checks complete ===\n")
