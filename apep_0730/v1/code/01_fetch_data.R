# 01_fetch_data.R — Fetch FARS crash data and time zone boundaries
# apep_0730: Time Zone Boundaries and Teen Morning Traffic Deaths

source("00_packages.R")
setwd(file.path(dirname(getwd()), "data"))

cat("=== Fetching FARS data (2010-2023) ===\n")

# FARS data is available as flat files from NHTSA
# https://www.nhtsa.gov/file-downloads?p=nhtsa/downloads/FARS/
# We use the FARS API (CrashViewer) for structured queries

# Strategy: download FARS flat files (CSV) which have lat/lon
# FARS flat files available at: https://static.nhtsa.gov/nhtsa/downloads/FARS/

fars_base <- "https://static.nhtsa.gov/nhtsa/downloads/FARS"
years <- 2010:2023

# We need two FARS tables:
# 1. ACCIDENT: crash-level (lat, lon, time, state, county, weather)
# 2. PERSON: person-level (age, sex, injury severity, person type)

all_accidents <- list()
all_persons <- list()

for (yr in years) {
  cat(sprintf("  Fetching FARS %d...\n", yr))

  # Try CSV format first (available for recent years)
  acc_url <- sprintf("%s/%d/National/FARS%dNationalCSV.zip", fars_base, yr, yr)

  tmp_zip <- tempfile(fileext = ".zip")
  resp <- tryCatch(
    download.file(acc_url, tmp_zip, mode = "wb", quiet = TRUE),
    error = function(e) {
      cat(sprintf("    Primary URL failed for %d, trying alternate...\n", yr))
      return(1)
    }
  )

  if (resp != 0) {
    # Try alternate URL pattern
    acc_url2 <- sprintf("%s/%d/National/FARS%d-NationalCSV.zip", fars_base, yr, yr)
    resp2 <- tryCatch(
      download.file(acc_url2, tmp_zip, mode = "wb", quiet = TRUE),
      error = function(e) {
        stop(sprintf("FATAL: Cannot download FARS %d from any URL. Aborting.", yr))
      }
    )
    if (resp2 != 0) {
      stop(sprintf("FATAL: Download failed for FARS %d. Aborting.", yr))
    }
  }

  # Extract to year-specific directory (avoids stale files from prior iterations)
  tmp_dir <- file.path(tempdir(), sprintf("fars_%d", yr))
  if (dir.exists(tmp_dir)) unlink(tmp_dir, recursive = TRUE)
  dir.create(tmp_dir, showWarnings = FALSE)
  unzip(tmp_zip, exdir = tmp_dir, overwrite = TRUE)

  # Find the accident file (case-insensitive)
  all_files <- list.files(tmp_dir, recursive = TRUE, full.names = TRUE)
  acc_file <- all_files[grepl("accident\\.csv$", all_files, ignore.case = TRUE)]
  per_file <- all_files[grepl("person\\.csv$", all_files, ignore.case = TRUE)]

  if (length(acc_file) == 0) stop(sprintf("FATAL: No accident.csv found in FARS %d zip", yr))
  if (length(per_file) == 0) stop(sprintf("FATAL: No person.csv found in FARS %d zip", yr))

  # Read accident data
  acc <- fread(acc_file[1], select = c(
    "STATE", "ST_CASE", "COUNTY", "CITY",
    "LATITUDE", "LONGITUD", "HOUR", "MONTH", "DAY_WEEK",
    "WEATHER", "LGT_COND", "FATALS"
  ))
  acc[, YEAR := yr]

  # Read person data (just age and person type for merging)
  per <- fread(per_file[1], select = c(
    "STATE", "ST_CASE", "PER_TYP", "AGE", "SEX", "INJ_SEV"
  ))
  per[, YEAR := yr]

  all_accidents[[as.character(yr)]] <- acc
  all_persons[[as.character(yr)]] <- per

  # Clean up extracted files
  unlink(tmp_zip)
  unlink(tmp_dir, recursive = TRUE)

  cat(sprintf("    %d: %d crashes, %d persons\n", yr, nrow(acc), nrow(per)))
}

cat("Binding all years...\n")
accidents <- rbindlist(all_accidents, fill = TRUE)
persons <- rbindlist(all_persons, fill = TRUE)

cat(sprintf("Total crashes: %d\n", nrow(accidents)))
cat(sprintf("Total persons: %d\n", nrow(persons)))

# Validate: crashes must have valid coordinates
stopifnot("No accident data fetched" = nrow(accidents) > 0)
stopifnot("No person data fetched" = nrow(persons) > 0)

# Check coordinate coverage
valid_coords <- accidents[LATITUDE > 20 & LATITUDE < 55 &
                          LONGITUD > -130 & LONGITUD < -65]
cat(sprintf("Crashes with valid US coordinates: %d (%.1f%%)\n",
            nrow(valid_coords), 100 * nrow(valid_coords) / nrow(accidents)))

stopifnot("Less than 50% of crashes have valid coordinates" =
            nrow(valid_coords) / nrow(accidents) > 0.5)

# Save raw data
fwrite(accidents, "fars_accidents_2010_2023.csv")
fwrite(persons, "fars_persons_2010_2023.csv")

cat("=== FARS data saved ===\n")

# --- County population data from Census ACS ---
cat("\n=== Fetching county population by age ===\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) == 0) stop("FATAL: CENSUS_API_KEY not set in .env")

# Get county-level population by age group for rate denominators
# Use ACS 5-year for stability. Variables:
# B01001_001E = total pop
# B01001_007E = male 15-17, B01001_008E = male 18-19
# B01001_031E = female 15-17, B01001_032E = female 18-19

acs_years <- c(2014, 2019, 2023)  # 5-year centered on 2012, 2017, 2021
pop_list <- list()

for (yr in acs_years) {
  cat(sprintf("  Fetching ACS %d...\n", yr))
  url <- sprintf(
    "https://api.census.gov/data/%d/acs/acs5?get=B01001_001E,B01001_007E,B01001_008E,B01001_031E,B01001_032E,NAME&for=county:*&key=%s",
    yr, census_key
  )
  resp <- GET(url)
  if (status_code(resp) != 200) {
    stop(sprintf("FATAL: Census ACS API returned %d for year %d", status_code(resp), yr))
  }
  raw <- fromJSON(content(resp, "text", encoding = "UTF-8"))
  df <- as.data.table(raw[-1, ])
  names(df) <- raw[1, ]
  df[, acs_year := yr]
  pop_list[[as.character(yr)]] <- df
}

pop_data <- rbindlist(pop_list, fill = TRUE)

# Convert numeric columns
num_cols <- c("B01001_001E", "B01001_007E", "B01001_008E", "B01001_031E", "B01001_032E")
for (col in num_cols) pop_data[, (col) := as.numeric(get(col))]

# Create teen population (15-19)
pop_data[, teen_pop := B01001_007E + B01001_008E + B01001_031E + B01001_032E]
pop_data[, total_pop := B01001_001E]
pop_data[, fips := paste0(state, county)]

fwrite(pop_data, "county_population.csv")
cat(sprintf("County population data: %d county-years\n", nrow(pop_data)))

cat("\n=== All data fetched successfully ===\n")
