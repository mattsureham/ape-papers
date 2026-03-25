# 01_fetch_data.R — Fetch Eurostat HICP and EECC transposition dates
# apep_0946: EECC transposition and consumer telecom prices

source("00_packages.R")

# ===========================================================================
# 1. EECC Transposition Dates (hard-coded from verified EU sources)
# Sources: EU Official Journal, Commission infringement proceedings,
#          Squire Patton Boggs EECC tracker, EUR-Lex
# ===========================================================================

# Transposition year = year the EECC was formally transposed into national law
# Directive 2018/1972, deadline: 21 December 2020
eecc_transposition <- data.table(
  geo = c("DK", "EL", "HU",          # Dec 2020 (on-time)
          "FI", "BG", "FR", "CZ",     # 2021
          "AT", "DE", "LU", "MT",     # 2021
          "BE", "EE", "CY", "NL",     # 2022
          "ES", "SE", "HR", "LV",     # 2022
          "RO", "PT", "SI",           # 2022
          "IE",                        # 2023
          "PL",                        # 2024 (never-treated in sample)
          "LT",                        # 2025 (never-treated in sample)
          "IT",                        # 2025 (never-treated in sample)
          "SK"),                       # 2025 (never-treated in sample)
  transposition_year = c(
    2020, 2020, 2020,   # On-time cohort
    2021, 2021, 2021, 2021,  # 2021 cohort
    2021, 2021, 2021, 2021,  # 2021 cohort (cont.)
    2022, 2022, 2022, 2022,  # 2022 cohort
    2022, 2022, 2022, 2022,  # 2022 cohort (cont.)
    2022, 2022, 2022,        # 2022 cohort (cont.)
    2023,                     # 2023 cohort
    NA_real_,                 # PL: Jul 2024 (post-sample)
    NA_real_,                 # LT: Jan 2025 (post-sample)
    NA_real_,                 # IT: Apr 2025 (post-sample)
    NA_real_)                 # SK: Jun 2025 (post-sample)
)

# Add non-EU countries as never-treated controls
non_eu_controls <- data.table(
  geo = c("NO", "CH"),
  transposition_year = c(NA_real_, NA_real_)
)

eecc_transposition <- rbind(eecc_transposition, non_eu_controls)

cat("EECC transposition dates:\n")
print(eecc_transposition[order(transposition_year, geo)])

# ===========================================================================
# 2. Fetch Eurostat HICP data
# ===========================================================================

cat("\nFetching Eurostat HICP data...\n")

# Main outcome: CP08 (Communications)
# Placebo outcomes: CP011 (Food), CP07 (Transport), CP04 (Housing)
coicop_codes <- c("CP08", "CP011", "CP07", "CP04")

# Fetch via direct Eurostat JSON API (avoids eurostat package filter issues)
our_countries <- eecc_transposition$geo

fetch_hicp_direct <- function(coicop_code, countries, years = 2014:2024) {
  # Use Eurostat JSON API directly — repeated &geo= params
  geo_str <- paste0("geo=", countries, collapse = "&")
  base_url <- "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/prc_hicp_aind"
  url <- paste0(base_url, "?unit=INX_A_AVG&coicop=", coicop_code,
                "&", geo_str,
                "&sinceTimePeriod=2014&untilTimePeriod=2024&lang=en")
  resp <- httr2::request(url) |>
    httr2::req_headers(Accept = "application/json") |>
    httr2::req_perform()
  json <- httr2::resp_body_json(resp)

  # Parse JSON-stat format
  geo_labels <- names(json$dimension$geo$category$index)
  time_labels <- names(json$dimension$time$category$index)

  n_geo <- length(geo_labels)
  n_time <- length(time_labels)

  if (n_geo == 0 || n_time == 0) {
    stop("No data returned for ", coicop_code)
  }

  # Build data.table from sparse JSON-stat values (0-indexed keys)
  results <- list()
  for (nm in names(json$value)) {
    idx <- as.integer(nm)
    geo_idx <- idx %/% n_time
    time_idx <- idx %% n_time
    results[[length(results) + 1]] <- data.table(
      geo = geo_labels[geo_idx + 1],
      year = as.integer(time_labels[time_idx + 1]),
      coicop_cat = coicop_code,
      values = as.numeric(json$value[[nm]])
    )
  }
  rbindlist(results)
}

hicp_list <- lapply(coicop_codes, function(cc) {
  cat("  Fetching", cc, "...\n")
  tryCatch(
    fetch_hicp_direct(cc, our_countries),
    error = function(e) {
      stop("Failed to fetch ", cc, ": ", e$message)
    }
  )
})
hicp <- rbindlist(hicp_list)

cat("HICP observations by COICOP:\n")
print(hicp[, .N, by = .(coicop_cat)])

cat("\nCountries with CP08 data:\n")
cp08_countries <- unique(hicp[coicop_cat == "CP08", geo])
print(sort(cp08_countries))

# Check which countries are missing
missing <- setdiff(our_countries, cp08_countries)
if (length(missing) > 0) {
  cat("\nWARNING: Countries missing CP08 data:", paste(missing, collapse = ", "), "\n")
}

# ===========================================================================
# 3. Fetch World Bank broadband data (secondary outcome)
# ===========================================================================

cat("\nFetching World Bank broadband subscriptions...\n")

# Map Eurostat geo codes to ISO2 for WDI
iso2_map <- data.table(
  geo = c("AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR",
          "DE","EL","HU","IE","IT","LV","LT","LU","MT","NL",
          "PL","PT","RO","SK","SI","ES","SE","NO","CH"),
  iso2c = c("AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR",
            "DE","GR","HU","IE","IT","LV","LT","LU","MT","NL",
            "PL","PT","RO","SK","SI","ES","SE","NO","CH")
)

broadband <- WDI(indicator = "IT.NET.BBND.P2",
                 country = iso2_map$iso2c,
                 start = 2014, end = 2024,
                 extra = FALSE)
broadband <- as.data.table(broadband)
broadband <- broadband[!is.na(IT.NET.BBND.P2)]

# Map back to Eurostat geo codes
broadband <- merge(broadband, iso2_map, by = "iso2c")

cat("Broadband observations:", nrow(broadband), "\n")

# ===========================================================================
# 4. Save all raw data
# ===========================================================================

fwrite(hicp, "../data/hicp_raw.csv")
fwrite(eecc_transposition, "../data/eecc_transposition.csv")
fwrite(broadband, "../data/broadband_raw.csv")

cat("\nAll data saved to data/\n")
cat("HICP total obs:", nrow(hicp), "\n")
cat("Countries:", length(unique(hicp$geo)), "\n")
cat("Years:", paste(range(hicp$year), collapse = "-"), "\n")
