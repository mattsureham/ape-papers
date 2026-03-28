## 02_clean_data.R — Construct state-week panel with proper exposure
## apep_0749 v2: The Game-Day Externality
## V2: state-week panel, actual NFL game dates, crash-hour splits

source("00_packages.R")

data_dir <- "../data"

fars <- fread(file.path(data_dir, "fars_crashes.csv"))
pop  <- fread(file.path(data_dir, "state_population.csv"))
osb  <- fread(file.path(data_dir, "osb_treatment_dates.csv"))
nfl  <- fread(file.path(data_dir, "nfl_schedule.csv"))

osb[, osb_launch := as.Date(osb_launch)]
nfl[, game_date := as.Date(game_date)]
fars[, date := as.Date(date)]

# ============================================================
# 1. MATCH FARS CRASHES TO NFL GAME DATES
# ============================================================
# Create a lookup of all NFL game dates
nfl_dates <- unique(nfl$game_date)
fars[, nfl_gameday := as.integer(date %in% nfl_dates)]

cat("NFL game-day classification:\n")
cat("  Game-day crashes:", sum(fars$nfl_gameday), "(",
    round(100 * mean(fars$nfl_gameday), 1), "%)\n")
cat("  Non-game-day crashes:", sum(!fars$nfl_gameday), "\n")

# ============================================================
# 2. CONSTRUCT STATE-WEEK PANEL
# ============================================================
# ISO week: consistent 7-day grouping
fars[, year_week := paste0(YEAR, "-W", sprintf("%02d", isoweek(date)))]
fars[, iso_year := isoyear(date)]
fars[, iso_week := isoweek(date)]

# Aggregate crashes to state-week level
panel_week <- fars[, .(
  alc_crashes       = sum(alcohol_involved, na.rm = TRUE),
  nonalc_crashes    = sum(1L - alcohol_involved, na.rm = TRUE),
  total_crashes     = .N,
  alc_fatals        = sum(alcohol_fatals, na.rm = TRUE),
  total_fatals      = sum(FATALS, na.rm = TRUE),
  # Night/day splits
  alc_night_crashes = sum(alcohol_involved == 1 & nighttime == 1, na.rm = TRUE),
  alc_day_crashes   = sum(alcohol_involved == 1 & nighttime == 0, na.rm = TRUE),
  nonalc_night      = sum(alcohol_involved == 0 & nighttime == 1, na.rm = TRUE),
  nonalc_day        = sum(alcohol_involved == 0 & nighttime == 0, na.rm = TRUE),
  # NFL game days in this state-week
  nfl_days          = sum(nfl_gameday, na.rm = TRUE),
  n_days            = uniqueN(date)
), by = .(state_fips = STATE, iso_year, iso_week)]

# Some weeks at year boundaries may have fewer than 7 days in our sample
# n_days tracks the actual number of observed days

# ============================================================
# 3. CREATE GAME-DAY INTENSITY VARIABLE
# ============================================================
# Instead of binary: use the NUMBER of NFL game dates per state-week
# This is a continuous treatment intensity for the DDD
# Also create a full date skeleton for proper exposure calculation

# Build complete state-week skeleton
all_dates <- seq(as.Date("2013-01-01"), as.Date("2022-12-31"), by = "day")
date_skel <- data.table(date = all_dates)
date_skel[, iso_year := isoyear(date)]
date_skel[, iso_week := isoweek(date)]
date_skel[, nfl_gameday := as.integer(date %in% nfl_dates)]

# Count NFL game days per week (for exposure)
week_nfl <- date_skel[, .(
  nfl_days_in_week = sum(nfl_gameday),
  days_in_week = .N
), by = .(iso_year, iso_week)]

# Merge NFL days into panel
panel_week <- merge(panel_week, week_nfl, by = c("iso_year", "iso_week"), all.x = TRUE)

# Binary game-week indicator (at least one NFL game this week)
panel_week[, game_week := as.integer(nfl_days_in_week > 0)]

cat("\nState-week panel:\n")
cat("  Game weeks:", sum(panel_week$game_week == 1),
    "(", round(100 * mean(panel_week$game_week == 1), 1), "%)\n")
cat("  Non-game weeks:", sum(panel_week$game_week == 0), "\n")

# ============================================================
# 4. MERGE POPULATION AND TREATMENT
# ============================================================
# Population: use year-level, merge to state-week
panel_week <- merge(panel_week, pop, by.x = c("state_fips", "iso_year"),
                    by.y = c("state_fips", "year"), all.x = TRUE)

# For weeks at year boundaries, iso_year might not match FARS year
# Fill missing with nearest year
panel_week[is.na(population), population := pop[state_fips == panel_week$state_fips[1] &
                                                  year == 2022, population],
           by = state_fips]

# Treatment: exact date
panel_week <- merge(panel_week, osb[, .(state_fips, osb_launch)],
                    by = "state_fips", all.x = TRUE)

# Create treatment indicator at the week level
# A state-week is treated if the OSB launch date falls on or before the
# last day of that ISO week
panel_week[, week_start := as.Date(paste0(iso_year, "-01-01")) +
             (iso_week - 1) * 7]
# More precise: use the actual dates in the week
week_dates <- date_skel[, .(
  week_start = min(date),
  week_end = max(date)
), by = .(iso_year, iso_week)]
panel_week[, c("week_start") := NULL]
panel_week <- merge(panel_week, week_dates, by = c("iso_year", "iso_week"), all.x = TRUE)

panel_week[, treated := as.integer(!is.na(osb_launch) & osb_launch <= week_end)]
panel_week[is.na(osb_launch), treated := 0L]

# Cohort for CS-DiD: the ISO week of treatment
panel_week[, osb_iso_year := isoyear(osb_launch)]
panel_week[, osb_iso_week := isoweek(osb_launch)]

# Time index (continuous week counter)
panel_week[, time_idx := (iso_year - 2013) * 52 + iso_week]
panel_week[, cohort_idx := fifelse(
  is.na(osb_launch), 0L,
  as.integer((osb_iso_year - 2013) * 52 + osb_iso_week)
)]

# ============================================================
# 5. COMPUTE RATES WITH PROPER EXPOSURE
# ============================================================
# Annualized rate per 100K population
# Rate = (crashes / days_in_week) * 365.25 / (population / 100000)
panel_week[, alc_crash_rate := (alc_crashes / days_in_week) * 365.25 /
             (population / 100000)]
panel_week[, nonalc_crash_rate := (nonalc_crashes / days_in_week) * 365.25 /
             (population / 100000)]
panel_week[, total_crash_rate := (total_crashes / days_in_week) * 365.25 /
             (population / 100000)]
panel_week[, alc_fatal_rate := (alc_fatals / days_in_week) * 365.25 /
             (population / 100000)]
panel_week[, alc_share := fifelse(total_crashes > 0,
                                    alc_crashes / total_crashes, NA_real_)]

# Night/day rates
panel_week[, alc_night_rate := (alc_night_crashes / days_in_week) * 365.25 /
             (population / 100000)]
panel_week[, alc_day_rate := (alc_day_crashes / days_in_week) * 365.25 /
             (population / 100000)]

# For Poisson/NB: keep counts and exposure
panel_week[, log_exposure := log(population / 100000 * days_in_week / 365.25)]

# ============================================================
# 6. ALSO BUILD STATE-QUARTER PANEL (for CS-DiD baseline)
# ============================================================
# CS-DiD requires balanced panel — state-quarter is more standard
fars[, quarter := quarter(date)]
panel_q <- fars[, .(
  alc_crashes    = sum(alcohol_involved, na.rm = TRUE),
  nonalc_crashes = sum(1L - alcohol_involved, na.rm = TRUE),
  total_crashes  = .N,
  alc_fatals     = sum(alcohol_fatals, na.rm = TRUE),
  total_fatals   = sum(FATALS, na.rm = TRUE),
  alc_night      = sum(alcohol_involved == 1 & nighttime == 1, na.rm = TRUE),
  alc_day        = sum(alcohol_involved == 1 & nighttime == 0, na.rm = TRUE)
), by = .(state_fips = STATE, year = YEAR, quarter)]

panel_q <- merge(panel_q, pop, by = c("state_fips", "year"), all.x = TRUE)
panel_q <- panel_q[!is.na(population) & population > 0]

panel_q <- merge(panel_q, osb[, .(state_fips, osb_launch)],
                 by = "state_fips", all.x = TRUE)
panel_q[, yearq := year + (quarter - 1) / 4]
panel_q[, osb_yearq := year(osb_launch) + (quarter(osb_launch) - 1) / 4]
panel_q[, treated := as.integer(!is.na(osb_yearq) & yearq >= osb_yearq)]
panel_q[is.na(osb_yearq), treated := 0L]
panel_q[, cohort_yearq := fifelse(is.na(osb_yearq), 0, osb_yearq)]

# Annualized rates per 100K
days_in_q <- 365.25 / 4
panel_q[, alc_crash_rate := alc_crashes / (population / 100000) / days_in_q * 365.25]
panel_q[, nonalc_crash_rate := nonalc_crashes / (population / 100000) / days_in_q * 365.25]
panel_q[, total_crash_rate := total_crashes / (population / 100000) / days_in_q * 365.25]
panel_q[, alc_fatal_rate := alc_fatals / (population / 100000) / days_in_q * 365.25]
panel_q[, alc_share := fifelse(total_crashes > 0, alc_crashes / total_crashes, NA_real_)]
panel_q[, alc_night_rate := alc_night / (population / 100000) / days_in_q * 365.25]
panel_q[, alc_day_rate := alc_day / (population / 100000) / days_in_q * 365.25]

# Time and cohort indices for CS-DiD
panel_q[, time_idx := (year - 2013) * 4 + quarter]
panel_q[, osb_year := year(osb_launch)]
panel_q[, osb_quarter := quarter(osb_launch)]
panel_q[, cohort_idx := fifelse(cohort_yearq == 0, 0L,
                                  as.integer((osb_year - 2013) * 4 + osb_quarter))]

# NFL game-day counts per state-quarter (for DDD)
fars_q_nfl <- fars[, .(
  nfl_crashes_alc = sum(alcohol_involved == 1 & nfl_gameday == 1, na.rm = TRUE),
  nfl_crashes_nonalc = sum(alcohol_involved == 0 & nfl_gameday == 1, na.rm = TRUE),
  nonnfl_crashes_alc = sum(alcohol_involved == 1 & nfl_gameday == 0, na.rm = TRUE),
  nfl_game_days = uniqueN(date[nfl_gameday == 1]),
  nonnfl_days = uniqueN(date[nfl_gameday == 0])
), by = .(state_fips = STATE, year = YEAR, quarter)]

panel_q <- merge(panel_q, fars_q_nfl, by = c("state_fips", "year", "quarter"), all.x = TRUE)
panel_q[is.na(nfl_game_days), nfl_game_days := 0L]

# Per-day rates for game vs non-game days (proper exposure!)
panel_q[, nfl_alc_rate := fifelse(nfl_game_days > 0,
  nfl_crashes_alc / nfl_game_days / (population / 100000) * 365.25,
  NA_real_)]
panel_q[, nonnfl_alc_rate := fifelse(nonnfl_days > 0,
  nonnfl_crashes_alc / nonnfl_days / (population / 100000) * 365.25,
  NA_real_)]

# Has NFL team?
nfl_teams <- fread(file.path(data_dir, "nfl_team_states.csv"))
panel_q[, has_nfl_team := as.integer(state_fips %in% nfl_teams$state_fips)]
panel_week[, has_nfl_team := as.integer(state_fips %in% nfl_teams$state_fips)]

# ============================================================
# 7. SAVE PANELS
# ============================================================
fwrite(panel_week, file.path(data_dir, "panel_state_week.csv"))
fwrite(panel_q, file.path(data_dir, "panel_state_quarter.csv"))

# Also save a state-quarter-gameday panel with PROPER per-day rates
panel_gd <- panel_q[nfl_game_days > 0, .(
  state_fips, year, quarter, time_idx, cohort_idx, treated, population,
  has_nfl_team,
  game_day = 1L,
  alc_crashes = nfl_crashes_alc,
  days = nfl_game_days,
  alc_crash_rate = nfl_alc_rate
)]
panel_nongd <- panel_q[, .(
  state_fips, year, quarter, time_idx, cohort_idx, treated, population,
  has_nfl_team,
  game_day = 0L,
  alc_crashes = nonnfl_crashes_alc,
  days = nonnfl_days,
  alc_crash_rate = nonnfl_alc_rate
)]
panel_gameday <- rbind(panel_gd, panel_nongd)
panel_gameday <- panel_gameday[!is.na(alc_crash_rate)]
fwrite(panel_gameday, file.path(data_dir, "panel_gameday.csv"))

cat("\n=== PANEL CONSTRUCTION COMPLETE ===\n")
cat("State-week panel:", nrow(panel_week), "obs\n")
cat("State-quarter panel:", nrow(panel_q), "obs\n")
cat("State-quarter-gameday panel:", nrow(panel_gameday), "obs\n")
cat("Unique states:", uniqueN(panel_q$state_fips), "\n")
cat("Treated states (in-sample):", uniqueN(panel_q[cohort_idx > 0, state_fips]), "\n")
cat("Pre-treatment mean alc_crash_rate (treated):",
    round(panel_q[treated == 0 & cohort_idx > 0, mean(alc_crash_rate, na.rm = TRUE)], 2), "\n")
cat("Pre-treatment mean alc_crash_rate (control):",
    round(panel_q[cohort_idx == 0, mean(alc_crash_rate, na.rm = TRUE)], 2), "\n")
