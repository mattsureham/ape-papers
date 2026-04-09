# 01_fetch_data.R — Fetch CMS HACRP and supplementary hospital data
# Uses CMS Provider Data API (POST) and direct CSV downloads

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# Helper: CMS Provider Data API fetcher (POST, paginated)
# ============================================================
fetch_cms_dataset <- function(dataset_id, label) {
  cat(sprintf("=== Fetching %s (dataset: %s) ===\n", label, dataset_id))
  base_url <- sprintf(
    "https://data.cms.gov/provider-data/api/1/datastore/query/%s/0",
    dataset_id
  )

  # First request to get count
  resp <- httr::POST(
    base_url,
    httr::content_type_json(),
    body = jsonlite::toJSON(list(limit = 1500, offset = 0), auto_unbox = TRUE)
  )
  if (httr::status_code(resp) != 200) {
    stop(sprintf("FATAL: HTTP %d from CMS for %s", httr::status_code(resp), label))
  }

  parsed <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
  total <- parsed$count
  results <- as.data.table(parsed$results)
  cat(sprintf("  Total records: %d, fetched: %d\n", total, nrow(results)))

  # Paginate
  if (total > 1500) {
    offsets <- seq(1500, total - 1, by = 1500)
    for (off in offsets) {
      resp2 <- httr::POST(
        base_url,
        httr::content_type_json(),
        body = jsonlite::toJSON(list(limit = 1500, offset = off), auto_unbox = TRUE)
      )
      batch <- as.data.table(jsonlite::fromJSON(
        httr::content(resp2, "text", encoding = "UTF-8")
      )$results)
      results <- rbindlist(list(results, batch), fill = TRUE)
      cat(sprintf("    offset %d -> %d rows total\n", off, nrow(results)))
    }
  }

  cat(sprintf("  Final: %d rows, %d cols\n", nrow(results), ncol(results)))
  return(results)
}

# ============================================================
# 1. HACRP Hospital Results (FY2026) — Running variable + penalty
# ============================================================
hacrp <- fetch_cms_dataset("yq43-i98g", "HACRP FY2026")
cat("  Columns:", paste(names(hacrp), collapse = ", "), "\n")
fwrite(hacrp, file.path(data_dir, "hacrp_fy2026.csv"))

# Quick validation
stopifnot(nrow(hacrp) > 2500)
stopifnot("total_hac_score" %in% names(hacrp))
stopifnot("payment_reduction" %in% names(hacrp))
cat("  Penalized hospitals:", sum(hacrp$payment_reduction == "Yes", na.rm = TRUE), "\n")
cat("  Non-penalized:", sum(hacrp$payment_reduction == "No", na.rm = TRUE), "\n")

# ============================================================
# 2. Hospital General Information — covariates (beds, ownership, etc.)
# ============================================================
hosp_info <- fetch_cms_dataset("xubh-q36u", "Hospital General Information")
fwrite(hosp_info, file.path(data_dir, "hospital_info.csv"))

# ============================================================
# 3. Hospital Value-Based Purchasing (HVBP) — Safety domain
# ============================================================
hvbp_safety <- fetch_cms_dataset("dgmq-aat3", "HVBP Safety")
fwrite(hvbp_safety, file.path(data_dir, "hvbp_safety.csv"))

# ============================================================
# 4. Healthcare Associated Infections — Hospital level (SIRs)
# ============================================================
cat("\n=== Fetching HAI Hospital data (direct CSV) ===\n")
hai_url <- "https://data.cms.gov/provider-data/sites/default/files/resources/43825e12dc0c923df9ba5cbdf473c9d5_1770163586/Healthcare_Associated_Infections-Hospital.csv"
hai_dest <- file.path(data_dir, "hai_hospital.csv")
download.file(hai_url, hai_dest, mode = "wb", quiet = TRUE)
hai <- fread(hai_dest)
cat("  HAI records:", nrow(hai), "\n")
cat("  Measures:", paste(unique(hai$`Measure ID`)[1:10], collapse = ", "), "\n")
stopifnot(nrow(hai) > 50000)

# ============================================================
# 5. Overall Hospital Star Ratings
# ============================================================
stars <- tryCatch({
  fetch_cms_dataset("dgck-syfz", "Hospital Star Ratings")
}, error = function(e) {
  cat("  Star ratings not available via API, trying alternative...\n")
  # Try the overall hospital quality star rating dataset
  tryCatch({
    fetch_cms_dataset("44jm-jm7a", "Hospital Star Ratings (alt)")
  }, error = function(e2) {
    cat("  Star ratings unavailable:", e2$message, "\n")
    NULL
  })
})
if (!is.null(stars)) {
  fwrite(stars, file.path(data_dir, "hospital_stars.csv"))
}

# ============================================================
# Summary
# ============================================================
cat("\n=== Data Fetch Complete ===\n")
files <- list.files(data_dir, pattern = "\\.csv$")
for (f in files) {
  sz <- file.size(file.path(data_dir, f))
  cat(sprintf("  %s: %.1f MB\n", f, sz / 1e6))
}
