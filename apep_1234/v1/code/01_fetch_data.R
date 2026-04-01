## 01_fetch_data.R — Fetch Panama banking data from SBP
## APEP paper apep_1234: FATF Grey-Listing and Panama Banking

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

base_url <- "https://www.superbancos.gob.pa"

# ---- 1. Financial Indicators (monthly, by bank type) ----
url_indicators <- paste0(base_url, "/documentos/financiera_y_estadistica/reportes_estadisticos/2026/02/otros/Indicadores_Financieros.xlsx?v=3.01")
dest_indicators <- file.path(data_dir, "Indicadores_Financieros.xlsx")

cat("Downloading Indicadores_Financieros.xlsx...\n")
resp <- GET(url_indicators, write_disk(dest_indicators, overwrite = TRUE), timeout(120))
stopifnot("Failed to download Indicadores_Financieros.xlsx" = status_code(resp) == 200)
cat(sprintf("  Downloaded: %s bytes\n", file.size(dest_indicators)))

# ---- 2. Bank Listing (monthly, individual banks) ----
url_bancos <- paste0(base_url, "/documentos/financiera_y_estadistica/reportes_estadisticos/2026/02/otros/BANCOS.xlsx?v=1.03")
dest_bancos <- file.path(data_dir, "BANCOS.xlsx")

cat("Downloading BANCOS.xlsx...\n")
resp2 <- GET(url_bancos, write_disk(dest_bancos, overwrite = TRUE), timeout(120))
stopifnot("Failed to download BANCOS.xlsx" = status_code(resp2) == 200)
cat(sprintf("  Downloaded: %s bytes\n", file.size(dest_bancos)))

# ---- 3. Balance Sheets by bank type (comparative — multi-year) ----
balance_files <- list(
  BIL = "RE-BALANCE-COMPARATIVO-en-BIL.xlsx",  # International License
  BPP = "RE-BALANCE-COMPARATIVO-en-BPP.xlsx",  # Panamanian Private
  CBI = "RE-BALANCE-COMPARATIVO-en-CBI.xlsx"   # Centro Bancario (total)
)

for (code in names(balance_files)) {
  fname <- balance_files[[code]]
  url <- paste0(base_url, "/documentos/financiera_y_estadistica/reportes_estadisticos/2026/02/balance_ambito_nacional/", fname)
  dest <- file.path(data_dir, fname)
  cat(sprintf("Downloading %s...\n", fname))
  resp_b <- GET(url, write_disk(dest, overwrite = TRUE), timeout(120))
  if (status_code(resp_b) == 200) {
    cat(sprintf("  Downloaded: %s bytes\n", file.size(dest)))
  } else {
    warning(sprintf("Failed to download %s (HTTP %d) — will proceed without it", fname, status_code(resp_b)))
  }
}

# ---- 4. World Bank indicators (annual, for context) ----
cat("Fetching World Bank NPL indicator for Panama...\n")
wb_url <- "https://api.worldbank.org/v2/country/PAN/indicator/FB.AST.NPER.ZS?date=2014:2025&format=json&per_page=50"
wb_resp <- GET(wb_url, timeout(30))
if (status_code(wb_resp) == 200) {
  wb_data <- content(wb_resp, as = "parsed")
  if (length(wb_data) >= 2 && length(wb_data[[2]]) > 0) {
    wb_npl <- tibble(
      year = map_chr(wb_data[[2]], ~ .x$date),
      npl_ratio = map_dbl(wb_data[[2]], ~ ifelse(is.null(.x$value), NA_real_, as.numeric(.x$value)))
    ) %>% arrange(year)
    write_csv(wb_npl, file.path(data_dir, "wb_npl_panama.csv"))
    cat(sprintf("  World Bank NPL data: %d years\n", nrow(wb_npl)))
  }
} else {
  warning("World Bank API failed — proceeding without NPL data")
}

# ---- 5. FRED deposit-to-GDP (annual, for context) ----
fred_key <- Sys.getenv("FRED_API_KEY")
if (nchar(fred_key) > 0) {
  cat("Fetching FRED deposit-to-GDP for Panama...\n")
  fred_url <- paste0(
    "https://api.stlouisfed.org/fred/series/observations?series_id=DDOI02PAA156NWDB",
    "&api_key=", fred_key, "&file_type=json&observation_start=2014-01-01"
  )
  fred_resp <- GET(fred_url, timeout(30))
  if (status_code(fred_resp) == 200) {
    fred_parsed <- content(fred_resp, as = "parsed")
    fred_df <- tibble(
      date = map_chr(fred_parsed$observations, ~ .x$date),
      deposits_gdp = map_chr(fred_parsed$observations, ~ .x$value)
    ) %>% mutate(deposits_gdp = as.numeric(deposits_gdp))
    write_csv(fred_df, file.path(data_dir, "fred_deposits_gdp_panama.csv"))
    cat(sprintf("  FRED data: %d observations\n", nrow(fred_df)))
  } else {
    warning("FRED API returned non-200 — proceeding without it")
  }
} else {
  cat("  FRED_API_KEY not set — skipping FRED data\n")
}

cat("\nData fetch complete. Files in:", data_dir, "\n")
cat("Contents:\n")
cat(paste(" ", list.files(data_dir), collapse = "\n"), "\n")
