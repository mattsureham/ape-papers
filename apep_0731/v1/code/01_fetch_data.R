## 01_fetch_data.R — Download IRS EO BMF data
## apep_0731: Nonprofit bunching at state audit thresholds

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ── Download IRS Exempt Organizations BMF ──────────────────────────────────
## The EO BMF is published by IRS as region-specific CSV files
## We download all four region files and combine

bmf_urls <- c(
  "https://www.irs.gov/pub/irs-soi/eo1.csv",
  "https://www.irs.gov/pub/irs-soi/eo2.csv",
  "https://www.irs.gov/pub/irs-soi/eo3.csv",
  "https://www.irs.gov/pub/irs-soi/eo4.csv"
)

bmf_files <- file.path(data_dir, paste0("eo", 1:4, ".csv"))

for (i in seq_along(bmf_urls)) {
  if (!file.exists(bmf_files[i])) {
    cat("Downloading", bmf_urls[i], "...\n")
    resp <- httr::GET(
      bmf_urls[i],
      httr::write_disk(bmf_files[i], overwrite = TRUE),
      httr::timeout(300),
      httr::user_agent("APEP Research (academic)")
    )
    if (httr::status_code(resp) != 200) {
      stop("Failed to download ", bmf_urls[i], ": HTTP ", httr::status_code(resp))
    }
    cat("  Saved:", bmf_files[i], "\n")
  } else {
    cat("Already have:", bmf_files[i], "\n")
  }
}

## ── Read and combine ───────────────────────────────────────────────────────
cat("\nReading EO BMF files...\n")
bmf_list <- lapply(bmf_files, function(f) {
  dt <- fread(f, colClasses = "character")
  cat("  Read", nrow(dt), "rows from", basename(f), "\n")
  dt
})
bmf <- rbindlist(bmf_list, fill = TRUE)
cat("\nTotal organizations:", format(nrow(bmf), big.mark = ","), "\n")

## ── Basic validation ───────────────────────────────────────────────────────
stopifnot("EIN" %in% names(bmf))
stopifnot("STATE" %in% names(bmf))

## Standardize revenue column
## IRS EO BMF has REVENUE_AMT or INCOME_AMT depending on version
rev_cols <- intersect(c("REVENUE_AMT", "INCOME_AMT", "ASSET_AMT"), names(bmf))
cat("Available financial columns:", paste(rev_cols, collapse = ", "), "\n")

## Convert revenue to numeric
if ("REVENUE_AMT" %in% names(bmf)) {
  bmf[, revenue := as.numeric(REVENUE_AMT)]
} else if ("INCOME_AMT" %in% names(bmf)) {
  bmf[, revenue := as.numeric(INCOME_AMT)]
} else {
  stop("No revenue column found in EO BMF data!")
}

## Basic stats
cat("\nRevenue summary:\n")
cat("  Non-missing:", format(sum(!is.na(bmf$revenue)), big.mark = ","), "\n")
cat("  Positive:", format(sum(bmf$revenue > 0, na.rm = TRUE), big.mark = ","), "\n")
cat("  Median (positive):", format(median(bmf$revenue[bmf$revenue > 0], na.rm = TRUE), big.mark = ","), "\n")
cat("  Mean (positive):", format(mean(bmf$revenue[bmf$revenue > 0], na.rm = TRUE), big.mark = ","), "\n")

## ── Save combined data ─────────────────────────────────────────────────────
fwrite(bmf, file.path(data_dir, "eo_bmf_combined.csv"))
cat("\nSaved combined EO BMF:", file.path(data_dir, "eo_bmf_combined.csv"), "\n")
cat("Done.\n")
