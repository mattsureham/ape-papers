## 01_fetch_data.R — Fetch Eurostat data for Finland Competitiveness Pact analysis
## apep_0664

source("code/00_packages.R")

cat("=== Fetching Eurostat data ===\n")

## ---- Helper function ----
fetch_eurostat_sdmx <- function(dataset, filter, start = 2008, end = 2022) {
  base_url <- "https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data"
  url <- paste0(base_url, "/", dataset, "/", filter,
                "?format=SDMX-CSV&startPeriod=", start, "&endPeriod=", end)
  cat("Fetching:", url, "\n")

  resp <- httr::GET(url, httr::timeout(120))
  if (httr::status_code(resp) != 200) {
    stop(paste("Eurostat API returned status", httr::status_code(resp), "for", dataset))
  }

  raw_text <- httr::content(resp, as = "text", encoding = "UTF-8")
  df <- readr::read_csv(raw_text, show_col_types = FALSE)

  cat("  Rows:", nrow(df), "\n")
  if (nrow(df) == 0) stop(paste("Empty response from Eurostat for", dataset))

  return(df)
}

## ---- 1. Total hours worked and employment by NACE sector ----
## nama_10_a10_e: National accounts employment data by A*10 industry
hours_raw <- fetch_eurostat_sdmx(
  "nama_10_a10_e",
  "A.THS_HW+THS_PER..EMP_DC.FI+SE+DK+NO",
  start = 2008, end = 2022
)

## ---- 2. GVA by NACE sector ----
## nama_10_a10: National accounts aggregates by A*10 industry
gva_raw <- fetch_eurostat_sdmx(
  "nama_10_a10",
  "A.CLV10_MEUR+CP_MEUR...FI+SE+DK+NO",
  start = 2008, end = 2022
)

## ---- 3. LFS employment by detailed NACE (robustness) ----
lfs_raw <- fetch_eurostat_sdmx(
  "lfsa_egan2",
  "A.THS_PER.T.Y15-64.TOTAL.FI+SE+DK+NO",
  start = 2008, end = 2022
)

## ---- Save raw data ----
saveRDS(hours_raw, "data/hours_raw.rds")
saveRDS(gva_raw, "data/gva_raw.rds")
saveRDS(lfs_raw, "data/lfs_raw.rds")

cat("\n=== Data fetch complete ===\n")
cat("Hours/employment data:", nrow(hours_raw), "rows\n")
cat("GVA data:", nrow(gva_raw), "rows\n")
cat("LFS data:", nrow(lfs_raw), "rows\n")
