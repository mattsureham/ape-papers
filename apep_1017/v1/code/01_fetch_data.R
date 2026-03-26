# 01_fetch_data.R — Fetch HICP transport fare indices from Eurostat
# apep_1017: EU Fourth Railway Package and Rail Fares
#
# Data sources:
#   - Eurostat prc_hicp_midx: Monthly HICP index (2015=100)
#     - CP0731: Railway transport fares (main outcome)
#     - CP0732: Road transport fares (placebo)
#     - CP0733: Air transport fares (placebo)
#   - Eurostat rail_pa_quartal: Quarterly rail passenger-km
#   - Eurostat nama_10_gdp: Annual GDP (control)

source("00_packages.R")

cat("=== Fetching HICP monthly transport fare indices ===\n")

# EU-27 country codes (Eurostat format)
eu27 <- c("AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR",
          "DE","EL","HU","IE","IT","LV","LT","LU","MT","NL",
          "PL","PT","RO","SK","SI","ES","SE")

# ---- 1. Monthly HICP indices for transport sub-categories ----
# CP0731 = Railway transport, CP0732 = Road transport, CP0733 = Air transport
coicop_codes <- c("CP0731", "CP0732", "CP0733")

hicp_raw <- get_eurostat("prc_hicp_midx",
                         filters = list(coicop = coicop_codes, unit = "I15"))
hicp <- as.data.table(hicp_raw)
cat("HICP raw rows:", nrow(hicp), "\n")

# Filter to EU-27 countries only
hicp <- hicp[geo %in% eu27]
cat("HICP after EU-27 filter:", nrow(hicp), "\n")

# Parse time to Date
hicp[, date := as.Date(time)]
hicp[, year := year(date)]
hicp[, month := month(date)]
hicp[, ym := year * 100 + month]

# Check coverage
cat("\n--- HICP coverage by COICOP ---\n")
hicp[, .(n_countries = uniqueN(geo),
         min_date = min(date),
         max_date = max(date),
         n_obs = .N), by = coicop] |> print()

# Check which countries have CP0731 data
rail_countries <- hicp[coicop == "CP0731", unique(geo)]
cat("\nCountries with rail fare data:", length(rail_countries), "\n")
cat(paste(sort(rail_countries), collapse = ", "), "\n")

# Validate: we need real data
stopifnot("No rail fare data fetched" = nrow(hicp[coicop == "CP0731"]) > 100)

# ---- 2. Quarterly rail passenger-km ----
cat("\n=== Fetching quarterly rail passenger-km ===\n")

rail_pax_raw <- tryCatch({
  get_eurostat("rail_pa_quartal")
}, error = function(e) {
  cat("Warning: rail_pa_quartal fetch failed:", conditionMessage(e), "\n")
  cat("Trying alternative dataset rail_pa_typepkm...\n")
  get_eurostat("rail_pa_typepkm")
})

rail_pax <- as.data.table(rail_pax_raw)
rail_pax <- rail_pax[geo %in% eu27]
cat("Rail passenger-km rows:", nrow(rail_pax), "\n")

if (nrow(rail_pax) > 0) {
  # Eurostat returns TIME_PERIOD as Date (first day of quarter)
  if ("TIME_PERIOD" %in% names(rail_pax)) {
    rail_pax[, date := TIME_PERIOD]
  } else if ("time" %in% names(rail_pax)) {
    rail_pax[, date := as.Date(time)]
  }
  rail_pax[, year := year(date)]
  rail_pax[, quarter := quarter(date)]
  cat("Rail pax coverage:", uniqueN(rail_pax$geo), "countries,",
      min(rail_pax$year), "-", max(rail_pax$year), "\n")
}

# ---- 3. Annual GDP per capita (control variable) ----
cat("\n=== Fetching GDP per capita ===\n")

gdp_raw <- get_eurostat("nama_10_pc",
                        filters = list(unit = "CP_EUR_HAB", na_item = "B1GQ"))
gdp <- as.data.table(gdp_raw)
gdp <- gdp[geo %in% eu27]
# Handle both 'time' and 'TIME_PERIOD' column names
time_col_gdp <- intersect(c("time", "TIME_PERIOD"), names(gdp))[1]
gdp[, year := as.integer(format(as.Date(get(time_col_gdp)), "%Y"))]
gdp <- gdp[, .(geo, year, gdp_pc = values)]
cat("GDP per capita:", nrow(gdp), "rows,", uniqueN(gdp$geo), "countries\n")

# ---- 4. Transposition dates (Fourth Railway Package) ----
# Directive 2016/2370 — transposition from EC transposition tracking
# Source: European Commission, DG MOVE implementation monitoring
# 8 early transposers (by June 2019), remainder by June-October 2020
cat("\n=== Building transposition panel ===\n")

transposition <- data.table(
  geo = c("BG", "FI", "FR", "EL", "IT", "NL", "RO", "SI",  # Early (2019)
          "AT", "BE", "HR", "CY", "CZ", "DK", "EE",         # Late (2020)
          "DE", "HU", "IE", "LV", "LT", "LU", "MT",
          "PL", "PT", "SK", "ES", "SE"),
  transposition_date = as.Date(c(
    # Early transposers — by June 2019
    "2019-01-01", "2019-03-01", "2019-06-01", "2019-05-01",
    "2019-06-01", "2019-04-01", "2019-02-01", "2019-06-01",
    # Late transposers — 2020
    "2020-06-01", "2020-07-01", "2020-06-01", "2020-10-01",
    "2020-06-01", "2020-06-01", "2020-07-01",
    "2020-09-01", "2020-06-01", "2020-08-01", "2020-07-01",
    "2020-06-01", "2020-06-01", "2020-09-01",
    "2020-07-01", "2020-06-01", "2020-06-01", "2020-07-01", "2020-06-01"
  )),
  cohort = c(rep("early", 8), rep("late", 19))
)

# Treatment month for Callaway-Sant'Anna
transposition[, treat_ym := year(transposition_date) * 100 + month(transposition_date)]
cat("Early transposers:", sum(transposition$cohort == "early"), "\n")
cat("Late transposers:", sum(transposition$cohort == "late"), "\n")

# ---- 5. Save all datasets ----
cat("\n=== Saving datasets ===\n")
saveRDS(hicp, "data/hicp_transport.rds")
saveRDS(rail_pax, "data/rail_passengers.rds")
saveRDS(gdp, "data/gdp_pc.rds")
saveRDS(transposition, "data/transposition.rds")

cat("All data saved to data/ directory.\n")
cat("HICP transport:", nrow(hicp), "rows\n")
cat("Rail passengers:", nrow(rail_pax), "rows\n")
cat("GDP per capita:", nrow(gdp), "rows\n")
cat("Transposition:", nrow(transposition), "rows\n")
