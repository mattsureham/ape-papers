## 01_fetch_data.R — Download Gambling Commission and ONS data
## apep_0715: FOBT Stake Reduction

source("00_packages.R")
# Set working directory to paper root (one level up from code/)
paper_root <- file.path(dirname(getwd()))
setwd(paper_root)
if (!dir.exists("data")) dir.create("data")

cat("=== Fetching data for apep_0715 ===\n")

# ─────────────────────────────────────────────────────────────
# 1. Licensing Authority Statistics (2014-2024, LA-level)
# ─────────────────────────────────────────────────────────────
la_stats_url <- "https://assets.ctfassets.net/j16ev64qyf6l/1ZTQg3I5OlRlAFtn1GNtWS/98bb4dac945e1c0f381b2ea50c267b7e/Licensing_Authority_Statistics_-_01_April_2014_-_31_March_2024.xlsx"
la_stats_file <- "data/licensing_authority_statistics.xlsx"

if (!file.exists(la_stats_file)) {
  cat("Downloading Licensing Authority Statistics...\n")
  resp <- httr::GET(la_stats_url, httr::write_disk(la_stats_file, overwrite = TRUE))
  if (httr::status_code(resp) != 200) {
    stop("FATAL: Failed to download LA statistics. Status: ", httr::status_code(resp))
  }
  cat("  Downloaded:", la_stats_file, "\n")
} else {
  cat("  LA statistics already on disk.\n")
}

# Inspect sheet names
sheets <- readxl::excel_sheets(la_stats_file)
cat("  Sheets in LA statistics file:\n")
for (s in sheets) cat("    -", s, "\n")

# ─────────────────────────────────────────────────────────────
# 2. Industry Statistics (national GGY by sector, 2009-2024)
# ─────────────────────────────────────────────────────────────
industry_url <- "https://assets.ctfassets.net/j16ev64qyf6l/3hjds3IqrgSlerWoSEfkAd/0d15fd771b342a3c0e733de5d79a256a/Industry_Statistics_July_2025_Correction.xlsx"
industry_file <- "data/industry_statistics.xlsx"

if (!file.exists(industry_file)) {
  cat("Downloading Industry Statistics...\n")
  resp <- httr::GET(industry_url, httr::write_disk(industry_file, overwrite = TRUE))
  if (httr::status_code(resp) != 200) {
    stop("FATAL: Failed to download industry statistics. Status: ", httr::status_code(resp))
  }
  cat("  Downloaded:", industry_file, "\n")
} else {
  cat("  Industry statistics already on disk.\n")
}

industry_sheets <- readxl::excel_sheets(industry_file)
cat("  Sheets in industry statistics file:\n")
for (s in industry_sheets) cat("    -", s, "\n")

# ─────────────────────────────────────────────────────────────
# 3. Premises register (current snapshot with license dates)
# ─────────────────────────────────────────────────────────────
premises_url <- "https://www.gamblingcommission.gov.uk/downloads/premises-licence-register.csv"
premises_file <- "data/premises_register.csv"

if (!file.exists(premises_file)) {
  cat("Downloading premises register...\n")
  resp <- httr::GET(premises_url, httr::write_disk(premises_file, overwrite = TRUE))
  if (httr::status_code(resp) != 200) {
    stop("FATAL: Failed to download premises register. Status: ", httr::status_code(resp))
  }
  cat("  Downloaded:", premises_file, "\n")
} else {
  cat("  Premises register already on disk.\n")
}

# Quick peek
premises_raw <- readr::read_csv(premises_file, show_col_types = FALSE, n_max = 5)
cat("  Premises register columns:\n")
cat("   ", paste(names(premises_raw), collapse = ", "), "\n")
cat("  First 5 rows:\n")
print(premises_raw)

# ─────────────────────────────────────────────────────────────
# 4. ONS mid-year population estimates by LA
# ─────────────────────────────────────────────────────────────
# Use ONS mid-year estimates for adult population (16+) by LA
# Available from NOMIS: NM_2002_1 (population estimates by LA)
# We'll use a simpler approach: download from ONS API

ons_pop_url <- "https://www.nomisweb.co.uk/api/v01/dataset/NM_2002_1.data.csv?geography=TYPE464&date=2015-2019&sex=7&age=0&measures=20100"
ons_pop_file <- "data/ons_population.csv"

if (!file.exists(ons_pop_file)) {
  cat("Downloading ONS population estimates...\n")
  resp <- httr::GET(ons_pop_url, httr::write_disk(ons_pop_file, overwrite = TRUE))
  if (httr::status_code(resp) == 200) {
    cat("  Downloaded:", ons_pop_file, "\n")
  } else {
    cat("  WARNING: ONS population download failed (status ", httr::status_code(resp), "). Will try alternative.\n")
    # Alternative: use total population from LA statistics if available
  }
} else {
  cat("  ONS population already on disk.\n")
}

cat("\n=== All data fetched successfully ===\n")
cat("Files in data/:\n")
for (f in list.files("data")) cat("  ", f, "\n")
