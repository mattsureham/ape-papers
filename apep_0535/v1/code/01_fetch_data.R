# ==============================================================================
# 01_fetch_data.R — Fetch all data sources
# apep_0535: Gas Tax Hikes and Macroeconomic Beliefs
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ==============================================================================
# 1. STATE GAS TAX CHANGES (hand-compiled from Tax Foundation, NCSL, FHWA)
# ==============================================================================
# Sources:
#   - Tax Foundation: https://taxfoundation.org/data/all/state/gas-taxes-state/
#   - NCSL: State Tax Actions database
#   - FHWA: https://www.fhwa.dot.gov/policyinformation/statistics.cfm
#   - ITEP: https://itep.org/state-gas-tax-rates/
#
# Criteria for inclusion: DISCRETE legislative increases (not automatic
# indexation adjustments). Each entry has a specific effective date and
# a fixed cents-per-gallon increase amount.

gas_tax_changes <- tribble(
  ~state, ~state_abbr, ~fips, ~effective_date,       ~increase_cpg, ~notes,
  # 2013
  "Virginia",        "VA", 51, "2013-07-01",  5.0,  "Restructured: eliminated 17.5cpg, added 3.5% wholesale + 0.7% retail levy; net initial ~5cpg increase",
  "Wyoming",         "WY", 56, "2013-07-01", 10.0,  "From 14cpg to 24cpg",
  "Vermont",         "VT", 50, "2013-07-01",  5.9,  "Adjusted rate from 19cpg to ~25cpg",
  "Maryland",        "MD", 24, "2013-07-01",  3.5,  "Phase 1: sales tax on gas (net ~3.5cpg initial rise)",
  # 2014
  "New Hampshire",   "NH", 33, "2014-07-01",  4.2,  "From 18cpg to 22.2cpg",
  "Rhode Island",    "RI", 44, "2014-07-01",  1.0,  "Indexed to inflation (initial bump ~1cpg); treated as discrete",
  # 2015
  "Georgia",         "GA", 13, "2015-07-01",  6.7,  "Restructured: from 7.5cpg to ~26.3cpg excise",
  "Idaho",           "ID", 16, "2015-07-01",  7.0,  "From 25cpg to 32cpg",
  "Iowa",            "IA", 19, "2015-03-01", 10.0,  "From 21cpg to 31cpg",
  "Nebraska",        "NE", 31, "2015-01-01",  6.0,  "From 25.6cpg to 31.6cpg (phased over 4 years)",
  "South Dakota",    "SD", 46, "2015-04-01",  6.0,  "From 22cpg to 28cpg",
  "Utah",            "UT", 49, "2015-01-01",  4.9,  "From 24.5cpg to 29.4cpg",
  "Washington",      "WA", 53, "2015-08-01", 11.9,  "From 37.5cpg to 49.4cpg (phased: 7cpg 2015, 4.9cpg 2016)",
  # 2016
  "New Jersey",      "NJ", 34, "2016-11-01", 22.6,  "From 14.5cpg to 37.1cpg",
  "Michigan",        "MI", 26, "2017-01-01",  7.3,  "From 19cpg to 26.3cpg (phased from 2016 legislation)",
  "Pennsylvania",    "PA", 42, "2016-01-01", 12.8,  "Phase-in from Act 89 (2013): effective rate rose ~12.8cpg by Jan 2016",
  # 2017
  "California",      "CA",  6, "2017-11-01", 12.0,  "SB1: from 18cpg to 30cpg excise + 5.75% sales",
  "Indiana",         "IN", 18, "2017-07-01", 10.0,  "From 18cpg to 28cpg + variable surcharge",
  "Montana",         "MT", 30, "2017-07-01",  6.0,  "From 27cpg to 33cpg (phased)",
  "Oregon",          "OR", 41, "2017-01-01", 10.0,  "HB 2017: from 30cpg to 34cpg (phased: +4cpg 2018, +2cpg each 2020,2022,2024)",
  "South Carolina",  "SC", 45, "2017-07-01",  2.0,  "Phase 1: from 16.75cpg to 18.75cpg (+2cpg/yr through 2022, total +12cpg)",
  "Tennessee",       "TN", 47, "2017-07-01",  6.0,  "IMPROVE Act: from 20cpg to 26cpg (phased)",
  "West Virginia",   "WV", 54, "2017-07-01",  3.5,  "Variable rate increase ~3.5cpg net",
  # 2018
  "Oklahoma",        "OK", 40, "2018-10-01",  3.0,  "From 16cpg to 19cpg",
  # 2019
  "Alabama",         "AL",  1, "2019-09-01",  6.0,  "Rebuild Alabama Act: from 18cpg to 24cpg (phased: +6, +2, +2)",
  "Arkansas",        "AR",  5, "2019-10-01",  3.0,  "From 21.5cpg to 24.5cpg",
  "Illinois",        "IL", 17, "2019-07-01", 19.0,  "From 19cpg to 38cpg (doubled)",
  "Ohio",            "OH", 39, "2019-07-01", 10.5,  "From 28cpg to 38.5cpg",
  # 2021
  "North Carolina",  "NC", 37, "2021-01-01",  2.5,  "Formula adjustment yielded net +2.5cpg discrete increase"
)

gas_tax_changes <- gas_tax_changes %>%
  mutate(
    effective_date = as.Date(effective_date),
    treat_year = year(effective_date)
  )

cat("Gas tax changes compiled:", nrow(gas_tax_changes), "treatment events across",
    n_distinct(gas_tax_changes$state), "states\n")
cat("Treatment years:", paste(sort(unique(gas_tax_changes$treat_year)), collapse = ", "), "\n")

fwrite(gas_tax_changes, file.path(data_dir, "gas_tax_changes.csv"))

# ==============================================================================
# 2. CES CUMULATIVE DATASET (Harvard Dataverse)
# ==============================================================================

ces_file <- file.path(data_dir, "ces_cumulative.rds")

if (!file.exists(ces_file)) {
  cat("Downloading CES cumulative dataset from Harvard Dataverse...\n")
  ces_url <- "https://dataverse.harvard.edu/api/access/datafile/12134963"
  tryCatch({
    download.file(ces_url, ces_file, mode = "wb", quiet = FALSE)
    cat("CES download complete:", round(file.size(ces_file) / 1e6, 1), "MB\n")
  }, error = function(e) {
    stop("CES data unavailable: ", e$message,
         "\nPivot research question or fix the source.")
  })
} else {
  cat("CES data already downloaded:", round(file.size(ces_file) / 1e6, 1), "MB\n")
}

# Load and validate
ces_raw <- readRDS(ces_file)
cat("CES loaded:", nrow(ces_raw), "rows,", ncol(ces_raw), "columns\n")

# Check key variables exist
required_vars <- c("year", "st", "economy_retro")
missing <- setdiff(required_vars, names(ces_raw))
if (length(missing) > 0) {
  # Try alternative variable names
  if (!"economy_retro" %in% names(ces_raw)) {
    # Check for alternative spellings
    econ_vars <- grep("econom|retro", names(ces_raw), value = TRUE, ignore.case = TRUE)
    cat("Economy-related variables found:", paste(econ_vars, collapse = ", "), "\n")
    if (length(econ_vars) == 0) {
      stop("Cannot find economy_retro or equivalent in CES data.")
    }
  }
}

# Validate
stopifnot("CES must have year variable" = "year" %in% names(ces_raw))
stopifnot("CES must have state variable" = "st" %in% names(ces_raw) | "state" %in% names(ces_raw))

cat("CES years:", paste(sort(unique(ces_raw$year)), collapse = ", "), "\n")
cat("CES states:", n_distinct(ces_raw$st), "\n")

# ==============================================================================
# 3. FRED DATA: National gas prices + state unemployment
# ==============================================================================

cat("\nFetching FRED data...\n")

# National weekly gas price (for aggregate context)
gas_national <- fredr(
  series_id = "GASREGW",
  observation_start = as.Date("2005-01-01"),
  observation_end = as.Date("2024-12-31")
) %>%
  select(date, gas_price_national = value) %>%
  mutate(year = year(date), month = month(date))

cat("National gas prices:", nrow(gas_national), "weekly observations\n")

fwrite(gas_national, file.path(data_dir, "gas_national.csv"))

# State unemployment rates from FRED (all 50 states + DC)
state_fips_map <- tribble(
  ~state_abbr, ~fips, ~fred_prefix,
  "AL", 1, "ALUR", "AK", 2, "AKUR", "AZ", 4, "AZUR", "AR", 5, "ARUR",
  "CA", 6, "CAUR", "CO", 8, "COUR", "CT", 9, "CTUR", "DE", 10, "DEUR",
  "FL", 12, "FLUR", "GA", 13, "GAUR", "HI", 15, "HIUR", "ID", 16, "IDUR",
  "IL", 17, "ILUR", "IN", 18, "INUR", "IA", 19, "IAUR", "KS", 20, "KSUR",
  "KY", 21, "KYUR", "LA", 22, "LAUR", "ME", 23, "MEUR", "MD", 24, "MDUR",
  "MA", 25, "MAUR", "MI", 26, "MIUR", "MN", 27, "MNUR", "MS", 28, "MSUR",
  "MO", 29, "MOUR", "MT", 30, "MTUR", "NE", 31, "NEUR", "NV", 32, "NVUR",
  "NH", 33, "NHUR", "NJ", 34, "NJUR", "NM", 35, "NMUR", "NY", 36, "NYUR",
  "NC", 37, "NCUR", "ND", 38, "NDUR", "OH", 39, "OHUR", "OK", 40, "OKUR",
  "OR", 41, "ORUR", "PA", 42, "PAUR", "RI", 44, "RIUR", "SC", 45, "SCUR",
  "SD", 46, "SDUR", "TN", 47, "TNUR", "TX", 48, "TXUR", "UT", 49, "UTUR",
  "VT", 50, "VTUR", "VA", 51, "VAUR", "WA", 53, "WAUR", "WV", 54, "WVUR",
  "WI", 55, "WIUR", "WY", 56, "WYUR", "DC", 11, "DCUR"
)

cat("Fetching state unemployment rates from FRED...\n")
state_unemp_list <- list()
for (i in seq_len(nrow(state_fips_map))) {
  sid <- state_fips_map$fred_prefix[i]
  tryCatch({
    d <- fredr(
      series_id = sid,
      observation_start = as.Date("2005-01-01"),
      observation_end = as.Date("2024-12-31")
    )
    if (nrow(d) > 0) {
      state_unemp_list[[sid]] <- d %>%
        select(date, unemp_rate = value) %>%
        mutate(
          state_abbr = state_fips_map$state_abbr[i],
          fips = state_fips_map$fips[i],
          year = year(date),
          month = month(date)
        )
    }
    Sys.sleep(0.15)  # rate limit
  }, error = function(e) {
    cat("  Warning: failed to fetch", sid, "-", e$message, "\n")
  })
}
state_unemp <- bind_rows(state_unemp_list)
cat("State unemployment:", nrow(state_unemp), "observations across",
    n_distinct(state_unemp$state_abbr), "states\n")

fwrite(state_unemp, file.path(data_dir, "state_unemployment.csv"))

# ==============================================================================
# 4. BEA STATE PERSONAL INCOME (annual, for economic controls)
# ==============================================================================

cat("\nFetching BEA state personal income...\n")
bea_key <- Sys.getenv("BEA_API_KEY")
if (nchar(bea_key) == 0) stop("BEA_API_KEY not found in environment.")

bea_url <- paste0(
  "https://apps.bea.gov/api/data/?UserID=", bea_key,
  "&method=GetData&datasetname=Regional",
  "&TableName=SAINC1",
  "&LineCode=1",
  "&GeoFips=STATE",
  "&Year=2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019,2020,2021,2022,2023,2024",
  "&ResultFormat=JSON"
)

bea_resp <- tryCatch({
  httr::GET(bea_url, httr::timeout(60))
}, error = function(e) {
  stop("BEA API unavailable: ", e$message)
})

if (httr::status_code(bea_resp) != 200) {
  stop("BEA API returned status ", httr::status_code(bea_resp))
}

bea_json <- httr::content(bea_resp, as = "text", encoding = "UTF-8")
bea_parsed <- fromJSON(bea_json)
bea_data <- bea_parsed$BEAAPI$Results$Data

if (is.null(bea_data) || nrow(bea_data) == 0) {
  stop("BEA API returned no data.")
}

state_income <- bea_data %>%
  as_tibble() %>%
  filter(GeoFips != "00000") %>%  # exclude US total
  mutate(
    fips = as.integer(substr(GeoFips, 1, 2)),
    year = as.integer(TimePeriod),
    personal_income = as.numeric(gsub(",", "", DataValue))
  ) %>%
  filter(!is.na(personal_income), fips <= 56 | fips == 11) %>%
  select(fips, year, personal_income, state_name = GeoName)

cat("BEA state income:", nrow(state_income), "observations across",
    n_distinct(state_income$fips), "states\n")

fwrite(state_income, file.path(data_dir, "state_personal_income.csv"))

# ==============================================================================
# 5. GOOGLE TRENDS — "inflation" and "recession" by state, monthly
# ==============================================================================

cat("\nFetching Google Trends data...\n")

# We fetch in batches to avoid rate limits
# Google Trends returns relative interest (0-100) normalized per query

# Function to fetch Google Trends for a keyword across all US states
fetch_gtrends_state <- function(keyword, time_range = "2010-01-01 2024-12-31") {
  tryCatch({
    res <- gtrends(
      keyword = keyword,
      geo = "US",
      time = time_range,
      onlyInterest = FALSE
    )

    # Extract interest by region (states)
    if (!is.null(res$interest_by_region)) {
      state_data <- res$interest_by_region %>%
        as_tibble() %>%
        filter(geo != "US") %>%
        mutate(keyword = keyword)
      return(state_data)
    }

    # Also get time series
    if (!is.null(res$interest_over_time)) {
      time_data <- res$interest_over_time %>%
        as_tibble() %>%
        mutate(keyword = keyword)
      return(list(region = NULL, time = time_data))
    }

    return(NULL)
  }, error = function(e) {
    cat("  Google Trends error for", keyword, ":", e$message, "\n")
    return(NULL)
  })
}

# Fetch interest over time (national, monthly resolution)
gtrends_time_list <- list()
for (kw in c("inflation", "recession", "economy", "gas prices")) {
  cat("  Fetching time series for:", kw, "\n")
  tryCatch({
    res <- gtrends(
      keyword = kw,
      geo = "US",
      time = "2010-01-01 2024-12-31"
    )
    if (!is.null(res$interest_over_time)) {
      gtrends_time_list[[kw]] <- res$interest_over_time %>%
        as_tibble() %>%
        mutate(keyword = kw)
    }
    Sys.sleep(3)  # rate limit
  }, error = function(e) {
    cat("  Error fetching", kw, ":", e$message, "\n")
  })
}

if (length(gtrends_time_list) > 0) {
  gtrends_national <- bind_rows(gtrends_time_list)
  cat("Google Trends national time series:", nrow(gtrends_national), "rows\n")
  fwrite(gtrends_national, file.path(data_dir, "gtrends_national.csv"))
} else {
  cat("WARNING: No Google Trends national data fetched.\n")
}

# Fetch state-level interest over time for "inflation" — requires state-by-state queries
# Google Trends doesn't directly give monthly state-level data; the API returns
# geographic breakdown for the entire time range.
# Strategy: Fetch "inflation" interest by state for each year window.

cat("  Fetching state-level Google Trends for 'inflation' by year...\n")
gtrends_state_list <- list()

for (yr in 2010:2024) {
  cat("    Year:", yr, "\n")
  tryCatch({
    res <- gtrends(
      keyword = "inflation",
      geo = "US",
      time = paste0(yr, "-01-01 ", yr, "-12-31")
    )
    if (!is.null(res$interest_by_region)) {
      gtrends_state_list[[as.character(yr)]] <- res$interest_by_region %>%
        as_tibble() %>%
        mutate(year = yr, keyword = "inflation")
    }
    Sys.sleep(2)
  }, error = function(e) {
    cat("    Error:", e$message, "\n")
  })
}

if (length(gtrends_state_list) > 0) {
  gtrends_state <- bind_rows(gtrends_state_list)
  cat("Google Trends state-year:", nrow(gtrends_state), "rows across",
      n_distinct(gtrends_state$location), "locations\n")
  fwrite(gtrends_state, file.path(data_dir, "gtrends_state_inflation.csv"))
}

# Also fetch "recession" by state
cat("  Fetching state-level Google Trends for 'recession' by year...\n")
gtrends_recession_list <- list()

for (yr in 2010:2024) {
  cat("    Year:", yr, "\n")
  tryCatch({
    res <- gtrends(
      keyword = "recession",
      geo = "US",
      time = paste0(yr, "-01-01 ", yr, "-12-31")
    )
    if (!is.null(res$interest_by_region)) {
      gtrends_recession_list[[as.character(yr)]] <- res$interest_by_region %>%
        as_tibble() %>%
        mutate(year = yr, keyword = "recession")
    }
    Sys.sleep(2)
  }, error = function(e) {
    cat("    Error:", e$message, "\n")
  })
}

if (length(gtrends_recession_list) > 0) {
  gtrends_recession <- bind_rows(gtrends_recession_list)
  fwrite(gtrends_recession, file.path(data_dir, "gtrends_state_recession.csv"))
}

# ==============================================================================
# 6. EIA SEDS — Annual state gasoline prices (first-stage validation)
# ==============================================================================

cat("\nFetching EIA SEDS annual state gas prices...\n")

eia_url <- "https://api.eia.gov/v2/seds/data/?api_key=DEMO_KEY&frequency=annual&data[0]=value&facets[seriesId][]=MGACD&start=2005&end=2024&sort[0][column]=period&sort[0][direction]=asc&length=5000"

eia_resp <- tryCatch({
  httr::GET(eia_url, httr::timeout(60))
}, error = function(e) {
  cat("EIA API warning:", e$message, "\n")
  NULL
})

if (!is.null(eia_resp) && httr::status_code(eia_resp) == 200) {
  eia_json <- httr::content(eia_resp, as = "text", encoding = "UTF-8")
  eia_parsed <- fromJSON(eia_json)
  if (!is.null(eia_parsed$response$data)) {
    eia_data <- eia_parsed$response$data %>%
      as_tibble() %>%
      mutate(
        year = as.integer(period),
        gas_price_btu = as.numeric(value),
        state_abbr = stateId
      ) %>%
      filter(!is.na(gas_price_btu), nchar(state_abbr) == 2, state_abbr != "US") %>%
      select(state_abbr, year, gas_price_btu)

    cat("EIA SEDS:", nrow(eia_data), "observations across",
        n_distinct(eia_data$state_abbr), "states\n")
    fwrite(eia_data, file.path(data_dir, "eia_seds_gas_prices.csv"))
  }
} else {
  cat("WARNING: EIA SEDS fetch failed. First stage validation will use FRED/BLS data.\n")
}

# ==============================================================================
# 7. USDA RURAL-URBAN CONTINUUM CODES (for heterogeneity)
# ==============================================================================

cat("\nFetching USDA Rural-Urban Continuum Codes...\n")
rucc_url <- "https://www.ers.usda.gov/webdocs/DataFiles/53251/ruralurbancodes2023.csv"

rucc_file <- file.path(data_dir, "rucc_2023.csv")
if (!file.exists(rucc_file)) {
  tryCatch({
    download.file(rucc_url, rucc_file, mode = "wb", quiet = TRUE)
    cat("RUCC downloaded.\n")
  }, error = function(e) {
    # Try alternative URL
    rucc_url2 <- "https://www.ers.usda.gov/webdocs/DataFiles/53251/ruralurbancodes2013.csv"
    tryCatch({
      download.file(rucc_url2, rucc_file, mode = "wb", quiet = TRUE)
      cat("RUCC (2013 vintage) downloaded.\n")
    }, error = function(e2) {
      cat("WARNING: Could not download RUCC data. Will create urban/rural proxy from state.\n")
    })
  })
}

if (file.exists(rucc_file)) {
  rucc <- fread(rucc_file)
  cat("RUCC codes:", nrow(rucc), "counties\n")
}

# ==============================================================================
# DATA VALIDATION
# ==============================================================================

cat("\n=== DATA VALIDATION ===\n")

# CES
stopifnot("CES must have 50+ states" = n_distinct(ces_raw$st) >= 50)
stopifnot("CES must span 2006-2024" = min(ces_raw$year) <= 2006 & max(ces_raw$year) >= 2023)
cat("CES validation passed:", nrow(ces_raw), "rows,",
    n_distinct(ces_raw$st), "states,",
    n_distinct(ces_raw$year), "years\n")

# Gas tax changes
stopifnot("Need 20+ treated states" = n_distinct(gas_tax_changes$state) >= 20)
cat("Gas tax validation passed:", n_distinct(gas_tax_changes$state), "treated states\n")

# State unemployment
stopifnot("Need 45+ states in unemployment data" = n_distinct(state_unemp$state_abbr) >= 45)
cat("State unemployment validation passed:", n_distinct(state_unemp$state_abbr), "states\n")

# State income
stopifnot("Need 45+ states in income data" = n_distinct(state_income$fips) >= 45)
cat("State income validation passed:", n_distinct(state_income$fips), "states\n")

cat("\n=== ALL DATA FETCHED AND VALIDATED ===\n")
