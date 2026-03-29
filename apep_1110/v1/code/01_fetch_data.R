# 01_fetch_data.R — Fetch real data from GOV.UK and Fingertips API
# APEP paper apep_1110: UK Sugar Tax and Childhood Dental Extractions

source("code/00_packages.R")

data_dir <- "data"
dir.create(data_dir, showWarnings = FALSE)

# ============================================================================
# 1. Hospital Episode Statistics: Tooth Extractions (GOV.UK OHID)
# ============================================================================
# Two datasets covering children 0-19 dental extractions by Local Authority
# Source: Office for Health Improvement and Disparities (OHID)

cat("Fetching tooth extraction data from Fingertips API...\n")

# Use Fingertips API for dental extraction data
# Indicator 93563: Hospital tooth extractions (0-19 years)
# This is the programmatic route to the same GOV.UK HES data

base_url <- "https://fingertips.phe.org.uk/api"

# Function to fetch Fingertips indicator data
fetch_fingertips <- function(indicator_id, area_type_id = 402) {
  url <- paste0(base_url, "/all_data/csv/by_indicator_id?indicator_ids=",
                indicator_id, "&area_type_id=", area_type_id)
  cat("  Fetching indicator", indicator_id, "from:", url, "\n")

  response <- httr::GET(url, httr::timeout(120))

  if (httr::status_code(response) != 200) {
    stop("API returned status ", httr::status_code(response), " for indicator ", indicator_id)
  }

  content_text <- httr::content(response, as = "text", encoding = "UTF-8")

  if (nchar(content_text) < 100) {
    stop("Response too small for indicator ", indicator_id, ": ", nchar(content_text), " bytes")
  }

  df <- readr::read_csv(content_text, show_col_types = FALSE)
  cat("  Retrieved", nrow(df), "rows for indicator", indicator_id, "\n")

  if (nrow(df) == 0) {
    stop("No data returned for indicator ", indicator_id)
  }

  return(df)
}

# Try dental extraction indicators
# 93563: Hospital episodes for dental caries in children (0-19)
# Alternative: 93489 (tooth extractions in children 0-5)
# Alternative: 92839 (hospital admissions for dental caries, 0-5)

dental_data <- tryCatch({
  fetch_fingertips(93563)
}, error = function(e) {
  cat("  Indicator 93563 failed:", e$message, "\n")
  cat("  Trying indicator 92839 (dental caries admissions 0-5)...\n")
  tryCatch({
    fetch_fingertips(92839)
  }, error = function(e2) {
    cat("  Indicator 92839 failed:", e2$message, "\n")
    cat("  Trying indicator 93489 (tooth extractions 0-5)...\n")
    fetch_fingertips(93489)
  })
})

# Validate dental data
stopifnot("Value" %in% names(dental_data) || "value" %in% names(dental_data))
cat("Dental extraction data: ", nrow(dental_data), " rows, ",
    length(unique(dental_data$`Area Code`)), " areas\n")

write_csv(dental_data, file.path(data_dir, "dental_extractions_raw.csv"))
cat("Saved dental_extractions_raw.csv\n")

# ============================================================================
# 2. IMD 2019 Deprivation Scores (Fingertips API)
# ============================================================================
# Indicator 93553: Index of Multiple Deprivation (IMD) score
cat("\nFetching IMD deprivation scores...\n")

imd_data <- fetch_fingertips(93553)

stopifnot(nrow(imd_data) > 0)
cat("IMD data: ", nrow(imd_data), " rows\n")

write_csv(imd_data, file.path(data_dir, "imd_raw.csv"))
cat("Saved imd_raw.csv\n")

# ============================================================================
# 3. Childhood Obesity Data (Fingertips API)
# ============================================================================
# Indicator 20601: Year 6 prevalence of obesity (NCMP)
cat("\nFetching childhood obesity data...\n")

obesity_data <- fetch_fingertips(20601)

stopifnot(nrow(obesity_data) > 0)
cat("Obesity data: ", nrow(obesity_data), " rows\n")

write_csv(obesity_data, file.path(data_dir, "obesity_raw.csv"))
cat("Saved obesity_raw.csv\n")

# ============================================================================
# 4. Water Fluoridation Status (Fingertips API)
# ============================================================================
# Indicator 93437: Proportion of population with fluoridated water
cat("\nFetching water fluoridation data...\n")

fluoride_data <- tryCatch({
  fetch_fingertips(93437)
}, error = function(e) {
  cat("  Fluoridation indicator 93437 failed:", e$message, "\n")
  cat("  Trying indicator 93105 (fluoridation proportion)...\n")
  tryCatch({
    fetch_fingertips(93105)
  }, error = function(e2) {
    cat("  Warning: Could not fetch fluoridation data. Will proceed without.\n")
    NULL
  })
})

if (!is.null(fluoride_data)) {
  write_csv(fluoride_data, file.path(data_dir, "fluoridation_raw.csv"))
  cat("Saved fluoridation_raw.csv\n")
} else {
  cat("Fluoridation data unavailable — will not include as control.\n")
}

# ============================================================================
# 5. Population Data for Rates (Fingertips API)
# ============================================================================
# Indicator 92708 or use denominator from dental data if available
cat("\nFetching child population data...\n")

pop_data <- tryCatch({
  fetch_fingertips(92708)
}, error = function(e) {
  cat("  Population indicator failed:", e$message, "\n")
  cat("  Will use denominators from dental extraction data.\n")
  NULL
})

if (!is.null(pop_data)) {
  write_csv(pop_data, file.path(data_dir, "population_raw.csv"))
  cat("Saved population_raw.csv\n")
}

# ============================================================================
# Summary
# ============================================================================
cat("\n=== Data Fetch Summary ===\n")
cat("Dental extractions: ", nrow(dental_data), " rows\n")
cat("IMD deprivation:    ", nrow(imd_data), " rows\n")
cat("Childhood obesity:  ", nrow(obesity_data), " rows\n")
cat("Fluoridation:       ", ifelse(is.null(fluoride_data), "UNAVAILABLE", paste(nrow(fluoride_data), "rows")), "\n")
cat("Population:         ", ifelse(is.null(pop_data), "Using denominators from dental data", paste(nrow(pop_data), "rows")), "\n")
cat("All files saved to: ", data_dir, "/\n")
