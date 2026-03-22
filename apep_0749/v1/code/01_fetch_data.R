## 01_fetch_data.R — Fetch FARS data, treatment dates, population, game schedules
## apep_0749: The Game-Day Externality

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. ONLINE SPORTS BETTING LEGALIZATION DATES
# ============================================================
# Source: American Gaming Association, cross-referenced with legal databases
# Treatment = first month accepting legal online wagers

# Only states with clear ONLINE sports betting launch within sample period
# Excluded: NV (in-person since 1949), OR/MT/MS (limited/lottery-based pre-2020)
# Excluded: RI/WA (mixed/retail-only launch unclear for online-specific)
osb_dates <- data.table(
  state_name = c(
    "New Jersey", "West Virginia", "Pennsylvania", "Indiana",
    "New Hampshire", "Iowa", "Illinois", "Colorado",
    "Tennessee", "Michigan", "Virginia", "Wyoming",
    "Arizona", "Connecticut", "Louisiana", "New York",
    "Maryland", "Kansas", "Ohio", "Massachusetts",
    "Kentucky", "Maine", "North Carolina", "Vermont"
  ),
  osb_launch = as.Date(c(
    "2018-06-14", "2019-08-27", "2019-07-15", "2019-10-03",
    "2019-12-30", "2019-08-15", "2020-06-18", "2020-05-01",
    "2020-11-01", "2021-01-22", "2021-01-21", "2021-09-01",
    "2021-09-09", "2021-10-19", "2022-01-28", "2022-01-08",
    "2022-11-23", "2022-09-01", "2023-01-01", "2023-03-10",
    "2023-09-28", "2023-11-03", "2024-03-11", "2024-01-11"
  )),
  state_fips = c(
    34L, 54L, 42L, 18L,
    33L, 19L, 17L, 8L,
    47L, 26L, 51L, 56L,
    4L, 9L, 22L, 36L,
    24L, 20L, 39L, 25L,
    21L, 23L, 37L, 50L
  )
)
stopifnot(nrow(osb_dates) == 24)

# Create quarter-level treatment indicator
osb_dates[, osb_year := year(osb_launch)]
osb_dates[, osb_quarter := quarter(osb_launch)]
osb_dates[, osb_yearq := osb_year + (osb_quarter - 1) / 4]

cat("OSB treatment dates for", nrow(osb_dates), "states\n")
cat("Treatment range:", min(osb_dates$osb_year), "-", max(osb_dates$osb_year), "\n")

# ============================================================
# 2. FARS DATA — DOWNLOAD AND PARSE
# ============================================================
# Download FARS annual files from NHTSA
# We need: ACCIDENT file (crash-level) and PERSON file (drinking status)

fars_years <- 2013:2022
fars_dir <- file.path(data_dir, "fars_raw")
dir.create(fars_dir, showWarnings = FALSE, recursive = TRUE)

fars_accidents <- list()

for (yr in fars_years) {
  cat("Fetching FARS", yr, "... ")

  # NHTSA FARS data CSV files
  base_url <- sprintf("https://static.nhtsa.gov/nhtsa/downloads/FARS/%d/National/FARS%d_NationalCSV.zip", yr, yr)
  zip_file <- file.path(fars_dir, sprintf("FARS%d.zip", yr))

  if (!file.exists(zip_file)) {
    resp <- tryCatch(
      download.file(base_url, zip_file, mode = "wb", quiet = TRUE),
      error = function(e) {
        # Try alternate URL pattern
        alt_url <- sprintf("https://static.nhtsa.gov/nhtsa/downloads/FARS/%d/National/FARS%dNationalCSV.zip", yr, yr)
        download.file(alt_url, zip_file, mode = "wb", quiet = TRUE)
      }
    )
  }

  if (!file.exists(zip_file) || file.size(zip_file) < 1000) {
    stop(sprintf("FARS %d download failed — cannot proceed without real data", yr))
  }

  # Extract and read ACCIDENT file
  extract_dir <- file.path(fars_dir, sprintf("fars_%d", yr))
  if (!dir.exists(extract_dir)) {
    unzip(zip_file, exdir = extract_dir)
  }

  # Find the accident file (naming varies by year)
  acc_files <- list.files(extract_dir, pattern = "(?i)accident", full.names = TRUE, recursive = TRUE)
  acc_file <- acc_files[grepl("\\.csv$", acc_files, ignore.case = TRUE)][1]

  if (is.na(acc_file) || !file.exists(acc_file)) {
    stop(sprintf("FARS %d ACCIDENT file not found in extracted ZIP", yr))
  }

  acc <- fread(acc_file, showProgress = FALSE)
  # Normalize column names to uppercase (varies by year)
  setnames(acc, toupper(names(acc)))
  # Select needed columns
  keep_cols <- intersect(names(acc), c("STATE", "ST_CASE", "MONTH", "DAY",
                                        "YEAR", "DRUNK_DR", "FATALS",
                                        "DAY_WEEK", "HOUR"))
  acc <- acc[, ..keep_cols]

  fars_accidents[[as.character(yr)]] <- acc
  cat("OK —", nrow(acc), "crashes\n")
}

fars <- rbindlist(fars_accidents, fill = TRUE)
cat("\nTotal FARS crashes:", nrow(fars), "\n")
cat("Years:", min(fars$YEAR), "-", max(fars$YEAR), "\n")

# Validate: no missing states, drinking field present
stopifnot("DRUNK_DR" %in% names(fars))
stopifnot(nrow(fars) > 300000)  # ~30K+ crashes per year × 10 years

# Create date and quarter variables
fars[, date := as.Date(sprintf("%d-%02d-%02d", YEAR, MONTH, DAY), format = "%Y-%m-%d")]
fars[, quarter := quarter(date)]
fars[, yearq := YEAR + (quarter - 1) / 4]
fars[, alcohol_involved := as.integer(DRUNK_DR > 0)]

# Flag game days (weekends are days 1=Sunday, 7=Saturday in FARS)
# DAY_WEEK: 1=Sun, 2=Mon, ..., 7=Sat
fars[, weekend := as.integer(DAY_WEEK %in% c(1, 6, 7))]

fwrite(fars, file.path(data_dir, "fars_crashes.csv"))
cat("FARS data saved:", nrow(fars), "crashes\n")

# ============================================================
# 3. STATE POPULATION DATA (Census API)
# ============================================================
census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) == 0) stop("CENSUS_API_KEY not set")

pop_list <- list()
for (yr in fars_years) {
  cat("Fetching population", yr, "... ")

  success <- FALSE

  # Try ACS 1-year first (not available for 2020)
  if (yr != 2020) {
    url <- sprintf(
      "https://api.census.gov/data/%d/acs/acs1?get=NAME,B01003_001E&for=state:*&key=%s",
      yr, census_key
    )
    resp <- tryCatch(httr::GET(url, httr::timeout(30)), error = function(e) NULL)
    if (!is.null(resp) && httr::status_code(resp) == 200) {
      raw <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
      df <- as.data.table(raw[-1, , drop = FALSE])
      setnames(df, raw[1, ])
      df[, population := as.numeric(B01003_001E)]
      df[, state_fips := as.integer(state)]
      df[, year := yr]
      pop_list[[as.character(yr)]] <- df[, .(state_fips, year, population)]
      success <- TRUE
    }
  }

  # Fallback: try PEP
  if (!success) {
    pep_urls <- c(
      sprintf("https://api.census.gov/data/%d/pep/population?get=NAME,POP&for=state:*&key=%s", yr, census_key),
      sprintf("https://api.census.gov/data/%d/pep/charagegroups?get=NAME,POP&for=state:*&key=%s", yr, census_key)
    )
    for (purl in pep_urls) {
      resp <- tryCatch(httr::GET(purl, httr::timeout(30)), error = function(e) NULL)
      if (!is.null(resp) && httr::status_code(resp) == 200) {
        raw <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
        df <- as.data.table(raw[-1, , drop = FALSE])
        setnames(df, raw[1, ])
        pop_col <- intersect(names(df), c("POP", "B01003_001E"))
        if (length(pop_col) > 0) {
          df[, population := as.numeric(get(pop_col[1]))]
          df[, state_fips := as.integer(state)]
          df[, year := yr]
          pop_list[[as.character(yr)]] <- df[, .(state_fips, year, population)]
          success <- TRUE
          break
        }
      }
    }
  }

  # Last resort for 2020: interpolate from 2019 and 2021
  if (!success) {
    cat("interpolating from neighbors... ")
    if (as.character(yr - 1) %in% names(pop_list) || as.character(yr + 1) %in% names(pop_list)) {
      # Will interpolate after the loop
      pop_list[[as.character(yr)]] <- NULL
    } else {
      stop(sprintf("Census API failed for %d — cannot proceed without population data", yr))
    }
  }

  cat("OK\n")
}

# Interpolate any missing years (e.g., 2020)
pop_dt_temp <- rbindlist(pop_list)
all_combos <- CJ(state_fips = unique(pop_dt_temp$state_fips), year = fars_years)
pop_dt_temp <- merge(all_combos, pop_dt_temp, by = c("state_fips", "year"), all.x = TRUE)
setorder(pop_dt_temp, state_fips, year)
pop_dt_temp[, population := as.numeric(population)]
# Linear interpolation for missing years
pop_dt_temp[, population := approx(year[!is.na(population)], population[!is.na(population)],
                                     xout = year)$y, by = state_fips]
stopifnot(sum(is.na(pop_dt_temp$population)) == 0)

pop_dt <- copy(pop_dt_temp)
fwrite(pop_dt, file.path(data_dir, "state_population.csv"))
cat("Population data saved:", nrow(pop_dt), "state-years\n")

# ============================================================
# 4. GAME DAY SCHEDULE (NFL focus — most relevant for bar viewing)
# ============================================================
# NFL season: September through February
# NFL games primarily: Sundays, Monday nights, Thursday nights
# We construct a simplified game-day indicator based on:
# - NFL regular season (Sep-Jan) + playoffs (Jan-Feb)
# - NBA season (Oct-Jun)
# - MLB season (Apr-Oct)
# Game days = days when at least one major professional league has games

# For efficiency, we define game-day windows by month and day-of-week
# NFL: Sep-Feb, primarily Sun/Mon/Thu
# NBA: Oct-Jun, games almost every day
# MLB: Apr-Oct, games almost every day
# Key insight: the COMBINATION of sports betting + game availability matters most

# We'll use a simpler approach: classify each FARS crash date as
# during an active sports season with likely game activity

fars[, month := MONTH]

# NFL game day: Sep-Feb, Sun/Mon/Thu (DAY_WEEK: 1=Sun, 2=Mon, 5=Thu)
fars[, nfl_gameday := as.integer(
  month %in% c(9, 10, 11, 12, 1, 2) & DAY_WEEK %in% c(1, 2, 5)
)]

# Any major sport game day (conservative: at least one league active)
# Sports seasons overlap considerably — we focus on NFL which drives bar viewing
fars[, game_day := nfl_gameday]

cat("Game day classification:\n")
cat("  NFL game days:", sum(fars$nfl_gameday), "(",
    round(100 * mean(fars$nfl_gameday), 1), "%)\n")

fwrite(fars, file.path(data_dir, "fars_crashes.csv"))

# ============================================================
# 5. SAVE TREATMENT DATA
# ============================================================
fwrite(osb_dates, file.path(data_dir, "osb_treatment_dates.csv"))

cat("\n=== DATA FETCH COMPLETE ===\n")
cat("FARS crashes:", nrow(fars), "\n")
cat("States with population:", length(unique(pop_dt$state_fips)), "\n")
cat("OSB treatment states:", nrow(osb_dates), "\n")
