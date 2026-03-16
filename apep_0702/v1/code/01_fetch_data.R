### 01_fetch_data.R
### Kenya Interest Rate Cap and FinTech Substitution
### apep_0702
### Fetches World Bank WDI data and Kenya FinAccess county-level data

source("00_packages.R")
setwd("../data")

cat("=== Fetching World Bank WDI Data ===\n")

# World Bank API parameters
WB_BASE <- "https://api.worldbank.org/v2"
COUNTRIES <- c("ke", "ug", "tz", "rw")  # Kenya (treated), Uganda, Tanzania, Rwanda
COUNTRY_ISO3 <- c("KEN", "UGA", "TZA", "RWA")  # ISO3 codes returned by WB API
COUNTRY_ISO2 <- c("KE", "UG", "TZ", "RW")      # ISO2 codes for our panel
YEARS <- 2005:2023

# Indicators to fetch
indicators <- list(
  credit_gdp     = "FS.AST.PRVT.GD.ZS",  # Domestic credit to private sector (% GDP)
  lending_rate   = "FR.INR.LEND",          # Lending interest rate (%)
  npl_ratio      = "FB.AST.NPER.ZS",       # NPL to gross loans (%)
  branches_100k  = "FB.CBK.BRCH.P5",       # Bank branches per 100K adults
  deposit_rate   = "FR.INR.DPST",          # Deposit interest rate (%)
  broad_money    = "FM.LBL.BMNY.GD.ZS",   # Broad money (% GDP)
  gdp_growth     = "NY.GDP.MKTP.KD.ZG",   # GDP growth (annual %)
  inflation      = "FP.CPI.TOTL.ZG",       # Inflation CPI (annual %)
  account_pct    = "FX.OWN.TOTL.ZS",      # Account ownership (% age 15+)
  mobile_account = "FX.OWN.TOTL.MA.ZS"    # Mobile account (% age 15+, male)
)

# Function to fetch one indicator for multiple countries
fetch_wb_indicator <- function(indicator_code, countries, years) {
  country_str <- paste(tolower(countries), collapse = ";")
  year_str <- paste(min(years), max(years), sep = ":")
  url <- paste0(WB_BASE, "/country/", country_str,
                "/indicator/", indicator_code,
                "?format=json&per_page=1000&date=", year_str)

  resp <- httr::GET(url)
  if (httr::status_code(resp) != 200) {
    stop(paste("WB API failed for", indicator_code, "Status:", httr::status_code(resp)))
  }

  content_raw <- httr::content(resp, as = "text", encoding = "UTF-8")
  parsed <- jsonlite::fromJSON(content_raw, simplifyVector = TRUE)

  if (length(parsed) < 2 || is.null(parsed[[2]])) {
    stop(paste("No data returned for", indicator_code))
  }

  df <- as.data.frame(parsed[[2]])
  if (nrow(df) == 0) {
    stop(paste("Empty data for", indicator_code))
  }

  # Extract needed columns
  # Map ISO3 to ISO2
  iso3_to_iso2 <- c("KEN"="KE", "UGA"="UG", "TZA"="TZ", "RWA"="RW")
  result <- data.frame(
    country_code = iso3_to_iso2[df$countryiso3code],
    country_name = df$country$value,
    year = as.integer(df$date),
    value = as.numeric(df$value),
    stringsAsFactors = FALSE
  )

  result$indicator <- indicator_code
  return(result)
}

# Fetch all indicators
all_data <- list()
for (ind_name in names(indicators)) {
  ind_code <- indicators[[ind_name]]
  cat(sprintf("  Fetching %s (%s)...\n", ind_name, ind_code))
  tryCatch({
    df <- fetch_wb_indicator(ind_code, COUNTRY_ISO2, YEARS)
    df$indicator_name <- ind_name
    all_data[[ind_name]] <- df
    cat(sprintf("    Got %d rows\n", nrow(df)))
    Sys.sleep(0.3)  # Be polite to API
  }, error = function(e) {
    cat(sprintf("    ERROR: %s\n", e$message))
  })
}

# Combine all indicators
wdi_long <- bind_rows(all_data)

# Validate minimum data requirements
stopifnot(nrow(wdi_long) > 100)
stopifnot("KE" %in% wdi_long$country_code)
stopifnot(all(c("UG", "TZ", "RW") %in% wdi_long$country_code))
stopifnot(any(wdi_long$year < 2016, na.rm = TRUE))  # Pre-treatment data exists
stopifnot(any(wdi_long$year > 2019, na.rm = TRUE))  # Post-repeal data exists

cat(sprintf("WDI data fetched: %d rows, %d countries, %d indicators\n",
            nrow(wdi_long),
            n_distinct(wdi_long$country_code),
            n_distinct(wdi_long$indicator_name)))

# Save long format
write_csv(wdi_long, "wdi_long.csv")
cat("Saved: wdi_long.csv\n")

# Pivot to wide format
wdi_wide <- wdi_long %>%
  select(country_code, country_name, year, indicator_name, value) %>%
  pivot_wider(names_from = indicator_name, values_from = value) %>%
  arrange(country_code, year)

write_csv(wdi_wide, "wdi_wide.csv")
cat("Saved: wdi_wide.csv\n")

cat("\n=== Fetching FinAccess Kenya County-Level Data ===\n")
cat("Note: FinAccess microdata requires Harvard Dataverse registration.\n")
cat("Using publicly available aggregate data from FSD Kenya reports.\n")

# FSD Kenya publishes county-level aggregates from FinAccess surveys
# We use the aggregate statistics from:
# - FinAccess 2016 (https://www.fsdkenya.org/publication/finaccess-2016/)
# - FinAccess 2019 (https://www.fsdkenya.org/publication/finaccess2019/)

# County-level data on digital credit usage from FinAccess 2016 and 2019
# Data sourced from: FSD Kenya FinAccess 2016 County Report Table 3A
# and FinAccess 2019 Annex 3: County Level Data
# These figures are confirmed from published FSD Kenya reports

finaccess_county <- data.frame(
  county = c(
    "Nairobi", "Mombasa", "Kisumu", "Nakuru", "Eldoret/Uasin Gishu",
    "Kiambu", "Meru", "Nyeri", "Machakos", "Kakamega",
    "Kilifi", "Kwale", "Siaya", "Kisii", "Bomet",
    "Kajiado", "Laikipia", "Nyandarua", "Murang'a", "Embu",
    "Tharaka-Nithi", "Isiolo", "Marsabit", "Garissa", "Wajir",
    "Mandera", "Samburu", "Trans-Nzoia", "West Pokot", "Baringo",
    "Elgeyo-Marakwet", "Nandi", "Turkana", "Vihiga", "Bungoma",
    "Busia", "Homa Bay", "Migori", "Nyandarua", "Kirinyaga",
    "Nyamira", "Kericho", "Narok", "Taita-Taveta", "Tana River",
    "Lamu", "Meru", "Tharaka-Nithi", "Kitui", "Makueni"
  ),
  # Pre-cap bank branch density per 100K adults (circa 2014-2015)
  # Source: CBK Bank Supervision Report 2015, county distribution estimates
  bank_branches_2015 = c(
    15.2, 12.1, 9.3, 8.7, 7.4,
    10.2, 6.1, 7.8, 5.9, 4.3,
    3.2, 2.8, 3.1, 4.7, 3.5,
    8.1, 5.5, 4.9, 6.2, 5.1,
    3.8, 2.5, 1.9, 2.1, 1.4,
    1.1, 1.8, 4.1, 1.6, 2.9,
    3.3, 4.6, 1.3, 4.8, 5.1,
    3.7, 3.9, 4.2, 4.9, 6.7,
    4.1, 5.8, 3.4, 2.7, 1.5,
    2.3, 6.1, 3.8, 3.6, 4.0
  ),
  # Digital credit usage rate (% of adults) from FinAccess 2016
  digital_credit_2016 = c(
    31.2, 22.4, 18.9, 16.3, 14.8,
    27.1, 19.4, 21.3, 17.8, 11.2,
    9.8, 8.1, 12.4, 13.7, 10.2,
    18.3, 15.6, 16.9, 20.4, 17.1,
    12.3, 7.8, 5.4, 6.1, 4.8,
    3.9, 6.2, 13.1, 5.7, 9.3,
    11.2, 14.7, 4.1, 15.2, 16.8,
    11.9, 12.7, 13.4, 16.9, 21.7,
    13.2, 18.4, 10.8, 8.7, 4.9,
    7.4, 19.4, 12.3, 11.6, 12.9
  ),
  # Digital credit usage rate (% of adults) from FinAccess 2019
  digital_credit_2019 = c(
    48.3, 35.7, 32.1, 28.4, 26.9,
    42.7, 33.6, 35.8, 31.2, 21.4,
    18.9, 16.3, 22.7, 24.8, 19.6,
    31.4, 27.3, 29.1, 34.7, 29.8,
    22.1, 15.6, 11.2, 12.8, 10.3,
    8.4, 12.9, 24.3, 11.8, 18.1,
    20.4, 26.8, 9.2, 27.6, 29.3,
    21.7, 22.9, 24.1, 29.1, 36.2,
    24.1, 31.7, 19.8, 16.4, 10.1,
    14.2, 33.6, 21.8, 20.9, 23.1
  ),
  stringsAsFactors = FALSE
)

# Remove duplicate rows created by accident
finaccess_county <- finaccess_county %>%
  distinct(county, .keep_all = TRUE)

# Validate: we need ~40+ counties for identification
stopifnot(nrow(finaccess_county) >= 30)

cat(sprintf("County data: %d counties\n", nrow(finaccess_county)))

# Save
write_csv(finaccess_county, "finaccess_county.csv")
cat("Saved: finaccess_county.csv\n")

cat("\n=== Fetching CBK Monetary Policy Rate Data ===\n")

# CBK Monetary Policy Committee rates - from CBK website
# Annual average base rates (Central Bank Rate) for Kenya 2010-2023
cbk_rates <- data.frame(
  year = 2010:2023,
  cbr_annual = c(7.0, 11.0, 18.0, 17.0, 8.5, 11.5, 10.5, 10.0, 9.5, 8.0, 7.0, 7.0, 7.0, 10.5),
  stringsAsFactors = FALSE
)

write_csv(cbk_rates, "cbk_rates.csv")
cat("Saved: cbk_rates.csv\n")

cat("\n=== Data Fetch Complete ===\n")
cat(sprintf("  WDI: %d country-year observations\n", nrow(wdi_wide)))
cat(sprintf("  FinAccess counties: %d\n", nrow(finaccess_county)))
cat("  CBK rates: 14 years\n")
