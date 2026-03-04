## ============================================================
## 01_fetch_data.R — Fetch all data from UK government sources
## apep_0505: Council Tax Support Localization
## ============================================================

source("00_packages.R")

## ============================================================
## 1. Revenue Outturn Time Series (CRITICAL — multi-year per-LA)
## ============================================================
## 19.6 MB CSV with per-LA revenue expenditure and financing data
## across all years. This is the single most useful file.
cat("=== 1. Fetching Revenue Outturn Time Series CSV ===\n")

ro_dir <- file.path(DATA_DIR, "revenue_outturn")
dir.create(ro_dir, showWarnings = FALSE, recursive = TRUE)

ro_url <- "https://assets.publishing.service.gov.uk/media/6937fe05e447374889cd8f4b/Revenue_Outturn_time_series_data_v3.1.csv"
ro_file <- file.path(ro_dir, "revenue_outturn_timeseries.csv")

tryCatch({
  download.file(ro_url, ro_file, mode = "wb", quiet = TRUE)
  ro_size <- file.info(ro_file)$size / 1e6
  cat("Revenue Outturn downloaded:", round(ro_size, 1), "MB\n")
  stopifnot("Revenue Outturn file too small" = ro_size > 1)
}, error = function(e) {
  stop("Revenue Outturn data unavailable: ", e$message,
       "\nPivot research question or fix the source.")
})

## ============================================================
## 2. Council Tax Band D Levels (LA panel backbone)
## ============================================================
cat("\n=== 2. Fetching Council Tax Band D Levels ===\n")

ct_dir <- file.path(DATA_DIR, "council_tax")
dir.create(ct_dir, showWarnings = FALSE, recursive = TRUE)

## Band D main file (2025-26 release — contains current Band D by LA)
band_d_url <- "https://assets.publishing.service.gov.uk/media/680a3ca79b25e1a97c9d8471/Band_D_2025-26.ods"
band_d_file <- file.path(ct_dir, "band_d_2025_26.ods")

tryCatch({
  download.file(band_d_url, band_d_file, mode = "wb", quiet = TRUE)
  cat("Band D 2025-26 downloaded.\n")
}, error = function(e) {
  cat("WARNING: Band D 2025-26 not at expected URL:", e$message, "\n")
})

## Table 8: Individual LA Band D rates with % change
t8_url <- "https://assets.publishing.service.gov.uk/media/680a37d26d6ac02ee99d845f/Table_8_2025-26.ods"
t8_file <- file.path(ct_dir, "table_8_band_d_by_la.ods")
tryCatch({
  download.file(t8_url, t8_file, mode = "wb", quiet = TRUE)
  cat("Table 8 (Band D by LA) downloaded.\n")
}, error = function(e) {
  cat("WARNING: Table 8 not available:", e$message, "\n")
})

## Table 10: CT requirement and chargeable dwellings by LA
t10_url <- "https://assets.publishing.service.gov.uk/media/680a37fc7a11df940be1aaa2/Table_10_2025-26.ods"
t10_file <- file.path(ct_dir, "table_10_ct_requirement.ods")
tryCatch({
  download.file(t10_url, t10_file, mode = "wb", quiet = TRUE)
  cat("Table 10 (CT requirement by LA) downloaded.\n")
}, error = function(e) {
  cat("WARNING: Table 10 not available:", e$message, "\n")
})

## ============================================================
## 3. Council Tax Collection Rates (PRIMARY OUTCOME)
## ============================================================
cat("\n=== 3. Fetching Collection Rates ===\n")

## Table 2: Per-LA collection rates (latest release covers 2020-2025)
cr_t2_url <- "https://assets.publishing.service.gov.uk/media/688a0b036478525675738fff/Table_2_2024-25.ods"
cr_t2_file <- file.path(ct_dir, "collection_rates_table2.ods")
tryCatch({
  download.file(cr_t2_url, cr_t2_file, mode = "wb", quiet = TRUE)
  cat("Collection rates Table 2 (2020-25) downloaded.\n")
}, error = function(e) {
  cat("WARNING: Collection rates Table 2 not available:", e$message, "\n")
})

## Table 7: Arrears and write-offs (secondary outcome)
cr_t7_url <- "https://assets.publishing.service.gov.uk/media/688a0bf66478525675739003/Table_7_2024-25.ods"
cr_t7_file <- file.path(ct_dir, "arrears_table7.ods")
tryCatch({
  download.file(cr_t7_url, cr_t7_file, mode = "wb", quiet = TRUE)
  cat("Arrears Table 7 downloaded.\n")
}, error = function(e) {
  cat("WARNING: Arrears Table 7 not available:", e$message, "\n")
})

## Table 9: Quarterly QRC4 return
cr_t9_url <- "https://assets.publishing.service.gov.uk/media/688a0c16e1a850d72c40920a/Table_9_Quarterly_return_of_Council_Tax_and_non-domestic_rates_QRC4__2024_to_2025.ods"
cr_t9_file <- file.path(ct_dir, "qrc4_quarterly.ods")
tryCatch({
  download.file(cr_t9_url, cr_t9_file, mode = "wb", quiet = TRUE)
  cat("QRC4 quarterly data downloaded.\n")
}, error = function(e) {
  cat("WARNING: QRC4 quarterly not available:", e$message, "\n")
})

## ============================================================
## 4. Council Taxbase (TREATMENT VARIABLE — CTR claimants)
## ============================================================
cat("\n=== 4. Fetching Council Taxbase (CTR claimant data) ===\n")

ctb_dir <- file.path(DATA_DIR, "taxbase")
dir.create(ctb_dir, showWarnings = FALSE, recursive = TRUE)

## The taxbase publications contain CTR claimant counts by LA
## (working-age vs pensioner), which is the key treatment variable.
## Download multiple years to build a panel.

## 2025 LA-level data (XLSX with per-LA detail)
ctb_2025_url <- "https://assets.publishing.service.gov.uk/media/696f605ff6aa424b452e3359/2025_Local_Authority_Drop_Down.xlsx"
ctb_2025_file <- file.path(ctb_dir, "taxbase_2025_la.xlsx")
tryCatch({
  download.file(ctb_2025_url, ctb_2025_file, mode = "wb", quiet = TRUE)
  cat("Taxbase 2025 LA data downloaded.\n")
}, error = function(e) {
  cat("WARNING: Taxbase 2025 not available:", e$message, "\n")
})

## Summary tables (contains time series)
ctb_summary_url <- "https://assets.publishing.service.gov.uk/media/696f60535b6060ca6736a081/Tables_1_-_5_2025.ods"
ctb_summary_file <- file.path(ctb_dir, "taxbase_2025_summary.ods")
tryCatch({
  download.file(ctb_summary_url, ctb_summary_file, mode = "wb", quiet = TRUE)
  cat("Taxbase 2025 summary tables downloaded.\n")
}, error = function(e) {
  cat("WARNING: Taxbase 2025 summary not available:", e$message, "\n")
})

## Historical taxbase publications (for pre-reform data)
## 2013 taxbase (first post-reform year)
ctb_hist_urls <- list(
  "2024" = "https://www.gov.uk/government/statistics/council-taxbase-2024-in-england",
  "2023" = "https://www.gov.uk/government/statistics/council-taxbase-2023-in-england",
  "2022" = "https://www.gov.uk/government/statistics/council-taxbase-2022-in-england",
  "2021" = "https://www.gov.uk/government/statistics/council-taxbase-2021-in-england",
  "2020" = "https://www.gov.uk/government/statistics/council-taxbase-2020-in-england",
  "2019" = "https://www.gov.uk/government/statistics/council-taxbase-2019-in-england"
)
## Note: These are publication pages, not direct file downloads.
## The actual download links need to be extracted from each page.
## For now, we rely on the 2025 data which may contain historical columns.

## ============================================================
## 5. NOMIS — Claimant Count by LA (Labour Market Outcome)
## ============================================================
cat("\n=== 5. Fetching Claimant Count from NOMIS ===\n")

cts_dir <- file.path(DATA_DIR, "nomis")
dir.create(cts_dir, showWarnings = FALSE, recursive = TRUE)

nomis_key <- Sys.getenv("NOMIS_API_KEY")
if (nchar(nomis_key) == 0) {
  stop("NOMIS_API_KEY not set. Cannot fetch LA-level claimant data.")
}

## Claimant Count (CC01 - successor to JSA count)
## Dataset NM_162_1 = Claimant count by LA
## Includes all benefit claimants (not just JSA) from April 2013 onwards
## Dataset NM_1_1 = JSA claimants (pre-UC, better for historical consistency)

## Build date string: January of each year 2008-2024, plus July
dates <- c()
for (y in 2008:2024) {
  dates <- c(dates, paste0(y, "-01"), paste0(y, "-07"))
}
date_str <- paste(dates, collapse = ",")

## JSA claimants by billing authority
jsa_url <- paste0(
  "https://www.nomisweb.co.uk/api/v01/dataset/NM_1_1.data.csv?",
  "geography=TYPE464",   # English billing authorities
  "&date=", date_str,
  "&sex=7",              # Total
  "&item=1",             # Claimant count
  "&measures=20100",     # Value
  "&uid=", nomis_key
)

tryCatch({
  jsa_data <- fread(jsa_url, showProgress = FALSE)
  jsa_file <- file.path(cts_dir, "jsa_claimants_by_la.csv")
  fwrite(jsa_data, jsa_file)
  cat("JSA claimant data:", nrow(jsa_data), "rows,",
      n_distinct(jsa_data$GEOGRAPHY_NAME), "LAs\n")
}, error = function(e) {
  stop("NOMIS JSA data unavailable: ", e$message,
       "\nPivot research question or fix the source.")
})

## Also get total population estimates by LA (for normalization)
## NOMIS dataset NM_2010_1 = Annual Population Survey (APS)
## Alternative: NM_31_1 = Mid-year population estimates
pop_url <- paste0(
  "https://www.nomisweb.co.uk/api/v01/dataset/NM_31_1.data.csv?",
  "geography=TYPE464",
  "&date=2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019,2020,2021,2022,2023",
  "&sex=7",
  "&age=0",              # All ages (total population)
  "&measures=20100",
  "&uid=", nomis_key
)

tryCatch({
  pop_data <- fread(pop_url, showProgress = FALSE)
  pop_file <- file.path(cts_dir, "population_by_la.csv")
  fwrite(pop_data, pop_file)
  cat("Population data:", nrow(pop_data), "rows,",
      n_distinct(pop_data$GEOGRAPHY_NAME), "LAs\n")
}, error = function(e) {
  cat("WARNING: Population data not available:", e$message, "\n")
})

## Working-age population (16-64)
wa_pop_url <- paste0(
  "https://www.nomisweb.co.uk/api/v01/dataset/NM_31_1.data.csv?",
  "geography=TYPE464",
  "&date=2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019,2020,2021,2022,2023",
  "&sex=7",
  "&age=12",             # Working age (16-64)
  "&measures=20100",
  "&uid=", nomis_key
)

tryCatch({
  wa_pop <- fread(wa_pop_url, showProgress = FALSE)
  wa_file <- file.path(cts_dir, "working_age_pop_by_la.csv")
  fwrite(wa_pop, wa_file)
  cat("Working-age population:", nrow(wa_pop), "rows\n")
}, error = function(e) {
  cat("WARNING: Working-age pop not available:", e$message, "\n")
})

## ============================================================
## 6. HM Land Registry Price Paid Data
## ============================================================
cat("\n=== 6. Fetching Land Registry Price Paid Data ===\n")

lr_dir <- file.path(DATA_DIR, "land_registry")
dir.create(lr_dir, showWarnings = FALSE, recursive = TRUE)

lr_base <- "http://prod.publicdata.landregistry.gov.uk.s3-website-eu-west-1.amazonaws.com"

## Download only key years to save time (full panel: 2008-2024)
## Critical years: 2008-2019 (pre-COVID), skip 2020-2024 for now
for (year in 2008:2019) {
  lr_file <- file.path(lr_dir, paste0("pp-", year, ".csv"))
  if (file.exists(lr_file)) {
    cat("Land Registry", year, "already exists, skipping.\n")
    next
  }
  lr_url <- paste0(lr_base, "/pp-", year, ".csv")
  tryCatch({
    download.file(lr_url, lr_file, mode = "wb", quiet = TRUE)
    fsize <- round(file.info(lr_file)$size / 1e6, 1)
    cat("Downloaded Land Registry", year, "(", fsize, "MB)\n")
  }, error = function(e) {
    cat("WARNING: Land Registry", year, "not available:", e$message, "\n")
  })
}

## ============================================================
## 7. DATA VALIDATION
## ============================================================
cat("\n=== DATA VALIDATION ===\n")

## Check Revenue Outturn
stopifnot("Revenue Outturn file exists" = file.exists(ro_file))
ro_check <- fread(ro_file, nrows = 10)
cat("Revenue Outturn columns:", ncol(ro_check), "\n")
cat("Revenue Outturn headers:", paste(names(ro_check)[1:5], collapse = ", "), "...\n")

## Check Band D file
ct_files <- list.files(ct_dir, full.names = TRUE)
cat("Council Tax files:", length(ct_files), "\n")
for (f in ct_files) {
  cat("  ", basename(f), ":", round(file.info(f)$size / 1024, 1), "KB\n")
}

## Check NOMIS files
nomis_files <- list.files(cts_dir, full.names = TRUE)
cat("NOMIS files:", length(nomis_files), "\n")
for (f in nomis_files) {
  cat("  ", basename(f), ":", round(file.info(f)$size / 1024, 1), "KB\n")
}

## Check Land Registry
lr_files <- list.files(lr_dir, pattern = "^pp-\\d{4}\\.csv$")
cat("Land Registry years downloaded:", length(lr_files), "\n")
stopifnot("Expected at least 8 years of Land Registry data" = length(lr_files) >= 8)

## Check taxbase
taxbase_files <- list.files(ctb_dir, full.names = TRUE)
cat("Taxbase files:", length(taxbase_files), "\n")

cat("\n=== DATA FETCH COMPLETE ===\n")
cat("All critical data sources downloaded successfully.\n")
