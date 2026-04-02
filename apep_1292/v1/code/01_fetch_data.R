# 01_fetch_data.R — Fetch BIS Locational Banking Statistics
# APEP Paper apep_1292: Sunshine Through the Alps

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. Download BIS LBS bulk CSV
# ============================================================
cat("Downloading BIS Locational Banking Statistics (bulk CSV ~60MB)...\n")

zip_file <- file.path(data_dir, "bis_lbs_d_pub.zip")
bis_url <- "https://www.bis.org/statistics/full_lbs_d_pub_csv.zip"

download_result <- tryCatch({
  download.file(bis_url, zip_file, mode = "wb", quiet = FALSE)
  TRUE
}, error = function(e) {
  cat("Download failed:", conditionMessage(e), "\n")
  FALSE
})

if (!download_result || !file.exists(zip_file) || file.size(zip_file) < 1000) {
  stop("FATAL: Cannot download BIS LBS data. Cannot proceed.")
}

cat("  Download complete. Size:", round(file.size(zip_file) / 1e6, 1), "MB\n")

# Extract CSV from zip
csv_files <- unzip(zip_file, list = TRUE)$Name
cat("  Files in zip:", paste(csv_files, collapse = ", "), "\n")

unzip(zip_file, exdir = data_dir)
csv_path <- file.path(data_dir, csv_files[1])

if (!file.exists(csv_path)) {
  stop("FATAL: Extracted CSV not found at ", csv_path)
}

cat("  Extracted:", csv_path, "\n")
cat("  Size:", round(file.size(csv_path) / 1e6, 1), "MB\n")

# ============================================================
# 2. Read and filter for Liechtenstein counterparty
# ============================================================
cat("Reading BIS LBS data (this may take a moment)...\n")

# Read full dataset
bis_raw <- fread(csv_path, showProgress = FALSE)
cat("  Total rows:", format(nrow(bis_raw), big.mark = ","), "\n")
cat("  Columns:", paste(names(bis_raw), collapse = ", "), "\n")

# Inspect counterparty country column
# BIS LBS uses "Counterparty country" or similar
cat("\nFirst 3 rows:\n")
print(head(bis_raw, 3))

# Find the counterparty country column
cp_col <- grep("counterparty.*country|cp.*country|L_CP_COUNTRY",
               names(bis_raw), ignore.case = TRUE, value = TRUE)
cat("Counterparty country column(s):", paste(cp_col, collapse = ", "), "\n")

# Find reporter country column
rep_col <- grep("^L_COUNTRY$|reporting.*country|rep.*country",
                names(bis_raw), ignore.case = TRUE, value = TRUE)
cat("Reporter country column(s):", paste(rep_col, collapse = ", "), "\n")

# Save column names for debugging
writeLines(names(bis_raw), file.path(data_dir, "bis_columns.txt"))

# Filter for Liechtenstein as counterparty
# LI is the ISO code for Liechtenstein
if (length(cp_col) > 0) {
  bis_li <- bis_raw[get(cp_col[1]) == "LI"]
} else {
  # Try looking at unique values in columns that might contain "LI"
  cat("No obvious counterparty column. Checking all columns for 'LI' values...\n")
  for (col in names(bis_raw)) {
    if (is.character(bis_raw[[col]])) {
      li_count <- sum(bis_raw[[col]] == "LI", na.rm = TRUE)
      if (li_count > 0) {
        cat("  Column", col, "has", li_count, "rows with 'LI'\n")
      }
    }
  }
  stop("FATAL: Cannot identify counterparty country column in BIS data.")
}

cat("\nLiechtenstein rows:", format(nrow(bis_li), big.mark = ","), "\n")

if (nrow(bis_li) == 0) {
  stop("FATAL: No Liechtenstein data found in BIS LBS. Cannot proceed.")
}

# Save filtered data
fwrite(bis_li, file.path(data_dir, "bis_lbs_li.csv"))
cat("Filtered Liechtenstein data saved.\n")

# ============================================================
# 3. Construct AEOI treatment dates
# ============================================================
cat("\nConstructing AEOI treatment dates...\n")

# Liechtenstein AEOI activation dates
# Sources: OECD CRS Implementation Status, Liechtenstein Tax Office (Steuerverwaltung)
# EU/EEA Directive 2014/107/EU: first exchange September 2017
# CRS Early Adopters: first exchange September 2017
# CRS Second Wave: first exchange September 2018
# Later commitments: 2019-2020

aeoi_dates <- tribble(
  ~country_code, ~country_name,       ~aeoi_quarter, ~aeoi_group,
  # EU/EEA — first exchange Sep 2017
  "AT", "Austria",                "2017-Q3", "EU_2017",
  "BE", "Belgium",               "2017-Q3", "EU_2017",
  "DK", "Denmark",               "2017-Q3", "EU_2017",
  "FI", "Finland",               "2017-Q3", "EU_2017",
  "FR", "France",                "2017-Q3", "EU_2017",
  "DE", "Germany",               "2017-Q3", "EU_2017",
  "IE", "Ireland",               "2017-Q3", "EU_2017",
  "IT", "Italy",                 "2017-Q3", "EU_2017",
  "LU", "Luxembourg",            "2017-Q3", "EU_2017",
  "NL", "Netherlands",           "2017-Q3", "EU_2017",
  "ES", "Spain",                 "2017-Q3", "EU_2017",
  "SE", "Sweden",                "2017-Q3", "EU_2017",
  # CRS Early Adopters — first exchange Sep 2017
  "GB", "United Kingdom",        "2017-Q3", "CRS_2017",
  "GG", "Guernsey",              "2017-Q3", "CRS_2017",
  "IM", "Isle of Man",           "2017-Q3", "CRS_2017",
  "JE", "Jersey",                "2017-Q3", "CRS_2017",
  "ZA", "South Africa",          "2017-Q3", "CRS_2017",
  # CRS Second Wave — first exchange Sep 2018
  "AU", "Australia",             "2018-Q3", "CRS_2018",
  "BR", "Brazil",                "2018-Q3", "CRS_2018",
  "CA", "Canada",                "2018-Q3", "CRS_2018",
  "HK", "Hong Kong SAR",         "2018-Q3", "CRS_2018",
  "JP", "Japan",                 "2018-Q3", "CRS_2018",
  "KR", "Korea",                 "2018-Q3", "CRS_2018",
  "MO", "Macao SAR",             "2018-Q3", "CRS_2018",
  "MX", "Mexico",                "2018-Q3", "CRS_2018",
  # Later waves
  "CL", "Chile",                 "2020-Q3", "CRS_2020",
  "PH", "Philippines",           "2020-Q3", "CRS_2020",
  "TW", "Chinese Taipei",        "2020-Q3", "CRS_2020"
)

cat("AEOI treatment dates for", nrow(aeoi_dates), "BIS-reporting countries:\n")
print(table(aeoi_dates$aeoi_group))

fwrite(aeoi_dates, file.path(data_dir, "aeoi_treatment_dates.csv"))
cat("Treatment dates saved.\n")

# Clean up large files
file.remove(zip_file)
file.remove(csv_path)
cat("Cleaned up bulk download files.\n")

cat("\n=== Data fetch complete ===\n")
