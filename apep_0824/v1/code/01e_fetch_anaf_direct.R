## 01e_fetch_anaf_direct.R — Direct download of ANAF balance sheet data
source("00_packages.R")

# ---- 1. Get full resource URLs for key years ----
cat("=== Getting full resource URLs from data.gov.ro CKAN ===\n")

get_resource_urls <- function(dataset_name) {
  url <- paste0("https://data.gov.ro/api/3/action/package_show?id=", dataset_name)
  tryCatch({
    resp <- httr::GET(url, httr::timeout(15))
    parsed <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
    if (parsed$success) {
      resources <- parsed$result$resources
      return(resources[, c("name", "format", "url")])
    }
    return(NULL)
  }, error = function(e) {
    cat("Error fetching", dataset_name, ":", e$message, "\n")
    return(NULL)
  })
}

# Focus on key years around threshold changes
# 2015 (pre-reform), 2016-2018 (expansions), 2019-2020 (stable/mandatory), 2022 (pre-contraction), 2023 (contraction)
key_years <- c(2015, 2016, 2017, 2018, 2019, 2022, 2023)

for (yr in key_years) {
  nm <- ifelse(yr == 2023, "situatii_financiare2023", paste0("situatii_financiare_", yr))
  resources <- get_resource_urls(nm)

  if (is.null(resources)) next

  cat("\n=== Year:", yr, "===\n")

  # Find the main balance sheet file (WEB_BL_BS_SL or similar)
  # Priority: CSV > TXT
  bl_idx <- grep("WEB_BL_BS_SL|web_bl_bs_sl|WEB_AN|web_an", resources$name, ignore.case = TRUE)
  if (length(bl_idx) == 0) {
    # For 2022/2023 the naming might be different
    bl_idx <- grep("WEB_VM|WEBASIG|WEB_VS", resources$name, ignore.case = TRUE)
  }

  # Show all CSV/TXT resources for this year
  csv_idx <- grep("csv|txt", resources$format, ignore.case = TRUE)
  for (i in csv_idx) {
    cat("  ", resources$name[i], " (", resources$format[i], ")\n")
    cat("    URL:", resources$url[i], "\n")
  }

  # Download the balance sheet CSV if available
  for (idx in bl_idx) {
    if (grepl("csv", resources$format[idx], ignore.case = TRUE)) {
      dl_url <- resources$url[idx]
      dest <- paste0("../data/anaf_bl_", yr, ".csv")
      cat("\n  Downloading:", resources$name[idx], "\n")
      cat("  From:", dl_url, "\n")

      tryCatch({
        download.file(dl_url, dest, mode = "wb", quiet = FALSE, method = "libcurl")
        fsize <- file.size(dest)
        cat("  Size:", round(fsize / 1e6, 1), "MB\n")

        if (fsize < 1000) {
          # File too small, probably a redirect page
          cat("  WARNING: File too small, checking content...\n")
          content <- readLines(dest, n = 5)
          cat("  First lines:", paste(content, collapse = "\n  "), "\n")

          # Try with curl
          cat("  Retrying with httr::GET...\n")
          resp <- httr::GET(dl_url, httr::timeout(120),
                           httr::write_disk(paste0(dest, ".retry"), overwrite = TRUE))
          cat("  Status:", httr::status_code(resp), "\n")
          retry_size <- file.size(paste0(dest, ".retry"))
          cat("  Retry size:", round(retry_size / 1e6, 1), "MB\n")

          if (retry_size > 1000) {
            file.rename(paste0(dest, ".retry"), dest)
            cat("  Retry succeeded!\n")
          }
        }
      }, error = function(e) {
        cat("  Download error:", e$message, "\n")
      })
      break  # Only need one file per year
    }
  }
}

# ---- 2. Check what we actually got ----
cat("\n=== Downloaded files ===\n")
files <- list.files("../data/", pattern = "anaf_", full.names = TRUE)
for (f in files) {
  fsize <- file.size(f)
  cat(basename(f), ":", round(fsize / 1e6, 2), "MB\n")
  if (fsize > 1000 && fsize < 1e9) {
    # Try to read first few lines
    tryCatch({
      lines <- readLines(f, n = 3)
      cat("  Header:", substr(lines[1], 1, 200), "\n")
    }, error = function(e) {
      cat("  Could not read:", e$message, "\n")
    })
  }
}

cat("\n=== Done ===\n")
