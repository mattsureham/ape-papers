# 01_fetch_data.R — Fetch Property Price Register data (per-year CSVs)
# Ireland HTB Price Bunching (apep_1297)
#
# Source: Property Price Register (propertypriceregister.ie)
# Per-year CSV files: PPR-{YEAR}.csv

source("00_packages.R")

cat("Fetching Property Price Register data (per-year downloads)...\n")

# Download per-year CSV files (2010-2025)
years <- 2010:2025
base_url <- "https://www.propertypriceregister.ie/website/npsra/ppr/npsra-ppr.nsf/Downloads/PPR-%d.csv/$FILE/PPR-%d.csv"

all_data <- list()

for (yr in years) {
  url <- sprintf(base_url, yr, yr)
  dest <- sprintf("../data/PPR-%d.csv", yr)

  if (!file.exists(dest)) {
    cat("Downloading", yr, "... ")
    dl_result <- tryCatch({
      download.file(url, dest, mode = "wb", quiet = TRUE)
      TRUE
    }, error = function(e) {
      cat("FAILED:", conditionMessage(e), "\n")
      FALSE
    })

    if (!dl_result || !file.exists(dest) || file.size(dest) < 1000) {
      cat("FAILED (file too small or missing)\n")
      if (file.exists(dest)) file.remove(dest)
      next
    }
    cat("OK (", round(file.size(dest) / 1e6, 1), "MB)\n")
  } else {
    cat("Using cached", yr, "(", round(file.size(dest) / 1e6, 1), "MB)\n")
  }

  # Read the CSV
  df_yr <- tryCatch({
    fread(dest, encoding = "Latin-1", header = TRUE, fill = TRUE)
  }, error = function(e) {
    cat("  Read error for", yr, ":", conditionMessage(e), "\n")
    NULL
  })

  if (!is.null(df_yr) && nrow(df_yr) > 0) {
    df_yr$source_year <- yr
    all_data[[as.character(yr)]] <- df_yr
    cat("  ", yr, ":", nrow(df_yr), "rows\n")
  }
}

if (length(all_data) == 0) {
  stop("FATAL: Could not download PPR data from any year. Cannot proceed.")
}

# Combine all years
raw <- rbindlist(all_data, fill = TRUE)
cat("\nCombined PPR data:", nrow(raw), "rows,", ncol(raw), "columns\n")
cat("Column names:", paste(names(raw), collapse = ", "), "\n")
cat("Years covered:", paste(sort(unique(raw$source_year)), collapse = ", "), "\n")

# Save raw data
saveRDS(raw, "../data/ppr_raw.rds")
cat("Saved ppr_raw.rds with", nrow(raw), "transactions\n")
