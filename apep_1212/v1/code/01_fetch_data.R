# 01_fetch_data.R — Fetch QWI race × industry data from Azure
# Reads state × quarter × race × NAICS 2-digit sector panels

source("00_packages.R")

# Fix: read Azure connection string directly from .env (bash truncates at semicolons)
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

cat("Connecting to Azure...\n")
cat(sprintf("Connection string length: %d\n", nchar(Sys.getenv("AZURE_STORAGE_CONNECTION_STRING"))))
con <- apep_azure_connect()

# ── Fetch QWI race × ethnicity × NAICS sector data ──
# Race codes: A1=White, A4=Asian
# Industries: 72=Hospitality, 44-45=Retail, 54=Professional, 51=Information
# Also fetch 00 (all industries) for normalization
cat("Querying QWI from Azure (all states, 2016-2024)...\n")

qwi_raw <- dbGetQuery(con, "
  SELECT
    LPAD(CAST(geography / 1000 AS VARCHAR), 2, '0') AS state_fips,
    year,
    quarter,
    race,
    industry,
    SUM(CASE WHEN Emp IS NOT NULL THEN Emp ELSE 0 END) AS emp,
    SUM(CASE WHEN HirA IS NOT NULL THEN HirA ELSE 0 END) AS hires,
    SUM(CASE WHEN Sep IS NOT NULL THEN Sep ELSE 0 END) AS separations,
    SUM(CASE WHEN EarnS IS NOT NULL AND Emp IS NOT NULL AND Emp > 0 THEN EarnS * Emp ELSE 0 END) AS total_earnings,
    SUM(CASE WHEN EarnS IS NOT NULL AND Emp IS NOT NULL AND Emp > 0 THEN Emp ELSE 0 END) AS emp_with_earnings
  FROM 'az://derived/qwi/rh/ns/*.parquet'
  WHERE year BETWEEN 2016 AND 2024
    AND race IN ('A1', 'A4')
    AND ethnicity = 'A0'
    AND industry IN ('00', '44-45', '51', '54', '72')
    AND geo_level = 'C'
    AND ownercode = 'A05'
  GROUP BY LPAD(CAST(geography / 1000 AS VARCHAR), 2, '0'), year, quarter, race, industry
  ORDER BY state_fips, year, quarter, race, industry
")

apep_azure_disconnect(con)

cat(sprintf("QWI rows fetched: %d\n", nrow(qwi_raw)))
cat(sprintf("States: %d\n", length(unique(qwi_raw$state_fips))))
cat(sprintf("Year range: %d-%d\n", min(qwi_raw$year), max(qwi_raw$year)))
cat(sprintf("Race codes: %s\n", paste(unique(qwi_raw$race), collapse=", ")))
cat(sprintf("Industries: %s\n", paste(unique(qwi_raw$industry), collapse=", ")))

# Compute average earnings
qwi_raw <- as.data.table(qwi_raw)
qwi_raw[, avg_earnings := fifelse(emp_with_earnings > 0, total_earnings / emp_with_earnings, NA_real_)]

# Validate that API returned actual records
stopifnot("No QWI data returned" = nrow(qwi_raw) > 0)
stopifnot("Missing states" = length(unique(qwi_raw$state_fips)) >= 45)
stopifnot("Missing race groups" = all(c("A1", "A4") %in% unique(qwi_raw$race)))

# Save
fwrite(qwi_raw, "../data/qwi_state_race_industry.csv")
cat("QWI data saved to data/qwi_state_race_industry.csv\n")

cat("\n── Sample counts by race and industry ──\n")
print(qwi_raw[year == 2019 & quarter == 4,
              .(total_emp = sum(emp, na.rm = TRUE)),
              by = .(race, industry)][order(race, industry)])
