# 01_fetch_data.R — Fetch FARS fatality data and Census population denominators
# apep_0801: California School Start Time Mandate and Teen Traffic Fatalities

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. FARS Data — Person-level fatal crash records (2015-2023)
# ============================================================
# NHTSA provides annual CSV files via their API/FTP.
# We use the FARS API to query person-level data by state/year.

fars_base <- "https://crashviewer.nhtsa.dot.gov/CrashAPI/crashes/GetCrashesByLocation"

# State FIPS codes for all 50 states + DC
state_fips <- c(
  "AL"=1,"AK"=2,"AZ"=4,"AR"=5,"CA"=6,"CO"=8,"CT"=9,"DE"=10,"DC"=11,
  "FL"=12,"GA"=13,"HI"=15,"ID"=16,"IL"=17,"IN"=18,"IA"=19,"KS"=20,
  "KY"=21,"LA"=22,"ME"=23,"MD"=24,"MA"=25,"MI"=26,"MN"=27,"MS"=28,
  "MO"=29,"MT"=30,"NE"=31,"NV"=32,"NH"=33,"NJ"=34,"NM"=35,"NY"=36,
  "NC"=37,"ND"=38,"OH"=39,"OK"=40,"OR"=41,"PA"=42,"RI"=44,"SC"=45,
  "SD"=46,"TN"=47,"TX"=48,"UT"=49,"VT"=50,"VA"=51,"WA"=53,"WV"=54,
  "WI"=55,"WY"=56
)

# Alternative approach: download FARS flat files directly
# The NHTSA FARS FTP has annual zipped CSVs.
# We'll use the FARS API endpoint for person-level data.

fars_api <- "https://crashviewer.nhtsa.dot.gov/CrashAPI/analytics/GetInjSevCountByDayOfWeek"

# More reliable: use the bulk CSV approach via NHTSA's data downloads
# FARS provides PERSON.csv and ACCIDENT.csv per year

cat("Fetching FARS data via bulk CSV downloads...\n")

years <- 2015:2023

all_person <- list()
all_accident <- list()

for (yr in years) {
  cat(sprintf("Downloading FARS %d...\n", yr))

  # NHTSA bulk download URL pattern
  zip_url <- sprintf(
    "https://static.nhtsa.gov/nhtsa/downloads/FARS/%d/National/FARS%dNationalCSV.zip",
    yr, yr
  )

  zip_file <- file.path(data_dir, sprintf("fars_%d.zip", yr))
  extract_dir <- file.path(data_dir, sprintf("fars_%d", yr))

  if (!file.exists(zip_file)) {
    resp <- tryCatch(
      download.file(zip_url, zip_file, mode = "wb", quiet = TRUE),
      error = function(e) {
        stop(sprintf("FARS %d download failed: %s", yr, e$message))
      }
    )
    if (resp != 0) stop(sprintf("FARS %d download returned non-zero status", yr))
  }

  # Extract
  dir.create(extract_dir, showWarnings = FALSE, recursive = TRUE)
  unzip(zip_file, exdir = extract_dir, overwrite = TRUE)

  # Find PERSON and ACCIDENT files (case-insensitive)
  all_files <- list.files(extract_dir, recursive = TRUE, full.names = TRUE)
  person_file <- grep("person\\.csv$", all_files, ignore.case = TRUE, value = TRUE)
  accident_file <- grep("accident\\.csv$", all_files, ignore.case = TRUE, value = TRUE)

  if (length(person_file) == 0) stop(sprintf("No PERSON.csv found in FARS %d", yr))
  if (length(accident_file) == 0) stop(sprintf("No ACCIDENT.csv found in FARS %d", yr))

  # Read person file
  person <- fread(person_file[1], showProgress = FALSE)
  # Standardize column names to uppercase
  setnames(person, toupper(names(person)))

  # Read accident file
  accident <- fread(accident_file[1], showProgress = FALSE)
  setnames(accident, toupper(names(accident)))

  # We need: ST_CASE (link key), STATE, HOUR (from accident), MONTH, AGE, INJ_SEV, PER_TYP
  # HOUR is in ACCIDENT table; AGE, INJ_SEV, PER_TYP in PERSON table

  # Select relevant columns from accident
  acc_cols <- intersect(c("ST_CASE", "STATE", "HOUR", "MONTH", "DAY_WEEK", "YEAR"), names(accident))
  acc_sub <- accident[, ..acc_cols]

  # Select relevant columns from person
  per_cols <- intersect(c("ST_CASE", "STATE", "AGE", "INJ_SEV", "PER_TYP", "SEX"), names(person))
  per_sub <- person[, ..per_cols]

  # Merge
  merged <- merge(per_sub, acc_sub, by = c("ST_CASE", "STATE"), all.x = TRUE)
  merged[, YEAR := yr]

  all_person[[as.character(yr)]] <- merged

  cat(sprintf("  FARS %d: %d person records, %d accidents\n", yr, nrow(merged), nrow(accident)))
}

fars <- rbindlist(all_person, fill = TRUE)
cat(sprintf("\nTotal FARS person records: %d\n", nrow(fars)))

# Filter to fatalities only (INJ_SEV == 4)
fars_fatal <- fars[INJ_SEV == 4]
cat(sprintf("Fatal person records: %d\n", nrow(fars_fatal)))

# Validate: no missing critical fields
stopifnot("STATE missing" = sum(is.na(fars_fatal$STATE)) == 0)
stopifnot("HOUR missing" = sum(is.na(fars_fatal$HOUR)) / nrow(fars_fatal) < 0.05)
stopifnot("AGE missing" = sum(is.na(fars_fatal$AGE)) / nrow(fars_fatal) < 0.05)

# Save processed FARS data
fwrite(fars_fatal, file.path(data_dir, "fars_fatal_2015_2023.csv"))

# ============================================================
# 2. Census ACS — State-level population by age group
# ============================================================
cat("\nFetching Census ACS population data...\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (census_key == "") stop("CENSUS_API_KEY not set in .env")

# ACS 1-year estimates, table B01001 (sex by age)
# We need total population for age groups 15-19 and 25-54 by state

pop_list <- list()

for (yr in years) {
  cat(sprintf("  ACS %d...\n", yr))
  # B01001_007 through B01001_010: Males 15-17, 18-19, 20, 21
  # B01001_031 through B01001_034: Females 15-17, 18-19, 20, 21
  # For teens 15-19: need 15-17 + 18-19 (male + female)
  # For adults 25-54: aggregate multiple bins

  # Use age-sex detail table
  # Male: _007=15-17, _008=18-19
  # Female: _031=15-17, _032=18-19
  teen_vars <- "B01001_007E,B01001_008E,B01001_031E,B01001_032E"

  # Male 25-29: _011, 30-34: _012, 35-39: _013, 40-44: _014, 45-49: _015, 50-54: _016
  # Female: _035, _036, _037, _038, _039, _040
  adult_vars <- "B01001_011E,B01001_012E,B01001_013E,B01001_014E,B01001_015E,B01001_016E,B01001_035E,B01001_036E,B01001_037E,B01001_038E,B01001_039E,B01001_040E"

  all_vars <- paste0("NAME,", teen_vars, ",", adult_vars)

  url <- sprintf(
    "https://api.census.gov/data/%d/acs/acs1?get=%s&for=state:*&key=%s",
    yr, all_vars, census_key
  )

  resp <- tryCatch(
    httr::GET(url, httr::timeout(120)),
    error = function(e) {
      # ACS 1-year might not be available; try 5-year
      url5 <- sprintf(
        "https://api.census.gov/data/%d/acs/acs5?get=%s&for=state:*&key=%s",
        yr, all_vars, census_key
      )
      httr::GET(url5, httr::timeout(120))
    }
  )

  if (httr::status_code(resp) != 200) {
    warning(sprintf("Census ACS %d returned status %d, trying 5-year", yr, httr::status_code(resp)))
    url5 <- sprintf(
      "https://api.census.gov/data/%d/acs/acs5?get=%s&for=state:*&key=%s",
      yr, all_vars, census_key
    )
    resp <- httr::GET(url5, httr::timeout(120))
    if (httr::status_code(resp) != 200) {
      stop(sprintf("Census ACS %d failed with status %d", yr, httr::status_code(resp)))
    }
  }

  raw <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
  df <- as.data.frame(raw[-1, ], stringsAsFactors = FALSE)
  names(df) <- raw[1, ]

  # Convert to numeric
  num_cols <- setdiff(names(df), c("NAME", "state"))
  df[num_cols] <- lapply(df[num_cols], as.numeric)

  # Compute teen (15-19) population
  df$pop_teen <- df$B01001_007E + df$B01001_008E + df$B01001_031E + df$B01001_032E

  # Compute adult (25-54) population
  adult_cols <- c("B01001_011E","B01001_012E","B01001_013E","B01001_014E",
                  "B01001_015E","B01001_016E","B01001_035E","B01001_036E",
                  "B01001_037E","B01001_038E","B01001_039E","B01001_040E")
  df$pop_adult <- rowSums(df[adult_cols])

  df$STATE <- as.integer(df$state)
  df$YEAR <- yr

  pop_list[[as.character(yr)]] <- df[, c("STATE", "YEAR", "pop_teen", "pop_adult", "NAME")]
}

pop <- rbindlist(pop_list)
cat(sprintf("Population data: %d state-year observations\n", nrow(pop)))

# Validate
stopifnot("No CA population" = 6 %in% pop$STATE)
stopifnot("Missing pop" = sum(is.na(pop$pop_teen)) == 0)

fwrite(pop, file.path(data_dir, "state_population_2015_2023.csv"))

cat("\n=== Data fetch complete ===\n")
cat(sprintf("FARS fatal records: %d\n", nrow(fars_fatal)))
cat(sprintf("Population records: %d\n", nrow(pop)))
