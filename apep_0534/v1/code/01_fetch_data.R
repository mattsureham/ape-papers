## 01_fetch_data.R — Download PatentsView bulk data + PatEx + EIA
## apep_0534: Green Patent Examiner Leniency IV

source("00_packages.R")

# ── PatentsView bulk downloads from S3 ──────────────────────────────────
PV_BASE <- "https://s3.amazonaws.com/data.patentsview.org/download"

pv_files <- list(
  patent      = "g_patent.tsv.zip",
  examiner    = "g_examiner_not_disambiguated.tsv.zip",
  cpc         = "g_cpc_current.tsv.zip",
  application = "g_application.tsv.zip",
  inventor    = "g_inventor_not_disambiguated.tsv.zip",
  citation    = "g_us_patent_citation.tsv.zip",
  assignee    = "g_assignee_not_disambiguated.tsv.zip"
)

download_pv <- function(key) {
  fname <- pv_files[[key]]
  dest  <- file.path(DATA_DIR, fname)
  tsv   <- file.path(DATA_DIR, sub("\\.zip$", "", fname))

  if (file.exists(tsv)) {
    cat("  Already extracted:", tsv, "\n")
    return(tsv)
  }

  url <- paste0(PV_BASE, "/", fname)
  cat("  Downloading:", key, "(", fname, ") ...\n")

  tryCatch({
    download.file(url, dest, mode = "wb", quiet = TRUE)
  }, error = function(e) {
    stop("Failed to download ", key, ": ", e$message,
         "\nURL: ", url,
         "\nCannot proceed without PatentsView data.")
  })

  cat("  Unzipping:", fname, "...\n")
  unzip(dest, exdir = DATA_DIR)
  unlink(dest)

  stopifnot(file.exists(tsv))
  cat("  Done:", key, "\n")
  return(tsv)
}

# Download core files (patent, examiner, cpc, application first; then larger ones)
cat("=== Downloading PatentsView bulk data ===\n")
core_keys <- c("patent", "examiner", "cpc", "application", "assignee")
for (k in core_keys) download_pv(k)

# Download larger files
cat("\n=== Downloading large files (inventor, citations) ===\n")
download_pv("inventor")
download_pv("citation")

# ── Attempt PatEx download ──────────────────────────────────────────────
# PatEx has the full application universe (including denials/abandonments)
# Try multiple known endpoints
patex_file <- file.path(DATA_DIR, "patex_applications.csv")
patex_available <- FALSE

if (!file.exists(patex_file)) {
  cat("\n=== Attempting PatEx download ===\n")
  patex_urls <- c(
    "https://bulkdata.uspto.gov/data/patent/pair/economics/2023/application_data.csv.zip",
    "https://data.patentsview.org/PatEx/application_data.csv.zip"
  )

  for (purl in patex_urls) {
    cat("  Trying:", purl, "\n")
    tryCatch({
      tmp <- file.path(DATA_DIR, "patex_temp.zip")
      download.file(purl, tmp, mode = "wb", quiet = TRUE, timeout = 120)
      unzip(tmp, exdir = DATA_DIR)
      unlink(tmp)
      # Look for the extracted CSV
      csvs <- list.files(DATA_DIR, pattern = "application.*\\.csv$", full.names = TRUE)
      if (length(csvs) > 0) {
        file.rename(csvs[1], patex_file)
        patex_available <- TRUE
        cat("  PatEx downloaded successfully!\n")
        break
      }
    }, error = function(e) {
      cat("  Failed:", e$message, "\n")
    })
  }

  if (!patex_available) {
    cat("  PatEx not available via bulk download.\n")
    cat("  Proceeding with PatentsView grants-only approach.\n")
    cat("  (Reduced-form examiner leniency design)\n")
  }
} else {
  patex_available <- TRUE
  cat("PatEx already downloaded.\n")
}

# ── EIA State Electricity Profiles ──────────────────────────────────────
cat("\n=== Downloading EIA renewable energy data ===\n")
eia_file <- file.path(DATA_DIR, "eia_renewable.csv")

if (!file.exists(eia_file)) {
  eia_key <- Sys.getenv("EIA_API_KEY", "DEMO_KEY")
  eia_url <- paste0(
    "https://api.eia.gov/v2/electricity/state-electricity-profiles/",
    "source-disposition?api_key=", eia_key,
    "&frequency=annual&data[0]=generation",
    "&facets[source][]=SUN&facets[source][]=WND&facets[source][]=GEO",
    "&facets[source][]=ALL",
    "&start=1990&end=2024",
    "&length=50000"
  )

  tryCatch({
    raw <- jsonlite::fromJSON(eia_url)
    eia_dt <- as.data.table(raw$response$data)
    fwrite(eia_dt, eia_file)
    cat("  EIA data:", nrow(eia_dt), "rows\n")
  }, error = function(e) {
    cat("  EIA download failed (exploratory outcome only):", e$message, "\n")
    cat("  Proceeding without EIA data.\n")
  })
} else {
  eia_dt <- fread(eia_file)
  cat("EIA data already downloaded:", nrow(eia_dt), "rows\n")
}

# ── Save metadata about data availability ───────────────────────────────
meta <- list(
  patex_available = patex_available,
  pv_files = sapply(pv_files, function(f)
    file.exists(file.path(DATA_DIR, sub("\\.zip$", "", f)))),
  eia_available = file.exists(eia_file),
  download_date = Sys.time()
)
saveRDS(meta, file.path(DATA_DIR, "fetch_metadata.rds"))

# ── Validation ──────────────────────────────────────────────────────────
cat("\n=== DATA VALIDATION ===\n")

# Check all core PatentsView files exist
for (k in names(pv_files)) {
  tsv <- file.path(DATA_DIR, sub("\\.zip$", "", pv_files[[k]]))
  if (!file.exists(tsv)) stop("PatentsView ", k, " file not found: ", tsv)
  sz <- file.info(tsv)$size / 1e9
  cat(sprintf("  %s: %.1f GB\n", k, sz))
}

cat("\nPatEx available:", patex_available, "\n")
cat("EIA available:", file.exists(eia_file), "\n")
cat("\nData fetch complete.\n")
