## =============================================================================
## 01_fetch_data.R — Fetch mortality and grant data
## APEP-0498: The Austerity Mortality Gradient
## =============================================================================

source("00_packages.R")

## ---------------------------------------------------------------------------
## 1. Fetch Fingertips API data — Mortality and Treatment Outcomes
## ---------------------------------------------------------------------------
indicators <- c(92432, 91380, 108, 90244, 90245, 40601, 92488)

area_type <- 402  # Upper tier local authorities

fetch_fingertips <- function(ind_id, area_type_id) {
  url <- paste0(
    "https://fingertips.phe.org.uk/api/all_data/csv/by_indicator_id",
    "?indicator_ids=", ind_id,
    "&area_type_id=", area_type_id
  )
  cat(sprintf("  Fetching indicator %d ...", ind_id))

  tmp <- tempfile(fileext = ".csv")
  tryCatch({
    download.file(url, tmp, mode = "wb", quiet = TRUE)
  }, error = function(e) {
    stop(sprintf("Failed to download indicator %d: %s", ind_id, e$message))
  })

  dt <- fread(tmp, showProgress = FALSE)
  unlink(tmp)

  if (nrow(dt) == 0) stop(sprintf("Indicator %d returned 0 rows", ind_id))
  cat(sprintf(" %d rows\n", nrow(dt)))
  dt
}

cat("Fetching Fingertips data...\n")
all_data <- rbindlist(lapply(indicators, fetch_fingertips, area_type_id = area_type),
                      fill = TRUE)

## Keep Persons + England upper-tier LAs
mortality_data <- all_data[
  Sex == "Persons" &
    grepl("^E0[6-9]|^E10", `Area Code`)
]

cat(sprintf("Fingertips: %d rows, %d unique LAs, %d indicators\n",
            nrow(mortality_data),
            uniqueN(mortality_data$`Area Code`),
            uniqueN(mortality_data$`Indicator ID`)))

## ---------------------------------------------------------------------------
## 2. Fetch Public Health Grant Allocations from GOV.UK
## ---------------------------------------------------------------------------
cat("\nFetching public health grant allocations...\n")

## Verified working URLs (March 2026)
grant_urls <- list(
  "2016-17" = list(
    url = "https://assets.publishing.service.gov.uk/media/5a814e4bed915d74e6231873/Public_health_allocations_2016_to_2017.xlsx",
    ext = ".xlsx"
  ),
  "2017-18" = list(
    url = "https://assets.publishing.service.gov.uk/media/5a749af540f0b616bcb17d6d/2017-18_allocations.xlsx",
    ext = ".xlsx"
  ),
  "2018-19" = list(
    url = "https://assets.publishing.service.gov.uk/media/5a74f23a40f0b6399b2af71b/Public_health_allocations_2018-19_and_indicative_allocations_2019-20.xlsx",
    ext = ".xlsx"
  ),
  "2019-20" = list(
    url = "https://assets.publishing.service.gov.uk/media/5c1b7eb2e5274a4685bfbb3c/Public_health_local_authority_allocations_2019_to_2020.ods",
    ext = ".ods"
  ),
  "2020-21" = list(
    url = "https://assets.publishing.service.gov.uk/media/5e6f50e3e90e070ad0e629d2/2020-21_Public_Health_Allocations.ods",
    ext = ".ods"
  ),
  "2021-22" = list(
    url = "https://assets.publishing.service.gov.uk/media/604f749ee90e077fed2a38a1/public-health-local-authority-allocations-2021-to-2022.ods",
    ext = ".ods"
  ),
  "2022-23" = list(
    url = "https://assets.publishing.service.gov.uk/media/61f024afd3bf7f054db93930/public-health-local-authority-allocations-2022-to-2023.ods",
    ext = ".ods"
  ),
  "2023-24" = list(
    url = "https://assets.publishing.service.gov.uk/media/655f4c600c7ec8001195bd38/public_health_local_authority_allocations_2023_to_2024_and_indicative_allocations_2024_to_2025_updated-27-nov-2023.ods",
    ext = ".ods"
  ),
  "2024-25" = list(
    url = "https://assets.publishing.service.gov.uk/media/67eeab66632d0f88e8248cf0/public-health-local-authority-allocations-2024-to-2025-revised-and-uplifted-april-2025.ods",
    ext = ".ods"
  )
)

for (yr in names(grant_urls)) {
  info <- grant_urls[[yr]]
  dest <- file.path(DATA_DIR, paste0("grant_", yr, info$ext))

  if (!file.exists(dest)) {
    cat(sprintf("  Downloading %s ... ", yr))
    tryCatch({
      download.file(info$url, dest, mode = "wb", quiet = TRUE)
      if (file.size(dest) > 100) {
        cat(sprintf("OK (%s bytes)\n", format(file.size(dest), big.mark = ",")))
      } else {
        cat("WARNING: file too small, likely failed\n")
        unlink(dest)
      }
    }, error = function(e) {
      cat(sprintf("FAILED: %s\n", e$message))
    })
  } else {
    cat(sprintf("  %s already exists\n", yr))
  }
}

## ---------------------------------------------------------------------------
## 3. Construct GDP Deflator
## ---------------------------------------------------------------------------
deflator <- data.table(
  year = 2001:2024,
  deflator = c(71.5, 73.3, 75.5, 77.5, 79.3, 81.2, 83.5, 85.8,
               86.4, 87.7, 89.4, 91.0, 92.5, 94.0, 95.0, 96.5,
               97.6, 98.2, 100.0, 101.2, 103.8, 112.4, 119.0, 122.1)
)
fwrite(deflator, file.path(DATA_DIR, "gdp_deflator.csv"))

## ---------------------------------------------------------------------------
## 4. Save raw data
## ---------------------------------------------------------------------------
fwrite(mortality_data, file.path(DATA_DIR, "fingertips_mortality_raw.csv"))

cat("\n=== Data Fetch Complete ===\n")
cat("  Mortality rows:", nrow(mortality_data), "\n")
cat("  Unique LAs:", uniqueN(mortality_data$`Area Code`), "\n")
cat("  Grant files:", sum(file.exists(
  file.path(DATA_DIR, paste0("grant_", names(grant_urls),
                              sapply(grant_urls, `[[`, "ext")))
)), "\n")
