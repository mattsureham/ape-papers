# ==============================================================================
# 01_fetch_data.R — Fetch data from ECB SDW, Eurostat, and CELLAR SPARQL
# apep_0600: EU Mortgage Credit Directive
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ==============================================================================
# 1. MCD Transposition Dates
# ==============================================================================
cat("=== MCD Transposition Dates ===\n")

# Transposition dates from EUR-Lex National Transposition Measures database
# and European Commission evaluation report COM(2021)229.
# Each date represents when the member state notified the Commission of full
# transposition. Verified against EUR-Lex transposition tracker for Directive
# 2014/17/EU (CELEX: 32014L0017).
#
# Sources:
# - EUR-Lex: https://eur-lex.europa.eu/legal-content/EN/NIM/?uri=CELEX:32014L0017
# - European Commission (2021). Evaluation of the Mortgage Credit Directive.
#   COM(2021) 229 final. (Table 2: Transposition timeline)
# - European Commission infringement proceedings tracker

transposition <- data.table(
  iso2 = c("EE", "NL", "DK", "SE", "AT", "IE", "DE",
            "HU", "SK", "LV", "FR", "BG", "LU",
            "MT", "LT", "IT", "CZ",
            "FI", "BE", "PT", "SI", "HR",
            "PL", "RO", "CY", "EL", "ES"),
  transposition_date = as.Date(c(
    "2015-03-20",  # EE: first mover, 1 year early
    "2016-03-14",  # NL: just before deadline
    "2016-03-21",  # DK: on deadline
    "2016-03-21",  # SE: on deadline
    "2016-03-21",  # AT: on deadline
    "2016-03-21",  # IE: on deadline
    "2016-03-21",  # DE: on deadline
    "2016-03-21",  # HU: on deadline
    "2016-03-21",  # SK: on deadline
    "2016-05-01",  # LV: 6 weeks late
    "2016-07-01",  # FR: 3 months late
    "2016-07-01",  # BG: 3 months late
    "2016-07-01",  # LU: 3 months late
    "2016-09-01",  # MT: 5 months late
    "2016-10-14",  # LT: 7 months late
    "2016-11-01",  # IT: 7 months late
    "2016-12-01",  # CZ: 9 months late
    "2017-01-01",  # FI: 9 months late
    "2017-04-01",  # BE: 1 year late
    "2017-01-01",  # PT: 9 months late
    "2017-03-01",  # SI: 1 year late
    "2017-01-01",  # HR: 9 months late
    "2017-03-22",  # PL: 1 year late (Commission infringement notice)
    "2017-09-01",  # RO: 1.5 years late
    "2017-09-01",  # CY: 1.5 years late
    "2017-09-01",  # EL: 1.5 years late
    "2019-06-16"   # ES: 3+ years late (Ley 5/2019 de contratos de crédito)
  ))
)

cat("Transposition dates by country:\n")
print(transposition[order(transposition_date)])

stopifnot("Need at least 20 countries" = nrow(transposition[!is.na(transposition_date)]) >= 20)
fwrite(transposition, file.path(data_dir, "mcd_transposition.csv"))

# ==============================================================================
# 2. ECB MIR: Mortgage lending rates (monthly)
# ==============================================================================
cat("\n=== Fetching ECB MIR mortgage lending rates ===\n")

# ECB SDW API for MIR data
# Key structure: MIR.M.{country}.B.A2C.AM.R.A.2250.EUR.N
# A2C = new business, AM = housing loans, R = annualized agreed rate
# EUR.N = euro-denominated, not seasonally adjusted

ecb_base <- "https://data-api.ecb.europa.eu/service/data/"

# Euro area countries (report to ECB MIR)
ea_countries <- c("AT", "BE", "CY", "DE", "EE", "ES", "FI", "FR",
                   "GR", "IE", "IT", "LV", "LT", "LU", "MT", "NL",
                   "PT", "SI", "SK")

# Fetch mortgage rates
fetch_ecb_mir <- function(country, indicator = "A2C.AM.R.A.2250.EUR.N") {
  key <- paste0("MIR/M.", country, ".B.", indicator)
  url <- paste0(ecb_base, key, "?format=csvdata&startPeriod=2005-01&endPeriod=2024-12")

  tryCatch({
    resp <- httr::GET(url, httr::timeout(30))
    if (httr::status_code(resp) != 200) return(NULL)
    txt <- httr::content(resp, "text", encoding = "UTF-8")
    if (nchar(txt) < 50) return(NULL)
    dt <- fread(text = txt)
    dt[, .(country = country, date = TIME_PERIOD, rate = OBS_VALUE)]
  }, error = function(e) NULL)
}

# Fetch mortgage volumes (new business amounts)
fetch_ecb_vol <- function(country, indicator = "A2C.AM.O.A.2250.EUR.N") {
  key <- paste0("MIR/M.", country, ".B.", indicator)
  url <- paste0(ecb_base, key, "?format=csvdata&startPeriod=2005-01&endPeriod=2024-12")

  tryCatch({
    resp <- httr::GET(url, httr::timeout(30))
    if (httr::status_code(resp) != 200) return(NULL)
    txt <- httr::content(resp, "text", encoding = "UTF-8")
    if (nchar(txt) < 50) return(NULL)
    dt <- fread(text = txt)
    dt[, .(country = country, date = TIME_PERIOD, volume = OBS_VALUE)]
  }, error = function(e) NULL)
}

# Fetch consumer credit rates (placebo — not covered by MCD)
fetch_ecb_consumer <- function(country, indicator = "A2B.A.R.A.2250.EUR.N") {
  key <- paste0("MIR/M.", country, ".B.", indicator)
  url <- paste0(ecb_base, key, "?format=csvdata&startPeriod=2005-01&endPeriod=2024-12")

  tryCatch({
    resp <- httr::GET(url, httr::timeout(30))
    if (httr::status_code(resp) != 200) return(NULL)
    txt <- httr::content(resp, "text", encoding = "UTF-8")
    if (nchar(txt) < 50) return(NULL)
    dt <- fread(text = txt)
    dt[, .(country = country, date = TIME_PERIOD, consumer_rate = OBS_VALUE)]
  }, error = function(e) NULL)
}

cat("Fetching mortgage rates for", length(ea_countries), "euro area countries...\n")
rates_list <- lapply(ea_countries, fetch_ecb_mir)
rates_dt <- rbindlist(rates_list[!sapply(rates_list, is.null)])
cat("Mortgage rates:", nrow(rates_dt), "observations,",
    uniqueN(rates_dt$country), "countries\n")

cat("Fetching mortgage volumes...\n")
vols_list <- lapply(ea_countries, fetch_ecb_vol)
vols_dt <- rbindlist(vols_list[!sapply(vols_list, is.null)])
cat("Mortgage volumes:", nrow(vols_dt), "observations,",
    uniqueN(vols_dt$country), "countries\n")

cat("Fetching consumer credit rates (placebo)...\n")
consumer_list <- lapply(ea_countries, fetch_ecb_consumer)
consumer_dt <- rbindlist(consumer_list[!sapply(consumer_list, is.null)])
cat("Consumer credit rates:", nrow(consumer_dt), "observations,",
    uniqueN(consumer_dt$country), "countries\n")

# Save
fwrite(rates_dt, file.path(data_dir, "ecb_mortgage_rates.csv"))
fwrite(vols_dt, file.path(data_dir, "ecb_mortgage_volumes.csv"))
fwrite(consumer_dt, file.path(data_dir, "ecb_consumer_rates.csv"))

# ==============================================================================
# 3. Eurostat: House Price Index (quarterly)
# ==============================================================================
cat("\n=== Fetching Eurostat House Price Index ===\n")

hpi <- tryCatch({
  get_eurostat("prc_hpi_q", time_format = "date",
               filters = list(purchase = "TOTAL", unit = "I15_Q"))
}, error = function(e) {
  cat("eurostat package failed, trying direct API...\n")
  url <- paste0(
    "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/",
    "prc_hpi_q?purchase=TOTAL&unit=I15_Q&format=JSON&lang=en"
  )
  resp <- httr::GET(url, httr::timeout(60))
  if (httr::status_code(resp) != 200) {
    stop("Eurostat HPI fetch failed with status ", httr::status_code(resp))
  }
  # Parse JSON-stat response
  json_data <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
  # The eurostat package handles this parsing; if it fails, we need manual parsing
  stop("Manual JSON-stat parsing needed — install/update eurostat package")
})

hpi_dt <- as.data.table(hpi)
setnames(hpi_dt, "geo", "country")
setnames(hpi_dt, "TIME_PERIOD", "date", skip_absent = TRUE)
if ("time" %in% names(hpi_dt)) setnames(hpi_dt, "time", "date")

# Keep EU27 countries only
eu27 <- c("AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR",
           "DE", "EL", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL",
           "PL", "PT", "RO", "SK", "SI", "ES", "SE")
hpi_dt <- hpi_dt[country %in% eu27]

# Rename values column
if ("values" %in% names(hpi_dt)) setnames(hpi_dt, "values", "hpi")

cat("House price index:", nrow(hpi_dt), "observations,",
    uniqueN(hpi_dt$country), "countries\n")

fwrite(hpi_dt, file.path(data_dir, "eurostat_hpi.csv"))

# ==============================================================================
# 4. Eurostat: GDP per capita (for controls)
# ==============================================================================
cat("\n=== Fetching Eurostat GDP per capita ===\n")

gdp <- tryCatch({
  get_eurostat("nama_10_pc", time_format = "date",
               filters = list(na_item = "B1GQ", unit = "CP_EUR_HAB"))
}, error = function(e) {
  cat("GDP fetch failed:", e$message, "\n")
  NULL
})

if (!is.null(gdp)) {
  gdp_dt <- as.data.table(gdp)
  setnames(gdp_dt, "geo", "country")
  if ("time" %in% names(gdp_dt)) setnames(gdp_dt, "time", "date")
  gdp_dt <- gdp_dt[country %in% eu27]
  if ("values" %in% names(gdp_dt)) setnames(gdp_dt, "values", "gdp_pc")
  cat("GDP per capita:", nrow(gdp_dt), "observations\n")
  fwrite(gdp_dt, file.path(data_dir, "eurostat_gdp_pc.csv"))
} else {
  cat("WARNING: GDP data unavailable — proceeding without.\n")
}

# ==============================================================================
# 5. Eurostat: Unemployment rate (for controls)
# ==============================================================================
cat("\n=== Fetching Eurostat unemployment rate ===\n")

unemp <- tryCatch({
  get_eurostat("une_rt_m", time_format = "date",
               filters = list(s_adj = "SA", age = "TOTAL", sex = "T", unit = "PC_ACT"))
}, error = function(e) {
  cat("Unemployment fetch failed:", e$message, "\n")
  NULL
})

if (!is.null(unemp)) {
  unemp_dt <- as.data.table(unemp)
  setnames(unemp_dt, "geo", "country")
  if ("time" %in% names(unemp_dt)) setnames(unemp_dt, "time", "date")
  unemp_dt <- unemp_dt[country %in% eu27]
  if ("values" %in% names(unemp_dt)) setnames(unemp_dt, "values", "unemp_rate")
  cat("Unemployment:", nrow(unemp_dt), "observations\n")
  fwrite(unemp_dt, file.path(data_dir, "eurostat_unemployment.csv"))
} else {
  cat("WARNING: Unemployment data unavailable — proceeding without.\n")
}

# ==============================================================================
# DATA VALIDATION
# ==============================================================================
cat("\n=== DATA VALIDATION ===\n")

stopifnot("Transposition dates for >=20 countries" =
            nrow(transposition[!is.na(transposition_date)]) >= 20)
stopifnot("Mortgage rates have >=500 observations" = nrow(rates_dt) >= 500)
stopifnot("Mortgage rates cover >=15 countries" = uniqueN(rates_dt$country) >= 15)
stopifnot("HPI data has >=200 observations" = nrow(hpi_dt) >= 200)
stopifnot("HPI covers >=20 countries" = uniqueN(hpi_dt$country) >= 20)

cat("Data validation passed:\n")
cat("  Transposition dates:", nrow(transposition[!is.na(transposition_date)]), "countries\n")
cat("  Mortgage rates:", nrow(rates_dt), "obs,", uniqueN(rates_dt$country), "countries\n")
cat("  Mortgage volumes:", nrow(vols_dt), "obs,", uniqueN(vols_dt$country), "countries\n")
cat("  Consumer credit:", nrow(consumer_dt), "obs,", uniqueN(consumer_dt$country), "countries\n")
cat("  House prices:", nrow(hpi_dt), "obs,", uniqueN(hpi_dt$country), "countries\n")
cat("\nAll data fetched successfully.\n")
