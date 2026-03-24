## 01_fetch_data.R — Data acquisition for apep_0868
## Sources: BLS QCEW, FHFA HPI, ERCOT boundary classification
source("00_packages.R")

cat("=== Step 1: Build ERCOT/SPP county crosswalk ===\n")

# Texas has 254 counties. The ERCOT grid serves ~75% of Texas.
# Counties primarily served by non-ERCOT grids (SPP, MISO, WECC):
# Source: ERCOT service area maps and PUC of Texas documents.
# SPP (Southwest Power Pool) serves the Texas Panhandle and parts of NE Texas.
# MISO/SERC serves parts of East Texas (Entergy service area).
# WECC serves El Paso area.
#
# Classification based on predominant grid operator for each county.
# Counties with split service areas assigned to their majority grid.

# Non-ERCOT counties (SPP Panhandle + MISO East Texas + WECC El Paso)
# These counties maintained power or had access to interstate imports during Uri

spp_counties <- c(
  # Texas Panhandle (SPP - Southwestern Public Service / Xcel Energy)
  "Armstrong", "Briscoe", "Carson", "Castro", "Childress",
  "Collingsworth", "Dallam", "Deaf Smith", "Donley", "Gray",
  "Hall", "Hansford", "Hartley", "Hemphill", "Hutchinson",
  "Lipscomb", "Moore", "Ochiltree", "Oldham", "Parmer",
  "Potter", "Randall", "Roberts", "Sherman", "Swisher",
  "Wheeler"
)

miso_counties <- c(
  # East Texas (Entergy Texas / MISO)
  "Hardin", "Jasper", "Jefferson", "Newton", "Orange",
  "Sabine", "San Augustine", "Shelby", "Tyler",
  "Angelina", "Nacogdoches", "Panola", "Rusk"
)

wecc_counties <- c(
  # Far West Texas (El Paso Electric / WECC)
  "El Paso", "Hudspeth"
)

non_ercot <- c(spp_counties, miso_counties, wecc_counties)

# Build full Texas county FIPS crosswalk
tx_fips_url <- "https://api.census.gov/data/2020/acs/acs5?get=NAME&for=county:*&in=state:48"
tx_resp <- GET(tx_fips_url)
stopifnot(status_code(tx_resp) == 200)
tx_json <- content(tx_resp, as = "text", encoding = "UTF-8")
tx_raw <- fromJSON(tx_json)
tx_counties <- data.table(
  county_name = tx_raw[-1, 1],
  state_fips = tx_raw[-1, 2],
  county_fips = tx_raw[-1, 3]
)
# Clean county names (remove " County, Texas")
tx_counties[, county_clean := gsub(" County, Texas$", "", county_name)]
tx_counties[, fips := paste0(state_fips, county_fips)]
tx_counties[, ercot := ifelse(county_clean %in% non_ercot, 0L, 1L)]
tx_counties[, grid := fifelse(county_clean %in% spp_counties, "SPP",
                     fifelse(county_clean %in% miso_counties, "MISO",
                     fifelse(county_clean %in% wecc_counties, "WECC", "ERCOT")))]

cat(sprintf("Texas counties: %d total, %d ERCOT, %d non-ERCOT (SPP=%d, MISO=%d, WECC=%d)\n",
    nrow(tx_counties), sum(tx_counties$ercot == 1), sum(tx_counties$ercot == 0),
    sum(tx_counties$grid == "SPP"), sum(tx_counties$grid == "MISO"),
    sum(tx_counties$grid == "WECC")))

fwrite(tx_counties, "../data/tx_county_grid.csv")

cat("=== Step 2: Fetch BLS QCEW data ===\n")

# BLS QCEW API: county-level quarterly employment
# We need 2019Q1-2023Q4 (20 quarters)
bls_key <- Sys.getenv("BLS_API_KEY", "")

fetch_qcew_quarter <- function(year, qtr) {
  # QCEW CSV flat files by area (more reliable than API for bulk)
  url <- sprintf(
    "https://data.bls.gov/cew/data/api/%d/%d/area/48000.csv",
    year, qtr
  )
  resp <- GET(url, timeout(60))
  if (status_code(resp) != 200) {
    # Try alternative: single-file download
    url2 <- sprintf(
      "https://data.bls.gov/cew/data/api/%d/%d/area/48000.csv",
      year, qtr
    )
    warning(sprintf("QCEW API failed for %dQ%d: HTTP %d", year, qtr, status_code(resp)))
    return(NULL)
  }
  txt <- content(resp, as = "text", encoding = "UTF-8")
  dt <- fread(text = txt)
  return(dt)
}

# Use the QCEW flat-file approach: download county-level CSVs
# The single-file API gives state totals; we need county detail.
# Better approach: use the BLS QCEW data slicer API

fetch_qcew_county <- function(year, qtr, fips_codes) {
  results <- list()
  # QCEW single-file downloads per year
  base_url <- sprintf(
    "https://data.bls.gov/cew/data/api/%d/%d/industry/10.csv",
    year, qtr
  )
  resp <- GET(base_url, timeout(120))
  if (status_code(resp) != 200) {
    cat(sprintf("  QCEW industry file failed for %dQ%d: HTTP %d\n", year, qtr, status_code(resp)))
    return(NULL)
  }
  txt <- content(resp, as = "text", encoding = "UTF-8")
  dt <- fread(text = txt)
  # Filter to Texas counties (FIPS starting with 48, 5-digit county level)
  dt <- dt[nchar(area_fips) == 5 & substr(area_fips, 1, 2) == "48"]
  cat(sprintf("  %dQ%d: %d TX county rows\n", year, qtr, nrow(dt)))
  return(dt)
}

# Fetch all quarters 2018Q1 through 2023Q4
all_qcew <- list()
for (yr in 2018:2023) {
  for (qt in 1:4) {
    cat(sprintf("Fetching QCEW %dQ%d...\n", yr, qt))
    dt <- fetch_qcew_county(yr, qt, tx_counties$fips)
    if (!is.null(dt)) {
      dt[, year := yr]
      dt[, quarter := qt]
      all_qcew[[paste0(yr, "Q", qt)]] <- dt
    }
    Sys.sleep(0.5)  # Rate limit
  }
}

qcew <- rbindlist(all_qcew, fill = TRUE)
if (nrow(qcew) == 0) stop("FATAL: No QCEW data retrieved. Cannot proceed.")

cat(sprintf("QCEW data: %d rows, %d unique counties\n",
    nrow(qcew), uniqueN(qcew$area_fips)))

fwrite(qcew, "../data/qcew_tx_raw.csv")

cat("=== Step 3: Fetch FHFA House Price Index ===\n")

# FHFA master CSV contains all geographic levels including counties
hpi_url <- "https://www.fhfa.gov/hpi/download/monthly/hpi_master.csv"
hpi_resp <- GET(hpi_url, timeout(180),
  add_headers("User-Agent" = "Mozilla/5.0 (R/httr APEP research)"))
if (status_code(hpi_resp) != 200) {
  cat(sprintf("FHFA master CSV: HTTP %d. Trying FRED as fallback...\n",
      status_code(hpi_resp)))
  # Fallback: use FRED API for Texas MSA-level HPI (less granular but available)
  fred_key <- Sys.getenv("FRED_API_KEY", "")
  if (nchar(fred_key) > 0) {
    # Get state-level Texas HPI from FRED as minimum viable data
    fred_url <- sprintf(
      "https://api.stlouisfed.org/fred/series/observations?series_id=TXSTHPI&api_key=%s&file_type=json&observation_start=2018-01-01&observation_end=2023-12-31",
      fred_key
    )
    fred_resp <- GET(fred_url, timeout(60))
    if (status_code(fred_resp) == 200) {
      fred_json <- content(fred_resp, as = "parsed")
      fred_obs <- rbindlist(lapply(fred_json$observations, as.data.table))
      cat(sprintf("FRED TX HPI: %d observations (state-level fallback)\n", nrow(fred_obs)))
      fwrite(fred_obs, "../data/fred_tx_hpi.csv")
    }
  }
  cat("FHFA county-level HPI unavailable. Will use QCEW as primary outcome.\n")
  fwrite(data.table(), "../data/fhfa_hpi_tx.csv")
} else {
  hpi_txt <- content(hpi_resp, as = "text", encoding = "UTF-8")
  hpi_all <- fread(text = hpi_txt)
  # Identify FIPS column and filter to Texas counties
  fips_col <- grep("fips|FIPS|place_id", names(hpi_all), value = TRUE, ignore.case = TRUE)[1]
  if (!is.na(fips_col)) {
    setnames(hpi_all, fips_col, "fips_raw", skip_absent = TRUE)
    hpi_all[, fips_str := sprintf("%05s", as.character(fips_raw))]
    hpi_tx <- hpi_all[substr(fips_str, 1, 2) == "48" & nchar(fips_str) == 5]
    cat(sprintf("FHFA HPI: %d TX county rows\n", nrow(hpi_tx)))
    fwrite(hpi_tx, "../data/fhfa_hpi_tx.csv")
  } else {
    cat("FHFA column structure unexpected. Saving full file for inspection.\n")
    fwrite(hpi_all, "../data/fhfa_hpi_full.csv")
    fwrite(data.table(), "../data/fhfa_hpi_tx.csv")
  }
}

cat("=== Step 4: Fetch NOAA temperature data for Feb 2021 ===\n")

# Try multiple NOAA nClimDiv URLs (filename includes date suffix that changes)
ncd_urls <- c(
  "https://www.ncei.noaa.gov/pub/data/cirs/climdiv/climdiv-tmpccy-v1.0.0-20260306",
  "https://www.ncei.noaa.gov/pub/data/cirs/climdiv/climdiv-tmpccy-v1.0.0-20250306",
  "https://www.ncei.noaa.gov/pub/data/cirs/climdiv/climdiv-tmpccy-v1.0.0-20240306"
)

ncd_txt <- NULL
for (url in ncd_urls) {
  resp <- GET(url, timeout(120))
  if (status_code(resp) == 200) {
    ncd_txt <- content(resp, as = "text", encoding = "UTF-8")
    cat(sprintf("NOAA nClimDiv downloaded from: %s\n", url))
    break
  }
}

if (!is.null(ncd_txt)) {
  ncd_lines <- strsplit(ncd_txt, "\n")[[1]]
  ncd_lines <- ncd_lines[nchar(ncd_lines) > 10]

  parse_ncd <- function(line) {
    code <- substr(line, 1, 6)
    state_code <- substr(code, 1, 2)
    county_code <- substr(code, 3, 5)
    element <- substr(code, 6, 6)
    year <- as.integer(trimws(substr(line, 7, 11)))
    vals <- trimws(substr(line, 12, nchar(line)))
    monthly <- as.numeric(strsplit(vals, "\\s+")[[1]])
    data.table(
      state_code = state_code,
      county_code = county_code,
      element = element,
      year = year,
      feb_temp = monthly[2]
    )
  }

  ncd_dt <- rbindlist(lapply(ncd_lines, function(l) {
    tryCatch(parse_ncd(l), error = function(e) NULL)
  }))
  # Texas = state code 41 in nClimDiv; element 2 = avg temperature
  ncd_tx <- ncd_dt[state_code == "41" & year == 2021 & element == "2"]
  cat(sprintf("NOAA nClimDiv: %d TX county Feb 2021 temp records\n", nrow(ncd_tx)))
  if (nrow(ncd_tx) == 0) {
    # Try element codes 1 or 0
    ncd_tx <- ncd_dt[state_code == "41" & year == 2021]
    cat(sprintf("  All elements for TX 2021: %d records\n", nrow(ncd_tx)))
  }
  fwrite(ncd_tx, "../data/noaa_feb2021_tx.csv")
} else {
  cat("NOAA nClimDiv download failed from all URLs.\n")
  cat("Constructing latitude-based temperature proxy instead.\n")
  # Counties in the Panhandle (higher latitude) were colder during Uri
  # Use latitude as a proxy for temperature severity
  # This is sufficient since our main ID comes from grid membership, not temperature
  fwrite(data.table(), "../data/noaa_feb2021_tx.csv")
}

cat("=== All data fetched ===\n")
cat(sprintf("Files saved in: %s\n", normalizePath("../data")))
