# 01_fetch_data.R — Fetch dispensary list and QWI employment data
# apep_1335: Cannabis Lottery and Local Economic Renewal

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# PART 1: IDFPR Adult-Use Dispensary License List
# ============================================================================

cat("=== Fetching IDFPR dispensary data ===\n")

# The IDFPR maintains a public list of adult-use dispensaries
# We use the structured data from the Illinois cannabis portal
# First try the PDF, then parse it

dispensary_url <- "https://idfpr.illinois.gov/content/dam/soi/en/web/idfpr/licenselookup/adultusedispensaries.pdf"
pdf_path <- file.path(data_dir, "idfpr_dispensaries.pdf")

resp <- httr::GET(dispensary_url, httr::write_disk(pdf_path, overwrite = TRUE))
stopifnot("Failed to download IDFPR dispensary PDF" = httr::status_code(resp) == 200)
cat("Downloaded IDFPR dispensary PDF:", file.size(pdf_path), "bytes\n")

# Extract text from PDF
pdf_text <- pdftools::pdf_text(pdf_path)
cat("PDF pages:", length(pdf_text), "\n")

# Parse the dispensary list from PDF text
# The PDF contains: License Number, DBA Name, Address, City, State, Zip, License Type, Issue Date
lines <- unlist(strsplit(paste(pdf_text, collapse = "\n"), "\n"))
lines <- trimws(lines)
lines <- lines[nchar(lines) > 10]  # Remove short/empty lines

# Parse structured dispensary data
# Look for lines with Illinois addresses (contain ", IL")
address_lines <- lines[grepl(", IL\\s+\\d{5}", lines, ignore.case = TRUE)]
cat("Found", length(address_lines), "address lines in PDF\n")

# Alternative approach: use the Illinois Data Portal / IDFPR lookup
# The PDF parsing may be fragile, so let's also construct treatment data
# from known lottery information

# Known lottery dates and structure (from public records):
# Round 1: Qualifying Applicant Lottery - July 29, 2021 (55 licenses)
# Round 2: Social Equity Justice Involved - August 5, 2021 (55 licenses)
# Round 3: Tied Applicant - August 19, 2021 (75 licenses)
# Round 4: SECL - July 13, 2023 (55 licenses)

# Parse PDF more carefully
# Try to extract structured fields
dispensary_records <- list()

for (page_text in pdf_text) {
  page_lines <- unlist(strsplit(page_text, "\n"))
  page_lines <- trimws(page_lines)

  for (line in page_lines) {
    # Try to match: License# ... Name ... Address, City, IL ZIP ... Date
    if (grepl("\\d{5,}", line) && grepl(", IL", line, ignore.case = TRUE)) {
      # Extract zip code
      zip_match <- regmatches(line, regexpr("\\b\\d{5}\\b", line))
      # Extract city/state
      city_match <- regmatches(line, regexpr("[A-Z][a-z]+(?:[ ][A-Z][a-z]+)*, IL", line))

      if (length(zip_match) > 0) {
        dispensary_records <- c(dispensary_records, list(list(
          raw_line = line,
          zip = zip_match[1],
          city_state = ifelse(length(city_match) > 0, city_match[1], NA)
        )))
      }
    }
  }
}

cat("Parsed", length(dispensary_records), "dispensary records from PDF\n")

# Convert to data frame
if (length(dispensary_records) > 0) {
  dispensary_df <- bind_rows(lapply(dispensary_records, as.data.frame))
} else {
  # If PDF parsing fails, use the known dispensary data from IDFPR website
  cat("WARNING: PDF parsing yielded few results. Using Illinois open data.\n")
  dispensary_df <- data.frame(raw_line = character(), zip = character(),
                               city_state = character())
}

# ============================================================================
# PART 1B: Supplement with Illinois Open Data Portal
# ============================================================================

# Query the Illinois cannabis dispensary data from data.illinois.gov
# Adult-use dispensary licenses dataset
cat("=== Fetching from Illinois Open Data Portal ===\n")

il_data_url <- "https://data.illinois.gov/api/views/rgw6-baj8/rows.csv?accessType=DOWNLOAD"
il_csv_path <- file.path(data_dir, "il_dispensaries_opendata.csv")

resp2 <- tryCatch({
  httr::GET(il_data_url, httr::write_disk(il_csv_path, overwrite = TRUE),
            httr::timeout(60))
}, error = function(e) {
  cat("Open data portal unavailable:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(resp2) && httr::status_code(resp2) == 200 && file.size(il_csv_path) > 500) {
  cat("Downloaded Illinois open data CSV:", file.size(il_csv_path), "bytes\n")
  il_open <- read.csv(il_csv_path, stringsAsFactors = FALSE)
  cat("Columns:", paste(names(il_open), collapse = ", "), "\n")
  cat("Rows:", nrow(il_open), "\n")
} else {
  cat("Open data portal did not return usable data.\n")
  il_open <- NULL
}

# ============================================================================
# PART 1C: Construct Treatment Panel from Known Lottery Structure
# ============================================================================

# Since PDF parsing and open data may be incomplete, construct the treatment
# variable from the known institutional details of the lottery rounds.
# We know:
# - 185 conditional licenses awarded in 3 lotteries (July-Aug 2021)
# - 55 additional in SECL (July 2023)
# - Actual store openings lagged license awards by 6-18 months
# - By 2026, 134+ social equity lottery winners are active

# For the county-level analysis, the key treatment variable is:
# "Quarter of first lottery-dispensary opening in county c"

# We need dispensary locations. Let's use the IDFPR PDF data more carefully.
# Extract all dispensary info including license dates

# Re-parse focusing on date patterns (MM/DD/YYYY)
date_pattern <- "\\d{1,2}/\\d{1,2}/\\d{4}"
license_pattern <- "\\d{6,8}-\\d+"

all_records <- data.frame(
  page = integer(),
  line_num = integer(),
  raw = character(),
  stringsAsFactors = FALSE
)

for (p in seq_along(pdf_text)) {
  page_lines <- unlist(strsplit(pdf_text[[p]], "\n"))
  page_lines <- trimws(page_lines)
  for (i in seq_along(page_lines)) {
    ln <- page_lines[i]
    if (nchar(ln) > 20) {
      all_records <- rbind(all_records, data.frame(
        page = p, line_num = i, raw = ln, stringsAsFactors = FALSE
      ))
    }
  }
}

cat("Total parseable lines from PDF:", nrow(all_records), "\n")

# Try to identify social equity / lottery dispensaries
# Social equity licenses typically have specific license number prefixes
# or are listed under "Social Equity" category in the PDF

se_lines <- all_records[grepl("social equity|lottery|conditional",
                               all_records$raw, ignore.case = TRUE), ]
cat("Lines mentioning social equity/lottery/conditional:", nrow(se_lines), "\n")

# ============================================================================
# PART 2: Census QWI Data via API
# ============================================================================

cat("\n=== Fetching Census QWI data ===\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) == 0) census_key <- Sys.getenv("CENSUS_KEY")

# Fetch QWI for Illinois (FIPS 17), all counties
# Variables: Emp (employment), EarnBeg (beginning-of-quarter earnings),
#            EmpS (stable employment), Payroll
# Industries: 44-45 (Retail Trade), 7225 (Food Services), 00 (Total Private)
# Years: 2018-2025, all quarters

qwi_base <- "https://api.census.gov/data/timeseries/qwi/sa"

fetch_qwi <- function(year, quarter, industry, key) {
  url <- paste0(qwi_base,
    "?get=Emp,EarnBeg,EmpS,Payroll",
    "&for=county:*",
    "&in=state:17",
    "&year=", year,
    "&quarter=", quarter,
    "&industry=", industry,
    "&sex=0&agegrp=A00&race=A0&ethnicity=A0",
    "&education=E0&firmage=0&firmsize=0",
    "&ownercode=A05&seasonadj=U")
  if (nchar(key) > 0) url <- paste0(url, "&key=", key)

  resp <- tryCatch(
    httr::GET(url, httr::timeout(30)),
    error = function(e) NULL
  )

  if (is.null(resp) || httr::status_code(resp) != 200) {
    return(NULL)
  }

  json <- httr::content(resp, as = "text", encoding = "UTF-8")
  dat <- jsonlite::fromJSON(json)

  if (is.null(dat) || nrow(dat) < 2) return(NULL)

  df <- as.data.frame(dat[-1, ], stringsAsFactors = FALSE)
  names(df) <- dat[1, ]
  df$year <- year
  df$quarter <- quarter
  df$industry_code <- industry
  return(df)
}

# Define parameters
years <- 2018:2025
quarters <- 1:4
industries <- c("44-45", "7225", "00")  # Retail, Food Service, Total Private

cat("Fetching QWI: IL counties ×", length(years), "years ×",
    length(quarters), "quarters ×", length(industries), "industries\n")

qwi_all <- list()
fetch_count <- 0
fail_count <- 0

for (yr in years) {
  for (qtr in quarters) {
    # Skip future quarters
    if (yr == 2025 && qtr > 4) next
    if (yr == 2026) next

    for (ind in industries) {
      result <- fetch_qwi(yr, qtr, ind, census_key)
      fetch_count <- fetch_count + 1

      if (!is.null(result) && nrow(result) > 0) {
        qwi_all[[length(qwi_all) + 1]] <- result
      } else {
        fail_count <- fail_count + 1
      }

      # Rate limiting
      Sys.sleep(0.3)
    }
  }
  cat("  Completed year", yr, "- fetched:", fetch_count, "failed:", fail_count, "\n")
}

cat("Total QWI fetches:", fetch_count, "| Successful:", length(qwi_all),
    "| Failed:", fail_count, "\n")

stopifnot("No QWI data retrieved — check API key and Census API status" = length(qwi_all) > 0)

qwi_df <- bind_rows(qwi_all)

# Clean numeric columns
qwi_df <- qwi_df %>%
  mutate(
    across(c(Emp, EarnBeg, EmpS, Payroll), as.numeric),
    county_fips = paste0(state, county),
    year = as.integer(year),
    quarter = as.integer(quarter),
    yearqtr = year + (quarter - 1) / 4
  )

cat("QWI panel dimensions:", nrow(qwi_df), "rows ×", ncol(qwi_df), "cols\n")
cat("Counties:", n_distinct(qwi_df$county_fips), "\n")
cat("Year range:", min(qwi_df$year), "-", max(qwi_df$year), "\n")
cat("Industries:", paste(unique(qwi_df$industry_code), collapse = ", "), "\n")

# ============================================================================
# PART 3: County Names and BLS Regions
# ============================================================================

cat("\n=== Adding county metadata ===\n")

# Get Illinois county FIPS codes and names
il_counties <- tigris::fips_codes %>%
  filter(state_code == "17") %>%
  mutate(county_fips = paste0(state_code, county_code)) %>%
  select(county_fips, county_name = county) %>%
  distinct()

cat("Illinois counties from FIPS codes:", nrow(il_counties), "\n")

# BLS regions for Illinois (17 Metropolitan Statistical Areas)
# Map counties to their BLS/MSA regions
# Key MSAs: Chicago-Naperville-Elgin, Peoria, Springfield, etc.
# For simplicity, we'll use MSA-based groupings

# ============================================================================
# PART 4: Construct Treatment Variables
# ============================================================================

cat("\n=== Constructing treatment variables ===\n")

# The treatment variable is based on when the first lottery-allocated
# dispensary opened in each county. We need to determine this from the
# IDFPR data.

# Known facts from IDFPR and public reporting:
# - Lottery licenses were awarded starting July 2021
# - Actual openings began approximately Q1 2022 due to local zoning,
#   buildout, and regulatory approvals
# - By 2024, most lottery winners in the Chicago metro area had opened
# - Rural counties saw later openings

# Parse actual dispensary locations from the PDF
# Look for address patterns: number + street + city + IL + zip
address_pattern <- "\\d+\\s+[A-Za-z ]+(?:St|Ave|Rd|Blvd|Dr|Ln|Ct|Way|Pkwy|Hwy|Route)[.,]?\\s+[A-Za-z ]+,?\\s+IL\\s+\\d{5}"

addresses <- character()
for (line in all_records$raw) {
  m <- regmatches(line, regexpr(address_pattern, line, ignore.case = TRUE))
  if (length(m) > 0) addresses <- c(addresses, m)
}

cat("Extracted", length(addresses), "addresses from PDF\n")

# Also try extracting just city + zip combinations
city_zip <- character()
for (line in all_records$raw) {
  m <- regmatches(line, gregexpr("[A-Z][a-zA-Z ]+,?\\s+IL\\s+\\d{5}", line))[[1]]
  if (length(m) > 0) city_zip <- c(city_zip, m)
}
city_zip <- unique(city_zip)
cat("Unique city-zip combinations:", length(city_zip), "\n")

# Map zip codes to counties using tigris
if (length(city_zip) > 0) {
  zips <- regmatches(city_zip, regexpr("\\d{5}", city_zip))
  zips <- unique(zips)
  cat("Unique zip codes:", length(zips), "\n")
}

# Use HUD USPS ZIP-County crosswalk or Census ZCTA
# For now, use a simpler approach: geocode city names to counties

# Extract unique cities
cities <- gsub(",?\\s+IL\\s+\\d{5}", "", city_zip)
cities <- trimws(cities)
cities <- unique(cities)
cat("Unique cities:", length(cities), "\n")

# Create a dispensary-to-county mapping
# Use the Illinois zip-to-county crosswalk
zip_county_url <- "https://www2.census.gov/geo/docs/maps-data/data/rel2020/zcta520/tab20_zcta520_county20_natl.txt"
zc_path <- file.path(data_dir, "zip_county_crosswalk.txt")

resp_zc <- tryCatch(
  httr::GET(zip_county_url, httr::write_disk(zc_path, overwrite = TRUE), httr::timeout(30)),
  error = function(e) NULL
)

if (!is.null(resp_zc) && httr::status_code(resp_zc) == 200) {
  zc_raw <- read.delim(zc_path, header = TRUE, sep = "|", stringsAsFactors = FALSE)
  cat("Zip-county crosswalk rows:", nrow(zc_raw), "\n")

  # Filter to Illinois
  zc_il <- zc_raw %>%
    filter(substr(GEOID_COUNTY_20, 1, 2) == "17") %>%
    mutate(
      zip = sprintf("%05d", as.integer(GEOID_ZCTA5_20)),
      county_fips = GEOID_COUNTY_20
    ) %>%
    group_by(zip) %>%
    # If a zip spans multiple counties, take the one with most area/population
    slice_max(order_by = AREALAND_PART, n = 1, with_ties = FALSE) %>%
    ungroup() %>%
    select(zip, county_fips)

  cat("Illinois zip-county pairs:", nrow(zc_il), "\n")
} else {
  cat("WARNING: Could not fetch zip-county crosswalk\n")
  zc_il <- data.frame(zip = character(), county_fips = character())
}

# Map dispensary zips to counties
if (exists("zips") && length(zips) > 0 && nrow(zc_il) > 0) {
  disp_counties <- data.frame(zip = zips, stringsAsFactors = FALSE) %>%
    left_join(zc_il, by = "zip") %>%
    filter(!is.na(county_fips))

  cat("Dispensaries mapped to counties:", nrow(disp_counties), "\n")
  cat("Unique counties with dispensaries:", n_distinct(disp_counties$county_fips), "\n")
}

# ============================================================================
# PART 5: Construct Treatment Timing from License Dates
# ============================================================================

# Parse license issue dates from the PDF to determine opening timing
# Look for date patterns in the raw PDF text
date_records <- list()

for (i in seq_len(nrow(all_records))) {
  line <- all_records$raw[i]
  dates <- regmatches(line, gregexpr("\\d{1,2}/\\d{1,2}/\\d{4}", line))[[1]]
  if (length(dates) > 0) {
    for (d in dates) {
      parsed_date <- tryCatch(as.Date(d, format = "%m/%d/%Y"), error = function(e) NA)
      if (!is.na(parsed_date)) {
        date_records <- c(date_records, list(list(
          line_num = i,
          raw_line = line,
          date = parsed_date
        )))
      }
    }
  }
}

cat("Found", length(date_records), "date records in PDF\n")

if (length(date_records) > 0) {
  date_df <- bind_rows(lapply(date_records, function(x) {
    data.frame(line_num = x$line_num, date = x$date, raw = x$raw_line,
               stringsAsFactors = FALSE)
  }))

  cat("License date range:", as.character(min(date_df$date)), "to",
      as.character(max(date_df$date)), "\n")

  # Lottery licenses were issued starting mid-2021
  # Pre-existing (early) licenses were issued 2019-2020
  lottery_dates <- date_df %>%
    filter(date >= as.Date("2021-07-01"))

  cat("Post-lottery license dates:", nrow(lottery_dates), "\n")
}

# ============================================================================
# SAVE ALL DATA
# ============================================================================

cat("\n=== Saving data ===\n")

saveRDS(qwi_df, file.path(data_dir, "qwi_illinois.rds"))
cat("Saved QWI data:", nrow(qwi_df), "rows\n")

if (nrow(dispensary_df) > 0) {
  saveRDS(dispensary_df, file.path(data_dir, "dispensaries_pdf.rds"))
}

if (exists("disp_counties") && nrow(disp_counties) > 0) {
  saveRDS(disp_counties, file.path(data_dir, "dispensary_counties.rds"))
}

if (exists("il_open") && !is.null(il_open) && nrow(il_open) > 0) {
  saveRDS(il_open, file.path(data_dir, "dispensaries_opendata.rds"))
}

saveRDS(il_counties, file.path(data_dir, "il_counties.rds"))

if (nrow(zc_il) > 0) {
  saveRDS(zc_il, file.path(data_dir, "zip_county_il.rds"))
}

cat("\n=== Data fetch complete ===\n")
cat("Files saved to:", normalizePath(data_dir), "\n")
