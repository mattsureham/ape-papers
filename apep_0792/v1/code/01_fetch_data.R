## 01_fetch_data.R — Fetch Colombia trade data from WITS and World Bank
source("00_packages.R")

cat("=== Fetching Trade Data from WITS ===\n")

## ---- 1. Colombia exports to Venezuela by sector group ----
years <- 2000:2022
partners <- c("VEN", "WLD", "USA", "CHN", "BRA", "ECU", "MEX")
partner_labels <- c("Venezuela", "World", "USA", "China", "Brazil", "Ecuador", "Mexico")

all_trade <- list()

for (i in seq_along(partners)) {
  prt <- partners[i]
  cat("Fetching Colombia →", partner_labels[i], "\n")

  for (yr in years) {
    url <- paste0(
      "https://wits.worldbank.org/API/V1/SDMX/V21/datasource/tradestats-trade/",
      "reporter/COL/year/", yr,
      "/partner/", prt,
      "/product/All/indicator/XPRT-TRD-VL"
    )

    resp <- tryCatch({
      Sys.sleep(0.5)
      httr::GET(url, httr::timeout(60))
    }, error = function(e) NULL)

    if (is.null(resp) || httr::status_code(resp) != 200) next

    xml_text <- httr::content(resp, as = "text", encoding = "UTF-8")

    ## Extract PRODUCTCODE and OBS_VALUE pairs from XML
    product_matches <- regmatches(xml_text,
      gregexpr('PRODUCTCODE="([^"]*)"[^/]*OBS_VALUE="([^"]*)"', xml_text))[[1]]

    if (length(product_matches) == 0) next

    for (m in product_matches) {
      pcode <- sub('.*PRODUCTCODE="([^"]*)".*', '\\1', m)
      val <- as.numeric(sub('.*OBS_VALUE="([^"]*)".*', '\\1', m))
      all_trade[[length(all_trade) + 1]] <- data.table(
        year = yr, partner = prt, partner_name = partner_labels[i],
        sector = pcode, export_value_1000usd = val
      )
    }
  }
  cat("  Done:", partner_labels[i], "\n")
}

if (length(all_trade) == 0) {
  stop("FATAL: No trade data fetched")
}

trade_dt <- rbindlist(all_trade)
cat("Total trade records:", nrow(trade_dt), "\n")
cat("Years:", range(trade_dt$year), "\n")
cat("Partners:", paste(unique(trade_dt$partner), collapse = ", "), "\n")
cat("Sectors:", uniqueN(trade_dt$sector), "\n")

fwrite(trade_dt, "../data/wits_trade.csv")
cat("Saved wits_trade.csv\n")

## ---- 2. World Bank: Colombia macro outcomes ----
cat("\n=== Fetching World Bank Data ===\n")

wb_indicators <- c(
  "NY.GDP.MKTP.CD",        # GDP
  "NV.IND.MANF.ZS",        # Manufacturing % GDP
  "SL.UEM.TOTL.ZS",        # Unemployment %
  "SL.IND.EMPL.ZS",        # Industry employment %
  "SL.SRV.EMPL.ZS",        # Services employment %
  "SL.AGR.EMPL.ZS",        # Agriculture employment %
  "NE.EXP.GNFS.ZS",        # Exports % GDP
  "NV.IND.MANF.CD",        # Manufacturing VA current USD
  "NV.IND.TOTL.CD",        # Industry VA current USD
  "SP.POP.TOTL",           # Population
  "FP.CPI.TOTL.ZG"         # Inflation CPI
)

## Also fetch for Venezuela and comparator countries (Ecuador, Peru, Chile)
countries <- c("COL", "VEN", "ECU", "PER", "CHL", "BRA", "MEX")

all_wb <- list()
for (ind in wb_indicators) {
  for (cty in countries) {
    url <- paste0(
      "https://api.worldbank.org/v2/country/", cty, "/indicator/", ind,
      "?format=json&per_page=50&date=2000:2022"
    )

    resp <- tryCatch({
      Sys.sleep(0.15)
      httr::GET(url, httr::timeout(30))
    }, error = function(e) NULL)

    if (!is.null(resp) && httr::status_code(resp) == 200) {
      json <- httr::content(resp, as = "text", encoding = "UTF-8")
      parsed <- jsonlite::fromJSON(json)
      if (length(parsed) >= 2 && !is.null(parsed[[2]])) {
        df <- as.data.table(parsed[[2]])
        df$indicator_id <- ind
        df$country_code <- cty
        all_wb[[length(all_wb) + 1]] <- df
      }
    }
  }
}

if (length(all_wb) > 0) {
  wb_dt <- rbindlist(all_wb, fill = TRUE)
  fwrite(wb_dt, "../data/wb_macro.csv")
  cat("Saved wb_macro.csv:", nrow(wb_dt), "rows\n")
  cat("Countries:", paste(unique(wb_dt$country_code), collapse = ", "), "\n")
  cat("Indicators:", uniqueN(wb_dt$indicator_id), "\n")
}

cat("\n=== Data fetch complete ===\n")
