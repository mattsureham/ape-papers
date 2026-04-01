## 01_fetch_data.R — Fetch QWI data from Azure Parquet
## Child Labor Law Relaxations and Teen Employment
## Data: QWI sex×age panel (derived/qwi/sa/ns/) on Azure

source("00_packages.R")

# --- Connect to Azure (read full connection string from .env) ---
lines <- readLines("../../../../.env", warn = FALSE)
az_line <- grep("^AZURE_STORAGE_CONNECTION_STRING=", lines, value = TRUE)
conn_str <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", az_line)
conn_str <- gsub('^["\'](.*)["\']+$', "\\1", conn_str)
Sys.setenv(AZURE_STORAGE_CONNECTION_STRING = conn_str)

library(duckdb)
con <- DBI::dbConnect(duckdb::duckdb())
DBI::dbExecute(con, "INSTALL azure;")
DBI::dbExecute(con, "LOAD azure;")
DBI::dbExecute(con, sprintf("CREATE SECRET apep_azure (TYPE azure, CONNECTION_STRING '%s');", conn_str))
cat("Connected to Azure.\n")

# --- Verify data availability ---
cat("Checking Azure QWI availability...\n")
test <- DBI::dbGetQuery(con, "
  SELECT COUNT(*) as n, MIN(year) as min_yr, MAX(year) as max_yr
  FROM 'az://derived/qwi/sa/ns/*.parquet'
  WHERE agegrp = 'A01'
")
cat(sprintf("QWI teen (A01) records: %s, years: %d-%d\n",
            format(test$n, big.mark = ","), test$min_yr, test$max_yr))

if (test$n == 0) stop("FATAL: No QWI teen data found on Azure")

# --- Fetch state-level aggregated panel ---
# Aggregate county-level QWI to state level for our analysis
# Age groups: A01 (14-18), A02 (19-21), A03 (25-34), A04 (35-44)
# Industries: all NAICS 2-digit sectors
# Period: 2019Q1 - latest available
cat("Fetching state × industry × age × quarter panel from Azure...\n")

qwi <- DBI::dbGetQuery(con, "
  SELECT
    CAST(FLOOR(geography / 1000) AS INTEGER) AS statefip,
    industry,
    agegrp,
    year,
    quarter,
    SUM(Emp) AS Emp,
    SUM(EmpS) AS EmpS,
    SUM(HirA) AS HirA,
    SUM(Sep) AS Sep,
    SUM(CASE WHEN EarnS IS NOT NULL AND Emp > 0 THEN EarnS * Emp ELSE 0 END) /
      NULLIF(SUM(CASE WHEN EarnS IS NOT NULL THEN Emp ELSE 0 END), 0) AS EarnS
  FROM 'az://derived/qwi/sa/ns/*.parquet'
  WHERE agegrp IN ('A01', 'A02', 'A03', 'A04')
    AND year >= 2019
    AND industry != '99'
  GROUP BY statefip, industry, agegrp, year, quarter
  ORDER BY statefip, industry, agegrp, year, quarter
")

cat(sprintf("Fetched %s rows\n", format(nrow(qwi), big.mark = ",")))

# --- Validate ---
stopifnot("No data fetched" = nrow(qwi) > 0)

# Check state coverage
n_states <- length(unique(qwi$statefip))
cat(sprintf("States: %d\n", n_states))
stopifnot("Must have 50+ states/DC" = n_states >= 50)

# Check treated states are present
# FIPS: NJ=34, NH=33, AR=5, IA=19, FL=12, IN=18
treated_fips <- c(34, 33, 5, 19, 12, 18)
treated_names <- c("NJ", "NH", "AR", "IA", "FL", "IN")
missing_treated <- treated_fips[!treated_fips %in% unique(qwi$statefip)]
if (length(missing_treated) > 0) {
  warning(sprintf("Missing treated states: %s", paste(missing_treated, collapse = ", ")))
}
stopifnot("Must have all 6 treated states" = length(missing_treated) == 0)

# Check age groups
cat(sprintf("Age groups: %s\n", paste(sort(unique(qwi$agegrp)), collapse = ", ")))
stopifnot("Must have A01 (teens)" = "A01" %in% unique(qwi$agegrp))

# Check industries
cat(sprintf("Industries: %d unique codes\n", length(unique(qwi$industry))))

# Check year-quarter coverage
qwi$yq <- qwi$year + (qwi$quarter - 1) / 4
cat(sprintf("Time range: %0.2f to %0.2f\n", min(qwi$yq), max(qwi$yq)))

# --- Save ---
saveRDS(qwi, "../data/qwi_state_panel.rds")
cat(sprintf("Saved: data/qwi_state_panel.rds (%s rows)\n",
            format(nrow(qwi), big.mark = ",")))

# --- Disconnect ---
DBI::dbDisconnect(con, shutdown = TRUE)
cat("Done.\n")
