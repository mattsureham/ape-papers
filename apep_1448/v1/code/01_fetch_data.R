# 01_fetch_data.R — Download CMS Star Ratings data
# apep_1448: Medicare Advantage Quality Bonus RDD

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# Star Ratings & Display Measures (contains continuous summary scores)
# ============================================================================

star_urls <- list(
  "2026" = "https://www.cms.gov/files/zip/2026-star-ratings-data-tables.zip",
  "2025" = "https://www.cms.gov/files/zip/2025-star-ratings-data-tables.zip",
  "2024" = "https://www.cms.gov/files/zip/2024-star-ratings-data-tables-jul-2-2024.zip",
  "2023" = "https://www.cms.gov/files/zip/2023-star-ratings-and-display-measures.zip",
  "2022" = "https://www.cms.gov/files/zip/2022-star-ratings-and-display-measures.zip",
  "2021" = "https://www.cms.gov/files/zip/2021-star-ratings-and-display-measures.zip",
  "2020" = "https://www.cms.gov/files/zip/2020-star-ratings-and-display-measures.zip",
  "2019" = "https://www.cms.gov/files/zip/2019-star-ratings-and-display-measures.zip",
  "2018" = "https://www.cms.gov/medicare/prescription-drug-coverage/prescriptiondrugcovgenin/downloads/2018-star-ratings-and-display-measures.zip",
  "2017" = "https://www.cms.gov/medicare/prescription-drug-coverage/prescriptiondrugcovgenin/downloads/2017_star_ratings_and_display_measures.zip",
  "2016" = "https://www.cms.gov/medicare/prescription-drug-coverage/prescriptiondrugcovgenin/downloads/2016_star_ratings_and_display_measures.zip",
  "2015" = "https://www.cms.gov/medicare/prescription-drug-coverage/prescriptiondrugcovgenin/downloads/2015_star_ratings_and_display_measures.zip"
)

for (yr in names(star_urls)) {
  extract_dir <- file.path(data_dir, paste0("star_", yr))
  if (dir.exists(extract_dir) && length(list.files(extract_dir)) > 0) {
    cat(sprintf("Already extracted: %s\n", extract_dir))
    next
  }

  zip_file <- file.path(data_dir, paste0("star_", yr, ".zip"))
  cat(sprintf("Downloading %s star ratings...\n", yr))

  resp <- tryCatch(
    {
      r <- GET(star_urls[[yr]], timeout(120), write_disk(zip_file, overwrite = TRUE))
      if (status_code(r) != 200) stop("HTTP ", status_code(r))
      r
    },
    error = function(e) {
      cat(sprintf("  FAILED: %s\n", e$message))
      NULL
    }
  )

  if (!is.null(resp)) {
    # Verify it's actually a zip file
    file_type <- system(sprintf("file '%s'", zip_file), intern = TRUE)
    if (!grepl("Zip|zip", file_type)) {
      cat(sprintf("  NOT A ZIP: %s\n", file_type))
      file.remove(zip_file)
      next
    }
    dir.create(extract_dir, showWarnings = FALSE)
    unzip(zip_file, exdir = extract_dir)
    cat(sprintf("  Extracted to: %s (%d files)\n", extract_dir, length(list.files(extract_dir, recursive = TRUE))))
    file.remove(zip_file)
  }
}

# ============================================================================
# Also get the cutpoints file (for reference)
# ============================================================================
cutpoints_url <- "https://www.cms.gov/files/document/updated-2024-star-ratings-cutpoints-and-star-averages.xlsx"
cutpoints_file <- file.path(data_dir, "cutpoints_2024.xlsx")
if (!file.exists(cutpoints_file)) {
  cat("Downloading cutpoints...\n")
  tryCatch(
    {
      r <- GET(cutpoints_url, timeout(60), write_disk(cutpoints_file, overwrite = TRUE))
      if (status_code(r) != 200) stop("HTTP ", status_code(r))
      cat("  Done.\n")
    },
    error = function(e) cat(sprintf("  FAILED: %s\n", e$message))
  )
}

# ============================================================================
# Summary
# ============================================================================
cat("\n=== Data fetch complete ===\n")
cat("Directories:\n")
dirs <- list.dirs(data_dir, recursive = FALSE)
for (d in dirs) {
  n_files <- length(list.files(d, recursive = TRUE))
  cat(sprintf("  %s: %d files\n", basename(d), n_files))
}
