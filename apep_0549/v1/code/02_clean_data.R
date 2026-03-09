## =============================================================================
## 02_clean_data.R — Construct analysis panels from FARS crash-level data
## =============================================================================

source("00_packages.R")

data_dir <- "../data/"
fars <- fread(file.path(data_dir, "fars_panel.csv"))
fars[, date := as.Date(date)]
fars[, treat_date := as.Date(treat_date)]

cat(sprintf("Loaded %d crash records\n", nrow(fars)))

## -----------------------------------------------------------------------------
## 1. State × Month Panel (for CS-DiD)
## -----------------------------------------------------------------------------

cat("Building state × month panel...\n")

# First aggregate crash-level data to state-month
sm_agg <- fars[, .(
  total_crashes    = .N,
  alcohol_crashes  = sum(alcohol),
  non_alc_crashes  = sum(1 - alcohol),
  fatalities       = sum(FATALS),
  alc_fatalities   = sum(FATALS * alcohol),
  night_alc        = sum(alcohol * nighttime),
  day_alc          = sum(alcohol * (1 - nighttime)),
  sunday_alc       = sum(alcohol * is_sunday),
  non_sunday_alc   = sum(alcohol * (1 - is_sunday)),
  nfl_sun_alc      = sum(alcohol * nfl_sunday),
  measured_alc_crashes = sum(measured_alc, na.rm = TRUE)
), by = .(state_fips, YEAR, MONTH)]

# Create COMPLETE grid: all state × year-month combinations
sm_states <- unique(fars$state_fips)
sm_years  <- unique(fars$YEAR)
sm_months <- 1:12

sm_grid <- CJ(state_fips = sm_states, YEAR = sm_years, MONTH = sm_months)

# Merge crash counts onto complete grid (zero-fill missing cells)
state_month <- merge(sm_grid, sm_agg,
                     by = c("state_fips", "YEAR", "MONTH"),
                     all.x = TRUE)
state_month[is.na(total_crashes),   total_crashes := 0L]
state_month[is.na(alcohol_crashes), alcohol_crashes := 0L]
state_month[is.na(non_alc_crashes), non_alc_crashes := 0L]
state_month[is.na(fatalities),      fatalities := 0L]
state_month[is.na(alc_fatalities),  alc_fatalities := 0L]
state_month[is.na(night_alc),       night_alc := 0L]
state_month[is.na(day_alc),         day_alc := 0L]
state_month[is.na(sunday_alc),      sunday_alc := 0L]
state_month[is.na(non_sunday_alc),  non_sunday_alc := 0L]
state_month[is.na(nfl_sun_alc),     nfl_sun_alc := 0L]
state_month[is.na(measured_alc_crashes), measured_alc_crashes := 0L]

# Population merge (from state-year level)
sm_pop <- unique(fars[, .(state_fips, YEAR, pop)])[, .(pop = first(pop)),
                                                     by = .(state_fips, YEAR)]
state_month <- merge(state_month, sm_pop,
                     by = c("state_fips", "YEAR"), all.x = TRUE)

# Rates per 100K population
state_month[, `:=`(
  alc_rate     = alcohol_crashes / pop * 100000 * 12,
  non_alc_rate = non_alc_crashes / pop * 100000 * 12,
  total_rate   = total_crashes / pop * 100000 * 12
)]

# Time variables
state_month[, year_month := sprintf("%d-%02d", YEAR, MONTH)]
state_month[, time_id := (YEAR - 2015) * 12 + MONTH]

# Treatment merge
treat_dt <- unique(fars[!is.na(treat_date), .(state_fips, treat_date, cohort_ym)])
state_month <- merge(state_month, treat_dt, by = "state_fips", all.x = TRUE)

state_month[, treated := as.integer(!is.na(treat_date) &
              as.Date(sprintf("%d-%02d-01", YEAR, MONTH)) >= treat_date)]
state_month[, ever_treated := as.integer(!is.na(treat_date))]

# CS-DiD group variable: cohort in time_id units (0 for never-treated)
# Must be on same scale as tname for did::att_gt()
state_month[, g := fifelse(is.na(treat_date), 0L,
                            as.integer((year(treat_date) - 2015L) * 12L + month(treat_date)))]

cat(sprintf("State-month panel: %d obs, %d states, %d months (complete grid)\n",
            nrow(state_month), length(unique(state_month$state_fips)),
            length(unique(state_month$time_id))))

## -----------------------------------------------------------------------------
## 2. State × Year Panel (for annual robustness)
## -----------------------------------------------------------------------------

cat("Building state × year panel...\n")

state_year <- fars[, .(
  total_crashes    = .N,
  alcohol_crashes  = sum(alcohol),
  non_alc_crashes  = sum(1 - alcohol),
  fatalities       = sum(FATALS),
  alc_fatalities   = sum(FATALS * alcohol),
  night_alc        = sum(alcohol * nighttime),
  day_alc          = sum(alcohol * (1 - nighttime)),
  sunday_alc       = sum(alcohol * is_sunday),
  non_sunday_alc   = sum(alcohol * (1 - is_sunday)),
  nfl_sun_alc      = sum(alcohol * nfl_sunday),
  measured_alc_crashes = sum(measured_alc, na.rm = TRUE),
  pop              = first(pop)
), by = .(state_fips, YEAR)]

state_year[, `:=`(
  alc_rate     = alcohol_crashes / pop * 100000,
  non_alc_rate = non_alc_crashes / pop * 100000,
  total_rate   = total_crashes / pop * 100000
)]

state_year <- merge(state_year, treat_dt, by = "state_fips", all.x = TRUE)
state_year[, treated := as.integer(!is.na(treat_date) &
              as.Date(sprintf("%d-07-01", YEAR)) >= treat_date)]
state_year[, ever_treated := as.integer(!is.na(treat_date))]

# Treatment year for CS-DiD
state_year[, treat_year := fifelse(is.na(treat_date), 0L,
                                    as.integer(format(treat_date, "%Y")))]

cat(sprintf("State-year panel: %d obs\n", nrow(state_year)))

## -----------------------------------------------------------------------------
## 3. State × Day-of-Week × Month Panel (for DDD)
## -----------------------------------------------------------------------------

cat("Building state × day-of-week × month panel...\n")

# First aggregate crash-level data
state_dow_agg <- fars[, .(
  total_crashes   = .N,
  alcohol_crashes = sum(alcohol),
  non_alc_crashes = sum(1 - alcohol),
  night_alc       = sum(alcohol * nighttime),
  measured_alc    = sum(measured_alc, na.rm = TRUE)
), by = .(state_fips, YEAR, MONTH, dow)]

# Create COMPLETE grid: all state × DOW × year-month combinations
all_states <- unique(fars$state_fips)
all_years  <- unique(fars$YEAR)
all_months <- 1:12
all_dows   <- 1:7

complete_grid <- CJ(state_fips = all_states, YEAR = all_years,
                    MONTH = all_months, dow = all_dows)

# Merge crash counts onto complete grid (zero-fill missing cells)
state_dow_month <- merge(complete_grid, state_dow_agg,
                         by = c("state_fips", "YEAR", "MONTH", "dow"),
                         all.x = TRUE)
state_dow_month[is.na(total_crashes),   total_crashes := 0L]
state_dow_month[is.na(alcohol_crashes), alcohol_crashes := 0L]
state_dow_month[is.na(non_alc_crashes), non_alc_crashes := 0L]
state_dow_month[is.na(night_alc),       night_alc := 0L]
state_dow_month[is.na(measured_alc),    measured_alc := 0L]

# NFL season indicator
state_dow_month[, nfl_season := as.integer(MONTH %in% c(9, 10, 11, 12, 1, 2))]

# Population merge (from state-month level)
pop_dt <- unique(fars[, .(state_fips, YEAR, pop)])[, .(pop = first(pop)),
                                                     by = .(state_fips, YEAR)]
state_dow_month <- merge(state_dow_month, pop_dt,
                         by = c("state_fips", "YEAR"), all.x = TRUE)

# Sunday indicator
state_dow_month[, is_sunday := as.integer(dow == 1)]

# Treatment merge
state_dow_month <- merge(state_dow_month, treat_dt, by = "state_fips", all.x = TRUE)
state_dow_month[, treated := as.integer(!is.na(treat_date) &
                  as.Date(sprintf("%d-%02d-15", YEAR, MONTH)) >= treat_date)]
state_dow_month[, ever_treated := as.integer(!is.na(treat_date))]

# DDD interaction
state_dow_month[, legal_x_sunday := treated * is_sunday]
state_dow_month[, legal_x_sunday_x_nfl := treated * is_sunday * nfl_season]

# Compute number of occurrences of each DOW in each year-month (for exposure normalization)
# e.g., January 2015 has 4 Sundays; March 2015 has 5 Sundays
dow_counts <- unique(fars[, .(date, dow = DAY_WEEK, YEAR, MONTH)])[,
  .(n_dow_in_month = .N), by = .(YEAR, MONTH, dow)]
state_dow_month <- merge(state_dow_month, dow_counts,
                         by = c("YEAR", "MONTH", "dow"), all.x = TRUE)
# Some cells may not have FARS records for a given DOW in a month;
# fill using calendar computation
state_dow_month[is.na(n_dow_in_month), n_dow_in_month := {
  # Compute from calendar: how many times does DOW appear in year-month?
  first_day <- as.Date(sprintf("%d-%02d-01", YEAR, MONTH))
  last_day <- first_day + lubridate::days_in_month(first_day) - 1
  all_days <- seq(first_day, last_day, by = "day")
  # R wday: 1=Sun, 2=Mon, ..., 7=Sat (same as FARS DAY_WEEK)
  sum(lubridate::wday(all_days) == dow)
}, by = .(YEAR, MONTH, dow)]

# Exposure-normalized outcome: crashes per occurrence of that DOW
state_dow_month[, alc_per_dow := alcohol_crashes / n_dow_in_month]
state_dow_month[, non_alc_per_dow := non_alc_crashes / n_dow_in_month]

# Panel IDs
state_dow_month[, time_id := (YEAR - 2015) * 12 + MONTH]
state_dow_month[, state_dow := paste0(state_fips, "_", dow)]
state_dow_month[, state_month := paste0(state_fips, "_", YEAR, "_", MONTH)]

cat(sprintf("State-DOW-month panel: %d obs (complete grid: %d states × 7 DOW × %d months)\n",
            nrow(state_dow_month), length(all_states),
            length(all_years) * length(all_months)))

## -----------------------------------------------------------------------------
## 4. Summary statistics
## -----------------------------------------------------------------------------

cat("\n=== Summary Statistics ===\n")

# Overall
cat(sprintf("Total crashes: %s\n", format(nrow(fars), big.mark = ",")))
cat(sprintf("Alcohol-involved: %s (%.1f%%)\n",
            format(sum(fars$alcohol), big.mark = ","),
            100 * mean(fars$alcohol)))

# By treatment status
cat("\nBy treatment status (state-year):\n")
print(state_year[, .(
  mean_alc_crashes = mean(alcohol_crashes),
  mean_alc_rate = mean(alc_rate),
  mean_non_alc_rate = mean(non_alc_rate),
  n_states = uniqueN(state_fips)
), by = .(ever_treated, treated)])

# By day of week
cat("\nAlcohol crash share by day of week:\n")
dow_stats <- fars[, .(
  total = .N,
  alcohol = sum(alcohol),
  alc_share = mean(alcohol)
), by = dow]
setorder(dow_stats, dow)
dow_stats[, day_name := c("Sunday", "Monday", "Tuesday", "Wednesday",
                           "Thursday", "Friday", "Saturday")]
print(dow_stats[, .(day_name, total, alcohol, alc_pct = round(100 * alc_share, 1))])

## -----------------------------------------------------------------------------
## 5. Save analysis panels
## -----------------------------------------------------------------------------

fwrite(state_month, file.path(data_dir, "state_month_panel.csv"))
fwrite(state_year, file.path(data_dir, "state_year_panel.csv"))
fwrite(state_dow_month, file.path(data_dir, "state_dow_month_panel.csv"))

# Summary stats for tables
sumstats <- fars[, .(
  variable = c("Total fatal crashes", "Alcohol-involved crashes",
               "Non-alcohol crashes", "Fatalities (total)",
               "Sunday crashes", "Nighttime crashes (8PM-3AM)",
               "NFL Sunday alcohol crashes"),
  mean = c(mean(.N), mean(sum(alcohol)), mean(sum(1 - alcohol)),
           mean(sum(FATALS)), mean(sum(is_sunday)),
           mean(sum(nighttime)), mean(sum(nfl_sunday * alcohol))),
  sd = rep(NA_real_, 7),
  N = rep(nrow(fars), 7)
)]

# Better approach: compute at state-year level
sumstats_sy <- state_year[, .(
  Variable = "State-year",
  alc_crashes_mean = mean(alcohol_crashes),
  alc_crashes_sd = sd(alcohol_crashes),
  non_alc_mean = mean(non_alc_crashes),
  non_alc_sd = sd(non_alc_crashes),
  alc_rate_mean = mean(alc_rate),
  alc_rate_sd = sd(alc_rate),
  non_alc_rate_mean = mean(non_alc_rate),
  non_alc_rate_sd = sd(non_alc_rate),
  pop_mean = mean(pop),
  pop_sd = sd(pop),
  N = .N
)]

fwrite(sumstats_sy, file.path(data_dir, "summary_stats.csv"))

cat("\nAll panels saved to data/\n")
cat(sprintf("  state_month_panel.csv: %d rows\n", nrow(state_month)))
cat(sprintf("  state_year_panel.csv: %d rows\n", nrow(state_year)))
cat(sprintf("  state_dow_month_panel.csv: %d rows\n", nrow(state_dow_month)))
