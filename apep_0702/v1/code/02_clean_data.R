### 02_clean_data.R
### Kenya Interest Rate Cap and FinTech Substitution
### apep_0702

source("00_packages.R")
setwd("../data")

cat("=== Cleaning and Constructing Analysis Dataset ===\n")

# Load WDI wide data
wdi_wide <- read_csv("wdi_wide.csv", show_col_types = FALSE)
cbk_rates <- read_csv("cbk_rates.csv", show_col_types = FALSE)
finaccess_county <- read_csv("finaccess_county.csv", show_col_types = FALSE)

cat(sprintf("WDI loaded: %d rows\n", nrow(wdi_wide)))

# ===================================================
# Panel 1: Country-Year Panel (DiD main analysis)
# ===================================================

# Focus on 2010-2023 and the 4 countries
panel_country <- wdi_wide %>%
  filter(country_code %in% c("KE", "UG", "TZ", "RW"),
         year >= 2010, year <= 2023) %>%
  arrange(country_code, year)

# Add treatment indicators
panel_country <- panel_country %>%
  mutate(
    # Kenya is the treated country
    kenya = as.integer(country_code == "KE"),

    # Cap period: law effective Sept 2016, so 2017+ is first full year
    # We treat 2016 as cap introduction year (partial), 2017-2019 as full cap
    cap_period = as.integer(year >= 2016 & year <= 2019),
    cap_full    = as.integer(year >= 2017 & year <= 2019),

    # Post-repeal period: Nov 2019 repeal, 2020+ is post-repeal
    post_repeal = as.integer(year >= 2020),

    # Interaction terms (DiD)
    treat_cap     = kenya * cap_period,
    treat_cap_full = kenya * cap_full,
    treat_repeal  = kenya * post_repeal,

    # Event-time: year relative to 2016 cap introduction
    event_year_cap    = year - 2016,   # 0 = 2016
    event_year_repeal = year - 2019,   # 0 = 2019

    # Country FE
    country_id = as.integer(as.factor(country_code))
  )

# Add CBK rates for Kenya
panel_country <- panel_country %>%
  left_join(cbk_rates, by = "year") %>%
  mutate(
    # Statutory cap = CBR + 4%
    cap_rate = ifelse(kenya == 1 & cap_period == 1, cbr_annual + 4, NA_real_)
  )

# Check data availability for key variables
cat("\nData availability (% non-missing by indicator):\n")
key_vars <- c("credit_gdp", "lending_rate", "npl_ratio", "branches_100k", "deposit_rate")
for (v in key_vars) {
  if (v %in% names(panel_country)) {
    pct <- mean(!is.na(panel_country[[v]])) * 100
    cat(sprintf("  %s: %.1f%%\n", v, pct))
  }
}

cat(sprintf("\nCountry panel: %d rows, %d countries, %d years\n",
            nrow(panel_country),
            n_distinct(panel_country$country_code),
            n_distinct(panel_country$year)))

# ===================================================
# Panel 2: Event Study Data (Kenya only, longer window)
# ===================================================

kenya_ts <- panel_country %>%
  filter(country_code == "KE") %>%
  mutate(
    # Event time for symmetric event study
    # Treat 2015 as -1 base year before cap
    event_cap_bin = case_when(
      event_year_cap <= -5  ~ -5,   # Bin pre-periods
      event_year_cap >= 4   ~ 4,    # Bin post-periods
      TRUE ~ event_year_cap
    )
  )

# ===================================================
# Panel 3: County-Level FinAccess (cross-sectional DiD)
# ===================================================

# Create long county panel from FinAccess cross-sections
county_long <- finaccess_county %>%
  pivot_longer(cols = c(digital_credit_2016, digital_credit_2019),
               names_to = "survey_year",
               values_to = "digital_credit_pct") %>%
  mutate(
    year = as.integer(str_extract(survey_year, "\\d{4}")),
    post_cap = as.integer(year >= 2019),  # 2019 survey is during cap period

    # Treatment intensity: pre-cap bank branch density
    bank_pen_std = scale(bank_branches_2015)[,1],

    # High bank penetration counties (above median) = more exposed
    high_bank = as.integer(bank_branches_2015 >= median(bank_branches_2015)),

    # Interaction
    bank_x_cap = bank_pen_std * post_cap
  )

# ===================================================
# Validate minimum sample requirements
# ===================================================

# Country panel
n_treated <- sum(panel_country$kenya == 1, na.rm = TRUE)
n_control <- sum(panel_country$kenya == 0, na.rm = TRUE)
n_pre_years <- length(unique(panel_country$year[panel_country$year < 2016]))

cat(sprintf("\nSample validation:\n"))
cat(sprintf("  Country panel: %d obs, %d Kenya-years, %d control country-years\n",
            nrow(panel_country), n_treated, n_control))
cat(sprintf("  Pre-treatment years: %d\n", n_pre_years))
cat(sprintf("  Counties: %d\n", nrow(finaccess_county)))

stopifnot(n_pre_years >= 5)
stopifnot(nrow(finaccess_county) >= 30)

# ===================================================
# Save cleaned datasets
# ===================================================

write_csv(panel_country, "panel_country.csv")
write_csv(kenya_ts, "kenya_ts.csv")
write_csv(county_long, "county_long.csv")
write_csv(finaccess_county, "finaccess_county_clean.csv")

cat("\nSaved: panel_country.csv, kenya_ts.csv, county_long.csv\n")
cat("=== Cleaning Complete ===\n")
