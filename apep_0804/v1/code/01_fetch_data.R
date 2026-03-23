# 01_fetch_data.R — Download ACS 1-Year PUMS via Census FTP (fast)
# APEP Paper apep_0804: The Caregiving Tax
#
# Strategy: Download national PUMS person CSVs from Census FTP.
# Much faster than the API (single large file vs thousands of paginated calls).

source("00_packages.R")

cat("=== Fetching ACS PUMS microdata 2008-2019 via FTP ===\n")

years <- 2008:2019
all_data <- list()

# Select columns to keep (minimize memory)
keep_cols <- c("SERIALNO", "ST", "AGEP", "SEX", "RELP", "REL",
               "DREM", "DPHY", "ESR", "WKHP", "WAGP",
               "SCHL", "RAC1P", "MAR", "PWGTP")

for (yr in years) {
  cache_file <- sprintf("../data/pums_filtered_%d.csv", yr)

  if (file.exists(cache_file)) {
    cat(sprintf("%d: Loading from cache...\n", yr))
    all_data[[as.character(yr)]] <- fread(cache_file)
    next
  }

  cat(sprintf("Downloading ACS PUMS %d from Census FTP...\n", yr))

  # Census FTP URL for national person file
  # 2008-2012: csv_pus.zip; 2013+: csv_pus.zip (same pattern)
  base_url <- sprintf(
    "https://www2.census.gov/programs-surveys/acs/data/pums/%d/1-Year/csv_pus.zip",
    yr
  )

  zip_file <- sprintf("../data/pums_%d.zip", yr)

  # Download ZIP
  dl_result <- tryCatch(
    download.file(base_url, zip_file, mode = "wb", quiet = TRUE),
    error = function(e) {
      # Try alternate URL pattern
      alt_url <- sprintf(
        "https://www2.census.gov/programs-surveys/acs/data/pums/%d/1-Year/csv_pus.zip",
        yr
      )
      tryCatch(
        download.file(alt_url, zip_file, mode = "wb", quiet = TRUE),
        error = function(e2) {
          stop(sprintf("FATAL: Cannot download PUMS for %d: %s", yr, e2$message))
        }
      )
    }
  )

  # List CSV files in ZIP
  csv_files <- unzip(zip_file, list = TRUE)$Name
  csv_file <- grep("^(ss|psam_pus|csv_pus)", csv_files, value = TRUE, ignore.case = TRUE)
  if (length(csv_file) == 0) {
    # Try any CSV
    csv_file <- grep("\\.csv$", csv_files, value = TRUE, ignore.case = TRUE)
  }
  if (length(csv_file) == 0) {
    stop(sprintf("FATAL: No CSV found in ZIP for %d. Files: %s",
                 yr, paste(csv_files, collapse = ", ")))
  }

  cat(sprintf("  Extracting %s...\n", csv_file[1]))

  # Extract CSV to data dir
  unzip(zip_file, files = csv_file[1], exdir = "../data/", overwrite = TRUE)
  extracted_path <- file.path("../data", csv_file[1])

  # Read with fread — only keep needed columns
  # First get header to find which columns exist
  header <- names(fread(extracted_path, nrows = 0))
  sel_cols <- intersect(keep_cols, header)
  raw <- fread(extracted_path, select = sel_cols, showProgress = FALSE)

  # If multiple CSVs (some years split into a/b), handle that
  if (length(csv_file) > 1) {
    for (cf in csv_file[-1]) {
      unzip(zip_file, files = cf, exdir = "../data/", overwrite = TRUE)
      ep <- file.path("../data", cf)
      hdr <- names(fread(ep, nrows = 0))
      part <- fread(ep, select = intersect(keep_cols, hdr), showProgress = FALSE)
      raw <- rbind(raw, part, fill = TRUE)
      file.remove(ep)
    }
  }

  # Clean up extracted CSV and ZIP
  file.remove(extracted_path)
  file.remove(zip_file)

  cat(sprintf("  %d: %s person records\n", yr, format(nrow(raw), big.mark = ",")))

  # Harmonize relationship variable
  if ("REL" %in% names(raw) && !"RELP" %in% names(raw)) {
    setnames(raw, "REL", "RELP")
  }
  # RELP in 2019 uses new codes (20=ref, 21/22=spouse, 23/24=partner)
  # Harmonize to old coding (0=ref, 1=spouse, 13=partner)
  if (yr >= 2019 && "RELP" %in% names(raw)) {
    raw[RELP == 20, RELP := 0L]
    raw[RELP %in% c(21, 22), RELP := 1L]
    raw[RELP %in% c(23, 24), RELP := 13L]
  }

  raw[, year := yr]

  # Type safety
  for (col in c("AGEP", "SEX", "RELP", "DREM", "DPHY", "ESR",
                "WKHP", "SCHL", "RAC1P", "MAR")) {
    if (col %in% names(raw)) raw[, (col) := as.integer(get(col))]
  }
  if ("WAGP" %in% names(raw)) raw[, WAGP := as.numeric(WAGP)]
  if ("PWGTP" %in% names(raw)) raw[, PWGTP := as.numeric(PWGTP)]

  # Filter: keep children 5-17 and women 20-60
  filtered <- raw[(AGEP >= 5 & AGEP <= 17) | (SEX == 2 & AGEP >= 20 & AGEP <= 60)]
  cat(sprintf("  Filtered: %s records\n", format(nrow(filtered), big.mark = ",")))

  fwrite(filtered, cache_file)
  all_data[[as.character(yr)]] <- filtered
  rm(raw, filtered); gc(verbose = FALSE)
}

# Stack
dt <- rbindlist(all_data, fill = TRUE)
cat(sprintf("\nTotal: %s records across %d years\n",
            format(nrow(dt), big.mark = ","), length(years)))

fwrite(dt, "../data/acs_pums_raw.csv")
cat("Saved to data/acs_pums_raw.csv\n")

# Validate
stopifnot("DREM" %in% names(dt))
stopifnot("ESR" %in% names(dt))
stopifnot("SERIALNO" %in% names(dt))
cat(sprintf("DREM values: %s\n",
            paste(sort(unique(dt$DREM[!is.na(dt$DREM)])), collapse = ", ")))
cat(sprintf("States: %d\n", uniqueN(dt$ST)))
cat("=== Data fetch complete ===\n")
