# 01_fetch_data.R — Fetch CMS Nursing Home data
# Sources: CMS Provider Data Catalog (public, no auth)

source("00_packages.R")
setwd("../")  # Move from code/ to paper root

cat("=== Fetching CMS Nursing Home Data ===\n")

# ---- Helper: get CSV download URL from CMS metastore ----
get_cms_download_url <- function(dataset_id) {
  meta_url <- paste0(
    "https://data.cms.gov/provider-data/api/1/metastore/schemas/dataset/items/",
    dataset_id
  )
  resp <- request(meta_url) |>
    req_timeout(30) |>
    req_retry(max_tries = 3) |>
    req_perform()
  meta <- resp_body_json(resp)
  dl_url <- meta$distribution[[1]]$downloadURL
  cat("  Dataset:", dataset_id, "-> URL obtained\n")
  return(dl_url)
}

# ---- Helper: download CSV with validation ----
download_cms_csv <- function(dataset_id, filename) {
  filepath <- file.path("data", filename)
  if (file.exists(filepath)) {
    cat("  Already downloaded:", filename, "\n")
    df <- fread(filepath)
    cat("  Rows:", nrow(df), "\n")
    return(df)
  }

  url <- get_cms_download_url(dataset_id)
  cat("  Downloading", filename, "...\n")

  resp <- request(url) |>
    req_timeout(300) |>
    req_retry(max_tries = 3) |>
    req_perform()

  writeBin(resp_body_raw(resp), filepath)
  df <- fread(filepath)
  cat("  Downloaded:", nrow(df), "rows\n")
  stopifnot("Download returned empty dataset" = nrow(df) > 0)
  return(df)
}

# ---- Helper: safe download (returns NULL on failure) ----
safe_download <- function(dataset_id, filename) {
  tryCatch(
    download_cms_csv(dataset_id, filename),
    error = function(e) {
      cat("  WARNING: Failed to download", filename, ":", conditionMessage(e), "\n")
      return(NULL)
    }
  )
}

# ---- 1. Health Deficiencies (r5ix-sfxw) — CRITICAL ----
cat("\n[1/4] Health Deficiencies...\n")
deficiencies <- download_cms_csv("r5ix-sfxw", "health_deficiencies.csv")
stopifnot("Deficiency data is required" = nrow(deficiencies) > 0)

# ---- 2. Provider Information (4pq5-n9py) — CRITICAL ----
cat("\n[2/4] Provider Information...\n")
providers <- download_cms_csv("4pq5-n9py", "provider_info.csv")
stopifnot("Provider data is required" = nrow(providers) > 0)

# ---- 3. Penalties — try multiple IDs ----
cat("\n[3/4] Penalties...\n")
penalties <- safe_download("g6vv-ecyk", "penalties.csv")
if (is.null(penalties)) {
  cat("  Trying alternative penalty dataset ID...\n")
  penalties <- safe_download("zvkn-s6rn", "penalties.csv")
}
if (is.null(penalties)) {
  cat("  Penalties data unavailable - proceeding without it (not critical)\n")
}

# ---- 4. Quality Measures (MDS) ----
cat("\n[4/4] Quality Measures...\n")
quality <- safe_download("djen-97ju", "quality_measures.csv")
if (is.null(quality)) {
  cat("  Trying alternative QM dataset ID...\n")
  quality <- safe_download("xcdc-v8bm", "quality_measures.csv")
}

# ---- Explore column names for key datasets ----
cat("\n=== Column Inventory ===\n")

cat("\nDeficiency columns:\n")
cat(paste(names(deficiencies), collapse = "\n"), "\n")

cat("\nProvider columns:\n")
cat(paste(names(providers), collapse = "\n"), "\n")

if (!is.null(penalties)) {
  cat("\nPenalty columns:\n")
  cat(paste(names(penalties), collapse = "\n"), "\n")
}

if (!is.null(quality)) {
  cat("\nQuality columns:\n")
  cat(paste(names(quality)[1:min(30, ncol(quality))], collapse = "\n"), "\n")
}

# ---- Quick data exploration ----
cat("\n=== Data Exploration ===\n")

# Deficiency severity codes
sev_col <- grep("scope|severity", names(deficiencies), ignore.case = TRUE, value = TRUE)
cat("\nSeverity column(s):", paste(sev_col, collapse = ", "), "\n")
if (length(sev_col) > 0) {
  cat("Severity distribution:\n")
  print(table(deficiencies[[sev_col[1]]]))
}

# Survey dates
date_col <- grep("survey.*date", names(deficiencies), ignore.case = TRUE, value = TRUE)
if (length(date_col) > 0) {
  cat("\nSurvey date range:\n")
  dates <- as.Date(deficiencies[[date_col[1]]], tryFormats = c("%Y-%m-%d", "%m/%d/%Y"))
  cat("  Min:", as.character(min(dates, na.rm = TRUE)), "\n")
  cat("  Max:", as.character(max(dates, na.rm = TRUE)), "\n")
}

# Provider state distribution
state_col <- grep("^state$", names(providers), ignore.case = TRUE, value = TRUE)
if (length(state_col) > 0) {
  cat("\nFacilities by state (top 10):\n")
  print(head(sort(table(providers[[state_col[1]]]), decreasing = TRUE), 10))
}

# Staffing columns
staff_cols <- grep("staff|hour|hprd|nurse|rn|lpn|cna", names(providers), ignore.case = TRUE, value = TRUE)
cat("\nStaffing columns:\n")
cat(paste(staff_cols, collapse = "\n"), "\n")

# Chain/ownership columns
chain_cols <- grep("chain|owner|affili", names(providers), ignore.case = TRUE, value = TRUE)
cat("\nChain/ownership columns:\n")
cat(paste(chain_cols, collapse = "\n"), "\n")

cat("\n=== Fetch Complete ===\n")
cat("  Deficiencies:", nrow(deficiencies), "records\n")
cat("  Providers:", nrow(providers), "records\n")
cat("  Penalties:", ifelse(is.null(penalties), "unavailable", nrow(penalties)), "\n")
cat("  Quality:", ifelse(is.null(quality), "unavailable", nrow(quality)), "\n")

# Save metadata for downstream scripts
saveRDS(list(
  has_penalties = !is.null(penalties),
  has_quality = !is.null(quality),
  n_deficiencies = nrow(deficiencies),
  n_providers = nrow(providers)
), "data/fetch_metadata.rds")
