## 01_fetch_data.R — Wrapper that calls Python fetcher then validates
## apep_0553: Do Export Controls Have Teeth?
##
## The actual API fetching is done by 01_fetch_data.py (Python handles
## the Comtrade API rate limiting more efficiently).

source("00_packages.R")

DATA_DIR <- "../data"

## Build CSV from cached API responses
cat("Building CSV from cached Comtrade API responses...\n")
exit_code <- system2("python3", "01_build_from_cache.py", stdout = "", stderr = "")
if (exit_code != 0) {
  stop("Cache builder failed with exit code ", exit_code)
}

## Load and validate
trade_raw <- fread(file.path(DATA_DIR, "comtrade_raw.csv"))

cat("\n=== R VALIDATION ===\n")
cat("Raw data loaded:", nrow(trade_raw), "rows\n")
cat("Reporters:", length(unique(trade_raw$reporter_code)), "\n")
cat("HS6 products:", length(unique(trade_raw$hs6)), "\n")
cat("Years:", paste(sort(unique(trade_raw$year)), collapse = ", "), "\n")
cat("CHPL rows:", sum(trade_raw$is_chpl == 1), "\n")
cat("Non-CHPL rows:", sum(trade_raw$is_chpl == 0), "\n")
cat("Positive trade:", sum(trade_raw$fob_value > 0), "\n")

## === DATA VALIDATION (required) ===
stopifnot("Expected 2+ reporters" = length(unique(trade_raw$reporter_code)) >= 2)
stopifnot("Expected 5+ years" = length(unique(trade_raw$year)) >= 5)
stopifnot("Expected CHPL products" = sum(trade_raw$is_chpl == 1) > 0)
stopifnot("Expected non-CHPL products" = sum(trade_raw$is_chpl == 0) > 0)
cat("\nData validation passed.\n")
