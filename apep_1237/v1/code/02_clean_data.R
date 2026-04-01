# =============================================================================
# 02_clean_data.R — Construct analysis panel
# =============================================================================

source("00_packages.R")

# ---- Load raw data ----
hbcu_dir <- readRDS("../data/hbcu_directory.rds")
hbcu_county_enroll <- readRDS("../data/hbcu_county_enrollment.rds")
hbcu_enroll <- readRDS("../data/hbcu_enrollment.rds")
hbcu_emp <- readRDS("../data/hbcu_inst_employment.rds")
qwi_raw <- readRDS("../data/qwi_raw.rds")

# ---- 1. Construct treatment intensity ----
# Ensure county_fips is character everywhere
hbcu_dir <- hbcu_dir %>% mutate(county_fips = str_pad(as.character(as.integer(county_fips)), 5, pad = "0"))
hbcu_county_enroll <- hbcu_county_enroll %>% mutate(county_fips = str_pad(as.character(as.integer(county_fips)), 5, pad = "0"))

# Pre-shock HBCU enrollment (average 2010-2011)
treatment_base <- hbcu_county_enroll %>%
  filter(year %in% c(2010, 2011)) %>%
  group_by(county_fips) %>%
  summarize(
    hbcu_enroll_pre = mean(hbcu_enrollment, na.rm = TRUE),
    n_hbcus = max(n_hbcus),
    .groups = "drop"
  )

# ---- 2. Clean QWI ----
# Create year-quarter time variable
qwi <- qwi_raw %>%
  mutate(
    county_fips = as.character(geography),
    # Pad to 5 digits
    county_fips = str_pad(county_fips, 5, pad = "0"),
    yq = year + (quarter - 1) / 4,
    # Event time: quarters relative to 2012Q3 (shock quarter)
    event_q = (year - 2012) * 4 + (quarter - 3)
  ) %>%
  filter(year >= 2008, year <= 2016)

# Get total employment per county (industry = "00") for normalization
qwi_total <- qwi %>%
  filter(industry == "00") %>%
  select(county_fips, year, quarter, yq, event_q, Emp, EarnS, HirA, Sep)

# Pre-shock average employment (2010-2011) for treatment intensity denominator
county_emp_base <- qwi_total %>%
  filter(year %in% c(2010, 2011)) %>%
  group_by(county_fips) %>%
  summarize(emp_pre = mean(Emp, na.rm = TRUE), .groups = "drop") %>%
  filter(emp_pre > 0)

# ---- 3. Merge treatment and create panel ----
# Compute treatment intensity = HBCU enrollment share of county employment
treatment <- treatment_base %>%
  inner_join(county_emp_base, by = "county_fips") %>%
  mutate(
    hbcu_share = hbcu_enroll_pre / emp_pre,
    hbcu_county = 1L
  )

# All counties panel
panel <- qwi_total %>%
  left_join(treatment %>% select(county_fips, hbcu_share, hbcu_county, n_hbcus, hbcu_enroll_pre),
            by = "county_fips") %>%
  mutate(
    hbcu_county = replace_na(hbcu_county, 0L),
    hbcu_share = replace_na(hbcu_share, 0),
    log_emp = log(pmax(Emp, 1)),
    log_earn = log(pmax(EarnS, 1)),
    state_fips = substr(county_fips, 1, 2),
    post = as.integer(yq >= 2012.5)  # 2012Q3 onward
  )

message(sprintf("Panel: %d county-quarter obs", nrow(panel)))
message(sprintf("  HBCU counties: %d", n_distinct(panel$county_fips[panel$hbcu_county == 1])))
message(sprintf("  Non-HBCU counties: %d", n_distinct(panel$county_fips[panel$hbcu_county == 0])))
message(sprintf("  Treatment intensity range: [%.4f, %.4f]",
                min(treatment$hbcu_share), max(treatment$hbcu_share)))

# ---- 4. Industry-level panel for mechanism tests ----
qwi_industry <- qwi %>%
  filter(industry != "00") %>%
  mutate(
    county_fips = str_pad(as.character(geography), 5, pad = "0"),
    log_emp = log(pmax(Emp, 1)),
    state_fips = substr(county_fips, 1, 2)
  ) %>%
  left_join(treatment %>% select(county_fips, hbcu_share, hbcu_county),
            by = "county_fips") %>%
  mutate(
    hbcu_county = replace_na(hbcu_county, 0L),
    hbcu_share = replace_na(hbcu_share, 0),
    post = as.integer(yq >= 2012.5)
  )

# ---- 5. First-stage: Aggregate HBCU enrollment trends ----
first_stage <- hbcu_enroll %>%
  left_join(hbcu_dir %>% select(unitid, county_fips), by = "unitid") %>%
  filter(!is.na(county_fips)) %>%
  group_by(year) %>%
  summarize(
    total_enrollment = sum(efytotlt, na.rm = TRUE),
    n_institutions = n_distinct(unitid),
    .groups = "drop"
  ) %>%
  mutate(
    pct_change = (total_enrollment / total_enrollment[year == 2011] - 1) * 100
  )

# ---- 6. IPEDS institutional employment trends ----
inst_emp_trend <- hbcu_emp %>%
  filter(!is.na(eaptot)) %>%
  group_by(year) %>%
  summarize(
    total_emp = sum(eaptot, na.rm = TRUE),
    n_institutions = n_distinct(unitid),
    .groups = "drop"
  ) %>%
  mutate(
    pct_change = (total_emp / total_emp[year == 2011] - 1) * 100
  )

# ---- 7. Save cleaned data ----
saveRDS(panel, "../data/panel.rds")
saveRDS(qwi_industry, "../data/panel_industry.rds")
saveRDS(treatment, "../data/treatment.rds")
saveRDS(first_stage, "../data/first_stage.rds")
saveRDS(inst_emp_trend, "../data/inst_emp_trend.rds")

message("Cleaning complete. Panel saved.")
