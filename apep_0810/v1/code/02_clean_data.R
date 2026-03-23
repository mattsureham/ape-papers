## 02_clean_data.R — Build county-quarter analysis panel
## apep_0810: Florida Liquor License Lottery and Business Formation

source("00_packages.R")
data_dir <- "../data/"

# ============================================================
# Load raw data
# ============================================================

qwi_df <- readRDS(file.path(data_dir, "qwi_florida.rds"))
pop_treatment <- readRDS(file.path(data_dir, "population_treatment.rds"))

# ============================================================
# 1. Clean QWI panel
# ============================================================

cat("Building QWI panel...\n")

qwi_panel <- qwi_df %>%
  mutate(
    county_fips = county,
    year = as.integer(year),
    quarter = as.integer(quarter),
    Emp = as.numeric(Emp),
    EarnS = as.numeric(EarnS),
    EmpS = as.numeric(EmpS)
  ) %>%
  # Create year-quarter time variable
  mutate(
    yq = year + (quarter - 1) / 4,
    time_id = (year - 2012) * 4 + quarter
  ) %>%
  select(county_fips, year, quarter, yq, time_id, naics,
         Emp, EarnS, EmpS)

# Split into treatment sector (7224) and placebo sector (7225)
drinking <- qwi_panel %>% filter(naics == "7224")
restaurants <- qwi_panel %>% filter(naics == "7225")

cat(sprintf("  Drinking places (7224): %d obs, %d counties, %d quarters\n",
            nrow(drinking), n_distinct(drinking$county_fips),
            n_distinct(drinking$time_id)))
cat(sprintf("  Restaurants (7225): %d obs, %d counties, %d quarters\n",
            nrow(restaurants), n_distinct(restaurants$county_fips),
            n_distinct(restaurants$time_id)))

# ============================================================
# 2. Merge treatment into quarterly panel
# ============================================================

cat("Merging treatment data...\n")

# Treatment is annual — map to quarterly
treatment_annual <- pop_treatment %>%
  select(county_fips, year, population, expected_licenses, new_licenses) %>%
  mutate(
    # Cumulative new licenses from start of sample
    cum_new_licenses = new_licenses  # Will be accumulated below
  )

# Compute cumulative licenses
treatment_annual <- treatment_annual %>%
  arrange(county_fips, year) %>%
  group_by(county_fips) %>%
  mutate(
    cum_new_licenses = cumsum(new_licenses),
    # Per capita measures (per 10,000 pop)
    new_licenses_pc = new_licenses / population * 10000,
    cum_licenses_pc = cum_new_licenses / population * 10000,
    # Log population
    log_pop = log(population)
  ) %>%
  ungroup()

# Map annual values to all quarters
treatment_quarterly <- treatment_annual %>%
  crossing(quarter = 1:4) %>%
  mutate(
    yq = year + (quarter - 1) / 4,
    time_id = (year - 2012) * 4 + quarter
  )

# Merge with drinking places
panel_7224 <- drinking %>%
  left_join(
    treatment_quarterly %>%
      select(county_fips, year, quarter, population, expected_licenses,
             new_licenses, cum_new_licenses, new_licenses_pc, cum_licenses_pc, log_pop),
    by = c("county_fips", "year", "quarter")
  ) %>%
  filter(!is.na(population))

# Merge with restaurants (placebo)
panel_7225 <- restaurants %>%
  left_join(
    treatment_quarterly %>%
      select(county_fips, year, quarter, population, expected_licenses,
             new_licenses, cum_new_licenses, new_licenses_pc, cum_licenses_pc, log_pop),
    by = c("county_fips", "year", "quarter")
  ) %>%
  filter(!is.na(population))

cat(sprintf("  Panel 7224: %d obs\n", nrow(panel_7224)))
cat(sprintf("  Panel 7225: %d obs\n", nrow(panel_7225)))

# ============================================================
# 3. Create analysis variables
# ============================================================

cat("Creating analysis variables...\n")

create_analysis_vars <- function(df) {
  df %>%
    mutate(
      # Employment rate per 10,000 population
      emp_rate = Emp / population * 10000,
      # Log employment (add 1 for zeros)
      log_emp = log(Emp + 1),
      # Earnings per worker
      earn_per_worker = ifelse(Emp > 0, EarnS / Emp, NA),
      # Post-treatment indicator (any new license in current or prior year)
      ever_treated = cum_new_licenses > 0,
      # Treatment intensity
      treat_intensity = cum_new_licenses
    ) %>%
    # Create county numeric ID for FE
    mutate(county_id = as.numeric(as.factor(county_fips)))
}

panel_7224 <- create_analysis_vars(panel_7224)
panel_7225 <- create_analysis_vars(panel_7225)

# ============================================================
# 4. Stacked panel for DiD (both sectors)
# ============================================================

stacked <- bind_rows(
  panel_7224 %>% mutate(sector = "drinking"),
  panel_7225 %>% mutate(sector = "restaurant")
) %>%
  mutate(
    is_drinking = as.integer(sector == "drinking"),
    # Triple-diff treatment: new licenses × drinking sector
    treat_x_drinking = new_licenses * is_drinking,
    cum_treat_x_drinking = cum_new_licenses * is_drinking
  )

cat(sprintf("  Stacked panel: %d obs\n", nrow(stacked)))

# ============================================================
# 5. Summary statistics
# ============================================================

cat("\n=== SUMMARY STATISTICS ===\n")

cat("\nDrinking Places (NAICS 7224):\n")
panel_7224 %>%
  summarise(
    mean_emp = mean(Emp, na.rm = TRUE),
    sd_emp = sd(Emp, na.rm = TRUE),
    median_emp = median(Emp, na.rm = TRUE),
    mean_emp_rate = mean(emp_rate, na.rm = TRUE),
    sd_emp_rate = sd(emp_rate, na.rm = TRUE),
    mean_earn = mean(earn_per_worker, na.rm = TRUE),
    n_obs = n(),
    n_counties = n_distinct(county_fips)
  ) %>%
  print()

cat("\nTreatment Variable (new licenses per county-year):\n")
treatment_annual %>%
  filter(year >= 2012) %>%
  summarise(
    mean_new = mean(new_licenses),
    sd_new = sd(new_licenses),
    prop_treated = mean(new_licenses > 0),
    mean_cum = mean(cum_new_licenses),
    total_new = sum(new_licenses)
  ) %>%
  print()

# ============================================================
# Save
# ============================================================

saveRDS(panel_7224, file.path(data_dir, "panel_7224.rds"))
saveRDS(panel_7225, file.path(data_dir, "panel_7225.rds"))
saveRDS(stacked, file.path(data_dir, "stacked_panel.rds"))
saveRDS(treatment_annual, file.path(data_dir, "treatment_annual.rds"))

cat("\nPanel data saved.\n")
