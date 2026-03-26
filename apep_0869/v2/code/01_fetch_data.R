# 01_fetch_data.R — Fetch QCEW data from BLS
# APEP-0869 V2: Private Enforcement and the Reorganization of Industry

source("00_packages.R")

# ============================================================
# BLS QCEW data via industry-level API
# Returns ALL areas nationwide for a given NAICS code
# We filter to target states' counties
# ============================================================

target_state_fips <- c("17", "18", "55", "29", "19", "21")
state_names <- c("17" = "Illinois", "18" = "Indiana", "55" = "Wisconsin",
                 "29" = "Missouri", "19" = "Iowa", "21" = "Kentucky")
# Extended to 2024 for reversal test (2024 BIPA amendments, signed Aug 2)
# BLS QCEW available with ~6-9 month lag; 2024Q2 should be available by Mar 2026
# 2025 data not yet available (404)
years <- 2015:2024

# NAICS 2-digit sectors for the continuous-exposure design:
# V2 uses 10 sectors spanning the exposure gradient (high → low biometric intensity)
# This gives rich variation without 1000+ API calls
# Note: "31-33", "44-45", "48-49" dropped — BLS QCEW API returns 404 for hyphenated codes
naics_codes <- c("10",  # Total (reference)
                 "51",  # Information (highest exposure)
                 "56",  # Admin Services (high exposure)
                 "54",  # Professional/Technical (moderate-high)
                 "55",  # Management (moderate)
                 "52",  # Finance (moderate, GLBA-shielded)
                 "62",  # Healthcare (moderate, HIPAA-shielded)
                 "23",  # Construction (low)
                 "72",  # Accommodation/Food (very low)
                 "61"   # Education (low)
                 )

# ============================================================
# Fetch annual data
# ============================================================

cat("=== FETCHING ANNUAL QCEW DATA ===\n")
annual_data <- list()
fetch_errors <- c()

for (yr in years) {
  for (naics in naics_codes) {
    url <- sprintf("https://data.bls.gov/cew/data/api/%d/a/industry/%s.csv", yr, naics)
    cat(sprintf("Fetching NAICS %s, %d...\n", naics, yr))

    response <- tryCatch(
      {
        resp <- httr::GET(url, httr::timeout(60))
        if (httr::status_code(resp) != 200) {
          stop(sprintf("HTTP %d", httr::status_code(resp)))
        }
        content_text <- httr::content(resp, as = "text", encoding = "UTF-8")
        dt <- fread(text = content_text)
        # Filter to target states (county FIPS = 5 digits, first 2 = state)
        dt[, state_fips := substr(area_fips, 1, 2)]
        dt <- dt[state_fips %in% target_state_fips]
        dt$naics_requested <- naics
        dt
      },
      error = function(e) {
        msg <- sprintf("FAILED: NAICS %s, %d — %s", naics, yr, e$message)
        cat(msg, "\n")
        fetch_errors <<- c(fetch_errors, msg)
        NULL
      }
    )

    if (!is.null(response) && nrow(response) > 0) {
      annual_data[[paste(yr, naics)]] <- response
    }

    Sys.sleep(0.3)
  }
}

if (length(annual_data) == 0) {
  stop("FATAL: No annual QCEW data fetched. Cannot proceed.")
}

if (length(fetch_errors) > 0) {
  cat("\nFetch errors:\n")
  cat(paste(fetch_errors, collapse = "\n"), "\n")
  total_requests <- length(years) * length(naics_codes)
  if (length(fetch_errors) > 0.3 * total_requests) {
    stop(sprintf("FATAL: %d/%d fetches failed.", length(fetch_errors), total_requests))
  }
}

qcew_annual <- rbindlist(annual_data, fill = TRUE)
cat(sprintf("\nAnnual data: %d rows\n", nrow(qcew_annual)))

# ============================================================
# Fetch quarterly data for event study
# ============================================================

cat("\n=== FETCHING QUARTERLY QCEW DATA ===\n")
quarterly_data <- list()

for (yr in years) {
  for (qtr in 1:4) {
    for (naics in naics_codes) {
      url <- sprintf("https://data.bls.gov/cew/data/api/%d/%d/industry/%s.csv", yr, qtr, naics)
      cat(sprintf("Fetching NAICS %s, %dQ%d...\n", naics, yr, qtr))

      response <- tryCatch(
        {
          resp <- httr::GET(url, httr::timeout(60))
          if (httr::status_code(resp) != 200) {
            stop(sprintf("HTTP %d", httr::status_code(resp)))
          }
          content_text <- httr::content(resp, as = "text", encoding = "UTF-8")
          dt <- fread(text = content_text)
          dt[, state_fips := substr(area_fips, 1, 2)]
          dt <- dt[state_fips %in% target_state_fips]
          dt$naics_requested <- naics
          dt
        },
        error = function(e) {
          cat(sprintf("  WARN: NAICS %s, %dQ%d — %s\n", naics, yr, qtr, e$message))
          NULL
        }
      )

      if (!is.null(response) && nrow(response) > 0) {
        quarterly_data[[paste(yr, qtr, naics)]] <- response
      }

      Sys.sleep(0.2)
    }
  }
}

if (length(quarterly_data) == 0) {
  stop("FATAL: No quarterly QCEW data fetched.")
}

qcew_quarterly <- rbindlist(quarterly_data, fill = TRUE)
cat(sprintf("\nQuarterly data: %d rows\n", nrow(qcew_quarterly)))

# ============================================================
# Save raw data
# ============================================================

fwrite(qcew_annual, "../data/qcew_annual_raw.csv")
fwrite(qcew_quarterly, "../data/qcew_quarterly_raw.csv")

cat("\n=== FETCH SUMMARY ===\n")
cat(sprintf("Annual: %d rows across %d state-FIPS\n",
            nrow(qcew_annual), length(unique(qcew_annual$state_fips))))
cat(sprintf("Quarterly: %d rows across %d state-FIPS\n",
            nrow(qcew_quarterly), length(unique(qcew_quarterly$state_fips))))
cat(sprintf("Years: %s\n", paste(sort(unique(qcew_annual$year)), collapse = ", ")))
cat(sprintf("NAICS: %s\n", paste(sort(unique(qcew_annual$naics_requested)), collapse = ", ")))

# ============================================================
# County adjacency file
# ============================================================

cat("\nFetching county adjacency file...\n")
adj_url <- "https://www2.census.gov/geo/docs/reference/county_adjacency2024.txt"
adj_resp <- httr::GET(adj_url, httr::timeout(120))
if (httr::status_code(adj_resp) != 200) {
  adj_url <- "https://www2.census.gov/geo/docs/reference/county_adjacency.txt"
  adj_resp <- httr::GET(adj_url, httr::timeout(120))
}

if (httr::status_code(adj_resp) == 200) {
  adj_text <- httr::content(adj_resp, as = "text", encoding = "UTF-8")
  writeLines(adj_text, "../data/county_adjacency.txt")
  cat("Saved: county_adjacency.txt\n")
} else {
  cat("WARNING: Could not fetch adjacency file (will use manual border counties).\n")
}

cat("\n=== DATA FETCH COMPLETE ===\n")
