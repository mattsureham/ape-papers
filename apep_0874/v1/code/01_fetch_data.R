# ============================================================
# 01_fetch_data.R — Fetch SNAP retailer and ACS data
# apep_0874: Feeding the Supply Side
# ============================================================

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ----------------------------------------------------------
# 1. SNAP Retailer Historical Database (USDA FNS)
# ----------------------------------------------------------
cat("=== SNAP Retailer Historical Database ===\n")

# Reuse from prior SNAP paper if available
reuse_path <- "../../apep_0753/v1/data/snap_retailers_raw.csv"
local_path <- file.path(data_dir, "snap_retailers_raw.csv")

if (file.exists(reuse_path) && !file.exists(local_path)) {
  cat("  Reusing SNAP retailer data from apep_0753...\n")
  file.copy(reuse_path, local_path)
  cat("  Copied.\n")
} else if (!file.exists(local_path)) {
  cat("  Downloading SNAP Retailer Historical Database...\n")
  retailer_url <- "https://www.fns.usda.gov/sites/default/files/resource-files/snap-retailer-locator-data2005-2025.zip"
  zip_path <- file.path(data_dir, "snap_retailers.zip")
  resp <- httr::GET(retailer_url, httr::write_disk(zip_path, overwrite = TRUE),
                    httr::timeout(300))
  stopifnot("SNAP retailer download failed" = httr::status_code(resp) == 200)
  csv_files <- unzip(zip_path, exdir = data_dir)
  main_csv <- csv_files[grepl("\\.csv$", csv_files, ignore.case = TRUE)][1]
  stopifnot("No CSV found in zip" = !is.na(main_csv))
  file.rename(main_csv, local_path)
  unlink(zip_path)
} else {
  cat("  Already exists, skipping.\n")
}

retailers <- fread(local_path, showProgress = FALSE)
cat("  Rows:", nrow(retailers), "\n")
cat("  Columns:", paste(names(retailers), collapse = ", "), "\n")
stopifnot("Need > 100K retailer rows" = nrow(retailers) > 100000)

# ----------------------------------------------------------
# 2. ACS 2019 5-Year County Data via Census API
# ----------------------------------------------------------
cat("\n=== Fetching ACS 2019 County Data ===\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) == 0) stop("CENSUS_API_KEY not found in .env")

acs_path <- file.path(data_dir, "acs_county_2019.csv")

if (!file.exists(acs_path)) {
  # Variables:
  # B22001_001E = Total households
  # B22001_002E = Households receiving SNAP
  # B01003_001E = Total population
  # B17001_001E = Population for poverty status
  # B17001_002E = Below poverty level
  # B19013_001E = Median household income
  # B02001_001E = Total pop (race)
  # B02001_003E = Black alone
  # B03003_003E = Hispanic/Latino

  vars <- "B22001_001E,B22001_002E,B01003_001E,B17001_001E,B17001_002E,B19013_001E,B02001_003E,B03003_003E"

  url <- paste0(
    "https://api.census.gov/data/2019/acs/acs5?get=NAME,", vars,
    "&for=county:*&key=", census_key
  )

  cat("  Requesting ACS 2019 5-year county data...\n")
  resp <- httr::GET(url, httr::timeout(120))
  stopifnot("Census API request failed" = httr::status_code(resp) == 200)

  raw <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
  acs <- as.data.table(raw[-1, ])  # drop header row
  setnames(acs, raw[1, ])

  # Build FIPS
  acs[, fips := paste0(state, county)]

  # Convert to numeric
  num_cols <- c("B22001_001E", "B22001_002E", "B01003_001E",
                "B17001_001E", "B17001_002E", "B19013_001E",
                "B02001_003E", "B03003_003E")
  for (col in num_cols) {
    acs[, (col) := as.numeric(get(col))]
  }

  # Compute rates
  acs[, snap_rate := fifelse(B22001_001E > 0, B22001_002E / B22001_001E, NA_real_)]
  acs[, poverty_rate := fifelse(B17001_001E > 0, B17001_002E / B17001_001E, NA_real_)]
  acs[, pct_black := fifelse(B01003_001E > 0, B02001_003E / B01003_001E, NA_real_)]
  acs[, pct_hispanic := fifelse(B01003_001E > 0, B03003_003E / B01003_001E, NA_real_)]
  acs[, population := B01003_001E]
  acs[, median_income := B19013_001E]
  acs[, snap_hh := B22001_002E]
  acs[, total_hh := B22001_001E]

  # Clean and save
  acs_clean <- acs[, .(fips, NAME, state, county, population, total_hh, snap_hh,
                        snap_rate, poverty_rate, pct_black, pct_hispanic, median_income)]

  fwrite(acs_clean, acs_path)
  cat("  Saved ACS data:", nrow(acs_clean), "counties\n")
} else {
  cat("  Already exists, loading...\n")
  acs_clean <- fread(acs_path)
}

cat("  Counties with SNAP data:", sum(!is.na(acs_clean$snap_rate)), "\n")
cat("  SNAP rate range:", round(min(acs_clean$snap_rate, na.rm = TRUE), 3), "-",
    round(max(acs_clean$snap_rate, na.rm = TRUE), 3), "\n")
cat("  SNAP rate mean:", round(mean(acs_clean$snap_rate, na.rm = TRUE), 3), "\n")

# ----------------------------------------------------------
# 3. Emergency Allotment Dates by State
# ----------------------------------------------------------
cat("\n=== EA Expiration Dates ===\n")

# State FIPS to abbreviation mapping
state_fips_map <- data.table(
  state_fips = sprintf("%02d", c(1,2,4,5,6,8,9,10,11,12,13,15,16,17,18,19,20,21,22,23,24,
                                  25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,44,
                                  45,46,47,48,49,50,51,53,54,55,56)),
  state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI","ID","IL","IN",
                  "IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
                  "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT",
                  "VT","VA","WA","WV","WI","WY")
)

# EA expiration dates (last month EA was issued)
ea_dates <- data.table(
  state_abbr = c(
    "ID","MT","ND","NE","SD","WY","TN","FL","IA","MS","MO","IN",
    "AK","AZ","AR","GA","KY","SC",
    "AL","CA","CO","CT","DE","DC","HI","IL","KS","LA","ME","MD","MA","MI","MN",
    "NV","NH","NJ","NM","NY","NC","OH","OK","OR","PA","RI","TX","UT","VT","VA",
    "WA","WV","WI"
  ),
  ea_end_date = as.Date(c(
    "2021-04-01","2021-07-01","2021-09-01","2021-07-01","2021-07-01","2021-07-01",
    "2021-07-01","2021-07-01","2021-07-01","2021-07-01","2021-07-01","2021-08-01",
    "2022-03-01","2022-04-01","2022-06-01","2022-06-01","2022-06-01","2023-01-01",
    rep("2023-02-01", 33)
  )),
  early_optout = c(rep(TRUE, 18), rep(FALSE, 33))
)

# Merge FIPS
ea_dates <- merge(ea_dates, state_fips_map, by = "state_abbr", all.x = TRUE)
saveRDS(ea_dates, file.path(data_dir, "ea_dates.rds"))

cat("  Early opt-out states:", sum(ea_dates$early_optout), "\n")
cat("  Late termination states:", sum(!ea_dates$early_optout), "\n")

# ----------------------------------------------------------
# 4. QWI Food Retail Employment (Azure)
# ----------------------------------------------------------
cat("\n=== Checking QWI Data on Azure ===\n")

qwi_available <- FALSE
tryCatch({
  source("../../../../scripts/lib/azure_data.R")
  con <- apep_azure_connect()

  # Check if QWI data exists
  test_query <- "SELECT COUNT(*) as n FROM read_parquet('az://derived/qwi/rh/n3/*.parquet') LIMIT 1"
  test_result <- DBI::dbGetQuery(con, test_query)

  if (test_result$n > 0) {
    cat("  QWI data found on Azure:", test_result$n, "rows\n")

    # Extract food retail (NAICS 4451) county-quarter data
    qwi_query <- "
      SELECT
        geography AS fips,
        CAST(year AS INTEGER) AS year,
        CAST(quarter AS INTEGER) AS quarter,
        industry AS naics,
        CAST(Emp AS DOUBLE) AS emp,
        CAST(EmpEnd AS DOUBLE) AS emp_end,
        CAST(EmpS AS DOUBLE) AS emp_stable,
        CAST(HirA AS DOUBLE) AS hires,
        CAST(FrmJbGn AS DOUBLE) AS firm_job_gains
      FROM read_parquet('az://derived/qwi/rh/n3/*.parquet')
      WHERE industry = '4451'
        AND geo_level = 'C'
        AND year >= 2016 AND year <= 2024
    "

    qwi_data <- DBI::dbGetQuery(con, qwi_query)
    qwi_data <- as.data.table(qwi_data)

    if (nrow(qwi_data) > 0) {
      cat("  QWI food retail rows:", nrow(qwi_data), "\n")
      fwrite(qwi_data, file.path(data_dir, "qwi_food_retail.csv"))
      qwi_available <- TRUE
    } else {
      cat("  QWI query returned 0 rows for NAICS 4451.\n")
    }
  }

  apep_azure_disconnect(con)
}, error = function(e) {
  cat("  QWI Azure access failed:", conditionMessage(e), "\n")
  cat("  Proceeding without QWI data.\n")
})

# Save flag
saveRDS(qwi_available, file.path(data_dir, "qwi_available.rds"))

cat("\n=== Data Fetch Complete ===\n")
cat("  SNAP retailers:", nrow(retailers), "rows\n")
cat("  ACS counties:", nrow(acs_clean), "\n")
cat("  QWI available:", qwi_available, "\n")
