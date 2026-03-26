# 01_fetch_data.R — Fetch MAGyP Estimaciones Agrícolas data
# Source: datos.magyp.gob.ar — Argentine Ministry of Agriculture
# APEP Working Paper apep_0992

source("code/00_packages.R")

# --- Download MAGyP crop production data ---
# This is the department-level crop estimates dataset
url <- "https://datos.magyp.gob.ar/reportes/estimaciones"
csv_file <- "data/magyp_estimaciones.csv"

if (!file.exists(csv_file)) {
  cat("Downloading MAGyP Estimaciones Agrícolas...\n")

  # Try the direct CSV download endpoint
  # MAGyP data portal provides CSV exports
  download_urls <- c(
    "https://datosestimaciones.magyp.gob.ar/reportes/reporte-estimaciones?format=csv",
    "https://datos.magyp.gob.ar/dataset/estimaciones-agricolas/archivo/estimaciones-agricolas-csv",
    "https://datosestimaciones.magyp.gob.ar/reportes/reporte_estimaciones.csv"
  )

  success <- FALSE
  for (u in download_urls) {
    cat("Trying:", u, "\n")
    tryCatch({
      download.file(u, csv_file, mode = "wb", quiet = FALSE, timeout = 120)
      if (file.info(csv_file)$size > 1000) {
        success <- TRUE
        cat("Download successful from:", u, "\n")
        break
      } else {
        file.remove(csv_file)
      }
    }, error = function(e) {
      cat("Failed:", conditionMessage(e), "\n")
    })
  }

  if (!success) {
    # Use the CKAN API for datos.gob.ar / datos.magyp.gob.ar
    # The dataset "estimaciones-agricolas" should be accessible
    ckan_url <- "https://datos.magyp.gob.ar/api/3/action/package_show?id=estimaciones-agricolas"
    cat("Trying CKAN API:", ckan_url, "\n")
    tryCatch({
      resp <- jsonlite::fromJSON(ckan_url)
      resources <- resp$result$resources
      csv_resources <- resources[grepl("csv", resources$format, ignore.case = TRUE), ]
      if (nrow(csv_resources) > 0) {
        dl_url <- csv_resources$url[1]
        cat("Found CSV resource:", dl_url, "\n")
        download.file(dl_url, csv_file, mode = "wb", quiet = FALSE, timeout = 120)
        if (file.info(csv_file)$size > 1000) {
          success <- TRUE
          cat("Download successful via CKAN\n")
        }
      }
    }, error = function(e) {
      cat("CKAN API failed:", conditionMessage(e), "\n")
    })
  }

  if (!success) {
    stop("FATAL: Could not download MAGyP data from any endpoint. Cannot proceed with simulated data.")
  }
}

# --- Read and validate ---
cat("Reading MAGyP data...\n")
raw <- fread(csv_file, encoding = "Latin-1")
cat("Dimensions:", nrow(raw), "rows x", ncol(raw), "columns\n")
cat("Column names:", paste(names(raw), collapse = ", "), "\n")

# Validate data is real and substantive
stopifnot("Data has fewer than 1000 rows — likely not real data" = nrow(raw) > 1000)
stopifnot("Data has fewer than 5 columns" = ncol(raw) >= 5)

cat("Data loaded successfully.\n")
cat("Unique crops:", length(unique(raw[[grep("cultivo|crop", names(raw), ignore.case = TRUE)[1]]])), "\n")

# Save raw data info
cat("File size:", file.info(csv_file)$size, "bytes\n")

saveRDS(raw, "data/magyp_raw.rds")
cat("Saved raw data to data/magyp_raw.rds\n")
