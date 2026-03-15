# 01_fetch_data.R — Download IRS SOI 990 extracts and SBA PPP data
# PPP Nonprofit Employment RDD (apep_0698)

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. IRS SOI 990 Extracts (ZIP files)
# ============================================================
cat("=== Downloading IRS SOI 990 extracts ===\n")

soi_urls <- c(
  "2018" = "https://www.irs.gov/pub/irs-soi/18eoextract990.zip",
  "2019" = "https://www.irs.gov/pub/irs-soi/19eoextract990.zip",
  "2020" = "https://www.irs.gov/pub/irs-soi/20eoextract990.zip",
  "2021" = "https://www.irs.gov/pub/irs-soi/21eoextract990.zip",
  "2022" = "https://www.irs.gov/pub/irs-soi/22eoextract990.zip",
  "2023" = "https://www.irs.gov/pub/irs-soi/23eoextract990.zip"
)

for (yr in names(soi_urls)) {
  csv_file <- file.path(data_dir, paste0("soi990_", yr, ".csv"))

  # Skip if CSV already extracted
  if (file.exists(csv_file) && file.size(csv_file) > 1e6) {
    cat("  ", yr, ": already have CSV (", round(file.size(csv_file)/1e6, 1), "MB)\n")
    next
  }

  zip_file <- file.path(data_dir, paste0("soi990_", yr, ".zip"))
  cat("  Downloading", yr, "...\n")

  dl_ok <- tryCatch({
    download.file(soi_urls[[yr]], zip_file, mode = "wb", quiet = TRUE)
    file.exists(zip_file) && file.size(zip_file) > 1e5
  }, error = function(e) {
    cat("    FAILED:", conditionMessage(e), "\n")
    FALSE
  })

  if (!dl_ok) {
    cat("    Could not download", yr, "\n")
    next
  }

  cat("    ZIP:", round(file.size(zip_file)/1e6, 1), "MB. Extracting...\n")
  csv_in_zip <- unzip(zip_file, list = TRUE)$Name
  cat("    Contents:", paste(csv_in_zip, collapse = ", "), "\n")

  unzip(zip_file, exdir = data_dir)

  # Rename the extracted CSV to our standard name
  extracted <- file.path(data_dir, csv_in_zip[1])
  if (file.exists(extracted) && extracted != csv_file) {
    file.rename(extracted, csv_file)
  }

  if (file.exists(csv_file)) {
    cat("    CSV:", round(file.size(csv_file)/1e6, 1), "MB\n")
  }

  # Clean up ZIP
  unlink(zip_file)
}

# Verify SOI data
cat("\nSOI 990 files:\n")
soi_files <- list.files(data_dir, pattern = "soi990_20[12][0-9]\\.csv$", full.names = TRUE)
for (f in sort(soi_files)) {
  cat("  ", basename(f), ":", round(file.size(f)/1e6, 1), "MB\n")
}

if (length(soi_files) < 3) {
  stop("FATAL: Need at least 3 years of SOI 990 data. Only got ", length(soi_files))
}

# ============================================================
# 2. SBA PPP Loan-Level Data
# ============================================================
# We only need the $150K+ file and a sample of smaller loans
# The $150K+ file has ALL loans above $150K with org names
# For efficiency, start with just the large-loan file (has best identifiers)

cat("\n=== Downloading SBA PPP data ===\n")

ppp_150k_url <- "https://data.sba.gov/dataset/8aa276e2-6cab-4f86-aca4-a7dde42adf24/resource/c1275a03-c25c-488a-bd95-403c4b2fa036/download/public_150k_plus_240930.csv"
ppp_under_urls <- c(
  "https://data.sba.gov/dataset/8aa276e2-6cab-4f86-aca4-a7dde42adf24/resource/cff06664-1f75-4969-ab3d-6fa7d6b4c41e/download/public_up_to_150k_1_240930.csv",
  "https://data.sba.gov/dataset/8aa276e2-6cab-4f86-aca4-a7dde42adf24/resource/1e6b6629-a5aa-46e6-a442-6e67366d2362/download/public_up_to_150k_2_240930.csv",
  "https://data.sba.gov/dataset/8aa276e2-6cab-4f86-aca4-a7dde42adf24/resource/644c304a-f5ad-4cfa-b128-fe2cbcb7b26e/download/public_up_to_150k_3_240930.csv"
)

# Download $150K+ file
ppp_150k_file <- file.path(data_dir, "ppp_150k_plus.csv")
if (!file.exists(ppp_150k_file) || file.size(ppp_150k_file) < 1e6) {
  cat("  Downloading PPP $150K+ loans...\n")
  tryCatch({
    download.file(ppp_150k_url, ppp_150k_file, mode = "wb", quiet = TRUE)
    cat("    Got:", round(file.size(ppp_150k_file)/1e6, 1), "MB\n")
  }, error = function(e) cat("    FAILED:", conditionMessage(e), "\n"))
} else {
  cat("  Already have PPP $150K+ (", round(file.size(ppp_150k_file)/1e6, 1), "MB)\n")
}

# Download first 3 under-$150K files (covers most nonprofits)
for (i in seq_along(ppp_under_urls)) {
  dest <- file.path(data_dir, paste0("ppp_under150k_", i, ".csv"))
  if (file.exists(dest) && file.size(dest) > 1e6) {
    cat("  Already have PPP under-$150K file", i, "\n")
    next
  }
  cat("  Downloading PPP under-$150K file", i, "...\n")
  tryCatch({
    download.file(ppp_under_urls[[i]], dest, mode = "wb", quiet = TRUE)
    cat("    Got:", round(file.size(dest)/1e6, 1), "MB\n")
  }, error = function(e) cat("    FAILED:", conditionMessage(e), "\n"))
}

# Verify PPP data
cat("\nPPP files:\n")
ppp_local <- list.files(data_dir, pattern = "ppp_", full.names = TRUE)
for (f in sort(ppp_local)) {
  cat("  ", basename(f), ":", round(file.size(f)/1e6, 1), "MB\n")
}

if (length(ppp_local) == 0) {
  stop("FATAL: No SBA PPP data downloaded. Cannot proceed.")
}

cat("\n=== Data fetch complete ===\n")
