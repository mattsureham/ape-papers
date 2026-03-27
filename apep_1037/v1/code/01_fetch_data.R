# 01_fetch_data.R — Fetch TWSE data for Taiwan CGT analysis
# apep_1037: The Round-Trip Tax
#
# Data sources:
# 1. TWSE daily market index (TAIEX) — aggregate market activity (FMTQIK)
# 2. TWSE all-stock daily reports — per-stock volume, value, price (STOCK_DAY_ALL)
# 3. TWSE institutional investor trading — foreign/trust/dealer flows (T86)
# 4. TWSE P/E and dividend yield by stock (BWIBBU_d)

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# Helper: TWSE API fetcher with rate limiting
# ============================================================================

fetch_twse <- function(url, pause = 3.5) {
  Sys.sleep(pause)
  resp <- tryCatch(
    httr::GET(url, httr::timeout(30)),
    error = function(e) {
      cat("  HTTP error:", conditionMessage(e), "\n")
      return(NULL)
    }
  )
  if (is.null(resp)) return(NULL)
  if (httr::status_code(resp) != 200) {
    cat("  Status:", httr::status_code(resp), "\n")
    return(NULL)
  }
  content <- httr::content(resp, as = "text", encoding = "UTF-8")
  parsed <- tryCatch(jsonlite::fromJSON(content), error = function(e) NULL)
  if (is.null(parsed)) {
    cat("  JSON parse failed\n")
    return(NULL)
  }
  return(parsed)
}

# ============================================================================
# 1. TWSE Market Index (TAIEX) — Monthly summary 2010-2018
# ============================================================================

cat("=== Fetching TAIEX monthly index data ===\n")

taiex_list <- list()
for (yr in 2010:2018) {
  for (mo in 1:12) {
    date_str <- sprintf("%d%02d01", yr, mo)
    url <- paste0("https://www.twse.com.tw/exchangeReport/FMTQIK?response=json&date=", date_str)
    cat(sprintf("  TAIEX %d-%02d... ", yr, mo))
    result <- fetch_twse(url)
    if (!is.null(result) && !is.null(result$data) && length(result$data) > 0) {
      df <- as.data.frame(result$data, stringsAsFactors = FALSE)
      if (ncol(df) >= 5) {
        names(df) <- c("date", "volume_shares", "value_twd", "n_transactions",
                        "taiex_close", "taiex_change")[1:ncol(df)]
        df$year <- yr
        df$month <- mo
        taiex_list[[length(taiex_list) + 1]] <- df
        cat("OK (", nrow(df), "rows)\n")
      } else {
        cat("unexpected columns:", ncol(df), "\n")
      }
    } else {
      cat("no data\n")
    }
  }
}

if (length(taiex_list) == 0) {
  stop("FATAL: No TAIEX data retrieved. Cannot proceed without real market data.")
}

taiex_raw <- bind_rows(taiex_list)
cat("TAIEX raw rows:", nrow(taiex_raw), "\n")
saveRDS(taiex_raw, file.path(data_dir, "taiex_monthly_raw.rds"))

# ============================================================================
# 2. TWSE All-Stock Daily Reports (STOCK_DAY_ALL)
# One trading day per month for all listed stocks
# ============================================================================

cat("\n=== Fetching per-stock data (STOCK_DAY_ALL) ===\n")

stock_list <- list()

# Sample one trading day per month (15th is mid-month, avoids month-end effects)
for (yr in 2010:2018) {
  for (mo in 1:12) {
    # Try 15th first, then nearby dates if it's a holiday
    success <- FALSE
    for (day in c(15, 16, 17, 14, 13, 18, 19, 12, 20, 10)) {
      if (success) break
      date_str <- sprintf("%d%02d%02d", yr, mo, day)
      url <- paste0("https://www.twse.com.tw/exchangeReport/STOCK_DAY_ALL?response=json&date=", date_str)
      cat(sprintf("  Stocks %d-%02d (day %02d)... ", yr, mo, day))
      result <- fetch_twse(url, pause = 3)

      if (!is.null(result) && result$stat == "OK" && !is.null(result$data)) {
        mat <- result$data
        if (is.matrix(mat) && nrow(mat) > 0 && ncol(mat) >= 10) {
          df <- data.frame(
            stock_code = trimws(mat[, 1]),
            stock_name = mat[, 2],
            volume_shares = mat[, 3],
            value_twd = mat[, 4],
            open = mat[, 5],
            high = mat[, 6],
            low = mat[, 7],
            close = mat[, 8],
            change = mat[, 9],
            n_transactions = mat[, 10],
            stringsAsFactors = FALSE
          )
          # Keep only ordinary shares (4-digit numeric codes)
          df <- df[grepl("^\\d{4}$", df$stock_code), ]
          df$date_str <- date_str
          df$year <- yr
          df$month <- mo
          stock_list[[length(stock_list) + 1]] <- df
          cat("OK (", nrow(df), "stocks)\n")
          success <- TRUE
        } else {
          cat("bad format\n")
        }
      } else {
        cat("no data, trying next day\n")
      }
    }
    if (!success) {
      cat(sprintf("  WARNING: No data found for %d-%02d after trying multiple days\n", yr, mo))
    }
  }
}

if (length(stock_list) == 0) {
  stop("FATAL: No per-stock trading data retrieved. Cannot proceed.")
}

stock_raw <- bind_rows(stock_list)
cat("\nPer-stock raw rows:", nrow(stock_raw), "\n")
cat("Unique stocks:", n_distinct(stock_raw$stock_code), "\n")
cat("Year range:", range(stock_raw$year), "\n")
saveRDS(stock_raw, file.path(data_dir, "stock_monthly_raw.rds"))

# ============================================================================
# 3. TWSE Institutional Investor Trading (T86 report)
# ============================================================================

cat("\n=== Fetching institutional investor flow data ===\n")

inst_list <- list()
for (yr in 2010:2018) {
  for (mo in c(1, 4, 7, 10)) {  # Quarterly to reduce API calls
    for (day in c(15, 16, 17, 14, 13, 18, 19, 12, 20)) {
      date_str <- sprintf("%d%02d%02d", yr, mo, day)
      url <- paste0("https://www.twse.com.tw/fund/T86?response=json&date=",
                     date_str, "&selectType=ALLBUT0999")
      cat(sprintf("  Inst flows %d-Q%d (day %02d)... ", yr, ceiling(mo/3), day))
      result <- fetch_twse(url, pause = 3)
      if (!is.null(result) && !is.null(result$data)) {
        raw_data <- result$data
        if (is.matrix(raw_data)) raw_data <- as.data.frame(raw_data, stringsAsFactors = FALSE)
        if (is.data.frame(raw_data) && nrow(raw_data) > 0 && ncol(raw_data) >= 7) {
          names(raw_data)[1:7] <- c("stock_code", "stock_name",
                                     "foreign_buy", "foreign_sell", "foreign_net",
                                     "trust_buy", "trust_sell")
          raw_data$stock_code <- trimws(raw_data$stock_code)
          raw_data$date_str <- date_str
          raw_data$year <- yr
          raw_data$quarter <- ceiling(mo / 3)
          raw_data <- raw_data[grepl("^\\d{4}$", raw_data$stock_code), ]
          inst_list[[length(inst_list) + 1]] <- raw_data
          cat("OK (", nrow(raw_data), "stocks)\n")
          break  # Got data, move to next quarter
        } else {
          cat("bad format\n")
        }
      } else {
        cat("no data, trying next day\n")
      }
    }
  }
}

if (length(inst_list) > 0) {
  inst_raw <- bind_rows(inst_list)
  cat("\nInstitutional flow raw rows:", nrow(inst_raw), "\n")
  saveRDS(inst_raw, file.path(data_dir, "institutional_flows_raw.rds"))
} else {
  cat("WARNING: No institutional flow data retrieved. Will use market cap proxy.\n")
  inst_raw <- NULL
}

# ============================================================================
# 4. P/E Ratios and Dividend Yields (BWIBBU)
# ============================================================================

cat("\n=== Fetching P/E and dividend yield data ===\n")

pe_list <- list()
for (yr in 2010:2018) {
  for (mo in c(1, 4, 7, 10)) {  # Quarterly
    for (day in c(15, 16, 17, 14, 13, 18)) {
      date_str <- sprintf("%d%02d%02d", yr, mo, day)
      url <- paste0("https://www.twse.com.tw/exchangeReport/BWIBBU_d?response=json&date=",
                     date_str, "&selectType=ALL")
      cat(sprintf("  P/E %d-Q%d (day %02d)... ", yr, ceiling(mo/3), day))
      result <- fetch_twse(url, pause = 3)
      if (!is.null(result) && !is.null(result$data) && length(result$data) > 0) {
        df_data <- result$data
        if (is.matrix(df_data)) df_data <- as.data.frame(df_data, stringsAsFactors = FALSE)
        if (is.data.frame(df_data) && nrow(df_data) > 0 && ncol(df_data) >= 5) {
          names(df_data)[1:5] <- c("stock_code", "stock_name",
                                     "dividend_yield", "pe_ratio", "pb_ratio")
          df_data$stock_code <- trimws(df_data$stock_code)
          df_data$date_str <- date_str
          df_data$year <- yr
          df_data$quarter <- ceiling(mo / 3)
          df_data <- df_data[grepl("^\\d{4}$", df_data$stock_code), ]
          pe_list[[length(pe_list) + 1]] <- df_data
          cat("OK (", nrow(df_data), "stocks)\n")
          break
        } else {
          cat("bad format\n")
        }
      } else {
        cat("no data, trying next day\n")
      }
    }
  }
}

if (length(pe_list) > 0) {
  pe_raw <- bind_rows(pe_list)
  cat("\nP/E raw rows:", nrow(pe_raw), "\n")
  saveRDS(pe_raw, file.path(data_dir, "pe_dividend_raw.rds"))
} else {
  cat("WARNING: No P/E data retrieved.\n")
}

# ============================================================================
# Summary
# ============================================================================

cat("\n=== DATA FETCH SUMMARY ===\n")
cat("TAIEX monthly:", nrow(taiex_raw), "rows\n")
cat("Per-stock monthly:", nrow(stock_raw), "rows,",
    n_distinct(stock_raw$stock_code), "unique stocks\n")
if (!is.null(inst_raw)) {
  cat("Institutional flows:", nrow(inst_raw), "rows\n")
}
if (length(pe_list) > 0) {
  cat("P/E and dividend:", nrow(pe_raw), "rows\n")
}
cat("All files saved to:", normalizePath(data_dir), "\n")
