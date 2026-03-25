# ===========================================================================
# 01_fetch_data.R — Data acquisition for apep_0919
# Whistleblower Shield and Corruption Exposure
# ===========================================================================

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# --- EU-27 country codes ---
eu27 <- data.table(
  iso2 = c("AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR",
           "DE","EL","HU","IE","IT","LV","LT","LU","MT","NL",
           "PL","PT","RO","SK","SI","ES","SE"),
  name = c("Austria","Belgium","Bulgaria","Croatia","Cyprus","Czechia",
           "Denmark","Estonia","Finland","France","Germany","Greece",
           "Hungary","Ireland","Italy","Latvia","Lithuania","Luxembourg",
           "Malta","Netherlands","Poland","Portugal","Romania","Slovakia",
           "Slovenia","Spain","Sweden")
)

# ===========================================================================
# 1. TREATMENT: Transposition dates for Directive 2019/1937
# CELEX: 32019L1937 (Whistleblower Protection Directive)
# ===========================================================================

cat("Fetching transposition dates from CELLAR SPARQL...\n")

endpoint <- "https://publications.europa.eu/webapi/rdf/sparql"

# Step 1: Get cellar URI from CELEX number
q1 <- '
PREFIX owl: <http://www.w3.org/2002/07/owl#>
SELECT ?cellar WHERE {
  ?cellar owl:sameAs <http://publications.europa.eu/resource/celex/32019L1937> .
  FILTER(CONTAINS(STR(?cellar), "/cellar/"))
}'

resp1 <- request(endpoint) |>
  req_url_query(query = q1) |>
  req_headers(Accept = "application/sparql-results+json") |>
  req_perform()

cellar_uri <- resp_body_json(resp1)$results$bindings[[1]]$cellar$value
cat("  Cellar URI:", cellar_uri, "\n")

# Step 2: Get national implementation measures
q2 <- sprintf('
PREFIX cdm: <http://publications.europa.eu/ontology/cdm#>
SELECT ?country ?notifDate ?entryDate ?docDate WHERE {
  GRAPH ?g {
    ?nim a cdm:measure_national_implementing .
    { ?nim cdm:measure_national_implementing_implements_directive <%s> }
    UNION
    { ?nim cdm:measure_national_implementing_implements_resource_legal <%s> }
    ?nim cdm:measure_national_implementing_implemented_by_country ?country .
    OPTIONAL { ?nim cdm:measure_national_implementing_date_notification ?notifDate }
    OPTIONAL { ?nim cdm:resource_legal_date_entry-into-force ?entryDate }
    OPTIONAL { ?nim cdm:work_date_document ?docDate }
  }
}', cellar_uri, cellar_uri)

resp2 <- request(endpoint) |>
  req_url_query(query = q2) |>
  req_headers(Accept = "application/sparql-results+json") |>
  req_perform()

bindings <- resp_body_json(resp2)$results$bindings
cat("  Found", length(bindings), "national implementation measures\n")

# Parse results
nims_raw <- rbindlist(lapply(bindings, function(b) {
  data.table(
    country_uri = b$country$value,
    notification_date = if (!is.null(b$notifDate)) as.Date(b$notifDate$value) else as.Date(NA),
    entry_into_force = if (!is.null(b$entryDate)) as.Date(b$entryDate$value) else as.Date(NA),
    document_date = if (!is.null(b$docDate)) as.Date(b$docDate$value) else as.Date(NA)
  )
}))

# Extract ISO3 country code from URI
nims_raw[, iso3 := toupper(sub(".*/country/", "", country_uri))]

# Map ISO3 to ISO2
iso_map <- data.table(
  iso3 = c("AUT","BEL","BGR","HRV","CYP","CZE","DNK","EST","FIN","FRA",
           "DEU","GRC","HUN","IRL","ITA","LVA","LTU","LUX","MLT","NLD",
           "POL","PRT","ROU","SVK","SVN","ESP","SWE"),
  iso2 = eu27$iso2
)

nims_raw <- merge(nims_raw, iso_map, by = "iso3", all.x = TRUE)

# Filter to measures after the directive was adopted (Dec 2019)
# Earlier dates are for unrelated pre-existing national measures
nims_raw <- nims_raw[is.na(notification_date) | notification_date >= as.Date("2019-12-01") |
                     is.na(entry_into_force) | entry_into_force >= as.Date("2019-12-01")]

# Aggregate: earliest date per country (use notification > entry > document)
transposition <- nims_raw[!is.na(iso2), .(
  first_notification = min(notification_date, na.rm = TRUE),
  first_entry_into_force = min(entry_into_force, na.rm = TRUE),
  first_document = min(document_date, na.rm = TRUE),
  n_measures = .N
), by = iso2]

# Use the best available date
transposition[, transposition_date := fifelse(
  !is.infinite(as.numeric(first_notification)), first_notification,
  fifelse(!is.infinite(as.numeric(first_entry_into_force)), first_entry_into_force,
          first_document)
)]
transposition[, transposition_year := as.integer(format(transposition_date, "%Y"))]

cat("  Transposition dates recovered for", nrow(transposition[!is.na(transposition_year)]), "countries\n")
print(transposition[order(transposition_year, iso2), .(iso2, transposition_year, transposition_date, n_measures)])

fwrite(transposition, paste0(data_dir, "transposition_dates.csv"))

# ===========================================================================
# 2. OUTCOMES: Eurostat crime statistics
# crim_off_cat — Police-recorded offences by crime category
# ===========================================================================

cat("\nFetching Eurostat crime statistics (crim_off_cat)...\n")

crime_raw <- get_eurostat("crim_off_cat", cache_dir = data_dir)
crime_dt <- as.data.table(crime_raw)

# Filter to relevant crime types: corruption and fraud
# ICCS codes: 0703 (corruption), 0701 (fraud)
crime_dt[, year := as.integer(format(TIME_PERIOD, "%Y"))]

# Check available crime categories
cat("  Available crime categories:\n")
print(crime_dt[, .N, by = iccs][order(-N)])

# Keep corruption and fraud; also bribery and money laundering if available
crime_filtered <- crime_dt[
  iccs %in% c("ICCS0703", "ICCS0701", "ICCS07041", "ICCS0601") &
  unit == "NR" &
  geo %in% eu27$iso2 &
  year >= 2015
]

cat("  Crime records after filtering:", nrow(crime_filtered), "\n")
cat("  Countries:", crime_filtered[, uniqueN(geo)], "\n")
cat("  Years:", paste(range(crime_filtered$year), collapse = "-"), "\n")

fwrite(crime_filtered, paste0(data_dir, "crime_data.csv"))

# ===========================================================================
# 3. OUTCOMES: Corruption Perception Index (CPI)
# sdg_16_50 — CPI score
# ===========================================================================

cat("\nFetching CPI data (sdg_16_50)...\n")

cpi_raw <- get_eurostat("sdg_16_50", cache_dir = data_dir)
cpi_dt <- as.data.table(cpi_raw)
cpi_dt[, year := as.integer(format(TIME_PERIOD, "%Y"))]

cpi_filtered <- cpi_dt[
  geo %in% eu27$iso2 &
  year >= 2015
]

cat("  CPI records:", nrow(cpi_filtered), "\n")
cat("  Countries:", cpi_filtered[, uniqueN(geo)], "\n")

fwrite(cpi_filtered, paste0(data_dir, "cpi_data.csv"))

# ===========================================================================
# 4. OUTCOMES: Government expenditure on courts (COFOG GF0303)
# gov_10a_exp
# ===========================================================================

cat("\nFetching government expenditure on courts (gov_10a_exp)...\n")

gov_raw <- get_eurostat("gov_10a_exp",
  filters = list(cofog99 = "GF0303", unit = "MIO_EUR", sector = "S13", na_item = "TE"))
gov_dt <- as.data.table(gov_raw)
setnames(gov_dt, "time", "time_period", skip_absent = TRUE)
setnames(gov_dt, "TIME_PERIOD", "time_period", skip_absent = TRUE)
gov_dt[, year := as.integer(format(time_period, "%Y"))]

gov_filtered <- gov_dt[
  geo %in% eu27$iso2 &
  year >= 2015
]

cat("  Court expenditure records:", nrow(gov_filtered), "\n")

fwrite(gov_filtered, paste0(data_dir, "court_expenditure.csv"))

# ===========================================================================
# 5. CONTROLS: GDP and Population
# ===========================================================================

cat("\nFetching GDP (nama_10_gdp)...\n")

gdp_raw <- get_eurostat("nama_10_gdp",
  filters = list(unit = "CP_MEUR", na_item = "B1GQ"))
gdp_dt <- as.data.table(gdp_raw)
setnames(gdp_dt, "time", "time_period", skip_absent = TRUE)
setnames(gdp_dt, "TIME_PERIOD", "time_period", skip_absent = TRUE)
gdp_dt[, year := as.integer(format(time_period, "%Y"))]
gdp_filtered <- gdp_dt[geo %in% eu27$iso2 & year >= 2015]
fwrite(gdp_filtered, paste0(data_dir, "gdp_data.csv"))

cat("\nFetching population (demo_pjan)...\n")

pop_raw <- get_eurostat("demo_pjan",
  filters = list(sex = "T", age = "TOTAL"))
pop_dt <- as.data.table(pop_raw)
setnames(pop_dt, "time", "time_period", skip_absent = TRUE)
setnames(pop_dt, "TIME_PERIOD", "time_period", skip_absent = TRUE)
pop_dt[, year := as.integer(format(time_period, "%Y"))]
pop_filtered <- pop_dt[geo %in% eu27$iso2 & year >= 2015]
fwrite(pop_filtered, paste0(data_dir, "population_data.csv"))

cat("\n=== Data fetch complete ===\n")
cat("Files saved to:", normalizePath(data_dir), "\n")
