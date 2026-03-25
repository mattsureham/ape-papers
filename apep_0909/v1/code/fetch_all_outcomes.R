# fetch_all_outcomes.R — Download ALL outcomes open data XLSX files (2015-2024)
# These are the definitive source: force × offence × outcome × quarter

library(httr)

data_dir <- "../data"

# From the police-recorded-crime-open-data-tables page
# All are XLSX format, quarterly, force × offence × outcome type
urls <- list(
  list(
    url = "https://assets.publishing.service.gov.uk/media/67163746720eec5582849b24/prc-outcomes-open-data-mar2015-tables-241024.xlsx",
    name = "outcomes_2014_15.xlsx"
  ),
  list(
    url = "https://assets.publishing.service.gov.uk/media/669fad34fc8e12ac3edb027e/prc-outcomes-open-data-mar2016-tables-240724.xlsx",
    name = "outcomes_2015_16.xlsx"
  ),
  list(
    url = "https://assets.publishing.service.gov.uk/media/669fad6bce1fd0da7b592b16/prc-outcomes-open-data-mar2017-tables-240724.xlsx",
    name = "outcomes_2016_17.xlsx"
  ),
  list(
    url = "https://assets.publishing.service.gov.uk/media/669ce6dbfc8e12ac3edb008e/prc-outcomes-open-data-mar2018-tables-240724.xlsx",
    name = "outcomes_2017_18.xlsx"
  ),
  list(
    url = "https://assets.publishing.service.gov.uk/media/669fadacab418ab055592b35/prc-outcomes-open-data-mar2019-tables-240724.xlsx",
    name = "outcomes_2018_19.xlsx"
  ),
  list(
    url = "https://assets.publishing.service.gov.uk/media/669fadfcab418ab055592b37/prc-outcomes-open-data-mar2020-tables-240724.xlsx",
    name = "outcomes_2019_20.xlsx"
  ),
  list(
    url = "https://assets.publishing.service.gov.uk/media/669a4db5ce1fd0da7b5928f5/prc-outcomes-open-data-mar2021-tables-240724.xlsx",
    name = "outcomes_2020_21.xlsx"
  ),
  list(
    url = "https://assets.publishing.service.gov.uk/media/679a2a13a39e422368d10e20/prc-outcomes-open-data-mar2022-tables-300125.xlsx",
    name = "outcomes_2021_22.xlsx"
  ),
  list(
    url = "https://assets.publishing.service.gov.uk/media/679a2a5adc6d75ae3ddc7bb6/prc-outcomes-open-data-mar2023-tables-300125.xlsx",
    name = "outcomes_2022_23.xlsx"
  ),
  list(
    url = "https://assets.publishing.service.gov.uk/media/679a2a7585c5e43aa3d10e23/prc-outcomes-open-data-mar2024-tables-300125.xlsx",
    name = "outcomes_2023_24.xlsx"
  ),
  list(
    url = "https://assets.publishing.service.gov.uk/media/679a29f8dc6d75ae3ddc7bb5/prc-outcomes-open-data-apr2024-to-sep2024-tables-300125.xlsx",
    name = "outcomes_apr_sep_2024.xlsx"
  ),
  # Also: PFA-level recorded crime (from 2013 onwards) for total crime counts
  list(
    url = "https://assets.publishing.service.gov.uk/media/679a2aa1a39e422368d10e21/prc-pfa-mar2013-onwards-tables-300125.ods",
    name = "prc_pfa_2013_onwards.ods"
  )
)

for (item in urls) {
  fpath <- file.path(data_dir, item$name)
  if (file.exists(fpath) && file.size(fpath) > 10000) {
    cat(sprintf("  Already have: %s (%.1f MB)\n", item$name, file.size(fpath) / 1e6))
    next
  }
  cat(sprintf("  Downloading: %s...", item$name))
  tryCatch({
    resp <- GET(item$url, timeout(300), write_disk(fpath, overwrite = TRUE))
    if (status_code(resp) == 200 && file.size(fpath) > 5000) {
      cat(sprintf(" OK (%.1f MB)\n", file.size(fpath) / 1e6))
    } else {
      cat(sprintf(" FAILED (HTTP %d, %.0f bytes)\n", status_code(resp), file.size(fpath)))
      if (file.exists(fpath)) file.remove(fpath)
    }
  }, error = function(e) cat(sprintf(" ERROR: %s\n", e$message)))
  Sys.sleep(1)
}

# Quick check: what do we have?
cat("\n=== Downloaded files ===\n")
all_files <- list.files(data_dir, pattern = "outcomes_20.*xlsx$", full.names = TRUE)
for (f in sort(all_files)) {
  cat(sprintf("  %s: %.1f MB\n", basename(f), file.size(f) / 1e6))
}
