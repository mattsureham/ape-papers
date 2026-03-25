# fetch_recent.R — Find and download recent Home Office crime outcomes open data
# Need data for 2018/19, 2020/21, 2021/22, 2022/23, 2023/24

library(httr)
library(jsonlite)

data_dir <- "../data"

# ============================================================================
# 1. Search data.gov.uk for all crime outcomes packages
# ============================================================================
cat("=== Searching data.gov.uk for recent crime outcomes ===\n")

# Try broader search
resp <- GET("https://data.gov.uk/api/action/package_search",
            query = list(q = "crime outcomes open data", rows = 50))
results <- fromJSON(content(resp, as = "text", encoding = "UTF-8"))
cat(sprintf("Found %d results\n", results$result$count))

for (i in seq_len(min(20, nrow(results$result$results)))) {
  cat(sprintf("  [%d] %s\n", i, results$result$results$title[i]))
}

# ============================================================================
# 2. Try direct gov.uk publication page URLs
# ============================================================================
cat("\n=== Trying gov.uk publication page URLs ===\n")

# The Home Office publishes crime outcomes statistics annually
# Pattern: gov.uk/government/statistics/crime-outcomes-in-england-and-wales-YEAR-to-YEAR
pub_urls <- c(
  "https://www.gov.uk/government/statistics/crime-outcomes-in-england-and-wales-2018-to-2019",
  "https://www.gov.uk/government/statistics/crime-outcomes-in-england-and-wales-2019-to-2020",
  "https://www.gov.uk/government/statistics/crime-outcomes-in-england-and-wales-2020-to-2021",
  "https://www.gov.uk/government/statistics/crime-outcomes-in-england-and-wales-2021-to-2022",
  "https://www.gov.uk/government/statistics/crime-outcomes-in-england-and-wales-2022-to-2023",
  "https://www.gov.uk/government/statistics/crime-outcomes-in-england-and-wales-2023-to-2024",
  # Alternative URL pattern
  "https://www.gov.uk/government/statistics/crime-outcomes-in-england-and-wales-year-ending-march-2019",
  "https://www.gov.uk/government/statistics/crime-outcomes-in-england-and-wales-year-ending-march-2020",
  "https://www.gov.uk/government/statistics/crime-outcomes-in-england-and-wales-year-ending-march-2021",
  "https://www.gov.uk/government/statistics/crime-outcomes-in-england-and-wales-year-ending-march-2022",
  "https://www.gov.uk/government/statistics/crime-outcomes-in-england-and-wales-year-ending-march-2023",
  "https://www.gov.uk/government/statistics/crime-outcomes-in-england-and-wales-year-ending-march-2024"
)

for (url in pub_urls) {
  resp <- GET(url, config(followlocation = TRUE))
  status <- status_code(resp)
  cat(sprintf("  %s → HTTP %d\n", basename(url), status))
  if (status == 200) {
    # Parse the page to find ODS/CSV download links
    page_content <- content(resp, as = "text", encoding = "UTF-8")
    # Look for attachment download links
    links <- regmatches(page_content,
      gregexpr("https://assets[.]publishing[.]service[.]gov[.]uk/[^\"]+\\.(ods|xlsx|csv)", page_content))[[1]]
    if (length(links) > 0) {
      cat(sprintf("    Found %d download links:\n", length(links)))
      for (link in links) {
        cat(sprintf("      %s\n", link))
      }
    }
  }
  Sys.sleep(0.5)
}

# ============================================================================
# 3. Try the police recorded crime page for recent data
# ============================================================================
cat("\n=== Trying police recorded crime page ===\n")

prc_urls <- c(
  "https://www.gov.uk/government/statistics/police-recorded-crime-open-data-tables",
  "https://www.gov.uk/government/collections/crime-outcomes-in-england-and-wales-statistics"
)

for (url in prc_urls) {
  resp <- GET(url, config(followlocation = TRUE))
  status <- status_code(resp)
  cat(sprintf("  %s → HTTP %d\n", basename(url), status))
  if (status == 200) {
    page_content <- content(resp, as = "text", encoding = "UTF-8")
    links <- regmatches(page_content,
      gregexpr("https://assets[.]publishing[.]service[.]gov[.]uk/[^\"]+\\.(ods|xlsx|csv)", page_content))[[1]]
    if (length(links) > 0) {
      cat(sprintf("    Found %d download links:\n", length(links)))
      for (link in head(links, 20)) {
        cat(sprintf("      %s\n", link))
      }
    }
    # Also check for links to individual year publications
    stat_links <- regmatches(page_content,
      gregexpr("/government/statistics/crime-outcomes[^\"]+", page_content))[[1]]
    if (length(stat_links) > 0) {
      cat(sprintf("    Found %d statistics links:\n", length(stat_links)))
      for (link in head(unique(stat_links), 15)) {
        cat(sprintf("      %s\n", link))
      }
    }
  }
  Sys.sleep(0.5)
}

# ============================================================================
# 4. Try direct download of recent open data files
# ============================================================================
cat("\n=== Trying direct downloads of recent open data ===\n")

# Based on the pattern from earlier files, try common URL patterns
# The 2019/20 file was at a different URL than expected, so let's try multiple patterns
direct_urls <- c(
  # Year ending March 2019 (2018/19)
  "https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/811207/crime-outcomes-open-data-ye-mar-2019.ods",
  "https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/811207/prc-outcomes-open-data-mar2019-tables.ods",
  # Year ending March 2021
  "https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/1003127/prc-outcomes-open-data-mar2021-tables.ods",
  # Year ending March 2022
  "https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/1093574/prc-outcomes-open-data-mar2022-tables.ods",
  # Year ending March 2023
  "https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/1172099/prc-outcomes-open-data-mar2023-tables.ods",
  # Year ending March 2024
  "https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/1369073/prc-outcomes-open-data-mar2024-tables.ods"
)

for (url in direct_urls) {
  fname <- basename(url)
  fpath <- file.path(data_dir, fname)
  resp <- GET(url, timeout(60), write_disk(fpath, overwrite = TRUE))
  status <- status_code(resp)
  fsize <- if (file.exists(fpath)) file.size(fpath) else 0
  cat(sprintf("  %s → HTTP %d (%.0f KB)\n", fname, status, fsize / 1024))
  if (status != 200 || fsize < 5000) {
    if (file.exists(fpath)) file.remove(fpath)
  }
  Sys.sleep(0.5)
}

cat("\n=== Done ===\n")
