## 01_fetch_data.R — Download NIAAA alcohol consumption + CDC cigarette tax data
## APEP-0606: Cross-Substance Spillovers of Cigarette Excise Taxes

source("00_packages.R")

# =============================================================================
# 1. Download NIAAA per capita ethanol consumption data
# =============================================================================
cat("Downloading NIAAA alcohol consumption data...\n")
niaaa_url <- "https://www.niaaa.nih.gov/sites/default/files/pcyr1970-2023.txt"
niaaa_file <- "../data/niaaa_alcohol.txt"

download_result <- tryCatch({
  download.file(niaaa_url, niaaa_file, mode = "wb", quiet = FALSE)
  TRUE
}, error = function(e) {
  stop("FATAL: Failed to download NIAAA data. Error: ", e$message)
})
stopifnot("NIAAA download failed" = download_result)

# Read the NIAAA data — fixed-width or tab-delimited format
niaaa_raw <- readLines(niaaa_file)
cat("Downloaded:", length(niaaa_raw), "lines\n")
cat("First 5 lines:\n")
cat(head(niaaa_raw, 5), sep = "\n")
cat("\n")

# Save raw lines for inspection
saveRDS(niaaa_raw, "../data/niaaa_raw_lines.rds")

# =============================================================================
# 2. Download CDC Tax Burden on Tobacco data
# =============================================================================
cat("\nDownloading CDC Tax Burden on Tobacco data...\n")

# The CDC Socrata API returns JSON. We need state excise tax rates.
# Fetch all state tax per pack data
all_tax_data <- list()
offset <- 0
batch_size <- 1000

repeat {
  cdc_url <- paste0(
    "https://data.cdc.gov/resource/7nwe-3aj9.json",
    "?submeasuredesc=State%20Tax%20per%20pack",
    "&$limit=", batch_size,
    "&$offset=", offset,
    "&$order=year,locationdesc"
  )
  resp <- httr::GET(cdc_url)
  stopifnot("CDC API request failed" = httr::status_code(resp) == 200)

  batch <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
  if (nrow(batch) == 0) break

  all_tax_data[[length(all_tax_data) + 1]] <- batch
  offset <- offset + batch_size
  cat("  Fetched", offset, "rows...\n")
  if (nrow(batch) < batch_size) break
}

cdc_raw <- rbindlist(lapply(all_tax_data, as.data.table))
cat("Total CDC tax rows:", nrow(cdc_raw), "\n")
cat("Columns:", paste(names(cdc_raw), collapse = ", "), "\n")
cat("Year range:", min(cdc_raw$year), "to", max(cdc_raw$year), "\n")
cat("States:", length(unique(cdc_raw$locationdesc)), "\n")

saveRDS(cdc_raw, "../data/cdc_tax_raw.rds")
cat("CDC tax data saved to data/cdc_tax_raw.rds\n")

# =============================================================================
# 3. Validate data availability
# =============================================================================
cat("\n=== DATA FETCH COMPLETE ===\n")
cat("NIAAA: ", length(niaaa_raw), " lines\n")
cat("CDC:   ", nrow(cdc_raw), " tax-rate obs\n")

# Quick check: California 2017 tax increase
ca_tax <- cdc_raw[locationdesc == "California"]
ca_tax[, data_value := as.numeric(data_value)]
ca_tax[, year := as.integer(year)]
cat("\nCalifornia tax per pack:\n")
print(ca_tax[year >= 2014 & year <= 2019, .(year, tax = data_value)])

cat("\nData fetch complete.\n")
