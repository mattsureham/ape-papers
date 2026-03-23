# =============================================================================
# 01_fetch_data.R — Fetch QWI data from Azure for apep_0779
# =============================================================================
# Census Quarterly Workforce Indicators: state x quarter x sex x age group
# Source: az://derived/qwi/sa/ns/*.parquet (51 state files)

source("00_packages.R")
source("../../../../scripts/lib/azure_data.R")

cat("Connecting to Azure...\n")
con <- apep_azure_connect()

# Query all 51 state files at once using glob pattern
# Filter to: state-level, total industry, relevant sex and age groups, 2000-2022
cat("Fetching QWI data (state-level, sex x age, 2000-2022)...\n")

qwi_raw <- DBI::dbGetQuery(con, "
  SELECT
    CAST(geography AS INTEGER) AS state_fips,
    CAST(sex AS INTEGER) AS sex,
    agegrp,
    CAST(year AS INTEGER) AS year,
    CAST(quarter AS INTEGER) AS quarter,
    Emp,
    HirA,
    Sep,
    EarnS,
    EarnHirAS
  FROM 'az://derived/qwi/sa/ns/*.parquet'
  WHERE geo_level = 'S'
    AND industry = '00'
    AND sex IN ('1', '2')
    AND agegrp IN ('A04', 'A06')
    AND year >= 2000
    AND year <= 2022
  ORDER BY state_fips, year, quarter, sex, agegrp
")

cat("Fetched", nrow(qwi_raw), "rows from QWI.\n")
cat("States:", length(unique(qwi_raw$state_fips)), "\n")
cat("Year range:", min(qwi_raw$year), "-", max(qwi_raw$year), "\n")

# Save raw data
arrow::write_parquet(qwi_raw, "../data/qwi_raw.parquet")
cat("Saved to data/qwi_raw.parquet\n")

# Basic data quality check
cat("\n--- Data Quality Summary ---\n")
cat("Rows:", nrow(qwi_raw), "\n")
cat("Missing Emp:", sum(is.na(qwi_raw$Emp)), "\n")
cat("Missing Sep:", sum(is.na(qwi_raw$Sep)), "\n")
cat("Missing HirA:", sum(is.na(qwi_raw$HirA)), "\n")
cat("Missing EarnS:", sum(is.na(qwi_raw$EarnS)), "\n")

# Show sample
cat("\n--- Sample Data (first 10 rows) ---\n")
print(head(qwi_raw, 10))

apep_azure_disconnect(con)
cat("Done.\n")
