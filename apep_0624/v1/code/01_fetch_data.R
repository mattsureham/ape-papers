# 01_fetch_data.R — Fetch ECCC GHGRP facility-level emissions data
# apep_0624: Canada Carbon Backstop and Facility-Level Emissions

source("00_packages.R")

cat("=== Fetching ECCC GHGRP Data ===\n")

outfile <- "../data/ghgrp_raw.csv"

if (!file.exists(outfile)) {
  cat("Downloading GHGRP data from ECCC...\n")
  url <- "https://data-donnees.az.ec.gc.ca/api/file?path=/substances/monitor/greenhouse-gas-reporting-program-ghgrp-facility-greenhouse-gas-ghg-data/PDGES-GHGRP-GHGEmissionsGES-2004-Present.csv"
  resp <- httr::GET(url,
    httr::add_headers(
      `User-Agent` = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
      Accept = "text/csv,*/*"
    ),
    httr::write_disk(outfile, overwrite = TRUE),
    httr::timeout(300))

  if (httr::status_code(resp) != 200) {
    stop("FATAL: GHGRP download failed with HTTP ", httr::status_code(resp),
         ". Cannot proceed without real data.")
  }
  fsize <- file.info(outfile)$size
  if (fsize < 1000) {
    stop("FATAL: Downloaded file too small (", fsize, " bytes). Likely not real CSV data.")
  }
  cat("Downloaded", round(fsize / 1e6, 1), "MB\n")
} else {
  cat("GHGRP data already on disk:",
      round(file.info(outfile)$size / 1e6, 1), "MB\n")
}

# Read and validate
df_raw <- fread(outfile, encoding = "Latin-1")

cat("\n=== Data Validation ===\n")
cat("Total rows:", nrow(df_raw), "\n")
cat("Columns:", ncol(df_raw), "\n")
cat("Column names:\n")
print(names(df_raw))

stopifnot("Data has zero rows" = nrow(df_raw) > 0)
stopifnot("Data has fewer than 10 columns" = ncol(df_raw) >= 10)

# Save column names for inspection
writeLines(names(df_raw), "../data/column_names.txt")

cat("\n=== Sample rows ===\n")
print(head(df_raw, 3))

cat("\nData fetch complete.\n")
