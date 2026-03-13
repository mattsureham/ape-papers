## 01_fetch_data.R — Download Zillow ZHVI and IRS SOI zip-code data
## APEP paper apep_0631

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ── 1. Zillow ZHVI (zip-code level, monthly) ──
zhvi_file <- file.path(data_dir, "zhvi_zip.csv")
if (!file.exists(zhvi_file)) {
  zhvi_url <- "https://files.zillowstatic.com/research/public_csvs/zhvi/Zip_zhvi_uc_sfrcondo_tier_0.33_0.67_sm_sa_month.csv"
  cat("Downloading Zillow ZHVI...\n")
  download.file(zhvi_url, zhvi_file, mode = "wb", quiet = FALSE)
}
stopifnot("Zillow ZHVI download failed" = file.exists(zhvi_file) && file.size(zhvi_file) > 1e6)
cat("ZHVI file size:", round(file.size(zhvi_file) / 1e6, 1), "MB\n")

## ── 2. IRS SOI zip-code income data (tax year 2017 — pre-TCJA) ──
irs_file <- file.path(data_dir, "irs_soi_2017.csv")
if (!file.exists(irs_file)) {
  irs_url <- "https://www.irs.gov/pub/irs-soi/17zpallagi.csv"
  cat("Downloading IRS SOI 2017 zip-code data...\n")
  download.file(irs_url, irs_file, mode = "wb", quiet = FALSE)
}
stopifnot("IRS SOI 2017 download failed" = file.exists(irs_file) && file.size(irs_file) > 1e6)
cat("IRS SOI 2017 file size:", round(file.size(irs_file) / 1e6, 1), "MB\n")

## ── 3. FHFA zip-code HPI (optional robustness outcome) ──
fhfa_file <- file.path(data_dir, "fhfa_zip_hpi.csv")
if (!file.exists(fhfa_file)) {
  fhfa_ok <- tryCatch({
    fhfa_url <- "https://www.fhfa.gov/hpi/download/monthly/hpi_at_bdl_zip.csv"
    cat("Downloading FHFA zip-code HPI...\n")
    download.file(fhfa_url, fhfa_file, mode = "wb", quiet = FALSE)
    TRUE
  }, error = function(e) {
    cat("FHFA download failed:", conditionMessage(e), "\n")
    FALSE
  })
  if (!fhfa_ok || !file.exists(fhfa_file) || file.size(fhfa_file) < 1e5) {
    cat("WARNING: FHFA zip HPI not available — will proceed without robustness outcome.\n")
    if (file.exists(fhfa_file)) file.remove(fhfa_file)
  }
} else {
  cat("FHFA file already exists:", round(file.size(fhfa_file) / 1e6, 1), "MB\n")
}

## ── Validation ──
cat("\n=== Data fetch complete ===\n")
cat("Required files:\n")
cat("  ZHVI:", file.exists(zhvi_file), "\n")
cat("  IRS SOI 2017:", file.exists(irs_file), "\n")
cat("Optional files:\n")
cat("  FHFA HPI:", file.exists(fhfa_file), "\n")
