## 01c_fetch_weather.R — Fetch daily precipitation from Open-Meteo
## apep_1432: Protests and Campaign Contributions (Weather IV)

source("00_packages.R")

ccc <- fread("../data/ccc_protests.csv") %>% as_tibble()

## Get representative coordinates for protest cities with 50+ events
city_coords <- ccc %>%
  group_by(city_state) %>%
  summarise(lat = median(lat, na.rm = TRUE),
            lon = median(lon, na.rm = TRUE),
            n_protests = n(),
            .groups = "drop") %>%
  filter(n_protests >= 50, !is.na(lat), !is.na(lon))

cat(sprintf("Fetching weather for %d cities with 50+ protests\n", nrow(city_coords)), flush = TRUE)

## Open-Meteo: query each city for each year
fetch_weather <- function(lat, lon, start_date, end_date) {
  url <- sprintf(
    "https://archive-api.open-meteo.com/v1/archive?latitude=%.4f&longitude=%.4f&start_date=%s&end_date=%s&daily=precipitation_sum&timezone=America/New_York",
    lat, lon, start_date, end_date
  )
  resp <- tryCatch(
    {
      r <- GET(url)
      Sys.sleep(0.2)
      content(r, as = "parsed")
    },
    error = function(e) NULL
  )
  if (is.null(resp) || is.null(resp$daily)) return(NULL)

  tibble(
    date = as.Date(unlist(resp$daily$time)),
    precip_mm = as.numeric(sapply(resp$daily$precipitation_sum,
                                   function(x) ifelse(is.null(x), NA_real_, x)))
  )
}

## Restrict to 2018-2023 matching GDELT period
## Take top 50 cities to match FEC scope
top_coords <- head(city_coords, 50)
years <- 2018:2023

weather_list <- list()
total <- nrow(top_coords) * length(years)
count <- 0

for (yr in years) {
  for (j in seq_len(nrow(top_coords))) {
    count <- count + 1
    if (count %% 20 == 0) {
      cat(sprintf("  Weather %d/%d (%s, %d)\n", count, total,
                  top_coords$city_state[j], yr), flush = TRUE)
    }
    w <- fetch_weather(
      lat = top_coords$lat[j],
      lon = top_coords$lon[j],
      start_date = paste0(yr, "-01-01"),
      end_date = paste0(yr, "-12-31")
    )
    if (!is.null(w)) {
      w$city_state <- top_coords$city_state[j]
      weather_list[[length(weather_list) + 1]] <- w
    }
  }
}

weather_df <- bind_rows(weather_list)
cat(sprintf("Weather data: %d city-day observations, %d cities\n",
            nrow(weather_df), n_distinct(weather_df$city_state)), flush = TRUE)

if (nrow(weather_df) == 0) {
  stop("FATAL: Weather API returned zero observations. Cannot proceed.")
}

fwrite(weather_df, "../data/weather_daily.csv")
cat("Saved weather data.\n")
