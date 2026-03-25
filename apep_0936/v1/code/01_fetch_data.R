# 01_fetch_data.R — Fetch Eurostat BERD data and CELLAR transposition dates
# for EU Trade Secrets Directive (2016/943)

source("00_packages.R")
library(eurostat)
library(httr2)

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ===========================================================================
# EU-27 country code lookup
# ===========================================================================
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
# 1. TRANSPOSITION DATES — CELLAR SPARQL for Directive 2016/943
# CELEX: 32016L0943
# ===========================================================================
message("=== Fetching transposition dates for Trade Secrets Directive (32016L0943) ===")

endpoint <- "https://publications.europa.eu/webapi/rdf/sparql"

# Step 1: Get cellar URI from CELEX
q1 <- 'PREFIX owl: <http://www.w3.org/2002/07/owl#>
SELECT ?cellar WHERE {
  ?cellar owl:sameAs <http://publications.europa.eu/resource/celex/32016L0943> .
  FILTER(CONTAINS(STR(?cellar), "/cellar/"))
}'

resp1 <- request(endpoint) |>
  req_url_query(query = q1) |>
  req_headers(Accept = "application/sparql-results+json") |>
  req_perform()

cellar_data <- resp_body_json(resp1)
stopifnot("No CELLAR URI found" = length(cellar_data$results$bindings) > 0)
cellar_uri <- cellar_data$results$bindings[[1]]$cellar$value
message("CELLAR URI: ", cellar_uri)

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
message("Found ", length(bindings), " national implementation measures")
stopifnot("No transposition data found" = length(bindings) > 0)

# Parse results
nims_dt <- rbindlist(lapply(bindings, function(b) {
  data.table(
    country_uri = b$country$value,
    notification_date = if (!is.null(b$notifDate)) as.Date(b$notifDate$value) else as.Date(NA),
    entry_into_force = if (!is.null(b$entryDate)) as.Date(b$entryDate$value) else as.Date(NA),
    document_date = if (!is.null(b$docDate)) as.Date(b$docDate$value) else as.Date(NA)
  )
}))

# Extract ISO3 country code from URI
nims_dt[, country_iso3 := toupper(sub(".*/country/", "", country_uri))]

# Map ISO3 to ISO2 using standard codes
iso_map <- data.table(
  iso3 = c("AUT","BEL","BGR","HRV","CYP","CZE","DNK","EST","FIN","FRA",
           "DEU","GRC","HUN","IRL","ITA","LVA","LTU","LUX","MLT","NLD",
           "POL","PRT","ROU","SVK","SVN","ESP","SWE","GBR"),
  iso2 = c("AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR",
           "DE","EL","HU","IE","IT","LV","LT","LU","MT","NL",
           "PL","PT","RO","SK","SI","ES","SE","UK")
)
nims_dt <- merge(nims_dt, iso_map, by.x = "country_iso3", by.y = "iso3", all.x = TRUE)

# Use the best available date: notification > entry_into_force > document
nims_dt[, best_date := fifelse(!is.na(notification_date), notification_date,
                       fifelse(!is.na(entry_into_force), entry_into_force,
                               document_date))]

# Aggregate: earliest date per country (first transposition measure)
transposition <- nims_dt[!is.na(best_date), .(
  first_transposition = min(best_date),
  n_measures = .N
), by = .(iso2, country_iso3)]

transposition[, transposition_year := as.integer(format(first_transposition, "%Y"))]

message("\n=== Transposition dates by country ===")
print(transposition[order(first_transposition)][, .(iso2, first_transposition, transposition_year, n_measures)])

# Save
fwrite(transposition, file.path(data_dir, "transposition_dates.csv"))
fwrite(nims_dt, file.path(data_dir, "nims_raw.csv"))

# ===========================================================================
# 2. EUROSTAT — BERD at NUTS2 level
# Dataset: rd_e_gerdreg (R&D expenditure by sector, NUTS2)
# ===========================================================================
message("\n=== Fetching BERD from Eurostat (rd_e_gerdreg) ===")

# Fetch GERD by sector of performance at NUTS2
rd_raw <- get_eurostat("rd_e_gerdreg",
  filters = list(
    sectperf = "BES",   # Business Enterprise Sector
    unit = "MIO_EUR"    # Millions of EUR
  ),
  cache_dir = data_dir
)
rd_dt <- as.data.table(rd_raw)

# Filter to NUTS2 (4-character codes)
rd_dt <- rd_dt[nchar(as.character(geo)) == 4]
rd_dt[, year := as.integer(format(time, "%Y"))]
rd_dt[, geo := as.character(geo)]

# Keep 2010-2023
rd_dt <- rd_dt[year >= 2010 & year <= 2023]
rd_dt[, country := substr(geo, 1, 2)]

# Filter to EU-27 + UK
eu_countries <- c(eu27$iso2, "UK")
rd_dt <- rd_dt[country %in% eu_countries]

message("BERD data: ", nrow(rd_dt), " region-year observations")
message("Unique regions: ", uniqueN(rd_dt$geo))
message("Year range: ", min(rd_dt$year), "-", max(rd_dt$year))
message("Countries: ", paste(sort(unique(rd_dt$country)), collapse = ", "))

fwrite(rd_dt[, .(geo, country, year, berd_mio_eur = values)],
       file.path(data_dir, "berd_nuts2.csv"))

# ===========================================================================
# 3. EUROSTAT — GDP at NUTS2 level (for normalization)
# ===========================================================================
message("\n=== Fetching GDP from Eurostat (nama_10r_2gdp) ===")

gdp_raw <- get_eurostat("nama_10r_2gdp",
  filters = list(unit = "MIO_EUR"),
  cache_dir = data_dir
)
gdp_dt <- as.data.table(gdp_raw)
gdp_dt <- gdp_dt[nchar(as.character(geo)) == 4]
gdp_dt[, year := as.integer(format(time, "%Y"))]
gdp_dt[, geo := as.character(geo)]
gdp_dt <- gdp_dt[year >= 2010 & year <= 2023]
gdp_dt[, country := substr(geo, 1, 2)]
gdp_dt <- gdp_dt[country %in% eu_countries]

message("GDP data: ", nrow(gdp_dt), " region-year observations")

fwrite(gdp_dt[, .(geo, country, year, gdp_mio_eur = values)],
       file.path(data_dir, "gdp_nuts2.csv"))

# ===========================================================================
# 4. EUROSTAT — Total GERD (all sectors) for robustness
# ===========================================================================
message("\n=== Fetching total GERD from Eurostat ===")

gerd_raw <- get_eurostat("rd_e_gerdreg",
  filters = list(
    sectperf = "TOTAL",
    unit = "MIO_EUR"
  ),
  cache_dir = data_dir
)
gerd_dt <- as.data.table(gerd_raw)
gerd_dt <- gerd_dt[nchar(as.character(geo)) == 4]
gerd_dt[, year := as.integer(format(time, "%Y"))]
gerd_dt[, geo := as.character(geo)]
gerd_dt <- gerd_dt[year >= 2010 & year <= 2023]
gerd_dt[, country := substr(geo, 1, 2)]
gerd_dt <- gerd_dt[country %in% eu_countries]

message("GERD data: ", nrow(gerd_dt), " region-year observations")

fwrite(gerd_dt[, .(geo, country, year, gerd_mio_eur = values)],
       file.path(data_dir, "gerd_nuts2.csv"))

# ===========================================================================
# 5. EUROSTAT — GVA by NACE sector at NUTS2 (for knowledge-intensive sectors)
# Dataset: nama_10r_3gva — NUTS3, but we'll aggregate
# ===========================================================================
message("\n=== Fetching GVA from Eurostat (nama_10r_2gvagd) ===")

# Try NUTS2 GVA first
gva_raw <- tryCatch({
  get_eurostat("nama_10r_2gvagd",
    filters = list(unit = "MIO_EUR"),
    cache_dir = data_dir
  )
}, error = function(e) {
  message("nama_10r_2gvagd not available, trying nama_10r_3gva...")
  NULL
})

if (!is.null(gva_raw)) {
  gva_dt <- as.data.table(gva_raw)
  gva_dt <- gva_dt[nchar(as.character(geo)) == 4]
  gva_dt[, year := as.integer(format(time, "%Y"))]
  gva_dt[, geo := as.character(geo)]
  gva_dt <- gva_dt[year >= 2010 & year <= 2023]
  gva_dt[, country := substr(geo, 1, 2)]
  gva_dt <- gva_dt[country %in% eu_countries]
  message("GVA data: ", nrow(gva_dt), " observations")
  fwrite(gva_dt[, .(geo, country, year, nace_r2, gva_mio_eur = values)],
         file.path(data_dir, "gva_nuts2.csv"))
} else {
  message("GVA data not available at NUTS2 — will use BERD only")
}

# ===========================================================================
# 6. EUROSTAT — Employment at NUTS2 (control variable)
# ===========================================================================
message("\n=== Fetching employment from Eurostat (nama_10r_3empers) ===")

emp_raw <- get_eurostat("nama_10r_3empers",
  filters = list(
    nace_r2 = "TOTAL",
    unit = "THS",    # Thousands of persons
    wstatus = "EMP"  # Total employment (not SAL or SELF)
  ),
  cache_dir = data_dir
)
emp_dt <- as.data.table(emp_raw)
# Aggregate NUTS3 to NUTS2 if needed
emp_dt[, geo := as.character(geo)]
emp_dt[, nuts_level := nchar(geo) - 2L]
emp_dt[, year := as.integer(format(time, "%Y"))]

# Use NUTS2 directly if available, otherwise aggregate NUTS3
emp_nuts2 <- emp_dt[nuts_level == 2 & year >= 2010 & year <= 2023]
emp_nuts2[, country := substr(geo, 1, 2)]
emp_nuts2 <- emp_nuts2[country %in% eu_countries]

message("Employment data: ", nrow(emp_nuts2), " region-year observations")

# Aggregate: sum employment across NACE categories, keep max (TOTAL should be largest)
emp_agg <- emp_nuts2[, .(emp_ths = max(values, na.rm = TRUE)), by = .(geo, country, year)]
message("Employment after dedup: ", nrow(emp_agg), " region-year observations")

fwrite(emp_agg, file.path(data_dir, "employment_nuts2.csv"))

# ===========================================================================
# Summary
# ===========================================================================
message("\n=== Data fetch complete ===")
message("Files saved to: ", data_dir)
message("  transposition_dates.csv — ", nrow(transposition), " countries")
message("  berd_nuts2.csv")
message("  gdp_nuts2.csv")
message("  gerd_nuts2.csv")
message("  employment_nuts2.csv")
if (!is.null(gva_raw)) message("  gva_nuts2.csv")
