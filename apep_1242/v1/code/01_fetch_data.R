# 01_fetch_data.R — Fetch UK Companies House PSC bulk snapshot + basic company data
# Data: PSC snapshot (JSON-lines in zip, ~72MB/chunk), Basic Company Data (CSV)
# Both free, no API key required

source("00_packages.R")

set.seed(42)
data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# 1. Download PSC snapshot chunks
# ============================================================================

base_url <- "http://download.companieshouse.gov.uk/"
snapshot_date <- "2026-04-01"
total_chunks <- 31

# Download 5 spread-out chunks for broad coverage (~2M+ companies)
chunks_to_get <- c(1, 8, 16, 24, 31)

for (chunk in chunks_to_get) {
  url <- sprintf("%spsc-snapshot-%s_%dof%d.zip", base_url, snapshot_date, chunk, total_chunks)
  dest <- file.path(data_dir, sprintf("psc_chunk_%d.zip", chunk))

  if (!file.exists(dest) || file.info(dest)$size < 1e6) {
    cat(sprintf("Downloading chunk %d/%d...\n", chunk, total_chunks))
    result <- tryCatch(
      download.file(url, dest, mode = "wb", quiet = TRUE),
      error = function(e) { cat(sprintf("  FAILED: %s\n", e$message)); 1 }
    )
    if (result != 0 || !file.exists(dest) || file.info(dest)$size < 1e6) {
      stop(sprintf("FATAL: Failed to download PSC chunk %d. No fallback.", chunk))
    }
  }
  cat(sprintf("  Chunk %d: %.1f MB\n", chunk, file.info(dest)$size / 1e6))
}

# ============================================================================
# 2. Parse PSC snapshot data — one chunk at a time with isolated temp dirs
# ============================================================================

cat("\nParsing PSC data...\n")

parse_psc_chunk <- function(zip_path, chunk_id) {
  cat(sprintf("  Parsing chunk %d...\n", chunk_id))

  # Extract to a UNIQUE temp directory to avoid cross-chunk contamination
  extract_dir <- file.path(tempdir(), sprintf("psc_chunk_%d", chunk_id))
  dir.create(extract_dir, showWarnings = FALSE, recursive = TRUE)
  unzip(zip_path, exdir = extract_dir)

  # Find the extracted .txt file
  txt_files <- list.files(extract_dir, pattern = "\\.txt$", full.names = TRUE)
  if (length(txt_files) == 0) {
    txt_files <- list.files(extract_dir, full.names = TRUE)
    txt_files <- txt_files[file.info(txt_files)$size > 1e4]
  }
  if (length(txt_files) == 0) stop(sprintf("No data file found in chunk %d", chunk_id))

  filepath <- txt_files[1]
  cat(sprintf("    File: %s (%.0f MB)\n", basename(filepath),
              file.info(filepath)$size / 1e6))

  # Read all lines (JSON-lines format: one PSC record per line)
  lines <- readLines(filepath, warn = FALSE)
  cat(sprintf("    Lines: %s\n", format(length(lines), big.mark = ",")))

  # Parse each line — extract key fields
  records <- vector("list", length(lines))
  n_parsed <- 0L
  n_failed <- 0L

  for (i in seq_along(lines)) {
    rec <- tryCatch({
      obj <- fromJSON(lines[i], simplifyVector = FALSE)
      co_num <- obj$company_number
      d <- obj$data

      natures <- d$natures_of_control
      band <- "unknown"
      if (!is.null(natures)) {
        for (n in natures) {
          if (grepl("75-to-100", n)) { band <- "75-100"; break }
          if (grepl("50-to-75", n)) { band <- "50-75"; break }
          if (grepl("25-to-50", n)) { band <- "25-50"; break }
          if (grepl("more-than-25", n)) { band <- "25+"; break }
        }
      }

      list(
        company_number = co_num,
        ownership_band = band,
        kind = d$kind %||% NA_character_,
        notified_on = d$notified_on %||% NA_character_,
        country_of_residence = d$country_of_residence %||% NA_character_,
        nationality = d$nationality %||% NA_character_
      )
    }, error = function(e) NULL)

    if (!is.null(rec)) {
      n_parsed <- n_parsed + 1L
      records[[n_parsed]] <- rec
    } else {
      n_failed <- n_failed + 1L
    }
  }

  records <- records[seq_len(n_parsed)]
  cat(sprintf("    Parsed: %s (failed: %d)\n",
              format(n_parsed, big.mark = ","), n_failed))

  # Clean up extracted file
  unlink(extract_dir, recursive = TRUE)

  rbindlist(records, fill = TRUE)
}

# NULL coalesce operator
`%||%` <- function(a, b) if (!is.null(a) && length(a) > 0 && !is.na(a[1])) a else b

all_chunks <- list()
for (chunk in chunks_to_get) {
  zip_path <- file.path(data_dir, sprintf("psc_chunk_%d.zip", chunk))
  all_chunks[[as.character(chunk)]] <- parse_psc_chunk(zip_path, chunk)
}

psc_all <- rbindlist(all_chunks, fill = TRUE)
cat(sprintf("\nTotal PSC records: %s\n", format(nrow(psc_all), big.mark = ",")))

# ============================================================================
# 3. Aggregate to company level
# ============================================================================

company_psc <- psc_all[, .(
  n_pscs = .N,
  n_individual = sum(grepl("individual", kind, ignore.case = TRUE), na.rm = TRUE),
  n_corporate = sum(grepl("corporate", kind, ignore.case = TRUE), na.rm = TRUE),
  n_band_25_50 = sum(ownership_band == "25-50", na.rm = TRUE),
  n_band_50_75 = sum(ownership_band == "50-75", na.rm = TRUE),
  n_band_75_100 = sum(ownership_band == "75-100", na.rm = TRUE),
  n_band_25plus = sum(ownership_band == "25+", na.rm = TRUE),
  n_band_unknown = sum(ownership_band == "unknown", na.rm = TRUE),
  n_foreign = sum(!is.na(country_of_residence) &
                    !country_of_residence %in% c("England", "Scotland", "Wales",
                                                  "Northern Ireland", "United Kingdom"),
                  na.rm = TRUE),
  has_corporate_psc = any(grepl("corporate", kind, ignore.case = TRUE), na.rm = TRUE)
), by = company_number]

cat("\n=== PSC Count Distribution ===\n")
psc_dist <- company_psc[, .N, by = n_pscs][order(n_pscs)]
psc_dist[, pct := round(100 * N / sum(N), 1)]
print(psc_dist[1:12])

# Verify: should see ~80% with 1 PSC
stopifnot("Expected ~80% single-PSC companies" =
            psc_dist[n_pscs == 1, N] / nrow(company_psc) > 0.5)

cat(sprintf("\nUnique companies: %s\n", format(nrow(company_psc), big.mark = ",")))

# ============================================================================
# 4. Download basic company data for SIC codes / incorporation dates
# ============================================================================

company_csv <- file.path(data_dir, "company_data.csv")
if (!file.exists(company_csv)) {
  cat("\nDownloading basic company data...\n")
  dates_try <- format(seq(as.Date("2026-04-01"), as.Date("2025-10-01"), by = "-1 month"), "%Y-%m-%d")

  downloaded <- FALSE
  for (d in dates_try) {
    url_try <- sprintf("%sBasicCompanyDataAsOneFile-%s.zip", base_url, d)
    dest_zip <- file.path(data_dir, "company_data.zip")
    cat(sprintf("  Trying: %s\n", url_try))
    ok <- tryCatch({
      download.file(url_try, dest_zip, mode = "wb", quiet = TRUE)
      file.exists(dest_zip) && file.info(dest_zip)$size > 1e7
    }, error = function(e) FALSE)

    if (ok) {
      cat(sprintf("  Downloaded (%.0f MB). Unzipping...\n", file.info(dest_zip)$size / 1e6))
      unzip(dest_zip, exdir = data_dir)
      csvs <- list.files(data_dir, pattern = "BasicCompanyData.*\\.csv$", full.names = TRUE)
      if (length(csvs) > 0) {
        file.rename(csvs[1], company_csv)
        downloaded <- TRUE
        break
      }
    }
  }

  if (!downloaded) {
    cat("WARNING: Could not download basic company data.\n")
  }
}

if (file.exists(company_csv)) {
  cat("Reading basic company data...\n")
  co_meta <- fread(company_csv,
                   select = c("CompanyNumber", "SICCode.SicText_1",
                              "IncorporationDate", "CompanyStatus",
                              "RegAddress.PostCode"),
                   showProgress = FALSE, nThread = 4)

  company_psc <- merge(company_psc, co_meta,
                       by.x = "company_number", by.y = "CompanyNumber",
                       all.x = TRUE)

  company_psc[, sic_text := `SICCode.SicText_1`]
  company_psc[, sic_div := substr(gsub("[^0-9]", "", sic_text), 1, 2)]
  company_psc[, inc_date := as.Date(IncorporationDate, format = "%d/%m/%Y")]
  company_psc[, inc_year := year(inc_date)]

  # High-risk sectors (FATF AML categories)
  company_psc[, high_risk := sic_div %in% c("64", "65", "66", "68", "69", "70", "82")]

  # Era indicators
  company_psc[, era := fcase(
    inc_date < as.Date("2016-04-06"), "Pre-PSC",
    inc_date >= as.Date("2016-04-06") & inc_date < as.Date("2023-10-26"), "Post-PSC",
    inc_date >= as.Date("2023-10-26"), "Post-ECCTA",
    default = NA_character_
  )]

  cat(sprintf("Matched with metadata: %d companies\n",
              sum(!is.na(company_psc$sic_div))))
}

# ============================================================================
# 5. Save
# ============================================================================

fwrite(company_psc, file.path(data_dir, "psc_company_merged.csv"))
fwrite(psc_all, file.path(data_dir, "psc_records_raw.csv"))
cat(sprintf("\nSaved: %s companies, %s raw PSC records\n",
            format(nrow(company_psc), big.mark = ","),
            format(nrow(psc_all), big.mark = ",")))
