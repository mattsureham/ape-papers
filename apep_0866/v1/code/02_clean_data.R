## 02_clean_data.R — Construct analysis variables
## apep_0866: Male-biased labor demand, sex ratios, and women's outcomes

source("00_packages.R")

qwi_df <- readRDS("../data/qwi_raw.rds")
acs_df <- readRDS("../data/acs_raw.rds")

cat(sprintf("QWI loaded: %d rows\n", nrow(qwi_df)))
cat(sprintf("ACS loaded: %d rows\n", nrow(acs_df)))

# =============================================================================
# 1. Construct shale exposure: mining employment share (pre-boom baseline)
# =============================================================================

# Total employment by county-quarter (sex=0 aggregated, industry=00)
# But we have sex-specific data. Let's compute total from sex=1 + sex=2
total_emp <- qwi_df |>
  filter(industry %in% c("21")) |>
  group_by(fips, year, quarter) |>
  summarise(mining_emp = sum(Emp, na.rm = TRUE), .groups = "drop")

all_emp <- qwi_df |>
  group_by(fips, year, quarter) |>
  summarise(total_emp = sum(Emp, na.rm = TRUE), .groups = "drop")

# Pre-boom mining share (2001-2004 average)
pre_boom_mining <- total_emp |>
  filter(year >= 2001, year <= 2004) |>
  group_by(fips) |>
  summarise(pre_mining_emp = mean(mining_emp, na.rm = TRUE), .groups = "drop")

pre_boom_total <- all_emp |>
  filter(year >= 2001, year <= 2004) |>
  group_by(fips) |>
  summarise(pre_total_emp = mean(total_emp, na.rm = TRUE), .groups = "drop")

shale_exposure <- pre_boom_mining |>
  left_join(pre_boom_total, by = "fips") |>
  mutate(
    mining_share_pre = pre_mining_emp / pre_total_emp,
    # Binary: high mining county (top quartile of mining share among counties with any mining)
    has_mining = pre_mining_emp > 10,
    high_mining = mining_share_pre > quantile(mining_share_pre[has_mining], 0.75, na.rm = TRUE)
  )

cat(sprintf("Counties with any pre-boom mining: %d\n", sum(shale_exposure$has_mining)))
cat(sprintf("High-mining counties (top quartile): %d\n", sum(shale_exposure$high_mining, na.rm = TRUE)))

# =============================================================================
# 2. Build county-year panel for main analysis
# =============================================================================

# Aggregate QWI to annual by county x sex
annual_qwi <- qwi_df |>
  group_by(fips, year, sex, industry, state) |>
  summarise(
    emp = mean(Emp, na.rm = TRUE),
    earnings = mean(EarnS, na.rm = TRUE),
    hires = mean(HirA, na.rm = TRUE),
    .groups = "drop"
  )

# Create county-year-sex panel for non-mining industries
# Key: female employment in non-mining sectors
non_mining <- annual_qwi |>
  filter(!(industry %in% c("21"))) |>
  group_by(fips, year, sex, state) |>
  summarise(
    emp_nonmining = sum(emp, na.rm = TRUE),
    earnings_nonmining = weighted.mean(earnings, emp, na.rm = TRUE),
    hires_nonmining = sum(hires, na.rm = TRUE),
    .groups = "drop"
  )

# Mining employment (to show first stage)
mining_panel <- annual_qwi |>
  filter(industry == "21") |>
  group_by(fips, year, sex, state) |>
  summarise(
    emp_mining = sum(emp, na.rm = TRUE),
    earnings_mining = weighted.mean(earnings, emp, na.rm = TRUE),
    .groups = "drop"
  )

# Merge
panel <- non_mining |>
  left_join(mining_panel, by = c("fips", "year", "sex", "state")) |>
  left_join(shale_exposure |> select(fips, mining_share_pre, has_mining, high_mining),
            by = "fips") |>
  mutate(
    emp_mining = replace_na(emp_mining, 0),
    earnings_mining = replace_na(earnings_mining, 0),
    total_emp = emp_nonmining + emp_mining,
    female = as.integer(sex == 2),
    # Treatment intensity: continuous
    treatment = mining_share_pre,
    # Period indicators (boom starts 2006: first year of significant Bakken production)
    period = case_when(
      year <= 2005 ~ "pre_boom",
      year >= 2006 & year <= 2014 ~ "boom",
      year >= 2015 & year <= 2018 ~ "bust",
      year >= 2019 ~ "recovery"
    ),
    boom = as.integer(year >= 2006 & year <= 2014),
    bust = as.integer(year >= 2015 & year <= 2018),
    post = as.integer(year >= 2006)
  )

# Drop counties with no pre-boom data
panel <- panel |>
  filter(!is.na(mining_share_pre))

cat(sprintf("Panel: %d rows, %d counties, years %d-%d\n",
            nrow(panel), n_distinct(panel$fips),
            min(panel$year), max(panel$year)))

# =============================================================================
# 3. Merge ACS demographics
# =============================================================================

acs_clean <- acs_df |>
  select(fips, year, total_pop, male_pop, female_pop, sex_ratio) |>
  filter(!is.na(sex_ratio), sex_ratio > 0.5, sex_ratio < 2)

# County-level demographics (not sex-specific)
panel <- panel |>
  left_join(acs_clean, by = c("fips", "year"))

# =============================================================================
# 4. Compute key outcome variables
# =============================================================================

panel <- panel |>
  mutate(
    # Log outcomes
    log_emp_nonmining = log(emp_nonmining + 1),
    log_earnings_nonmining = log(earnings_nonmining + 1),
    log_emp_mining = log(emp_mining + 1),
    # Gender earnings gap (county-year level)
    county_year_id = paste(fips, year, sep = "_")
  )

# Gender gap: compute within county-year
gender_gap <- panel |>
  select(fips, year, sex, earnings_nonmining) |>
  pivot_wider(names_from = sex, values_from = earnings_nonmining,
              names_prefix = "earn_sex") |>
  mutate(
    gender_earn_ratio = earn_sex2 / earn_sex1,  # female / male
    gender_earn_gap = (earn_sex1 - earn_sex2) / earn_sex1  # (male - female) / male
  ) |>
  select(fips, year, gender_earn_ratio, gender_earn_gap)

panel <- panel |>
  left_join(gender_gap, by = c("fips", "year"))

# =============================================================================
# 5. Save analysis-ready dataset
# =============================================================================

saveRDS(panel, "../data/analysis_panel.rds")

# Summary stats
cat("\n=== Panel Summary ===\n")
cat(sprintf("Total observations: %d\n", nrow(panel)))
cat(sprintf("Unique counties: %d\n", n_distinct(panel$fips)))
cat(sprintf("Year range: %d - %d\n", min(panel$year), max(panel$year)))
cat(sprintf("High-mining counties: %d\n", n_distinct(panel$fips[panel$high_mining == TRUE])))
cat(sprintf("Non-mining counties: %d\n",
            n_distinct(panel$fips[panel$has_mining == FALSE])))

# Write diagnostics baseline
diag <- list(
  n_counties = n_distinct(panel$fips),
  n_treated = n_distinct(panel$fips[panel$high_mining == TRUE]),
  n_control = n_distinct(panel$fips[panel$has_mining == FALSE]),
  n_years = n_distinct(panel$year),
  n_obs = nrow(panel),
  year_min = min(panel$year),
  year_max = max(panel$year)
)
jsonlite::write_json(diag, "../data/diagnostics_preliminary.json", auto_unbox = TRUE)
cat("\nPreliminary diagnostics saved.\n")
