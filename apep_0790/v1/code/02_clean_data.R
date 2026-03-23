# 02_clean_data.R — Construct within-year excess PM2.5 outcome
# Key design: July 4-5 PM2.5 minus baseline (adjacent non-holiday days)

source("00_packages.R")

data_dir <- "../data"
daily <- fread(file.path(data_dir, "epa_daily_pm25_filtered.csv"))
daily[, date := as.Date(date)]

cat(sprintf("Loaded %s monitor-days from %d monitors\n",
            format(nrow(daily), big.mark = ","),
            uniqueN(daily$monitor_id)))

# ── Treatment coding ──
# State fireworks legalization years (consumer fireworks, not just sparklers)
# Sources: American Pyrotechnics Association, state statute research
treatment_info <- data.table(
  state_code = c("18", "26", "33", "49", "23", "36", "13", "54", "42", "34", "19", "10", "39"),
  state_abbr = c("IN", "MI", "NH", "UT", "ME", "NY", "GA", "WV", "PA", "NJ", "IA", "DE", "OH"),
  treat_year = c(2006L, 2011L, 2011L, 2011L, 2012L, 2014L, 2015L, 2016L, 2017L, 2017L, 2017L, 2018L, 2022L),
  type = c("full", "full", "full", "full", "full", "sparklers", "full", "full", "full", "sparklers", "full", "full", "full")
)

# States that maintain strict restrictions throughout (never-treated controls)
# Massachusetts, Delaware pre-2018, etc. — but many states already allowed fireworks before 2003
# Control = states that did NOT change their fireworks law during 2003-2023
# States with longstanding bans/restrictions that didn't change
never_treated_states <- c("25") # Massachusetts — strictest, complete ban maintained

# All unique state codes in data
all_states <- unique(daily$state_code)

# Mark treated states
daily <- merge(daily, treatment_info[, .(state_code, treat_year, type)],
               by = "state_code", all.x = TRUE)

# Never-treated get treat_year = Inf (standard for CS estimator with gname)
# States NOT in treatment_info: need to classify
# Strategy: use "not-yet-treated" as comparison — CS handles this
# Set treat_year = 0 for never-treated (did package convention)
daily[is.na(treat_year), treat_year := 0L]
daily[is.na(type), type := "control"]

cat("\n── Treatment groups ──\n")
cat(sprintf("Treated states: %d\n", nrow(treatment_info)))
cat(sprintf("  Full legalization: %d states\n", sum(treatment_info$type == "full")))
cat(sprintf("  Sparklers only: %d states (NY, NJ)\n", sum(treatment_info$type == "sparklers")))
cat(sprintf("  Never-treated (controls): remaining %d states\n",
            length(setdiff(all_states, treatment_info$state_code))))

# ── Construct July 4th excess PM2.5 ──
# For each monitor-year:
#   Holiday PM2.5 = mean PM2.5 on July 4-5
#   Baseline PM2.5 = mean PM2.5 on June 25-July 2 AND July 7-10
#   Excess PM2.5 = Holiday - Baseline
cat("\n── Constructing excess PM2.5 ──\n")

daily[, month := month(date)]
daily[, day := mday(date)]

# Define windows for July 4
daily[, july4_holiday := (month == 7 & day %in% c(4, 5))]
daily[, july4_baseline := (month == 6 & day >= 25) |
        (month == 7 & day %in% c(1, 2, 3)) |
        (month == 7 & day >= 7 & day <= 10)]

# Compute monitor-year averages for holiday and baseline
holiday_avg <- daily[july4_holiday == TRUE, .(
  pm25_holiday = mean(pm25, na.rm = TRUE),
  n_holiday_days = .N
), by = .(monitor_id, year, state_code, lat, lon, treat_year, type)]

baseline_avg <- daily[july4_baseline == TRUE, .(
  pm25_baseline = mean(pm25, na.rm = TRUE),
  sd_pm25_baseline = sd(pm25, na.rm = TRUE),
  n_baseline_days = .N
), by = .(monitor_id, year)]

# Merge
july4 <- merge(holiday_avg, baseline_avg, by = c("monitor_id", "year"))

# Require minimum data coverage
july4 <- july4[n_holiday_days >= 1 & n_baseline_days >= 3]

# Excess PM2.5
july4[, excess_pm25 := pm25_holiday - pm25_baseline]
july4[, log_ratio := log(pm25_holiday / pm25_baseline)]

cat(sprintf("July 4 panel: %s monitor-years\n", format(nrow(july4), big.mark = ",")))
cat(sprintf("  Years: %d-%d\n", min(july4$year), max(july4$year)))
cat(sprintf("  Monitors: %d unique\n", uniqueN(july4$monitor_id)))
cat(sprintf("  Mean excess PM2.5: %.2f µg/m³\n", mean(july4$excess_pm25)))
cat(sprintf("  SD excess PM2.5: %.2f µg/m³\n", sd(july4$excess_pm25)))

# ── Construct placebo holiday excess PM2.5 ──
# New Year's Eve (Dec 31 - Jan 1 vs Dec 28-30, Jan 2-4)
daily[, nye_holiday := (month == 12 & day == 31) | (month == 1 & day == 1)]
daily[, nye_baseline := (month == 12 & day %in% 28:30) | (month == 1 & day %in% 2:4)]

nye_holiday_avg <- daily[nye_holiday == TRUE, .(
  pm25_holiday = mean(pm25, na.rm = TRUE),
  n_holiday_days = .N
), by = .(monitor_id, year = fifelse(month(date) == 12, year(date), year(date) - 1L),
          state_code, lat, lon, treat_year, type)]

nye_baseline_avg <- daily[nye_baseline == TRUE, .(
  pm25_baseline = mean(pm25, na.rm = TRUE),
  n_baseline_days = .N
), by = .(monitor_id, year = fifelse(month(date) == 12, year(date), year(date) - 1L))]

nye <- merge(nye_holiday_avg, nye_baseline_avg, by = c("monitor_id", "year"))
nye <- nye[n_holiday_days >= 1 & n_baseline_days >= 2]
nye[, excess_pm25 := pm25_holiday - pm25_baseline]

cat(sprintf("\nNew Year's Eve panel: %s monitor-years\n", format(nrow(nye), big.mark = ",")))

# Memorial Day (last Monday in May + following Tuesday, vs surrounding days)
# Memorial Day falls on different dates each year — compute it
memorial_day_dates <- function(yr) {
  # Last Monday in May
  may31 <- as.Date(sprintf("%d-05-31", yr))
  wday31 <- as.integer(format(may31, "%u"))  # 1=Monday
  md <- may31 - ((wday31 - 1) %% 7)
  return(md)
}

# For each year, mark Memorial Day windows
daily[, is_mem_holiday := FALSE]
daily[, is_mem_baseline := FALSE]

for (yr in 2003:2023) {
  md <- memorial_day_dates(yr)
  holiday_dates <- md + 0:1  # Monday + Tuesday
  baseline_dates <- c(md - 5, md - 4, md - 3, md + 3, md + 4, md + 5)

  daily[date %in% holiday_dates, is_mem_holiday := TRUE]
  daily[date %in% baseline_dates, is_mem_baseline := TRUE]
}

mem_holiday_avg <- daily[is_mem_holiday == TRUE, .(
  pm25_holiday = mean(pm25, na.rm = TRUE),
  n_holiday_days = .N
), by = .(monitor_id, year, state_code, lat, lon, treat_year, type)]

mem_baseline_avg <- daily[is_mem_baseline == TRUE, .(
  pm25_baseline = mean(pm25, na.rm = TRUE),
  n_baseline_days = .N
), by = .(monitor_id, year)]

memorial <- merge(mem_holiday_avg, mem_baseline_avg, by = c("monitor_id", "year"))
memorial <- memorial[n_holiday_days >= 1 & n_baseline_days >= 2]
memorial[, excess_pm25 := pm25_holiday - pm25_baseline]

cat(sprintf("Memorial Day panel: %s monitor-years\n", format(nrow(memorial), big.mark = ",")))

# ── Random July placebo: July 18-19 vs July 12-16, July 21-24 ──
daily[, placebo_holiday := (month == 7 & day %in% c(18, 19))]
daily[, placebo_baseline := (month == 7 & day %in% c(12, 13, 14, 15, 16)) |
        (month == 7 & day %in% c(21, 22, 23, 24))]

plac_holiday_avg <- daily[placebo_holiday == TRUE, .(
  pm25_holiday = mean(pm25, na.rm = TRUE),
  n_holiday_days = .N
), by = .(monitor_id, year, state_code, lat, lon, treat_year, type)]

plac_baseline_avg <- daily[placebo_baseline == TRUE, .(
  pm25_baseline = mean(pm25, na.rm = TRUE),
  n_baseline_days = .N
), by = .(monitor_id, year)]

placebo_july <- merge(plac_holiday_avg, plac_baseline_avg, by = c("monitor_id", "year"))
placebo_july <- placebo_july[n_holiday_days >= 1 & n_baseline_days >= 3]
placebo_july[, excess_pm25 := pm25_holiday - pm25_baseline]

cat(sprintf("Placebo July (18-19) panel: %s monitor-years\n",
            format(nrow(placebo_july), big.mark = ",")))

# ── Assign state-level info for CS estimator ──
# CS needs: panel id (monitor), time (year), outcome, group (first treat year)
# Collapse to state-year level for more power and proper clustering

state_year <- july4[, .(
  excess_pm25 = mean(excess_pm25, na.rm = TRUE),
  pm25_holiday = mean(pm25_holiday, na.rm = TRUE),
  pm25_baseline = mean(pm25_baseline, na.rm = TRUE),
  n_monitors = .N
), by = .(state_code, year, treat_year, type)]

cat(sprintf("\nState-year panel: %d obs (%d states × %d years)\n",
            nrow(state_year), uniqueN(state_year$state_code), uniqueN(state_year$year)))

# ── Save all datasets ──
fwrite(july4, file.path(data_dir, "july4_monitor_year.csv"))
fwrite(state_year, file.path(data_dir, "july4_state_year.csv"))
fwrite(nye, file.path(data_dir, "nye_monitor_year.csv"))
fwrite(memorial, file.path(data_dir, "memorial_monitor_year.csv"))
fwrite(placebo_july, file.path(data_dir, "placebo_july_monitor_year.csv"))

cat("\n=== Data cleaning complete ===\n")
cat("Files saved:\n")
cat("  july4_monitor_year.csv\n")
cat("  july4_state_year.csv\n")
cat("  nye_monitor_year.csv\n")
cat("  memorial_monitor_year.csv\n")
cat("  placebo_july_monitor_year.csv\n")
