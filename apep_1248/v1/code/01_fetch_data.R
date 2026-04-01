## 01_fetch_data.R — Download and combine DANE GEIH microdata (2010-2016)
## Uses pre-scraped URL manifest from 00a_scrape_urls.py

library(httr)
library(haven)
library(data.table)
library(jsonlite)

DATA_DIR <- file.path(dirname(getwd()), "data")
RAW_DIR <- file.path(DATA_DIR, "raw_geih")
dir.create(RAW_DIR, showWarnings = FALSE, recursive = TRUE)

# Load URL manifest
manifest <- fromJSON(file.path(DATA_DIR, "geih_download_urls.json"))
cat(sprintf("URL manifest loaded: %d years\n", length(manifest)))

months_es <- c("Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
               "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre")

# Variables to keep from Ocupados module
keep_vars_upper <- c(
  "AREA", "DPTO", "P6040", "P6020", "P6210", "P6210S1",
  "P6430", "P6440", "P6450", "P6460", "P6426",
  "P6870",
  "P6500", "P6510",
  "P6800",
  "P6424S1", "P6424S2", "P6424S3",
  "P6630S1", "P6630S2", "P6630S3",
  "P6920",
  "P6090",
  "RAMA4D", "RAMA2D"
)

# Function to download and extract one month
process_month <- function(year, month_idx, url_info) {
  rds_path <- file.path(RAW_DIR, sprintf("ocupados_%s_%02d.rds", year, month_idx))

  # Skip if already processed
  if (file.exists(rds_path)) {
    cat(sprintf("  [cached] %s/%02d\n", year, month_idx))
    return(readRDS(rds_path))
  }

  download_url <- url_info$url
  filename <- url_info$filename

  zip_path <- file.path(RAW_DIR, sprintf("geih_%s_%02d.zip", year, month_idx))

  cat(sprintf("  Downloading %s %s...", year, months_es[month_idx]))

  tryCatch({
    resp <- GET(download_url,
                write_disk(zip_path, overwrite = TRUE),
                timeout(300),
                config(followlocation = TRUE))

    if (status_code(resp) != 200) {
      cat(sprintf(" FAILED (HTTP %d)\n", status_code(resp)))
      unlink(zip_path)
      stop(sprintf("HTTP %d for %s/%02d", status_code(resp), year, month_idx))
    }

    fsize <- file.info(zip_path)$size
    cat(sprintf(" %.1f MB...", fsize / 1e6))

    # List zip contents and find Ocupados
    zip_contents <- unzip(zip_path, list = TRUE)$Name
    ocupados_files <- grep("Ocupados", zip_contents, value = TRUE, ignore.case = TRUE)

    # Prefer .sav files, then .csv, then .txt
    sav_files <- grep("\\.sav$", ocupados_files, value = TRUE, ignore.case = TRUE)
    csv_files <- grep("\\.csv$", ocupados_files, value = TRUE, ignore.case = TRUE)
    txt_files <- grep("\\.txt$", ocupados_files, value = TRUE, ignore.case = TRUE)

    # Among each type, prefer "Area" (combined geographic domain)
    pick_best <- function(files) {
      area <- grep("Area|area", files, value = TRUE)
      if (length(area) > 0) return(area[1])
      cab <- grep("Cabecera|cabecera", files, value = TRUE)
      if (length(cab) > 0) return(cab[1])
      if (length(files) > 0) return(files[1])
      return(NULL)
    }

    target <- pick_best(sav_files)
    file_type <- "sav"
    if (is.null(target)) {
      target <- pick_best(csv_files)
      file_type <- "csv"
    }
    if (is.null(target)) {
      target <- pick_best(txt_files)
      file_type <- "txt"
    }

    if (is.null(target)) {
      cat(" no Ocupados file found!\n")
      stop(sprintf("No Ocupados module in %s/%02d. Contents: %s",
                    year, month_idx, paste(head(zip_contents, 10), collapse = ", ")))
    }

    sav_file <- target
    exdir <- file.path(RAW_DIR, sprintf("tmp_%s_%02d", year, month_idx))
    dir.create(exdir, showWarnings = FALSE, recursive = TRUE)
    unzip(zip_path, files = sav_file, exdir = exdir)

    extracted <- file.path(exdir, sav_file)
    if (!file.exists(extracted)) {
      # Try extracting all and finding it
      unzip(zip_path, exdir = exdir)
      extracted <- file.path(exdir, sav_file)
      if (!file.exists(extracted)) {
        # Search recursively
        all_extracted <- list.files(exdir, recursive = TRUE, full.names = TRUE)
        match_files <- grep("Ocupados", all_extracted, value = TRUE, ignore.case = TRUE)
        sav_match <- grep("\\.sav$", match_files, value = TRUE, ignore.case = TRUE)
        if (length(sav_match) > 0) {
          extracted <- sav_match[1]
          file_type <- "sav"
        } else if (length(match_files) > 0) {
          extracted <- match_files[1]
          file_type <- ifelse(grepl("\\.csv$", extracted, ignore.case = TRUE), "csv", "txt")
        } else {
          stop(sprintf("Cannot find Ocupados after full extraction. Files: %s",
                        paste(basename(all_extracted), collapse = ", ")))
        }
      }
    }

    # Read file based on type
    if (file_type == "sav") {
      df <- haven::read_sav(extracted)
    } else {
      # Try tab-delimited first, then auto-detect
      df <- data.table::fread(extracted, encoding = "Latin-1")
    }
    df <- as.data.table(df)
    names(df) <- toupper(names(df))

    # Add identifiers
    df[, YEAR := as.integer(year)]
    df[, MONTH := as.integer(month_idx)]

    # Find weight variable
    weight_cols <- grep("^FEX", names(df), value = TRUE)
    if (length(weight_cols) > 0 && !"FEX_C18" %in% names(df)) {
      setnames(df, weight_cols[1], "FEX_C18")
    }

    # Keep only needed variables (plus any available)
    avail <- intersect(c(keep_vars_upper, "YEAR", "MONTH", "FEX_C18"), names(df))
    df <- df[, ..avail]

    # Cleanup
    unlink(exdir, recursive = TRUE)
    unlink(zip_path)

    # Save processed month
    saveRDS(df, rds_path)
    cat(sprintf(" %s rows\n", format(nrow(df), big.mark = ",")))

    return(df)

  }, error = function(e) {
    cat(sprintf(" ERROR: %s\n", e$message))
    unlink(zip_path)
    stop(e)  # Fail loudly — no silent fallback
  })
}

# ---- Main download loop ----
all_data <- list()
years <- sort(names(manifest))

for (yr in years) {
  cat(sprintf("\n=== GEIH %s ===\n", yr))
  month_data <- manifest[[yr]]
  month_keys <- sort(names(month_data))

  for (mk in month_keys) {
    m_idx <- as.integer(mk)
    url_info <- month_data[[mk]]
    result <- process_month(yr, m_idx, url_info)
    all_data[[paste(yr, m_idx, sep = "_")]] <- result
  }
}

if (length(all_data) == 0) {
  stop("FATAL: No GEIH data downloaded. Cannot proceed.")
}

# ---- Combine ----
cat("\nCombining all months...\n")

# Strip haven labels for consistent binding across SPSS and text file sources
strip_labels <- function(dt) {
  for (col in names(dt)) {
    if (inherits(dt[[col]], "haven_labelled")) {
      # Preserve underlying type (numeric stays numeric, character stays character)
      dt[[col]] <- unclass(dt[[col]])
      attr(dt[[col]], "labels") <- NULL
      attr(dt[[col]], "label") <- NULL
      attr(dt[[col]], "format.spss") <- NULL
    }
  }
  dt
}
all_data <- lapply(all_data, strip_labels)

geih <- rbindlist(all_data, use.names = TRUE, fill = TRUE)

cat(sprintf("Total observations: %s\n", format(nrow(geih), big.mark = ",")))
cat(sprintf("Years: %s\n", paste(sort(unique(geih$YEAR)), collapse = ", ")))
cat(sprintf("\nMonth coverage:\n"))
print(table(geih$YEAR, geih$MONTH))

# Validate required variables exist
required_vars <- c("P6500", "P6870", "P6440", "P6920", "P6424S1")
missing <- setdiff(required_vars, names(geih))
if (length(missing) > 0) {
  stop(sprintf("FATAL: Required variables missing from combined data: %s",
               paste(missing, collapse = ", ")))
}

# Check benefit variables
cat("\nBenefit variable coverage:\n")
for (v in c("P6424S1", "P6424S2", "P6424S3", "P6920")) {
  if (v %in% names(geih)) {
    cat(sprintf("  %s: %s non-NA (%.1f%%)\n", v,
                format(sum(!is.na(geih[[v]])), big.mark = ","),
                100 * mean(!is.na(geih[[v]]))))
  } else {
    cat(sprintf("  %s: NOT FOUND\n", v))
  }
}

# Save combined dataset
combined_path <- file.path(DATA_DIR, "geih_ocupados_2010_2016.rds")
saveRDS(geih, combined_path)
cat(sprintf("\nSaved: %s (%.1f MB)\n", combined_path,
            file.size(combined_path) / 1e6))

cat("\n=== Data fetch complete ===\n")
