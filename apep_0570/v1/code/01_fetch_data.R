# ==============================================================================
# 01_fetch_data.R — Load CPI data (pre-converted from Parquet by Python)
# APEP-0570: Malaysia GST-to-SST Tax Pass-Through
# ==============================================================================

source("00_packages.R")

cat("=== Loading OpenDOSM CPI data ===\n")

# Data was downloaded and converted from Parquet (Brotli-compressed) to CSV
# by Python's pyarrow. Source: OpenDOSM (storage.dosm.gov.my)
cpi_4d <- fread("../data/cpi_4d_raw.csv")
cpi_2d <- fread("../data/cpi_2d_raw.csv")

# Convert date columns
cpi_4d[, date := as.Date(date)]
cpi_2d[, date := as.Date(date)]

cat("4-digit CPI:", nrow(cpi_4d), "rows,",
    uniqueN(cpi_4d$date), "dates,",
    uniqueN(cpi_4d$class), "classes\n")

cat("2-digit CPI:", nrow(cpi_2d), "rows,",
    uniqueN(cpi_2d$date), "dates,",
    uniqueN(cpi_2d$division), "divisions\n")

# --- Inspect class codes ---
cat("\n=== 4-digit class codes (COICOP) ===\n")
classes <- sort(unique(cpi_4d$class))
cat("Number of classes:", length(classes), "\n")
cat("Class codes:\n")
print(classes)

# --- Date range ---
cat("\n=== Date range ===\n")
cat("4-digit:", as.character(min(cpi_4d$date)), "to",
    as.character(max(cpi_4d$date)), "\n")
cat("2-digit:", as.character(min(cpi_2d$date)), "to",
    as.character(max(cpi_2d$date)), "\n")

# --- Sample around June 2018 ---
cat("\n=== CPI around June 2018 (GST zeroing) ===\n")
window <- cpi_4d[date >= "2018-04-01" & date <= "2018-10-01"]
for (cl in head(classes, 15)) {
  sub <- window[class == cl]
  if (nrow(sub) > 0) {
    cat(sprintf("Class %s: ", cl))
    for (i in 1:nrow(sub)) {
      cat(sprintf("%s=%.1f  ", format(sub$date[i], "%Y-%m"), sub$index[i]))
    }
    cat("\n")
  }
}

# === DATA VALIDATION (required) ===
stopifnot("Expected 90+ product classes" = uniqueN(cpi_4d$class) >= 90)
stopifnot("Expected data from 2010" = min(cpi_4d$date) <= as.Date("2010-02-01"))
stopifnot("Expected data through 2025" = max(cpi_4d$date) >= as.Date("2025-01-01"))
stopifnot("Expected 15000+ observations" = nrow(cpi_4d) >= 15000)

cat("\n=== Data validation PASSED ===\n")
cat("4-digit CPI:", nrow(cpi_4d), "rows,",
    uniqueN(cpi_4d$class), "classes,",
    uniqueN(cpi_4d$date), "months\n")
