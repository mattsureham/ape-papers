## 01_fetch_data.R — Load pre-processed GFW data and compute lunar illumination
source("00_packages.R")

data_dir <- file.path(dirname(getwd()), "data")

# ---- Load squid jigger flag-day aggregates ----
squid_2020 <- fread(file.path(data_dir, "squid_flag_day_2020.csv"))
squid_2022 <- fread(file.path(data_dir, "squid_flag_day_2022.csv"))
squid <- rbind(squid_2020, squid_2022)
squid[, date := as.Date(date)]

cat("Squid jigger flag-day observations:", nrow(squid), "\n")
cat("Date range:", as.character(range(squid$date)), "\n")
cat("Flags:", paste(sort(unique(squid$flag)), collapse = ", "), "\n")

# ---- Compute lunar illumination for each date ----
all_dates <- data.table(date = seq(min(squid$date), max(squid$date), by = 1))
# suncalc::getMoonIllumination returns fraction (0-1)
moon <- getMoonIllumination(date = all_dates$date, keep = "fraction")
all_dates[, lunar_fraction := moon$fraction]

# Merge lunar data
squid <- merge(squid, all_dates, by = "date", all.x = TRUE)

cat("Lunar illumination range:", range(squid$lunar_fraction), "\n")

# ---- Flag classification ----
# Chinese fleet = subsidized; Korean, Taiwanese, Japanese = unsubsidized comparators
squid[, fleet_type := fifelse(flag == "CHN", "Chinese (subsidized)",
                     fifelse(flag %in% c("KOR", "TWN", "JPN"), "Comparator (unsubsidized)",
                             "Other"))]

cat("\nFleet composition:\n")
print(squid[, .(total_fishing_hours = sum(fishing_hours),
                total_vessels = sum(mmsi_present),
                n_days = uniqueN(date)), by = fleet_type])

# ---- Calendar variables ----
squid[, `:=`(
  year = year(date),
  month = month(date),
  dow = wday(date),
  yearmonth = format(date, "%Y-%m"),
  doy = yday(date)
)]

# ---- Save processed squid data ----
fwrite(squid, file.path(data_dir, "squid_panel.csv"))
cat("\nSaved squid_panel.csv:", nrow(squid), "rows\n")

# ---- Load trawler data for falsification ----
trawl_files <- list.files(data_dir, pattern = "trawler_flag_day_", full.names = TRUE)
if (length(trawl_files) > 0) {
  trawl <- rbindlist(lapply(trawl_files, fread))
  trawl[, date := as.Date(date)]
  trawl <- merge(trawl, all_dates, by = "date", all.x = TRUE)
  trawl[, fleet_type := fifelse(flag == "CHN", "Chinese",
                       fifelse(flag %in% c("KOR", "TWN", "JPN"), "Comparator", "Other"))]
  trawl[, `:=`(year = year(date), month = month(date), dow = wday(date),
               yearmonth = format(date, "%Y-%m"))]
  fwrite(trawl, file.path(data_dir, "trawler_panel.csv"))
  cat("Saved trawler_panel.csv:", nrow(trawl), "rows\n")
} else {
  cat("Trawler data not yet available — will be added.\n")
}

# ---- Vessel registry summary ----
vessels <- fread(file.path(data_dir, "fishing-vessels-v3.csv"),
                 select = c("flag_gfw", "vessel_class_gfw"))
squid_vessels <- vessels[vessel_class_gfw == "squid_jigger"]
cat("\nSquid jigger vessels in registry:\n")
print(squid_vessels[, .N, by = flag_gfw][order(-N)][1:10])
