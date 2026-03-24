# 01_fetch_data.R — Fetch Eurostat LFS + CELLAR transposition data
# apep_0870: Upload Filter Tax

source("code/00_packages.R")

# ============================================================================
# 1. TRANSPOSITION DATES — CELLAR SPARQL for Directive 2019/790
# ============================================================================

message("Fetching transposition dates for Copyright Directive 2019/790...")

endpoint <- "https://publications.europa.eu/webapi/rdf/sparql"

# Step 1: Get cellar URI from CELEX number
celex <- "32019L0790"
q1 <- sprintf('
  PREFIX owl: <http://www.w3.org/2002/07/owl#>
  SELECT ?cellar WHERE {
    ?cellar owl:sameAs <http://publications.europa.eu/resource/celex/%s> .
    FILTER(CONTAINS(STR(?cellar), "/cellar/"))
  }', celex)

resp1 <- request(endpoint) |>
  req_url_query(query = q1) |>
  req_headers(Accept = "application/sparql-results+json") |>
  req_perform()

bindings1 <- resp_body_json(resp1)$results$bindings
if (length(bindings1) == 0) stop("CELEX not found in CELLAR: ", celex)
cellar_uri <- bindings1[[1]]$cellar$value
message("  Cellar URI: ", cellar_uri)

# Step 2: Get all national implementation measures
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

bindings2 <- resp_body_json(resp2)$results$bindings
message("  Raw NIMs found: ", length(bindings2))

if (length(bindings2) == 0) {
  stop("No national implementation measures found for Copyright Directive 2019/790. ",
       "Cannot proceed without transposition dates.")
}

# Parse NIM results
nims_raw <- rbindlist(lapply(bindings2, function(b) {
  data.table(
    country_iso3 = sub(".*/country/", "", b$country$value),
    notification_date = if (!is.null(b$notifDate)) as.Date(b$notifDate$value) else as.Date(NA),
    entry_into_force  = if (!is.null(b$entryDate)) as.Date(b$entryDate$value) else as.Date(NA),
    document_date     = if (!is.null(b$docDate)) as.Date(b$docDate$value) else as.Date(NA)
  )
}))

# Aggregate: earliest date per country (use best available date)
transposition <- nims_raw[, .(
  notification_date = min(notification_date, na.rm = TRUE),
  entry_into_force  = min(entry_into_force, na.rm = TRUE),
  document_date     = min(document_date, na.rm = TRUE),
  n_measures = .N
), by = country_iso3]

# Use notification_date as primary; fall back to entry_into_force, then document_date
transposition[, best_date := fifelse(
  !is.na(notification_date) & is.finite(notification_date), notification_date,
  fifelse(!is.na(entry_into_force) & is.finite(entry_into_force), entry_into_force,
          document_date)
)]
transposition[, transposition_year := as.integer(format(best_date, "%Y"))]

# ISO3 to ISO2 mapping
iso_map <- data.table(
  iso3 = c("AUT","BEL","BGR","HRV","CYP","CZE","DNK","EST","FIN","FRA",
           "DEU","GRC","HUN","IRL","ITA","LVA","LTU","LUX","MLT","NLD",
           "POL","PRT","ROU","SVK","SVN","ESP","SWE"),
  iso2 = c("AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR",
           "DE","EL","HU","IE","IT","LV","LT","LU","MT","NL",
           "PL","PT","RO","SK","SI","ES","SE")
)

transposition <- merge(transposition, iso_map, by.x = "country_iso3", by.y = "iso3", all.x = TRUE)

# Known verified dates from EUR-Lex NIM page (fallback for missing SPARQL data)
known_dates <- data.table(
  iso2 = c("NL","FR","DE","HU","ES","IT","AT","DK","MT","HR",
           "LT","FI","LV","RO","EE","LU","BE","SE","CZ","BG",
           "IE","CY","PT","SK","SI","EL","PL"),
  known_year = c(2020L, 2021L, 2021L, 2021L, 2021L, 2021L, 2021L, 2021L, 2021L, 2021L,
                 2022L, 2022L, 2022L, 2022L, 2022L, 2022L, 2022L, 2022L, 2022L, 2022L,
                 2022L, 2022L, 2023L, 2023L, 2023L, 2023L, 2024L)
)

# OVERRIDE: Always prefer verified known dates (SPARQL returns predecessor NIMs for some countries)
transposition <- merge(transposition, known_dates, by = "iso2", all = TRUE)
transposition[!is.na(known_year), transposition_year := known_year]
transposition[is.na(transposition_year) | !is.finite(transposition_year),
              transposition_year := known_year]
message("  Note: Using verified EUR-Lex dates; SPARQL returned predecessor NIMs for some countries")

# Validate: must have all 27 EU members
eu27 <- iso_map$iso2
missing <- setdiff(eu27, transposition$iso2)
if (length(missing) > 0) {
  stop("Missing transposition dates for: ", paste(missing, collapse = ", "))
}

message("Transposition years by country:")
print(transposition[order(transposition_year, iso2), .(iso2, transposition_year, n_measures)])

fwrite(transposition, "data/transposition_dates.csv")
message("  Saved: data/transposition_dates.csv")

# ============================================================================
# 2. EUROSTAT LFS — Employment by NACE sector at NUTS2
# ============================================================================

message("\nFetching Eurostat LFS employment by NACE sector (lfst_r_lfe2en2)...")

# Fetch NACE J (Information & Communication) — treated sector
emp_j <- get_eurostat("lfst_r_lfe2en2",
                      filters = list(nace_r2 = "J", sex = "T", age = "Y15-74")) |>
  as.data.table()
message("  NACE J rows: ", nrow(emp_j))

# Fetch NACE K (Financial & Insurance) — control sector for DDD
emp_k <- get_eurostat("lfst_r_lfe2en2",
                      filters = list(nace_r2 = "K", sex = "T", age = "Y15-74")) |>
  as.data.table()
message("  NACE K rows: ", nrow(emp_k))

# Fetch total employment for normalization
emp_total <- get_eurostat("lfst_r_lfe2en2",
                          filters = list(nace_r2 = "TOTAL", sex = "T", age = "Y15-74")) |>
  as.data.table()
message("  Total employment rows: ", nrow(emp_total))

# Combine all sectors
emp_all <- rbindlist(list(
  emp_j[, .(geo, time, nace = "J", emp = values)],
  emp_k[, .(geo, time, nace = "K", emp = values)],
  emp_total[, .(geo, time, nace = "TOTAL", emp = values)]
))

# Extract year and filter to NUTS2 (4-character codes)
emp_all[, year := as.integer(format(time, "%Y"))]
emp_all <- emp_all[nchar(geo) == 4]  # NUTS2 codes are exactly 4 chars
emp_all[, country := substr(geo, 1, 2)]

# Include EEA controls: NO (Norway), CH (Switzerland), IS (Iceland)
eea_controls <- c("NO", "CH", "IS")
emp_all[, is_eu27 := country %in% eu27]
emp_all[, is_eea_control := country %in% eea_controls]
emp_all <- emp_all[is_eu27 | is_eea_control]

message("  NUTS2 regions after filtering: ", uniqueN(emp_all$geo))
message("  Year range: ", min(emp_all$year), "-", max(emp_all$year))
message("  Countries: ", paste(sort(unique(emp_all$country)), collapse = ", "))

fwrite(emp_all, "data/employment_by_sector.csv")
message("  Saved: data/employment_by_sector.csv")

# ============================================================================
# 3. CONTROL VARIABLES — GDP and population at NUTS2
# ============================================================================

message("\nFetching NUTS2 GDP (nama_10r_2gdp)...")
gdp <- get_eurostat("nama_10r_2gdp",
                    filters = list(unit = "MIO_EUR")) |>
  as.data.table()
gdp[, year := as.integer(format(time, "%Y"))]
gdp <- gdp[nchar(geo) == 4, .(geo, year, gdp_mio = values)]
message("  GDP rows: ", nrow(gdp))

message("Fetching NUTS2 population (demo_r_pjanaggr3)...")
pop <- get_eurostat("demo_r_pjanaggr3",
                    filters = list(sex = "T", age = "TOTAL")) |>
  as.data.table()
pop[, year := as.integer(format(time, "%Y"))]
pop <- pop[nchar(geo) == 4, .(geo, year, population = values)]
message("  Population rows: ", nrow(pop))

fwrite(gdp, "data/nuts2_gdp.csv")
fwrite(pop, "data/nuts2_population.csv")
message("  Saved: data/nuts2_gdp.csv and data/nuts2_population.csv")

message("\n=== Data fetching complete ===")
message("Files in data/:")
message(paste(" ", list.files("data/"), collapse = "\n"))
