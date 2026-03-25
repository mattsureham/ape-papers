## 01_fetch_data.R — Fetch QCEW data from BLS API
## APEP paper apep_0922: Alkaline Hydrolysis and Funeral Industry Competition

source("00_packages.R")

## ── Configuration ────────────────────────────────────────────────────────────
years <- 2014:2023
naics_codes <- c("812210", "812220")  # Funeral Homes; Cemeteries/Crematories
base_url <- "https://data.bls.gov/cew/data/api"

## ── Fetch function ───────────────────────────────────────────────────────────
fetch_qcew_annual <- function(year, naics) {
  url <- sprintf("%s/%d/a/industry/%s.csv", base_url, year, naics)
  message(sprintf("Fetching QCEW: year=%d, NAICS=%s", year, naics))

  resp <- GET(url, timeout(60))
  if (status_code(resp) != 200) {
    stop(sprintf("API returned status %d for year=%d, NAICS=%s",
                 status_code(resp), year, naics))
  }

  raw_text <- content(resp, as = "text", encoding = "UTF-8")
  if (nchar(raw_text) < 100) {
    stop(sprintf("API returned empty/tiny response for year=%d, NAICS=%s", year, naics))
  }

  dt <- fread(raw_text)
  dt[, naics_code := naics]
  return(dt)
}

## ── Fetch all data ───────────────────────────────────────────────────────────
all_data <- rbindlist(lapply(years, function(y) {
  rbindlist(lapply(naics_codes, function(n) {
    fetch_qcew_annual(y, n)
  }))
}), fill = TRUE)

## ── Validate ─────────────────────────────────────────────────────────────────
n_rows <- nrow(all_data)
n_years <- uniqueN(all_data$year)
message(sprintf("Fetched %d rows across %d years", n_rows, n_years))

stopifnot("No data fetched" = n_rows > 0)
stopifnot("Missing years" = n_years == length(years))

## ── Save raw data ────────────────────────────────────────────────────────────
saveRDS(all_data, "../data/qcew_raw.rds")
message(sprintf("Saved raw data: %d rows to data/qcew_raw.rds", n_rows))
