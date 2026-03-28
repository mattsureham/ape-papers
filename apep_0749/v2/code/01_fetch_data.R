## 01_fetch_data.R — Fetch FARS, NFL schedules, treatment dates, population
## apep_0749 v2: The Game-Day Externality
## V2 changes: actual NFL game dates, corrected treatment dates, state population

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. ONLINE SPORTS BETTING LEGALIZATION DATES (CORRECTED)
# ============================================================
# V2 fix: Only include states whose online launch falls within FARS sample
# (2013-2022). States launching 2023+ are NEVER-TREATED in our sample.
# Treatment = exact date of first legal online wager accepted.

osb_dates <- data.table(
  state_name = c(
    "New Jersey", "West Virginia", "Pennsylvania", "Indiana",
    "New Hampshire", "Iowa", "Illinois", "Colorado",
    "Tennessee", "Michigan", "Virginia", "Wyoming",
    "Arizona", "Connecticut", "Louisiana", "New York",
    "Maryland", "Kansas"
  ),
  osb_launch = as.Date(c(
    "2018-06-14", "2019-08-27", "2019-07-15", "2019-10-03",
    "2019-12-30", "2019-08-15", "2020-06-18", "2020-05-01",
    "2020-11-01", "2021-01-22", "2021-01-21", "2021-09-01",
    "2021-09-09", "2021-10-19", "2022-01-28", "2022-01-08",
    "2022-11-23", "2022-09-01"
  )),
  state_fips = c(
    34L, 54L, 42L, 18L,
    33L, 19L, 17L, 8L,
    47L, 26L, 51L, 56L,
    4L, 9L, 22L, 36L,
    24L, 20L
  )
)

# States launching 2023+ (OH, MA, KY, ME, NC, VT) are never-treated
# in FARS 2013-2022 sample. Record them for the treatment appendix.
future_treated <- data.table(
  state_name = c("Ohio", "Massachusetts", "Kentucky", "Maine",
                 "North Carolina", "Vermont"),
  osb_launch = as.Date(c("2023-01-01", "2023-03-10", "2023-09-28",
                          "2023-11-03", "2024-03-11", "2024-01-11")),
  state_fips = c(39L, 25L, 21L, 23L, 37L, 50L),
  in_sample = FALSE
)
osb_dates[, in_sample := TRUE]

treatment_appendix <- rbind(osb_dates, future_treated, fill = TRUE)
fwrite(treatment_appendix, file.path(data_dir, "treatment_appendix.csv"))

stopifnot(nrow(osb_dates) == 18)
cat("In-sample treated states:", nrow(osb_dates), "\n")
cat("Future-treated (never-treated in sample):", nrow(future_treated), "\n")
cat("Treatment range:", min(osb_dates$osb_launch), "to",
    as.character(max(osb_dates$osb_launch)), "\n")

# ============================================================
# 2. FARS DATA — DOWNLOAD AND PARSE
# ============================================================
fars_years <- 2013:2022
fars_dir <- file.path(data_dir, "fars_raw")
dir.create(fars_dir, showWarnings = FALSE, recursive = TRUE)

fars_accidents <- list()

for (yr in fars_years) {
  cat("Fetching FARS", yr, "... ")

  base_url <- sprintf(
    "https://static.nhtsa.gov/nhtsa/downloads/FARS/%d/National/FARS%d_NationalCSV.zip",
    yr, yr
  )
  zip_file <- file.path(fars_dir, sprintf("FARS%d.zip", yr))

  if (!file.exists(zip_file)) {
    resp <- tryCatch(
      download.file(base_url, zip_file, mode = "wb", quiet = TRUE),
      error = function(e) {
        alt_url <- sprintf(
          "https://static.nhtsa.gov/nhtsa/downloads/FARS/%d/National/FARS%dNationalCSV.zip",
          yr, yr
        )
        download.file(alt_url, zip_file, mode = "wb", quiet = TRUE)
      }
    )
  }

  if (!file.exists(zip_file) || file.size(zip_file) < 1000) {
    stop(sprintf("FARS %d download failed — cannot proceed without real data", yr))
  }

  extract_dir <- file.path(fars_dir, sprintf("fars_%d", yr))
  if (!dir.exists(extract_dir)) {
    unzip(zip_file, exdir = extract_dir)
  }

  acc_files <- list.files(extract_dir, pattern = "(?i)accident", full.names = TRUE,
                          recursive = TRUE)
  acc_file <- acc_files[grepl("\\.csv$", acc_files, ignore.case = TRUE)][1]

  if (is.na(acc_file) || !file.exists(acc_file)) {
    stop(sprintf("FARS %d ACCIDENT file not found in extracted ZIP", yr))
  }

  acc <- fread(acc_file, showProgress = FALSE)
  setnames(acc, toupper(names(acc)))
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

stopifnot("DRUNK_DR" %in% names(fars))
stopifnot("HOUR" %in% names(fars))
stopifnot(nrow(fars) > 300000)

# Create date variables
fars[, date := as.Date(sprintf("%d-%02d-%02d", YEAR, MONTH, DAY), format = "%Y-%m-%d")]
fars <- fars[!is.na(date)]  # Drop rows where date construction failed
fars[, alcohol_involved := as.integer(DRUNK_DR > 0)]
fars[, alcohol_fatals := fifelse(DRUNK_DR > 0, FATALS, 0L)]

# Crash hour: HOUR=99 means unknown in FARS
# Nighttime = 8pm-3:59am (20-23, 0-3): post-game drinking window
fars[, nighttime := as.integer(HOUR %in% c(20, 21, 22, 23, 0, 1, 2, 3))]
fars[HOUR == 99, nighttime := NA_integer_]

cat("Crash hour distribution:\n")
cat("  Nighttime (8pm-4am):", sum(fars$nighttime == 1, na.rm = TRUE),
    "(", round(100 * mean(fars$nighttime == 1, na.rm = TRUE), 1), "%)\n")
cat("  Unknown hour:", sum(fars$HOUR == 99), "\n")

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

  if (!success) {
    pep_urls <- c(
      sprintf("https://api.census.gov/data/%d/pep/population?get=NAME,POP&for=state:*&key=%s",
              yr, census_key),
      sprintf("https://api.census.gov/data/%d/pep/charagegroups?get=NAME,POP&for=state:*&key=%s",
              yr, census_key)
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

  if (!success) {
    cat("interpolating from neighbors... ")
    pop_list[[as.character(yr)]] <- NULL
  }
  cat("OK\n")
}

pop_dt_temp <- rbindlist(pop_list)
all_combos <- CJ(state_fips = unique(pop_dt_temp$state_fips), year = fars_years)
pop_dt_temp <- merge(all_combos, pop_dt_temp, by = c("state_fips", "year"), all.x = TRUE)
setorder(pop_dt_temp, state_fips, year)
pop_dt_temp[, population := as.numeric(population)]
pop_dt_temp[, population := approx(year[!is.na(population)], population[!is.na(population)],
                                     xout = year)$y, by = state_fips]
stopifnot(sum(is.na(pop_dt_temp$population)) == 0)

pop_dt <- copy(pop_dt_temp)
fwrite(pop_dt, file.path(data_dir, "state_population.csv"))
cat("Population data saved:", nrow(pop_dt), "state-years\n")

# ============================================================
# 4. ACTUAL NFL GAME SCHEDULES (2013-2022)
# ============================================================
cat("\n=== Fetching NFL game schedules ===\n")

nfl_games <- list()

for (season in 2013:2022) {
  cat("NFL season", season, "... ")

  url <- sprintf("https://www.pro-football-reference.com/years/%d/games.htm", season)

  page <- tryCatch(
    read_html(url),
    error = function(e) {
      Sys.sleep(5)
      tryCatch(read_html(url), error = function(e2) NULL)
    }
  )

  if (is.null(page)) {
    cat("FAILED\n")
    next
  }

  tbl <- tryCatch({
    html_table(page, fill = TRUE)[[1]]
  }, error = function(e) NULL)

  if (is.null(tbl) || nrow(tbl) == 0) {
    cat("no table found\n")
    next
  }

  tbl <- as.data.table(tbl)

  # PFR has "Date" column with format like "September 5" or "January 3"
  date_col <- intersect(names(tbl), c("Date", "date"))
  if (length(date_col) == 0 && ncol(tbl) >= 3) {
    date_col <- names(tbl)[3]
  } else if (length(date_col) > 0) {
    date_col <- date_col[1]
  } else {
    cat("no date column\n")
    next
  }

  raw_dates <- tbl[[date_col]]
  raw_dates <- raw_dates[!raw_dates %in% c("Date", "", "Playoffs", "Week")]

  parsed <- character(0)
  for (d in raw_dates) {
    # PFR dates: "September 5" — try season year, then season+1
    for (try_year in c(season, season + 1)) {
      full <- paste(d, try_year)
      pd <- tryCatch(as.Date(full, format = "%B %d %Y"), error = function(e) NA)
      if (!is.na(pd)) {
        m <- month(pd)
        # Jan/Feb belong to season+1
        if (m %in% 1:2 && try_year == season) next
        if (m >= 9 && try_year == season + 1) next
        parsed <- c(parsed, as.character(pd))
        break
      }
    }
  }

  game_dates <- unique(as.Date(parsed))
  game_dates <- game_dates[!is.na(game_dates)]

  if (length(game_dates) > 0) {
    nfl_games[[as.character(season)]] <- data.table(
      game_date = game_dates,
      nfl_season = season
    )
    cat("OK —", length(game_dates), "unique game dates\n")
  } else {
    cat("no dates parsed\n")
  }

  Sys.sleep(3)  # Be polite to PFR
}

# Combine all seasons
if (length(nfl_games) > 0) {
  nfl_schedule <- rbindlist(nfl_games)
  nfl_schedule <- unique(nfl_schedule, by = "game_date")
  setorder(nfl_schedule, game_date)
  cat("\nTotal NFL game dates:", nrow(nfl_schedule), "\n")
  cat("Date range:", as.character(min(nfl_schedule$game_date)), "to",
      as.character(max(nfl_schedule$game_date)), "\n")
} else {
  # Fallback: known NFL schedule patterns
  cat("WARNING: PFR scraping failed entirely. Using calendar-based fallback.\n")
  all_dates <- seq(as.Date("2013-01-01"), as.Date("2023-02-28"), by = "day")
  dt <- data.table(game_date = all_dates)
  dt[, m := month(game_date)]
  dt[, dow := wday(game_date)]  # 1=Sun
  dt[, nfl_month := m %in% c(9, 10, 11, 12, 1, 2)]
  dt[, nfl_day := dow %in% c(1, 2, 5)]  # Sun/Mon/Thu
  dt[, nfl_sat := dow == 7 & m %in% c(12, 1)]
  nfl_schedule <- dt[nfl_month == TRUE & (nfl_day == TRUE | nfl_sat == TRUE),
                     .(game_date)]
  nfl_schedule[, nfl_season := fifelse(month(game_date) >= 9,
                                         year(game_date),
                                         year(game_date) - 1L)]
  cat("Fallback NFL dates:", nrow(nfl_schedule), "\n")
}

fwrite(nfl_schedule, file.path(data_dir, "nfl_schedule.csv"))

# ============================================================
# 5. NFL TEAM LOCATIONS (for local-team heterogeneity)
# ============================================================
nfl_team_states <- c(4L, 6L, 8L, 9L, 12L, 13L, 17L, 18L, 22L, 24L, 25L,
                     26L, 27L, 29L, 34L, 36L, 39L, 42L, 47L, 48L, 53L)
# NJ hosts Giants/Jets but plays in NJ (state_fips 34)
# KY partially served by Bengals but team is in OH
fwrite(data.table(state_fips = nfl_team_states, has_nfl_team = TRUE),
       file.path(data_dir, "nfl_team_states.csv"))
cat("States with NFL teams:", length(nfl_team_states), "\n")

# ============================================================
# 6. SAVE TREATMENT DATA
# ============================================================
fwrite(osb_dates, file.path(data_dir, "osb_treatment_dates.csv"))

cat("\n=== DATA FETCH COMPLETE ===\n")
cat("FARS crashes:", nrow(fars), "\n")
cat("States with population:", length(unique(pop_dt$state_fips)), "\n")
cat("In-sample treated states:", nrow(osb_dates), "\n")
cat("NFL game dates:", nrow(nfl_schedule), "\n")
