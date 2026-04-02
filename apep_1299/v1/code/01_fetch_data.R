# 01_fetch_data.R — Data acquisition for apep_1299
# The Deportation Dividend: Immigration Judge Leniency and Origin-Country Remittances

source("00_packages.R")

# ===================================================================
# 1. World Bank Remittance Data (WDI API)
# ===================================================================
cat("=== Step 1: Fetch World Bank Remittance Data ===\n")

# Top origin countries for US immigration court cases
# ISO3 codes mapped to EOIR nationality codes later in 02_clean_data.R
countries <- c(
  "MEX", "GTM", "HND", "SLV", "CHN", "IND", "HTI", "BRA",
  "COL", "ECU", "PER", "DOM", "JAM", "NGA", "ETH", "PAK",
  "PHL", "VNM", "NIC", "VEN", "GHA", "KEN", "EGY", "BGD",
  "CUB", "GUY", "TTO", "CRI", "PAN", "URY"
)

fetch_wb <- function(iso3, indicator, start_year = 2000, end_year = 2023) {
  url <- sprintf(
    "https://api.worldbank.org/v2/country/%s/indicator/%s?format=json&date=%d:%d&per_page=100",
    iso3, indicator, start_year, end_year
  )
  resp <- httr::GET(url, httr::timeout(30))
  if (httr::status_code(resp) != 200) return(NULL)
  content <- httr::content(resp, as = "parsed")
  if (length(content) < 2 || is.null(content[[2]])) return(NULL)
  records <- content[[2]]
  rbindlist(lapply(records, function(r) {
    data.table(
      iso3 = iso3,
      country_name = r$country$value,
      year = as.integer(r$date),
      value = if (is.null(r$value)) NA_real_ else as.numeric(r$value)
    )
  }))
}

# Fetch remittance inflows
cat("  Fetching remittance inflows...\n")
remit_list <- lapply(countries, function(iso3) {
  Sys.sleep(0.2)
  fetch_wb(iso3, "BX.TRF.PWKR.CD.DT")
})
remittances <- rbindlist(remit_list[!sapply(remit_list, is.null)])
setnames(remittances, "value", "remittances_usd")

# Fetch GDP (current USD) for scaling
cat("  Fetching GDP data...\n")
gdp_list <- lapply(countries, function(iso3) {
  Sys.sleep(0.2)
  fetch_wb(iso3, "NY.GDP.MKTP.CD")
})
gdp <- rbindlist(gdp_list[!sapply(gdp_list, is.null)])
setnames(gdp, "value", "gdp_usd")
gdp[, c("country_name") := NULL]

# Fetch GDP growth
cat("  Fetching GDP growth...\n")
gdpg_list <- lapply(countries, function(iso3) {
  Sys.sleep(0.2)
  fetch_wb(iso3, "NY.GDP.MKTP.KD.ZG")
})
gdpg <- rbindlist(gdpg_list[!sapply(gdpg_list, is.null)])
setnames(gdpg, "value", "gdp_growth")
gdpg[, c("country_name") := NULL]

# Fetch population
cat("  Fetching population data...\n")
pop_list <- lapply(countries, function(iso3) {
  Sys.sleep(0.2)
  fetch_wb(iso3, "SP.POP.TOTL")
})
pop <- rbindlist(pop_list[!sapply(pop_list, is.null)])
setnames(pop, "value", "population")
pop[, c("country_name") := NULL]

# Merge all WB data
wb_data <- remittances
wb_data <- merge(wb_data, gdp, by = c("iso3", "year"), all.x = TRUE)
wb_data <- merge(wb_data, gdpg, by = c("iso3", "year"), all.x = TRUE)
wb_data <- merge(wb_data, pop, by = c("iso3", "year"), all.x = TRUE)

fwrite(wb_data, "../data/wb_data.csv")
cat(sprintf("  Saved WB data: %d rows, %d countries\n", nrow(wb_data), uniqueN(wb_data$iso3)))

# Validation
stopifnot("No remittance data fetched" = sum(!is.na(wb_data$remittances_usd)) > 100)

# ===================================================================
# 2. Verify EOIR Parquet Data
# ===================================================================
cat("\n=== Step 2: Verify EOIR Data ===\n")

eoir_file <- "../data/eoir_cases.parquet"
if (file.exists(eoir_file) && file.size(eoir_file) > 1e6) {
  # Read schema only to verify
  schema <- arrow::read_parquet(eoir_file, as_data_frame = FALSE)$schema
  cat(sprintf("  EOIR parquet found: %.1f MB\n", file.size(eoir_file) / 1e6))
  cat(sprintf("  Columns: %s\n", paste(schema$names, collapse = ", ")))
} else {
  stop("EOIR parquet data not found. Download from deportationdata.org")
}

# ===================================================================
# 3. OpenImmigration.us Court Data (supplementary)
# ===================================================================
cat("\n=== Step 3: Fetch Court Index ===\n")

court_url <- "https://www.openimmigration.us/data/court-index.json"
courts <- tryCatch({
  resp <- httr::GET(court_url, httr::timeout(30))
  dt <- as.data.table(jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8")))
  cat(sprintf("  Fetched %d courts\n", nrow(dt)))
  dt
}, error = function(e) {
  cat(sprintf("  Warning: court data fetch failed: %s\n", e$message))
  NULL
})
if (!is.null(courts)) fwrite(courts, "../data/courts.csv")

cat("\n=== Data fetch complete ===\n")
