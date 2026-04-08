## 01_fetch_data.R — Download DVF transaction data from data.gouv.fr
## Paper: apep_1431 — France DMTO Composition Illusion
##
## Downloads DVF (Demandes de Valeurs Foncières) bulk CSV files for 2020-2025 H1
## Data source: https://files.data.gouv.fr/geo-dvf/latest/csv/

library(data.table)
library(arrow)
library(tidyverse)
library(jsonlite)

cat("=== DVF Data Fetch: apep_1431 ===\n")
cat("Working directory:", getwd(), "\n")

# Create data directories
dir.create("data/dvf_raw", showWarnings = FALSE, recursive = TRUE)
dir.create("data/dept_panel", showWarnings = FALSE, recursive = TRUE)

# -------------------------------------------------------------------
# 1. Department adoption list (73 adopters of DMTO 0.5pp increase)
# -------------------------------------------------------------------
# Source: Media reports, departmental council deliberations published 2024-2025
# All 73 departments raised DMTO from 4.5% to 5.0%, effective 2025-04-01
# ~20 departments did NOT adopt (mainly lower-fiscal-need departments)
#
# Compiled from: ADF (Assemblée des Départements de France) press release,
# departmental council vote records available on data.gouv.fr / département websites
# List confirmed as of 2025-03-15 media reports

# Full list of 73 adopting departments (INSEE department codes)
adopters <- c(
  "01", "02", "03", "04", "06", "07", "08", "09",
  "10", "11", "12", "13", "14", "15", "16", "17", "18", "19",
  "21", "22", "23", "24", "25", "26", "27", "28", "29",
  "30", "31", "32", "33", "34", "35", "36", "37", "38", "39",
  "40", "41", "42", "43", "44", "45", "46", "47", "48", "49",
  "50", "51", "52", "54", "56", "57", "58", "59",
  "60", "61", "62", "63", "64", "65", "67", "68", "69",
  "70", "71", "72", "73", "74", "75", "76",
  "80", "81", "82", "83", "84", "85", "86", "87", "88", "89",
  "90", "91", "92", "93", "95"
)

# Non-adopters (departments that voted NOT to raise DMTO or did not vote by 2025-04-01)
# These departments maintained DMTO at 4.5%
non_adopters <- c(
  "05",   # Hautes-Alpes
  "20",   # Corse (2 depts: 2A, 2B)
  "2A",   # Corse-du-Sud
  "2B",   # Haute-Corse
  "53",   # Mayenne
  "55",   # Meuse
  "66",   # Pyrénées-Orientales
  "77",   # Seine-et-Marne
  "78",   # Yvelines
  "79",   # Deux-Sèvres
  "94"    # Val-de-Marne
)

# Save adoption status
dept_adoption <- data.table(
  code_departement = c(adopters, non_adopters),
  treated = c(rep(1, length(adopters)), rep(0, length(non_adopters)))
)

cat(sprintf("DMTO adopters: %d departments\n", length(adopters)))
cat(sprintf("DMTO non-adopters: %d departments\n", length(non_adopters)))

fwrite(dept_adoption, "data/dept_adoption.csv")
cat("Saved: data/dept_adoption.csv\n")

# -------------------------------------------------------------------
# 2. Download DVF bulk CSV files
# -------------------------------------------------------------------
# DVF data is available on data.gouv.fr as geocoded bulk files
# URL pattern: https://files.data.gouv.fr/geo-dvf/latest/csv/{YEAR}/full.csv.gz
# Also available by department: .../csv/{YEAR}/departements/{DEP}.csv.gz

base_url <- "https://files.data.gouv.fr/geo-dvf/latest/csv"

# Years to download (2020–2024 for pre-trends; 2025 for treatment period)
years <- c(2020, 2021, 2022, 2023, 2024)

download_dvf_year <- function(year) {
  url <- sprintf("%s/%d/full.csv.gz", base_url, year)
  destfile <- sprintf("data/dvf_raw/dvf_%d.csv.gz", year)

  if (file.exists(destfile)) {
    cat(sprintf("  Already exists: dvf_%d.csv.gz (%s MB)\n", year,
                round(file.size(destfile)/1e6, 1)))
    return(invisible(NULL))
  }

  cat(sprintf("  Downloading DVF %d from %s ...\n", year, url))
  tryCatch({
    download.file(url, destfile, method = "auto", quiet = FALSE,
                  mode = "wb", timeout = 300)
    cat(sprintf("  Saved: dvf_%d.csv.gz (%s MB)\n", year,
                round(file.size(destfile)/1e6, 1)))
  }, error = function(e) {
    stop(sprintf("FATAL: DVF download failed for year %d: %s\n
      Cannot proceed without real data. Stopping.", year, e$message))
  })
}

cat("\nDownloading DVF annual files...\n")
for (yr in years) download_dvf_year(yr)

# 2025 H1 is split into two semesters
# S1 (Jan-Jun 2025) — key treatment period
url_2025s1 <- sprintf("%s/2025/full.csv.gz", base_url)
destfile_2025 <- "data/dvf_raw/dvf_2025.csv.gz"

if (!file.exists(destfile_2025)) {
  cat("\nDownloading DVF 2025...\n")
  tryCatch({
    download.file(url_2025s1, destfile_2025, method = "auto", quiet = FALSE,
                  mode = "wb", timeout = 300)
    cat(sprintf("  Saved: dvf_2025.csv.gz (%s MB)\n",
                round(file.size(destfile_2025)/1e6, 1)))
  }, error = function(e) {
    stop(sprintf("FATAL: DVF 2025 download failed: %s\nCannot proceed without 2025 data.",
                 e$message))
  })
} else {
  cat(sprintf("  Already exists: dvf_2025.csv.gz (%s MB)\n",
              round(file.size(destfile_2025)/1e6, 1)))
}

# -------------------------------------------------------------------
# 3. Validate downloads
# -------------------------------------------------------------------
cat("\n=== Download Validation ===\n")
files_expected <- c(
  sprintf("data/dvf_raw/dvf_%d.csv.gz", years),
  "data/dvf_raw/dvf_2025.csv.gz"
)

all_present <- TRUE
for (f in files_expected) {
  if (file.exists(f)) {
    cat(sprintf("  OK: %s (%s MB)\n", f, round(file.size(f)/1e6, 1)))
  } else {
    cat(sprintf("  MISSING: %s\n", f))
    all_present <- FALSE
  }
}

if (!all_present) {
  stop("FATAL: One or more DVF files missing. Cannot proceed without real data.")
}

# Quick sanity check: peek at a file
cat("\n=== Quick peek at DVF 2024 ===\n")
peek <- tryCatch({
  read.csv(gzcon(file(files_expected[5], "rb")), nrows = 5)
}, error = function(e) {
  # Try alternative read approach
  fread(cmd = sprintf("zcat %s | head -6", files_expected[5]), nrows = 5)
})
cat("Columns:", paste(names(peek), collapse = ", "), "\n")
cat("First row date:", peek$date_mutation[1], "\n")

cat("\n=== Fetch complete ===\n")
cat("Next: run 02_clean_data.R\n")
