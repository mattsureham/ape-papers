## =============================================================================
## 01a_fetch_qcew.R — Fetch BLS QCEW County Employment Data
## =============================================================================

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

cat("Fetching BLS QCEW data...\n")

options(timeout = 300)  # 5 minute timeout per file

qcew_all <- list()
years <- 2005:2023

for (yr in years) {
  qcew_file <- file.path(data_dir, paste0("qcew_annual_", yr, ".csv"))

  if (!file.exists(qcew_file)) {
    url <- paste0("https://data.bls.gov/cew/data/files/", yr,
                  "/csv/", yr, "_annual_singlefile.zip")
    zip_file <- file.path(data_dir, paste0("qcew_", yr, ".zip"))

    cat("  Downloading QCEW", yr, "...\n")
    dl_result <- tryCatch({
      download.file(url, zip_file, mode = "wb", quiet = TRUE)
      TRUE
    }, error = function(e) {
      cat("    Failed:", e$message, "\n")
      FALSE
    })

    if (dl_result && file.exists(zip_file) && file.size(zip_file) > 1000) {
      tryCatch({
        csv_name <- unzip(zip_file, list = TRUE)$Name[1]
        unzip(zip_file, exdir = data_dir, overwrite = TRUE)
        extracted <- file.path(data_dir, csv_name)

        # Read and filter — these files are large (~500MB each)
        dt <- fread(extracted, select = c(
          "area_fips", "own_code", "industry_code", "agglvl_code",
          "annual_avg_estabs", "annual_avg_emplvl", "annual_avg_wkly_wage",
          "total_annual_wages"
        ))

        # Keep: private ownership (5), county level (70-78), target industries
        dt <- dt[own_code == 5 &
                   agglvl_code %in% c(70, 71, 72, 73, 74, 75, 76, 77, 78) &
                   industry_code %in% c("10", "72", "56", "52", "54")]
        dt[, year := yr]

        fwrite(dt, qcew_file)
        cat("    QCEW", yr, "saved:", nrow(dt), "rows\n")

        file.remove(extracted)
        file.remove(zip_file)
      }, error = function(e) {
        cat("    Error processing QCEW", yr, ":", e$message, "\n")
      })
    }
  } else {
    cat("  QCEW", yr, "already exists\n")
  }

  if (file.exists(qcew_file)) {
    qcew_all[[as.character(yr)]] <- fread(qcew_file)
  }
}

qcew <- rbindlist(qcew_all, fill = TRUE)
cat("\nQCEW data combined:", nrow(qcew), "rows,", n_distinct(qcew$area_fips), "areas,",
    n_distinct(qcew$year), "years\n")

fwrite(qcew, file.path(data_dir, "qcew_combined.csv"))

# Validation
stopifnot("QCEW must cover 50+ areas" = n_distinct(qcew$area_fips) >= 50)
stopifnot("QCEW must cover 10+ years" = n_distinct(qcew$year) >= 10)
cat("QCEW validation passed.\n")
