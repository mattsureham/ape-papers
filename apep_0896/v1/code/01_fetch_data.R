# 01_fetch_data.R — Fetch QCEW data from BLS API
# apep_0896: Does the Right to Repair Create Repairers?

source("00_packages.R")

# ── BLS QCEW API ──
# Endpoint: https://data.bls.gov/cew/data/api/{YEAR}/{QTR}/industry/{NAICS}.csv
# NAICS 8112: Electronic and Precision Equipment Repair and Maintenance
# NAICS 8111: Automotive Repair and Maintenance (placebo)

fetch_qcew <- function(year, qtr, naics) {
  url <- sprintf(
    "https://data.bls.gov/cew/data/api/%d/%d/industry/%s.csv",
    year, qtr, naics
  )
  cat(sprintf("Fetching QCEW: year=%d, qtr=%d, naics=%s ... ", year, qtr, naics))

  resp <- httr::GET(url, httr::timeout(30))

  if (httr::status_code(resp) != 200) {
    cat(sprintf("FAILED (HTTP %d)\n", httr::status_code(resp)))
    return(NULL)
  }

  raw <- httr::content(resp, as = "text", encoding = "UTF-8")
  df <- read.csv(text = raw, stringsAsFactors = FALSE)
  cat(sprintf("OK (%d rows)\n", nrow(df)))
  return(df)
}

# ── Fetch all quarters for both NAICS codes ──
years <- 2019:2025
quarters <- 1:4
naics_codes <- c("8112", "8111")

all_data <- list()

for (naics in naics_codes) {
  for (yr in years) {
    for (qt in quarters) {
      # Skip future quarters
      if (yr == 2025 && qt > 2) next

      df <- fetch_qcew(yr, qt, naics)
      if (!is.null(df)) {
        df$naics_code <- naics
        all_data[[paste(naics, yr, qt, sep = "_")]] <- df
      }

      Sys.sleep(0.5)  # Rate limiting
    }
  }
}

# Combine
qcew_raw <- bind_rows(all_data)

if (nrow(qcew_raw) == 0) {
  stop("FATAL: No QCEW data fetched. Cannot proceed with simulated data.")
}

cat(sprintf("\nTotal rows fetched: %d\n", nrow(qcew_raw)))
cat(sprintf("NAICS codes: %s\n", paste(unique(qcew_raw$naics_code), collapse = ", ")))

# ── Filter to state-level, private ownership ──
# own_code == 5 is private sector
# area_fips ending in "000" are state-level
qcew_state <- qcew_raw %>%
  filter(
    own_code == 5,
    agglvl_code == 58  # State-level, by industry (NAICS 4-digit)
  )

cat(sprintf("State-level private rows: %d\n", nrow(qcew_state)))
cat(sprintf("Unique states: %d\n", n_distinct(qcew_state$area_fips)))

# ── Save raw data ──
write_csv(qcew_raw, "../data/qcew_raw.csv")
write_csv(qcew_state, "../data/qcew_state.csv")

cat("Data saved to data/qcew_raw.csv and data/qcew_state.csv\n")

# ── Validation assertions ──
stopifnot("No data fetched" = nrow(qcew_state) > 0)
stopifnot("Missing NAICS codes" = all(c("8112", "8111") %in% qcew_state$naics_code))
n_state_qtrs <- qcew_state %>%
  filter(naics_code == "8112") %>%
  summarise(n = n_distinct(paste(area_fips, qtr)))
cat(sprintf("Unique state-quarter observations (8112): %d\n", n_state_qtrs$n))
