## 01_fetch_data.R — Download MHLW Basic Survey on Wage Structure
## Source: Ministry of Health, Labour and Welfare (厚生労働省)
## Data: 賃金構造基本統計調査 (Basic Survey on Wage Structure), 2014-2024

cat("=== Fetching MHLW Wage Structure Data ===\n")

data_dir <- file.path(getwd(), "data")
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# URL patterns differ by year: .xls for 2014-2018, .xlsx for 2019+
urls <- list()
for (year in 2014:2018) {
  urls[[as.character(year)]] <- sprintf(
    "https://www.mhlw.go.jp/toukei/itiran/roudou/chingin/kouzou/z%d/xls/zuhyo.xls", year
  )
}
for (year in 2019:2024) {
  urls[[as.character(year)]] <- sprintf(
    "https://www.mhlw.go.jp/toukei/itiran/roudou/chingin/kouzou/z%d/xls/zuhyo.xlsx", year
  )
}

# Download files
for (year in names(urls)) {
  ext <- ifelse(as.integer(year) <= 2018, "xls", "xlsx")
  outpath <- file.path(data_dir, sprintf("mhlw_wage_%s.%s", year, ext))

  if (file.exists(outpath) && file.size(outpath) > 1000) {
    cat(sprintf("  %s: already downloaded (%d bytes)\n", year, file.size(outpath)))
    next
  }

  tryCatch({
    download.file(urls[[year]], outpath, mode = "wb", quiet = TRUE)
    if (file.size(outpath) < 1000) {
      stop("Downloaded file too small — likely an error page")
    }
    cat(sprintf("  %s: downloaded (%d bytes)\n", year, file.size(outpath)))
  }, error = function(e) {
    stop(sprintf("FATAL: Failed to download %s data: %s", year, e$message))
  })
}

# Verify all files present
expected_files <- character(0)
for (year in 2014:2024) {
  ext <- ifelse(year <= 2018, "xls", "xlsx")
  expected_files <- c(expected_files, file.path(data_dir, sprintf("mhlw_wage_%d.%s", year, ext)))
}

missing <- expected_files[!file.exists(expected_files)]
if (length(missing) > 0) {
  stop(sprintf("FATAL: Missing data files: %s", paste(basename(missing), collapse = ", ")))
}

cat(sprintf("\nAll %d files downloaded successfully (2014-2024).\n", length(expected_files)))
cat("Data source: MHLW Basic Survey on Wage Structure\n")
cat("URL: https://www.mhlw.go.jp/toukei/itiran/roudou/chingin/kouzou/\n")
