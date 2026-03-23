## 01_fetch_data.R — Download MSHA Accidents, Violations, and Mines data
## APEP paper apep_0782: MSHA 2007 Penalty Reform

library(data.table)

cat("=== 01_fetch_data.R: Downloading MSHA data ===\n")

data_dir <- here::here("output", "apep_0782", "v1", "data")
dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)

## --- Download helper ---
fetch_msha <- function(url, destfile) {
  cat(sprintf("Downloading %s ...\n", basename(url)))
  download.file(url, destfile, mode = "wb", quiet = FALSE)
  if (!file.exists(destfile) || file.size(destfile) < 1000) {
    stop(sprintf("FATAL: Download failed for %s — file missing or too small", url))
  }
  cat(sprintf("  OK: %s (%.1f MB)\n", destfile, file.size(destfile) / 1e6))
}

## --- Download ---
urls <- list(
  Accidents  = "https://arlweb.msha.gov/OpenGovernmentData/DataSets/Accidents.zip",
  Violations = "https://arlweb.msha.gov/OpenGovernmentData/DataSets/Violations.zip",
  Mines      = "https://arlweb.msha.gov/OpenGovernmentData/DataSets/Mines.zip"
)

zip_files <- list()
for (nm in names(urls)) {
  dest <- file.path(data_dir, paste0(nm, ".zip"))
  fetch_msha(urls[[nm]], dest)
  zip_files[[nm]] <- dest
}

## --- Unzip and parse ---
parse_msha_zip <- function(zipfile, label) {
  cat(sprintf("Parsing %s ...\n", label))
  tmpdir <- tempfile(pattern = "msha_")
  dir.create(tmpdir)
  unzip(zipfile, exdir = tmpdir)
  # Find the txt file inside
  txt_files <- list.files(tmpdir, pattern = "\\.txt$", full.names = TRUE, recursive = TRUE)
  if (length(txt_files) == 0) {
    stop(sprintf("FATAL: No .txt file found in %s", zipfile))
  }
  # Pick the one matching label, or first one
  target <- txt_files[grepl(tolower(label), tolower(basename(txt_files)))]
  if (length(target) == 0) target <- txt_files[1]
  cat(sprintf("  Reading %s\n", basename(target[1])))
  # MSHA files are pipe-delimited
  dt <- fread(target[1], sep = "|", header = TRUE, fill = TRUE, quote = "")
  cat(sprintf("  Rows: %s, Cols: %d\n", format(nrow(dt), big.mark = ","), ncol(dt)))
  # Clean up
  unlink(tmpdir, recursive = TRUE)
  return(dt)
}

accidents_raw  <- parse_msha_zip(zip_files[["Accidents"]], "Accidents")
violations_raw <- parse_msha_zip(zip_files[["Violations"]], "Violations")
mines_raw      <- parse_msha_zip(zip_files[["Mines"]], "Mines")

## --- Basic validation ---
stopifnot("MINE_ID" %in% names(accidents_raw))
stopifnot("MINE_ID" %in% names(violations_raw))
stopifnot("MINE_ID" %in% names(mines_raw))

cat(sprintf("\n=== Data Summary ===\n"))
cat(sprintf("Accidents:  %s rows\n", format(nrow(accidents_raw), big.mark = ",")))
cat(sprintf("Violations: %s rows\n", format(nrow(violations_raw), big.mark = ",")))
cat(sprintf("Mines:      %s rows\n", format(nrow(mines_raw), big.mark = ",")))

## --- Save ---
saveRDS(accidents_raw, file.path(data_dir, "accidents_raw.rds"))
saveRDS(violations_raw, file.path(data_dir, "violations_raw.rds"))
saveRDS(mines_raw, file.path(data_dir, "mines_raw.rds"))

cat("=== 01_fetch_data.R: DONE ===\n")
