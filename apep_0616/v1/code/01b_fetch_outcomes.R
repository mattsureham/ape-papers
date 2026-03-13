## 01b_fetch_outcomes.R — Download historical crime outcomes data
## Need 2006-2020 for full austerity panel

suppressPackageStartupMessages(library(tidyverse))

data_dir <- "data"

# Historical combined file: 2006-2014
cat("Downloading outcomes 2006-2014 (ODS)...\n")
download.file(
  "https://assets.publishing.service.gov.uk/media/6807a0178c1316be7978e6d5/prc-outcomes-open-data-mar2006-mar2014-tabs.ods",
  file.path(data_dir, "outcomes_2006_2014.ods"), mode = "wb", quiet = TRUE
)

# Individual year files for austerity period
years <- c(2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022)
urls <- c(
  "https://assets.publishing.service.gov.uk/media/6807a0704dd7e0f8897a6195/prc-outcomes-open-data-mar2015-tables-241024.xlsx",
  "https://assets.publishing.service.gov.uk/media/6807a0c13bdfd1243078e6d8/prc-outcomes-open-data-mar2016-tables-240724.xlsx",
  "https://assets.publishing.service.gov.uk/media/6807a0f90324470d6a394e70/prc-outcomes-open-data-mar2017-tables-240724.xlsx",
  "https://assets.publishing.service.gov.uk/media/6807a12b4dd7e0f8897a6196/prc-outcomes-open-data-mar2018-tables-240724.xlsx",
  "https://assets.publishing.service.gov.uk/media/6807a1618c1316be7978e6d7/prc-outcomes-open-data-mar2019-tables-240724.xlsx",
  "https://assets.publishing.service.gov.uk/media/6807a1914dd7e0f8897a6197/prc-outcomes-open-data-mar2020-tables-240724.xlsx",
  "https://assets.publishing.service.gov.uk/media/6880899d77a3acd9f4d0e26c/prc-outcomes-open-data-mar2021-tables-240425.xlsx",
  "https://assets.publishing.service.gov.uk/media/6890c52123e00ee4ad463ebf/prc-outcomes-open-data-mar2022-tables-240725.xlsx"
)

for (i in seq_along(years)) {
  fname <- file.path(data_dir, sprintf("outcomes_%d.xlsx", years[i]))
  cat(sprintf("Downloading outcomes %d...\n", years[i]))
  tryCatch(
    download.file(urls[i], fname, mode = "wb", quiet = TRUE),
    error = function(e) cat("  FAILED:", e$message, "\n")
  )
}

# Summary
cat("\nDownloaded files:\n")
files <- list.files(data_dir, pattern = "outcomes", full.names = TRUE)
for (f in files) {
  cat(sprintf("  %s: %.1f MB\n", basename(f), file.info(f)$size / (1024*1024)))
}
