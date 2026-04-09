# 01_fetch_data.R — Fetch all data from APIs
# APEP 1456: DPA Enforcement Intensity and Startup Survival

source("00_packages.R")

cat("=== Fetching data for APEP 1456 ===\n")

# ---------------------------------------------------------------
# 1. GDPR Enforcement Tracker — fine records
# ---------------------------------------------------------------
cat("Fetching Enforcement Tracker data...\n")

resp <- GET("https://www.enforcementtracker.com/data4sfk3j4hwe324kjhfdwe.json")
stopifnot("Enforcement Tracker API failed" = status_code(resp) == 200)

raw_json <- content(resp, as = "text", encoding = "UTF-8")
parsed <- fromJSON(raw_json)

# The data field contains a matrix of records
enforcement_raw <- as.data.frame(parsed$data, stringsAsFactors = FALSE)

# Column names from the tracker: ETid, country_html, DPA, date, fine, company, sector, articles, type, ...
# Based on known structure, assign meaningful names
colnames(enforcement_raw)[1:10] <- c(
  "etid", "country_html", "dpa", "date_str", "fine_str",
  "controller", "sector", "articles", "type", "summary"
)

cat(sprintf("  Downloaded %d enforcement records\n", nrow(enforcement_raw)))
stopifnot("No enforcement records returned" = nrow(enforcement_raw) > 100)

saveRDS(enforcement_raw, "../data/enforcement_raw.rds")

# ---------------------------------------------------------------
# 2. Eurostat Business Demography — ICT sector
# ---------------------------------------------------------------
cat("Fetching Eurostat business demography (ICT, NACE J)...\n")

# Birth rate (V97020), 1-year survival (V97041), 3-year survival (V97043),
# Employment share of births (V97120), Average size of births (V97121)
bd_indicators <- c("V97020", "V97041", "V97043", "V97120", "V97121")

bd_data <- get_eurostat(
  id = "bd_9bd_sz_cl_r2",
  filters = list(
    nace_r2 = c("J", "F"),   # J = ICT, F = Construction (placebo)
    indic_sb = bd_indicators,
    sizeclas = "TOTAL"
  ),
  time_format = "num"
)

stopifnot("Eurostat business demography returned no data" = nrow(bd_data) > 0)
cat(sprintf("  Downloaded %d business demography observations\n", nrow(bd_data)))

saveRDS(bd_data, "../data/eurostat_bd.rds")

# ---------------------------------------------------------------
# 3. Eurostat GDP — for normalization
# ---------------------------------------------------------------
cat("Fetching Eurostat GDP data...\n")

gdp_data <- get_eurostat(
  id = "nama_10_gdp",
  filters = list(
    unit = "CP_MEUR",         # Current prices, million EUR
    na_item = "B1GQ"          # GDP at market prices
  ),
  time_format = "num"
)

stopifnot("Eurostat GDP returned no data" = nrow(gdp_data) > 0)
cat(sprintf("  Downloaded %d GDP observations\n", nrow(gdp_data)))

saveRDS(gdp_data, "../data/eurostat_gdp.rds")

# ---------------------------------------------------------------
# 4. Eurostat Unemployment — control variable
# ---------------------------------------------------------------
cat("Fetching Eurostat unemployment data...\n")

unemp_data <- get_eurostat(
  id = "une_rt_a",
  filters = list(
    sex = "T",               # Total
    age = "Y15-74",          # Working age
    unit = "PC_ACT"          # Percent of active population
  ),
  time_format = "num"
)

stopifnot("Eurostat unemployment returned no data" = nrow(unemp_data) > 0)
cat(sprintf("  Downloaded %d unemployment observations\n", nrow(unemp_data)))

saveRDS(unemp_data, "../data/eurostat_unemp.rds")

cat("=== All data fetched successfully ===\n")
