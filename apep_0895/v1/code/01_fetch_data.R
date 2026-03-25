# 01_fetch_data.R — Fetch Eurostat crime data + CELLAR SPARQL transposition dates
# apep_0895: Does AML Regulation Actually Detect Money Laundering?

source("00_packages.R")
library(eurlex)

# Helper: extract year from whichever time column Eurostat returns
extract_year <- function(dt) {
  time_col <- intersect(names(dt), c("TIME_PERIOD", "time", "time_period"))
  if (length(time_col) == 0) stop("No time column found in: ", paste(names(dt), collapse=", "))
  tc <- time_col[1]
  if (inherits(dt[[tc]], "Date")) {
    dt[, year := as.integer(format(.SD[[1]], "%Y")), .SDcols = tc]
  } else {
    dt[, year := as.integer(substr(as.character(.SD[[1]]), 1, 4)), .SDcols = tc]
  }
  dt
}

# ===========================================================================
# EU-27 country mapping
# ===========================================================================
eu27 <- data.table(
  iso2 = c("AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR",
           "DE","EL","HU","IE","IT","LV","LT","LU","MT","NL",
           "PL","PT","RO","SK","SI","ES","SE"),
  iso3 = c("AUT","BEL","BGR","HRV","CYP","CZE","DNK","EST","FIN","FRA",
           "DEU","GRC","HUN","IRL","ITA","LVA","LTU","LUX","MLT","NLD",
           "POL","PRT","ROU","SVK","SVN","ESP","SWE"),
  name = c("Austria","Belgium","Bulgaria","Croatia","Cyprus","Czechia",
           "Denmark","Estonia","Finland","France","Germany","Greece",
           "Hungary","Ireland","Italy","Latvia","Lithuania","Luxembourg",
           "Malta","Netherlands","Poland","Portugal","Romania","Slovakia",
           "Slovenia","Spain","Sweden")
)

# ===========================================================================
# 1. 5AMLD transposition dates
# ===========================================================================
message("=== Loading 5AMLD transposition dates ===")

# Transposition dates from CELLAR SPARQL (confirmed 2026-03-25, 521 NIMs for 32018L0843).
# Earliest notification date per country, filtered to post-2018 (5AMLD era).
# Source: https://publications.europa.eu/webapi/rdf/sparql
# 4 countries (CZ, HU, SK, SI) had no post-2018 NIMs — treated as never-transposed.
transposition <- data.table(
  iso2 = c("EL","BE","LU","LV","IE","HR","FI","AT","IT","BG","SE",
           "LT","DK","FR","DE","EE","PL","MT","NL","ES","RO","PT","CY"),
  transposition_date = as.Date(c(
    "2018-08-02","2018-08-20","2019-01-16","2019-03-20","2019-03-27",
    "2019-04-25","2019-06-18","2019-07-24","2019-10-31","2019-12-17",
    "2019-12-19","2020-01-09","2020-01-10","2020-01-14","2020-01-17",
    "2020-01-23","2020-01-31","2020-02-07","2020-05-25","2020-06-25",
    "2020-07-20","2020-08-31","2021-02-24")),
  n_measures = c(2L,5L,8L,9L,24L,66L,7L,33L,3L,26L,20L,
                 28L,3L,31L,1L,5L,12L,15L,10L,12L,26L,2L,12L)
)

# Merge with EU27 mapping
transposition <- merge(transposition, eu27, by = "iso2", all.y = TRUE)

message("\n=== Transposition dates ===")
print(transposition[order(transposition_date), .(name, iso2, transposition_date, n_measures)])

# ===========================================================================
# 2. Eurostat: Crime statistics (money laundering offences)
# ===========================================================================
message("\n=== Fetching crime data from Eurostat ===")

# Primary outcome: money laundering (ICCS 07041)
crime_raw <- get_eurostat("crim_off_cat", cache_dir = "data/")
crime_dt <- as.data.table(crime_raw)

crime_dt <- extract_year(crime_dt)

# Filter to country level (2-letter geo codes) and relevant ICCS codes
crime_dt <- crime_dt[nchar(geo) == 2]

# Filter to NR (number) unit to avoid duplicates from rate (P_HTHAB) rows
crime_dt <- crime_dt[unit == "NR"]

# Money laundering
ml_dt <- crime_dt[iccs == "ICCS07041", .(geo, year, ml_offences = values)]
message("Money laundering data: ", nrow(ml_dt), " observations")
message("Countries: ", paste(sort(unique(ml_dt$geo)), collapse = ", "))
message("Years: ", paste(range(ml_dt$year), collapse = "-"))

# Placebo outcomes: property crimes and assault
property_dt <- crime_dt[iccs == "ICCS0501", .(geo, year, property_offences = values)]
assault_dt <- crime_dt[iccs == "ICCS0201", .(geo, year, assault_offences = values)]

# Also get total recorded crimes for normalization
total_dt <- crime_dt[iccs == "ICCS0101", .(geo, year, total_offences = values)]

# ===========================================================================
# 3. Eurostat: House price index (secondary outcome)
# ===========================================================================
message("\n=== Fetching house price data ===")
hpi_raw <- get_eurostat("prc_hpi_a", cache_dir = "data/")
hpi_dt <- as.data.table(hpi_raw)
hpi_dt <- extract_year(hpi_dt)
message("HPI columns: ", paste(names(hpi_dt), collapse = ", "))
message("HPI rows before filter: ", nrow(hpi_dt))
# Filter to country level — check column names for purchase/unit
hpi_dt <- hpi_dt[nchar(geo) == 2]
if ("purchase" %in% names(hpi_dt)) hpi_dt <- hpi_dt[purchase == "TOTAL"]
if ("unit" %in% names(hpi_dt)) hpi_dt <- hpi_dt[unit == "I15_A_AVG"]
hpi_dt <- hpi_dt[, .(geo, year, hpi = values)]
message("House price index: ", nrow(hpi_dt), " observations")

# ===========================================================================
# 4. Eurostat: Financial sector employment (secondary outcome)
# ===========================================================================
message("\n=== Fetching financial sector employment ===")
emp_raw <- get_eurostat("lfst_r_lfe2en2",
                        filters = list(nace_r2 = "K", sex = "T", age = "Y15-74"),
                        cache_dir = "data/")
emp_dt <- as.data.table(emp_raw)
emp_dt <- extract_year(emp_dt)
# Country level (NUTS0 = 2-char geo)
emp_dt <- emp_dt[nchar(geo) == 2, .(geo, year, fin_employment = values)]
message("Financial employment: ", nrow(emp_dt), " observations")

# ===========================================================================
# 5. Eurostat: GDP for normalization
# ===========================================================================
message("\n=== Fetching GDP data ===")
gdp_raw <- get_eurostat("nama_10_gdp",
                        filters = list(unit = "CP_MEUR", na_item = "B1GQ"),
                        cache_dir = "data/")
gdp_dt <- as.data.table(gdp_raw)
gdp_dt <- extract_year(gdp_dt)
gdp_dt <- gdp_dt[nchar(geo) == 2, .(geo, year, gdp_meur = values)]

# ===========================================================================
# 6. Eurostat: Population for per-capita rates
# ===========================================================================
message("\n=== Fetching population data ===")
pop_raw <- get_eurostat("demo_pjan",
                        filters = list(sex = "T", age = "TOTAL"),
                        cache_dir = "data/")
pop_dt <- as.data.table(pop_raw)
pop_dt <- extract_year(pop_dt)
pop_dt <- pop_dt[nchar(geo) == 2, .(geo, year, population = values)]

# ===========================================================================
# Save raw data
# ===========================================================================
dir.create("data", showWarnings = FALSE, recursive = TRUE)

fwrite(transposition, "data/transposition_5amld.csv")
fwrite(ml_dt, "data/money_laundering_offences.csv")
fwrite(property_dt, "data/property_offences.csv")
fwrite(assault_dt, "data/assault_offences.csv")
fwrite(total_dt, "data/total_offences.csv")
fwrite(hpi_dt, "data/house_price_index.csv")
fwrite(emp_dt, "data/financial_employment.csv")
fwrite(gdp_dt, "data/gdp.csv")
fwrite(pop_dt, "data/population.csv")

message("\n=== All data fetched and saved ===")
message("Transposition dates: ", sum(!is.na(transposition$transposition_date)), " countries with dates")
message("ML offences: ", nrow(ml_dt), " country-year observations")
