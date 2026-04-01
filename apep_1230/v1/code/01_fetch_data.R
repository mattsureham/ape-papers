## 01_fetch_data.R — Fetch CMS hospice data
## Sources:
##   1. Hospice Enrollments CSV (PECOS) — enrollment dates, state, ownership
##   2. Hospice Quality CSV (CMS Provider Data) — HCI, spending, visits near death
##   3. Hospice Owners CSV (PECOS) — for-profit, nonprofit, PE flags
## All CMS public data, no API key needed.

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE)

# ============================================================
# 1. Hospice Enrollments (PECOS)
# ============================================================
cat("Downloading CMS Hospice Enrollments...\n")
enroll_url <- "https://data.cms.gov/sites/default/files/2026-01/adf86a27-5387-44b9-85c6-72e7c4ea5342/Hospice_Enrollments_2026.01.21.csv"
enroll_file <- file.path(data_dir, "hospice_enrollments.csv")
download.file(enroll_url, enroll_file, mode = "wb", quiet = TRUE)
enroll_raw <- fread(enroll_file, encoding = "UTF-8")
cat(sprintf("Hospice enrollments: %d rows\n", nrow(enroll_raw)))
if (nrow(enroll_raw) < 1000) stop("FATAL: Fewer than 1000 enrollments.")
saveRDS(enroll_raw, file.path(data_dir, "hospice_enrollments.rds"))

# ============================================================
# 2. Hospice Quality Measures (CMS Provider Data - CSV)
# ============================================================
cat("Downloading CMS Hospice Quality Measures...\n")
quality_url <- "https://data.cms.gov/provider-data/sites/default/files/resources/3e583faac30f654ddde3559ffd1a4946_1770242744/Hospice_Provider_Feb2026.csv"
quality_file <- file.path(data_dir, "hospice_quality.csv")
download.file(quality_url, quality_file, mode = "wb", quiet = TRUE)
quality_raw <- fread(quality_file, encoding = "UTF-8")
cat(sprintf("Hospice quality: %d rows\n", nrow(quality_raw)))
if (nrow(quality_raw) < 100000) stop("FATAL: Fewer than 100K quality records.")
saveRDS(quality_raw, file.path(data_dir, "hospice_quality.rds"))

# ============================================================
# 3. Hospice Owners (PECOS)
# ============================================================
cat("Downloading CMS Hospice Owners...\n")
owners_url <- "https://data.cms.gov/sites/default/files/2026-01/d69dbba3-86af-41c3-82c5-ddf3dd5acfe0/Hospice_All_Owners_2026.01.02.csv"
owners_file <- file.path(data_dir, "hospice_owners.csv")
download.file(owners_url, owners_file, mode = "wb", quiet = TRUE)
owners_raw <- fread(owners_file, encoding = "UTF-8")
cat(sprintf("Hospice owners: %d rows\n", nrow(owners_raw)))
saveRDS(owners_raw, file.path(data_dir, "hospice_owners.rds"))

cat("\n=== Data fetch complete ===\n")
cat(sprintf("  Enrollments:  %d rows\n", nrow(enroll_raw)))
cat(sprintf("  Quality:      %d rows\n", nrow(quality_raw)))
cat(sprintf("  Owners:       %d rows\n", nrow(owners_raw)))
