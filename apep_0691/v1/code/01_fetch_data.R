## 01_fetch_data.R — Fetch data from PHE/OHID Fingertips API
## APEP-0691: Sugar Tax Without Sticker Shock

source("00_packages.R")

# ============================================================================
# Fingertips API helper
# ============================================================================

fingertips_fetch <- function(indicator_id, area_type_id = 401) {
  # area_type_id: 401 = County & UA (pre-2019), 402 = Districts (2019+)
  # For most public health indicators, 401 is the standard

  url <- paste0(
    "https://fingertips.phe.org.uk/api/all_data/csv/by_indicator_id?",
    "indicator_ids=", indicator_id,
    "&area_type_id=", area_type_id
  )

  cat("Fetching indicator", indicator_id, "from Fingertips...\n")

  resp <- httr2::request(url) |>
    httr2::req_timeout(120) |>
    httr2::req_perform()

  if (httr2::resp_status(resp) != 200) {
    stop("Fingertips API returned status ", httr2::resp_status(resp),
         " for indicator ", indicator_id)
  }

  raw_text <- httr2::resp_body_string(resp)

  if (nchar(raw_text) < 100) {
    stop("Fingertips returned empty/minimal data for indicator ", indicator_id)
  }

  dt <- data.table::fread(text = raw_text)
  cat("  Fetched", nrow(dt), "rows,", ncol(dt), "columns\n")
  return(dt)
}

# ============================================================================
# 1. Dental decay in 5-year-olds (Indicator 93563)
# ============================================================================

dental_raw <- fingertips_fetch(93563, area_type_id = 401)
cat("\nDental decay data:\n")
cat("  Time periods:", paste(sort(unique(dental_raw$`Time period`)), collapse = ", "), "\n")
cat("  Unique areas:", length(unique(dental_raw$`Area Code`)), "\n")

# Save raw
fwrite(dental_raw, "../data/dental_raw.csv")
cat("  Saved to data/dental_raw.csv\n")

# ============================================================================
# 2. Childhood obesity, Reception year (Indicator 20601)
# ============================================================================

obesity_raw <- fingertips_fetch(20601, area_type_id = 401)
cat("\nChildhood obesity data:\n")
cat("  Time periods:", paste(sort(unique(obesity_raw$`Time period`)), collapse = ", "), "\n")
cat("  Unique areas:", length(unique(obesity_raw$`Area Code`)), "\n")

fwrite(obesity_raw, "../data/obesity_raw.csv")
cat("  Saved to data/obesity_raw.csv\n")

# ============================================================================
# 3. COPD emergency admissions — placebo (Indicator 92302)
# ============================================================================

copd_raw <- fingertips_fetch(92302, area_type_id = 401)
cat("\nCOPD admissions data:\n")
cat("  Time periods:", paste(sort(unique(copd_raw$`Time period`)), collapse = ", "), "\n")
cat("  Unique areas:", length(unique(copd_raw$`Area Code`)), "\n")

fwrite(copd_raw, "../data/copd_raw.csv")
cat("  Saved to data/copd_raw.csv\n")

# ============================================================================
# 4. IMD 2019 deprivation scores (Indicator 93553)
# ============================================================================

imd_raw <- fingertips_fetch(93553, area_type_id = 401)
cat("\nIMD deprivation data:\n")
cat("  Time periods:", paste(sort(unique(imd_raw$`Time period`)), collapse = ", "), "\n")
cat("  Unique areas:", length(unique(imd_raw$`Area Code`)), "\n")

fwrite(imd_raw, "../data/imd_raw.csv")
cat("  Saved to data/imd_raw.csv\n")

# ============================================================================
# Validation: Assert real data was fetched
# ============================================================================

stopifnot("Dental data has 0 rows" = nrow(dental_raw) > 0)
stopifnot("Obesity data has 0 rows" = nrow(obesity_raw) > 0)
stopifnot("COPD data has 0 rows" = nrow(copd_raw) > 0)
stopifnot("IMD data has 0 rows" = nrow(imd_raw) > 0)

cat("\n=== All data fetched and validated successfully ===\n")
