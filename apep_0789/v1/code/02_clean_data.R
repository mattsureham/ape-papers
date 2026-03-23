# 02_clean_data.R — Clean JEPX data and construct analysis panel
library(data.table)
library(lubridate)

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(normalizePath(sub("--file=", "", args[grep("--file=", args)])))
setwd(dirname(script_dir))

jepx <- readRDS("data/jepx_raw.rds")
regions_info <- readRDS("data/regions.rds")
first_restart <- readRDS("data/first_restart.rds")

# ─── 1. Reshape from wide to long ─────────────────────────────────────────
cat("Reshaping JEPX data...\n")

# Map column names to standard region names
col_map <- c(
  "Hokkaido Yen/kWh" = "Hokkaido",
  "Tohoku Yen/kWh" = "Tohoku",
  "Tokyo Yen/kWh" = "Tokyo",
  "Chuubu Yen/kWh" = "Chubu",
  "Hokuriku Yen/kWh" = "Hokuriku",
  "Kansai Yen/kWh" = "Kansai",
  "Chuugoku Yen/kWh" = "Chugoku",
  "Kyushu Yen/kWh" = "Kyushu",
  "Shikoku Yen/kWh" = "Shikoku"
)

# Parse datetime
jepx[, datetime_parsed := as.POSIXct(datetime, format = "%Y-%m-%d %H:%M:%S")]
jepx[, date := as.Date(datetime_parsed)]
jepx[, hour := hour(datetime_parsed)]

# Melt to long format
price_cols <- names(col_map)
jepx_long <- melt(jepx, id.vars = c("datetime_parsed", "date", "hour", "PeriodID"),
                  measure.vars = price_cols, variable.name = "region_col",
                  value.name = "price_yen_kwh")
jepx_long[, region := col_map[as.character(region_col)]]
jepx_long[, region_col := NULL]

# Drop Okinawa (not in JEPX) and any missing
jepx_long <- jepx_long[!is.na(region) & !is.na(price_yen_kwh)]
cat(sprintf("Long format: %d observations, %d regions\n",
            nrow(jepx_long), uniqueN(jepx_long$region)))

# ─── 2. Aggregate to monthly level ────────────────────────────────────────
cat("Aggregating to monthly level...\n")

jepx_long[, year_month := floor_date(date, "month")]

monthly <- jepx_long[, .(
  price_mean = mean(price_yen_kwh, na.rm = TRUE),
  price_median = median(price_yen_kwh, na.rm = TRUE),
  price_sd = sd(price_yen_kwh, na.rm = TRUE),
  price_p10 = quantile(price_yen_kwh, 0.10, na.rm = TRUE),
  price_p90 = quantile(price_yen_kwh, 0.90, na.rm = TRUE),
  n_obs = .N
), by = .(region, year_month)]

# Create peak/off-peak aggregates (peak: 8am-8pm, off-peak: 8pm-8am)
jepx_long[, peak := hour >= 8 & hour < 20]

monthly_peak <- jepx_long[peak == TRUE, .(
  price_peak = mean(price_yen_kwh, na.rm = TRUE)
), by = .(region, year_month)]

monthly_offpeak <- jepx_long[peak == FALSE, .(
  price_offpeak = mean(price_yen_kwh, na.rm = TRUE)
), by = .(region, year_month)]

monthly <- merge(monthly, monthly_peak, by = c("region", "year_month"), all.x = TRUE)
monthly <- merge(monthly, monthly_offpeak, by = c("region", "year_month"), all.x = TRUE)

cat(sprintf("Monthly panel: %d region-months, %d regions, %s to %s\n",
            nrow(monthly), uniqueN(monthly$region),
            min(monthly$year_month), max(monthly$year_month)))

# ─── 3. Merge treatment information ───────────────────────────────────────
cat("Merging treatment status...\n")

monthly <- merge(monthly, regions_info[, .(region, frequency_hz, grid, treated)],
                 by = "region", all.x = TRUE)
monthly <- merge(monthly, first_restart[, .(region, first_restart_date)],
                 by = "region", all.x = TRUE)

# Treatment timing: month of first restart
monthly[, treat_month := floor_date(first_restart_date, "month")]
monthly[, post := year_month >= treat_month]
monthly[is.na(post), post := FALSE]

# Cohort variable for CS estimator (0 = never treated)
monthly[, cohort := as.integer(format(treat_month, "%Y%m"))]
monthly[is.na(cohort), cohort := 0L]

# Time variable as integer months from 2010-04
monthly[, time_int := as.integer(difftime(year_month, as.Date("2010-04-01"), units = "days")) %/% 30]

# Relative time to treatment
monthly[treated == TRUE, rel_time := as.integer(difftime(year_month, treat_month, units = "days")) %/% 30]

# Region as numeric ID
monthly[, region_id := as.integer(factor(region))]

# Log price (for elasticity interpretation)
monthly[, log_price := log(price_mean)]

cat(sprintf("Final panel: %d obs, treated regions: %s\n",
            nrow(monthly),
            paste(unique(monthly[treated == TRUE]$region), collapse = ", ")))

# ─── 4. Sample restrictions ───────────────────────────────────────────────
# Focus on 2012-2025 (dropping first 2 years with very different market structure)
# and exclude last incomplete month
panel <- monthly[year_month >= "2012-01-01" & year_month <= "2025-12-01"]
cat(sprintf("Analysis panel (2012-2025): %d obs\n", nrow(panel)))

# ─── 5. Summary statistics ────────────────────────────────────────────────
cat("\nSummary by treatment status:\n")
print(panel[, .(
  mean_price = round(mean(price_mean), 2),
  sd_price = round(sd(price_mean), 2),
  n_months = .N,
  n_regions = uniqueN(region)
), by = treated])

cat("\nPre-treatment summary (before any restart):\n")
pre <- panel[year_month < "2015-08-01"]
print(pre[, .(
  mean_price = round(mean(price_mean), 2),
  sd_price = round(sd(price_mean), 2)
), by = region][order(region)])

saveRDS(panel, "data/analysis_panel.rds")
saveRDS(jepx_long, "data/jepx_long.rds")
cat("\nCleaned data saved.\n")
