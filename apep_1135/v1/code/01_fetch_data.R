# ==============================================================================
# 01_fetch_data.R — Fetch QWI data from Azure + Comtrade trade data
# ==============================================================================
source("00_packages.R")

# --- Load connection string DIRECTLY from .env (shell source truncates at ;) ---
env_path <- "../../../../.env"
env_lines <- readLines(env_path, warn = FALSE)
for (line in env_lines) {
  line <- trimws(line)
  if (nchar(line) == 0 || startsWith(line, "#")) next
  line <- sub("^export\\s+", "", line)
  eq_pos <- regexpr("=", line, fixed = TRUE)
  if (eq_pos > 0) {
    key <- substr(line, 1, eq_pos - 1)
    val <- substr(line, eq_pos + 1, nchar(line))
    val <- gsub('^["\'](.*)["\']$', "\\1", val)
    do.call(Sys.setenv, setNames(list(val), key))
  }
}

# --- Connect to Azure via DuckDB ---
con <- DBI::dbConnect(duckdb::duckdb())
DBI::dbExecute(con, "INSTALL azure;")
DBI::dbExecute(con, "LOAD azure;")

conn_str <- Sys.getenv("AZURE_STORAGE_CONNECTION_STRING")
cat("Connection string length:", nchar(conn_str), "\n")
stopifnot(nchar(conn_str) > 50)  # Ensure full string

DBI::dbExecute(con, sprintf(
  "CREATE SECRET apep_azure (TYPE azure, CONNECTION_STRING '%s');",
  conn_str
))
cat("Connected to Azure.\n")

# ------------------------------------------------------------------------------
# 1. QWI data: NAICS 562 (Waste) + placebo sectors, all workers
# ------------------------------------------------------------------------------
cat("Fetching QWI data for NAICS 562, 423, 541, 722...\n")

qwi_sa <- dbGetQuery(con, "
  SELECT
    geography AS fips,
    year,
    quarter,
    industry,
    Emp,
    EmpEnd,
    HirA,
    Sep,
    EarnS,
    FrmJbGn,
    FrmJbLs
  FROM 'az://derived/qwi/sa/n3/*.parquet'
  WHERE industry IN ('562', '423', '541', '722')
    AND year BETWEEN 2013 AND 2023
    AND sex = 0
    AND agegrp = 'A00'
  ORDER BY geography, year, quarter, industry
")

cat(sprintf("  QWI (all workers): %s rows\n", format(nrow(qwi_sa), big.mark = ",")))
stopifnot(nrow(qwi_sa) > 10000)

# Also fetch total county employment for exposure calculation
cat("Fetching total county employment...\n")
qwi_total <- dbGetQuery(con, "
  SELECT
    geography AS fips,
    year,
    quarter,
    SUM(Emp) AS total_emp
  FROM 'az://derived/qwi/sa/n3/*.parquet'
  WHERE year BETWEEN 2013 AND 2017
    AND sex = 0
    AND agegrp = 'A00'
  GROUP BY geography, year, quarter
")
cat(sprintf("  Total emp: %s rows\n", format(nrow(qwi_total), big.mark = ",")))

# Race breakdowns for NAICS 562
cat("Fetching race breakdowns for NAICS 562...\n")
qwi_rh <- dbGetQuery(con, "
  SELECT
    geography AS fips,
    year,
    quarter,
    industry,
    race,
    ethnicity,
    Emp,
    EarnS
  FROM 'az://derived/qwi/rh/n3/*.parquet'
  WHERE industry = '562'
    AND year BETWEEN 2013 AND 2023
  ORDER BY geography, year, quarter, race
")
cat(sprintf("  QWI race (NAICS 562): %s rows\n", format(nrow(qwi_rh), big.mark = ",")))

DBI::dbDisconnect(con, shutdown = TRUE)

# Save
saveRDS(qwi_sa, "../data/qwi_sa_raw.rds")
saveRDS(qwi_total, "../data/qwi_total.rds")
saveRDS(qwi_rh, "../data/qwi_rh_raw.rds")

# ------------------------------------------------------------------------------
# 2. Comtrade: US waste exports to China (for motivation)
# ------------------------------------------------------------------------------
cat("\nFetching Comtrade trade data...\n")

comtrade_key <- Sys.getenv("COMTRADE_API_PRIMARY", "")
if (nchar(comtrade_key) == 0) {
  comtrade_key <- Sys.getenv("COMTRADE_API_SECONDARY", "")
}
if (nchar(comtrade_key) == 0) {
  stop("No Comtrade API key found")
}

hs_codes <- c("3915", "4707", "7204")
trade_list <- list()

for (hs in hs_codes) {
  cat(sprintf("  Fetching HS %s...\n", hs))
  url <- sprintf(
    "https://comtradeapi.un.org/data/v1/get/C/A/HS?reporterCode=842&partnerCode=156&cmdCode=%s&flowCode=X&period=2013,2014,2015,2016,2017,2018,2019,2020,2021,2022,2023",
    hs
  )
  resp <- httr::GET(url, httr::add_headers("Ocp-Apim-Subscription-Key" = comtrade_key))
  if (httr::status_code(resp) == 200) {
    content <- httr::content(resp, as = "text", encoding = "UTF-8")
    parsed <- jsonlite::fromJSON(content)
    if (!is.null(parsed$data) && nrow(parsed$data) > 0) {
      trade_list[[hs]] <- parsed$data
      cat(sprintf("    Got %d records\n", nrow(parsed$data)))
    } else {
      cat(sprintf("    No data for HS %s\n", hs))
    }
  } else {
    cat(sprintf("    HTTP %d for HS %s\n", httr::status_code(resp), hs))
  }
  Sys.sleep(1.5)
}

if (length(trade_list) > 0) {
  trade_df <- bind_rows(trade_list)
  saveRDS(trade_df, "../data/comtrade_raw.rds")
  cat(sprintf("  Saved %d trade records\n", nrow(trade_df)))
} else {
  cat("  WARNING: No Comtrade data. Will use literature values.\n")
}

cat("\nData fetch complete.\n")
