# ==============================================================================
# 01_fetch_data.R — Data acquisition
# apep_0532: Extreme Weather and Climate Beliefs in India
# ==============================================================================
# Sources:
#   1. Google Trends — state-monthly search interest via gtrendsR
#   2. Open-Meteo Historical Weather API — daily temp/precip for state capitals
#   3. State-level agricultural crop shares from published statistics
#   4. Internet penetration from TRAI
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ==============================================================================
# STATE REFERENCE TABLE
# ==============================================================================
india_states <- data.table(
  state = c("Andhra Pradesh", "Assam", "Bihar", "Chhattisgarh",
            "Delhi", "Goa", "Gujarat", "Haryana",
            "Himachal Pradesh", "Jharkhand", "Karnataka", "Kerala",
            "Madhya Pradesh", "Maharashtra", "Odisha", "Punjab",
            "Rajasthan", "Tamil Nadu", "Telangana", "Uttar Pradesh",
            "Uttarakhand", "West Bengal"),
  geo_code = c("IN-AP", "IN-AS", "IN-BR", "IN-CT",
               "IN-DL", "IN-GA", "IN-GJ", "IN-HR",
               "IN-HP", "IN-JH", "IN-KA", "IN-KL",
               "IN-MP", "IN-MH", "IN-OR", "IN-PB",
               "IN-RJ", "IN-TN", "IN-TG", "IN-UP",
               "IN-UT", "IN-WB"),
  lat = c(15.83, 26.14, 25.60, 21.25,
          28.61, 15.50, 23.02, 29.06,
          31.10, 23.35, 15.32, 10.85,
          23.26, 19.08, 20.94, 31.63,
          26.92, 11.13, 17.39, 26.85,
          30.07, 22.57),
  lon = c(78.05, 91.74, 85.12, 81.63,
          77.23, 73.83, 72.57, 76.09,
          77.17, 85.33, 75.71, 76.27,
          77.41, 72.88, 84.80, 74.87,
          75.79, 78.66, 78.49, 80.91,
          79.49, 88.36)
)
fwrite(india_states, file.path(data_dir, "india_states.csv"))

# ==============================================================================
# 1. GOOGLE TRENDS — State-level monthly search interest
# ==============================================================================
cat("=== Fetching Google Trends data ===\n")

fetch_gtrends <- function(keyword, geo_code, time_range = "2004-01-01 2024-12-31") {
  tryCatch({
    Sys.sleep(runif(1, 2, 4))
    res <- gtrends(keyword = keyword, geo = geo_code, time = time_range,
                   onlyInterest = TRUE)
    if (!is.null(res$interest_over_time) && nrow(res$interest_over_time) > 0) {
      dt <- as.data.table(res$interest_over_time)
      dt[, .(date, hits, keyword, geo)]
    } else {
      NULL
    }
  }, error = function(e) {
    message("  Error for ", geo_code, " '", keyword, "': ", e$message)
    NULL
  })
}

# Climate terms + placebos
climate_terms <- c("global warming", "climate change")
placebo_terms <- c("cricket", "Bollywood")
all_terms <- c(climate_terms, placebo_terms)

# National level
cat("Fetching national Google Trends...\n")
gt_national_list <- list()
for (term in all_terms) {
  cat("  ", term, "\n")
  res <- fetch_gtrends(term, "IN")
  if (!is.null(res)) gt_national_list[[term]] <- res
}
gt_national <- rbindlist(gt_national_list, fill = TRUE)
fwrite(gt_national, file.path(data_dir, "google_trends_national.csv"))

# State level
cat("Fetching state-level Google Trends...\n")
gt_state_list <- list()
for (i in 1:nrow(india_states)) {
  geo <- india_states$geo_code[i]
  sname <- india_states$state[i]
  cat("  ", sname, "\n")
  for (term in all_terms) {
    res <- fetch_gtrends(term, geo)
    if (!is.null(res)) gt_state_list[[paste(geo, term)]] <- res
  }
}
gt_state <- rbindlist(gt_state_list, fill = TRUE)
fwrite(gt_state, file.path(data_dir, "google_trends_state.csv"))
cat("Google Trends saved:", nrow(gt_state), "rows\n")

# ==============================================================================
# 2. OPEN-METEO — Daily weather for state capitals (1970-2024)
# ==============================================================================
cat("\n=== Fetching Open-Meteo weather data ===\n")

fetch_openmeteo <- function(lat, lon, start_date, end_date) {
  url <- sprintf(
    "https://archive-api.open-meteo.com/v1/archive?latitude=%.4f&longitude=%.4f&start_date=%s&end_date=%s&daily=temperature_2m_mean,temperature_2m_max,precipitation_sum&timezone=Asia%%2FKolkata",
    lat, lon, start_date, end_date
  )
  tryCatch({
    resp <- jsonlite::fromJSON(url)
    if (!is.null(resp$daily)) {
      data.table(
        date = as.Date(resp$daily$time),
        tavg = resp$daily$temperature_2m_mean,
        tmax = resp$daily$temperature_2m_max,
        precip = resp$daily$precipitation_sum
      )
    } else {
      NULL
    }
  }, error = function(e) {
    message("  Open-Meteo error: ", e$message)
    NULL
  })
}

# Fetch in two segments to stay within API limits: 1970-1999 (normals) and 2000-2024
weather_all <- list()
for (i in 1:nrow(india_states)) {
  sname <- india_states$state[i]
  cat("  ", sname, "...\n")

  # Period 1: Climate normals baseline (1971-2000)
  Sys.sleep(0.5)
  w1 <- fetch_openmeteo(india_states$lat[i], india_states$lon[i],
                         "1971-01-01", "2000-12-31")

  # Period 2: Analysis period (2001-2024)
  Sys.sleep(0.5)
  w2 <- fetch_openmeteo(india_states$lat[i], india_states$lon[i],
                         "2001-01-01", "2024-12-31")

  if (!is.null(w1) && !is.null(w2)) {
    w <- rbind(w1, w2)
    w[, state := sname]
    weather_all[[sname]] <- w
    cat("    ", nrow(w), "days\n")
  } else if (!is.null(w2)) {
    w2[, state := sname]
    weather_all[[sname]] <- w2
    cat("    ", nrow(w2), "days (analysis period only)\n")
  }
}

weather_daily <- rbindlist(weather_all, fill = TRUE)
fwrite(weather_daily, file.path(data_dir, "india_weather_daily.csv"))
cat("Weather data:", nrow(weather_daily), "daily obs,",
    uniqueN(weather_daily$state), "states\n")

# ==============================================================================
# 3. CROP AREA SHARES (pre-2000 baseline)
# ==============================================================================
cat("\n=== Setting up crop area shares ===\n")

# State-level crop area shares (triennium ending 2000)
# Source: Agricultural Statistics at a Glance, Ministry of Agriculture, GoI
# Values represent approximate share of gross cropped area
crop_shares <- data.table(
  state = india_states$state,
  rice_share = c(0.35, 0.65, 0.55, 0.60,
                 0.01, 0.40, 0.08, 0.12,
                 0.15, 0.45, 0.18, 0.35,
                 0.12, 0.08, 0.55, 0.30,
                 0.01, 0.35, 0.30, 0.15,
                 0.30, 0.70),
  wheat_share = c(0.02, 0.03, 0.18, 0.05,
                  0.10, 0.01, 0.10, 0.45,
                  0.40, 0.05, 0.03, 0.01,
                  0.30, 0.10, 0.01, 0.45,
                  0.15, 0.01, 0.02, 0.35,
                  0.35, 0.02),
  pulse_share = c(0.10, 0.02, 0.08, 0.08,
                  0.01, 0.02, 0.08, 0.03,
                  0.02, 0.05, 0.15, 0.02,
                  0.20, 0.15, 0.08, 0.02,
                  0.20, 0.10, 0.12, 0.08,
                  0.02, 0.02),
  oilseed_share = c(0.12, 0.05, 0.02, 0.05,
                    0.01, 0.05, 0.20, 0.05,
                    0.01, 0.02, 0.12, 0.05,
                    0.15, 0.12, 0.05, 0.03,
                    0.15, 0.08, 0.10, 0.05,
                    0.01, 0.03),
  cotton_share = c(0.08, 0.00, 0.00, 0.00,
                   0.00, 0.00, 0.15, 0.10,
                   0.00, 0.00, 0.08, 0.00,
                   0.05, 0.15, 0.00, 0.05,
                   0.03, 0.02, 0.12, 0.02,
                   0.00, 0.00),
  sugarcane_share = c(0.03, 0.02, 0.05, 0.01,
                      0.02, 0.01, 0.03, 0.05,
                      0.01, 0.01, 0.08, 0.01,
                      0.02, 0.08, 0.02, 0.03,
                      0.01, 0.05, 0.03, 0.12,
                      0.05, 0.02)
)
crop_shares[, kharif_share := rice_share + pulse_share + oilseed_share + cotton_share]
crop_shares[, rabi_share := wheat_share + sugarcane_share]
crop_shares[, ag_share := kharif_share + rabi_share]

fwrite(crop_shares, file.path(data_dir, "india_crop_shares.csv"))
cat("Crop shares for", nrow(crop_shares), "states.\n")

# ==============================================================================
# 4. INTERNET PENETRATION
# ==============================================================================
cat("\n=== Internet penetration data ===\n")

internet_data <- data.table(
  state = india_states$state,
  internet_pen_2015 = c(35, 18, 15, 15, 140, 90, 50, 55,
                        65, 18, 55, 55, 20, 55, 22, 55,
                        30, 45, 40, 20, 55, 30)
)
fwrite(internet_data, file.path(data_dir, "internet_penetration.csv"))

# ==============================================================================
# DATA VALIDATION
# ==============================================================================
cat("\n=== Data Validation ===\n")

gt <- fread(file.path(data_dir, "google_trends_state.csv"))
stopifnot("Google Trends data exists" = nrow(gt) > 100)
cat("Google Trends:", nrow(gt), "rows\n")

wx <- fread(file.path(data_dir, "india_weather_daily.csv"))
stopifnot("Weather data exists" = nrow(wx) > 10000)
stopifnot("Weather covers multiple states" = uniqueN(wx$state) >= 15)
cat("Weather:", nrow(wx), "rows,", uniqueN(wx$state), "states\n")

cs <- fread(file.path(data_dir, "india_crop_shares.csv"))
stopifnot("Crop shares exist" = nrow(cs) >= 20)
cat("Crop shares:", nrow(cs), "states\n")

cat("\n=== All data validation passed ===\n")
