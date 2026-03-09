# =============================================================================
# 01_fetch_data.R — Fetch tailings failure events and stock price data
# APEP-0560: Market Discipline and Mining Safety
# =============================================================================

source("00_packages.R")

cat("=== PHASE 1: Scraping WISE Tailings Dam Failures Database ===\n")

# --- 1. Scrape WISE database ---
wise_url <- "https://www.wise-uranium.org/mdaf.html"

wise_page <- tryCatch({
  read_html(wise_url)
}, error = function(e) {
  stop("WISE database unavailable: ", e$message,
       "\nCannot proceed without event data. Fix the source or check internet connection.")
})

# Extract the main table
wise_tables <- html_table(wise_page, fill = TRUE)

# The WISE page has one main table with failure data
if (length(wise_tables) == 0) {
  stop("No tables found on WISE page. Page structure may have changed.")
}

# Parse the largest table (the main failure chronology)
raw_dt <- as.data.table(wise_tables[[which.max(sapply(wise_tables, nrow))]])
cat("Raw WISE table:", nrow(raw_dt), "rows,", ncol(raw_dt), "columns\n")

# Save raw scrape for reproducibility
fwrite(raw_dt, "../data/wise_raw_scrape.csv")

# --- 2. Parse and clean WISE data ---
# Column names vary but typically: Date, Mine/Location, Country, Type, Ore, Details
# Inspect actual column names
cat("Column names:", paste(names(raw_dt), collapse = ", "), "\n")

# Standardize column names based on content
# The WISE table typically has columns like: Date, Mine/Location, Ore, Cause, Quantity released, etc.
setnames(raw_dt, make.names(names(raw_dt), unique = TRUE))

# We need to parse this carefully since the HTML table structure varies
# Let's work with whatever columns we have
cat("First 5 rows:\n")
print(head(raw_dt, 5))

# Try to identify the date column and extract dates
date_cols <- names(raw_dt)[sapply(raw_dt, function(x) {
  any(grepl("\\d{4}", as.character(x)))
})]

cat("Columns with year-like values:", paste(date_cols, collapse = ", "), "\n")

# Parse the full HTML more carefully to extract structured data
# The WISE page uses a specific table format
wise_text <- html_text2(wise_page)

# Alternative approach: parse the page structure directly
# Extract all table rows
rows <- html_nodes(wise_page, "tr")
cat("Total table rows found:", length(rows), "\n")

# Parse each row
events_list <- list()
for (i in seq_along(rows)) {
  cells <- html_nodes(rows[[i]], "td")
  if (length(cells) >= 3) {
    cell_text <- trimws(html_text(cells))
    events_list[[length(events_list) + 1]] <- cell_text
  }
}

cat("Parsed", length(events_list), "data rows\n")

# Build structured data from parsed rows
# WISE table columns are typically:
# Date | Mine/Location, State/Province, Country | Parent Company | Ore Type | Cause/Type | Details
parse_wise_event <- function(cells) {
  n <- length(cells)
  if (n < 3) return(NULL)

  data.table(
    raw_date = cells[1],
    location = if (n >= 2) cells[2] else NA_character_,
    company = if (n >= 3) cells[3] else NA_character_,
    ore_type = if (n >= 4) cells[4] else NA_character_,
    incident_type = if (n >= 5) cells[5] else NA_character_,
    details = if (n >= 6) paste(cells[6:n], collapse = " | ") else NA_character_
  )
}

events_dt <- rbindlist(lapply(events_list, parse_wise_event), fill = TRUE)
cat("Structured events:", nrow(events_dt), "rows\n")

# Extract year from date column
events_dt[, year := as.integer(str_extract(raw_date, "\\d{4}"))]

# Extract country from location (typically last element after comma)
events_dt[, country := trimws(str_extract(location, "[^,]+$"))]

# Parse actual date where possible
events_dt[, event_date := as.Date(raw_date, format = "%Y, %B %d")]
# Try alternative formats
events_dt[is.na(event_date), event_date := as.Date(raw_date, format = "%Y, %b %d")]
events_dt[is.na(event_date), event_date := as.Date(raw_date, format = "%Y, %b. %d")]
# For year-month only, use first of month
events_dt[is.na(event_date) & !is.na(year), event_date := as.Date(paste0(year, "-06-15"))]

# Filter to events with valid years
events_dt <- events_dt[!is.na(year) & year >= 1960]
cat("Events with valid years (1960+):", nrow(events_dt), "\n")

# Classify severity (look for fatality mentions in details)
events_dt[, has_fatalities := grepl("kill|death|died|fatalit|lives|dead",
                                     paste(details, incident_type), ignore.case = TRUE)]
events_dt[, fatality_count := {
  nums <- str_extract_all(paste(details, incident_type),
                           "\\b(\\d+)\\s*(people|person|worker|lives|killed|died|dead|fatalit)")
  sapply(nums, function(x) {
    if (length(x) == 0) return(0L)
    max(as.integer(str_extract(x, "\\d+")), na.rm = TRUE)
  })
}]

# Extract release volume (in m³ or tonnes)
events_dt[, release_volume_m3 := {
  vol_text <- paste(details, incident_type)
  # Try to extract numbers before "m³" or "cubic meters"
  vol <- str_extract(vol_text, "[\\d,.]+\\s*(million\\s+)?(m[³3]|cubic\\s+met)")
  as.numeric(gsub("[^0-9.]", "", str_extract(vol, "[\\d,.]+")))
}]

# Flag post-GISTM events (August 2020)
events_dt[, post_gistm := event_date >= as.Date("2020-08-05")]

# Save cleaned events
fwrite(events_dt, "../data/tailings_events_cleaned.csv")
cat("Cleaned events saved:", nrow(events_dt), "events\n")
cat("  Post-GISTM:", sum(events_dt$post_gistm, na.rm = TRUE), "\n")
cat("  With fatalities:", sum(events_dt$has_fatalities, na.rm = TRUE), "\n")
cat("  Year range:", min(events_dt$year, na.rm = TRUE), "-", max(events_dt$year, na.rm = TRUE), "\n")

# --- 3. Define mining firm universe ---
cat("\n=== PHASE 2: Building Mining Firm Universe ===\n")

# Major publicly traded mining companies with tickers
# This is a curated list of the largest global mining firms
mining_firms <- data.table(
  ticker = c(
    # Diversified miners
    "BHP", "RIO", "VALE", "GLEN.L", "AAL.L", "ANTO.L",
    "TECK.B.TO", "FCX", "SCCO",
    # Gold
    "NEM", "GOLD", "AEM", "GFI", "KGC", "AU", "WPM",
    "FNV", "RGLD",
    # Iron ore
    "VALE", "CLF", "HBM.TO",
    # Copper
    "FCX", "SCCO", "ANTO.L", "HBM.TO", "TECK.B.TO",
    # Coal
    "BTU", "ARCH", "HCC", "CEIX", "AMR",
    # Nickel/Platinum
    "IMPJ.JO", "AMSJ.JO", "SBSW",
    # Potash/Fertilizer
    "NTR", "MOS", "IPI",
    # Lithium
    "ALB", "SQM", "LTHM",
    # Steel (integrated mining)
    "MT", "X", "NUE", "STLD",
    # Uranium
    "CCJ", "UEC", "DNN",
    # Zinc/Lead
    "NEXA", "IVPAF",
    # Silver
    "PAAS", "AG", "CDE", "HL",
    # Phosphate
    "MOS", "IPI",
    # Aluminum (bauxite mining)
    "AA", "CENX"
  ),
  company = c(
    "BHP Group", "Rio Tinto", "Vale SA", "Glencore", "Anglo American", "Antofagasta",
    "Teck Resources", "Freeport-McMoRan", "Southern Copper",
    "Newmont", "Barrick Gold", "Agnico Eagle", "Gold Fields", "Kinross Gold",
    "AngloGold Ashanti", "Wheaton Precious Metals", "Franco-Nevada", "Royal Gold",
    "Vale SA", "Cleveland-Cliffs", "Hudbay Minerals",
    "Freeport-McMoRan", "Southern Copper", "Antofagasta", "Hudbay Minerals", "Teck Resources",
    "Peabody Energy", "Arch Resources", "Warrior Met Coal", "CONSOL Energy", "Alpha Metallurgical",
    "Impala Platinum", "Anglo American Platinum", "Sibanye-Stillwater",
    "Nutrien", "Mosaic Company", "Intrepid Potash",
    "Albemarle", "SQM", "Livent",
    "ArcelorMittal", "US Steel", "Nucor", "Steel Dynamics",
    "Cameco", "Uranium Energy", "Denison Mines",
    "Nexa Resources", "Ivanhoe Mines",
    "Pan American Silver", "First Majestic Silver", "Coeur Mining", "Hecla Mining",
    "Mosaic Company", "Intrepid Potash",
    "Alcoa", "Century Aluminum"
  ),
  primary_commodity = c(
    "Diversified", "Diversified", "Iron Ore", "Diversified", "Diversified", "Copper",
    "Diversified", "Copper", "Copper",
    "Gold", "Gold", "Gold", "Gold", "Gold", "Gold", "Gold", "Gold", "Gold",
    "Iron Ore", "Iron Ore", "Copper",
    "Copper", "Copper", "Copper", "Copper", "Diversified",
    "Coal", "Coal", "Coal", "Coal", "Coal",
    "PGM", "PGM", "PGM",
    "Potash", "Phosphate", "Potash",
    "Lithium", "Lithium", "Lithium",
    "Steel", "Steel", "Steel", "Steel",
    "Uranium", "Uranium", "Uranium",
    "Zinc", "Diversified",
    "Silver", "Silver", "Silver", "Silver",
    "Phosphate", "Potash",
    "Aluminum", "Aluminum"
  ),
  has_tailings_dams = c(
    TRUE, TRUE, TRUE, TRUE, TRUE, TRUE,
    TRUE, TRUE, TRUE,
    TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE,
    TRUE, TRUE, TRUE,
    TRUE, TRUE, TRUE, TRUE, TRUE,
    TRUE, TRUE, TRUE, TRUE, TRUE,
    TRUE, TRUE, TRUE,
    TRUE, TRUE, TRUE,
    TRUE, TRUE, TRUE,
    TRUE, TRUE, TRUE, TRUE,
    TRUE, TRUE, TRUE,
    TRUE, TRUE,
    TRUE, TRUE, TRUE, TRUE,
    TRUE, TRUE,
    TRUE, TRUE
  ),
  is_streaming_royalty = c(
    rep(FALSE, 15), TRUE, TRUE, TRUE,
    rep(FALSE, 40)
  )
)

# Remove duplicates
mining_firms <- unique(mining_firms, by = "ticker")
cat("Unique mining firms:", nrow(mining_firms), "\n")

# Save firm universe
fwrite(mining_firms, "../data/mining_firms_universe.csv")

# --- 4. Fetch stock price data from Yahoo Finance ---
cat("\n=== PHASE 3: Fetching Stock Price Data ===\n")

# We need daily returns for all firms
# Focus on 2000-2025 for most liquid data (pre-2000 coverage is spotty)
start_date <- "1995-01-01"
end_date <- Sys.Date()

fetch_stock <- function(ticker) {
  tryCatch({
    stock <- getSymbols(ticker, src = "yahoo", from = start_date, to = end_date,
                        auto.assign = FALSE)
    if (is.null(stock) || nrow(stock) < 100) return(NULL)

    # Calculate returns
    adj_close <- Ad(stock)
    ret <- dailyReturn(adj_close, type = "log")

    dt <- data.table(
      date = index(ret),
      ticker = ticker,
      ret = as.numeric(ret),
      adj_close = as.numeric(adj_close)[-1]
    )
    # Remove first row (NA return)
    dt <- dt[!is.na(ret)]
    return(dt)
  }, error = function(e) {
    cat("  Failed:", ticker, "-", e$message, "\n")
    return(NULL)
  })
}

cat("Fetching stock data for", nrow(mining_firms), "firms...\n")

stock_list <- list()
successful <- 0
failed <- 0

for (i in seq_len(nrow(mining_firms))) {
  ticker <- mining_firms$ticker[i]
  cat("  [", i, "/", nrow(mining_firms), "]", ticker, "...")
  result <- fetch_stock(ticker)
  if (!is.null(result)) {
    stock_list[[ticker]] <- result
    successful <- successful + 1
    cat(" OK (", nrow(result), "days)\n")
  } else {
    failed <- failed + 1
    cat(" FAILED\n")
  }
  Sys.sleep(0.5)  # Rate limiting
}

cat("\nStock data fetched:", successful, "succeeded,", failed, "failed\n")

if (successful < 20) {
  stop("Too few firms with stock data (", successful, "). Need at least 20. ",
       "Check internet connection and Yahoo Finance availability.")
}

stock_dt <- rbindlist(stock_list, fill = TRUE)
cat("Total stock observations:", nrow(stock_dt), "\n")
cat("Date range:", as.character(min(stock_dt$date)), "to", as.character(max(stock_dt$date)), "\n")

# Merge firm characteristics
stock_dt <- merge(stock_dt, mining_firms, by = "ticker", all.x = TRUE)

# Save stock data
fwrite(stock_dt, "../data/stock_returns.csv")

# --- 5. Fetch market benchmark data ---
cat("\n=== PHASE 4: Fetching Market Benchmarks ===\n")

benchmarks <- c("^GSPC", "^FTSE", "XME")  # S&P 500, FTSE 100, S&P Metals & Mining ETF

bench_list <- list()
for (bm in benchmarks) {
  cat("  Fetching", bm, "...")
  tryCatch({
    stock <- getSymbols(bm, src = "yahoo", from = start_date, to = end_date,
                        auto.assign = FALSE)
    adj_close <- Ad(stock)
    ret <- dailyReturn(adj_close, type = "log")
    dt <- data.table(
      date = index(ret),
      benchmark = bm,
      mkt_ret = as.numeric(ret)
    )
    dt <- dt[!is.na(mkt_ret)]
    bench_list[[bm]] <- dt
    cat(" OK (", nrow(dt), "days)\n")
  }, error = function(e) {
    cat(" FAILED -", e$message, "\n")
  })
}

bench_dt <- rbindlist(bench_list, fill = TRUE)
fwrite(bench_dt, "../data/benchmark_returns.csv")

# === DATA VALIDATION (required) ===
stopifnot("Need at least 20 mining firms" = uniqueN(stock_dt$ticker) >= 20)
stopifnot("Need at least 30 tailings events" = nrow(events_dt) >= 30)
stopifnot("Stock data needs 50000+ rows" = nrow(stock_dt) >= 50000)
stopifnot("Need benchmark data" = nrow(bench_dt) >= 1000)

cat("\n=== DATA VALIDATION PASSED ===\n")
cat("  Mining firms:", uniqueN(stock_dt$ticker), "\n")
cat("  Tailings events:", nrow(events_dt), "\n")
cat("  Stock observations:", nrow(stock_dt), "\n")
cat("  Benchmark observations:", nrow(bench_dt), "\n")
cat("  Date range:", as.character(min(stock_dt$date)), "to", as.character(max(stock_dt$date)), "\n")
