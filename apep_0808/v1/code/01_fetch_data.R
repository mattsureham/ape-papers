## ── 01_fetch_data.R ───────────────────────────────────────────────────────────
## Data acquisition for apep_0808
## Sources: IRS Auto-Revocation List, IRS Exempt Organizations BMF
## ──────────────────────────────────────────────────────────────────────────────

source("code/00_packages.R")

cat("=== DATA ACQUISITION FOR APEP_0808 ===\n")
cat("IRS Automatic Revocation Shock\n\n")

## ── 1. Download IRS Auto-Revocation List ─────────────────────────────────────
revocation_url <- "https://apps.irs.gov/pub/epostcard/data-download-revocation.zip"
revocation_zip <- "data/revocation.zip"
revocation_txt <- "data/data-download-revocation.txt"

if (!file.exists(revocation_txt)) {
  cat("Downloading IRS Auto-Revocation List...\n")
  dl <- tryCatch(
    download.file(revocation_url, revocation_zip, mode = "wb", quiet = FALSE),
    error = function(e) stop(sprintf("FATAL: Cannot download: %s", conditionMessage(e)))
  )
  if (dl != 0) stop("FATAL: Download failed")
  unzip(revocation_zip, exdir = "data/")
}

stopifnot("Revocation file must exist" = file.exists(revocation_txt))
cat("Revocation file present.\n")

## ── 2. Parse revocation data ─────────────────────────────────────────────────
## Pipe-delimited, no header, first 2 lines blank
## Fields: EIN | Name | DBA | Address | City | State | ZIP | Country |
##         Subsection | Revocation_Date | Revocation_Posting_Date | Exemption_Type
cat("Parsing revocation data...\n")

rev_raw <- fread(
  revocation_txt,
  sep = "|",
  header = FALSE,
  skip = 2,  # skip blank lines
  col.names = c("ein", "org_name", "dba", "address", "city", "state",
                "zip", "country", "subsection", "revocation_date",
                "revocation_posting_date", "exemption_type"),
  strip.white = TRUE
)

## Remove any completely empty rows
rev_raw <- rev_raw[nchar(ein) > 0]

cat(sprintf("Revocation records loaded: %s rows\n",
            format(nrow(rev_raw), big.mark = ",")))

## Parse dates
rev_raw[, rev_date := as.Date(revocation_date, format = "%d-%b-%Y")]
rev_raw[, rev_post_date := as.Date(revocation_posting_date, format = "%d-%b-%Y")]
rev_raw[, rev_year := year(rev_date)]

cat("Revocations by year:\n")
print(rev_raw[, .N, by = rev_year][order(rev_year)])

## ── 3. Download IRS BMF ─────────────────────────────────────────────────────
bmf_base_url <- "https://www.irs.gov/pub/irs-soi/"
bmf_files <- paste0("eo", 1:4, ".csv")

for (bmf_file in bmf_files) {
  local_path <- file.path("data", bmf_file)
  if (!file.exists(local_path)) {
    cat(sprintf("Downloading BMF %s...\n", bmf_file))
    bmf_url <- paste0(bmf_base_url, bmf_file)
    dl <- tryCatch(
      download.file(bmf_url, local_path, mode = "wb", quiet = FALSE),
      error = function(e) {
        cat(sprintf("WARNING: %s failed: %s\n", bmf_file, conditionMessage(e)))
        return(1)
      }
    )
  } else {
    cat(sprintf("BMF %s already present.\n", bmf_file))
  }
}

## ── 4. Load BMF data ─────────────────────────────────────────────────────────
cat("\nLoading BMF data...\n")
bmf_list <- list()
for (bmf_file in bmf_files) {
  local_path <- file.path("data", bmf_file)
  if (file.exists(local_path)) {
    bmf_list[[bmf_file]] <- tryCatch(
      fread(local_path, header = TRUE),
      error = function(e) {
        cat(sprintf("WARNING: Error reading %s: %s\n", bmf_file, conditionMessage(e)))
        return(NULL)
      }
    )
  }
}

bmf <- rbindlist(bmf_list, fill = TRUE)
cat(sprintf("BMF records loaded: %s rows\n", format(nrow(bmf), big.mark = ",")))
cat("BMF columns: ", paste(names(bmf), collapse = ", "), "\n")

## ── 5. Save raw data ─────────────────────────────────────────────────────────
saveRDS(rev_raw, "data/revocation_raw.rds")
saveRDS(bmf, "data/bmf_raw.rds")

cat("\n=== Data acquisition complete ===\n")
cat(sprintf("Revocation records: %s\n", format(nrow(rev_raw), big.mark = ",")))
cat(sprintf("BMF records: %s\n", format(nrow(bmf), big.mark = ",")))
