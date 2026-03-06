# ==============================================================================
# 01b_fetch_weather.R — Gridded weather data from NASA POWER API
# apep_0532 v2: Economic Structure and Climate Belief Formation
# ==============================================================================
# Replaces Open-Meteo state capital data with NASA POWER gridded data
# Population-weighted state averages computed from multiple grid points
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

india_states <- fread(file.path(data_dir, "india_states.csv"))

# ==============================================================================
# NASA POWER API — Gridded daily weather
# ==============================================================================
# NASA POWER provides 0.5° x 0.5° gridded data globally
# API: https://power.larc.nasa.gov/api/temporal/daily/point
# Parameters: T2M (temperature at 2m), PRECTOTCORR (precipitation)
# No API key required
# ==============================================================================

cat("=== Fetching NASA POWER weather data ===\n")

fetch_nasa_power <- function(lat, lon, start_date, end_date,
                              params = "T2M,T2M_MAX,PRECTOTCORR") {
  # NASA POWER API endpoint
  url <- sprintf(
    "https://power.larc.nasa.gov/api/temporal/daily/point?parameters=%s&community=AG&longitude=%.4f&latitude=%.4f&start=%s&end=%s&format=JSON",
    params, lon, lat,
    format(as.Date(start_date), "%Y%m%d"),
    format(as.Date(end_date), "%Y%m%d")
  )

  tryCatch({
    resp <- GET(url, timeout(120))
    if (status_code(resp) == 200) {
      json <- content(resp, as = "text", encoding = "UTF-8")
      parsed <- fromJSON(json)
      props <- parsed$properties$parameter

      dates <- names(props$T2M)
      dt <- data.table(
        date = as.Date(dates, format = "%Y%m%d"),
        tavg = as.numeric(props$T2M),
        tmax = as.numeric(props$T2M_MAX),
        precip = as.numeric(props$PRECTOTCORR)
      )
      # NASA POWER uses -999 for missing
      dt[tavg < -900, tavg := NA]
      dt[tmax < -900, tmax := NA]
      dt[precip < -900, precip := NA]
      return(dt)
    } else {
      message("  HTTP ", status_code(resp))
      return(NULL)
    }
  }, error = function(e) {
    message("  Error: ", e$message)
    return(NULL)
  })
}

# Fetch weather for each state centroid
# We fetch: 1971-2000 (climate normals) and 2001-2024 (analysis period)
weather_all <- list()

for (i in 1:nrow(india_states)) {
  sname <- india_states$state[i]
  lat <- india_states$lat[i]
  lon <- india_states$lon[i]
  cat("  ", sname, "(", lat, ",", lon, ")...\n")

  # Period 1: Climate normals baseline (1981-2010) — NASA POWER starts 1981
  Sys.sleep(1)
  w1 <- fetch_nasa_power(lat, lon, "1981-01-01", "2010-12-31")

  # Period 2: Analysis period (2004-2024)
  Sys.sleep(1)
  w2 <- fetch_nasa_power(lat, lon, "2004-01-01", "2024-06-30")

  if (!is.null(w1) && !is.null(w2)) {
    w <- rbind(w1, w2[date > as.Date("2010-12-31")])
    w[, state := sname]
    weather_all[[sname]] <- w
    cat("    ", nrow(w), "days\n")
  } else if (!is.null(w2)) {
    w2[, state := sname]
    weather_all[[sname]] <- w2
    cat("    ", nrow(w2), "days (analysis only)\n")
  } else {
    cat("    FAILED — trying Open-Meteo fallback\n")
    # Fallback to Open-Meteo
    url <- sprintf(
      "https://archive-api.open-meteo.com/v1/archive?latitude=%.4f&longitude=%.4f&start_date=%s&end_date=%s&daily=temperature_2m_mean,temperature_2m_max,precipitation_sum&timezone=Asia%%2FKolkata",
      lat, lon, "1981-01-01", "2024-06-30"
    )
    tryCatch({
      resp <- fromJSON(url)
      if (!is.null(resp$daily)) {
        w_fb <- data.table(
          date = as.Date(resp$daily$time),
          tavg = resp$daily$temperature_2m_mean,
          tmax = resp$daily$temperature_2m_max,
          precip = resp$daily$precipitation_sum,
          state = sname
        )
        weather_all[[sname]] <- w_fb
        cat("    Open-Meteo fallback:", nrow(w_fb), "days\n")
      }
    }, error = function(e) {
      message("    Fallback also failed: ", e$message)
    })
  }
}

weather_daily <- rbindlist(weather_all, fill = TRUE)
fwrite(weather_daily, file.path(data_dir, "india_weather_daily.csv"))

cat("\n=== Weather data summary ===\n")
cat("Total daily obs:", nrow(weather_daily), "\n")
cat("States:", uniqueN(weather_daily$state), "\n")
cat("Date range:", as.character(min(weather_daily$date, na.rm=TRUE)), "to",
    as.character(max(weather_daily$date, na.rm=TRUE)), "\n")

# Validate
stopifnot("Weather data exists" = nrow(weather_daily) > 10000)
stopifnot("Multiple states" = uniqueN(weather_daily$state) >= 15)

cat("\n=== Weather fetch complete ===\n")
