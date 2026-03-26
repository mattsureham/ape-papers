## 01_fetch_data.R — Fetch Eurostat packaging waste data
## apep_1030: EU Deposit Return Schemes and Packaging Waste Recycling

source("00_packages.R")

cat("=== Fetching Eurostat data ===\n")

# ---------------------------------------------------------------
# 1. Recycling rate of packaging waste by type (cei_wm020)
# ---------------------------------------------------------------
cat("Fetching cei_wm020 (recycling rates)...\n")
cei_raw <- get_eurostat("cei_wm020", time_format = "num")

if (is.null(cei_raw) || nrow(cei_raw) == 0) {
  stop("FATAL: cei_wm020 returned no data. Cannot proceed.")
}

cat(sprintf("  cei_wm020: %d rows, years %.0f-%.0f, %d countries\n",
            nrow(cei_raw),
            min(cei_raw$TIME_PERIOD, na.rm = TRUE),
            max(cei_raw$TIME_PERIOD, na.rm = TRUE),
            n_distinct(cei_raw$geo)))

saveRDS(cei_raw, "../data/cei_wm020_raw.rds")

# ---------------------------------------------------------------
# 2. Packaging waste generation and treatment (env_waspac)
# ---------------------------------------------------------------
cat("Fetching env_waspac (packaging waste tonnes)...\n")
env_raw <- get_eurostat("env_waspac", time_format = "num")

if (is.null(env_raw) || nrow(env_raw) == 0) {
  stop("FATAL: env_waspac returned no data. Cannot proceed.")
}

cat(sprintf("  env_waspac: %d rows, years %.0f-%.0f, %d countries\n",
            nrow(env_raw),
            min(env_raw$TIME_PERIOD, na.rm = TRUE),
            max(env_raw$TIME_PERIOD, na.rm = TRUE),
            n_distinct(env_raw$geo)))

saveRDS(env_raw, "../data/env_waspac_raw.rds")

# ---------------------------------------------------------------
# 3. DRS adoption dates (hand-coded from TOMRA/Reloop/EU sources)
# ---------------------------------------------------------------
# Note: Only countries adopting within or before the Eurostat data window.
# Nordic countries with pre-2000 DRS: Finland (1952), Sweden (1984),
# Denmark (2002), Norway (1999, non-EU). These are "always treated."
# Germany (2003) also effectively always-treated if data starts ~2005.

drs_dates <- tribble(
  ~geo,  ~country_name,     ~drs_year, ~deposit_eur,
  "DE",  "Germany",          2003,      0.25,
  "EE",  "Estonia",          2005,      0.10,
  "HR",  "Croatia",          2006,      0.07,
  "FI",  "Finland",          1996,      0.20,   # PET bottles; cans since 1952

  "SE",  "Sweden",           1984,      0.10,
  "DK",  "Denmark",          2002,      0.13,
  "LT",  "Lithuania",        2016,      0.10,
  "NL",  "Netherlands",      2021,      0.15,   # small PET 2021, cans 2023
  "SK",  "Slovakia",         2022,      0.12,
  "LV",  "Latvia",           2022,      0.10,
  "MT",  "Malta",            2022,      0.10,
  "RO",  "Romania",          2023,      0.13,
  "HU",  "Hungary",          2024,      0.10,   # beyond data window
  "IE",  "Ireland",          2024,      0.15,   # beyond data window
  "AT",  "Austria",          2025,      0.25,   # beyond data window
  "PL",  "Poland",           2025,      0.50    # beyond data window
)

saveRDS(drs_dates, "../data/drs_dates.rds")

cat(sprintf("  DRS dates: %d countries with adoption dates\n", nrow(drs_dates)))
cat("=== Data fetch complete ===\n")
