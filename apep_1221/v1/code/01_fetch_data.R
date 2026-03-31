## =============================================================================
## 01_fetch_data.R — Fetch USPTO PAIR data via BigQuery
## Paper: Rejected and Relocated (apep_1221)
## =============================================================================

library(bigrquery)
library(DBI)
library(data.table)

# Authenticate using ADC
bq_auth(path = "~/.config/gcloud/application_default_credentials.json")
project_id <- "gen-lang-client-0330172635"

con <- dbConnect(
  bigrquery::bigquery(),
  project = "patents-public-data",
  billing = project_id
)

cat("Connected to BigQuery\n")

## ---------------------------------------------------------------------------
## Query 1: Build inventor-application panel with examiner info
## Restrict to US utility patents, filing years 2002-2014 (sufficient post-period)
## ---------------------------------------------------------------------------

cat("Querying inventor-application-examiner panel...\n")

query_main <- "
SELECT
  inv.application_number,
  inv.inventor_name_first,
  inv.inventor_name_last,
  inv.inventor_rank,
  inv.inventor_region_code AS state,
  app.filing_date,
  CAST(SUBSTR(app.filing_date, 1, 4) AS INT64) AS filing_year,
  app.examiner_id,
  app.examiner_art_unit,
  app.disposal_type,
  app.patent_number,
  app.small_entity_indicator
FROM `patents-public-data.uspto_oce_pair.all_inventors` inv
INNER JOIN `patents-public-data.uspto_oce_pair.application_data` app
  ON inv.application_number = app.application_number
WHERE
  inv.inventor_country_code = 'US'
  AND inv.inventor_region_code IS NOT NULL
  AND LENGTH(inv.inventor_region_code) = 2
  AND app.examiner_id IS NOT NULL
  AND app.examiner_art_unit IS NOT NULL
  AND app.filing_date IS NOT NULL
  AND CAST(SUBSTR(app.filing_date, 1, 4) AS INT64) BETWEEN 2002 AND 2014
  AND app.application_type = 'REGULAR'
  AND app.disposal_type IN ('ISS', 'ABN')
"

dt <- as.data.table(dbGetQuery(con, query_main))
cat(sprintf("Raw panel: %s rows, %s unique applications\n",
            format(nrow(dt), big.mark = ","),
            format(uniqueN(dt$application_number), big.mark = ",")))

## ---------------------------------------------------------------------------
## Validate: no empty critical columns
## ---------------------------------------------------------------------------

stopifnot(sum(is.na(dt$examiner_id)) == 0)
stopifnot(sum(is.na(dt$state)) == 0)
stopifnot(sum(is.na(dt$filing_year)) == 0)
stopifnot(sum(dt$state == "") == 0)

cat(sprintf("Filing years: %d to %d\n", min(dt$filing_year), max(dt$filing_year)))
cat(sprintf("Unique examiners: %s\n", format(uniqueN(dt$examiner_id), big.mark = ",")))
cat(sprintf("Unique art units: %s\n", format(uniqueN(dt$examiner_art_unit), big.mark = ",")))
cat(sprintf("Disposal: ISS=%s, ABN=%s\n",
            format(sum(dt$disposal_type == "ISS"), big.mark = ","),
            format(sum(dt$disposal_type == "ABN"), big.mark = ",")))

## ---------------------------------------------------------------------------
## Save raw data
## ---------------------------------------------------------------------------

fwrite(dt, "../data/inventor_app_panel.csv")
cat(sprintf("Saved inventor_app_panel.csv: %.1f MB\n",
            file.size("../data/inventor_app_panel.csv") / 1e6))

dbDisconnect(con)
cat("Done.\n")
