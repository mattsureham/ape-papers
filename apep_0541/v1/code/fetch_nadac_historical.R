source("00_packages.R")
data_dir <- "../data"

# Fetch multiple NADAC files from Medicaid.gov for broader coverage
# The main NADAC dataset has a Socrata-compatible endpoint
# Try the full historical dataset via data.medicaid.gov

cat("=== Fetching historical NADAC via data.medicaid.gov ===\n")

# The full NADAC dataset ID: dfa2ab14-06c2-457a-9e36-5cb6d80f8d93
# Try downloading annual snapshots from different years

nadac_files <- c()
years_to_try <- c(2018, 2019, 2020, 2021, 2022, 2023)

for (yr in years_to_try) {
  # Try date-specific download URLs
  dates_to_try <- sprintf("%d-12-25", yr)
  for (dt in dates_to_try) {
    url <- sprintf("https://download.medicaid.gov/data/nadac-national-average-drug-acquisition-cost-%s.csv", dt)
    dest <- file.path(data_dir, sprintf("nadac_%d.csv", yr))
    
    if (file.exists(dest) && file.size(dest) > 10000) {
      cat(sprintf("  %d: already downloaded\n", yr))
      nadac_files <- c(nadac_files, dest)
      next
    }
    
    result <- tryCatch({
      download.file(url, dest, mode = "wb", quiet = TRUE)
      if (file.size(dest) > 10000) {
        cat(sprintf("  %d: downloaded (%.1f MB)\n", yr, file.size(dest)/1e6))
        nadac_files <- c(nadac_files, dest)
      } else {
        cat(sprintf("  %d: file too small, skipping\n", yr))
        file.remove(dest)
      }
      TRUE
    }, error = function(e) {
      cat(sprintf("  %d: download failed (%s)\n", yr, e$message))
      FALSE
    })
  }
}

# Also try API endpoint for older data
cat("\nTrying Medicaid.gov API for more historical data...\n")

# The API endpoint
api_url <- "https://data.medicaid.gov/api/1/datastore/query/a4y5-998d/0"

# Test if API gives different data than the CSV
test <- tryCatch({
  resp <- httr::GET(api_url, query = list(limit = 5), httr::timeout(30))
  if (httr::status_code(resp) == 200) {
    content <- httr::content(resp, as = "text", encoding = "UTF-8")
    data <- jsonlite::fromJSON(content)
    cat("API accessible. Sample date range:\n")
    if (!is.null(data$results)) {
      print(head(data$results[, c("effective_date", "ndc_description")]))
    }
  } else {
    cat("API returned status:", httr::status_code(resp), "\n")
  }
}, error = function(e) cat("API error:", e$message, "\n"))

# Combine all NADAC files
cat("\nCombining all NADAC files...\n")
all_nadac <- list()
existing_files <- list.files(data_dir, pattern = "nadac_\\d{4}\\.csv", full.names = TRUE)
# Also include the main raw file
if (file.exists(file.path(data_dir, "nadac_raw.csv"))) {
  existing_files <- c(file.path(data_dir, "nadac_raw.csv"), existing_files)
}

for (f in existing_files) {
  dt <- fread(f, select = c("NDC Description", "NDC", "NADAC Per Unit", 
                             "Effective Date", "Classification for Rate Setting"))
  cat(sprintf("  %s: %d records\n", basename(f), nrow(dt)))
  all_nadac[[f]] <- dt
}

if (length(all_nadac) > 0) {
  combined <- rbindlist(all_nadac, fill = TRUE)
  # Standardize names
  setnames(combined, 
           c("NDC Description", "NDC", "NADAC Per Unit", 
             "Effective Date", "Classification for Rate Setting"),
           c("ndc_description", "ndc", "nadac_per_unit", 
             "effective_date", "classification"),
           skip_absent = TRUE)
  
  # Deduplicate
  combined <- unique(combined, by = c("ndc", "effective_date"))
  
  fwrite(combined, file.path(data_dir, "nadac_combined.csv"))
  cat(sprintf("\nCombined NADAC: %d unique records\n", nrow(combined)))
  
  # Parse dates to check range
  combined[, eff_date := as.Date(effective_date, format = "%m/%d/%Y")]
  cat("Date range:", as.character(min(combined$eff_date, na.rm = TRUE)),
      "to", as.character(max(combined$eff_date, na.rm = TRUE)), "\n")
}
