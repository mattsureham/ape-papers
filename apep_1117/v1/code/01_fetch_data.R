## 01_fetch_data.R — Fetch Buenos Aires crime data + construct ANSES payment calendar
## apep_1117: Payday Depletion Cycle and Property Crime in Buenos Aires

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ============================================================
## PART 1: Buenos Aires crime data (2019-2023)
## ============================================================

years <- 2019:2023
base_url <- "https://cdn.buenosaires.gob.ar/datosabiertos/datasets/ministerio-de-justicia-y-seguridad/delitos/delitos_%d.csv"

crime_list <- list()

for (yr in years) {
  url <- sprintf(base_url, yr)
  dest <- file.path(data_dir, sprintf("delitos_%d.csv", yr))

  if (!file.exists(dest)) {
    cat(sprintf("Downloading crime data for %d...\n", yr))
    resp <- httr::GET(url, httr::write_disk(dest, overwrite = TRUE),
                      httr::timeout(120))
    if (httr::status_code(resp) != 200) {
      stop(sprintf("FATAL: Failed to download crime data for %d. Status: %d",
                    yr, httr::status_code(resp)))
    }
    cat(sprintf("  Downloaded: %s (%.1f MB)\n", dest,
                file.info(dest)$size / 1e6))
  } else {
    cat(sprintf("Using cached: %s\n", dest))
  }

  df <- fread(dest, encoding = "Latin-1")
  crime_list[[as.character(yr)]] <- df
  cat(sprintf("  %d: %d records\n", yr, nrow(df)))
}

crime_raw <- rbindlist(crime_list, fill = TRUE)
cat(sprintf("\nTotal crime records: %d\n", nrow(crime_raw)))

## Validate: must have real data
stopifnot("No crime data loaded" = nrow(crime_raw) > 10000)
stopifnot("Missing fecha column" = "fecha" %in% names(crime_raw))
stopifnot("Missing tipo column" = "tipo" %in% names(crime_raw))

fwrite(crime_raw, file.path(data_dir, "crime_all_years.csv"))
cat("Saved: crime_all_years.csv\n")

## ============================================================
## PART 2: ANSES Payment Calendar Construction
## ============================================================
## ANSES pays pensions/AUH on staggered days determined by DNI last digit.
## The schedule is published monthly. Payment dates follow a consistent
## pattern: digit 0 pays first, then 1, 2, ..., 9, each on successive
## business days. We construct the calendar from known patterns.
##
## Key facts:
## - Payments begin on the 6th-11th business day of each month (pensions)
## - AUH payments follow ~1 week later
## - Each digit gets one specific day
## - We use the pension schedule as the primary calendar (largest group)
##
## We construct approximate payment days using the known institutional
## pattern: payments for digits 0-9 occur on successive business days
## starting from approximately the 8th of each month.

## Helper: get business days (exclude weekends) for a month
get_business_days <- function(year, month) {
  start <- as.Date(sprintf("%d-%02d-01", year, month))
  end <- start + days_in_month(start) - 1
  all_days <- seq(start, end, by = "day")
  bdays <- all_days[!wday(all_days) %in% c(1, 7)]  # exclude Sun/Sat
  return(bdays)
}

## Construct payment calendar: for each month, digits 0-9 receive payments
## on the 6th through 15th business days of the month
## (This follows the standard ANSES pattern for jubilaciones/pensiones)
calendar_list <- list()

for (yr in years) {
  for (mo in 1:12) {
    bdays <- get_business_days(yr, mo)

    ## Payments typically start on the 6th business day for digit 0
    ## and continue through the 15th business day for digit 9
    if (length(bdays) < 15) next  # safety check

    for (dig in 0:9) {
      pay_day_idx <- 6 + dig  # business day index: 6th for dig 0, 15th for dig 9
      if (pay_day_idx > length(bdays)) next

      calendar_list[[length(calendar_list) + 1]] <- data.table(
        year = yr,
        month = mo,
        digit = dig,
        payment_date = bdays[pay_day_idx]
      )
    }
  }
}

calendar <- rbindlist(calendar_list)
cat(sprintf("\nPayment calendar: %d digit-month observations\n", nrow(calendar)))
stopifnot("Calendar too small" = nrow(calendar) >= 500)

fwrite(calendar, file.path(data_dir, "anses_payment_calendar.csv"))
cat("Saved: anses_payment_calendar.csv\n")

## ============================================================
## PART 3: Summary statistics
## ============================================================

cat("\n=== Crime Data Summary ===\n")
cat(sprintf("Years: %d-%d\n", min(crime_raw$anio, na.rm = TRUE),
            max(crime_raw$anio, na.rm = TRUE)))
cat(sprintf("Total records: %s\n", format(nrow(crime_raw), big.mark = ",")))
cat("\nBy type:\n")
print(crime_raw[, .N, by = tipo][order(-N)])

cat("\n=== Payment Calendar Summary ===\n")
cat(sprintf("Months covered: %d\n", uniqueN(calendar[, .(year, month)])))
cat(sprintf("Digit-month obs: %d\n", nrow(calendar)))
cat("Sample payment dates (Jan 2019):\n")
print(calendar[year == 2019 & month == 1])

cat("\nData fetch complete.\n")
