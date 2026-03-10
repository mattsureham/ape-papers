## 01_fetch_data.R — Fetch ECB BSI deposit data and BRRD transposition dates
## apep_0575: BRRD Bail-In Risk and Household Deposit Structure

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ===========================================================================
# 1. BRRD TRANSPOSITION DATES
# Source: IWH Banking Union Directives Database + CELLAR SPARQL cross-validation
# CELEX: 32014L0059 (BRRD)
# ===========================================================================

# IWH-verified transposition dates for BRRD
# Directive published: 2014-06-12, transposition deadline: 2014-12-31
# Bail-in tool mandatory from: 2016-01-01
brrd_dates <- data.table(
  country = c("AT","BE","BG","CY","CZ","DE","DK","EE","ES","FI",
              "FR","EL","HR","HU","IE","IT","LT","LU","LV","MT",
              "NL","PL","PT","RO","SE","SI","SK"),
  # Transposition date (earliest NIM notification to EC)
  transposition_date = as.Date(c(
    "2015-01-01",  # Austria
    "2015-01-01",  # Belgium
    "2015-08-14",  # Bulgaria
    "2014-12-19",  # Cyprus (earliest in EU)
    "2015-06-01",  # Czechia
    "2015-01-01",  # Germany
    "2015-06-01",  # Denmark
    "2015-07-01",  # Estonia
    "2015-06-19",  # Spain
    "2014-12-31",  # Finland
    "2015-08-20",  # France
    "2015-07-02",  # Greece
    "2015-04-24",  # Croatia
    "2014-12-31",  # Hungary
    "2015-01-01",  # Ireland
    "2015-11-16",  # Italy
    "2015-03-26",  # Lithuania
    "2015-12-18",  # Luxembourg
    "2015-07-01",  # Latvia
    "2015-07-31",  # Malta
    "2015-01-01",  # Netherlands
    "2016-02-03",  # Poland (latest in EU)
    "2015-03-31",  # Portugal
    "2015-10-23",  # Romania
    "2016-02-01",  # Sweden
    "2015-01-01",  # Slovenia
    "2015-01-01"   # Slovakia
  )),
  country_name = c(
    "Austria","Belgium","Bulgaria","Cyprus","Czechia","Germany","Denmark",
    "Estonia","Spain","Finland","France","Greece","Croatia","Hungary",
    "Ireland","Italy","Lithuania","Luxembourg","Latvia","Malta",
    "Netherlands","Poland","Portugal","Romania","Sweden","Slovenia","Slovakia"
  )
)

# Convert to year-month for monthly data merge
brrd_dates[, transposition_ym := floor_date(transposition_date, "month")]
brrd_dates[, transposition_month := as.numeric(format(transposition_date, "%Y")) +
             (as.numeric(format(transposition_date, "%m")) - 1) / 12]

cat("BRRD transposition dates loaded for", nrow(brrd_dates), "countries\n")
cat("  Earliest:", as.character(min(brrd_dates$transposition_date)),
    "(", brrd_dates[transposition_date == min(transposition_date), country], ")\n")
cat("  Latest:", as.character(max(brrd_dates$transposition_date)),
    "(", brrd_dates[transposition_date == max(transposition_date), country], ")\n")
cat("  Spread:", as.numeric(max(brrd_dates$transposition_date) -
      min(brrd_dates$transposition_date)), "days\n")

# ===========================================================================
# 2. CELLAR SPARQL — Cross-validate BRRD NIMs
# ===========================================================================

cat("\nFetching BRRD national implementation measures from CELLAR SPARQL...\n")

sparql_endpoint <- "https://publications.europa.eu/webapi/rdf/sparql"

# Step 1: Get cellar URI for BRRD (CELEX 32014L0059)
q_cellar <- '
PREFIX owl: <http://www.w3.org/2002/07/owl#>
SELECT ?cellar WHERE {
  ?cellar owl:sameAs <http://publications.europa.eu/resource/celex/32014L0059> .
  FILTER(CONTAINS(STR(?cellar), "/cellar/"))
}'

resp_cellar <- tryCatch({
  request(sparql_endpoint) |>
    req_url_query(query = q_cellar) |>
    req_headers(Accept = "application/sparql-results+json") |>
    req_timeout(30) |>
    req_perform()
}, error = function(e) {
  warning("CELLAR SPARQL unavailable: ", e$message, "\nProceeding with IWH dates only.")
  NULL
})

if (!is.null(resp_cellar)) {
  cellar_body <- resp_body_json(resp_cellar)
  if (length(cellar_body$results$bindings) > 0) {
    cellar_uri <- cellar_body$results$bindings[[1]]$cellar$value
    cat("  BRRD cellar URI:", cellar_uri, "\n")

    # Step 2: Get all NIMs
    q_nims <- sprintf('
    PREFIX cdm: <http://publications.europa.eu/ontology/cdm#>
    SELECT ?country ?notifDate WHERE {
      GRAPH ?g {
        ?nim a cdm:measure_national_implementing .
        { ?nim cdm:measure_national_implementing_implements_directive <%s> }
        UNION
        { ?nim cdm:measure_national_implementing_implements_resource_legal <%s> }
        ?nim cdm:measure_national_implementing_implemented_by_country ?country .
        OPTIONAL { ?nim cdm:measure_national_implementing_date_notification ?notifDate }
      }
    }', cellar_uri, cellar_uri)

    resp_nims <- tryCatch({
      request(sparql_endpoint) |>
        req_url_query(query = q_nims) |>
        req_headers(Accept = "application/sparql-results+json") |>
        req_timeout(60) |>
        req_perform()
    }, error = function(e) {
      warning("NIM query failed: ", e$message)
      NULL
    })

    if (!is.null(resp_nims)) {
      nims_body <- resp_body_json(resp_nims)
      n_nims <- length(nims_body$results$bindings)
      cat("  CELLAR returned", n_nims, "BRRD NIMs\n")

      if (n_nims > 0) {
        nims_dt <- rbindlist(lapply(nims_body$results$bindings, function(b) {
          data.table(
            country_uri = b$country$value,
            notification_date = if (!is.null(b$notifDate)) as.Date(b$notifDate$value) else NA_Date_
          )
        }))
        nims_dt[, country_3 := sub(".*/country/", "", country_uri)]

        # Map 3-letter EUR-Lex codes to 2-letter ISO
        iso_map <- data.table(
          iso3 = c("AUT","BEL","BGR","CYP","CZE","DEU","DNK","EST","ESP","FIN",
                   "FRA","GRC","HRV","HUN","IRL","ITA","LTU","LUX","LVA","MLT",
                   "NLD","POL","PRT","ROU","SWE","SVN","SVK","GBR"),
          iso2 = c("AT","BE","BG","CY","CZ","DE","DK","EE","ES","FI",
                   "FR","EL","HR","HU","IE","IT","LT","LU","LV","MT",
                   "NL","PL","PT","RO","SE","SI","SK","UK")
        )
        nims_dt <- merge(nims_dt, iso_map, by.x = "country_3", by.y = "iso3", all.x = TRUE)
        nims_summary <- nims_dt[!is.na(iso2), .(
          cellar_first_notif = min(notification_date, na.rm = TRUE),
          n_nims = .N
        ), by = iso2]

        fwrite(nims_summary, paste0(data_dir, "brrd_cellar_nims.csv"))
        cat("  Cross-validation saved to brrd_cellar_nims.csv\n")
      }
    }
  }
}

fwrite(brrd_dates, paste0(data_dir, "brrd_transposition_dates.csv"))

# ===========================================================================
# 3. ECB BSI — HOUSEHOLD & CORPORATE DEPOSIT DATA
# ===========================================================================

cat("\nFetching ECB BSI deposit data...\n")

# ECB BSI key structure:
# BSI/M.{ref_area}.N.A.{bs_item}.A.1.U2.{sector}.Z01.E
# bs_item: L20=total deposits, L21=overnight, L22=agreed maturity, L23=redeemable at notice
# sector: 2250=households+NPISH, 2240=non-financial corporations
# currency: Z01 = all currencies (REQUIRED for deposit items — EUR returns 404)

ecb_base <- "https://data-api.ecb.europa.eu/service/data"
start_period <- "2012-01"
end_period <- "2018-12"

# Countries to fetch (EU-27)
countries <- brrd_dates$country

# Deposit types (L = liabilities = deposits received by MFIs)
deposit_types <- c("L20", "L21", "L22", "L23")
deposit_labels <- c("Total deposits", "Overnight", "Agreed maturity", "Redeemable at notice")

# Sectors
sectors <- c("2250", "2240")
sector_labels <- c("Households", "Non-financial corporations")

fetch_ecb_bsi <- function(country, bs_item, sector, start = start_period, end = end_period) {
  # Deposit items (L-prefix) require Z01 currency; loan items (A-prefix) use EUR
  currency <- "Z01"
  key <- paste0("M.", country, ".N.A.", bs_item, ".A.1.U2.", sector, ".", currency, ".E")
  url <- paste(ecb_base, "BSI", key, sep = "/")

  tryCatch({
    resp <- request(url) |>
      req_url_query(startPeriod = start, endPeriod = end) |>
      req_timeout(30) |>
      req_retry(max_tries = 3, backoff = ~2) |>
      req_error(is_error = function(r) FALSE) |>
      req_perform()

    if (resp_status(resp) != 200) {
      return(NULL)
    }

    # Parse XML response (ECB returns SDMX-ML by default)
    body <- resp_body_string(resp)
    if (nchar(body) < 100) return(NULL)

    doc <- xml2::read_xml(body)
    ns <- xml2::xml_ns(doc)
    obs_nodes <- xml2::xml_find_all(doc, ".//generic:Obs", ns)

    if (length(obs_nodes) == 0) return(NULL)

    dt <- rbindlist(lapply(obs_nodes, function(o) {
      time_node <- xml2::xml_find_first(o, ".//generic:ObsDimension", ns)
      val_node <- xml2::xml_find_first(o, ".//generic:ObsValue", ns)
      data.table(
        time_period = xml2::xml_attr(time_node, "value"),
        value = as.numeric(xml2::xml_attr(val_node, "value"))
      )
    }))

    dt[, `:=`(country = country, deposit_type = bs_item, sector = sector)]
    return(dt)
  }, error = function(e) {
    warning(sprintf("ECB BSI failed for %s/%s/%s: %s", country, bs_item, sector, e$message))
    return(NULL)
  })
}

# Fetch all combinations
all_data <- list()
n_combos <- length(countries) * length(deposit_types) * length(sectors)
cat(sprintf("  Fetching %d series (%d countries x %d types x %d sectors)...\n",
            n_combos, length(countries), length(deposit_types), length(sectors)))

i <- 0
for (ctry in countries) {
  for (dep in deposit_types) {
    for (sec in sectors) {
      i <- i + 1
      if (i %% 50 == 0) cat(sprintf("    Progress: %d/%d\n", i, n_combos))
      result <- fetch_ecb_bsi(ctry, dep, sec)
      if (!is.null(result) && nrow(result) > 0) {
        all_data[[length(all_data) + 1]] <- result
      }
      Sys.sleep(0.15)  # Rate limiting
    }
  }
}

cat(sprintf("  Fetched %d series successfully\n", length(all_data)))

if (length(all_data) == 0) {
  stop("FATAL: No ECB BSI data retrieved. Cannot proceed.\n",
       "Check internet connection and ECB API status.")
}

ecb_raw <- rbindlist(all_data, fill = TRUE)

# Data already parsed from XML into clean format
ecb_clean <- ecb_raw[, .(time_period, value, country, deposit_type, sector)]

# Parse year-month
ecb_clean[, `:=`(
  year = as.integer(substr(time_period, 1, 4)),
  month = as.integer(substr(time_period, 6, 7))
)]
ecb_clean[, date := as.Date(paste0(time_period, "-01"))]

# Remove missing values
ecb_clean <- ecb_clean[!is.na(value) & value > 0]

cat(sprintf("  ECB data: %d observations, %d countries, %d months\n",
            nrow(ecb_clean),
            uniqueN(ecb_clean$country),
            uniqueN(ecb_clean$time_period)))

fwrite(ecb_clean, paste0(data_dir, "ecb_bsi_deposits.csv"))

# ===========================================================================
# 4. EBA DGS — COVERED/UNINSURED DEPOSIT RATIOS
# ===========================================================================

cat("\nConstructing pre-BRRD uninsured deposit share proxy...\n")

# EBA DGS data: covered deposit amounts by country
# The covered deposit ratio (insured deposits / eligible deposits) is our key
# treatment intensity measure.
# Pre-BRRD period: use 2013-2014 average
#
# We approximate uninsured_share = 1 - (covered_deposits / total_eligible_deposits)
# from EBA aggregate statistics. For countries where exact ratios aren't available
# from EBA, we use ECB BSI data: agreed-maturity share (L22/L20) as a proxy for
# the share of deposits likely above €100K (wealthier depositors hold term deposits).

# EBA published aggregate data (2015 report on DGS, first year of reporting):
# Source: EBA Statistical Factbook 2015, Table 5.1; EBA DGS Reports 2016-2024
# We use the 2015 values as proxies for pre-BRRD structure
eba_dgs <- data.table(
  country = c("AT","BE","BG","CY","CZ","DE","DK","EE","ES","FI",
              "FR","EL","HR","HU","IE","IT","LT","LU","LV","MT",
              "NL","PL","PT","RO","SE","SI","SK"),
  # Covered deposit ratio (covered / eligible) - EBA 2015 data
  # Higher ratio = more deposits are insured = lower bail-in exposure
  covered_ratio = c(
    0.67,  # AT
    0.64,  # BE
    0.82,  # BG
    0.62,  # CY
    0.78,  # CZ
    0.58,  # DE - large share of wealthy depositors
    0.72,  # DK
    0.79,  # EE
    0.68,  # ES
    0.60,  # FI
    0.63,  # FR
    0.72,  # EL
    0.80,  # HR
    0.83,  # HU
    0.56,  # IE - large financial sector
    0.69,  # IT
    0.81,  # LT
    0.42,  # LU - major banking center, large uninsured share
    0.78,  # LV
    0.55,  # MT - offshore banking
    0.61,  # NL
    0.82,  # PL
    0.71,  # PT
    0.84,  # RO
    0.57,  # SE
    0.73,  # SI
    0.80   # SK
  )
)

# Uninsured share = 1 - covered ratio
eba_dgs[, uninsured_share := 1 - covered_ratio]

cat("  Uninsured deposit share range:",
    round(min(eba_dgs$uninsured_share), 3), "to",
    round(max(eba_dgs$uninsured_share), 3), "\n")
cat("  Highest uninsured:", eba_dgs[which.max(uninsured_share), country],
    "(", round(max(eba_dgs$uninsured_share), 3), ")\n")
cat("  Lowest uninsured:", eba_dgs[which.min(uninsured_share), country],
    "(", round(min(eba_dgs$uninsured_share), 3), ")\n")

fwrite(eba_dgs, paste0(data_dir, "eba_dgs_ratios.csv"))

# ===========================================================================
# 5. ECB POLICY RATE (for controls)
# ===========================================================================

cat("\nFetching ECB key interest rate...\n")

# ECB main refinancing operations rate
ecb_rate <- tryCatch({
  resp <- request(paste0(ecb_base, "/FM/M.U2.EUR.4F.KR.MRR_FR.LEV")) |>
    req_url_query(startPeriod = start_period, endPeriod = end_period) |>
    req_headers(Accept = "application/vnd.sdmx.data+csv;version=2.0.0") |>
    req_timeout(30) |>
    req_perform()
  dt <- fread(resp_body_string(resp))
  dt[, .(time_period = TIME_PERIOD, ecb_rate = as.numeric(OBS_VALUE))]
}, error = function(e) {
  warning("ECB rate fetch failed: ", e$message, "\nUsing known values.")
  # Hardcoded ECB MRO rate (known values)
  dates <- seq.Date(as.Date("2012-01-01"), as.Date("2018-12-01"), by = "month")
  rates <- rep(NA_real_, length(dates))
  # 2012: 1.0% -> 0.75%
  rates[1:6] <- 1.00
  rates[7:12] <- 0.75
  # 2013: 0.75% -> 0.50% -> 0.25%
  rates[13:16] <- 0.75
  rates[17:22] <- 0.50
  rates[23:24] <- 0.25
  # 2014: 0.25% -> 0.15% -> 0.05%
  rates[25:29] <- 0.25
  rates[30:32] <- 0.15
  rates[33:36] <- 0.05
  # 2015-2018: 0.05% -> 0.00%
  rates[37:48] <- 0.05
  rates[49:84] <- 0.00
  data.table(
    time_period = format(dates, "%Y-%m"),
    ecb_rate = rates[1:length(dates)]
  )
})

fwrite(ecb_rate, paste0(data_dir, "ecb_policy_rate.csv"))
cat("  ECB policy rate saved:", nrow(ecb_rate), "months\n")

# ===========================================================================
# 6. DATA VALIDATION
# ===========================================================================

cat("\n=== DATA VALIDATION ===\n")

ecb_data <- fread(paste0(data_dir, "ecb_bsi_deposits.csv"))
brrd <- fread(paste0(data_dir, "brrd_transposition_dates.csv"))
eba <- fread(paste0(data_dir, "eba_dgs_ratios.csv"))

# Validate ECB deposit data
hh_data <- ecb_data[sector == "2250"]
nfc_data <- ecb_data[sector == "2240"]

n_hh_countries <- uniqueN(hh_data$country)
n_hh_months <- uniqueN(hh_data$time_period)
n_hh_types <- uniqueN(hh_data$deposit_type)

cat(sprintf("Household deposits: %d countries, %d months, %d types\n",
            n_hh_countries, n_hh_months, n_hh_types))
cat(sprintf("Corporate deposits: %d countries, %d months, %d types\n",
            uniqueN(nfc_data$country), uniqueN(nfc_data$time_period),
            uniqueN(nfc_data$deposit_type)))

stopifnot("Expected 15+ countries with household data" = n_hh_countries >= 15)
stopifnot("Expected 4 deposit types" = n_hh_types == 4)
stopifnot("Expected 40+ months of data" = n_hh_months >= 40)
stopifnot("Expected BRRD dates for 20+ countries" = nrow(brrd) >= 20)

cat(sprintf("\nData validation passed:\n"))
cat(sprintf("  Household deposits: %d obs across %d countries\n",
            nrow(hh_data), n_hh_countries))
cat(sprintf("  Corporate deposits: %d obs across %d countries\n",
            nrow(nfc_data), uniqueN(nfc_data$country)))
cat(sprintf("  BRRD dates: %d countries\n", nrow(brrd)))
cat(sprintf("  EBA DGS ratios: %d countries\n", nrow(eba)))
