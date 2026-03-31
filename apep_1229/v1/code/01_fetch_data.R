# 01_fetch_data.R — Fetch FCA GI Value Measures and BoE Insurance Aggregates
# apep_1229: GIPP and Insurance Market Competition

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# 1. FCA General Insurance Value Measures Data
# ============================================================================
# Annual firm-level data on premiums, claims, and loss ratios by insurance line
# Published by FCA as part of supervisory reporting

cat("--- Fetching FCA GI Value Measures data ---\n")

# Try multiple years of GI Value Measures
fca_urls <- c(
  "2024" = "https://www.fca.org.uk/publication/data/gi-value-measures-data-2024.xlsx",
  "2023" = "https://www.fca.org.uk/publication/data/gi-value-measures-data-2023.xlsx",
  "2022" = "https://www.fca.org.uk/publication/data/gi-value-measures-data-2022.xlsx"
)

for (yr in names(fca_urls)) {
  dest <- paste0(data_dir, "fca_gi_vm_", yr, ".xlsx")
  cat("Downloading FCA GI VM", yr, "...\n")
  resp <- tryCatch(
    httr::GET(fca_urls[[yr]], httr::write_disk(dest, overwrite = TRUE),
              httr::timeout(60)),
    error = function(e) {
      cat("  ERROR downloading FCA GI VM", yr, ":", conditionMessage(e), "\n")
      NULL
    }
  )
  if (!is.null(resp) && httr::status_code(resp) == 200) {
    fsize <- file.info(dest)$size
    cat("  OK:", fsize, "bytes\n")
    if (fsize < 1000) {
      cat("  WARNING: File suspiciously small, may be error page\n")
      file.remove(dest)
    }
  } else {
    cat("  FAILED: HTTP", ifelse(!is.null(resp), httr::status_code(resp), "N/A"), "\n")
    if (file.exists(dest)) file.remove(dest)
  }
}

# Verify at least one FCA file downloaded
fca_files <- list.files(data_dir, pattern = "fca_gi_vm_.*\\.xlsx$", full.names = TRUE)
if (length(fca_files) == 0) {
  stop("FATAL: No FCA GI Value Measures files downloaded. Cannot proceed without real data.")
}
cat("FCA files downloaded:", length(fca_files), "\n")

# ============================================================================
# 2. Bank of England Insurance Aggregate Data
# ============================================================================
# Quarterly industry-level data on premiums, claims, combined ratios by line

cat("\n--- Fetching BoE Insurance Aggregate Data ---\n")

boe_url <- "https://www.bankofengland.co.uk/-/media/boe/files/statistics/insurance-aggregate/insurance-aggregate-data-file.csv"
boe_dest <- paste0(data_dir, "boe_insurance_aggregate.csv")

boe_resp <- tryCatch(
  httr::GET(boe_url, httr::write_disk(boe_dest, overwrite = TRUE), httr::timeout(120)),
  error = function(e) {
    cat("  ERROR downloading BoE data:", conditionMessage(e), "\n")
    NULL
  }
)

if (!is.null(boe_resp) && httr::status_code(boe_resp) == 200) {
  fsize <- file.info(boe_dest)$size
  cat("  OK:", fsize, "bytes\n")
  if (fsize < 1000) {
    stop("FATAL: BoE file too small, likely error page.")
  }
} else {
  stop("FATAL: Failed to download BoE Insurance Aggregate Data. HTTP ",
       ifelse(!is.null(boe_resp), httr::status_code(boe_resp), "N/A"))
}

# ============================================================================
# 3. ABI Motor Insurance Premium Tracker
# ============================================================================
# The ABI publishes average motor premium data quarterly
# Try the ABI data page

cat("\n--- Fetching ABI/industry premium tracker data ---\n")

# ABI publishes motor insurance premium data; also try ONS CPI insurance component
# ONS CPI COICOP class 12.5.2 = Insurance (available via ONS API)
# Series ID: D7DA (Insurance) from CPI detailed goods and services indices

ons_url <- "https://api.beta.ons.gov.uk/v1/datasets/cpih01/editions/time-series/versions/38/observations?time=*&geography=K02000001&aggregate=cpih1dim1A0-12-5-2"
ons_dest <- paste0(data_dir, "ons_cpi_insurance.json")

ons_resp <- tryCatch(
  httr::GET(ons_url, httr::write_disk(ons_dest, overwrite = TRUE), httr::timeout(60)),
  error = function(e) {
    cat("  WARNING: ONS CPI insurance fetch failed:", conditionMessage(e), "\n")
    NULL
  }
)

if (!is.null(ons_resp) && httr::status_code(ons_resp) == 200) {
  cat("  ONS CPI Insurance data: OK\n")
} else {
  cat("  WARNING: ONS CPI Insurance not available via this endpoint (HTTP",
      ifelse(!is.null(ons_resp), httr::status_code(ons_resp), "N/A"), ")\n")
  cat("  Will use BoE and FCA data as primary sources.\n")
}

# ============================================================================
# 4. Summary of downloaded files
# ============================================================================

cat("\n=== DATA FETCH SUMMARY ===\n")
all_files <- list.files(data_dir, full.names = TRUE)
for (f in all_files) {
  cat(sprintf("  %s (%s bytes)\n", basename(f), format(file.info(f)$size, big.mark = ",")))
}
cat("========================\n")
cat("Data fetch complete. Proceed to 02_clean_data.R\n")
