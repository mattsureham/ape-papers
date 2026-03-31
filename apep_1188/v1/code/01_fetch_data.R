# ==============================================================================
# 01_fetch_data.R — Fetch QWI data from Azure + EU trade exposure
# ==============================================================================

source("00_packages.R")

# Force-load AZURE_STORAGE_CONNECTION_STRING from .env (bash truncates at ';')
env_lines <- readLines("../../../../.env", warn = FALSE)
for (line in env_lines) {
  line <- trimws(line)
  if (startsWith(line, "AZURE_STORAGE_CONNECTION_STRING=")) {
    val <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", line)
    val <- gsub('^["\'](.*)["\']$', "\\1", val)
    Sys.setenv(AZURE_STORAGE_CONNECTION_STRING = val)
    break
  }
}

source("../../../../scripts/lib/azure_data.R")

# --- Connect to Azure ---
con <- apep_azure_connect()

# --- Fetch QWI 2-digit NAICS, sex×age, all states ---
cat("Fetching QWI 2-digit NAICS data from Azure...\n")
qwi_2d <- dbGetQuery(con, "
  SELECT
    geography AS county_fips,
    CAST(FLOOR(geography / 1000) AS INTEGER) AS state_fips,
    industry AS naics2,
    year, quarter,
    Emp, EmpEnd, HirA, HirN, Sep, EarnS, EarnBeg,
    FrmJbGn, FrmJbLs,
    sEmp, sEmpEnd, sHirA, sHirN, sSep, sEarnS
  FROM 'az://derived/qwi/sa/ns/*.parquet'
  WHERE industry IN ('51', '52', '54', '72')
    AND year BETWEEN 2014 AND 2020
    AND agegrp = 'A00'
    AND sex = '0'
    AND quarter BETWEEN 1 AND 4
")
cat(sprintf("QWI 2-digit: %d rows, %d counties\n", nrow(qwi_2d), n_distinct(qwi_2d$county_fips)))

stopifnot("No QWI data returned" = nrow(qwi_2d) > 0)

# --- Fetch QWI 3-digit NAICS for placebo tests ---
cat("Fetching QWI 3-digit NAICS data from Azure...\n")
qwi_3d <- dbGetQuery(con, "
  SELECT
    geography AS county_fips,
    CAST(FLOOR(geography / 1000) AS INTEGER) AS state_fips,
    industry AS naics3,
    year, quarter,
    Emp, HirA, Sep, EarnS,
    sEmp, sHirA, sSep, sEarnS
  FROM 'az://derived/qwi/sa/n3/*.parquet'
  WHERE industry IN ('511', '512', '515', '517', '518', '519')
    AND year BETWEEN 2014 AND 2020
    AND agegrp = 'A00'
    AND sex = '0'
")
cat(sprintf("QWI 3-digit: %d rows\n", nrow(qwi_3d)))

apep_azure_disconnect(con)

# --- Load state-level EU trade exposure (pre-fetched from Census Foreign Trade API) ---
cat("Loading EU trade exposure data...\n")
# Pre-fetched by fetch_trade_exposure.py from Census statehs endpoint
# EU-28 exports proxied by top 6 partners: DE, FR, NL, IT, UK, AT (>85% of EU trade)
trade_exposure <- read.csv("../data/trade_exposure.csv", stringsAsFactors = FALSE)
trade_exposure$eu_share <- as.numeric(trade_exposure$eu_share)

stopifnot("No trade exposure data" = nrow(trade_exposure) > 30)
cat(sprintf("Trade exposure: %d states, mean EU share = %.3f\n",
            nrow(trade_exposure), mean(trade_exposure$eu_share, na.rm = TRUE)))

# --- Save all data ---
saveRDS(qwi_2d, "../data/qwi_2digit.rds")
saveRDS(qwi_3d, "../data/qwi_3digit.rds")
saveRDS(trade_exposure, "../data/trade_exposure.rds")

cat("Data fetch complete.\n")
cat(sprintf("  QWI 2-digit: %d rows\n", nrow(qwi_2d)))
cat(sprintf("  QWI 3-digit: %d rows\n", nrow(qwi_3d)))
cat(sprintf("  Trade exposure: %d states\n", nrow(trade_exposure)))
