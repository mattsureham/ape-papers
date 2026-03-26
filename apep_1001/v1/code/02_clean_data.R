## 02_clean_data.R — Construct analysis dataset
## APEP paper apep_1001: Poland Sunday Trading Ban and Traffic Accidents

source("00_packages.R")

cat("=== Cleaning SEWIK data ===\n")

# Load raw data
incidents <- fread("../data/incidents.csv", encoding = "UTF-8")
incidents[, datetime_parsed := as.POSIXct(datetime, format = "%Y-%m-%d %H:%M:%S")]
incidents[, date := as.Date(datetime_parsed)]
incidents[, hour := hour(datetime_parsed)]
incidents[, year := year(date)]
incidents[, month := month(date)]
incidents[, dow := wday(date, week_start = 1)]  # 1=Monday, 7=Sunday

cat(sprintf("Total records: %d\n", nrow(incidents)))
cat(sprintf("Date range: %s to %s\n", min(incidents$date, na.rm=TRUE), max(incidents$date, na.rm=TRUE)))

# ============================================================
# TRADING SUNDAY CALENDAR (Phase 3: 2020-2023)
# Under the Act of 10 January 2018, Phase 3 permits trading only on
# legislatively designated Sundays (~7 per year)
# ============================================================

# Official exempt (trading) Sundays under Phase 3
# Sources: Dziennik Ustaw (Journal of Laws), Art. 7 as amended
trading_sundays <- as.Date(c(
  # 2020
  "2020-01-26", "2020-04-05", "2020-04-26", "2020-06-28",
  "2020-08-30", "2020-12-13", "2020-12-20",
  # 2021
  "2021-01-31", "2021-03-28", "2021-04-25", "2021-06-27",
  "2021-08-29", "2021-12-12", "2021-12-19",
  # 2022
  "2022-01-30", "2022-04-10", "2022-04-24", "2022-06-26",
  "2022-08-28", "2022-12-11", "2022-12-18",
  # 2023
  "2023-01-29", "2023-04-02", "2023-04-23", "2023-06-25",
  "2023-08-27", "2023-12-17", "2023-12-24"
))

# Verify all are Sundays
stopifnot(all(wday(trading_sundays, week_start = 1) == 7))
cat(sprintf("Trading Sundays defined: %d dates\n", length(trading_sundays)))

# ============================================================
# Classify days
# ============================================================
incidents[, is_sunday := (dow == 7)]
incidents[, is_saturday := (dow == 6)]
incidents[, is_trading_sunday := (date %in% trading_sundays)]
incidents[, non_trading := (is_sunday & !is_trading_sunday)]

# Restrict to weekends only (Sat + Sun) for cleaner comparison
weekends <- incidents[is_sunday == TRUE | is_saturday == TRUE]
cat(sprintf("Weekend records: %d\n", nrow(weekends)))

# ============================================================
# Accident type classification
# ============================================================
# Map Polish incident types to English categories
weekends[, accident_type := fcase(
  grepl("piesz", incident_type, ignore.case = TRUE), "pedestrian",
  grepl("zderzeni", incident_type, ignore.case = TRUE), "vehicle_collision",
  grepl("najech.*przeszk|najech.*zap|najech.*unier", incident_type, ignore.case = TRUE), "hit_object",
  grepl("wywróc|przeWróc|przewroc", incident_type, ignore.case = TRUE), "rollover",
  default = "other"
)]

cat("Accident type distribution:\n")
print(weekends[, .N, by = accident_type][order(-N)])

# Intoxication flag
weekends[, intoxicated := (driver_under_influence == TRUE |
                            driver_under_influence == "True")]

# ============================================================
# Aggregate to voivodeship-date level
# ============================================================
daily_voiv <- weekends[, .(
  accidents = .N,
  pedestrian = sum(accident_type == "pedestrian", na.rm = TRUE),
  vehicle_collision = sum(accident_type == "vehicle_collision", na.rm = TRUE),
  intoxicated = sum(intoxicated, na.rm = TRUE)
), by = .(voivodeship, date, year, month, dow, is_sunday, is_saturday,
          is_trading_sunday, non_trading)]

cat(sprintf("\nDaily voivodeship panel: %d obs\n", nrow(daily_voiv)))
cat(sprintf("Voivodeships: %d\n", uniqueN(daily_voiv$voivodeship)))
cat(sprintf("Sundays: %d (trading: %d, non-trading: %d)\n",
            uniqueN(daily_voiv[is_sunday == TRUE]$date),
            uniqueN(daily_voiv[is_trading_sunday == TRUE]$date),
            uniqueN(daily_voiv[non_trading == TRUE]$date)))

# ============================================================
# Hourly aggregation for DDD
# ============================================================
hourly_voiv <- weekends[is_sunday == TRUE, .(
  accidents = .N,
  pedestrian = sum(accident_type == "pedestrian", na.rm = TRUE)
), by = .(voivodeship, date, year, month, hour, is_trading_sunday, non_trading)]

# Shopping hours indicator (10:00-17:59 — typical Polish Sunday opening)
hourly_voiv[, shop_hours := (hour >= 10 & hour <= 17)]

cat(sprintf("Hourly Sunday panel: %d obs\n", nrow(hourly_voiv)))

# ============================================================
# Weather data (merge daily averages)
# ============================================================
weather <- tryCatch({
  w <- fread("../data/weather.csv", encoding = "UTF-8")
  cat(sprintf("Weather columns: %s\n", paste(names(w), collapse = ", ")))
  # Weather CSV has: date, county, voivodeship, temperature, precipitation, humidity
  if ("date" %in% names(w) && "voivodeship" %in% names(w)) {
    w[, date := as.Date(date)]
    precip_col <- intersect(names(w), c("precipitation", "precipation"))
    if (length(precip_col) > 0) {
      setnames(w, precip_col[1], "precip_val")
    } else {
      w[, precip_val := 0]
    }
    w_daily <- w[, .(
      temp_mean = mean(temperature, na.rm = TRUE),
      precip_sum = sum(precip_val, na.rm = TRUE)
    ), by = .(voivodeship, date)]
    cat(sprintf("Weather data: %d voivodeship-day obs\n", nrow(w_daily)))
    w_daily
  } else {
    cat("Weather data format unexpected, skipping weather controls.\n")
    NULL
  }
}, error = function(e) {
  cat(sprintf("Weather data error: %s\n", e$message))
  stop("Weather data is required for controls — cannot proceed without it.")
})

if (!is.null(weather)) {
  daily_voiv <- merge(daily_voiv, weather, by = c("voivodeship", "date"), all.x = TRUE)
  cat(sprintf("Merged weather: %d obs with temp data: %d\n",
              nrow(daily_voiv), sum(!is.na(daily_voiv$temp_mean))))
}

# ============================================================
# Save cleaned datasets
# ============================================================
fwrite(daily_voiv, "../data/daily_voivodeship.csv")
fwrite(hourly_voiv, "../data/hourly_sunday.csv")

# Summary statistics
cat("\n=== Summary Statistics ===\n")
cat(sprintf("Total weekend days: %d\n", uniqueN(daily_voiv$date)))
sunday_stats <- daily_voiv[is_sunday == TRUE, .(
  mean_acc = mean(accidents),
  sd_acc = sd(accidents),
  n_days = uniqueN(date)
), by = .(is_trading_sunday)]
print(sunday_stats)

cat("\n=== Data cleaning complete ===\n")
