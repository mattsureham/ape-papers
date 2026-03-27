# 01b_fetch_stocks.R — Fetch daily data for a sample of TWSE stocks
# The STOCK_DAY endpoint returns monthly data for individual stocks
# We fetch data for ~50 representative stocks across size quintiles
# apep_1037

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# Helper
# ============================================================================

fetch_twse <- function(url, pause = 3) {
  Sys.sleep(pause)
  resp <- tryCatch(
    httr::GET(url, httr::timeout(30)),
    error = function(e) { cat("HTTP err\n"); return(NULL) }
  )
  if (is.null(resp) || httr::status_code(resp) != 200) return(NULL)
  content <- httr::content(resp, as = "text", encoding = "UTF-8")
  tryCatch(jsonlite::fromJSON(content), error = function(e) NULL)
}

# ============================================================================
# Select representative stocks
# Pick ~50 stocks: top 10 by market cap + random sample across sectors
# These are well-known TWSE-listed firms with continuous trading 2010-2018
# ============================================================================

# Major TWSE stocks (selected for continuous listing 2010-2018)
sample_stocks <- c(
  # Top 10 blue chips (large cap, institutional)
  "2330",  # TSMC
  "2317",  # Hon Hai / Foxconn
  "2412",  # Chunghwa Telecom
  "2454",  # MediaTek
  "1301",  # Formosa Plastics
  "1303",  # Nan Ya Plastics
  "2882",  # Cathay Financial
  "2881",  # Fubon Financial
  "2308",  # Delta Electronics
  "1326",  # Formosa Chemicals
  # Mid-cap stocks
  "2357",  # Asustek
  "2382",  # Quanta
  "3008",  # Largan Precision
  "2912",  # President Chain Store
  "2474",  # Catcher Technology
  "2105",  # Cheng Shin Rubber
  "5880",  # Yuanta Financial
  "2891",  # CTBC Financial
  "1402",  # Far Eastern
  "2207",  # Hotai Motor
  # Small/mid-cap stocks (more retail-dominated)
  "2409",  # AU Optronics
  "3481",  # Innolux
  "2610",  # China Airlines
  "2603",  # EVA Airways
  "2609",  # Yang Ming Marine
  "2377",  # Micro-Star
  "2301",  # Lite-On Technology
  "2344",  # Winbond
  "2337",  # Macronix
  "6239",  # Powertech
  # Small caps
  "3034",  # Novatek
  "2498",  # HTC
  "3443",  # Transcend
  "3231",  # Wistron NeWeb
  "6271",  # Brogent Technologies
  "2449",  # Kyec
  "2376",  # Gigabyte
  "2356",  # Inventec
  "3702",  # WPG Holdings
  "2324",  # Compal
  # Additional diverse stocks
  "2002",  # China Steel
  "9910",  # Feng Hsin Steel
  "2801",  # Chang Hwa Bank
  "2880",  # Hua Nan Financial
  "1216",  # Uni-President
  "1101",  # Taiwan Cement
  "1102",  # Asia Cement
  "2892",  # First Financial
  "2884",  # E.SUN Financial
  "2886"   # Mega Financial
)

cat("Fetching daily data for", length(sample_stocks), "stocks\n")
cat("Period: 2010-01 to 2018-12 (108 months per stock)\n")
cat("Total API calls:", length(sample_stocks) * 108, "\n\n")

# ============================================================================
# Fetch STOCK_DAY for each stock × month
# ============================================================================

all_data <- list()
failed_stocks <- c()

for (stk in sample_stocks) {
  cat(sprintf("Stock %s: ", stk))
  stock_data <- list()

  for (yr in 2010:2018) {
    for (mo in 1:12) {
      date_str <- sprintf("%d%02d01", yr, mo)
      url <- paste0("https://www.twse.com.tw/exchangeReport/STOCK_DAY?response=json&date=",
                     date_str, "&stockNo=", stk)
      result <- fetch_twse(url, pause = 3)

      if (!is.null(result) && result$stat == "OK" && !is.null(result$data)) {
        mat <- result$data
        if (is.matrix(mat) && nrow(mat) > 0) {
          df <- data.frame(
            date_roc = mat[, 1],  # ROC calendar date
            volume_shares = mat[, 2],
            value_twd = mat[, 3],
            open = mat[, 4],
            high = mat[, 5],
            low = mat[, 6],
            close = mat[, 7],
            change = mat[, 8],
            n_transactions = mat[, 9],
            stringsAsFactors = FALSE
          )
          df$stock_code <- stk
          df$year <- yr
          df$month <- mo
          stock_data[[length(stock_data) + 1]] <- df
        }
      }
    }
    cat(".")
  }

  if (length(stock_data) > 0) {
    combined <- bind_rows(stock_data)
    all_data[[stk]] <- combined
    cat(sprintf(" %d daily obs\n", nrow(combined)))
  } else {
    failed_stocks <- c(failed_stocks, stk)
    cat(" FAILED\n")
  }
}

if (length(all_data) == 0) {
  stop("FATAL: No stock data retrieved from STOCK_DAY endpoint")
}

stock_daily <- bind_rows(all_data)
cat("\n=== STOCK FETCH SUMMARY ===\n")
cat("Total daily observations:", nrow(stock_daily), "\n")
cat("Stocks fetched:", n_distinct(stock_daily$stock_code), "\n")
cat("Failed stocks:", length(failed_stocks), "\n")
if (length(failed_stocks) > 0) cat("  ", paste(failed_stocks, collapse = ", "), "\n")

saveRDS(stock_daily, file.path(data_dir, "stock_daily_sample.rds"))
cat("Saved to:", file.path(data_dir, "stock_daily_sample.rds"), "\n")
