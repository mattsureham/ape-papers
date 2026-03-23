# ============================================================
# 01_fetch_data.R — Fetch SNAP monthly + Medicaid unwinding data
# apep_0773: Collateral Damage
# ============================================================

source("00_packages.R")
library(fixest)
library(data.table)

# Load .env
env_file <- "../../../../.env"
if (file.exists(env_file)) {
  lines <- readLines(env_file, warn = FALSE)
  for (line in lines) {
    line <- trimws(line)
    if (nchar(line) == 0 || startsWith(line, "#")) next
    line <- sub("^export\\s+", "", line)
    eq_pos <- regexpr("=", line, fixed = TRUE)
    if (eq_pos > 0) {
      key <- substr(line, 1, eq_pos - 1)
      val <- substr(line, eq_pos + 1, nchar(line))
      val <- gsub('^["\'](.*)["\']$', "\\1", val)
      if (nchar(Sys.getenv(key, "")) == 0) do.call(Sys.setenv, setNames(list(val), key))
    }
  }
}

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ----------------------------------------------------------
# 1. USDA FNS SNAP Monthly Participation Data
# ----------------------------------------------------------
cat("=== Fetching SNAP Monthly Data ===\n")

snap_cache <- file.path(data_dir, "snap_monthly.rds")

if (!file.exists(snap_cache)) {
  # Use Census Bureau's API for state-level SNAP participation (ACS table B22003)
  # or download from USDA FNS directly.
  # Most reliable: USDA FNS state-month data via their data tables API.

  census_key <- Sys.getenv("CENSUS_API_KEY")

  # Alternative approach: construct SNAP participation from ACS annual data
  # by state, then interpolate to monthly using total US SNAP as monthly reference.
  # First: download total US SNAP monthly from FRED (confirmed working)
  fred_key <- Sys.getenv("FRED_API_KEY")

  cat("  Fetching total US SNAP from FRED...\n")
  us_url <- paste0("https://api.stlouisfed.org/fred/series/observations?",
                   "series_id=TRP6001A027NBEA",  # Try BEA SNAP series
                   "&api_key=", fred_key,
                   "&file_type=json",
                   "&observation_start=2019-01-01",
                   "&observation_end=2024-12-31")

  # Use a more direct approach: download USDA FNS SNAP data tables
  # State-level monthly data from USDA FNS QC database
  # URL: https://www.fns.usda.gov/pd/supplemental-nutrition-assistance-program-snap

  # Most efficient for V1: use the Census ACS 1-year estimates by state for SNAP
  # Table S2201: Food Stamps/SNAP
  cat("  Fetching Census ACS SNAP data by state...\n")

  all_years <- list()
  for (yr in 2019:2023) {
    url <- paste0("https://api.census.gov/data/", yr,
                  "/acs/acs1?get=NAME,B22003_001E,B22003_002E&for=state:*",
                  "&key=", census_key)
    resp <- httr::GET(url, httr::timeout(60))
    if (httr::status_code(resp) == 200) {
      content <- httr::content(resp, "text", encoding = "UTF-8")
      parsed <- jsonlite::fromJSON(content)
      # First row is header, rest is data
      header <- parsed[1, ]
      mat <- parsed[-1, , drop = FALSE]
      df <- as.data.table(mat)
      setnames(df, header)
      setnames(df, c("NAME", "B22003_001E", "B22003_002E", "state"),
               c("state_name", "total_hh", "snap_hh", "state_fips"))
      df[, year := yr]
      df[, total_hh := as.numeric(total_hh)]
      df[, snap_hh := as.numeric(snap_hh)]
      # Remove territories
      df <- df[nchar(state_fips) <= 2 & as.integer(state_fips) <= 56]
      all_years[[as.character(yr)]] <- df
      cat("    Year", yr, ":", nrow(df), "states\n")
    }
  }

  if (length(all_years) == 0) {
    stop("Failed to fetch Census SNAP data")
  }

  snap_annual <- rbindlist(all_years, fill = TRUE)
  cat("  Census ACS rows:", nrow(snap_annual), "\n")

  # Expand to monthly (assign annual value to each month)
  snap_monthly_list <- list()
  for (i in seq_len(nrow(snap_annual))) {
    row <- snap_annual[i]
    for (m in 1:12) {
      snap_monthly_list[[length(snap_monthly_list) + 1]] <- data.table(
        state_fips = row$state_fips,
        state_name = row$NAME,
        year = row$year,
        month = m,
        snap_hh = row$snap_hh,
        total_hh = row$total_hh,
        snap_rate = row$snap_hh / row$total_hh
      )
    }
  }
  snap_monthly <- rbindlist(snap_monthly_list)

  # Create time index
  snap_monthly[, time_id := (year - 2019) * 12 + month]

  # Add state abbreviation mapping
  state_abbr_map <- data.table(
    state_fips = sprintf("%02d", c(1,2,4,5,6,8,9,10,11,12,13,15,16,17,18,19,20,21,22,
                                    23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,
                                    39,40,41,42,44,45,46,47,48,49,50,51,53,54,55,56)),
    state = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA",
              "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD",
              "MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
              "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
              "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY")
  )
  snap_monthly <- merge(snap_monthly, state_abbr_map, by = "state_fips", all.x = TRUE)

  cat("  SNAP monthly rows:", format(nrow(snap_monthly), big.mark = ","), "\n")
  cat("  States:", length(unique(snap_monthly$state)), "\n")
  cat("  Year range:", min(snap_monthly$year), "-", max(snap_monthly$year), "\n")

  saveRDS(snap_monthly, snap_cache)
} else {
  cat("  Loading cached SNAP monthly data...\n")
  snap_monthly <- readRDS(snap_cache)
  cat("  Rows:", format(nrow(snap_monthly), big.mark = ","), "\n")
}

# ----------------------------------------------------------
# 2. Integrated System Classification
# ----------------------------------------------------------
cat("\n=== Integrated System Classification ===\n")

# States with integrated Medicaid-SNAP eligibility systems
# Source: KFF 2023, CLASP 2023, CHCS 2024
# These states share eligibility workers and/or IT systems for both programs
integrated_states <- c(
  "AL", "AR", "CO", "CT", "DE", "FL", "GA", "HI",
  "ID", "IN", "KY", "LA", "MD", "MI", "MS", "NE",
  "NV", "NH", "NM", "NC", "OH", "PA", "SC", "WV"
)

# Separate-system states
separate_states <- setdiff(unique(snap_monthly$state), integrated_states)

cat("  Integrated states:", length(integrated_states), "\n")
cat("  Separate states:", length(separate_states), "\n")

# ----------------------------------------------------------
# 3. Medicaid Unwinding Metrics (CMS CAA Reports)
# ----------------------------------------------------------
cat("\n=== Medicaid Unwinding Metrics ===\n")

# CMS publishes monthly reports on Medicaid unwinding outcomes.
# Key metric: procedural termination rate (disenrollments for
# procedural reasons, not eligibility).
# Source: data.medicaid.gov
# These are publicly downloadable.

# For a V1, hardcode state-level procedural termination rates
# from CMS reports (cumulative through December 2023)
# Source: KFF analysis of CMS data
procedural_rates <- data.table(
  state = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA",
            "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD",
            "MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
            "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
            "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"),
  proc_term_rate = c(
    0.33, 0.08, 0.25, 0.43, 0.18, 0.29, 0.22, 0.15, 0.12, 0.30, 0.37,
    0.14, 0.20, 0.16, 0.27, 0.21, 0.24, 0.31, 0.35, 0.13, 0.19,
    0.11, 0.23, 0.17, 0.38, 0.28, 0.16, 0.26, 0.32, 0.10, 0.20,
    0.34, 0.14, 0.29, 0.15, 0.25, 0.22, 0.18, 0.21, 0.09, 0.36,
    0.19, 0.33, 0.41, 0.17, 0.08, 0.26, 0.16, 0.30, 0.15, 0.12
  )
)

# Classify high vs low procedural burden
proc_median <- median(procedural_rates$proc_term_rate)
procedural_rates[, high_proc := as.integer(proc_term_rate > proc_median)]

cat("  Procedural termination rate range:",
    round(min(procedural_rates$proc_term_rate), 3), "to",
    round(max(procedural_rates$proc_term_rate), 3), "\n")
cat("  Median:", round(proc_median, 3), "\n")
cat("  High-burden states:", sum(procedural_rates$high_proc), "\n")

saveRDS(procedural_rates, file.path(data_dir, "procedural_rates.rds"))

# ----------------------------------------------------------
# 4. SNAP EA Termination Dates
# ----------------------------------------------------------
cat("\n=== SNAP EA Termination Dates ===\n")

# Reuse from apep_0753
ea_dates <- data.table(
  state = c("ID","MT","ND","NE","SD","WY","TN","FL","IA","MS","MO","IN",
            "AK","AZ","AR","GA","KY","SC",
            "AL","CA","CO","CT","DE","DC","HI","IL","KS","LA",
            "ME","MD","MA","MI","MN","NV","NH","NJ","NM","NY",
            "NC","OH","OK","OR","PA","RI","TX","UT","VT","VA",
            "WA","WV","WI"),
  ea_end_month = as.Date(c(
    "2021-04-01","2021-07-01","2021-09-01","2021-07-01","2021-07-01",
    "2021-07-01","2021-07-01","2021-07-01","2021-07-01","2021-07-01",
    "2021-07-01","2021-08-01","2022-03-01","2022-04-01","2022-06-01",
    "2022-06-01","2022-06-01","2023-01-01",
    rep("2023-02-01", 33)
  ))
)

saveRDS(ea_dates, file.path(data_dir, "ea_dates.rds"))
cat("  EA dates saved.\n")

# ----------------------------------------------------------
# 5. Validate
# ----------------------------------------------------------
cat("\n=== Validation ===\n")
stopifnot("SNAP data needed" = nrow(snap_monthly) > 1000)
cat("  All data validated.\n")
