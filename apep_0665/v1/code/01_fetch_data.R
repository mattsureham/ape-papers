## 01_fetch_data.R — Fetch Eurostat data for Fornero analysis
## apep_0665

source("code/00_packages.R")

cat("=== Fetching Eurostat data ===\n")

fetch_eurostat <- function(dataset, filter, start = 2000, end = 2022) {
  url <- paste0("https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/",
                dataset, "/", filter,
                "?format=SDMX-CSV&startPeriod=", start, "&endPeriod=", end)
  cat("Fetching:", url, "\n")
  resp <- httr::GET(url, httr::timeout(120))
  if (httr::status_code(resp) != 200) {
    cat("  ERROR: HTTP", httr::status_code(resp), "\n")
    raw <- httr::content(resp, as = "text", encoding = "UTF-8")
    cat("  Response:", substr(raw, 1, 300), "\n")
    stop(paste("Eurostat API error for", dataset))
  }
  raw <- httr::content(resp, as = "text", encoding = "UTF-8")
  df <- readr::read_csv(raw, show_col_types = FALSE)
  cat("  Rows:", nrow(df), "\n")
  stopifnot(nrow(df) > 0)
  return(df)
}

## 1. Employment rate 55-64, both sexes, all Italian NUTS2
## Dimension order: freq, unit, sex, age, geo
emp_5564 <- fetch_eurostat(
  "lfst_r_lfe2emprt",
  "A.PC.T.Y55-64.ITC1+ITC2+ITC3+ITC4+ITF1+ITF2+ITF3+ITF4+ITF5+ITF6+ITG1+ITG2+ITH1+ITH2+ITH3+ITH4+ITH5+ITI1+ITI2+ITI3+ITI4",
  start = 2000, end = 2022
)

## 2. Employment rate 25-64 (broader working age placebo)
emp_2564 <- fetch_eurostat(
  "lfst_r_lfe2emprt",
  "A.PC.T.Y25-64.ITC1+ITC2+ITC3+ITC4+ITF1+ITF2+ITF3+ITF4+ITF5+ITF6+ITG1+ITG2+ITH1+ITH2+ITH3+ITH4+ITH5+ITI1+ITI2+ITI3+ITI4",
  start = 2000, end = 2022
)

## 3. Employment rate 15-24 (youth displacement)
emp_1524 <- fetch_eurostat(
  "lfst_r_lfe2emprt",
  "A.PC.T.Y15-24.ITC1+ITC2+ITC3+ITC4+ITF1+ITF2+ITF3+ITF4+ITF5+ITF6+ITG1+ITG2+ITH1+ITH2+ITH3+ITH4+ITH5+ITI1+ITI2+ITI3+ITI4",
  start = 2000, end = 2022
)

## 4. GFCF by NUTS2 (total and by sector)
## nama_10r_2gfcf dimensions: freq, sector, currency, nace_r2, geo
regions_str <- "ITC1+ITC2+ITC3+ITC4+ITF1+ITF2+ITF3+ITF4+ITF5+ITF6+ITG1+ITG2+ITH1+ITH2+ITH3+ITH4+ITH5+ITI1+ITI2+ITI3+ITI4"
gfcf_raw <- fetch_eurostat(
  "nama_10r_2gfcf",
  paste0("A..MIO_EUR.TOTAL+C.", regions_str),
  start = 2000, end = 2022
)

## 5. R&D by NUTS2
## rd_e_gerdreg dimensions: freq, sectperf, unit, geo
rd_raw <- fetch_eurostat(
  "rd_e_gerdreg",
  paste0("A.TOTAL.MIO_EUR.", regions_str),
  start = 2000, end = 2022
)

## Save
saveRDS(emp_5564, "data/emp_5564.rds")
saveRDS(emp_2564, "data/emp_2564.rds")
saveRDS(emp_1524, "data/emp_1524.rds")
saveRDS(gfcf_raw, "data/gfcf_raw.rds")
saveRDS(rd_raw, "data/rd_raw.rds")

cat("\n=== Fetch complete ===\n")
