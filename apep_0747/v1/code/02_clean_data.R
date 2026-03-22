## 02_clean_data.R — Construct analysis panel
source("00_packages.R")

acs_raw  <- readRDS("../data/acs_raw.rds")
nass_raw <- readRDS("../data/nass_raw.rds")

# ===================================================================
# 1. Clean ACS: pivot to wide county-year panel
# ===================================================================
cat("Cleaning ACS data...\n")

acs <- acs_raw %>%
  select(GEOID, NAME, variable, estimate, year) %>%
  pivot_wider(names_from = variable, values_from = estimate) %>%
  mutate(
    state_fips = substr(GEOID, 1, 2),
    county_fips = GEOID,
    hisp_share = hisp_pop / total_pop,
    black_share = black_pop / total_pop,
    white_share = white_pop / total_pop,
    poverty_rate = pov_below / pov_total,
    log_income = log(pmax(med_income, 1))
  ) %>%
  filter(!is.na(total_pop), total_pop > 0)

cat(sprintf("ACS panel: %d county-years, %d counties\n",
            nrow(acs), n_distinct(acs$county_fips)))

# ===================================================================
# 2. Clean NASS: get pre-treatment hog inventory by county
# ===================================================================
cat("Cleaning NASS data...\n")

# NASS FIPS: state_fips_code (2 digit) + county_code (3 digit)
nass <- nass_raw %>%
  filter(
    !is.na(state_fips_code),
    !is.na(county_code),
    county_code != "",
    county_code != "998",  # "OTHER (COMBINED) COUNTIES"
    county_code != "999"   # "OTHER COUNTIES"
  ) %>%
  mutate(
    county_fips = paste0(
      str_pad(state_fips_code, 2, pad = "0"),
      str_pad(county_code, 3, pad = "0")
    ),
    hog_inv = as.numeric(gsub(",", "", Value))
  ) %>%
  filter(!is.na(hog_inv)) %>%
  select(county_fips, census_year, hog_inv)

# Use 2012 Census of Agriculture for pre-treatment classification
# (before any RTF expansion: ND 2012 is borderline, use 2007 as robustness)
hogs_2012 <- nass %>%
  filter(census_year == 2012) %>%
  group_by(county_fips) %>%
  summarize(hog_inv_2012 = sum(hog_inv, na.rm = TRUE), .groups = "drop")

# Classify into quintiles
hogs_2012 <- hogs_2012 %>%
  filter(hog_inv_2012 > 0) %>%
  mutate(
    hog_quintile = ntile(hog_inv_2012, 5),
    high_cafo = as.integer(hog_quintile >= 4),  # Top 40% = high CAFO
    log_hogs = log(hog_inv_2012)
  )

cat(sprintf("NASS hog counties: %d (with positive inventory in 2012)\n", nrow(hogs_2012)))
cat("Hog quintile distribution:\n")
print(table(hogs_2012$hog_quintile))

# ===================================================================
# 3. Define RTF treatment
# ===================================================================
cat("Defining RTF treatment...\n")

# State FIPS codes for treated states and their RTF expansion year
rtf_states <- data.frame(
  state_fips = c("38", "29", "19", "37", "31", "54", "12"),
  state_abbr = c("ND", "MO", "IA", "NC", "NE", "WV", "FL"),
  rtf_year   = c(2012L, 2014L, 2017L, 2017L, 2019L, 2019L, 2021L),
  stringsAsFactors = FALSE
)

cat("RTF treatment states:\n")
print(rtf_states)

# ===================================================================
# 4. Merge into analysis panel
# ===================================================================
cat("Constructing analysis panel...\n")

panel <- acs %>%
  left_join(hogs_2012, by = "county_fips") %>%
  left_join(rtf_states, by = "state_fips") %>%
  mutate(
    # Treatment indicators
    rtf_state = as.integer(!is.na(rtf_year)),
    post_rtf = as.integer(!is.na(rtf_year) & year >= rtf_year),
    # For counties without hog data, set to 0 (no CAFOs)
    hog_inv_2012 = replace_na(hog_inv_2012, 0),
    high_cafo = replace_na(high_cafo, 0L),
    hog_quintile = replace_na(hog_quintile, 0L),
    log_hogs = replace_na(log_hogs, 0),
    # Triple-diff interaction
    ddd = post_rtf * high_cafo,
    # Cohort year for CS-DiD (0 = never treated)
    cohort_year = ifelse(rtf_state == 1 & high_cafo == 1, rtf_year, 0L)
  )

cat(sprintf("\nFinal panel: %d county-years\n", nrow(panel)))
cat(sprintf("  Counties: %d\n", n_distinct(panel$county_fips)))
cat(sprintf("  Years: %d (%d-%d)\n", n_distinct(panel$year),
            min(panel$year), max(panel$year)))
cat(sprintf("  RTF states: %d\n", sum(rtf_states$state_fips %in% unique(panel$state_fips))))
cat(sprintf("  High-CAFO counties in RTF states: %d\n",
            n_distinct(panel$county_fips[panel$rtf_state == 1 & panel$high_cafo == 1])))
cat(sprintf("  High-CAFO counties in control states: %d\n",
            n_distinct(panel$county_fips[panel$rtf_state == 0 & panel$high_cafo == 1])))

# ===================================================================
# Save analysis panel
# ===================================================================
saveRDS(panel, "../data/panel.rds")
cat("\nPanel saved to data/panel.rds\n")
