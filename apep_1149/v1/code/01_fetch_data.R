# ==============================================================================
# 01_fetch_data.R — Load ARCOS transactions from Azure (quarterly aggregation)
# ==============================================================================

source("00_packages.R")
library(fixest)  # Main econometrics package

# Load .env directly (matching proven approach from apep_1129)
env_lines <- readLines("../../../../.env", warn = FALSE)
for (line in env_lines) {
  line <- trimws(line)
  if (nchar(line) == 0 || startsWith(line, "#")) next
  line <- sub("^export\\s+", "", line)
  eq_pos <- regexpr("=", line, fixed = TRUE)
  if (eq_pos > 0) {
    key <- substr(line, 1, eq_pos - 1)
    val <- substr(line, eq_pos + 1, nchar(line))
    val <- gsub('^["\'](.*)["\']+$', "\\1", val)
    do.call(Sys.setenv, setNames(list(val), key))
  }
}

source("../../../../scripts/lib/azure_data.R")

# --- ARCOS from Azure (QUARTERLY aggregation) ---
cat("Connecting to Azure...\n")
con <- apep_azure_connect()

# TRANSACTION_DATE is BIGINT in MMDDYYYY format
# Month = TRANSACTION_DATE / 1000000 (integer division)
# Year = TRANSACTION_DATE % 10000
# Quarter = CEIL(month / 3)
cat("Aggregating ARCOS at county-distributor-quarter level via DuckDB...\n")
arcos_agg <- DBI::dbGetQuery(con, "
  SELECT
    BUYER_STATE AS state,
    BUYER_COUNTY AS county_name,
    Reporter_family AS distributor,
    CAST(TRANSACTION_DATE % 10000 AS INTEGER) AS year,
    CAST(CEIL(CAST(TRANSACTION_DATE / 1000000 AS INTEGER) / 3.0) AS INTEGER) AS quarter,
    SUM(DOSAGE_UNIT) AS total_pills,
    COUNT(*) AS n_transactions
  FROM 'az://raw/arcos/arcos_transactions.parquet'
  WHERE CAST(TRANSACTION_DATE % 10000 AS INTEGER) BETWEEN 2006 AND 2012
  GROUP BY BUYER_STATE, BUYER_COUNTY, Reporter_family,
    CAST(TRANSACTION_DATE % 10000 AS INTEGER),
    CAST(CEIL(CAST(TRANSACTION_DATE / 1000000 AS INTEGER) / 3.0) AS INTEGER)
")
arcos_dt <- as.data.table(arcos_agg)
cat(sprintf("ARCOS aggregated: %d rows (county-quarter-distributor)\n", nrow(arcos_dt)))

# County-quarter totals
county_qtr_total <- as.data.table(DBI::dbGetQuery(con, "
  SELECT
    BUYER_STATE AS state,
    BUYER_COUNTY AS county_name,
    CAST(TRANSACTION_DATE % 10000 AS INTEGER) AS year,
    CAST(CEIL(CAST(TRANSACTION_DATE / 1000000 AS INTEGER) / 3.0) AS INTEGER) AS quarter,
    SUM(DOSAGE_UNIT) AS total_pills,
    COUNT(*) AS n_transactions
  FROM 'az://raw/arcos/arcos_transactions.parquet'
  WHERE CAST(TRANSACTION_DATE % 10000 AS INTEGER) BETWEEN 2006 AND 2012
  GROUP BY BUYER_STATE, BUYER_COUNTY,
    CAST(TRANSACTION_DATE % 10000 AS INTEGER),
    CAST(CEIL(CAST(TRANSACTION_DATE / 1000000 AS INTEGER) / 3.0) AS INTEGER)
"))
cat(sprintf("County-quarter totals: %d rows\n", nrow(county_qtr_total)))

apep_azure_disconnect(con)

# --- Save raw data ---
fwrite(arcos_dt, "../data/arcos_county_qtr_distributor.csv")
fwrite(county_qtr_total, "../data/arcos_county_qtr_total.csv")

cat("Data fetch complete.\n")
cat(sprintf("  ARCOS distributor-level: %d rows\n", nrow(arcos_dt)))
cat(sprintf("  ARCOS county-quarter total: %d rows\n", nrow(county_qtr_total)))

stopifnot("ARCOS data is empty" = nrow(arcos_dt) > 0)
stopifnot("County-quarter totals empty" = nrow(county_qtr_total) > 0)
