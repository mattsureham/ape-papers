# 01_fetch_data.R — Fetch Eurostat business registration and VAT data
# apep_1002: Czech EET Abolition and Formalization Hysteresis

source("00_packages.R")

cat("=== Fetching Eurostat STS_RB_Q (quarterly business registrations) ===\n")

# Countries: CZ (treated), HU, HR, IT, PL, SE (controls)
countries <- c("CZ", "HU", "HR", "IT", "PL", "SE")

# Fetch quarterly business registrations
# STS_RB_Q: Short-term business statistics - business registrations - quarterly
sts_raw <- tryCatch(
  get_eurostat("sts_rb_q", time_format = "date"),
  error = function(e) {
    cat("eurostat package failed, trying direct SDMX API...\n")
    NULL
  }
)

if (is.null(sts_raw)) {
  # Direct SDMX REST API fallback
  base_url <- "https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/sts_rb_q"
  resp <- httr::GET(
    base_url,
    query = list(
      format = "JSON",
      geo = paste(countries, collapse = "+"),
      sinceTimePeriod = "2015-Q1"
    )
  )
  if (httr::status_code(resp) != 200) {
    stop("FATAL: Cannot fetch STS_RB_Q from Eurostat. Status: ", httr::status_code(resp),
         "\nResponse: ", httr::content(resp, "text", encoding = "UTF-8"))
  }
  # Parse JSON-stat
  json_data <- httr::content(resp, "text", encoding = "UTF-8")
  sts_raw <- jsonlite::fromJSON(json_data)
  cat("Fetched via SDMX API.\n")
}

stopifnot("Data fetch returned NULL or empty" = !is.null(sts_raw) && nrow(sts_raw) > 0)

cat("Raw STS_RB_Q rows:", nrow(sts_raw), "\n")
cat("Countries available:", paste(unique(sts_raw$geo), collapse = ", "), "\n")
cat("Time range:", as.character(min(sts_raw$TIME_PERIOD, na.rm = TRUE)), "to",
    as.character(max(sts_raw$TIME_PERIOD, na.rm = TRUE)), "\n")

# Save raw data
saveRDS(sts_raw, "../data/sts_rb_q_raw.rds")
cat("Saved sts_rb_q_raw.rds\n")

# Fetch VAT revenue data
cat("\n=== Fetching Eurostat GOV_10A_TAXAG (tax revenue by type) ===\n")

vat_raw <- tryCatch(
  get_eurostat("gov_10a_taxag", time_format = "date"),
  error = function(e) {
    cat("WARNING: Could not fetch GOV_10A_TAXAG:", conditionMessage(e), "\n")
    cat("Proceeding without VAT data (supplementary only).\n")
    NULL
  }
)

if (!is.null(vat_raw) && nrow(vat_raw) > 0) {
  saveRDS(vat_raw, "../data/gov_10a_taxag_raw.rds")
  cat("Saved gov_10a_taxag_raw.rds, rows:", nrow(vat_raw), "\n")
} else {
  cat("VAT data not available — will proceed with business registration data only.\n")
}

cat("\n=== Data fetch complete ===\n")
