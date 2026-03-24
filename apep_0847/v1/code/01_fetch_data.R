# 01_fetch_data.R — Fetch all data for apep_0847
# Stop smoking service austerity and respiratory health in England

source("00_packages.R")
setwd(file.path(dirname(getwd()), "data"))

cat("=== Fetching Fingertips health outcome data ===\n")

# ---- 1. Health outcomes from Fingertips API (direct HTTP) ----
# area_type_id: 202 = upper-tier LAs (UTLAs)

fetch_fingertips <- function(indicator_id, name) {
  cat(sprintf("Fetching %s (indicator %d)...\n", name, indicator_id))
  url <- sprintf(
    "https://fingertips.phe.org.uk/api/all_data/csv/by_indicator_id?indicator_ids=%d&area_type_id=202",
    indicator_id
  )
  tmp <- tempfile(fileext = ".csv")
  resp <- httr::GET(url, httr::user_agent("APEP-Research/1.0"),
                    httr::timeout(60))
  if (httr::status_code(resp) != 200) {
    stop(sprintf("FATAL: Fingertips API returned %d for indicator %d",
                 httr::status_code(resp), indicator_id))
  }
  writeBin(httr::content(resp, "raw"), tmp)
  df <- read_csv(tmp, show_col_types = FALSE, locale = locale(encoding = "UTF-8"))
  cat(sprintf("  -> %d rows, %d areas\n", nrow(df), n_distinct(df$`Area Code`)))
  if (nrow(df) == 0) stop(sprintf("FATAL: No data returned for indicator %d", indicator_id))
  df
}

smoking_prev <- fetch_fingertips(92443, "Smoking prevalence 18+")
quit_rate    <- fetch_fingertips(1211,  "CO-validated quit rate")
copd_admis   <- fetch_fingertips(92302, "COPD emergency admissions 35+")
lung_cancer  <- fetch_fingertips(1203,  "Lung cancer mortality")

# Falsification: sexual health screening
sexual_health <- fetch_fingertips(91735, "Sexual health screening (chlamydia)")

saveRDS(smoking_prev, "smoking_prev_raw.rds")
saveRDS(quit_rate,    "quit_rate_raw.rds")
saveRDS(copd_admis,   "copd_admis_raw.rds")
saveRDS(lung_cancer,  "lung_cancer_raw.rds")
saveRDS(sexual_health, "sexual_health_raw.rds")

cat("\n=== Fetching public health grant allocations ===\n")

# ---- 2. Public health grant allocations (for Bartik instrument) ----
download_safe <- function(url, dest) {
  resp <- httr::GET(url, httr::user_agent("APEP-Research/1.0"),
                    httr::timeout(60))
  if (httr::status_code(resp) != 200) {
    stop(sprintf("FATAL: HTTP %d for %s", httr::status_code(resp), dest))
  }
  writeBin(httr::content(resp, "raw"), dest)
  cat(sprintf("  -> saved %s (%d bytes)\n", dest, file.size(dest)))
}

# XLSX files (earlier years)
xlsx_urls <- list(
  "grant_2016_17.xlsx" = "https://assets.publishing.service.gov.uk/media/5a814e4bed915d74e6231873/Public_health_allocations_2016_to_2017.xlsx",
  "grant_2017_18.xlsx" = "https://assets.publishing.service.gov.uk/media/5a749af540f0b616bcb17d6d/2017-18_allocations.xlsx",
  "grant_2018_19.xlsx" = "https://assets.publishing.service.gov.uk/media/5a74f23a40f0b6399b2af71b/Public_health_allocations_2018-19_and_indicative_allocations_2019-20.xlsx"
)

for (f in names(xlsx_urls)) {
  cat(sprintf("Downloading %s...\n", f))
  download_safe(xlsx_urls[[f]], f)
}

# ODS files (later years)
ods_urls <- list(
  "grant_2019_20.ods" = "https://assets.publishing.service.gov.uk/media/5c1b7eb2e5274a4685bfbb3c/Public_health_local_authority_allocations_2019_to_2020.ods",
  "grant_2020_21.ods" = "https://assets.publishing.service.gov.uk/media/5e6f50e3e90e070ad0e629d2/2020-21_Public_Health_Allocations.ods",
  "grant_2021_22.ods" = "https://assets.publishing.service.gov.uk/media/604f749ee90e077fed2a38a1/public-health-local-authority-allocations-2021-to-2022.ods",
  "grant_2022_23.ods" = "https://assets.publishing.service.gov.uk/media/61f024afd3bf7f054db93930/public-health-local-authority-allocations-2022-to-2023.ods"
)

for (f in names(ods_urls)) {
  cat(sprintf("Downloading %s...\n", f))
  download_safe(ods_urls[[f]], f)
}

# ---- 3. Public health spending by service line (RO3 outturn data) ----
# Try PLDR for pre-compiled spending data
cat("\n=== Fetching PLDR spending data ===\n")
pldr_url <- "https://pldr.org/api/3/action/package_show?id=local-authority-finance-public-health-services-individual-spendi-2nxz3"
tryCatch({
  resp <- httr::GET(pldr_url, httr::user_agent("APEP-Research/1.0"),
                    httr::timeout(30))
  if (httr::status_code(resp) == 200) {
    pkg <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
    resources <- pkg$result$resources
    cat("PLDR resources found:\n")
    for (i in seq_len(nrow(resources))) {
      cat(sprintf("  [%d] %s (%s)\n", i, resources$name[i], resources$format[i]))
    }
    # Download all CSV resources
    for (i in seq_len(nrow(resources))) {
      if (grepl("csv", resources$format[i], ignore.case = TRUE)) {
        fn <- sprintf("pldr_%s.csv", gsub("[^a-zA-Z0-9]", "_", resources$name[i]))
        tryCatch({
          download_safe(resources$url[i], fn)
        }, error = function(e) cat(sprintf("  -> skipped: %s\n", e$message)))
      }
    }
  } else {
    cat(sprintf("PLDR API returned %d\n", httr::status_code(resp)))
  }
}, error = function(e) {
  cat(sprintf("PLDR fetch failed: %s — will use grant allocations as proxy.\n", e$message))
})

cat("\n=== All data fetched ===\n")
cat("Files in data/:\n")
cat(paste(list.files("."), collapse = "\n"), "\n")
