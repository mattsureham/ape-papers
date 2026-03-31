# 02_clean_data.R — Construct analysis variables for apep_1180
# Korea Mandatory English Disclosure paper

source("00_packages.R")

data_dir <- file.path(dirname(getwd()), "data")

# ============================================================
# Load raw data
# ============================================================
daily <- fread(file.path(data_dir, "daily_stock_data.csv"))
firms <- fread(file.path(data_dir, "firm_characteristics.csv"))

cat("Daily observations:", nrow(daily), "\n")
cat("Firms:", nrow(firms), "\n")

# ============================================================
# Merge firm characteristics
# ============================================================
daily <- merge(daily, firms[, .(ticker, name, market_cap, total_assets, sector,
                                 shares_outstanding, phase1)],
               by = "ticker", all.x = TRUE)

# Drop firms without phase1 classification
daily <- daily[!is.na(phase1)]
cat("After merging with firm data:", nrow(daily), "\n")

# ============================================================
# Date variables
# ============================================================
daily[, date := as.Date(date)]
daily[, year := year(date)]
daily[, month := month(date)]
daily[, yearmonth := year * 100 + month]
daily[, week := format(date, "%Y-W%V")]

# Treatment date: January 2, 2024 (first trading day of 2024)
TREATMENT_DATE <- as.Date("2024-01-02")
daily[, post := as.integer(date >= TREATMENT_DATE)]

# ============================================================
# Construct outcome variables
# ============================================================

# Daily return
daily[, ret := c(NA, diff(log(close))), by = ticker]

# Amihud illiquidity ratio: |return| / (volume * close)
# Volume in KRW = volume * close price
daily[, volume_krw := volume * close]
daily[, amihud := abs(ret) / (volume_krw / 1e9)]  # Scale volume to billions KRW
# Handle zeros and extremes
daily[volume_krw == 0, amihud := NA]
daily[amihud > quantile(amihud, 0.999, na.rm = TRUE), amihud := NA]

# Log Amihud (for regression — more normally distributed)
daily[, log_amihud := log(amihud + 1e-10)]

# Trading turnover: volume / shares outstanding
daily[, turnover := volume / shares_outstanding]
daily[is.infinite(turnover) | is.na(shares_outstanding), turnover := NA]
daily[, log_turnover := log(turnover + 1e-10)]

# Absolute return (volatility proxy)
daily[, abs_ret := abs(ret)]

# ============================================================
# Weekly aggregation (primary analysis level)
# ============================================================
weekly <- daily[!is.na(ret), .(
  amihud_w    = mean(amihud, na.rm = TRUE),
  turnover_w  = mean(turnover, na.rm = TRUE),
  abs_ret_w   = mean(abs_ret, na.rm = TRUE),
  volume_w    = mean(volume, na.rm = TRUE),
  close_w     = mean(close, na.rm = TRUE),
  n_days      = .N
), by = .(ticker, week, phase1, post, sector, market_cap, total_assets, name)]

# Log transformations
weekly[, log_amihud_w := log(amihud_w + 1e-10)]
weekly[, log_turnover_w := log(turnover_w + 1e-10)]

# Week number relative to treatment (for event study)
# Parse week string to get a numeric week index
weekly[, week_date := as.Date(paste0(substr(week, 1, 4), "-W",
                                      substr(week, 7, 8), "-1"),
                               format = "%Y-W%V-%u")]
weekly[, week_num := as.integer(difftime(week_date, TREATMENT_DATE, units = "weeks"))]

# Drop incomplete weeks (< 3 trading days)
weekly <- weekly[n_days >= 3]

cat("Weekly observations:", nrow(weekly), "\n")
cat("Unique firms:", uniqueN(weekly$ticker), "\n")
cat("Treated firms:", uniqueN(weekly[phase1 == 1]$ticker), "\n")
cat("Control firms:", uniqueN(weekly[phase1 == 0]$ticker), "\n")
cat("Weeks:", uniqueN(weekly$week), "\n")

# ============================================================
# Monthly aggregation (for RDD)
# ============================================================
daily[, yearmonth_str := format(date, "%Y-%m")]
monthly <- daily[!is.na(ret), .(
  amihud_m    = mean(amihud, na.rm = TRUE),
  turnover_m  = mean(turnover, na.rm = TRUE),
  abs_ret_m   = mean(abs_ret, na.rm = TRUE),
  volume_m    = mean(volume, na.rm = TRUE),
  close_m     = mean(close, na.rm = TRUE),
  n_days      = .N
), by = .(ticker, yearmonth, yearmonth_str, phase1, post, sector,
          market_cap, total_assets, name)]

monthly[, log_amihud_m := log(amihud_m + 1e-10)]
monthly[, log_turnover_m := log(turnover_m + 1e-10)]

# Relative month
monthly[, month_rel := as.integer(yearmonth %/% 100) * 12 +
                        (yearmonth %% 100) -
                        (2024 * 12 + 1)]

cat("Monthly observations:", nrow(monthly), "\n")

# ============================================================
# Save cleaned data
# ============================================================
fwrite(daily, file.path(data_dir, "daily_clean.csv"))
fwrite(weekly, file.path(data_dir, "weekly_panel.csv"))
fwrite(monthly, file.path(data_dir, "monthly_panel.csv"))

cat("\nCleaned data saved.\n")

# ============================================================
# Summary statistics for text
# ============================================================
cat("\n--- Summary Statistics ---\n")
cat("Pre-period weeks (treated):", nrow(weekly[phase1 == 1 & post == 0]), "\n")
cat("Post-period weeks (treated):", nrow(weekly[phase1 == 1 & post == 1]), "\n")
cat("Pre-period weeks (control):", nrow(weekly[phase1 == 0 & post == 0]), "\n")
cat("Post-period weeks (control):", nrow(weekly[phase1 == 0 & post == 1]), "\n")

cat("\nAmihud illiquidity (weekly mean):\n")
cat("  Treated pre:", round(mean(weekly[phase1 == 1 & post == 0]$amihud_w, na.rm = TRUE), 6), "\n")
cat("  Treated post:", round(mean(weekly[phase1 == 1 & post == 1]$amihud_w, na.rm = TRUE), 6), "\n")
cat("  Control pre:", round(mean(weekly[phase1 == 0 & post == 0]$amihud_w, na.rm = TRUE), 6), "\n")
cat("  Control post:", round(mean(weekly[phase1 == 0 & post == 1]$amihud_w, na.rm = TRUE), 6), "\n")

cat("\nTurnover (weekly mean):\n")
cat("  Treated pre:", round(mean(weekly[phase1 == 1 & post == 0]$turnover_w, na.rm = TRUE), 6), "\n")
cat("  Treated post:", round(mean(weekly[phase1 == 1 & post == 1]$turnover_w, na.rm = TRUE), 6), "\n")
cat("  Control pre:", round(mean(weekly[phase1 == 0 & post == 0]$turnover_w, na.rm = TRUE), 6), "\n")
cat("  Control post:", round(mean(weekly[phase1 == 0 & post == 1]$turnover_w, na.rm = TRUE), 6), "\n")
