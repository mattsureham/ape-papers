## 01_fetch_data.R — Download Singapore property market data
## apep_1417: Singapore ABSD and Housing Markets
##
## All data from data.gov.sg (URA / SingStat public APIs)

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# Helper: download from data.gov.sg
fetch_datagov <- function(dataset_id, outfile, desc) {
  if (file.exists(outfile)) {
    cat("  [cached]", desc, "\n")
    return(invisible(NULL))
  }
  cat("  Downloading", desc, "...")
  url <- paste0("https://api-open.data.gov.sg/v1/public/api/datasets/", dataset_id, "/poll-download")
  resp <- httr2::request(url) |> httr2::req_perform()
  body <- httr2::resp_body_json(resp)
  download_url <- body$data$url
  stopifnot("Download URL not found" = !is.null(download_url) && nchar(download_url) > 0)
  download.file(download_url, outfile, mode = "wb", quiet = TRUE)
  stopifnot("Downloaded file is empty" = file.size(outfile) > 100)
  cat(" OK\n")
  Sys.sleep(5)  # Rate limit
}

cat("=== Fetching Singapore property data ===\n")

# 1. Property price index by locality (CCR/RCR/OCR), quarterly
fetch_datagov("d_f65e490a8ad430f60a9a3d9df2bff2a0",
              file.path(data_dir, "ppi_locality.csv"),
              "Property Price Index by Locality")

# 2. Rental index by locality (CCR/RCR/OCR), quarterly
fetch_datagov("d_56b0c7f6538be69f24956634d88d82e8",
              file.path(data_dir, "rental_index.csv"),
              "Rental Index by Locality")

# 3. Transaction volumes — CCR
fetch_datagov("d_c287c8be114bfa7d055b27ab2c87de83",
              file.path(data_dir, "transactions_ccr.csv"),
              "CCR Transactions")

# 4. Transaction volumes — OCR
fetch_datagov("d_1a7823f3d31e7db4b426833833762bab",
              file.path(data_dir, "transactions_ocr.csv"),
              "OCR Transactions")

# 5. HDB resale flat prices (placebo — no foreign buyers)
fetch_datagov("d_8b84c4ee58e3cfc0ece0d773c8ca6abc",
              file.path(data_dir, "hdb_resale.csv"),
              "HDB Resale Flat Prices")

cat("\n=== All data downloaded ===\n")
cat("Files in data/:\n")
for (f in list.files(data_dir)) {
  sz <- file.size(file.path(data_dir, f))
  cat(sprintf("  %-30s %s\n", f, format(sz, big.mark = ",")))
}
