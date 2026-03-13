## 01_fetch_data.R — Fetch police workforce, crime outcomes, and crime data
## apep_0616: Police Austerity and Criminal Justice Quality
##
## Data sources:
## 1. Home Office: Police workforce open data tables (officer headcount by force)
## 2. Home Office: Police recorded crime & outcomes by PFA (2003-2025)
## 3. Home Office: Crime outcomes open data (charge rates by offense type)

suppressPackageStartupMessages({
  library(tidyverse)
  library(httr2)
  library(jsonlite)
  library(readODS)
  library(data.table)
  library(janitor)
})

data_dir <- "data"
dir.create(data_dir, showWarnings = FALSE)

# ============================================================================
# 1. Police Workforce Open Data (officer headcount by force, 2007-2025)
# ============================================================================
cat("=== 1. Fetching Police Workforce Data ===\n")

workforce_url <- "https://assets.publishing.service.gov.uk/media/697255b5a1311bdcfa0ed8f3/open-data-table-police-workforce-280126.ods"
workforce_file <- file.path(data_dir, "police_workforce.ods")

download.file(workforce_url, workforce_file, mode = "wb", quiet = TRUE)
stopifnot("Workforce download failed" = file.exists(workforce_file) && file.info(workforce_file)$size > 1000)
cat("  Downloaded:", round(file.info(workforce_file)$size / 1024), "KB\n")

# List sheets to understand structure
sheets <- list_ods_sheets(workforce_file)
cat("  Sheets:", paste(sheets, collapse = ", "), "\n")

# ============================================================================
# 2. Crime and Outcomes by Police Force Area (2013-2025)
# ============================================================================
cat("\n=== 2. Fetching PFA Crime & Outcomes Data ===\n")

# PFA tables 2013 onwards (13.2 MB)
pfa_2013_url <- "https://assets.publishing.service.gov.uk/media/69779329d345446f8ce71f5e/prc-pfa-mar2013-onwards-tables-290126.ods"
pfa_2013_file <- file.path(data_dir, "pfa_crime_2013_onwards.ods")

download.file(pfa_2013_url, pfa_2013_file, mode = "wb", quiet = TRUE)
stopifnot("PFA 2013+ download failed" = file.exists(pfa_2013_file) && file.info(pfa_2013_file)$size > 1000)
cat("  Downloaded 2013+:", round(file.info(pfa_2013_file)$size / (1024*1024), 1), "MB\n")

# PFA tables 2008-2012 (6 MB)
pfa_2008_url <- "https://assets.publishing.service.gov.uk/media/680799ed8c1316be7978e6cd/prc-pfa-mar2008-mar2012-tabs.ods"
pfa_2008_file <- file.path(data_dir, "pfa_crime_2008_2012.ods")

download.file(pfa_2008_url, pfa_2008_file, mode = "wb", quiet = TRUE)
stopifnot("PFA 2008-12 download failed" = file.exists(pfa_2008_file) && file.info(pfa_2008_file)$size > 1000)
cat("  Downloaded 2008-12:", round(file.info(pfa_2008_file)$size / (1024*1024), 1), "MB\n")

# ============================================================================
# 3. Crime Outcomes Open Data (detailed by offense type, 2023-2025)
# ============================================================================
cat("\n=== 3. Fetching Crime Outcomes Open Data ===\n")

# Latest outcomes file (Mar 2025)
outcomes_url <- "https://assets.publishing.service.gov.uk/media/697792f7276692606c013865/prc-outcomes-open-data-mar2025-tables-290126.xlsx"
outcomes_file <- file.path(data_dir, "crime_outcomes_mar2025.xlsx")

tryCatch({
  download.file(outcomes_url, outcomes_file, mode = "wb", quiet = TRUE)
  cat("  Downloaded outcomes 2025:", round(file.info(outcomes_file)$size / (1024*1024), 1), "MB\n")
}, error = function(e) {
  cat("  2025 outcomes download failed, trying 2024...\n")
  outcomes_url_2024 <- "https://assets.publishing.service.gov.uk/media/697792a267ae94b328013868/prc-outcomes-open-data-mar2024-tables-290126.xlsx"
  download.file(outcomes_url_2024, outcomes_file, mode = "wb", quiet = TRUE)
  cat("  Downloaded outcomes 2024\n")
})

# ============================================================================
# 4. Explore downloaded data structure
# ============================================================================
cat("\n=== 4. Data Structure Exploration ===\n")

# Workforce sheets
cat("\nWorkforce ODS sheets:\n")
for (s in sheets) {
  cat("  -", s, "\n")
}

# Read first few rows of workforce data to understand structure
tryCatch({
  wf_sample <- read_ods(workforce_file, sheet = 1, range = "A1:J10")
  cat("\nWorkforce sheet 1 sample:\n")
  print(head(wf_sample, 5))
}, error = function(e) {
  cat("  Could not read workforce sheet 1:", e$message, "\n")
})

# PFA 2013+ sheets
pfa_sheets <- list_ods_sheets(pfa_2013_file)
cat("\nPFA 2013+ ODS sheets:\n")
for (s in pfa_sheets[1:min(10, length(pfa_sheets))]) {
  cat("  -", s, "\n")
}

# PFA 2008-12 sheets
pfa08_sheets <- list_ods_sheets(pfa_2008_file)
cat("\nPFA 2008-12 ODS sheets:\n")
for (s in pfa08_sheets[1:min(10, length(pfa08_sheets))]) {
  cat("  -", s, "\n")
}

# Outcomes structure
if (file.exists(outcomes_file)) {
  library(readxl)
  out_sheets <- excel_sheets(outcomes_file)
  cat("\nOutcomes XLSX sheets:\n")
  for (s in out_sheets[1:min(10, length(out_sheets))]) {
    cat("  -", s, "\n")
  }
}

cat("\n=== Data Fetch Summary ===\n")
data_files <- list.files(data_dir, full.names = TRUE)
for (f in data_files) {
  cat(sprintf("  %s: %.1f MB\n", basename(f), file.info(f)$size / (1024*1024)))
}
cat("Done.\n")
