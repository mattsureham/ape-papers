## 02_clean_data.R — Clean crime data and merge with payment calendar
## apep_1117: Payday Depletion Cycle and Property Crime in Buenos Aires

source("00_packages.R")

data_dir <- "../data"

## ============================================================
## PART 1: Clean crime data
## ============================================================

crime <- fread(file.path(data_dir, "crime_all_years.csv"))
cat(sprintf("Raw crime records: %s\n", format(nrow(crime), big.mark = ",")))

## Parse date
crime[, date := as.Date(fecha)]
crime <- crime[!is.na(date)]

## Classify crime types
crime[, crime_type := fcase(
  tipo == "Robo", "robbery",
  tipo == "Hurto", "theft",
  tipo == "Lesiones", "assault",
  tipo == "Amenazas", "threats",
  tipo == "Homicidios", "homicide",
  default = "other"
)]

## Property crime indicator (our main outcome)
crime[, property_crime := as.integer(crime_type %in% c("robbery", "theft"))]

## Violent non-property crime (placebo outcome)
crime[, violent_nonprop := as.integer(crime_type %in% c("assault", "threats"))]

## Extract commune (geographic unit)
crime[, comuna := as.integer(gsub("^Comuna ", "", as.character(comuna)))]

## Extract time variables
crime[, `:=`(
  year = year(date),
  month = month(date),
  dow = wday(date),   # 1=Sun, 7=Sat
  day = mday(date)
)]

cat(sprintf("Cleaned records: %s\n", format(nrow(crime), big.mark = ",")))
cat(sprintf("Date range: %s to %s\n", min(crime$date), max(crime$date)))

## ============================================================
## PART 2: Aggregate to daily crime counts
## ============================================================

## City-level daily counts by crime type
daily_total <- crime[, .(
  property_crimes = sum(property_crime),
  robbery = sum(crime_type == "robbery"),
  theft = sum(crime_type == "theft"),
  violent_nonprop = sum(violent_nonprop),
  assault = sum(crime_type == "assault"),
  threats = sum(crime_type == "threats"),
  total_crimes = .N
), by = date]

daily_total[, `:=`(
  year = year(date),
  month = month(date),
  dow = wday(date),
  ym = format(date, "%Y-%m")
)]

cat(sprintf("\nDaily panel: %d days\n", nrow(daily_total)))
cat(sprintf("Avg daily property crimes: %.1f\n",
            mean(daily_total$property_crimes)))
cat(sprintf("Avg daily robbery: %.1f\n", mean(daily_total$robbery)))
cat(sprintf("Avg daily theft: %.1f\n", mean(daily_total$theft)))

## ============================================================
## PART 3: Merge with payment calendar — compute "days since payment"
## ============================================================

calendar <- fread(file.path(data_dir, "anses_payment_calendar.csv"))
calendar[, payment_date := as.Date(payment_date)]

## For each calendar day, compute: for each digit group, how many days
## since that group's most recent payment?
## Then aggregate across all 10 digit groups.

## Build a full date sequence
all_dates <- data.table(date = seq(min(daily_total$date),
                                    max(daily_total$date), by = "day"))
all_dates[, `:=`(year = year(date), month = month(date))]

## For each digit group × date, find the most recent payment date
## We need to look at current month and previous month's payment
digit_day_list <- list()

for (dig in 0:9) {
  dig_cal <- calendar[digit == dig, .(payment_date)]
  setorder(dig_cal, payment_date)

  ## For each date in our panel, find the most recent payment for this digit
  merged <- all_dates[, .(date)]

  ## Rolling join: for each date, find the most recent payment_date <= date
  merged[, join_date := date]
  dig_cal[, join_date := payment_date]

  setkey(merged, join_date)
  setkey(dig_cal, join_date)

  result <- dig_cal[merged, roll = TRUE]
  result[, `:=`(
    digit = dig,
    days_since_payment = as.integer(date - payment_date)
  )]

  digit_day_list[[dig + 1]] <- result[, .(date, digit, payment_date,
                                           days_since_payment)]
}

digit_day <- rbindlist(digit_day_list)

## Remove observations where days_since_payment is NA or negative
digit_day <- digit_day[!is.na(days_since_payment) & days_since_payment >= 0]

cat(sprintf("\nDigit-day panel: %d observations\n", nrow(digit_day)))
cat(sprintf("Days since payment range: %d to %d\n",
            min(digit_day$days_since_payment),
            max(digit_day$days_since_payment)))

## ============================================================
## PART 4: Create city-level aggregated "days since payment" measure
## ============================================================

## Average days-since-payment across all 10 digit groups for each day
avg_dsp <- digit_day[, .(
  avg_days_since_payment = mean(days_since_payment),
  min_days_since_payment = min(days_since_payment),
  max_days_since_payment = max(days_since_payment),
  n_digits = .N
), by = date]

## Merge with daily crime counts
daily <- merge(daily_total, avg_dsp, by = "date", all.x = TRUE)
daily <- daily[!is.na(avg_days_since_payment)]

cat(sprintf("\nFinal daily panel: %d days\n", nrow(daily)))
cat(sprintf("Avg 'days since payment' (city mean): %.1f\n",
            mean(daily$avg_days_since_payment)))

## ============================================================
## PART 5: Create binned days-since-payment categories
## ============================================================

## Bin into categories for non-parametric estimation
daily[, dsp_bin := fcase(
  avg_days_since_payment <= 2, "0-2 (just paid)",
  avg_days_since_payment <= 5, "3-5",
  avg_days_since_payment <= 10, "6-10",
  avg_days_since_payment <= 15, "11-15",
  avg_days_since_payment <= 20, "16-20",
  default = "21+"
)]

daily[, dsp_bin := factor(dsp_bin,
  levels = c("0-2 (just paid)", "3-5", "6-10", "11-15", "16-20", "21+"))]

## Create digit-group level panel for more granular analysis
digit_day_crime <- merge(digit_day, daily_total[, .(date, property_crimes,
  robbery, theft, violent_nonprop, total_crimes, dow, year, month)],
  by = "date")

## Bin days since payment at digit level
digit_day_crime[, dsp_bin_dig := fcase(
  days_since_payment == 0, "payday",
  days_since_payment <= 3, "1-3",
  days_since_payment <= 7, "4-7",
  days_since_payment <= 14, "8-14",
  days_since_payment <= 21, "15-21",
  default = "22+"
)]

digit_day_crime[, dsp_bin_dig := factor(dsp_bin_dig,
  levels = c("payday", "1-3", "4-7", "8-14", "15-21", "22+"))]

## ============================================================
## PART 6: Save analysis-ready datasets
## ============================================================

fwrite(daily, file.path(data_dir, "daily_panel.csv"))
fwrite(digit_day_crime, file.path(data_dir, "digit_day_panel.csv"))
fwrite(digit_day, file.path(data_dir, "digit_day_dsp.csv"))

cat("\n=== Final Dataset Summary ===\n")
cat(sprintf("Daily city panel: %d rows × %d cols\n",
            nrow(daily), ncol(daily)))
cat(sprintf("Digit-day panel: %d rows × %d cols\n",
            nrow(digit_day_crime), ncol(digit_day_crime)))

cat("\nProperty crimes by DSP bin (city-level):\n")
print(daily[, .(
  mean_crime = round(mean(property_crimes), 1),
  sd_crime = round(sd(property_crimes), 1),
  n_days = .N
), by = dsp_bin][order(dsp_bin)])

cat("\nCleaning complete.\n")
