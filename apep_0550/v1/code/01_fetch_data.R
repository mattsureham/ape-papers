## 01_fetch_data.R — Fetch commodity price data
## apep_0550: India Farm Laws Symmetric Natural Experiment
##
## Primary data source: WFP/VAM food price monitoring data from HDX
## (Humanitarian Data Exchange). This dataset provides monthly commodity
## prices from markets across India, sourced originally from government
## reporting systems including AGMARKNET mandis.
##
## URL: https://data.humdata.org/dataset/wfp-food-prices-for-india

source("00_packages.R")

DATA_DIR <- file.path(dirname(getwd()), "data")
dir.create(DATA_DIR, recursive = TRUE, showWarnings = FALSE)

PRICES_URL <- "https://data.humdata.org/dataset/dc663585-4b6f-46ae-a6d6-b2f3e4ea32b5/resource/3b1ff071-6b01-4998-aa62-2f3efb5d4888/download/wfp_food_prices_ind.csv"
MARKETS_URL <- "https://data.humdata.org/dataset/dc663585-4b6f-46ae-a6d6-b2f3e4ea32b5/resource/a8fed7ab-5e3f-4f1f-86ec-5ef0a92ad1be/download/wfp_markets_ind.csv"

prices_file <- file.path(DATA_DIR, "wfp_food_prices_ind.csv")
markets_file <- file.path(DATA_DIR, "wfp_markets_ind.csv")

## Download if not already present
if (!file.exists(prices_file)) {
  cat("Downloading WFP food prices for India...\n")
  download.file(PRICES_URL, prices_file, mode = "wb", quiet = FALSE)
} else {
  cat("WFP prices file already exists, skipping download.\n")
}

if (!file.exists(markets_file)) {
  cat("Downloading WFP markets for India...\n")
  download.file(MARKETS_URL, markets_file, mode = "wb", quiet = FALSE)
} else {
  cat("WFP markets file already exists, skipping download.\n")
}

## Load and validate
prices <- fread(prices_file)
markets <- fread(markets_file)

cat("\n=== DATA VALIDATION ===\n")
cat("Price records:", nrow(prices), "\n")
cat("Market records:", nrow(markets), "\n")
cat("Columns:", paste(names(prices), collapse = ", "), "\n")
cat("Date range:", min(prices$date), "to", max(prices$date), "\n")
cat("States:", uniqueN(prices$admin1), "\n")
cat("Commodities:", uniqueN(prices$commodity), "\n")

## Filter to analysis period and target commodities
target_comms <- c("Rice", "Wheat", "Onions", "Potatoes", "Tomatoes")
prices_filtered <- prices[
  date >= "2018-01-01" & date <= "2023-12-31" &
  commodity %in% target_comms
]

cat("\n=== FILTERED DATA ===\n")
cat("Records in 2018-2023 for target commodities:", nrow(prices_filtered), "\n")
cat("States:", uniqueN(prices_filtered$admin1), "\n")
cat("Commodities:", paste(unique(prices_filtered$commodity), collapse = ", "), "\n")

## Data validation assertions
stopifnot("Expected 15+ states" = uniqueN(prices_filtered$admin1) >= 15)
stopifnot("Expected 5 target commodities" = uniqueN(prices_filtered$commodity) == 5)
stopifnot("Expected 10000+ records" = nrow(prices_filtered) >= 10000)

## Save filtered data
fwrite(prices_filtered, file.path(DATA_DIR, "prices_filtered.csv"))
cat("\nFiltered data saved:", nrow(prices_filtered), "rows\n")

cat("\n=== DATA FETCH COMPLETE ===\n")
