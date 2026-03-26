## 01_fetch_data.R — Fetch Eurostat crime data + EIO transposition dates
## apep_0975: European Investigation Order and Crime Deterrence

source("00_packages.R")
setwd(file.path(dirname(getwd())))

# ===========================================================================
# 1. Eurostat crime data: crim_off_cat (police-recorded offences by ICCS)
# ===========================================================================
cat("Fetching Eurostat crim_off_cat...\n")
crime_raw <- get_eurostat("crim_off_cat", cache_dir = "data/")
crime_dt <- as.data.table(crime_raw)

cat(sprintf("  Raw crime data: %d rows\n", nrow(crime_dt)))
cat(sprintf("  ICCS categories: %s\n", paste(unique(crime_dt$iccs), collapse = ", ")))
cat(sprintf("  Countries: %s\n", paste(sort(unique(crime_dt$geo)), collapse = ", ")))
cat(sprintf("  Years: %s to %s\n",
            min(format(crime_dt$TIME_PERIOD, "%Y")), max(format(crime_dt$TIME_PERIOD, "%Y"))))

# Extract year
crime_dt[, year := as.integer(format(TIME_PERIOD, "%Y"))]

# Keep relevant ICCS categories
# Treatment (cross-border): Fraud (ICCS0701), Drug offences (ICCS0601), Theft (ICCS0502)
# Placebo (domestic): Homicide (ICCS0101), Assault (ICCS020111)
# Also keep total (ICCS0101 through broad categories)
target_iccs <- c("ICCS0701", "ICCS0601", "ICCS0502", "ICCS0101", "ICCS020111",
                 "ICCS02011", "ICCS0401")
crime_dt <- crime_dt[iccs %in% target_iccs]
cat(sprintf("  After ICCS filter: %d rows\n", nrow(crime_dt)))

# EU-25 participating states (EU-27 minus DK and IE who opted out)
eu27 <- c("AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR",
          "DE","EL","HU","IE","IT","LV","LT","LU","MT","NL",
          "PL","PT","RO","SK","SI","ES","SE")
crime_dt <- crime_dt[geo %in% eu27]

# Keep unit = NR (number of offences)
crime_dt <- crime_dt[unit == "NR"]

# Focus on 2008-2022
crime_dt <- crime_dt[year >= 2008 & year <= 2022]

cat(sprintf("  Final crime data: %d rows, %d countries, years %d-%d\n",
            nrow(crime_dt), length(unique(crime_dt$geo)),
            min(crime_dt$year), max(crime_dt$year)))

# Check coverage
coverage <- crime_dt[!is.na(values), .N, by = .(geo, iccs)]
cat(sprintf("  Non-missing cells: %d\n", sum(coverage$N)))

fwrite(crime_dt[, .(geo, year, iccs, values)], "data/crime_raw.csv")

# ===========================================================================
# 2. Population data for rate calculation
# ===========================================================================
cat("\nFetching Eurostat demo_pjan (population)...\n")
pop_raw <- get_eurostat("demo_pjan",
                        filters = list(sex = "T", age = "TOTAL"),
                        cache_dir = "data/")
pop_dt <- as.data.table(pop_raw)
# Column name varies by dataset: time or TIME_PERIOD
if ("TIME_PERIOD" %in% names(pop_dt)) {
  pop_dt[, year := as.integer(format(TIME_PERIOD, "%Y"))]
} else {
  pop_dt[, year := as.integer(format(time, "%Y"))]
}
pop_dt <- pop_dt[geo %in% eu27 & year >= 2008 & year <= 2022]
pop_dt <- pop_dt[, .(geo, year, population = values)]
pop_dt <- pop_dt[!is.na(population)]

# Deduplicate (keep latest observation per country-year)
pop_dt <- pop_dt[, .(population = max(population)), by = .(geo, year)]

cat(sprintf("  Population data: %d rows, %d countries\n",
            nrow(pop_dt), length(unique(pop_dt$geo))))

fwrite(pop_dt, "data/population.csv")

# ===========================================================================
# 3. EIO transposition dates from EUR-Lex CELLAR SPARQL
# ===========================================================================
cat("\nFetching EIO transposition dates from CELLAR SPARQL...\n")

eio_celex <- "32014L0041"

# Step 1: Resolve CELEX to CELLAR URI
endpoint <- "https://publications.europa.eu/webapi/rdf/sparql"

q_cellar <- sprintf('
  PREFIX owl: <http://www.w3.org/2002/07/owl#>
  SELECT ?cellar WHERE {
    ?cellar owl:sameAs <http://publications.europa.eu/resource/celex/%s> .
    FILTER(CONTAINS(STR(?cellar), "/cellar/"))
  }', eio_celex)

resp1 <- request(endpoint) |>
  req_url_query(query = q_cellar) |>
  req_headers(Accept = "application/sparql-results+json") |>
  req_perform()

cellar_result <- resp_body_json(resp1)
stopifnot(length(cellar_result$results$bindings) > 0)
cellar_uri <- cellar_result$results$bindings[[1]]$cellar$value
cat(sprintf("  CELLAR URI: %s\n", cellar_uri))

# Step 2: Get national implementation measures
q_nims <- sprintf('
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
  req_url_query(query = q_nims) |>
  req_headers(Accept = "application/sparql-results+json") |>
  req_perform()

bindings <- resp_body_json(resp2)$results$bindings
cat(sprintf("  NIM records found: %d\n", length(bindings)))

if (length(bindings) == 0) {
  stop("FATAL: No national implementation measures found for EIO directive. Cannot proceed.")
}

# Parse NIM results
nims_list <- lapply(bindings, function(b) {
  data.table(
    country_uri = b$country$value,
    notification_date = if (!is.null(b$notifDate)) as.Date(b$notifDate$value) else as.Date(NA),
    entry_into_force  = if (!is.null(b$entryDate)) as.Date(b$entryDate$value) else as.Date(NA),
    document_date     = if (!is.null(b$docDate))   as.Date(b$docDate$value) else as.Date(NA)
  )
})
nims_dt <- rbindlist(nims_list)

# Extract ISO3 country codes from URI
nims_dt[, iso3 := toupper(sub(".*/country/", "", country_uri))]

# Map ISO3 to ISO2
iso_map <- data.table(
  iso3 = c("AUT","BEL","BGR","HRV","CYP","CZE","DNK","EST","FIN","FRA",
           "DEU","GRC","HUN","IRL","ITA","LVA","LTU","LUX","MLT","NLD",
           "POL","PRT","ROU","SVK","SVN","ESP","SWE"),
  iso2 = c("AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR",
           "DE","EL","HU","IE","IT","LV","LT","LU","MT","NL",
           "PL","PT","RO","SK","SI","ES","SE")
)
nims_dt <- merge(nims_dt, iso_map, by = "iso3", all.x = TRUE)

# Use best available date: notification > entry_into_force > document
nims_dt[, best_date := fifelse(!is.na(notification_date), notification_date,
                       fifelse(!is.na(entry_into_force), entry_into_force,
                               document_date))]

# Filter: EIO directive adopted April 2014, deadline May 2017
# Measures dated before 2016 are for predecessor instruments (MLA Convention, EEW)
nims_dt <- nims_dt[is.na(best_date) | best_date >= as.Date("2016-01-01")]

# Aggregate: earliest date per country (post-2016 only)
eio_trans <- nims_dt[!is.na(iso2) & !is.na(best_date), .(
  transposition_date = min(best_date, na.rm = TRUE),
  n_measures = .N
), by = iso2]

eio_trans[, transposition_year := as.integer(format(transposition_date, "%Y"))]

cat("\nEIO Transposition dates:\n")
print(eio_trans[order(transposition_date)])

fwrite(eio_trans, "data/eio_transposition.csv")

# ===========================================================================
# 4. Validation assertions
# ===========================================================================
cat("\n=== Validation ===\n")
stopifnot("Crime data has rows" = nrow(crime_dt) > 0)
stopifnot("Population data has rows" = nrow(pop_dt) > 0)
stopifnot("EIO transposition data has rows" = nrow(eio_trans) > 0)
stopifnot("Multiple countries in crime data" = length(unique(crime_dt$geo)) >= 20)
stopifnot("Multiple years in crime data" = length(unique(crime_dt$year)) >= 10)

cat("All data fetched and validated.\n")
cat(sprintf("Crime: %d obs, Population: %d obs, Transposition: %d countries\n",
            nrow(crime_dt), nrow(pop_dt), nrow(eio_trans)))
