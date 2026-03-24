# =============================================================================
# 01_fetch_data.R — Fetch QWI race×ethnicity data from Azure
# =============================================================================
source("00_packages.R")

# --- Azure connection (read .env directly to avoid shell semicolon truncation) ---
env_lines <- readLines("../../../../.env", warn = FALSE)
cs_line <- grep("^AZURE_STORAGE_CONNECTION_STRING=", env_lines, value = TRUE)[1]
conn_str <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", cs_line)
conn_str <- gsub('^["\'](.*)["\'"]$', "\\1", conn_str)
stopifnot("Azure connection string not found" = nchar(conn_str) > 50)

con <- dbConnect(duckdb())
dbExecute(con, "INSTALL azure;")
dbExecute(con, "LOAD azure;")
dbExecute(con, sprintf("CREATE SECRET apep_azure (TYPE azure, CONNECTION_STRING '%s');", conn_str))
cat("Connected to Azure.\n")

# --- Fetch QWI race data for low-wage sectors ---
# Industries: 72 (Accommodation/Food), 44-45 (Retail), 62 (Healthcare)
# Race: A1 (White alone), A2 (Black alone)
# Ethnicity: A0 (all ethnicities) to avoid double-counting
cat("Querying QWI race×county×industry data from Azure...\n")

df <- dbGetQuery(con, "
  SELECT
    geography AS fips_county,
    industry,
    race,
    year,
    quarter,
    Emp AS emp,
    EmpS AS emp_stable,
    EarnS AS earn_avg,
    HirN AS hires,
    Sep AS separations,
    TurnOvrS AS turnover,
    FrmJbGn AS firm_job_gain,
    FrmJbLs AS firm_job_loss
  FROM 'az://derived/qwi/rh/ns/*.parquet'
  WHERE industry IN ('72', '44-45', '62')
    AND race IN ('A1', 'A2')
    AND ethnicity = 'A0'
    AND ownercode = 'A05'
    AND year >= 2001
    AND Emp > 0
")

dbDisconnect(con, shutdown = TRUE)
cat("Fetched", nrow(df), "rows from Azure.\n")

# --- Basic validation ---
stopifnot("No data fetched" = nrow(df) > 0)

cat("Unique states (from FIPS):", length(unique(substr(sprintf("%05d", df$fips_county), 1, 2))), "\n")
cat("Year range:", range(df$year), "\n")
cat("Industries:", unique(df$industry), "\n")
cat("Race codes:", unique(df$race), "\n")

# --- Save ---
saveRDS(df, "../data/qwi_raw.rds")
cat("Saved qwi_raw.rds:", nrow(df), "rows,", ncol(df), "columns\n")
