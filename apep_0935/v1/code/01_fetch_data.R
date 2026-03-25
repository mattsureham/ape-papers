## 01_fetch_data.R — Download USSC sentencing data
## APEP-0935: First Step Act Safety Valve and Judge Leniency

source("00_packages.R")

options(timeout = 600)  # 10-minute timeout for large files

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. Download USSC Individual Datafiles (FY2016-FY2023)
# ============================================================
# Focus: 3 pre-FSA years (FY2016-FY2018) + 5 post-FSA (FY2019-FY2023)
cat("=== Downloading USSC Individual Datafiles ===\n")

ussc_years <- 2016:2023
ussc_base <- "https://www.ussc.gov/sites/default/files/zip"

for (yr in ussc_years) {
  yy <- sprintf("%02d", yr %% 100)
  dest_zip <- file.path(data_dir, paste0("ussc_fy", yr, ".zip"))

  if (file.exists(dest_zip) && file.size(dest_zip) > 100000) {
    cat(sprintf("  FY%d: already downloaded (%.1f MB)\n", yr, file.size(dest_zip)/1e6))
    next
  }

  # FY16-17 use hyphen in filename
  if (yr %in% c(2016, 2017)) {
    url <- sprintf("%s/opafy%s-nid.zip", ussc_base, yy)
  } else {
    url <- sprintf("%s/opafy%snid.zip", ussc_base, yy)
  }

  cat(sprintf("  FY%d: downloading from %s...\n", yr, basename(url)))
  tryCatch({
    download.file(url, dest_zip, mode = "wb", quiet = TRUE)
    stopifnot(file.size(dest_zip) > 100000)
    cat(sprintf("  FY%d: SUCCESS (%.1f MB)\n", yr, file.size(dest_zip)/1e6))
  }, error = function(e) {
    if (file.exists(dest_zip)) file.remove(dest_zip)
    stop(sprintf("FATAL: Cannot download USSC FY%d data: %s", yr, e$message))
  })
}

# ============================================================
# 2. Also get FY2024 CSV (smaller, faster)
# ============================================================
cat("\n=== Downloading USSC FY2024 CSV ===\n")
fy24_csv_zip <- file.path(data_dir, "ussc_fy2024_csv.zip")

if (!file.exists(fy24_csv_zip) || file.size(fy24_csv_zip) < 100000) {
  tryCatch({
    download.file(
      "https://www.ussc.gov/sites/default/files/zip/opafy24nid_csv.zip",
      fy24_csv_zip, mode = "wb", quiet = TRUE
    )
    cat(sprintf("  FY2024 CSV: SUCCESS (%.1f MB)\n", file.size(fy24_csv_zip)/1e6))
  }, error = function(e) {
    cat(sprintf("  FY2024 CSV: failed: %s\n", e$message))
  })
} else {
  cat(sprintf("  FY2024 CSV: already downloaded (%.1f MB)\n",
              file.size(fy24_csv_zip)/1e6))
}

# ============================================================
# 3. Extract USSC data
# ============================================================
cat("\n=== Extracting USSC data ===\n")

all_years <- c(ussc_years, 2024)
for (yr in all_years) {
  # Find the zip for this year
  if (yr == 2024) {
    dest_zip <- fy24_csv_zip
  } else {
    dest_zip <- file.path(data_dir, paste0("ussc_fy", yr, ".zip"))
  }

  if (!file.exists(dest_zip)) next

  extract_dir <- file.path(data_dir, paste0("ussc_fy", yr))

  existing_data <- list.files(extract_dir,
                              pattern = "\\.(sas7bdat|csv|sav|dta)$",
                              recursive = TRUE, full.names = TRUE,
                              ignore.case = TRUE)
  if (length(existing_data) > 0) {
    cat(sprintf("  FY%d: already extracted (%d data files)\n", yr, length(existing_data)))
    next
  }

  dir.create(extract_dir, showWarnings = FALSE)
  tryCatch({
    unzip(dest_zip, exdir = extract_dir)
    files <- list.files(extract_dir, recursive = TRUE)
    cat(sprintf("  FY%d: extracted %d files: %s\n", yr, length(files),
                paste(files, collapse = ", ")))
  }, error = function(e) {
    cat(sprintf("  FY%d: extraction error: %s\n", yr, e$message))
  })
}

# ============================================================
# 4. Validate data structure from one file
# ============================================================
cat("\n=== Validating data structure ===\n")

# Find data files
all_data_files <- list.files(data_dir,
                             pattern = "\\.(sas7bdat|csv|sav)$",
                             recursive = TRUE, full.names = TRUE,
                             ignore.case = TRUE)
# Exclude justfair
all_data_files <- all_data_files[!grepl("justfair", all_data_files, ignore.case = TRUE)]

cat(sprintf("  Found %d data files\n", length(all_data_files)))

if (length(all_data_files) == 0) {
  stop("FATAL: No readable USSC data files found after extraction.")
}

# Read the latest available file to check structure
test_file <- tail(all_data_files, 1)
cat(sprintf("  Testing: %s\n", test_file))

if (grepl("\\.sas7bdat$", test_file, ignore.case = TRUE)) {
  test_df <- haven::read_sas(test_file, n_max = 50)
} else if (grepl("\\.csv$", test_file, ignore.case = TRUE)) {
  test_df <- read_csv(test_file, n_max = 50, show_col_types = FALSE)
} else if (grepl("\\.sav$", test_file, ignore.case = TRUE)) {
  test_df <- haven::read_sav(test_file, n_max = 50)
}

cat(sprintf("  Columns: %d, Sample rows: %d\n", ncol(test_df), nrow(test_df)))

# Check key variables (case-insensitive)
names_upper <- toupper(names(test_df))
key_vars <- c("USSCIDN", "TOTPRISN", "NEWRACE", "XCRHISSR",
              "DISTRICT", "MONSEX", "AGE", "CITIZEN",
              "DRUGTYP", "PRIMARY", "STATMIN", "STATMAX")

for (v in key_vars) {
  idx <- which(names_upper == v)
  if (length(idx) > 0) {
    cat(sprintf("  %-12s: found (col %d)\n", v, idx[1]))
  } else {
    partial <- grep(substr(v, 1, 5), names_upper, value = TRUE)
    cat(sprintf("  %-12s: NOT FOUND (similar: %s)\n", v,
                ifelse(length(partial) > 0, paste(partial, collapse = ", "), "none")))
  }
}

# Look for safety valve / mandatory minimum variables
sv_vars <- grep("MAND|SAFE|VALVE|MESSION", names_upper, value = TRUE)
cat(sprintf("\n  Safety valve related vars: %s\n",
            ifelse(length(sv_vars) > 0, paste(sv_vars, collapse = ", "), "none found")))

# Look for sentencing guideline variables
guide_vars <- grep("XFOLSOR|BOOKER|DEPART|RANGE|GUIDEHI|GUIDELO",
                   names_upper, value = TRUE)
cat(sprintf("  Guideline range vars: %s\n",
            ifelse(length(guide_vars) > 0, paste(guide_vars, collapse = ", "), "none")))

cat("\n=== Data fetch complete ===\n")
