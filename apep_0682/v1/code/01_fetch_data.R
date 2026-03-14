## 01_fetch_data.R — Download EDM storm overflow data + Land Registry PPD
## apep_0682: Sewage EDM Information Revelation and House Prices

library(data.table)
library(httr2)
library(readxl)

DATA_DIR <- "data"
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)

## ── 1. EDM Long-Term Trends (2016–2024 consolidated) ──────────────────────
cat("=== Downloading EDM Long-Term Trends ===\n")
edm_zip <- file.path(DATA_DIR, "EDM_Long-term_Trends.zip")
if (!file.exists(edm_zip)) {
  edm_url <- "https://environment.data.gov.uk/api/file/download?fileDataSetId=c55e170e-3c75-49a5-8026-a961ff94c8e0&fileName=EDM_Long-term_Trends_Storm_Overflow_Annual_Return.zip"
  resp <- request(edm_url) |> req_timeout(300) |> req_perform()
  writeBin(resp_body_raw(resp), edm_zip)
  cat("Downloaded EDM long-term trends:", file.size(edm_zip), "bytes\n")
}

edm_dir <- file.path(DATA_DIR, "edm_trends")
dir.create(edm_dir, showWarnings = FALSE)
unzip(edm_zip, exdir = edm_dir, overwrite = TRUE)
edm_files <- list.files(edm_dir, pattern = "\\.(xlsx|csv)$", full.names = TRUE, recursive = TRUE)
cat("EDM files extracted:", paste(basename(edm_files), collapse = ", "), "\n")

## ── 2. EDM 2023 Annual Return (most complete year) ────────────────────────
cat("=== Downloading EDM 2023 Annual Return ===\n")
edm23_zip <- file.path(DATA_DIR, "EDM_2023_Annual_Return.zip")
if (!file.exists(edm23_zip)) {
  edm23_url <- "https://environment.data.gov.uk/api/file/download?fileDataSetId=c55e170e-3c75-49a5-8026-a961ff94c8e0&fileName=EDM_2023_Storm_Overflow_Annual_Return.zip"
  resp <- request(edm23_url) |> req_timeout(300) |> req_perform()
  writeBin(resp_body_raw(resp), edm23_zip)
  cat("Downloaded EDM 2023:", file.size(edm23_zip), "bytes\n")
}

edm23_dir <- file.path(DATA_DIR, "edm_2023")
dir.create(edm23_dir, showWarnings = FALSE)
unzip(edm23_zip, exdir = edm23_dir, overwrite = TRUE)
edm23_files <- list.files(edm23_dir, pattern = "\\.(xlsx|csv)$", full.names = TRUE, recursive = TRUE)
cat("EDM 2023 files:", paste(basename(edm23_files), collapse = ", "), "\n")

## ── 3. EDM 2024 Annual Return ─────────────────────────────────────────────
cat("=== Downloading EDM 2024 Annual Return ===\n")
edm24_zip <- file.path(DATA_DIR, "EDM_2024_Annual_Return.zip")
if (!file.exists(edm24_zip)) {
  edm24_url <- "https://environment.data.gov.uk/api/file/download?fileDataSetId=c55e170e-3c75-49a5-8026-a961ff94c8e0&fileName=EDM_2024_Storm_Overflow_Annual_Return.zip"
  resp <- request(edm24_url) |> req_timeout(300) |> req_perform()
  writeBin(resp_body_raw(resp), edm24_zip)
  cat("Downloaded EDM 2024:", file.size(edm24_zip), "bytes\n")
}

edm24_dir <- file.path(DATA_DIR, "edm_2024")
dir.create(edm24_dir, showWarnings = FALSE)
unzip(edm24_zip, exdir = edm24_dir, overwrite = TRUE)
edm24_files <- list.files(edm24_dir, pattern = "\\.(xlsx|csv)$", full.names = TRUE, recursive = TRUE)
cat("EDM 2024 files:", paste(basename(edm24_files), collapse = ", "), "\n")

## ── 4. Land Registry PPD (2016–2024, annual CSVs) ─────────────────────────
cat("=== Downloading Land Registry PPD ===\n")
lr_dir <- file.path(DATA_DIR, "land_registry")
dir.create(lr_dir, showWarnings = FALSE)

for (yr in 2016:2024) {
  lr_file <- file.path(lr_dir, paste0("pp-", yr, ".csv"))
  if (!file.exists(lr_file)) {
    lr_url <- paste0(
      "http://prod.publicdata.landregistry.gov.uk.s3-website-eu-west-1.amazonaws.com/pp-",
      yr, ".csv"
    )
    cat("  Downloading", yr, "...\n")
    resp <- tryCatch(
      request(lr_url) |> req_timeout(600) |> req_perform(),
      error = function(e) {
        cat("  FAILED:", yr, "-", conditionMessage(e), "\n")
        stop(paste("Land Registry download failed for year", yr))
      }
    )
    writeBin(resp_body_raw(resp), lr_file)
    cat("  Downloaded", yr, ":", round(file.size(lr_file) / 1e6, 1), "MB\n")
  } else {
    cat("  Already have", yr, ":", round(file.size(lr_file) / 1e6, 1), "MB\n")
  }
}

## ── 5. ONS NSPL (latest — for postcode geocoding) ─────────────────────────
cat("=== Checking NSPL availability ===\n")
nspl_file <- file.path(DATA_DIR, "NSPL.csv")
if (!file.exists(nspl_file)) {
  cat("NSPL not found locally. Will use postcodes.io API for geocoding.\n")
  cat("Alternatively, download from: https://geoportal.statistics.gov.uk/\n")
} else {
  cat("NSPL found:", round(file.size(nspl_file) / 1e6, 1), "MB\n")
}

cat("\n=== Data fetch complete ===\n")
cat("EDM trends files:", length(edm_files), "\n")
cat("EDM 2023 files:", length(edm23_files), "\n")
cat("EDM 2024 files:", length(edm24_files), "\n")
cat("Land Registry years: 2016-2024\n")
