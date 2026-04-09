# 01_fetch_data.R — Fetch CQC ratings data via bulk ODS downloads
source("00_packages.R")

# === 1. Download CQC bulk ratings (multiple snapshots for panel) ===
cat("Downloading CQC bulk ratings snapshots...\n")

# CQC publishes monthly ODS files with all ratings
# We download multiple snapshots to build a panel
snapshots <- c(
  "2026-03" = "https://www.cqc.org.uk/sites/default/files/2026-03/01_March_2026_Latest_ratings.ods",
  "2025-10" = "https://www.cqc.org.uk/sites/default/files/2025-10/01_October_2025_Latest_ratings.ods",
  "2025-04" = "https://www.cqc.org.uk/sites/default/files/2025-04/01_April_2025_Latest_ratings.ods",
  "2024-10" = "https://www.cqc.org.uk/sites/default/files/2024-10/01_October_2024_Latest_ratings.ods",
  "2024-04" = "https://www.cqc.org.uk/sites/default/files/2024-04/01_April_2024_Latest_ratings.ods",
  "2023-10" = "https://www.cqc.org.uk/sites/default/files/2023-10/01_October_2023_Latest_ratings.ods",
  "2023-04" = "https://www.cqc.org.uk/sites/default/files/2023-04/01_April_2023_Latest_ratings.ods",
  "2022-10" = "https://www.cqc.org.uk/sites/default/files/2022-10/01_October_2022_Latest_ratings.ods",
  "2022-04" = "https://www.cqc.org.uk/sites/default/files/2022-04/01_April_2022_Latest_ratings.ods"
)

# Download the latest snapshot (most complete — contains historical ratings)
latest_file <- "../data/cqc_latest_ratings.ods"
cat("Downloading March 2026 snapshot...\n")
resp <- httr::GET(snapshots[["2026-03"]], httr::write_disk(latest_file, overwrite = TRUE), httr::timeout(120))
stopifnot(httr::status_code(resp) == 200)
cat(sprintf("Downloaded: %s (%.1f MB)\n", latest_file, file.info(latest_file)$size / 1e6))

# === 2. Read the ODS file ===
cat("Reading ODS file (this may take a moment)...\n")
sheets <- readODS::list_ods_sheets(latest_file)
cat(sprintf("Available sheets: %s\n", paste(sheets, collapse = ", ")))

# The CQC file typically has sheets: Locations, Providers, HSCA ratings
# Read the main ratings sheet
ratings_raw <- as.data.table(readODS::read_ods(latest_file, sheet = "Locations"))
cat(sprintf("Read %d rows from sheet '%s'\n", nrow(ratings_raw), sheets[1]))
cat(sprintf("Columns: %s\n", paste(names(ratings_raw), collapse = ", ")))

# Save raw for inspection
fwrite(ratings_raw, "../data/cqc_ratings_raw.csv")
cat("Saved raw ratings to data/cqc_ratings_raw.csv\n")

# === 3. Download additional snapshots for panel construction ===
# Try to get 2-3 more snapshots to track status changes over time
for (snap_name in c("2024-10", "2023-10", "2022-10")) {
  snap_file <- sprintf("../data/cqc_ratings_%s.ods", gsub("-", "_", snap_name))
  cat(sprintf("Downloading %s snapshot...\n", snap_name))
  resp <- httr::GET(snapshots[[snap_name]], httr::write_disk(snap_file, overwrite = TRUE), httr::timeout(120))
  if (httr::status_code(resp) == 200) {
    cat(sprintf("  Downloaded: %.1f MB\n", file.info(snap_file)$size / 1e6))
  } else {
    warning(sprintf("  Failed to download %s (HTTP %d)\n", snap_name, httr::status_code(resp)))
  }
}

# === 4. Basic validation ===
cat("\n=== Data Validation ===\n")
cat(sprintf("Total rows: %d\n", nrow(ratings_raw)))
cat(sprintf("Column names:\n"))
print(names(ratings_raw))
cat("\nFirst 5 rows:\n")
print(head(ratings_raw, 5))
