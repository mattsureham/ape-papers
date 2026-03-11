## =============================================================================
## 01_fetch_data.R — Fetch all data for Nigeria fuel subsidy analysis
## Paper: From Pumps to Plates — Geographic Pass-Through of Nigeria's
##        2023 Fuel Subsidy Removal
## =============================================================================

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ---------------------------------------------------------------------------
## 1. Petroleum import terminal coordinates (NNPC/PPMC infrastructure)
## ---------------------------------------------------------------------------

terminals <- tribble(
  ~terminal, ~lat, ~lon,
  "Lagos/Apapa", 6.4400, 3.3700,
  "Port Harcourt", 4.7600, 7.0100,
  "Warri", 5.5167, 5.7500
)

fwrite(terminals, file.path(data_dir, "terminals.csv"))

## ---------------------------------------------------------------------------
## 2. World Bank Real Time Energy Prices (RTEP) — market-level petrol prices
##    Source: HDX / World Bank Development Economics Data Group
##    Coverage: 65 markets, 15 states, 2007–2025, monthly
## ---------------------------------------------------------------------------

cat("=== Fetching World Bank RTEP (market-level energy prices) ===\n")

rtep_url <- "https://data.humdata.org/dataset/73009422-8e57-41a4-ad24-d77f9405accb/resource/a8dbee76-02d2-443e-91d1-a3978826bafd/download/real-time-energy-prices-for-nigeria.csv"
rtep_file <- file.path(data_dir, "rtep_nigeria.csv")

tryCatch({
  download.file(rtep_url, rtep_file, mode = "wb", quiet = FALSE)
  cat("RTEP data downloaded successfully.\n")
}, error = function(e) {
  stop("RTEP data unavailable: ", e$message,
       "\nThis is the primary data source. Cannot proceed without it.",
       "\nURL: ", rtep_url)
})

rtep <- fread(rtep_file)
cat("RTEP rows:", nrow(rtep), "\n")
cat("RTEP columns:", paste(names(rtep)[1:20], collapse = ", "), "...\n")

# Filter to analysis period and actual markets (exclude "Market Average")
rtep <- rtep[adm1_name != "Market Average"]

# Create date variable
rtep[, date := as.Date(paste0(year, "-", sprintf("%02d", month), "-01"))]

# Compute distance from each market to nearest terminal
market_coords <- unique(rtep[, .(mkt_name, adm1_name, lat, lon)])
terminal_coords <- as.matrix(terminals[, c("lon", "lat")])
market_mat <- as.matrix(market_coords[, .(lon, lat)])

dist_matrix <- geodist::geodist(
  x = market_mat,
  y = terminal_coords,
  measure = "haversine"
) / 1000  # km

market_coords[, dist_lagos := dist_matrix[, 1]]
market_coords[, dist_ph := dist_matrix[, 2]]
market_coords[, dist_warri := dist_matrix[, 3]]
market_coords[, dist_nearest := apply(dist_matrix, 1, min)]
market_coords[, nearest_terminal := terminals$terminal[apply(dist_matrix, 1, which.min)]]

cat("Market distance range:", round(min(market_coords$dist_nearest)),
    "km to", round(max(market_coords$dist_nearest)), "km\n")

# Merge distances into RTEP panel
rtep <- merge(rtep, market_coords[, .(mkt_name, dist_nearest, nearest_terminal)],
              by = "mkt_name", all.x = TRUE)

# Create analysis variables
rtep[, post := as.integer(date >= as.Date("2023-06-01"))]
rtep[, log_petrol := log(o_fuel_petrol_gasoline)]
rtep[, log_diesel := log(o_fuel_diesel)]
rtep[, log_kerosene := log(o_fuel_kerosene)]
rtep[, dist_post := dist_nearest * post]
rtep[, month_id := as.integer(factor(date))]
rtep[, market_id := as.integer(factor(mkt_name))]

# Filter to analysis window: Jan 2021 – Dec 2024
rtep_analysis <- rtep[date >= as.Date("2021-01-01") & date <= as.Date("2024-12-31")]

cat("RTEP analysis panel:\n")
cat("  Markets:", n_distinct(rtep_analysis$mkt_name), "\n")
cat("  States:", n_distinct(rtep_analysis$adm1_name), "\n")
cat("  Months:", n_distinct(rtep_analysis$date), "\n")
cat("  Observations:", nrow(rtep_analysis), "\n")

fwrite(rtep_analysis, file.path(data_dir, "rtep_analysis.csv"))
fwrite(market_coords, file.path(data_dir, "market_distances.csv"))

## ---------------------------------------------------------------------------
## 3. WFP Food Prices — market-level food and fuel prices
##    Source: HDX / World Food Programme VAM
##    Coverage: 68 markets, 14 states, 43 commodities, 2002–2026
## ---------------------------------------------------------------------------

cat("\n=== Fetching WFP food prices ===\n")

wfp_url <- "https://data.humdata.org/dataset/42db041f-7aaf-4ab4-961f-2a12096861e7/resource/12b51155-0cd3-4806-9924-61ede4077591/download/wfp_food_prices_nga.csv"
wfp_file <- file.path(data_dir, "wfp_food_prices.csv")

tryCatch({
  download.file(wfp_url, wfp_file, mode = "wb", quiet = FALSE)
  cat("WFP food prices downloaded successfully.\n")
}, error = function(e) {
  stop("WFP food price data unavailable: ", e$message,
       "\nThis is required for the food price pass-through analysis.",
       "\nURL: ", wfp_url)
})

wfp <- fread(wfp_file)
cat("WFP rows:", nrow(wfp), "\n")
cat("Commodities:", n_distinct(wfp$commodity), "\n")

# Compute distances for WFP markets
wfp_markets <- unique(wfp[!is.na(latitude) & !is.na(longitude),
                           .(market, admin1, latitude, longitude)])
wfp_mat <- as.matrix(wfp_markets[, .(longitude, latitude)])
wfp_dist <- geodist::geodist(x = wfp_mat, y = terminal_coords, measure = "haversine") / 1000

wfp_markets[, dist_nearest := apply(wfp_dist, 1, min)]
wfp_markets[, nearest_terminal := terminals$terminal[apply(wfp_dist, 1, which.min)]]

# Merge distances
wfp <- merge(wfp, wfp_markets[, .(market, dist_nearest, nearest_terminal)],
             by = "market", all.x = TRUE)

# Create analysis variables
wfp[, date := as.Date(date)]
wfp[, year := year(date)]
wfp[, month := month(date)]
wfp[, post := as.integer(date >= as.Date("2023-06-01"))]
wfp[, log_price := log(price)]
wfp[, dist_post := dist_nearest * post]
wfp[, market_commodity := paste0(market, "_", commodity)]

# Classify commodities by transport cost sensitivity
# High transport cost: perishable, bulky (rice, maize, cassava, beans)
# Low transport cost: processed, lightweight, high-value (oil, sugar)
wfp[, transport_intensive := as.integer(
  commodity %in% c("Maize", "Maize (white)", "Maize (yellow)", "Maize flour",
                    "Rice", "Rice (imported)", "Rice (local)",
                    "Cassava meal (gari, yellow)", "Gari (white)",
                    "Beans (niebe)", "Beans (red)", "Beans (white)",
                    "Cowpeas", "Cowpeas (brown)", "Cowpeas (white)",
                    "Sorghum", "Millet", "Yam")
)]

# Filter to analysis window
wfp_analysis <- wfp[date >= as.Date("2021-01-01") & date <= as.Date("2024-12-31")]

cat("WFP analysis panel:\n")
cat("  Markets:", n_distinct(wfp_analysis$market), "\n")
cat("  States:", n_distinct(wfp_analysis$admin1), "\n")
cat("  Commodities:", n_distinct(wfp_analysis$commodity), "\n")
cat("  Observations:", nrow(wfp_analysis), "\n")

fwrite(wfp_analysis, file.path(data_dir, "wfp_analysis.csv"))

## ---------------------------------------------------------------------------
## 4. WFP Markets — coordinates for all monitored markets
## ---------------------------------------------------------------------------

cat("\n=== Fetching WFP market locations ===\n")

wfp_mkt_url <- "https://data.humdata.org/dataset/42db041f-7aaf-4ab4-961f-2a12096861e7/resource/5329e772-0b74-4f65-8cc0-37a0915cc7e4/download/wfp_markets_nga.csv"
wfp_mkt_file <- file.path(data_dir, "wfp_markets.csv")

tryCatch({
  download.file(wfp_mkt_url, wfp_mkt_file, mode = "wb", quiet = FALSE)
  cat("WFP markets data downloaded.\n")
}, error = function(e) {
  cat("WFP markets file unavailable:", e$message, "\n")
})

## ---------------------------------------------------------------------------
## 5. ACLED conflict events for Nigeria
##    Source: Armed Conflict Location & Event Data Project
## ---------------------------------------------------------------------------

cat("\n=== Fetching ACLED conflict data ===\n")

acled_email <- Sys.getenv("ACLED_EMAIL")
acled_key <- Sys.getenv("ACLED_PASSWORD")

acled_data <- NULL

if (acled_email != "" && acled_key != "") {
  # Try ACLED API (legacy key-based auth)
  acled_url <- paste0(
    "https://api.acleddata.com/acled/read?",
    "key=", acled_key,
    "&email=", acled_email,
    "&country=Nigeria",
    "&event_date=2021-01-01|2024-12-31",
    "&event_date_where=BETWEEN",
    "&limit=0"
  )

  tryCatch({
    resp <- httr::GET(acled_url, httr::timeout(120))
    if (httr::status_code(resp) == 200) {
      parsed <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
      if (!is.null(parsed$data) && length(parsed$data) > 0) {
        acled_data <- as.data.table(parsed$data)
        cat("ACLED data fetched:", nrow(acled_data), "events\n")
      }
    } else {
      cat("ACLED API status:", httr::status_code(resp), "\n")
    }
  }, error = function(e) {
    cat("ACLED API error:", e$message, "\n")
  })

  # If legacy fails, try newer API format
  if (is.null(acled_data)) {
    acled_url2 <- paste0(
      "https://api.acleddata.com/acled/read?",
      "key=", acled_key,
      "&email=", acled_email,
      "&iso=566",
      "&event_date=2021-01-01|2024-12-31",
      "&event_date_where=BETWEEN",
      "&limit=0"
    )
    tryCatch({
      resp <- httr::GET(acled_url2, httr::timeout(120))
      if (httr::status_code(resp) == 200) {
        parsed <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
        if (!is.null(parsed$data) && length(parsed$data) > 0) {
          acled_data <- as.data.table(parsed$data)
          cat("ACLED v2 data fetched:", nrow(acled_data), "events\n")
        }
      }
    }, error = function(e) {
      cat("ACLED v2 failed:", e$message, "\n")
    })
  }
}

if (!is.null(acled_data) && nrow(acled_data) > 0) {
  fwrite(acled_data, file.path(data_dir, "acled_nigeria.csv"))
  cat("ACLED events by type:\n")
  print(table(acled_data$event_type))
} else {
  cat("ACLED data unavailable. Protest analysis will be excluded.\n")
  cat("Paper proceeds with fuel and food price panels only.\n")
}

## ---------------------------------------------------------------------------
## 6. World Bank development indicators for Nigeria (context)
## ---------------------------------------------------------------------------

cat("\n=== Fetching World Bank indicators ===\n")

wb_indicators <- c(
  "SP.POP.TOTL" = "population",
  "NY.GDP.PCAP.CD" = "gdp_pc",
  "FP.CPI.TOTL.ZG" = "cpi_inflation",
  "SL.UEM.TOTL.ZS" = "unemployment"
)

wb_list <- list()
for (ind in names(wb_indicators)) {
  url <- paste0(
    "https://api.worldbank.org/v2/country/NGA/indicator/", ind,
    "?format=json&date=2015:2025&per_page=100"
  )
  tryCatch({
    resp <- httr::GET(url, httr::timeout(15))
    if (httr::status_code(resp) == 200) {
      parsed <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
      if (length(parsed) >= 2 && !is.null(parsed[[2]])) {
        wb_list[[ind]] <- data.table(
          indicator = wb_indicators[ind],
          year = as.integer(parsed[[2]]$date),
          value = as.numeric(parsed[[2]]$value)
        )
      }
    }
  }, error = function(e) {
    cat("WB", ind, "failed:", e$message, "\n")
  })
}

if (length(wb_list) > 0) {
  wb_all <- rbindlist(wb_list)
  fwrite(wb_all, file.path(data_dir, "wb_indicators.csv"))
  cat("World Bank indicators:", nrow(wb_all), "observations\n")
}

## ---------------------------------------------------------------------------
## DATA VALIDATION (required)
## ---------------------------------------------------------------------------

# RTEP validation
stopifnot("RTEP: Expected 10+ markets" = n_distinct(rtep_analysis$mkt_name) >= 10)
stopifnot("RTEP: Expected 36+ months" = n_distinct(rtep_analysis$date) >= 36)
stopifnot("RTEP: Petrol prices exist" = sum(!is.na(rtep_analysis$o_fuel_petrol_gasoline)) > 1000)
stopifnot("RTEP: Distances computed" = !any(is.na(rtep_analysis$dist_nearest)))

# WFP validation
stopifnot("WFP: Expected 10+ markets" = n_distinct(wfp_analysis$market) >= 10)
stopifnot("WFP: Expected 20+ commodities" = n_distinct(wfp_analysis$commodity) >= 20)
stopifnot("WFP: Food prices exist" = sum(!is.na(wfp_analysis$price)) > 5000)

cat("\n=== DATA VALIDATION PASSED ===\n")
cat("RTEP: ", nrow(rtep_analysis), " obs, ",
    n_distinct(rtep_analysis$mkt_name), " markets, ",
    n_distinct(rtep_analysis$adm1_name), " states\n", sep = "")
cat("WFP:  ", nrow(wfp_analysis), " obs, ",
    n_distinct(wfp_analysis$market), " markets, ",
    n_distinct(wfp_analysis$commodity), " commodities\n", sep = "")
cat("Distance range: ", round(min(market_coords$dist_nearest)), " to ",
    round(max(market_coords$dist_nearest)), " km\n", sep = "")
