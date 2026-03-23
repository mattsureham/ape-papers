# 01_fetch_data.R — Download Companies House bulk data
# Source: https://download.companieshouse.gov.uk/en_output.html
# Monthly CSV snapshot of all ~5M UK companies (dated 2026-03-02)

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

out_file <- file.path(data_dir, "companies_house.csv")

if (!file.exists(out_file)) {
  cat("Downloading Companies House bulk data (part 1 of 7)...\n")

  # Download only part 1 (~69MB) — contains ~700K companies, enough for our analysis
  # We will download multiple parts to ensure coverage of food service + placebo sectors
  # across England and Scotland
  base_url <- "https://download.companieshouse.gov.uk/"

  all_parts <- list()
  for (part in 1:7) {
    part_url <- paste0(base_url, "BasicCompanyData-2026-03-02-part", part, "_7.zip")
    part_zip <- file.path(data_dir, sprintf("ch_part%d.zip", part))

    cat(sprintf("Downloading part %d/7...\n", part))
    tryCatch({
      download.file(part_url, part_zip, mode = "wb", quiet = FALSE)

      if (file.size(part_zip) < 1e6) {
        stop("Downloaded file too small — likely error page")
      }

      # Unzip
      unzip(part_zip, exdir = data_dir)
      csv_files <- list.files(data_dir, pattern = sprintf("part%d.*\\.csv$", part),
                              full.names = TRUE, ignore.case = TRUE)

      # If no part-specific CSV, look for any new CSV
      if (length(csv_files) == 0) {
        csv_files <- list.files(data_dir, pattern = "BasicCompanyData.*\\.csv$",
                                full.names = TRUE)
      }

      if (length(csv_files) > 0) {
        cat(sprintf("  Reading %s...\n", basename(csv_files[1])))
        part_dt <- fread(csv_files[1], fill = TRUE, na.strings = "")
        all_parts[[part]] <- part_dt
        cat(sprintf("  Part %d: %d rows, %d cols\n", part, nrow(part_dt), ncol(part_dt)))
        unlink(csv_files)
      }
      unlink(part_zip)
    }, error = function(e) {
      cat(sprintf("  Error on part %d: %s\n", part, e$message))
    })
  }

  if (length(all_parts) == 0) {
    stop("FATAL: Could not download any Companies House data. Cannot proceed.")
  }

  # Combine all parts
  dt <- rbindlist(all_parts, fill = TRUE)
  cat(sprintf("Total companies: %s\n", format(nrow(dt), big.mark = ",")))
  cat(sprintf("Columns: %s\n", paste(names(dt), collapse = ", ")))

  # Save combined data
  fwrite(dt, out_file)
  cat(sprintf("Saved to %s (%.1f MB)\n", out_file, file.size(out_file) / 1e6))

} else {
  cat("Companies House data already present.\n")
  dt <- fread(out_file, nrows = 5)
  cat(sprintf("Columns: %s\n", paste(names(dt), collapse = ", ")))
}

cat("Data fetch complete.\n")
