# =============================================================================
# 01_fetch_data.R — Fetch QWI from Azure and coal/oil prices from FRED
# =============================================================================

source("00_packages.R")

# Force-load Azure connection string from .env (shell may truncate at semicolons)
env_file <- "../../../../.env"
env_lines <- readLines(env_file, warn = FALSE)
for (line in env_lines) {
  line <- trimws(line)
  if (startsWith(line, "AZURE_STORAGE_CONNECTION_STRING=")) {
    val <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", line)
    val <- gsub('^["\'](.*)["\']$', "\\1", val)
    Sys.setenv(AZURE_STORAGE_CONNECTION_STRING = val)
    cat("Azure connection string loaded:", nchar(val), "chars\n")
    break
  }
}

source("../../../../scripts/lib/azure_data.R")

# --- 1. QWI Mining Employment from Azure ---
cat("=== Fetching QWI mining employment from Azure ===\n")
con <- apep_azure_connect()

# NAICS 3-digit: 211 (Oil/Gas), 212 (Coal), 213 (Mining Support)
qwi_query <- "
SELECT
  geography,
  CAST(FLOOR(geography / 1000) AS INTEGER) AS state_fips,
  year,
  quarter,
  industry,
  \"Emp\" AS emp,
  \"EmpEnd\" AS emp_end,
  \"HirA\" AS hir_all,
  \"HirN\" AS hir_new,
  \"Sep\" AS sep,
  \"EarnS\" AS earn_s,
  \"FrmJbGn\" AS frm_job_gain,
  \"FrmJbLs\" AS frm_job_loss
FROM 'az://derived/qwi/sa/n3/*.parquet'
WHERE industry IN ('211', '212', '213')
  AND sex = '0'
  AND agegrp = 'A00'
  AND year BETWEEN 2008 AND 2020
  AND ownercode = 'A05'
"

qwi_mining <- dbGetQuery(con, qwi_query)
cat(sprintf("  QWI mining records: %d\n", nrow(qwi_mining)))
stopifnot("QWI must have data" = nrow(qwi_mining) > 1000)

# Also get total private employment (NAICS 00) for county controls
qwi_total_query <- "
SELECT
  geography,
  year,
  quarter,
  \"Emp\" AS emp_total,
  \"EarnS\" AS earn_total
FROM 'az://derived/qwi/sa/ns/*.parquet'
WHERE industry = '00'
  AND sex = '0'
  AND agegrp = 'A00'
  AND year BETWEEN 2008 AND 2020
  AND ownercode = 'A05'
"

qwi_total <- dbGetQuery(con, qwi_total_query)
cat(sprintf("  QWI total employment records: %d\n", nrow(qwi_total)))

apep_azure_disconnect(con)

write_csv(qwi_mining, "../data/qwi_mining.csv.gz")
write_csv(qwi_total, "../data/qwi_total.csv.gz")
cat("  Saved QWI data\n")

# --- 2. Coal and Oil Prices from FRED ---
cat("\n=== Fetching commodity prices from FRED ===\n")

# Load .env for FRED API key
env_path <- "../../../../.env"
if (file.exists(env_path)) {
  lines <- readLines(env_path, warn = FALSE)
  for (line in lines) {
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
}

fred_key <- Sys.getenv("FRED_API_KEY")
stopifnot("FRED_API_KEY must be set" = nchar(fred_key) > 0)

fetch_fred <- function(series_id, api_key) {
  url <- sprintf(
    "https://api.stlouisfed.org/fred/series/observations?series_id=%s&api_key=%s&file_type=json&observation_start=2008-01-01&observation_end=2020-12-31",
    series_id, api_key
  )
  resp <- jsonlite::fromJSON(url)
  df <- resp$observations %>%
    select(date, value) %>%
    mutate(
      date = as.Date(date),
      value = as.numeric(value),
      series = series_id
    ) %>%
    filter(!is.na(value))
  return(df)
}

# DCOILWTICO: WTI Crude Oil (daily -> quarterly avg)
cat("  Fetching WTI oil prices...\n")
oil_prices <- fetch_fred("DCOILWTICO", fred_key)
cat(sprintf("    %d observations\n", nrow(oil_prices)))

# PCOALAUUSDM: Global coal price, Australia (monthly, USD)
cat("  Fetching coal prices...\n")
coal_prices <- fetch_fred("PCOALAUUSDM", fred_key)
cat(sprintf("    %d observations\n", nrow(coal_prices)))

# Aggregate to quarterly
price_quarterly <- bind_rows(oil_prices, coal_prices) %>%
  mutate(
    year = year(date),
    quarter = quarter(date)
  ) %>%
  group_by(series, year, quarter) %>%
  summarise(price = mean(value, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = series, values_from = price) %>%
  rename(oil_price = DCOILWTICO, coal_price = PCOALAUUSDM)

write_csv(price_quarterly, "../data/commodity_prices.csv")
cat("  Saved commodity_prices.csv\n")

# --- Summary ---
cat("\n=== Data fetch complete ===\n")
cat(sprintf("QWI mining: %d rows, %d counties\n",
            nrow(qwi_mining), n_distinct(qwi_mining$geography)))
cat(sprintf("QWI total: %d rows\n", nrow(qwi_total)))
cat(sprintf("Coal prices: %d quarters\n", sum(!is.na(price_quarterly$coal_price))))
cat(sprintf("Oil prices: %d quarters\n", sum(!is.na(price_quarterly$oil_price))))
