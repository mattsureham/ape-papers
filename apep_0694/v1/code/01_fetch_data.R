## 01_fetch_data.R — Fetch ABS building approvals via SDMX API
## apep_0694: HomeBuilder Net Additionality

source("00_packages.R")

# ------------------------------------------------------------------
# 1. Fetch ABS Building Approvals by state (monthly)
# ------------------------------------------------------------------
# ABS Building Approvals (8731.0) — total dwellings by state
# Using ABS SDMX REST API
# Dataflow: ABS,BA,1.0.0
# Dimensions: MEASURE (new houses=1, other res=2, total=3), REGION (states), FREQUENCY=M

cat("Fetching ABS building approvals data...\n")

# Try to get national + state level approvals for houses and other residential
# ABS SDMX endpoint
base_url <- "https://api.data.abs.gov.au/data"

# Fetch dwelling approvals by state - houses (new) and other residential
# Using the building approvals dataset
# Try the direct CSV approach first
abs_url <- paste0(
  base_url,
  "/ABS,BUILDING_APPROVALS,1.0.0/",
  "1+2+3.",       # Measures: houses, other res, total
  "1+2+3+4+5+6+7+8+AUS.",  # States + national (NSW=1, VIC=2, QLD=3, SA=4, WA=5, TAS=6, NT=7, ACT=8)
  "M",             # Monthly
  "?startPeriod=2016-01&endPeriod=2025-12",
  "&format=csv"
)

cat("URL:", abs_url, "\n")

# Download
resp <- GET(abs_url, timeout(120))
cat("HTTP status:", status_code(resp), "\n")

if (status_code(resp) == 200) {
  abs_raw <- content(resp, as = "text", encoding = "UTF-8")
  abs_df <- fread(text = abs_raw)
  cat(sprintf("ABS data: %d rows, %d columns\n", nrow(abs_df), ncol(abs_df)))
  cat("Columns:", paste(names(abs_df), collapse = ", "), "\n")
  fwrite(abs_df, "../data/abs_building_approvals.csv")
} else {
  # Try alternative SDMX query structure
  cat("First attempt failed, trying alternative structure...\n")

  # Try simpler query — all measures, all regions
  alt_url <- paste0(
    base_url,
    "/ABS,BA_GCCSA,1.0.0/",
    "all",
    "?startPeriod=2016-01&endPeriod=2025-12",
    "&format=csv"
  )

  resp2 <- GET(alt_url, timeout(120))
  cat("Alt HTTP status:", status_code(resp2), "\n")

  if (status_code(resp2) == 200) {
    abs_raw <- content(resp2, as = "text", encoding = "UTF-8")
    abs_df <- fread(text = abs_raw)
    cat(sprintf("ABS data (alt): %d rows, %d columns\n", nrow(abs_df), ncol(abs_df)))
    fwrite(abs_df, "../data/abs_building_approvals.csv")
  } else {
    # Try the data.gov.au endpoint
    cat("Trying data.gov.au endpoint...\n")

    # ABS building approvals total by state, seasonally adjusted
    abs_url3 <- "https://api.data.abs.gov.au/data/ABS,BA_SA2_ASGS16,1.0.0/all?startPeriod=2018-01&endPeriod=2024-12&format=csv&dimensionAtObservation=AllDimensions"

    resp3 <- GET(abs_url3, timeout(120))
    cat("HTTP status 3:", status_code(resp3), "\n")

    if (status_code(resp3) != 200) {
      # Final attempt: use the known working URL from smoke test
      cat("Trying original smoke test URL pattern...\n")

      # Download the ABS 8731.0 time series spreadsheet directly
      # This is the most reliable access method
      abs_ts_url <- "https://www.abs.gov.au/statistics/industry/building-and-construction/building-approvals-australia/latest-release/8731001.xlsx"

      download.file(abs_ts_url, "../data/abs_8731.xlsx", mode = "wb", quiet = FALSE)
      if (file.exists("../data/abs_8731.xlsx") && file.size("../data/abs_8731.xlsx") > 1000) {
        cat("Downloaded ABS 8731 spreadsheet successfully.\n")
        # Will parse in 02_clean_data.R
      } else {
        stop("FATAL: Cannot access ABS building approvals data from any source.")
      }
    }
  }
}

cat("Data fetch complete.\n")
