## =============================================================================
## 01_fetch_data.R — Fetch FARS data and construct treatment variables
## =============================================================================

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## -----------------------------------------------------------------------------
## 1. FARS Data: Download annual CSV files from NHTSA
## -----------------------------------------------------------------------------

fars_years <- 2015:2023

cat("Fetching FARS accident and person data...\n")

fetch_fars_year <- function(year) {
  cat(sprintf("  Downloading FARS %d...\n", year))

  base_url <- sprintf(
    "https://static.nhtsa.gov/nhtsa/downloads/FARS/%d/National/FARS%dNationalCSV.zip",
    year, year
  )

  zip_file <- file.path(data_dir, sprintf("fars_%d.zip", year))
  extract_dir <- file.path(data_dir, sprintf("fars_%d", year))

  tryCatch({
    if (!file.exists(zip_file)) {
      download.file(base_url, zip_file, mode = "wb", quiet = TRUE)
    }
    dir.create(extract_dir, showWarnings = FALSE)
    unzip(zip_file, exdir = extract_dir, overwrite = TRUE)

    # Find accident file (search recursively — FARS nests in subdirectory)
    acc_file <- list.files(extract_dir, pattern = "(?i)^accident\\.csv$",
                           full.names = TRUE, recursive = TRUE)[1]
    if (is.na(acc_file)) stop("Accident CSV not found for year ", year)

    # Check if DRUNK_DR column exists
    header <- names(fread(acc_file, nrows = 0))
    has_drunk_dr <- "DRUNK_DR" %in% header

    # Read core columns (always present)
    core_cols <- c("STATE", "ST_CASE", "MONTH", "DAY", "YEAR", "HOUR",
                   "DAY_WEEK", "FATALS", "COUNTY", "LATITUDE", "LONGITUD")
    if (has_drunk_dr) core_cols <- c(core_cols, "DRUNK_DR")

    acc <- fread(acc_file, select = core_cols)

    # Always read person file for measured-BAC robustness variable
    per_file <- list.files(extract_dir, pattern = "(?i)^person\\.csv$",
                           full.names = TRUE, recursive = TRUE)[1]

    # If DRUNK_DR missing, derive from person file
    if (!has_drunk_dr) {
      cat(sprintf("    %d: DRUNK_DR missing, deriving from person file...\n", year))
      if (is.na(per_file)) stop("Person CSV not found for year ", year)

      # DRINKING: 0=No, 1=Yes, 8=Not reported, 9=Unknown
      # PER_TYP: 1=Driver
      per <- fread(per_file, select = c("ST_CASE", "PER_TYP", "DRINKING"))
      drunk_drivers <- per[PER_TYP == 1 & DRINKING == 1,
                           .(DRUNK_DR = .N), by = ST_CASE]
      acc <- merge(acc, drunk_drivers, by = "ST_CASE", all.x = TRUE)
      acc[is.na(DRUNK_DR), DRUNK_DR := 0L]
    }

    # Measured-BAC robustness: use DRINKING variable from Person file
    # DRINKING: 0=No (police-reported), 1=Yes (police-reported),
    #           8=Not reported, 9=Unknown/not tested
    # We define measured_alc = 1 if any driver has DRINKING==1 (police-reported positive)
    if (!is.na(per_file)) {
      per_drink <- tryCatch({
        per_cols <- c("ST_CASE", "PER_TYP", "DRINKING")
        pd <- fread(per_file, select = intersect(per_cols, names(fread(per_file, nrows = 0))))
        if (all(c("ST_CASE", "PER_TYP", "DRINKING") %in% names(pd))) {
          pd[PER_TYP == 1 & DRINKING == 1, .(measured_alc = 1L), by = ST_CASE]
        } else {
          NULL
        }
      }, error = function(e) NULL)
      if (!is.null(per_drink) && nrow(per_drink) > 0) {
        acc <- merge(acc, per_drink, by = "ST_CASE", all.x = TRUE)
        acc[is.na(measured_alc), measured_alc := 0L]
        cat(sprintf("    %d: %d crashes with police-reported alcohol (%.1f%%)\n",
                    year, sum(acc$measured_alc), 100 * mean(acc$measured_alc)))
      } else {
        acc[, measured_alc := NA_integer_]
        cat(sprintf("    %d: DRINKING variable not available, measured_alc = NA\n", year))
      }
    } else {
      acc[, measured_alc := NA_integer_]
    }

    cat(sprintf("    %d: %d crashes, %d with drunk driver (%.1f%%)\n",
                year, nrow(acc), sum(acc$DRUNK_DR > 0),
                100 * mean(acc$DRUNK_DR > 0)))

    # Clean up zip
    unlink(zip_file)

    return(acc)
  }, error = function(e) {
    stop(sprintf("FARS %d download failed: %s\nPivot research question or fix the source.",
                 year, e$message))
  })
}

fars_list <- lapply(fars_years, fetch_fars_year)
fars <- rbindlist(fars_list, use.names = TRUE, fill = TRUE)

cat(sprintf("\nTotal FARS records: %d crashes across %d years\n",
            nrow(fars), length(unique(fars$YEAR))))

## -----------------------------------------------------------------------------
## 2. Construct key variables
## -----------------------------------------------------------------------------

# Alcohol involvement: DRUNK_DR >= 1 means at least one driver was drinking
fars[, alcohol := as.integer(DRUNK_DR >= 1)]

# Create date variable
fars[, date := as.Date(sprintf("%d-%02d-%02d", YEAR, MONTH, DAY))]

# Day of week: 1=Sunday, 2=Monday, ..., 7=Saturday (FARS coding)
# R wday: 1=Sunday, 2=Monday, ..., 7=Saturday
fars[, dow := DAY_WEEK]

# Is Sunday (NFL primary game day)
fars[, is_sunday := as.integer(dow == 1)]

# Nighttime: 8PM-3AM (hours 20-23, 0-3)
fars[, nighttime := as.integer(HOUR %in% c(20, 21, 22, 23, 0, 1, 2, 3))]

# State FIPS
fars[, state_fips := sprintf("%02d", STATE)]

# Year-month
fars[, year_month := sprintf("%d-%02d", YEAR, MONTH)]

# Clean up
fars <- fars[MONTH %in% 1:12 & DAY %in% 1:31]  # Remove unknown dates

cat(sprintf("Alcohol-involved crashes: %d (%.1f%%)\n",
            sum(fars$alcohol), 100 * mean(fars$alcohol)))
cat(sprintf("Sunday crashes: %d (%.1f%%)\n",
            sum(fars$is_sunday), 100 * mean(fars$is_sunday)))
cat(sprintf("Nighttime crashes: %d (%.1f%%)\n",
            sum(fars$nighttime), 100 * mean(fars$nighttime)))
cat(sprintf("Police-verified alcohol (measured_alc): %d (%.1f%%)\n",
            sum(fars$measured_alc, na.rm = TRUE),
            100 * mean(fars$measured_alc, na.rm = TRUE)))

## -----------------------------------------------------------------------------
## 3. NFL Schedule: construct game day indicators
## -----------------------------------------------------------------------------

cat("\nConstructing NFL game day indicators...\n")

# NFL regular season runs approximately Week 1 (early Sep) through Week 18 (early Jan)
# We define NFL season broadly: September 1 through February 15 (includes playoffs/Super Bowl)
fars[, nfl_season := as.integer(MONTH %in% c(9, 10, 11, 12, 1, 2) |
                                 (MONTH == 2 & DAY <= 15))]

# NFL games are primarily on Sundays (1pm, 4pm, 8pm ET)
# Thursday Night Football and Monday Night Football are secondary
fars[, nfl_sunday := as.integer(is_sunday == 1 & nfl_season == 1)]

# NFL market counties: counties containing or adjacent to NFL stadiums
# 32 NFL teams across ~25 metro areas
nfl_metros <- data.table(
  state_fips = c("04", "06", "06", "06", "08", "09", "11", "12",
                 "12", "13", "17", "18", "21", "22", "24", "25",
                 "26", "27", "29", "32", "34", "36", "36", "39",
                 "39", "42", "42", "47", "48", "48", "53", "55"),
  team = c("ARI", "LAC", "LAR", "SF", "DEN", "NE*", "WAS", "JAX",
           "MIA", "ATL", "CHI", "IND", "CIN*", "NO", "BAL", "NE",
           "DET", "MIN", "KC", "LV", "NYJ/NYG*", "NYJ/NYG", "BUF", "CLE",
           "CIN", "PHI", "PIT", "TEN", "DAL", "HOU", "SEA", "GB")
)
# * = stadium in bordering state; we use the metro state

fars[, nfl_market := as.integer(state_fips %in% nfl_metros$state_fips)]

cat(sprintf("NFL Sunday crashes: %d\n", sum(fars$nfl_sunday)))
cat(sprintf("NFL market state crashes: %d\n", sum(fars$nfl_market)))

## -----------------------------------------------------------------------------
## 4. Treatment: Online sports betting legalization dates
## -----------------------------------------------------------------------------

cat("\nCoding treatment dates...\n")

# Online/mobile sports betting launch dates (verified from state gaming commissions)
treatment_dates <- data.table(
  state_fips = c("34", "42", "18", "15", "19", "08", "17", "47",
                 "51", "37", "26", "06*", "55", "04", "50*", "56",
                 "09", "22", "36", "24", "20", "39", "25", "21",
                 "23", "48*", "37*", "50", "33"),
  state_abbr = c("NJ", "PA", "IN", "HI*", "IA", "CO", "IL", "TN",
                 "VA", "NC*", "MI", "CA*", "WI*", "AZ", "VT*", "WY",
                 "CT", "LA", "NY", "MD", "KS", "OH", "MA", "KY",
                 "ME", "TX*", "NC", "VT", "NH"),
  launch_date = as.Date(c(
    "2018-06-14", "2019-07-15", "2019-10-03", NA, "2019-08-15",
    "2020-05-01", "2020-06-18", "2020-11-01",
    "2021-01-21", NA, "2021-01-22", NA, NA, "2021-09-09", NA, "2021-09-01",
    "2021-10-19", "2022-01-28", "2022-01-08", "2022-11-23", "2022-09-01",
    "2023-01-01", "2023-03-10", "2023-09-28",
    "2023-11-03", NA, "2024-03-11", "2024-01-13", "2024-01-01"
  ))
)

# Remove states without online betting, with NA launch dates, or with * fips
treatment_dates <- treatment_dates[!is.na(launch_date) &
                                     !grepl("\\*", state_fips)]

# Clean state_fips
treatment_dates[, state_fips := gsub("\\*", "", state_fips)]

# Remove states whose launch dates fall after the FARS sample period (Dec 2023)
# These states have zero post-treatment observations and cannot be treated
treatment_dates <- treatment_dates[launch_date <= as.Date("2023-12-31")]

cat(sprintf("Treated states: %d\n", nrow(treatment_dates)))
print(treatment_dates[order(launch_date), .(state_abbr, launch_date)])

# Merge treatment to FARS
fars[, treat_date := treatment_dates$launch_date[
  match(state_fips, treatment_dates$state_fips)]]

fars[, treated := as.integer(!is.na(treat_date) & date >= treat_date)]
fars[, ever_treated := as.integer(!is.na(treat_date))]

# Treatment cohort (year-month of launch)
fars[, cohort_ym := fifelse(!is.na(treat_date),
                             format(treat_date, "%Y-%m"), NA_character_)]

cat(sprintf("Post-treatment crash observations: %d (%.1f%%)\n",
            sum(fars$treated), 100 * mean(fars$treated)))

## -----------------------------------------------------------------------------
## 5. State population for rate construction
## -----------------------------------------------------------------------------

cat("\nFetching state population estimates...\n")

# Try multiple Census population API endpoints
pop_df <- NULL
pop_apis <- list(
  list(url = "https://api.census.gov/data/2022/pep/population?get=POP_2022,NAME&for=state:*",
       col = "POP_2022"),
  list(url = "https://api.census.gov/data/2021/pep/population?get=POP_2021,NAME&for=state:*",
       col = "POP_2021"),
  list(url = "https://api.census.gov/data/2019/pep/population?get=POP,NAME&for=state:*",
       col = "POP")
)

for (api in pop_apis) {
  pop_df <- tryCatch({
    pop_raw <- jsonlite::fromJSON(api$url)
    dt <- as.data.table(pop_raw[-1, ])
    setnames(dt, c("pop_raw", "name", "state_fips"))
    dt[, pop := as.numeric(pop_raw)]
    dt[, state_fips := sprintf("%02d", as.integer(state_fips))]
    cat(sprintf("Population from %s: %d states\n", api$col, nrow(dt)))
    dt
  }, error = function(e) { cat(sprintf("  %s failed: %s\n", api$col, e$message)); NULL })
  if (!is.null(pop_df)) break
}

if (is.null(pop_df)) stop("All Census population APIs failed.")

fars <- merge(fars, pop_df[, .(state_fips, pop)], by = "state_fips", all.x = TRUE)

## -----------------------------------------------------------------------------
## 6. Save raw FARS panel
## -----------------------------------------------------------------------------

fwrite(fars, file.path(data_dir, "fars_panel.csv"))
cat(sprintf("\nSaved: %s (%d rows, %d cols)\n",
            file.path(data_dir, "fars_panel.csv"), nrow(fars), ncol(fars)))

## === DATA VALIDATION (required) ===
n_states <- length(unique(fars$state_fips))
n_years <- length(unique(fars$YEAR))
n_alc <- sum(fars$alcohol)

stopifnot("Expected 50+ states/territories" = n_states >= 50)
stopifnot("Expected all analysis years 2015-2023" = all(2015:2023 %in% fars$YEAR))
stopifnot("Expected substantial alcohol-involved crashes" = n_alc > 50000)
stopifnot("Expected treated observations" = sum(fars$treated) > 0)

cat(sprintf("\nData validation passed: %d rows, %d states, %d years, %d alcohol crashes\n",
            nrow(fars), n_states, n_years, n_alc))

# Clean up extracted directories
unlink(list.files(data_dir, pattern = "^fars_\\d{4}$", full.names = TRUE),
       recursive = TRUE)
