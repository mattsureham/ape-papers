# 01_fetch_data.R — Fetch Comtrade HS 4-digit trade data for CBAM analysis
# apep_0900: CBAM product-scope loophole

source("00_packages.R")

comtrade_key <- Sys.getenv("COMTRADE_API_PRIMARY")
if (nchar(comtrade_key) == 0) stop("COMTRADE_API_PRIMARY not set in .env")

# --- Define product codes ---
# CBAM-covered products (HS 72: iron and steel)
hs72_codes <- sprintf("%04d", 7201:7229)
# Exempt downstream articles (HS 73: articles of iron or steel)
hs73_codes <- sprintf("%04d", 7301:7326)
# CBAM-covered aluminum (unwrought)
hs76_covered <- c("7601", "7602", "7603")
# Exempt aluminum articles
hs76_exempt <- sprintf("%04d", 7604:7616)

all_codes <- c(hs72_codes, hs73_codes, hs76_covered, hs76_exempt)

# --- Define partner countries ---
# High-carbon steel exporters (>1.5 tCO2/t)
high_carbon <- c("156", "356", "792", "643", "804", "704")  # CN, IN, TR, RU, UA, VN
# Low-carbon steel exporters (<1.2 tCO2/t) — control group
low_carbon <- c("392", "410", "076", "158")  # JP, KR, BR, TW

partners <- c(high_carbon, low_carbon)

# --- Fetch function for Comtrade API v2 ---
fetch_comtrade <- function(reporter, partner_codes, cmd_codes, year, flow = "M",
                           freq = "A", api_key = comtrade_key) {
  # Comtrade API v2: https://comtradeapi.un.org/data/v1/get/C/A/HS
  # flow: M = imports
  base_url <- "https://comtradeapi.un.org/data/v1/get/C"

  # Batch cmd codes (API limit ~50 codes per call)
  code_batches <- split(cmd_codes, ceiling(seq_along(cmd_codes) / 30))

  results <- list()
  for (i in seq_along(code_batches)) {
    batch <- code_batches[[i]]
    cmd_str <- paste(batch, collapse = ",")
    partner_str <- paste(partner_codes, collapse = ",")

    url <- paste0(base_url, "/", freq, "/HS?",
                  "reporterCode=", reporter,
                  "&partnerCode=", partner_str,
                  "&cmdCode=", cmd_str,
                  "&flowCode=", flow,
                  "&period=", year,
                  "&subscription-key=", api_key)

    cat(sprintf("  Fetching batch %d/%d for year %s...\n", i, length(code_batches), year))

    resp <- tryCatch({
      req <- request(url) |>
        req_timeout(120) |>
        req_retry(max_tries = 3, backoff = ~ 5)
      resp <- req_perform(req)
      resp_body_json(resp)
    }, error = function(e) {
      cat(sprintf("  ERROR: %s\n", e$message))
      return(NULL)
    })

    if (is.null(resp)) {
      stop(sprintf("Failed to fetch Comtrade data for year %s batch %d. Cannot proceed with NULL data.", year, i))
    }

    if (!is.null(resp$data) && length(resp$data) > 0) {
      dt <- rbindlist(resp$data, fill = TRUE)
      results[[length(results) + 1]] <- dt
    }

    Sys.sleep(1.5)  # Rate limit
  }

  if (length(results) == 0) return(NULL)
  rbindlist(results, fill = TRUE)
}

# --- Fetch data for years 2019-2024 ---
# Reporter 97 = EU-27 aggregate (Comtrade code)
# If EU-27 aggregate not available, use individual reporters
years <- 2019:2024
all_data <- list()

cat("Fetching EU-27 imports from Comtrade API v2...\n")
for (yr in years) {
  cat(sprintf("Year %d:\n", yr))
  dt <- fetch_comtrade(
    reporter = "97",  # EU (European Union)
    partner_codes = partners,
    cmd_codes = all_codes,
    year = as.character(yr)
  )
  if (!is.null(dt) && nrow(dt) > 0) {
    all_data[[as.character(yr)]] <- dt
    cat(sprintf("  -> %d rows\n", nrow(dt)))
  } else {
    cat(sprintf("  -> No data for year %d\n", yr))
  }
}

if (length(all_data) == 0) {
  # Fallback: try Germany (276) as largest EU importer
  cat("\nEU-27 aggregate not available. Trying individual EU importers...\n")
  eu_reporters <- c("276", "380", "250", "528", "056")  # DE, IT, FR, NL, BE
  reporter_str <- paste(eu_reporters, collapse = ",")

  for (yr in years) {
    cat(sprintf("Year %d (individual EU reporters):\n", yr))
    dt <- fetch_comtrade(
      reporter = reporter_str,
      partner_codes = partners,
      cmd_codes = all_codes,
      year = as.character(yr)
    )
    if (!is.null(dt) && nrow(dt) > 0) {
      all_data[[as.character(yr)]] <- dt
      cat(sprintf("  -> %d rows\n", nrow(dt)))
    }
  }
}

if (length(all_data) == 0) stop("FATAL: No trade data retrieved from Comtrade. Cannot proceed.")

trade_raw <- rbindlist(all_data, fill = TRUE)
cat(sprintf("\nTotal raw rows: %d\n", nrow(trade_raw)))
cat(sprintf("Years covered: %s\n", paste(sort(unique(trade_raw$period)), collapse = ", ")))
cat(sprintf("Products: %d unique codes\n", uniqueN(trade_raw$cmdCode)))
cat(sprintf("Partners: %d unique\n", uniqueN(trade_raw$partnerCode)))

# --- Save raw data ---
fwrite(trade_raw, "../data/trade_raw.csv")
cat("Saved: data/trade_raw.csv\n")

# --- Validate ---
stopifnot("No data retrieved" = nrow(trade_raw) > 0)
stopifnot("No product codes" = uniqueN(trade_raw$cmdCode) >= 5)
stopifnot("No partner countries" = uniqueN(trade_raw$partnerCode) >= 3)

cat("\n=== Data fetch complete ===\n")
