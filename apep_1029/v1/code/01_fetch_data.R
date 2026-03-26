# 01_fetch_data.R — Fetch Companies House data for bunching analysis
# Strategy: Use Companies House Advanced Search API to get company counts by
# employee number ranges, supplemented with bulk BasicCompanyData for size
# distribution analysis.

source("00_packages.R")

cat("=== Fetching Companies House Data ===\n")

# ---------------------------------------------------------------------------
# APPROACH: Companies House does not expose individual employee counts via API.
# Instead, we use the Companies House Accounts bulk data endpoint.
# Companies House publishes a monthly BasicCompanyData snapshot (CSV) with
# company info, and annual accounts filings contain employee counts.
#
# For a V1 bunching paper, we use the Companies House REST API to retrieve
# company profiles in size-relevant SIC sectors, then use the annual accounts
# endpoint to extract employee counts and turnover from filed accounts.
#
# Alternative: Use the free Companies House streaming API or bulk download.
# ---------------------------------------------------------------------------

# Companies House API key (free registration)
ch_api_key <- Sys.getenv("COMPANIES_HOUSE_API_KEY")

# ---------------------------------------------------------------------------
# STRATEGY PIVOT: The Companies House API requires authentication and has
# rate limits. For a bunching paper requiring the full universe of employee
# counts, we use the ONS Business Register and Employment Survey (BRES)
# via NOMIS, which provides establishment-level employment counts by size
# band, plus the UK Business Counts data (also NOMIS) which gives exact
# counts of enterprises by employment size band at fine geographic detail.
#
# NOMIS datasets:
# - UK Business Counts (enterprises by employment size band): dataset 142
# - BRES (employees by enterprise size): dataset NM_189_1
# ---------------------------------------------------------------------------

nomis_key <- Sys.getenv("NOMIS_API_KEY")
base_url <- "https://www.nomisweb.co.uk/api/v01"

cat("Fetching UK Business Counts by employment size band from NOMIS...\n")

# =========================================================================
# Dataset 1: UK Business Counts — Enterprises by Employment Size Band
# NOMIS dataset ID: NM_142_1 (UK Business Counts - enterprises)
# This gives counts of enterprises in each size band for all UK geographies
# Available years: 2010-2024
# Size bands include: 0-4, 5-9, 10-19, 20-49, 50-99, 100-249, 250-499, etc.
# =========================================================================

fetch_nomis <- function(dataset_id, geography, time_range, measures,
                         select_cols, extra_params = "") {
  url <- paste0(base_url, "/dataset/", dataset_id, ".data.csv?",
                "geography=", geography,
                "&time=", time_range,
                "&measures=", measures,
                select_cols,
                extra_params,
                if (nzchar(nomis_key)) paste0("&uid=", nomis_key) else "")

  cat("  Requesting:", substr(url, 1, 120), "...\n")
  resp <- httr::GET(url, httr::timeout(120))

  if (httr::status_code(resp) != 200) {
    stop("NOMIS API returned status ", httr::status_code(resp),
         ": ", httr::content(resp, "text", encoding = "UTF-8"))
  }

  raw_text <- httr::content(resp, "text", encoding = "UTF-8")
  if (nchar(raw_text) < 100) {
    stop("NOMIS returned too little data: ", nchar(raw_text), " bytes")
  }

  df <- read.csv(textConnection(raw_text), stringsAsFactors = FALSE)
  cat("  Retrieved", nrow(df), "rows\n")
  return(df)
}

# Fetch UK Business Counts: enterprises by employment size band
# Geography: UK total (2092957703)
# Time: 2010-2024
# Employment size bands are in the "employment_sizeband" dimension
biz_counts <- fetch_nomis(
  dataset_id = "NM_142_1",
  geography = "2092957703",
  time_range = "2010-2024",
  measures = "20100",
  select_cols = "&select=DATE,DATE_NAME,GEOGRAPHY_NAME,EMPLOYMENT_SIZEBAND,EMPLOYMENT_SIZEBAND_NAME,MEASURES_NAME,OBS_VALUE",
  extra_params = "&legal_status=0"  # All legal statuses
)

cat("\nBusiness counts columns:", paste(names(biz_counts), collapse=", "), "\n")
cat("Size bands found:", length(unique(biz_counts$EMPLOYMENT_SIZEBAND_NAME)), "\n")
cat("Unique size bands:\n")
print(sort(unique(biz_counts$EMPLOYMENT_SIZEBAND_NAME)))

# Save raw data
fwrite(biz_counts, "../data/nomis_business_counts_raw.csv")
cat("Saved business counts:", nrow(biz_counts), "rows\n")

# =========================================================================
# Dataset 2: Inter-Departmental Business Register (IDBR) — finer size bands
# NOMIS dataset NM_141_1 gives LOCAL UNITS by employment size band
# This may have finer bins near the thresholds
# =========================================================================

cat("\nFetching IDBR local units by employment size band...\n")

local_units <- tryCatch({
  fetch_nomis(
    dataset_id = "NM_141_1",
    geography = "2092957703",
    time_range = "2010-2024",
    measures = "20100",
    select_cols = "&select=DATE,DATE_NAME,GEOGRAPHY_NAME,EMPLOYMENT_SIZEBAND,EMPLOYMENT_SIZEBAND_NAME,MEASURES_NAME,OBS_VALUE",
    extra_params = "&legal_status=0"
  )
}, error = function(e) {
  cat("  IDBR local units fetch failed:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(local_units)) {
  fwrite(local_units, "../data/nomis_local_units_raw.csv")
  cat("Saved local units:", nrow(local_units), "rows\n")
  cat("Local unit size bands:\n")
  print(sort(unique(local_units$EMPLOYMENT_SIZEBAND_NAME)))
}

# =========================================================================
# Dataset 3: BRES — Business Register and Employment Survey
# NM_189_1: Employment by size band at detailed geography
# This gives actual employment (not just firm counts) by size band
# =========================================================================

cat("\nFetching BRES employment by enterprise size...\n")

bres <- tryCatch({
  fetch_nomis(
    dataset_id = "NM_189_1",
    geography = "2092957703",
    time_range = "2015-2023",
    measures = "20100",
    select_cols = "&select=DATE,DATE_NAME,GEOGRAPHY_NAME,EMPLOYMENT_SIZEBAND,EMPLOYMENT_SIZEBAND_NAME,INDUSTRY_NAME,MEASURES_NAME,OBS_VALUE",
    extra_params = "&industry=37748736"  # All industries
  )
}, error = function(e) {
  cat("  BRES fetch failed:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(bres)) {
  fwrite(bres, "../data/nomis_bres_raw.csv")
  cat("Saved BRES:", nrow(bres), "rows\n")
}

# =========================================================================
# Dataset 4: Companies House BasicCompanyData — for universe characteristics
# Monthly bulk CSV (~468MB). We download the metadata-only version
# to characterize the universe of active UK companies.
# =========================================================================

cat("\nFetching Companies House company characteristics...\n")
cat("(Using Companies House free data API for company size distribution)\n")

# Companies House publish an "Accounts data" snapshot. Let's check
# the free bulk data endpoint for the latest BasicCompanyData
ch_bulk_url <- "http://download.companieshouse.gov.uk/en_output.html"

# Instead of downloading the full 468MB file, we'll use the Companies House
# search API to sample companies at different size points.
# The API is free but requires an API key for authenticated requests.

# For V1, use the NOMIS data as primary (universe counts by size band)
# and supplement with ONS Business Population Estimates for validation.

# =========================================================================
# Dataset 5: ONS Business Population Estimates (BPE)
# Published annually, gives enterprise counts by size band with finer
# granularity than NOMIS
# =========================================================================

cat("\nFetching ONS Business Population Estimates...\n")

bpe_url <- "https://www.ons.gov.uk/file?uri=/businessindustryandtrade/business/activitysizeandlocation/datasets/ukbusinessactivitysizeandlocation/2024/ukbusinessworkbook2024tables.xlsx"

bpe_file <- "../data/ons_bpe_2024.xlsx"
tryCatch({
  download.file(bpe_url, bpe_file, mode = "wb", quiet = TRUE)
  cat("  Downloaded BPE workbook\n")
}, error = function(e) {
  cat("  BPE download failed, trying alternative URL...\n")
  # Try data.gov.uk CKAN for BPE
  alt_url <- "https://www.ons.gov.uk/file?uri=/businessindustryandtrade/business/activitysizeandlocation/datasets/ukbusinessactivitysizeandlocation/2023/ukbusinessworkbook2023revisedtables.xlsx"
  tryCatch({
    download.file(alt_url, bpe_file, mode = "wb", quiet = TRUE)
    cat("  Downloaded BPE 2023 workbook\n")
  }, error = function(e2) {
    cat("  BPE download also failed:", conditionMessage(e2), "\n")
  })
})

# =========================================================================
# CRITICAL PIVOT: For a bunching analysis, we need the DISTRIBUTION of
# firms by exact employee count, not just counts within coarse size bands.
#
# The finest publicly available data is the ONS "UK Business; Activity,
# Size and Location" which gives counts at: 0, 1, 2-3, 4, 5-9, 10-19,
# 20-49, 50-99, 100-249, 250-499, 500-999, 1000+
#
# This is TOO COARSE for bunching at 10, 50, 250.
# We need individual-level or unit-record data.
#
# SOLUTION: Use the FAME/ORBIS database structure that Companies House
# bulk accounts data provides. Parse the actual XBRL filings for exact
# employee counts.
#
# For V1 feasibility: We can demonstrate bunching using the available
# size band data by testing for EXCESS DENSITY in bands adjacent to
# thresholds, combined with a sample of exact employee counts from the
# Companies House streaming API.
# =========================================================================

cat("\n=== Fetching Companies House Accounts via Streaming API ===\n")
cat("Downloading recent daily account filings with employee counts...\n")

# Companies House publishes daily account filing data as downloadable
# zip files. Each contains XBRL/iXBRL documents.
# For V1, we sample a cross-section from the Companies House REST API.

# Use the Companies House search endpoint to find companies with accounts
# and extract employee counts from the accounts data.

# The Advanced Company Search API allows filtering by company size
# This endpoint is publicly available
search_url <- "https://api.company-information.service.gov.uk/advanced-search/companies"

# Function to search for companies by size and extract employee info
search_companies <- function(size_category, start_index = 0) {
  if (!nzchar(ch_api_key)) {
    cat("  No COMPANIES_HOUSE_API_KEY — using NOMIS data only\n")
    return(NULL)
  }

  url <- paste0(search_url,
                "?company_status=active",
                "&size=", size_category,
                "&start_index=", start_index,
                "&size_request=100")

  resp <- httr::GET(url, httr::authenticate(ch_api_key, ""))

  if (httr::status_code(resp) == 200) {
    data <- httr::content(resp, "parsed")
    return(data)
  } else {
    cat("  Search returned status", httr::status_code(resp), "\n")
    return(NULL)
  }
}

# =========================================================================
# FINAL DATA STRATEGY: Combine multiple sources
#
# 1. NOMIS UK Business Counts (NM_142_1): Universe counts by size band
#    (10-bin resolution near thresholds) — PRIMARY for aggregate evidence
#
# 2. Companies House free filing data (parse XBRL): Exact employee
#    counts — use a sample of recent filings for microdata evidence
#
# 3. ONS BPE: Cross-validation of aggregate counts
#
# The key insight: Even coarse size bands reveal bunching when we compare
# actual counts to a smooth counterfactual across bands. The 10-19 band
# vs 20-49 band transition (at the 10-employee threshold) and the
# 50-99 vs 100-249 transition (at the 50-employee threshold) will show
# excess mass below and deficit above if firms are bunching.
# =========================================================================

# Process NOMIS data for analysis
cat("\n=== Processing NOMIS Business Counts for Bunching Analysis ===\n")

df_raw <- fread("../data/nomis_business_counts_raw.csv")
cat("Raw data:", nrow(df_raw), "rows,", ncol(df_raw), "columns\n")
cat("Years:", paste(sort(unique(df_raw$DATE_NAME)), collapse = ", "), "\n")
cat("Size bands:\n")
print(table(df_raw$EMPLOYMENT_SIZEBAND_NAME))

# =========================================================================
# Parse Companies House bulk accounts for exact employee counts
# Companies House provides free daily filing dumps
# Each is a zip of iXBRL documents with structured financial data
# =========================================================================

cat("\n=== Downloading Companies House Daily Filing Data ===\n")

# Companies House daily accounts data:
# http://download.companieshouse.gov.uk/en_accountsdata.html
# Format: Accounts_Bulk_Data-YYYY-MM-DD.zip
# Each zip contains directories with XBRL/HTML filings

# For a sample, get the latest available day's data
# The accounts bulk data URL pattern:

get_ch_accounts_date <- function(date_str) {
  url <- paste0("http://download.companieshouse.gov.uk/Accounts_Bulk_Data-",
                date_str, ".zip")
  dest <- paste0("../data/ch_accounts_", date_str, ".zip")

  cat("  Trying:", url, "\n")
  resp <- httr::HEAD(url, httr::timeout(15))

  if (httr::status_code(resp) == 200) {
    download.file(url, dest, mode = "wb", quiet = TRUE)
    cat("  Downloaded:", dest, "(", file.size(dest) / 1e6, "MB)\n")
    return(dest)
  } else {
    cat("  Not available (status", httr::status_code(resp), ")\n")
    return(NULL)
  }
}

# Try recent dates
recent_dates <- format(Sys.Date() - 1:14, "%Y-%m-%d")
ch_zip <- NULL
for (d in recent_dates) {
  ch_zip <- get_ch_accounts_date(d)
  if (!is.null(ch_zip)) break
}

# Parse employee counts from iXBRL if we got data
if (!is.null(ch_zip) && file.exists(ch_zip)) {
  cat("\nParsing employee counts from iXBRL filings...\n")

  # Extract zip
  extract_dir <- paste0("../data/ch_accounts_extracted")
  dir.create(extract_dir, showWarnings = FALSE, recursive = TRUE)

  # List files in zip
  zip_contents <- unzip(ch_zip, list = TRUE)
  cat("  Zip contains", nrow(zip_contents), "files\n")

  # Extract all files
  unzip(ch_zip, exdir = extract_dir)

  # Find HTML/XBRL files
  html_files <- list.files(extract_dir, pattern = "\\.(html|htm|xbrl)$",
                           recursive = TRUE, full.names = TRUE)
  cat("  Found", length(html_files), "filing documents\n")

  # Parse employee counts from iXBRL
  # The key XBRL tags for employee counts:
  # uk-direp:AverageNumberEmployeesDuringPeriod
  # uk-gaap:AverageNumberOfEmployeesDuringThePeriod
  # core:AverageNumberEmployeesDuringPeriod

  parse_employee_count <- function(file_path) {
    tryCatch({
      lines <- readLines(file_path, warn = FALSE, n = 500)
      text <- paste(lines, collapse = "\n")

      # Search for employee count patterns in iXBRL
      patterns <- c(
        "AverageNumberEmployeesDuringPeriod[^>]*>\\s*([0-9,]+)\\s*<",
        "NumberOfEmployees[^>]*>\\s*([0-9,]+)\\s*<",
        "AverageNumberOfEmployees[^>]*>\\s*([0-9,]+)\\s*<",
        "EmployeesTotal[^>]*>\\s*([0-9,]+)\\s*<",
        "ns\\d+:AverageNumberEmployeesDuringPeriod[^>]*>\\s*([0-9,]+)\\s*<"
      )

      for (pat in patterns) {
        m <- regmatches(text, regexpr(pat, text, perl = TRUE))
        if (length(m) > 0) {
          num <- as.numeric(gsub("[^0-9]", "",
                                 sub(".*>\\s*([0-9,]+)\\s*<.*", "\\1", m[1])))
          if (!is.na(num) && num > 0 && num < 1e6) {
            return(num)
          }
        }
      }

      return(NA_real_)
    }, error = function(e) NA_real_)
  }

  # Parse a sample of files (up to 5000)
  sample_files <- if (length(html_files) > 5000) {
    sample(html_files, 5000)
  } else {
    html_files
  }

  cat("  Parsing", length(sample_files), "filings for employee counts...\n")

  employee_counts <- vapply(sample_files, parse_employee_count, numeric(1))

  valid_counts <- employee_counts[!is.na(employee_counts)]
  cat("  Found", length(valid_counts), "filings with employee counts\n")
  cat("  (out of", length(sample_files), "parsed)\n")

  if (length(valid_counts) >= 100) {
    emp_df <- data.frame(
      employees = valid_counts,
      source = "ch_accounts"
    )
    fwrite(emp_df, "../data/ch_employee_counts.csv")
    cat("  Saved", nrow(emp_df), "employee count observations\n")
    cat("  Distribution summary:\n")
    print(summary(valid_counts))
    cat("  Counts near thresholds:\n")
    cat("    5-15:", sum(valid_counts >= 5 & valid_counts <= 15), "\n")
    cat("    40-60:", sum(valid_counts >= 40 & valid_counts <= 60), "\n")
    cat("    200-300:", sum(valid_counts >= 200 & valid_counts <= 300), "\n")
  } else {
    cat("  WARNING: Too few employee counts found. Will rely on NOMIS aggregate data.\n")
    emp_df <- data.frame(employees = integer(0), source = character(0))
    fwrite(emp_df, "../data/ch_employee_counts.csv")
  }

  # Clean up extracted files to save space
  unlink(extract_dir, recursive = TRUE)

} else {
  cat("\nWARNING: Could not download Companies House accounts data.\n")
  cat("Proceeding with NOMIS aggregate data only.\n")
  emp_df <- data.frame(employees = integer(0), source = character(0))
  fwrite(emp_df, "../data/ch_employee_counts.csv")
}

# =========================================================================
# Also fetch the BIS/BEIS Business Population Estimates from ONS API
# This gives more detailed size band breakdowns
# =========================================================================

cat("\n=== Fetching ONS Business Population Estimates via API ===\n")

# ONS Table: UK businesses — number of businesses, by number of employees
# Dataset ID: ukbusiness
ons_base <- "https://api.beta.ons.gov.uk/v1"

# Fetch BPE timeseries from ONS — enterprise counts by size band
# The BPE tables are published as Excel/CSV by BEIS
# Let's try the direct download approach

bpe_years <- 2014:2024

for (yr in bpe_years) {
  bpe_url_yr <- paste0(
    "https://www.ons.gov.uk/file?uri=/businessindustryandtrade/business/",
    "activitysizeandlocation/datasets/ukbusinessactivitysizeandlocation/",
    yr, "/ukbusinessworkbook", yr, "tables.xlsx"
  )

  dest_file <- paste0("../data/ons_bpe_", yr, ".xlsx")
  if (file.exists(dest_file)) next

  tryCatch({
    resp <- httr::HEAD(bpe_url_yr, httr::timeout(10))
    if (httr::status_code(resp) == 200) {
      download.file(bpe_url_yr, dest_file, mode = "wb", quiet = TRUE)
      cat("  Downloaded BPE", yr, "\n")
    }
  }, error = function(e) {
    cat("  BPE", yr, "not available\n")
  })
}

cat("\n=== Data Fetch Complete ===\n")
cat("Files in data directory:\n")
print(list.files("../data", full.names = FALSE))

# Final validation
stopifnot(file.exists("../data/nomis_business_counts_raw.csv"))
cat("\nPrimary data source (NOMIS business counts) confirmed.\n")
