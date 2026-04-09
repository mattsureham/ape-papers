## 01_fetch_data.R — Fetch Google Trends + FCA complaints data
## apep_1439: The Switching Paradox

source("00_packages.R")

cat("=== Fetching Google Trends data ===\n")

# --- Google Trends: Insurance comparison sites vs non-insurance ---
# Treated: confused.com (insurance-heavy), gocompare.com (insurance-heavy)
# Control: moneysupermarket.com (broad financial), uswitch.com (energy/broadband)
# We fetch in groups of 5 max

# Period: 2018-01-01 to 2025-12-31 (4 years pre, 4 years post Jan 2022)
time_range <- "2018-01-01 2025-12-31"

# Fetch treated insurance comparison sites
cat("Fetching insurance comparison site trends...\n")
gt_insurance <- gtrends(
  keyword = c("confused.com", "comparethemarket.com", "gocompare.com"),
  geo = "GB",
  time = time_range
)
stopifnot(!is.null(gt_insurance$interest_over_time))
cat(sprintf("  Got %d rows for insurance sites\n", nrow(gt_insurance$interest_over_time)))

Sys.sleep(5)  # Rate limit

# Fetch control non-insurance comparison sites
cat("Fetching non-insurance comparison site trends...\n")
gt_control <- gtrends(
  keyword = c("uswitch.com", "moneysavingexpert.com"),
  geo = "GB",
  time = time_range
)
stopifnot(!is.null(gt_control$interest_over_time))
cat(sprintf("  Got %d rows for control sites\n", nrow(gt_control$interest_over_time)))

# Combine
gt_all <- bind_rows(
  gt_insurance$interest_over_time %>% mutate(group = "insurance"),
  gt_control$interest_over_time %>% mutate(group = "control")
) %>%
  mutate(
    date = as.Date(date),
    hits = as.numeric(ifelse(hits == "<1", "0.5", hits))
  ) %>%
  select(date, keyword, hits, group)

cat(sprintf("Combined Google Trends: %d rows, %d keywords\n", nrow(gt_all), n_distinct(gt_all$keyword)))

# --- FCA Aggregate Complaints Data ---
cat("\n=== Fetching FCA Complaints Data ===\n")

# FCA publishes half-yearly aggregate complaints as Excel
# URL pattern: https://www.fca.org.uk/publication/data/aggregate-complaints-data-YYYY-hN.xlsx
# We need to try multiple URLs as naming conventions change

fca_urls <- c(
  "https://www.fca.org.uk/publication/data/aggregate-complaints-data-2025-h1.xlsx",
  "https://www.fca.org.uk/publication/data/aggregate-complaints-data-2024-h2.xlsx",
  "https://www.fca.org.uk/publication/data/aggregate-complaints-data-2024-h1.xlsx"
)

fca_data <- NULL
for (url in fca_urls) {
  cat(sprintf("Trying: %s\n", url))
  tmp <- tempfile(fileext = ".xlsx")
  resp <- try(download.file(url, tmp, mode = "wb", quiet = TRUE), silent = TRUE)
  if (!inherits(resp, "try-error") && file.exists(tmp) && file.size(tmp) > 1000) {
    sheets <- excel_sheets(tmp)
    cat(sprintf("  Success! Sheets: %s\n", paste(sheets, collapse = ", ")))
    # Read the product-specific sheet
    product_sheet <- sheets[grepl("product|Product", sheets, ignore.case = TRUE)]
    if (length(product_sheet) > 0) {
      fca_raw <- read_excel(tmp, sheet = product_sheet[1])
      cat(sprintf("  Read %d rows from '%s'\n", nrow(fca_raw), product_sheet[1]))
      if (is.null(fca_data)) fca_data <- fca_raw
    }
    break
  }
}

if (is.null(fca_data)) {
  cat("WARNING: Could not fetch FCA complaints data from any URL.\n")
  cat("Proceeding with Google Trends as primary data source.\n")
} else {
  cat(sprintf("FCA complaints data: %d rows\n", nrow(fca_data)))
}

# --- FOS Quarterly Complaints ---
cat("\n=== Fetching FOS Quarterly Complaints Data ===\n")

fos_url <- "https://www.financial-ombudsman.org.uk/files/323505/Quarterly-complaints-data-Q3-2024-25.xlsx"
fos_tmp <- tempfile(fileext = ".xlsx")
fos_resp <- try(download.file(fos_url, fos_tmp, mode = "wb", quiet = TRUE), silent = TRUE)
fos_data <- NULL
if (!inherits(fos_resp, "try-error") && file.exists(fos_tmp) && file.size(fos_tmp) > 1000) {
  fos_sheets <- excel_sheets(fos_tmp)
  cat(sprintf("FOS sheets: %s\n", paste(fos_sheets, collapse = ", ")))
  # Try to find product-level data
  for (s in fos_sheets) {
    tmp_df <- try(read_excel(fos_tmp, sheet = s), silent = TRUE)
    if (!inherits(tmp_df, "try-error") && nrow(tmp_df) > 5) {
      cat(sprintf("  Sheet '%s': %d rows, %d cols\n", s, nrow(tmp_df), ncol(tmp_df)))
    }
  }
} else {
  cat("WARNING: Could not fetch FOS data.\n")
}

# --- Save ---
saveRDS(gt_all, "../data/google_trends.rds")
cat(sprintf("\nSaved google_trends.rds (%d rows)\n", nrow(gt_all)))

if (!is.null(fca_data)) {
  saveRDS(fca_data, "../data/fca_complaints.rds")
  cat(sprintf("Saved fca_complaints.rds (%d rows)\n", nrow(fca_data)))
}

cat("\n=== Data fetch complete ===\n")
