## 01_fetch_data.R — Data acquisition for apep_0717
## Benefit cap reduction (November 2016) and temporary accommodation
## Sources: DWP benefit cap ODS, MHCLG homelessness live tables, NOMIS population

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

safe_download <- function(url, dest, label) {
  if (file.exists(dest)) {
    cat("Already exists:", dest, "\n")
    return(TRUE)
  }
  cat("Downloading", label, "...\n")
  resp <- tryCatch(
    httr2::request(url) |>
      httr2::req_timeout(120) |>
      httr2::req_error(is_error = function(resp) FALSE) |>
      httr2::req_perform(),
    error = function(e) {
      cat("  Network error:", conditionMessage(e), "\n")
      return(NULL)
    }
  )
  if (is.null(resp) || httr2::resp_status(resp) != 200) {
    cat("  FAILED: HTTP", if (!is.null(resp)) httr2::resp_status(resp) else "error", "\n")
    return(FALSE)
  }
  writeBin(httr2::resp_body_raw(resp), dest)
  cat("  Saved:", dest, "(", file.size(dest), "bytes)\n")
  return(TRUE)
}

## =========================================================================
## 1. DWP Benefit Cap Statistics — LA-level capped household counts
## =========================================================================

## May 2017 tables (confirmed URL — first full post-reduction release with LA data)
ok1 <- safe_download(
  "https://assets.publishing.service.gov.uk/media/5a82eb9ded915d74e34043c9/benefit-cap-statistics-to-may-2017-tables.ods",
  file.path(data_dir, "benefit_cap_may2017.ods"),
  "Benefit cap May 2017 tables"
)

## Feb 2019 tables (confirmed URL — covers full period 2013-2019 with LA data)
ok2 <- safe_download(
  "https://assets.publishing.service.gov.uk/media/5cc9afb640f0b64c23bb08aa/benefit-cap-statistics-february-2019-tables.ods",
  file.path(data_dir, "benefit_cap_feb2019.ods"),
  "Benefit cap Feb 2019 tables"
)

if (!ok1 && !ok2) {
  stop("CRITICAL: Could not download any benefit cap data files")
}

## =========================================================================
## 2. MHCLG Temporary Accommodation — LA-level quarterly data
## =========================================================================

## Final P1E release (2018Q1) with historical quarterly TA data by LA
ok3 <- safe_download(
  "https://assets.publishing.service.gov.uk/media/5d00bd40e5274a3d4b416479/Temporary_accommodation2018Q1.xlsx",
  file.path(data_dir, "Temporary_accommodation2018Q1.xlsx"),
  "Temporary accommodation 2018Q1"
)

## England-level time series for context
ok4 <- safe_download(
  "https://assets.publishing.service.gov.uk/media/699d93e2db2401de164d6c17/Statutory_Homelessness_England_Time_Series_202509.ods",
  file.path(data_dir, "homelessness_time_series.ods"),
  "Homelessness time series"
)

## Detailed LA tables (H-CLIC era, 2018Q2+)
ok5 <- safe_download(
  "https://assets.publishing.service.gov.uk/media/699d94c56457311dafbbcbcd/Statutory_Homelessness_Detailed_Local_Authority_Data_202509.ods",
  file.path(data_dir, "hclic_detailed_la.ods"),
  "H-CLIC detailed LA tables"
)

if (!ok3) {
  stop("CRITICAL: Could not download temporary accommodation data")
}

## =========================================================================
## 3. NOMIS — Population estimates by LA (for per-capita rates)
## =========================================================================

cat("Fetching population estimates from NOMIS...\n")
nomis_base <- "https://www.nomisweb.co.uk/api/v01/"

pop_url <- paste0(
  nomis_base,
  "dataset/NM_2002_1.data.csv?",
  "geography=TYPE464&",
  "date=2013-2019&",
  "gender=0&",
  "c_age=200&",
  "measures=20100&",
  "select=DATE_NAME,GEOGRAPHY_NAME,GEOGRAPHY_CODE,OBS_VALUE"
)

pop_path <- file.path(data_dir, "nomis_population.csv")
ok6 <- safe_download(pop_url, pop_path, "NOMIS population estimates")

## =========================================================================
## 4. NOMIS — Claimant counts by LA (control variable)
## =========================================================================

cat("Fetching claimant count data from NOMIS...\n")
claimant_url <- paste0(
  nomis_base,
  "dataset/NM_162_1.data.csv?",
  "geography=TYPE464&",
  "date=2013-01-2019-12&",
  "gender=0&",
  "age=0&",
  "measure=1&",
  "measures=20100&",
  "select=DATE_NAME,GEOGRAPHY_NAME,GEOGRAPHY_CODE,OBS_VALUE"
)

claimant_path <- file.path(data_dir, "nomis_claimants.csv")
ok7 <- safe_download(claimant_url, claimant_path, "NOMIS claimant counts")

## =========================================================================
## 5. Validation
## =========================================================================

cat("\n=== Data Download Summary ===\n")
files <- list.files(data_dir, full.names = TRUE)
for (f in files) {
  cat(sprintf("  %-55s %s bytes\n", basename(f), format(file.size(f), big.mark = ",")))
}

## Check critical files
if (!file.exists(file.path(data_dir, "benefit_cap_may2017.ods")) &&
    !file.exists(file.path(data_dir, "benefit_cap_feb2019.ods"))) {
  stop("CRITICAL: No benefit cap data available")
}
if (!file.exists(file.path(data_dir, "Temporary_accommodation2018Q1.xlsx"))) {
  stop("CRITICAL: No temporary accommodation data available")
}

cat("\n=== All critical data files present ===\n")
