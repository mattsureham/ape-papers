## 01_fetch_data.R — Data acquisition for apep_0803
## Who Gets the New Jobs? Medicaid Expansion and Racial Employment in Healthcare
## ALL data from real sources. No simulated data. Fail loudly.

source("00_packages.R")

## Azure connection
source("../../../../scripts/lib/azure_data.R")

data_dir <- "../data/"
dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)

cat("=== DATA ACQUISITION START ===\n")

## ─────────────────────────────────────────────────────────
## 1. QWI Race-Ethnicity Panel from Azure (NAICS 62)
## ─────────────────────────────────────────────────────────
cat("\n--- 1. QWI Race-Ethnicity Healthcare Panel ---\n")

con <- apep_azure_connect()

## Query QWI race panel for NAICS 62 (Healthcare), county level
## Fields: fips, year, quarter, race, EmpEnd, Acc, Sep, EarnBeg
qwi_query <- "
SELECT
  geography AS fips,
  year,
  quarter,
  race_ethnicity AS race,
  industry,
  SUM(Emp) AS emp,
  SUM(EmpEnd) AS emp_end,
  SUM(HirA) AS hires,
  SUM(Sep) AS separations,
  AVG(EarnHirAS) AS avg_earnings_new_hires
FROM read_parquet('az://apepdata/derived/qwi/rh/ns/*.parquet')
WHERE geo_level = 'C'
  AND industry = '62'
  AND year BETWEEN 2001 AND 2023
GROUP BY geography, year, quarter, race_ethnicity, industry
ORDER BY geography, year, quarter, race_ethnicity
"

cat("  Running QWI query (may take a minute)...\n")
qwi_hc <- tryCatch(
  {
    result <- DBI::dbGetQuery(con, qwi_query)
    as.data.table(result)
  },
  error = function(e) {
    cat(sprintf("  ERROR in QWI query: %s\n", e$message))
    ## Try simpler query
    cat("  Trying simpler query...\n")
    NULL
  }
)

if (is.null(qwi_hc) || nrow(qwi_hc) == 0) {
  ## Try listing what's available
  cat("  Listing Azure QWI files...\n")
  list_query <- "
  SELECT file_name FROM glob('az://apepdata/derived/qwi/rh/ns/*.parquet')
  LIMIT 5
  "
  files <- try(DBI::dbGetQuery(con, list_query), silent = TRUE)
  if (!inherits(files, "try-error")) {
    cat(sprintf("  Available files: %s\n", paste(files[[1]], collapse = ", ")))
  }

  ## Try with different column names
  cat("  Trying with alternative column names...\n")
  qwi_query2 <- "
  SELECT *
  FROM read_parquet('az://apepdata/derived/qwi/rh/ns/*.parquet')
  WHERE geo_level = 'C' AND industry = '62'
  LIMIT 5
  "
  sample_dt <- try(as.data.table(DBI::dbGetQuery(con, qwi_query2)), silent = TRUE)
  if (!inherits(sample_dt, "try-error") && nrow(sample_dt) > 0) {
    cat(sprintf("  Column names: %s\n", paste(names(sample_dt), collapse = ", ")))
    cat(sprintf("  Sample values:\n"))
    print(head(sample_dt, 3))
  } else {
    cat(sprintf("  Sample query also failed: %s\n",
                if (inherits(sample_dt, "try-error")) conditionMessage(attr(sample_dt, "condition")) else "no rows"))
    stop("FATAL: Cannot read QWI data from Azure. Check connection and paths.")
  }
}

if (!is.null(qwi_hc) && nrow(qwi_hc) > 0) {
  cat(sprintf("  ✓ QWI Healthcare data: %d rows\n", nrow(qwi_hc)))
  cat(sprintf("  Columns: %s\n", paste(names(qwi_hc), collapse = ", ")))
  cat(sprintf("  Years: %s\n", paste(sort(unique(qwi_hc$year)), collapse = ", ")))
  cat(sprintf("  Races: %s\n", paste(sort(unique(qwi_hc$race)), collapse = ", ")))
  cat(sprintf("  Counties: %d unique\n", length(unique(qwi_hc$fips))))
  fwrite(qwi_hc, file.path(data_dir, "qwi_healthcare_race.csv"))
  cat("  Saved to data/qwi_healthcare_race.csv\n")
}

## ─────────────────────────────────────────────────────────
## 2. QWI for placebo industry (Retail Trade, NAICS 44-45)
## ─────────────────────────────────────────────────────────
cat("\n--- 2. QWI Retail Placebo Panel ---\n")

qwi_placebo_query <- "
SELECT
  geography AS fips,
  year,
  quarter,
  race_ethnicity AS race,
  industry,
  SUM(Emp) AS emp,
  SUM(EmpEnd) AS emp_end,
  SUM(HirA) AS hires,
  SUM(Sep) AS separations,
  AVG(EarnHirAS) AS avg_earnings_new_hires
FROM read_parquet('az://apepdata/derived/qwi/rh/ns/*.parquet')
WHERE geo_level = 'C'
  AND industry = '44-45'
  AND year BETWEEN 2001 AND 2023
GROUP BY geography, year, quarter, race_ethnicity, industry
ORDER BY geography, year, quarter, race_ethnicity
"

cat("  Running retail placebo query...\n")
qwi_retail <- tryCatch(
  as.data.table(DBI::dbGetQuery(con, qwi_placebo_query)),
  error = function(e) {
    cat(sprintf("  WARNING: Retail query failed: %s\n", e$message))
    NULL
  }
)

if (!is.null(qwi_retail) && nrow(qwi_retail) > 0) {
  cat(sprintf("  ✓ QWI Retail placebo: %d rows\n", nrow(qwi_retail)))
  fwrite(qwi_retail, file.path(data_dir, "qwi_retail_race.csv"))
}

apep_azure_disconnect(con)

## ─────────────────────────────────────────────────────────
## 3. Medicaid Expansion Dates (hard-coded from KFF)
## ─────────────────────────────────────────────────────────
cat("\n--- 3. Medicaid Expansion Dates ---\n")

## Source: KFF State Health Facts (confirmed public documentation)
## https://www.kff.org/affordable-care-act/issue-brief/status-of-state-medicaid-expansion-decisions-interactive-map/
expansion_dates <- data.table(
  state = c("AZ", "AR", "CA", "CO", "CT", "DE", "DC", "HI", "IL", "IN",
            "IA", "KY", "MD", "MA", "MI", "MN", "MT", "NV", "NH", "NJ",
            "NM", "NY", "ND", "OH", "OR", "PA", "RI", "VT", "WA", "WV",
            "AK", "LA", "VA", "ME", "ID", "UT", "NE", "OK", "MO", "SD"),
  expansion_date = as.Date(c(
    "2014-01-01", "2014-01-01", "2014-01-01", "2014-01-01", "2014-01-01",
    "2014-01-01", "2014-01-01", "2014-01-01", "2014-01-01", "2015-02-01",
    "2014-01-01", "2014-01-01", "2014-01-01", "2014-01-01", "2014-04-01",
    "2014-01-01", "2016-01-01", "2014-01-01", "2014-08-15", "2014-01-01",
    "2014-01-01", "2014-01-01", "2014-01-01", "2014-01-01", "2014-01-01",
    "2015-01-01", "2014-01-01", "2014-01-01", "2014-01-01", "2014-01-01",
    "2015-09-01", "2016-07-01", "2019-01-01", "2019-01-10", "2020-01-01",
    "2020-01-01", "2020-10-01", "2021-07-01", "2021-10-01", "2023-07-01"
  )),
  expansion_year = c(
    2014, 2014, 2014, 2014, 2014, 2014, 2014, 2014, 2014, 2015,
    2014, 2014, 2014, 2014, 2014, 2014, 2016, 2014, 2014, 2014,
    2014, 2014, 2014, 2014, 2014, 2015, 2014, 2014, 2014, 2014,
    2015, 2016, 2019, 2019, 2020, 2020, 2020, 2021, 2021, 2023
  )
)

## Non-expansion states (as of early 2026)
non_expansion <- data.table(
  state = c("TX", "GA", "FL", "WI", "NC", "SC", "TN", "AL", "MS", "WY", "KS"),
  expansion_date = as.Date(NA),
  expansion_year = NA_integer_
)
## Note: Wisconsin has partial expansion (up to 100% FPL) but not full ACA expansion

all_states <- rbind(expansion_dates, non_expansion)
cat(sprintf("  Expansion states: %d\n", nrow(expansion_dates)))
cat(sprintf("  Non-expansion states: %d\n", nrow(non_expansion)))
fwrite(all_states, file.path(data_dir, "medicaid_expansion.csv"))

## ─────────────────────────────────────────────────────────
## 4. State FIPS crosswalk
## ─────────────────────────────────────────────────────────
cat("\n--- 4. State FIPS Crosswalk ---\n")

state_fips <- data.table(
  state_fips = sprintf("%02d", c(1,2,4,5,6,8,9,10,11,12,13,15,16,17,18,19,20,
                                  21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,
                                  36,37,38,39,40,41,42,44,45,46,47,48,49,50,51,
                                  53,54,55,56)),
  state = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI","ID",
            "IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO",
            "MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA",
            "RI","SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY")
)
fwrite(state_fips, file.path(data_dir, "state_fips.csv"))
cat(sprintf("  ✓ State FIPS crosswalk: %d states\n", nrow(state_fips)))

## ─────────────────────────────────────────────────────────
## SUMMARY
## ─────────────────────────────────────────────────────────
cat("\n=== DATA ACQUISITION SUMMARY ===\n")
cat(sprintf("  QWI Healthcare: %s\n",
    ifelse(exists("qwi_hc") && !is.null(qwi_hc), sprintf("%d rows", nrow(qwi_hc)), "PENDING")))
cat(sprintf("  QWI Retail placebo: %s\n",
    ifelse(exists("qwi_retail") && !is.null(qwi_retail), sprintf("%d rows", nrow(qwi_retail)), "MISSING")))
cat(sprintf("  Medicaid expansion dates: %d states\n", nrow(all_states)))
cat(sprintf("  State FIPS crosswalk: %d states\n", nrow(state_fips)))

cat("\n=== DATA ACQUISITION COMPLETE ===\n")
