## 01_fetch_data.R — Download and validate all data sources
## APEP-0861: Austerity Triage and Domestic Abuse Justice

source("00_packages.R")
setwd("..")

cat("=== DATA ACQUISITION ===\n")

# ---------------------------------------------------------------
# 1. Police workforce (pre-downloaded via shell)
#    Source: Home Office Police Workforce Open Data Tables
#    URL: https://assets.publishing.service.gov.uk/media/697255b5a1311bdcfa0ed8f3/open-data-table-police-workforce-280126.ods
# ---------------------------------------------------------------
stopifnot(file.exists("data/police_workforce.ods"))
cat("Police workforce ODS present.\n")

# ---------------------------------------------------------------
# 2. Crime outcomes supplementary metrics (pre-downloaded)
#    Source: Home Office Crime Outcomes Open Data
#    URL: https://assets.publishing.service.gov.uk/media/679a2ab5a77d250007d3145a/prc-supplementary-crime-outcomes-metrics-300125.xlsx
# ---------------------------------------------------------------
stopifnot(file.exists("data/crime_outcomes_supplementary.xlsx"))
cat("Crime outcomes supplementary XLSX present.\n")

# ---------------------------------------------------------------
# 3. DA and CJS appendix tables (pre-downloaded)
#    Source: ONS Domestic Abuse and the Criminal Justice System
#    Downloaded 2024 edition
# ---------------------------------------------------------------
stopifnot(file.exists("data/da_cjs_2024.xlsx"))
cat("DA CJS 2024 XLSX present.\n")

# ---------------------------------------------------------------
# 4. Validate all raw files
# ---------------------------------------------------------------
raw_files <- c(
  "data/police_workforce.ods",
  "data/crime_outcomes_supplementary.xlsx",
  "data/da_cjs_2024.xlsx"
)

cat("\n=== VALIDATION ===\n")
for (f in raw_files) {
  sz <- file.info(f)$size
  cat(sprintf("  %-50s %10s bytes  %s\n", f, format(sz, big.mark = ","),
              if (!is.na(sz) && sz > 100) "OK" else "FAIL"))
  if (is.na(sz) || sz < 100) stop(paste("FATAL: Missing or empty:", f))
}

cat("\nAll raw data files validated.\n")
