## 03_main_analysis.R — Main regressions
## apep_0810: Florida Liquor License Lottery and Business Formation

source("00_packages.R")
data_dir <- "../data/"

panel_7224 <- readRDS(file.path(data_dir, "panel_7224.rds"))
panel_7225 <- readRDS(file.path(data_dir, "panel_7225.rds"))
stacked <- readRDS(file.path(data_dir, "stacked_panel.rds"))

cat("=== MAIN ANALYSIS ===\n\n")

# ============================================================
# 1. CUMULATIVE TREATMENT SPECIFICATION
# ============================================================

cat("--- Specification 1: Cumulative licenses on employment ---\n")

# 1a. Log employment on cumulative new licenses (county + quarter FE)
m1a <- feols(log_emp ~ cum_new_licenses | county_fips + time_id,
             data = panel_7224, cluster = ~county_fips)

# 1b. Add log population control
m1b <- feols(log_emp ~ cum_new_licenses + log_pop | county_fips + time_id,
             data = panel_7224, cluster = ~county_fips)

# 1c. Employment rate per 10,000 on cumulative licenses per capita
m1c <- feols(emp_rate ~ cum_licenses_pc | county_fips + time_id,
             data = panel_7224, cluster = ~county_fips)

# 1d. Flow specification: new licenses in current year
m1d <- feols(log_emp ~ new_licenses | county_fips + time_id,
             data = panel_7224, cluster = ~county_fips)

# 1e. Flow with population control
m1e <- feols(log_emp ~ new_licenses + log_pop | county_fips + time_id,
             data = panel_7224, cluster = ~county_fips)

cat("Cumulative treatment (log emp):\n")
etable(m1a, m1b, m1d, m1e,
       headers = c("Cum Licenses", "Cum + Pop", "Flow", "Flow + Pop"),
       se.below = TRUE)

# ============================================================
# 2. EARNINGS SPECIFICATION
# ============================================================

cat("\n--- Specification 2: Effect on earnings ---\n")

# Earnings per worker
m2a <- feols(earn_per_worker ~ cum_new_licenses | county_fips + time_id,
             data = panel_7224 %>% filter(!is.na(earn_per_worker)),
             cluster = ~county_fips)

m2b <- feols(earn_per_worker ~ cum_new_licenses + log_pop | county_fips + time_id,
             data = panel_7224 %>% filter(!is.na(earn_per_worker)),
             cluster = ~county_fips)

etable(m2a, m2b,
       headers = c("Earnings/Worker", "Earnings + Pop"),
       se.below = TRUE)

# ============================================================
# 3. TRIPLE-DIFFERENCE: DRINKING vs. RESTAURANTS
# ============================================================

cat("\n--- Specification 3: Triple-difference (Drinking vs Restaurants) ---\n")

# Triple-diff: treatment × sector interaction
m3a <- feols(log_emp ~ cum_treat_x_drinking + cum_new_licenses + is_drinking |
               county_fips^sector + time_id^sector,
             data = stacked, cluster = ~county_fips)

m3b <- feols(log_emp ~ cum_treat_x_drinking + cum_new_licenses + is_drinking + log_pop |
               county_fips^sector + time_id^sector,
             data = stacked, cluster = ~county_fips)

cat("Triple-difference results:\n")
etable(m3a, m3b,
       headers = c("DDD Base", "DDD + Pop"),
       se.below = TRUE)

# ============================================================
# 4. PLACEBO: RESTAURANTS ONLY
# ============================================================

cat("\n--- Specification 4: Placebo (Restaurants NAICS 7225) ---\n")

m4a <- feols(log_emp ~ cum_new_licenses | county_fips + time_id,
             data = panel_7225, cluster = ~county_fips)

m4b <- feols(log_emp ~ cum_new_licenses + log_pop | county_fips + time_id,
             data = panel_7225, cluster = ~county_fips)

cat("Placebo (should be null):\n")
etable(m4a, m4b,
       headers = c("Restaurants", "Restaurants + Pop"),
       se.below = TRUE)

# ============================================================
# 5. EVENT STUDY — Dynamic effects
# ============================================================

cat("\n--- Specification 5: Event study ---\n")

# Create event time relative to first new license in county
panel_es <- panel_7224 %>%
  group_by(county_fips) %>%
  mutate(
    first_treat_year = min(year[new_licenses > 0], na.rm = TRUE),
    first_treat_year = ifelse(is.infinite(first_treat_year), NA, first_treat_year)
  ) %>%
  ungroup() %>%
  filter(!is.na(first_treat_year)) %>%
  mutate(
    event_year = year - first_treat_year
  ) %>%
  # Bin endpoints
  mutate(
    event_year_binned = case_when(
      event_year <= -4 ~ -4L,
      event_year >= 6 ~ 6L,
      TRUE ~ as.integer(event_year)
    )
  )

# Event study regression
m5 <- feols(log_emp ~ i(event_year_binned, ref = -1) | county_fips + time_id,
            data = panel_es, cluster = ~county_fips)

cat("Event study coefficients:\n")
print(coeftable(m5))

# ============================================================
# 6. SAVE RESULTS
# ============================================================

results <- list(
  m1_cum = m1a,
  m1_cum_pop = m1b,
  m1_cum_rate = m1c,
  m1_flow = m1d,
  m1_flow_pop = m1e,
  m2_earn = m2a,
  m2_earn_pop = m2b,
  m3_ddd = m3a,
  m3_ddd_pop = m3b,
  m4_placebo = m4a,
  m4_placebo_pop = m4b,
  m5_event = m5
)

saveRDS(results, file.path(data_dir, "main_results.rds"))

# ============================================================
# 7. DIAGNOSTICS for validator
# ============================================================

# Count treated units and pre-periods
n_treated_counties <- panel_7224 %>%
  group_by(county_fips) %>%
  summarise(ever = any(new_licenses > 0)) %>%
  filter(ever) %>%
  nrow()

n_pre <- panel_es %>%
  filter(event_year < 0) %>%
  pull(event_year) %>%
  n_distinct()

jsonlite::write_json(
  list(
    n_treated = n_treated_counties,
    n_pre = n_pre,
    n_obs = nrow(panel_7224)
  ),
  file.path(data_dir, "diagnostics.json"),
  auto_unbox = TRUE
)

cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated_counties, n_pre, nrow(panel_7224)))

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
