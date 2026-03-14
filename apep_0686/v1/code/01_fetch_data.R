## 01_fetch_data.R — Download HDT measurement files and PS2 planning statistics
## apep_0686: UK Housing Delivery Test RDD

source("code/00_packages.R")
setwd(here::here())

data_dir <- "data"
dir.create(data_dir, showWarnings = FALSE)

## ---- HDT Measurement Files ----
## Six annual rounds: 2018-2023
## 2018-2019 are XLSX; 2020-2023 are ODS

hdt_urls <- list(
  "2018" = "https://assets.publishing.service.gov.uk/media/5f69f779e90e073fd4e1316b/HDT_2018_measurement.xlsx",
  "2019" = "https://assets.publishing.service.gov.uk/media/5f846dfce90e07703cfe2e4f/Housing_Delivery_Test_2019_Measurement.xlsx",
  "2020" = "https://assets.publishing.service.gov.uk/media/600599988fa8f55f658a1b2d/HDT_2020.ods",
  "2021" = "https://assets.publishing.service.gov.uk/media/61e01d6de90e0703805e295a/2021_HDT_Final_Results_.ods",
  "2022" = "https://assets.publishing.service.gov.uk/media/657c7f1b95bf65000d7190ca/HDT_2022_Publication_output.ods",
  "2023" = "https://assets.publishing.service.gov.uk/media/6759ccfbad4694c785b0eddb/Housing_Delivery_Test_2023_measurement.ods"
)

for (year in names(hdt_urls)) {
  ext <- ifelse(year %in% c("2018", "2019"), "xlsx", "ods")
  dest <- file.path(data_dir, paste0("hdt_", year, ".", ext))
  if (!file.exists(dest)) {
    cat(sprintf("Downloading HDT %s...\n", year))
    resp <- httr::GET(hdt_urls[[year]], httr::write_disk(dest, overwrite = TRUE))
    if (httr::status_code(resp) != 200) {
      stop(sprintf("FATAL: Failed to download HDT %s (HTTP %d). Cannot proceed with simulated data.",
                    year, httr::status_code(resp)))
    }
    cat(sprintf("  -> %s (%s bytes)\n", dest, file.size(dest)))
  } else {
    cat(sprintf("HDT %s already downloaded: %s\n", year, dest))
  }
}

## ---- PS2 Planning Statistics ----
ps2_url <- "https://assets.publishing.service.gov.uk/media/694160c92d5e7e863253752c/PS2_data_-_open_data_table__202509_.csv"
ps2_dest <- file.path(data_dir, "ps2_full.csv")

if (!file.exists(ps2_dest)) {
  cat("Downloading PS2 planning statistics (40 MB)...\n")
  resp <- httr::GET(ps2_url, httr::write_disk(ps2_dest, overwrite = TRUE),
                    httr::progress())
  if (httr::status_code(resp) != 200) {
    stop(sprintf("FATAL: Failed to download PS2 data (HTTP %d). Cannot proceed with simulated data.",
                  httr::status_code(resp)))
  }
  cat(sprintf("  -> %s (%s bytes)\n", ps2_dest, file.size(ps2_dest)))
} else {
  cat(sprintf("PS2 already downloaded: %s\n", ps2_dest))
}

## ---- Validate Downloads ----
cat("\n=== Download Validation ===\n")
for (year in names(hdt_urls)) {
  ext <- ifelse(year %in% c("2018", "2019"), "xlsx", "ods")
  fpath <- file.path(data_dir, paste0("hdt_", year, ".", ext))
  stopifnot(file.exists(fpath))
  cat(sprintf("  HDT %s: %s bytes OK\n", year, file.size(fpath)))
}
stopifnot(file.exists(ps2_dest))
cat(sprintf("  PS2: %s bytes OK\n", file.size(ps2_dest)))
cat("All data files validated.\n")
