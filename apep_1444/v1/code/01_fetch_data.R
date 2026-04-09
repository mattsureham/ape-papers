# 01_fetch_data.R — Download ENEMDU quarterly microdata from INEC Ecuador
# Source: ecuadorencifras.gob.ec (public open data)

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# --- ENEMDU quarterly CSV open-data download URLs ---
# URL patterns vary by year. We try multiple patterns per quarter.
# Focus on 2019-2023 (post-MMA reform, quarterly format available)

quarter_labels <- c("I", "II", "III", "IV")
quarter_months_2022 <- c(
  "Trimestre-enero-marzo",
  "Trimestre-abril-junio",
  "Trimestre-julio-septiembre",
  "Trimestre-octubre-diciembre"
)

base_url <- "https://www.ecuadorencifras.gob.ec/documentos/web-inec/EMPLEO"

# Build list of candidate URLs for each year-quarter
build_urls <- function(year, q) {
  ql <- quarter_labels[q]
  qm <- quarter_months_2022[q]
  fname <- paste0("2_BDD_DATOS_ABIERTOS_ENEMDU_", year, "_", ql, "_TRIMESTRE_CSV.zip")
  # Also try SPSS if CSV fails
  fname_spss <- paste0("1_BDD_ENEMDU_", year, "_", ql, "_TRIMESTRE_SPSS.zip")

  urls <- c(
    # 2023+ pattern: Trimestre_I/
    paste0(base_url, "/", year, "/Trimestre_", ql, "/", fname),
    # 2022 pattern: Trimestre-enero-marzo-YYYY/
    paste0(base_url, "/", year, "/", qm, "-", year, "/", fname),
    # Alternative: Trimestre-enero_marzo-YYYY
    paste0(base_url, "/", year, "/", gsub("-", "_", qm), "-", year, "/", fname),
    # SPSS versions (same folder patterns)
    paste0(base_url, "/", year, "/Trimestre_", ql, "/", fname_spss),
    paste0(base_url, "/", year, "/", qm, "-", year, "/", fname_spss)
  )
  return(urls)
}

# Download function with multiple URL attempts
download_quarter <- function(year, q) {
  dest_csv <- file.path(data_dir, paste0("enemdu_", year, "_Q", q, ".zip"))
  if (file.exists(dest_csv)) {
    cat(sprintf("  Already have %d Q%d, skipping.\n", year, q))
    return(dest_csv)
  }

  urls <- build_urls(year, q)
  for (url in urls) {
    cat(sprintf("  Trying: %s\n", basename(url)))
    tryCatch({
      resp <- httr::GET(url, httr::write_disk(dest_csv, overwrite = TRUE),
                        httr::timeout(120))
      if (httr::status_code(resp) == 200 && file.size(dest_csv) > 10000) {
        cat(sprintf("  SUCCESS: %d Q%d (%.1f MB)\n", year, q,
                    file.size(dest_csv) / 1e6))
        return(dest_csv)
      } else {
        file.remove(dest_csv)
      }
    }, error = function(e) {
      if (file.exists(dest_csv)) file.remove(dest_csv)
    })
  }
  cat(sprintf("  FAILED: %d Q%d — no working URL found.\n", year, q))
  return(NULL)
}

# Download 2019-2023, all quarters
cat("=== Downloading ENEMDU quarterly microdata ===\n")
downloaded <- list()
for (year in 2019:2023) {
  for (q in 1:4) {
    cat(sprintf("\n%d Q%d:\n", year, q))
    result <- download_quarter(year, q)
    if (!is.null(result)) {
      downloaded[[paste0(year, "_Q", q)]] <- result
    }
  }
}

cat(sprintf("\n=== Downloaded %d of 20 quarters ===\n", length(downloaded)))

if (length(downloaded) < 4) {
  stop("FATAL: Fewer than 4 quarters downloaded. Cannot proceed with RDD analysis.")
}

# --- Unzip and read all downloaded files ---
cat("\n=== Reading and stacking microdata ===\n")

read_quarter <- function(zipfile, year, q) {
  tmpdir <- file.path(tempdir(), paste0("enemdu_", year, "_Q", q))
  dir.create(tmpdir, showWarnings = FALSE, recursive = TRUE)
  # Use system unzip to handle non-UTF8 filenames
  system2("unzip", args = c("-o", "-q", shQuote(zipfile), "-d", shQuote(tmpdir)),
          stdout = FALSE, stderr = FALSE)

  # Find the data file (CSV or SAV)
  csvfiles <- list.files(tmpdir, pattern = "\\.csv$", full.names = TRUE, recursive = TRUE)
  savfiles <- list.files(tmpdir, pattern = "\\.sav$", full.names = TRUE, recursive = TRUE)

  if (length(csvfiles) > 0) {
    # Pick the largest CSV (main person-level file)
    sizes <- file.size(csvfiles)
    mainfile <- csvfiles[which.max(sizes)]
    cat(sprintf("  Reading CSV: %s (%.1f MB)\n", basename(mainfile), max(sizes)/1e6))
    df <- data.table::fread(mainfile, encoding = "Latin-1")
  } else if (length(savfiles) > 0) {
    sizes <- file.size(savfiles)
    mainfile <- savfiles[which.max(sizes)]
    cat(sprintf("  Reading SAV: %s (%.1f MB)\n", basename(mainfile), max(sizes)/1e6))
    df <- as.data.table(haven::read_sav(mainfile))
  } else {
    cat(sprintf("  WARNING: No CSV or SAV found in %s\n", basename(zipfile)))
    return(NULL)
  }

  # Standardize column names to lowercase
  setnames(df, tolower(names(df)))

  # Add year-quarter identifier
  df[, year := year]
  df[, quarter := q]
  df[, yq := paste0(year, "Q", q)]

  # Clean up temp files
  unlink(list.files(tmpdir, full.names = TRUE, recursive = TRUE))

  return(df)
}

all_data <- list()
for (key in names(downloaded)) {
  parts <- strsplit(key, "_Q")[[1]]
  yr <- as.integer(parts[1])
  qt <- as.integer(parts[2])
  cat(sprintf("\nReading %s:\n", key))
  df <- read_quarter(downloaded[[key]], yr, qt)
  if (!is.null(df)) {
    all_data[[key]] <- df
  }
}

# Stack all quarters using rbindlist with fill=TRUE (columns may vary)
cat("\n=== Stacking all quarters ===\n")
# Strip haven labels — convert to numeric or character depending on underlying type
for (i in seq_along(all_data)) {
  for (col in names(all_data[[i]])) {
    v <- all_data[[i]][[col]]
    if (inherits(v, "haven_labelled")) {
      raw <- vctrs::vec_data(v)
      if (is.character(raw)) {
        all_data[[i]][[col]] <- as.character(v)
      } else {
        all_data[[i]][[col]] <- as.double(raw)
      }
    }
  }
}
full_df <- rbindlist(all_data, fill = TRUE, use.names = TRUE)
cat(sprintf("Total observations: %s\n", format(nrow(full_df), big.mark = ",")))
cat(sprintf("Columns: %d\n", ncol(full_df)))
cat(sprintf("Quarters loaded: %d\n", length(all_data)))

# --- Identify key variables ---
# ENEMDU variable names (may vary slightly across years):
# p03 = age, p02 = sex, p01 = household relationship
# p15 = occupation status, condact = economic activity condition
# ingrl = labor income, area = urban/rural
# p10a/p10b = education level, p24 = social security affiliation

# Check which age variable exists
age_vars <- intersect(names(full_df), c("p03", "edad", "age", "p03a"))
cat(sprintf("Age variable candidates: %s\n", paste(age_vars, collapse = ", ")))

# Save raw stacked data
saveRDS(full_df, file.path(data_dir, "enemdu_raw_stacked.rds"))
cat(sprintf("\nSaved: %s (%.1f MB)\n",
            file.path(data_dir, "enemdu_raw_stacked.rds"),
            file.size(file.path(data_dir, "enemdu_raw_stacked.rds")) / 1e6))

cat("\n=== Data fetch complete ===\n")
