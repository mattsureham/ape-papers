# 01_fetch_data.R — Download NHTSA flat files (investigations, complaints, recalls)
# apep_1192: Defect Queue Congestion

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. NHTSA Investigations flat file
# ============================================================
cat("Downloading NHTSA Investigations...\n")
inv_url <- "https://static.nhtsa.gov/odi/ffdd/inv/FLAT_INV.zip"
inv_zip <- file.path(data_dir, "investigations.zip")
download.file(inv_url, inv_zip, mode = "wb", quiet = FALSE)
stopifnot("Investigation download failed" = file.size(inv_zip) > 1000)

inv_dir <- file.path(data_dir, "investigations_raw")
dir.create(inv_dir, showWarnings = FALSE)
unzip(inv_zip, exdir = inv_dir)
inv_files <- list.files(inv_dir, pattern = "\\.(txt|csv|tsv)$",
                        full.names = TRUE, recursive = TRUE)
cat(sprintf("  Extracted %d files\n", length(inv_files)))

# ============================================================
# 2. NHTSA Complaints flat file (full historical)
# ============================================================
cat("Downloading NHTSA Complaints...\n")
comp_url <- "https://static.nhtsa.gov/odi/ffdd/cmpl/FLAT_CMPL.zip"
comp_zip <- file.path(data_dir, "complaints.zip")
download.file(comp_url, comp_zip, mode = "wb", quiet = FALSE)
stopifnot("Complaint download failed" = file.size(comp_zip) > 1000)

comp_dir <- file.path(data_dir, "complaints_raw")
dir.create(comp_dir, showWarnings = FALSE)
unzip(comp_zip, exdir = comp_dir)
comp_files <- list.files(comp_dir, pattern = "\\.(txt|csv|tsv)$",
                         full.names = TRUE, recursive = TRUE)
cat(sprintf("  Extracted %d files\n", length(comp_files)))

# ============================================================
# 3. NHTSA Recalls flat files (pre-2010 + post-2010)
# ============================================================
cat("Downloading NHTSA Recalls...\n")
rec_urls <- c(
  "https://static.nhtsa.gov/odi/ffdd/rcl/FLAT_RCL_PRE_2010.zip",
  "https://static.nhtsa.gov/odi/ffdd/rcl/FLAT_RCL_POST_2010.zip"
)
rec_dir <- file.path(data_dir, "recalls_raw")
dir.create(rec_dir, showWarnings = FALSE)

for (url in rec_urls) {
  zf <- file.path(data_dir, basename(url))
  download.file(url, zf, mode = "wb", quiet = FALSE)
  stopifnot("Recall download failed" = file.size(zf) > 1000)
  unzip(zf, exdir = rec_dir)
}
rec_files <- list.files(rec_dir, pattern = "\\.(txt|csv|tsv)$",
                        full.names = TRUE, recursive = TRUE)
cat(sprintf("  Extracted %d recall files\n", length(rec_files)))

# ============================================================
# 4. Download data dictionaries for reference
# ============================================================
cat("Downloading data dictionaries...\n")
dict_dir <- file.path(data_dir, "dictionaries")
dir.create(dict_dir, showWarnings = FALSE)

dict_urls <- c(
  "https://static.nhtsa.gov/odi/ffdd/inv/INV.txt",
  "https://static.nhtsa.gov/odi/ffdd/cmpl/CMPL.txt",
  "https://static.nhtsa.gov/odi/ffdd/rcl/RCL.txt"
)
for (url in dict_urls) {
  download.file(url, file.path(dict_dir, basename(url)), mode = "w", quiet = TRUE)
}

# ============================================================
# 5. Verify downloads
# ============================================================
cat("\n=== Download Summary ===\n")
for (d in c(inv_dir, comp_dir, rec_dir)) {
  files <- list.files(d, recursive = TRUE, full.names = TRUE)
  total_size <- sum(file.size(files))
  cat(sprintf("  %s: %d files, %.1f MB\n", basename(d), length(files), total_size / 1e6))
}

stopifnot("No investigation files found" = length(inv_files) > 0)
stopifnot("No complaint files found" = length(comp_files) > 0)
stopifnot("No recall files found" = length(rec_files) > 0)

cat("\nAll NHTSA data downloaded successfully.\n")
