# 01_fetch_data.R — Fetch FCA complaints + BoE insurance data
# REAL DATA ONLY — no simulation, no silent fallback

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ==============================================================================
# 1. FCA Aggregate Complaints Data
# ==============================================================================
# FCA publishes half-yearly Excel files with "Product Specific" sheet.
# Each file contains multiple periods. Newer files use no-hyphen URLs,
# older files use hyphen format. 2021-h1 does not exist on FCA site.

cat("=== Fetching FCA Aggregate Complaints Data ===\n")

fca_urls <- list(
  "2025h1"  = "https://www.fca.org.uk/publication/data/aggregate-complaints-data-2025-h1.xlsx",
  "2024h1"  = "https://www.fca.org.uk/publication/data/aggregate-complaints-data-2024-h1.xlsx",
  "2023h1"  = "https://www.fca.org.uk/publication/data/aggregate-complaints-data-2023-h1.xlsx",
  "2022h1"  = "https://www.fca.org.uk/publication/data/aggregate-complaints-data-2022-h1.xlsx",
  "2020h2"  = "https://www.fca.org.uk/publication/data/aggregate-complaints-data-2020-h2.xlsx",
  "2020h1"  = "https://www.fca.org.uk/publication/data/aggregate-complaints-data-2020-h1.xlsx",
  "2019h2"  = "https://www.fca.org.uk/publication/data/aggregate-complaints-data-2019-h2.xlsx",
  "2019h1"  = "https://www.fca.org.uk/publication/data/aggregate-complaints-data-2019-h1.xlsx",
  "2018h2"  = "https://www.fca.org.uk/publication/data/aggregate-complaints-data-2018-h2.xlsx"
)

for (label in names(fca_urls)) {
  dest <- file.path(data_dir, paste0("fca_complaints_", label, ".xlsx"))
  if (!file.exists(dest)) {
    cat(sprintf("  Downloading FCA %s ...\n", label))
    resp <- GET(fca_urls[[label]], write_disk(dest, overwrite = TRUE))
    if (status_code(resp) != 200) {
      cat(sprintf("  WARNING: FCA download failed for %s (HTTP %d)\n", label, status_code(resp)))
      file.remove(dest)
      next
    }
    cat(sprintf("  -> %s (%d bytes)\n", dest, file.size(dest)))
  } else {
    cat(sprintf("  Already have %s\n", dest))
  }
}

# ==============================================================================
# 2. Bank of England Insurance Aggregate Data
# ==============================================================================

cat("\n=== Fetching Bank of England Insurance Data ===\n")

boe_url <- "https://www.bankofengland.co.uk/-/media/boe/files/statistics/insurance-aggregate/insurance-aggregate-data-file.csv"
boe_dest <- file.path(data_dir, "boe_insurance_aggregate.csv")

if (!file.exists(boe_dest)) {
  cat("  Downloading BoE insurance aggregate CSV ...\n")
  resp <- GET(boe_url, write_disk(boe_dest, overwrite = TRUE))
  if (status_code(resp) != 200) {
    stop(sprintf("FATAL: BoE download failed (HTTP %d)", status_code(resp)))
  }
  cat(sprintf("  -> %s (%d bytes)\n", boe_dest, file.size(boe_dest)))
} else {
  cat(sprintf("  Already have %s\n", boe_dest))
}

# ==============================================================================
# 3. Validate downloads
# ==============================================================================

cat("\n=== Validating downloads ===\n")

fca_files <- list.files(data_dir, pattern = "fca_complaints_.*\\.xlsx$", full.names = TRUE)
if (length(fca_files) < 3) stop("FATAL: Need at least 3 FCA files for adequate time coverage")
cat(sprintf("  FCA files downloaded: %d\n", length(fca_files)))

for (f in fca_files) {
  sheets <- excel_sheets(f)
  cat(sprintf("  %s: %d sheets\n", basename(f), length(sheets)))
  if (!"Product Specific" %in% sheets) {
    cat(sprintf("    WARNING: No 'Product Specific' sheet in %s\n", basename(f)))
  }
}

boe_size <- file.size(boe_dest)
if (boe_size < 1000) stop("FATAL: BoE CSV is suspiciously small")
cat(sprintf("  BoE CSV size: %s bytes\n", format(boe_size, big.mark = ",")))

cat("\n=== Data fetch complete ===\n")
