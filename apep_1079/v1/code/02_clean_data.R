# 02_clean_data.R — Construct analysis panel
# apep_1079: Section 301 tariffs and racial employment effects

source("00_packages.R")

qwi <- readRDS("../data/qwi_panel.rds")
industry_tx <- readRDS("../data/industry_treatment.rds")

cat("QWI rows:", nrow(qwi), "\n")
cat("Industry treatment rows:", nrow(industry_tx), "\n")

# ============================================================
# 1. Clean QWI panel
# ============================================================

# Create time variable (quarterly)
qwi <- qwi %>%
  mutate(
    # Ensure geography is 5-digit FIPS (zero-padded)
    fips = sprintf("%05d", as.integer(geography)),
    state_fips = substr(fips, 1, 2),
    naics3 = substr(industry, 1, 3),
    # Quarter as integer for time series
    yrq = year + (quarter - 1) / 4,
    time_id = (year - 2015) * 4 + quarter,
    # Post-treatment indicator (Lists 1+2: July 2018 = 2018Q3)
    post = as.integer(yrq >= 2018.5),
    # Race labels
    race_label = case_when(
      race == "A0" ~ "All",
      race == "A1" ~ "White",
      race == "A2" ~ "Black",
      race == "A4" ~ "Asian",
      TRUE ~ race
    )
  )

# Drop cells with zero or missing employment
qwi <- qwi %>%
  filter(!is.na(Emp), Emp > 0)

cat("After dropping zero/missing Emp:", nrow(qwi), "rows\n")

# ============================================================
# 2. Merge industry treatment
# ============================================================
qwi <- qwi %>%
  left_join(
    industry_tx %>% select(naics3, cip, tariff_max, tariff_exposure, early_hit),
    by = "naics3"
  )

# For service sectors, set tariff exposure to 0
qwi <- qwi %>%
  mutate(
    cip = ifelse(is.na(cip), 0, cip),
    tariff_max = ifelse(is.na(tariff_max), 0, tariff_max),
    tariff_exposure = ifelse(is.na(tariff_exposure), 0, tariff_exposure),
    early_hit = ifelse(is.na(early_hit), FALSE, early_hit)
  )

# ============================================================
# 3. Construct county-level Bartik exposure
# ============================================================
# County tariff exposure = Σ_s (L_{cs,2017Q2} / L_{c,2017Q2}) × tariff_exposure_s

# Get 2017Q2 employment shares (pre-treatment baseline)
baseline <- qwi %>%
  filter(year == 2017, quarter == 2, race == "A0", sector == "manufacturing") %>%
  group_by(fips) %>%
  mutate(
    county_total_emp = sum(Emp, na.rm = TRUE),
    emp_share = Emp / county_total_emp
  ) %>%
  ungroup() %>%
  select(fips, naics3, emp_share, county_total_emp)

# County-level Bartik exposure
county_exposure <- baseline %>%
  left_join(
    industry_tx %>% select(naics3, tariff_exposure, cip, tariff_max),
    by = "naics3"
  ) %>%
  mutate(
    tariff_exposure = ifelse(is.na(tariff_exposure), 0, tariff_exposure),
    cip = ifelse(is.na(cip), 0, cip)
  ) %>%
  group_by(fips) %>%
  summarize(
    bartik_tariff = sum(emp_share * tariff_exposure, na.rm = TRUE),
    bartik_cip = sum(emp_share * cip, na.rm = TRUE),
    mfg_emp_2017 = first(county_total_emp),
    n_industries = n(),
    .groups = "drop"
  )

cat("County exposure computed for", nrow(county_exposure), "counties\n")
cat("Bartik tariff exposure: mean =", round(mean(county_exposure$bartik_tariff), 4),
    ", sd =", round(sd(county_exposure$bartik_tariff), 4), "\n")

# Merge county exposure back
qwi <- qwi %>%
  left_join(county_exposure %>% select(fips, bartik_tariff, bartik_cip), by = "fips")

qwi <- qwi %>%
  mutate(
    bartik_tariff = ifelse(is.na(bartik_tariff), 0, bartik_tariff),
    bartik_cip = ifelse(is.na(bartik_cip), 0, bartik_cip)
  )

# ============================================================
# 4. Create regression variables
# ============================================================
qwi <- qwi %>%
  mutate(
    log_emp = log(Emp),
    log_earn = ifelse(EarnS > 0, log(EarnS), NA_real_),
    # Indicators for race interactions
    is_asian = as.integer(race == "A4"),
    is_black = as.integer(race == "A2"),
    is_white = as.integer(race == "A1"),
    # High-exposure industry indicator (top tercile of tariff_max)
    high_exposure = as.integer(tariff_max >= 0.25),
    # County-industry-race cell ID for FE
    cell_id = paste(fips, naics3, race, sep = "_"),
    # Industry-quarter FE
    ind_qtr = paste(naics3, year, quarter, sep = "_"),
    # Race-quarter FE
    race_qtr = paste(race, year, quarter, sep = "_"),
    # County-race FE
    county_race = paste(fips, race, sep = "_"),
    # State FIPS for clustering
    state = state_fips
  )

# ============================================================
# 5. Descriptive: Asian concentration by industry
# ============================================================
asian_shares <- qwi %>%
  filter(year == 2017, quarter == 2, sector == "manufacturing") %>%
  group_by(naics3, race_label) %>%
  summarize(total_emp = sum(Emp, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = race_label, values_from = total_emp, values_fill = 0) %>%
  mutate(
    total = All,
    asian_share = Asian / All,
    white_share = White / All,
    black_share = Black / All
  ) %>%
  left_join(industry_tx %>% select(naics3, tariff_max, cip), by = "naics3") %>%
  arrange(desc(asian_share))

cat("\nAsian worker concentration by NAICS 3-digit (2017Q2):\n")
print(asian_shares %>% select(naics3, total, asian_share, tariff_max, cip) %>%
  mutate(across(c(asian_share), ~round(., 3))))

# ============================================================
# 6. Restrict to analysis sample
# ============================================================
# Manufacturing panel, individual race groups only (drop A0)
analysis <- qwi %>%
  filter(sector == "manufacturing", race != "A0")

# Placebo: service sectors
placebo <- qwi %>%
  filter(sector == "services", race != "A0")

cat("\nAnalysis sample:", nrow(analysis), "rows\n")
cat("  Counties:", n_distinct(analysis$fips), "\n")
cat("  Industries:", n_distinct(analysis$naics3), "\n")
cat("  Race groups:", n_distinct(analysis$race), "\n")
cat("  Quarters:", n_distinct(analysis$time_id), "\n")

cat("\nPlacebo sample:", nrow(placebo), "rows\n")

# Save
saveRDS(analysis, "../data/analysis_panel.rds")
saveRDS(placebo, "../data/placebo_panel.rds")
saveRDS(county_exposure, "../data/county_exposure.rds")
saveRDS(asian_shares, "../data/asian_industry_shares.rds")
saveRDS(qwi, "../data/qwi_full.rds")

cat("\nCleaned data saved.\n")
