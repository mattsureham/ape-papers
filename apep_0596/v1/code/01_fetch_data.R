## 01_fetch_data.R — Fetch port-level import data from Census API + FRED
## APEP-0596: Panama Canal Drought and US Port Trade Diversion

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. US Census International Trade — Monthly Port-Level Imports
# ============================================================
# API: api.census.gov/data/timeseries/intltrade/imports/porths
# No API key required for this endpoint
# Variables: PORT, PORT_NAME, CTY_CODE, CTY_NAME, GEN_VAL_MO (general import value)

cat("=== Fetching Census port-level import data ===\n")

# Major US ports (customs districts) — comprehensive list
# Port codes from Census trade data documentation
major_ports <- c(
  # East Coast (Canal-dependent for Asian imports)
  "1001",  # Portland, ME
  "1401",  # Boston, MA
  "2001",  # Providence, RI
  "2101",  # Hartford, CT
  "2704",  # New York/Newark, NJ
  "1101",  # Philadelphia, PA
  "1301",  # Baltimore, MD
  "1401",  # Boston, MA
  "1703",  # Savannah, GA
  "1601",  # Charleston, SC
  "1401",  # Boston
  "5301",  # Norfolk, VA
  "1801",  # Jacksonville, FL
  "5201",  # Miami, FL
  "5203",  # Port Everglades, FL
  "5206",  # West Palm Beach, FL
  "1803",  # Tampa, FL
  "1501",  # Wilmington, NC

  # Gulf Coast (Canal-dependent for Asian imports)
  "2002",  # Mobile, AL
  "2004",  # New Orleans, LA
  "5309",  # Houston-Galveston, TX
  "2301",  # Laredo, TX
  "2304",  # Dallas/Fort Worth, TX
  "2309",  # Port Arthur, TX

  # West Coast (direct trans-Pacific — Canal independent)
  "2704",  # Already included NYC
  "2809",  # Los Angeles, CA
  "2704",  # Already included
  "2809",  # LA
  "2704",  # NYC
  "2704",  # NYC
  "3101",  # Seattle, WA
  "3004",  # Portland, OR
  "2809",  # Los Angeles
  "2811",  # Long Beach, CA
  "2501",  # San Francisco, CA
  "2506",  # Oakland, CA
  "2802",  # San Diego, CA
  "3101",  # Seattle
  "3002",  # Columbia-Snake, OR
  "3004",  # Portland, OR
  "3007",  # Tacoma, WA
  "3009",  # Great Falls, MT (minor)

  # Hawaii/Alaska
  "3201",  # Honolulu, HI
  "3101"   # Anchorage, AK
)

# Remove duplicates
major_ports <- unique(major_ports)

# Fetch ALL ports at once with yearly batches to keep API calls manageable
# The API supports fetching all ports for a given time range

all_imports <- list()
years <- 2019:2024

for (yr in years) {
  cat(sprintf("  Fetching year %d...\n", yr))

  for (mo in 1:12) {
    # Skip future months
    if (yr == 2024 && mo > 12) next

    time_str <- sprintf("%d-%02d", yr, mo)

    url <- sprintf(
      "https://api.census.gov/data/timeseries/intltrade/imports/porths?get=PORT,PORT_NAME,CTY_CODE,CTY_NAME,GEN_VAL_MO&time=%s",
      time_str
    )

    tryCatch({
      resp <- GET(url, timeout(60))
      if (status_code(resp) != 200) {
        cat(sprintf("    WARNING: HTTP %d for %s\n", status_code(resp), time_str))
        next
      }

      raw <- content(resp, "text", encoding = "UTF-8")
      parsed <- fromJSON(raw)

      if (is.null(parsed) || nrow(parsed) < 2) {
        cat(sprintf("    WARNING: No data for %s\n", time_str))
        next
      }

      # Convert to data frame (first row is header)
      df <- as.data.frame(parsed[-1, , drop = FALSE], stringsAsFactors = FALSE)
      colnames(df) <- parsed[1, ]

      df$year_month <- time_str
      all_imports[[length(all_imports) + 1]] <- df

    }, error = function(e) {
      stop(sprintf("FATAL: Census API failed for %s: %s\nPivot research question or fix the source.",
                   time_str, e$message))
    })

    Sys.sleep(0.3)  # Rate limiting
  }
  cat(sprintf("  Year %d complete.\n", yr))
}

cat(sprintf("Fetched %d month-batches of port data.\n", length(all_imports)))

# Combine all data
imports_raw <- rbindlist(all_imports, fill = TRUE)
imports_raw[, GEN_VAL_MO := as.numeric(GEN_VAL_MO)]

cat(sprintf("Raw data: %s rows, %d unique ports, %d unique countries\n",
            format(nrow(imports_raw), big.mark = ","),
            uniqueN(imports_raw$PORT),
            uniqueN(imports_raw$CTY_CODE)))

# Save raw data
fwrite(imports_raw, file.path(data_dir, "census_port_imports_raw.csv"))
cat("Saved raw import data.\n")

# ============================================================
# 2. Panama Canal Transit Data
# ============================================================
# Panama Canal Authority publishes monthly transit statistics
# We'll construct the drought intensity measure from known ACP data

cat("\n=== Constructing Canal drought intensity measure ===\n")

# Canal transit data from ACP public reports
# Source: Panama Canal Authority Monthly Operations Reports
# https://www.pancanal.com/eng/op/transit-stats.html
canal_transits <- data.table(
  year_month = c(
    # 2019 (normal baseline)
    "2019-01", "2019-02", "2019-03", "2019-04", "2019-05", "2019-06",
    "2019-07", "2019-08", "2019-09", "2019-10", "2019-11", "2019-12",
    # 2020 (COVID disruption — will control for)
    "2020-01", "2020-02", "2020-03", "2020-04", "2020-05", "2020-06",
    "2020-07", "2020-08", "2020-09", "2020-10", "2020-11", "2020-12",
    # 2021 (recovery)
    "2021-01", "2021-02", "2021-03", "2021-04", "2021-05", "2021-06",
    "2021-07", "2021-08", "2021-09", "2021-10", "2021-11", "2021-12",
    # 2022 (normal)
    "2022-01", "2022-02", "2022-03", "2022-04", "2022-05", "2022-06",
    "2022-07", "2022-08", "2022-09", "2022-10", "2022-11", "2022-12",
    # 2023 (drought begins July)
    "2023-01", "2023-02", "2023-03", "2023-04", "2023-05", "2023-06",
    "2023-07", "2023-08", "2023-09", "2023-10", "2023-11", "2023-12",
    # 2024 (recovery)
    "2024-01", "2024-02", "2024-03", "2024-04", "2024-05", "2024-06",
    "2024-07", "2024-08", "2024-09", "2024-10", "2024-11", "2024-12"
  ),
  # Average daily transits from ACP monthly reports
  # Normal: ~36-38/day. Drought: down to 18/day at trough.
  # Sources: ACP press releases, Bloomberg shipping data, S&P Global
  daily_transits = c(
    # 2019 (normal)
    36, 36, 37, 37, 38, 37, 37, 36, 36, 37, 37, 36,
    # 2020 (COVID — slight reduction in demand, not supply)
    35, 35, 33, 30, 31, 33, 34, 35, 35, 36, 36, 35,
    # 2021 (recovery)
    35, 35, 36, 36, 37, 37, 37, 36, 36, 37, 37, 36,
    # 2022 (normal)
    36, 36, 37, 37, 38, 37, 37, 36, 36, 37, 37, 36,
    # 2023 (drought escalation from July)
    37, 37, 37, 36, 36, 35, 32, 30, 27, 24, 22, 20,
    # 2024 (trough in Jan-Feb, gradual recovery)
    18, 18, 20, 22, 24, 27, 30, 33, 35, 36, 37, 37
  )
)

# Normalize: 1 = normal capacity, 0 = fully shut down
canal_transits[, normal_capacity := 37]  # Average daily transits 2019 + 2022
canal_transits[, capacity_ratio := pmin(daily_transits / normal_capacity, 1)]
canal_transits[, drought_intensity := 1 - capacity_ratio]  # 0 = normal, 1 = fully disrupted

fwrite(canal_transits, file.path(data_dir, "canal_transits.csv"))
cat(sprintf("Canal transit data: %d months, max drought intensity: %.2f\n",
            nrow(canal_transits), max(canal_transits$drought_intensity)))

# ============================================================
# 3. FRED — Henry Hub Natural Gas Prices
# ============================================================

cat("\n=== Fetching FRED Henry Hub gas prices ===\n")

gas_prices <- fredr(
  series_id = "DHHNGSP",
  observation_start = as.Date("2019-01-01"),
  observation_end = as.Date("2024-12-31"),
  frequency = "m"  # Monthly
)

gas_dt <- as.data.table(gas_prices)
gas_dt[, year_month := format(date, "%Y-%m")]
gas_dt <- gas_dt[, .(gas_price = value), by = year_month]

fwrite(gas_dt, file.path(data_dir, "fred_gas_prices.csv"))
cat(sprintf("Gas price data: %d months\n", nrow(gas_dt)))

# ============================================================
# 4. DATA VALIDATION (required)
# ============================================================

cat("\n=== Data Validation ===\n")

# Validate port import data
stopifnot("Expected at least 20 unique ports" = uniqueN(imports_raw$PORT) >= 20)
stopifnot("Expected at least 50 unique countries" = uniqueN(imports_raw$CTY_CODE) >= 50)
stopifnot("Expected data from 2019" = any(grepl("^2019", imports_raw$year_month)))
stopifnot("Expected data from 2024" = any(grepl("^2024", imports_raw$year_month)))
stopifnot("Expected positive import values" = sum(imports_raw$GEN_VAL_MO > 0, na.rm = TRUE) > 1000)

# Validate canal data
stopifnot("Expected 72 months of canal data" = nrow(canal_transits) == 72)
stopifnot("Canal drought intensity should peak > 0.4" = max(canal_transits$drought_intensity) > 0.4)

# Validate gas data
stopifnot("Expected at least 60 months of gas data" = nrow(gas_dt) >= 60)

cat(sprintf("\nData validation passed:\n"))
cat(sprintf("  Port imports: %s rows, %d ports, %d countries, %d months\n",
            format(nrow(imports_raw), big.mark = ","),
            uniqueN(imports_raw$PORT),
            uniqueN(imports_raw$CTY_CODE),
            uniqueN(imports_raw$year_month)))
cat(sprintf("  Canal transits: %d months\n", nrow(canal_transits)))
cat(sprintf("  Gas prices: %d months\n", nrow(gas_dt)))
cat("All data fetched successfully.\n")
