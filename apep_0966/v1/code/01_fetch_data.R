## 01_fetch_data.R — Fetch Eurostat HICP data and construct treatment variable
## apep_0966: EU Menthol Cigarette Ban

source("code/00_packages.R")

cat("=== Fetching Eurostat HICP monthly data ===\n")

# ------------------------------------------------------------------
# 1. Fetch monthly HICP index by COICOP for EU countries
# ------------------------------------------------------------------
# CP022 = Tobacco
# CP021 = Alcoholic beverages (placebo)
# CP011 = Food (placebo)
# CP031 = Clothing and footwear (placebo)
# CP00  = All items (control)

coicop_codes <- c("CP022", "CP021", "CP011", "CP031", "CP00")

hicp_raw <- eurostat::get_eurostat(
  id = "prc_hicp_midx",
  time_format = "date",
  filters = list(
    coicop = coicop_codes,
    unit = "I15"  # Index 2015=100
  )
)

stopifnot("Empty HICP data" = nrow(hicp_raw) > 0)
cat(sprintf("HICP raw: %d rows\n", nrow(hicp_raw)))

# ------------------------------------------------------------------
# 2. EU member states (EU27 + UK for pre-Brexit overlap)
# ------------------------------------------------------------------
eu_countries <- c(
  "AT", "BE", "BG", "CY", "CZ", "DE", "DK", "EE", "EL", "ES",
  "FI", "FR", "HR", "HU", "IE", "IT", "LT", "LU", "LV", "MT",
  "NL", "PL", "PT", "RO", "SE", "SI", "SK", "UK"
)

hicp <- hicp_raw |>
  filter(geo %in% eu_countries) |>
  rename(country = geo, date = time, index = values, category = coicop) |>
  select(country, date, category, index) |>
  mutate(
    year  = lubridate::year(date),
    month = lubridate::month(date)
  )

cat(sprintf("HICP filtered: %d rows, %d countries\n",
            nrow(hicp), n_distinct(hicp$country)))

# Verify we have tobacco data for enough countries
tobacco_countries <- hicp |>
  filter(category == "CP022", !is.na(index)) |>
  distinct(country) |>
  pull(country)

cat(sprintf("Countries with tobacco HICP: %d\n", length(tobacco_countries)))
stopifnot("Need at least 15 countries with tobacco HICP" = length(tobacco_countries) >= 15)

# ------------------------------------------------------------------
# 3. Pre-ban menthol market share by country
# ------------------------------------------------------------------
# Sources:
#   - Laverty et al. (2018), Tobacco Control: "Menthol and other flavours
#     in cigarettes and roll-your-own tobacco: use among European adults"
#   - Euromonitor International (2019) cited in European Commission TPD
#     impact assessment and Hiscock et al. (2018)
#   - Fong et al. (2016), ITC Project surveys
#   - Zatonski et al. (2021), Tob Prev Cessation: Poland data
#
# These are pre-ban menthol market shares (% of total cigarette market),
# reflecting approximately 2017-2019 data.

menthol_shares <- tribble(
  ~country, ~menthol_share, ~source,
  "PL",     0.280, "Zatonski et al. 2021; Euromonitor 2019",
  "FI",     0.150, "Laverty et al. 2018; Euromonitor 2019",
  "LT",     0.120, "Euromonitor 2019",
  "LV",     0.100, "Euromonitor 2019",
  "EE",     0.090, "Euromonitor 2019",
  "CZ",     0.080, "Euromonitor 2019",
  "SK",     0.070, "Euromonitor 2019",
  "DE",     0.060, "Laverty et al. 2018; Euromonitor 2019",
  "UK",     0.055, "ASH UK factsheet 2019",
  "HU",     0.050, "Euromonitor 2019",
  "NL",     0.045, "Laverty et al. 2018",
  "SE",     0.040, "Euromonitor 2019",
  "IE",     0.040, "Euromonitor 2019",
  "AT",     0.035, "Euromonitor 2019",
  "BE",     0.035, "Euromonitor 2019",
  "DK",     0.030, "Euromonitor 2019",
  "FR",     0.030, "Laverty et al. 2018; Euromonitor 2019",
  "BG",     0.025, "Euromonitor 2019",
  "RO",     0.025, "Euromonitor 2019",
  "HR",     0.020, "Euromonitor 2019",
  "SI",     0.020, "Euromonitor 2019",
  "PT",     0.020, "Euromonitor 2019",
  "LU",     0.020, "Euromonitor 2019",
  "IT",     0.030, "Laverty et al. 2018; Euromonitor 2019",
  "ES",     0.020, "Laverty et al. 2018; Euromonitor 2019",
  "EL",     0.020, "Euromonitor 2019",
  "CY",     0.015, "Euromonitor 2019",
  "MT",     0.015, "Euromonitor 2019"
)

cat(sprintf("Menthol shares: %d countries, range [%.1f%%, %.1f%%]\n",
            nrow(menthol_shares),
            min(menthol_shares$menthol_share) * 100,
            max(menthol_shares$menthol_share) * 100))

# ------------------------------------------------------------------
# 4. COVID stringency data (Oxford COVID-19 Government Response Tracker)
# ------------------------------------------------------------------
cat("=== Fetching OxCGRT COVID stringency data ===\n")

oxcgrt_url <- "https://raw.githubusercontent.com/OxCGRT/covid-policy-dataset/main/data/OxCGRT_compact_national_v1.csv"
oxcgrt_raw <- tryCatch(
  read_csv(oxcgrt_url, show_col_types = FALSE),
  error = function(e) {
    # Fallback URL
    oxcgrt_url2 <- "https://raw.githubusercontent.com/OxCGRT/covid-policy-tracker/master/data/OxCGRT_nat_latest.csv"
    tryCatch(
      read_csv(oxcgrt_url2, show_col_types = FALSE),
      error = function(e2) {
        stop("Cannot fetch OxCGRT data from either URL: ", e2$message)
      }
    )
  }
)

stopifnot("Empty OxCGRT data" = nrow(oxcgrt_raw) > 0)
cat(sprintf("OxCGRT raw: %d rows\n", nrow(oxcgrt_raw)))

# Map OxCGRT country codes to Eurostat 2-letter codes
iso3_to_eu <- c(
  AUT = "AT", BEL = "BE", BGR = "BG", CYP = "CY", CZE = "CZ",
  DEU = "DE", DNK = "DK", EST = "EE", GRC = "EL", ESP = "ES",
  FIN = "FI", FRA = "FR", HRV = "HR", HUN = "HU", IRL = "IE",
  ITA = "IT", LTU = "LT", LUX = "LU", LVA = "LV", MLT = "MT",
  NLD = "NL", POL = "PL", PRT = "PT", ROU = "RO", SWE = "SE",
  SVN = "SI", SVK = "SK", GBR = "UK"
)

# Identify country code column
cc_col <- intersect(names(oxcgrt_raw), c("CountryCode", "country_code"))
si_col <- intersect(names(oxcgrt_raw), c("StringencyIndex_Average", "StringencyIndex", "stringency_index"))
date_col <- intersect(names(oxcgrt_raw), c("Date", "date"))

if (length(cc_col) == 0 || length(si_col) == 0 || length(date_col) == 0) {
  cat("OxCGRT column names: ", paste(names(oxcgrt_raw)[1:20], collapse = ", "), "\n")
  stop("Cannot identify required OxCGRT columns")
}

oxcgrt <- oxcgrt_raw |>
  select(country_code = !!sym(cc_col[1]),
         date_raw = !!sym(date_col[1]),
         stringency = !!sym(si_col[1])) |>
  mutate(
    country = iso3_to_eu[country_code],
    date_parsed = as.Date(as.character(date_raw), format = "%Y%m%d")
  ) |>
  filter(!is.na(country), !is.na(date_parsed)) |>
  mutate(
    year  = lubridate::year(date_parsed),
    month = lubridate::month(date_parsed)
  ) |>
  group_by(country, year, month) |>
  summarise(stringency = mean(stringency, na.rm = TRUE), .groups = "drop")

cat(sprintf("OxCGRT processed: %d country-months\n", nrow(oxcgrt)))

# ------------------------------------------------------------------
# 5. Save all data
# ------------------------------------------------------------------
saveRDS(hicp, "data/hicp_monthly.rds")
saveRDS(menthol_shares, "data/menthol_shares.rds")
saveRDS(oxcgrt, "data/oxcgrt_stringency.rds")

cat("=== Data fetch complete ===\n")
cat(sprintf("  HICP: %d rows, %d countries\n", nrow(hicp), n_distinct(hicp$country)))
cat(sprintf("  Menthol shares: %d countries\n", nrow(menthol_shares)))
cat(sprintf("  OxCGRT: %d country-months\n", nrow(oxcgrt)))
