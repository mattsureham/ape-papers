## ============================================================
## 01_fetch_data.R — Fetch DFM stock data + GCC index data
## The Cost of Sponsorship: Kafala Reform and Firm Value
## ============================================================

source(file.path(dirname(normalizePath(sys.frame(1)$ofile)), "00_packages.R"))

## ---------------------------------------------------------------
## 1. DFM (Dubai Financial Market) listed firms
## ---------------------------------------------------------------
## Yahoo Finance uses .AE suffix for DFM stocks
## We include all major DFM-listed equities with pre-2022 data

dfm_tickers <- tribble(
  ~ticker, ~name, ~sector,
  # Banking
  "EMIRATESNBD.AE", "Emirates NBD", "Banking",
  "DIB.AE", "Dubai Islamic Bank", "Banking",
  "CBD.AE", "Commercial Bank of Dubai", "Banking",
  "AJMANBANK.AE", "Ajman Bank", "Banking",
  "EIBANK.AE", "Emirates Investment Bank", "Banking",
  # Insurance
  "SALAMA.AE", "Salama Islamic Insurance", "Insurance",
  "SUKOON.AE", "Sukoon Insurance", "Insurance",
  "SUKOONTAKAFL.AE", "Sukoon Takaful", "Insurance",
  "WATANIA.AE", "Al Watania International", "Insurance",
  "AMAN.AE", "Aman Insurance", "Insurance",
  # Telecom
  "DU.AE", "du (Emirates Integrated Telecom)", "Telecom",
  # Real Estate & Construction
  "EMAAR.AE", "Emaar Properties", "RealEstate",
  "EMAARDEV.AE", "Emaar Development", "RealEstate",
  "DEYAAR.AE", "Deyaar Development", "RealEstate",
  "DRC.AE", "Dubai Refreshments", "RealEstate",
  "AMLAK.AE", "Amlak Finance", "RealEstate",
  "MASQ.AE", "Mashreqbank", "Banking",
  # Services & Hospitality
  "AIRARABIA.AE", "Air Arabia", "Services",
  "DFM.AE", "Dubai Financial Market", "Financial",
  "GFH.AE", "GFH Financial Group", "Financial",
  # Industrial
  "NIND.AE", "National Industries Group", "Industrial",
  "NCC.AE", "National Cement Company", "Industrial",
  "NGI.AE", "National General Insurance", "Insurance",
  "UPP.AE", "United Foods", "Industrial",
  "UFC.AE", "Union Properties", "RealEstate",
  "UNIKAI.AE", "Unikai Foods", "Industrial",
  "DIN.AE", "Dubai Investments", "Investment",
  "DIC.AE", "Dubai Investment Company", "Investment",
  "TABREED.AE", "Tabreed (National Central Cooling)", "Utilities",
  # Investment / Financial Services
  "SHUAA.AE", "SHUAA Capital", "Financial",
  "AMANAT.AE", "Amanat Holdings", "Investment",
  "ARMX.AE", "Aramex", "Services",
  "IFA.AE", "International Financial Advisors", "Financial",
  "BHMCAPITAL.AE", "BHM Capital", "Financial",
  "ITHMR.AE", "Ithmaar Holding", "Financial",
  "ERC.AE", "Emirates Refreshment", "Industrial",
  "DSI.AE", "Dubai Starr Insurance", "Insurance",
  "ALRAMZ.AE", "Al Ramz Capital", "Financial",
  "MAZAYA.AE", "Mazaya Real Estate", "RealEstate",
  "GULFNAV.AE", "Gulf Navigation", "Services",
  "NAHO.AE", "National Holdings", "Investment",
  "EKTTITAB.AE", "Ekttitab Holding", "Services",
  "DNIR.AE", "Dar Al Takaful", "Insurance",
  "ALFIRDOUS.AE", "Al Firdous Holdings", "Industrial",
  "SALAM_BAH.AE", "Salam International", "Services"
)

cat("Fetching data for", nrow(dfm_tickers), "DFM tickers...\n")

## Fetch period: Jan 2019 to Dec 2024
start_date <- as.Date("2019-01-01")
end_date   <- as.Date("2024-12-31")

## Download all tickers
fetch_stock <- function(ticker, start, end) {
  tryCatch({
    getSymbols(ticker, src = "yahoo", from = start, to = end, auto.assign = FALSE)
  }, error = function(e) {
    message("  FAILED: ", ticker, " — ", e$message)
    NULL
  })
}

stock_list <- list()
for (i in seq_len(nrow(dfm_tickers))) {
  tk <- dfm_tickers$ticker[i]
  cat("  Fetching", tk, "...")
  xts_data <- fetch_stock(tk, start_date, end_date)
  if (!is.null(xts_data) && nrow(xts_data) > 0) {
    df_tmp <- data.frame(
      date   = index(xts_data),
      close  = as.numeric(Cl(xts_data)),
      volume = as.numeric(Vo(xts_data)),
      open   = as.numeric(Op(xts_data)),
      high   = as.numeric(Hi(xts_data)),
      low    = as.numeric(Lo(xts_data))
    )
    df_tmp$ticker <- tk
    stock_list[[tk]] <- df_tmp
    cat(" OK (", nrow(df_tmp), "obs)\n")
  } else {
    cat(" EMPTY\n")
  }
  Sys.sleep(0.5)  # rate limiting
}

dfm_raw <- bind_rows(stock_list)
cat("\nDFM data:", nrow(dfm_raw), "total observations from",
    n_distinct(dfm_raw$ticker), "tickers\n")

## Merge with metadata
dfm_raw <- dfm_raw %>%
  left_join(dfm_tickers, by = "ticker")

## ---------------------------------------------------------------
## 2. GCC Index Data (for placebos) + DFM market index
## ---------------------------------------------------------------

## Compute DFM equal-weighted market return from individual stocks
cat("\nComputing DFM equal-weighted market index...\n")
dfm_mkt_idx <- dfm_raw %>%
  arrange(ticker, date) %>%
  group_by(ticker) %>%
  mutate(ret = (close / lag(close)) - 1) %>%
  filter(!is.na(ret)) %>%
  ungroup() %>%
  group_by(date) %>%
  summarise(
    mkt_close = mean(close, na.rm = TRUE),
    n_stocks = n(),
    .groups = "drop"
  ) %>%
  mutate(market = "UAE_DFM")

## Try multiple GCC tickers (some may work)
gcc_tickers <- tribble(
  ~ticker, ~market,
  "2222.SR", "Saudi_Aramco",     # Saudi Aramco as Saudi proxy
  "1180.SR", "Saudi_AlRajhi",    # Al Rajhi Banking
  "QNBK.QA", "Qatar_QNB"        # QNB Group as Qatar proxy
)

cat("Fetching GCC reference stocks...\n")
idx_list <- list()
for (i in seq_len(nrow(gcc_tickers))) {
  tk <- gcc_tickers$ticker[i]
  cat("  Fetching", tk, "...")
  xts_data <- fetch_stock(tk, start_date, end_date)
  if (!is.null(xts_data) && nrow(xts_data) > 0) {
    df_tmp <- data.frame(
      date  = index(xts_data),
      close = as.numeric(Cl(xts_data))
    )
    df_tmp$market <- gcc_tickers$market[gcc_tickers$ticker == tk]
    idx_list[[tk]] <- df_tmp
    cat(" OK (", nrow(df_tmp), "obs)\n")
  } else {
    cat(" EMPTY\n")
  }
  Sys.sleep(0.5)
}

## Combine DFM index + any GCC data
gcc_idx <- bind_rows(
  dfm_mkt_idx %>% select(date, close = mkt_close, market),
  bind_rows(idx_list)
)
cat("\nGCC/market index data:", nrow(gcc_idx), "obs from",
    n_distinct(gcc_idx$market), "markets\n")

## ---------------------------------------------------------------
## 3. Save raw data
## ---------------------------------------------------------------
write_csv(dfm_raw, file.path(data_dir, "dfm_raw.csv"))
write_csv(gcc_idx, file.path(data_dir, "gcc_indices.csv"))

## ---------------------------------------------------------------
## 4. DATA VALIDATION (required)
## ---------------------------------------------------------------
stopifnot("Expected 30+ DFM tickers" = n_distinct(dfm_raw$ticker) >= 30)
stopifnot("Expected data spanning 2019-2024" =
            min(dfm_raw$date) <= as.Date("2019-06-01") &
            max(dfm_raw$date) >= as.Date("2024-01-01"))
stopifnot("Expected at least 1 market index series" = n_distinct(gcc_idx$market) >= 1)

cat("\n=== DATA VALIDATION PASSED ===\n")
cat("DFM:", nrow(dfm_raw), "rows,", n_distinct(dfm_raw$ticker), "tickers,",
    "date range:", as.character(min(dfm_raw$date)), "to", as.character(max(dfm_raw$date)), "\n")
cat("GCC:", nrow(gcc_idx), "rows,", n_distinct(gcc_idx$market), "markets\n")
