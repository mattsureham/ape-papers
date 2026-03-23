## 01d_fetch_anaf.R — Fetch ANAF financial statement data from data.gov.ro
source("00_packages.R")

# The ANAF "Situatii financiare" datasets contain firm-level financial data
# including turnover (cifra de afaceri) for all registered firms in Romania

# ---- 1. Discover all available ANAF financial statement datasets ----
cat("=== Discovering ANAF financial statement datasets ===\n")

years_to_try <- 2008:2023
dataset_info <- list()

for (yr in years_to_try) {
  # Try both naming conventions
  names_to_try <- c(
    paste0("situatii_financiare_", yr),
    paste0("situatii-financiare-", yr),
    paste0("situatii_financiare", yr)
  )

  for (nm in names_to_try) {
    url <- paste0("https://data.gov.ro/api/3/action/package_show?id=", nm)
    resp <- tryCatch({
      httr_resp <- httr::GET(url, httr::timeout(15))
      if (httr::status_code(httr_resp) == 200) {
        parsed <- jsonlite::fromJSON(httr::content(httr_resp, as = "text", encoding = "UTF-8"))
        if (parsed$success) {
          resources <- parsed$result$resources
          cat(yr, ": Found! (", nm, ") -", nrow(resources), "resources\n")
          for (i in seq_len(min(5, nrow(resources)))) {
            cat("  ", resources$name[i], ":", resources$format[i],
                "->", substr(resources$url[i], 1, 100), "\n")
          }
          dataset_info[[as.character(yr)]] <- list(
            name = nm,
            resources = resources
          )
          break
        }
      }
    }, error = function(e) NULL)
  }
}

cat("\n=== Found datasets for years:", paste(names(dataset_info), collapse = ", "), "===\n")

# ---- 2. Download the most relevant years for our analysis ----
# Key years for threshold changes:
# 2015 (pre-expansion, threshold = 65K EUR)
# 2016 (threshold raised to 100K, rate changes)
# 2017 (threshold raised to 500K)
# 2018 (threshold raised to 1M)
# 2019 (stable at 1M)
# 2020 (mandatory for eligible)
# 2022 (pre-contraction)
# 2023 (threshold dropped to 500K)

# Download CSV/zip files for available years
target_years <- c("2015", "2016", "2017", "2018", "2019", "2020", "2021", "2022", "2023")

for (yr in target_years) {
  if (!yr %in% names(dataset_info)) {
    cat("Year", yr, "not found on data.gov.ro\n")
    next
  }

  resources <- dataset_info[[yr]]$resources
  # Look for CSV or ZIP resources
  csv_idx <- which(grepl("csv|CSV|zip|ZIP", resources$format, ignore.case = TRUE))
  if (length(csv_idx) == 0) csv_idx <- 1  # Take first available

  for (idx in csv_idx[1:min(1, length(csv_idx))]) {
    dl_url <- resources$url[idx]
    ext <- tolower(tools::file_ext(dl_url))
    if (ext == "") ext <- tolower(resources$format[idx])
    dest <- paste0("../data/anaf_", yr, ".", ext)

    cat("Downloading", yr, "from", substr(dl_url, 1, 80), "...\n")
    tryCatch({
      download.file(dl_url, dest, mode = "wb", quiet = TRUE)
      fsize <- file.size(dest) / 1e6
      cat("  Downloaded:", round(fsize, 1), "MB\n")
    }, error = function(e) {
      cat("  Download error:", e$message, "\n")
    })
  }
}

# ---- 3. Also try INS TEMPO for turnover-based enterprise counts ----
cat("\n=== Trying INS TEMPO for turnover size classes ===\n")

# The TEMPO API uses a specific query structure
# Let me try to get the dimensions for INT101B and related matrices
matrices_to_try <- c("INT101B", "INT103I", "INT101A", "INT102A", "INT104A")

for (mat in matrices_to_try) {
  url <- paste0("http://statistici.insse.ro:8077/tempo-ins/matrix/", mat, "?lang=en")
  tryCatch({
    resp <- httr::GET(url, httr::timeout(15))
    if (httr::status_code(resp) == 200) {
      parsed <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
      cat("\n", mat, ":", parsed$matrixName, "\n")
      if (!is.null(parsed$dimensionsMap)) {
        dims <- parsed$dimensionsMap
        for (d in names(dims)) {
          cat("  Dim:", d, "-", length(dims[[d]]$options), "options\n")
          if (length(dims[[d]]$options) < 20) {
            opts <- sapply(dims[[d]]$options, function(x) x$label)
            cat("    ", paste(head(opts, 10), collapse = "; "), "\n")
          }
        }
      }
    }
  }, error = function(e) {
    cat(mat, "error:", e$message, "\n")
  })
}

cat("\n=== ANAF data fetch complete ===\n")
