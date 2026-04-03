# 01_fetch_data.R — Data acquisition (API-only, no hard-coded values)
# apep_1343: Private Governance and Bangladesh Apparel Exports After Rana Plaza
#
# All data from real APIs: UN Comtrade, World Bank

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# 1. UN COMTRADE — Bangladesh bilateral exports by HS chapter
# ============================================================================
cat("=== Fetching UN Comtrade bilateral trade data ===\n")

comtrade_key <- Sys.getenv("COMTRADE_API_KEY", "")
if (nchar(comtrade_key) == 0) comtrade_key <- Sys.getenv("COMTRADE", "")

fetch_comtrade <- function(year, hs_code) {
  # Try subscription API first, then public preview
  if (nchar(comtrade_key) > 0) {
    url <- sprintf(
      "https://comtradeapi.un.org/data/v1/get/C/A/HS?reporterCode=050&period=%s&cmdCode=%s&flowCode=X&subscription-key=%s",
      year, hs_code, comtrade_key
    )
  } else {
    url <- sprintf(
      "https://comtradeapi.un.org/public/v1/preview/C/A/HS?reporterCode=050&period=%s&cmdCode=%s&flowCode=X",
      year, hs_code
    )
  }

  resp <- GET(url, timeout(60),
              add_headers("User-Agent" = "Mozilla/5.0 (academic research)"))

  if (status_code(resp) == 200) {
    raw <- content(resp, as = "text", encoding = "UTF-8")
    result <- fromJSON(raw)
    if (!is.null(result$data) && length(result$data) > 0) {
      dt <- as.data.table(result$data)
      return(dt)
    }
  }
  cat("  Status:", status_code(resp), "for year=", year, "HS=", hs_code, "\n")
  return(NULL)
}

# HS chapters: apparel (61,62) + controls (03 fish, 52 cotton, 64 footwear)
hs_chapters <- c("61", "62", "03", "52", "64")
years <- 2008:2022

comtrade_list <- list()
n_success <- 0

for (yr in years) {
  for (hs in hs_chapters) {
    cat("Comtrade: BGD exports year=", yr, " HS=", hs, " ... ")
    dt <- NULL
    tryCatch({
      dt <- fetch_comtrade(yr, hs)
    }, error = function(e) {
      cat("Error:", e$message, "\n")
    })

    if (!is.null(dt) && nrow(dt) > 0) {
      comtrade_list[[paste(yr, hs)]] <- dt
      n_success <- n_success + 1
      cat(nrow(dt), "rows\n")
    } else {
      cat("no data\n")
    }
    Sys.sleep(2)  # Respect rate limits
  }
}

cat("\n--- Comtrade summary:", n_success, "/", length(years) * length(hs_chapters),
    "queries returned data ---\n")

if (n_success == 0) {
  stop("FATAL: Comtrade API returned no data. Cannot proceed without bilateral trade data.
Check: (1) API key in COMTRADE_API_KEY env var, (2) network connectivity,
(3) rate limits (public API: 1 req/sec, 100/day).")
}

comtrade_dt <- rbindlist(comtrade_list, fill = TRUE)

# Keep essential columns
keep_cols <- intersect(
  names(comtrade_dt),
  c("period", "reporterCode", "reporterDesc", "partnerCode", "partnerDesc",
    "cmdCode", "cmdDesc", "flowCode", "primaryValue", "netWgt", "qty",
    "partner2Code", "partner2Desc", "fobvalue", "cifvalue")
)
comtrade_dt <- comtrade_dt[, ..keep_cols]

fwrite(comtrade_dt, file.path(data_dir, "comtrade_bgd_bilateral.csv"))
cat("Saved Comtrade data:", nrow(comtrade_dt), "rows,",
    uniqueN(comtrade_dt$period), "years,",
    uniqueN(comtrade_dt$cmdCode), "HS chapters,",
    uniqueN(comtrade_dt$partnerCode), "partners\n")

# ============================================================================
# 2. WORLD BANK — Bangladesh macro indicators
# ============================================================================
cat("\n=== Fetching World Bank indicators ===\n")

wb_indicators <- c(
  "NE.EXP.GNFS.CD",      # Total exports
  "NV.IND.MANF.CD",      # Manufacturing VA
  "NY.GDP.MKTP.CD",      # GDP
  "TX.VAL.MRCH.CD.WT",   # Merchandise exports
  "FP.CPI.TOTL.ZG",      # Inflation
  "PA.NUS.FCRF"           # Exchange rate (LCU per USD)
)

wb_list <- list()
for (ind in wb_indicators) {
  url <- sprintf(
    "https://api.worldbank.org/v2/country/BGD/indicator/%s?format=json&per_page=50&date=2008:2022",
    ind
  )
  tryCatch({
    resp <- GET(url, timeout(30))
    if (status_code(resp) == 200) {
      result <- fromJSON(content(resp, as = "text", encoding = "UTF-8"))
      if (length(result) >= 2 && !is.null(result[[2]])) {
        vals <- result[[2]]
        dt <- data.table(
          year = as.integer(vals$date),
          indicator = ind,
          value = as.numeric(vals$value)
        )
        wb_list[[ind]] <- dt[!is.na(value)]
        cat("WB:", ind, "->", nrow(dt[!is.na(value)]), "obs\n")
      }
    }
  }, error = function(e) cat("WB error:", ind, "\n"))
  Sys.sleep(0.5)
}

if (length(wb_list) == 0) {
  stop("FATAL: World Bank API returned no data. Check network connectivity.")
}

wb_dt <- rbindlist(wb_list)
wb_wide <- dcast(wb_dt, year ~ indicator, value.var = "value")
fwrite(wb_wide, file.path(data_dir, "wb_bangladesh.csv"))
cat("Saved WB data:", nrow(wb_wide), "rows,", ncol(wb_wide) - 1, "indicators\n")

# ============================================================================
# 3. ACCORD / ALLIANCE PUBLISHED REPORTS — Factory-level data attempt
# ============================================================================
cat("\n=== Attempting Accord/Alliance factory data ===\n")

# Try International Accord's publicly available factory inspection reports
accord_urls <- c(
  "https://internationalaccord.org/api/factories",
  "https://internationalaccord.org/factories/export",
  "https://bangladeshaccord.org/api/factories"
)

accord_fetched <- FALSE
for (url in accord_urls) {
  tryCatch({
    resp <- GET(url, timeout(30),
                add_headers("Accept" = "application/json, text/csv",
                            "User-Agent" = "Mozilla/5.0 (academic research)"))
    cat("Accord URL:", url, "-> Status:", status_code(resp), "\n")
    if (status_code(resp) == 200) {
      raw_text <- content(resp, as = "text", encoding = "UTF-8")
      ct <- headers(resp)$`content-type`
      if (grepl("json", ct, ignore.case = TRUE)) {
        accord_data <- fromJSON(raw_text)
        if (is.data.frame(accord_data) || is.list(accord_data)) {
          fwrite(as.data.table(accord_data), file.path(data_dir, "accord_factories.csv"))
          accord_fetched <- TRUE
          cat("SUCCESS: Factory-level data from", url, "\n")
          break
        }
      } else if (grepl("csv|text", ct, ignore.case = TRUE)) {
        writeLines(raw_text, file.path(data_dir, "accord_factories_raw.csv"))
        accord_fetched <- TRUE
        cat("SUCCESS: CSV data from", url, "\n")
        break
      } else {
        # Try parsing as HTML to extract factory table
        page <- read_html(raw_text)
        tables <- html_table(page, fill = TRUE)
        if (length(tables) > 0) {
          biggest <- tables[[which.max(sapply(tables, nrow))]]
          fwrite(as.data.table(biggest), file.path(data_dir, "accord_factories.csv"))
          accord_fetched <- TRUE
          cat("SUCCESS: Extracted table from HTML at", url, "\n")
          break
        }
      }
    }
  }, error = function(e) {
    cat("  Error:", e$message, "\n")
  })
}

if (!accord_fetched) {
  cat("\nWARNING: Could not fetch factory-level Accord data.\n")
  cat("Analysis will rely on Comtrade bilateral trade data.\n")
}

# ============================================================================
# 4. VALIDATION
# ============================================================================
cat("\n=== Data validation ===\n")

# Must have Comtrade data
stopifnot("Comtrade data required" =
            file.exists(file.path(data_dir, "comtrade_bgd_bilateral.csv")))
ct <- fread(file.path(data_dir, "comtrade_bgd_bilateral.csv"))
stopifnot("Comtrade must have >50 rows" = nrow(ct) > 50)

# Must have WB data
stopifnot("WB data required" =
            file.exists(file.path(data_dir, "wb_bangladesh.csv")))

cat("Comtrade:", nrow(ct), "rows\n")
cat("Years covered:", paste(range(ct$period), collapse = "-"), "\n")
cat("HS chapters:", paste(sort(unique(ct$cmdCode)), collapse = ", "), "\n")
cat("Partners:", uniqueN(ct$partnerCode), "\n")

cat("\n=== Data acquisition complete ===\n")
