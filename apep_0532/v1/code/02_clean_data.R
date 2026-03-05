# ==============================================================================
# 02_clean_data.R — Variable construction and panel assembly
# apep_0532: Extreme Weather and Climate Beliefs in India
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"

# ==============================================================================
# 1. CLEAN GOOGLE TRENDS DATA
# ==============================================================================
cat("=== Cleaning Google Trends data ===\n")

gt_state <- fread(file.path(data_dir, "google_trends_state.csv"))
india_states <- fread(file.path(data_dir, "india_states.csv"))

# Convert hits to numeric
gt_state[, hits_num := as.numeric(ifelse(hits == "<1", 0.5, hits))]
gt_state[, date := as.Date(date)]
gt_state[, year := year(date)]
gt_state[, month := month(date)]

# Merge state names
gt_state <- merge(gt_state, india_states[, .(geo_code, state)],
                   by.x = "geo", by.y = "geo_code", all.x = TRUE)

# Climate vs placebo
gt_state[, is_climate := keyword %in% c("global warming", "climate change")]

# Aggregate: climate search index per state-month
gt_climate <- gt_state[is_climate == TRUE,
  .(climate_search = mean(hits_num, na.rm = TRUE)),
  by = .(state, year, month)
]

# Placebo search index
gt_placebo <- gt_state[is_climate == FALSE,
  .(placebo_search = mean(hits_num, na.rm = TRUE)),
  by = .(state, year, month)
]

gt_panel <- merge(gt_climate, gt_placebo,
                   by = c("state", "year", "month"), all.x = TRUE)

# National climate search for reference
gt_national <- fread(file.path(data_dir, "google_trends_national.csv"))
gt_national[, hits_num := as.numeric(ifelse(hits == "<1", 0.5, hits))]
gt_national[, date := as.Date(date)]
gt_national[, year := year(date)]
gt_national[, month := month(date)]
gt_nat <- gt_national[keyword %in% c("global warming", "climate change"),
  .(nat_climate = mean(hits_num, na.rm = TRUE)),
  by = .(year, month)
]
gt_panel <- merge(gt_panel, gt_nat, by = c("year", "month"), all.x = TRUE)

cat("Google Trends panel:", nrow(gt_panel), "state-month obs,",
    uniqueN(gt_panel$state), "states\n")

# ==============================================================================
# 2. PROCESS WEATHER DATA — monthly aggregation and anomalies
# ==============================================================================
cat("\n=== Processing weather data ===\n")

wx <- fread(file.path(data_dir, "india_weather_daily.csv"))
wx[, date := as.Date(date)]
wx[, year := year(date)]
wx[, month := month(date)]

# Monthly aggregation per state
wx_monthly <- wx[, .(
  tavg_mean = mean(tavg, na.rm = TRUE),
  tmax_mean = mean(tmax, na.rm = TRUE),
  precip_total = sum(precip, na.rm = TRUE),
  precip_days = sum(precip > 1, na.rm = TRUE),
  hot_days = sum(tmax > 40, na.rm = TRUE),
  n_days = .N
), by = .(state, year, month)]

# 30-year normals (1971-2000)
normals <- wx_monthly[year >= 1971 & year <= 2000, .(
  tavg_norm = mean(tavg_mean, na.rm = TRUE),
  tavg_sd = sd(tavg_mean, na.rm = TRUE),
  precip_norm = mean(precip_total, na.rm = TRUE),
  precip_sd = sd(precip_total, na.rm = TRUE)
), by = .(state, month)]

# Merge normals and compute anomalies
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

cat("Weather monthly:", nrow(wx_monthly), "state-month obs,",
    uniqueN(wx_monthly$state), "states,",
    "years:", min(wx_monthly$year), "-", max(wx_monthly$year), "\n")

# ==============================================================================
# 3. BARTIK INSTRUMENT
# ==============================================================================
cat("\n=== Constructing Bartik instrument ===\n")

crop_shares <- fread(file.path(data_dir, "india_crop_shares.csv"))

# National (leave-one-out) weather anomalies
wx_analysis <- wx_monthly[year >= 2004]

# For each state-month, compute national avg temp anomaly excluding that state
nat_anomaly <- wx_analysis[, .(
  nat_tavg = mean(tavg_anomaly, na.rm = TRUE),
  nat_precip = mean(precip_anomaly, na.rm = TRUE)
), by = .(year, month)]

# Leave-one-out: for state s, national avg excludes s
loo_list <- list()
for (s in unique(wx_analysis$state)) {
  others <- wx_analysis[state != s, .(
    loo_tavg = mean(tavg_anomaly, na.rm = TRUE),
    loo_precip = mean(precip_anomaly, na.rm = TRUE)
  ), by = .(year, month)]
  others[, state := s]
  loo_list[[s]] <- others
}
loo <- rbindlist(loo_list)

# Merge crop shares
loo <- merge(loo, crop_shares[, .(state, kharif_share, rabi_share, ag_share)],
              by = "state", all.x = TRUE)

# Season indicators
loo[, is_kharif := month >= 6 & month <= 11]

# Bartik = seasonal_crop_share * leave-one-out national anomaly
loo[, bartik_tavg := fifelse(is_kharif,
                              kharif_share * loo_tavg,
                              rabi_share * loo_tavg)]
loo[, bartik_precip := fifelse(is_kharif,
                                kharif_share * loo_precip,
                                rabi_share * loo_precip)]

cat("Bartik instrument:", nrow(loo), "state-month obs\n")

# ==============================================================================
# 4. ASSEMBLE PANEL
# ==============================================================================
cat("\n=== Assembling analysis panel ===\n")

# Merge GT + Weather
panel <- merge(gt_panel, wx_monthly[year >= 2004,
  .(state, year, month, tavg_mean, tavg_anomaly, tavg_z,
    precip_total, precip_anomaly, precip_z,
    heat_extreme, drought, flood, any_extreme, hot_days, n_days)],
  by = c("state", "year", "month"), all.x = TRUE)

# Merge Bartik
panel <- merge(panel, loo[, .(state, year, month, bartik_tavg, bartik_precip,
                                ag_share, kharif_share, rabi_share, loo_tavg, loo_precip)],
                by = c("state", "year", "month"), all.x = TRUE)

# Merge internet penetration
internet <- fread(file.path(data_dir, "internet_penetration.csv"))
panel <- merge(panel, internet, by = "state", all.x = TRUE)

# Create FE identifiers
panel[, state_id := as.integer(as.factor(state))]
panel[, month_of_year := month]
panel[, time_id := year * 100 + month]

# Log transform
panel[, log_climate := log(climate_search + 1)]
panel[, log_placebo := log(placebo_search + 1)]

# Interaction terms
panel[, tavg_x_ag := tavg_anomaly * ag_share]
panel[, precip_x_ag := precip_anomaly * ag_share]

# Lags and leads
setorder(panel, state, year, month)
for (lag_k in c(1, 3, 6, 12)) {
  panel[, paste0("tavg_lag", lag_k) := shift(tavg_anomaly, lag_k, type = "lag"), by = state]
  panel[, paste0("precip_lag", lag_k) := shift(precip_anomaly, lag_k, type = "lag"), by = state]
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
# 5. SUMMARY STATISTICS
# ==============================================================================
cat("\n=== Summary Statistics ===\n")

sumstat_vars <- c("climate_search", "placebo_search", "tavg_anomaly", "tavg_z",
                  "precip_anomaly", "precip_z", "bartik_tavg", "bartik_precip",
                  "ag_share", "heat_extreme", "drought", "any_extreme",
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

# Save full panel description
cat("\nPanel description:\n")
cat("  States:", paste(sort(unique(panel_clean$state)), collapse = ", "), "\n")
cat("  Period:", min(panel_clean$year), "-", max(panel_clean$year), "\n")
cat("  Obs:", nrow(panel_clean), "\n")
