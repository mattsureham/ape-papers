# Smoke test: check NAICS 312 (Beverage Manufacturing) in QWI
library(DBI)
library(duckdb)

# Load Azure connection string from .env
env_file <- "../../../../.env"
stopifnot(file.exists(env_file))
lines <- readLines(env_file, warn = FALSE)
az_conn <- NULL
for (line in lines) {
  line <- trimws(line)
  if (startsWith(line, "AZURE_STORAGE_CONNECTION_STRING=")) {
    az_conn <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", line)
    az_conn <- gsub('^["\']|["\']$', '', az_conn)
    break
  }
}
stopifnot("Azure connection string not found" = !is.null(az_conn))

con <- dbConnect(duckdb())
dbExecute(con, "INSTALL azure; LOAD azure;")
dbExecute(con, sprintf("SET azure_storage_connection_string = '%s';", az_conn))
cat("Azure connection configured.\n")

# 1. Check NAICS 31x industries
cat("\n=== NAICS 31x industries in QWI n3 ===\n")
ind <- dbGetQuery(con, "
  SELECT DISTINCT CAST(industry AS VARCHAR) as ind, COUNT(*) as n_rows
  FROM read_parquet('az://derived/qwi/sa/n3/*.parquet')
  WHERE CAST(industry AS VARCHAR) LIKE '31%'
  GROUP BY ind
  ORDER BY ind
")
print(ind)

# 2. NAICS 312 employment over time (national)
cat("\n=== NAICS 312 Employment by Year ===\n")
emp312 <- dbGetQuery(con, "
  SELECT
    year,
    quarter,
    SUM(Emp) as total_emp,
    SUM(HirN) as total_new_hires,
    SUM(Sep) as total_separations,
    COUNT(DISTINCT geography) as n_counties
  FROM read_parquet('az://derived/qwi/sa/n3/*.parquet')
  WHERE CAST(industry AS VARCHAR) = '312'
    AND CAST(sex AS VARCHAR) = '0'
    AND CAST(agegrp AS VARCHAR) = 'A00'
  GROUP BY year, quarter
  ORDER BY year, quarter
")
print(as.data.frame(emp312))

# 3. State-level employment in NAICS 312 (2019 Q1)
cat("\n=== NAICS 312 by State (2019 Q1, top 20) ===\n")
state312 <- dbGetQuery(con, "
  SELECT
    CAST(CAST(geography AS INTEGER) / 1000 AS INTEGER) as state_fips,
    SUM(Emp) as total_emp,
    COUNT(DISTINCT geography) as n_counties
  FROM read_parquet('az://derived/qwi/sa/n3/*.parquet')
  WHERE CAST(industry AS VARCHAR) = '312'
    AND CAST(sex AS VARCHAR) = '0'
    AND CAST(agegrp AS VARCHAR) = 'A00'
    AND year = 2019 AND quarter = 1
  GROUP BY CAST(CAST(geography AS INTEGER) / 1000 AS INTEGER)
  ORDER BY total_emp DESC
  LIMIT 20
")
print(state312)

# 4. Placebo check: NAICS 311 (Food Mfg) employment over time
cat("\n=== NAICS 311 (Food Mfg) Employment by Year (sample) ===\n")
emp311 <- dbGetQuery(con, "
  SELECT
    year,
    SUM(Emp) as total_emp,
    COUNT(DISTINCT geography) as n_counties
  FROM read_parquet('az://derived/qwi/sa/n3/*.parquet')
  WHERE CAST(industry AS VARCHAR) = '311'
    AND CAST(sex AS VARCHAR) = '0'
    AND CAST(agegrp AS VARCHAR) = 'A00'
    AND quarter = 1
  GROUP BY year
  ORDER BY year
")
print(emp311, n = 30)

dbDisconnect(con, shutdown = TRUE)
cat("\n=== Smoke test complete ===\n")
