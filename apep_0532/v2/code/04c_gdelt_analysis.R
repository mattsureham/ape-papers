# ==============================================================================
# 04c_gdelt_analysis.R — GDELT news coverage analysis
# apep_0532 v2: Economic Structure and Climate Belief Formation
# ==============================================================================
# Shows supply-side: climate news coverage in Indian media responds to weather
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"

# ==============================================================================
# LOAD GDELT DATA
# ==============================================================================
gdelt_file <- file.path(data_dir, "gdelt_india_climate.csv")

if (!file.exists(gdelt_file) || file.size(gdelt_file) < 100) {
  cat("GDELT data not available or empty. Attempting to fetch...\n")
  system2("python3", args = c("01c_fetch_gdelt.py"), wait = TRUE)
}

if (file.exists(gdelt_file) && file.size(gdelt_file) > 100) {
  gdelt <- fread(gdelt_file)
  cat("GDELT loaded:", nrow(gdelt), "rows\n")

  # Parse dates
  gdelt[, date := as.Date(substr(date, 1, 10))]
  gdelt[, year := year(date)]
  gdelt[, month := month(date)]

  # Categorize queries
  gdelt[, is_climate := grepl("climate|warming|crisis", query)]
  gdelt[, is_ag := grepl("crop|drought|monsoon", query)]

  # Monthly aggregation
  gdelt_monthly <- gdelt[, .(
    climate_news = sum(value[is_climate == TRUE], na.rm = TRUE),
    ag_news = sum(value[is_ag == TRUE], na.rm = TRUE),
    total_news = sum(value, na.rm = TRUE)
  ), by = .(year, month)]

  # Merge with national weather
  wx <- fread(file.path(data_dir, "india_weather_daily.csv"))
  wx[, date := as.Date(date)]
  wx_nat <- wx[, .(
    nat_tavg = mean(tavg, na.rm = TRUE),
    nat_tmax = mean(tmax, na.rm = TRUE)
  ), by = .(year = year(date), month = month(date))]

  # Compute national anomaly
  nat_normals <- wx_nat[year >= 1981 & year <= 2010, .(
    norm_tavg = mean(nat_tavg, na.rm = TRUE),
    sd_tavg = sd(nat_tavg, na.rm = TRUE)
  ), by = month]

  wx_nat <- merge(wx_nat, nat_normals, by = "month")
  wx_nat[, tavg_anomaly := nat_tavg - norm_tavg]
  wx_nat[, tavg_z := fifelse(sd_tavg > 0, tavg_anomaly / sd_tavg, 0)]

  # Merge
  gdelt_panel <- merge(gdelt_monthly, wx_nat[, .(year, month, tavg_anomaly, tavg_z)],
                         by = c("year", "month"), all.x = TRUE)

  gdelt_panel[, time_id := year * 100 + month]

  cat("GDELT panel:", nrow(gdelt_panel), "national-month obs\n\n")

  # ==============================================================================
  # REGRESSIONS
  # ==============================================================================
  cat("=== GDELT Analysis ===\n\n")

  # National-level: does weather predict climate news coverage?
  if (nrow(gdelt_panel[!is.na(tavg_anomaly) & climate_news > 0]) > 12) {
    g1 <- lm(log(climate_news + 1) ~ tavg_anomaly + factor(month),
             data = gdelt_panel[!is.na(tavg_anomaly)])
    cat("Climate news ~ temperature anomaly:\n")
    print(summary(g1))

    g2 <- lm(log(ag_news + 1) ~ tavg_anomaly + factor(month),
             data = gdelt_panel[!is.na(tavg_anomaly) & ag_news > 0])
    cat("\nAg news ~ temperature anomaly:\n")
    print(summary(g2))

    # Save
    fwrite(gdelt_panel, file.path(data_dir, "gdelt_analysis_panel.csv"))
  } else {
    cat("Insufficient GDELT data for regression analysis.\n")
  }

} else {
  cat("GDELT data not available. Skipping GDELT analysis.\n")
  cat("This is a supplementary analysis — paper proceeds without it.\n")
}

cat("\n=== GDELT analysis complete ===\n")
