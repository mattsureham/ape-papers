# 01_fetch_data.R — Fetch Eurostat packaging waste + CELLAR transposition dates
# apep_1049: EU Single-Use Plastics Directive

source("00_packages.R")

# ===========================================================================
# 1. EU-27 country reference
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
# 2. Fetch Eurostat env_waspac — Packaging waste by material
# ===========================================================================
message("Fetching Eurostat env_waspac (packaging waste by material)...")

# env_waspac: packaging waste generation and recycling
waspac_raw <- get_eurostat("env_waspac", cache_dir = "data/")
waspac <- as.data.table(waspac_raw)

message(sprintf("env_waspac: %d rows fetched", nrow(waspac)))

# Inspect available dimensions
message("waste categories: ", paste(unique(waspac$waste), collapse = ", "))
message("wst_oper categories: ", paste(unique(waspac$wst_oper), collapse = ", "))

# Key waste codes for packaging materials:
# W150101 = Paper and cardboard packaging
# W150102 = Plastic packaging
# W150103 = Wooden packaging
# W150104 = Metallic packaging
# W150107 = Glass packaging
# W1501 = Total packaging waste

# Filter to generation (GEN) and relevant materials
target_waste <- c("W150101", "W150102", "W150103", "W150104", "W150107", "W1501")
waspac_gen <- waspac[wst_oper == "GEN" & waste %in% target_waste]

# Extract year — Eurostat uses TIME_PERIOD column (Date class)
if ("TIME_PERIOD" %in% names(waspac_gen)) {
  waspac_gen[, year := as.integer(format(TIME_PERIOD, "%Y"))]
} else if ("time" %in% names(waspac_gen)) {
  waspac_gen[, year := as.integer(format(time, "%Y"))]
} else {
  stop("No time column found in env_waspac data")
}

# Keep only EU-27 countries
waspac_gen <- waspac_gen[geo %in% eu27$iso2]

message(sprintf("After filtering: %d rows, %d countries, years %d-%d",
                nrow(waspac_gen), uniqueN(waspac_gen$geo),
                min(waspac_gen$year), max(waspac_gen$year)))

# Save raw packaging waste
saveRDS(waspac_gen, "data/waspac_gen.rds")

# ===========================================================================
# 3. Fetch SUP Directive transposition dates from CELLAR SPARQL
# ===========================================================================
message("Fetching SUP Directive transposition dates from CELLAR SPARQL...")

# SUP Directive CELEX: 32019L0904
endpoint <- "https://publications.europa.eu/webapi/rdf/sparql"

# Step 1: Get cellar URI from CELEX
q1 <- '
PREFIX owl: <http://www.w3.org/2002/07/owl#>
SELECT ?cellar WHERE {
  ?cellar owl:sameAs <http://publications.europa.eu/resource/celex/32019L0904> .
  FILTER(CONTAINS(STR(?cellar), "/cellar/"))
}'

resp1 <- request(endpoint) |>
  req_url_query(query = q1) |>
  req_headers(Accept = "application/sparql-results+json") |>
  req_perform()

cellar_uri <- resp_body_json(resp1)$results$bindings[[1]]$cellar$value
message("CELLAR URI: ", cellar_uri)

# Step 2: Get all NIMs for SUP Directive
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

if (length(bindings) == 0) {
  stop("FATAL: No national implementation measures found for SUP Directive 32019L0904")
}

message(sprintf("Found %d national implementation measures", length(bindings)))

# Parse results
nims <- rbindlist(lapply(bindings, function(b) {
  data.table(
    country_uri = b$country$value,
    country = sub(".*/country/", "", b$country$value),
    notification_date = if (!is.null(b$notifDate)) as.Date(b$notifDate$value) else as.Date(NA),
    entry_into_force = if (!is.null(b$entryDate)) as.Date(b$entryDate$value) else as.Date(NA),
    document_date = if (!is.null(b$docDate)) as.Date(b$docDate$value) else as.Date(NA)
  )
}))

message("NIMs by country:")
print(nims[, .N, by = country][order(country)])

# Filter: keep only measures with dates AFTER the directive was adopted (2019-06-05)
# Earlier dates are predecessor legislation incorrectly linked to SUP
nims_post <- nims[
  (entry_into_force >= as.Date("2019-06-01") | is.na(entry_into_force)) &
  (notification_date >= as.Date("2019-06-01") | is.na(notification_date)) &
  (document_date >= as.Date("2019-01-01") | is.na(document_date))
]
# Also filter out rows where all dates are NA
nims_post <- nims_post[!is.na(entry_into_force) | !is.na(notification_date) | !is.na(document_date)]

message(sprintf("NIMs after filtering to post-2019: %d (from %d)", nrow(nims_post), nrow(nims)))

# Aggregate: earliest entry-into-force date per country
transposition <- nims_post[, .(
  first_eif = min(entry_into_force, na.rm = TRUE),
  first_notif = min(notification_date, na.rm = TRUE),
  first_doc = min(document_date, na.rm = TRUE),
  n_measures = .N
), by = country]

# Use entry-into-force as primary; fall back to notification then document date
transposition[, transposition_date := fifelse(
  !is.na(first_eif) & is.finite(first_eif), first_eif,
  fifelse(!is.na(first_notif) & is.finite(first_notif), first_notif, first_doc)
)]

# Convert ISO3 to ISO2 via eu27 lookup
transposition <- merge(transposition, eu27[, .(iso2, iso3)],
                       by.x = "country", by.y = "iso3", all.x = TRUE)

# Code transposition year (for annual data: if transposition before July 1, code as that year; otherwise next year)
transposition[, trans_year := as.integer(format(transposition_date, "%Y"))]
transposition[, trans_month := as.integer(format(transposition_date, "%m"))]
# If transposed in second half of year, the effective year for annual data is the next year
transposition[, effective_year := fifelse(trans_month >= 7, trans_year + 1L, trans_year)]

message("\nTransposition dates (earliest entry-into-force):")
print(transposition[order(transposition_date), .(country, iso2, transposition_date, effective_year, n_measures)])

stopifnot(nrow(transposition[!is.na(iso2)]) >= 15)
message(sprintf("\n%d EU-27 countries with SUP transposition dates", nrow(transposition[!is.na(iso2)])))

saveRDS(transposition, "data/transposition.rds")
saveRDS(nims, "data/nims_raw.rds")

# ===========================================================================
# 4. Fetch controls: GDP per capita and population
# ===========================================================================
message("\nFetching GDP per capita (nama_10_pc)...")
# nama_10_pc: GDP per capita in PPS, country-level
gdp_raw <- get_eurostat("nama_10_pc",
                        filters = list(unit = "CP_EUR_HAB", na_item = "B1GQ"),
                        cache_dir = "data/")
gdp <- as.data.table(gdp_raw)
if ("TIME_PERIOD" %in% names(gdp)) {
  gdp[, year := as.integer(format(TIME_PERIOD, "%Y"))]
} else {
  gdp[, year := as.integer(format(time, "%Y"))]
}
gdp <- gdp[geo %in% eu27$iso2 & year >= 2005 & year <= 2023]
gdp <- gdp[, .(geo, year, gdp_pc = values)]
saveRDS(gdp, "data/gdp_pc.rds")
message(sprintf("GDP per capita: %d observations", nrow(gdp)))

message("Fetching population (demo_pjan)...")
pop_raw <- get_eurostat("demo_pjan",
                        filters = list(sex = "T", age = "TOTAL"),
                        cache_dir = "data/")
pop <- as.data.table(pop_raw)
if ("TIME_PERIOD" %in% names(pop)) {
  pop[, year := as.integer(format(TIME_PERIOD, "%Y"))]
} else {
  pop[, year := as.integer(format(time, "%Y"))]
}
pop <- pop[geo %in% eu27$iso2 & year >= 2005 & year <= 2023]
pop <- pop[, .(geo, year, population = values)]
saveRDS(pop, "data/population.rds")
message(sprintf("Population: %d observations", nrow(pop)))

message("\n=== Data fetch complete ===")
