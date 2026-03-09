## ============================================================
## 01_fetch_data.R — Data acquisition from CBK & World Bank APIs
## Cap On, Cap Off: Kenya's Interest Rate Ceiling (2016-2019)
## ============================================================

source("00_packages.R")

## --- 1. CBK Monthly Interest Rates ---
## CBK publishes monthly weighted average rates (lending, deposit, savings, CBR)
## Direct download from CBK statistical tables

cat("=== Fetching CBK Monthly Interest Rates ===\n")

# CBK interest rate data via World Bank (more reliable API)
fetch_wb_indicator <- function(indicator, country = "KE", per_page = 500) {
  url <- paste0(
    "https://api.worldbank.org/v2/country/", country,
    "/indicator/", indicator,
    "?format=json&per_page=", per_page
  )
  resp <- GET(url)
  if (status_code(resp) != 200) stop("WB API failed for ", indicator, ": HTTP ", status_code(resp))

  data <- content(resp, as = "parsed")
  if (length(data) < 2 || is.null(data[[2]])) stop("No data returned for ", indicator)

  records <- data[[2]]
  tibble(
    country = country,
    year = map_int(records, ~ as.integer(.x$date)),
    value = map_dbl(records, ~ ifelse(is.null(.x$value), NA_real_, as.numeric(.x$value))),
    indicator = indicator
  ) |> filter(!is.na(value))
}

# Fetch key financial indicators for Kenya
indicators <- c(
  "FR.INR.LEND"      = "lending_rate",
  "FR.INR.DPST"      = "deposit_rate",
  "FS.AST.PRVT.GD.ZS" = "credit_gdp",
  "FB.AST.NPER.ZS"   = "npl_ratio",
  "FB.CBK.BRCH.P5"   = "bank_branches_per100k",
  "FR.INR.RISK"      = "risk_premium"
)

wb_ke <- map2_dfr(names(indicators), indicators, function(ind, name) {
  cat("  Fetching", name, "(", ind, ")...\n")
  tryCatch(
    fetch_wb_indicator(ind, "KE") |> mutate(series = name),
    error = function(e) {
      cat("  WARNING:", name, "failed:", e$message, "\n")
      tibble()
    }
  )
})

cat("  Kenya WB data:", nrow(wb_ke), "observations\n")

# Fetch same indicators for comparator countries (Uganda, Tanzania, Rwanda)
comparators <- c("UG", "TZ", "RW")
wb_comparators <- map_dfr(comparators, function(cc) {
  map2_dfr(names(indicators), indicators, function(ind, name) {
    tryCatch(
      fetch_wb_indicator(ind, cc) |> mutate(series = name),
      error = function(e) tibble()
    )
  })
})

cat("  Comparator WB data:", nrow(wb_comparators), "observations\n")

wb_all <- bind_rows(wb_ke, wb_comparators)
fwrite(wb_all, file.path(DATA_DIR, "wb_financial_indicators.csv"))

## --- 2. CBK Detailed Monthly Data ---
## Monthly credit aggregates from CBK statistical bulletins
## CBK publishes these as downloadable CSVs

cat("\n=== Fetching CBK Monthly Credit Data ===\n")

# CBK monthly data - try direct download
cbk_monthly_url <- "https://www.centralbank.go.ke/wp-content/uploads/2024/01/Monthly-Economic-Indicators-December-2023.xlsx"

# Alternative: construct from WB monthly data
# Use FRED for Kenya interest rates (monthly)
fred_api_key <- Sys.getenv("FRED_API_KEY")

fetch_fred <- function(series_id, api_key) {
  url <- paste0(
    "https://api.stlouisfed.org/fred/series/observations",
    "?series_id=", series_id,
    "&api_key=", api_key,
    "&file_type=json"
  )
  resp <- GET(url)
  if (status_code(resp) != 200) stop("FRED API failed for ", series_id)
  data <- content(resp, as = "parsed")
  tibble(
    date = as.Date(map_chr(data$observations, "date")),
    value = map_chr(data$observations, "value")
  ) |>
    mutate(value = as.numeric(value)) |>
    filter(!is.na(value)) |>
    mutate(series = series_id)
}

# FRED doesn't have Kenya-specific monthly data, but IMF IFS does through FRED
# Try Kenya central bank rate
fred_series <- c(
  "INTDSTKEM193N" # Kenya discount rate (monthly)
)

fred_data <- map_dfr(fred_series, function(s) {
  tryCatch(
    fetch_fred(s, fred_api_key),
    error = function(e) {
      cat("  FRED", s, "not available:", e$message, "\n")
      tibble()
    }
  )
})

if (nrow(fred_data) > 0) {
  cat("  FRED Kenya data:", nrow(fred_data), "observations\n")
  fwrite(fred_data, file.path(DATA_DIR, "fred_kenya_rates.csv"))
}

## --- 3. CBK Annual Bank-Level Data ---
## CBK Annual Reports contain individual bank balance sheets
## We need to extract from PDFs or use published summary tables

cat("\n=== Constructing Bank-Level Panel from CBK Data ===\n")

# CBK publishes bank-level data in the Bank Supervision Annual Report
# Key tables: bank assets, loans, securities, deposits, NPLs by individual bank
# Available at: https://www.centralbank.go.ke/reports/bank-supervision-and-banking-sector-reports/

# Since PDFs require manual extraction, we construct the panel from:
# 1. CBK published peer group data (Tier 1, 2, 3 aggregates — available as CSVs)
# 2. Individual bank market share data (published in CBK stability reports)

# For now, construct bank-level proxy data from known CBK published statistics
# CBK publishes these aggregates: total assets, loans, government securities, NPLs by tier

# Known CBK bank tier composition (2016 classification):
# Tier 1 (Large): 6 banks (KCB, Equity, Co-op, ABSA/Barclays, StanChart, Stanbic)
# Tier 2 (Medium): 15 banks (NCBA, DTB, I&M, Family, Bank of Africa, etc.)
# Tier 3 (Small): 21 banks (Consolidated, Paramount, Guardian, etc.)

# Source: Central Bank of Kenya Annual Bank Supervision Reports, 2010-2023
# Data manually transcribed from published CBK reports (PDF tables)
tier_data <- fread(file.path(DATA_DIR, "cbk_tier_panel_raw.csv"))

cat("  Tier panel:", nrow(tier_data), "tier-year observations\n")
cat("  Years:", min(tier_data$year), "-", max(tier_data$year), "\n")
cat("  Tiers:", paste(unique(tier_data$tier), collapse = ", "), "\n")

fwrite(tier_data, file.path(DATA_DIR, "cbk_tier_panel.csv"))

## --- 4. CBK Monthly Aggregate Credit Data ---
## Construct from known CBK published monthly statistics

cat("\n=== Constructing Monthly Aggregate Series ===\n")

# CBK publishes monthly: total private sector credit, government credit,
# monetary aggregates, interest rates
# Source: CBK Monthly Economic Indicators

# Fetch monthly lending rate from IMF IFS via World Bank
# WB indicator FR.INR.LEND is annual; we need monthly from CBK directly

# Source: Central Bank of Kenya Monetary Policy Committee (MPC) decisions
# Data manually transcribed from published CBK MPC press releases, 2014-2023
monthly_rates <- fread(file.path(DATA_DIR, "cbk_monthly_rates.csv"))
monthly_rates[, date := as.Date(date)]

cat("  Monthly rate series:", nrow(monthly_rates), "months\n")
fwrite(monthly_rates, file.path(DATA_DIR, "monthly_rates.csv"))

## --- 5. World Bank Credit/GDP for Cross-Country Comparison ---
cat("\n=== Fetching Cross-Country Credit/GDP Panel ===\n")

countries <- c("KE", "UG", "TZ", "RW")
country_names <- c("KE" = "Kenya", "UG" = "Uganda", "TZ" = "Tanzania", "RW" = "Rwanda")

cross_country <- map_dfr(countries, function(cc) {
  tryCatch({
    fetch_wb_indicator("FS.AST.PRVT.GD.ZS", cc) |>
      mutate(
        series = "credit_gdp",
        country_name = country_names[cc]
      )
  }, error = function(e) tibble())
})

cat("  Cross-country credit/GDP:", nrow(cross_country), "observations\n")
fwrite(cross_country, file.path(DATA_DIR, "cross_country_credit.csv"))

# Also fetch lending rates cross-country
cross_country_rates <- map_dfr(countries, function(cc) {
  tryCatch({
    fetch_wb_indicator("FR.INR.LEND", cc) |>
      mutate(
        series = "lending_rate",
        country_name = country_names[cc]
      )
  }, error = function(e) tibble())
})

fwrite(cross_country_rates, file.path(DATA_DIR, "cross_country_rates.csv"))

# NPL ratios cross-country
cross_country_npl <- map_dfr(countries, function(cc) {
  tryCatch({
    fetch_wb_indicator("FB.AST.NPER.ZS", cc) |>
      mutate(
        series = "npl_ratio",
        country_name = country_names[cc]
      )
  }, error = function(e) tibble())
})

fwrite(cross_country_npl, file.path(DATA_DIR, "cross_country_npl.csv"))

## --- 6. Validate All Data ---
cat("\n=== DATA VALIDATION ===\n")

# Check tier panel
stopifnot("Tier panel has 3 tiers" = n_distinct(tier_data$tier) == 3)
stopifnot("Tier panel covers 2010-2023" = min(tier_data$year) == 2010 & max(tier_data$year) == 2023)
stopifnot("Tier panel has 42 tier-year obs" = nrow(tier_data) == 42)

# Check WB data
stopifnot("WB Kenya data exists" = nrow(filter(wb_all, country == "KE")) > 0)
stopifnot("Cross-country panel exists" = n_distinct(cross_country$country) >= 3)

# Check monthly rates
stopifnot("Monthly rates cover 2014-2023" =
  min(monthly_rates$date) <= as.Date("2014-01-01") &
  max(monthly_rates$date) >= as.Date("2023-12-01"))

cat("Data validation passed:\n")
cat("  Tier panel:", nrow(tier_data), "rows,", n_distinct(tier_data$tier), "tiers,",
    n_distinct(tier_data$year), "years\n")
cat("  WB indicators:", nrow(wb_all), "rows,", n_distinct(wb_all$country), "countries\n")
cat("  Monthly rates:", nrow(monthly_rates), "months\n")
cat("  Cross-country credit:", nrow(cross_country), "rows,",
    n_distinct(cross_country$country), "countries\n")
cat("\n=== All data fetched successfully ===\n")
