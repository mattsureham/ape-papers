## 01_fetch_data.R — Fetch Eurostat data for EU PQ Directive analysis
## apep_0845: EU Professional Qualifications Directive

source("code/00_packages.R")

cat("\n=== FETCHING EUROSTAT DATA ===\n")

## ─── 1. Overqualification by citizenship (primary outcome) ────────────────
## lfsa_eoqgan: Over-qualification rates by citizenship
## Dimension: geo × time × citizen × isced11 × age × sex
cat("Fetching overqualification data (lfsa_eoqgan)...\n")
oq_raw <- get_eurostat("lfsa_eoqgan", time_format = "num")
cat(sprintf("  Rows: %d\n", nrow(oq_raw)))
stopifnot("Overqualification data is empty" = nrow(oq_raw) > 0)

## ─── 2. Employment by NACE sector (secondary outcome) ─────────────────────
## lfst_r_lfe2en2: Employment by NACE Rev.2, age, sex — NUTS2
cat("Fetching employment by sector (lfst_r_lfe2en2)...\n")
emp_raw <- get_eurostat("lfst_r_lfe2en2", time_format = "num",
                        filters = list(sex = "T", age = "Y15-64"))
cat(sprintf("  Rows: %d\n", nrow(emp_raw)))
stopifnot("Employment data is empty" = nrow(emp_raw) > 0)

## ─── 3. Immigration by citizenship (secondary outcome) ────────────────────
## migr_imm1ctz: Immigration by citizenship
cat("Fetching immigration data (migr_imm1ctz)...\n")
imm_raw <- tryCatch({
  d <- get_eurostat("migr_imm1ctz", time_format = "num")
  cat(sprintf("  Rows (full): %d\n", nrow(d)))
  d
}, error = function(e) {
  cat(sprintf("  migr_imm1ctz failed: %s\n", e$message))
  cat("  Trying migr_imm2ctz...\n")
  tryCatch({
    d <- get_eurostat("migr_imm2ctz", time_format = "num")
    cat(sprintf("  Rows: %d\n", nrow(d)))
    d
  }, error = function(e2) {
    cat(sprintf("  migr_imm2ctz also failed: %s — creating empty placeholder\n", e2$message))
    data.table(geo = character(), time = numeric(), citizen = character(), values = numeric())
  })
})
cat(sprintf("  Immigration rows: %d\n", nrow(imm_raw)))

## ─── 4. Self-employment by citizenship (secondary outcome) ────────────────
## lfsa_esgan: Self-employment by citizenship
cat("Fetching self-employment data (lfsa_esgan)...\n")
se_raw <- tryCatch({
  d <- get_eurostat("lfsa_esgan", time_format = "num")
  cat(sprintf("  Rows: %d\n", nrow(d)))
  d
}, error = function(e) {
  cat(sprintf("  lfsa_esgan failed: %s — creating empty placeholder\n", e$message))
  data.table(geo = character(), time = numeric(), citizen = character(), values = numeric())
})
cat(sprintf("  Self-employment rows: %d\n", nrow(se_raw)))

## ─── 5. Regulated professions count by country ───────────────────────────
## Source: European Commission Regulated Professions Database
## https://ec.europa.eu/growth/tools-databases/regprof/
## Pre-compiled from ECA Special Report 10/2024 and EC database
## These are the number of regulated professions per country circa 2013
regulated_profs <- data.table(
  geo = c("AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR",
          "DE", "EL", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL",
          "PL", "PT", "RO", "SK", "SI", "ES", "SE"),
  n_regulated = c(260, 218, 102, 198, 140, 395, 171, 100, 148, 211,
                  371, 228, 415, 124, 184, 115, 88, 157, 145, 176,
                  364, 217, 159, 174, 299, 186, 109)
)
cat(sprintf("  Countries: %d, range: %d-%d regulated professions\n",
            nrow(regulated_profs), min(regulated_profs$n_regulated),
            max(regulated_profs$n_regulated)))

## ─── 6. Transposition dates via CELLAR SPARQL ─────────────────────────────
cat("Fetching transposition dates for Directive 2013/55/EU...\n")

sparql_query <- '
PREFIX cdm: <http://publications.europa.eu/ontology/cdm#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
SELECT DISTINCT ?country ?notif_date
WHERE {
  ?measure cdm:resource_legal_is_about_concept_directory-code <http://publications.europa.eu/resource/authority/fd_555/CONSIL.3278.SN>;
           cdm:resource_legal_date_notification ?notif_date;
           cdm:resource_legal_id_sector ?country.
  FILTER(STRLEN(STR(?country)) = 2 || STRLEN(STR(?country)) = 3)
}
ORDER BY ?country
'

# Try fetching transposition data
tryCatch({
  resp <- httr::GET(
    "https://publications.europa.eu/webapi/rdf/sparql",
    query = list(query = sparql_query, format = "application/sparql-results+json"),
    httr::timeout(30)
  )
  if (httr::status_code(resp) == 200) {
    result <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
    bindings <- result$results$bindings
    if (!is.null(bindings) && nrow(bindings) > 0) {
      transposition <- data.table(
        geo = bindings$country$value,
        notif_date = as.Date(bindings$notif_date$value)
      )
      cat(sprintf("  SPARQL returned %d transposition records\n", nrow(transposition)))
    } else {
      cat("  SPARQL returned no results — using manual transposition dates\n")
      transposition <- NULL
    }
  } else {
    cat(sprintf("  SPARQL HTTP %d — using manual transposition dates\n",
                httr::status_code(resp)))
    transposition <- NULL
  }
}, error = function(e) {
  cat(sprintf("  SPARQL error: %s — using manual transposition dates\n", e$message))
  transposition <<- NULL
})

# Fallback: manual transposition dates from ECA Report 10/2024
# Deadline was January 18, 2016. Early/on-time vs late transposers.
if (is.null(transposition) || nrow(transposition) == 0) {
  transposition <- data.table(
    geo = c("AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR",
            "DE", "EL", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL",
            "PL", "PT", "RO", "SK", "SI", "ES", "SE"),
    # Transposition year (when national law came into force)
    # Early: before deadline (2016); Late: 2016-2019; Very late: 2020+
    trans_year = c(2016, 2017, 2016, 2020, 2018, 2016, 2016, 2016, 2016, 2017,
                   2016, 2020, 2016, 2017, 2018, 2016, 2016, 2016, 2017, 2016,
                   2016, 2018, 2016, 2016, 2016, 2016, 2016)
  )
  cat("  Using manual transposition dates (ECA Report 10/2024)\n")
}

## ─── Save raw data ────────────────────────────────────────────────────────
cat("\nSaving raw data...\n")
saveRDS(oq_raw, "data/oq_raw.rds")
saveRDS(emp_raw, "data/emp_raw.rds")
saveRDS(imm_raw, "data/imm_raw.rds")
saveRDS(se_raw, "data/se_raw.rds")
saveRDS(regulated_profs, "data/regulated_profs.rds")
saveRDS(transposition, "data/transposition.rds")

cat("\n=== DATA FETCH COMPLETE ===\n")
cat(sprintf("Overqualification: %d rows\n", nrow(oq_raw)))
cat(sprintf("Employment: %d rows\n", nrow(emp_raw)))
cat(sprintf("Immigration: %d rows\n", nrow(imm_raw)))
cat(sprintf("Self-employment: %d rows\n", nrow(se_raw)))
cat(sprintf("Regulated professions: %d countries\n", nrow(regulated_profs)))
cat(sprintf("Transposition dates: %d countries\n", nrow(transposition)))
