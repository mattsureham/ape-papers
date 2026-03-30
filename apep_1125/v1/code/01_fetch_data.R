## 01_fetch_data.R — Fetch all data for apep_1125
## UK Breathing Space moratorium and personal insolvency

source("00_packages.R")

data_dir <- "data"
dir.create(data_dir, showWarnings = FALSE)

# ============================================================================
# 1. England & Wales insolvencies by LA, 2015-2025
#    Source: Insolvency Service, Individual Insolvencies by Location
# ============================================================================
cat("=== Fetching E/W LA-level insolvency data (2015-2025) ===\n")

ew_url <- "https://assets.publishing.service.gov.uk/media/69c526f9471d520038d0f6b6/Data_Tables_in_Excel_xlsx_Format_-_Individual_insolvencies_by_Location_England_and_Wales_2015_to_2025.xlsx"
ew_file <- file.path(data_dir, "ew_insolvency_location_2015_2025.xlsx")

if (!file.exists(ew_file)) {
  resp <- httr::GET(ew_url, httr::write_disk(ew_file, overwrite = TRUE))
  stopifnot("Failed to download E/W insolvency location data" = httr::status_code(resp) == 200)
  cat("  Downloaded:", file.info(ew_file)$size, "bytes\n")
} else {
  cat("  Already on disk.\n")
}

# ============================================================================
# 2. Quarterly insolvency statistics (includes Scotland + NI national totals)
#    Source: Insolvency Service Q4 2023 publication
# ============================================================================
cat("=== Fetching quarterly insolvency data (includes Scotland) ===\n")

qtr_url <- "https://assets.publishing.service.gov.uk/media/65bb8620cc6fd600145dbe3a/Data_Tables_in_Excel__xlsx__Format_-_Individual_Insolvency_Statistics_October_to_December_2023.xlsx"
qtr_file <- file.path(data_dir, "quarterly_insolvency_2023q4.xlsx")

if (!file.exists(qtr_file)) {
  resp <- httr::GET(qtr_url, httr::write_disk(qtr_file, overwrite = TRUE))
  stopifnot("Failed to download quarterly insolvency data" = httr::status_code(resp) == 200)
  cat("  Downloaded:", file.info(qtr_file)$size, "bytes\n")
} else {
  cat("  Already on disk.\n")
}

# ============================================================================
# 3. ONS mid-year population estimates by LA (for rate construction)
#    Source: NOMIS NM_2002_1
# ============================================================================
cat("=== Fetching population estimates from NOMIS ===\n")

nomis_key <- Sys.getenv("NOMIS_API_KEY", "")
nomis_base <- "https://www.nomisweb.co.uk/api/v01/"

# Adult population (aged 18+) by LA
pop_url <- paste0(
  nomis_base,
  "dataset/NM_2002_1.data.csv?",
  "geography=TYPE464&",
  "date=2015,2016,2017,2018,2019,2020,2021,2022,2023&",
  "gender=0&",
  "c_age=201&",
  "measures=20100&",
  "select=date_name,geography_name,geography_code,obs_value"
)
if (nchar(nomis_key) > 0) pop_url <- paste0(pop_url, "&uid=", nomis_key)

pop_file <- file.path(data_dir, "population_adult_la.csv")
if (!file.exists(pop_file)) {
  resp <- httr::GET(pop_url, httr::write_disk(pop_file, overwrite = TRUE))
  stopifnot("Failed to download adult population data" = httr::status_code(resp) == 200)
  cat("  Downloaded:", file.info(pop_file)$size, "bytes\n")
} else {
  cat("  Already on disk.\n")
}

# ============================================================================
# 4. Claimant count by LA (January each year, unemployment control)
#    Source: NOMIS NM_162_1
# ============================================================================
cat("=== Fetching claimant count data from NOMIS ===\n")

cc_url <- paste0(
  nomis_base,
  "dataset/NM_162_1.data.csv?",
  "geography=TYPE464&",
  "date=2015-01,2016-01,2017-01,2018-01,2019-01,2020-01,2021-01,2022-01,2023-01&",
  "gender=0&",
  "age=0&",
  "measure=1&",
  "measures=20100&",
  "select=date_name,geography_name,geography_code,obs_value"
)
if (nchar(nomis_key) > 0) cc_url <- paste0(cc_url, "&uid=", nomis_key)

cc_file <- file.path(data_dir, "claimant_count_la.csv")
if (!file.exists(cc_file)) {
  resp <- httr::GET(cc_url, httr::write_disk(cc_file, overwrite = TRUE))
  stopifnot("Failed to download claimant count data" = httr::status_code(resp) == 200)
  cat("  Downloaded:", file.info(cc_file)$size, "bytes\n")
} else {
  cat("  Already on disk.\n")
}

cat("\n=== All data fetched ===\n")
cat("Files:\n")
for (f in list.files(data_dir)) {
  cat(sprintf("  %-50s %s bytes\n", f, file.info(file.path(data_dir, f))$size))
}
