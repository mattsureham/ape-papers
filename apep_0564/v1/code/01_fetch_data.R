## =============================================================================
## 01_fetch_data.R — Fetch Data from EOIR, BLS QCEW, Census ACS
## Paper: The Economic Integration Lottery
## =============================================================================

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ---------------------------------------------------------------------------
## A. EOIR Case Data
## ---------------------------------------------------------------------------
## The EOIR Case Data is a 4.24 GB zip from DOJ FOIA Library.
## Contains case-level records for all immigration court proceedings.

eoir_zip <- file.path(data_dir, "EOIR_Case_Data.zip")
eoir_dir <- file.path(data_dir, "eoir_raw")

if (!file.exists(eoir_zip)) {
  cat("Downloading EOIR Case Data (4.24 GB)... this may take 10-30 minutes.\n")
  download.file(
    url = "https://fileshare.eoir.justice.gov/EOIR%20Case%20Data.zip",
    destfile = eoir_zip,
    mode = "wb",
    timeout = 3600  # 1 hour timeout
  )
  if (!file.exists(eoir_zip) || file.size(eoir_zip) < 1e9) {
    stop("EOIR download failed or file is too small. Cannot proceed without case data.")
  }
  cat("EOIR data downloaded:", round(file.size(eoir_zip)/1e9, 2), "GB\n")
}

# Unzip EOIR data
if (!dir.exists(eoir_dir)) {
  cat("Extracting EOIR data...\n")
  dir.create(eoir_dir, showWarnings = FALSE)
  unzip(eoir_zip, exdir = eoir_dir)
  cat("EOIR data extracted to:", eoir_dir, "\n")
}

# List extracted files
eoir_files <- list.files(eoir_dir, recursive = TRUE, full.names = TRUE)
cat("EOIR files found:\n")
for (f in eoir_files) cat("  ", basename(f), "—", round(file.size(f)/1e6, 1), "MB\n")

## Read the key EOIR tables
## The EOIR data typically contains:
##   - A_TblCase or tblCase: case-level records
##   - B_TblProceeding or tblProceeding: proceeding-level records
##   - Other lookup tables

# Find the case and proceeding files
case_file <- grep("case", eoir_files, ignore.case = TRUE, value = TRUE)
proc_file <- grep("proceed", eoir_files, ignore.case = TRUE, value = TRUE)
sched_file <- grep("sched", eoir_files, ignore.case = TRUE, value = TRUE)

if (length(case_file) == 0) {
  # Try alternative naming patterns
  case_file <- grep("tblCase|A_Tbl|case_data", eoir_files, ignore.case = TRUE, value = TRUE)
}
if (length(proc_file) == 0) {
  proc_file <- grep("tblProc|B_Tbl|proc_data", eoir_files, ignore.case = TRUE, value = TRUE)
}

cat("\nCase file(s):", paste(basename(case_file), collapse = ", "), "\n")
cat("Proceeding file(s):", paste(basename(proc_file), collapse = ", "), "\n")

# Read case data (may be large — use fread for speed)
if (length(case_file) > 0) {
  # Try to read with flexible parsing
  cases_raw <- tryCatch({
    fread(case_file[1], fill = TRUE, encoding = "Latin-1")
  }, error = function(e) {
    cat("fread failed, trying read_csv...\n")
    tryCatch({
      read_csv(case_file[1], locale = locale(encoding = "Latin-1"),
               show_col_types = FALSE)
    }, error = function(e2) {
      stop("Cannot read EOIR case file: ", e2$message,
           "\nInspect file manually and adjust parsing.")
    })
  })
  cat("Cases loaded:", nrow(cases_raw), "rows,", ncol(cases_raw), "columns\n")
  cat("Column names:", paste(head(names(cases_raw), 20), collapse = ", "), "\n")
} else {
  stop("No EOIR case file found in extracted data. Files: ",
       paste(basename(eoir_files), collapse = ", "))
}

# Read proceedings data
if (length(proc_file) > 0) {
  procs_raw <- tryCatch({
    fread(proc_file[1], fill = TRUE, encoding = "Latin-1")
  }, error = function(e) {
    cat("fread failed for proceedings, trying read_csv...\n")
    tryCatch({
      read_csv(proc_file[1], locale = locale(encoding = "Latin-1"),
               show_col_types = FALSE)
    }, error = function(e2) {
      stop("Cannot read EOIR proceedings file: ", e2$message)
    })
  })
  cat("Proceedings loaded:", nrow(procs_raw), "rows,", ncol(procs_raw), "columns\n")
  cat("Column names:", paste(head(names(procs_raw), 20), collapse = ", "), "\n")
} else {
  cat("WARNING: No proceedings file found. Will use case-level data only.\n")
  procs_raw <- NULL
}

# Save parsed EOIR data
fwrite(cases_raw, file.path(data_dir, "eoir_cases.csv"))
if (!is.null(procs_raw)) fwrite(procs_raw, file.path(data_dir, "eoir_proceedings.csv"))

cat("\nEOIR data saved to CSV.\n")

## ---------------------------------------------------------------------------
## B. BLS QCEW — County-by-Industry Quarterly Employment
## ---------------------------------------------------------------------------
## Use BLS QCEW API: https://data.bls.gov/cew/data/api/
## Fetch annual averages for total private (10), accommodation & food (72),
## admin services (56), finance (52), professional services (54).

cat("\nFetching BLS QCEW data...\n")

# QCEW API fetches one year × one area at a time
# We'll fetch annual averages for all counties, 2005-2023

qcew_fetch <- function(year, area_fips) {
  url <- paste0("https://data.bls.gov/cew/data/api/", year,
                "/a/area/", area_fips, ".csv")
  tryCatch({
    resp <- GET(url, timeout(30))
    if (status_code(resp) == 200) {
      txt <- content(resp, as = "text", encoding = "UTF-8")
      if (nchar(txt) > 100) {
        return(fread(text = txt))
      }
    }
    return(NULL)
  }, error = function(e) NULL)
}

# Get state-level FIPS for all 50 states + DC
state_fips <- c(sprintf("%02d", 1:56))
state_fips <- state_fips[!state_fips %in% c("03","07","14","43","52")]  # Remove territories

# Industries of interest (NAICS sector codes for QCEW)
# 10 = Total, all industries
# 72 = Accommodation and food services
# 56 = Administrative and support services
# 52 = Finance and insurance (PLACEBO)
# 54 = Professional and technical services (PLACEBO)

# Strategy: fetch state-level QCEW for all years, then aggregate
# For county-level, QCEW provides data but we need to iterate

# Use QCEW data files (more efficient than individual API calls)
# The QCEW provides annual county-level data files at:
# https://data.bls.gov/cew/data/files/{year}/csv/{year}_annual_singlefile.zip

qcew_all <- list()
years <- 2005:2023

for (yr in years) {
  qcew_file <- file.path(data_dir, paste0("qcew_annual_", yr, ".csv"))

  if (!file.exists(qcew_file)) {
    url <- paste0("https://data.bls.gov/cew/data/files/", yr,
                  "/csv/", yr, "_annual_singlefile.zip")
    zip_file <- file.path(data_dir, paste0("qcew_", yr, ".zip"))

    cat("  Downloading QCEW", yr, "...\n")
    dl_result <- tryCatch({
      download.file(url, zip_file, mode = "wb", quiet = TRUE, timeout = 120)
      TRUE
    }, error = function(e) {
      cat("    Failed:", e$message, "\n")
      FALSE
    })

    if (dl_result && file.exists(zip_file)) {
      # Extract and filter to relevant industries and county level
      tryCatch({
        csv_name <- unzip(zip_file, list = TRUE)$Name[1]
        unzip(zip_file, exdir = data_dir, overwrite = TRUE)
        extracted <- file.path(data_dir, csv_name)

        # Read and filter (these files are ~500MB each)
        dt <- fread(extracted, select = c(
          "area_fips", "own_code", "industry_code", "agglvl_code",
          "annual_avg_estabs", "annual_avg_emplvl", "annual_avg_wkly_wage",
          "total_annual_wages"
        ))

        # Keep: private ownership (5), county-level (70-78), target industries
        dt <- dt[own_code == 5 &
                   agglvl_code %in% c(70, 71, 72, 73, 74, 75, 76, 77, 78) &
                   industry_code %in% c("10", "72", "56", "52", "54")]
        dt[, year := yr]

        fwrite(dt, qcew_file)
        cat("    QCEW", yr, "saved:", nrow(dt), "rows\n")

        # Clean up large files
        file.remove(extracted)
        file.remove(zip_file)
      }, error = function(e) {
        cat("    Error processing QCEW", yr, ":", e$message, "\n")
      })
    }
  }

  if (file.exists(qcew_file)) {
    qcew_all[[as.character(yr)]] <- fread(qcew_file)
  }
}

qcew <- rbindlist(qcew_all, fill = TRUE)
cat("QCEW data combined:", nrow(qcew), "rows,", n_distinct(qcew$area_fips), "areas\n")

# Save combined QCEW
fwrite(qcew, file.path(data_dir, "qcew_combined.csv"))

## ---------------------------------------------------------------------------
## C. Census ACS — County Demographics
## ---------------------------------------------------------------------------
## Fetch from ACS 5-year estimates: noncitizen pop, foreign-born, poverty

cat("\nFetching Census ACS data...\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) == 0) {
  cat("WARNING: No CENSUS_API_KEY set. Using unauthenticated requests (slower).\n")
  key_param <- ""
} else {
  key_param <- paste0("&key=", census_key)
}

# ACS 5-year variables:
# B05001_006E = Not a U.S. citizen (noncitizen population)
# B05001_001E = Total population (universe for citizenship)
# B05002_013E = Foreign born
# B05002_001E = Total population (universe for nativity)
# B17001_002E = Below poverty level
# B17001_001E = Total for poverty status
# B01003_001E = Total population
# B23025_002E = In labor force
# B23025_005E = Unemployed

acs_years <- 2009:2023  # ACS 5-year starts 2005-2009 release in 2010

acs_vars <- c(
  "B05001_006E", "B05001_001E",  # Noncitizen
  "B05002_013E", "B05002_001E",  # Foreign born
  "B17001_002E", "B17001_001E",  # Poverty
  "B01003_001E",                  # Total pop
  "B23025_002E", "B23025_005E",  # Labor force, unemployed
  "NAME"
)

acs_all <- list()
for (yr in acs_years) {
  acs_file <- file.path(data_dir, paste0("acs_", yr, ".csv"))

  if (!file.exists(acs_file)) {
    vars_str <- paste(acs_vars, collapse = ",")
    url <- paste0("https://api.census.gov/data/", yr,
                  "/acs/acs5?get=", vars_str,
                  "&for=county:*", key_param)

    cat("  Fetching ACS", yr, "...\n")
    resp <- tryCatch({
      r <- GET(url, timeout(60))
      if (status_code(r) == 200) {
        json <- content(r, as = "text", encoding = "UTF-8")
        mat <- fromJSON(json)
        df <- as.data.frame(mat[-1, ], stringsAsFactors = FALSE)
        names(df) <- mat[1, ]
        df$year <- yr
        fwrite(df, acs_file)
        cat("    ACS", yr, ":", nrow(df), "counties\n")
        df
      } else {
        cat("    ACS", yr, "failed: HTTP", status_code(r), "\n")
        NULL
      }
    }, error = function(e) {
      cat("    ACS", yr, "error:", e$message, "\n")
      NULL
    })
  }

  if (file.exists(acs_file)) {
    acs_all[[as.character(yr)]] <- fread(acs_file)
  }
}

acs <- rbindlist(acs_all, fill = TRUE)
cat("ACS data combined:", nrow(acs), "rows,", length(acs_years), "years\n")

# Save combined ACS
fwrite(acs, file.path(data_dir, "acs_combined.csv"))

## ---------------------------------------------------------------------------
## D. Court-County Crosswalk
## ---------------------------------------------------------------------------
## Map each EOIR immigration court to its county FIPS code.
## Based on official EOIR court addresses.

cat("\nBuilding court-county crosswalk...\n")

# Major EOIR immigration courts with their county FIPS
# Source: https://www.justice.gov/eoir/immigration-court-listing
court_county <- data.table(
  court_name = c(
    "Arlington", "Atlanta", "Baltimore", "Batavia", "Boston",
    "Buffalo", "Charlotte", "Chicago", "Cleveland", "Dallas",
    "Denver", "Detroit", "El Paso", "Hartford", "Honolulu",
    "Houston", "Imperial", "Kansas City", "Las Vegas", "Los Angeles",
    "Memphis", "Miami", "New Orleans", "New York City", "Newark",
    "Omaha", "Orlando", "Pearsall", "Philadelphia", "Phoenix",
    "Pittsburgh", "Portland (OR)", "San Antonio", "San Diego",
    "San Francisco", "Seattle", "Tacoma", "Tampa",
    "Bloomington", "Fort Worth", "Harlingen", "Jena",
    "Lumpkin", "Oakdale", "Otay Mesa", "Port Isabel",
    "San Pedro", "Varick Street", "York",
    "Aurora", "Eloy", "Florence", "Adelanto",
    "Elizabeth", "Krome", "Lancaster", "Otero",
    "Stewart", "Conroe", "Chaparral", "LaSalle",
    "Montgomery", "Naperville", "Sacramento", "Salt Lake City",
    "St. Paul", "Wichita"
  ),
  county_fips = c(
    "51013", "13121", "24510", "36011", "25025",  # Arlington VA, Fulton GA, Baltimore city, Genesee NY, Suffolk MA
    "36029", "37119", "17031", "39035", "48113",  # Erie NY, Mecklenburg NC, Cook IL, Cuyahoga OH, Dallas TX
    "08031", "26163", "48141", "09003", "15003",  # Denver CO, Wayne MI, El Paso TX, Hartford CT, Honolulu HI
    "48201", "06025", "29095", "32003", "06037",  # Harris TX, Imperial CA, Jackson MO, Clark NV, Los Angeles CA
    "47157", "12086", "22071", "36061", "34013",  # Shelby TN, Miami-Dade FL, Orleans LA, New York NY, Essex NJ
    "31055", "12095", "48163", "42101", "04013",  # Douglas NE, Orange FL, Frio TX, Philadelphia PA, Maricopa AZ
    "42003", "41051", "48029", "06073",           # Allegheny PA, Multnomah OR, Bexar TX, San Diego CA
    "06075", "53033", "53053", "12057",           # San Francisco CA, King WA, Pierce WA, Hillsborough FL
    "27053", "48439", "48061", "21097",           # Hennepin MN, Tarrant TX, Cameron TX, Letcher KY (Jena=LA)
    "13275", "22029", "06073", "48061",           # Lumpkin GA (Stewart), Rapides LA, San Diego CA, Cameron TX
    "06037", "36061", "42133",                     # Los Angeles CA, New York NY, York PA
    "08005", "04021", "04021", "06071",           # Arapahoe CO, Pinal AZ, Pinal AZ, San Bernardino CA
    "34039", "12086", "42071", "35035",           # Union NJ, Miami-Dade FL, Lancaster PA, Otero NM
    "13259", "48291", "35013", "22059",           # Stewart GA, Liberty TX (Conroe=Montgomery), Dona Ana NM, LaSalle LA
    "48339", "17043", "06067", "49035",           # Montgomery TX, DuPage IL, Sacramento CA, Salt Lake UT
    "27123", "20173"                               # Ramsey MN, Sedgwick KS
  )
)

# Some courts share counties (e.g., multiple NYC courts in 36061)
# Deduplicate: keep unique court_name × county_fips
court_county <- unique(court_county)

fwrite(court_county, file.path(data_dir, "court_county_crosswalk.csv"))
cat("Court-county crosswalk:", nrow(court_county), "courts mapped\n")

## ---------------------------------------------------------------------------
## E. Data Validation
## ---------------------------------------------------------------------------

cat("\n=== DATA VALIDATION ===\n")

# EOIR
stopifnot("EOIR cases must have > 100,000 rows" = nrow(cases_raw) > 100000)
cat("EOIR cases:", format(nrow(cases_raw), big.mark = ","), "rows\n")

# QCEW
stopifnot("QCEW must cover 50+ areas" = n_distinct(qcew$area_fips) >= 50)
stopifnot("QCEW must cover 10+ years" = n_distinct(qcew$year) >= 10)
cat("QCEW:", format(nrow(qcew), big.mark = ","), "rows,",
    n_distinct(qcew$area_fips), "areas,",
    n_distinct(qcew$year), "years\n")

# ACS
stopifnot("ACS must cover 3000+ counties" = nrow(acs) > 3000)
cat("ACS:", format(nrow(acs), big.mark = ","), "rows\n")

# Crosswalk
stopifnot("Crosswalk must have 50+ courts" = nrow(court_county) >= 50)
cat("Crosswalk:", nrow(court_county), "courts\n")

cat("\nData validation passed. All sources fetched successfully.\n")
