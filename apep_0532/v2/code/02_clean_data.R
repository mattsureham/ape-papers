# ==============================================================================
# 02_clean_data.R — Variable construction and panel assembly
# apep_0532 v2: Economic Structure and Climate Belief Formation
# ==============================================================================
# Builds state-month panel merging:
#   1. Google Trends (climate + agricultural + placebo)
#   2. NASA POWER weather (anomalies vs 1981-2010 normals)
#   3. Agricultural shares (Census 2001)
#   4. Internet penetration (TRAI)
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"

# ==============================================================================
# 1. CLEAN GOOGLE TRENDS DATA
# ==============================================================================
cat("=== Cleaning Google Trends ===\n")

gt_state <- fread(file.path(data_dir, "google_trends_state.csv"))
india_states <- fread(file.path(data_dir, "india_states.csv"))

gt_state[, hits_num := as.numeric(ifelse(hits == "<1", 0.5, hits))]
gt_state[, date := as.Date(date)]
gt_state[, year := year(date)]
gt_state[, month := month(date)]

# Merge state names if needed
if (!"state" %in% names(gt_state)) {
  gt_state <- merge(gt_state, india_states[, .(geo_code, state)],
                     by.x = "geo", by.y = "geo_code", all.x = TRUE)
}

# Categorize terms
climate_terms <- c("global warming", "climate change")
ag_terms <- c("crop damage", "rain forecast", "crop insurance", "mandi price")
placebo_terms <- c("cricket", "Bollywood")

gt_state[, term_type := fifelse(keyword %in% climate_terms, "climate",
                        fifelse(keyword %in% ag_terms, "agricultural",
                        "placebo"))]

# Aggregate by state-month-category
gt_by_type <- gt_state[, .(search_index = mean(hits_num, na.rm = TRUE)),
                        by = .(state, year, month, term_type)]

# Wide format: climate, agricultural, placebo columns
gt_wide <- dcast(gt_by_type, state + year + month ~ term_type,
                  value.var = "search_index", fill = 0)

# Also keep individual climate search for backward compat
gt_climate <- gt_state[term_type == "climate",
  .(climate_search = mean(hits_num, na.rm = TRUE)),
  by = .(state, year, month)]

gt_panel <- merge(gt_wide, gt_climate, by = c("state", "year", "month"), all.x = TRUE)

# National reference
gt_national <- fread(file.path(data_dir, "google_trends_national.csv"))
gt_national[, hits_num := as.numeric(ifelse(hits == "<1", 0.5, hits))]
gt_national[, date := as.Date(date)]
gt_national[, year := year(date)]
gt_national[, month := month(date)]
gt_nat <- gt_national[keyword %in% climate_terms,
  .(nat_climate = mean(hits_num, na.rm = TRUE)),
  by = .(year, month)]
gt_panel <- merge(gt_panel, gt_nat, by = c("year", "month"), all.x = TRUE)

cat("GT panel:", nrow(gt_panel), "state-month obs,",
    uniqueN(gt_panel$state), "states\n")

# ==============================================================================
# 2. PROCESS WEATHER DATA
# ==============================================================================
cat("\n=== Processing weather ===\n")

wx <- fread(file.path(data_dir, "india_weather_daily.csv"))
wx[, date := as.Date(date)]
wx[, year := year(date)]
wx[, month := month(date)]

# Monthly aggregation
wx_monthly <- wx[, .(
  tavg_mean = mean(tavg, na.rm = TRUE),
  tmax_mean = mean(tmax, na.rm = TRUE),
  precip_total = sum(precip, na.rm = TRUE),
  precip_days = sum(precip > 1, na.rm = TRUE),
  hot_days = sum(tmax > 40, na.rm = TRUE),
  n_days = .N
), by = .(state, year, month)]

# 30-year normals (1981-2010 for NASA POWER)
normals <- wx_monthly[year >= 1981 & year <= 2010, .(
  tavg_norm = mean(tavg_mean, na.rm = TRUE),
  tavg_sd = sd(tavg_mean, na.rm = TRUE),
  precip_norm = mean(precip_total, na.rm = TRUE),
  precip_sd = sd(precip_total, na.rm = TRUE)
), by = .(state, month)]

wx_monthly <- merge(wx_monthly, normals, by = c("state", "month"), all.x = TRUE)
wx_monthly[, tavg_anomaly := tavg_mean - tavg_norm]
wx_monthly[, tavg_z := fifelse(tavg_sd > 0, tavg_anomaly / tavg_sd, 0)]
wx_monthly[, precip_anomaly := precip_total - precip_norm]
wx_monthly[, precip_z := fifelse(precip_sd > 0, precip_anomaly / precip_sd, 0)]

# Extreme indicators
wx_monthly[, heat_extreme := as.integer(tavg_z > 1.5)]
wx_monthly[, drought := as.integer(precip_z < -1.5)]
wx_monthly[, flood := as.integer(precip_z > 1.5)]
wx_monthly[, any_extreme := as.integer(heat_extreme == 1 | drought == 1 | flood == 1)]

cat("Weather:", nrow(wx_monthly), "state-month obs,",
    uniqueN(wx_monthly$state), "states\n")

# ==============================================================================
# 3. ASSEMBLE PANEL
# ==============================================================================
cat("\n=== Assembling panel ===\n")

# Merge GT + Weather
panel <- merge(gt_panel, wx_monthly[year >= 2004,
  .(state, year, month, tavg_mean, tavg_anomaly, tavg_z,
    precip_total, precip_anomaly, precip_z,
    heat_extreme, drought, flood, any_extreme, hot_days)],
  by = c("state", "year", "month"), all.x = TRUE)

# Merge agricultural shares
ag_shares <- fread(file.path(data_dir, "ag_shares.csv"))
panel <- merge(panel, ag_shares, by = "state", all.x = TRUE)

# Merge internet penetration
internet <- fread(file.path(data_dir, "internet_penetration.csv"))
panel <- merge(panel, internet, by = "state", all.x = TRUE)

# Fixed effects
panel[, state_id := as.integer(as.factor(state))]
panel[, month_of_year := month]
panel[, time_id := year * 100 + month]

# Log transforms
panel[, log_climate := log(climate_search + 1)]
panel[, log_agricultural := log(agricultural + 1)]
panel[, log_placebo := log(placebo + 1)]

# Interaction terms
panel[, tavg_x_ag := tavg_anomaly * ag_emp_share]
panel[, precip_x_ag := precip_anomaly * ag_emp_share]
panel[, tavg_x_crop := tavg_anomaly * crop_area_share]

# Seasonal indicators
panel[, is_monsoon := as.integer(month >= 6 & month <= 9)]
panel[, is_hot_season := as.integer(month >= 3 & month <= 5)]

# Lags and leads
setorder(panel, state, year, month)
for (lag_k in c(1, 3, 6, 12)) {
  panel[, paste0("tavg_lag", lag_k) := shift(tavg_anomaly, lag_k, type = "lag"), by = state]
}
for (lead_k in c(1, 3)) {
  panel[, paste0("tavg_lead", lead_k) := shift(tavg_anomaly, lead_k, type = "lead"), by = state]
}

# Drop missing
panel_clean <- panel[!is.na(climate_search) & !is.na(tavg_anomaly)]

cat("Panel:", nrow(panel_clean), "obs,",
    uniqueN(panel_clean$state), "states,",
    min(panel_clean$year), "-", max(panel_clean$year), "\n")

fwrite(panel_clean, file.path(data_dir, "analysis_panel.csv"))

# ==============================================================================
# 4. SUMMARY STATISTICS
# ==============================================================================
cat("\n=== Summary Statistics ===\n")

sumstat_vars <- c("climate_search", "agricultural", "placebo",
                  "tavg_anomaly", "tavg_z", "precip_anomaly", "precip_z",
                  "ag_emp_share", "crop_area_share",
                  "heat_extreme", "drought", "any_extreme",
                  "internet_pen_2015")

sumstats <- rbindlist(lapply(sumstat_vars, function(v) {
  x <- panel_clean[[v]]
  if (is.null(x)) return(NULL)
  data.table(
    Variable = v,
    N = sum(!is.na(x)),
    Mean = round(mean(x, na.rm = TRUE), 4),
    SD = round(sd(x, na.rm = TRUE), 4),
    Min = round(min(x, na.rm = TRUE), 4),
    P25 = round(quantile(x, 0.25, na.rm = TRUE), 4),
    Median = round(median(x, na.rm = TRUE), 4),
    P75 = round(quantile(x, 0.75, na.rm = TRUE), 4),
    Max = round(max(x, na.rm = TRUE), 4)
  )
}))

fwrite(sumstats, file.path(data_dir, "summary_stats.csv"))
print(sumstats)

cat("\nStates:", paste(sort(unique(panel_clean$state)), collapse = ", "), "\n")
cat("\n=== Data cleaning complete ===\n")
