## 01_fetch_data.R — Fetch ECB BSI and World Bank data
## apep_0872: Hungary bank levy and credit supply
##
## Data sources:
##   1. ECB SDW — BSI outstanding loans to NFCs (monthly)
##   2. World Bank — Domestic credit to private sector (% GDP, annual)
##   3. ECB SDW — Total bank assets (monthly, for context)

source("00_packages.R")

# ============================================================
# 1. ECB BSI: Outstanding loans to non-financial corporations
# ============================================================
# Series key structure: BSI.M.{CC}.N.A.A20.A.1.U6.0000.Z01.E
#   M = monthly
#   CC = country code (HU, CZ, PL, SK, AT)
#   N = domestic (non-euro area) or national contribution
#   A = all currencies
#   A20 = loans outstanding
#   A.1 = MFIs excl central bank, to domestic
#   U6 = non-financial corporations
#   0000 = all maturities
#   Z01 = outstanding amounts
#   E = EUR

countries <- c("HU", "CZ", "PL", "SK", "AT")
country_names <- c("Hungary", "Czech Republic", "Poland", "Slovakia", "Austria")

# ECB SDW SDMX REST API
# We fetch total outstanding amounts of loans to NFCs
# Key: BSI.M.{CC}.N.A.A20.A.1.U6.0000.Z01.E
fetch_ecb_bsi <- function(cc) {
  # Try different BSI key patterns
  # Pattern 1: National data with all currencies
  keys <- c(
    sprintf("BSI.M.%s.N.A.A20.A.1.U6.0000.Z01.E", cc),
    sprintf("BSI.M.%s.N.A.L20.A.1.U6.0000.Z01.E", cc),  # L20 = loans
    sprintf("BSI.M.%s.N.A.A20.A.1.U6.2240.Z01.E", cc)    # 2240 = up to 5yr + over 5yr
  )

  for (key in keys) {
    url <- sprintf(
      "https://data-api.ecb.europa.eu/service/data/%s?format=csvdata&startPeriod=2003-01&endPeriod=2020-12",
      key
    )
    cat(sprintf("  Trying %s for %s...\n", key, cc))

    resp <- tryCatch(
      httr::GET(url, httr::timeout(30)),
      error = function(e) NULL
    )

    if (!is.null(resp) && httr::status_code(resp) == 200) {
      txt <- httr::content(resp, "text", encoding = "UTF-8")
      if (nchar(txt) > 100) {
        df <- read.csv(text = txt, stringsAsFactors = FALSE)
        if (nrow(df) > 0 && "OBS_VALUE" %in% names(df)) {
          cat(sprintf("  SUCCESS: %d obs for %s\n", nrow(df), cc))
          return(df)
        }
      }
    }
  }

  # If specific keys fail, try a broader query
  url <- sprintf(
    "https://data-api.ecb.europa.eu/service/data/BSI/M.%s.N.A..A.1.U6.0000.Z01.E?format=csvdata&startPeriod=2003-01&endPeriod=2020-12",
    cc
  )
  cat(sprintf("  Trying broad query for %s...\n", cc))
  resp <- tryCatch(httr::GET(url, httr::timeout(30)), error = function(e) NULL)

  if (!is.null(resp) && httr::status_code(resp) == 200) {
    txt <- httr::content(resp, "text", encoding = "UTF-8")
    if (nchar(txt) > 100) {
      df <- read.csv(text = txt, stringsAsFactors = FALSE)
      if (nrow(df) > 0 && "OBS_VALUE" %in% names(df)) {
        cat(sprintf("  SUCCESS (broad): %d obs for %s\n", nrow(df), cc))
        return(df)
      }
    }
  }

  stop(sprintf("FATAL: No ECB BSI data found for %s. Cannot proceed with simulated data.", cc))
}

cat("Fetching ECB BSI NFC loan data...\n")
bsi_raw <- list()
for (i in seq_along(countries)) {
  cat(sprintf("\nFetching %s (%s)...\n", country_names[i], countries[i]))
  bsi_raw[[countries[i]]] <- fetch_ecb_bsi(countries[i])
}

# Parse and combine
parse_ecb <- function(df, cc) {
  # ECB CSV has TIME_PERIOD (YYYY-MM) and OBS_VALUE
  out <- data.frame(
    country = cc,
    date = as.Date(paste0(df$TIME_PERIOD, "-01")),
    nfc_loans = as.numeric(df$OBS_VALUE),
    stringsAsFactors = FALSE
  )
  out <- out[!is.na(out$nfc_loans) & !is.na(out$date), ]
  return(out)
}

bsi_list <- lapply(countries, function(cc) parse_ecb(bsi_raw[[cc]], cc))
bsi <- do.call(rbind, bsi_list)
bsi <- bsi[order(bsi$country, bsi$date), ]

cat(sprintf("\nBSI panel: %d obs, %d countries, %s to %s\n",
            nrow(bsi), length(unique(bsi$country)),
            min(bsi$date), max(bsi$date)))

# Validate: each country should have substantial time series
for (cc in countries) {
  n <- sum(bsi$country == cc)
  if (n < 60) stop(sprintf("FATAL: Only %d months for %s, need at least 60", n, cc))
  cat(sprintf("  %s: %d months\n", cc, n))
}

# ============================================================
# 2. World Bank: Domestic credit to private sector (% GDP)
# ============================================================
cat("\nFetching World Bank credit/GDP data...\n")

wb_codes <- c("HUN", "CZE", "POL", "SVK", "AUT")
wb_cc_map <- setNames(countries, wb_codes)

fetch_wb_credit <- function() {
  # indicator: FS.AST.PRVT.GD.ZS (domestic credit to private sector, % GDP)
  country_str <- paste(wb_codes, collapse = ";")
  url <- sprintf(
    "https://api.worldbank.org/v2/country/%s/indicator/FS.AST.PRVT.GD.ZS?format=json&per_page=500&date=2000:2023",
    country_str
  )

  resp <- httr::GET(url, httr::timeout(30))
  if (httr::status_code(resp) != 200) {
    stop("FATAL: World Bank API returned non-200 status")
  }

  parsed <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))

  if (length(parsed) < 2 || is.null(parsed[[2]])) {
    stop("FATAL: World Bank API returned no data")
  }

  df <- parsed[[2]]
  out <- data.frame(
    country_wb = df$countryiso3code,
    year = as.integer(df$date),
    credit_gdp = as.numeric(df$value),
    stringsAsFactors = FALSE
  )
  out <- out[!is.na(out$credit_gdp), ]

  # Map to our country codes
  out$country <- wb_cc_map[out$country_wb]
  out <- out[!is.na(out$country), ]

  return(out[, c("country", "year", "credit_gdp")])
}

wb <- fetch_wb_credit()
cat(sprintf("World Bank panel: %d obs, %d countries, %d-%d\n",
            nrow(wb), length(unique(wb$country)),
            min(wb$year), max(wb$year)))

for (cc in countries) {
  n <- sum(wb$country == cc)
  cat(sprintf("  %s: %d years\n", cc, n))
}

# ============================================================
# 3. Save
# ============================================================
saveRDS(bsi, "../data/bsi_nfc_loans.rds")
saveRDS(wb, "../data/wb_credit_gdp.rds")

cat("\nData saved to data/\n")
cat("DONE: 01_fetch_data.R\n")
