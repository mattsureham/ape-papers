# ============================================================
# 01_fetch_data.R — Fetch QWI and SNAP retailer data
# apep_0757: The Racial Anatomy of Food Desert Formation
# ============================================================

source("00_packages.R")
source("../../../../scripts/lib/azure_data.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ----------------------------------------------------------
# 1. QWI NAICS 445 by Race from Azure
# ----------------------------------------------------------
cat("=== Fetching QWI NAICS 445 by race from Azure ===\n")

con <- apep_azure_connect()

# Query QWI race×ethnicity data for NAICS 445 (Food & Beverage Stores)
# The rh/n3 files have 3-digit NAICS with race breakdown
qwi_query <- "
  SELECT *
  FROM 'az://derived/qwi/rh/n3/*.parquet'
  WHERE industry = '445'
    AND year >= 2005
"

cat("  Running Azure query (this may take a moment)...\n")
qwi_raw <- dbGetQuery(con, qwi_query)
qwi <- as.data.table(qwi_raw)

cat("  QWI rows:", format(nrow(qwi), big.mark = ","), "\n")
cat("  Columns:", paste(names(qwi), collapse = ", "), "\n")
cat("  Year range:", min(qwi$year, na.rm = TRUE), "-", max(qwi$year, na.rm = TRUE), "\n")

# Check race/ethnicity column
race_col <- names(qwi)[grepl("race|ethnicity|rh", names(qwi), ignore.case = TRUE)]
cat("  Race columns:", paste(race_col, collapse = ", "), "\n")

if (length(race_col) > 0) {
  cat("  Race values:\n")
  print(table(qwi[[race_col[1]]]))
}

# Save QWI data
saveRDS(qwi, file.path(data_dir, "qwi_445_race.rds"))
cat("  Saved qwi_445_race.rds\n")

apep_azure_disconnect(con)

# ----------------------------------------------------------
# 2. SNAP Retailer Historical Database
# ----------------------------------------------------------
cat("\n=== Loading SNAP Retailer Data ===\n")

# Reuse from apep_0753 if available
snap_path_0753 <- "../../apep_0753/v1/data/snap_retailers_raw.csv"
snap_path_local <- file.path(data_dir, "snap_retailers_raw.csv")

if (file.exists(snap_path_0753) && !file.exists(snap_path_local)) {
  cat("  Copying from apep_0753...\n")
  file.copy(snap_path_0753, snap_path_local)
} else if (!file.exists(snap_path_local)) {
  cat("  Downloading SNAP Retailer Historical Database...\n")
  retailer_url <- "https://www.fns.usda.gov/sites/default/files/resource-files/snap-retailer-locator-data2005-2025.zip"
  zip_path <- file.path(data_dir, "snap_retailers.zip")
  resp <- httr::GET(retailer_url, httr::write_disk(zip_path, overwrite = TRUE),
                    httr::timeout(300))
  stopifnot("SNAP download failed" = httr::status_code(resp) == 200)
  csv_files <- unzip(zip_path, exdir = data_dir)
  main_csv <- csv_files[grepl("\\.csv$", csv_files, ignore.case = TRUE)][1]
  file.rename(main_csv, snap_path_local)
  unlink(zip_path)
}

retailers <- fread(snap_path_local, showProgress = FALSE)
cat("  SNAP retailers:", format(nrow(retailers), big.mark = ","), "\n")

# ----------------------------------------------------------
# 3. Validate
# ----------------------------------------------------------
cat("\n=== Data Validation ===\n")
stopifnot("QWI data must have rows" = nrow(qwi) > 1000)
stopifnot("SNAP data must have rows" = nrow(retailers) > 100000)
cat("  Both datasets validated.\n")
