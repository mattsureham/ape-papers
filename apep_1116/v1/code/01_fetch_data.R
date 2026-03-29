## 01_fetch_data.R — Data acquisition (reads BigQuery exports)
## APEP-1116: The Patent Office Lottery
##
## Data fetched by 00_fetch_data.py from BigQuery.
## This script validates the CSV files exist and are non-empty.

source("00_packages.R")

data_dir <- file.path(dirname(getwd()), "data")

# Validate data files exist
files_needed <- c("twin_pairs.csv", "examiner_grant_rates.csv", "office_actions.csv")
for (f in files_needed) {
  fpath <- file.path(data_dir, f)
  if (!file.exists(fpath)) {
    stop(paste("MISSING DATA FILE:", fpath,
               "\nRun 00_fetch_data.py first to fetch from BigQuery."))
  }
  sz <- file.info(fpath)$size
  if (sz < 1000) {
    stop(paste("DATA FILE TOO SMALL:", fpath, "—", sz, "bytes"))
  }
  cat(sprintf("  ✓ %s (%.1f MB)\n", f, sz / 1e6))
}

cat("\nAll data files validated. Proceed to 02_clean_data.R\n")
