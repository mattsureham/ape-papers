## 01_fetch_data.R — Fetch World Bank WDI data for SCM analysis
## apep_1208: Ghana DDEP and Private Sector Credit

source("00_packages.R")

## ---- Configuration ----
# SSA countries: Ghana (treated) + 15 donor pool candidates
countries <- c(
  "GHA",  # Ghana (treated)
  "NGA", "KEN", "ZAF", "CIV", "SEN",  # Donors

  "TZA", "UGA", "RWA", "BWA", "MUS",
  "NAM", "CMR", "ETH", "MOZ", "MDG"
)

# WDI indicators
indicators <- c(
  "FD.AST.PRVT.GD.ZS",   # Domestic credit to private sector (% GDP)
  "FB.AST.NPER.ZS",       # Bank non-performing loans (% total)
  "NY.GDP.MKTP.KD.ZG",    # GDP growth (annual %)
  "FP.CPI.TOTL.ZG",       # Inflation, consumer prices (annual %)
  "NE.TRD.GNFS.ZS",       # Trade (% GDP)
  "GC.DOD.TOTL.GD.ZS",    # Central government debt (% GDP)
  "NY.GDP.PCAP.KD",        # GDP per capita (constant 2015 US$)
  "FM.LBL.BMNY.GD.ZS"     # Broad money (% GDP)
)

indicator_labels <- c(
  "credit_gdp", "npl_ratio", "gdp_growth", "inflation",
  "trade_gdp", "govt_debt_gdp", "gdp_pc", "broad_money_gdp"
)

year_range <- 2005:2024

## ---- Fetch from WDI API ----
fetch_wdi <- function(indicator, countries, years) {
  country_str <- paste(countries, collapse = ";")
  url <- sprintf(
    "https://api.worldbank.org/v2/country/%s/indicator/%s?date=%d:%d&format=json&per_page=5000",
    country_str, indicator, min(years), max(years)
  )

  resp <- httr::GET(url, httr::timeout(60))
  if (httr::status_code(resp) != 200) {
    stop(sprintf("WDI API returned status %d for indicator %s",
                 httr::status_code(resp), indicator))
  }

  content <- httr::content(resp, as = "text", encoding = "UTF-8")
  parsed <- jsonlite::fromJSON(content, simplifyVector = FALSE)

  # WDI returns a list: first element is metadata, second is data

  if (length(parsed) < 2 || is.null(parsed[[2]])) {
    stop(sprintf("No data returned for indicator %s", indicator))
  }

  records <- parsed[[2]]

  df <- tibble(
    iso3c = sapply(records, function(x) x$countryiso3code),
    country = sapply(records, function(x) x$country$value),
    year = as.integer(sapply(records, function(x) x$date)),
    value = sapply(records, function(x) ifelse(is.null(x$value), NA_real_, as.numeric(x$value)))
  )

  df
}

cat("Fetching WDI indicators...\n")

all_data <- list()
for (i in seq_along(indicators)) {
  cat(sprintf("  Fetching %s (%s)...\n", indicator_labels[i], indicators[i]))
  df <- fetch_wdi(indicators[i], countries, year_range)
  df$variable <- indicator_labels[i]
  all_data[[i]] <- df
  Sys.sleep(0.5)  # Rate limiting
}

wdi_long <- bind_rows(all_data)
cat(sprintf("Fetched %d rows across %d indicators.\n", nrow(wdi_long), length(indicators)))

## ---- Validate data ----
# Check Ghana credit/GDP has the expected collapse
ghana_credit <- wdi_long %>%
  filter(iso3c == "GHA", variable == "credit_gdp") %>%
  arrange(year)

cat("\nGhana credit/GDP time series:\n")
print(ghana_credit %>% select(year, value), n = 20)

# Verify the collapse exists
credit_2022 <- ghana_credit %>% filter(year == 2022) %>% pull(value)
credit_2023 <- ghana_credit %>% filter(year == 2023) %>% pull(value)

if (length(credit_2022) == 0 || is.na(credit_2022)) {
  stop("FATAL: Ghana 2022 credit/GDP data missing. Cannot proceed.")
}
if (length(credit_2023) == 0 || is.na(credit_2023)) {
  stop("FATAL: Ghana 2023 credit/GDP data missing. Cannot proceed.")
}

pct_change <- (credit_2023 - credit_2022) / credit_2022 * 100
cat(sprintf("\nGhana credit/GDP: %.2f%% (2022) -> %.2f%% (2023), change: %.1f%%\n",
            credit_2022, credit_2023, pct_change))

if (pct_change > -10) {
  warning("Credit decline smaller than expected. Check data quality.")
}

## ---- Reshape to wide panel ----
panel_wide <- wdi_long %>%
  select(iso3c, country, year, variable, value) %>%
  pivot_wider(names_from = variable, values_from = value) %>%
  arrange(iso3c, year)

# Check donor pool coverage
coverage <- panel_wide %>%
  filter(year >= 2010, year <= 2022) %>%
  group_by(iso3c) %>%
  summarise(
    credit_n = sum(!is.na(credit_gdp)),
    gdp_growth_n = sum(!is.na(gdp_growth)),
    .groups = "drop"
  )

cat("\nDonor pool data coverage (2010-2022):\n")
print(coverage, n = 20)

# Drop countries with < 10 years of credit data
good_donors <- coverage %>%
  filter(credit_n >= 10) %>%
  pull(iso3c)

panel_wide <- panel_wide %>%
  filter(iso3c %in% good_donors)

cat(sprintf("\nRetaining %d countries with sufficient data.\n", n_distinct(panel_wide$iso3c)))

## ---- Save ----
saveRDS(panel_wide, "../data/wdi_panel.rds")
saveRDS(wdi_long, "../data/wdi_long.rds")

cat("\nData saved to data/wdi_panel.rds and data/wdi_long.rds\n")
cat("DONE: 01_fetch_data.R\n")
