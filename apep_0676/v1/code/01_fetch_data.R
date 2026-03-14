## 01_fetch_data.R — Fetch Charity Commission register data
## apep_0676: UK Charity Bunching at Audit Thresholds

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ============================================================
## 1. Charity Commission for England & Wales — Bulk Data
## ============================================================

# Charity Commission publishes data at Azure blob storage as ZIP files
cc_base_url <- "https://ccewuksprdoneregsadata1.blob.core.windows.net/data/txt"

files_needed <- c(
  "publicextract.charity_annual_return_history",
  "publicextract.charity",
  "publicextract.charity_classification"
)

for (fname in files_needed) {
  zip_path <- file.path(data_dir, paste0(fname, ".zip"))
  # Extract the short name for the CSV/TXT file inside
  short_name <- sub("publicextract\\.", "", fname)

  if (!file.exists(zip_path)) {
    url <- paste0(cc_base_url, "/", fname, ".zip")
    cat("Downloading:", fname, "...\n")
    resp <- download.file(url, zip_path, mode = "wb", quiet = FALSE, timeout = 600)
    if (resp != 0) {
      stop(paste("FATAL: Failed to download", fname, "from", url))
    }
    cat("  Downloaded:", format(file.size(zip_path), big.mark = ","), "bytes\n")
  } else {
    cat("Already exists:", fname, "\n")
  }

  # Unzip
  csv_candidates <- unzip(zip_path, list = TRUE)$Name
  cat("  ZIP contains:", paste(csv_candidates, collapse = ", "), "\n")
  unzip(zip_path, exdir = data_dir, overwrite = TRUE)
}

## ============================================================
## 2. Load and validate
## ============================================================

# Find the annual return history file
arr_files <- list.files(data_dir, pattern = "annual_return_history", full.names = TRUE,
                        ignore.case = TRUE)
arr_files <- arr_files[!grepl("\\.zip$", arr_files)]
stopifnot("FATAL: No annual return history file found" = length(arr_files) > 0)

cat("\nLoading annual return history from:", arr_files[1], "\n")
arr <- fread(arr_files[1], header = TRUE, encoding = "UTF-8")
cat("  Rows:", format(nrow(arr), big.mark = ","), "\n")
cat("  Columns:", paste(names(arr), collapse = ", "), "\n")

# Find charity file
char_files <- list.files(data_dir, pattern = "^publicextract\\.charity\\.", full.names = TRUE,
                         ignore.case = TRUE)
char_files <- char_files[!grepl("(classification|annual|zip)", char_files, ignore.case = TRUE)]
stopifnot("FATAL: No charity file found" = length(char_files) > 0)

cat("\nLoading charity register from:", char_files[1], "\n")
charity <- fread(char_files[1], header = TRUE, encoding = "UTF-8")
cat("  Rows:", format(nrow(charity), big.mark = ","), "\n")
cat("  Columns:", paste(names(charity), collapse = ", "), "\n")

# Find classification file
class_files <- list.files(data_dir, pattern = "classification", full.names = TRUE,
                          ignore.case = TRUE)
class_files <- class_files[!grepl("\\.zip$", class_files)]
stopifnot("FATAL: No classification file found" = length(class_files) > 0)

cat("\nLoading classifications from:", class_files[1], "\n")
classif <- fread(class_files[1], header = TRUE, encoding = "UTF-8")
cat("  Rows:", format(nrow(classif), big.mark = ","), "\n")

## ============================================================
## 3. OSCR (Scotland) — for placebo test
## ============================================================

# OSCR provides download but requires form submission
# Try direct download first
oscr_path <- file.path(data_dir, "oscr_register.csv")

if (!file.exists(oscr_path)) {
  cat("\nAttempting OSCR download...\n")
  # OSCR provides a form-based download; try the direct endpoint
  oscr_url <- "https://www.oscr.org.uk/umbraco/Surface/FormsSurface/CharityRegDownload"
  tryCatch({
    resp <- httr::POST(oscr_url,
                       body = list(
                         BothCharity = "true",
                         RegStatus = "0"
                       ),
                       httr::write_disk(oscr_path, overwrite = TRUE),
                       httr::timeout(120),
                       httr::add_headers(`User-Agent` = "Mozilla/5.0 (Academic Research)"))
    if (httr::status_code(resp) == 200 && file.size(oscr_path) > 5000) {
      cat("  Downloaded OSCR:", format(file.size(oscr_path), big.mark = ","), "bytes\n")
    } else {
      cat("  OSCR download returned HTTP", httr::status_code(resp),
          "or file too small. Placebo will be skipped.\n")
      if (file.exists(oscr_path)) file.remove(oscr_path)
    }
  }, error = function(e) {
    cat("  OSCR download failed:", e$message, "\n")
    cat("  Scotland placebo will be conducted with publicly available summary data.\n")
    if (file.exists(oscr_path)) file.remove(oscr_path)
  })
}

oscr <- NULL
if (file.exists(oscr_path) && file.size(oscr_path) > 5000) {
  oscr <- tryCatch(
    fread(oscr_path, header = TRUE, encoding = "UTF-8"),
    error = function(e) {
      cat("  Could not parse OSCR file:", e$message, "\n")
      NULL
    }
  )
  if (!is.null(oscr)) {
    cat("OSCR rows:", format(nrow(oscr), big.mark = ","), "\n")
    cat("OSCR columns:", paste(names(oscr), collapse = ", "), "\n")
  }
}

## ============================================================
## 4. Save raw data objects
## ============================================================

save(arr, charity, classif, file = file.path(data_dir, "raw_data.RData"))
if (!is.null(oscr)) {
  save(oscr, file = file.path(data_dir, "oscr_raw.RData"))
}

cat("\n=== Data fetch complete ===\n")
cat("Annual returns:", format(nrow(arr), big.mark = ","), "rows\n")
cat("Charities:", format(nrow(charity), big.mark = ","), "rows\n")
cat("Classifications:", format(nrow(classif), big.mark = ","), "rows\n")
if (!is.null(oscr)) cat("OSCR:", format(nrow(oscr), big.mark = ","), "rows\n")
