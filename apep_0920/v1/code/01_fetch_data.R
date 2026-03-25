# 01_fetch_data.R — Download CMS Geographic Variation PUF (State/County Level)
# apep_0920: MAID Laws and End-of-Life Medicare Spending
#
# Source: CMS Medicare FFS Geographic Variation Public Use File (2014-2023)
# Direct CSV download from data.cms.gov

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

cat("=== Downloading CMS Geographic Variation PUF (2014-2023) ===\n\n")

# Direct CSV download URL from CMS data.json catalog
csv_url <- "https://data.cms.gov/sites/default/files/2025-03/a40ac71d-9f80-4d99-92d2-fd149433d7d8/2014-2023%20Medicare%20Fee-for-Service%20Geographic%20Variation%20Public%20Use%20File.csv"

csv_path <- file.path(data_dir, "cms_gv_puf_2014_2023.csv")

cat("Downloading from CMS...\n")
download.file(csv_url, csv_path, mode = "wb", quiet = FALSE)

if (!file.exists(csv_path) || file.size(csv_path) < 1000) {
  stop("FATAL: Download failed or file is empty. Cannot proceed.")
}

cat("File size:", round(file.size(csv_path) / 1e6, 1), "MB\n")

# Read the CSV
cat("Reading CSV...\n")
raw <- read_csv(csv_path, show_col_types = FALSE)
cat("Rows:", nrow(raw), " Columns:", ncol(raw), "\n")

# Show column names to understand structure
cat("\nColumn names:\n")
cat(paste(names(raw), collapse = "\n"), "\n")

# Show first few rows of key columns
cat("\nGeographic levels present:\n")
if ("BENE_GEO_LVL" %in% names(raw)) {
  print(table(raw$BENE_GEO_LVL))
} else if ("Bene_Geo_Lvl" %in% names(raw)) {
  print(table(raw$Bene_Geo_Lvl))
} else {
  cat("Checking for geographic identifiers...\n")
  geo_cols <- names(raw)[grepl("geo|state|county|level|lvl", names(raw), ignore.case = TRUE)]
  cat("Geographic columns:", paste(geo_cols, collapse = ", "), "\n")
  for (col in geo_cols) {
    cat("\n", col, ":\n")
    print(head(table(raw[[col]]), 20))
  }
}

# Show year range
year_cols <- names(raw)[grepl("year", names(raw), ignore.case = TRUE)]
cat("\nYear columns:", paste(year_cols, collapse = ", "), "\n")
if (length(year_cols) > 0) {
  for (col in year_cols) {
    cat(col, "range:", paste(range(raw[[col]], na.rm = TRUE), collapse = " to "), "\n")
  }
}

# Check for hospice columns
hospice_cols <- names(raw)[grepl("hospc|hospice", names(raw), ignore.case = TRUE)]
cat("\nHospice columns found:", length(hospice_cols), "\n")
cat(paste(hospice_cols, collapse = "\n"), "\n")

# Check for inpatient columns
ip_cols <- names(raw)[grepl("^IP_|inpatient|acute", names(raw), ignore.case = TRUE)]
cat("\nInpatient columns found:", length(ip_cols), "\n")
cat(paste(head(ip_cols, 10), collapse = "\n"), "\n")

# Save as RDS for faster subsequent loading
saveRDS(raw, file.path(data_dir, "cms_gv_puf_raw.rds"))
cat("\nSaved to:", file.path(data_dir, "cms_gv_puf_raw.rds"), "\n")

# --- Validate data quality ---
cat("\n=== Data Validation ===\n")
cat("Total observations:", nrow(raw), "\n")
cat("Total columns:", ncol(raw), "\n")
cat("Hospice spending columns present:", length(hospice_cols) > 0, "\n")

if (length(hospice_cols) == 0) {
  stop("FATAL: No hospice spending columns found in the data. Cannot proceed.")
}

cat("\n=== Data fetch complete ===\n")
