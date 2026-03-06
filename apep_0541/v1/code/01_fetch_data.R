###############################################################################
# 01_fetch_data.R — Fetch FDA Orange Book and CMS NADAC data
# APEP-0541: How Many Generics Does It Take?
###############################################################################

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ==========================================================================
# 1. FDA Orange Book (products, patents, exclusivity)
# ==========================================================================

cat("=== Downloading FDA Orange Book ===\n")
ob_url <- "https://www.fda.gov/media/76860/download"
ob_zip <- file.path(data_dir, "orangebook.zip")
ob_dir <- file.path(data_dir, "orangebook")

tryCatch({
  download.file(ob_url, ob_zip, mode = "wb", quiet = TRUE)
}, error = function(e) stop("Orange Book download failed: ", e$message,
                            "\nCannot proceed without treatment data."))

dir.create(ob_dir, showWarnings = FALSE)
unzip(ob_zip, exdir = ob_dir, overwrite = TRUE)

# Parse products
products_file <- file.path(ob_dir, "products.txt")
stopifnot("Orange Book products.txt not found" = file.exists(products_file))
products <- fread(products_file, sep = "~", header = TRUE, fill = TRUE,
                  quote = "")

cat("Orange Book products loaded:", nrow(products), "rows\n")
cat("  ANDA (generic) applications:", sum(products$Appl_Type == "A"), "\n")
cat("  NDA (brand) applications:", sum(products$Appl_Type == "N"), "\n")

# Parse patents
patents_file <- file.path(ob_dir, "patent.txt")
if (file.exists(patents_file)) {
  patents <- fread(patents_file, sep = "~", header = TRUE, fill = TRUE,
                   quote = "")
  cat("Patents loaded:", nrow(patents), "rows\n")
  fwrite(patents, file.path(data_dir, "ob_patents.csv"))
}

# Parse exclusivity
excl_file <- file.path(ob_dir, "exclusivity.txt")
if (file.exists(excl_file)) {
  exclusivity <- fread(excl_file, sep = "~", header = TRUE, fill = TRUE,
                       quote = "")
  cat("Exclusivity entries loaded:", nrow(exclusivity), "rows\n")
  fwrite(exclusivity, file.path(data_dir, "ob_exclusivity.csv"))
}

# Save products
fwrite(products, file.path(data_dir, "ob_products.csv"))

# ==========================================================================
# 2. CMS NADAC (National Average Drug Acquisition Cost)
# ==========================================================================

cat("\n=== Downloading CMS NADAC data ===\n")

# NADAC is available through Medicaid.gov data downloads
# Use the Socrata API endpoint for comprehensive access
nadac_base <- "https://data.medicaid.gov/api/1/datastore/query/"
nadac_resource <- "a]4y5-998d"  # NADAC dataset identifier

# Try the bulk CSV download approach (more reliable for large datasets)
# NADAC weekly files from data.medicaid.gov
# We'll fetch the comprehensive NADAC file via the API

cat("Fetching NADAC via Medicaid.gov API...\n")

# The NADAC data is large — fetch in batches via Socrata-compatible API
# Alternative: direct CSV download from data.medicaid.gov
nadac_url <- "https://data.medicaid.gov/api/1/datastore/query/a4y5-998d/0"

# First, test the API
test_resp <- tryCatch({
  httr::GET(
    nadac_url,
    query = list(limit = 5, offset = 0),
    httr::timeout(60)
  )
}, error = function(e) {
  cat("Primary NADAC API failed:", e$message, "\n")
  NULL
})

if (is.null(test_resp) || httr::status_code(test_resp) != 200) {
  # Fallback: try the direct NADAC download from CMS
  cat("Trying alternative NADAC source...\n")

  # CMS Provider Data API
  nadac_alt_url <- "https://download.medicaid.gov/data/nadac-national-average-drug-acquisition-cost-12-25-2024.csv"
  nadac_csv <- file.path(data_dir, "nadac_2024.csv")

  tryCatch({
    download.file(nadac_alt_url, nadac_csv, mode = "wb", quiet = FALSE)
  }, error = function(e) {
    # Try without date suffix
    nadac_alt_url2 <- "https://data.medicaid.gov/dataset/dfa2ab14-06c2-457a-9e36-5cb6d80f8d93/data?conditions[0][resource]=t&conditions[0][property]=as_of_date&conditions[0][value]=2024-01-03&conditions[0][operator]=%3E%3D"
    tryCatch({
      download.file(nadac_alt_url2, nadac_csv, mode = "wb", quiet = FALSE)
    }, error = function(e2) {
      stop("All NADAC download attempts failed: ", e2$message,
           "\nPivot research question or fix the source.")
    })
  })

  if (file.exists(nadac_csv) && file.size(nadac_csv) > 1000) {
    nadac <- fread(nadac_csv)
    cat("NADAC loaded from CSV:", nrow(nadac), "rows\n")
  } else {
    stop("NADAC CSV download produced empty or tiny file. Cannot proceed.")
  }
} else {
  # API works — fetch in batches
  cat("NADAC API accessible. Fetching data in batches...\n")

  batch_size <- 10000
  all_batches <- list()
  offset <- 0
  max_records <- 2000000  # Safety cap

  repeat {
    resp <- httr::GET(
      nadac_url,
      query = list(limit = batch_size, offset = offset),
      httr::timeout(120)
    )

    if (httr::status_code(resp) != 200) {
      cat("Batch fetch stopped at offset", offset, "- status:",
          httr::status_code(resp), "\n")
      break
    }

    batch_json <- httr::content(resp, as = "text", encoding = "UTF-8")
    batch_data <- jsonlite::fromJSON(batch_json)

    if (is.null(batch_data$results) || length(batch_data$results) == 0 ||
        nrow(batch_data$results) == 0) {
      cat("No more records at offset", offset, "\n")
      break
    }

    all_batches[[length(all_batches) + 1]] <- as.data.table(batch_data$results)
    n_fetched <- nrow(batch_data$results)
    offset <- offset + n_fetched

    if (offset %% 100000 == 0) cat("  Fetched", offset, "records...\n")

    if (n_fetched < batch_size || offset >= max_records) break
  }

  if (length(all_batches) == 0) {
    stop("NADAC API returned no data. Cannot proceed.")
  }

  nadac <- rbindlist(all_batches, fill = TRUE)
  cat("NADAC loaded via API:", nrow(nadac), "rows\n")
}

fwrite(nadac, file.path(data_dir, "nadac_raw.csv"))

# ==========================================================================
# 3. FDA Drug Shortages (for robustness)
# ==========================================================================

cat("\n=== Fetching FDA Drug Shortages ===\n")

shortage_url <- "https://api.fda.gov/drug/shortages.json?limit=1000"
shortage_resp <- tryCatch({
  httr::GET(shortage_url, httr::timeout(60))
}, error = function(e) {
  cat("FDA shortage API unavailable:", e$message, "\n")
  cat("Will proceed without shortage controls.\n")
  NULL
})

if (!is.null(shortage_resp) && httr::status_code(shortage_resp) == 200) {
  shortage_json <- httr::content(shortage_resp, as = "text", encoding = "UTF-8")
  shortage_data <- jsonlite::fromJSON(shortage_json, flatten = TRUE)
  if (!is.null(shortage_data$results)) {
    shortages <- as.data.table(shortage_data$results)
    # Keep only atomic columns (drop nested list columns)
    atomic_cols <- names(shortages)[sapply(shortages, function(x) is.atomic(x))]
    shortages_flat <- shortages[, ..atomic_cols]
    fwrite(shortages_flat, file.path(data_dir, "fda_shortages.csv"))
    cat("FDA shortages loaded:", nrow(shortages_flat), "entries\n")
  }
} else {
  cat("Shortage data unavailable — skipping (not used in main analysis).\n")
}

# ==========================================================================
# 4. DATA VALIDATION (required)
# ==========================================================================

cat("\n=== Data Validation ===\n")

# Validate Orange Book
anda_products <- products[Appl_Type == "A"]
stopifnot("Expected 30,000+ ANDA products" = nrow(anda_products) >= 30000)
stopifnot("Approval_Date field must exist" = "Approval_Date" %in% names(products))
cat("Orange Book validation passed:", nrow(anda_products), "ANDAs\n")

# Validate NADAC
stopifnot("Expected 100,000+ NADAC records" = nrow(nadac) >= 100000)
cat("NADAC validation passed:", nrow(nadac), "records\n")

# Summary
cat("\n=== Fetch Summary ===\n")
cat("Orange Book ANDAs:", nrow(anda_products), "\n")
cat("NADAC records:", nrow(nadac), "\n")
cat("All data saved to:", normalizePath(data_dir), "\n")
