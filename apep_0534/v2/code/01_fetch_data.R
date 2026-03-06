## 01_fetch_data.R — Download PatentsView bulk data (PatEx already fetched via BigQuery)
## apep_0534 v2: Green Patent Examiner Leniency IV (Application-Level)
##
## PatEx application_data (3.6M rows) was downloaded from BigQuery via Python
## and saved as data/patex_applications.parquet. This script downloads
## PatentsView bulk files for CPC codes, citations, and patent metadata.

source("00_packages.R")

# ── Verify PatEx data exists ─────────────────────────────────────────────
patex_file <- file.path(DATA_DIR, "patex_applications.parquet")
if (!file.exists(patex_file)) {
  stop("PatEx data not found at ", patex_file,
       "\nRun the BigQuery download script first.")
}
patex <- read_parquet(patex_file)
setDT(patex)
cat("PatEx applications:", format(nrow(patex), big.mark = ","), "\n")
cat("  ISS:", format(sum(patex$disposal_type == "ISS"), big.mark = ","), "\n")
cat("  ABN:", format(sum(patex$disposal_type == "ABN"), big.mark = ","), "\n")

# ── PatentsView bulk downloads from S3 ──────────────────────────────────
PV_BASE <- "https://s3.amazonaws.com/data.patentsview.org/download"

pv_files <- list(
  cpc      = "g_cpc_current.tsv.zip",
  citation = "g_us_patent_citation.tsv.zip",
  patent   = "g_patent.tsv.zip"
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

cat("\n=== Downloading PatentsView bulk data ===\n")
for (k in names(pv_files)) download_pv(k)

# ── Validation ──────────────────────────────────────────────────────────
cat("\n=== DATA VALIDATION ===\n")

for (k in names(pv_files)) {
  tsv <- file.path(DATA_DIR, sub("\\.zip$", "", pv_files[[k]]))
  if (!file.exists(tsv)) stop("PatentsView ", k, " file not found: ", tsv)
  sz <- file.info(tsv)$size / 1e9
  cat(sprintf("  %s: %.1f GB\n", k, sz))
}

cat("\nPatEx file:", round(file.info(patex_file)$size / 1e6, 1), "MB\n")
cat("Data fetch complete.\n")
