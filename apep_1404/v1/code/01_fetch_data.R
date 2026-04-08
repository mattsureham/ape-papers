# 01_fetch_data.R — Fetch PHMSA pipeline incident data
source("00_packages.R")

# Download PHMSA cleaned incident data from GitHub
url <- "https://raw.githubusercontent.com/jmceager/phmsa_clean/main/data/all_inc.csv"
dest <- "../data/all_inc.csv"

if (!file.exists(dest)) {
  cat("Downloading PHMSA incident data...\n")
  download.file(url, dest, mode = "wb")
}

raw <- fread(dest)
cat("Raw data:", nrow(raw), "rows,", ncol(raw), "columns\n")
cat("Years:", min(raw$IYEAR, na.rm = TRUE), "-", max(raw$IYEAR, na.rm = TRUE), "\n")
cat("Columns:", paste(names(raw)[1:20], collapse = ", "), "...\n")

# Verify key columns exist
stopifnot("TOTAL_COST_CURRENT" %in% names(raw))
stopifnot("SIGNIFICANT" %in% names(raw))
stopifnot("OPERATOR_ID" %in% names(raw))
stopifnot("IYEAR" %in% names(raw))

# Download CPI data from FRED
fred_key <- Sys.getenv("FRED_API_KEY")
if (fred_key == "") stop("FRED_API_KEY not set in .env")

cpi_url <- paste0(
  "https://api.stlouisfed.org/fred/series/observations?",
  "series_id=CPIAUCSL&api_key=", fred_key,
  "&file_type=json&observation_start=1984-01-01&observation_end=2023-12-31&frequency=a"
)

cpi_resp <- jsonlite::fromJSON(cpi_url)
cpi <- data.table(
  year = as.integer(substr(cpi_resp$observations$date, 1, 4)),
  cpi = as.numeric(cpi_resp$observations$value)
)
cat("CPI data:", nrow(cpi), "years\n")

# Save
saveRDS(raw, "../data/raw_incidents.rds")
saveRDS(cpi, "../data/cpi.rds")
cat("Data saved to data/\n")
