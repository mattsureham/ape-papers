## 04_robustness.R — Robustness checks
## apep_0810: Florida Liquor License Lottery and Business Formation

source("00_packages.R")
data_dir <- "../data/"

panel_7224 <- readRDS(file.path(data_dir, "panel_7224.rds"))
panel_7225 <- readRDS(file.path(data_dir, "panel_7225.rds"))
stacked <- readRDS(file.path(data_dir, "stacked_panel.rds"))

cat("=== ROBUSTNESS CHECKS ===\n\n")

# ============================================================
# 1. EXCLUDE COVID PERIOD (2020-2021)
# ============================================================

cat("--- R1: Excluding COVID period (2020-2021) ---\n")

panel_nocovid <- panel_7224 %>% filter(!(year %in% c(2020, 2021)))

r1a <- feols(log_emp ~ new_licenses | county_fips + time_id,
             data = panel_nocovid, cluster = ~county_fips)

r1b <- feols(log_emp ~ new_licenses + log_pop | county_fips + time_id,
             data = panel_nocovid, cluster = ~county_fips)

etable(r1a, r1b,
       headers = c("No COVID", "No COVID + Pop"),
       se.below = TRUE)

# ============================================================
# 2. LAGGED TREATMENT (1-year lag for activation time)
# ============================================================

cat("\n--- R2: Lagged treatment (t-1 licenses) ---\n")

panel_lag <- panel_7224 %>%
  arrange(county_fips, year, quarter) %>%
  group_by(county_fips) %>%
  mutate(
    lag_new_licenses = lag(new_licenses, 4),  # 4 quarters = 1 year lag
    lag_cum_licenses = lag(cum_new_licenses, 4)
  ) %>%
  ungroup() %>%
  filter(!is.na(lag_new_licenses))

r2a <- feols(log_emp ~ lag_new_licenses | county_fips + time_id,
             data = panel_lag, cluster = ~county_fips)

r2b <- feols(log_emp ~ lag_cum_licenses | county_fips + time_id,
             data = panel_lag, cluster = ~county_fips)

etable(r2a, r2b,
       headers = c("Lag Flow", "Lag Cumulative"),
       se.below = TRUE)

# ============================================================
# 3. HETEROGENEITY BY COUNTY SIZE
# ============================================================

cat("\n--- R3: Heterogeneity by county population ---\n")

# Split at median population
panel_het <- panel_7224 %>%
  group_by(county_fips) %>%
  mutate(mean_pop = mean(population, na.rm = TRUE)) %>%
  ungroup() %>%
  mutate(large_county = mean_pop > median(mean_pop))

r3a <- feols(log_emp ~ new_licenses | county_fips + time_id,
             data = panel_het %>% filter(!large_county),
             cluster = ~county_fips)

r3b <- feols(log_emp ~ new_licenses | county_fips + time_id,
             data = panel_het %>% filter(large_county),
             cluster = ~county_fips)

cat("Small counties:\n")
etable(r3a, se.below = TRUE)
cat("Large counties:\n")
etable(r3b, se.below = TRUE)

# ============================================================
# 4. ALTERNATIVE SE CLUSTERING
# ============================================================

cat("\n--- R4: Alternative clustering ---\n")

r4_robust <- feols(log_emp ~ new_licenses | county_fips + time_id,
                   data = panel_7224, vcov = "hetero")

r4_county <- feols(log_emp ~ new_licenses | county_fips + time_id,
                   data = panel_7224, cluster = ~county_fips)

r4_twoway <- feols(log_emp ~ new_licenses | county_fips + time_id,
                   data = panel_7224, cluster = ~county_fips + time_id)

etable(r4_robust, r4_county, r4_twoway,
       headers = c("Robust", "County", "Two-way"),
       se.below = TRUE)

# ============================================================
# 5. EMPLOYMENT LEVELS (not logs)
# ============================================================

cat("\n--- R5: Level specification ---\n")

r5a <- feols(Emp ~ new_licenses | county_fips + time_id,
             data = panel_7224, cluster = ~county_fips)

r5b <- feols(emp_rate ~ new_licenses_pc | county_fips + time_id,
             data = panel_7224, cluster = ~county_fips)

etable(r5a, r5b,
       headers = c("Emp Level", "Emp Rate"),
       se.below = TRUE)

# ============================================================
# 6. DOSE-RESPONSE (1 vs 2+ licenses)
# ============================================================

cat("\n--- R6: Dose-response ---\n")

panel_dose <- panel_7224 %>%
  mutate(
    dose_1 = as.integer(new_licenses == 1),
    dose_2plus = as.integer(new_licenses >= 2)
  )

r6 <- feols(log_emp ~ dose_1 + dose_2plus | county_fips + time_id,
            data = panel_dose, cluster = ~county_fips)

etable(r6, se.below = TRUE)

# ============================================================
# Save robustness results
# ============================================================

robust_results <- list(
  r1_nocovid = r1a,
  r1_nocovid_pop = r1b,
  r2_lag_flow = r2a,
  r2_lag_cum = r2b,
  r3_small = r3a,
  r3_large = r3b,
  r4_robust = r4_robust,
  r4_county = r4_county,
  r4_twoway = r4_twoway,
  r5_level = r5a,
  r5_rate = r5b,
  r6_dose = r6
)

saveRDS(robust_results, file.path(data_dir, "robustness_results.rds"))

cat("\n=== ROBUSTNESS COMPLETE ===\n")
