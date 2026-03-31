## 01_fetch_data.R — Download FCA and BoE data for apep_1228
## GIPP waterbed effect in UK insurance

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ============================================================
## 1. FCA GI Value Measures Data (2022, 2023, 2024)
## ============================================================
## The FCA publishes GI Value Measures annually since 2022.
## 2024 data URL confirmed in smoke test.

fca_urls <- list(
  "2024" = "https://www.fca.org.uk/publication/data/gi-value-measures-data-2024.xlsx",
  "2023" = "https://www.fca.org.uk/publication/data/gi-value-measures-data-2023.xlsx",
  "2022" = "https://www.fca.org.uk/publication/data/gi-value-measures-data-2022.xlsx"
)

for (yr in names(fca_urls)) {
  dest <- file.path(data_dir, paste0("fca_gi_vm_", yr, ".xlsx"))
  if (!file.exists(dest)) {
    cat(sprintf("Downloading FCA GI Value Measures %s...\n", yr))
    resp <- httr::GET(fca_urls[[yr]], httr::write_disk(dest, overwrite = TRUE),
                      httr::timeout(120))
    if (httr::status_code(resp) != 200) {
      stop(sprintf("FATAL: Failed to download FCA GI VM %s. HTTP %d", yr, httr::status_code(resp)))
    }
    cat(sprintf("  Saved: %s (%d bytes)\n", dest, file.info(dest)$size))
  } else {
    cat(sprintf("  Already have: %s\n", dest))
  }
}

## ============================================================
## 2. Bank of England Insurance Aggregate Data
## ============================================================
boe_url <- "https://www.bankofengland.co.uk/-/media/boe/files/statistics/insurance-aggregate/insurance-aggregate-data-file.csv"
boe_dest <- file.path(data_dir, "boe_insurance_aggregate.csv")

if (!file.exists(boe_dest)) {
  cat("Downloading Bank of England Insurance Aggregate Data...\n")
  resp <- httr::GET(boe_url, httr::write_disk(boe_dest, overwrite = TRUE),
                    httr::timeout(120))
  if (httr::status_code(resp) != 200) {
    stop(sprintf("FATAL: Failed to download BoE data. HTTP %d", httr::status_code(resp)))
  }
  cat(sprintf("  Saved: %s (%d bytes)\n", boe_dest, file.info(boe_dest)$size))
} else {
  cat(sprintf("  Already have: %s\n", boe_dest))
}

## ============================================================
## 3. FCA Aggregate Complaints Data
## ============================================================
## Try multiple half-year vintages
complaints_urls <- c(
  "https://www.fca.org.uk/publication/data/aggregate-complaints-data-2025-h1.xlsx",
  "https://www.fca.org.uk/publication/data/aggregate-complaints-data-2024-h2.xlsx",
  "https://www.fca.org.uk/publication/data/aggregate-complaints-data-2024-h1.xlsx"
)

complaints_dest <- file.path(data_dir, "fca_complaints.xlsx")
if (!file.exists(complaints_dest)) {
  downloaded <- FALSE
  for (url in complaints_urls) {
    cat(sprintf("Trying FCA complaints: %s\n", basename(url)))
    resp <- httr::GET(url, httr::write_disk(complaints_dest, overwrite = TRUE),
                      httr::timeout(120))
    if (httr::status_code(resp) == 200 && file.info(complaints_dest)$size > 1000) {
      cat(sprintf("  Saved: %s (%d bytes)\n", complaints_dest, file.info(complaints_dest)$size))
      downloaded <- TRUE
      break
    }
  }
  if (!downloaded) {
    warning("Could not download FCA complaints data — continuing without it")
    file.remove(complaints_dest)
  }
} else {
  cat(sprintf("  Already have: %s\n", complaints_dest))
}

## ============================================================
## 4. Verify downloads
## ============================================================
cat("\n=== Data download summary ===\n")
data_files <- list.files(data_dir, full.names = TRUE)
for (f in data_files) {
  cat(sprintf("  %s: %s bytes\n", basename(f), format(file.info(f)$size, big.mark = ",")))
}

## Quick peek at FCA GI Value Measures structure
cat("\n=== FCA GI Value Measures 2024 — Sheet names ===\n")
sheets_2024 <- readxl::excel_sheets(file.path(data_dir, "fca_gi_vm_2024.xlsx"))
cat(paste(sheets_2024, collapse = "\n"), "\n")

## Quick peek at BoE data structure
cat("\n=== BoE Insurance Aggregate — First 5 rows ===\n")
boe_peek <- fread(boe_dest, nrows = 5)
print(boe_peek)

cat("\nData fetch complete.\n")
