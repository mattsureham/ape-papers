## 01_fetch_data.R — Fetch Eurostat employment by sector
## apep_0666: EU smoking bans and hospitality employment

source("code/00_packages.R")

cat("=== Fetching Eurostat data ===\n")

fetch_eurostat <- function(dataset, filter, start = 1995, end = 2023) {
  url <- paste0("https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/",
                dataset, "/", filter,
                "?format=SDMX-CSV&startPeriod=", start, "&endPeriod=", end)
  cat("Fetching:", substr(url, 1, 120), "...\n")
  resp <- httr::GET(url, httr::timeout(120))
  if (httr::status_code(resp) != 200) {
    cat("  ERROR: HTTP", httr::status_code(resp), "\n")
    stop(paste("API error for", dataset))
  }
  raw <- httr::content(resp, as = "text", encoding = "UTF-8")
  df <- readr::read_csv(raw, show_col_types = FALSE)
  cat("  Rows:", nrow(df), "\n")
  stopifnot(nrow(df) > 0)
  return(df)
}

## 1. Employment by NACE A*10 sector for all EU/EEA countries
## nama_10_a10_e: freq, na_item, unit, nace_r2, geo
## We want: EMP_DC (domestic concept employment), THS_PER (thousands of persons)
## Dimensions: freq, unit, nace_r2, na_item, geo
## Need explicit country list (API rejects wildcard with too many results)
countries <- "AT+BE+BG+CY+CZ+DE+DK+EE+EL+ES+FI+FR+HR+HU+IE+IT+LT+LU+LV+MT+NL+NO+PL+PT+RO+SE+SI+SK+UK"

emp_raw <- fetch_eurostat(
  "nama_10_a10_e",
  paste0("A.THS_PER.G-I+J+K+M_N+TOTAL.EMP_DC.", countries),
  start = 1995, end = 2023
)

## Also fetch hours worked for intensity
hours_raw <- fetch_eurostat(
  "nama_10_a10_e",
  paste0("A.THS_HW.G-I+J+K+M_N+TOTAL.EMP_DC.", countries),
  start = 1995, end = 2023
)

## Save
saveRDS(emp_raw, "data/emp_raw.rds")
saveRDS(hours_raw, "data/hours_raw.rds")

cat("\n=== Fetch complete ===\n")
cat("Employment:", nrow(emp_raw), "rows\n")
cat("Hours:", nrow(hours_raw), "rows\n")
cat("Countries:", paste(sort(unique(emp_raw$geo)), collapse = ", "), "\n")
