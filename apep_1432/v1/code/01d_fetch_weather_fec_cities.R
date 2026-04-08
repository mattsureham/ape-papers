## 01d_fetch_weather_fec_cities.R — Fetch weather for FEC contribution cities
source("00_packages.R")

fec <- fread("../data/fec_contributions.csv") %>% as_tibble()
fec <- fec %>% mutate(city = str_to_title(trimws(contributor_city)),
                       state = toupper(trimws(contributor_state)),
                       city_state = paste0(city, ", ", state))

ccc <- fread("../data/ccc_protests.csv") %>% as_tibble()

## FEC cities
fec_cities <- unique(fec$city_state)
cat(sprintf("FEC cities: %d\n", length(fec_cities)))

## Get coordinates from GDELT for these FEC cities
fec_coords <- ccc %>%
  filter(city_state %in% fec_cities) %>%
  group_by(city_state) %>%
  summarise(lat = median(lat, na.rm = TRUE),
            lon = median(lon, na.rm = TRUE),
            .groups = "drop") %>%
  filter(!is.na(lat), !is.na(lon))

cat(sprintf("FEC cities with GDELT coords: %d\n", nrow(fec_coords)))

## Also read existing weather and append
existing_weather <- fread("../data/weather_daily.csv") %>% as_tibble()
existing_cities <- unique(existing_weather$city_state)

## Only fetch weather for cities we don't already have
new_cities <- fec_coords %>% filter(!city_state %in% existing_cities)
cat(sprintf("New cities to fetch weather: %d\n", nrow(new_cities)))

fetch_weather <- function(lat, lon, start_date, end_date) {
  url <- sprintf(
    "https://archive-api.open-meteo.com/v1/archive?latitude=%.4f&longitude=%.4f&start_date=%s&end_date=%s&daily=precipitation_sum&timezone=America/New_York",
    lat, lon, start_date, end_date)
  resp <- tryCatch({
    r <- GET(url)
    Sys.sleep(0.2)
    content(r, as = "parsed")
  }, error = function(e) NULL)
  if (is.null(resp) || is.null(resp$daily)) return(NULL)
  tibble(
    date = as.Date(unlist(resp$daily$time)),
    precip_mm = as.numeric(sapply(resp$daily$precipitation_sum,
                                   function(x) ifelse(is.null(x), NA_real_, x)))
  )
}

weather_list <- list()
years <- 2018:2023
for (yr in years) {
  for (j in seq_len(nrow(new_cities))) {
    w <- fetch_weather(new_cities$lat[j], new_cities$lon[j],
                       paste0(yr, "-01-01"), paste0(yr, "-12-31"))
    if (!is.null(w)) {
      w$city_state <- new_cities$city_state[j]
      weather_list[[length(weather_list) + 1]] <- w
    }
  }
  cat(sprintf("  Year %d done\n", yr), flush = TRUE)
}

new_weather <- bind_rows(weather_list)
cat(sprintf("New weather data: %d city-days\n", nrow(new_weather)))

## Append to existing (fix date type mismatch)
existing_weather$date <- as.Date(existing_weather$date)
new_weather$date <- as.Date(new_weather$date)
combined_weather <- bind_rows(existing_weather, new_weather)
cat(sprintf("Total weather: %d city-days, %d cities\n",
            nrow(combined_weather), n_distinct(combined_weather$city_state)))

fwrite(combined_weather, "../data/weather_daily.csv")
cat("Saved combined weather data.\n")
