# ==============================================================================
# 01_fetch_data.R — Load QWI data (fetched from Azure via Python)
# ==============================================================================
# Data was fetched by 01_fetch_data.py using Python DuckDB Azure extension.
# This script validates the CSV output.

source("00_packages.R")

qwi <- fread("../data/qwi_raw.csv")

cat(sprintf("Loaded %s rows from qwi_raw.csv\n", format(nrow(qwi), big.mark = ",")))
stopifnot("QWI data must have rows" = nrow(qwi) > 100000)

# Validate structure
stopifnot("Must have fips_county" = "fips_county" %in% names(qwi))
stopifnot("Must have year" = "year" %in% names(qwi))
stopifnot("Must have Emp" = "Emp" %in% names(qwi))

cat(sprintf("Counties: %d\n", uniqueN(qwi$fips_county)))
cat(sprintf("Year range: %d-%d\n", min(qwi$year), max(qwi$year)))
cat(sprintf("Industries: %s\n", paste(sort(unique(qwi$industry)), collapse = ", ")))
cat(sprintf("Age groups: %s\n", paste(sort(unique(qwi$agegrp)), collapse = ", ")))

cat("Data validation passed.\n")
