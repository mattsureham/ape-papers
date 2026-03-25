# 01_fetch_data.R — Fetch Home Office Crime Outcomes Data
# PCC Electoral Cycles and Crime Investigation Quality (apep_0909)
#
# Data sources:
# 1. Home Office "Crime Outcomes" open data tables (ODS) — 2005/06 to 2013/14
# 2. Home Office "PRC Outcomes" open data tables (ODS) — 2015 to 2018
# 3. Police UK API — 2023 to 2026 (force-level with outcomes)
# 4. Home Office crime outcomes PFA-level tabs (ODS)

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# 1. Download Home Office outcomes open data ODS files
# ============================================================================
cat("=== Downloading Home Office outcomes open data ===\n")

# Key ODS files from data.gov.uk (Crime Outcomes package + PFA dataset)
ods_files <- list(
  # Historical outcomes 2005/06-2013/14 (Crime Outcomes package, resource 10)
  list(
    url = "https://www.gov.uk/government/uploads/system/uploads/attachment_data/file/445648/prc-outcomes-open-data-0506-to-1314.ods",
    name = "outcomes_0506_1314.ods",
    desc = "Outcomes open data 2005/06 to 2013/14"
  ),
  # PFA-level outcomes tabs (Crime Outcomes 2013/14 bulletin)
  list(
    url = "https://www.gov.uk/government/uploads/system/uploads/attachment_data/file/330496/hosb0114-pfatabs.ods",
    name = "outcomes_pfa_1314.ods",
    desc = "PFA outcomes tabs 2013/14"
  ),
  # PFA-level outcomes tabs (Crime Outcomes 2014/15 bulletin)
  list(
    url = "https://www.gov.uk/government/uploads/system/uploads/attachment_data/file/445544/hosb0115-pfa-tabs.ods",
    name = "outcomes_pfa_1415.ods",
    desc = "PFA outcomes tabs 2014/15"
  ),
  # Outcomes open data to March 2015 (PFA dataset)
  list(
    url = "https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/584462/prc-outcomes-open-data-march15-tabs.ods",
    name = "outcomes_open_mar2015.ods",
    desc = "Outcomes open data to March 2015"
  ),
  # Outcomes open data to March 2016
  list(
    url = "https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/726526/prc-outcomes-open-data-mar2016-tables.ods",
    name = "outcomes_open_mar2016.ods",
    desc = "Outcomes open data to March 2016"
  ),
  # Outcomes open data to March 2017
  list(
    url = "https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/749315/prc-outcomes-open-data-mar2017-tables.ods",
    name = "outcomes_open_mar2017.ods",
    desc = "Outcomes open data to March 2017"
  ),
  # Outcomes open data to March 2018
  list(
    url = "https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/749314/prc-outcomes-open-data-mar2018-tables-e.ods",
    name = "outcomes_open_mar2018.ods",
    desc = "Outcomes open data to March 2018"
  ),
  # Outcomes open data April-June 2018
  list(
    url = "https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/749313/prc-outcomes-open-data-aprjun2018-tables.ods",
    name = "outcomes_open_aprjun2018.ods",
    desc = "Outcomes open data Apr-Jun 2018"
  ),
  # Crime outcomes tabs (general)
  list(
    url = "https://www.gov.uk/government/uploads/system/uploads/attachment_data/file/330000/prc-crime-outcomes-tabs.ods",
    name = "prc_crime_outcomes_tabs.ods",
    desc = "PRC crime outcomes tabs"
  ),
  # Q2 2015/16 tabs
  list(
    url = "https://www.gov.uk/government/uploads/system/uploads/attachment_data/file/493535/outcomes-q2-1516-tabs.ods",
    name = "outcomes_q2_1516.ods",
    desc = "Crime Outcomes Q2 2015/16"
  ),
  # General crime outcomes data tabs 2013/14
  list(
    url = "https://www.gov.uk/government/uploads/system/uploads/attachment_data/file/330493/hosb0114-tabs.ods",
    name = "outcomes_tabs_1314.ods",
    desc = "Crime Outcomes data tabs 2013/14"
  )
)

for (item in ods_files) {
  fpath <- file.path(data_dir, item$name)
  if (file.exists(fpath) && file.size(fpath) > 1000) {
    cat(sprintf("  Already downloaded: %s\n", item$name))
    next
  }
  cat(sprintf("  Downloading: %s (%s)...\n", item$name, item$desc))
  tryCatch({
    resp <- httr::GET(item$url, httr::timeout(120),
                      httr::write_disk(fpath, overwrite = TRUE))
    if (httr::status_code(resp) == 200 && file.size(fpath) > 1000) {
      cat(sprintf("    OK: %.1f KB\n", file.size(fpath) / 1024))
    } else {
      cat(sprintf("    FAILED: HTTP %d, size %d\n",
                  httr::status_code(resp), file.size(fpath)))
      if (file.exists(fpath)) file.remove(fpath)
    }
  }, error = function(e) {
    cat(sprintf("    ERROR: %s\n", e$message))
  })
  Sys.sleep(1)
}

# ============================================================================
# 2. Inspect all downloaded ODS files
# ============================================================================
cat("\n=== Inspecting downloaded ODS files ===\n")

ods_downloaded <- list.files(data_dir, pattern = "\\.ods$", full.names = TRUE)
cat(sprintf("Successfully downloaded: %d ODS files\n", length(ods_downloaded)))

for (fpath in ods_downloaded) {
  cat(sprintf("\n--- %s (%.0f KB) ---\n", basename(fpath), file.size(fpath) / 1024))
  tryCatch({
    sheets <- readODS::list_ods_sheets(fpath)
    cat(sprintf("  Sheets (%d): %s\n", length(sheets),
                paste(sheets, collapse = ", ")))

    # Read first data sheet to understand structure
    for (s in sheets) {
      if (grepl("intro|note|content", tolower(s))) next
      tryCatch({
        sample <- readODS::read_ods(fpath, sheet = s, n_max = 8)
        cat(sprintf("  Sheet '%s': %d cols, cols: %s\n",
                    s, ncol(sample),
                    paste(head(names(sample), 8), collapse = " | ")))
        # Print first 3 rows
        for (r in 1:min(3, nrow(sample))) {
          vals <- sapply(sample[r, 1:min(6, ncol(sample))], as.character)
          cat(sprintf("    Row %d: %s\n", r, paste(vals, collapse = " | ")))
        }
        break  # Only show first data sheet per file
      }, error = function(e) NULL)
    }
  }, error = function(e) {
    cat(sprintf("  Error: %s\n", e$message))
  })
}

# ============================================================================
# 3. Parse the main outcomes open data file (2005/06 - 2013/14)
# ============================================================================
cat("\n=== Parsing historical outcomes data (2005/06 - 2013/14) ===\n")

historical_file <- file.path(data_dir, "outcomes_0506_1314.ods")
if (file.exists(historical_file)) {
  sheets <- readODS::list_ods_sheets(historical_file)
  cat(sprintf("Sheets: %s\n", paste(sheets, collapse = ", ")))

  # Read each data sheet
  for (s in sheets) {
    if (grepl("intro|note|content|lookup", tolower(s))) next
    cat(sprintf("\nReading sheet: %s\n", s))
    tryCatch({
      dt <- readODS::read_ods(historical_file, sheet = s)
      cat(sprintf("  Rows: %d, Cols: %d\n", nrow(dt), ncol(dt)))
      cat(sprintf("  Columns: %s\n", paste(names(dt), collapse = " | ")))
      if (nrow(dt) > 0) {
        print(head(dt, 5))
      }
    }, error = function(e) cat(sprintf("  Error: %s\n", e$message)))
  }
} else {
  cat("  Historical file not found!\n")
}

# ============================================================================
# 4. Parse the PFA outcomes tabs (2013/14 and 2014/15)
# ============================================================================
cat("\n=== Parsing PFA outcomes tabs ===\n")

pfa_files <- c(
  file.path(data_dir, "outcomes_pfa_1314.ods"),
  file.path(data_dir, "outcomes_pfa_1415.ods")
)

for (pfa_file in pfa_files) {
  if (!file.exists(pfa_file)) {
    cat(sprintf("  File not found: %s\n", basename(pfa_file)))
    next
  }
  cat(sprintf("\n--- %s ---\n", basename(pfa_file)))
  sheets <- readODS::list_ods_sheets(pfa_file)
  cat(sprintf("  Sheets: %s\n", paste(sheets, collapse = ", ")))

  for (s in sheets) {
    if (grepl("intro|note|content|lookup", tolower(s))) next
    cat(sprintf("\n  Sheet: %s\n", s))
    tryCatch({
      dt <- readODS::read_ods(pfa_file, sheet = s)
      cat(sprintf("    Rows: %d, Cols: %d\n", nrow(dt), ncol(dt)))
      cat(sprintf("    Columns: %s\n", paste(head(names(dt), 10), collapse = " | ")))
      if (nrow(dt) > 0) {
        # Show first few rows
        for (r in 1:min(3, nrow(dt))) {
          vals <- sapply(dt[r, 1:min(6, ncol(dt))], as.character)
          cat(sprintf("    Row %d: %s\n", r, paste(vals, collapse = " | ")))
        }
      }
    }, error = function(e) cat(sprintf("    Error: %s\n", e$message)))
  }
}

# ============================================================================
# 5. Parse the more recent outcomes open data files (2015-2018)
# ============================================================================
cat("\n=== Parsing recent outcomes open data files ===\n")

recent_files <- list.files(data_dir, pattern = "outcomes_open_mar201[5-8]|outcomes_open_aprjun",
                           full.names = TRUE)
cat(sprintf("Found %d recent outcomes files\n", length(recent_files)))

for (rf in recent_files) {
  cat(sprintf("\n--- %s ---\n", basename(rf)))
  tryCatch({
    sheets <- readODS::list_ods_sheets(rf)
    cat(sprintf("  Sheets: %s\n", paste(sheets, collapse = ", ")))

    for (s in sheets) {
      if (grepl("intro|note|content|lookup|source", tolower(s))) next
      cat(sprintf("  Sheet: %s\n", s))
      tryCatch({
        dt <- readODS::read_ods(rf, sheet = s, n_max = 10)
        cat(sprintf("    Rows: %d, Cols: %d\n", nrow(dt), ncol(dt)))
        cat(sprintf("    Columns: %s\n", paste(head(names(dt), 10), collapse = " | ")))
        if (nrow(dt) > 0) {
          for (r in 1:min(3, nrow(dt))) {
            vals <- sapply(dt[r, 1:min(8, ncol(dt))], as.character)
            cat(sprintf("    Row %d: %s\n", r, paste(vals, collapse = " | ")))
          }
        }
        break  # Only show first data sheet
      }, error = function(e) cat(sprintf("    Error: %s\n", e$message)))
    }
  }, error = function(e) cat(sprintf("  Error: %s\n", e$message)))
}

# ============================================================================
# 6. Also load the Police UK API data (2023-2026)
# ============================================================================
cat("\n=== Loading Police UK API data (2023-2026) ===\n")

cache_file <- file.path(data_dir, "raw_crime_data.rds")
if (file.exists(cache_file)) {
  api_data <- readRDS(cache_file)
  cat(sprintf("  API data: %d records, %s to %s, %d forces\n",
              nrow(api_data), min(api_data$month), max(api_data$month),
              uniqueN(api_data$force)))
} else {
  cat("  No API data cache found. Run the previous version of this script first.\n")
}

cat("\n=== Data fetch complete ===\n")
