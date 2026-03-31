## 01d_fetch_cdc_natality.R — Get county-level natality data
## apep_1190: Try multiple approaches to get county-level birth data

source("00_packages.R")
data_dir <- "../data"

# ============================================================================
# APPROACH 1: CDC FTP fixed-width natality (includes county FIPS)
# ============================================================================
# The CDC publishes natality in fixed-width format at CDC FTP.
# Unlike the NBER CSV version, the fixed-width may include geographic fields
# at positions defined in the record layout.

cat("=== Approach 1: CDC FTP Fixed-Width Natality ===\n")

# Try 2022 first (most recent)
yr <- 2022
cdc_url <- sprintf(
  "https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/DVS/natality/Nat%dus.zip",
  yr
)

zip_file <- file.path(data_dir, sprintf("Nat%dus.zip", yr))
cat(sprintf("Downloading CDC FTP natality %d...\n", yr))

resp <- tryCatch({
  httr::GET(cdc_url, httr::timeout(600),
            httr::write_disk(zip_file, overwrite = TRUE),
            httr::progress())
}, error = function(e) {
  cat(sprintf("Download failed: %s\n", e$message))
  NULL
})

if (!is.null(resp) && httr::status_code(resp) == 200 &&
    file.exists(zip_file) && file.size(zip_file) > 1000) {
  cat("Unzipping...\n")
  unzip(zip_file, exdir = data_dir)

  # Find the fixed-width file
  fwf_files <- list.files(data_dir, pattern = sprintf("(?i)nat.*%d.*\\.txt$|nat.*%d.*\\.dat$|VS.*%d", yr, yr, yr),
                           full.names = TRUE)

  # Also check for unzipped files without extension filter
  all_new <- list.files(data_dir, pattern = sprintf("(?i).*%d.*", yr),
                         full.names = TRUE)
  all_new <- setdiff(all_new, c(zip_file, list.files(data_dir, pattern = "\\.csv$|\\.zip$",
                                                       full.names = TRUE)))
  cat(sprintf("New files after unzip: %s\n",
              paste(basename(all_new), collapse = ", ")))

  # Check first few bytes of each potential data file
  for (f in all_new) {
    if (file.size(f) > 10000) {
      sample <- readLines(f, n = 2, warn = FALSE)
      cat(sprintf("  %s: width=%d, starts with: %s\n",
                  basename(f), nchar(sample[1]),
                  substr(sample[1], 1, 100)))
    }
  }
} else {
  cat("CDC FTP download failed or returned empty file.\n")
  if (file.exists(zip_file)) file.remove(zip_file)
}

# ============================================================================
# APPROACH 2: County Health Rankings (try multiple URL formats)
# ============================================================================
cat("\n=== Approach 2: County Health Rankings ===\n")

# CHR uses various URL patterns across years
chr_urls <- list(
  "2024" = "https://www.countyhealthrankings.org/sites/default/files/media/document/2024CHR_CSV_Analytic_Data.csv",
  "2023" = "https://www.countyhealthrankings.org/sites/default/files/media/document/2023CHR_CSV_Analytic_Data.csv",
  "2022" = "https://www.countyhealthrankings.org/sites/default/files/media/document/2022CHR_CSV_Analytic_Data.csv",
  "2021" = "https://www.countyhealthrankings.org/sites/default/files/media/document/2021CHR_CSV_Analytic_Data.csv",
  "2020" = "https://www.countyhealthrankings.org/sites/default/files/media/document/2020CHR_CSV_Analytic_Data.csv",
  "2019" = "https://www.countyhealthrankings.org/sites/default/files/media/document/2019CHR_CSV_Analytic_Data.csv",
  "2018" = "https://www.countyhealthrankings.org/sites/default/files/media/document/2018CHR_CSV_Analytic_Data.csv",
  "2017" = "https://www.countyhealthrankings.org/sites/default/files/media/document/2017CHR_CSV_Analytic_Data.csv"
)

chr_found <- list()

for (yr_str in names(chr_urls)) {
  cat(sprintf("  CHR %s: ", yr_str))
  url <- chr_urls[[yr_str]]

  resp <- tryCatch(
    httr::GET(url, httr::timeout(30),
              httr::config(followlocation = TRUE)),
    error = function(e) NULL
  )

  if (!is.null(resp) && httr::status_code(resp) == 200) {
    content <- httr::content(resp, "raw")
    if (length(content) > 5000) {
      out_file <- file.path(data_dir, sprintf("chr_%s.csv", yr_str))
      writeBin(content, out_file)
      cat(sprintf("saved (%s bytes)\n", format(length(content), big.mark = ",")))
      chr_found[[yr_str]] <- yr_str
    } else {
      cat("too small\n")
    }
  } else {
    # Try alternate URL patterns
    alt_urls <- c(
      sprintf("https://www.countyhealthrankings.org/sites/default/files/media/document/analytic_data%s.csv", yr_str),
      sprintf("https://www.countyhealthrankings.org/sites/default/files/analytic_data%s.csv", yr_str),
      sprintf("https://www.countyhealthrankings.org/sites/default/files/media/document/%sCHR_CSV_Analytic_Data_v2.csv", yr_str)
    )

    got_it <- FALSE
    for (alt in alt_urls) {
      resp2 <- tryCatch(
        httr::GET(alt, httr::timeout(30), httr::config(followlocation = TRUE)),
        error = function(e) NULL
      )
      if (!is.null(resp2) && httr::status_code(resp2) == 200 &&
          length(httr::content(resp2, "raw")) > 5000) {
        writeBin(httr::content(resp2, "raw"),
                 file.path(data_dir, sprintf("chr_%s.csv", yr_str)))
        cat("saved (alt URL)\n")
        chr_found[[yr_str]] <- yr_str
        got_it <- TRUE
        break
      }
    }
    if (!got_it) cat("not found\n")
  }
  Sys.sleep(0.3)
}

cat(sprintf("CHR data found for %d years: %s\n",
            length(chr_found), paste(unlist(chr_found), collapse = ", ")))

# Parse CHR files if found
if (length(chr_found) > 0) {
  cat("\nParsing CHR files for birth outcome measures...\n")

  for (yr_str in names(chr_found)) {
    f <- file.path(data_dir, sprintf("chr_%s.csv", yr_str))
    # CHR CSVs often have 2 header rows
    lines <- readLines(f, n = 5, warn = FALSE)
    cat(sprintf("  %s: first line starts: %s\n", yr_str, substr(lines[1], 1, 120)))
  }
}

# ============================================================================
# APPROACH 3: CDC PLACES (county-level health indicators)
# ============================================================================
cat("\n=== Approach 3: CDC PLACES (checking available measures) ===\n")

# Get full list of available county-level measures
places_url <- "https://data.cdc.gov/resource/swc5-untb.json?$select=distinct%20measureid,measure,category&$limit=500"
resp <- tryCatch(httr::GET(places_url, httr::timeout(30)), error = function(e) NULL)

if (!is.null(resp) && httr::status_code(resp) == 200) {
  df <- tryCatch(jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8")),
                  error = function(e) NULL)
  if (!is.null(df) && is.data.frame(df)) {
    cat("Available measures in CDC PLACES:\n")
    print(df[, c("measureid", "measure", "category")])
  }
}

# ============================================================================
# APPROACH 4: CDC Tracking Network (correct API format)
# ============================================================================
cat("\n=== Approach 4: CDC Tracking Network (corrected API) ===\n")

# First, find the right measure IDs for birth outcomes
# Use /measures endpoint with content area filter
resp <- tryCatch(
  httr::GET("https://ephtracking.cdc.gov/apigateway/api/v1/measures/1/json",
            httr::timeout(30)),
  error = function(e) NULL
)

if (!is.null(resp) && httr::status_code(resp) == 200) {
  content <- httr::content(resp, "text", encoding = "UTF-8")
  cat(sprintf("Content area 1 response: %s\n", substr(content, 1, 500)))
}

# Try getting data with different parameters
# https://ephtracking.cdc.gov/apigateway/api/v1/getData
for (mid in c(296, 297, 298, 299, 300, 1, 2, 3, 4, 5)) {
  url <- sprintf(
    "https://ephtracking.cdc.gov/apigateway/api/v1/getData?measureId=%d&geographicTypeId=2&temporalColumnName=Year&temporalStartValue=2018&temporalEndValue=2020&isSmoothed=0",
    mid
  )
  resp <- tryCatch(httr::GET(url, httr::timeout(15)), error = function(e) NULL)
  if (!is.null(resp) && httr::status_code(resp) == 200) {
    content <- httr::content(resp, "text", encoding = "UTF-8")
    df <- tryCatch(jsonlite::fromJSON(content), error = function(e) NULL)
    if (!is.null(df) && is.data.frame(df) && nrow(df) > 0) {
      cat(sprintf("Measure %d: %d records! Cols: %s\n",
                  mid, nrow(df), paste(head(names(df), 6), collapse = ", ")))
      # Save if it has data
      write_csv(df, file.path(data_dir, sprintf("tracking_m%d.csv", mid)))
    } else if (!is.null(df) && is.list(df) && length(df) > 0) {
      cat(sprintf("Measure %d: list with %d elements\n", mid, length(df)))
    }
  }
}

# ============================================================================
# REPORT
# ============================================================================
cat("\n=== Final data inventory ===\n")
files <- list.files(data_dir, full.names = TRUE)
for (f in files) {
  sz <- file.size(f)
  if (sz > 1000) {
    cat(sprintf("  %s (%s)\n", basename(f), format(sz, big.mark = ",")))
  }
}
