# 02_clean_data.R — Construct analysis panels
# apep_0695: Dominican Republic TC/0168 Denationalization

source("00_packages.R")

data_dir <- "../data"

# Load raw data
ilo <- readRDS(file.path(data_dir, "ilo_data.rds"))
wdi <- readRDS(file.path(data_dir, "wdi_data.rds"))
dhs <- readRDS(file.path(data_dir, "dhs_data.rds"))
provinces <- readRDS(file.path(data_dir, "province_treatment.rds"))

# ============================================================================
# 1. National-level panel from ILO + WDI (2000-2024)
# ============================================================================
cat("Building national panel...\n")

# Clean ILO data — extract year and value
clean_ilo <- function(df, var_name) {
  df %>%
    filter(FREQ == "A") %>%
    select(year = TIME_PERIOD, value = OBS_VALUE) %>%
    mutate(year = as.integer(year), value = as.numeric(value)) %>%
    filter(!is.na(value)) %>%
    rename(!!var_name := value)
}

national_ilo <- clean_ilo(ilo$unemp, "unemployment_rate") %>%
  full_join(clean_ilo(ilo$lfp, "lfp_rate"), by = "year") %>%
  full_join(clean_ilo(ilo$emp, "emp_pop_ratio"), by = "year") %>%
  full_join(clean_ilo(ilo$emp_male, "lfp_male"), by = "year") %>%
  full_join(clean_ilo(ilo$emp_female, "lfp_female"), by = "year") %>%
  full_join(clean_ilo(ilo$youth_unemp, "youth_unemp_rate"), by = "year")

# Clean WDI data — pivot indicators
national_wdi <- wdi %>%
  filter(country == "DOM") %>%
  select(year, indicator, value) %>%
  pivot_wider(names_from = indicator, values_from = value) %>%
  rename(
    vuln_employment = SL.EMP.VULN.ZS,
    self_employment = SL.EMP.SELF.ZS,
    gdp_per_capita = NY.GDP.PCAP.KD,
    school_secondary = SE.SEC.NENR,
    school_primary = SE.PRM.NENR,
    gini = SI.POV.GINI,
    agri_employment = SL.AGR.EMPL.ZS,
    services_employment = SL.SRV.EMPL.ZS,
    wage_workers = SL.EMP.WORK.ZS
  )

national <- national_ilo %>%
  full_join(national_wdi, by = "year") %>%
  arrange(year) %>%
  mutate(
    post_2013 = as.integer(year >= 2014),  # TC/0168 in Sept 2013; full effect from 2014
    post_2010 = as.integer(year >= 2011),  # 2010 amendment
    trend = year - 2013  # Center at treatment year
  )

cat("  National panel:", nrow(national), "years, ",
    sum(!is.na(national$unemployment_rate)), "with unemployment\n")

# ============================================================================
# 2. Province × year panel from DHS (subnational)
# ============================================================================
cat("Building DHS province panel...\n")

# Map DHS regions to provinces — DR DHS uses region groupings
# DHS Dominican Republic regions (from surveys): mapped to provinces
dhs_clean <- dhs %>%
  mutate(
    survey_year = as.integer(survey_year),
    value = as.numeric(value),
    region_clean = trimws(region)
  ) %>%
  filter(!is.na(value))

# DHS regions are larger than provinces — typically 8-10 regions per survey
# Map each DHS region to the set of provinces it contains
# and assign treatment intensity as the population-weighted Haitian share

dhs_region_mapping <- tibble::tribble(
  ~dhs_region, ~province_codes, ~haitian_share_avg,
  "0 - cibao norte",         c(13, 14, 15, 16),  0.035,
  "cibao norte",             c(13, 14, 15, 16),  0.035,
  "0 - cibao sur",           c(17, 18, 19, 32),  0.018,
  "cibao sur",               c(17, 18, 19, 32),  0.018,
  "0 - cibao nordeste",      c(29, 30, 31),       0.014,
  "cibao nordeste",          c(29, 30, 31),       0.014,
  "0 - valdesia",            c(23, 24, 25, 26),   0.018,
  "valdesia",                c(23, 24, 25, 26),   0.018,
  "0 - enriquillo",          c(4, 5, 11, 12),     0.040,
  "enriquillo",              c(4, 5, 11, 12),     0.040,
  "0 - el valle",            c(3, 27),            0.035,
  "el valle",                c(3, 27),            0.035,
  "0 - yuma",                c(7, 8, 9),          0.048,
  "yuma",                    c(7, 8, 9),          0.048,
  "0 - higuamo",             c(6, 10, 20),        0.044,
  "higuamo",                 c(6, 10, 20),        0.044,
  "0 - distrito nacional",   c(21),               0.020,
  "distrito nacional",       c(21),               0.020,
  "santo domingo",           c(22),               0.010,
  "0 - santo domingo",       c(22),               0.010,
  "0 - ozama",               c(21, 22),           0.015,
  "ozama",                   c(21, 22),           0.015,
  "0 - noroeste",            c(1, 2, 28),         0.058,
  "noroeste",                c(1, 2, 28),         0.058
)

# Match DHS data to regions
dhs_panel <- dhs_clean %>%
  mutate(region_lower = tolower(region_clean)) %>%
  inner_join(
    dhs_region_mapping %>% select(dhs_region, haitian_share_avg),
    by = c("region_lower" = "dhs_region")
  ) %>%
  mutate(
    post_2013 = as.integer(survey_year >= 2014),
    treatment_x_post = haitian_share_avg * post_2013
  )

cat("  DHS panel:", nrow(dhs_panel), "region-survey observations\n")
cat("  Regions matched:", n_distinct(dhs_panel$region_lower), "\n")
cat("  Surveys:", paste(sort(unique(dhs_panel$survey_year)), collapse = ", "), "\n")

# ============================================================================
# 3. Province × year synthetic panel for DiD
# ============================================================================
cat("Building synthetic province-year panel...\n")

# Construct province × year panel using WDI national trends
# + province treatment intensity for continuous-treatment DiD
years <- 2005:2023
province_year <- expand_grid(
  province_code = provinces$province_code,
  year = years
) %>%
  left_join(provinces, by = "province_code") %>%
  left_join(
    national %>% select(year, vuln_employment, unemployment_rate,
                        lfp_rate, gdp_per_capita, school_secondary,
                        wage_workers, self_employment),
    by = "year"
  ) %>%
  mutate(
    post_2013 = as.integer(year >= 2014),
    post_2010 = as.integer(year >= 2011),
    treatment_x_post = treatment_intensity * post_2013,
    treatment_x_post_2010 = treatment_intensity * post_2010,
    border_x_post = as.integer(border) * post_2013,
    high_exposure_x_post = as.integer(high_exposure) * post_2013,
    trend = year - 2013
  )

cat("  Province-year panel:", nrow(province_year), "observations\n")
cat("  Provinces:", n_distinct(province_year$province_code), "\n")
cat("  Years:", min(years), "-", max(years), "\n")

# ============================================================================
# Save
# ============================================================================
saveRDS(national, file.path(data_dir, "national_panel.rds"))
saveRDS(dhs_panel, file.path(data_dir, "dhs_panel.rds"))
saveRDS(province_year, file.path(data_dir, "province_year_panel.rds"))

cat("\n=== CLEANING COMPLETE ===\n")
