## 01_fetch_data.R — Fetch all data for Zambia mining tax paper
## apep_0960

source("00_packages.R")

# ── 1. Zambia district boundaries (GADM Level 2) ─────────────────────────
cat("Fetching Zambia GADM Level 2 boundaries...\n")
zmb_gadm <- gadm(country = "ZMB", level = 2, path = tempdir())
zmb_sf <- st_as_sf(zmb_gadm)
cat("  Districts found:", nrow(zmb_sf), "\n")
stopifnot(nrow(zmb_sf) > 50)  # Zambia has ~116 districts

# Save district names for reference
cat("  Province names:", paste(unique(zmb_sf$NAME_1), collapse = ", "), "\n")

saveRDS(zmb_sf, "../data/zmb_districts.rds")

# ── 2. VIIRS nightlights (annual composites 2012–2023) ───────────────────
cat("\nFetching VIIRS annual nightlights via blackmarbler...\n")

nasa_token <- Sys.getenv("NASA_EARTHDATA_API_KEY")
if (nchar(nasa_token) == 0) stop("NASA_EARTHDATA_API_KEY not set in .env")

# Use annual product VNP46A4 for stability (monthly can be noisy)
# Fetch 2012-2023 (VIIRS starts April 2012, annual from 2012)
years_fetch <- 2012:2023

ntl_annual <- bm_extract(
  roi_sf = zmb_sf,
  product_id = "VNP46A4",
  date = years_fetch,
  bearer = nasa_token,
  aggregation_fun = "mean",
  quiet = FALSE
)

cat("  NTL rows fetched:", nrow(ntl_annual), "\n")
stopifnot(nrow(ntl_annual) > 0)

saveRDS(ntl_annual, "../data/ntl_annual_raw.rds")

# ── 3. World Bank indicators ─────────────────────────────────────────────
cat("\nFetching World Bank indicators for Zambia...\n")

wb_indicators <- c(
  "NY.GDP.MKTP.KD.ZG",  # GDP growth
  "NY.GDP.MINR.RT.ZS",  # Mineral rents (% GDP)
  "NE.EXP.GNFS.ZS"      # Exports (% GDP)
)

wb_data <- WDI(
  country = "ZM",
  indicator = wb_indicators,
  start = 2010,
  end = 2023,
  extra = FALSE
)

cat("  WB rows:", nrow(wb_data), "\n")
stopifnot(nrow(wb_data) > 5)

saveRDS(wb_data, "../data/wb_zambia.rds")

# ── 4. Copper prices from World Bank commodity data ──────────────────────
cat("\nFetching copper price data...\n")

# Use World Bank Commodities - try monthly copper prices
copper_url <- "https://api.worldbank.org/v2/country/ZMB/indicator/PCOPP.MCOPP?date=2012:2023&format=json&per_page=200"
copper_resp <- tryCatch(
  {
    resp <- readLines(copper_url, warn = FALSE)
    fromJSON(paste(resp, collapse = ""))
  },
  error = function(e) {
    cat("  WB copper API failed, using alternative...\n")
    NULL
  }
)

# If WB API doesn't have commodity prices, use FRED or manual
if (is.null(copper_resp) || length(copper_resp) < 2) {
  cat("  Fetching copper prices from FRED...\n")
  fred_key <- Sys.getenv("FRED_API_KEY")
  if (nchar(fred_key) > 0) {
    fred_url <- paste0(
      "https://api.stlouisfed.org/fred/series/observations?series_id=PCOPPUSDM",
      "&observation_start=2012-01-01&observation_end=2023-12-31",
      "&api_key=", fred_key, "&file_type=json"
    )
    fred_resp <- fromJSON(readLines(fred_url, warn = FALSE))
    copper_prices <- fred_resp$observations %>%
      transmute(
        date = as.Date(date),
        year = year(date),
        month = month(date),
        copper_price_usd = as.numeric(value)
      ) %>%
      filter(!is.na(copper_price_usd))
    cat("  Copper price observations:", nrow(copper_prices), "\n")
  } else {
    stop("Neither WB commodity nor FRED API available for copper prices")
  }
} else {
  copper_prices <- copper_resp[[2]] %>%
    transmute(
      date = as.Date(paste0(date, "-01")),
      year = year(date),
      month = month(date),
      copper_price_usd = as.numeric(value)
    ) %>%
    filter(!is.na(copper_price_usd))
}

stopifnot(nrow(copper_prices) > 20)
saveRDS(copper_prices, "../data/copper_prices.rds")

cat("\n=== Data fetch complete ===\n")
cat("Files saved to ../data/:\n")
cat("  zmb_districts.rds\n  ntl_annual_raw.rds\n  wb_zambia.rds\n  copper_prices.rds\n")
