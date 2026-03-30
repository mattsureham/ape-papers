## 01_fetch_data.R — Fetch ARCOS and IPEDS data from Azure

library(duckdb)
library(DBI)
library(dplyr)
library(readr)

# Force-read connection string from .env (system env may be truncated)
env_line <- grep("^AZURE_STORAGE_CONNECTION_STRING=",
                 readLines("../../../.env", warn = FALSE), value = TRUE)
eq_pos <- regexpr("=", env_line, fixed = TRUE)
Sys.setenv(AZURE_STORAGE_CONNECTION_STRING = substr(env_line, eq_pos + 1, nchar(env_line)))

source("../../../scripts/lib/azure_data.R")
con <- apep_azure_connect()

# ─────────────────────────────────────────────────────────
# 1. ARCOS: County-year aggregate opioid pill shipments
# ─────────────────────────────────────────────────────────
cat("═══════════════════════════════════════════════════════\n")
cat("Fetching ARCOS county-year aggregate data...\n")

arcos <- apep_azure_read(con, "raw/arcos/arcos_county_annual.parquet")
cat(sprintf("ARCOS: %d rows, %d states, %d counties, years %d-%d\n",
            nrow(arcos), n_distinct(arcos$buyer_state),
            n_distinct(paste(arcos$buyer_state, arcos$buyer_county)),
            min(arcos$year), max(arcos$year)))

# Drug-specific breakdown (OXYCODONE vs HYDROCODONE)
cat("\nFetching ARCOS drug-level breakdown...\n")
arcos_drugs <- dbGetQuery(con, "
  SELECT BUYER_STATE as buyer_state, BUYER_COUNTY as buyer_county,
         DRUG_NAME as drug_name,
         SUM(DOSAGE_UNIT) AS total_pills,
         COUNT(*) AS n_transactions
  FROM 'az://raw/arcos/arcos_transactions.parquet'
  GROUP BY BUYER_STATE, BUYER_COUNTY, DRUG_NAME
")
cat(sprintf("ARCOS by drug: %d rows (%s)\n", nrow(arcos_drugs),
            paste(sort(unique(arcos_drugs$drug_name)), collapse=", ")))

# ─────────────────────────────────────────────────────────
# 2. IPEDS: Completions by CIP code (c_a table)
# ─────────────────────────────────────────────────────────
cat("\n═══════════════════════════════════════════════════════\n")
cat("Attaching IPEDS database...\n")

dbExecute(con, "ATTACH 'az://raw/ipeds/ipeds.duckdb' AS ipeds (READ_ONLY)")

# Check c_a (completions/awards) table structure
cat("\n--- Completions table (c_a) ---\n")
schema_ca <- dbGetQuery(con, "DESCRIBE ipeds.c_a")
print(schema_ca)

ca_count <- dbGetQuery(con, "SELECT COUNT(*) as n FROM ipeds.c_a")[[1]]
cat(sprintf("Total rows in c_a: %s\n", format(ca_count, big.mark=",")))

# Sample to see CIP code format
cat("\nSample rows:\n")
print(dbGetQuery(con, "SELECT * FROM ipeds.c_a LIMIT 5"))

# Get completions for target CIP codes:
#   51.15xx = Substance Abuse/Addiction Counseling
#   14.xxxx = Engineering (placebo)
#   52.xxxx = Business (placebo)
cat("\nFetching completions for target CIP codes...\n")

ipeds_comp <- dbGetQuery(con, "
  SELECT *
  FROM ipeds.c_a
  WHERE CAST(cipcode AS VARCHAR) LIKE '51.15%'
     OR CAST(cipcode AS VARCHAR) LIKE '51.22%'
     OR CAST(cipcode AS VARCHAR) LIKE '14.%'
     OR CAST(cipcode AS VARCHAR) LIKE '52.%'
")

cat(sprintf("IPEDS completions fetched: %d rows\n", nrow(ipeds_comp)))

# Also check CIP 51.1501, 51.1504, etc.
cip_check <- dbGetQuery(con, "
  SELECT CAST(cipcode AS VARCHAR) as cip, COUNT(*) as n, SUM(ctotalt) as total_awards
  FROM ipeds.c_a
  WHERE CAST(cipcode AS VARCHAR) LIKE '51.15%'
  GROUP BY CAST(cipcode AS VARCHAR)
  ORDER BY total_awards DESC
")
cat("\nSubstance abuse CIP breakdown:\n")
print(cip_check)

# ─────────────────────────────────────────────────────────
# 3. IPEDS: Institutional directory (hd table)
# ─────────────────────────────────────────────────────────
cat("\n--- Institutional directory (hd) ---\n")
schema_hd <- dbGetQuery(con, "DESCRIBE ipeds.hd")
cat("Directory columns:", paste(schema_hd$column_name, collapse=", "), "\n")

# Get directory with county FIPS
ipeds_dir <- dbGetQuery(con, "
  SELECT unitid, year, institution_name, state, county_fips, county_name,
         latitude, longitude, control, level, instcat
  FROM ipeds.hd
")
cat(sprintf("IPEDS directory: %d rows, %d institutions\n",
            nrow(ipeds_dir), n_distinct(ipeds_dir$unitid)))

# ─────────────────────────────────────────────────────────
# 4. Save all data locally
# ─────────────────────────────────────────────────────────
write_csv(arcos, "data/arcos_county_annual.csv")
write_csv(arcos_drugs, "data/arcos_county_drugs.csv")
write_csv(ipeds_comp, "data/ipeds_completions.csv")
write_csv(ipeds_dir, "data/ipeds_directory.csv")

cat(sprintf("\n═══════════════════════════════════════════════════════\n"))
cat(sprintf("Data saved successfully:\n"))
cat(sprintf("  ARCOS county-year: %d rows\n", nrow(arcos)))
cat(sprintf("  ARCOS by drug: %d rows\n", nrow(arcos_drugs)))
cat(sprintf("  IPEDS completions: %d rows\n", nrow(ipeds_comp)))
cat(sprintf("  IPEDS directory: %d rows\n", nrow(ipeds_dir)))

apep_azure_disconnect(con)
