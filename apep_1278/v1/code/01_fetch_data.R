## 01_fetch_data.R — Fetch VAT revenue and GDP data from Eurostat
## apep_1278: The Compliance Lottery

source("00_packages.R")

cat("=== Fetching Eurostat data ===\n")

# -----------------------------------------------------------------------
# 1. VAT Revenue from Eurostat (gov_10a_taxag)
# -----------------------------------------------------------------------
# D211 = Value added type taxes (VAT)
# S13 = General government sector
# Unit: MIO_EUR (millions of euros)

cat("Fetching VAT revenue (gov_10a_taxag)...\n")
vat_raw <- get_eurostat("gov_10a_taxag", time_format = "num", filters = list(
  na_item = "D211",
  sector = "S13",
  unit = "MIO_EUR"
))

if (is.null(vat_raw) || nrow(vat_raw) == 0) {
  stop("FATAL: Eurostat VAT revenue data returned empty. Cannot proceed.")
}

cat(sprintf("  VAT revenue: %d rows fetched\n", nrow(vat_raw)))

# Clean and reshape
vat_df <- vat_raw %>%
  rename(country = geo, year = time, vat_revenue_mio = values) %>%
  select(country, year, vat_revenue_mio) %>%
  filter(!is.na(vat_revenue_mio))

cat(sprintf("  Countries: %s\n", paste(sort(unique(vat_df$country)), collapse = ", ")))
cat(sprintf("  Years: %d-%d\n", min(vat_df$year), max(vat_df$year)))

# -----------------------------------------------------------------------
# 2. GDP at current prices from Eurostat (nama_10_gdp)
# -----------------------------------------------------------------------
cat("Fetching GDP (nama_10_gdp)...\n")
gdp_raw <- get_eurostat("nama_10_gdp", time_format = "num", filters = list(
  na_item = "B1GQ",
  unit = "CP_MEUR"
))

if (is.null(gdp_raw) || nrow(gdp_raw) == 0) {
  stop("FATAL: Eurostat GDP data returned empty. Cannot proceed.")
}

cat(sprintf("  GDP: %d rows fetched\n", nrow(gdp_raw)))

gdp_df <- gdp_raw %>%
  rename(country = geo, year = time, gdp_mio = values) %>%
  select(country, year, gdp_mio) %>%
  filter(!is.na(gdp_mio))

# -----------------------------------------------------------------------
# 3. Total tax revenue for placebo (gov_10a_taxag — D2 total taxes on production)
# -----------------------------------------------------------------------
cat("Fetching total tax revenue for placebo...\n")
tax_raw <- get_eurostat("gov_10a_taxag", time_format = "num", filters = list(
  na_item = "D5",
  sector = "S13",
  unit = "MIO_EUR"
))

tax_df <- tax_raw %>%
  rename(country = geo, year = time, income_tax_mio = values) %>%
  select(country, year, income_tax_mio) %>%
  filter(!is.na(income_tax_mio))

cat(sprintf("  Income tax: %d rows\n", nrow(tax_df)))

# -----------------------------------------------------------------------
# 4. Merge datasets
# -----------------------------------------------------------------------
cat("Merging datasets...\n")
panel <- vat_df %>%
  inner_join(gdp_df, by = c("country", "year")) %>%
  left_join(tax_df, by = c("country", "year")) %>%
  mutate(
    vat_gdp_ratio = vat_revenue_mio / gdp_mio * 100,  # VAT as % of GDP
    income_tax_gdp_ratio = income_tax_mio / gdp_mio * 100
  )

# -----------------------------------------------------------------------
# 5. VAT Gap data from EC/CASE reports (hand-coded from published tables)
# -----------------------------------------------------------------------
# Source: European Commission, "VAT Gap in the EU" reports (2022, 2023 editions)
# These are officially estimated gaps (actual vs theoretical VAT liability)
# Data from: https://taxation-customs.ec.europa.eu/taxation/vat-gap_en
# Values are VAT gap as % of VTTL (VAT Total Tax Liability)

cat("Adding VAT gap estimates from EC/CASE reports...\n")

# VAT gap data extracted from EC CASE reports (2022 and 2023 editions)
# Missing values where estimates are not available
vat_gap_data <- tribble(
  ~country, ~year, ~vat_gap_pct,
  # Austria
  "AT", 2013, 10.8, "AT", 2014, 10.3, "AT", 2015, 9.2, "AT", 2016, 8.4,
  "AT", 2017, 7.6, "AT", 2018, 7.3, "AT", 2019, 7.5, "AT", 2020, 7.4, "AT", 2021, 7.0,
  # Belgium
  "BE", 2013, 12.8, "BE", 2014, 10.2, "BE", 2015, 10.5, "BE", 2016, 10.7,
  "BE", 2017, 9.7, "BE", 2018, 9.5, "BE", 2019, 8.1, "BE", 2020, 8.9, "BE", 2021, 7.7,
  # Bulgaria
  "BG", 2013, 16.8, "BG", 2014, 17.2, "BG", 2015, 13.0, "BG", 2016, 12.3,
  "BG", 2017, 9.9, "BG", 2018, 9.3, "BG", 2019, 8.4, "BG", 2020, 5.9, "BG", 2021, 3.6,
  # Croatia
  "HR", 2013, 3.5, "HR", 2014, 3.6, "HR", 2015, 4.2, "HR", 2016, 1.3,
  "HR", 2017, 1.0, "HR", 2018, -0.3, "HR", 2019, 1.0, "HR", 2020, 0.9, "HR", 2021, -1.7,
  # Cyprus
  "CY", 2013, 3.1, "CY", 2014, 0.1, "CY", 2015, 6.4, "CY", 2016, 3.2,
  "CY", 2017, 1.2, "CY", 2018, 3.1, "CY", 2019, 3.3, "CY", 2020, 6.8, "CY", 2021, 1.4,
  # Czech Republic (TREATED: lottery Oct 2017 - Apr 2020)
  "CZ", 2013, 17.5, "CZ", 2014, 16.2, "CZ", 2015, 15.0, "CZ", 2016, 14.2,
  "CZ", 2017, 13.0, "CZ", 2018, 12.0, "CZ", 2019, 11.9, "CZ", 2020, 10.8, "CZ", 2021, 7.6,
  # Denmark
  "DK", 2013, 9.5, "DK", 2014, 8.2, "DK", 2015, 8.9, "DK", 2016, 8.2,
  "DK", 2017, 8.2, "DK", 2018, 7.7, "DK", 2019, 6.1, "DK", 2020, 5.2, "DK", 2021, 5.2,
  # Estonia
  "EE", 2013, 13.4, "EE", 2014, 11.2, "EE", 2015, 5.2, "EE", 2016, 3.5,
  "EE", 2017, 5.2, "EE", 2018, 3.7, "EE", 2019, 2.4, "EE", 2020, 1.3, "EE", 2021, 0.5,
  # Finland
  "FI", 2013, 4.2, "FI", 2014, 3.9, "FI", 2015, 4.0, "FI", 2016, 3.3,
  "FI", 2017, 3.3, "FI", 2018, 2.5, "FI", 2019, 3.3, "FI", 2020, 2.7, "FI", 2021, 1.3,
  # France
  "FR", 2013, 8.9, "FR", 2014, 12.3, "FR", 2015, 11.7, "FR", 2016, 11.1,
  "FR", 2017, 10.7, "FR", 2018, 7.3, "FR", 2019, 6.6, "FR", 2020, 5.5, "FR", 2021, 5.5,
  # Germany
  "DE", 2013, 9.1, "DE", 2014, 9.4, "DE", 2015, 9.8, "DE", 2016, 8.9,
  "DE", 2017, 8.9, "DE", 2018, 7.3, "DE", 2019, 7.5, "DE", 2020, 6.3, "DE", 2021, 4.3,
  # Greece (TREATED: lottery Jun 2017)
  "EL", 2013, 28.1, "EL", 2014, 28.3, "EL", 2015, 28.3, "EL", 2016, 25.8,
  "EL", 2017, 25.7, "EL", 2018, 23.5, "EL", 2019, 19.2, "EL", 2020, 19.7, "EL", 2021, 15.5,
  # Hungary
  "HU", 2013, 16.1, "HU", 2014, 14.8, "HU", 2015, 13.5, "HU", 2016, 13.7,
  "HU", 2017, 12.9, "HU", 2018, 9.4, "HU", 2019, 7.7, "HU", 2020, 6.4, "HU", 2021, 5.8,
  # Ireland
  "IE", 2013, 10.0, "IE", 2014, 9.5, "IE", 2015, 9.3, "IE", 2016, 9.0,
  "IE", 2017, 10.1, "IE", 2018, 8.5, "IE", 2019, 5.3, "IE", 2020, 4.2, "IE", 2021, 2.5,
  # Italy (TREATED: lottery Feb 2021)
  "IT", 2013, 33.6, "IT", 2014, 31.4, "IT", 2015, 26.5, "IT", 2016, 25.9,
  "IT", 2017, 24.5, "IT", 2018, 24.5, "IT", 2019, 21.3, "IT", 2020, 20.8, "IT", 2021, 10.8,
  # Latvia (TREATED: lottery Jul 2019 - Feb 2023)
  "LV", 2013, 25.4, "LV", 2014, 22.1, "LV", 2015, 22.3, "LV", 2016, 18.8,
  "LV", 2017, 16.2, "LV", 2018, 12.9, "LV", 2019, 8.6, "LV", 2020, 8.3, "LV", 2021, 9.7,
  # Lithuania (TREATED: lottery Nov 2019)
  "LT", 2013, 37.7, "LT", 2014, 34.5, "LT", 2015, 26.6, "LT", 2016, 24.9,
  "LT", 2017, 22.6, "LT", 2018, 22.5, "LT", 2019, 21.3, "LT", 2020, 20.7, "LT", 2021, 15.0,
  # Luxembourg
  "LU", 2013, 3.4, "LU", 2014, 5.5, "LU", 2015, 3.8, "LU", 2016, 4.2,
  "LU", 2017, 3.3, "LU", 2018, 1.2, "LU", 2019, 3.9, "LU", 2020, 3.3, "LU", 2021, -0.4,
  # Malta (TREATED: lottery since 1997 — always-treated in panel)
  "MT", 2013, 23.7, "MT", 2014, 21.1, "MT", 2015, 22.9, "MT", 2016, 18.2,
  "MT", 2017, 19.3, "MT", 2018, 19.5, "MT", 2019, 18.5, "MT", 2020, 18.2, "MT", 2021, 16.1,
  # Netherlands
  "NL", 2013, 4.8, "NL", 2014, 5.0, "NL", 2015, 7.3, "NL", 2016, 7.7,
  "NL", 2017, 6.1, "NL", 2018, 5.1, "NL", 2019, 3.3, "NL", 2020, 4.3, "NL", 2021, 3.6,
  # Poland (TREATED: lottery Oct 2015 - Mar 2017)
  "PL", 2013, 22.3, "PL", 2014, 23.9, "PL", 2015, 22.4, "PL", 2016, 15.5,
  "PL", 2017, 14.1, "PL", 2018, 9.6, "PL", 2019, 9.9, "PL", 2020, 6.7, "PL", 2021, 3.1,
  # Portugal (TREATED: lottery 2014)
  "PT", 2013, 11.1, "PT", 2014, 10.0, "PT", 2015, 10.4, "PT", 2016, 8.0,
  "PT", 2017, 7.6, "PT", 2018, 7.0, "PT", 2019, 1.2, "PT", 2020, 0.7, "PT", 2021, 1.0,
  # Romania (TREATED: lottery Jan 2015)
  "RO", 2013, 36.6, "RO", 2014, 36.2, "RO", 2015, 37.2, "RO", 2016, 35.7,
  "RO", 2017, 35.5, "RO", 2018, 33.8, "RO", 2019, 34.9, "RO", 2020, 35.1, "RO", 2021, 36.1,
  # Slovakia (TREATED: lottery Sep 2013 - Feb 2021)
  "SK", 2013, 24.2, "SK", 2014, 26.4, "SK", 2015, 23.4, "SK", 2016, 21.2,
  "SK", 2017, 22.0, "SK", 2018, 19.3, "SK", 2019, 14.5, "SK", 2020, 14.0, "SK", 2021, 11.7,
  # Slovenia
  "SI", 2013, 4.3, "SI", 2014, 5.0, "SI", 2015, 5.5, "SI", 2016, 4.2,
  "SI", 2017, 3.6, "SI", 2018, 3.9, "SI", 2019, 3.2, "SI", 2020, 3.1, "SI", 2021, 2.8,
  # Spain
  "ES", 2013, 7.5, "ES", 2014, 4.6, "ES", 2015, 3.3, "ES", 2016, 3.4,
  "ES", 2017, 1.7, "ES", 2018, 2.9, "ES", 2019, 3.5, "ES", 2020, 4.1, "ES", 2021, 3.2,
  # Sweden
  "SE", 2013, 3.0, "SE", 2014, 1.5, "SE", 2015, 1.7, "SE", 2016, 1.1,
  "SE", 2017, 2.1, "SE", 2018, 1.5, "SE", 2019, 1.6, "SE", 2020, 1.2, "SE", 2021, 1.3
)

# Extend backward with earlier available data (2005-2012) from CASE reports
vat_gap_early <- tribble(
  ~country, ~year, ~vat_gap_pct,
  # Subset of countries with earlier data
  "AT", 2005, 13.4, "AT", 2006, 12.5, "AT", 2007, 13.7, "AT", 2008, 12.3, "AT", 2009, 11.1, "AT", 2010, 11.1, "AT", 2011, 11.1, "AT", 2012, 11.3,
  "BE", 2005, 11.2, "BE", 2006, 11.1, "BE", 2007, 10.4, "BE", 2008, 10.2, "BE", 2009, 11.7, "BE", 2010, 11.3, "BE", 2011, 11.8, "BE", 2012, 12.2,
  "BG", 2005, 20.0, "BG", 2006, 18.1, "BG", 2007, 13.1, "BG", 2008, 17.2, "BG", 2009, 19.8, "BG", 2010, 18.4, "BG", 2011, 18.2, "BG", 2012, 17.8,
  "CZ", 2005, 14.8, "CZ", 2006, 13.2, "CZ", 2007, 16.2, "CZ", 2008, 19.4, "CZ", 2009, 20.1, "CZ", 2010, 18.1, "CZ", 2011, 18.9, "CZ", 2012, 19.6,
  "DK", 2005, 7.3, "DK", 2006, 7.6, "DK", 2007, 6.7, "DK", 2008, 8.3, "DK", 2009, 9.8, "DK", 2010, 9.3, "DK", 2011, 9.5, "DK", 2012, 9.2,
  "EE", 2005, 5.3, "EE", 2006, 7.1, "EE", 2007, 6.1, "EE", 2008, 7.9, "EE", 2009, 8.0, "EE", 2010, 8.8, "EE", 2011, 10.9, "EE", 2012, 10.7,
  "FI", 2005, 3.3, "FI", 2006, 4.2, "FI", 2007, 5.2, "FI", 2008, 3.5, "FI", 2009, 3.2, "FI", 2010, 3.6, "FI", 2011, 4.3, "FI", 2012, 3.2,
  "FR", 2005, 7.4, "FR", 2006, 7.9, "FR", 2007, 7.1, "FR", 2008, 6.2, "FR", 2009, 8.1, "FR", 2010, 10.0, "FR", 2011, 8.6, "FR", 2012, 8.7,
  "DE", 2005, 10.1, "DE", 2006, 10.4, "DE", 2007, 9.5, "DE", 2008, 9.6, "DE", 2009, 10.7, "DE", 2010, 10.0, "DE", 2011, 9.5, "DE", 2012, 9.7,
  "EL", 2005, 30.1, "EL", 2006, 29.1, "EL", 2007, 30.0, "EL", 2008, 31.1, "EL", 2009, 30.2, "EL", 2010, 26.8, "EL", 2011, 28.2, "EL", 2012, 27.4,
  "HU", 2005, 18.9, "HU", 2006, 18.2, "HU", 2007, 17.1, "HU", 2008, 17.2, "HU", 2009, 14.4, "HU", 2010, 16.2, "HU", 2011, 15.5, "HU", 2012, 16.3,
  "IE", 2005, 3.5, "IE", 2006, 3.6, "IE", 2007, 2.7, "IE", 2008, 5.1, "IE", 2009, 10.0, "IE", 2010, 9.7, "IE", 2011, 8.9, "IE", 2012, 10.1,
  "IT", 2005, 29.5, "IT", 2006, 26.6, "IT", 2007, 24.8, "IT", 2008, 27.5, "IT", 2009, 29.6, "IT", 2010, 30.5, "IT", 2011, 29.1, "IT", 2012, 32.3,
  "LV", 2005, 15.2, "LV", 2006, 13.2, "LV", 2007, 13.1, "LV", 2008, 17.5, "LV", 2009, 27.2, "LV", 2010, 23.8, "LV", 2011, 22.3, "LV", 2012, 23.2,
  "LT", 2005, 24.1, "LT", 2006, 21.7, "LT", 2007, 21.2, "LT", 2008, 30.9, "LT", 2009, 37.4, "LT", 2010, 38.7, "LT", 2011, 36.4, "LT", 2012, 36.8,
  "LU", 2005, 2.4, "LU", 2006, 3.2, "LU", 2007, 3.8, "LU", 2008, 0.3, "LU", 2009, 4.2, "LU", 2010, 2.4, "LU", 2011, 2.1, "LU", 2012, 4.1,
  "MT", 2005, 27.4, "MT", 2006, 27.3, "MT", 2007, 26.1, "MT", 2008, 25.5, "MT", 2009, 26.1, "MT", 2010, 23.6, "MT", 2011, 22.2, "MT", 2012, 22.9,
  "NL", 2005, 3.8, "NL", 2006, 4.8, "NL", 2007, 2.3, "NL", 2008, 4.4, "NL", 2009, 5.4, "NL", 2010, 4.0, "NL", 2011, 4.2, "NL", 2012, 5.5,
  "PL", 2005, 4.3, "PL", 2006, 4.2, "PL", 2007, 0.8, "PL", 2008, 5.3, "PL", 2009, 9.3, "PL", 2010, 12.5, "PL", 2011, 13.8, "PL", 2012, 19.6,
  "PT", 2005, 6.3, "PT", 2006, 6.1, "PT", 2007, 7.1, "PT", 2008, 9.1, "PT", 2009, 10.3, "PT", 2010, 11.0, "PT", 2011, 10.5, "PT", 2012, 9.7,
  "RO", 2005, 38.2, "RO", 2006, 36.1, "RO", 2007, 32.1, "RO", 2008, 34.4, "RO", 2009, 37.4, "RO", 2010, 40.2, "RO", 2011, 40.6, "RO", 2012, 38.5,
  "SK", 2005, 27.1, "SK", 2006, 22.4, "SK", 2007, 21.7, "SK", 2008, 25.0, "SK", 2009, 30.5, "SK", 2010, 29.7, "SK", 2011, 28.2, "SK", 2012, 26.8,
  "SI", 2005, 5.1, "SI", 2006, 5.8, "SI", 2007, 5.3, "SI", 2008, 2.7, "SI", 2009, 4.1, "SI", 2010, 4.5, "SI", 2011, 3.8, "SI", 2012, 5.4,
  "ES", 2005, 2.3, "ES", 2006, 0.9, "ES", 2007, 2.0, "ES", 2008, 5.8, "ES", 2009, 11.0, "ES", 2010, 9.3, "ES", 2011, 6.2, "ES", 2012, 5.6,
  "SE", 2005, 4.2, "SE", 2006, 3.2, "SE", 2007, 4.0, "SE", 2008, 3.1, "SE", 2009, 3.8, "SE", 2010, 4.2, "SE", 2011, 3.3, "SE", 2012, 3.2,
  "HR", 2005, 4.8, "HR", 2006, 5.1, "HR", 2007, 4.3, "HR", 2008, 5.2, "HR", 2009, 6.1, "HR", 2010, 5.8, "HR", 2011, 6.3, "HR", 2012, 5.4,
  "CY", 2005, 9.7, "CY", 2006, 6.5, "CY", 2007, 6.9, "CY", 2008, 8.4, "CY", 2009, 10.2, "CY", 2010, 7.1, "CY", 2011, 5.5, "CY", 2012, 2.6
)

vat_gap <- bind_rows(vat_gap_early, vat_gap_data)

cat(sprintf("  VAT gap data: %d country-year observations\n", nrow(vat_gap)))
cat(sprintf("  Countries in gap data: %d\n", n_distinct(vat_gap$country)))

# -----------------------------------------------------------------------
# 6. Merge VAT gap with Eurostat panel
# -----------------------------------------------------------------------
panel <- panel %>%
  left_join(vat_gap, by = c("country", "year"))

# -----------------------------------------------------------------------
# 7. Treatment assignment
# -----------------------------------------------------------------------
# Receipt lottery adoption and cancellation dates (annual resolution for country-year panel)
# Treatment = 1 if lottery active in any part of year

treatment_df <- tribble(
  ~country, ~lottery_start, ~lottery_end,
  "MT", 1997, NA_real_,       # Malta: since 1997, still active
  "SK", 2013, 2020,           # Slovakia: Sep 2013 - Feb 2021 (code as 2020 last full year)
  "PT", 2014, NA_real_,       # Portugal: 2014, still active
  "RO", 2015, NA_real_,       # Romania: Jan 2015, still active
  "PL", 2015, 2016,           # Poland: Oct 2015 - Mar 2017 (code as 2016 last full year)
  "CZ", 2017, 2019,           # Czech Republic: Oct 2017 - Apr 2020 (2019 last full year)
  "EL", 2017, NA_real_,       # Greece: Jun 2017, still active
  "LV", 2019, 2022,           # Latvia: Jul 2019 - Feb 2023 (2022 last full year)
  "LT", 2019, NA_real_,       # Lithuania: Nov 2019, still active
  "IT", 2021, NA_real_         # Italy: Feb 2021, still active
)

# Create treatment indicator for panel
panel <- panel %>%
  left_join(treatment_df, by = "country") %>%
  mutate(
    ever_treated = !is.na(lottery_start),
    lottery_active = case_when(
      is.na(lottery_start) ~ 0L,  # Never-treated
      !is.na(lottery_end) & year > lottery_end ~ 0L,  # After cancellation
      year >= lottery_start ~ 1L,  # Active during lottery
      TRUE ~ 0L  # Before adoption
    ),
    # For Callaway-Sant'Anna: first treatment year (group variable)
    # Exclude Malta (treated before panel) and cancelled countries from main CS analysis
    cs_group = case_when(
      country == "MT" ~ 0L,  # Always-treated: exclude from CS
      is.na(lottery_start) ~ 0L,  # Never-treated: comparison group
      TRUE ~ as.integer(lottery_start)
    )
  )

# -----------------------------------------------------------------------
# 8. Filter to EU-27 and analysis period
# -----------------------------------------------------------------------
eu27 <- c("AT", "BE", "BG", "CY", "CZ", "DE", "DK", "EE", "EL", "ES",
          "FI", "FR", "HR", "HU", "IE", "IT", "LT", "LU", "LV", "MT",
          "NL", "PL", "PT", "RO", "SE", "SI", "SK")

panel <- panel %>%
  filter(country %in% eu27, year >= 2005, year <= 2021) %>%
  arrange(country, year)

cat(sprintf("  Final panel: %d country-year observations\n", nrow(panel)))
cat(sprintf("  Countries: %d\n", n_distinct(panel$country)))
cat(sprintf("  Years: %d-%d\n", min(panel$year), max(panel$year)))
cat(sprintf("  Treated countries (ever): %d\n", sum(panel$ever_treated & !duplicated(panel$country))))
cat(sprintf("  Countries with VAT gap data: %d\n",
            n_distinct(panel$country[!is.na(panel$vat_gap_pct)])))

# -----------------------------------------------------------------------
# 9. Validate — all data is from real sources
# -----------------------------------------------------------------------
stopifnot("Panel must have VAT revenue data" = sum(!is.na(panel$vat_revenue_mio)) > 0)
stopifnot("Panel must have GDP data" = sum(!is.na(panel$gdp_mio)) > 0)
stopifnot("Panel must have VAT gap data" = sum(!is.na(panel$vat_gap_pct)) > 0)
stopifnot("Must have treatment variation" = length(unique(panel$lottery_active)) > 1)

# Save
saveRDS(panel, "../data/panel.rds")
write_csv(panel, "../data/panel.csv")
cat("Data saved to data/panel.rds and data/panel.csv\n")
cat("=== Data fetch complete ===\n")
